--[[ Plan storage: read and write sheet values, renamed slot labels and the chosen variant for each
raid page. Boss and Trash fields with an "inherit" key show the General value until they set their own.
Writes that change nothing are skipped, so views are not redrawn for them. Every change redraws the
sheet and the sidebar (whose page badges count filled slots).
Events: none. SavedVariables: FRA_DB.plans[instanceID].pages[pageKey] = { values, labels, variant }. ]]

local _, ns = ...

local Plan = {}
ns.Plan = Plan

-- Saved data for one page; with create, builds the tables that are missing.
local function PageData(raid, key, create)
	local raidData = ns.db.plans[raid.instanceID]
	if not raidData then
		if not create then return nil end
		raidData = { pages = {} }
		ns.db.plans[raid.instanceID] = raidData
	end
	local page = raidData.pages[key]
	if not page and create then
		page = { values = {}, labels = {} }
		raidData.pages[key] = page
	end
	return page
end

-- Redraw the views that show plan data.
local function Changed()
	ns.MarkDirty("raids")
	ns.MarkDirty("nav")
end

local function IsEmpty(v)
	return v == nil or v == "" or (type(v) == "table" and next(v) == nil)
end

-- Values are strings, numbers or flat tables, so a one-level comparison is enough.
local function Same(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, v in pairs(a) do
		if b[k] ~= v then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

-- Returns the field's value and true when that value is inherited from the General page.
function Plan.Get(raid, page, field)
	local data = PageData(raid, page.key)
	local value = data and data.values[field.id]
	if value == nil and field.inherit and page.key ~= "general" then
		local general = PageData(raid, "general")
		value = general and general.values[field.inherit]
		return value, value ~= nil
	end
	return value, false
end

-- Store value (always a new table for table values); empty values clear the field.
function Plan.Set(raid, page, field, value)
	if IsEmpty(value) then value = nil end
	local data = PageData(raid, page.key, value ~= nil)
	if not data or Same(data.values[field.id], value) then return end
	data.values[field.id] = value
	Changed()
end

-- Number of fields on the page with their own value (inherited values are not counted).
function Plan.Count(raid, page)
	local data = PageData(raid, page.key)
	local count = 0
	for _ in pairs(data and data.values or {}) do
		count = count + 1
	end
	return count
end

function Plan.Label(raid, page, field)
	local data = PageData(raid, page.key)
	return data and data.labels[field.id] or field.label
end

-- Rename a renamable slot; an empty name or the template name restores the default.
function Plan.SetLabel(raid, page, field, text)
	if text == "" or text == field.label then text = nil end
	local data = PageData(raid, page.key, text ~= nil)
	if not data or data.labels[field.id] == text then return end
	data.labels[field.id] = text
	Changed()
end

-- Selected variant key for a page with variants (the first one by default).
function Plan.Variant(raid, page)
	local data = PageData(raid, page.key)
	return data and data.variant or page.variants[1].key
end

function Plan.SetVariant(raid, page, key)
	local data = PageData(raid, page.key, true)
	if data.variant == key then return end
	data.variant = key
	Changed()
end

-- Clear every value on one page. Renamed labels and the variant stay.
function Plan.ClearPage(raid, page)
	local data = PageData(raid, page.key)
	if data then
		wipe(data.values)
		Changed()
	end
end

-- Clear every value on every page of the raid.
function Plan.ClearRaid(raid)
	local raidData = ns.db.plans[raid.instanceID]
	if raidData then
		for _, data in pairs(raidData.pages) do
			wipe(data.values)
		end
		Changed()
	end
end

-- Return a page to its template: values, renamed labels and variant are all dropped.
function Plan.ResetPage(raid, page)
	local raidData = ns.db.plans[raid.instanceID]
	if raidData and raidData.pages[page.key] then
		raidData.pages[page.key] = nil
		Changed()
	end
end
