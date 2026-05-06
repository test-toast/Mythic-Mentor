-- DungeonCheckWindow.lua
-- Kompakt tjek-vindue der vises automatisk ved dungeon-entry.
-- Viser spillerens spec og holdbarhed.
-- Samme visuelle stil som MiniWindow, men uden boss-ikon, boss-titel og dungeon-navn.

DungeonCheckWindow = DungeonCheckWindow or {}

-- ---------------------------------------------------------------------------
-- Modul-tilstand
-- ---------------------------------------------------------------------------
local dcwFrame = nil

-- ---------------------------------------------------------------------------
-- Layout-konstanter
-- ---------------------------------------------------------------------------
local LAYOUT = {
    W_MIN          = 130,  -- minimum bredde; udvides automatisk til spec-navnets længde
    H              = 235,  -- højde inkl. to stablede knapper i bunden
    H_NO_BTNS      = 170,  -- højde uden knapper (H - ACT_AREA_H)
    HEADER_H       = 34,
    PADDING        = 12,
    INNER_PAD      = 8,

    SPEC_ICON_SIZE  = 40,
    ICON_SHADOW_H  = 13,  -- højde på rolle-shadow nederst på ikonet
    SPEC_NAME_OFS  = 0,   -- vertikal offset for spec-navn inde i ikonhøjde
    SPEC_LOAD_OFS  = 17,  -- loadout lige under spec-navn (rolle er nu på ikonet)
    STATS_GAP      = 14,  -- mellemrum fra spec-blok til stats
    ROW_H          = 20,  -- højde per stats-række

    -- Handlingsknapper i bunden
    ACT_BTN_H      = 22,  -- højde på Ready Check / Countdown-knapper
    ACT_BTN_GAP    = 5,   -- mellemrum mellem de to stablede knapper
    ACT_BTN_PAD    = 8,   -- luft fra bunden af vinduet til nederste knap
    ACT_AREA_H     = 65,  -- afstand fra bund til separator (2 knapper + gaps + pad)

    -- Vindue-knapper
    WIN_BTN_SIZE = 20,
    WIN_BTN_X    = -5,
    WIN_BTN_Y    = -5,

    -- Skrifttyper
    FONT_TITLE   = 14,
    FONT_SPEC    = 14,
    FONT_ROLE    = 11,
    FONT_LOADOUT = 9,
    FONT_LABEL   = 10,
    FONT_VALUE   = 11,
    TITLE_OFFSET = 12,

    ZONE_DELAY   = 1.5,
}

-- ---------------------------------------------------------------------------
-- Farver
-- ---------------------------------------------------------------------------
local C  -- sættes i CreateDungeonCheckWindow (efter BossHelper.lua er loadet)

local MC = {
    WIN_BTN_BG         = {0.08, 0.09, 0.13, 0.95},
    CLOSE_HOVER_BG     = {1,    0.1,  0.1,  1   },
    CLOSE_HOVER_BORDER = {1,    0.6,  0.6,  1   },
    SEP                = {1,    0.5,  0,    0.35},
    -- Use same color as MiniWindow boss title
    TITLE              = {1.0, 0.5, 0.0},  -- match MiniWindow BOSS title color
    LABEL              = {0.55, 0.55, 0.75       },  -- sektion-label
    VALUE              = {0.98, 0.82, 0.55       },  -- spec-navn / dur default
    LOADOUT            = {0.52, 0.56, 0.78       },  -- loadout-tekst
    ROLE_TANK          = {0.25, 0.65, 1.00       },  -- blå
    ROLE_HEALER        = {0.20, 0.85, 0.35       },  -- grøn
    ROLE_DPS           = {1.00, 0.38, 0.22       },  -- rød-orange
    DUR_HIGH           = {0.2,  0.85, 0.2        },  -- >= 75 %
    DUR_MED            = {1.0,  0.78, 0.0        },  -- 40-74 %
    DUR_LOW            = {1.0,  0.28, 0.1        },  -- < 40 %
    CONSUMP_OK         = {0.2,  0.85, 0.2        },  -- buff aktiv
    CONSUMP_WARN       = {1.0,  0.78, 0.0        },  -- mangler buff, men har item
    CONSUMP_MISSING    = {1.0,  0.28, 0.1        },  -- mangler buff og item
}

-- ---------------------------------------------------------------------------
-- Durability-hjælper
-- Itererer alle rustnings- og våbenslots og returnerer samlet pct (0-100).
-- ---------------------------------------------------------------------------
local DURA_SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 }

