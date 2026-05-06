### Changelog ###

#### v3.0.0 - May 6, 2026
## New
- Dungeon Check Window:
    - Appears automatically when entering a dungeon and auto-closes when dungeon starts.
    - Shows the player's specialization, roll and talent loadout.
    - Displays overall gear durability percentage.
    - Shows flask / food consumable status and bag counts.
    - Includes leader-only Ready Check & Countdown buttons.

- Mini Window:
    - added setting to enable/disable the Mini Window. When disabled the mini window is fully inactive (no timers, no event handlers, and no frame work) to avoid unnecessary performance cost.
    - added a button to open the Mini Window from Settings.
    - `/mmw` and the Settings button now fall back to the last-known dungeon or the first dungeon in `BossData.DungeonOrder` when no current dungeon is available.

- Key Tracker:
    - added setting to enable/disable the Key Tracker. When disabled no keystone data is collected and all key-tracker UI (Start Page widget and Group Finder panel) is hidden.
    - Keystone tracker implementation (LibKeystone callbacks and roster timers), `GroupFinderPanel` and `StartPage` now short-circuit and do no work when the Key Tracker is disabled.

- Settings:
    - Added "Hide start page guide" setting, hides the hint text on the start page and centers the logo in the panel.
    - Added custom checkbox and slider controls that match the addon's UI style.
    - Added inline-edit for slider values (click the numeric readout to type a value).
    - Added setting to hide the minimap button.
    - Added a settings info panel with images and descriptive text (replaces tooltips).
    - Added a new hover effect for settings: subtle top and bottom stripes appear on hover.
    - Added visual "gray-out" behavior for dependent settings when a feature is disabled: affected setting cards are dimmed and input is blocked until re-enabled.
    

- Teleports:
    - Added clickable Mythic+ dungeon images to teleport to that dungeon.
    - Added clickable images on Key Tracker (Key Cards and Key List) to teleport directly to the dungeon.

- Auto-Invite:
    - Added a multi-trigger Auto-Invite system with two separate trigger-word lists: "Guild & Friends" and "Others".
    - SavedVariables migration: existing single `triggerWord` is migrated automatically into the new `triggerWordsFriendly` list on first load.
    - Slash commands: `/mminv addfriendly|addother|removefriendly|removeother|list|debug` to manage triggers and debug mode.
    - Invite logic: detects guild members, Battle.net friends and friend-list friends; caches guild GUIDs and API references; uses safe invite call and group-permission checks.

- Added a small leader crown icon on the key image/card for the party leader uses (`Interface\\GroupFrame\\UI-Group-LeaderIcon`).

## Changed
- Key Tracker:
    - Refactored the Keystone widget to iterate unit slots (`player`, `party1`, ...) instead of matching names, more robust against realm/shortname variations.
    - The Keystone widget now hides in raids and only displays for party members.

- Settings:
    - Overhauled settings UI into card-style panels.
    - Card-based layout matching Edit Tactics visual style.
    - Two-column support so related settings can sit left/right.
    - Updated several setting labels to the gold color to match other UI labels; adjusted language dropdown width to match sliders.

- Info page:
    - Overhauled the Info page with a card-based layout matching the rest of the UI.
    - Added a reusable `MakeCard` builder exposing `add` / `fin` helpers for text, header, bullet, subbullet, keyval, and spacer row types.
    - Expanded from 4 categories to 6: About, Features, Changelog, Help, Commands, and Credits.

- UI:
    - Adjusted scroll frames to scroll by 20 px per step for smoother navigation.

- Locales:
    - Updated Russian and French boss tactics.

## Fixed
- Removed debug print on boss death (ENCOUNTER_END) that showed encounter/journal ID matching.

- Key Tracker:
    - Fixed an issue where a player could appear both with a keystone and as having no key.
    - Fixed an issue where the Key Card widget could appear on non-start pages (e.g. Settings or Info). The widget now respects being hidden and will not be shown by background refreshes.
    
