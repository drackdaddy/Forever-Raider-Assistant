--[[ Capability filters: which players a slot's dropdown offers.
Tank and healer slots take players the leader tagged (Home screen) or the game assigned that role.
The class rules below are PROVISIONAL. They follow the classic class kit, adjusted for the Forever
beta notes (Fear Ward is no longer limited to Dwarf priests). Check each interrupt, dispel,
crowd-control and fear-protection spell on the beta and edit only this table.
A filter may also be "class:WARRIOR" (any one class file name).
Events: none. SavedVariables: reads FRA_DB.roleTags. ]]

local _, ns = ...

local RULES = {
	tank = { label = "Tanks", tags = { MT = true, OT = true }, role = "TANK" },
	healer = { label = "Healers", tags = { HEALER = true }, role = "HEALER" },
	interrupt = { label = "Interrupters", classes = { WARRIOR = true, ROGUE = true, SHAMAN = true, MAGE = true } },
	curse = { label = "Curse removers", classes = { MAGE = true, DRUID = true } },
	magic = { label = "Magic dispellers", classes = { PRIEST = true, PALADIN = true } },
	purge = { label = "Offensive dispellers", classes = { PRIEST = true, SHAMAN = true, WARLOCK = true } },
	cc = {
		label = "Crowd control",
		classes = { MAGE = true, ROGUE = true, WARLOCK = true, HUNTER = true, PRIEST = true, DRUID = true },
	},
	fear = { label = "Fear protection", classes = { PRIEST = true, SHAMAN = true } },
}

-- True if roster member may fill a slot with this filter (nil filter = anyone).
function ns.Eligible(member, filter)
	if not filter then return true end
	local class = filter:match("^class:(.+)")
	if class then return member.class == class end
	local rule = RULES[filter]
	if rule.tags then
		return rule.tags[ns.db.roleTags[member.name]] or member.role == rule.role
	end
	return rule.classes[member.class] == true
end

-- Display label for a filter, used as the picker title and in its empty-state message.
function ns.FilterLabel(filter)
	if not filter then return "Any player" end
	local class = filter:match("^class:(.+)")
	if class then return LOCALIZED_CLASS_NAMES_MALE[class] or class end
	return RULES[filter].label
end
