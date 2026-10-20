--[[ Launchers: minimap button (left-click opens the main window, right-click the note window, drag
to move it around the minimap), an Addon Compartment entry, and the /fra slash command
(/fra: main window, /fra notes: note window).
Events: PLAYER_LOGIN. SavedVariables: FRA_CharDB.minimapAngle. ]]

local _, ns = ...

-- Place the button on a circle just outside the minimap's edge at the saved angle.
local function Place(button)
	local angle = math.rad(ns.char.minimapAngle)
	local radius = Minimap:GetWidth() / 2 + 10
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Runs every frame only while the button is being dragged, so it follows the cursor.
local function FollowCursor(button)
	local mx, my = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	ns.char.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
	Place(button)
end

local function ShowTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(ns.TITLE)
	GameTooltip:AddLine("Left-click: open or close the main window", 1, 1, 1)
	GameTooltip:AddLine("Right-click: open or close the note window", 1, 1, 1)
	GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
	GameTooltip:Show()
end

local function CreateMinimapButton()
	local button = CreateFrame("Button", nil, Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetPoint("CENTER")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	icon:SetTexture(ns.ICON)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(52, 52)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns.ToggleNoteWindow()
		else
			ns.ToggleMain()
		end
	end)
	button:SetScript("OnEnter", ShowTooltip)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnDragStart", function(self)
		GameTooltip:Hide()
		self:SetScript("OnUpdate", FollowCursor)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	Place(button)
end

ns.On("PLAYER_LOGIN", function()
	CreateMinimapButton()
	-- Forever reskinned the minimap header, so only register if the compartment is present.
	if not AddonCompartmentFrame then return end
	AddonCompartmentFrame:RegisterAddon({
		text = ns.TITLE,
		icon = ns.ICON,
		notCheckable = true,
		func = ns.ToggleMain,
	})
end)

SLASH_FRA1 = "/fra"
SlashCmdList.FRA = function(msg)
	msg = strlower(strtrim(msg))
	if msg == "" then
		ns.ToggleMain()
	elseif msg == "notes" or msg == "note" then
		ns.ToggleNoteWindow()
	else
		ns.Print("/fra opens or closes the main window; /fra notes opens or closes the note window.")
	end
end
