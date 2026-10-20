--[[ Add-player form: a small panel opened from an empty roster slot to plan a player into that group
by full name and class (see Core/Planned.lua). Enter or "Add" saves; Escape or "Cancel" closes.
Events: none. SavedVariables: FRA_DB.manualRoster through ns.Planned. ]]

local _, ns = ...

local C, Planned = ns.Colors, ns.Planned

local form
local group, class -- target group and picked class while the form is open

local function ClassLabel(classFile)
	return C_ClassColor.GetClassColor(classFile):WrapTextInColorCode(LOCALIZED_CLASS_NAMES_MALE[classFile] or classFile)
end

local function Submit()
	local name = Planned.CleanName(form.name:GetText())
	if not name then
		form.status:SetText("Type the character's first and last name.")
		return
	end
	if not class then
		form.status:SetText("Pick a class.")
		return
	end
	local ok, reason = Planned.Add(name, class, group)
	if ok then form:Hide() else form.status:SetText(reason) end
end

local function Build()
	form = CreateFrame("Frame", "FRAPlannedForm", UIParent, "BackdropTemplate")
	ns.StylePanel(form)
	form:SetBackdropBorderColor(unpack(C.accent))
	form:SetSize(260, 172)
	form:SetFrameStrata("DIALOG")
	form:SetToplevel(true)
	form:SetClampedToScreen(true)
	form:EnableMouse(true)
	tinsert(UISpecialFrames, "FRAPlannedForm")

	form.title = ns.Text(form, "GameFontHighlight")
	form.title:SetPoint("TOPLEFT", 12, -12)
	local close = ns.CreateIconButton(form, "close")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() form:Hide() end)

	local nameLabel = ns.Text(form, "GameFontHighlightSmall", C.dim)
	nameLabel:SetPoint("TOPLEFT", 12, -40)
	nameLabel:SetText("First and last name")
	form.name = ns.CreateEditBox(form, 236)
	form.name:SetPoint("TOPLEFT", 12, -56)
	form.name:SetMaxLetters(Planned.MAX_NAME)
	form.name:SetScript("OnEnterPressed", Submit)
	form.name:SetScript("OnEscapePressed", function() form:Hide() end)

	form.class = CreateFrame("DropdownButton", nil, form, "WowStyle1DropdownTemplate")
	form.class:SetPoint("TOPLEFT", 12, -86)
	form.class:SetWidth(236)
	form.class:SetDefaultText("Class")
	form.class:SetupMenu(function(_, root)
		for _, classFile in ipairs(Planned.CLASSES) do
			root:CreateRadio(ClassLabel(classFile),
				function() return class == classFile end,
				function() class = classFile end)
		end
	end)

	form.status = ns.Text(form, "GameFontHighlightSmall", { 1, 0.45, 0.35, 1 })
	form.status:SetPoint("TOPLEFT", 12, -116)
	form.status:SetPoint("RIGHT", -12, 0)

	local add = ns.CreateButton(form, "Add", 112)
	add:SetPoint("BOTTOMRIGHT", -12, 12)
	ns.SetActive(add, true)
	add:SetScript("OnClick", Submit)
	local cancel = ns.CreateButton(form, CANCEL, 112)
	cancel:SetPoint("BOTTOMLEFT", 12, 12)
	cancel:SetScript("OnClick", function() form:Hide() end)
end

-- Open the form below anchor (an empty roster slot) to plan a player into groupIndex.
function ns.OpenPlannedForm(anchor, groupIndex)
	if not form then Build() end
	group, class = groupIndex, nil
	form.title:SetText(("Add a player to %s %d"):format(GROUP, groupIndex))
	form.name:SetText("")
	form.status:SetText("")
	form.class:GenerateMenu()
	local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
	form:ClearAllPoints()
	form:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", anchor:GetLeft() * scale, anchor:GetBottom() * scale - 2)
	form:Show()
	form.name:SetFocus()
end
