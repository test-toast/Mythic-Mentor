-- MiniWindow.lua
-- Kompakt mini-vindue der viser boss-taktikker automatisk ved dungeon-entry.
-- Åbnes/lukkes med /mmw. Genbruger præcis samme dungeon-detection som BossUI.lua.

MiniWindow = MiniWindow or {}

-- ---------------------------------------------------------------------------
-- Modul-tilstand
-- ---------------------------------------------------------------------------
local currentDungeonKey     = nil
local currentBossIndex      = 1
local currentPhaseIndex     = 1      -- aktiv fase-indeks for nuværende boss
local lastBossIndexForPhase = -1     -- bruges til reset af fase ved boss-skift
local miniFrame             = nil    -- lazy-oprettet
local miniMinimized         = false  -- kollaps-tilstand

-- ---------------------------------------------------------------------------
-- Layout-konstanter  (saml alle dimensioner ét sted for nem justering)
-- ---------------------------------------------------------------------------
local LAYOUT = {
    W        = 300,
    FULL_H   = 250,
    HEADER_H = 44,
    PADDING  = 8,

    -- Header
    PORTRAIT_W = 52,
    PORTRAIT_H = 40,
    TITLE_X    = 64,
    SEP_Y      = -42,

    -- Fase-dropdown bar
    PHASE_BAR_Y         = -47,
    PHASE_BAR_H         = 24,
    PHASE_BTN_W         = 160,
    PHASE_BTN_H         = 22,
    PHASE_ITEM_H        = 24,
    PHASE_PANEL_LEVEL   = 2000,
    PHASE_CATCHER_LEVEL = 1999,

    -- Scroll-area
    SCROLL_Y_BASE    = -47,    -- scroll-top uden fase-bar
    SCROLL_Y_PHASE   = -75,    -- scroll-top med fase-bar
    SCROLL_BOTTOM    = 34,
    SCROLL_STEP      = 20,
    SBAR_W           = 5,
    SBAR_GAP         = 3,
    CONTENT_W        = 256,
    CONTENT_VPADDING = 16,
    CONTENT_MIN_H    = 60,
    TEXT_W           = 248,
    THUMB_MIN_H      = 14,

    -- Navigation
    NAV_BTN_W = 26,
    NAV_BTN_H = 22,
    NAV_BTN_Y = 6,

    -- Vindue-knapper (luk / minimér)
    WIN_BTN_SIZE = 20,
    WIN_BTN_X    = -5,
    WIN_BTN_Y    = -5,
    WIN_BTN_GAP  = -3,

    -- Skrifttyper
    FONT_DUNGEON  = 9,
    FONT_BOSS     = 14,
    FONT_CLOSE    = 11,
    FONT_MINIMIZE = 13,
    FONT_HEADER_INDEX = 11,

    -- Timer
    ZONE_DELAY = 1.5,
}

-- ---------------------------------------------------------------------------
-- Farver
-- ---------------------------------------------------------------------------

-- Genvej til delt farvepalette (loadet efter BossHelper.lua i TOC-rækkefølgen)
local C = BossHelper.UI.C
local Anim = BossHelper and BossHelper.Anim

-- Modul-lokale farver uden pendant i BossHelper.UI.C
local MC = {
    BTN_BG_DEFAULT      = {0.06, 0.07, 0.11, 1   },
    BTN_BG_HOVER        = {0.15, 0.15, 0.25, 1   },
    BTN_BG_SELECTED     = {1,    0.5,  0,    1   },
    BTN_BORDER_HOVER    = {1,    0.6,  0.2,  1   },
    BTN_BORDER_SELECTED = {1,    0.5,  0,    1   },
    TEXT_HOVER          = {1,    0.95, 0.75      },
    DUNGEON_TITLE       = {0.65, 0.65, 0.85      },
    BOSS_TITLE          = {1,    0.5,  0         },
    TACTIC_TEXT         = {0.98, 0.82, 0.55      },
    NAV_LABEL           = {0.65, 0.65, 0.65      },
    SEP                 = {1,    0.5,  0,    0.35},
    SBAR_BG             = {0.06, 0.06, 0.10, 0.85},
    SBAR_THUMB          = {1,    0.5,  0,    0.6 },
    SBAR_THUMB_HOVER    = {1,    0.65, 0.2,  0.9 },
    WIN_BTN_BG          = {0.08, 0.09, 0.13, 0.95},
    CLOSE_HOVER_BG      = {1,    0.1,  0.1,  1   },
    CLOSE_HOVER_BORDER  = {1,    0.6,  0.6,  1   },
    MIN_HOVER_BG        = {0.15, 0.35, 0.65, 1   },
    MIN_HOVER_BORDER    = {0.4,  0.7,  1,    1   },
    PHASE_PANEL_BG      = {0.08, 0.09, 0.13, 0.98},
    PHASE_PANEL_BORDER  = {1,    0.5,  0,    0.7 },
}

-- ---------------------------------------------------------------------------
-- Forward declarations (cirkulære afhængigheder)
-- ---------------------------------------------------------------------------
local RefreshContent
local SetMinimized

-- ---------------------------------------------------------------------------
-- Dungeon detection  (1:1 kopi af GetCurrentDungeonKey fra BossUI.lua)
-- ---------------------------------------------------------------------------
local function GetCurrentDungeonKey()
    if not GetInstanceInfo then return nil end
    local instanceName, instanceType = GetInstanceInfo()
    if not instanceName or instanceName == "" or instanceType == "none" then return nil end

    local order = BossData and BossData.DungeonOrder
    if not order then return nil end

    -- Primær match: via EJ instanceID
    for _, key in ipairs(order) do
        local data = BossData[key]
        if type(data) == "table" then
            if data.instanceID and data.instanceID > 0 then
                local ejName = BossHelper:GetDungeonName(data.instanceID)
                if ejName == instanceName then return key end
            end
        end
    end

    -- Fallback: match via string-nøgle
    for _, key in ipairs(order) do
        local data = BossData[key]
        if type(data) == "table" and not (data.instanceID and data.instanceID > 0) then
            if key == instanceName then return key end
        end
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- Taktik-tekst-hjælpere
-- ---------------------------------------------------------------------------
local function ReplaceRoleIcons(text)
    if BossHelper and BossHelper.ReplaceRoleIcons then
        return BossHelper:ReplaceRoleIcons(text)
    end
    return text
end

-- Fjerner tomme linjer og gensamler med enkelt blank linje imellem
local function NormalizeText(rawText)
    local lines = {}
    for line in rawText:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n\n")
