--[[ Main window: a flat window that moves by its title bar, minimizes to the title bar and closes with
Escape. The sidebar (UI/Sidebar.lua) sits on the left; the selected screen fills the rest.
Screens add a builder to ns.screenBuilders. Remembers its position and the last screen.
Events: none. SavedVariables: FRA_CharDB.ui.point, FRA_CharDB.ui.screen. ]]

local _, ns = ...

ns.screenBuilders = {}

local WIDTH, HEIGHT, TITLE_HEIGHT, SIDEBAR_WIDTH = 880, 580, 32, 210
local SCREENS = { "home", "tools", "notes", "raids" }

local main, body
local screens = {}
local minimized = false

-- Show screen key ("home", "tools", "notes" or "raids") in the content pane.
function ns.ShowScreen(key)
	ns.char.ui.screen = key
	for k, screen in pairs(screens) do
		screen:SetShown(k == key)
	end
	ns.MarkDirty("nav")
end

-- Save the top-left corner so minimizing shrinks the window toward its title bar.
local function SavePosition()
	main:StopMovingOrSizing()
	local left, top = main:GetLeft(), main:GetTop()
	ns.char.ui.point = { left, top }
	main:ClearAllPoints()
	main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function ToggleMinimized()
	minimized = not minimized
	ns.ClosePicker()
	body:SetShown(not minimized)
	main:SetHeight(minimized and TITLE_HEIGHT + 2 or HEIGHT)
end

local function BuildTitleBar()
	local bar = CreateFrame("Frame", nil, main)
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("TOPRIGHT", -1, -1)
	bar:SetHeight(TITLE_HEIGHT)
	ns.Fill(bar, ns.Colors.titlebar)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function() main:StartMoving() end)
	bar:SetScript("OnDragStop", SavePosition)

	local icon = bar:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("LEFT", 10, 0)
	icon:SetTexture(ns.ICON)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local title = ns.Text(bar, "GameFontHighlight")
	title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	title:SetText(ns.TITLE)

	local close = ns.CreateIconButton(bar, "close")
	close:SetPoint("RIGHT", -2, 0)
	close:SetScript("OnClick", function() main:Hide() end)
	local minimize = ns.CreateIconButton(bar, "minimize")
	minimize:SetPoint("RIGHT", close, "LEFT", 0, 0)
	minimize:SetScript("OnClick", ToggleMinimized)
	return bar
end

local function Create()
	main = CreateFrame("Frame", "FRAMainFrame", UIParent, "BackdropTemplate")
	ns.StylePanel(main)
	main:SetSize(WIDTH, HEIGHT)
	main:SetFrameStrata("HIGH")
	main:SetToplevel(true)
	main:SetClampedToScreen(true)
	main:SetMovable(true)
	main:EnableMouse(true)
	main:SetDontSavePosition(true)
	main:HookScript("OnHide", ns.ClosePicker)
	local point = ns.char.ui.point
	if point then
		main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", point[1], point[2])
	else
		main:SetPoint("TOP", UIParent, "TOP", 0, -120)
	end
	tinsert(UISpecialFrames, "FRAMainFrame")

	local bar = BuildTitleBar()
	body = CreateFrame("Frame", nil, main)
	body:SetPoint("TOPLEFT", bar, "BOTTOMLEFT")
	body:SetPoint("BOTTOMRIGHT", -1, 1)

	local sidebar = CreateFrame("Frame", nil, body)
	sidebar:SetPoint("TOPLEFT")
	sidebar:SetPoint("BOTTOMLEFT")
	sidebar:SetWidth(SIDEBAR_WIDTH)
	ns.Fill(sidebar, ns.Colors.sidebar)
	local divider = sidebar:CreateTexture(nil, "BORDER")
	divider:SetPoint("TOPRIGHT")
	divider:SetPoint("BOTTOMRIGHT")
	divider:SetWidth(1)
	divider:SetColorTexture(unpack(ns.Colors.border))

	local content = CreateFrame("Frame", nil, body)
	content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 16, -14)
	content:SetPoint("BOTTOMRIGHT", -16, 14)
	for _, key in ipairs(SCREENS) do
		screens[key] = ns.screenBuilders[key](content)
		screens[key]:Hide()
	end
	ns.BuildSidebar(sidebar)
end

-- Open the main window on the last screen used.
function ns.ShowMain()
	if not main then Create() end
	if not main:IsShown() then
		main:Show()
		ns.ShowScreen(screens[ns.char.ui.screen] and ns.char.ui.screen or "home")
	end
end

function ns.ToggleMain()
	if main and main:IsShown() then
		main:Hide()
	else
		ns.ShowMain()
	end
end