local function GetOverallDurabilityPct()
    local totalCur, totalMax = 0, 0
    for _, slot in ipairs(DURA_SLOTS) do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            totalCur = totalCur + cur
            totalMax = totalMax + max
        end
    end
    if totalMax == 0 then return nil end
    return math.floor((totalCur / totalMax) * 100)
end

-- ---------------------------------------------------------------------------
-- Consumable buff/bag hjælpere
-- ---------------------------------------------------------------------------

-- Returnerer flask/phial-buff-navn eller nil (scanner alle aktive buffs).
local function GetFlaskBuff()
    local i = 1
    while true do
        local aura = C_UnitAuras and C_UnitAuras.GetBuffDataByIndex
            and C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        local name = aura.name
        if name and (name:find("Phial") or name:find("Flask")) then
            return name
        end
        i = i + 1
    end
    return nil
end

-- Returnerer food-buff-navn eller nil.
local function GetFoodBuff()
    local i = 1
    while true do
        local aura = C_UnitAuras and C_UnitAuras.GetBuffDataByIndex
            and C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        local name = aura.name
        if name == "Well Fed" then return name end
        i = i + 1
    end
    return nil
end

-- Tjekker tasker for flask/phial (Consumable subclass 1-3 + navn-match).
local function HasFlaskInBags()
    for bag = 0, 4 do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots(bag))
            or GetContainerNumSlots(bag)
        for slot = 1, (numSlots or 0) do
            local itemInfo = C_Container and C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemInfo.itemID)
                if classID == 0 and (subclassID == 1 or subclassID == 2 or subclassID == 3) then
                    local name = GetItemInfo(itemInfo.itemID)
                    if name and (name:find("Phial") or name:find("Flask")) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Returnerer antal flask/phial i tasker
local function CountFlaskInBags()
    local count = 0
    for bag = 0, 4 do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots(bag))
            or GetContainerNumSlots(bag)
        for slot = 1, (numSlots or 0) do
            local itemInfo = C_Container and C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemInfo.itemID)
                if classID == 0 and (subclassID == 1 or subclassID == 2 or subclassID == 3) then
                    local name = GetItemInfo(itemInfo.itemID)
                    if name and (name:find("Phial") or name:find("Flask")) then
                        count = count + (itemInfo.stackCount or 1)
                    end
                end
            end
        end
    end
    return count
end

-- Returnerer antal mad-items i tasker (quality >= Uncommon)
local function CountFoodInBags()
    local count = 0
    for bag = 0, 4 do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots(bag))
            or GetContainerNumSlots(bag)
        for slot = 1, (numSlots or 0) do
            local itemInfo = C_Container and C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemInfo.itemID)
                if classID == 0 and subclassID == 5 then
                    local _, _, quality = GetItemInfo(itemInfo.itemID)
                    if quality and quality >= 2 then
                        count = count + (itemInfo.stackCount or 1)
                    end
                end
            end
        end
    end
    return count
end

-- Tjekker tasker for mad-items (Consumable/Food&Drink, quality >= Uncommon).
local function HasFoodInBags()
    for bag = 0, 4 do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots(bag))
            or GetContainerNumSlots(bag)
        for slot = 1, (numSlots or 0) do
            local itemInfo = C_Container and C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                -- classID 0 = Consumable, subclassID 5 = Food & Drink
                local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemInfo.itemID)
                if classID == 0 and subclassID == 5 then
                    local _, _, quality = GetItemInfo(itemInfo.itemID)
                    if quality and quality >= 2 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Luk-knap (samme stil som MiniWindow)
-- ---------------------------------------------------------------------------
local function BuildCloseButton(f)
    local closeBtn = BossUI.CreateCustomButton(f, LAYOUT.WIN_BTN_SIZE, LAYOUT.WIN_BTN_SIZE, "X")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", LAYOUT.WIN_BTN_X, LAYOUT.WIN_BTN_Y)
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
        if self.icon then self.icon:SetVertexColor(1, 1, 1, 1) end
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(MC.WIN_BTN_BG))
        self:SetBackdropBorderColor(unpack(C.BORDER_GREY))
        if self.icon then
            self.icon:SetVertexColor(C.TEXT_ORANGE[1], C.TEXT_ORANGE[2], C.TEXT_ORANGE[3], 1)
        end
    end)
    f.closeBtn = closeBtn
end

