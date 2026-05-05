-- Affixes.lua
-- Extracted affix display logic from BossUI.lua for cleanliness.
-- Provides a single global function: BossHelper_Affixes_Show(rightPanel)

local AFFIX_WIDTH = 540
local AFFIX_MIN_HEIGHT = 70
local AFFIX_SPACING = 10
local AFFIX_SCROLL_BOTTOM_OFFSET = 10 -- reduced from previous 60 to let the scroll frame reach further down

local function EnsureAffixScroll(rightPanel)
    if rightPanel.affixScroll then return end
    local scroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -50)
    scroll:SetPoint("RIGHT", rightPanel, "RIGHT", -30, 0)
    scroll:SetPoint("BOTTOM", rightPanel, "BOTTOM", 0, AFFIX_SCROLL_BOTTOM_OFFSET)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1,1)
    scroll:SetScrollChild(content)
    rightPanel.affixScroll = scroll
    rightPanel.affixContent = content
    rightPanel.affixFrames = {}
end

local function ClearAffixFrames(rightPanel)
    for _, f in ipairs(rightPanel.affixFrames or {}) do
        pcall(function() f:Hide(); f:SetParent(nil) end)
    end
    rightPanel.affixFrames = {}
end

local function BuildAffixUI(rightPanel)
    if not rightPanel or not rightPanel.affixContent then return end
    ClearAffixFrames(rightPanel)

    local affixes = C_MythicPlus and C_MythicPlus.GetCurrentAffixes and C_MythicPlus.GetCurrentAffixes() or nil
    if not affixes or #affixes == 0 then
        local msg = rightPanel.affixContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("TOPLEFT", rightPanel.affixContent, "TOPLEFT", 0, 0)
        msg:SetWidth(AFFIX_WIDTH)
        msg:SetJustifyH("LEFT")
        msg:SetText((Translate and Translate("AFFIXES_LOADING")) or "Affixes not available yet. Try again soon.")
        table.insert(rightPanel.affixFrames, msg)
        rightPanel.affixContent:SetHeight(30)
        return
    end

    local y = 0
    for _, a in ipairs(affixes) do
        if a and a.id then
            local name, desc, fileID = C_ChallengeMode.GetAffixInfo(a.id)
            local holder = CreateFrame("Frame", nil, rightPanel.affixContent, "BackdropTemplate")
            holder:SetPoint("TOPLEFT", rightPanel.affixContent, "TOPLEFT", 0, -y)
            holder:SetSize(AFFIX_WIDTH, AFFIX_MIN_HEIGHT)
            holder:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 12,
                insets = { left=4, right=4, top=4, bottom=4 }
            })
            holder:SetBackdropColor(0.06,0.07,0.11,0.95)
            holder:SetBackdropBorderColor(1,0.5,0,0.8)

            local icon = holder:CreateTexture(nil, "ARTWORK")
            icon:SetSize(40,40)
            icon:SetPoint("TOPLEFT", holder, "TOPLEFT", 8, -8)
            if fileID then icon:SetTexture(fileID) end

            local titleFS = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            titleFS:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
            titleFS:SetWidth(AFFIX_WIDTH-60)
            titleFS:SetJustifyH("LEFT")
            titleFS:SetText(name or ("Affix "..tostring(a.id)))
            titleFS:SetTextColor(1,0.8,0.2)

            local descFS = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            descFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -4)
            descFS:SetWidth(AFFIX_WIDTH-60)
            descFS:SetJustifyH("LEFT")
            descFS:SetJustifyV("TOP")
            descFS:SetText(desc or "")

            local neededH = 16 + (descFS:GetStringHeight() or 0) + 20
            if neededH < AFFIX_MIN_HEIGHT then neededH = AFFIX_MIN_HEIGHT end
            holder:SetHeight(neededH)

            -- Simple tooltip for full description
            holder:EnableMouse(true)
            holder:SetScript("OnEnter", function()
                GameTooltip:SetOwner(holder, "ANCHOR_RIGHT")
                GameTooltip:AddLine(name or ("Affix "..tostring(a.id)), 1,0.82,0)
                if desc and desc ~= "" then
                    GameTooltip:AddLine(desc, 0.9,0.9,0.9, true)
                end
                GameTooltip:Show()
            end)
            holder:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            table.insert(rightPanel.affixFrames, holder)
            y = y + neededH + AFFIX_SPACING
        end
    end
    rightPanel.affixContent:SetHeight(math.max(1, y))
end

function BossHelper_Affixes_Show(rightPanel)
    if not rightPanel then return end
    EnsureAffixScroll(rightPanel)
    rightPanel.affixScroll:Show()

    -- event frame (created once)
    if not rightPanel.affixEventFrame then
        local ev = CreateFrame("Frame")
        -- Some events may not exist in all client versions / builds; guard with pcall
        local registeredAny = false
        local function SafeReg(eventName)
            local ok, err = pcall(ev.RegisterEvent, ev, eventName)
            if ok then registeredAny = true else
                -- optional debug
                -- print("|cffFF4500[MythicMentor]|r Could not register event "..tostring(eventName)..": "..tostring(err))
            end
        end
        -- Use widely available events
        SafeReg("CHALLENGE_MODE_MAPS_UPDATE")      -- fires when M+ data updates
        SafeReg("PLAYER_ENTERING_WORLD")           -- early retry
        SafeReg("ZONE_CHANGED_NEW_AREA")           -- zone change can refresh API readiness

        ev:SetScript("OnEvent", function(_, evt)
            if rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
                BuildAffixUI(rightPanel)
            end
        end)
        rightPanel.affixEventFrame = ev

        if not registeredAny then
            print("|cffFF4500[MythicMentor]|r No affix events registered; using timer fallback only.")
        end
    end

    -- Timer fallback: rebuild a few times until data appears (then stop)
    if not rightPanel.affixRetryTicker then
        local attempts = 0
        rightPanel.affixRetryTicker = C_Timer.NewTicker(5, function(t)
            attempts = attempts + 1
            if rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
                local aff = C_MythicPlus and C_MythicPlus.GetCurrentAffixes and C_MythicPlus.GetCurrentAffixes() or nil
                if aff and #aff > 0 then
                    BuildAffixUI(rightPanel)
                    t:Cancel(); rightPanel.affixRetryTicker = nil
                    return
                else
                    BuildAffixUI(rightPanel) -- keeps loading message fresh
                end
            end
            if attempts >= 6 then -- ~30 seconds
                if rightPanel.affixRetryTicker then t:Cancel(); rightPanel.affixRetryTicker = nil end
            end
        end)
    end

    BuildAffixUI(rightPanel)
    -- Expose manual rebuild for debugging
    rightPanel.RebuildAffixes = function()
        BuildAffixUI(rightPanel)
    end
end
