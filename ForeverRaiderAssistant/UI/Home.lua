--[[ Home screen: the live roster as 8 group cards of 5, class counts, and the role-tag toolbar.
Pick a tag (Main Tank, Off Tank, Healer), then click players to add or remove it. Tags feed the
tank and healer filters. "Clear tags" removes every tag after a confirmation.
In a raid, the leader or an assistant can drag a player onto another group: onto an empty slot to
move them, or onto a player to swap the two. The game makes the move; the cards then redraw from
the game's roster, so they always show the real groups. Moves are refused in combat.
Events: none (redrawn through ns.MarkDirty("home")). SavedVariables: FRA_DB.roleTags. ]]

local _, ns = ...

local C = ns.Colors

local GROUPS, SLOTS = 8, 5
local CARD_WIDTH, CARD_HEIGHT, CARD_GAP = 150, 142, 12
local TAGS = {
	{ key = "MT", text = "Main Tank", short = "MT", color = "ff7259" },
	{ key = "OT", text = "Off Tank", short = "OT", color = "ffb24d" },
	{ key = "HEALER", text = "Healer", short = "Heal", color = "66e680" },
}
local BADGE = {}
for _, tag in ipairs(TAGS) do
	BADGE[tag.key] = "|cff" .. tag.color .. tag.short .. "|r"
end
local RANK_ICONS = {
	[1] = "Interface\\GroupFrame\\UI-Group-AssistantIcon",
	[2] = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
}

local view
local activeTag
local dragFrom -- slot being dragged
local ghost -- label that follows the cursor while dragging

local function ToggleTag(slot)
	if slot.dragged then
		slot.dragged = nil
		return
	end
	if not activeTag or not slot.name then return end
	local tags = ns.db.roleTags
	tags[slot.name] = tags[slot.name] ~= activeTag and activeTag or nil
	ns.MarkDirty("home")
	ns.MarkDirty("raids")
end

-- Returns true if the player may move raiders now, or false plus the reason to print.
local function CanMove()
	if not IsInRaid() then return false, "Moving players between groups needs a raid." end
	if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
		return false, "Only the raid leader or an assistant can move players."
	end
	if InCombatLockdown() then return false, "Players can't be moved in combat." end
	return true
end

-- Raid roster index of a member ("raid7" -> 7).
local function RaidIndex(member)
	return tonumber(member.unit:match("^raid(%d+)$"))
end

local function FollowCursor(self)
	local x, y = GetCursorPosition()
	local scale = self:GetEffectiveScale()
	self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 12, y / scale - 8)
end

local function StartDrag(slot)
	if not slot.member then return end
	slot.dragged = true
	local ok, reason = CanMove()
	if not ok then
		ns.Print(reason)
		return
	end
	if not ghost then
		ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		ns.StylePanel(ghost, C.card)
		ghost:SetBackdropBorderColor(unpack(C.accent))
		ghost:SetFrameStrata("TOOLTIP")
		ghost:SetSize(CARD_WIDTH - 12, 20)
		ghost.text = ns.Text(ghost)
		ghost.text:SetPoint("LEFT", 8, 0)
		-- Runs every frame only while a drag is in progress, so the label tracks the cursor.
		ghost:SetScript("OnUpdate", FollowCursor)
	end
	dragFrom = slot
	ghost.text:SetText(slot.text:GetText())
	FollowCursor(ghost)
	ghost:Show()
end

-- Drop on whichever slot is under the cursor: an empty slot moves the player into that group,
-- another player's slot swaps the two. One drop makes at most one call to the game.
local function StopDrag(slot)
	C_Timer.After(0, function() slot.dragged = nil end)
	if not dragFrom then return end
	local from = dragFrom.member
	dragFrom = nil
	ghost:Hide()
	local target
	for _, candidate in ipairs(view.slots) do
		if candidate:IsMouseOver() then target = candidate end
	end
	if not target or target.groupIndex == from.group or not CanMove() then return end
	if target.member then
		SwapRaidSubgroup(RaidIndex(from), RaidIndex(target.member))
	else
		SetRaidSubgroup(RaidIndex(from), target.groupIndex)
	end
end

