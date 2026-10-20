--[[ Saved data: migrations from older versions, then defaults for both SavedVariables, applied in one
place on ADDON_LOADED.
Events: ADDON_LOADED.
SavedVariables:
  FRA_DB (account): schema, roleTags[fullName] = "MT"|"OT"|"HEALER",
    tools (same shape as the character's; created the first time a character switches to it),
    notes[key] (see Core/Notes.lua)
  FRA_CharDB (character): schema, ui = { screen, point, note }, minimapAngle,
    noteWindow = { point, width, height },
    tools = { autoLog, autoInvite, inviteWords = "comma, separated" }, toolsScope = "char"|"account"
New fields come from the defaults on load; removed fields are deleted by a migration step. ]]

local addonName, ns = ...

local SCHEMA = 2

local DB_DEFAULTS = {
	roleTags = {},
	notes = {},
}

local CHAR_DEFAULTS = {
	ui = { screen = "home" },
	minimapAngle = 225,
	tools = { autoLog = false, autoInvite = false, inviteWords = "inv, invite" },
	toolsScope = "char",
	noteWindow = { width = 320, height = 240 },
}

-- Copy every default that is missing from t, recursing into tables. Existing values are kept.
local function Fill(t, defaults)
	for k, v in pairs(defaults) do
		if t[k] == nil then
			t[k] = type(v) == "table" and Fill({}, v) or v
		elseif type(v) == "table" and type(t[k]) == "table" then
			Fill(t[k], v)
		end
	end
	return t
end

-- Upgrade account data saved by older versions. Data without a schema is new, so already current.
local function MigrateAccount(db)
	if (db.schema or SCHEMA) < 2 then
		-- 0.6.0 removed raid planning; the saved raid plans are deleted, as chosen by the author.
		db.plans = nil
	end
	db.schema = SCHEMA
end

-- Upgrade character data saved by older versions.
local function MigrateChar(char)
	if (char.schema or SCHEMA) < 2 and char.ui then
		-- 0.6.0 removed the Raids screen and its selected raid, page and phase.
		char.ui.raid, char.ui.page, char.ui.phase = nil, nil, nil
		if char.ui.screen == "raids" then char.ui.screen = "home" end
	end
	char.schema = SCHEMA
end

ns.On("ADDON_LOADED", function(_, name)
	if name ~= addonName then return end
	FRA_DB = FRA_DB or {}
	MigrateAccount(FRA_DB)
	Fill(FRA_DB, DB_DEFAULTS)
	FRA_CharDB = FRA_CharDB or {}
	MigrateChar(FRA_CharDB)
	Fill(FRA_CharDB, CHAR_DEFAULTS)
	ns.db, ns.char = FRA_DB, FRA_CharDB
end)

-- The tools settings this character uses: its own, or the account-wide ones.
function ns.Tools()
	return ns.char.toolsScope == "account" and ns.db.tools or ns.char.tools
end

-- Switch this character between "char" and "account" tools settings. The account settings start
-- as a copy of this character's the first time any character switches to them.
function ns.SetToolsScope(scope)
	if scope == "account" and not ns.db.tools then
		ns.db.tools = CopyTable(ns.char.tools)
	end
	ns.char.toolsScope = scope
end
