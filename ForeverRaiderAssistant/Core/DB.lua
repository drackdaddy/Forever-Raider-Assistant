--[[ Saved data: defaults for both SavedVariables, applied in one place on ADDON_LOADED.
Events: ADDON_LOADED.
SavedVariables:
  FRA_DB (account): schema, roleTags[fullName] = "MT"|"OT"|"HEALER",
    plans[instanceID].pages[pageKey] = { values = {}, labels = {}, variant = key }
  FRA_CharDB (character): schema, ui = { screen, point, raid, page, phase }, minimapAngle ]]

local addonName, ns = ...

local SCHEMA = 1

local DB_DEFAULTS = {
	roleTags = {},
	plans = {},
}

local CHAR_DEFAULTS = {
	ui = { screen = "home" },
	minimapAngle = 225,
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
