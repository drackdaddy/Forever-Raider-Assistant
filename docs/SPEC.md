# Raid Assignment Addon — Feature Spec (WoW: Forever)

Oct 19, 2026 · Rusty Martin

## Overview

This addon lets WoW: Forever raid leaders plan every boss and get each raider their jobs before the pull. It does five things:

1. **Hold the roster**: the live raid, a planned roster, an imported roster, or a saved raid team.
2. **Fill assignment sheets**: one per boss, built from templates (tanks, healers, raid markers, interrupts, dispels, crowd control, custom jobs).
3. **Draw position maps**: icons, freehand lines and text on a picture of each boss room.
4. **Share the plan**: post it to raid chat and push it to other players running the addon.
5. **Show each raider only their own jobs**, in a small window that follows the raid boss by boss.

Rosters and raid data files feed one plan per raid; chat posts, synced copies, both windows and backup strings are all views of that plan.

Platform facts that shape the design:

* **Content.** Raids open December 9, 2026 with Barrow Deeps (10-player), Hyjal Summit (20-player) and Onyxia's Lair (40-player), so the addon must handle 40 players from day one ([Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/raids/)).
* **Client.** Blizzard says Forever "shares Mainline WoW's UI architecture, including the vast majority of APIs available in 12.1.5", and Midnight's addon restrictions, secrets included, apply ([Icy Veins](https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/), [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes)).
* **Interface number.** It isn't published on the pages I checked. Read it from the beta client with /dump select(4, GetBuildInfo()).

## Ground rules

Six rules keep the addon self-contained, safe to publish, and inside Forever's addon limits.

* **Modern APIs only.** Use mainline APIs: Menu.ModifyMenu for right-click menus, the Settings panel, the Addon Compartment, and C\_ChatInfo for addon messages.
* **Data-driven content.** Each raid lives in its own data file. The UI and sync code never hard-code an encounter.
* **Planning, not automation.** The addon plans, shares and displays jobs. It never casts, targets, or reads combat data.
* **Your own or built-in art.** Use Blizzard's built-in textures and atlases for raid markers, class and role icons, and your own screenshots or drawings for room maps.
* **Libraries from upstream.** Get LibDeflate, Ace3, LibSerialize or LibDataBroker from each project's own source and keep each license file.
* **Your own identity and license.** Choose the addon name, slash commands, saved-variables name, addon-message prefix and export-string header, and pick an explicit license before publishing.

## Core features: roster and assignment engine

The engine is data-driven: each raid is a data file describing its bosses and fields, and the UI and sharing code never hard-code an encounter. The Phase column maps each feature to the build order at the end; change it as your plans change.

### Roster

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Live roster reader | Reads party or raid members (name, class, group, rank, game-assigned role, online state) for up to 8 groups of 5, and refreshes on roster and role changes. | 1 Core sheets |
| Leader role tags | The leader tags players as Main Tank, Off Tank or Healer on the roster screen. Tags feed the dropdown filters and auto-fill, and one button clears them all. | 1 Core sheets |
| Raid Builder | Plans a roster outside the raid on an 8 x 5 grid: type a name, pick class and spec (spec sets the role), drag to move or swap, clear a slot or the grid, and see class and role counts. | 4 Planning tools |
| Roster import | Pastes a JSON roster (group, slot, name, class, spec, color per player) from a web sign-up or comp tool into the Raid Builder, and reports rows it couldn't use. | 4 Planning tools |
| Saved raid teams | Saves roster, assignments and maps under a name in a searchable list. Loads a team into the Raid Builder, or loads only its assignments onto the live raid and reports assigned players who aren't there. | 4 Planning tools |
| Sort raid to plan | Lets the leader or an assistant move live players into the groups the plan shows. | 4 Planning tools |
| Roster quick actions | Right-clicking a roster slot sets a raid marker, sets Main Tank or Main Assist, promotes or demotes an assistant, passes lead, removes the player, or opens a whisper. | 4 Planning tools |
| Missing-player check | Lists assigned players who aren't in the raid, grouped by player with every job they hold. Each row jumps to its slot, and affected bosses and slots are highlighted. It re-checks on roster changes and after each push. | 4 Planning tools |