end

local function GetBossTacticText(dungeonKey, boss)
    -- 1) Custom tactics (redigerede af brugeren)
    if BossUI and BossUI.HasCustomTactics and BossUI.HasCustomTactics(dungeonKey, boss.encounterID) then
        local phases = BossUI.GetCustomPhases and BossUI.GetCustomPhases(dungeonKey, boss.encounterID) or {}
        if BossUI.GetCustomTacticsText then
            local txt = BossUI.GetCustomTacticsText(dungeonKey, boss.encounterID, phases[1])
            if txt and txt ~= "" then return txt end
            -- Prøv "No phase"
            local ct = BossUI.GetCustomTacticsText(dungeonKey, boss.encounterID, nil)
            if ct and ct ~= "" then return ct end
        end
    end

    -- 2) Fase-tekst (native)
    if boss.phases and boss.phaseText and #boss.phases > 0 then
        local firstPhase = boss.phases[1]
        if firstPhase and boss.phaseText[firstPhase] then
            return boss.phaseText[firstPhase]
        end
    end

    -- 3) Almindelig short-tekst
    return boss.short or ""
end

-- Returnerer faselisten for en boss (merged custom + native, aldrig "No phase")
local function GetMiniPhaseList(dungeonKey, boss)
    local hasCustom = BossUI and BossUI.HasCustomTactics and BossUI.HasCustomTactics(dungeonKey, boss.encounterID)
    if hasCustom then
        local customList = (BossUI.GetCustomPhases and BossUI.GetCustomPhases(dungeonKey, boss.encounterID)) or {}
        local merged, seen = {}, {}
        for _, p in ipairs(customList) do
            if p ~= "No phase" then
                table.insert(merged, p)
                seen[p] = true
            end
        end
        for _, p in ipairs(boss.phases or {}) do
            if not seen[p] then table.insert(merged, p) end
        end
        return merged, true
    end
    return boss.phases or {}, false
end

local function GetMiniTacticForPhase(dungeonKey, boss, phases, idx, hasCustom)
    local phaseName = phases[idx]
    if hasCustom and phaseName and BossUI and BossUI.GetCustomTacticsText then
        local txt = BossUI.GetCustomTacticsText(dungeonKey, boss.encounterID, phaseName)
        if txt and txt ~= "" then return txt end
    end
    if phaseName and boss.phaseText and boss.phaseText[phaseName] then
        return boss.phaseText[phaseName]
    end
    return boss.short or ""
end

-- ---------------------------------------------------------------------------
-- Fase-panel hjælpere  (eliminerer duplikeret toggle-logik)
-- ---------------------------------------------------------------------------
local function HidePhasePanel()
    if miniFrame.phasePanel   then miniFrame.phasePanel:Hide()   end
    if miniFrame.phaseCatcher then miniFrame.phaseCatcher:Hide() end
    if miniFrame.phaseMainBtn and miniFrame.phaseMainBtn.arrow then
        miniFrame.phaseMainBtn.arrow:SetRotation(0)
    end
end

local function ShowPhasePanel()
    local panel = miniFrame.phasePanel
    if not panel then return end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", miniFrame.phaseBar, "BOTTOMLEFT", 0, -2)
    panel:Show()
    if miniFrame.phaseCatcher then miniFrame.phaseCatcher:Show() end
    if miniFrame.phaseMainBtn and miniFrame.phaseMainBtn.arrow then
        miniFrame.phaseMainBtn.arrow:SetRotation(math.pi)
    end
end

-- ---------------------------------------------------------------------------
-- Navigation  (eliminerer duplikeret prev/next-logik)
-- ---------------------------------------------------------------------------
local function NavigateBoss(delta)
    if not currentDungeonKey then return end
    local d = BossData[currentDungeonKey]
    if not d or not d.bosses then return end
    currentBossIndex = currentBossIndex + delta
    RefreshContent()  -- bounds-check håndteres i RefreshContent
end

-- ---------------------------------------------------------------------------
-- Fjerner scale-animation fra en knap (bevar kun farve-hover)
-- ---------------------------------------------------------------------------
local function StripScaleAnim(btn)
    btn:SetScript("OnEnter", function(self)
        if not self._isSelected then
            self:SetBackdropColor(unpack(MC.BTN_BG_HOVER))
            self:SetBackdropBorderColor(unpack(MC.BTN_BORDER_HOVER))
            self.text:SetTextColor(unpack(MC.TEXT_HOVER))
        else
            self:SetBackdropColor(unpack(MC.BTN_BG_SELECTED))
            self:SetBackdropBorderColor(unpack(MC.BTN_BORDER_SELECTED))
            self.text:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self._isSelected then
            self:SetBackdropColor(unpack(MC.BTN_BG_DEFAULT))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
            self.text:SetTextColor(unpack(C.TEXT_ORANGE))
        else
            self:SetBackdropColor(unpack(MC.BTN_BG_SELECTED))
            self:SetBackdropBorderColor(unpack(MC.BTN_BORDER_SELECTED))
            self.text:SetTextColor(1, 1, 1)
        end
    end)
end

-- ============================================================
-- UI-byggere  (kaldt fra CreateMiniWindow)
-- ============================================================

