-- QuickStart.lua
-- Vises én gang ved første installation og lader brugeren vælge et setup-profil.
--
-- Public API:
--   BossHelper.QuickStart.ShowIfNeeded()   — vis kun hvis quickStartDone er false/nil
--   BossHelper.QuickStart.Show()           — tving vinduet frem (fx fra Settings)

BossHelper.QuickStart = {}

local QS = BossHelper.QuickStart
local _C = BossHelper.UI.C

-- ---------------------------------------------------------------------------
-- Profiler
-- ---------------------------------------------------------------------------
local PROFILES = {
    recommended = {
        miniWindowEnabled      = true,
        keyTrackerEnabled      = false,
        showKeysOnStartPage    = false,
        showKeysInGroupFinder  = false,
        teleportOnMythicTab    = false,
        dcwEnabled             = false,
        brtEnabled             = false,
        autoInviteEnabled      = false,
    },
    advanced = {
        miniWindowEnabled      = true,
        keyTrackerEnabled      = true,
        showKeysOnStartPage    = true,
        showKeysInGroupFinder  = true,
        teleportOnMythicTab    = true,
        dcwEnabled             = true,
        brtEnabled             = true,
        autoInviteEnabled      = false,
    },
}

-- ---------------------------------------------------------------------------
-- Advanced wizard – features der gennemgås ét ad gangen
-- ---------------------------------------------------------------------------
local SIMG          = "Interface\\AddOns\\BossHelper\\Media\\settings-img\\"
local SIMG_START    = "Interface\\AddOns\\BossHelper\\Media\\start\\"

local WIZARD_FEATURES = {
    {
        nameKey = "QS_FEAT_MINI",
        descKey = "QS_DESC_MINI",
        dbKeys  = { "miniWindowEnabled" },
        image   = SIMG .. "mini-window\\mini-window.png",
    },
    {
        nameKey = "QS_FEAT_KEYS",
        descKey = "QS_DESC_KEYS",
        dbKeys  = { "keyTrackerEnabled", "showKeysOnStartPage", "showKeysInGroupFinder" },
        image   = SIMG .. "key-tracker\\key-list.png",
    },
    {
        nameKey = "QS_FEAT_DCW",
        descKey = "QS_DESC_DCW",
        dbKeys  = { "dcwEnabled" },
        image   = SIMG .. "dungeon-check\\check-w.png",
    },
    {
        nameKey = "QS_FEAT_BRT",
        descKey = "QS_DESC_BRT",
        dbKeys  = { "brtEnabled" },
        image   = SIMG .. "br-tracker\\br-tracker.png",
    },
    {
        nameKey = "QS_FEAT_TELEPORT",
        descKey = "QS_DESC_TELEPORT",
        dbKeys  = { "teleportOnMythicTab" },
        image   = SIMG .. "general\\mythic-tap-teleport.png",
    },
    {
        nameKey = "QS_FEAT_INVITE",
        descKey = "QS_DESC_INVITE",
        dbKeys  = { "autoInviteEnabled" },
        image   = nil,
    },
    {
        nameKey  = "QS_FINISH",
        descKey  = "",
        dbKeys   = {},
        image    = SIMG_START .. "setup-complete.png",
        isFinish = true,
    },
}

-- ---------------------------------------------------------------------------
-- Intern hjælper: anvend en profil og marker setup som færdigt
-- ---------------------------------------------------------------------------
local function ApplyProfile(key)
    BossHelperDB = BossHelperDB or {}
    for k, v in pairs(PROFILES[key] or {}) do
        BossHelperDB[k] = v
    end
    BossHelperDB.quickStartDone = true
end

