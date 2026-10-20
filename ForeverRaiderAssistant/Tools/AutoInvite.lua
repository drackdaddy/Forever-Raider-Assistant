--[[ Auto invite: when the option is on, a character whisper whose whole text (ignoring capitals and
outer spaces) is one of the invite words gets the sender a group invite. It works only while you
can invite: solo, as party leader, or as raid leader or assistant. It pauses during boss
encounters, when the game hides whisper text from addons, and it sends no chat.
When party members plus invites still waiting for an answer would pass 5, the party leader's party
is converted to a raid. If the party is already full, the invite waits until the conversion lands.
Events: CHAT_MSG_WHISPER, GROUP_ROSTER_UPDATE (debounced).
SavedVariables: FRA_CharDB.tools.autoInvite, .inviteWords. ]]

local _, ns = ...

local PARTY_SIZE = MAX_PARTY_MEMBERS + 1
-- Invites nobody answers stop counting toward the party size after this many seconds.
local INVITE_TIMEOUT = 120

local words -- set of lower-case invite words, rebuilt after the list changes
local pending = {} -- [fullName] = time sent, for invites not yet answered
local queued = {} -- names to invite once the party has become a raid
local converting = false

-- Split a comma-separated word list into a set of lower-case words.
function ns.ParseInviteWords(text)
	local set = {}
	for word in text:gmatch("[^,]+") do
		word = strlower(strtrim(word))
		if word ~= "" then
			set[word] = true
		end
	end
	return set
end

-- Save the comma-separated word list.
function ns.SetInviteWords(text)
	ns.char.tools.inviteWords = text
	words = nil
end

local function PendingCount()
	local count = 0
	for _ in pairs(pending) do
		count = count + 1
	end
	return count
end

-- Ask the game to turn the party into a raid, once until the change arrives.
local function ConvertToRaid()
	if converting then return end
	converting = true
	C_PartyInfo.ConvertToRaid()
	ns.Print("Converted the party to a raid.")
end

-- Convert when members plus unanswered invites would not fit in a party. Only a party leader can.
local function ConvertIfNeeded()
	if IsInGroup() and not IsInRaid() and UnitIsGroupLeader("player")
		and GetNumGroupMembers() + PendingCount() > PARTY_SIZE then
		ConvertToRaid()
	end
end

local function Invite(name)
	local sent = GetTime()
	pending[name] = sent
	C_Timer.After(INVITE_TIMEOUT, function()
		if pending[name] == sent then pending[name] = nil end
	end)
	C_PartyInfo.InviteUnit(name)
	ns.Print(("Invited %s."):format(Ambiguate(name, "short")))
	ConvertIfNeeded()
end

-- Returns "invite", "queue" (party full, convert first), or false plus a reason worth printing.
local function InviteAction()
	if not IsInGroup() then return "invite" end
	if IsInRaid() then
		if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return false end
		if GetNumGroupMembers() >= MAX_RAID_MEMBERS then return false, "The raid is full." end
		return "invite"
	end
	if not UnitIsGroupLeader("player") then return false end
	return GetNumGroupMembers() >= PARTY_SIZE and "queue" or "invite"
end

ns.On("CHAT_MSG_WHISPER", function(_, text, sender)
	local tools = ns.char.tools
	if not tools.autoInvite or IsEncounterInProgress() then return end
	words = words or ns.ParseInviteWords(tools.inviteWords)
	if not words[strlower(strtrim(text))] or ns.Roster.byName[sender] or pending[sender] then return end
	local action, reason = InviteAction()
	if action == "invite" then
		Invite(sender)
	elseif action == "queue" then
		if not tContains(queued, sender) then queued[#queued + 1] = sender end
		ConvertToRaid()
	elseif reason then
		ns.Print(reason)
	end
end)

-- After the group changes: forget invites that were accepted, send invites that waited for the raid,
-- and convert if the party is about to overflow. Runs after the roster reader has refreshed.
local function OnGroupChanged()
	for name in pairs(pending) do
		if ns.Roster.byName[name] then pending[name] = nil end
	end
	if IsInRaid() or not IsInGroup() then converting = false end
	if not IsInGroup() then wipe(queued) end
	if IsInRaid() and #queued > 0 then
		local names = queued
		queued = {}
		for _, name in ipairs(names) do
			if not ns.Roster.byName[name] then Invite(name) end
		end
	end
	ConvertIfNeeded()
end

ns.On("GROUP_ROSTER_UPDATE", function()
	ns.Debounce("autoinvite", 0.5, OnGroupChanged)
end)
