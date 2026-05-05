-- Affixes.lua
-- Five-column keystone affix view.
-- Tactics are defined in AffixData.lua (Tactics table, keyed by affix ID).
-- Hover over an affix row to see the tactic in a tooltip.
-- Public entry point: BossHelper_Affixes_Show(rightPanel)

------------------------------------------------------------------------
-- Layout constants
------------------------------------------------------------------------
local TIERS       = BossHelper.AffixData.Tiers
local NUM_TIERS   = #TIERS
local C           = BossHelper.UI.C

local OUTER_PAD   = 8    -- horizontal padding of the whole column area
local COL_GAP     = 5    -- gap between adjacent columns
local HEADER_H    = 26   -- tier label row height
local INNER_PAD   = 6    -- padding inside column content

-- Module-level list of column frames so they can be rebuilt cleanly.
local _colFrames = {}

------------------------------------------------------------------------
-- Local data helpers (logic moved here from AffixData.lua)
------------------------------------------------------------------------

-- Return the tactic text for an affix ID, or nil if none defined.
local function GetTactic(affixId)
    local entry = BossHelper.AffixData.Affixes[tonumber(affixId)]
    return entry and entry.tactic
end

-- Return the affixes from affixList that belong in the given tier.
--
-- Tyrannical (9) / Fortified (10) have no fixed range in AffixData.
-- The API returns both each week; whichever comes FIRST is the weekly
-- rotating one (active from +7-9). The second is always-on from +10.
-- If the API supplies a valid startLevel we use that directly instead.
local function GetAffixesForTier(tier, affixList)
    -- Find which of Tyrannical/Fortified is first in the API list this week.
    local firstFT = nil
    for _, a in ipairs(affixList or {}) do
        local id = tonumber(a.id)
        if (id == 9 or id == 10) and not firstFT then
            firstFT = id
        end
    end

    local result = {}
    for _, a in ipairs(affixList or {}) do
        local id    = tonumber(a.id)
        local entry = id and BossHelper.AffixData.Affixes[id]
        local aMin, aMax

        if entry and entry.range then
            aMin, aMax = entry.range[1], entry.range[2]
        elseif id == 9 or id == 10 then
            if a.startLevel and a.startLevel > 0 then
                aMin, aMax = a.startLevel, 999
            elseif id == firstFT then
                aMin, aMax = 7, 999   -- weekly rotating one
            else
                aMin, aMax = 10, 999  -- always-on from +10
            end
        elseif a.startLevel and a.startLevel > 0 then
            aMin, aMax = a.startLevel, 999
        end

        if aMin and aMax and aMin <= tier.maxLevel and aMax >= tier.minLevel then
            table.insert(result, a)
        end
    end
    return result
end

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------
local function DestroyColumns()
    for _, f in ipairs(_colFrames) do
        pcall(function() f:Hide(); f:SetParent(nil) end)
    end
    _colFrames = {}
end