-- Anvend de valg der er lavet i wizard-gennemgangen
local function ApplyWizardChoices(choices)
    BossHelperDB = BossHelperDB or {}
    -- Start med recommended som base (tactics altid slået til)
    for k, v in pairs(PROFILES["recommended"] or {}) do
        BossHelperDB[k] = v
    end
    -- Overskriv med brugerens valg
    for _, feature in ipairs(WIZARD_FEATURES) do
        local enabled = choices[feature.nameKey]
        for _, dbKey in ipairs(feature.dbKeys) do
            BossHelperDB[dbKey] = enabled
        end
    end
    BossHelperDB.quickStartDone = true
end

-- ---------------------------------------------------------------------------
-- Layout-konstanter
-- ---------------------------------------------------------------------------
local WIN_W  = 560
local WIN_H  = 605
local CARD_W = 244
local CARD_H = 310

local _win        -- forward-declaration
local _mainPage   -- sub-frame med kortene + footer
local _wizardPage -- sub-frame til wizard
local _header     -- banner + subtitle + separator (skjules i wizard-tilstand)

local _wizardStep    = 1
local _wizardMaxStep = 1
local _wizardChoices = {}

-- ---------------------------------------------------------------------------
-- Opret et enkelt option-kort
-- ---------------------------------------------------------------------------
local function BuildCard(parent, xOffset, titleKey, descKey, imagePath, profileKey, onSelect)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    card:SetPoint("TOP", parent, "TOP", xOffset, -9)
    BossHelper.UI.ApplyBackdrop(card, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT___CYR.TTF", 14, "OUTLINE")
    title:SetPoint("TOP", card, "TOP", 0, -14)
    title:SetTextColor(1, 0.5, 0)
    title:SetText(Translate(titleKey))

    local titleSep = card:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  card, "TOPLEFT",  10, -32)
    titleSep:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -32)
    titleSep:SetColorTexture(1, 0.5, 0, 0.25)

    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOP", titleSep, "BOTTOM", 0, -8)
    desc:SetSize(CARD_W - 24, 0)
    desc:SetJustifyH("CENTER")
    desc:SetJustifyV("TOP")
    desc:SetText(Translate(descKey))
    desc:SetTextColor(0.78, 0.78, 0.78)

    local imgFrame = CreateFrame("Frame", nil, card)
    imgFrame:SetSize(200, 200)
    imgFrame:SetPoint("TOP", desc, "BOTTOM", 0, -8)
    
    local featureImg = imgFrame:CreateTexture(nil, "ARTWORK")
    featureImg:SetPoint("TOPLEFT",     imgFrame, "TOPLEFT",     4, -4)
    featureImg:SetPoint("BOTTOMRIGHT", imgFrame, "BOTTOMRIGHT", -4,  4)
    featureImg:SetTexture(imagePath)
    
    if imgFrame.CreateMaskTexture and featureImg.AddMaskTexture then
        local imgMask = imgFrame:CreateMaskTexture()
        imgMask:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Masks\\CoverFadeMask")
        imgMask:SetAllPoints(featureImg)
        featureImg:AddMaskTexture(imgMask)
    end

    local btnLabel = profileKey == "recommended" and "QS_SELECT_RECOMMENDED" or "QS_SELECT_ADVANCED"
    local btn = BossHelper.Buttons.Create(card, CARD_W - 20, 28, btnLabel)
    btn:SetPoint("BOTTOM", card, "BOTTOM", 0, 10)
    btn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        onSelect()
    end)

    return card
end

