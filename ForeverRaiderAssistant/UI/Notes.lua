--[[ Quick Notes screen: a list of your notes and the notes pushed to you (newest first), and an
editor for the selected note. Your own notes save as you type and can be pushed to the group by its
leader or an assistant; received notes are read-only. "Show" opens the note in the note window.
A row of marker buttons inserts target and ground marker codes at the cursor (see Core/Markers.lua).
Events: none (redrawn through ns.MarkDirty("notes")).
SavedVariables: FRA_CharDB.ui.note (selected note); FRA_DB.notes through ns.Notes. ]]

local _, ns = ...

local C, Notes = ns.Colors, ns.Notes

local LIST_WIDTH = 200
local STATUS = {
	sending = "Sending...",
	queued = "Queued: it sends when the boss encounter ends.",
	sent = "Sent to the group.",
	failed = "The game refused the message, so the note was not sent.",
	denied = "Only the group leader or a raid assistant can push notes.",
}

local view

-- Select note key. Focus leaves the editor first, so the next redraw fills it with that note's text
-- instead of keeping the text being typed into the previous note.
local function SelectNote(key)
	if view then
		view.title:ClearFocus()
		view.body:ClearFocus()
	end
	ns.char.ui.note = key
	ns.MarkDirty("notes")
end

-- Open key on the Quick Notes screen of the main window.
function ns.OpenNote(key)
	ns.ShowMain()
	ns.ShowScreen("notes")
	SelectNote(key)
end

local function Selected()
	return Notes.Get(ns.char.ui.note)
end

local function InitRow(button, note)
	if not button.text then
		ns.StyleListButton(button)
		button.badge = ns.Text(button, "GameFontHighlightSmall", C.dim)
		button.badge:SetPoint("RIGHT", -8, 0)
		button.text:SetPoint("RIGHT", -70, 0)
		button:SetScript("OnClick", function(self) SelectNote(self.key) end)
	end
	button.key = note.key
	button.text:SetText(ns.RenderMarkers(note.title, 12))
	button.badge:SetText(note.from and Ambiguate(note.from, "short") or "You")
	ns.SetSelected(button, note.key == ns.char.ui.note)
end

-- Fill an edit box from the note unless the player is typing in it.
local function SetIfIdle(edit, text)
	if not edit:HasFocus() then edit:SetText(text) end
end

local function Refresh(self)
	local list = Notes.List()
	if not Selected() then ns.char.ui.note = list[1] and list[1].key end
	self.scrollBox:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)

	local note = Selected()
	self.editor:SetShown(note ~= nil)
	self.empty:SetShown(note == nil)
	if not note then return end
	local mine = note.from == nil
	self.meta:SetText(mine and "Your note" or ("From %s, received %s"):format(Ambiguate(note.from, "short"),
		date("%b %d %H:%M", note.time)))
	SetIfIdle(self.title, note.title)
	SetIfIdle(self.body, note.body)
	self.title:SetEnabled(mine)
	self.body:SetEnabled(mine)
	self.count:SetText(("%d / %d"):format(strlenutf8(note.body), Notes.MAX_BODY))
	self.push:SetShown(mine)
	self.markerBar:SetShown(mine)
	self.status:SetText(mine and STATUS[Notes.status[note.key]] or "")
end

local function OnEdit(field)
	return function(edit, userInput)
		local note = Selected()
		if userInput and note and not note.from then
			Notes.Edit(note, field, edit:GetText())
		end
	end
end

-- Multi-line body editor in a scroll frame that keeps the cursor in view.
local function BuildBody(editor)
	local panel = CreateFrame("Frame", nil, editor, "BackdropTemplate")
	ns.StylePanel(panel, C.field)
	panel:SetPoint("TOPLEFT", 0, -74)
	panel:SetPoint("BOTTOMRIGHT", 0, 62)
	local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", -26, 8)
	local body = CreateFrame("EditBox", nil, scroll)
	body:SetMultiLine(true)
	body:SetAutoFocus(false)
	body:SetFontObject("GameFontHighlight")
	body:SetMaxLetters(Notes.MAX_BODY)
	body:SetWidth(380)
	scroll:SetScrollChild(body)
	scroll:SetScript("OnSizeChanged", function(self) body:SetWidth(self:GetWidth()) end)
	body:SetScript("OnEscapePressed", body.ClearFocus)
	body:SetScript("OnCursorChanged", function(_, _, y, _, height)
		local top, shown = scroll:GetVerticalScroll(), scroll:GetHeight()
		y = -y
		if y < top then
			scroll:SetVerticalScroll(y)
		elseif y + height > top + shown then
			scroll:SetVerticalScroll(y + height - shown)
		end
	end)
	body:SetScript("OnTextChanged", OnEdit("body"))
	panel:EnableMouse(true)
	panel:SetScript("OnMouseDown", function() if body:IsEnabled() then body:SetFocus() end end)
	return body
end

-- Insert a marker code at the body's cursor and save it (Insert is not reported as typing).
local function InsertCode(code)
	local note = Selected()
	if not note or note.from then return end
	view.body:SetFocus()
	view.body:Insert(code)
	Notes.Edit(note, "body", view.body:GetText())
end

