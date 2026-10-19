--[[ Raid and boss catalog: raid data files register here, and every raid gets a General page and a
Trash page ahead of its bosses (in kill order). Pages are keyed "general", "trash" or the encounter ID.
The UI reads only this catalog, so adding a raid means adding a data file.

Page shape: { key, name, hint, phases = { "label", ... }, variants = { { key, text }, ... },
  sections = { { title, phase = n, variant = key, fields = { field, ... } }, ... } }
Field shape: { id, type, label, filter, target, inherit, renamable, options }
  type: "player" | "players" | "pair" (filter = source, target = destination filter)
    | "markplayer" (raid marker plus player) | "choice" (options = { { key, text } }) | "text"
  inherit: field id on the General page used until this page sets its own value.
Events: none. SavedVariables: none. ]]

local _, ns = ...

ns.raids = {}
ns.raidByID = {}

local T = {}
ns.Templates = T

-- Build a field definition. extra holds the optional keys listed in the header.
function T.Field(id, ftype, label, extra)
	local field = extra or {}
	field.id, field.type, field.label = id, ftype, label
	return field
end
local F = T.Field

function T.General()
	return {
		hint = "Tanks and standing jobs set here apply to every boss until a boss sheet sets its own.",
		sections = {
			{ title = "Tanks", fields = {
				F("mt", "markplayer", "Main Tank", { filter = "tank" }),
				F("ot1", "markplayer", "Off Tank 1", { filter = "tank" }),
				F("ot2", "markplayer", "Off Tank 2", { filter = "tank" }),
			} },
			{ title = "Standing jobs", fields = {
				F("interrupt", "players", "Interrupts", { filter = "interrupt" }),
				F("magic", "players", "Magic dispels", { filter = "magic" }),
				F("curse", "players", "Curse removal", { filter = "curse" }),
				F("fear1", "pair", "Fear protection", { filter = "fear", target = "tank" }),
				F("fear2", "pair", "Fear protection", { filter = "fear", target = "tank" }),
				F("notes", "text", "Raid notes"),
			} },
		},
	}
end

function T.Trash()
	local cc = {}
	for i = 1, 4 do
		cc[i] = F("cc" .. i, "markplayer", "Crowd control", { filter = "cc" })
	end
	return {
		hint = "Crowd control and kill order for trash pulls.",
		sections = {
			{ title = "Crowd control", fields = cc },
			{ title = "Pulls", fields = {
				F("interrupt", "players", "Interrupts", { filter = "interrupt", inherit = "interrupt" }),
				F("helper", "player", "Pull helper", { renamable = true }),
				F("order", "text", "Kill order"),
			} },
		},
	}
end

local TANK_DEFAULTS = { "mt", "ot1", "ot2" }

-- Generic boss sheet: one target section per entry in boss.targets (default one), then ability
-- and utility rows. Used for new raids until their mechanics are known.
function T.Boss(boss)
	local sections = {}
	for i, target in ipairs(boss.targets or { "Boss" }) do
		local p = "t" .. i
		sections[i] = { title = target, fields = {
			F(p .. "tank", "markplayer", "Tank", { filter = "tank", inherit = TANK_DEFAULTS[i] }),
			F(p .. "heal", "players", "Healers", { filter = "healer" }),
			F(p .. "helper", "player", "Pull helper", { renamable = true }),
		} }
	end
	sections[#sections + 1] = { title = "Abilities", fields = {
		F("interrupt", "players", "Interrupts", { filter = "interrupt", inherit = "interrupt" }),
		F("magic", "players", "Magic dispels", { filter = "magic", inherit = "magic" }),
		F("curse", "players", "Curse removal", { filter = "curse", inherit = "curse" }),
	} }
	sections[#sections + 1] = { title = "Utility", fields = { F("notes", "text", "Notes") } }
	return {
		hint = boss.hint or "Mechanics not confirmed yet: generic jobs only. Treat this sheet as provisional.",
		sections = sections,
	}
end

local function AddPage(raid, page, key, name)
	page.key, page.name = key, name
	raid.pages[#raid.pages + 1] = page
	raid.pageByKey[key] = page
end

-- Register a raid: { instanceID, name, size, bosses = { { encounterID, name, targets, hint, page } } }.
-- A boss without its own page gets the generic boss template.
function ns.RegisterRaid(raid)
	raid.pages, raid.pageByKey = {}, {}
	AddPage(raid, T.General(), "general", "General")
	AddPage(raid, T.Trash(), "trash", "Trash")
	for _, boss in ipairs(raid.bosses) do
		AddPage(raid, boss.page or T.Boss(boss), boss.encounterID, boss.name)
	end
	ns.raids[#ns.raids + 1] = raid
	ns.raidByID[raid.instanceID] = raid
end
