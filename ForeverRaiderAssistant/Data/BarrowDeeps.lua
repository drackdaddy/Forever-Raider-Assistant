--[[ Barrow Deeps (10 players): bosses in kill order with generic templates.
PROVISIONAL: instanceID and encounterIDs are placeholders (99xxx) until they are read from the beta
client. Boss names and order follow Warcraft Tavern and Warcraft Wiki and may still change.
Events: none. SavedVariables: none. ]]

local _, ns = ...

ns.RegisterRaid({
	instanceID = 99001,
	name = "Barrow Deeps",
	size = 10,
	bosses = {
		{ encounterID = 99101, name = "Deepscar Matriarch" },
		{ encounterID = 99102, name = "Khalith the Dreadspinner" },
		{ encounterID = 99103, name = "Amethrax" },
		{ encounterID = 99104, name = "Ravus and Darlissa", targets = { "Ravus", "Darlissa" } },
		{ encounterID = 99105, name = "Elder Tangleclaw" },
		{ encounterID = 99106, name = "Well of Sorrow" },
		{ encounterID = 99107, name = "Del'lynar Songwood" },
		{ encounterID = 99108, name = "Sonya Darkhallow" },
	},
})
