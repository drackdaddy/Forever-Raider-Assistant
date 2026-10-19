--[[ Home screen: the live roster as a grid of 8 groups of 5, class counts, and the role-tag toolbar.
Pick a tag (Main Tank, Off Tank, Healer), then click players to add or remove it. Tags feed the
tank and healer filters. "Clear tags" removes every tag after a confirmation.
Events: none (redrawn through ns.MarkDirty("home")). SavedVariables: FRA_DB.roleTags. ]]

local _, ns = ...

local GROUPS, SLOTS = 8, 5
local TAGS = {
	{ key = "MT", text = "Main Tank", short = "MT" },
	{ key = "OT", text = "Off Tank", short = "OT" },
	{ key = "HEALER", text = "Healer", short = "Heal" },
}
local SHORT = {}
for _, tag in ipairs(TAGS) do
	SHORT[tag.key] = tag.short
end
local RANK_ICONS = {
	[1] = "Interface\\GroupFrame\\UI-Group-AssistantIcon",
	[2] = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
}

local view
local activeTag

local function ToggleTag(slot)
	if not activeTag or not slot.name then return end
	local tags = ns.db.roleTags
	tags[slot.name] = tags[slot.name] ~= activeTag and activeTag or nil
	ns.MarkDirty("home")
	ns.MarkDirty("raids")
end

local function NewSlot(parent)
	local slot = ns.CreateListButton(parent, 146, 20)
	local background = slot:CreateTexture(nil, "BACKGROUND", nil, -1)
	background:SetAllPoints()
	background:SetColorTexture(0, 0, 0, 0.35)
	slot.rank = slot:CreateTexture(nil, "OVERLAY")
	slot.rank:SetSize(12, 12)
	slot.rank:SetPoint("LEFT", 3, 0)
	slot.text:SetFontObject("GameFontHighlightSmall")
	slot.text:ClearAllPoints()
	slot.text:SetPoint("LEFT", 18, 0)
	slot.text:SetPoint("RIGHT", -34, 0)
	slot.tag = slot:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slot.tag:SetPoint("RIGHT", -4, 0)
	slot:SetScript("OnClick", ToggleTag)
	return slot
end

local function FillSlot(slot, member)
	slot.name = member and member.name
	slot.text:SetText(member and ns.ColorName(member.name, member.class, not member.online) or "")
	slot.tag:SetText(member and SHORT[ns.db.roleTags[member.name]] or "")
	local icon = member and RANK_ICONS[member.rank]
	slot.rank:SetTexture(icon)
	slot.rank:SetShown(icon ~= nil)
end

local function ClassCounts(list)
	local counts = {}
	for _, member in ipairs(list) do
		if member.class then
			counts[member.class] = (counts[member.class] or 0) + 1
		end
	end
	local parts = {}
	for _, class in ipairs(CLASS_SORT_ORDER) do
		if counts[class] then
			local text = (LOCALIZED_CLASS_NAMES_MALE[class] or class) .. " " .. counts[class]
			parts[#parts + 1] = C_ClassColor.GetClassColor(class):WrapTextInColorCode(text)
		end
	end
	return table.concat(parts, "    ")
end

local function Refresh(self)
	local list = ns.Roster.list
	if IsInRaid() then
		self.header:SetText(("Live raid: %d players"):format(#list))
	elseif IsInGroup() then
		self.header:SetText(("Live party: %d players"):format(#list))
	else
		self.header:SetText("Not in a group: showing only you")
	end

	local byGroup = {}
	for g = 1, GROUPS do
		byGroup[g] = {}
	end
	for _, member in ipairs(list) do
		local members = byGroup[member.group]
		if members and #members < SLOTS then
			members[#members + 1] = member
		end
	end
	for g = 1, GROUPS do
		for s = 1, SLOTS do
			FillSlot(self.slots[(g - 1) * SLOTS + s], byGroup[g][s])
		end
	end

	for _, button in ipairs(self.tagButtons) do
		if button.key == activeTag then button:LockHighlight() else button:UnlockHighlight() end
	end
	self.counts:SetText(ClassCounts(list))
end

ns.screenBuilders.home = function(parent)
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh

	view.header = view:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	view.header:SetPoint("TOPLEFT", 0, -4)

	local label = view:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	label:SetPoint("TOPLEFT", 0, -38)
	label:SetText("Tag players:")
	view.tagButtons = {}
	local previous = label
	for _, tag in ipairs(TAGS) do
		local button = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
		button:SetSize(96, 22)
		button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
		button:SetText(tag.text)
		button.key = tag.key
		button:SetScript("OnClick", function()
			activeTag = activeTag ~= tag.key and tag.key or nil
			ns.MarkDirty("home")
		end)
		view.tagButtons[#view.tagButtons + 1] = button
		previous = button
	end
	local clear = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
	clear:SetSize(96, 22)
	clear:SetPoint("LEFT", previous, "RIGHT", 16, 0)
	clear:SetText("Clear tags")
	clear:SetScript("OnClick", function()
		ns.Confirm("Remove every Main Tank, Off Tank and Healer tag?", function()
			wipe(ns.db.roleTags)
			ns.MarkDirty("home")
			ns.MarkDirty("raids")
		end)
	end)

	local hint = view:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", 0, -62)
	hint:SetText("Pick a tag, then click players to add or remove it. Click the tag again to stop tagging.")

	view.slots = {}
	for g = 1, GROUPS do
		local column, rowIndex = (g - 1) % 4, math.floor((g - 1) / 4)
		local x, y = column * 160, -86 - rowIndex * 136
		local title = view:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		title:SetPoint("TOPLEFT", x, y)
		title:SetText(GROUP .. " " .. g)
		for s = 1, SLOTS do
			local slot = NewSlot(view)
			slot:SetPoint("TOPLEFT", x, y - 18 - (s - 1) * 22)
			view.slots[(g - 1) * SLOTS + s] = slot
		end
	end

	view.counts = view:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	view.counts:SetPoint("TOPLEFT", 0, -366)
	view.counts:SetPoint("RIGHT")
	view.counts:SetJustifyH("LEFT")

	ns.RegisterView("home", view)
	return view
end