- Settings:
    - Fixed slider tooltip formatting which previously showed very long floating-point values.

------------------------------------------------------------------------

# v2.1.0 - April 23, 2026
## New
- Small boss tactics window.
- M+ Key Tracking now shows all party keys.
- Added more small animations.

## Changes
- New icons (Close, Settings, Info, Notes, and Edit).
- Removed old images (now 1 MB, previously 3 MB).
- Removed small gaps between borders and backgrounds (buttons and panels).
- Overhauled the Affix tap now custom taktik to evry affix and beder guidning.
- Overhauled the Settings tab.
- Move the Vision nr over i højre side.
- Refactored codebase for better organization, modularity, and performance.

## Fixed
- Fixed Reset button in Edit Mode; now resets to original tactics.
- Fixed hover effect on buttons where the background visually grew beyond button borders.
- Fixed Boss Notes button sometimes remaining active when switching to another tab.

------------------------------------------------------------------------

# v2.0.0 - April 13, 2026
## New
- Edit Tactics: You can now edit all boss tactics or create your own
- Custom confirmation popups
- All tactics have been translated into Danish, German, French, and Russian

## Changes
- In active instances (e.g. Mythic+), a copy window is now shown since Blizzard’s chat lockdown system prevents addons from writing directly to chat during encounters.
- Updated left panel background to match the right panel design
- Changed button border color to dark grey instead of black
- Hover animation now only appears on hover (removed from de-hover state)

## Fixed
- Core: Added UI toggle, moved update-banner refresh into PLAYER_LOGIN, and made sound playback safe.
- Messaging: Fixed PlayButtonSound nil guard and stabilized the message queue.
- Auto-invite: Fixed slash command and removed unused global trigger; use Inviter.SetTrigger().
- Settings: Fixed language dropdown initial label bug, removed duplicate rightPanel declaration, and used Translate("SETTINGS").
- UI: Replaced hardcoded texts with localization keys; added UNKNOWN_BOSS and COPY_HINT_TEXT.
- Fixed missing image for Xenas Kasreth (Nexus-Point)

------------------------------------------------------------------------

# v1.3.3 - April 10, 2026
## Update
- Updated TOC

------------------------------------------------------------------------

# v1.3.2 - April 7, 2026
## New
- Auto-selects the current dungeon.

## Update
- Improved boss tactics.

## Fixed
- Fixed an issue where the button would sometimes turn black after hover; it now stays a consistent dark bluish color.

------------------------------------------------------------------------

# v1.3.1 - April 6, 2026
## Fixed
- Windrunner Spire dungeon not showing.

------------------------------------------------------------------------

# v1.3.0 - April 5, 2026
## New
- Added custom notes for bosses and general encounters
- Added affix information
- Introduced new settings options

## Update
- Added new boss tactics for Midnight
- Various minor improvements and optimizations for better performance and stability


------------------------------------------------------------------------

# v1.2.1 - Sep 15, 2025
## New
- Added Russian and German language support.

## Update
- Refined Boss tactics.
- Various minor improvements and optimizations for better performance and stability.

------------------------------------------------------------------------

# v1.2.0 - Sep 14, 2025
# Language Support & Improvements
## New
- Added language selection: English (default) and Danish, more languages coming soon.

## Update
- General improvements and optimizations for smoother performance.
- Updated TOC file for proper addon loading.

------------------------------------------------------------------------

# v1.1.0 - Sep 6, 2025
## Update
- Updated UI.
- Added setting to toggle closing the addon with ESC.
- Moved the Phase Button to the left.
- Small improvements.

------------------------------------------------------------------------

# v1.0.0 - Sep 5, 2025
## Note
- The very first public release of Mythic Mentor!
- Mythic Mentor is now officially live and ready to help you and your group tackle Mythic+ dungeons!

## Includes full core features:
- Boss tactics for every encounter.
- Party chat strategy sharing.
- Auto‑Invite system with custom keyword support (e.g., invite!).
- Titan Panel integration for quick access.