--[[ Sidebar: one entry per screen (Roster, Tools, Quick Notes); the selected screen is highlighted.
Events: none (redrawn through ns.MarkDirty("nav")). SavedVariables: reads FRA_CharDB.ui.screen. ]]

local _, ns = ...

local ENTRIES = {
	{ key = "home", text = "Roster" },
	{ key = "tools", text = "Tools" },
	{ key = "notes", text = "Quick Notes" },
}

local function Refresh(self)
	for _, button in ipairs(self.buttons) do
		ns.SetSelected(button, button.key == ns.char.ui.screen)
	end
end

-- Build the sidebar inside parent (the main window's left column).
function ns.BuildSidebar(parent)
	local view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh
	view.buttons = {}
	for i, entry in ipairs(ENTRIES) do
		local button = ns.CreateListButton(view, parent:GetWidth(), 26)
		button:SetPoint("TOPLEFT", 0, -8 - (i - 1) * 26)
		button:SetPoint("RIGHT")
		button.text:SetFontObject("GameFontHighlight")
		button.text:SetPoint("LEFT", 12, 0)
		button.text:SetText(entry.text)
		button.key = entry.key
		button:SetScript("OnClick", function() ns.ShowScreen(entry.key) end)
		view.buttons[i] = button
	end
	ns.RegisterView("nav", view)
end
