--[[ Auto invite: when the option is on, a character whisper whose whole text (ignoring capitals and
outer spaces) is one of the invite words gets the sender a group invite. It works only while you
can invite: solo, as party leader, or as raid leader or assistant. It pauses during boss
encounters, when the game hides whisper text from addons, and it sends no chat.
Events: CHAT_MSG_WHISPER. SavedVariables: FRA_CharDB.tools.autoInvite, .inviteWords. ]]

local _, ns = ...

local words -- set of lower-case invite words, rebuilt after the list changes

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

-- Returns true if the player may invite now, or false plus a reason worth printing.
local function CanInvite()
	if not IsInGroup() then return true end
	if IsInRaid() then
		if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return false end
		return GetNumGroupMembers() < MAX_RAID_MEMBERS, "The raid is full."
	end
	if not UnitIsGroupLeader("player") then return false end
	return GetNumGroupMembers() <= MAX_PARTY_MEMBERS, "The party is full. Convert it to a raid to keep inviting."
end

ns.On("CHAT_MSG_WHISPER", function(_, text, sender)
	local tools = ns.char.tools
	if not tools.autoInvite or IsEncounterInProgress() then return end
	words = words or ns.ParseInviteWords(tools.inviteWords)
	if not words[strlower(strtrim(text))] or ns.Roster.byName[sender] then return end
	local ok, reason = CanInvite()
	if not ok then
		if reason then ns.Print(reason) end
		return
	end
	C_PartyInfo.InviteUnit(sender)
	ns.Print(("Invited %s."):format(Ambiguate(sender, "short")))
end)
