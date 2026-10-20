--[[ Planned roster: players added by hand to a group before they join, with their class. They show
dimmed in that group on the Roster screen and can be tagged, dragged to another group or removed.
When a live group member with the same full name (ignoring capitals) appears, the planned entry is
merged away; role tags are keyed by name, so a tag set on the planned entry carries over.
Events: none (Core/Roster.lua calls Planned.Merge after each refresh).
SavedVariables: FRA_DB.manualRoster = { { name, class, group }, ... } ]]

local _, ns = ...

local Planned = {}
ns.Planned = Planned

Planned.MAX_NAME = 40

-- Forever's playable classes, in the order the class picker lists them.
Planned.CLASSES = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

local function Changed()
	ns.MarkDirty("home")
end

-- Typed name with outer spaces trimmed and inner runs of spaces made single; nil if empty or too long.
function Planned.CleanName(text)
	local name = strtrim(text):gsub("%s+", " ")
	if name == "" or strlenutf8(name) > Planned.MAX_NAME then return nil end
	return name
end

-- Planned entry with this name (ignoring capitals), and its index.
function Planned.Find(name)
	name = strlower(name)
	for i, entry in ipairs(ns.db.manualRoster) do
		if strlower(entry.name) == name then return entry, i end
	end
end

-- Add a planned player to group. Returns true, or false and the reason to show.
function Planned.Add(name, class, group)
	if Planned.Find(name) then return false, name .. " is already planned." end
	if ns.Roster.Find(name) then return false, name .. " is already in your group." end
	table.insert(ns.db.manualRoster, { name = name, class = class, group = group })
	Changed()
	return true
end

function Planned.Remove(entry)
	local _, index = Planned.Find(entry.name)
	if index then
		table.remove(ns.db.manualRoster, index)
		Changed()
	end
end

function Planned.Move(entry, group)
	entry.group = group
	Changed()
end

-- Drop planned entries for players who are now in the group, keeping their role tag.
function Planned.Merge()
	local list, tags = ns.db.manualRoster, ns.db.roleTags
	for i = #list, 1, -1 do
		local member = ns.Roster.Find(list[i].name)
		if member then
			local planned = table.remove(list, i).name
			if planned ~= member.name and tags[planned] then
				tags[member.name] = tags[member.name] or tags[planned]
				tags[planned] = nil
			end
			ns.Print(("%s joined; their planned entry was merged."):format(member.name))
		end
	end
end
