--[[ Field widgets: one pooled row per sheet field, built once per field type and reused on redraw.
Types: player, players, pair, markplayer, choice, text (see Core/Catalog.lua).
Left-click a slot to pick, right-click to clear. Inherited values are tagged "(General)".
Renamable slots (white labels) rename by clicking their label.
Events: none. SavedVariables: FRA_DB.plans through ns.Plan. ]]

local _, ns = ...

local Plan, C = ns.Plan, ns.Colors
local Fields = {}
ns.Fields = Fields

local LABEL_WIDTH, ROW_WIDTH, VALUE_X = 170, 586, 180
local EMPTY = "|cff4d525c-|r"

local Build, Update = {}, {}
local pools = {}

-- Display text for an assigned player: class-colored when in the group, grey when absent.
local function PlayerText(name)
	if not name then return EMPTY end
	local member = ns.Roster.byName[name]
	return ns.ColorName(name, member and member.class, not (member and member.online))
end

local function Tagged(text, inherited)
	return inherited and (text .. "  |cff8c94a3(General)|r") or text
end

-- The row's raid, page and field are read at click time because rows are pooled and reused.
local function Context(row)
	return row.raid, row.page, row.field
end

-- Copy a table value (or start a new one) so Plan.Set always receives a fresh table.
local function Copy(value)
	local copy = {}
	for k, v in pairs(value or {}) do
		copy[k] = v
	end
	return copy
end

-- Label renaming ---------------------------------------------------------------

local function FinishRename(edit)
	local row = edit:GetParent()
	edit:Hide()
	row.label:Show()
	if edit.cancelled then
		edit.cancelled = nil
		return
	end
	local raid, page, field = Context(row)
	Plan.SetLabel(raid, page, field, strtrim(edit:GetText()))
end

local function StartRename(label)
	local row = label:GetParent()
	local edit = row.labelEdit
	if not edit then
		edit = ns.CreateEditBox(row, LABEL_WIDTH - 10)
		edit:SetPoint("LEFT")
		edit:SetMaxLetters(40)
		edit:SetScript("OnEnterPressed", edit.ClearFocus)
		edit:SetScript("OnEscapePressed", function(self)
			self.cancelled = true
			self:ClearFocus()
		end)
		edit:HookScript("OnEditFocusLost", FinishRename)
		row.labelEdit = edit
	end
	label:Hide()
	edit:SetText(label.text:GetText())
	edit:Show()
	edit:SetFocus()
	edit:HighlightText()
end

local function ShowRenameTip(label)
	GameTooltip:SetOwner(label, "ANCHOR_TOPLEFT")
	GameTooltip:SetText("Click to rename this slot.")
	GameTooltip:Show()
end

local function BuildBase(row)
	row:SetSize(ROW_WIDTH, 22)
	local label = CreateFrame("Button", nil, row)
	label:SetSize(LABEL_WIDTH, 22)
	label:SetPoint("LEFT")
	label.text = ns.Text(label)
	label.text:SetAllPoints()
	label.text:SetWordWrap(false)
	label:SetScript("OnClick", StartRename)
	label:SetScript("OnEnter", ShowRenameTip)
	label:SetScript("OnLeave", GameTooltip_Hide)
	row.label = label
end

-- Player slots -----------------------------------------------------------------

-- Open the picker for the player stored under key in a table value (pair and markplayer types).
local function PickPart(button, key, filter)
	local raid, page, field = Context(button:GetParent())
	local value = Plan.Get(raid, page, field)
	local current = value and value[key]
	ns.OpenPicker(button, {
		filter = filter,
		selected = current and { [current] = true } or {},
		onPick = function(name)
			local new = Copy(value)
			new[key] = name
			Plan.Set(raid, page, field, new)
		end,
	})
end

-- Clear a part of a table value (right-click on pair and markplayer slots).
local function ClearPart(button, key)
	local raid, page, field = Context(button:GetParent())
	local new = Copy(Plan.Get(raid, page, field))
	new[key] = nil
	Plan.Set(raid, page, field, new)
end

function Build.player(row)
	row.value = ns.CreateValueButton(row, 260)
	row.value:SetPoint("LEFT", VALUE_X, 0)
	row.value:SetScript("OnClick", function(self, button)
		local raid, page, field = Context(row)
		if button == "RightButton" then
			Plan.Set(raid, page, field, nil)
			return
		end
		local current = Plan.Get(raid, page, field)
		ns.OpenPicker(self, {
			filter = field.filter,
			selected = current and { [current] = true } or {},
			onPick = function(name) Plan.Set(raid, page, field, name) end,
		})
	end)
end

function Update.player(row)
	local value, inherited = Plan.Get(Context(row))
	row.value.text:SetText(Tagged(PlayerText(value), inherited))
end

function Build.players(row)
	row.value = ns.CreateValueButton(row, 400)
	row.value:SetPoint("LEFT", VALUE_X, 0)
	row.value:SetScript("OnClick", function(self, button)
		local raid, page, field = Context(row)
		if button == "RightButton" then
			Plan.Set(raid, page, field, nil)
			return
		end
		local selected = {}
		for _, name in ipairs(Plan.Get(raid, page, field) or {}) do
			selected[name] = true
		end
		ns.OpenPicker(self, {
			filter = field.filter,
			multi = true,
			selected = selected,
			onPick = function(list) Plan.Set(raid, page, field, list) end,
		})
	end)
end