-- Bygger header: portræt, dungeon-titel, boss-titel, separator
local function BuildMiniHeader(f)
    local portrait = f:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(LAYOUT.PORTRAIT_W, LAYOUT.PORTRAIT_H)
    portrait:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.PADDING, -2)
    portrait:Hide()
    f.bossPortrait = portrait

    f.dungeonTitle = f:CreateFontString(nil, "OVERLAY")
    f.dungeonTitle:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_DUNGEON, "OUTLINE")
    f.dungeonTitle:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.TITLE_X, -8)
    f.dungeonTitle:SetPoint("RIGHT",   f, "RIGHT",   -32, 0)
    f.dungeonTitle:SetTextColor(unpack(MC.DUNGEON_TITLE))
    f.dungeonTitle:SetJustifyH("LEFT")
    f.dungeonTitle:SetWordWrap(false)

    -- Boss-titel + plads til kompakt boss-indeks når vinduet er minimeret
    f.bossTitle = f:CreateFontString(nil, "OVERLAY")
    f.bossTitle:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_BOSS, "OUTLINE")
    f.bossTitle:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.TITLE_X, -22)
    f.bossTitle:SetTextColor(unpack(MC.BOSS_TITLE))
    f.bossTitle:SetJustifyH("LEFT")
    f.bossTitle:SetWordWrap(false)
    f.bossTitle:SetText("")

    -- Kompakt indeks vises i header når mini-vinduet er minimeret
    f.headerIndex = f:CreateFontString(nil, "OVERLAY")
    f.headerIndex:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_HEADER_INDEX, "OUTLINE")
    -- Placeret under close/minimize-knapperne (justeret lidt op)
    f.headerIndex:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -26)
    f.headerIndex:SetTextColor(unpack(MC.NAV_LABEL))
    f.headerIndex:SetJustifyH("RIGHT")
    f.headerIndex:SetText("")
    f.headerIndex:Hide()

    -- Begræns boss-titlen så den ikke overlapper indekset
    f.bossTitle:SetPoint("RIGHT", f.headerIndex, "LEFT", -6, 0)

    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  f, "TOPLEFT",  LAYOUT.PADDING,  LAYOUT.SEP_Y)
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -LAYOUT.PADDING, LAYOUT.SEP_Y)
    sep:SetColorTexture(unpack(MC.SEP))
    -- expose separator so settings can hide/show it
    f.headerSep = sep
    if BossHelperDB and BossHelperDB.miniWindowHideSeparator then
        sep:Hide()
    else
        sep:Show()
    end
end

-- Opretter en minimal custom scrollbar tilknyttet scroll/content.
-- Returnerer sbTrack og UpdateScrollThumb-funktionen.
local function CreateScrollbar(parent, scroll, content)
    local sbTrack = CreateFrame("Frame", nil, parent)
    sbTrack:SetWidth(LAYOUT.SBAR_W)
    sbTrack:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    LAYOUT.SBAR_GAP, 0)
    sbTrack:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", LAYOUT.SBAR_GAP, 0)

    local sbTrackTex = sbTrack:CreateTexture(nil, "BACKGROUND")
    sbTrackTex:SetAllPoints()
    -- Hide the visible track background so only the scroll thumb is shown
    sbTrackTex:SetColorTexture(MC.SBAR_BG[1], MC.SBAR_BG[2], MC.SBAR_BG[3], 0)

    local sbThumb = CreateFrame("Frame", nil, sbTrack)
    sbThumb:SetWidth(LAYOUT.SBAR_W)
    sbThumb:SetHeight(20)
    sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, 0)

    local sbThumbTex = sbThumb:CreateTexture(nil, "ARTWORK")
    sbThumbTex:SetAllPoints()
    sbThumbTex:SetColorTexture(unpack(MC.SBAR_THUMB))

    sbThumb:EnableMouse(true)
    sbThumb:SetScript("OnEnter", function() sbThumbTex:SetColorTexture(unpack(MC.SBAR_THUMB_HOVER)) end)
    sbThumb:SetScript("OnLeave", function() sbThumbTex:SetColorTexture(unpack(MC.SBAR_THUMB))       end)

    local function UpdateScrollThumb()
        local maxScroll = scroll:GetVerticalScrollRange()
        if not maxScroll or maxScroll <= 0 then sbThumb:Hide(); return end
        sbThumb:Show()
        local trackH = sbTrack:GetHeight()
        local totalH = content:GetHeight()
        local viewH  = scroll:GetHeight()
        if totalH <= 0 or trackH <= 0 then return end
        local thumbH = math.max(math.floor(trackH * (viewH / totalH)), LAYOUT.THUMB_MIN_H)
        sbThumb:SetHeight(thumbH)
        local offset = scroll:GetVerticalScroll()
        local thumbY = (offset / maxScroll) * (trackH - thumbH)
        sbThumb:ClearAllPoints()
        sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, -thumbY)
    end

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur  = self:GetVerticalScroll()
        local maxS = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(maxS, cur - delta * LAYOUT.SCROLL_STEP)))
        UpdateScrollThumb()
    end)

    sbThumb:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local startY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local startScroll = scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local maxS   = scroll:GetVerticalScrollRange()
            local trackH = sbTrack:GetHeight()
            local thumbH = sbThumb:GetHeight()
            local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local pct    = (startY - curY) / math.max(trackH - thumbH, 1)
            scroll:SetVerticalScroll(math.max(0, math.min(maxS, startScroll + pct * maxS)))
            UpdateScrollThumb()
        end)
    end)
    sbThumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnScrollRangeChanged", function() C_Timer.After(0, UpdateScrollThumb) end)

    return sbTrack, UpdateScrollThumb
end

-- Opretter fase-dropdown-bar (skjult indtil boss har > 1 fase)
local function BuildPhaseBar(f)
    local phaseBar = CreateFrame("Frame", nil, f)
    phaseBar:SetHeight(LAYOUT.PHASE_BAR_H)
    phaseBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  LAYOUT.PADDING,  LAYOUT.PHASE_BAR_Y)
    phaseBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -LAYOUT.PADDING, LAYOUT.PHASE_BAR_Y)
    phaseBar:Hide()
    f.phaseBar = phaseBar

    local phaseMainBtn = BossUI.CreateCustomButton(phaseBar, LAYOUT.PHASE_BTN_W, LAYOUT.PHASE_BTN_H, "")
    StripScaleAnim(phaseMainBtn)
    phaseMainBtn:SetPoint("LEFT", phaseBar, "LEFT", 0, 0)

    local arrow = phaseMainBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
    arrow:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 0.8)
    arrow:SetSize(16, 8)
    arrow:SetPoint("RIGHT", phaseMainBtn, "RIGHT", -6, 0)
    arrow:SetRotation(0)
    phaseMainBtn.arrow = arrow

    f.phaseMainBtn  = phaseMainBtn
    f.phasePanel    = nil    -- oprettes lazy første gang i RefreshContent
    f.phaseCatcher  = nil
    f._phaseButtons = {}
end

-- Opretter scroll-area med taktik-tekst og custom scrollbar
local function BuildScrollArea(f)
    local scrollRightInset = LAYOUT.PADDING + LAYOUT.SBAR_W + LAYOUT.SBAR_GAP

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",     LAYOUT.PADDING,    LAYOUT.SCROLL_Y_BASE)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -scrollRightInset, LAYOUT.SCROLL_BOTTOM)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(LAYOUT.CONTENT_W)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local tacticText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tacticText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
    tacticText:SetWidth(LAYOUT.TEXT_W)
    tacticText:SetJustifyH("LEFT")
    tacticText:SetJustifyV("TOP")
    tacticText:SetWordWrap(true)
    tacticText:SetTextColor(unpack(MC.TACTIC_TEXT))
    tacticText:SetText("")

    f.tacticText    = tacticText
    f.tacticContent = content
    f.tacticScroll  = scroll

    local sbTrack, UpdateScrollThumb = CreateScrollbar(f, scroll, content)
    f.sbTrack            = sbTrack
    f._UpdateScrollThumb = UpdateScrollThumb
