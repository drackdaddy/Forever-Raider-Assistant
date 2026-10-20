--[[ Auto loot master: while you lead a raid, the named player (full name, ignoring capitals) is made
master looter once they are in the raid. It is set once per raid, so if you change the loot method
by hand afterwards it stays as you set it. Changes wait until combat ends.
Events: GROUP_ROSTER_UPDATE (debounced), PLAYER_REGEN_ENABLED.
SavedVariables: lootMaster, lootMasterName in the active tools settings (see ns.Tools in
Core/DB.lua). ]]

local _, ns = ...

local assigned -- full name made loot master in the current raid
local waiting = false -- a run was skipped for combat

-- The name form the loot API takes for unit: first name, plus realm when it differs from ours.
local function LootName(unit)
	local first, realm = UnitName(unit)
	return (realm and realm ~= "") and (first .. "-" .. realm) or first
end

-- Make the named player master looter if they are in the raid and have not been made it yet.
function ns.RunLootMaster()
	if not IsInRaid() then
		assigned = nil
		return
	end
	local tools = ns.Tools()
	local wanted = tools.lootMaster and ns.Planned.CleanName(tools.lootMasterName)
	if not wanted or not UnitIsGroupLeader("player") then return end
	local member = ns.Roster.Find(wanted)
	if not member or assigned == member.name then return end
	if InCombatLockdown() then
		waiting = true
		return
	end
	assigned = member.name
	C_PartyInfo.SetLootMethod(Enum.LootMethod.Masterlooter, LootName(member.unit))
	ns.Print(("Set %s as master looter."):format(member.name))
end

ns.On("GROUP_ROSTER_UPDATE", function()
	ns.Debounce("lootmaster", 1, ns.RunLootMaster)
end)

ns.On("PLAYER_REGEN_ENABLED", function()
	if waiting then
		waiting = false
		ns.RunLootMaster()
	end
end)
