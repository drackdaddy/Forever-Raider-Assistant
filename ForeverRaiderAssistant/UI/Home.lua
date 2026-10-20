--[[ Roster screen: the group as 8 cards of 5 showing full names (first and last), class counts, and
the role-tag toolbar. Pick a tag (Main Tank, Off Tank, Healer), then click players to add or remove
it; tags mark roles on the roster. "Clear tags" removes every tag after a confirmation.
Click an empty slot to plan a player into that group by name and class (UI/PlannedForm.lua).
Planned players show dimmed after the live members, merge away when they join, can be dragged to
another group, and are removed with a right-click.
In a raid, the leader or an assistant can drag a live player onto another group: onto an empty or
planned slot to move them, or onto a player to swap the two. The game makes the move; the cards
then redraw from the game's roster, so they always show the real groups. Moves are refused in combat.
Events: none (redrawn through ns.MarkDirty("home")). SavedVariables: FRA_DB.roleTags; planned
players through ns.Planned. ]]

local _, ns = ...

local C = ns.Colors

local GROUPS, SLOTS = 8, 5
local CARD_WIDTH, CARD_GAP, SLOT_HEIGHT, SLOT_STEP = 150, 12, 30, 31
local CARD_HEIGHT = 26 + SLOTS * SLOT_STEP + 4
local GRID_TOP = 112
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

-- Left-click: tag a player while a tag is picked, or plan a player into an empty slot.
-- Right-click: remove a planned player.
local function OnSlotClick(slot, mouseButton)
	if slot.dragged then
		slot.dragged = nil
		return
	end
	if mouseButton == "RightButton" then
		if slot.planned then ns.Planned.Remove(slot.planned) end
		return
	end
	if not slot.name then
		if not activeTag then ns.OpenPlannedForm(slot, slot.groupIndex) end
		return
	end
	if not activeTag then return end
	local tags = ns.db.roleTags
	tags[slot.name] = tags[slot.name] ~= activeTag and activeTag or nil
	ns.MarkDirty("home")
end

local function ShowSlotTip(slot)
	GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
	if slot.planned then
		GameTooltip:SetText(slot.planned.name)
		GameTooltip:AddLine("Planned: merges when they join. Drag to another group; right-click to remove.",
			1, 1, 1, true)
	elseif slot.member then
		GameTooltip:SetText(slot.member.name)
	else
		GameTooltip:SetText("Click to add a player by name.")
	end
	GameTooltip:Show()
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
	if not (slot.member or slot.planned) then return end
	slot.dragged = true
	if slot.member then
		local ok, reason = CanMove()
		if not ok then
			ns.Print(reason)
			return
		end
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

-- Drop on whichever slot is under the cursor. A live player moves into the target's group (an
-- empty or planned slot) or swaps with the live player there; one drop makes at most one call to
-- the game. A planned player moves to the target's group unless the target is a live player.
local function StopDrag(slot)
	C_Timer.After(0, function() slot.dragged = nil end)
	if not dragFrom then return end
	local from = dragFrom
	dragFrom = nil
	ghost:Hide()
	local target
	for _, candidate in ipairs(view.slots) do
		if candidate:IsMouseOver() then target = candidate end
	end
	if not target or target.groupIndex == from.groupIndex then return end
	if from.planned then
		if not target.member then ns.Planned.Move(from.planned, target.groupIndex) end
		return
	end
	if not CanMove() then return end
	if target.member then
		SwapRaidSubgroup(RaidIndex(from.member), RaidIndex(target.member))
	else
		SetRaidSubgroup(RaidIndex(from.member), target.groupIndex)
	end
end

local function NewSlot(parent)
	local slot = ns.CreateListButton(parent, CARD_WIDTH - 12, SLOT_HEIGHT)
	ns.Fill(slot, C.field, "BACKGROUND", -1)
	slot.rank = slot:CreateTexture(nil, "OVERLAY")
	slot.rank:SetSize(12, 12)
	slot.rank:SetPoint("LEFT", 4, 0)
	slot.text:SetPoint("LEFT", 19, 0)
	slot.text:SetPoint("RIGHT", -32, 0)
	-- First and last name on one line when they fit, else on two.
	slot.text:SetWordWrap(true)
	slot.text:SetMaxLines(2)
	slot.tag = ns.Text(slot)
	slot.tag:SetPoint("RIGHT", -5, 0)
	slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	slot:SetScript("OnClick", OnSlotClick)
	slot:SetScript("OnEnter", ShowSlotTip)
	slot:SetScript("OnLeave", GameTooltip_Hide)
	slot:RegisterForDrag("LeftButton")
	slot:SetScript("OnDragStart", StartDrag)
	slot:SetScript("OnDragStop", StopDrag)
	return slot
