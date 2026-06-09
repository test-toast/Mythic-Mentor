-- Table of German strings
-- Translate("ANIMATIONS_TOOLTIP")

L_deDE = {
    -----------------------------------------------
    -- UI Labels
    -----------------------------------------------
    ["DUNGEONS"]                  = "Dungeons",
    ["GENERAL"]                   = "Allgemein",
    ["BACK"]                      = "Zurück",
    ["POST_TO_CHAT"]              = "Posten im Chat",
    ["COPY_TEXT"]                 = "Text kopieren",
    ["COMING_SOON"]               = "Demnächst",
    ["HIDE_DETAILS"]              = "Details ausblenden",
    ["SHOW_DETAILS"]              = "Details anzeigen",
    ["THIS_WEEK_AFFIXES"]         = "Affixe dieser Woche",
    ["AFFIXES"]                   = "Affixe",
    ["AFFIXES_LOADING"]           = "Affixe noch nicht verfügbar. Versuche es bald noch einmal.",

    -----------------------------------------------
    -- Quick Start Guide
    -----------------------------------------------
    ["QS_TITLE"]                  = "Willkommen bei Mythic Mentor!",
    ["QS_SUBTITLE"]               = "Wähle aus, wie du Mythic Mentor nutzen möchtest.\nDu kannst diese Einstellungen jederzeit in den Optionen ändern.",
    ["QS_RECOMMENDED"]            = "Standard-Setup",
    ["QS_REC_DESC"]               = "Ein klares Setup, das fokussiert auf Taktiken und das Mini-Fenster für den schnellen Einsatz im Dungeon ist.",
    ["QS_ADVANCED"]               = "Benutzerdefiniertes Setup",
    ["QS_ADV_DESC"]               = "Wähle in einer geführten Schritt-für-Schritt-Anleitung genau aus, welche Funktionen du aktivieren möchtest.",
    ["QS_SELECT_RECOMMENDED"]     = "Mit Standard fortfahren",
    ["QS_SELECT_ADVANCED"]        = "Mein Setup erstellen",
    ["QS_FEAT_TACTICS"]           = "Taktiken",
    ["QS_FEAT_MINI"]              = "Mini-Fenster",
    ["QS_FEAT_KEYS"]              = "Key-Tracker",
    ["QS_FEAT_DCW"]               = "Dungeon-Check",
    ["QS_FEAT_BRT"]               = "Wiederbelebungs-Tracker",
    ["QS_FEAT_TELEPORT"]          = "Teleport",
    ["QS_FEAT_INVITE"]            = "Auto-Einladen",
    ["QS_FOOTER"]                 = "Alle Auswahlmöglichkeiten können jederzeit in den Einstellungen angepasst werden.",
    ["QS_SKIP"]                   = "Überspringen",
    -- Advanced wizard    
    ["QS_ADV_ENABLE"]             = "Aktivieren",
    ["QS_ADV_DISABLE"]            = "Deaktivieren",
    ["QS_WIZARD_HINT"]            = "Gehe jede Funktion durch und wähle aus, ob du sie aktivieren oder deaktivieren möchtest.",
    ["QS_FINISH"]                 = "Fertigstellen",
    ["QS_FINISH_TITLE"]           = "Setup abgeschlossen",
    ["QS_FINISH_BTN"]             = "Abschließen",
    ["QS_DESC_MINI"]              = "Fügt während Mythic+ Dungeons ein kleines Fenster mit Boss-Taktiken hinzu. Zeigt automatisch den aktuellen Boss und die Taktiken an und wechselt automatisch zum nächsten Boss.",
    ["QS_DESC_KEYS"]              = "Verfolgt Mythic+ Schlüsselsteine für dich und deine Gruppe. Zeigt Schlüssel auf der Startseite des Addon-Hauptfensters und im Gruppensuche-Panel an.",
    ["QS_DESC_DCW"]               = "Öffnet vor jedem Dungeon-Start ein kleines Checklisten-Fenster. Zeigt deine Spezialisierung, Rolle, Haltbarkeit sowie Fläschchen- und Essensstatus an. Gruppenleiter können auch einen Bereitschaftscheck oder Countdown starten.",
    ["QS_DESC_BRT"]               = "Verfolgt die Aufladungen von Wiederbelebungen im Kampf (Battle Rez) und die Abklingzeit bis zur nächsten Aufladung in Mythic+ Dungeons.",
    ["QS_DESC_TELEPORT"]          = "Mach das Dungeon-Symbol anklickbar, sodass du dich direkt aus dem „Mythisch+“-Reiter im Dungeonbrowser dorthin teleportieren kannst. Bietet schnellen Zugriff auf alle deine Dungeon-Teleporte.",
    ["QS_DESC_INVITE"]            = "Lädt automatisch Spieler ein, die ein bestimmtes Schlüsselwort flüstern. Separate Listen für Freunde/Gilde und andere. Funktioniert auch innerhalb von Nachrichten wie \"inv :D\".",

    -----------------------------------------------
    -- Dungeon Check Window & Battle Res Tracker
    -----------------------------------------------
    ["DCW_TITLE"]                 = "Check",
    ["DCW_DURABILITY"]            = "Haltbarkeit",
    ["DCW_FLASK"]                 = "Fläschchen",
    ["DCW_FOOD"]                  = "Essen",
    ["DCW_ACTIVE"]                = "Aktiv",
    ["DCW_NOT_APPLIED"]           = "Nicht angewendet",
    ["DCW_NONE_IN_BAGS"]          = "Nichts in den Taschen",
    ["DCW_READY_CHECK"]           = "Bereitschaftscheck",
    ["DCW_COUNTDOWN"]             = "Countdown",
    ["DCW_CATE"]                  = "Dungeon-Check",
    ["BRT_CATE"]                  = "Battle Res Tracker",
    ["BRT_ENABLED_TITLE"]         = "Battle Res Tracker aktivieren",
    ["BRT_ENABLED_TOOLTIP"]       = "An: Das Fenster erscheint automatisch beim Betreten eines Dungeons.\n\nAus: Das Fenster erscheint niemals und verbraucht keine Leistung.",
    ["BRT_NO_BORDER_TITLE"]       = "Rahmen ausblenden",
    ["BRT_NO_BORDER_TOOLTIP"]     = "An: Entfernt den Rahmen des Battle Res Tracker-Fensters.\n\nAus: Der Rahmen wird angezeigt.",
    ["BRT_TRANSPARENT_TITLE"]     = "Hintergrundtransparenz",
    ["BRT_TRANSPARENT_TOOLTIP"]   = "Stellen Sie die Hintergrundtransparenz ein (0% = vollständig transparent, 100% = undurchsichtig).",
    ["BRT_SCALE_TITLE"]           = "Fenster-Skalierung",
    ["BRT_SCALE_TOOLTIP"]         = "Passe die Größe des Battle Res Tracker-Fensters an (50% bis 200%).",
    ["BRT_HIDE_TITLE_TITLE"]      = "Titel und Trennlinie ausblenden",
    ["BRT_HIDE_TITLE_TOOLTIP"]    = "An: Blendet den \"Battle Res\" Titeltext und die Trennlinie aus.\n\nAus: Titel und Trennlinie werden angezeigt.",
    ["BRT_LOCK_MOVE_TITLE"]       = "Position sperren (Shift zum Verschieben halten)",
    ["BRT_LOCK_MOVE_TOOLTIP"]     = "An: Shift muss gehalten werden, um den Tracker zu ziehen. Alle Klicks gehen durch das Fenster.\n\nAus: Das Fenster verhält sich normal und kann durch Ziehen verschoben werden.",
    ["BRT_OPEN_BTN"]              = "Tracker öffnen",
    ["BRT_OPEN_BTN_TOOLTIP"]      = "Das Battle Res Tracker-Fenster öffnen.",
    ["DCW_SETTINGS_BEHAVIOR"]     = "Anzeige / Checks",
    ["DCW_SETTINGS_APPEARANCE"]   = "Aussehen",
    ["DCW_SHOW_SPEC_TITLE"]       = "Spezialisierung anzeigen",
    ["DCW_SHOW_SPEC_TOOLTIP"]     = "An: Zeigt Spezialisierungssymbol, Name und Rolle.\n\nAus: Spalte wird ausgeblendet.",
    ["DCW_SHOW_DUR_TITLE"]        = "Haltbarkeit anzeigen",
    ["DCW_SHOW_DUR_TOOLTIP"]      = "An: Zeigt die gesamte Ausrüstungshaltbarkeit in Prozent.\n\nAus: Spalte wird ausgeblendet.",
    ["DCW_SHOW_FLASK_TITLE"]      = "Fläschchen anzeigen",
    ["DCW_SHOW_FLASK_TOOLTIP"]    = "An: Zeigt Fläschchen-/Fläschchen-Buff-Status und Anzahl in den Taschen.\n\nAus: Spalte wird ausgeblendet.",
    ["DCW_SHOW_FOOD_TITLE"]       = "Essen anzeigen",
    ["DCW_SHOW_FOOD_TOOLTIP"]     = "An: Zeigt 'Satt'-Buff-Status und Anzahl in den Taschen.\n\nAus: Spalte wird ausgeblendet.",
    ["DCW_SHOW_BTNS_TITLE"]       = "Buttons anzeigen",
    ["DCW_SHOW_BTNS_TOOLTIP"]     = "An: Zeigt Bereitschaftscheck- und Countdown-Buttons (nur Gruppenführer).\n\nAus: Buttons werden ausgeblendet.",
    ["DCW_NO_BORDER_TITLE"]       = "Rahmen ausblenden",
    ["DCW_NO_BORDER_TOOLTIP"]     = "An: Entfernt den Rahmen des Dungeon Check-Fensters.\n\nAus: Der Rahmen wird angezeigt.",
    ["DCW_LOCK_MOVE_TITLE"]       = "Position sperren (Shift zum Verschieben halten)",
    ["DCW_LOCK_MOVE_TOOLTIP"]     = "An: Shift muss gehalten werden, um das Fenster zu ziehen. Alle Klicks gehen durch das Fenster.\n\nAus: Das Fenster verhält sich normal und kann durch Ziehen verschoben werden.",
    ["DCW_TRANSPARENT_TITLE"]     = "Hintergrundtransparenz",
    ["DCW_TRANSPARENT_TOOLTIP"]   = "Stellen Sie die Hintergrundtransparenz ein (0% = vollständig transparent, 100% = undurchsichtig).",
    ["DCW_SCALE_TITLE"]           = "Fenster-Skalierung",
    ["DCW_SCALE_TOOLTIP"]         = "Passe die Größe des Dungeon Check-Fensters an (50% bis 200%).",
    ["DCW_ENABLED_TITLE"]         = "Dungeon-Check aktivieren",
    ["DCW_ENABLED_TOOLTIP"]       = "An: Öffnet sich automatisch beim Betreten eines Mythic+-Dungeons. Zeigt Spezialisierung, Rolle, Ausrüstungs-Haltbarkeit sowie Fläschchen- und Essensstatus. Gruppenleiter können einen Bereitschaftscheck oder Countdown starten. Schließt sich automatisch, wenn der Dungeon-Timer startet.\n\nAus: Das Fenster wird niemals angezeigt.",
    ["DCW_OPEN_BTN"]              = "Check-Fenster öffnen",
    ["DCW_OPEN_BTN_TOOLTIP"]      = "Das Dungeon Check-Fenster öffnen.",
    ["SETTINGS_HOVER_HINT"]       = "Fahre mit der Maus über eine Einstellung, um Infos zu sehen.",
    ["ROLE_TANK"]                 = "Tank",
    ["ROLE_HEALER"]               = "Heiler",
    ["ROLE_DPS"]                  = "DPS",

    -----------------------------------------------
    -- Settings
    -----------------------------------------------
    ["SETTINGS"]                  = "Einstellungen",

    -- category names
    ["GENERAL_CATE"]              = "Allgemein",
    ["AUTO_INVITE_CATE"]          = "Auto-Einladen",

    -- text
    ["/RELOAD_TEXT"]              = "Taktiken aktualisiert. Verwenden Sie /reload für die UI-Übersetzung.",

    -- Section headers
    ["SETTINGS_DISPLAY_SECTION"]            = "Anzeige",
    ["SETTINGS_BEHAVIOR_SECTION"]           = "Verhalten",
    ["SETTINGS_MINIMAP_SECTION"]            = "Minimap",
    ["SETTINGS_APPEARANCE_SECTION"]         = "Erscheinungsbild",

    -- Setting Main
    ["SELECT_LANGUAGE_TITLE"]               = "Sprache auswählen",
    ["SCALE_SLIDER_TITLE"]                  = "Addon-Skalierung",
    ["ANIMATIONS_COMBT_TITLE"]              = "Animationen im Kampf erlauben",
    ["CLOSE_WINDOW_TITLE"]                  = "Fenster nach 'Posten im Chat' schließen",
    ["ESC_CLOSE_TITLE"]                     = "Schließen mit ESC erlauben",
    ["AUTO_OPEN_NOTES_TITLE"]               = "Boss-Notizen automatisch öffnen",
    ["MINIMAP_BTN_TITLE"]                   = "Minimap-Schaltfläche ausblenden",

    ["AUTO_INVITE_TITLE"]                   = "Auto-Einladen aktivieren",
    ["TRIGGER_FRIENDLY_TITLE"]              = "Gilde & Freunde",
    ["TRIGGER_OTHER_TITLE"]                 = "Andere",
    ["TRIGGER_INPUT_HINT"]                  = "Eingeben und Enter drücken zum Hinzufügen...",
    ["TRIGGER_NONE"]                        = "(keine)",

    -- ToolTip settings         
    ["LANGUAGE_TOOLTIP_1"]                  = "Wählen Sie die Sprache für Mythic Mentor.",
    ["LANGUAGE_TOOLTIP_2"]                  = "Klicken Sie, um die Liste der verfügbaren Sprachen zu öffnen.",
    ["SCALE_TOOLTIP"]                       = "Ändert die Skalierung des gesamten Addons. Ziehen zum Ändern.",
    ["CURRENT_SCALE_TOOLTIP"]               = "Aktuell: ",
    ["ANIMATIONS_TOOLTIP"]                  = "An: Animationen werden im Kampf abgespielt.\n\nAus: Animationen sind im Kampf deaktiviert (kann die Leistung verbessern).",
    ["CLOSE_WINDOW_TOOLTIP"]                = "An: Schließt das Fenster automatisch nach dem Klick auf 'Posten im Chat'.\n\nAus: Das Fenster bleibt nach dem Posten geöffnet.",
    ["ESC_CLOSE_TOOLTIP"]                   = "An: Das Fenster kann mit ESC geschlossen werden.\n\nAus: ESC schließt das Fenster nicht.",
    ["AUTO_OPEN_NOTES_TOOLTIP"]             = "An: Öffnet automatisch das Boss-Notizen-Panel beim Auswählen eines Bosses (falls Notizen vorhanden).\n\nAus: Das Boss-Notizen-Panel muss manuell geöffnet werden.",
    ["MINIMAP_BTN_TOOLTIP"]                 = "An: Blendet die Mythic Mentor Minimap-Schaltfläche aus.\n\nAus: Die Minimap-Schaltfläche wird angezeigt.",

    ["QUICK_START_CARD"]                    = "Schnellstart",
    ["QUICK_START_OPEN_BTN"]                = "Setup-Assistenten öffnen",
["QUICK_START_OPEN_BTN_TOOLTIP"] = "Öffne den Setup-Assistenten erneut, um deine Profileinstellungen anzupassen.",

    ["AUTO_INVITE_TOOLTIP"]                 = "An: Spieler, die ein konfiguriertes Auslöserwort flüstern, werden automatisch in deine Gruppe eingeladen. Getrennte Auslöserlisten sind für Gilde/Freunde und alle anderen verfügbar.\n\nAus: Es werden keine automatischen Einladungen gesendet.",

    -- Mini Window settings
    ["MINI_WINDOW_CATE"]                    = "Mini-Fenster",
    ["MINI_WINDOW_SCALE_TITLE"]             = "Fenster-Skalierung",
    ["MINI_WINDOW_SCALE_TOOLTIP"]           = "Passe die Größe des Mini-Fensters an (50% bis 200%).",
    ["MINI_WINDOW_TRANSPARENT_TITLE"]       = "Hintergrundtransparenz",
    ["MINI_WINDOW_TRANSPARENT_TOOLTIP"]     = "Stellen Sie die Hintergrundtransparenz ein (0% = vollständig transparent, 100% = undurchsichtig).",
    ["MINI_WINDOW_NO_BORDER_TITLE"]         = "Rahmen ausblenden",
    ["MINI_WINDOW_NO_BORDER_TOOLTIP"]       = "An: Entfernt den Rahmen des Mini-Fensters.\n\nAus: Der Rahmen wird angezeigt.",
    ["MINI_WINDOW_HIDE_SEP_TITLE"]          = "Trennlinie ausblenden",
    ["MINI_WINDOW_HIDE_SEP_TOOLTIP"]        = "An: Versteckt die dünne Trennlinie unter der Mini-Fenster-Überschrift.\n\nAus: Die Trennlinie wird angezeigt.",
    ["MINI_WINDOW_ICONS_ONLY_TITLE"]        = "Nur Symbole (Knopf-Oberfläche ausblenden)",
    ["MINI_WINDOW_ICONS_ONLY_TOOLTIP"]      = "An: Entfernt Hintergrund und Rahmen der Fensterknöpfe, zeigt nur die Symbole.\n\nAus: Knöpfe werden mit vollem Hintergrund und Rahmen angezeigt.",
    ["MINI_WINDOW_LOCK_MOVE_TITLE"]         = "Position sperren (Shift zum Verschieben halten)",
    ["MINI_WINDOW_LOCK_MOVE_TOOLTIP"]       = "An: Shift muss gehalten werden, um das Fenster zu ziehen. Alle Klicks gehen durch das Fenster.\n\nAus: Das Fenster verhält sich normal und kann durch Ziehen verschoben werden.",
    ["MINI_WINDOW_ENABLED_TITLE"]           = "Mini-Fenster aktivieren",
    ["MINI_WINDOW_ENABLED_TOOLTIP"]         = "An: Öffnet sich automatisch beim Betreten eines Mythic+-Dungeons und zeigt Taktiken für den aktuellen Boss-Encounter. Wechselt automatisch zum nächsten Boss, wenn der aktuelle besiegt wurde.\n\nAus: Das Mini-Fenster erscheint niemals.",
    ["MINI_WINDOW_AUTO_EXPAND_TITLE"]       = "Auto-erweitern bei Boss-Pull",
    ["MINI_WINDOW_AUTO_EXPAND_TOOLTIP"]     = "An: Erweitert das Mini-Fenster automatisch, wenn ein Boss-Encounter beginnt, und minimiert es wieder, wenn der Boss besiegt wird.\n\nAus: Das Fenster bleibt in seinem aktuellen Zustand.",
    ["MINI_WINDOW_AUTO_FADE_TITLE"]         = "Automatisches Ausblenden (25%)",
    ["MINI_WINDOW_AUTO_FADE_TOOLTIP"]       = "Verringert die Deckkraft des Mini-Fensters auf 25%, wenn sich die Maus nicht darüber befindet.",
    ["MINI_WINDOW_OPEN_BTN"]                = "Mini-Fenster öffnen",
    ["MINI_WINDOW_OPEN_BTN_TOOLTIP"]        = "Öffnet das Mini-Fenster (gleich wie /mmw).",
    ["MINI_WINDOW_FONT_SIZE_TITLE"]         = "Schriftgröße des Taktiktexts",
    ["MINI_WINDOW_FONT_SIZE_TOOLTIP"]       = "Passt die Schriftgröße des Taktiktexts im Mini-Fenster an.",

    -- Key Tracker Kategorie
    ["KEY_TRACKER_CATE"]                    = "Key Tracker",
    ["KEY_TRACKER_SECTION"]                 = "Anzeige",
    ["KEY_TRACKER_STARTPAGE_TITLE"]         = "Keys auf Startseite anzeigen",
    ["KEY_TRACKER_STARTPAGE_TOOLTIP"]       = "Zeigt das Keystone-Widget unten auf der Startseite an.",
    ["KEY_TRACKER_GROUPFINDER_TITLE"]       = "Keys im Gruppensuche-Fenster anzeigen",
    ["KEY_TRACKER_GROUPFINDER_TOOLTIP"]     = "Zeigt das Keystone-Panel am Gruppensuche-Fenster an.",

    -- Gruppensuche-Panel Erscheinungsbild
    ["KEY_TRACKER_STARTPAGE_CARD"]          = "Startseite Tracker",
    ["KEY_TRACKER_GF_APPEARANCE"]           = "Gruppensuche-Panel",
    ["KEY_TRACKER_GF_TRANSPARENT_TITLE"]    = "Hintergrundtransparenz",
    ["KEY_TRACKER_GF_TRANSPARENT_TOOLTIP"]  = "Stellen Sie die Hintergrundtransparenz ein (0% = vollständig transparent, 100% = undurchsichtig).",
    ["KEY_TRACKER_GF_NO_BORDER_TITLE"]      = "Rahmen ausblenden",
    ["KEY_TRACKER_GF_NO_BORDER_TOOLTIP"]    = "An: Entfernt den Rahmen des Gruppensuche-Panels.\n\nAus: Der Rahmen wird angezeigt.",
    ["KEY_TRACKER_GF_HIDE_TITLE_TITLE"]     = "'Keys'-Überschrift ausblenden",
    ["KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"]   = "An: Blendet die 'Keys'-Beschriftung oben im Gruppensuche-Panel aus.\n\nAus: Die Überschrift wird angezeigt.",
    ["KEY_TRACKER_ENABLED_TITLE"]           = "Key Tracker aktivieren",
    ["KEY_TRACKER_ENABLED_TOOLTIP"]         = "Den Key Tracker aktivieren oder deaktivieren. Wenn aktiv, werden Keystones für dich und deine Gruppe verfolgt und auf der Startseite sowie im Gruppensuche-Panel angezeigt. Wenn deaktiviert, werden keine Keystonedaten gesammelt und die Tracker-Panels ausgeblendet.",
    ["NO_KEY"]                              = "Kein Key",

    -- Teleport-Einstellungen
    ["TELEPORT_CARD"]                       = "Teleport",
    ["TELEPORT_KEY_LIST_TITLE"]             = "Key List Teleport",
    ["TELEPORT_KEY_LIST_TOOLTIP"]           = "An: Klicken Sie auf das Dungeon-Symbol in Keystone-Zeilen (Gruppensuche-Panel), um direkt zu diesem Dungeon zu teleportieren.\n\nAus: Das Dungeon-Symbol ist nicht klickbar.",
    ["TELEPORT_KEY_CARD_TITLE"]             = "Key Card Teleport",
    ["TELEPORT_KEY_CARD_TOOLTIP"]           = "An: Klicken Sie auf das Dungeon-Symbol auf den Startseiten-Schlüsselkarten, um direkt zu diesem Dungeon zu teleportieren.\n\nAus: Das Dungeon-Symbol ist nicht klickbar.",
    ["TELEPORT_MYTHIC_TAB_TITLE"]           = "Mythic+ Tab Teleport",
    ["TELEPORT_MYTHIC_TAB_TOOLTIP"]         = "An: Fügt eine klickbare Teleport-Schaltfläche auf jedem Dungeon-Symbol im Mythic+-Reiter (Herausforderungen) der Gruppensuche hinzu.\n\nAus: Keine Teleport-Schaltflächen werden hinzugefügt.",
    ["TELEPORT_IN_COMBAT"]                  = "Teleportieren im Kampf nicht möglich.",
    ["TELEPORT_READY"]                      = "Bereit",
    ["TELEPORT_COOLDOWN"]                   = "Bereit in: ",
    ["TELEPORT_NOT_LEARNED"]                = "Zauber nicht erlernt.",

    -----------------------------------------------
    -- Start Side
    -----------------------------------------------
    ["SELECT_DUNGEON_HINT"]                 = "Wählen Sie einen Dungeon im linken Bereich aus, um Bosse und Taktiken anzuzeigen.",
    ["START_PAGE_HIDE_GUIDE_TITLE"]         = "Startseiten-Hinweis ausblenden",
    ["START_PAGE_HIDE_GUIDE_TOOLTIP"]       = "An: Blendet den Hinweistext auf der Startseite aus und zentriert das Logo.\n\nAus: Der Hinweistext wird angezeigt.",

    -----------------------------------------------
    -- Notes
    -----------------------------------------------
    -- Boss Notes
    ["BOSS_NOTES"]                          = "Boss-Notizen",
    ["BOSS_CLOSE_NOTE"]                     = "Notiz schließen",
    ["ADD_NOTE_TIP"]                        = "Notiz schreiben und Enter drücken:",

    -- General Notes            
    ["GENERAL_NOTES"]                       = "Allgemeine Notizen",
    ["ADD_CATEGORY"]                        = "Neue Kategorie",
    ["DEFAULT_CATEGORY"]                    = "Alle",
    ["CONFIRM_DELETE_NOTE"]                 = "Sind Sie sicher, dass Sie diese Notiz löschen möchten?",
    ["CONFIRM_DELETE_CATEGORY"]             = "Sind Sie sicher, dass Sie diese Kategorie und alle ihre Notizen löschen möchten?",
    ["CONFIRM_DELETE_NOTE_TITLE"]           = "Notiz löschen",
    ["CONFIRM_DELETE_CATEGORY_TITLE"]       = "Kategorie löschen",

    -----------------------------------------------
    -- Info panel
    -----------------------------------------------
    ["INFO"]                                = "Informationen",

    -----------------------------------------------
    -- Socials
    -----------------------------------------------
    ["DISCORD_TOOLTIP"]                     = "Klicken Sie, um den Discord-Link zu erhalten.",
    ["JOIN_DISCORD"]                        = "Tritt unserem Discord bei!",

    ["GITHUB_TOOLTIP"]                      = "Klicken Sie, um den GitHub-Link zu erhalten.",
    ["VISIT_GITHUB"]                        = "Besuche unser GitHub!",

    ["BUG_TOOLTIP"]                         = "Klicken Sie, um einen Fehler zu melden.",
    ["REPORT_BUG"]                          = "Fehler melden!",
    ["BUG_GUIDE"]                           = "Einen Fehler gefunden? Melde ihn über Discord oder GitHub Issues.",

    ["COPY_LINK"]                           = "Strg+C, um den Link zu kopieren",
    ["COPY_HINT_TEXT"]                      = "— schließt das Fenster",
    ["UNKNOWN_BOSS"]                        = "Unbekannter Boss",
    ["TITAN_LEFT_CLICK"]                    = "Linksklick: Mythic Mentor öffnen",
    ["TITAN_RIGHT_CLICK"]                   = "Rechtsklick: Menü öffnen",

    -----------------------------------------------
    -- Update banner
    -----------------------------------------------
    ["UPDATE_AVAILABLE_BANNER"]   = "Neues Update verfügbar – Deine: %s  Neu: %s  (zum Öffnen klicken)",

    -----------------------------------------------
    -- Edit Tactics
    -----------------------------------------------
    ["TACTIC_PLACEHOLDER"]        = "Taktik hier schreiben...",
    ["DELETE"]                    = "Löschen",
    ["SAVE"]                      = "Speichern",
    ["SAVE_CHANGES"]              = "Änderungen speichern",
    ["RESET"]                     = "Zurücksetzen",
    ["CANCEL"]                    = "Abbrechen",
    ["EDIT_TACTICS_TOOLTIP"]      = "Taktiken bearbeiten",
    ["EDIT_TACTICS_BETA_TITLE"]   = "Taktiken bearbeiten - Beta",
    ["EDIT_TACTICS_BETA_MSG"]     = "Das Bearbeiten von Boss-Taktiken ist eine neue Funktion.\n\nEs können Fehler auftreten. Wenn du Probleme findest, melde sie bitte auf unserem Discord oder GitHub.\n\nMöchtest du fortfahren?",
    ["FILTER_PHASE_TOOLTIP"]      = "Phase filtern",
    ["DELETE_PHASE_TITLE"]        = "Phase löschen",
    ["DELETE_PHASE_MSG"]          = "Bist du sicher, dass du die Phase '%s' und alle ihre Taktiken löschen möchtest?\n\nDies kann nicht rückgängig gemacht werden.",
    ["NEW_PHASE"]                 = "Neue Phase",
    ["NEW_PHASE_MSG"]             = "Gib den Namen der neuen Phase ein:",
    ["ADD_TACTIC_BTN"]            = "+ Taktik hinzufügen",
    ["RESET_TACTICS_TITLE"]       = "Taktiken zurücksetzen",
    ["RESET_TACTICS_MSG"]         = "Bist du sicher, dass du alle Taktiken für diesen Boss zurücksetzen möchtest?\n\nDies kann nicht rückgängig gemacht werden.",
    ["RESET_ORDER"]               = "Reihenfolge zurücksetzen",
    ["RESET_ORDER_TITLE"]         = "Boss-Reihenfolge zurücksetzen",
    ["RESET_ORDER_MSG"]           = "Bist du sicher, dass du die benutzerdefinierte Boss-Sortierreihenfolge für diesen Dungeon auf die Standardeinstellung zurücksetzen möchtest?",
    ["UNSAVED_CHANGES_TITLE"]     = "Ungespeicherte Änderungen",
    ["UNSAVED_CHANGES_MSG"]       = "Du hast ungespeicherte Änderungen.\n\nBist du sicher, dass du abbrechen möchtest, ohne zu speichern?",

    -----------------------------------------------
    -- Update popup
    -----------------------------------------------
    ["UPDATE_POPUP_TEXT"]         = "Eine neue Version von Mythic Mentor ist verfügbar!\n\nDeine: %s\nNeu: %s\n\nGitHub öffnen, um zu aktualisieren?",
    ["UPDATE_POPUP_BTN_GITHUB"]   = "GitHub",

    -----------------------------------------------
    -- Fehler- / Statusmeldungen
    -----------------------------------------------
    ["CMD_UI_NOT_READY"]          = "Benutzeroberfläche noch nicht bereit. Bitte erneut versuchen.",
    ["CMD_UI_NOT_LOADED"]         = "BossUI nicht geladen.",
    ["CMD_DCW_NOT_LOADED"]        = "DungeonCheckWindow nicht geladen.",
    ["CHAT_SEND_FAILED"]          = "Chat-Senden fehlgeschlagen: ",
    ["CHAT_NOT_IN_GROUP"]         = "Nicht in einer Gruppe – Nachrichten werden nur dir angezeigt.",
    ["INVITE_FN_UNAVAILABLE"]     = "Einladefunktion nicht verfügbar.",
    ["INVITE_NOT_LEADER"]         = "Du bist kein Gruppenleiter/Assistent.",
    ["INVITE_FAILED_FOR"]         = "Einladung fehlgeschlagen für: ",
    ["ESC_REGISTER_FAILED"]       = "Frame kann nicht für ESC-Schließen registriert werden (fehlender Name).",
}

return L_deDE