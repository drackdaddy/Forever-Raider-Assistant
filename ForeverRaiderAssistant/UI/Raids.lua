--[[ Raids screen: the assignment sheet for the raid page picked in the sidebar.
Header: page name, raid name and size, Clear sheet / Reset sheet / Clear raid (each asks first) and
the tactic hint. Pages with phases get a phase picker (one phase or all); pages with variants get a
variant picker. Each section is drawn as a card.
Events: none (redrawn through ns.MarkDirty("raids")).
SavedVariables: FRA_CharDB.ui.raid, .page, .phase; FRA_DB.plans through ns.Plan. ]]

local _, ns = ...

local Plan, Fields, C = ns.Plan, ns.Fields, ns.Colors

local SHEET_WIDTH, HEAD_HEIGHT, ROW_HEIGHT = 610, 28, 26
local view

-- Selected raid and page, falling back to the first ones when the saved keys no longer exist.
local function Current()
	local ui = ns.char.ui
	local raid = ns.raidByID[ui.raid] or ns.raids[1]
	return raid, raid.pageByKey[ui.page] or raid.pages[1]
end

-- Open pageKey of raidID on the Raids screen (the raid's first page when pageKey is nil).
function ns.SelectPage(raidID, pageKey)
	ns.ClosePicker()
	local ui = ns.char.ui
	ui.raid, ui.page, ui.phase = raidID, pageKey or ns.raidByID[raidID].pages[1].key, 0
	ns.ShowScreen("raids")
	ns.MarkDirty("raids")
end

local function IsPhase(index)
	return (ns.char.ui.phase or 0) == index
end

local function SetPhase(index)
	ns.char.ui.phase = index
	ns.MarkDirty("raids")
end

local function SectionShown(section, page, raid)
	local phase = ns.char.ui.phase or 0
	if phase ~= 0 and section.phase and section.phase ~= phase then return false end
	return not section.variant or section.variant == Plan.Variant(raid, page)
end

-- Draw each visible section as a card: a header strip with the title, then one row per field.
local function DrawSheet(raid, page)
	Fields.ReleaseAll()
	view.cards:ReleaseAll()
	view.heads:ReleaseAll()
	view.titles:ReleaseAll()
	local allPhases = (ns.char.ui.phase or 0) == 0
	local y = 0
	for _, section in ipairs(page.sections) do
		if SectionShown(section, page, raid) then
			local top = y
			local head = view.heads:Acquire()
			head:SetColorTexture(unpack(C.cardHead))
			head:SetPoint("TOPLEFT", 0, -y)
			head:SetSize(SHEET_WIDTH, HEAD_HEIGHT)
			head:Show()
			local title = view.titles:Acquire()
			title:SetPoint("LEFT", head, "LEFT", 12, 0)
			local suffix = ""
			if allPhases and section.phase then
				suffix = "   |cff8c94a3" .. page.phases[section.phase] .. "|r"
			end
			title:SetText(section.title .. suffix)
			title:Show()
			y = y + HEAD_HEIGHT + 6
			for _, field in ipairs(section.fields) do
				local row = Fields.Acquire(view.child, raid, page, field)
				row:SetPoint("TOPLEFT", 12, -y)
				row:Show()
				y = y + ROW_HEIGHT
			end
			y = y + 6
			local card = view.cards:Acquire()
			card:SetColorTexture(unpack(C.card))
			card:SetPoint("TOPLEFT", 0, -top)
			card:SetSize(SHEET_WIDTH, y - top)
			card:Show()
			y = y + 12
		end
	end
	view.child:SetHeight(math.max(y, 1))
end

-- Show the phase and variant pickers the page needs, side by side under the hint.
local function PlacePickers(page)
	view.phaseDrop:SetShown(page.phases ~= nil)
	view.variantDrop:SetShown(page.variants ~= nil)
	view.variantDrop:ClearAllPoints()
	if page.phases then
		local ui = ns.char.ui
		if (ui.phase or 0) > #page.phases then ui.phase = 0 end
		view.phaseDrop:GenerateMenu()
		view.variantDrop:SetPoint("LEFT", view.phaseDrop, "RIGHT", 8, 0)
	else
		view.variantDrop:SetPoint("LEFT", view.toolbar, "LEFT")
	end
	if page.variants then view.variantDrop:GenerateMenu() end
	view.toolbar:SetHeight((page.phases or page.variants) and 26 or 1)
end

local function Refresh(self)
	local raid, page = Current()
	local ui = ns.char.ui
	if ui.raid ~= raid.instanceID or ui.page ~= page.key then
		ui.raid, ui.page = raid.instanceID, page.key
		ns.MarkDirty("nav")
	end
	self.title:SetText(page.name)
	self.subtitle:SetText(("%s, %d players"):format(raid.name, raid.size))
	self.hint:SetText(page.hint or "")
	PlacePickers(page)
	DrawSheet(raid, page)
end

local function ActionButton(text, anchor, onClick)
	local button = ns.CreateButton(view, text, 96)
	if anchor then
		button:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
	else
		button:SetPoint("TOPRIGHT", -2, 0)
	end
	button:SetScript("OnClick", function()
		onClick(Current())
	end)
	return button
end

local function BuildHeader()
	local clearRaid = ActionButton("Clear raid", nil, function(raid)
		ns.Confirm(("Clear every job on every page of %s?"):format(raid.name),
			function() Plan.ClearRaid(raid) end)
	end)
	local reset = ActionButton("Reset sheet", clearRaid, function(raid, page)
		ns.Confirm(("Reset %s to its template? Renamed slots go back to their names too."):format(page.name),
			function() Plan.ResetPage(raid, page) end)
	end)
	local clearSheet = ActionButton("Clear sheet", reset, function(raid, page)
		ns.Confirm(("Clear every job on %s?"):format(page.name),
			function() Plan.ClearPage(raid, page) end)
	end)

	view.title = ns.Text(view, "GameFontHighlightLarge")
	view.title:SetPoint("TOPLEFT", 0, -2)
	view.title:SetPoint("RIGHT", clearSheet, "LEFT", -12, 0)
	view.title:SetWordWrap(false)
	view.subtitle = ns.Text(view, "GameFontHighlightSmall", C.dim)
	view.subtitle:SetPoint("TOPLEFT", view.title, "BOTTOMLEFT", 0, -4)

	view.hint = ns.Text(view, "GameFontHighlightSmall", C.dim)
	view.hint:SetPoint("TOPLEFT", 0, -50)
	view.hint:SetPoint("RIGHT", -2, 0)

	view.toolbar = CreateFrame("Frame", nil, view)
	view.toolbar:SetPoint("TOPLEFT", view.hint, "BOTTOMLEFT", 0, -10)
	view.toolbar:SetPoint("RIGHT")

	view.phaseDrop = CreateFrame("DropdownButton", nil, view.toolbar, "WowStyle1DropdownTemplate")
	view.phaseDrop:SetPoint("LEFT")
	view.phaseDrop:SetWidth(150)
	view.phaseDrop:SetupMenu(function(_, root)
		local _, page = Current()
		if not page.phases then return end
		root:CreateRadio("All phases", IsPhase, SetPhase, 0)
		for i, label in ipairs(page.phases) do
			root:CreateRadio(label, IsPhase, SetPhase, i)
		end
	end)

	view.variantDrop = CreateFrame("DropdownButton", nil, view.toolbar, "WowStyle1DropdownTemplate")
	view.variantDrop:SetWidth(170)
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
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh

	BuildHeader()

	view.scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate")
	view.scroll:SetPoint("TOPLEFT", view.toolbar, "BOTTOMLEFT", 0, -12)
	view.scroll:SetPoint("BOTTOMRIGHT", -18, 0)
	view.child = CreateFrame("Frame", nil, view.scroll)
	view.child:SetSize(SHEET_WIDTH, 1)
	view.scroll:SetScrollChild(view.child)
	-- Card backgrounds are textures on the scroll child, so field rows (child frames) always draw above.
	view.cards = CreateTexturePool(view.child, "BACKGROUND", 0)
	view.heads = CreateTexturePool(view.child, "BACKGROUND", 1)
	view.titles = CreateFontStringPool(view.child, "ARTWORK", 0, "GameFontHighlight")

	ns.RegisterView("raids", view)
	return view
end
