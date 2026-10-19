--[[ Hyjal Summit (20 players): bosses in kill order with generic templates.
PROVISIONAL: instanceID and encounterIDs are placeholders (99xxx) until they are read from the beta
client. Sources spell three names differently (Minderel/Minderei, Sylvesteris/Sylvestris,
Dreambound/Dreadbound); confirm them in game. Time-Lost Battalion and Council of Thorns look like
multi-target fights, so they get three target sections each until the fights are known.
Events: none. SavedVariables: none. ]]

local _, ns = ...

local THREE_TARGETS = { "Target 1", "Target 2", "Target 3" }

ns.RegisterRaid({
	instanceID = 99002,
	name = "Hyjal Summit",
	size = 20,
	bosses = {
		{ encounterID = 99201, name = "Bandalar" },
		{ encounterID = 99202, name = "Time-Lost Battalion", targets = THREE_TARGETS },
		{ encounterID = 99203, name = "Old Gloomlurker" },
		{ encounterID = 99204, name = "Kathris the Haunted" },
		{ encounterID = 99205, name = "Elder Minderel" },
		{ encounterID = 99206, name = "Council of Thorns", targets = THREE_TARGETS },
		{ encounterID = 99207, name = "The Wild King" },
		{ encounterID = 99208, name = "Ancient of Decay" },
		{ encounterID = 99209, name = "Sylvesteris Dusksong" },
		{ encounterID = 99210, name = "Gharalis the Abyssal" },
		{ encounterID = 99211, name = "Anara Chillwind" },
		{ encounterID = 99212, name = "Tracker Stillwind" },
		{ encounterID = 99213, name = "Nythus the Dreambound" },
	},
})
