--[[ Core: namespace, event dispatch, debouncing, deferred view refresh and shared text helpers.
Events: none of its own; features register handlers through ns.On.
SavedVariables: none. ]]

local _, ns = ...

ns.TITLE = "Forever Raider Assistant"
ns.ICON = "Interface\\Icons\\INV_Misc_Note_01"

-- One event frame for the whole addon. Features add handlers with ns.On.
local eventFrame = CreateFrame("Frame")
local handlers = {}

-- Run fn(event, ...) whenever event fires. Several features may handle the same event.
function ns.On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		eventFrame:RegisterEvent(event)
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do
		fn(event, ...)
	end
end)

-- Coalesce bursts of calls: fn runs once, delay seconds after the first call of a burst.
local pending = {}
function ns.Debounce(key, delay, fn)
	if pending[key] then return end
	pending[key] = true
	C_Timer.After(delay, function()
		pending[key] = nil
		fn()
	end)
end

-- Fast refresh: views are marked dirty and redrawn at most once per frame.
-- Hidden views stay dirty and redraw when they are next shown.
local views, dirty = {}, {}
local flushQueued = false

local function Flush()
	flushQueued = false
	for name in pairs(dirty) do
		local view = views[name]
		if view and view:IsVisible() then
			dirty[name] = nil
			view:Refresh()
		end
	end
end

-- Register frame (which must have a Refresh method) under name. It starts dirty.
function ns.RegisterView(name, frame)
	views[name] = frame
	dirty[name] = true
	frame:HookScript("OnShow", function()
		if dirty[name] then
			dirty[name] = nil
			frame:Refresh()
		end
	end)
end

function ns.MarkDirty(name)
	dirty[name] = true
	if not flushQueued then
		flushQueued = true
		C_Timer.After(0, Flush)
	end
end

function ns.Print(msg)
	print("|cff45adff" .. ns.TITLE .. "|r: " .. msg)
end

-- Short display name, class-colored; grey when dim is true or the class is unknown.
function ns.ColorName(fullName, classFile, dim)
	local short = Ambiguate(fullName, "short")
	local color = not dim and classFile and C_ClassColor.GetClassColor(classFile)
	if not color then
		return "|cff808080" .. short .. "|r"
	end
	return color:WrapTextInColorCode(short)
end