local function ShowMarkerTip(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOP")
	GameTooltip:SetText(button.tip)
	GameTooltip:AddLine("Inserts " .. button.code, 1, 1, 1)
	GameTooltip:Show()
end

-- One button per target marker, a gap, then one per ground marker.
local function BuildMarkerBar(editor)
	local bar = CreateFrame("Frame", nil, editor)
	bar:SetPoint("TOPLEFT", 0, -46)
	bar:SetPoint("RIGHT")
	bar:SetHeight(22)
	local x = 0
	local function Add(code, tip, width)
		local button = CreateFrame("Button", nil, bar)
		button:SetSize(width, 22)
		button:SetPoint("LEFT", x, 0)
		ns.Fill(button, C.hover, "HIGHLIGHT")
		local icon = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		icon:SetPoint("CENTER")
		icon:SetText(ns.RenderMarkers(code, 16))
		button.code, button.tip = code, tip
		button:SetScript("OnEnter", ShowMarkerTip)
		button:SetScript("OnLeave", GameTooltip_Hide)
		button:SetScript("OnClick", function() InsertCode(code) end)
		x = x + width + 2
	end
	for i = 1, 8 do
		Add("{rt" .. i .. "}", "Target marker: " .. _G["RAID_TARGET_" .. i], 22)
	end
	x = x + 10
	for i, marker in ipairs(ns.GROUND_MARKERS) do
		Add("{wm" .. i .. "}", "Ground marker: " .. marker.name, 28)
	end
	return bar
end

local function BuildEditor()
	local editor = CreateFrame("Frame", nil, view)
	editor:SetPoint("TOPLEFT", LIST_WIDTH + 16, -56)
	editor:SetPoint("BOTTOMRIGHT")
	view.editor = editor

	view.meta = ns.Text(editor, "GameFontHighlightSmall", C.dim)
	view.meta:SetPoint("TOPLEFT", 0, -2)
	view.title = ns.CreateEditBox(editor, 10)
	view.title:SetPoint("TOPLEFT", 0, -18)
	view.title:SetPoint("RIGHT")
	view.title:SetMaxLetters(Notes.MAX_TITLE)
	view.title:SetScript("OnEnterPressed", view.title.ClearFocus)
	view.title:SetScript("OnEscapePressed", view.title.ClearFocus)
	view.title:SetScript("OnTextChanged", OnEdit("title"))
	view.markerBar = BuildMarkerBar(editor)
	view.body = BuildBody(editor)

	view.count = ns.Text(editor, "GameFontHighlightSmall", C.dim)
	view.count:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 0, 56)
	view.status = ns.Text(editor, "GameFontHighlightSmall", C.dim)
	view.status:SetPoint("LEFT", view.count, "RIGHT", 16, 0)
	view.status:SetPoint("RIGHT")

	view.push = ns.CreateButton(editor, "Push to group", 120)
	view.push:SetPoint("BOTTOMLEFT", 0, 2)
	ns.SetActive(view.push, true)
	view.push:SetScript("OnClick", function()
		local note = Selected()
		if not ns.Comm.CanSend() then
			Notes.status[note.key] = "denied"
			ns.MarkDirty("notes")
			return
		end
		Notes.Push(note)
	end)
	local show = ns.CreateButton(editor, "Show", 90)
	show:SetPoint("LEFT", view.push, "RIGHT", 6, 0)
	show:SetScript("OnClick", function() ns.ShowNoteTab(Selected().key) end)
	local delete = ns.CreateButton(editor, "Delete", 90)
	delete:SetPoint("BOTTOMRIGHT", 0, 2)
	delete:SetScript("OnClick", function()
		local note = Selected()
		ns.Confirm(("Delete the note \"%s\"?"):format(note.title), function() Notes.Delete(note.key) end)
	end)
end

ns.screenBuilders.notes = function(parent)
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh

	local title = ns.Text(view, "GameFontHighlightLarge")
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetText("Quick Notes")
	local subtitle = ns.Text(view, "GameFontHighlightSmall", C.dim)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	subtitle:SetText("Write notes and push them to everyone in your group who runs the addon.")

	local new = ns.CreateButton(view, "New note", LIST_WIDTH)
	new:SetPoint("TOPLEFT", 0, -56)
	new:SetScript("OnClick", function() SelectNote(Notes.New().key) end)

	view.scrollBox = CreateFrame("Frame", nil, view, "WowScrollBoxList")
	view.scrollBox:SetPoint("TOPLEFT", new, "BOTTOMLEFT", 0, -8)
	view.scrollBox:SetPoint("BOTTOM")
	view.scrollBox:SetWidth(LIST_WIDTH - 12)
	local scrollBar = CreateFrame("EventFrame", nil, view, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", view.scrollBox, "TOPRIGHT", 4, 0)
	scrollBar:SetPoint("BOTTOMLEFT", view.scrollBox, "BOTTOMRIGHT", 4, 0)
	local listView = CreateScrollBoxListLinearView()
	listView:SetElementExtent(26)
	listView:SetElementInitializer("Button", InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(view.scrollBox, scrollBar, listView)

	BuildEditor()
	view.empty = ns.Text(view, "GameFontHighlight", C.dim)
	view.empty:SetPoint("TOPLEFT", LIST_WIDTH + 16, -60)
	view.empty:SetText("No notes yet. Click New note to write one.")

	ns.RegisterView("notes", view)
	return view
end
