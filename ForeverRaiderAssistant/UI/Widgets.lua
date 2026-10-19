--[[ Shared widgets: flat list buttons, value boxes for sheet slots, and a yes/no confirmation.
Events: none. SavedVariables: none. ]]

local _, ns = ...

-- Flat clickable row: left-aligned text, hover highlight, and a .selected texture to show/hide.
function ns.CreateListButton(parent, width, height)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, height)
	button.selected = button:CreateTexture(nil, "BACKGROUND")
	button.selected:SetAllPoints()
	button.selected:SetColorTexture(1, 0.82, 0, 0.18)
	button.selected:Hide()
	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.08)
	button.text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	button.text:SetPoint("LEFT", 6, 0)
	button.text:SetPoint("RIGHT", -6, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetWordWrap(false)
	return button
end

-- Dark box for a sheet slot, so empty slots still read as clickable. Takes left and right clicks.
function ns.CreateValueButton(parent, width)
	local button = ns.CreateListButton(parent, width, 20)
	local background = button:CreateTexture(nil, "BACKGROUND", nil, -1)
	background:SetAllPoints()
	background:SetColorTexture(0, 0, 0, 0.45)
	button.text:SetFontObject("GameFontHighlightSmall")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	return button
end

StaticPopupDialogs.FRA_CONFIRM = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, fn) fn() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- Ask text as a yes/no question; fn runs only on Yes.
function ns.Confirm(text, fn)
	StaticPopup_Show("FRA_CONFIRM", text, nil, fn)
end