-- ---------------------------------------------------------------------------
-- Opret vinduet (lazy init, kaldes én gang)
-- ---------------------------------------------------------------------------
local function CreateDungeonCheckWindow()
    if dcwFrame then return end
    C = BossHelper.UI.C

    dcwFrame = CreateFrame("Frame", "BossHelper_DungeonCheckFrame", UIParent, "BackdropTemplate")
    dcwFrame:SetSize(LAYOUT.W_MIN, LAYOUT.H)

    -- Gendan gemt position, ellers placer til venstre for midten
    if BossHelperDB and BossHelperDB.dcwX and BossHelperDB.dcwY then
        dcwFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
            BossHelperDB.dcwX, BossHelperDB.dcwY)
    else
        dcwFrame:SetPoint("CENTER", UIParent, "CENTER", -320, 0)
    end

    dcwFrame:SetFrameStrata("HIGH")
    dcwFrame:SetMovable(true)
    dcwFrame:EnableMouse(true)
    dcwFrame:RegisterForDrag("LeftButton")
    dcwFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    dcwFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BossHelperDB = BossHelperDB or {}
        local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        BossHelperDB.dcwX = self:GetLeft()  * scale
        BossHelperDB.dcwY = self:GetTop()   * scale
    end)
    dcwFrame:SetClampedToScreen(true)
    dcwFrame:Hide()

    -- Backdrop – identisk med MiniWindow
    BossHelper.UI.ApplyBackdrop(dcwFrame, "EDITBOX", C.BG_PANEL_DARK, C.BORDER_AMBER)

    -- -----------------------------------------------------------------------
    -- Header: "Check" titel (centreret) + separator
    -- -----------------------------------------------------------------------
    local titleText = dcwFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_TITLE, "OUTLINE")
    titleText:SetPoint("TOP", dcwFrame, "TOP", 0, -LAYOUT.TITLE_OFFSET)
    titleText:SetJustifyH("CENTER")
    titleText:SetText(Translate("DCW_TITLE"))
    titleText:SetTextColor(unpack(MC.TITLE))

    local sep = dcwFrame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  dcwFrame, "TOPLEFT",  LAYOUT.PADDING,  -LAYOUT.HEADER_H)
    sep:SetPoint("TOPRIGHT", dcwFrame, "TOPRIGHT", -LAYOUT.PADDING, -LAYOUT.HEADER_H)
    sep:SetColorTexture(MC.SEP[1], MC.SEP[2], MC.SEP[3], MC.SEP[4])

    -- -----------------------------------------------------------------------
    -- Spec-sektion
    -- -----------------------------------------------------------------------
    local cTop     = -(LAYOUT.HEADER_H + LAYOUT.INNER_PAD)  -- content top Y
    local textX    = LAYOUT.PADDING + LAYOUT.SPEC_ICON_SIZE + LAYOUT.INNER_PAD

    local specIcon = dcwFrame:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(LAYOUT.SPEC_ICON_SIZE, LAYOUT.SPEC_ICON_SIZE)
    specIcon:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", LAYOUT.PADDING, cTop)
    specIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    dcwFrame.specIcon = specIcon

    -- Halvgennemsigtig shadow i bunden af spec-ikonet (samme stil som KeystoneWidget)
    local iconShadow = dcwFrame:CreateTexture(nil, "OVERLAY")
    iconShadow:SetSize(LAYOUT.SPEC_ICON_SIZE, LAYOUT.ICON_SHADOW_H)
    iconShadow:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT",
        LAYOUT.PADDING,
        cTop - LAYOUT.SPEC_ICON_SIZE + LAYOUT.ICON_SHADOW_H)
    iconShadow:SetColorTexture(0.04, 0.05, 0.09, 0.82)
    dcwFrame.iconShadow = iconShadow

    -- Masken til cirkulært ikon er kommenteret ud så ikonet forbliver firkantet.
    -- Cirkulær maske på ikon + shadow (giver afrundede/cirkulære kanter)

    --local iconMask = dcwFrame:CreateMaskTexture()
    --iconMask:SetSize(LAYOUT.SPEC_ICON_SIZE, LAYOUT.SPEC_ICON_SIZE)
    --iconMask:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", LAYOUT.PADDING, cTop)
    --iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
    --    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    --specIcon:AddMaskTexture(iconMask)
    --iconShadow:AddMaskTexture(iconMask)
   

    -- Rolle-tekst henover shadow
    local roleIconVal = dcwFrame:CreateFontString(nil, "OVERLAY")
    roleIconVal:SetFont("Fonts\\FRIZQT___CYR.TTF", 8, "OUTLINE")
    roleIconVal:SetSize(LAYOUT.SPEC_ICON_SIZE, LAYOUT.ICON_SHADOW_H)
    roleIconVal:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT",
        LAYOUT.PADDING,
        cTop - LAYOUT.SPEC_ICON_SIZE + LAYOUT.ICON_SHADOW_H)
    roleIconVal:SetJustifyH("CENTER")
    roleIconVal:SetJustifyV("MIDDLE")
    roleIconVal:SetTextColor(unpack(MC.LABEL))
    roleIconVal:SetText("-")
    dcwFrame.roleIconVal = roleIconVal

    local specNameVal = dcwFrame:CreateFontString(nil, "OVERLAY")
    specNameVal:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_SPEC, "OUTLINE")
    specNameVal:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", textX, cTop - LAYOUT.SPEC_NAME_OFS)
    -- ingen RIGHT-anker: bredden måles i RefreshDCW og bruges til at resize rammen
    specNameVal:SetJustifyH("LEFT")
    specNameVal:SetTextColor(unpack(MC.VALUE))
    specNameVal:SetText("-")
    dcwFrame.specNameVal = specNameVal

    local loadoutVal = dcwFrame:CreateFontString(nil, "OVERLAY")
    loadoutVal:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_LOADOUT, "OUTLINE")
    loadoutVal:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", textX,           cTop - LAYOUT.SPEC_LOAD_OFS)
    loadoutVal:SetPoint("RIGHT",   dcwFrame, "RIGHT",   -LAYOUT.PADDING, 0)
    loadoutVal:SetJustifyH("LEFT")
    loadoutVal:SetTextColor(unpack(MC.LOADOUT))
    loadoutVal:SetWordWrap(false)
    loadoutVal:SetText("-")
    dcwFrame.loadoutVal = loadoutVal

    -- -----------------------------------------------------------------------
    -- Stats-sektion  (label LEFT, value RIGHT – fast kolonne)
    -- Række 1: Holdbarhed   Række 2: Flask   Række 3: Food
    -- -----------------------------------------------------------------------
    local statsY = cTop - LAYOUT.SPEC_ICON_SIZE - LAYOUT.STATS_GAP

    local function MakeRow(label, offsetRows)
        local y = statsY - offsetRows * LAYOUT.ROW_H

        local lbl = dcwFrame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", LAYOUT.FONT_LABEL, "OUTLINE")
        lbl:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", LAYOUT.PADDING, y)
        lbl:SetTextColor(unpack(MC.LABEL))
        lbl:SetText(label)

        local val = dcwFrame:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT___CYR.TTF", LAYOUT.FONT_VALUE, "OUTLINE")
        val:SetPoint("TOPRIGHT", dcwFrame, "TOPRIGHT", -LAYOUT.PADDING, y)
        val:SetJustifyH("RIGHT")
        val:SetWordWrap(false)
        val:SetTextColor(unpack(MC.VALUE))
        val:SetText("-")
        return val, lbl
    end

    dcwFrame.durVal,   dcwFrame.durLbl   = MakeRow(Translate("DCW_DURABILITY"), 0)
    dcwFrame.flaskVal, dcwFrame.flaskLbl = MakeRow(Translate("DCW_FLASK"),      1)
    dcwFrame.foodVal,  dcwFrame.foodLbl  = MakeRow(Translate("DCW_FOOD"),       2)

    -- -----------------------------------------------------------------------
    -- Handlingsknapper: Ready Check + Countdown (i bunden)
    -- -----------------------------------------------------------------------

    -- Separator over knapperne
    local sepBot = dcwFrame:CreateTexture(nil, "ARTWORK")
    sepBot:SetHeight(1)
    sepBot:SetPoint("BOTTOMLEFT",  dcwFrame, "BOTTOMLEFT",  LAYOUT.PADDING,  LAYOUT.ACT_AREA_H)
    sepBot:SetPoint("BOTTOMRIGHT", dcwFrame, "BOTTOMRIGHT", -LAYOUT.PADDING, LAYOUT.ACT_AREA_H)
    sepBot:SetColorTexture(MC.SEP[1], MC.SEP[2], MC.SEP[3], MC.SEP[4])
    dcwFrame.sepBot = sepBot

    -- Hjælper: er spilleren gruppe-leder eller assistent?
    local function IsLeaderOrAssist()
        return (UnitIsGroupLeader and UnitIsGroupLeader("player"))
            or (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))
    end

    -- Hjælper: kør countdown (samme logik som PortalAuthority:KeystoneUtility_DoPull10)
    local function DoCountdown(sec)
        if InCombatLockdown and InCombatLockdown() then return end
        local s = math.floor(math.max(1, math.min(60, sec or 10)))
        -- Prøv Blizzard's native API først, derefter /cd makro som fallback
        if C_PartyInfo and type(C_PartyInfo.DoCountdown) == "function" then
            pcall(C_PartyInfo.DoCountdown, s)
        elseif RunMacroText then
            pcall(RunMacroText, string.format("/cd %d", s))
        end
    end

    -- Beregn knap-bredde = fuld indre bredde
    local innerW = LAYOUT.W_MIN - LAYOUT.PADDING * 2

    -- Ready Check-knap — øverste knap (stablet over Countdown)
    local rdyBtn = BossUI.CreateCustomButton(dcwFrame, innerW, LAYOUT.ACT_BTN_H, Translate("DCW_READY_CHECK"))
    rdyBtn:ClearAllPoints()
    rdyBtn:SetPoint("BOTTOMLEFT",  dcwFrame, "BOTTOMLEFT",
        LAYOUT.PADDING,  LAYOUT.ACT_BTN_PAD + LAYOUT.ACT_BTN_H + LAYOUT.ACT_BTN_GAP)
    rdyBtn:SetPoint("BOTTOMRIGHT", dcwFrame, "BOTTOMRIGHT",
        -LAYOUT.PADDING, LAYOUT.ACT_BTN_PAD + LAYOUT.ACT_BTN_H + LAYOUT.ACT_BTN_GAP)
    if rdyBtn.text then rdyBtn.text:SetText(Translate("DCW_READY_CHECK")) end
    rdyBtn:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then return end
        if not (IsInGroup and IsInGroup()) then return end
        if not IsLeaderOrAssist() then return end
        if type(DoReadyCheck) == "function" then pcall(DoReadyCheck) end
    end)
    dcwFrame.rdyBtn = rdyBtn

    -- Countdown-knap — nederste knap, 10 sekunder
    local cdBtn = BossUI.CreateCustomButton(dcwFrame, innerW, LAYOUT.ACT_BTN_H, Translate("DCW_COUNTDOWN"))
    cdBtn:ClearAllPoints()
    cdBtn:SetPoint("BOTTOMLEFT",  dcwFrame, "BOTTOMLEFT",  LAYOUT.PADDING,  LAYOUT.ACT_BTN_PAD)
    cdBtn:SetPoint("BOTTOMRIGHT", dcwFrame, "BOTTOMRIGHT", -LAYOUT.PADDING, LAYOUT.ACT_BTN_PAD)
    if cdBtn.text then cdBtn.text:SetText(Translate("DCW_COUNTDOWN")) end
    cdBtn:SetScript("OnClick", function() DoCountdown(10) end)
    dcwFrame.cdBtn = cdBtn

    -- -----------------------------------------------------------------------
    -- Luk-knap
    -- -----------------------------------------------------------------------
    BuildCloseButton(dcwFrame)

    -- Anvend gemte settings (backdrop-alpha, border, synlighed af rækker)
    if DungeonCheckWindow.ApplySettings then DungeonCheckWindow.ApplySettings() end