### Assignment engine

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Raid and boss catalog | One data file per raid lists bosses in kill order, each with a room picture and encounter icons. Every raid also gets a General page and a Trash page. | 1 Core sheets |
| Boss templates | Each boss lists target sections (tank slots, optional raid marker, healer slots, renamable pull-helper slots), ability rows such as "interrupt this spell", utility fields, and a short tactic hint. | 1 Core sheets |
| Field types | Supports single player, player list, player-to-target pairs (such as a mana cooldown on a healer), healer-to-target, raid marker plus player, fixed-choice dropdown, and free text. | 1 Core sheets |
| Phases and variants | Splits a sheet into phases (view one or all) and handles encounters that come in alternate versions. | 1 Core sheets |
| Capability filters | Dropdowns offer only eligible players: tanks, healers, interrupters, curse removers, magic dispellers, offensive dispellers, crowd control, fear protection, or a single class. The rules live in one table you fill from Forever's class kit, including race or talent limits where class alone isn't enough. | 1 Core sheets |
| Raid-wide defaults | The General page sets tanks and standing jobs for the whole raid. Every boss inherits them until you override them on that boss. | 1 Core sheets |
| Clear and reset | Clears the current boss or the whole raid, or resets a sheet to its template, after a confirmation. | 1 Core sheets |
| Auto-fill | Fills empty slots from the roster by filter, giving each job to the least-used eligible player and cycling raid markers across target sections. Player-to-target pairs stay manual. | 4 Planning tools |
| Unit right-click assign | Right-clicking a player on raid, party or target frames lets you put them into, or clear them from, any slot by browsing raid, boss and phase. | 4 Planning tools |
| Block preferences | Per user: favorite a block (pins it to a Favorites group), hide it (with a show-hidden toggle), collapse sections or all, and mark rows as tracked for the leader window. | 4 Planning tools |
| Boss order | Each raid has a boss order the leader can rearrange, with fixed encounters locked in place. The raider windows follow it. | 3 Raider windows |
| Kill auto-advance | When an encounter ends in a kill, the raider windows move to the next boss in the order. | 3 Raider windows |
| Assignment profiles | Named strategies per raid, organized into segments (General, Trash, each boss and phase). One profile is active per raid; profiles can be cloned, renamed and deleted, and a default is seeded from the built-in templates. | 6 Profiles & backup |
| Custom assignment builder | Builds a new assignment from ordered parts (text, a player field with filter and multi-select, a target field) with a live preview, and adds or removes rows on any block. | 6 Profiles & backup |

## UI features: windows, maps and settings

The addon has one main window for planning and two small overlays for raid night: a personal jobs window for every raider and a leader window for calling assignments.

