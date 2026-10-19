--[[ Raids screen: pick a raid, then its General page, Trash page or a boss, and fill the sheet.
Pages with phases get a phase picker (one phase or all); pages with variants get a variant picker.
Clear sheet, Clear raid and Reset sheet ask before acting.
Events: none (redrawn through ns.MarkDirty("raids")).
SavedVariables: FRA_CharDB.ui.raid, .page, .phase; FRA_DB.plans through ns.Plan. ]]

local _, ns = ...

local Plan, Fields = ns.Plan, ns.Fields

local LIST_WIDTH = 170
local view, ui

-- Selected raid and page, falling back to the first ones when the saved keys no longer exist.
local function Current()
	local raid = ns.raidByID[ui.raid] or ns.raids[1]
	return raid, raid.pageByKey[ui.page] or raid.pages[1]
end

local function SelectPage(raidID, pageKey)
	ns.ClosePicker()
	ui.raid, ui.page, ui.phase = raidID, pageKey, 0
	ns.MarkDirty("raids")
end

local function IsPhase(index)
	return (ui.phase or 0) == index
end

local function SetPhase(index)
	ui.phase = index
	ns.MarkDirty("raids")
end

local function PageButton(index)
	local button = view.pageButtons[index]
	if not button then
		button = ns.CreateListButton(view.list, LIST_WIDTH, 20)
		button:SetPoint("TOPLEFT", 0, -(index - 1) * 21)
		button.text:SetFontObject("GameFontHighlightSmall")
		button:SetScript("OnClick", function(self) SelectPage(ui.raid, self.key) end)
		view.pageButtons[index] = button
	end
	return button
end

local function SectionShown(section, page, raid)
	local phase = ui.phase or 0
	if phase ~= 0 and section.phase and section.phase ~= phase then return false end
	return not section.variant or section.variant == Plan.Variant(raid, page)
end

local function DrawSheet(raid, page)
	Fields.ReleaseAll()
	view.headers:ReleaseAll()
	local y = 0
	for _, section in ipairs(page.sections) do
		if SectionShown(section, page, raid) then
			local header = view.headers:Acquire()
			header:SetPoint("TOPLEFT", 0, -y)
			local suffix = ""
			if (ui.phase or 0) == 0 and section.phase then
				suffix = "  |cff808080" .. page.phases[section.phase] .. "|r"
			end
			header:SetText(section.title .. suffix)
			header:Show()
			y = y + 22
			for _, field in ipairs(section.fields) do
				local row = Fields.Acquire(view.child, raid, page, field)
				row:SetPoint("TOPLEFT", 8, -y)
				row:Show()
				y = y + 24
			end
			y = y + 10
		end
	end
	view.child:SetHeight(math.max(y, 1))
end

local function Refresh(self)
	local raid, page = Current()
	ui.raid, ui.page = raid.instanceID, page.key
	self.raidDrop:GenerateMenu()

	self.phaseDrop:SetShown(page.phases ~= nil)
	if page.phases then
		if (ui.phase or 0) > #page.phases then ui.phase = 0 end
		self.phaseDrop:GenerateMenu()
	end
	self.variantDrop:SetShown(page.variants ~= nil)
	if page.variants then
		self.variantDrop:GenerateMenu()
	end

	for i, p in ipairs(raid.pages) do
		local button = PageButton(i)
		button.key = p.key
		button.text:SetText(p.name)
		button.selected:SetShown(p == page)
		button:Show()
	end
	for i = #raid.pages + 1, #self.pageButtons do
		self.pageButtons[i]:Hide()
	end

	self.hint:SetText(page.hint or "")
	DrawSheet(raid, page)
end

local function ActionButton(text, previous, onClick)
	local button = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
	button:SetSize(LIST_WIDTH, 22)
	button:SetPoint("BOTTOMLEFT", previous or view, previous and "TOPLEFT" or "BOTTOMLEFT", 0, previous and 4 or 0)
	button:SetText(text)
	button:SetScript("OnClick", function()
		local raid, page = Current()
		onClick(raid, page)
	end)
	return button
end

local function BuildTopBar()
	view.raidDrop = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
	view.raidDrop:SetPoint("TOPLEFT", 0, 0)
	view.raidDrop:SetWidth(LIST_WIDTH + 30)
	view.raidDrop:SetupMenu(function(_, root)
		for _, raid in ipairs(ns.raids) do
			root:CreateRadio(("%s (%d)"):format(raid.name, raid.size),
				function() return ui.raid == raid.instanceID end,
				function() SelectPage(raid.instanceID, nil) end)
		end
	end)

	view.phaseDrop = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
	view.phaseDrop:SetPoint("LEFT", view.raidDrop, "RIGHT", 10, 0)
	view.phaseDrop:SetWidth(130)
	view.phaseDrop:SetupMenu(function(_, root)
		local _, page = Current()
		if not page.phases then return end
		root:CreateRadio("All phases", IsPhase, SetPhase, 0)
		for i, label in ipairs(page.phases) do
			root:CreateRadio(label, IsPhase, SetPhase, i)
		end
	end)

	view.variantDrop = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
	view.variantDrop:SetPoint("LEFT", view.phaseDrop, "RIGHT", 10, 0)
	view.variantDrop:SetWidth(150)
	view.variantDrop:SetupMenu(function(_, root)
		local raid, page = Current()
		if not page.variants then return end
		for _, variant in ipairs(page.variants) do
			root:CreateRadio(variant.text,
				function() return Plan.Variant(raid, page) == variant.key end,
				function() Plan.SetVariant(raid, page, variant.key) end)
		end
	end)
end

ns.screenBuilders.raids = function(parent)
	ui = ns.char.ui
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh
	view.pageButtons = {}

	BuildTopBar()

	view.list = CreateFrame("Frame", nil, view)
	view.list:SetPoint("TOPLEFT", 0, -38)
	view.list:SetSize(LIST_WIDTH, 320)

	local reset = ActionButton("Reset sheet", nil, function(raid, page)
		ns.Confirm(("Reset %s to its template? Renamed slots go back to their names too."):format(page.name),
			function() Plan.ResetPage(raid, page) end)
	end)
	local clearRaid = ActionButton("Clear raid", reset, function(raid)
		ns.Confirm(("Clear every job on every page of %s?"):format(raid.name),
			function() Plan.ClearRaid(raid) end)
	end)
	ActionButton("Clear sheet", clearRaid, function(raid, page)
		ns.Confirm(("Clear every job on %s?"):format(page.name),
			function() Plan.ClearPage(raid, page) end)
	end)

	view.hint = view:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	view.hint:SetPoint("TOPLEFT", view.list, "TOPRIGHT", 16, 0)
	view.hint:SetPoint("RIGHT", -26, 0)
	view.hint:SetJustifyH("LEFT")

	view.scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate")
	view.scroll:SetPoint("TOPLEFT", view.hint, "BOTTOMLEFT", 0, -8)
	view.scroll:SetPoint("BOTTOMRIGHT", -26, 0)
	view.child = CreateFrame("Frame", nil, view.scroll)
	view.child:SetSize(440, 1)
	view.scroll:SetScrollChild(view.child)
	view.headers = CreateFontStringPool(view.child, "ARTWORK", 0, "GameFontNormal")

	ns.RegisterView("raids", view)
	return view
end
