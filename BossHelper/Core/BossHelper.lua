-- BossHelper.lua
BossHelper = {}

--------------------------------------------------------------------------------
-- Addon metadata and version helpers
--------------------------------------------------------------------------------
BossHelper.ADDON_NAME = "BossHelper"

--------------------------------------------------------------------------------
-- Central locale registry
-- key    = internal locale code
-- label  = display name shown in Settings
-- suffix = global variable suffix used by dungeon files (e.g. "_daDK")
-- Adding a new language only requires one entry here + its Locale/Dungeon files.
--------------------------------------------------------------------------------
BossHelper.LOCALES = {
    { key = "enUS", label = "English", suffix = ""      },
    { key = "daDK", label = "Danish",  suffix = "_daDK" },
    { key = "ruRU", label = "Russian", suffix = "_ruRU" },
    { key = "deDE", label = "German",  suffix = "_deDE" },
    { key = "frFR", label = "French",  suffix = "_frFR" },
}

-- Chat message color tags (centralized so all files use the same colors)
BossHelper.CHAT_TAG     = "|cff00ff00[MythicMentor]|r"
BossHelper.CHAT_TAG_ERR = "|cffff5555[MythicMentor]|r"

--------------------------------------------------------------------------------
-- Centralized external links
-- Change links here once – all popups and UI elements pick them up automatically.
--------------------------------------------------------------------------------
BossHelper.Links = {
    DISCORD       = "https://discord.gg/sYFdZDPKr3",
    GITHUB        = "https://github.com/test-toast/Mythic-Mentor",
    GITHUB_ISSUES = "https://github.com/test-toast/Mythic-Mentor/issues",
    CURSEFORGE    = "https://www.curseforge.com/wow/addons/mythic-mentor",
}

--------------------------------------------------------------------------------
-- Default SavedVariables values
-- ApplyDefaults() iterates this table so adding a new setting only requires
-- one entry here instead of an extra if-nil block in the ADDON_LOADED handler.
--------------------------------------------------------------------------------
BossHelper.DB_DEFAULTS = {
-- General settings
    language                   = "enUS",
    scale                      = 1.0,
    allowAnimationsInCombat    = true,
    closeOnPost                = false,
    allowEscClose              = true,
    autoOpenBossNotes          = true,
    hideStartPageGuide         = false,

-- teleport settings
    teleportOnMythicTab        = true,

-- Auto-invite settings
    autoInviteEnabled          = false,

-- mini-window settings
    miniWindowEnabled          = true,
    miniWindowTransparency     = 0.95,
    miniWindowNoBorder         = false,
    miniWindowHideSeparator    = false,
    miniWindowHideButtonChrome = false,
    miniWindowAutoExpand       = false,

-- Key tracking settings    
    keyTrackerEnabled          = true,
    showKeysOnStartPage        = true,
    showKeysInGroupFinder      = true,
    teleportOnKeyCards         = true,
    teleportOnKeyList          = true,
    gfPanelTransparency        = 0.95,
    gfNoBorder                 = false,
    gfHideTitle                = false,

-- Dungeon Check Window settings
    dcwEnabled                 = true,
    dcwNoBorder                = false,
    dcwTransparency            = 0.95,
    dcwShowSpec                = true,
    dcwShowDurability          = true,
    dcwShowFlask               = true,
    dcwShowFood                = true,
    dcwShowButtons             = true,
}

function BossHelper:ApplyDefaults()
    BossHelperDB = BossHelperDB or {}
    for key, default in pairs(self.DB_DEFAULTS) do
        if BossHelperDB[key] == nil then
            BossHelperDB[key] = default
        end
    end
end

--------------------------------------------------------------------------------
-- Shared safe UI utilities
-- Available as BossHelper.UI.hide(obj) etc. from any file, removing the need
-- for each module to define its own local phide/psetparent/… copies.
--------------------------------------------------------------------------------
BossHelper.UI = {}

function BossHelper.UI.hide(obj)
    if not obj then return end
    pcall(function() if obj.Hide then obj:Hide() end end)
end

function BossHelper.UI.setParent(obj, p)
    if not obj then return end
    pcall(function() if obj.SetParent then obj:SetParent(p) end end)
end

function BossHelper.UI.clearPoints(obj)
    if not obj then return end
    pcall(function() if obj.ClearAllPoints then obj:ClearAllPoints() end end)
end

function BossHelper.UI.setText(obj, txt)
    if not obj then return end
    pcall(function() if obj.SetText then obj:SetText(txt) end end)
end

function BossHelper.UI.destroyWidget(w)
    BossHelper.UI.hide(w)
    BossHelper.UI.setParent(w, nil)
    BossHelper.UI.clearPoints(w)
