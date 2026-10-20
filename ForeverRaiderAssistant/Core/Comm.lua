--[[ Addon messages: a small, reliable-enough transport for sending one payload to the group.
Wire format, one addon message per chunk (prefix "FRA", 255 bytes max):
  <protocol version> TAB <kind letter> TAB <message id> TAB <chunk number> TAB <chunk count> TAB <data>
Payloads are split into chunks and sent one at a time, paced, with a pause and retry when the game
reports throttling. Nothing is sent while a boss encounter is in progress: the queue waits for
ENCOUNTER_END. Received chunks are only accepted from group members with leader or assistant rank,
and only from the same protocol version (other versions are ignored, with one warning). Partial
payloads that stop arriving are dropped after a while.
Events: CHAT_MSG_ADDON, ENCOUNTER_END. SavedVariables: none. ]]

local _, ns = ...

local Comm = {}
ns.Comm = Comm

local PREFIX = "FRA"
local VERSION = 1
local CHUNK_DATA = 220 -- data bytes per message, leaving room for the header within 255
local MAX_CHUNKS = 40
local PACE = 0.2 -- seconds between messages
local THROTTLE_RETRY = 1
local PARTIAL_TIMEOUT = 30

local Result = Enum.SendAddonMessageResult
local handlers = {} -- [kind] = fn(sender, payload)
local queue = {} -- chunks waiting to go out: { text, channel, job }
local pumping = false
local nextID = 0
local partial = {} -- [sender TAB id] = { kind, total, count, parts, seen }
local warnedVersion = false

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

-- Handle complete payloads of kind (one letter) with fn(sender, payload).
function Comm.Register(kind, fn)
	handlers[kind] = fn
end

-- True if the player may send to the group: in a group, and its leader (or a raid assistant).
function Comm.CanSend()
	if not IsInGroup() then return false end
	return UnitIsGroupLeader("player") or (IsInRaid() and UnitIsGroupAssistant("player"))
end

-- Send the queue head, then schedule the next one. Stops while an encounter is in progress.
local function Pump()
	local item = queue[1]
	if not item then
		pumping = false
		return
	end
	if IsEncounterInProgress() then
		item.job.onStatus("queued")
		pumping = false
		return
	end
	local result = C_ChatInfo.SendAddonMessage(PREFIX, item.text, item.channel)
	if result == Result.AddonMessageThrottle or result == Result.ChannelThrottle then
		C_Timer.After(THROTTLE_RETRY, Pump)
		return
	end
	table.remove(queue, 1)
	local job = item.job
	if result ~= Result.Success then
		-- Drop the rest of this payload; a partial copy is useless to receivers.
		for i = #queue, 1, -1 do
			if queue[i].job == job then table.remove(queue, i) end
		end
		job.onStatus("failed")
	elseif item.last then
		job.onStatus("sent")
	end
	C_Timer.After(PACE, Pump)
end

-- Queue payload of kind for the whole group. onStatus(state) reports "sending", "queued" (waiting
-- for the encounter to end), "sent" or "failed". Returns false if the payload is too large.
function Comm.Send(kind, payload, onStatus)
	local total = math.max(1, math.ceil(#payload / CHUNK_DATA))
	if total > MAX_CHUNKS then return false end
	nextID = nextID + 1
	local job = { onStatus = onStatus }
	local channel = IsInRaid() and "RAID" or "PARTY"
	for seq = 1, total do
		local data = payload:sub((seq - 1) * CHUNK_DATA + 1, seq * CHUNK_DATA)
		queue[#queue + 1] = {
			text = table.concat({ VERSION, kind, nextID, seq, total, data }, "\t"),
			channel = channel, job = job, last = seq == total,
		}
	end
	onStatus("sending")
	if not pumping then
		pumping = true
		Pump()
	end
	return true
end

-- Resume a held queue shortly after the encounter, once the game reports it as over.
ns.On("ENCOUNTER_END", function()
	C_Timer.After(1, function()
		if not pumping and #queue > 0 then
			pumping = true
			queue[1].job.onStatus("sending")
			Pump()
		end
	end)
end)

local function PruneStale(now)
	for key, entry in pairs(partial) do
		if now - entry.seen > PARTIAL_TIMEOUT then partial[key] = nil end
	end
end

ns.On("CHAT_MSG_ADDON", function(_, prefix, text, _, sender)
	if prefix ~= PREFIX then return end
	-- Senders are matched to the live roster and known by their full name from here on.
	local member = ns.Roster.FromSender(sender)
	if not member or member.name == ns.Roster.FullName("player") or (member.rank or 0) < 1 then return end
	sender = member.name
	local version, kind, id, seq, total, data = text:match("^(%d+)\t(%a)\t(%d+)\t(%d+)\t(%d+)\t(.*)$")
	if not version then return end
	if tonumber(version) ~= VERSION then
		if not warnedVersion then
			warnedVersion = true
			ns.Print(("%s runs a different version of the addon; their notes are ignored. Update both copies.")
				:format(Ambiguate(sender, "short")))
		end
		return
	end
	seq, total = tonumber(seq), tonumber(total)
	if not handlers[kind] or total > MAX_CHUNKS or seq < 1 or seq > total then return end

	local now = GetTime()
	PruneStale(now)
	local key = sender .. "\t" .. id
	local entry = partial[key]
	if not entry then
		entry = { kind = kind, total = total, count = 0, parts = {} }
		partial[key] = entry
	elseif entry.kind ~= kind or entry.total ~= total then
		return
	end
	entry.seen = now
	if not entry.parts[seq] then
		entry.parts[seq] = data
		entry.count = entry.count + 1
	end
	if entry.count == total then
		partial[key] = nil
		handlers[kind](sender, table.concat(entry.parts))
	end
end)
