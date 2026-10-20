--[[ Combat logging: when the option is on, entering a raid instance turns on the game's combat log,
and leaving one asks whether to stop it. The addon only switches logging; it never reads the log.
Events: PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA.
SavedVariables: autoLog in the active tools settings (see ns.Tools in Core/DB.lua). ]]

local _, ns = ...

local inRaid = false

StaticPopupDialogs.FRA_STOP_LOG = {
	text = "You left the raid instance. Stop combat logging?",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		LoggingCombat(false)
		ns.Print("Combat logging stopped.")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- Act only when the player crosses into or out of a raid instance, so other zone changes are ignored.
local function Check()
	local _, instanceType = IsInInstance()
	local nowInRaid = instanceType == "raid"
	if nowInRaid == inRaid then return end
	inRaid = nowInRaid
	if not ns.Tools().autoLog then return end
	if nowInRaid and not LoggingCombat() then
		LoggingCombat(true)
		ns.Print("Combat logging started.")
	elseif not nowInRaid and LoggingCombat() then
		StaticPopup_Show("FRA_STOP_LOG")
	end
end

-- Turn the option on or off. Turning it on inside a raid starts logging right away.
function ns.SetAutoLog(on)
	ns.Tools().autoLog = on
	if on then
		inRaid = false
		Check()
	end
end

ns.On("PLAYER_ENTERING_WORLD", Check)
ns.On("ZONE_CHANGED_NEW_AREA", Check)
