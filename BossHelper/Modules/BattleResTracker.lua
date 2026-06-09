-- BattleResTracker.lua
-- Kompakt flydende vindue der sporer Battle Resurrection-opladninger og timer.
-- Grøn når der er opladninger ledig, rød ved 0 – med nedtælling til næste opladning.
-- Samme visuelle stil som DungeonCheckWindow.

BattleResTracker = BattleResTracker or {}

local math_floor = math.floor
local tostring = tostring
local GetTime = GetTime
local unpack = unpack

-- ---------------------------------------------------------------------------
-- Modul-tilstand
-- ---------------------------------------------------------------------------
local brtFrame = nil

-- ---------------------------------------------------------------------------
-- Layout-konstanter
-- ---------------------------------------------------------------------------
local LAYOUT = {
    W             = 110,
    H             = 52,  -- fuld højde med titel + separator
    H_NO_TITLE    = 28,  -- kompakt højde uden titel/separator
    HEADER_H      = 20,  -- separator tæt under titlen
    PADDING       = 10,

    FONT_TITLE    = 12,
    FONT_LABEL    = 11,
    FONT_COUNT    = 13,
    FONT_TIMER    = 11,
    TITLE_OFFSET  = 5,
}

-- ---------------------------------------------------------------------------
-- Farver
-- ---------------------------------------------------------------------------
local C  -- sættes i CreateBattleResTracker (efter BossHelper.lua er loadet)

local MC = {
    SEP                = {1,    0.5,  0,    0.35},
    TITLE              = {1.0,  0.5,  0.0       },
    LABEL              = {0.55, 0.55, 0.75      },
    COUNT_AVAIL        = {0.20, 0.85, 0.20      },  -- grøn – opladninger ledig
    COUNT_EMPTY        = {1.00, 0.28, 0.10      },  -- rød  – ingen opladninger
    TIMER              = {0.65, 0.65, 0.65      },  -- grå nedtælling
}

-- ---------------------------------------------------------------------------
-- Combat Resurrection: spell-ID for "Rebirth" (druid) – bruges som
-- fælles charge-tracker for alle combat-res-spells i encounter og M+.
-- ---------------------------------------------------------------------------
local BR_SPELL_ID = 20484

local function GetBRInfo()
    local info = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(BR_SPELL_ID)
    if info then
        return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration
    end
end

