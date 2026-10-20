--[[ Live roster reader: the current party or raid (up to 8 groups of 5) with name, class,
group, rank, game-assigned role and online state. Solo, it holds only the player.
Events: PLAYER_ENTERING_WORLD, GROUP_ROSTER_UPDATE, UNIT_CONNECTION, PLAYER_ROLES_ASSIGNED (debounced).
SavedVariables: none. ]]

local _, ns = ...

local Roster = { list = {}, byName = {} }
ns.Roster = Roster

-- "Name-Realm" for unit, or nil while the client has not loaded the name yet.
local function FullName(unit)
	local name, realm = UnitName(unit)
	if not name or name == UNKNOWNOBJECT then return nil end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName()
	end
	return realm and (name .. "-" .. realm)
end
Roster.FullName = FullName

-- Add one unit to the roster. Returns false if its name is not available yet.
local function Add(unit, group, rank)
	local name = FullName(unit)
	if not name then return false end
	local _, class = UnitClass(unit)
	local member = {
		name = name, unit = unit, class = class, group = group, rank = rank,
		role = UnitGroupRolesAssigned(unit), online = UnitIsConnected(unit),
	}
	Roster.list[#Roster.list + 1] = member
	Roster.byName[name] = member
	return true
end

local function Refresh()
	wipe(Roster.list)
	wipe(Roster.byName)
	local complete = true
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local _, rank, group = GetRaidRosterInfo(i)
			complete = Add("raid" .. i, group, rank) and complete
		end
	else
		complete = Add("player", 1, UnitIsGroupLeader("player") and 2 or 0)
		for i = 1, GetNumSubgroupMembers() do
			local unit = "party" .. i
			complete = Add(unit, 1, UnitIsGroupLeader(unit) and 2 or 0) and complete
		end
	end
	-- Names can be missing right after a zone change; read again shortly instead of showing gaps.
	if not complete then
		ns.Debounce("roster", 1, Refresh)
	end
	ns.MarkDirty("home")
end

local function Queue()
	ns.Debounce("roster", 0.3, Refresh)
end

ns.On("PLAYER_ENTERING_WORLD", Queue)
ns.On("GROUP_ROSTER_UPDATE", Queue)
ns.On("UNIT_CONNECTION", Queue)
ns.On("PLAYER_ROLES_ASSIGNED", Queue)
