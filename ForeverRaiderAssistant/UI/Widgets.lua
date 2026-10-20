--[[ Shared widgets and the flat look: color tokens, flat panels, push and toggle buttons, list rows,
edit boxes, checkboxes, title-bar icon buttons, and a yes/no confirmation.
Events: none. SavedVariables: none. ]]

local _, ns = ...

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Color tokens ({ r, g, b, a }) used by every screen, so the look can be tuned in one place.
local C = {
	window = { 0.055, 0.06, 0.075, 0.97 },
	titlebar = { 0.08, 0.085, 0.105, 1 },
	sidebar = { 0.075, 0.08, 0.1, 1 },
	card = { 0.1, 0.105, 0.13, 1 },
	field = { 0.035, 0.04, 0.05, 1 },
	border = { 1, 1, 1, 0.08 },
	hover = { 1, 1, 1, 0.06 },
	accent = { 0.27, 0.68, 1, 1 },
	accentDim = { 0.27, 0.68, 1, 0.16 },
	text = { 0.92, 0.93, 0.95, 1 },
	dim = { 0.55, 0.58, 0.64, 1 },
}
ns.Colors = C

-- Solid color texture covering frame. Returns the texture.
function ns.Fill(frame, color, layer, subLevel)
	local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel)
	texture:SetAllPoints()
	texture:SetColorTexture(unpack(color))
	return texture
end

-- Font string with a template and an optional color token.
function ns.Text(parent, template, color)
	local text = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlightSmall")
	if color then text:SetTextColor(unpack(color)) end
	text:SetJustifyH("LEFT")
	return text
end

-- Flat panel: solid background with a 1 px border. frame must inherit BackdropTemplate.
function ns.StylePanel(frame, color)
	frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	frame:SetBackdropColor(unpack(color or C.window))
	frame:SetBackdropBorderColor(unpack(C.border))
end

-- Show a flat button as on (accent) or off.
function ns.SetActive(button, on)
	button:SetBackdropColor(unpack(on and C.accentDim or C.card))
	button:SetBackdropBorderColor(unpack(on and C.accent or C.border))
end

-- Flat push button. Toggle buttons call ns.SetActive to show their state.
function ns.CreateButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, 24)
	ns.StylePanel(button, C.card)
	ns.Fill(button, C.hover, "HIGHLIGHT")
	button:SetNormalFontObject("GameFontHighlightSmall")
	button:SetHighlightFontObject("GameFontHighlightSmall")
	button:SetText(text)
	return button
end

-- Add the list-row look to button: hover tint, a .text label, and an accent bar plus tint when
-- selected (see ns.SetSelected). Used for sidebar entries, roster slots, note rows and note tabs.
function ns.StyleListButton(button)
	button.selected = ns.Fill(button, C.accentDim)
	button.bar = button:CreateTexture(nil, "ARTWORK")
	button.bar:SetPoint("TOPLEFT")
	button.bar:SetPoint("BOTTOMLEFT")
	button.bar:SetWidth(2)
	button.bar:SetColorTexture(unpack(C.accent))
	ns.Fill(button, C.hover, "HIGHLIGHT")
	button.text = ns.Text(button)
	button.text:SetPoint("LEFT", 10, 0)
	button.text:SetPoint("RIGHT", -6, 0)
	button.text:SetWordWrap(false)
	ns.SetSelected(button, false)
end

function ns.SetSelected(button, on)
	button.selected:SetShown(on)
	button.bar:SetShown(on)
end

function ns.CreateListButton(parent, width, height)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, height)
	ns.StyleListButton(button)
	return button
end

-- Flat single-line edit box. Its border lights up while focused; callers add their own focus-lost
-- logic with HookScript so this highlight keeps working.
function ns.CreateEditBox(parent, width)
	local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	edit:SetSize(width, 22)
	ns.StylePanel(edit, C.field)
	edit:SetFontObject("GameFontHighlightSmall")
	edit:SetTextInsets(8, 8, 0, 0)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
	edit:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)
	return edit
end

-- Flat checkbox with a label; clicking the label toggles it too. onToggle(on) runs on each click.
-- Call box:SetValue(on) to show a saved value.
function ns.CreateCheckbox(parent, label, onToggle)
	local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
	box:SetSize(18, 18)
	ns.StylePanel(box, C.field)
	box.mark = box:CreateTexture(nil, "ARTWORK")
	box.mark:SetPoint("TOPLEFT", 4, -4)
	box.mark:SetPoint("BOTTOMRIGHT", -4, 4)
	box.mark:SetColorTexture(unpack(C.accent))
	box.text = ns.Text(box, "GameFontHighlight")
	box.text:SetPoint("LEFT", box, "RIGHT", 10, 0)
	box.text:SetText(label)
	box:SetHitRectInsets(0, -(box.text:GetStringWidth() + 10), 0, 0)
	box.SetValue = function(self, on) self.mark:SetShown(on) end
	box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
	box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)
	box:SetScript("OnClick", function(self)
		local on = not self.mark:IsShown()
		self:SetValue(on)
		onToggle(on)
	end)
	return box
end

-- Title-bar button drawn from thin lines: kind "close" (an X) or "minimize" (a dash).
function ns.CreateIconButton(parent, kind)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(28, 28)
	ns.Fill(button, C.hover, "HIGHLIGHT")
	for _, angle in ipairs(kind == "close" and { 45, -45 } or { 0 }) do
		local line = button:CreateTexture(nil, "ARTWORK")
		line:SetSize(12, 2)
		line:SetPoint("CENTER")
		line:SetColorTexture(unpack(C.dim))
		line:SetRotation(math.rad(angle))
	end
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