end

-- Opretter navigationsknapper og boss-indeks-label
local function BuildNavigation(f)
    local prevBtn = BossUI.CreateCustomButton(f, LAYOUT.NAV_BTN_W, LAYOUT.NAV_BTN_H, "<")
    prevBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LAYOUT.PADDING, LAYOUT.NAV_BTN_Y)
    prevBtn:SetScript("OnClick", function() NavigateBoss(-1) end)
    prevBtn:SetScript("OnLeave", function(self)
        if miniFrame and miniFrame._iconsOnly then
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        else
            self:SetBackdropColor(unpack(MC.BTN_BG_DEFAULT))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        end
        self.text:SetTextColor(unpack(C.TEXT_ORANGE))
    end)
    f.prevBtn = prevBtn

    local nextBtn = BossUI.CreateCustomButton(f, LAYOUT.NAV_BTN_W, LAYOUT.NAV_BTN_H, ">")
    nextBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -LAYOUT.PADDING, LAYOUT.NAV_BTN_Y)
    nextBtn:SetScript("OnClick", function() NavigateBoss(1) end)
    nextBtn:SetScript("OnLeave", function(self)
        if miniFrame and miniFrame._iconsOnly then
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        else
            self:SetBackdropColor(unpack(MC.BTN_BG_DEFAULT))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        end
        self.text:SetTextColor(unpack(C.TEXT_ORANGE))
    end)
    f.nextBtn = nextBtn

    f.navLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.navLabel:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    f.navLabel:SetTextColor(unpack(MC.NAV_LABEL))
    f.navLabel:SetText("")
end

-- Opretter luk- og minimér-knapper (øverste højre hjørne)
local function BuildWindowButtons(f)
    local closeBtn = BossUI.CreateCustomButton(f, LAYOUT.WIN_BTN_SIZE, LAYOUT.WIN_BTN_SIZE, "X")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", LAYOUT.WIN_BTN_X, LAYOUT.WIN_BTN_Y)
    closeBtn.text:ClearAllPoints()
    closeBtn.text:SetPoint("CENTER", closeBtn, "CENTER", 1, 0)
    closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_CLOSE, "OUTLINE")
    -- Use an icon for close and hide text
    closeBtn.text:Hide()
    closeBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\x.png")
    if closeBtn.icon then
        closeBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 7, LAYOUT.WIN_BTN_SIZE - 7)
        closeBtn.icon:ClearAllPoints()
        closeBtn.icon:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
        closeBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
    end
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(MC.CLOSE_HOVER_BG))
        self:SetBackdropBorderColor(unpack(MC.CLOSE_HOVER_BORDER))
        if self.icon then self.icon:SetVertexColor(1,1,1,1) end
    end)
    closeBtn:SetScript("OnLeave", function(self)
        if miniFrame and miniFrame._iconsOnly then
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        else
            self:SetBackdropColor(unpack(MC.WIN_BTN_BG))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        end
        if self.icon then self.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1) end
    end)
    f.closeBtn = closeBtn

    local mainBtn = BossUI.CreateCustomButton(f, LAYOUT.WIN_BTN_SIZE, LAYOUT.WIN_BTN_SIZE, "M")
    mainBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", LAYOUT.WIN_BTN_GAP, 0)
    mainBtn.text:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_CLOSE, "OUTLINE")
    -- Use a square icon matching the other window button colours
    mainBtn.text:Hide()
    mainBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\square.png")
    if mainBtn.icon then
        mainBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
        mainBtn.icon:ClearAllPoints()
        mainBtn.icon:SetPoint("CENTER", mainBtn, "CENTER", 0, 0)
        mainBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
    end

    mainBtn:SetScript("OnClick", function()
        local LDB
        if LibStub and LibStub.GetLibrary then
            LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
        end
        if LDB and LDB.GetDataObjectByName then
            local obj = LDB:GetDataObjectByName("BossHelper")
            if obj and obj.OnClick then
                obj.OnClick(obj, "LeftButton")
                return
            end
        end
        if BossHelper and BossHelper.Toggle then BossHelper:Toggle() end
    end)
    mainBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(MC.MIN_HOVER_BG))
        self:SetBackdropBorderColor(unpack(MC.MIN_HOVER_BORDER))
        if self.icon then self.icon:SetVertexColor(1, 1, 1, 1) end
    end)
    mainBtn:SetScript("OnLeave", function(self)
        if miniFrame and miniFrame._iconsOnly then
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        else
            self:SetBackdropColor(unpack(MC.WIN_BTN_BG))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        end
        if self.icon then self.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1) end
    end)
    f.mainBtn = mainBtn

    local minBtn = BossUI.CreateCustomButton(f, LAYOUT.WIN_BTN_SIZE, LAYOUT.WIN_BTN_SIZE, "-")
    minBtn:SetPoint("TOPRIGHT", mainBtn, "TOPLEFT", LAYOUT.WIN_BTN_GAP, 0)
    minBtn.text:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_MINIMIZE, "OUTLINE")
    -- Use icon for minimize/expand; default to minus (expanded)
    minBtn.text:Hide()
    minBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\minus.png")
    if minBtn.icon then
        minBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
        minBtn.icon:ClearAllPoints()
        minBtn.icon:SetPoint("CENTER", minBtn, "CENTER", 0, 0)
        minBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
    end
    minBtn:SetScript("OnClick", function() SetMinimized(not miniMinimized) end)
    minBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(MC.MIN_HOVER_BG))
        self:SetBackdropBorderColor(unpack(MC.MIN_HOVER_BORDER))
        if self.icon then self.icon:SetVertexColor(1,1,1,1) end
    end)
    minBtn:SetScript("OnLeave", function(self)
        if miniFrame and miniFrame._iconsOnly then
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        else
            self:SetBackdropColor(unpack(MC.WIN_BTN_BG))
            self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        end
        if self.icon then self.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1) end
    end)

    f.minimizeBtn = minBtn
end

