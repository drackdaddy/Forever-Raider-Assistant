--[[ Tools screen: options for automatic combat logging (Tools/CombatLog.lua), whisper auto-invite
with a customizable list of invite words (Tools/AutoInvite.lua), auto promotion to raid assistant
by guild rank or name (Tools/AutoPromote.lua), and an automatic master looter (Tools/LootMaster.lua).
A switch picks whether this character uses its own settings or the account-wide ones. The cards
scroll.
Events: none (redrawn through ns.MarkDirty("tools")).
SavedVariables: FRA_CharDB.toolsScope; the active tools settings through ns.Tools. ]]

local _, ns = ...

local C = ns.Colors

local MAX_RANKS, RANK_COLUMNS = 10, 3
local view

-- Flat card holding one tool, placed below anchor (or at the top of the scrolled area).
local function Card(anchor, title, height)
	local card = CreateFrame("Frame", nil, view.child, "BackdropTemplate")
	ns.StylePanel(card, C.card)
	card:SetPoint("TOPLEFT", anchor or view.child, anchor and "BOTTOMLEFT" or "TOPLEFT", 0, anchor and -12 or 0)
	card:SetPoint("RIGHT", view.child)
	card:SetHeight(height)
	local text = ns.Text(card, "GameFontHighlight")
	text:SetPoint("TOPLEFT", 14, -12)
	text:SetText(title)
	return card
end

local function Note(card, y, text)
	local note = ns.Text(card, "GameFontHighlightSmall", C.dim)
	note:SetPoint("TOPLEFT", 14, y)
	note:SetPoint("RIGHT", -14, 0)
	note:SetText(text)
	return note
end

-- Checkbox at y on card for the boolean setting key; after runs once the value is saved.
local function Toggle(card, y, label, key, after)
	local box = ns.CreateCheckbox(card, label, function(on)
		ns.Tools()[key] = on
		if after then after() end
	end)
	box:SetPoint("TOPLEFT", 14, y)
	box.key = key
	return box
end

-- Labeled edit box at y on card for the text setting key; save(text) stores a confirmed edit.
local function TextSetting(card, y, label, width, key, save)
	local text = ns.Text(card, "GameFontHighlightSmall", C.dim)
	text:SetPoint("TOPLEFT", 14, y)
	text:SetText(label)
	local edit = ns.CreateEditBox(card, width)
	edit:SetPoint("LEFT", text, "LEFT", 100, 0)
	edit:SetMaxLetters(200)
	edit:SetScript("OnEnterPressed", edit.ClearFocus)
	edit:SetScript("OnEscapePressed", function(self)
		self:SetText(ns.Tools()[key])
		self:ClearFocus()
	end)
	edit:HookScript("OnEditFocusLost", function(self)
		save(strtrim(self:GetText()))
		ns.MarkDirty("tools")
	end)
	edit.key = key
	return edit
end

-- Switch settings scope; the newly active settings may start logging, promoting or setting loot.
local function SetScope(scope)
	ns.SetToolsScope(scope)
	ns.SetAutoLog(ns.Tools().autoLog)
	ns.RunAutoPromote()
	ns.RunLootMaster()
	ns.MarkDirty("tools")
end