end

-- ---------------------------------------------------------------------------
-- Hjælper: hent spec-info robust (matcher TitanSpecsLoadouts sin tilgang)
-- ---------------------------------------------------------------------------
local function GetSpecInfo()
    local specIndex
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        specIndex = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
        specIndex = GetSpecialization()
    end
    if not specIndex or specIndex == 0 then return nil end

    local specID, specName, _, specIconID, role

    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        local a, b, c, d, e = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        if type(a) == "table" then
            local info = a
            specID     = info.specializationID or info.specID or info.id
            specName   = info.name or b
            specIconID = info.icon or info.iconID or d
            role       = info.role or info.talentRole or e
        else
            specID     = a
            specName   = b
            specIconID = d
            role       = e
        end
    end

    -- Fallback til klassisk API
    if type(specID) ~= "number" and GetSpecializationInfo then
        local a,b,c,d,e = GetSpecializationInfo(specIndex)
        specID = a
        specName = b
        specIconID = d
        role = e
    end

    if not specID then return nil end
    return { specID = specID, name = specName, icon = specIconID, role = role }
end

-- ---------------------------------------------------------------------------
-- Hjælper: hent loadout-navn (matcher TitanSpecsLoadouts sin tilgang)
-- ---------------------------------------------------------------------------
local function GetCurrentLoadoutName(specID)
    if not C_ClassTalents then return nil end

    -- Primær: sidst valgte gemte config for denne spec
    local configID = C_ClassTalents.GetLastSelectedSavedConfigID
        and C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    if not (configID and configID > 0) then
        -- Fallback: aktiv config
        configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    end
    if not (configID and configID > 0) then return nil end

    -- GetConfigInfo: prøv C_ClassTalents først, derefter C_Traits
    local info
    if C_ClassTalents.GetConfigInfo then
        info = C_ClassTalents.GetConfigInfo(configID)
    end
    if not info and C_Traits and C_Traits.GetConfigInfo then
        info = C_Traits.GetConfigInfo(configID)
    end
    if info and info.name and info.name ~= "" then
        return info.name
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Anvend settings fra DB på vinduet:
-- backdrop-farve/alpha, border, spec-synlighed, stat-rækker (med repositionering),
-- og knapper (leader + dcwShowButtons).
-- ---------------------------------------------------------------------------
local function ApplySettings()
    if not dcwFrame then return end
    local db = BossHelperDB or {}

    -- Er DCW slået helt fra? Skjul og gør ingenting mere.
    if db.dcwEnabled == false then
        dcwFrame:Hide()
        return
    end
    local CC = BossHelper.UI.C

    -- Baggrunds-alpha og border
    local alpha = (db.dcwTransparency ~= nil) and db.dcwTransparency or 0.95
    local bgC = CC.BG_PANEL_DARK
    dcwFrame:SetBackdropColor(bgC[1], bgC[2], bgC[3], alpha)
    if db.dcwNoBorder then
        dcwFrame:SetBackdropBorderColor(0, 0, 0, 0)
    else
        local bC = CC.BORDER_AMBER
        dcwFrame:SetBackdropBorderColor(bC[1], bC[2], bC[3], bC[4])
    end

    -- Spec-sektion
    local showSpec = db.dcwShowSpec ~= false
    local specEls = { dcwFrame.specIcon, dcwFrame.iconShadow, dcwFrame.roleIconVal, dcwFrame.specNameVal, dcwFrame.loadoutVal }
    for _, el in ipairs(specEls) do
        if el then if showSpec then el:Show() else el:Hide() end end
    end

    -- Stat-rækker: vis/skjul + ompositionér dynamisk
    local showDur   = db.dcwShowDurability ~= false
    local showFlask = db.dcwShowFlask ~= false
    local showFood  = db.dcwShowFood ~= false

    local function setRowVis(lbl, val, show)
        if lbl then if show then lbl:Show() else lbl:Hide() end end
        if val then if show then val:Show() else val:Hide() end end
    end
    setRowVis(dcwFrame.durLbl,   dcwFrame.durVal,   showDur)
    setRowVis(dcwFrame.flaskLbl, dcwFrame.flaskVal, showFlask)
    setRowVis(dcwFrame.foodLbl,  dcwFrame.foodVal,  showFood)

    -- Ompositionér synlige rækker
    local specGap    = showSpec and (LAYOUT.SPEC_ICON_SIZE + LAYOUT.STATS_GAP) or LAYOUT.INNER_PAD
    local cTop       = -(LAYOUT.HEADER_H + LAYOUT.INNER_PAD)
    local statsBaseY = cTop - specGap
    local rowDefs = {
        { show = showDur,   lbl = dcwFrame.durLbl,   val = dcwFrame.durVal   },
        { show = showFlask, lbl = dcwFrame.flaskLbl, val = dcwFrame.flaskVal },
        { show = showFood,  lbl = dcwFrame.foodLbl,  val = dcwFrame.foodVal  },
    }
    local nVisible = 0
    for _, row in ipairs(rowDefs) do
        if row.show then
            local y = statsBaseY - nVisible * LAYOUT.ROW_H
            if row.lbl then
                row.lbl:ClearAllPoints()
                row.lbl:SetPoint("TOPLEFT", dcwFrame, "TOPLEFT", LAYOUT.PADDING, y)
            end
            if row.val then
                row.val:ClearAllPoints()
                row.val:SetPoint("TOPRIGHT", dcwFrame, "TOPRIGHT", -LAYOUT.PADDING, y)
            end
            nVisible = nVisible + 1
        end
    end

    -- Beregn ny højde
    local absContentTop = LAYOUT.HEADER_H + LAYOUT.INNER_PAD + specGap
    local baseH = math.max(60, absContentTop + nVisible * LAYOUT.ROW_H + 14)

    -- Knapper (kun for leader OG dcwShowButtons)
    local showBtns  = db.dcwShowButtons ~= false
    local isLeader  = UnitIsGroupLeader and UnitIsGroupLeader("player")
    if showBtns and isLeader then
        if dcwFrame.sepBot then dcwFrame.sepBot:Show() end
        if dcwFrame.rdyBtn then dcwFrame.rdyBtn:Show() end
        if dcwFrame.cdBtn  then dcwFrame.cdBtn:Show()  end
        dcwFrame:SetHeight(baseH + LAYOUT.ACT_AREA_H)
    else
        if dcwFrame.sepBot then dcwFrame.sepBot:Hide() end
        if dcwFrame.rdyBtn then dcwFrame.rdyBtn:Hide() end
        if dcwFrame.cdBtn  then dcwFrame.cdBtn:Hide()  end
        dcwFrame:SetHeight(baseH)
    end
