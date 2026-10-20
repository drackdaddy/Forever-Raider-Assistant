--[[ Live roster reader: the current party or raid (up to 8 groups of 5) with name, class,
group, rank, game-assigned role and online state. Solo, it holds only the player.
Forever characters have a first and last name. GetUnitName(unit, true) gives the full name
("Drack Daddy"), which is each player's key here, in role tags and in planned entries. Chat and
addon-message events name players by first name and internal realm, so Roster.FromSender matches
those forms too.
Events: PLAYER_ENTERING_WORLD, GROUP_ROSTER_UPDATE, UNIT_CONNECTION, PLAYER_ROLES_ASSIGNED (debounced).
SavedVariables: none. ]]

local _, ns = ...

local Roster = { list = {}, byName = {}, bySender = {} }
ns.Roster = Roster

-- Full character name ("Drack Daddy") for unit, or nil while the client has not loaded it yet.
local function FullName(unit)
	local name = GetUnitName(unit, true)
	if not name or name == UNKNOWNOBJECT then return nil end
	return name
end
Roster.FullName = FullName

-- The "First-Realm" form chat and addon-message events use for unit.
local function SenderName(unit)
	local first, realm = UnitName(unit)
	if not realm or realm == "" then realm = GetNormalizedRealmName() end
	return realm and (first .. "-" .. realm) or first
end

-- Live member named by a chat or addon-message sender: full name, "First-Realm", or "First".
function Roster.FromSender(sender)
	local member = Roster.byName[sender] or Roster.bySender[sender]
	if member or sender:find("-", 1, true) then return member end
	local realm = GetNormalizedRealmName()
	return realm and Roster.bySender[sender .. "-" .. realm]
end

-- Live member whose name matches name, ignoring capitals.
function Roster.Find(name)
	name = strlower(name)
	for _, member in ipairs(Roster.list) do
		if strlower(member.name) == name then return member end
	end
end

-- Add one unit to the roster. Returns false if its name is not available yet.
local function Add(unit, group, rank)
	local name = FullName(unit)
	if not name then return false end
	local _, class = UnitClass(unit)
	local member = {
		name = name, sender = SenderName(unit), unit = unit, class = class, group = group, rank = rank,
		role = UnitGroupRolesAssigned(unit), online = UnitIsConnected(unit),
	}
	Roster.list[#Roster.list + 1] = member
	Roster.byName[name] = member
	Roster.bySender[member.sender] = member
	-- Role tags saved by 0.7.x and earlier used "First-Realm"; move them to the full name.
	local tags = ns.db.roleTags
	if tags[member.sender] then
		tags[name] = tags[name] or tags[member.sender]
		tags[member.sender] = nil
	end
	return true
end

local function Refresh()
	wipe(Roster.list)
	wipe(Roster.byName)
	wipe(Roster.bySender)
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
	ns.Planned.Merge()
	ns.MarkDirty("home")
end

local function Queue()
	ns.Debounce("roster", 0.3, Refresh)
end

ns.On("PLAYER_ENTERING_WORLD", Queue)
ns.On("GROUP_ROSTER_UPDATE", Queue)
ns.On("UNIT_CONNECTION", Queue)
ns.On("PLAYER_ROLES_ASSIGNED", Queue)