function Update.players(row)
	local value, inherited = Plan.Get(Context(row))
	local names = {}
	for i, name in ipairs(value or {}) do
		names[i] = PlayerText(name)
	end
	row.value.text:SetText(Tagged(#names > 0 and table.concat(names, ", ") or EMPTY, inherited))
end

function Build.pair(row)
	row.a = ns.CreateValueButton(row, 180)
	row.a:SetPoint("LEFT", VALUE_X, 0)
	row.on = ns.Text(row, "GameFontHighlightSmall", C.dim)
	row.on:SetPoint("LEFT", row.a, "RIGHT", 8, 0)
	row.on:SetText("on")
	row.b = ns.CreateValueButton(row, 180)
	row.b:SetPoint("LEFT", row.on, "RIGHT", 8, 0)
	row.a:SetScript("OnClick", function(self, button)
		if button == "RightButton" then return ClearPart(self, "a") end
		PickPart(self, "a", row.field.filter)
	end)
	row.b:SetScript("OnClick", function(self, button)
		if button == "RightButton" then return ClearPart(self, "b") end
		PickPart(self, "b", row.field.target)
	end)
end

function Update.pair(row)
	local value, inherited = Plan.Get(Context(row))
	value = value or {}
	row.a.text:SetText(PlayerText(value.a))
	row.b.text:SetText(Tagged(PlayerText(value.b), inherited))
end

-- Raid marker plus player ------------------------------------------------------

local function SetMarker(button, index)
	local raid, page, field = Context(button:GetParent())
	local new = Copy(Plan.Get(raid, page, field))
	new.m = index
	Plan.Set(raid, page, field, new)
end

local function MarkerMenu(button)
	MenuUtil.CreateContextMenu(button, function(_, root)
		root:CreateTitle("Raid marker")
		for i = 1, 8 do
			root:CreateButton(ns.MarkerIcon(i, 14) .. " " .. _G["RAID_TARGET_" .. i], function() SetMarker(button, i) end)
		end
		root:CreateButton(NONE, function() SetMarker(button, nil) end)
	end)
end

function Build.markplayer(row)
	row.mark = ns.CreateValueButton(row, 26)
	row.mark:SetPoint("LEFT", VALUE_X, 0)
	row.mark.text:SetJustifyH("CENTER")
	row.mark.text:SetPoint("LEFT", 0, 0)
	row.mark.text:SetPoint("RIGHT", 0, 0)
	row.mark:SetScript("OnClick", function(self, button)
		if button == "RightButton" then return SetMarker(self, nil) end
		MarkerMenu(self)
	end)
	row.value = ns.CreateValueButton(row, 230)
	row.value:SetPoint("LEFT", row.mark, "RIGHT", 4, 0)
	row.value:SetScript("OnClick", function(self, button)
		if button == "RightButton" then return ClearPart(self, "p") end
		PickPart(self, "p", row.field.filter)
	end)
end

function Update.markplayer(row)
	local value, inherited = Plan.Get(Context(row))
	value = value or {}
	row.mark.text:SetText(value.m and ns.MarkerIcon(value.m, 16) or EMPTY)
	row.value.text:SetText(Tagged(PlayerText(value.p), inherited))
end

-- Fixed-choice dropdown --------------------------------------------------------

function Build.choice(row)
	row.value = ns.CreateValueButton(row, 220)
	row.value:SetPoint("LEFT", VALUE_X, 0)
	row.value:SetScript("OnClick", function(self, button)
		local raid, page, field = Context(row)
		if button == "RightButton" then
			Plan.Set(raid, page, field, nil)
			return
		end
		MenuUtil.CreateContextMenu(self, function(_, root)
			for _, option in ipairs(field.options) do
				root:CreateRadio(option.text,
					function() return Plan.Get(raid, page, field) == option.key end,
					function() Plan.Set(raid, page, field, option.key) end)
			end
		end)
	end)
end

function Update.choice(row)
	local value, inherited = Plan.Get(Context(row))
	local text = EMPTY
	for _, option in ipairs(row.field.options) do
		if option.key == value then text = option.text end
	end
	row.value.text:SetText(Tagged(text, inherited))
end

-- Free text --------------------------------------------------------------------

function Build.text(row)
	local edit = ns.CreateEditBox(row, 400)
	edit:SetPoint("LEFT", VALUE_X, 0)
	edit:SetMaxLetters(200)
	edit:SetScript("OnEnterPressed", edit.ClearFocus)
	edit:SetScript("OnEscapePressed", function(self)
		self:SetText(row.saved)
		self:ClearFocus()
	end)
	edit:HookScript("OnEditFocusLost", function(self)
		local raid, page, field = Context(row)
		Plan.Set(raid, page, field, strtrim(self:GetText()))
	end)
	row.edit = edit
end

function Update.text(row)
	row.saved = Plan.Get(Context(row)) or ""
	if not row.edit:HasFocus() then
		row.edit:SetText(row.saved)
	end
end

-- Pooling ----------------------------------------------------------------------

-- Get a row for field on raid page, built for its type and filled with the current value.
function Fields.Acquire(parent, raid, page, field)
	local pool = pools[field.type]
	if not pool then
		pool = CreateFramePool("Frame", parent)
		pools[field.type] = pool
	end
	local row, isNew = pool:Acquire()
	if isNew then
		BuildBase(row)
		Build[field.type](row)
	end
	row.raid, row.page, row.field = raid, page, field
	row.label.text:SetText(Plan.Label(raid, page, field))
	row.label:EnableMouse(field.renamable or false)
	row.label.text:SetTextColor(unpack(field.renamable and C.text or C.dim))
	row.label:Show()
	if row.labelEdit then row.labelEdit:Hide() end
	Update[field.type](row)
	return row
end

function Fields.ReleaseAll()
	for _, pool in pairs(pools) do
		pool:ReleaseAll()
	end
end