local function NewSlot(parent)
	local slot = ns.CreateListButton(parent, CARD_WIDTH - 12, 20)
	ns.Fill(slot, C.field, "BACKGROUND", -1)
	slot.rank = slot:CreateTexture(nil, "OVERLAY")
	slot.rank:SetSize(12, 12)
	slot.rank:SetPoint("LEFT", 4, 0)
	slot.text:SetPoint("LEFT", 19, 0)
	slot.text:SetPoint("RIGHT", -32, 0)
	slot.tag = ns.Text(slot)
	slot.tag:SetPoint("RIGHT", -5, 0)
	slot:SetScript("OnClick", ToggleTag)
	slot:RegisterForDrag("LeftButton")
	slot:SetScript("OnDragStart", StartDrag)
	slot:SetScript("OnDragStop", StopDrag)
	return slot
end

local function FillSlot(slot, member)
	slot.member = member
	slot.name = member and member.name
	slot.text:SetText(member and ns.ColorName(member.name, member.class, not member.online) or "")
	slot.tag:SetText(member and BADGE[ns.db.roleTags[member.name]] or "")
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
		self.subtitle:SetText(("Live raid, %d players"):format(#list))
	elseif IsInGroup() then
		self.subtitle:SetText(("Live party, %d players"):format(#list))
	else
		self.subtitle:SetText("Not in a group: showing only you")
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
		ns.SetActive(button, button.key == activeTag)
	end
	self.counts:SetText(ClassCounts(list))
end

local function BuildToolbar()
	local label = ns.Text(view, "GameFontHighlightSmall", C.dim)
	label:SetPoint("TOPLEFT", 0, -64)
	label:SetText("Tag players")
	view.tagButtons = {}
	local previous = label
	for _, tag in ipairs(TAGS) do
		local button = ns.CreateButton(view, tag.text, 96)
		button:SetPoint("LEFT", previous, "RIGHT", previous == label and 12 or 6, 0)
		button.key = tag.key
		button:SetScript("OnClick", function()
			activeTag = activeTag ~= tag.key and tag.key or nil
			ns.MarkDirty("home")
		end)
		view.tagButtons[#view.tagButtons + 1] = button
		previous = button
	end
	local clear = ns.CreateButton(view, "Clear tags", 96)
	clear:SetPoint("TOPRIGHT", -2, 0)
	clear:SetScript("OnClick", function()
		ns.Confirm("Remove every Main Tank, Off Tank and Healer tag?", function()
			wipe(ns.db.roleTags)
			ns.MarkDirty("home")
			ns.MarkDirty("raids")
		end)
	end)

	local hint = ns.Text(view, "GameFontHighlightSmall", C.dim)
	hint:SetPoint("TOPLEFT", 0, -90)
	hint:SetText("Pick a tag, then click players to tag them; click the tag again to stop. "
		.. "Drag a player to another group to move them.")
end

local function BuildGroups()
	view.slots = {}
	for g = 1, GROUPS do
		local card = CreateFrame("Frame", nil, view, "BackdropTemplate")
		ns.StylePanel(card, C.card)
		card:SetSize(CARD_WIDTH, CARD_HEIGHT)
		card:SetPoint("TOPLEFT", ((g - 1) % 4) * (CARD_WIDTH + CARD_GAP),
			-112 - math.floor((g - 1) / 4) * (CARD_HEIGHT + CARD_GAP))
		local title = ns.Text(card, "GameFontHighlightSmall", C.dim)
		title:SetPoint("TOPLEFT", 8, -8)
		title:SetText(GROUP .. " " .. g)
		for s = 1, SLOTS do
			local slot = NewSlot(card)
			slot.groupIndex = g
			slot:SetPoint("TOPLEFT", 6, -26 - (s - 1) * 22)
			view.slots[(g - 1) * SLOTS + s] = slot
		end
	end
end

ns.screenBuilders.home = function(parent)
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh

	local title = ns.Text(view, "GameFontHighlightLarge")
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetText("Roster")
	view.subtitle = ns.Text(view, "GameFontHighlightSmall", C.dim)
	view.subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

	BuildToolbar()
	BuildGroups()

	view.counts = ns.Text(view)
	view.counts:SetPoint("TOPLEFT", 0, -112 - 2 * (CARD_HEIGHT + CARD_GAP))
	view.counts:SetPoint("RIGHT")

	ns.RegisterView("home", view)
	return view
end