### Main window

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Main window and navigation | A movable window with a left menu: Home, My jobs, Raids, Profiles, Settings, Info. It remembers the last raid, boss and page, can be minimized, and layers cleanly with other addon windows. | 1 Core sheets |
| Home screen | Roster source tabs (live raid, imported, Raid Builder, saved teams), a group grid of up to 8 groups (8 shown by default, since Onyxia's Lair is 40 players), class counts, and the role-tag toolbar. | 1 Core sheets |
| Raids screen | Raid dropdown, a boss list with General and Trash entries, a sheet/map toggle, phase and variant pickers, collapse-all, show-hidden, and buttons to share or announce, clear, auto-fill, load from a saved team, and request sync. | 1 Core sheets |
| Searchable player dropdowns | Type to filter, class-colored names, inline raid-marker icons, and an empty-state message when nobody qualifies. | 1 Core sheets |
| Read-only mode | When the leader locks editing, other players see the sheets greyed out with a one-line reason. | 2 Sharing |
| Profiles screen | A profile list with an options menu (activate, clone, export, delete), Assignments and Segments tabs, and the assignment editor with preview. | 6 Profiles & backup |

### Raid-night windows

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Personal jobs window | A small overlay with only your jobs for the current boss: boss header and counter, previous and next, and "no specific jobs" for bosses where you have none. It opens by itself when a push gives you jobs, waiting until you leave combat. | 3 Raider windows |
| Personal window options | Raid and boss dropdowns, current-raid-only, show only inside a raid instance, lock position, header and background toggles, transparency, minimize, and a request-sync button. | 3 Raider windows |
| Highlight colors | Separate colors for boss names, player names and ability words in the personal window, with an on/off switch. | 3 Raider windows |
| Leader window | A compact preview of tracked rows for the selected boss or phase, with an Announce button for the leader and assistants. Options hide the button and the phase and boss dropdowns, and set header, background, lock and transparency. | 3 Raider windows |

### Map planner

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Room map canvas | Each boss page has a map view on its room picture. General and Trash pages have none. | 5 Maps |
| Icon palette | Drag raid markers, role icons (tank, healer, melee, ranged), class icons and encounter icons onto the map, then move, resize (about 16 to 96 px) or delete them. The palette scrolls for large icon sets. | 5 Maps |
| Draw, erase and text tools | Freehand lines with a color picker, an eraser that removes any line, icon or text it touches, and text labels you can place, edit and move. | 5 Maps |
| Map storage | Maps are saved per boss and per saved team. When editing is locked, other players view them read-only. | 5 Maps |

### Settings and access

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Launchers | Minimap button (drag around the minimap, left-click for the main window, right-click for the personal window, tooltip), a LibDataBroker launcher for bars like Titan Panel, and an Addon Compartment entry. | 1 Core sheets |
| Slash commands | Open the window, push the plan, open the missing-player list, toggle auto-sync and compression, and open the sync debug log. | 1 Core sheets |
| Fast refresh | Views are marked dirty and redrawn once per frame, hidden pages aren't rebuilt, frames are pooled, and unchanged values aren't rewritten. Build this in from the start. | 1 Core sheets |
| Settings screen | Categories for Home (groups shown), Personal window, Highlights and Raid leader (lock, assistant permission, leader window), plus personal toggles for sync chat messages and button tooltips. | 3 Raider windows |
| Info screen | Version, slash command list and your support links. | 6 Profiles & backup |
| Sync debug log | A window listing sync traffic for troubleshooting, off by default. | 6 Profiles & backup |

## Communication: raid chat, sync and sharing

The plan reaches the raid three ways: posted to raid chat for everyone, synced to players running the addon, and copied out as text strings for backup or sharing between guilds.

| Feature | What it does | Phase |
| :---- | :---- | :---- |
| Raid chat announce | Posts the selected boss, or one phase, to raid chat. Only rows with someone assigned are sent, one section at a time with a short pause between sections (for example, 2 s between sections and 0.12 s between lines), with raid markers shown as chat icons. Leader and allowed assistants only. | 2 Sharing |
| Edit authority and lock | The raid leader owns the plan. An optional lock makes everyone else read-only, and a setting lets assistants edit and push too. Clients broadcast and request this policy so everyone agrees on it. | 2 Sharing |
| Push and clear | The leader sends the whole plan for the current raid (active profile plus values); receivers replace their copy of that raid only. A clear sends only the emptied values, so it fits in one or two messages. | 2 Sharing |
| Live edit sync | While the leader edits, each change sends only its scope: one boss sheet, the General sheet, or one boss map. Map changes go out when a stroke, icon move or text edit finishes. | 2 Sharing |
| Late-joiner catch-up | A player who joins or reloads asks for the plan. Only the leader answers, by whisper, and repeat requests from the same player are debounced. | 2 Sharing |
| Request sync button | Non-leaders pull the latest plan on demand from the personal window or the Raids screen, with a brief visual confirmation. | 2 Sharing |
| Reliable transport | Payloads are serialized, compressed and encoded, then split into numbered chunks under the 255-byte addon-message limit and paced. Receivers ask for missing chunks and give up only after a stretch of silence; stale transfers are pruned. | 2 Sharing |
| Version check | Clients swap versions when they join a group and warn once if someone runs a newer one. | 2 Sharing |
| Sync status messages | Short chat lines when a plan is sent or received, switchable per player. Errors always show. | 2 Sharing |
| Profile only when changed | Routine pushes carry a short token naming the active profile instead of the full profile. Receivers that don't have it ask for the full copy. | 6 Profiles & backup |
| Backup and share strings | Exports everything, one saved team, one raid's assignments, one boss's assignments, one boss map, or settings as a single string with a format version and checksum. Import shows what the string holds first, then adds it as a copy or overwrites after a second click. Per-machine settings such as window positions are never included. | 6 Profiles & backup |
| Profile import and export | Exports a whole profile, one segment or one assignment. Imports are validated (type, version, raid and boss ids, field shapes, sizes) before anything is saved, and never silently replace an existing profile. | 6 Profiles & backup |

Forever-specific rules to design around:

* **No comms during a pull.** Blizzard limited the Midnight addon-message and chat lockdown to "an active raid encounter or Mythic+ run" ([Icy Veins](https://www.icy-veins.com/wow/news/combat-addon-restrictions-eased-in-midnight/)). Queue any push, catch-up reply or announcement made mid-pull, send it when the encounter ends, and show "queued" in the UI. Test on the beta whether posting to raid chat is blocked too.
* **No combat data.** Don't depend on the combat log, cooldowns or auras. The addon needs only roster data plus encounter start, end and kill events; confirm those fire on Forever.
* **Trial accounts can't send addon messages** on Forever 1.60.1 ([Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes)). They can't request sync, so show them a short notice.
* **Use the client's tools.** Check SendAddonMessage's result code and back off when throttled, or use AceComm with ChatThrottleLib. If Forever exposes C\_EncodingUtil for compression and encoding, use it instead of shipping LibDeflate.

## Content for WoW: Forever

Ship data files for the three raids that open on December 9, 2026: 22 boss pages plus a General and a Trash page for each raid. Boss lists come from [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/raids/) and Warcraft Wiki ([Barrow Deeps](https://warcraft.wiki.gg/wiki/Barrow_Deeps_\(instance\)), [Hyjal Summit](https://warcraft.wiki.gg/wiki/Hyjal_Summit_\(instance\))); treat them as provisional until you've seen each fight on the beta.

| Raid | Players | Bosses, in order | Template notes |
| :---- | :---- | :---- | :---- |
| Barrow Deeps | 10 | Deepscar Matriarch, Khalith the Dreadspinner, Amethrax, Ravus and Darlissa, Elder Tangleclaw, Well of Sorrow, Del'lynar Songwood, Sonya Darkhallow | New raid, no published mechanics yet. Ravus and Darlissa needs one target section per boss. |
| Hyjal Summit | 20 | Bandalar, Time-Lost Battalion, Old Gloomlurker, Kathris the Haunted, Elder Minderel, Council of Thorns, The Wild King, Ancient of Decay, Sylvesteris Dusksong, Gharalis the Abyssal, Anara Chillwind, Tracker Stillwind, Nythus the Dreambound | New raid. Time-Lost Battalion and Council of Thorns look like multi-target fights. Sources spell three names differently (Minderel/Minderei, Sylvesteris/Sylvestris, Dreambound/Dreadbound). |
| Onyxia's Lair | 40 | Onyxia | Returning raid; attunement required. If the fight is unchanged, template it as three phases with tank, whelp-control, side-group and fear-protection jobs. |

* **Key bosses by encounter ID, not name.** Names differ between sources and client languages, so match raids and bosses by the instance and encounter IDs the game reports. Collect them on the beta.
* **Start new raids with generic templates.** Give each boss tank, healer, marker and interrupt rows, and add mechanic-specific jobs with the custom builder as fights become known.
* **Make your own room maps** from beta screenshots or simple schematics.
* **Expect more raids.** Two new raids are planned for spring 2027 and a revamped raid plus another new one for summer ([Icy Veins](https://www.icy-veins.com/wow-forever/news/blizzard-will-release-at-least-two-raids-every-tier-in-wow-forever/)). Adding a raid should mean adding a data file, with no code changes.
* **Build the capability table from Forever's class kit.** Check every interrupt, dispel, cleanse, crowd-control and fear-protection spell against Forever's classes and faction rules before filling the filters.

## Suggested build order

Build in six phases so you have a usable addon after phase 2, well before raids open on December 9. The phases match the Phase column in the tables above.

1. **Core sheets.** Raid files for the three Forever raids, live roster, role tags, capability filters, General and boss sheets with searchable dropdowns, clear and reset, launchers, slash commands and fast refresh. Done when a leader can fill a boss sheet from the live raid and it survives a reload.
2. **Sharing.** Raid chat announce, edit authority and lock, push and clear, live edit sync, catch-up, request sync, transport, version check and the mid-encounter queue. Done when two clients show the same sheet after a push, and a raider who reloads gets it back without asking.
3. **Raider windows.** Personal jobs window, highlights, leader window, boss order, kill auto-advance and the settings screen. Done when raiders see only their own jobs and the window moves on after a kill.
4. **Planning tools.** Raid Builder, roster import, saved teams, sort raid, roster quick actions, missing-player check, auto-fill, right-click assign and block preferences. Done when a team saved midweek loads onto raid night's group and flags who is missing.
5. **Maps.** Canvas, palette, draw, erase and text tools, storage and map sync. Done when a map the leader draws shows up on raiders' screens.
6. **Profiles and backup.** Assignment profiles, the custom builder, profile import and export, the profile token, backup strings, the info screen and the sync log. Done when a profile exported on one account imports cleanly on another.
