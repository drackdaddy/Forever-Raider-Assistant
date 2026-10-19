--[[ Main window: movable, minimizable, closes with Escape, with a left menu of screens.
Remembers its position and the last screen. Screens add a builder to ns.screenBuilders.
Events: none. SavedVariables: FRA_CharDB.ui.point, FRA_CharDB.ui.screen. ]]

local _, ns = ...

ns.screenBuilders = {}

local WIDTH, HEIGHT, MINIMIZED_HEIGHT = 800, 540, 64
local NAV = {
	{ key = "home", text = "Home" },
	{ key = "raids", text = "Raids" },
}

local main, body
local screens, navButtons = {}, {}

local function ShowScreen(key)
	ns.char.ui.screen = key
	for k, screen in pairs(screens) do
		screen:SetShown(k == key)
	end
	for k, button in pairs(navButtons) do
		button.selected:SetShown(k == key)
	end
end

-- Save the top-left corner so minimizing shrinks the window toward its title bar.
local function SavePosition(frame)
	frame:StopMovingOrSizing()
	local left, top = frame:GetLeft(), frame:GetTop()
	ns.char.ui.point = { left, top }
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function Create()
	main = CreateFrame("Frame", "FRAMainFrame", UIParent, "ButtonFrameTemplate")
	ButtonFrameTemplate_HidePortrait(main)
	main.Inset:Hide()
	main:SetTitle("Forever Raider Assistant")
	main:SetSize(WIDTH, HEIGHT)
	main:SetFrameStrata("HIGH")
	main:SetToplevel(true)
	main:SetClampedToScreen(true)
	main:SetMovable(true)
	main:EnableMouse(true)
	main:SetDontSavePosition(true)
	main:RegisterForDrag("LeftButton")
	main:SetScript("OnDragStart", main.StartMoving)
	main:SetScript("OnDragStop", SavePosition)
	main:HookScript("OnHide", ns.ClosePicker)
	local point = ns.char.ui.point
	if point then
		main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", point[1], point[2])
	else
		main:SetPoint("TOP", UIParent, "TOP", 0, -120)
	end
	tinsert(UISpecialFrames, "FRAMainFrame")

	body = CreateFrame("Frame", nil, main)
	body:SetPoint("TOPLEFT", 10, -30)
	body:SetPoint("BOTTOMRIGHT", -12, 12)

	local minimize = CreateFrame("Frame", nil, main, "MaximizeMinimizeButtonFrameTemplate")
	minimize:SetPoint("RIGHT", main.CloseButton, "LEFT", 2, 0)
	minimize:SetOnMinimizedCallback(function()
		ns.ClosePicker()
		body:Hide()
		main:SetHeight(MINIMIZED_HEIGHT)
	end)
	minimize:SetOnMaximizedCallback(function()
		main:SetHeight(HEIGHT)
		body:Show()
	end)

	local content = CreateFrame("Frame", nil, body)
	content:SetPoint("TOPLEFT", 126, -4)
	content:SetPoint("BOTTOMRIGHT")

	for i, entry in ipairs(NAV) do
		local button = ns.CreateListButton(body, 112, 24)
		button:SetPoint("TOPLEFT", 0, -4 - (i - 1) * 26)
		button.text:SetText(entry.text)
		button:SetScript("OnClick", function() ShowScreen(entry.key) end)
		navButtons[entry.key] = button
		screens[entry.key] = ns.screenBuilders[entry.key](content)
		screens[entry.key]:Hide()
	end
end

function ns.ToggleMain()
	if not main then Create() end
	if main:IsShown() then
		main:Hide()
	else
		main:Show()
		ShowScreen(screens[ns.char.ui.screen] and ns.char.ui.screen or "home")
	end
end
