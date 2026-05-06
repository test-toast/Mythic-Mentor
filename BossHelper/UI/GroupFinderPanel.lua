-- GroupFinderPanel.lua
-- Viser KeystoneWidget i et flytbart panel forankret til PVEFrame (Group Finder).
-- Panelet er synligt på ALLE faner i Group Finder,
-- Positionen gemmes i BossHelperDB.groupFinderPanelPos og gendannes ved næste åbning.

local PANEL_PADDING = 8
local PANEL_MIN_W   = 60   -- minimum bredde (udvides automatisk)
local PANEL_MIN_H   = 60   -- minimum højde
local DEFAULT_X     = 4    -- standard offset fra PVEFrame TOPRIGHT
local DEFAULT_Y     = 0

-- ============================================================
-- Intern state
-- ============================================================
local panel          = nil
local keystoneWidget = nil
local initialized    = false

-- ============================================================
-- Position gem / gendan
-- ============================================================
local function SavePosition()
    if not panel or not PVEFrame then return end

    local panelScale  = panel:GetEffectiveScale()
    local parentScale = PVEFrame:GetEffectiveScale()

    local absLeft = panel:GetLeft()  * panelScale
    local absTop  = panel:GetTop()   * panelScale
    local parLeft = PVEFrame:GetLeft()  * parentScale
    local parTop  = PVEFrame:GetTop()   * parentScale

    BossHelperDB = BossHelperDB or {}
    BossHelperDB.groupFinderPanelPos = {
        x = (absLeft - parLeft) / parentScale,
        y = (absTop  - parTop)  / parentScale,
    }
end

local function LoadPosition()
    if not panel or not PVEFrame then return end

    local pos = BossHelperDB and BossHelperDB.groupFinderPanelPos
    if not pos then
        -- Ingen gemt position: placer til højre for PVEFrame
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", DEFAULT_X, DEFAULT_Y)
        return
    end

    local panelScale  = panel:GetEffectiveScale()
    local parentScale = PVEFrame:GetEffectiveScale()
    local ax = pos.x * parentScale / panelScale
    local ay = pos.y * parentScale / panelScale

    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", PVEFrame, "TOPLEFT", ax, ay)
end


-- ============================================================
-- Juster panelstørrelse efter KeystoneWidget-indhold
-- ============================================================
local function AdjustPanelSize()
    if not panel or not keystoneWidget then return end
    local fw = keystoneWidget.frame:GetWidth()  or 0
    local fh = keystoneWidget.frame:GetHeight() or 0
    local headerH = 22
    local newW = math.max(PANEL_MIN_W, fw + PANEL_PADDING * 2)
    local newH = math.max(PANEL_MIN_H, fh + headerH + PANEL_PADDING)
    panel:SetWidth(newW)
    panel:SetHeight(newH)
end

-- ============================================================
-- Opret panel + widget én gang
-- ============================================================
local function InitPanel()
    if initialized then return end

    -- Sæt ikke initialized=true før PVEFrame er klar, så vi kan prøve igen
    if not PVEFrame then return end
    initialized = true

    panel = CreateFrame("Frame", "BossHelperGroupFinderPanel", PVEFrame, "BackdropTemplate")
    panel:SetHeight(PANEL_MIN_H)
    panel:SetWidth(PANEL_MIN_W)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(PVEFrame:GetFrameLevel() + 2)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetClampedToScreen(true)
    panel:Hide()

    -- Standard-position (øverst til højre for PVEFrame) – overskrives af LoadPosition
    panel:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", DEFAULT_X, DEFAULT_Y)

    BossHelper.UI.ApplyBackdrop(panel, "EDITBOX", BossHelper.UI.C.BG_PANEL_DARK, BossHelper.UI.C.BORDER_AMBER)

    -- Overskrift / drag-håndtag
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", panel, "TOP", 0, -5)
    title:SetTextColor(BossHelper.UI.C.TEXT_GOLD[1], BossHelper.UI.C.TEXT_GOLD[2], BossHelper.UI.C.TEXT_GOLD[3])
    title:SetText("Keys")
    panel.title = title

    -- Drag
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
        -- Genanbring som et punkt relativt til PVEFrame, så panelet følger når PVEFrame flyttes
        LoadPosition()
    end)

    -- KeystoneWidget inde i panelet (list-layout: ikon venstre, tekst højre, stablet lodret)
    keystoneWidget = BossHelper.UI.CreateKeystoneWidget(panel, "list")
    keystoneWidget.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, -22)

    -- Justér panel-bredde når keystones ændres
    local adjustTimer
    hooksecurefunc(BossHelper, "RefreshAllKeystoneWidgets", function()
        if not panel or not panel:IsShown() then return end
        if not adjustTimer then
            adjustTimer = C_Timer.NewTimer(0.05, function()
                adjustTimer = nil
                if panel and panel:IsShown() then
                    AdjustPanelSize()
                end
            end)
        end
    end)
