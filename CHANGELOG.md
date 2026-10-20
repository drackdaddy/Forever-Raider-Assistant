# Changelog

## 0.7.1 - 2026-10-19
- /fra notes and right-clicking the minimap button open or close the note window (on the newest note when it has no tabs). /fra still opens the main window.

## 0.7.0 - 2026-10-19
- Quick Notes: target markers ({rt1}-{rt8} or {star}, {circle}, {diamond}, {triangle}, {moon}, {square}, {cross}/{x}, {skull}) and ground markers ({wm1}-{wm8}) in note titles and text, drawn as icons in the note window, note list and chat line. The editor has a marker bar that inserts them at the cursor.
- Other "|" escape codes in notes now show as typed, so pushed notes can't draw anything but markers.

## 0.6.0 - 2026-10-19
- The addon is now a raid-night utility: raid planning is removed (raid catalog and data files for Barrow Deeps, Hyjal Summit, Onyxia's Lair and the Generic raid, boss sheets, the Raids screen, player picker and capability filters).
- Saved data schema 2: existing raid plans are deleted once on load, and the old Raids screen selection is cleared. Role tags, tools settings and notes are kept.
- Role tags stay on the roster as role markers.

## 0.5.0 - 2026-10-19
- Quick Notes (new sidebar entry after Tools): write notes of up to 2,000 characters, saved account-wide. The group leader or a raid assistant can push a note to everyone running the addon; pushing again updates their copy.
- Note window: received notes open as tabs in one movable, resizable window, each tab closable, with "Open in Quick Notes" to jump to the note in the planner.
- Addon-message transport (protocol version 1, prefix "FRA"): chunked under 255 bytes, paced, retries when throttled, held during boss encounters, accepts only leader/assistant senders and warns once about other versions.

## 0.4.0 - 2026-10-19
- Tools: choose whether this character uses its own settings or account-wide ones. Account settings start as a copy of the first character that switches to them.
- Roster: raid leaders and assistants can drag players between groups (drop on an empty slot to move, on a player to swap). The game makes the move and the cards follow the game's groups. Not available in combat.

## 0.3.1 - 2026-10-19
- Auto invite converts the party to a raid when members plus invites waiting for an answer would pass 5; whispers that arrive while the party is full are invited once the raid forms.

## 0.3.0 - 2026-10-19
- Tools screen (new sidebar entry) with per-character options.
- Combat logging: optionally starts the combat log when you enter a raid instance and asks whether to stop it when you leave.
- Auto invite: optionally invites players who whisper one of your invite words (comma-separated, default "inv, invite"). Works when solo, party leader, or raid leader or assistant; pauses during boss encounters.

## 0.2.0 - 2026-10-19
- Modern flat window: title bar with minimize and close, flat buttons, slot boxes and edit boxes, and sheet sections drawn as cards.
- Sidebar navigation: Home, then each raid, which expands into its General, Trash and boss pages with a count of filled slots; the page's assignments fill the rest of the window. The raid dropdown and page list are gone.
- Generic raid with 12 generic boss sheets for raids that have no data file yet.

## 0.1.0 - 2026-10-19
- Phase 1 (Core sheets): live roster with role tags, capability filters, raid catalog for Barrow Deeps, Hyjal Summit and Onyxia's Lair (provisional IDs), General/Trash/boss sheets with searchable player dropdowns, phases, clear and reset, minimap button, Addon Compartment entry and /fra.