end

--------------------------------------------------------------------------------
-- Shared backdrop presets  (avoid copy-pasting the same 7-line table)
-- Usage:  frame:SetBackdrop(BossHelper.UI.Backdrop.FRAME)
--    or   BossHelper.UI.ApplyBackdrop(frame, "FRAME", bgColor, borderColor)
--------------------------------------------------------------------------------
local _BGFILE  = "Interface/Buttons/WHITE8X8"
local _EDGEFILE = "Interface/Tooltips/UI-Tooltip-Border"

BossHelper.UI.Backdrop = {
    FRAME   = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=16, insets={left=3,right=3,top=3,bottom=3} },
    NORMAL  = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=16, insets={left=3,right=3,top=3,bottom=3} },
    EDITBOX = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=16, insets={left=3,right=3,top=3,bottom=3} },
    SMALL   = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=12, insets={left=3,right=3,top=3,bottom=3} },
    ITEM    = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=12, insets={left=3,right=3,top=3,bottom=3} },
    BTN     = { bgFile=_BGFILE, edgeFile=_EDGEFILE, tile=true, tileSize=16, edgeSize=12, insets={left=3,right=3,top=3,bottom=3} },
}

-- Color palette  (avoid repeating raw RGBA floats throughout the UI code)
-- Usage:  local C = BossHelper.UI.C
--         frame:SetBackdropColor(C.BG_DARK[1], C.BG_DARK[2], C.BG_DARK[3], C.BG_DARK[4])
--    or   BossHelper.UI.ApplyBackdrop(frame, "NORMAL", C.BG_DARK, C.BORDER_GREY)
BossHelper.UI.C = {
    BG_DARK               = {0.06, 0.07, 0.11, 0.95},
    BG_DARK_90            = {0.06, 0.07, 0.11, 0.9 },
    BG_DARK_OPAQUE        = {0.06, 0.07, 0.11, 0.98},
    BG_VERY_DARK          = {0.02, 0.03, 0.06, 1   },
    BG_FOCUSED            = {0.08, 0.07, 0.05, 1   },
    BG_PANEL              = {0.08, 0.08, 0.15, 0.9 },
    BG_PANEL_DARK         = {0.08, 0.08, 0.15, 0.95},
    BG_RED                = {0.35, 0.07, 0.07, 0.9 },
    BORDER_GREY           = {0.3,  0.3,  0.3,  0.8},
    BORDER_DARK_BLUE      = {0.12, 0.15, 0.26, 1  },
    BORDER_AMBER          = {1,    0.5,  0,    0.8},
    BORDER_ORANGE         = {1,    0.6,  0.2,  0.6},
    BORDER_ORANGE_MED     = {1,    0.6,  0.2,  0.8},
    BORDER_ORANGE_BRIGHT  = {1,    0.6,  0.2,  0.9},
    BORDER_RED            = {0.6,  0.18, 0.18, 0.8},
    TEXT_GOLD             = {0.95, 0.85, 0.6 },
    TEXT_ORANGE           = {0.98, 0.82, 0.55},
}

-- Apply a standard backdrop + optional colors to a BackdropTemplate frame in one call.
-- variant     = "FRAME" | "NORMAL" | "EDITBOX" | "SMALL" | "BTN"
-- bgColor     = RGBA array from BossHelper.UI.C, or nil to skip
-- borderColor = RGBA array from BossHelper.UI.C, or nil to skip
function BossHelper.UI.ApplyBackdrop(frame, variant, bgColor, borderColor)
    frame:SetBackdrop(BossHelper.UI.Backdrop[variant or "NORMAL"])
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    end
    if borderColor then
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    end
end

local function _GetTOCMetadata(field)
    local v
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        v = C_AddOns.GetAddOnMetadata(BossHelper.ADDON_NAME, field)
    elseif GetAddOnMetadata then
        v = GetAddOnMetadata(BossHelper.ADDON_NAME, field)
    end
    return v
end

BossHelper.VERSION_STRING = (_GetTOCMetadata and _GetTOCMetadata("Version")) or "0.0.0"