-- ---------------------------------------------------------------------------
-- Refresh: opdater indhold baseret på currentDungeonKey / currentBossIndex
-- ---------------------------------------------------------------------------
RefreshContent = function()
    if not miniFrame then return end

    local dungeonData = currentDungeonKey and BossData[currentDungeonKey]
    if not dungeonData or not dungeonData.bosses or #dungeonData.bosses == 0 then
        miniFrame:Hide()
        return
    end

    -- Bounds-check (cirkulær navigation)
    local total = #dungeonData.bosses
    if currentBossIndex < 1 then currentBossIndex = total end
    if currentBossIndex > total then currentBossIndex = 1 end

    local boss = dungeonData.bosses[currentBossIndex]

    -- Nulstil fase ved boss-skift
    if currentBossIndex ~= lastBossIndexForPhase then
        currentPhaseIndex     = 1
        lastBossIndexForPhase = currentBossIndex
    end

    -- Boss-navn og portræt
    local bossName = BossHelper:GetBossName(boss.encounterID) or Translate("UNKNOWN_BOSS")
    local anim = Anim
    local bossChanged = not miniFrame._lastBossIndex or (miniFrame._lastBossIndex ~= currentBossIndex)

    -- Titel: crossfade ved boss-skift, ellers sæt direkte
    if bossChanged and anim and anim.CrossfadeText then
        anim.CrossfadeText(miniFrame.bossTitle, bossName, anim.Config.CROSSFADE_DURATION)
    else
        miniFrame.bossTitle:SetText(bossName)
    end

    -- Portræt: opdatér texture og afspil en lille pop hvis boss skiftede
    if miniFrame.bossPortrait then
        local iconTexture = boss.icon or BossHelper:GetBossPortraitFileID(boss.encounterID, boss)
        if iconTexture then
            miniFrame.bossPortrait:SetTexture(iconTexture)
            miniFrame.bossPortrait:Show()
            if bossChanged and anim and anim.PlayLogoPop then
                anim.PlayLogoPop(miniFrame.bossPortrait, anim.Config.CROSSFADE_DURATION)
            end
        else
            miniFrame.bossPortrait:Hide()
        end
    end

    -- Dungeon-navn (sub-header)
    local dName = BossHelper:GetDungeonName(dungeonData.instanceID) or currentDungeonKey
    miniFrame.dungeonTitle:SetText(dName)

    -- Fase-dropdown
    local phases, hasCustom = GetMiniPhaseList(currentDungeonKey, boss)
    local hasPhases = #phases > 1
    if currentPhaseIndex > #phases then currentPhaseIndex = 1 end

    local scrollRightInset = LAYOUT.PADDING + LAYOUT.SBAR_W + LAYOUT.SBAR_GAP

    if hasPhases and miniFrame.phaseBar then
        -- Lazy-opret fase-panel og click-catcher første gang
        if not miniFrame.phasePanel then
            local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            panel:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 14,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            panel:SetBackdropColor(unpack(MC.PHASE_PANEL_BG))
            panel:SetBackdropBorderColor(unpack(MC.PHASE_PANEL_BORDER))
            panel:SetFrameStrata("FULLSCREEN_DIALOG")
            panel:SetFrameLevel(LAYOUT.PHASE_PANEL_LEVEL)
            panel:Hide()

            local catcher = CreateFrame("Frame", nil, UIParent)
            catcher:SetAllPoints(UIParent)
            catcher:EnableMouse(true)
            catcher:Hide()
            catcher:SetFrameStrata("FULLSCREEN_DIALOG")
            catcher:SetFrameLevel(LAYOUT.PHASE_CATCHER_LEVEL)
            catcher:SetScript("OnMouseDown", function() HidePhasePanel() end)

            miniFrame.phasePanel   = panel
            miniFrame.phaseCatcher = catcher
        end

        local panel   = miniFrame.phasePanel
        local buttons = miniFrame._phaseButtons

        -- Tilpas panel-størrelse og position
        panel:SetSize(LAYOUT.PHASE_BTN_W, #phases * LAYOUT.PHASE_ITEM_H)
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", miniFrame.phaseBar, "BOTTOMLEFT", 0, -2)

        -- Opret / genrug fase-knapper
        for i = 1, #phases do
            if not buttons[i] then
                buttons[i] = BossUI.CreateCustomButton(panel, LAYOUT.PHASE_BTN_W, LAYOUT.PHASE_BTN_H, "")
                StripScaleAnim(buttons[i])
            end
            local btn = buttons[i]
            btn:ClearAllPoints()
            btn:SetPoint("TOP", panel, "TOP", 0, -((i - 1) * LAYOUT.PHASE_ITEM_H))
            btn:SetText(phases[i])
            btn:SetSelected(i == currentPhaseIndex)
            local phaseIdx = i
            btn:SetScript("OnClick", function()
                currentPhaseIndex = phaseIdx
                HidePhasePanel()
                RefreshContent()
            end)
            btn:Show()
        end
        -- Skjul overskydende knapper
        for i = #phases + 1, #buttons do buttons[i]:Hide() end

        -- Hoved-knap: tekst + toggle
        miniFrame.phaseMainBtn:SetText(phases[currentPhaseIndex])
        miniFrame.phaseMainBtn:SetScript("OnClick", function()
            if miniFrame.phasePanel:IsShown() then
                HidePhasePanel()
            else
                ShowPhasePanel()
            end
        end)

        miniFrame.phaseBar:Show()
        miniFrame.tacticScroll:ClearAllPoints()
        miniFrame.tacticScroll:SetPoint("TOPLEFT",     miniFrame, "TOPLEFT",     LAYOUT.PADDING,    LAYOUT.SCROLL_Y_PHASE)
        miniFrame.tacticScroll:SetPoint("BOTTOMRIGHT", miniFrame, "BOTTOMRIGHT", -scrollRightInset, LAYOUT.SCROLL_BOTTOM)
    else
        if miniFrame.phaseBar then miniFrame.phaseBar:Hide() end
        HidePhasePanel()
        miniFrame.tacticScroll:ClearAllPoints()
        miniFrame.tacticScroll:SetPoint("TOPLEFT",     miniFrame, "TOPLEFT",     LAYOUT.PADDING,    LAYOUT.SCROLL_Y_BASE)
        miniFrame.tacticScroll:SetPoint("BOTTOMRIGHT", miniFrame, "BOTTOMRIGHT", -scrollRightInset, LAYOUT.SCROLL_BOTTOM)
    end

    -- Taktik-tekst (fase-bevidst)
    local rawText = hasPhases
        and GetMiniTacticForPhase(currentDungeonKey, boss, phases, currentPhaseIndex, hasCustom)
        or  GetBossTacticText(currentDungeonKey, boss)

    -- Hvis boss skiftede: fade ud → opdatér tekst → fade ind (brug Anim helpers)
    local text = ReplaceRoleIcons(NormalizeText(rawText))
    miniFrame.tacticScroll:SetVerticalScroll(0)
    if bossChanged and anim then
        local duration = (anim.Config and anim.Config.CROSSFADE_DURATION) or 0.12
        if miniFrame.tacticScroll and anim.AnimateAlpha then
            anim.AnimateAlpha(miniFrame.tacticScroll, miniFrame.tacticScroll:GetAlpha() or 1, 0, duration)
        else
            if miniFrame.tacticScroll then miniFrame.tacticScroll:SetAlpha(0); miniFrame.tacticScroll:Hide() end
        end

        C_Timer.After(duration, function()
            if not miniFrame then return end
            miniFrame.tacticText:SetText(text)
            C_Timer.After(0, function()
                if not miniFrame or not miniFrame.tacticContent then return end
                local h = miniFrame.tacticText:GetStringHeight() or 0
                miniFrame.tacticContent:SetHeight(math.max(h + LAYOUT.CONTENT_VPADDING, LAYOUT.CONTENT_MIN_H))
                if miniFrame._UpdateScrollThumb then miniFrame._UpdateScrollThumb() end
            end)

            if miniFrame.tacticScroll and anim.AnimateAlpha then
                anim.AnimateAlpha(miniFrame.tacticScroll, 0, 1, duration)
            else
                if miniFrame.tacticScroll then miniFrame.tacticScroll:SetAlpha(1); miniFrame.tacticScroll:Show() end
            end
        end)
    else
        miniFrame.tacticText:SetText(text)
        C_Timer.After(0, function()
            if not miniFrame or not miniFrame.tacticContent then return end
            local h = miniFrame.tacticText:GetStringHeight() or 0
            miniFrame.tacticContent:SetHeight(math.max(h + LAYOUT.CONTENT_VPADDING, LAYOUT.CONTENT_MIN_H))
            if miniFrame._UpdateScrollThumb then miniFrame._UpdateScrollThumb() end
        end)
    end

    -- Gem seneste viste boss til fremtidige skift
    miniFrame._lastBossIndex = currentBossIndex

    -- Opdater kompakt header-indeks (vises når minimeret)
    if miniFrame.headerIndex then
        miniFrame.headerIndex:SetText(currentBossIndex .. " / " .. total)
        miniFrame.headerIndex:SetShown(miniMinimized)
    end

    -- Navigation-label og pile-knapper (vises kun når ikke minimeret)
    miniFrame.navLabel:SetText(currentBossIndex .. " / " .. total)
    local showNav = not miniMinimized and total > 1
    miniFrame.prevBtn:SetShown(showNav)
    miniFrame.nextBtn:SetShown(showNav)
    miniFrame.navLabel:SetShown(showNav)
end

-- ---------------------------------------------------------------------------
-- Kollaps / ekspander vinduet
-- ---------------------------------------------------------------------------
SetMinimized = function(minimized)
    if not miniFrame then return end
    miniMinimized = minimized
    local curH = miniFrame:GetHeight() or LAYOUT.FULL_H
    local anim = Anim
    if minimized then
        -- fade out content then shrink (use Anim helpers if available)
        if miniFrame.tacticScroll then
            if anim and anim.AnimateAlpha then
                anim.AnimateAlpha(miniFrame.tacticScroll, miniFrame.tacticScroll:GetAlpha() or 1, 0, anim.Config.CROSSFADE_DURATION)
            else
                miniFrame.tacticScroll:SetAlpha(0); miniFrame.tacticScroll:Hide()
            end
        end
        if miniFrame.sbTrack then
            if anim and anim.AnimateAlpha then
                anim.AnimateAlpha(miniFrame.sbTrack, miniFrame.sbTrack:GetAlpha() or 1, 0, anim.Config.CROSSFADE_DURATION)
            else
                miniFrame.sbTrack:SetAlpha(0); miniFrame.sbTrack:Hide()
            end
        end

        if anim and anim.AnimateHeight then
            anim.AnimateHeight(miniFrame, curH, LAYOUT.HEADER_H, 0.18, function()
                if miniFrame.tacticScroll then miniFrame.tacticScroll:Hide() end
                if miniFrame.sbTrack then miniFrame.sbTrack:Hide() end
                if miniFrame.prevBtn then miniFrame.prevBtn:Hide() end
                if miniFrame.nextBtn then miniFrame.nextBtn:Hide() end
                if miniFrame.navLabel then miniFrame.navLabel:Hide() end
                if miniFrame.phaseBar then miniFrame.phaseBar:Hide() end
                HidePhasePanel()
                if miniFrame.headerSep then miniFrame.headerSep:Hide() end
                    if miniFrame.minimizeBtn and miniFrame.minimizeBtn.icon then
                        miniFrame.minimizeBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\plus.png")
                        miniFrame.minimizeBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
                        miniFrame.minimizeBtn.icon:ClearAllPoints()
                        miniFrame.minimizeBtn.icon:SetPoint("CENTER", miniFrame.minimizeBtn, "CENTER", 0, 0)
                        miniFrame.minimizeBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
                    end
                    if miniFrame.headerIndex then miniFrame.headerIndex:Show() end
            end)
        else
            miniFrame:SetHeight(LAYOUT.HEADER_H)
            if miniFrame.tacticScroll then miniFrame.tacticScroll:Hide() end
            if miniFrame.sbTrack then miniFrame.sbTrack:Hide() end
            if miniFrame.prevBtn then miniFrame.prevBtn:Hide() end
            if miniFrame.nextBtn then miniFrame.nextBtn:Hide() end
            if miniFrame.navLabel then miniFrame.navLabel:Hide() end
            if miniFrame.phaseBar then miniFrame.phaseBar:Hide() end
            HidePhasePanel()
                if miniFrame.headerSep then miniFrame.headerSep:Hide() end
                if miniFrame.minimizeBtn and miniFrame.minimizeBtn.icon then
                    miniFrame.minimizeBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\plus.png")
                    miniFrame.minimizeBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
                    miniFrame.minimizeBtn.icon:ClearAllPoints()
                    miniFrame.minimizeBtn.icon:SetPoint("CENTER", miniFrame.minimizeBtn, "CENTER", 0, 0)
                    miniFrame.minimizeBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
                end
                if miniFrame.headerIndex then miniFrame.headerIndex:Show() end
        end
    else
        -- expand: show content (invisible) and grow, then fade in
        if miniFrame.tacticScroll then
            miniFrame.tacticScroll:Show()
            miniFrame.tacticScroll:SetAlpha(0)
        end
        if miniFrame.sbTrack then
            miniFrame.sbTrack:Show()
            miniFrame.sbTrack:SetAlpha(0)
        end

        if anim and anim.AnimateHeight then
            anim.AnimateHeight(miniFrame, curH, LAYOUT.FULL_H, 0.18, function()
                if miniFrame.minimizeBtn and miniFrame.minimizeBtn.icon then
                    miniFrame.minimizeBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\minus.png")
                    miniFrame.minimizeBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
                    miniFrame.minimizeBtn.icon:ClearAllPoints()
                    miniFrame.minimizeBtn.icon:SetPoint("CENTER", miniFrame.minimizeBtn, "CENTER", 0, 0)
                    miniFrame.minimizeBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
                end
                RefreshContent()
                -- restore separator unless user explicitly disabled it
                if miniFrame.headerSep then
                    if BossHelperDB and BossHelperDB.miniWindowHideSeparator then
                        miniFrame.headerSep:Hide()
                    else
                        miniFrame.headerSep:Show()
                    end
                end
                if miniFrame.tacticScroll and anim.AnimateAlpha then anim.AnimateAlpha(miniFrame.tacticScroll, 0, 1, 0.16) end
                if miniFrame.sbTrack    and anim.AnimateAlpha then anim.AnimateAlpha(miniFrame.sbTrack,    0, 1, 0.16) end
                if miniFrame.headerIndex then miniFrame.headerIndex:Hide() end
            end)
        else
            miniFrame:SetHeight(LAYOUT.FULL_H)
            if miniFrame.minimizeBtn and miniFrame.minimizeBtn.icon then
                miniFrame.minimizeBtn:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\minus.png")
                miniFrame.minimizeBtn.icon:SetSize(LAYOUT.WIN_BTN_SIZE - 10, LAYOUT.WIN_BTN_SIZE - 10)
                miniFrame.minimizeBtn.icon:ClearAllPoints()
                miniFrame.minimizeBtn.icon:SetPoint("CENTER", miniFrame.minimizeBtn, "CENTER", 0, 0)
                miniFrame.minimizeBtn.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
            end
            RefreshContent()
            if miniFrame.headerSep then
                if BossHelperDB and BossHelperDB.miniWindowHideSeparator then
                    miniFrame.headerSep:Hide()
                else
                    miniFrame.headerSep:Show()
                end
            end
            if miniFrame.tacticScroll then miniFrame.tacticScroll:SetAlpha(1); miniFrame.tacticScroll:Show() end
            if miniFrame.sbTrack then miniFrame.sbTrack:SetAlpha(1); miniFrame.sbTrack:Show() end
            if miniFrame.headerIndex then miniFrame.headerIndex:Hide() end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Åbn mini-vinduet for en given dungeon
-- ---------------------------------------------------------------------------
local function OpenForDungeon(key)
    if not miniFrame then return end
    currentDungeonKey     = key
    currentBossIndex      = 1
    currentPhaseIndex     = 1
    lastBossIndexForPhase = -1
    RefreshContent()
    miniFrame:Show()
end

-- ---------------------------------------------------------------------------
-- Anvend Mini-vindue indstillinger (gennemsigtig baggrund / ingen kant)
-- ---------------------------------------------------------------------------
local function ApplyMiniWindowSettings()
    if not miniFrame then return end
    -- Hide the frame entirely if the setting is disabled
    if BossHelperDB and BossHelperDB.miniWindowEnabled == false then
        miniFrame:Hide()
        return
    end
    local noBorder = BossHelperDB and BossHelperDB.miniWindowNoBorder

    local bg = C.BG_PANEL_DARK
    local stored = BossHelperDB and BossHelperDB.miniWindowTransparency
    local bgAlpha = tonumber(stored) or bg[4]
    if bgAlpha < 0 then bgAlpha = 0 end
    if bgAlpha > 1 then bgAlpha = 1 end
    miniFrame:SetBackdropColor(bg[1], bg[2], bg[3], bgAlpha)

    local border = C.BORDER_AMBER
    local borderAlpha = noBorder and 0 or border[4]
    miniFrame:SetBackdropBorderColor(border[1], border[2], border[3], borderAlpha)
    -- Separator visibility
    local hideSep = BossHelperDB and BossHelperDB.miniWindowHideSeparator
    if miniFrame.headerSep then
        if hideSep then miniFrame.headerSep:Hide() else miniFrame.headerSep:Show() end
    end
    -- Window button chrome visibility
    local iconsOnly = BossHelperDB and BossHelperDB.miniWindowHideButtonChrome
    miniFrame._iconsOnly = iconsOnly and true or false
    local winBtns = { miniFrame.closeBtn, miniFrame.mainBtn, miniFrame.minimizeBtn }
    for _, btn in ipairs(winBtns) do
        if btn then
            if iconsOnly then
                btn:SetBackdropColor(0, 0, 0, 0)
                btn:SetBackdropBorderColor(0, 0, 0, 0)
            else
                btn:SetBackdropColor(unpack(MC.WIN_BTN_BG))
                btn:SetBackdropBorderColor(unpack(C.BORDER_GREY))
            end
        end
    end
    local navBtns = { miniFrame.prevBtn, miniFrame.nextBtn }
    for _, btn in ipairs(navBtns) do
        if btn then
            if iconsOnly then
                btn:SetBackdropColor(0, 0, 0, 0)
                btn:SetBackdropBorderColor(0, 0, 0, 0)
            else
                btn:SetBackdropColor(unpack(MC.BTN_BG_DEFAULT))
                btn:SetBackdropBorderColor(unpack(C.BORDER_GREY))
            end
        end
    end
end

MiniWindow.ApplySettings = ApplyMiniWindowSettings

-- ---------------------------------------------------------------------------
-- Opret mini-vinduet (lazy init, kaldes én gang)
-- ---------------------------------------------------------------------------
local function CreateMiniWindow()
    if miniFrame then return end

    miniFrame = CreateFrame("Frame", "BossHelper_MiniFrame", UIParent, "BackdropTemplate")
    miniFrame:SetSize(LAYOUT.W, LAYOUT.FULL_H)

    -- Gendan gemt position, ellers placer til højre for midten
    if BossHelperDB and BossHelperDB.miniWindowX and BossHelperDB.miniWindowY then
        miniFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
            BossHelperDB.miniWindowX, BossHelperDB.miniWindowY)
    else
        miniFrame:SetPoint("CENTER", UIParent, "CENTER", 320, 0)
    end

    miniFrame:SetFrameStrata("HIGH")
    miniFrame:SetMovable(true)
    miniFrame:EnableMouse(true)
    miniFrame:RegisterForDrag("LeftButton")
    miniFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    miniFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Gem position i SavedVariables
        BossHelperDB = BossHelperDB or {}
        local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        BossHelperDB.miniWindowX = self:GetLeft() * scale
        BossHelperDB.miniWindowY = self:GetTop() * scale
    end)
    miniFrame:SetClampedToScreen(true)
    miniFrame:Hide()

    -- Backdrop – identisk med resten af UI'et
    BossHelper.UI.ApplyBackdrop(miniFrame, "EDITBOX", C.BG_PANEL_DARK, C.BORDER_AMBER)

    BuildMiniHeader(miniFrame)
    BuildPhaseBar(miniFrame)
    BuildScrollArea(miniFrame)
    BuildNavigation(miniFrame)
    BuildWindowButtons(miniFrame)

    -- Anvend gemte settings EFTER alle knapper er oprettet
    ApplyMiniWindowSettings()
