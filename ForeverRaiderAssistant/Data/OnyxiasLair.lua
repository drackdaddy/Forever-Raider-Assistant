--[[ Onyxia's Lair (40 players): one boss, templated as the classic three-phase fight with tank,
whelp-control, side-group and fear-protection jobs. Confirm the fight is unchanged on the beta.
PROVISIONAL: instanceID and encounterID are placeholders (99xxx) until they are read from the beta client.
Events: none. SavedVariables: none. ]]

local _, ns = ...
local F = ns.Templates.Field

ns.RegisterRaid({
	instanceID = 99003,
	name = "Onyxia's Lair",
	size = 40,
	bosses = {
		{ encounterID = 99301, name = "Onyxia", page = {
			hint = "Template assumes the classic three-phase fight. Confirm on the beta.",
			phases = { "Phase 1", "Phase 2", "Phase 3" },
			sections = {
				{ title = "Ground phase", phase = 1, fields = {
					F("p1tank", "markplayer", "Tank", { filter = "tank", inherit = "mt" }),
					F("p1heal", "players", "Tank healers", { filter = "healer" }),
					F("p1fear", "pair", "Fear protection", { filter = "fear", target = "tank" }),
				} },
				{ title = "Air phase", phase = 2, fields = {
					F("p2whelpL", "players", "Whelps, left"),
					F("p2whelpR", "players", "Whelps, right"),
					F("p2sideL", "players", "Left side group"),
					F("p2sideR", "players", "Right side group"),
					F("p2ranged", "choice", "Ranged position", { options = {
						{ key = "left", text = "Left side" },
						{ key = "right", text = "Right side" },
						{ key = "split", text = "Split" },
					} }),
				} },
				{ title = "Second ground phase", phase = 3, fields = {
					F("p3tank", "markplayer", "Tank", { filter = "tank", inherit = "mt" }),
					F("p3heal", "players", "Tank healers", { filter = "healer" }),
					F("p3fear1", "pair", "Fear protection", { filter = "fear", target = "tank" }),
					F("p3fear2", "pair", "Fear protection", { filter = "fear", target = "tank" }),
					F("p3whelps", "players", "Whelp control"),
				} },
				{ title = "Utility", fields = { F("notes", "text", "Notes") } },
			},
		} },
	},
})
