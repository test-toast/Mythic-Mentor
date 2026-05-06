-- Table of English strings
-- Translate("ANIMATIONS_TOOLTIP")
L_enUS = {
    -----------------------------------------------
    -- UI Labels
    -----------------------------------------------
    ["DUNGEONS"] = "Dungeons",
    ["GENERAL"] = "General",
    ["BACK"] = "Back",
    ["POST_TO_CHAT"] = "Post to chat",
    ["COPY_TEXT"] = "Copy Text",
    ["COMING_SOON"] = "Coming soon",
    ["HIDE_DETAILS"] = "Hide Details",
    ["SHOW_DETAILS"] = "Show Details",
    ["THIS_WEEK_AFFIXES"] = "This Week's Affixes",
    ["AFFIXES"] = "Affixes",
    ["AFFIXES_LOADING"] = "Affixes not available yet. Try again soon.",

    -- Dungeon Check Window
    ["DCW_TITLE"] = "Check",
    ["DCW_DURABILITY"] = "Durability",
    ["DCW_FLASK"] = "Flask",
    ["DCW_FOOD"] = "Food",
    ["DCW_ACTIVE"] = "Active",
    ["DCW_NOT_APPLIED"] = "Not applied",
    ["DCW_NONE_IN_BAGS"] = "None in bags",
    ["DCW_READY_CHECK"] = "Ready Check",
    ["DCW_COUNTDOWN"] = "Countdown",
    ["DCW_CATE"] = "Dungeon Check",
    ["DCW_SETTINGS_BEHAVIOR"] = "Display / Checks",
    ["DCW_SETTINGS_APPEARANCE"] = "Appearance",
    ["DCW_SHOW_SPEC_TITLE"] = "Show Spec",
    ["DCW_SHOW_SPEC_TOOLTIP"] = "Show the specialization icon, name and role.",
    ["DCW_SHOW_DUR_TITLE"] = "Show Durability",
    ["DCW_SHOW_DUR_TOOLTIP"] = "Show the overall gear durability percentage.",
    ["DCW_SHOW_FLASK_TITLE"] = "Show Flask",
    ["DCW_SHOW_FLASK_TOOLTIP"] = "Show flask / phial buff status and bag count.",
    ["DCW_SHOW_FOOD_TITLE"] = "Show Food",
    ["DCW_SHOW_FOOD_TOOLTIP"] = "Show Well Fed food buff status and bag count.",
    ["DCW_SHOW_BTNS_TITLE"] = "Show Buttons",
    ["DCW_SHOW_BTNS_TOOLTIP"] = "Show Ready Check and Countdown buttons (party leader only).",
    ["DCW_NO_BORDER_TITLE"] = "Hide border",
    ["DCW_NO_BORDER_TOOLTIP"] = "Remove the border from the Dungeon Check window.",
    ["DCW_TRANSPARENT_TITLE"] = "Background transparency",
    ["DCW_TRANSPARENT_TOOLTIP"] = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["DCW_ENABLED_TITLE"] = "Enable Dungeon Check",
    ["DCW_ENABLED_TOOLTIP"] = "Enable or disable the Dungeon Check. When active, opens automatically when entering a Mythic+ dungeon. Shows spec, role, gear durability, flask and food status. Party leaders can run a Ready Check or Countdown from this window. Closes automatically when the dungeon timer starts. When disabled, the window will never appear.",
    ["DCW_OPEN_BTN"] = "Open Check Window",
    ["DCW_OPEN_BTN_TOOLTIP"] = "Open the Dungeon Check window.",
    ["SETTINGS_HOVER_HINT"] = "Hover over a setting to see info.",
    ["ROLE_TANK"] = "Tank",
    ["ROLE_HEALER"] = "Healer",
    ["ROLE_DPS"] = "DPS",


    -----------------------------------------------
    -- settings
    -----------------------------------------------
    ["SETTINGS"] = "Settings",

    -- category names
    ["GENERAL_CATE"] = "General",
    ["AUTO_INVITE_CATE"] = "Auto-Invite",
    ["MINI_WINDOW_CATE"] = "Mini Window",

    -- text
    ["/RELOAD_TEXT"] = "Tactics updated. Use /reload for UI translation.",

    -- Section headers
    ["SETTINGS_DISPLAY_SECTION"] = "Display",
    ["SETTINGS_BEHAVIOR_SECTION"] = "Behavior",
    ["SETTINGS_MINIMAP_SECTION"] = "Minimap",
    ["SETTINGS_APPEARANCE_SECTION"] = "Appearance",

    -- Setting Main
    ["SELECT_LANGUAGE_TITLE"] = "Select Language",
    ["SCALE_SLIDER_TITLE"] = "Addon Scale",
    ["ANIMATIONS_COMBT_TITLE"] = "Allow animations in combat",
    ["CLOSE_WINDOW_TITLE"] = "Close window on Post",
    ["ESC_CLOSE_TITLE"] = "Allow closing with ESC",
    ["AUTO_OPEN_NOTES_TITLE"] = "Auto-open Boss Notes",
    ["MINIMAP_BTN_TITLE"] = "Hide minimap button",

    ["AUTO_INVITE_TITLE"]      = "Enable Auto-Invite",
    ["TRIGGER_FRIENDLY_TITLE"] = "Guild & Friends",
    ["TRIGGER_OTHER_TITLE"]    = "Others",
    ["TRIGGER_INPUT_HINT"]     = "Type and press Enter to add...",
    ["TRIGGER_NONE"]           = "(none)",

    -- Mini Window settings
    ["MINI_WINDOW_TRANSPARENT_TITLE"] = "Background transparency",
    ["MINI_WINDOW_NO_BORDER_TITLE"] = "Hide border",

    -- ToolTip settings
    ["LANGUAGE_TOOLTIP_1"] = "Choose the language used in Mythic Mentor.",
    ["LANGUAGE_TOOLTIP_2"] = "Click to open the list of available languages.",
    ["SCALE_TOOLTIP"] = "Changes the scale of the entire addon. Drag to change.",
    ["CURRENT_SCALE_TOOLTIP"] = "Current: ",
    ["ANIMATIONS_TOOLTIP"] = "Play animations in combat.",
    ["CLOSE_WINDOW_TOOLTIP"] = "Close window after 'Post to chat' is pressed.",
    ["ESC_CLOSE_TOOLTIP"] = "Close window with ESC.",
    ["AUTO_OPEN_NOTES_TOOLTIP"] = "Automatically open the Boss Notes panel\nwhen selecting a boss (if notes exist).",
    ["MINIMAP_BTN_TOOLTIP"] = "Hide or show the minimap button for Mythic Mentor.",

    ["AUTO_INVITE_TOOLTIP"] = "Enable or disable Auto-Invite. When active, players who whisper a configured trigger word are automatically invited to your group. Separate trigger word lists are available for guild/friends and everyone else.",

    ["MINI_WINDOW_TRANSPARENT_TOOLTIP"] = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["MINI_WINDOW_NO_BORDER_TOOLTIP"] = "Removes the border from the Mini Window.",
    ["MINI_WINDOW_HIDE_SEP_TITLE"] = "Hide separator",
    ["MINI_WINDOW_HIDE_SEP_TOOLTIP"] = "Hide the thin separator line under the Mini Window header.",
    ["MINI_WINDOW_ICONS_ONLY_TITLE"] = "Icons only (hide button chrome)",
    ["MINI_WINDOW_ICONS_ONLY_TOOLTIP"] = "Remove the background and border from the window buttons, showing only the icons.",
    ["MINI_WINDOW_ENABLED_TITLE"] = "Enable Mini Window",
    ["MINI_WINDOW_ENABLED_TOOLTIP"] = "Enable or disable the Mini Window. When active, opens automatically when entering a Mythic+ dungeon, showing tactics for the current boss encounter and automatically switching to the next boss when the current one is defeated.",
    ["MINI_WINDOW_AUTO_EXPAND_TITLE"] = "Auto-expand on boss pull",
    ["MINI_WINDOW_AUTO_EXPAND_TOOLTIP"] = "Automatically expand the Mini Window when a boss encounter starts, and minimize it again when the boss dies.",
    ["MINI_WINDOW_OPEN_BTN"] = "Open Mini Window",
    ["MINI_WINDOW_OPEN_BTN_TOOLTIP"] = "Open the Mini Window (same as /mmw).",

    -- Key Tracker category
    ["KEY_TRACKER_CATE"] = "Key Tracker",
    ["KEY_TRACKER_ENABLED_TITLE"] = "Enable Key Tracker",
    ["KEY_TRACKER_ENABLED_TOOLTIP"] = "Enable or disable the Key Tracker. When active, it tracks keystones for you and your party, displaying them on the Start Page and in the Group Finder panel. When disabled, no keystone data is collected and tracker panels are hidden.",
    ["KEY_TRACKER_SECTION"] = "Display",
    ["KEY_TRACKER_STARTPAGE_TITLE"] = "Show keys on Start Page",
    ["KEY_TRACKER_STARTPAGE_TOOLTIP"] = "Show the keystone tracker widget at the bottom of the Start Page.",
    ["KEY_TRACKER_GROUPFINDER_TITLE"] = "Show keys in Group Finder",
    ["KEY_TRACKER_GROUPFINDER_TOOLTIP"] = "Show the keystone tracker panel attached to the Group Finder window.",

    -- Group Finder panel appearance
    ["KEY_TRACKER_STARTPAGE_CARD"] = "Start Page Tracker",
    ["KEY_TRACKER_GF_APPEARANCE"] = "Group Finder Panel",
    ["KEY_TRACKER_GF_TRANSPARENT_TITLE"] = "Background transparency",
    ["KEY_TRACKER_GF_TRANSPARENT_TOOLTIP"] = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["KEY_TRACKER_GF_NO_BORDER_TITLE"] = "Hide border",
    ["KEY_TRACKER_GF_NO_BORDER_TOOLTIP"] = "Removes the border from the Group Finder panel.",
    ["KEY_TRACKER_GF_HIDE_TITLE_TITLE"] = "Hide 'Keys' header",
    ["KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"] = "Hides the 'Keys' label at the top of the Group Finder panel.",
    ["NO_KEY"] = "No key",

    -- Teleport settings
    ["TELEPORT_CARD"] = "Teleport",
    ["TELEPORT_KEY_CARDS_TITLE"] = "Key Card Teleport",
    ["TELEPORT_KEY_CARDS_TOOLTIP"] = "Click the dungeon image on keystone cards (Start Page) to teleport directly to that dungeon.",
    ["TELEPORT_KEY_LIST_TITLE"] = "Key List Teleport",
    ["TELEPORT_KEY_LIST_TOOLTIP"] = "Click the dungeon icon on keystone rows (Group Finder panel) to teleport directly to that dungeon.",
    ["TELEPORT_MYTHIC_TAB_TITLE"] = "Mythic+ Tab Teleport",
    ["TELEPORT_MYTHIC_TAB_TOOLTIP"] = "Adds a clickable teleport button on each dungeon icon in the Mythic+ (Challenges) tab of the Group Finder.",
    ["TELEPORT_IN_COMBAT"] = "Cannot teleport while in combat.",
    ["TELEPORT_READY"] = "Ready",
    ["TELEPORT_COOLDOWN"] = "Ready in: ",
    ["TELEPORT_NOT_LEARNED"] = "Spell not learned.",

    -----------------------------------------------
    -- Start Side
    -----------------------------------------------

    -- Text
    ["SELECT_DUNGEON_HINT"] = "Select a dungeon in the left panel to view bosses and tactics.",
    ["START_PAGE_HIDE_GUIDE_TITLE"] = "Hide start page guide",
    ["START_PAGE_HIDE_GUIDE_TOOLTIP"] = "Hide the hint text on the start page and center the logo.",

    -----------------------------------------------
    -- Notes
    -----------------------------------------------

    -- Boss Notes
    ["BOSS_NOTES"] = "Boss Notes",
    ["BOSS_CLOSE_NOTE"] = "Close Note",
    ["ADD_NOTE_TIP"] = "Write note and press Enter:",

    -- General Notes
    ["GENERAL_NOTES"] = "General Notes",
    ["ADD_CATEGORY"] = "New Category",
    ["DEFAULT_CATEGORY"] = "All",
    ["CONFIRM_DELETE_NOTE"] = "Are you sure you want to delete this note?",
    ["CONFIRM_DELETE_CATEGORY"] = "Are you sure you want to delete this category and all its notes?",
    ["CONFIRM_DELETE_NOTE_TITLE"] = "Delete Note",
    ["CONFIRM_DELETE_CATEGORY_TITLE"] = "Delete Category",


    -----------------------------------------------
    -- Info panel
    -----------------------------------------------

    ["INFO"] = "Information",


    -----------------------------------------------
    -- Socials
    -----------------------------------------------
    ["DISCORD_TOOLTIP"] = "Click to get the Discord link.",
    ["JOIN_DISCORD"] = "Join Our Discord!",

    ["GITHUB_TOOLTIP"] = "Click to get the GitHub link.",
    ["VISIT_GITHUB"] = "Visit Our GitHub!",

    ["BUG_TOOLTIP"] = "Click to report a bug",
    ["REPORT_BUG"] = "Report a Bug!",
    ["BUG_GUIDE"] = "Found a bug? Report it via Discord or GitHub Issues.",


    ["COPY_LINK"] = "Ctrl+C to copy link",
    ["COPY_HINT_TEXT"] = "— closes window",
    ["UNKNOWN_BOSS"] = "Unknown boss",
    ["TITAN_LEFT_CLICK"] = "Left click: Open Mythic Mentor",
    ["TITAN_RIGHT_CLICK"] = "Right click: Open menu",

    -----------------------------------------------
    -- Update banner
    -----------------------------------------------
    ["UPDATE_AVAILABLE_BANNER"] = "New update available – Yours: %s  New: %s  (click to open)",

    -----------------------------------------------
    -- Edit Tactics
    -----------------------------------------------
    ["TACTIC_PLACEHOLDER"] = "Write tactic here...",
    ["DELETE"] = "Delete",
    ["SAVE"] = "Save",
    ["RESET"] = "Reset",
    ["CANCEL"] = "Cancel",
    ["EDIT_TACTICS_TOOLTIP"] = "Edit Tactics",
    ["EDIT_TACTICS_BETA_TITLE"] = "Edit Tactics - Beta",
    ["EDIT_TACTICS_BETA_MSG"] = "Editing boss tactics is a new feature.\n\nBugs may occur. If you find any issues, please report them on our Discord or GitHub.\n\nDo you want to continue?",
    ["FILTER_PHASE_TOOLTIP"] = "Filter Phase",
    ["DELETE_PHASE_TITLE"] = "Delete Phase",
    ["DELETE_PHASE_MSG"] = "Are you sure you want to delete the phase '%s' and all its tactics?\n\nThis cannot be undone.",
    ["ADD_TACTIC_BTN"] = "+ Add Tactic",
    ["RESET_TACTICS_TITLE"] = "Reset Tactics",
    ["RESET_TACTICS_MSG"] = "Are you sure you want to reset all tactics for this boss?\n\nThis cannot be undone.",
    ["UNSAVED_CHANGES_TITLE"] = "Unsaved Changes",
    ["UNSAVED_CHANGES_MSG"] = "You have unsaved changes.\n\nAre you sure you want to cancel without saving?",

    -----------------------------------------------
    -- Update popup
    -----------------------------------------------
    ["UPDATE_POPUP_TEXT"] = "A new version of Mythic Mentor is available!\n\nYours: %s\nNew: %s\n\nOpen GitHub to update?",
    ["UPDATE_POPUP_BTN_GITHUB"] = "GitHub",

    -----------------------------------------------
    -- Error / status messages
    -----------------------------------------------
    ["CMD_UI_NOT_READY"]      = "UI not ready yet. Try again in a moment.",
    ["CMD_UI_NOT_LOADED"]     = "BossUI not loaded.",
    ["CMD_DCW_NOT_LOADED"]    = "DungeonCheckWindow not loaded.",
    ["CHAT_SEND_FAILED"]      = "Chat send failed: ",
    ["CHAT_NOT_IN_GROUP"]     = "Not in a group – messages will only be shown to you.",
    ["INVITE_FN_UNAVAILABLE"] = "Invite function not available.",
    ["INVITE_NOT_LEADER"]     = "You are not leader/assistant.",
    ["INVITE_FAILED_FOR"]     = "Invite failed for: ",
    ["ESC_REGISTER_FAILED"]   = "Cannot register frame for ESC-close (missing name).",
}

return L_enUS