end

-- ---------------------------------------------------------------------------
-- Refresh: opdater spec og holdbarhed
-- ---------------------------------------------------------------------------
local function RefreshDCW()
    if not dcwFrame then return end

    -- Spec
    local specInfo = GetSpecInfo()
    if specInfo then
        if dcwFrame.specIcon then
            dcwFrame.specIcon:SetTexture(specInfo.icon)
        end
        if dcwFrame.specNameVal then
            dcwFrame.specNameVal:SetText(specInfo.name or "-")
            -- Tilpas vinduets bredde automatisk til spec-navnets længde
            local textX = LAYOUT.PADDING + LAYOUT.SPEC_ICON_SIZE + LAYOUT.INNER_PAD
            local newW = math.max(LAYOUT.W_MIN,
                math.ceil(textX + dcwFrame.specNameVal:GetStringWidth() + LAYOUT.PADDING + 4))
            dcwFrame:SetWidth(newW)
        end
        if dcwFrame.roleIconVal then
            local role = specInfo.role
            local roleText, rr, rg, rb
            if role == "TANK" then
                roleText = Translate("ROLE_TANK")
                rr, rg, rb = MC.ROLE_TANK[1], MC.ROLE_TANK[2], MC.ROLE_TANK[3]
            elseif role == "HEALER" then
                roleText = Translate("ROLE_HEALER")
                rr, rg, rb = MC.ROLE_HEALER[1], MC.ROLE_HEALER[2], MC.ROLE_HEALER[3]
            elseif role == "DAMAGER" then
                roleText = Translate("ROLE_DPS")
                rr, rg, rb = MC.ROLE_DPS[1], MC.ROLE_DPS[2], MC.ROLE_DPS[3]
            else
                roleText = role or "-"
                rr, rg, rb = MC.LABEL[1], MC.LABEL[2], MC.LABEL[3]
            end
            dcwFrame.roleIconVal:SetText(roleText)
            dcwFrame.roleIconVal:SetTextColor(rr, rg, rb)
        end
        if dcwFrame.loadoutVal then
            dcwFrame.loadoutVal:SetText(GetCurrentLoadoutName(specInfo.specID) or "-")
        end
    else
        if dcwFrame.specNameVal  then dcwFrame.specNameVal:SetText("-")  end
        if dcwFrame.roleIconVal  then dcwFrame.roleIconVal:SetText("-")  end
        if dcwFrame.loadoutVal   then dcwFrame.loadoutVal:SetText("-")   end
    end

    -- Holdbarhed
    local pct = GetOverallDurabilityPct()
    if dcwFrame.durVal then
        if pct then
            local r, g, b
            if pct >= 75 then
                r, g, b = MC.DUR_HIGH[1], MC.DUR_HIGH[2], MC.DUR_HIGH[3]
            elseif pct >= 40 then
                r, g, b = MC.DUR_MED[1], MC.DUR_MED[2], MC.DUR_MED[3]
            else
                r, g, b = MC.DUR_LOW[1], MC.DUR_LOW[2], MC.DUR_LOW[3]
            end
            dcwFrame.durVal:SetText(pct .. "%")
            dcwFrame.durVal:SetTextColor(r, g, b)
        else
            dcwFrame.durVal:SetText("-")
            dcwFrame.durVal:SetTextColor(unpack(MC.VALUE))
        end
    end

    -- Flask / Phial (vis antal i tasker)
    if dcwFrame.flaskVal then
        local buff = GetFlaskBuff()
        local count = CountFlaskInBags()
            if buff then
            local txt = Translate("DCW_ACTIVE")
            if count and count > 0 then txt = txt .. " (" .. tostring(count) .. ")" end
            dcwFrame.flaskVal:SetText(txt)
            dcwFrame.flaskVal:SetTextColor(unpack(MC.CONSUMP_OK))
        elseif count and count > 0 then
            dcwFrame.flaskVal:SetText(Translate("DCW_NOT_APPLIED") .. " (" .. tostring(count) .. ")")
            dcwFrame.flaskVal:SetTextColor(unpack(MC.CONSUMP_WARN))
        else
            dcwFrame.flaskVal:SetText(Translate("DCW_NONE_IN_BAGS"))
            dcwFrame.flaskVal:SetTextColor(unpack(MC.CONSUMP_MISSING))
        end
    end

    -- Food (vis antal i tasker)
    if dcwFrame.foodVal then
        local buff = GetFoodBuff()
        local count = CountFoodInBags()
        if buff then
            local txt = Translate("DCW_ACTIVE")
            if count and count > 0 then txt = txt .. " (" .. tostring(count) .. ")" end
            dcwFrame.foodVal:SetText(txt)
            dcwFrame.foodVal:SetTextColor(unpack(MC.CONSUMP_OK))
        elseif count and count > 0 then
            dcwFrame.foodVal:SetText(Translate("DCW_NOT_APPLIED") .. " (" .. tostring(count) .. ")")
            dcwFrame.foodVal:SetTextColor(unpack(MC.CONSUMP_WARN))
        else
            dcwFrame.foodVal:SetText(Translate("DCW_NONE_IN_BAGS"))
            dcwFrame.foodVal:SetTextColor(unpack(MC.CONSUMP_MISSING))
        end
    end

    -- Knap-synlighed (vises kun for party leader)
    ApplySettings()