end

-- ============================================================
-- Anvend udseende-indstillinger på panelet
-- ============================================================
local function ApplyPanelSettings()
    if not panel then return end

    local bg     = BossHelper.UI.C.BG_PANEL_DARK
    local stored = BossHelperDB and BossHelperDB.gfPanelTransparency
    local bgAlpha = tonumber(stored) or bg[4]
    bgAlpha = math.max(0, math.min(1, bgAlpha))
    panel:SetBackdropColor(bg[1], bg[2], bg[3], bgAlpha)

    local border      = BossHelper.UI.C.BORDER_AMBER
    local noBorder    = BossHelperDB and BossHelperDB.gfNoBorder
    local borderAlpha = noBorder and 0 or border[4]
    panel:SetBackdropBorderColor(border[1], border[2], border[3], borderAlpha)

    local hideTitle = BossHelperDB and BossHelperDB.gfHideTitle
    if panel.title then
        if hideTitle then
            panel.title:Hide()
        else
            panel.title:Show()
        end
    end

    -- Juster keystone-widget anker afhængigt af om titlen er synlig
    if keystoneWidget then
        local topOffset = (hideTitle) and -8 or -22
        keystoneWidget.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, topOffset)
        AdjustPanelSize()
    end
end

-- ============================================================
-- Vis / skjul logik
-- ============================================================
local function HidePanel()
    if panel then panel:Hide() end
end

local function ShowPanel()
    -- Bail out when Key Tracker is disabled entirely
    if BossHelperDB and BossHelperDB.keyTrackerEnabled == false then
        HidePanel()
        return
    end
    if BossHelperDB and BossHelperDB.showKeysInGroupFinder == false then
        HidePanel()
        return
    end
    InitPanel()
    if not panel then return end
    keystoneWidget:Refresh()
    -- Skjul panelet helt hvis ingen har keystones
    if not keystoneWidget.frame:IsShown() then
        panel:Hide()
        return
    end
    AdjustPanelSize()
    -- genindlæs gemt position efter størrelse er opdateret
    LoadPosition()
    ApplyPanelSettings()
    panel:Show()
end

-- ============================================================
-- Offentlig API – bruges af BossSettings til live-opdatering
-- ============================================================
BossHelper.GroupFinderPanel = BossHelper.GroupFinderPanel or {}
function BossHelper.GroupFinderPanel.UpdateVisibility()
    if BossHelperDB and BossHelperDB.keyTrackerEnabled == false then
        HidePanel()
        return
    end
    if PVEFrame and PVEFrame:IsShown() then
        if BossHelperDB and BossHelperDB.showKeysInGroupFinder == false then
            HidePanel()
        else
            ShowPanel()
        end
    end
end

function BossHelper.GroupFinderPanel.ApplySettings()
    ApplyPanelSettings()
end

-- ============================================================
-- Hook PVEFrame (Group Finder – alle faner)
-- ============================================================
local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent", function(self, event)
    if not PVEFrame then return end

    PVEFrame:HookScript("OnShow", ShowPanel)
    PVEFrame:HookScript("OnHide", HidePanel)
    -- Når PVEFrame ændrer størrelse/position, re-placer panelet efter gemt offset
    PVEFrame:HookScript("OnSizeChanged", function()
        if panel and panel:IsShown() then LoadPosition() end
    end)

    if PVEFrame:IsShown() then ShowPanel() end

    self:UnregisterAllEvents()
end)
