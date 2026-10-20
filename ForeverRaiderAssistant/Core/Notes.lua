--[[ Quick Notes data: notes you write and notes pushed to you, saved account-wide. The group leader
or an assistant can push their own notes to everyone in the group running the addon; pushing the
same note again updates the receivers' copy. A received note is saved and opened in the note
window (UI/NoteWindow.lua).
Payload (Comm kind "N"): note id LF title LF body. Receivers check the id and the title and body
lengths before saving anything; sender rank is checked by Core/Comm.lua.
Events: none of its own. SavedVariables: FRA_DB.notes[key] =
  { key, id, title, body, from = sender's full name (nil for your own notes), time = server time } ]]

local _, ns = ...

local Notes = { status = {} } -- status[key] = this session's last push state, shown on the screen
ns.Notes = Notes

Notes.MAX_TITLE = 60
Notes.MAX_BODY = 2000

local function Changed()
	ns.MarkDirty("notes")
	ns.MarkDirty("noteWindow")
end

-- All notes, newest first.
function Notes.List()
	local list = {}
	for _, note in pairs(ns.db.notes) do
		list[#list + 1] = note
	end
	table.sort(list, function(a, b)
		if a.time ~= b.time then return a.time > b.time end
		return a.key < b.key
	end)
	return list
end

function Notes.Get(key)
	return key and ns.db.notes[key]
end

-- Create an empty note of your own and return it. Own notes are keyed by their numeric id;
-- received notes by "sender/id", so the two never collide.
function Notes.New()
	local id = GetServerTime()
	while ns.db.notes[tostring(id)] do
		id = id + 1
	end
	id = tostring(id)
	local note = { key = id, id = id, title = "New note", body = "", time = GetServerTime() }
	ns.db.notes[id] = note
	Changed()
	return note
end

-- Change field ("title" or "body") of one of your own notes.
function Notes.Edit(note, field, value)
	if field == "title" then value = value:gsub("\n", " ") end
	if note[field] == value then return end
	note[field] = value
	Changed()
end

function Notes.Delete(key)
	ns.db.notes[key] = nil
	Notes.status[key] = nil
	Changed()
end

-- Push one of your own notes to the group. Progress lands in Notes.status[note.key].
function Notes.Push(note)
	local payload = table.concat({ note.id, note.title, note.body }, "\n")
	ns.Comm.Send("N", payload, function(state)
		Notes.status[note.key] = state
		ns.MarkDirty("notes")
	end)
end

ns.Comm.Register("N", function(sender, payload)
	local id, title, body = payload:match("^(%d+)\n([^\n]*)\n(.*)$")
	if not id or #id > 12 or strlenutf8(title) > Notes.MAX_TITLE or strlenutf8(body) > Notes.MAX_BODY then
		return
	end
	if title == "" then title = "Untitled" end
	local key = sender .. "/" .. id
	ns.db.notes[key] = { key = key, id = id, title = title, body = body, from = sender, time = GetServerTime() }
	Changed()
	ns.ShowNoteTab(key)
	ns.Print(("New note from %s: %s"):format(Ambiguate(sender, "short"), ns.RenderMarkers(title, 12)))
end)