local function SortedKeys(set)
	local list = {}
	for key in pairs(set) do
		list[#list + 1] = key
	end
	table.sort(list)
	return list
end

-- One checkbox per guild rank (rank index 0 is the guild master).
local function RefreshRanks(self, tools)
	local count = IsInGuild() and math.min(GuildControlGetNumRanks(), MAX_RANKS) or 0
	for i, box in ipairs(self.rankBoxes) do
		local shown = i <= count
		box:SetShown(shown)
		if shown then
			box.text:SetText(GuildControlGetRankName(i))
			box:SetHitRectInsets(0, -(box.text:GetStringWidth() + 10), 0, 0)
			box:SetValue(tools.promoteRanks[i - 1] == true)
		end
	end
	self.noGuild:SetShown(count == 0)
end

local function Refresh(self)
	local tools = ns.Tools()
	for _, button in ipairs(self.scopeButtons) do
		ns.SetActive(button, button.scope == ns.char.toolsScope)
	end
	for _, box in ipairs(self.toggles) do
		box:SetValue(tools[box.key])
	end
	for _, edit in ipairs(self.edits) do
		if not edit:HasFocus() then edit:SetText(tools[edit.key]) end
	end
	local words = SortedKeys(ns.ParseInviteWords(tools.inviteWords))
	self.listening:SetText(#words > 0 and ("Listening for: " .. table.concat(words, ", "))
		or "No invite words set, so nobody is invited.")
	RefreshRanks(self, tools)
end

local function BuildHeader()
	local title = ns.Text(view, "GameFontHighlightLarge")
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetText("Tools")
	local subtitle = ns.Text(view, "GameFontHighlightSmall", C.dim)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	subtitle:SetText("Raid-night helpers for logging, invites, assistants and loot.")

	local scopeLabel = ns.Text(view, "GameFontHighlightSmall", C.dim)
	scopeLabel:SetPoint("TOPLEFT", 0, -62)
	scopeLabel:SetText("Settings apply to")
	view.scopeButtons = {}
	local previous
	for _, option in ipairs({ { "char", "This character" }, { "account", "All characters" } }) do
		local button = ns.CreateButton(view, option[2], 120)
		button:SetPoint("LEFT", previous or scopeLabel, "RIGHT", previous and 6 or 12, 0)
		button.scope = option[1]
		button:SetScript("OnClick", function() SetScope(option[1]) end)
		view.scopeButtons[#view.scopeButtons + 1] = button
		previous = button
	end
end

local function BuildLogAndInvite()
	local logCard = Card(nil, "Combat logging", 104)
	local autoLog = ns.CreateCheckbox(logCard, "Start combat logging when I enter a raid instance", ns.SetAutoLog)
	autoLog:SetPoint("TOPLEFT", 14, -40)
	autoLog.key = "autoLog"
	view.toggles[#view.toggles + 1] = autoLog
	Note(logCard, -70, "When you leave the raid instance, you are asked whether to stop logging.")

	local inviteCard = Card(logCard, "Auto invite", 176)
	view.toggles[#view.toggles + 1] = Toggle(inviteCard, -40, "Invite players who whisper me an invite word",
		"autoInvite")
	view.edits[#view.edits + 1] = TextSetting(inviteCard, -78, "Invite words", 300, "inviteWords",
		ns.SetInviteWords)
	view.listening = Note(inviteCard, -104, "")
	Note(inviteCard, -124, "Separate words with commas. A whisper must be exactly one of the words; capitals "
		.. "don't matter. Works when you're solo, party leader, or raid leader or assistant, and pauses "
		.. "during boss encounters. A party that would grow past 5 is converted to a raid.")
	return inviteCard
end

local function BuildPromote(anchor)
	local card = Card(anchor, "Auto promote to raid assistant", 288)
	local function Save(key)
		return function(text)
			ns.Tools()[key] = text
			ns.RunAutoPromote()
		end
	end
	view.toggles[#view.toggles + 1] = Toggle(card, -40, "Promote guild members with these ranks", "promoteByRank",
		ns.RunAutoPromote)
	view.rankBoxes = {}
	for i = 1, MAX_RANKS do
		local box = ns.CreateCheckbox(card, "", function(on)
			ns.Tools().promoteRanks[i - 1] = on or nil
			ns.RunAutoPromote()
		end)
		box:SetPoint("TOPLEFT", 40 + ((i - 1) % RANK_COLUMNS) * 180, -68 - math.floor((i - 1) / RANK_COLUMNS) * 24)
		view.rankBoxes[i] = box
	end
	view.noGuild = Note(card, -70, "You're not in a guild.")
	view.toggles[#view.toggles + 1] = Toggle(card, -172, "Promote these players", "promoteByName",
		ns.RunAutoPromote)
	view.edits[#view.edits + 1] = TextSetting(card, -206, "Names", 380, "promoteNames", Save("promoteNames"))
	Note(card, -234, "Full names separated by commas. Runs while you lead a raid and waits until combat "
		.. "ends. Someone you demote stays demoted for the rest of the session.")
	return card
end

local function BuildLoot(anchor)
	local card = Card(anchor, "Auto loot master", 150)
	view.toggles[#view.toggles + 1] = Toggle(card, -40, "Make this player master looter when they're in my raid",
		"lootMaster", ns.RunLootMaster)
	view.edits[#view.edits + 1] = TextSetting(card, -74, "Name", 300, "lootMasterName", function(text)
		ns.Tools().lootMasterName = text
		ns.RunLootMaster()
	end)
	Note(card, -102, "Full name. Set once per raid while you lead it, so a loot method you change yourself "
		.. "stays. Waits until combat ends.")
	return card
end

ns.screenBuilders.tools = function(parent)
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh
	view.toggles, view.edits = {}, {}

	BuildHeader()
	view.scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate")
	view.scroll:SetPoint("TOPLEFT", 0, -94)
	view.scroll:SetPoint("BOTTOMRIGHT", -18, 0)
	view.child = CreateFrame("Frame", nil, view.scroll)
	view.child:SetSize(610, 104 + 176 + 288 + 150 + 3 * 12)
	view.scroll:SetScrollChild(view.child)

	BuildLoot(BuildPromote(BuildLogAndInvite()))

	ns.RegisterView("tools", view)
	return view
end