------------------------------------------------------------------------
-- BuildColumn  – creates one tier column parented to 'container'
--
-- container  : parent frame (rightPanel.affixScroll sentinel)
-- tier       : entry from BossHelper.AffixData.Tiers
-- tierIdx    : 1-5 (column index, left to right)
-- colX       : left offset from container TOPLEFT
-- colW       : column width in pixels
-- panelH     : height of the right panel (for column sizing)
-- tierAffixes: list of {id, startLevel} from the API for this tier
------------------------------------------------------------------------
local function BuildColumn(container, tier, tierIdx, colX, colW, panelH, tierAffixes)
    local colH   = panelH - 50
    local iconW  = colW - INNER_PAD * 2 - 4  -- icon fills the column width

    -- Outer column frame -------------------------------------------------
    local col = CreateFrame("Frame", nil, container, "BackdropTemplate")
    col:SetPoint("TOPLEFT", container, "TOPLEFT", colX, -40)
    col:SetSize(colW, colH)
    col:SetBackdrop(BossHelper.UI.Backdrop.FRAME)
    col:SetBackdropColor(
        tier.colorBg[1], tier.colorBg[2], tier.colorBg[3], tier.colorBg[4])
    col:SetBackdropBorderColor(
        tier.colorBorder[1], tier.colorBorder[2], tier.colorBorder[3], tier.colorBorder[4])

    -- Tier header label --------------------------------------------------
    local hdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOP", col, "TOP", 0, -10)
    hdr:SetWidth(colW - 8)
    hdr:SetJustifyH("CENTER")
    hdr:SetText(tier.label)
    hdr:SetTextColor(tier.colorBorder[1], tier.colorBorder[2], tier.colorBorder[3])

    -- Separator line under header ----------------------------------------
    local sep = col:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", col, "TOPLEFT", 4, -(HEADER_H - 2))
    sep:SetSize(colW - 8, 1)
    sep:SetColorTexture(
        tier.colorBorder[1], tier.colorBorder[2], tier.colorBorder[3], 0.45)

    -- Plain content frame (no scrollbar) ---------------------------------
    local content = CreateFrame("Frame", nil, col)
    content:SetPoint("TOPLEFT",     col, "TOPLEFT",     2, -HEADER_H)
    content:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -2, 2)

    -- Populate content ---------------------------------------------------
    local yOff = INNER_PAD

    if #tierAffixes == 0 then
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOP", content, "TOP", 0, -yOff)
        lbl:SetWidth(colW - INNER_PAD * 2)
        lbl:SetJustifyH("CENTER")
        lbl:SetText("\u2013")
        lbl:SetTextColor(0.45, 0.45, 0.45)
    else
        for _, affix in ipairs(tierAffixes) do
            local affixId            = affix.id
            local name, desc, fileID = C_ChallengeMode.GetAffixInfo(affixId)

            -- Affix kort (keystone-stil): billede i boks + navn nedenunder --
            local imgSz  = math.min(iconW - 6, 68)   -- max 68 px bred
            local cardW  = imgSz + 8                  -- 4 px padding i hver side
            local cardH  = imgSz + 24                 -- billedet + 2 px gap + 18 px tekst

            local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
            card:SetSize(cardW, cardH)
            card:SetPoint("TOP", content, "TOP", 0, -yOff)
            BossHelper.UI.ApplyBackdrop(card, "ITEM", C.BG_DARK, C.BORDER_GREY)

            -- Hover-hint: vis et lille '?' i hjørnet når der er en custom taktik
            local hasTactic = GetTactic(affixId)
            if hasTactic and hasTactic ~= "" then
                local hint = card:CreateFontString(nil, "OVERLAY")
                -- make the hint visually larger (approx. double)
                local fp, fs, ff = GameFontNormalSmall:GetFont()
                fs = (fs or 12) * 2
                hint:SetFont(fp, fs, ff)
                hint:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -6)
                hint:SetText("?")
                hint:SetTextColor(1, 0.85, 0)
                hint:SetShadowColor(0, 0, 0, 1)
                hint:SetShadowOffset(1, -1)
                hint:SetJustifyH("CENTER")
            end

            -- Billede øverst i kortet ------------------------------------
            local icon = card:CreateTexture(nil, "ARTWORK")
            icon:SetSize(imgSz, imgSz)
            icon:SetPoint("TOP", card, "TOP", 0, -4)
            if fileID then icon:SetTexture(fileID) end
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- crop built-in icon border

            -- Skygge-gradient i bunden af billedet
            local shadow = card:CreateTexture(nil, "OVERLAY")
            shadow:SetSize(imgSz, 3)
            shadow:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)
            shadow:SetColorTexture(0.06, 0.07, 0.11, 0.75)

            -- Affix navn under billedet ----------------------------------
            local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOP", icon, "BOTTOM", 0, 0)
            lbl:SetSize(cardW - 4, 18)
            lbl:SetJustifyH("CENTER")
            lbl:SetText(name or ("Affix " .. tostring(affixId)))
            lbl:SetTextColor(0.65, 0.65, 0.85)
            lbl:SetWordWrap(false)

            -- Hit-frame for tooltip over hele kortet ---------------------
            local hit = CreateFrame("Frame", nil, content)
            hit:SetSize(cardW, cardH)
            hit:SetPoint("TOP", content, "TOP", 0, -yOff)
            hit:EnableMouse(true)
            hit:SetScript("OnEnter", function()
                card:SetBackdropColor(0.15, 0.15, 0.25, 1)
                card:SetBackdropBorderColor(1, 0.6, 0.2, 1)
                GameTooltip:SetOwner(hit, "ANCHOR_RIGHT")
                GameTooltip:AddLine(name or ("Affix " .. tostring(affixId)), 1, 0.5, 0)
                local tactic = GetTactic(affixId)
                if tactic and tactic ~= "" then
                    for line in (tactic .. "\n"):gmatch("([^\n]*)\n") do
                        if line ~= "" then
                            GameTooltip:AddLine(line, C.TEXT_GOLD[1], C.TEXT_GOLD[2], C.TEXT_GOLD[3], true)
                        end
                    end
                end
                GameTooltip:Show()
            end)
            hit:SetScript("OnLeave", function()
                card:SetBackdropColor(C.BG_DARK[1], C.BG_DARK[2], C.BG_DARK[3], C.BG_DARK[4])
                card:SetBackdropBorderColor(C.BORDER_GREY[1], C.BORDER_GREY[2], C.BORDER_GREY[3], C.BORDER_GREY[4])
                GameTooltip:Hide()
            end)

            yOff = yOff + cardH + INNER_PAD
        end
    end

    return col