-- Compare semantic-ish versions like "1.2.3"; returns -1, 0, 1
function BossHelper:CompareVersions(a, b)
    if a == b then return 0 end
    local function split(ver)
        local out = {}
        ver = tostring(ver or "0")
        for num in ver:gmatch("%d+") do
            table.insert(out, tonumber(num) or 0)
        end
        return out
    end
    local aa, bb = split(a), split(b)
    local n = math.max(#aa, #bb)
    for i = 1, n do
        local x = aa[i] or 0
        local y = bb[i] or 0
        if x < y then return -1 end
        if x > y then return 1 end
    end
    return 0
end

--------------------------------------------------------------------------------
-- Centralized sound IDs
-- Reference BossHelper.Sounds.X instead of hardcoding numbers anywhere.
--------------------------------------------------------------------------------
BossHelper.Sounds = {
    NORMAL_BUTTON  = 1115,    -- knap-klik (generisk)
    BOSS_SELECT    = 841,     -- vælg boss
    DUNGEON_SELECT = 841,     -- vælg dungeon
    POST_TO_CHAT   = 271864,  -- send til chat afsluttet
    BACK_BUTTON    = 84240,   -- back-knap
    OPEN_SETTINGS  = 84240,   -- åbn indstillinger
    CLOSE_SETTINGS = 84240,   -- luk indstillinger
    OPEN_MENU      = 175320,  -- åbn addon
    CLOSE_MENU     = 170887,  -- luk addon
}

--------------------------------------------------------------------------------
-- Centralized text color codes for [category:text] markup
-- Reference BossHelper.COLOR_TAGS.X instead of hardcoding hex-values.
--------------------------------------------------------------------------------
BossHelper.COLOR_TAGS = {
    Boss          = "|cFFFF6600",   -- dyb orange
    BossAbilities = "|cFFFF0000",   -- rød
    Buff          = "|cFF00FF00",   -- grøn
    Debuff        = "|cFFFFAA33",   -- mørk orange
    Objectives    = "|cFF3399FF",   -- blå
    Miscellaneous = "|cFF00FFFF",   -- cyan
    Important     = "|cFFCC00FF",   -- lilla
}

--------------------------------------------------------------------------------
-- Hent Mythic+ dungeons
--------------------------------------------------------------------------------
function BossHelper:GetMythicPlusDungeons()
    local dungeons = {}
    for i, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
        local name, _, _, textureID = C_ChallengeMode.GetMapUIInfo(mapID)
        if name and textureID then
            table.insert(dungeons, {id = mapID, name = name, texture = textureID})
        end
    end
    return dungeons
end

--------------------------------------------------------------------------------
-- Localisering af UI
--------------------------------------------------------------------------------
-- Load the correct locale table. Locale tables follow the naming convention L_{key}.
-- Adding a new language only requires adding it to BossHelper.LOCALES above.
function BossHelper:LoadLocale()
    BossHelperDB = BossHelperDB or {}
    BossHelper.selectedLocale = BossHelperDB.language or "enUS"
    self.Lfile = _G["L_" .. BossHelper.selectedLocale] or L_enUS
end
-- Load default locale at startup
BossHelper:LoadLocale()

--------------------------------------------------------------------------------
-- load localized string som Loadlocale file with global function
--------------------------------------------------------------------------------
function BossHelper:Translate(key)
    if self.Lfile and self.Lfile[key] then
        return self.Lfile[key]
    else
        return key -- fallback to key if not found
    end
end

Translate = function(key) return BossHelper:Translate(key) end


--------------------------------------------------------------------------------
-- Sikker afspilning af lyd
--------------------------------------------------------------------------------
function BossHelper:SafePlaySound(soundId)
    if type(soundId) ~= "number" then return end
    if not PlaySound then return end
    pcall(PlaySound, soundId)
end

-- Chat-systemet (kø + throttling + SendSmartMessage/SendSingleSmartMessage)
-- er flyttet til Chat.lua som loades efter denne fil.

--------------------------------------------------------------------------------
-- Encounter Journal hjælpefunktioner
--------------------------------------------------------------------------------

-- Hent bossens navn fra Encounter Journal via journalEncounterID
function BossHelper:GetBossName(encounterID)
    if not encounterID or encounterID <= 0 then return nil end
    return (EJ_GetEncounterInfo(encounterID))
end

-- GetDungeonEncounterID er defineret i EncounterIDLookup.lua

-- Hent dungeonens navn fra Encounter Journal via instanceID
function BossHelper:GetDungeonName(instanceID)
    if not instanceID or instanceID <= 0 then return nil end
    return (EJ_GetInstanceInfo(instanceID))
end

-- Hent dungeon-teksturens fileID via ChallengeMode API (matcher på EJ-navn)
function BossHelper:GetDungeonTextureID(instanceID)
    if not instanceID or instanceID <= 0 then return nil end
    local ejName = self:GetDungeonName(instanceID)
    if not ejName then return nil end
    for _, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
        local name, _, _, textureID = C_ChallengeMode.GetMapUIInfo(mapID)
        if name == ejName and textureID and textureID ~= 0 then
            return textureID
        end
    end
    return nil
end

-- Slår boss-portræt op direkte via encounterID (ingen navne-søgning)
function BossHelper:GetBossPortraitFileID(encounterID, bossData)
    if bossData and bossData.icon then
        return bossData.icon
    end
    if not encounterID or encounterID <= 0 then return nil end
    local _, _, _, _, iconFile = EJ_GetCreatureInfo(1, encounterID)
    if iconFile then
        if bossData then bossData.icon = iconFile end
        return iconFile
    end
    return nil
end

-- SendDungeonMessages er flyttet til Chat.lua

--------------------------------------------------------------------------------
-- Loader events
--------------------------------------------------------------------------------
local _loader = CreateFrame("Frame")
_loader:RegisterEvent("ADDON_LOADED")
_loader:RegisterEvent("PLAYER_LOGIN")

_loader:SetScript("OnEvent", function(self, event, ...)
    local arg1 = select(1, ...)
    if event == "ADDON_LOADED" and arg1 == "BossHelper" then
        -- Sørg for at SavedVariables tabellen eksisterer
        BossHelperDB = BossHelperDB or {}
        -- load localisering file
        BossHelper:LoadLocale()
        BossData:Load(BossHelper.selectedLocale)

        -- Apply all default settings from the central DB_DEFAULTS table
        BossHelper:ApplyDefaults()

        -- Ved reload: nulstil panelvalg så General Notes ikke åbner automatisk
        if BossHelperDB.lastOpenPanel == "info" or BossHelperDB.lastOpenPanel == "notes" then
            BossHelperDB.lastOpenPanel = nil
        end

        -- Opret UI hvis BossUI er klar
        if BossUI and BossUI.CreateUI then
            BossUI:CreateUI()
            BossHelper._uiCreated = true
        end

        -- Registrer ESC-lukning hvis indstillingen er aktiv
        if BossUI and BossUI.GetFrame then
            local f = BossUI:GetFrame()
            if f then
                BossHelper:RegisterEscClose(f)
            end
        end

        -- Fjern ADDON_LOADED, da vi ikke behøver at køre det igen
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        BossHelperDB = BossHelperDB or {}
        BossHelper:ApplyDefaults()

        -- Register addon message prefix for version checks
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            pcall(C_ChatInfo.RegisterAddonMessagePrefix, BossHelper.VERSION_PREFIX)
        end

        -- notifiedLatestVersion is populated lazily when a newer version is detected

        -- Sørg for at UI'et er oprettet ved login
        if BossUI and BossUI.CreateUI and not BossHelper._uiCreated then
            BossUI:CreateUI()
            BossHelper._uiCreated = true
        end

        -- Registrer ESC-lukning efter login også
        if BossUI and BossUI.GetFrame then
            local f = BossUI:GetFrame()
            if f then
                BossHelper:RegisterEscClose(f)
            end
        end

        -- Delay initial version broadcast slightly to ensure channel join completed
        if C_Timer and C_Timer.After then
            C_Timer.After(5, function()
                BossHelper:BroadcastVersion()
                -- Refresh update banner now that SavedVariables and UI are ready
                if BossUI and BossUI.RefreshUpdateBanner then
                    BossUI:RefreshUpdateBanner()
                end
            end)
        else
            -- Fallback immediate send
            BossHelper:BroadcastVersion()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- New group formed or changed; rebroadcast version (throttled by timer)
        if C_Timer and C_Timer.After then
            if not BossHelper._pendingVersionBroadcast then
                BossHelper._pendingVersionBroadcast = true
                C_Timer.After(3, function()
                    BossHelper._pendingVersionBroadcast = false
                    BossHelper:BroadcastVersion()
                end)
            end
        else
            BossHelper:BroadcastVersion()
        end
    elseif event == "CHAT_MSG_ADDON" then
        -- For CHAT_MSG_ADDON the handler receives: prefix (arg1), message, channel, sender, ...
        local prefix, message, channel, sender = ...
        if prefix == BossHelper.VERSION_PREFIX and type(message) == "string" then
            BossHelper:HandleIncomingVersion(message, sender)
        end
    end
end)

-- Register additional events after frame exists
_loader:RegisterEvent("GROUP_ROSTER_UPDATE")
_loader:RegisterEvent("CHAT_MSG_ADDON")

-- BroadcastVersion / HandleIncomingVersion / ShowUpdatePopup er flyttet til Version.lua

--------------------------------------------------------------------------------
-- Toggle the main UI frame
--------------------------------------------------------------------------------
function BossHelper:Toggle()
    if BossUI and BossUI.GetFrame then
        local f = BossUI:GetFrame()
        if f then
            if f:IsShown() then
                f:Hide()
            else
                f:Show()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Init (kan bruges til at registrere flere events senere)
--------------------------------------------------------------------------------
function BossHelper:Init()
    -- Placeholder
end