-- ---------------------------------------------------------------------------
-- Hjælper: opdater wizard-sidens indhold til givet trin
-- ---------------------------------------------------------------------------
local function UpdateWizardStep(wp, step)
    local feature = WIZARD_FEATURES[step]
    local NUM     = #WIZARD_FEATURES

    -- Finish-trin: vis oversigt over valg
    if feature.isFinish then
        wp.nameText:SetText(Translate("QS_FINISH_TITLE"))
        wp.descText:SetText("")
        wp.descText:Hide()
        wp.finishList:Show()
        for _, row in ipairs(wp.finishRows) do
            local val = _wizardChoices[row.nameKey]
            if val == true then
                row.icon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\check.png")
                row.icon:SetVertexColor(1, 1, 1)
                row.lbl:SetText(Translate(row.nameKey))
                row.lbl:SetTextColor(1, 1, 1)
            elseif val == false then
                row.icon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\x.png")
                row.icon:SetVertexColor(1, 1, 1)
                row.lbl:SetText(Translate(row.nameKey))
                row.lbl:SetTextColor(0.55, 0.55, 0.55)
            else
                row.icon:SetTexture(nil)
                row.lbl:SetText(Translate(row.nameKey))
                row.lbl:SetTextColor(0.4, 0.4, 0.4)
            end
        end
        
        if feature.image then
            wp.featureImg:SetTexture(feature.image)
            wp.featureImg:SetAlpha(1)
            wp.featureImg:Show()
            wp.imgPlaceholder:Hide()
        else
            wp.featureImg:SetTexture(nil)
            wp.imgPlaceholder:Hide()
        end
        
        wp.enableBtn:Hide()
        wp.disableBtn:Hide()
        if wp.finishBtn then wp.finishBtn:Show() end
    else
        -- Tekst
        wp.nameText:SetText(Translate(feature.nameKey))
        wp.finishList:Hide()
        wp.descText:SetText(Translate(feature.descKey))
        wp.descText:Show()

        -- Billede
        if feature.image then
            wp.featureImg:SetTexture(feature.image)
            wp.featureImg:SetAlpha(1)
            wp.imgPlaceholder:Hide()
        else
            wp.featureImg:SetTexture(nil)
            wp.imgPlaceholder:Show()
        end
        wp.enableBtn:Show()
        wp.disableBtn:Show()
        if wp.finishBtn then wp.finishBtn:Hide() end
    end

    -- Step-dots
    for i = 1, NUM do
        local dot  = wp.stepDots[i]
        local line = wp.stepLines[i]

        if i == step then
            -- Aktiv: samme stil som valgt boss
            dot:SetBackdropColor(1, 0.5, 0, 1)
            dot:SetBackdropBorderColor(1, 0.5, 0, 1)
            dot.label:SetText("|cFFFFFFFF" .. i .. "|r")
        elseif i <= _wizardMaxStep then
            -- Besøgt: orange kant + nummer
            dot:SetBackdropColor(0.14, 0.08, 0.01, 0.95)
            dot:SetBackdropBorderColor(1, 0.55, 0.1, 0.9)
            dot.label:SetText("|cFFFF9922" .. i .. "|r")
        else
            -- Kommende: mørk + grå
            dot:SetBackdropColor(_C.BG_DARK[1], _C.BG_DARK[2], _C.BG_DARK[3], 0.95)
            dot:SetBackdropBorderColor(0.28, 0.28, 0.28, 0.5)
            dot.label:SetText("|cFF4A4A4A" .. i .. "|r")
        end

        -- Forbindelseslinjer
        if line then
            if i < _wizardMaxStep then
                line:SetColorTexture(1, 0.52, 0.1, 0.65)
            else
                line:SetColorTexture(0.22, 0.22, 0.22, 0.7)
            end
        end

        -- Dot-navn farve
        local dotName = wp.stepDotNames[i]
        if dotName then
            if i == step then
                -- Aktiv
                dotName:SetTextColor(1, 0.55, 0.1)
            elseif i <= _wizardMaxStep then
                -- Besøgt
                dotName:SetTextColor(0.7, 0.7, 0.7)
            else
                -- Kommende
                dotName:SetTextColor(0.42, 0.42, 0.42)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Vis/skjul sider
