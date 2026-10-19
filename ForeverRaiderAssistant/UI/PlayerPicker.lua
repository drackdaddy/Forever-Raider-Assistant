--[[ Searchable player dropdown: lists eligible roster members, class-colored, with the raid marker
they wear. Type to filter. Single mode picks one player and closes; multi mode toggles players and
saves each change. Assigned players who left the group stay listed (greyed) so they can be removed.
Events: none. SavedVariables: none (callers save through ns.Plan). ]]

local _, ns = ...

local picker
local opts -- { filter, multi, selected = { [name] = true }, onPick = fn(name or list) }

-- Marker icons are skipped in combat: unit state may be a restricted (secret) value there,
-- and the addon never reads those.
local function Label(name, member)
	local text = ns.ColorName(name, member and member.class, not (member and member.online))
	local marker = member and not InCombatLockdown() and GetRaidTargetIndex(member.unit)
	return marker and (ns.MarkerIcon(marker, 14) .. " " .. text) or text
end

local function Matches(name, query)
	return query == "" or strlower(Ambiguate(name, "short")):find(query, 1, true) ~= nil
end

local function Rebuild()
	local query = strlower(picker.search:GetText())
	local items, listed = {}, {}
	for _, member in ipairs(ns.Roster.list) do
		if ns.Eligible(member, opts.filter) and Matches(member.name, query) then
			listed[member.name] = true
			items[#items + 1] = { name = member.name, label = Label(member.name, member) }
		end
	end
	for name in pairs(opts.selected) do
		if not listed[name] and Matches(name, query) then
			items[#items + 1] = { name = name, label = Label(name, ns.Roster.byName[name]) }
		end
	end
	table.sort(items, function(a, b) return a.name < b.name end)
	for _, item in ipairs(items) do
		item.selected = opts.selected[item.name]
	end
	picker.scrollBox:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants.RetainScrollPosition)
	picker.empty:SetText(query ~= "" and "No match."
		or ("Nobody in the group qualifies (%s)."):format(ns.FilterLabel(opts.filter)))
	picker.empty:SetShown(#items == 0)
end

local function SelectedList()
	local list = {}
	for name in pairs(opts.selected) do
		list[#list + 1] = name
	end
	table.sort(list)
	return list
end

local function Pick(name)
	if opts.multi then
		opts.selected[name] = not opts.selected[name] or nil
		opts.onPick(SelectedList())
		Rebuild()
	else
		picker:Hide()
		opts.onPick(name)
	end
end

local function Clear()
	if opts.multi then
		wipe(opts.selected)
		opts.onPick({})
		Rebuild()
	else
		picker:Hide()
		opts.onPick(nil)
	end
end

-- Pooled entry setup; picked players get the accent bar and tint.
local function InitEntry(button, item)
	if not button.text then
		ns.StyleListButton(button)
		button:SetScript("OnClick", function(self) Pick(self.name) end)
	end
	button.name = item.name
	button.text:SetText(item.label)
	ns.SetSelected(button, item.selected or false)
end

local function Build()
	picker = CreateFrame("Frame", "FRAPlayerPicker", UIParent, "BackdropTemplate")
	ns.StylePanel(picker)
	picker:SetBackdropBorderColor(unpack(ns.Colors.accent))
	picker:SetSize(240, 320)
	picker:SetFrameStrata("DIALOG")
	picker:SetToplevel(true)
	picker:SetClampedToScreen(true)
	picker:EnableMouse(true)
	tinsert(UISpecialFrames, "FRAPlayerPicker")

	picker.title = ns.Text(picker, "GameFontHighlight")
	picker.title:SetPoint("TOPLEFT", 12, -12)

	local close = ns.CreateIconButton(picker, "close")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() picker:Hide() end)

	picker.search = CreateFrame("EditBox", nil, picker, "SearchBoxTemplate")
	picker.search:SetSize(200, 20)
	picker.search:SetPoint("TOPLEFT", 16, -36)
	picker.search:SetAutoFocus(false)
	picker.search:HookScript("OnTextChanged", function()
		if picker:IsShown() then Rebuild() end
	end)

	picker.scrollBox = CreateFrame("Frame", nil, picker, "WowScrollBoxList")
	picker.scrollBox:SetPoint("TOPLEFT", 8, -64)
	picker.scrollBox:SetPoint("BOTTOMRIGHT", -24, 44)
	local scrollBar = CreateFrame("EventFrame", nil, picker, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", picker.scrollBox, "TOPRIGHT", 6, 0)
	scrollBar:SetPoint("BOTTOMLEFT", picker.scrollBox, "BOTTOMRIGHT", 6, 0)
	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(22)
	view:SetElementInitializer("Button", InitEntry)
	ScrollUtil.InitScrollBoxListWithScrollBar(picker.scrollBox, scrollBar, view)

	picker.empty = ns.Text(picker, "GameFontHighlightSmall", ns.Colors.dim)
	picker.empty:SetPoint("TOPLEFT", picker.scrollBox, 8, -6)
	picker.empty:SetPoint("RIGHT", picker.scrollBox, -4, 0)

	local clear = ns.CreateButton(picker, "Clear", 100)
	clear:SetPoint("BOTTOMLEFT", 12, 12)
	clear:SetScript("OnClick", Clear)

	picker.done = ns.CreateButton(picker, DONE, 100)
	picker.done:SetPoint("BOTTOMRIGHT", -12, 12)
	ns.SetActive(picker.done, true)
	picker.done:SetScript("OnClick", function() picker:Hide() end)
end

-- Open below anchor. The position is fixed at open time because sheet rows are pooled and may
-- move when the sheet redraws after a pick.
function ns.OpenPicker(anchor, options)
	if not picker then Build() end
	opts = options
	picker.title:SetText(ns.FilterLabel(options.filter))
	picker.done:SetShown(options.multi or false)
	picker.search:SetText("")
	local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
	picker:ClearAllPoints()
	picker:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", anchor:GetLeft() * scale, anchor:GetBottom() * scale - 2)
	picker:Show()
	picker:Raise()
	Rebuild()
end

function ns.ClosePicker()
	if picker then picker:Hide() end
end