-- ---------------------------------------------------------------------------
-- Opret vinduet (lazy init, kaldes én gang)
-- ---------------------------------------------------------------------------
local function CreateBattleResTracker()
    if brtFrame then return end
    C = BossHelper.UI.C

    brtFrame = CreateFrame("Frame", "BossHelper_BattleResFrame", UIParent, "BackdropTemplate")
    brtFrame:SetSize(LAYOUT.W, LAYOUT.H)

    local initScale = (BossHelperDB and tonumber(BossHelperDB.brtScale)) or 1.0
    brtFrame:SetScale(initScale)

    -- Gendan gemt position, ellers placer midt-højre på skærmen
    if BossHelperDB and BossHelperDB.brtCenterX and BossHelperDB.brtCenterY then
        brtFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", BossHelperDB.brtCenterX / initScale, BossHelperDB.brtCenterY / initScale)
    elseif BossHelperDB and BossHelperDB.brtX and BossHelperDB.brtY then
        brtFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BossHelperDB.brtX / initScale, BossHelperDB.brtY / initScale)
    else
        brtFrame:SetPoint("CENTER", UIParent, "CENTER", 240 / initScale, 80 / initScale)
    end

    brtFrame:SetFrameStrata("HIGH")
    brtFrame:SetMovable(true)
    brtFrame:RegisterForDrag("LeftButton")
    brtFrame:SetScript("OnDragStart", function(self)
        local lockMove = BossHelperDB and BossHelperDB.brtLockMove ~= false
        if (not lockMove) or IsShiftKeyDown() then self:StartMoving() end
    end)
    brtFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BossHelperDB = BossHelperDB or {}
        local scale = self:GetScale()
        local cx, cy = self:GetCenter()
        if cx and cy then
            BossHelperDB.brtCenterX = cx * scale
            BossHelperDB.brtCenterY = cy * scale
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
        end
    end)
    brtFrame:SetClampedToScreen(true)
    brtFrame:Hide()

    -- Backdrop – identisk med DungeonCheckWindow
    BossHelper.UI.ApplyBackdrop(brtFrame, "EDITBOX", C.BG_PANEL_DARK, C.BORDER_AMBER)

    -- -----------------------------------------------------------------------
    -- Header: "Battle Res" titel + separator
    -- -----------------------------------------------------------------------
    local titleText = brtFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_TITLE, "OUTLINE")
    titleText:SetPoint("TOP", brtFrame, "TOP", 0, -LAYOUT.TITLE_OFFSET)
    titleText:SetJustifyH("CENTER")
    titleText:SetText("Battle Res")
    titleText:SetTextColor(unpack(MC.TITLE))
    brtFrame.titleText = titleText

    local sep = brtFrame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  brtFrame, "TOPLEFT",  LAYOUT.PADDING,  -LAYOUT.HEADER_H)
    sep:SetPoint("TOPRIGHT", brtFrame, "TOPRIGHT", -LAYOUT.PADDING, -LAYOUT.HEADER_H)
    sep:SetColorTexture(MC.SEP[1], MC.SEP[2], MC.SEP[3], MC.SEP[4])
    brtFrame.sep = sep

    -- -----------------------------------------------------------------------
    -- Enkelt linje: [BR:]  [antal]  [M:SS]
    -- Centreret vertikalt mellem separatoren og bunden af vinduet.
    -- CENTER-ankre: Y-offset fra rammens midtpunkt = -HEADER_H/2
    -- -----------------------------------------------------------------------
    local contentY = -(LAYOUT.HEADER_H / 2)  -- offset fra CENTER

    local brLbl = brtFrame:CreateFontString(nil, "OVERLAY")
    brLbl:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_LABEL, "OUTLINE")
    brLbl:SetPoint("LEFT", brtFrame, "CENTER", -brtFrame:GetWidth()/2 + LAYOUT.PADDING, contentY)
    brLbl:SetJustifyH("LEFT")
    brLbl:SetTextColor(unpack(MC.LABEL))
    brLbl:SetText("BR:")
    brtFrame.brLbl = brLbl

    local brVal = brtFrame:CreateFontString(nil, "OVERLAY")
    brVal:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_COUNT, "OUTLINE")
    brVal:SetPoint("CENTER", brtFrame, "CENTER", 0, contentY)
    brVal:SetJustifyH("CENTER")
    brVal:SetText("-")
    brtFrame.brVal = brVal

    local timerVal = brtFrame:CreateFontString(nil, "OVERLAY")
    timerVal:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_TIMER, "OUTLINE")
    timerVal:SetPoint("RIGHT", brtFrame, "CENTER", brtFrame:GetWidth()/2 - LAYOUT.PADDING, contentY)
    timerVal:SetJustifyH("RIGHT")
    timerVal:SetTextColor(unpack(MC.TIMER))
    timerVal:SetText("")
    brtFrame.timerVal = timerVal

    -- -----------------------------------------------------------------------
    -- OnUpdate: opdater tæller og timer hvert 0.25 s
    -- -----------------------------------------------------------------------
    brtFrame.elapsed = 0.25  -- kør første gang straks
    brtFrame:SetScript("OnUpdate", function(self, elapsed)
        -- Shift-tjek: aktiver/deaktiver mus for drag vs. click-through (kun i lock-mode)
        local lockMove = BossHelperDB and BossHelperDB.brtLockMove ~= false
        if lockMove then
            local shiftHeld = IsShiftKeyDown()
            if shiftHeld ~= self._mouseEnabled then
                self:EnableMouse(shiftHeld)
                self._mouseEnabled = shiftHeld
            end
        end

        self.elapsed = self.elapsed + elapsed
        if self.elapsed < 0.25 then return end
        self.elapsed = 0

        local charges, maxCharges, started, duration = GetBRInfo()

        if not charges then
            -- Ingen charge-data udenfor encounter – vis "-" uden timer
            self.brVal:SetText("-")
            self.brVal:SetTextColor(unpack(MC.LABEL))
            self.timerVal:SetText("")
            return
        end

        -- BR-tæller (grøn / rød)
        if charges > 0 then
            self.brVal:SetText(tostring(charges))
            self.brVal:SetTextColor(unpack(MC.COUNT_AVAIL))
        else
            self.brVal:SetText("0")
            self.brVal:SetTextColor(unpack(MC.COUNT_EMPTY))
        end

        -- Timer (højre): vises kun når opladninger er under max
        if charges < maxCharges and duration and duration > 0 and started and started > 0 then
            local remaining = duration - (GetTime() - started)
            if remaining < 0 then remaining = 0 end
            local m = math_floor(remaining / 60)
            local s = math_floor(remaining % 60)
            self.timerVal:SetFormattedText("%d:%02d", m, s)
        else
            self.timerVal:SetText("")
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Offentligt API
-- ---------------------------------------------------------------------------
local function ApplySettings()
    if not brtFrame then return end
    local db = BossHelperDB or {}

    if db.brtEnabled == false then
        brtFrame:Hide()
        return
    end

    -- Opdater mus/click-through baseret på lock-move indstilling
    local lockMove = db.brtLockMove ~= false
    if lockMove then
        -- Kræver Shift for at flytte; click-through som standard
        local shiftHeld = IsShiftKeyDown()
        brtFrame:EnableMouse(shiftHeld)
        brtFrame._mouseEnabled = shiftHeld
    else
        -- Normal vindue: mus altid aktiv
        brtFrame:EnableMouse(true)
        brtFrame._mouseEnabled = true
    end

    local CC = BossHelper.UI.C

    -- Skalering
    local scale = tonumber(db.brtScale) or 1.0
    local oldScale = brtFrame:GetScale()
    brtFrame:SetScale(scale)

    if scale ~= oldScale then
        if db.brtCenterX and db.brtCenterY then
            brtFrame:ClearAllPoints()
            brtFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.brtCenterX / scale, db.brtCenterY / scale)
        else
            local cx, cy = brtFrame:GetCenter()
            if cx and cy then
                db.brtCenterX = cx * scale
                db.brtCenterY = cy * scale
                brtFrame:ClearAllPoints()
                brtFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
            end
        end
    end

    -- Baggrunds-alpha og border
    local alpha = (db.brtTransparency ~= nil) and db.brtTransparency or 0.95
    local bgC = CC.BG_PANEL_DARK
    brtFrame:SetBackdropColor(bgC[1], bgC[2], bgC[3], alpha)
    if db.brtNoBorder then
        brtFrame:SetBackdropBorderColor(0, 0, 0, 0)
    else
        local bC = CC.BORDER_AMBER
        brtFrame:SetBackdropBorderColor(bC[1], bC[2], bC[3], bC[4])
    end

    -- Titel og separator + højde og reankring af indhold
    local showTitle = not db.brtHideTitle
    if brtFrame.titleText then
        if showTitle then brtFrame.titleText:Show() else brtFrame.titleText:Hide() end
    end
    if brtFrame.sep then
        if showTitle then brtFrame.sep:Show() else brtFrame.sep:Hide() end
    end

    -- Ændr vindueshøjde og centrer indholdsrækken
    local newH   = showTitle and LAYOUT.H or LAYOUT.H_NO_TITLE
    local newY   = showTitle and -(LAYOUT.HEADER_H / 2) or 0
    local halfW  = LAYOUT.W / 2
    brtFrame:SetHeight(newH)
    if brtFrame.brLbl then
        brtFrame.brLbl:ClearAllPoints()
        brtFrame.brLbl:SetPoint("LEFT", brtFrame, "CENTER", -halfW + LAYOUT.PADDING, newY)
    end
    if brtFrame.brVal then
        brtFrame.brVal:ClearAllPoints()
        brtFrame.brVal:SetPoint("CENTER", brtFrame, "CENTER", 0, newY)
    end
    if brtFrame.timerVal then
        brtFrame.timerVal:ClearAllPoints()
        brtFrame.timerVal:SetPoint("RIGHT", brtFrame, "CENTER", halfW - LAYOUT.PADDING, newY)
    end