-- ---------------------------------------------------------------------------
local function ShowMainPage()
    if _win        then _win:SetHeight(WIN_H)  end
    if _header     then _header:Show()        end
    if _mainPage   then _mainPage:Show()      end
    if _wizardPage then
        _wizardPage:ClearAllPoints()
        _wizardPage:SetPoint("TOPLEFT",     _win, "TOPLEFT",     0, -246)
        _wizardPage:SetPoint("BOTTOMRIGHT", _win, "BOTTOMRIGHT", 0,    0)
        _wizardPage:Hide()
    end
end

local function ShowWizardPage()
    _wizardStep    = 1
    _wizardMaxStep = 1
    _wizardChoices = {}
    if _win        then _win:SetHeight(430)   end
    if _header     then _header:Hide()        end
    if _mainPage   then _mainPage:Hide()      end
    if _wizardPage then
        _wizardPage:ClearAllPoints()
        _wizardPage:SetPoint("TOPLEFT",     _win, "TOPLEFT",     0, -10)
        _wizardPage:SetPoint("BOTTOMRIGHT", _win, "BOTTOMRIGHT", 0,   0)
        _wizardPage:Show()
        UpdateWizardStep(_wizardPage, 1)
    end
end

-- ---------------------------------------------------------------------------
-- Byg wizard-siden
-- ---------------------------------------------------------------------------
local function BuildWizardPage(win)
    local wp = CreateFrame("Frame", nil, win)
    wp:SetPoint("TOPLEFT",     win, "TOPLEFT",     0, -246)
    wp:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0,    0)
    wp:Hide()

    -- "Setup Wizard" titel øverst til venstre
    local wizTitle = wp:CreateFontString(nil, "OVERLAY")
    wizTitle:SetFont("Fonts\\FRIZQT___CYR.TTF", 14, "OUTLINE")
    wizTitle:SetPoint("TOPLEFT", wp, "TOPLEFT", 14, -6)
    wizTitle:SetText("Setup Wizard")
    wizTitle:SetTextColor(1, 0.55, 0)

    -- Instruktions-hint (undertitel under "Setup Wizard")
    local hint = wp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", wizTitle, "BOTTOMLEFT", 0, -3)
    hint:SetSize(WIN_W - 28, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(Translate("QS_WIZARD_HINT"))
    hint:SetTextColor(0.7, 0.7, 0.7)

    local NUM_STEPS = #WIZARD_FEATURES
    local DOT_SIZE  = 26
    local DOT_GAP   = 68  -- afstand center-til-center

    -- ----------------------------------------------------------------
    -- 1. Step-dots med forbindelseslinjer
    -- ----------------------------------------------------------------
    wp.stepDots     = {}
    wp.stepLines    = {}
    wp.stepDotNames = {}

    for i = 1, NUM_STEPS do
        local cx = -(NUM_STEPS - 1) * DOT_GAP / 2 + (i - 1) * DOT_GAP

        local dot = CreateFrame("Button", nil, wp, "BackdropTemplate")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint("TOP", wp, "TOP", cx, -52)
        BossHelper.UI.ApplyBackdrop(dot, "BTN", _C.BG_DARK, _C.BORDER_GREY)

        dot.label = dot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dot.label:SetPoint("CENTER")
        dot.label:SetText(tostring(i))
        dot.label:SetTextColor(0.4, 0.4, 0.4)

        -- Tooltip + klik (brug do-blok for at fange i korrekt)
        do
            local idx = i
            dot:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(1, 1, 0.6, 1)
            end)
            dot:SetScript("OnLeave", function()
                UpdateWizardStep(wp, _wizardStep)
            end)
            dot:SetScript("OnClick", function()
                BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
                _wizardStep    = idx
                _wizardMaxStep = math.max(_wizardMaxStep, idx)
                UpdateWizardStep(wp, idx)
            end)
        end

        wp.stepDots[i] = dot

        -- Feature-navn under dot
        local dotName = wp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dotName:SetPoint("TOP", dot, "BOTTOM", 0, -3)
        dotName:SetSize(DOT_GAP - 2, 0)
        dotName:SetJustifyH("CENTER")
        dotName:SetText(Translate(WIZARD_FEATURES[i].nameKey))
        dotName:SetTextColor(0.42, 0.42, 0.42)
        wp.stepDotNames[i] = dotName
    end

    -- Forbindelseslinjer (oprettes efter alle dots)
    for i = 1, NUM_STEPS - 1 do
        local line = wp:CreateTexture(nil, "ARTWORK")
        line:SetHeight(2)
        line:SetPoint("LEFT",  wp.stepDots[i],     "RIGHT",  3, 0)
        line:SetPoint("RIGHT", wp.stepDots[i + 1], "LEFT",  -3, 0)
        line:SetColorTexture(0.22, 0.22, 0.22, 0.7)
        wp.stepLines[i] = line
    end


    -- ----------------------------------------------------------------
    -- 2 & 3. Indholdsbox (billede + navn + beskrivelse)
    -- ----------------------------------------------------------------
    local PAD   = 12
    local IMG_W = 240

    local contentBox = CreateFrame("Frame", nil, wp, "BackdropTemplate")
    contentBox:SetPoint("TOPLEFT",     wp, "TOPLEFT",     10,  -114)
    contentBox:SetPoint("BOTTOMRIGHT", wp, "BOTTOMRIGHT", -10,   42)
    BossHelper.UI.ApplyBackdrop(contentBox, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)

    -- Billedramme (fylder højden af boksen)
    local imgFrame = CreateFrame("Frame", nil, contentBox)
    imgFrame:SetSize(IMG_W, IMG_W)
    imgFrame:SetPoint("TOPLEFT", contentBox, "TOPLEFT", PAD, -PAD)

    wp.featureImg = imgFrame:CreateTexture(nil, "ARTWORK")
    wp.featureImg:SetPoint("TOPLEFT",     imgFrame, "TOPLEFT",     4, -4)
    wp.featureImg:SetPoint("BOTTOMRIGHT", imgFrame, "BOTTOMRIGHT", -4,  4)
    if imgFrame.CreateMaskTexture and wp.featureImg.AddMaskTexture then
        local imgMask = imgFrame:CreateMaskTexture()
        imgMask:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Masks\\CoverFadeMask")
        imgMask:SetAllPoints(wp.featureImg)
        wp.featureImg:AddMaskTexture(imgMask)
    end

    wp.imgPlaceholder = imgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    wp.imgPlaceholder:SetPoint("CENTER")
    wp.imgPlaceholder:SetText("|cFF444455No Preview|r")
    wp.imgPlaceholder:Hide()

    -- Tekst-sektion (højre for billede)
    local TEXT_X = PAD + IMG_W + PAD
    local TEXT_W = WIN_W - 20 - TEXT_X - PAD

    wp.nameText = contentBox:CreateFontString(nil, "OVERLAY")
    wp.nameText:SetFont("Fonts\\FRIZQT___CYR.TTF", 24, "OUTLINE")
    wp.nameText:SetPoint("TOPLEFT", contentBox, "TOPLEFT", TEXT_X, -PAD)
    wp.nameText:SetSize(TEXT_W, 0)
    wp.nameText:SetJustifyH("LEFT")
    wp.nameText:SetJustifyV("TOP")
    wp.nameText:SetTextColor(1, 0.55, 0)

    wp.descText = contentBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wp.descText:SetPoint("TOPLEFT", wp.nameText, "BOTTOMLEFT", 0, -10)
    wp.descText:SetSize(TEXT_W, 0)
    wp.descText:SetJustifyH("LEFT")
    wp.descText:SetJustifyV("TOP")
    wp.descText:SetTextColor(0.78, 0.78, 0.78)

    -- Finish-liste med ikon-textures per feature
    local ROW_H = 22
    wp.finishList = CreateFrame("Frame", nil, contentBox)
    wp.finishList:SetPoint("TOPLEFT",  wp.nameText, "BOTTOMLEFT",  0, -10)
    wp.finishList:SetSize(TEXT_W, 200)
    wp.finishList:Hide()

    wp.finishRows = {}
    local rowIdx = 0
    for _, f in ipairs(WIZARD_FEATURES) do
        if not f.isFinish then
            rowIdx = rowIdx + 1
            local row = CreateFrame("Frame", nil, wp.finishList)
            row:SetSize(TEXT_W, ROW_H)
            row:SetPoint("TOPLEFT", wp.finishList, "TOPLEFT", 0, -(rowIdx - 1) * (ROW_H + 5))

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", row, "LEFT", 0, 0)

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", icon, "RIGHT", 7, 0)
            lbl:SetSize(TEXT_W - 26, 0)
            lbl:SetJustifyH("LEFT")

            row.icon    = icon
            row.lbl     = lbl
            row.nameKey = f.nameKey
            wp.finishRows[rowIdx] = row
        end
    end

    -- ----------------------------------------------------------------
    -- 4. Enable / Disable knapper (standard stil)
    -- ----------------------------------------------------------------
    wp.enableBtn  = BossHelper.Buttons.Create(wp, 110, 28, "QS_ADV_ENABLE")
    wp.disableBtn = BossHelper.Buttons.Create(wp, 110, 28, "QS_ADV_DISABLE")
    wp.enableBtn._normalTextColor = {0.2, 1, 0.2}
    wp.enableBtn._hoverTextColor  = {0.6, 1, 0.6}
    wp.enableBtn.text:SetTextColor(0.2, 1, 0.2)
    wp.disableBtn._normalTextColor = {1, 0.2, 0.2}
    wp.disableBtn._hoverTextColor  = {1, 0.6, 0.6}
    wp.disableBtn.text:SetTextColor(1, 0.2, 0.2)

    wp.enableBtn:SetPoint( "BOTTOMRIGHT", wp, "BOTTOMRIGHT", -12,   9)
    wp.disableBtn:SetPoint("BOTTOMRIGHT", wp, "BOTTOMRIGHT", -130,  9)

    wp.finishBtn = BossHelper.Buttons.Create(wp, 110, 28, "QS_FINISH_BTN")
    wp.finishBtn:SetPoint("BOTTOMRIGHT", wp, "BOTTOMRIGHT", -12, 9)
    wp.finishBtn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        ApplyWizardChoices(_wizardChoices)
        if _win then _win:Hide() end
        ReloadUI()
    end)
    wp.finishBtn:Hide()

    wp.enableBtn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        _wizardChoices[WIZARD_FEATURES[_wizardStep].nameKey] = true
        _wizardStep    = _wizardStep + 1
        _wizardMaxStep = math.max(_wizardMaxStep, _wizardStep)
        if _wizardStep > NUM_STEPS then
            ApplyWizardChoices(_wizardChoices)
            if _win then _win:Hide() end
            ReloadUI()
        else
            UpdateWizardStep(wp, _wizardStep)
        end
    end)

    wp.disableBtn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        _wizardChoices[WIZARD_FEATURES[_wizardStep].nameKey] = false
        _wizardStep    = _wizardStep + 1
        _wizardMaxStep = math.max(_wizardMaxStep, _wizardStep)
        if _wizardStep > NUM_STEPS then
            ApplyWizardChoices(_wizardChoices)
            if _win then _win:Hide() end
            ReloadUI()
        else
            UpdateWizardStep(wp, _wizardStep)
        end
    end)

    -- ----------------------------------------------------------------
    -- 5. Back-knap
    -- ----------------------------------------------------------------
    wp.backBtn = BossHelper.Buttons.Create(wp, 110, 28, "BACK")
    wp.backBtn:SetPoint("BOTTOMLEFT", wp, "BOTTOMLEFT", 12, 9)
    wp.backBtn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        if _wizardStep <= 1 then
            ShowMainPage()
        else
            _wizardStep = _wizardStep - 1
            UpdateWizardStep(wp, _wizardStep)
        end
    end)

    _wizardPage = wp
    return wp