end

-- Show a live member, a planned entry (dimmed), or nothing in slot.
local function FillSlot(slot, entry)
	local live = entry and entry.unit ~= nil
	slot.member = live and entry or nil
	slot.planned = entry and not live and entry or nil
	slot.name = entry and entry.name
	slot.text:SetText(entry and ns.ColorName(entry.name, entry.class, live and not entry.online) or "")
	slot.text:SetAlpha(slot.planned and 0.5 or 1)
	slot.tag:SetText(entry and BADGE[ns.db.roleTags[entry.name]] or "")
	local icon = live and RANK_ICONS[entry.rank]
	slot.rank:SetTexture(icon or nil)
	slot.rank:SetShown(icon ~= nil)
end

-- Class counts over live and planned players.
local function ClassCounts(list, planned)
	local counts = {}
	for _, source in ipairs({ list, planned }) do
		for _, entry in ipairs(source) do
			if entry.class then
				counts[entry.class] = (counts[entry.class] or 0) + 1
			end
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
	local list, planned = ns.Roster.list, ns.db.manualRoster
	local status
	if IsInRaid() then
		status = ("Live raid, %d players"):format(#list)
	elseif IsInGroup() then
		status = ("Live party, %d players"):format(#list)
	else
		status = "Not in a group: showing only you"
	end
	if #planned > 0 then status = ("%s, %d planned"):format(status, #planned) end
	self.subtitle:SetText(status)

	-- Live members first, then planned ones; anything past 5 in a group is counted on its card.
	local byGroup, hidden = {}, {}
	for g = 1, GROUPS do
		byGroup[g], hidden[g] = {}, 0
	end
	for _, source in ipairs({ list, planned }) do
		for _, entry in ipairs(source) do
			local entries = byGroup[entry.group]
			if entries and #entries < SLOTS then
				entries[#entries + 1] = entry
			elseif entries then
				hidden[entry.group] = hidden[entry.group] + 1
			end
		end
	end
	for g = 1, GROUPS do
		for s = 1, SLOTS do
			FillSlot(self.slots[(g - 1) * SLOTS + s], byGroup[g][s])
		end
		self.groupTitles[g]:SetText(hidden[g] > 0 and ("%s %d   +%d planned"):format(GROUP, g, hidden[g])
			or (GROUP .. " " .. g))
	end

	for _, button in ipairs(self.tagButtons) do
		ns.SetActive(button, button.key == activeTag)
	end
	self.counts:SetText(ClassCounts(list, planned))
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
		end)
	end)

	local hint = ns.Text(view, "GameFontHighlightSmall", C.dim)
	hint:SetPoint("TOPLEFT", 0, -90)
	hint:SetText("Click an empty slot to add a player. Pick a tag, then click players to tag them. "
		.. "Drag players between groups.")
end

local function BuildGroups()
	view.slots, view.groupTitles = {}, {}
	for g = 1, GROUPS do
		local card = CreateFrame("Frame", nil, view, "BackdropTemplate")
		ns.StylePanel(card, C.card)
		card:SetSize(CARD_WIDTH, CARD_HEIGHT)
		card:SetPoint("TOPLEFT", ((g - 1) % 4) * (CARD_WIDTH + CARD_GAP),
			-GRID_TOP - math.floor((g - 1) / 4) * (CARD_HEIGHT + CARD_GAP))
		local title = ns.Text(card, "GameFontHighlightSmall", C.dim)
		title:SetPoint("TOPLEFT", 8, -8)
		view.groupTitles[g] = title
		for s = 1, SLOTS do
			local slot = NewSlot(card)
			slot.groupIndex = g
			slot:SetPoint("TOPLEFT", 6, -26 - (s - 1) * SLOT_STEP)
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
	view.counts:SetPoint("TOPLEFT", 0, -GRID_TOP - 2 * CARD_HEIGHT - CARD_GAP - 6)
	view.counts:SetPoint("RIGHT")

	ns.RegisterView("home", view)
	return view
end
