--[[ Tools screen: options for automatic combat logging (Tools/CombatLog.lua) and whisper auto-invite
with a customizable list of invite words (Tools/AutoInvite.lua). A switch picks whether this
character uses its own settings or the account-wide ones.
Events: none (redrawn through ns.MarkDirty("tools")).
SavedVariables: FRA_CharDB.toolsScope; the active tools settings through ns.Tools. ]]

local _, ns = ...

local C = ns.Colors

local view

-- Flat card holding one tool, placed below anchor (or at the top of the screen).
local function Card(anchor, title, height)
	local card = CreateFrame("Frame", nil, view, "BackdropTemplate")
	ns.StylePanel(card, C.card)
	card:SetPoint("TOPLEFT", anchor or view, anchor and "BOTTOMLEFT" or "TOPLEFT", 0, anchor and -12 or -94)
	card:SetPoint("RIGHT")
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

local function SaveWords(edit)
	ns.SetInviteWords(strtrim(edit:GetText()))
	ns.MarkDirty("tools")
end

-- Switch settings scope; the newly active settings may turn logging on if we are in a raid.
local function SetScope(scope)
	ns.SetToolsScope(scope)
	ns.SetAutoLog(ns.Tools().autoLog)
	ns.MarkDirty("tools")
end

local function Refresh(self)
	local tools = ns.Tools()
	for _, button in ipairs(self.scopeButtons) do
		ns.SetActive(button, button.scope == ns.char.toolsScope)
	end
	self.autoLog:SetValue(tools.autoLog)
	self.autoInvite:SetValue(tools.autoInvite)
	if not self.words:HasFocus() then
		self.words:SetText(tools.inviteWords)
	end
	local list = {}
	for word in pairs(ns.ParseInviteWords(tools.inviteWords)) do
		list[#list + 1] = word
	end
	table.sort(list)
	self.listening:SetText(#list > 0 and ("Listening for: " .. table.concat(list, ", "))
		or "No invite words set, so nobody is invited.")
end

ns.screenBuilders.tools = function(parent)
	view = CreateFrame("Frame", nil, parent)
	view:SetAllPoints()
	view.Refresh = Refresh

	local title = ns.Text(view, "GameFontHighlightLarge")
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetText("Tools")
	local subtitle = ns.Text(view, "GameFontHighlightSmall", C.dim)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	subtitle:SetText("Raid-night helpers for logging and invites.")

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

	local logCard = Card(nil, "Combat logging", 104)
	view.autoLog = ns.CreateCheckbox(logCard, "Start combat logging when I enter a raid instance", ns.SetAutoLog)
	view.autoLog:SetPoint("TOPLEFT", 14, -40)
	Note(logCard, -70, "When you leave the raid instance, you are asked whether to stop logging.")

	local inviteCard = Card(logCard, "Auto invite", 176)
	view.autoInvite = ns.CreateCheckbox(inviteCard, "Invite players who whisper me an invite word", function(on)
		ns.Tools().autoInvite = on
	end)
	view.autoInvite:SetPoint("TOPLEFT", 14, -40)

	local label = ns.Text(inviteCard, "GameFontHighlightSmall", C.dim)
	label:SetPoint("TOPLEFT", 14, -78)
	label:SetText("Invite words")
	view.words = ns.CreateEditBox(inviteCard, 300)
	view.words:SetPoint("LEFT", label, "LEFT", 100, 0)
	view.words:SetMaxLetters(200)
	view.words:SetScript("OnEnterPressed", view.words.ClearFocus)
	view.words:SetScript("OnEscapePressed", function(self)
		self:SetText(ns.Tools().inviteWords)
		self:ClearFocus()
	end)
	view.words:HookScript("OnEditFocusLost", SaveWords)

	view.listening = Note(inviteCard, -104, "")
	Note(inviteCard, -124, "Separate words with commas. A whisper must be exactly one of the words; capitals "
		.. "don't matter. Works when you're solo, party leader, or raid leader or assistant, and pauses "
		.. "during boss encounters. A party that would grow past 5 is converted to a raid.")

	ns.RegisterView("tools", view)
	return view
end
