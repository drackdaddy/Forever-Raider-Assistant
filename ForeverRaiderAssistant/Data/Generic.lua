--[[ Generic raid: for raids that have no data file yet. Twelve generic boss sheets (Boss 1 to 12),
each with tank, healer, marker, interrupt and dispel rows, plus the usual General and Trash pages.
Sized for 40 players so any raid fits. instanceID 0 is never a real instance, so its saved plan
cannot collide with a real raid's; bosses use keys instead of encounter IDs for the same reason.
Events: none. SavedVariables: none. ]]

local _, ns = ...

local BOSS_COUNT = 12
local bosses = {}
for i = 1, BOSS_COUNT do
	bosses[i] = {
		key = "boss" .. i,
		name = "Boss " .. i,
		hint = "Generic sheet for a raid without its own data file. Name the boss in the notes row.",
	}
end

ns.RegisterRaid({
	instanceID = 0,
	name = "Generic raid",
	size = 40,
	bosses = bosses,
})