end

-- Offentlig funktion: opret vinduet (hvis nødvendigt) og vis det for den
-- aktuelle dungeon. Bruges når brugeren aktiverer indstillingen midt i et run.
-- Falder tilbage på sidst-kendt dungeon, eller første dungeon i listen.
function MiniWindow.ShowIfInDungeon()
    CreateMiniWindow()
    local key = GetCurrentDungeonKey()
        or currentDungeonKey
        or (BossData and BossData.DungeonOrder and BossData.DungeonOrder[1])
    if key then
        OpenForDungeon(key)
    end
end

-- ---------------------------------------------------------------------------
-- Event-handler: auto-åbn ved dungeon-entry + auto-skift ved boss-kill
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Bail out completely when Mini Window is disabled — no timers, no frame work.
    if BossHelperDB and BossHelperDB.miniWindowEnabled == false then
        if miniFrame then miniFrame:Hide() end
        return
    end

    if event == "ENCOUNTER_START" then
        -- Auto-expand mini window at boss pull (if setting enabled)
        if BossHelperDB and BossHelperDB.miniWindowAutoExpand then
            if miniFrame and miniFrame:IsShown() and miniMinimized then
                SetMinimized(false)
            end
        end
        return
    end

    if event == "ENCOUNTER_END" then
        local encounterID, encounterName, _, _, success = ...
        -- Kun ved kill (success == 1), ikke ved wipes.
        if success ~= 1 then return end
        if not currentDungeonKey then return end

        local dungeonData = BossData[currentDungeonKey]
        if not dungeonData or not dungeonData.bosses then return end

        local total = #dungeonData.bosses
        local matchedIndex = nil
        local matchMethod  = nil

        -- Primær match: dungeonEncounterID via EJ API (sprog-uafhængigt, direkte match med ENCOUNTER_END)
        for i = 1, total do
            local dungeonEncID = BossHelper:GetDungeonEncounterID(dungeonData.bosses[i].encounterID)
            if dungeonEncID == encounterID then
                matchedIndex = i
                matchMethod  = "dungeonEncounterID"
                break
            end
        end

        -- Fallback: navn-match (bruges hvis EJ_GetEncounterInfo ikke returnerer et ID)
        if not matchedIndex and encounterName then
            local lowerName = string.lower(encounterName)
            for i = 1, total do
                local bossName = BossHelper:GetBossName(dungeonData.bosses[i].encounterID)
                if bossName and string.lower(bossName) == lowerName then
                    matchedIndex = i
                    matchMethod  = "name-fallback"
                    break
                end
            end
        end

        -- må ikke fjernes, vigtigt for at kunne debugge og forbedre match-logikken i fremtiden
        -- Debug
        --DEFAULT_CHAT_FRAME:AddMessage(string.format(
        --    "|cff00ff00[BossHelper]|r ENCOUNTER_END %q (id=%d) → match=%s via %s",
        --    tostring(encounterName), encounterID,
        --    tostring(matchedIndex), tostring(matchMethod)
        --))

        -- Auto-collapse mini window on boss kill (if setting enabled)
        if BossHelperDB and BossHelperDB.miniWindowAutoExpand then
            if miniFrame and miniFrame:IsShown() and not miniMinimized then
                SetMinimized(true)
            end
        end

        -- Skift til næste boss ved kill; sid stille på sidst boss
        if matchedIndex and matchedIndex < total then
            currentBossIndex      = matchedIndex + 1
            currentPhaseIndex     = 1
            lastBossIndexForPhase = -1
            if miniFrame and miniFrame:IsShown() then
                RefreshContent()
            end
        end
        return
    end

    -- PLAYER_ENTERING_WORLD / ZONE_CHANGED_NEW_AREA:
    -- Vent lidt så GetInstanceInfo er fuldt opdateret
    C_Timer.After(LAYOUT.ZONE_DELAY, function()
        -- Re-check after the delay (setting may have changed)
        if BossHelperDB and BossHelperDB.miniWindowEnabled == false then
            if miniFrame then miniFrame:Hide() end
            return
        end
        CreateMiniWindow()
        local key = GetCurrentDungeonKey()
        if key then
            OpenForDungeon(key)
        elseif miniFrame then
            miniFrame:Hide()
        end
    end)
end)

-- ---------------------------------------------------------------------------
-- Public API: MiniWindow.Toggle() -- bruges af Commands.lua
-- ---------------------------------------------------------------------------
function MiniWindow.Toggle()
    CreateMiniWindow()
    local key = GetCurrentDungeonKey()
    if key then
        -- Re-check: åbn (eller genåbn) med korrekt dungeon
        OpenForDungeon(key)
    else
        -- Ikke i en dungeon
        if miniFrame and miniFrame:IsShown() then
            miniFrame:Hide()
        else
            -- Brug sidst-kendt dungeon, ellers første dungeon i listen
            local fallback = currentDungeonKey
                or (BossData and BossData.DungeonOrder and BossData.DungeonOrder[1])
            if fallback then
                OpenForDungeon(fallback)
            end
        end
    end
end