end

BattleResTracker.ApplySettings = ApplySettings

BattleResTracker.Show = function()
    if BossHelperDB and BossHelperDB.brtEnabled == false then return end
    CreateBattleResTracker()
    if brtFrame then ApplySettings(); brtFrame:Show() end
end

BattleResTracker.Hide = function()
    if brtFrame then brtFrame:Hide() end
end

BattleResTracker.Toggle = function()
    if BossHelperDB and BossHelperDB.brtEnabled == false then return end
    CreateBattleResTracker()
    if brtFrame then
        if brtFrame:IsShown() then
            brtFrame:Hide()
        else
            ApplySettings()
            brtFrame:Show()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Hjælpere
-- ---------------------------------------------------------------------------
local ZONE_DELAY = 1.5  -- sekunder at vente efter zone-skift (matches DungeonCheckWindow)

local function IsInMythicPlus()
    return C_ChallengeMode
        and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive()
end

local function IsInDungeon()
    if not GetInstanceInfo then return false end
    local _, instanceType = GetInstanceInfo()
    return instanceType == "party" or instanceType == "raid"
end

-- ---------------------------------------------------------------------------
-- Event-handler: vis vinduet ved dungeon-entry, skjul det udenfor
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    C_Timer.After(ZONE_DELAY, function()
        if BossHelperDB and BossHelperDB.brtEnabled == false then return end
        CreateBattleResTracker()
        if IsInDungeon() then
            BattleResTracker.Show()
        else
            if brtFrame then brtFrame:Hide() end
        end
    end)
end)