end

------------------------------------------------------------------------
-- Rebuild all 5 tier columns inside the container frame.
-- rightPanel is passed explicitly so sizing is always valid
-- (container:GetWidth() can return 0 before the first layout pass).
------------------------------------------------------------------------
local function BuildAllColumns(container, rightPanel, animate)
    DestroyColumns()

    -- Use rightPanel dimensions – it has SetSize(580,400) so always valid.
    local panelW = (rightPanel and rightPanel:GetWidth()  > 0 and rightPanel:GetWidth())
                   or container:GetWidth() or 580
    local panelH = (rightPanel and rightPanel:GetHeight() > 0 and rightPanel:GetHeight())
                   or container:GetHeight() or 400

    local affixes = (C_MythicPlus
        and C_MythicPlus.GetCurrentAffixes
        and C_MythicPlus.GetCurrentAffixes()) or {}

    local availW = panelW - OUTER_PAD * 2
    local colW   = math.max(60, math.floor((availW - (NUM_TIERS - 1) * COL_GAP) / NUM_TIERS))

    for i, tier in ipairs(TIERS) do
        local tierAffixes = GetAffixesForTier(tier, affixes)
        local colX = OUTER_PAD + (i - 1) * (colW + COL_GAP)
        local col  = BuildColumn(container, tier, i, colX, colW, panelH, tierAffixes)
        table.insert(_colFrames, col)
    end

    if animate then
        BossHelper.Anim.PlayAffixColumnsIn(_colFrames)
    end
end

------------------------------------------------------------------------
-- Public entry point – called from BossUI.lua
------------------------------------------------------------------------
function BossHelper_Affixes_Show(rightPanel)
    if not rightPanel then return end

    -- Create a sentinel container frame the first time.
    -- BossUI.lua calls :Show() / :Hide() / :IsShown() on rightPanel.affixScroll,
    -- so we keep that key pointing to this container.
    if not rightPanel.affixScroll then
        local container = CreateFrame("Frame", nil, rightPanel)
        container:SetAllPoints(rightPanel)
        container:Hide()
        -- Store back-reference so BuildAllColumns can read rightPanel dimensions.
        container._rightPanel = rightPanel
        rightPanel.affixScroll = container
    end
    rightPanel.affixScroll:Show()

    -- Register game events once per rightPanel lifetime -----------------
    if not rightPanel.affixEventFrame then
        local ev = CreateFrame("Frame")
        local function SafeReg(name)
            pcall(ev.RegisterEvent, ev, name)
        end
        SafeReg("CHALLENGE_MODE_MAPS_UPDATE")
        SafeReg("PLAYER_ENTERING_WORLD")
        SafeReg("ZONE_CHANGED_NEW_AREA")
        ev:SetScript("OnEvent", function()
            if rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
                BuildAllColumns(rightPanel.affixScroll, rightPanel, false)
            end
        end)
        rightPanel.affixEventFrame = ev
    end

    -- Timer fallback: keep retrying until affix data becomes available --
    if not rightPanel.affixRetryTicker then
        local attempts = 0
        rightPanel.affixRetryTicker = C_Timer.NewTicker(5, function(t)
            attempts = attempts + 1
            local aff = C_MythicPlus
                and C_MythicPlus.GetCurrentAffixes
                and C_MythicPlus.GetCurrentAffixes()
            if aff and #aff > 0 then
                if rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
                    BuildAllColumns(rightPanel.affixScroll, rightPanel, false)
                end
                t:Cancel()
                rightPanel.affixRetryTicker = nil
                return
            end
            if attempts >= 6 then
                t:Cancel()
                rightPanel.affixRetryTicker = nil
            end
        end)
    end

    -- Defer by one tick so WoW has processed the rightPanel layout.
    C_Timer.After(0, function()
        if rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
            BuildAllColumns(rightPanel.affixScroll, rightPanel, true)
        end
    end)

    -- Expose manual rebuild (useful for /reload debugging)
    rightPanel.RebuildAffixes = function()
        BuildAllColumns(rightPanel.affixScroll, rightPanel, false)
    end
end