end

DungeonCheckWindow.Refresh       = RefreshDCW
DungeonCheckWindow.ApplySettings = ApplySettings
DungeonCheckWindow.Show = function()
    CreateDungeonCheckWindow()
    if dcwFrame then RefreshDCW(); dcwFrame:Show() end
end

-- ---------------------------------------------------------------------------
-- Auto-refresh: opdater vinduet når relevante ting ændrer sig,
-- men KUN når vinduet er synligt (performance-venlig).
-- Debounce: samler hurtige events til ét kald 0.5s efter sidste event.
-- ---------------------------------------------------------------------------
local refreshPending = false

local function ScheduleRefresh()
    if not dcwFrame or not dcwFrame:IsShown() then return end
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.5, function()
        refreshPending = false
        if dcwFrame and dcwFrame:IsShown() then
            RefreshDCW()
        end
    end)
end

local updateFrame = CreateFrame("Frame")
-- Buff-ændringer (flask / food / Well Fed)
updateFrame:RegisterEvent("UNIT_AURA")
-- Spec- eller loadout-skift
updateFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
updateFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
-- Rustning på/af (durability)
updateFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
-- Pose ændres (flask/food talt op/ned)
updateFrame:RegisterEvent("BAG_UPDATE")
-- Gruppesammensætning ændres (leder-tjek opdateres)
updateFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

