-- ConfirmDialog.lua
-- Genbrugelig custom popup med titel, besked, Ok- og Cancel-knap.
--
-- API:
--   ConfirmDialog.Show(options)
--
-- options = {
--   title   = string,           -- overskrift (valgfri)
--   message = string,           -- brødtekst
--   onOk    = function(),       -- kaldes når Ok klikkes
--   onCancel= function(),       -- kaldes når Cancel klikkes (valgfri)
-- }
-- =====================================================================

ConfirmDialog = ConfirmDialog or {}

local DIALOG_W = 360
local DIALOG_H = 180  -- udvides automatisk til teksten

-- =====================================================================
-- Byg frame én gang (lazy)
-- =====================================================================
local dlg

local function BuildDialog()
    if dlg then return end

    dlg = CreateFrame("Frame", "BossHelperConfirmDialog", UIParent, "BackdropTemplate")
    dlg:SetSize(DIALOG_W, DIALOG_H)
    dlg:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    dlg:SetFrameStrata("DIALOG")
    dlg:SetFrameLevel(500)
    dlg:EnableMouse(true)
    dlg:SetMovable(true)
    dlg:RegisterForDrag("LeftButton")
    dlg:SetScript("OnDragStart", dlg.StartMoving)
    dlg:SetScript("OnDragStop",  dlg.StopMovingOrSizing)

    dlg:SetBackdrop({
        bgFile   = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left=5, right=5, top=5, bottom=5 },
    })
    dlg:SetBackdropColor(0.06, 0.07, 0.12, 0.97)
    dlg:SetBackdropBorderColor(1, 0.6, 0.2, 0.9)

    -- Dimmer bag dialogen
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetAllPoints(UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(499)
    local overlayBg = overlay:CreateTexture(nil, "BACKGROUND")
    overlayBg:SetAllPoints()
    overlayBg:SetColorTexture(0, 0, 0, 0.55)
    dlg.overlay = overlay

    -- ---------------------------------------------------------------
    -- Øverst: farvet titelbar
    -- ---------------------------------------------------------------
    local titleBar = dlg:CreateTexture(nil, "ARTWORK")
    titleBar:SetColorTexture(1, 0.6, 0.2, 0.15)
    titleBar:SetPoint("TOPLEFT",  dlg, "TOPLEFT",  6, -6)
    titleBar:SetPoint("TOPRIGHT", dlg, "TOPRIGHT", -6, -6)
    titleBar:SetHeight(26)

    dlg.titleText = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dlg.titleText:SetPoint("TOPLEFT",  dlg, "TOPLEFT",  14, -12)
    dlg.titleText:SetPoint("TOPRIGHT", dlg, "TOPRIGHT", -14, -12)
    dlg.titleText:SetJustifyH("LEFT")
    dlg.titleText:SetTextColor(1, 0.82, 0.3)

    -- Separator linje under titel
    local sep = dlg:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 0.6, 0.2, 0.4)
    sep:SetPoint("TOPLEFT",  dlg, "TOPLEFT",  6, -34)
    sep:SetPoint("TOPRIGHT", dlg, "TOPRIGHT", -6, -34)
    sep:SetHeight(1)

    -- ---------------------------------------------------------------
    -- Besked-tekst
    -- ---------------------------------------------------------------
    dlg.msgText = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dlg.msgText:SetPoint("TOPLEFT",  dlg, "TOPLEFT",  14, -44)
    dlg.msgText:SetPoint("TOPRIGHT", dlg, "TOPRIGHT", -14, -44)
    dlg.msgText:SetJustifyH("LEFT")
    dlg.msgText:SetJustifyV("TOP")
    dlg.msgText:SetSpacing(4)
    dlg.msgText:SetTextColor(0.88, 0.88, 0.88)
    dlg.msgText:SetWordWrap(true)

    -- ---------------------------------------------------------------
    -- Knap-hjælper
    -- ---------------------------------------------------------------
    local function MakeButton(label, color)
        local btn = CreateFrame("Button", nil, dlg, "BackdropTemplate")
        btn:SetSize(110, 28)
        btn:SetBackdrop({
            bgFile   = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 10,
            insets   = { left=3, right=3, top=3, bottom=3 },
        })
        btn:SetBackdropColor(0.08, 0.09, 0.16, 1)
        btn:SetBackdropBorderColor(color[1]*0.7, color[2]*0.7, color[3]*0.7, 0.8)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(label)
        lbl:SetTextColor(color[1], color[2], color[3])

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(color[1]*0.20, color[2]*0.20, color[3]*0.20, 1)
            self:SetBackdropBorderColor(color[1], color[2], color[3], 1)
            lbl:SetTextColor(1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.09, 0.16, 1)
            self:SetBackdropBorderColor(color[1]*0.7, color[2]*0.7, color[3]*0.7, 0.8)
            lbl:SetTextColor(color[1], color[2], color[3])
        end)
        return btn
    end

    dlg.okBtn     = MakeButton("Ok",     { 0.3, 0.9, 0.4 })
    dlg.cancelBtn = MakeButton("Cancel", { 0.9, 0.35, 0.35 })

    -- Placer knapper (opdateres i Show())
    dlg.okBtn:SetPoint("BOTTOMRIGHT", dlg, "BOTTOM",    -6, 12)
    dlg.cancelBtn:SetPoint("BOTTOMLEFT", dlg, "BOTTOM",  6, 12)

    dlg:Hide()
    overlay:Hide()
end

-- =====================================================================
-- ConfirmDialog.Show
-- =====================================================================
function ConfirmDialog.Show(opts)
    BuildDialog()
    opts = opts or {}

    -- Titel
    local titleStr = opts.title or ""
    dlg.titleText:SetText(titleStr)

    -- Besked
    local msgStr = opts.message or ""
    dlg.msgText:SetText(msgStr)

    -- Tilpas dialog-højde til teksten
    dlg.msgText:SetWidth(DIALOG_W - 28)
    local textH = dlg.msgText:GetStringHeight()
    local totalH = math.max(DIALOG_H, 44 + textH + 16 + 40 + 12)
    dlg:SetHeight(totalH)

    -- Callbacks
    local function closeAll()
        dlg:Hide()
        dlg.overlay:Hide()
    end

    dlg.okBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then
            BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        end
        closeAll()
        if opts.onOk then opts.onOk() end
    end)

    dlg.cancelBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then
            BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON)
        end
        closeAll()
        if opts.onCancel then opts.onCancel() end
    end)

    dlg.overlay:Show()
    dlg:Show()
    dlg:Raise()
end

-- =====================================================================
-- ConfirmDialog.Hide  (kan bruges udefra om nødvendigt)
-- =====================================================================
function ConfirmDialog.Hide()
    if dlg then
        dlg:Hide()
        if dlg.overlay then dlg.overlay:Hide() end
    end
end
