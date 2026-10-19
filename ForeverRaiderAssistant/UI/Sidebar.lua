--[[ Sidebar: Home, then every raid in the catalog. The open raid expands into its General, Trash and
boss pages, and each page shows how many of its slots are filled. Clicking a page opens its
assignments on the Raids screen; clicking another raid opens its General page. Clicking the open
raid's header folds or unfolds it (remembered for this session only).
Events: none (redrawn through ns.MarkDirty("nav")). SavedVariables: reads FRA_CharDB.ui. ]]

local _, ns = ...

local C = ns.Colors
local folded = false

local function OnClick(button)
	local item, ui = button.item, ns.char.ui
	if item.kind == "home" then
		ns.ShowScreen("home")
	elseif item.kind == "raid" and ui.screen == "raids" and ui.raid == item.raid.instanceID then
		folded = not folded
		ns.MarkDirty("nav")
	else
		folded = false
		ns.SelectPage(item.raid.instanceID, item.page and item.page.key)
	end
end

-- Pooled row setup. Rows are reused for every kind, so each call sets every part it touches.
local function InitRow(button, item)
	if not button.text then
		ns.StyleListButton(button)
		button.badge = ns.Text(button, "GameFontHighlightSmall", C.dim)
		button.badge:SetPoint("RIGHT", -10, 0)
		button:SetScript("OnClick", OnClick)
	end
	button.item = item
	local ui = ns.char.ui
	local text
	local badge, color, selected = "", C.text, false
	if item.kind == "home" then
		text, selected = "Home", ui.screen == "home"
	elseif item.kind == "label" then
		text, color = "RAIDS", C.dim
	elseif item.kind == "raid" then
		text, badge = item.raid.name, item.raid.size
		color = item.open and C.accent or C.text
	else
		local count = ns.Plan.Count(item.raid, item.page)
		text, badge = item.page.name, count > 0 and count or ""
		selected = ui.screen == "raids" and ui.page == item.page.key
	end
	button:EnableMouse(item.kind ~= "label")
	button.text:SetFontObject(item.kind == "page" and "GameFontHighlightSmall" or "GameFontHighlight")
	button.text:SetPoint("LEFT", item.kind == "page" and 24 or 12, 0)
	button.text:SetPoint("RIGHT", -34, 0)
	button.text:SetText(text)
	button.text:SetTextColor(unpack(color))
	button.badge:SetText(badge)
	ns.SetSelected(button, selected)
end

local function Refresh(self)
	local ui = ns.char.ui
	local open = ns.raidByID[ui.raid] or ns.raids[1]
	local items = { { kind = "home" }, { kind = "label" } }
	for _, raid in ipairs(ns.raids) do
		local expanded = raid == open and not folded
		items[#items + 1] = { kind = "raid", raid = raid, open = expanded }
		if expanded then
			for _, page in ipairs(raid.pages) do
				items[#items + 1] = { kind = "page", raid = raid, page = page }
			end
		end
	end
	self.scrollBox:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants.RetainScrollPosition)
end

-- Build the sidebar list inside parent (the main window's left column).
function ns.BuildSidebar(parent)
	local view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh
	view.scrollBox = CreateFrame("Frame", nil, view, "WowScrollBoxList")
	view.scrollBox:SetPoint("TOPLEFT", 0, -8)
	view.scrollBox:SetPoint("BOTTOMRIGHT", -12, 8)
	local scrollBar = CreateFrame("EventFrame", nil, view, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", view.scrollBox, "TOPRIGHT", 2, 0)
	scrollBar:SetPoint("BOTTOMLEFT", view.scrollBox, "BOTTOMRIGHT", 2, 0)
	local listView = CreateScrollBoxListLinearView()
	listView:SetElementExtent(26)
	listView:SetElementInitializer("Button", InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(view.scrollBox, scrollBar, listView)
	ns.RegisterView("nav", view)
end
