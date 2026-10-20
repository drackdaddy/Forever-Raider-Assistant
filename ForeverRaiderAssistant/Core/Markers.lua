--[[ Marker codes in note text: target (raid) markers and ground (world) markers.
  Target markers: {rt1} to {rt8}, or by name as in chat: {star} {circle} {diamond} {triangle}
    {moon} {square} {cross} {x} {skull}.
  Ground markers: {wm1} to {wm8}, in the game's world-marker order (1 blue square, 2 green
    triangle, 3 purple diamond, 4 red cross, 5 yellow star, 6 orange circle, 7 silver moon,
    8 white skull). They draw as the marker's color bar followed by its shape.
Notes store and send the plain codes; only display turns them into icons. Any other "|" escape
codes in note text are shown as typed, so a pushed note can only draw these markers.
Events: none. SavedVariables: none. ]]

local _, ns = ...

local ICON = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d|t"
local BAR = "|TInterface\\Buttons\\WHITE8X8:%d:%d:0:0:8:8:0:8:0:8:%d:%d:%d|t"

local TARGET_NAMES = {
	star = 1, circle = 2, diamond = 3, triangle = 4, moon = 5, square = 6, cross = 7, x = 7, skull = 8,
}

-- Ground marker n: target-marker icon with the same shape, its color (0-255) and its name.
ns.GROUND_MARKERS = {
	{ icon = 6, color = { 51, 140, 255 }, name = "Blue square" },
	{ icon = 4, color = { 64, 230, 64 }, name = "Green triangle" },
	{ icon = 3, color = { 190, 90, 255 }, name = "Purple diamond" },
	{ icon = 7, color = { 255, 64, 64 }, name = "Red cross" },
	{ icon = 1, color = { 255, 230, 51 }, name = "Yellow star" },
	{ icon = 2, color = { 255, 153, 38 }, name = "Orange circle" },
	{ icon = 5, color = { 205, 215, 230 }, name = "Silver moon" },
	{ icon = 8, color = { 255, 255, 255 }, name = "White skull" },
}

local function Target(index, size)
	return ICON:format(index, size)
end

local function Ground(index, size)
	local marker = ns.GROUND_MARKERS[index]
	local r, g, b = unpack(marker.color)
	return BAR:format(size, math.max(3, math.floor(size / 4)), r, g, b) .. Target(marker.icon, size)
end

-- Display text for note text: escape codes neutralized, marker codes drawn as icons of size px.
function ns.RenderMarkers(text, size)
	size = size or 14
	text = text:gsub("|", "||")
	return (text:gsub("{(%w+)}", function(code)
		code = code:lower()
		local n = code:match("^rt([1-8])$")
		if n then return Target(tonumber(n), size) end
		n = code:match("^wm([1-8])$")
		if n then return Ground(tonumber(n), size) end
		if TARGET_NAMES[code] then return Target(TARGET_NAMES[code], size) end
	end))
end