end

-- ---------------------------------------------------------------------------
-- Opret hovedvinduet (singleton)
-- ---------------------------------------------------------------------------

local function CreateWindow()
    if _win then return _win end

    local win = CreateFrame("Frame", "BossHelperQuickStart", UIParent, "BackdropTemplate")
    win:SetSize(WIN_W, WIN_H)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(200)
    BossHelper.UI.ApplyBackdrop(win, "EDITBOX", _C.BG_PANEL, _C.BORDER_AMBER)

    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop",  win.StopMovingOrSizing)

    -- Header-frame (indeholder banner, undertitel og separator)
    -- Skjules når wizard er aktiv for at give mere plads
    local header = CreateFrame("Frame", nil, win)
    header:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    header:SetHeight(246)
    _header = header

    -- Banner logo (1024x512 → vises 360x180)
    local banner = header:CreateTexture(nil, "ARTWORK")
    banner:SetSize(360, 180)
    banner:SetPoint("TOP", header, "TOP", 0, -10)
    banner:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Mythic-Mentor-longe-V2.png")

    -- Undertitel
    local sub = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", banner, "BOTTOM", 0, -8)
    sub:SetSize(WIN_W - 60, 0)
    sub:SetJustifyH("CENTER")
    sub:SetText(Translate("QS_SUBTITLE"))
    sub:SetTextColor(0.7, 0.7, 0.7)

    -- Header-separator
    local headerSep = header:CreateTexture(nil, "ARTWORK")
    headerSep:SetHeight(1)
    headerSep:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  10, 1)
    headerSep:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 1)
    headerSep:SetColorTexture(1, 0.5, 0, 0.2)

    -- ---------------------------------------------------------------------------
    -- Hovedside (kortene + footer)
    -- ---------------------------------------------------------------------------
    local mainPage = CreateFrame("Frame", nil, win)
    mainPage:SetPoint("TOPLEFT",     win, "TOPLEFT",     0, -246)
    mainPage:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0,    0)

    BuildCard(mainPage, -(CARD_W / 2 + 8), "QS_RECOMMENDED", "QS_REC_DESC", SIMG_START .. "standard.png", "recommended", function()
        ApplyProfile("recommended")
        if _win then _win:Hide() end
        ReloadUI()
    end)

    BuildCard(mainPage, (CARD_W / 2 + 8), "QS_ADVANCED", "QS_ADV_DESC", SIMG_START .. "advanced.png", "advanced", function()
        ShowWizardPage()
    end)

    local footer = mainPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOM", mainPage, "BOTTOM", 0, 17)
    footer:SetText(Translate("QS_FOOTER"))
    footer:SetTextColor(0.45, 0.45, 0.45)

    local skipBtn = BossHelper.Buttons.Create(mainPage, 100, 24, "QS_SKIP")
    skipBtn:SetPoint("BOTTOMRIGHT", mainPage, "BOTTOMRIGHT", -12, 10)
    skipBtn:SetScript("OnClick", function()
        BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.quickStartDone = true
        if _win then _win:Hide() end
    end)

    _mainPage = mainPage

    -- ---------------------------------------------------------------------------
    -- Wizard-side
    -- ---------------------------------------------------------------------------
    BuildWizardPage(win)

    _win = win
    return win
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Vis Quick Start-guiden hvis brugeren ikke allerede har valgt et setup.
function QS.ShowIfNeeded()
    if BossHelperDB and BossHelperDB.quickStartDone then return end
    QS.Show()
end

--- Vis Quick Start-guiden (kan kaldes fra Settings for at genåbne).
function QS.Show()
    local w = CreateWindow()
    ShowMainPage()
    w:Show()
end
