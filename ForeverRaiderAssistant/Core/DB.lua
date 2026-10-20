--[[ Saved data: defaults for both SavedVariables, applied in one place on ADDON_LOADED.
Events: ADDON_LOADED.
SavedVariables:
  FRA_DB (account): schema, roleTags[fullName] = "MT"|"OT"|"HEALER",
    plans[instanceID].pages[pageKey] = { values = {}, labels = {}, variant = key },
    tools (same shape as the character's; created the first time a character switches to it)
  FRA_CharDB (character): schema, ui = { screen, point, raid, page, phase }, minimapAngle,
    tools = { autoLog, autoInvite, inviteWords = "comma, separated" }, toolsScope = "char"|"account"
New fields come from the defaults on load, so older saved data needs no other upgrade. ]]

local addonName, ns = ...

local SCHEMA = 1

local DB_DEFAULTS = {
	roleTags = {},
	plans = {},
}

local CHAR_DEFAULTS = {
	ui = { screen = "home" },
	minimapAngle = 225,
	tools = { autoLog = false, autoInvite = false, inviteWords = "inv, invite" },
	toolsScope = "char",
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

ns.On("ADDON_LOADED", function(_, name)
	if name ~= addonName then return end
	FRA_DB = Fill(FRA_DB or {}, DB_DEFAULTS)
	FRA_DB.schema = FRA_DB.schema or SCHEMA
	FRA_CharDB = Fill(FRA_CharDB or {}, CHAR_DEFAULTS)
	FRA_CharDB.schema = FRA_CharDB.schema or SCHEMA
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
