--[[ Note window: shows pushed notes, one tab per note, newest tab selected. It can be moved by its
title bar and resized from the corner grip, and it remembers both. Each tab has its own close
button; closing the window closes every tab. "Open in Quick Notes" shows the note in the main window.
Events: none (redrawn through ns.MarkDirty("noteWindow")). SavedVariables: FRA_CharDB.noteWindow. ]]

local _, ns = ...

local C = ns.Colors

local TITLE_HEIGHT, TAB_HEIGHT, MAX_TAB_WIDTH = 28, 24, 140

local window
local open = {} -- keys of the notes with a tab, in the order they arrived
local active -- key of the selected tab
local tabButtons = {}

-- Remember the top-left corner and size.
local function SaveGeometry()
	window:StopMovingOrSizing()
	local saved = ns.char.noteWindow
	saved.point = { window:GetLeft(), window:GetTop() }
	saved.width, saved.height = window:GetSize()
	window:ClearAllPoints()
	window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.point[1], saved.point[2])
end

local function Close()
	wipe(open)
	active = nil
	window:Hide()
end

local function CloseTab(key)
	for i, k in ipairs(open) do
		if k == key then
			table.remove(open, i)
			if active == key then active = open[i] or open[i - 1] end
			break
		end
	end
	if #open == 0 then Close() else ns.MarkDirty("noteWindow") end
end

local function TabButton(index)
	local tab = tabButtons[index]
	if not tab then
		tab = ns.CreateListButton(window, MAX_TAB_WIDTH, TAB_HEIGHT)
		tab.text:SetPoint("RIGHT", -22, 0)
		tab.close = ns.CreateIconButton(tab, "close")
		tab.close:SetSize(20, 20)
		tab.close:SetPoint("RIGHT", -1, 0)
		tab.close:SetScript("OnClick", function() CloseTab(tab.key) end)
		tab:SetScript("OnClick", function()
			active = tab.key
			ns.MarkDirty("noteWindow")
		end)
		tabButtons[index] = tab
	end
	return tab
end

local function Refresh(self)
	for i = #open, 1, -1 do
		if not ns.Notes.Get(open[i]) then CloseTab(open[i]) end
	end
	if #open == 0 then return end
	local width = math.min(MAX_TAB_WIDTH, math.floor((self:GetWidth() - 12) / #open))
	for i, key in ipairs(open) do
		local tab = TabButton(i)
		tab.key = key
		tab:SetWidth(width)
		tab:SetPoint("TOPLEFT", 6 + (i - 1) * width, -TITLE_HEIGHT - 2)
		tab.text:SetText(ns.Notes.Get(key).title)
		ns.SetSelected(tab, key == active)
		tab:Show()
	end
	for i = #open + 1, #tabButtons do
		tabButtons[i]:Hide()
	end

	local note = ns.Notes.Get(active)
	self.from:SetText(note.from and ("From %s"):format(Ambiguate(note.from, "short")) or "Your note")
	local textWidth = self.scroll:GetWidth()
	self.child:SetWidth(textWidth)
	self.body:SetWidth(textWidth)
	self.body:SetText(note.body)
	self.child:SetHeight(self.body:GetStringHeight() + 24)
end

local function Build()
	window = CreateFrame("Frame", "FRANoteWindow", UIParent, "BackdropTemplate")
	ns.StylePanel(window)
	local saved = ns.char.noteWindow
	window:SetSize(saved.width, saved.height)
	if saved.point then
		window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.point[1], saved.point[2])
	else
		window:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
	end
	window:SetFrameStrata("HIGH")
	window:SetToplevel(true)
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:SetResizable(true)
	window:SetResizeBounds(240, 160, 900, 700)
	window:EnableMouse(true)
	window:SetDontSavePosition(true)
	window.Refresh = Refresh
	window:SetScript("OnSizeChanged", function() ns.MarkDirty("noteWindow") end)

	local bar = CreateFrame("Frame", nil, window)
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("TOPRIGHT", -1, -1)
	bar:SetHeight(TITLE_HEIGHT)
	ns.Fill(bar, C.titlebar)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function() window:StartMoving() end)
	bar:SetScript("OnDragStop", SaveGeometry)
	local title = ns.Text(bar, "GameFontHighlight")
	title:SetPoint("LEFT", 10, 0)
	title:SetText("Quick Notes")
	local close = ns.CreateIconButton(bar, "close")
	close:SetPoint("RIGHT", 0, 0)
	close:SetScript("OnClick", Close)

	window.from = ns.Text(window, "GameFontHighlightSmall", C.dim)
	window.from:SetPoint("TOPLEFT", 12, -TITLE_HEIGHT - TAB_HEIGHT - 10)

	window.scroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
	window.scroll:SetPoint("TOPLEFT", window.from, "BOTTOMLEFT", 0, -6)
	window.scroll:SetPoint("BOTTOMRIGHT", -26, 40)
	window.child = CreateFrame("Frame", nil, window.scroll)
	window.child:SetSize(1, 1)
	window.scroll:SetScrollChild(window.child)
	window.body = ns.Text(window.child, "GameFontHighlight")
	window.body:SetPoint("TOPLEFT")
	window.body:SetJustifyV("TOP")

	local goTo = ns.CreateButton(window, "Open in Quick Notes", 140)
	goTo:SetPoint("BOTTOMLEFT", 10, 10)
	goTo:SetScript("OnClick", function() ns.OpenNote(active) end)

	local grip = CreateFrame("Button", nil, window)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", SaveGeometry)

	ns.RegisterView("noteWindow", window)
end

-- Open key in the note window: add its tab if it has none, select it, and show the window.
function ns.ShowNoteTab(key)
	if not window then Build() end
	if not tContains(open, key) then open[#open + 1] = key end
	active = key
	window:Show()
	ns.MarkDirty("noteWindow")
end
