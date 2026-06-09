-- Table of English strings
-- Translate("ANIMATIONS_TOOLTIP")

L_enUS = {
    -----------------------------------------------
    -- UI Labels
    -----------------------------------------------
    ["DUNGEONS"]                  = "Dungeons",
    ["GENERAL"]                   = "General",
    ["BACK"]                      = "Back",
    ["POST_TO_CHAT"]              = "Post to chat",
    ["COPY_TEXT"]                 = "Copy Text",
    ["COMING_SOON"]               = "Coming soon",
    ["HIDE_DETAILS"]              = "Hide Details",
    ["SHOW_DETAILS"]              = "Show Details",
    ["THIS_WEEK_AFFIXES"]         = "This Week's Affixes",
    ["AFFIXES"]                   = "Affixes",
    ["AFFIXES_LOADING"]           = "Affixes not available yet. Try again soon.",

    -----------------------------------------------
    -- Quick Start Guide
    -----------------------------------------------
    ["QS_TITLE"]                  = "Welcome to Mythic Mentor!",
    ["QS_SUBTITLE"]               = "Choose how you want to use Mythic Mentor.\nYou can change these settings at any time in Settings.",
    ["QS_RECOMMENDED"]            = "Standard Setup.",
    ["QS_REC_DESC"]               = "A clean setup focused on tactics and the mini window for quick dungeon use.",
    ["QS_ADVANCED"]               = "Custom Setup.",
    ["QS_ADV_DESC"]               = "Choose exactly which features to enable in a guided step-by-step setup.",
    ["QS_SELECT_RECOMMENDED"]     = "Continue with Standard",
    ["QS_SELECT_ADVANCED"]        = "Build My Setup",
    ["QS_FEAT_TACTICS"]           = "Tactics",
    ["QS_FEAT_MINI"]              = "Mini Window",
    ["QS_FEAT_KEYS"]              = "Key Tracker",
    ["QS_FEAT_DCW"]               = "Dungeon Check",
    ["QS_FEAT_BRT"]               = "Battle Res Tracker",
    ["QS_FEAT_TELEPORT"]          = "Teleport",
    ["QS_FEAT_INVITE"]            = "Auto-Invite",
    ["QS_FOOTER"]                 = "All choices can be adjusted at any time in the Settings.",
    ["QS_SKIP"]                   = "Skip",
    -- Advanced wizard    
    ["QS_ADV_ENABLE"]             = "Enable",
    ["QS_ADV_DISABLE"]            = "Disable",
    ["QS_WIZARD_HINT"]            = "Go through each feature and choose whether to enable or disable it.",
    ["QS_FINISH"]                 = "Finish",
    ["QS_FINISH_TITLE"]           = "Setup Complete",
    ["QS_FINISH_BTN"]             = "Complete",
    ["QS_DESC_MINI"]              = "Adds a small window with boss tactics during Mythic+ dungeons. Automatically shows the current boss and tactics, and switches to the next boss automatically.",
    ["QS_DESC_KEYS"]              = "Tracks Mythic+ keystones for you and your group. Shows keys on the Start Page of the addon main window and inside the Group Finder panel.",
    ["QS_DESC_DCW"]               = "Opens a small checklist window before each dungeon starts. Shows your spec, role, durability, flask and food status. Party leaders can also run a ready check or countdown.",
    ["QS_DESC_BRT"]               = "Tracks Battle Rez charges and Cooldown to next charge in Mythic+ dungeons.",
    ["QS_DESC_TELEPORT"]          = "Makes the dungeon image clickable, allowing you to teleport directly to the dungeon from the Mythic+ tab in the Group Finder. Provides quick access to all your dungeon teleports.",
    ["QS_DESC_INVITE"]            = "Auto-invites players who whisper a keyword. Separate lists for friends/guild and others. Works inside messages like \"inv :D\".",
    
    -- Dungeon Check Window
    ["DCW_TITLE"]                 = "Check",
    ["DCW_DURABILITY"]            = "Durability",
    ["DCW_FLASK"]                 = "Flask",
    ["DCW_FOOD"]                  = "Food",
    ["DCW_ACTIVE"]                = "Active",
    ["DCW_NOT_APPLIED"]           = "Not applied",
    ["DCW_NONE_IN_BAGS"]          = "None in bags",
    ["DCW_READY_CHECK"]           = "Ready Check",
    ["DCW_COUNTDOWN"]             = "Countdown",
    ["DCW_CATE"]                  = "Dungeon Check",
    ["BRT_CATE"]                  = "Battle Res Tracker",
    ["BRT_ENABLED_TITLE"]         = "Enable Battle Res Tracker",
    ["BRT_ENABLED_TOOLTIP"]       = "On: The tracker window appears automatically when entering a dungeon.\n\nOff: The window never appears and uses no performance.",
    ["BRT_NO_BORDER_TITLE"]       = "Hide border",
    ["BRT_NO_BORDER_TOOLTIP"]     = "On: Removes the border from the Battle Res Tracker window.\n\nOff: Shows the border.",
    ["BRT_SCALE_TITLE"]           = "Window Scale",
    ["BRT_SCALE_TOOLTIP"]         = "Adjust the size of the Battle Res Tracker window (50% to 200%).",
    ["BRT_TRANSPARENT_TITLE"]     = "Background transparency",
    ["BRT_TRANSPARENT_TOOLTIP"]   = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["BRT_HIDE_TITLE_TITLE"]      = "Hide title and separator",
    ["BRT_HIDE_TITLE_TOOLTIP"]    = "On: Hides the \"Battle Res\" title text and the separator line.\n\nOff: Shows the title and separator.",
    ["BRT_LOCK_MOVE_TITLE"]       = "Lock position (require Shift to move)",
    ["BRT_LOCK_MOVE_TOOLTIP"]     = "On: You must hold Shift to drag the tracker. All clicks pass through the window.\n\nOff: The window behaves normally and can be moved by dragging.",
    ["BRT_OPEN_BTN"]              = "Open Tracker",
    ["BRT_OPEN_BTN_TOOLTIP"]      = "Open the Battle Res Tracker window.",
    ["DCW_SETTINGS_BEHAVIOR"]     = "Display / Checks",
    ["DCW_SHOW_SPEC_TITLE"]       = "Show Spec",
    ["DCW_SHOW_SPEC_TOOLTIP"]     = "On: Shows the specialization icon, name and role.\n\nOff: Hides the spec column.",
    ["DCW_SHOW_DUR_TITLE"]        = "Show Durability",
    ["DCW_SHOW_DUR_TOOLTIP"]      = "On: Shows the overall gear durability percentage.\n\nOff: Hides the durability column.",
    ["DCW_SHOW_FLASK_TITLE"]      = "Show Flask",
    ["DCW_SHOW_FLASK_TOOLTIP"]    = "On: Shows flask / phial buff status and bag count.\n\nOff: Hides the flask column.",
    ["DCW_SHOW_FOOD_TITLE"]       = "Show Food",
    ["DCW_SHOW_FOOD_TOOLTIP"]     = "On: Shows Well Fed food buff status and bag count.\n\nOff: Hides the food column.",
    ["DCW_SHOW_BTNS_TITLE"]       = "Show Buttons",
    ["DCW_SHOW_BTNS_TOOLTIP"]     = "On: Shows Ready Check and Countdown buttons (party leader only).\n\nOff: Hides the buttons.",
    ["DCW_NO_BORDER_TITLE"]       = "Hide border",
    ["DCW_NO_BORDER_TOOLTIP"]     = "On: Removes the border from the Dungeon Check window.\n\nOff: Shows the border.",
    ["DCW_LOCK_MOVE_TITLE"]       = "Lock position (require Shift to move)",
    ["DCW_LOCK_MOVE_TOOLTIP"]     = "On: You must hold Shift to drag the window. All clicks pass through the window.\n\nOff: The window behaves normally and can be moved by dragging.",
    ["DCW_TRANSPARENT_TITLE"]     = "Background transparency",
    ["DCW_TRANSPARENT_TOOLTIP"]   = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["DCW_SCALE_TITLE"]           = "Window Scale",
    ["DCW_SCALE_TOOLTIP"]         = "Adjust the size of the Dungeon Check window (50% to 200%).",
    ["DCW_ENABLED_TITLE"]         = "Enable Dungeon Check",
    ["DCW_ENABLED_TOOLTIP"]       = "On: Opens automatically when entering a Mythic+ dungeon. Shows spec, role, gear durability, flask and food status. Party leaders can run a Ready Check or Countdown. Closes automatically when the dungeon timer starts.\n\nOff: The window will never appear.",
    ["DCW_OPEN_BTN"]              = "Open Check Window",
    ["DCW_OPEN_BTN_TOOLTIP"]      = "Open the Dungeon Check window.",
    ["SETTINGS_HOVER_HINT"]       = "Hover over a setting to see info.",
    ["ROLE_TANK"]                 = "Tank",
    ["ROLE_HEALER"]               = "Healer",
    ["ROLE_DPS"]                  = "DPS",

    -----------------------------------------------
    -- settings
    -----------------------------------------------
    ["SETTINGS"]            = "Settings",

    -- category names
    ["GENERAL_CATE"]        = "General",
    ["AUTO_INVITE_CATE"]    = "Auto-Invite",
    ["MINI_WINDOW_CATE"]    = "Mini Window",

    -- text
    ["/RELOAD_TEXT"]        = "Tactics updated. Use /reload for UI translation.",  

    -- Section headers
    ["SETTINGS_DISPLAY_SECTION"]            = "Display",
    ["SETTINGS_BEHAVIOR_SECTION"]           = "Behavior",
    ["SETTINGS_MINIMAP_SECTION"]            = "Minimap",
    ["SETTINGS_APPEARANCE_SECTION"]         = "Appearance",
        
    -- Setting Main     
    ["SELECT_LANGUAGE_TITLE"]               = "Select Language",
    ["SCALE_SLIDER_TITLE"]                  = "Addon Scale",
    ["ANIMATIONS_COMBT_TITLE"]              = "Allow animations in combat",
    ["CLOSE_WINDOW_TITLE"]                  = "Close window on Post",
    ["ESC_CLOSE_TITLE"]                     = "Allow closing with ESC",
    ["AUTO_OPEN_NOTES_TITLE"]               = "Auto-open Boss Notes",
    ["MINIMAP_BTN_TITLE"]                   = "Hide minimap button",
        
    ["AUTO_INVITE_TITLE"]                   = "Enable Auto-Invite",
    ["TRIGGER_FRIENDLY_TITLE"]              = "Guild & Friends",
    ["TRIGGER_OTHER_TITLE"]                 = "Others",
    ["TRIGGER_INPUT_HINT"]                  = "Type and press Enter to add...",
    ["TRIGGER_NONE"]                        = "(none)",

    -- Mini Window settings
    ["MINI_WINDOW_SCALE_TITLE"]             = "Window Scale",
    ["MINI_WINDOW_SCALE_TOOLTIP"]           = "Adjust the size of the Mini Window (50% to 200%).",
    ["MINI_WINDOW_TRANSPARENT_TITLE"]       = "Background transparency",
    ["MINI_WINDOW_NO_BORDER_TITLE"]         = "Hide border",

    -- ToolTip settings
    ["LANGUAGE_TOOLTIP_1"]                  = "Choose the language used in Mythic Mentor.",
    ["LANGUAGE_TOOLTIP_2"]                  = "Click to open the list of available languages.",
    ["SCALE_TOOLTIP"]                       = "Changes the scale of the entire addon. Drag to change.",
    ["CURRENT_SCALE_TOOLTIP"]               = "Current: ",
    ["ANIMATIONS_TOOLTIP"]                  = "On: Animations play during combat.\n\nOff: Animations are disabled in combat (may improve performance).",
    ["CLOSE_WINDOW_TOOLTIP"]                = "On: Automatically closes the window after 'Post to chat' is pressed.\n\nOff: The window stays open after posting.",
    ["ESC_CLOSE_TOOLTIP"]                   = "On: The window can be closed by pressing ESC.\n\nOff: ESC does not close the window.",
    ["AUTO_OPEN_NOTES_TOOLTIP"]             = "On: Automatically opens the Boss Notes panel when selecting a boss (if notes exist).\n\nOff: The Boss Notes panel must be opened manually.",
    ["MINIMAP_BTN_TOOLTIP"]                 = "On: Hides the Mythic Mentor minimap button.\n\nOff: Shows the minimap button.",

    -- quick start
    ["QUICK_START_CARD"]                     = "Quick Start",
    ["QUICK_START_OPEN_BTN"]                 = "Open Setup Guide",
    ["QUICK_START_OPEN_BTN_TOOLTIP"]         = "Re-open the Setup Guide to reconfigure your profile settings.",

    ["AUTO_INVITE_TOOLTIP"]                 = "On: Players who whisper a configured trigger word are automatically invited to your group. Separate trigger word lists are available for guild/friends and everyone else.\n\nOff: No automatic invites are sent.",

    -- Mini Window
    ["MINI_WINDOW_TRANSPARENT_TOOLTIP"]     = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["MINI_WINDOW_NO_BORDER_TOOLTIP"]       = "On: Removes the border from the Mini Window.\n\nOff: Shows the border.",
    ["MINI_WINDOW_HIDE_SEP_TITLE"]          = "Hide separator",
    ["MINI_WINDOW_HIDE_SEP_TOOLTIP"]        = "On: Hides the thin separator line under the Mini Window header.\n\nOff: Shows the separator line.",
    ["MINI_WINDOW_ICONS_ONLY_TITLE"]        = "Icons only (hide button chrome)",
    ["MINI_WINDOW_ICONS_ONLY_TOOLTIP"]      = "On: Removes the background and border from the window buttons, showing only the icons.\n\nOff: Buttons are shown with their full background and border.",
    ["MINI_WINDOW_LOCK_MOVE_TITLE"]         = "Lock position (require Shift to move)",
    ["MINI_WINDOW_LOCK_MOVE_TOOLTIP"]       = "On: You must hold Shift to drag the window. All clicks pass through the window.\n\nOff: The window behaves normally and can be moved by dragging.",
    ["MINI_WINDOW_ENABLED_TITLE"]           = "Enable Mini Window",
    ["MINI_WINDOW_ENABLED_TOOLTIP"]         = "On: Opens automatically when entering a Mythic+ dungeon, showing tactics for the current boss encounter and switching to the next boss when the current one is defeated.\n\nOff: The Mini Window never appears.",
    ["MINI_WINDOW_AUTO_EXPAND_TITLE"]       = "Auto-expand on boss pull",
    ["MINI_WINDOW_AUTO_EXPAND_TOOLTIP"]     = "On: Automatically expands the Mini Window when a boss encounter starts, and minimizes it again when the boss dies.\n\nOff: The window stays in its current state.",
    ["MINI_WINDOW_AUTO_FADE_TITLE"]         = "Auto Fade (25%)",
    ["MINI_WINDOW_AUTO_FADE_TOOLTIP"]       = "Dims the mini window to 25% opacity when the mouse is not over it.",
    ["MINI_WINDOW_OPEN_BTN"]                = "Open Mini Window",
    ["MINI_WINDOW_OPEN_BTN_TOOLTIP"]        = "Open the Mini Window (same as /mmw).",
    ["MINI_WINDOW_FONT_SIZE_TITLE"]         = "Tactic text font size",
    ["MINI_WINDOW_FONT_SIZE_TOOLTIP"]       = "Adjust the font size of the tactic text inside the Mini Window.",

    -- Key Tracker category
    ["KEY_TRACKER_CATE"]                    = "Key Tracker",
    ["KEY_TRACKER_ENABLED_TITLE"]           = "Enable Key Tracker",
    ["KEY_TRACKER_ENABLED_TOOLTIP"]         = "On: Tracks keystones for you and your party, displaying them on the Start Page and in the Group Finder panel.\n\nOff: No keystone data is collected and tracker panels are hidden.",
    ["KEY_TRACKER_SECTION"]                 = "Display",
    ["KEY_TRACKER_STARTPAGE_TITLE"]         = "Show keys on Start Page",
    ["KEY_TRACKER_STARTPAGE_TOOLTIP"]       = "On: Shows the keystone tracker widget at the bottom of the Start Page.\n\nOff: Hides the tracker on the Start Page.",
    ["KEY_TRACKER_GROUPFINDER_TITLE"]       = "Show keys in Group Finder",
    ["KEY_TRACKER_GROUPFINDER_TOOLTIP"]     = "On: Shows the keystone tracker panel attached to the Group Finder window.\n\nOff: Hides the tracker panel in the Group Finder.",

    -- Group Finder panel appearance
    ["KEY_TRACKER_STARTPAGE_CARD"]          = "Start Page Tracker",
    ["KEY_TRACKER_GF_APPEARANCE"]           = "Group Finder Panel",
    ["KEY_TRACKER_GF_TRANSPARENT_TITLE"]    = "Background transparency",
    ["KEY_TRACKER_GF_TRANSPARENT_TOOLTIP"]  = "Adjust the background transparency (0% = fully transparent, 100% = opaque).",
    ["KEY_TRACKER_GF_NO_BORDER_TITLE"]      = "Hide border",
    ["KEY_TRACKER_GF_NO_BORDER_TOOLTIP"]    = "On: Removes the border from the Group Finder panel.\n\nOff: Shows the border.",
    ["KEY_TRACKER_GF_HIDE_TITLE_TITLE"]     = "Hide 'Keys' header",
    ["KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"]   = "On: Hides the 'Keys' label at the top of the Group Finder panel.\n\nOff: Shows the header.",
    ["NO_KEY"]                              = "No key",

    -- Teleport settings
    ["TELEPORT_CARD"]                       = "Teleport",
    ["TELEPORT_KEY_LIST_TITLE"]             = "Key List Teleport",
    ["TELEPORT_KEY_LIST_TOOLTIP"]           = "On: Click the dungeon icon on keystone rows (Group Finder panel) to teleport directly to that dungeon.\n\nOff: The dungeon icon is not clickable.",
    ["TELEPORT_KEY_CARD_TITLE"]             = "Key Card Teleport",
    ["TELEPORT_KEY_CARD_TOOLTIP"]           = "On: Click the dungeon icon on the start page key cards to teleport directly to that dungeon.\n\nOff: The dungeon icon is not clickable.",
    ["TELEPORT_MYTHIC_TAB_TITLE"]           = "Mythic+ Tab Teleport",
    ["TELEPORT_MYTHIC_TAB_TOOLTIP"]         = "On: Adds a clickable teleport button on each dungeon icon in the Mythic+ (Challenges) tab of the Group Finder.\n\nOff: No teleport buttons are added.",
    ["TELEPORT_IN_COMBAT"]                  = "Cannot teleport while in combat.",
    ["TELEPORT_READY"]                      = "Ready",
    ["TELEPORT_COOLDOWN"]                   = "Ready in: ",
    ["TELEPORT_NOT_LEARNED"]                = "Spell not learned.",

    -----------------------------------------------
    -- Start Side
    -----------------------------------------------

    -- Text
    ["SELECT_DUNGEON_HINT"]                 = "Select a dungeon in the left panel to view bosses and tactics.",
    ["START_PAGE_HIDE_GUIDE_TITLE"]         = "Hide start page guide",
    ["START_PAGE_HIDE_GUIDE_TOOLTIP"]       = "On: Hides the hint text on the start page and centers the logo.\n\nOff: Shows the hint text.",

    -----------------------------------------------
    -- Notes
    -----------------------------------------------

    -- Boss Notes
    ["BOSS_NOTES"]                          = "Boss Notes",
    ["BOSS_CLOSE_NOTE"]                     = "Close Note",
    ["ADD_NOTE_TIP"]                        = "Write note and press Enter:",

    -- General Notes    
    ["GENERAL_NOTES"]                       = "General Notes",
    ["ADD_CATEGORY"]                        = "New Category",
    ["DEFAULT_CATEGORY"]                    = "All",
    ["CONFIRM_DELETE_NOTE"]                 = "Are you sure you want to delete this note?",
    ["CONFIRM_DELETE_CATEGORY"]             = "Are you sure you want to delete this category and all its notes?",
    ["CONFIRM_DELETE_NOTE_TITLE"]           = "Delete Note",
    ["CONFIRM_DELETE_CATEGORY_TITLE"]       = "Delete Category",

    -----------------------------------------------
    -- Info panel
    -----------------------------------------------

    ["INFO"] = "Information",

    -----------------------------------------------
    -- Socials
    -----------------------------------------------
    ["DISCORD_TOOLTIP"]            = "Click to get the Discord link.",
    ["JOIN_DISCORD"]               = "Join Our Discord!",

    ["GITHUB_TOOLTIP"]             = "Click to get the GitHub link.",
    ["VISIT_GITHUB"]               = "Visit Our GitHub!",

    ["BUG_TOOLTIP"]                = "Click to report a bug",
    ["REPORT_BUG"]                 = "Report a Bug!",
    ["BUG_GUIDE"]                  = "Found a bug? Report it via Discord or GitHub Issues.",

    ["COPY_LINK"]                  = "Ctrl+C to copy link",
    ["COPY_HINT_TEXT"]             = "— closes window",
    ["UNKNOWN_BOSS"]               = "Unknown boss",
    ["TITAN_LEFT_CLICK"]           = "Left click: Open Mythic Mentor",
    ["TITAN_RIGHT_CLICK"]          = "Right click: Open menu",

    -----------------------------------------------
    -- Update banner
    -----------------------------------------------
    ["UPDATE_AVAILABLE_BANNER"]   = "New update available – Yours: %s  New: %s  (click to open)",

    -----------------------------------------------
    -- Edit Tactics
    -----------------------------------------------
    ["TACTIC_PLACEHOLDER"]        = "Write tactic here...",
    ["DELETE"]                    = "Delete",
    ["SAVE"]                      = "Save",
    ["SAVE_CHANGES"]              = "Save Changes",
    ["RESET"]                     = "Reset",
    ["CANCEL"]                    = "Cancel",
    ["EDIT_TACTICS_TOOLTIP"]      = "Edit Mode",
    ["EDIT_TACTICS_BETA_TITLE"]   = "Edit Tactics - Beta",
    ["EDIT_TACTICS_BETA_MSG"]     = "Editing boss tactics is a new feature.\n\nBugs may occur. If you find any issues, please report them on our Discord or GitHub.\n\nDo you want to continue?",
    ["FILTER_PHASE_TOOLTIP"]      = "Filter Phase",
    ["DELETE_PHASE_TITLE"]        = "Delete Phase",
    ["DELETE_PHASE_MSG"]          = "Are you sure you want to delete the phase '%s' and all its tactics?\n\nThis cannot be undone.",
    ["NEW_PHASE"]                 = "New Phase",
    ["NEW_PHASE_MSG"]             = "Enter the name of the new phase:",
    ["ADD_TACTIC_BTN"]            = "+ Add Tactic",
    ["RESET_TACTICS_TITLE"]       = "Reset Tactics",
    ["RESET_TACTICS_MSG"]         = "Are you sure you want to reset all tactics for this boss?\n\nThis cannot be undone.",
    ["RESET_ORDER"]               = "Reset Order",
    ["RESET_ORDER_TITLE"]         = "Reset Boss Order",
    ["RESET_ORDER_MSG"]           = "Are you sure you want to reset the custom boss sort order for this dungeon back to default?",
    ["UNSAVED_CHANGES_TITLE"]     = "Unsaved Changes",
    ["UNSAVED_CHANGES_MSG"]       = "You have unsaved changes.\n\nAre you sure you want to cancel without saving?",

    -----------------------------------------------
    -- Update popup
    -----------------------------------------------
    ["UPDATE_POPUP_TEXT"]         = "A new version of Mythic Mentor is available!\n\nYours: %s\nNew: %s\n\nOpen GitHub to update?",
    ["UPDATE_POPUP_BTN_GITHUB"]   = "GitHub",

    -----------------------------------------------
    -- Error / status messages
    -----------------------------------------------
    ["CMD_UI_NOT_READY"]          = "UI not ready yet. Try again in a moment.",
    ["CMD_UI_NOT_LOADED"]         = "BossUI not loaded.",
    ["CMD_DCW_NOT_LOADED"]        = "DungeonCheckWindow not loaded.",
    ["CHAT_SEND_FAILED"]          = "Chat send failed: ",
    ["CHAT_NOT_IN_GROUP"]         = "Not in a group – messages will only be shown to you.",
    ["INVITE_FN_UNAVAILABLE"]     = "Invite function not available.",
    ["INVITE_NOT_LEADER"]         = "You are not leader/assistant.",
    ["INVITE_FAILED_FOR"]         = "Invite failed for: ",
    ["ESC_REGISTER_FAILED"]       = "Cannot register frame for ESC-close (missing name).",
}

return L_enUS