updateFrame:SetScript("OnEvent", function(self, event, unitOrSlot, ...)
    -- UNIT_AURA fyrer for alle units; vi vil kun have player
    if event == "UNIT_AURA" and unitOrSlot ~= "player" then return end
    ScheduleRefresh()
end)

-- ---------------------------------------------------------------------------
-- Hjælper: er vi i en aktiv M+ run?
-- ---------------------------------------------------------------------------
local function IsInMythicPlus()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return C_ChallengeMode.IsChallengeModeActive()
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Event-handler: vis vinduet ved dungeon-entry, skjul det udenfor
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- M+ timer starter = luk vinduet
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
-- Kamp starter = luk vinduet (kun i ikke-M+ dungeon)
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Luk øjeblikkeligt når M+ timer starter
    if event == "CHALLENGE_MODE_START" then
        if dcwFrame then dcwFrame:Hide() end
        return
    end

    -- Luk ved combat-start i almindelige dungeons (ikke M+)
    if event == "PLAYER_REGEN_DISABLED" then
        if dcwFrame and dcwFrame:IsShown() and not IsInMythicPlus() then
            dcwFrame:Hide()
        end
        return
    end

    -- Zone-ændring: vis/skjul baseret på instans-type
    C_Timer.After(LAYOUT.ZONE_DELAY, function()
        -- Er DCW slået helt fra? Gør ingenting.
        if BossHelperDB and BossHelperDB.dcwEnabled == false then return end
        CreateDungeonCheckWindow()
        if not GetInstanceInfo then return end
        local _, instanceType = GetInstanceInfo()
        if instanceType == "party" or instanceType == "raid" then
            -- Vis ikke hvis vi allerede er i en aktiv M+ run
            if IsInMythicPlus() then
                dcwFrame:Hide()
            else
                RefreshDCW()
                dcwFrame:Show()
            end
        elseif dcwFrame then
            dcwFrame:Hide()
        end
    end)
end)
