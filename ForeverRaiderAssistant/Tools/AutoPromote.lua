--[[ Auto promote: while you lead a raid, members of your guild with a ticked guild rank, and players
on your name list (full names, ignoring capitals), are promoted to raid assistant. Each player is
promoted at most once per session, so someone you demote stays demoted. Changes wait until combat
ends.
Events: GROUP_ROSTER_UPDATE (debounced), PLAYER_REGEN_ENABLED, GUILD_RANKS_UPDATE.
SavedVariables: promoteByRank, promoteRanks[rankIndex] = true, promoteByName, promoteNames in the
active tools settings (see ns.Tools in Core/DB.lua). ]]

local _, ns = ...

local done = {} -- [full name] = true once promoted this session
local waiting = false -- a run was skipped for combat

-- Set of lower-case full names from a comma-separated list.
function ns.ParseNames(text)
	local set = {}
	for part in text:gmatch("[^,]+") do
		local name = ns.Planned.CleanName(part)
		if name then set[strlower(name)] = true end
	end
	return set
end

-- True if member should be an assistant under the current settings.
local function Wanted(member, tools, names, myGuild)
	if tools.promoteByName and names[strlower(member.name)] then return true end
	if not (tools.promoteByRank and myGuild) then return false end
	local guild, _, rankIndex = GetGuildInfo(member.unit)
	return guild == myGuild and tools.promoteRanks[rankIndex] == true
end

-- Promote every wanted member who is not an assistant yet. Only the raid leader can promote.
function ns.RunAutoPromote()
	local tools = ns.Tools()
	if not (tools.promoteByRank or tools.promoteByName) then return end
	if not (IsInRaid() and UnitIsGroupLeader("player")) then return end
	if InCombatLockdown() then
		waiting = true
		return
	end
	local names, myGuild = ns.ParseNames(tools.promoteNames), GetGuildInfo("player")
	for _, member in ipairs(ns.Roster.list) do
		if member.rank == 0 and not done[member.name] and Wanted(member, tools, names, myGuild) then
			done[member.name] = true
			PromoteToAssistant(member.unit)
			ns.Print(("Promoted %s to raid assistant."):format(member.name))
		end
	end
end

-- Runs after the roster reader has refreshed (its debounce is shorter).
ns.On("GROUP_ROSTER_UPDATE", function()
	ns.Debounce("autopromote", 1, ns.RunAutoPromote)
end)

ns.On("PLAYER_REGEN_ENABLED", function()
	if waiting then
		waiting = false
		ns.RunAutoPromote()
	end
end)

ns.On("GUILD_RANKS_UPDATE", function()
	ns.MarkDirty("tools")
end)
