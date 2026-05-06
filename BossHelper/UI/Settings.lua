-- BossSettings.lua
-- API: BossSettings.ShowSettings(ctx)
-- ctx = {
--   frame = frame,
--   leftPanel = leftPanel,
--   rightPanel = rightPanel,
--   backButton = backButton,
--   CreateCustomButton = CreateCustomButton,    -- required
--   BossHelper = BossHelper,                    -- optional, for lyd/calls
--   BossHelperDB = BossHelperDB                 -- optional, til checkbox init
-- }

if not BossSettings then BossSettings = {} end

local deps = {} -- internal deps (populated fra Init eller ShowSettings args)

local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end

function BossSettings.Init(d)
    if not d then return end
    for k, v in pairs(d) do deps[k] = v end
end

-- ---------------------------------------------------------------------------
-- Shared UI helpers
-- ---------------------------------------------------------------------------
local _UI = BossHelper.UI
local _C  = BossHelper.UI.C

local function _hide(o)          _UI.hide(o)         end
local function _setParent(o, p)  _UI.setParent(o, p) end
local function _setText(o, txt)  _UI.setText(o, txt) end

local function _safeSound(sid)
    pcall(function()
        if deps.BossHelper and deps.BossHelper.SafePlaySound then
            deps.BossHelper:SafePlaySound(sid)
        end
    end)
end

local function _showInfo(title, desc, image)
    if deps.ShowSettingsInfo then deps.ShowSettingsInfo(title, desc, image) end
end

local function _hideInfo()
    if deps.HideSettingsInfo then deps.HideSettingsInfo() end
end

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------
local function CleanupSettingsWidgets(rPanel)
    if not rPanel or not rPanel.settingsWidgets then return end
    for _, w in ipairs(rPanel.settingsWidgets) do
        _UI.destroyWidget(w)
    end
    rPanel.settingsWidgets = nil
end

-- Public helper: clean up the current category and rebuild it in-place.
-- Used by widgets (e.g. Add/Remove word buttons) that need a live refresh.
function BossSettings.RebuildCategory(rPanel, category, ctx)
    CleanupSettingsWidgets(rPanel)
    if rPanel._settingsContent then rPanel._settingsContent:SetHeight(1) end
    BossSettings.BuildSettingsCategoryUI(rPanel, category, ctx)
end

-- Converts a desc that is either a string or table to a plain string.
local function _toDescStr(desc)
    if type(desc) == "table" then return desc[#desc] or "" end
    return tostring(desc or "")
end

-- ---------------------------------------------------------------------------
-- Info-hover: attaches OnEnter/OnLeave to show the settings info panel.
-- ---------------------------------------------------------------------------
local function AttachInfoHover(obj, title, desc, image)
    if not obj then return end
    if obj.EnableMouse then obj:EnableMouse(true) end
    local descStr = _toDescStr(desc)
    obj:HookScript("OnEnter", function() _showInfo(title, descStr, image) end)
    obj:HookScript("OnLeave", function() _hideInfo() end)
end



-- ===========================================================================
-- BuildSettingsCategoryUI  (the main entry point for each category)
-- ===========================================================================
function BossSettings.BuildSettingsCategoryUI(rPanel, category, ctx)
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
    local BossHelperDB       = ctx.BossHelperDB       or deps.BossHelperDB or {}

    rPanel.settingsWidgets = rPanel.settingsWidgets or {}

    -- -----------------------------------------------------------------------
    -- Image path constants
    -- -----------------------------------------------------------------------
    local SIMG = "Interface\\AddOns\\BossHelper\\Media\\settings-img\\"
    local IMG = {
        LANG          = SIMG .. "general\\select-language.blp",
        MYTHIC        = SIMG .. "general\\mythic-tap-teleport.blp",
        NOTES         = SIMG .. "general\\auto-boss-note.blp",
        CLOSE_ON_POST = SIMG .. "general\\close-on-post.blp",
        MINI          = SIMG .. "mini.window\\mini-window.blp",
        KEY_CARD      = SIMG .. "key-tracker\\key-card.blp",
        KEY_LIST      = SIMG .. "key-tracker\\key-list.blp",
        KEY_TELEPORT  = SIMG .. "key-tracker\\teleport\\key-card-teleport.blp",
        DCW           = SIMG .. "dungeon-check\\check-w.blp",
    }

    -- -----------------------------------------------------------------------
    -- Widget registry: tracks everything created so it can be cleaned up.
    -- -----------------------------------------------------------------------
    local function W(w)
        table.insert(rPanel.settingsWidgets, w)
        return w
    end

    local _BD = _UI.ApplyBackdrop

    -- -----------------------------------------------------------------------
    -- Scroll frame â€“ created once, reused across category switches.
    -- -----------------------------------------------------------------------
    if not rPanel.settingsScroll then
        local scroll = CreateFrame("ScrollFrame", nil, rPanel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",     rPanel, "TOPLEFT",     10, -40)
        scroll:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -30,  4)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
        end)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(540)
        content:SetHeight(1)
        scroll:SetScrollChild(content)
        rPanel.settingsScroll   = scroll
        rPanel._settingsContent = content
    end
    rPanel.settingsScroll:Show()
    local settingsContent = rPanel._settingsContent
    settingsContent:SetHeight(1)

    -- =========================================================
    -- Card layout constants  (matches EditTactics box style)
    -- =========================================================
    local CARD_W     = 540   -- card width  (content 540 âˆ’ 8px each side)
    local CARD_X     = 2     -- card left offset inside settingsContent
    local CARD_PH    = 10    -- horizontal padding inside card
    local CARD_PV    = 10    -- vertical padding (top & bottom)
    local CARD_GAP   = 10   -- gap between stacked cards
    local TITLE_H    = 13   -- GameFontNormalSmall approx height
    local RULE_ABOVE = 4
    local RULE_BELOW = 8

    local GOLD = { 0.98, 0.82, 0.55 }

    -- Cursor tracking for card stacking
    local cardY       = 0
    local pendingRowH = 0
    local pendingRowY = 0  -- kept for symmetry

    -- -----------------------------------------------------------------------
    -- MakeCard: creates a styled card frame with a title + divider rule.
    -- col = "full" (default) | "left" | "right"
    -- Returns: card, CY, Adv, Fin
    -- -----------------------------------------------------------------------
    local function MakeCard(title, col)
        col = col or "full"
        local HALF_W = math.floor((CARD_W - CARD_GAP) / 2)
        local thisW  = (col == "full") and CARD_W or HALF_W
        local thisX  = (col == "right") and (CARD_X + HALF_W + CARD_GAP) or CARD_X

        local card = W(CreateFrame("Frame", nil, settingsContent, "BackdropTemplate"))
        card:SetWidth(thisW)
        card:SetHeight(50)
        _BD(card, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)
        card:SetPoint("TOPLEFT", settingsContent, "TOPLEFT", thisX, cardY)

        local tfs = W(card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        tfs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, -CARD_PV)
        tfs:SetText(title:upper())
        tfs:SetTextColor(1, 0.5, 0)
        tfs:SetJustifyH("LEFT")

        local rule = W(card:CreateTexture(nil, "ARTWORK"))
        rule:SetColorTexture(1, 0.5, 0, 0.25)
        rule:SetHeight(1)
        rule:SetWidth(thisW - CARD_PH * 2)
        rule:SetPoint("TOPLEFT", tfs, "BOTTOMLEFT", 0, -RULE_ABOVE)

        local cy = -(CARD_PV + TITLE_H + RULE_ABOVE + 1 + RULE_BELOW)  -- â‰ˆ âˆ’36
        local function CY() return cy end
        local function Adv(n) cy = cy - n end
        local function Fin()
            local h = math.abs(cy) + CARD_PV
            card:SetHeight(h)
            if col == "left" then
                pendingRowH = h
                pendingRowY = cardY
            elseif col == "right" then
                cardY = cardY - math.max(pendingRowH, h) - CARD_GAP
                pendingRowH = 0
            else
                cardY = cardY - h - CARD_GAP
            end
        end
        return card, CY, Adv, Fin
    end

    -- -----------------------------------------------------------------------
    -- CardCheck: styled checkbox row inside a card.
    -- rightPad reserves space on the right (e.g. for a side button).
    -- Returns the checkbox widget.
    -- -----------------------------------------------------------------------
    local function CardCheck(card, cy, label, tooltip, initial, onToggle, image, rightPad)
        local BOX    = 18
        local rp     = rightPad or 0
        local labelW = card:GetWidth() - CARD_PH * 2 - BOX - 10 - rp

        -- Visual checkbox button
        local cb = W(CreateFrame("Button", nil, card, "BackdropTemplate"))
        cb:SetSize(BOX, BOX)
        cb:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
        cb:EnableMouse(true)
        cb:SetBackdrop({
            bgFile   = "Interface/Buttons/WHITE8X8",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        cb:SetBackdropColor(_C.BG_VERY_DARK[1], _C.BG_VERY_DARK[2], _C.BG_VERY_DARK[3], _C.BG_VERY_DARK[4])
        cb:SetBackdropBorderColor(_C.BORDER_GREY[1], _C.BORDER_GREY[2], _C.BORDER_GREY[3], _C.BORDER_GREY[4])

        local checkTex = cb:CreateTexture(nil, "OVERLAY")
        checkTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checkTex:SetSize(BOX, BOX)
        checkTex:SetPoint("CENTER", cb, "CENTER", 0, 0)
        checkTex:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
        checkTex:Hide()

        cb._checked = (initial and true or false)

        local function Refresh(self)
            if self._checked then
                self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
                checkTex:Show()
            else
                self:SetBackdropBorderColor(_C.BORDER_GREY[1], _C.BORDER_GREY[2], _C.BORDER_GREY[3], _C.BORDER_GREY[4])
                checkTex:Hide()
            end
        end
        Refresh(cb)

        local function DoToggle()
            cb._checked = not cb._checked
            Refresh(cb)
            if onToggle then onToggle(cb._checked) end
            _safeSound(856)
        end

        cb:HookScript("OnEnter", function(self)
            if not self._checked then
                self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.45)
            end
        end)
        cb:HookScript("OnLeave", function(self)
            if not self._checked then
                self:SetBackdropBorderColor(_C.BORDER_GREY[1], _C.BORDER_GREY[2], _C.BORDER_GREY[3], _C.BORDER_GREY[4])
            end
        end)
        cb:SetScript("OnClick", DoToggle)

        -- Non-interactive label
        local fs = W(card:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
        fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        fs:SetText(label)
        fs:SetWidth(labelW)
        fs:SetWordWrap(false)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

        -- Invisible click target over the label
        local labelBtn = W(CreateFrame("Button", nil, card))
        labelBtn:SetSize(labelW, BOX)
        labelBtn:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        labelBtn:EnableMouse(true)
        labelBtn:SetScript("OnClick", DoToggle)

        -- Full-row hover zone with animated gradient (via Animations.lua)
        local ROW_H  = BOX + 8
        local halfW  = math.floor((card:GetWidth() - 4 - rp) / 2)
        local rowFrame = W(CreateFrame("Frame", nil, card))
        rowFrame:SetHeight(ROW_H)
        rowFrame:SetPoint("TOPLEFT",  card, "TOPLEFT",  2,       cy + 4)
        rowFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", -2 - rp, cy + 4)
        rowFrame:EnableMouse(true)
        rowFrame:SetFrameLevel(math.max(1, cb:GetFrameLevel() - 1))

        BossHelper.Anim.ApplySettingsRowHover(
            rowFrame, cb, labelBtn, halfW,
            GOLD[1], GOLD[2], GOLD[3],
            function()  -- onShow
                if deps.ShowSettingsInfo then
                    deps.ShowSettingsInfo(label, _toDescStr(tooltip), image)
                end
            end,
            function() _hideInfo() end
        )

        function cb:GetChecked() return self._checked end
        function cb:SetChecked(val)
            self._checked = val and true or false
            Refresh(self)
        end

        return cb
    end

    -- -----------------------------------------------------------------------
    -- GrayCard: visually disables a card (alpha + mouse-blocking overlay).
    -- -----------------------------------------------------------------------
    local function GrayCard(card, disabled)
        if not card then return end
        if disabled then
            card:SetAlpha(0.4)
            if not card._disableOverlay then
                local overlay = W(CreateFrame("Frame", nil, card))
                overlay:SetAllPoints(card)
                overlay:EnableMouse(true)
                overlay:SetFrameLevel(card:GetFrameLevel() + 50)
                card._disableOverlay = overlay
            end
            card._disableOverlay:Show()
        else
            card:SetAlpha(1.0)
            if card._disableOverlay then
                card._disableOverlay:Hide()
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- CardSlider: labelled slider with inline value editing.
    -- Returns the slider widget.  Caller should Adv(44).
    -- -----------------------------------------------------------------------
    local function CardSlider(card, cy, label, tooltip, minVal, maxVal, step, initial,
                               formatFn, onChanged, onRelease, parseFn, image)
        local TRACK_H = 8
        local THUMB_W = 6
        local THUMB_H = 16
        local TW      = 170
        local fmt     = formatFn or function(v) return string.format("%.2f", v) end

        -- Label (left)
        local lbl = W(card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
        lbl:SetText(label)
        lbl:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

        -- Klikbar value-tekst: vis formatted vÃ¦rdi; klik â†’ inline editbox
        local valTxt = W(card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        valTxt:SetPoint("TOPRIGHT", card, "TOPLEFT", CARD_PH + TW, cy)
        valTxt:SetJustifyH("RIGHT")
        valTxt:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        valTxt:SetText(fmt(initial or minVal))

        -- Usynlig klik-knap over value-teksten
        local sld -- forward-declare so closures capture this local
        local valBtn = W(CreateFrame("Button", nil, card))
        valBtn:SetSize(44, 16)
        valBtn:SetPoint("TOPRIGHT", card, "TOPLEFT", CARD_PH + TW, cy - 1)
        valBtn:EnableMouse(true)
        valBtn:HookScript("OnEnter", function() valTxt:SetTextColor(1, 1, 0.7) end)
        valBtn:HookScript("OnLeave", function() valTxt:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end)

        -- Inline edit box (shown when value is clicked)
        local valEB = W(CreateFrame("EditBox", nil, card, "BackdropTemplate"))
        valEB:SetSize(44, 16)
        valEB:SetPoint("TOPRIGHT", card, "TOPLEFT", CARD_PH + TW, cy - 1)
        valEB:SetBackdrop({
            bgFile   = "Interface/Buttons/WHITE8X8",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 6,
            insets = { left = 2, right = 2, top = 1, bottom = 1 },
        })
        valEB:SetBackdropColor(_C.BG_VERY_DARK[1], _C.BG_VERY_DARK[2], _C.BG_VERY_DARK[3], 1)
        valEB:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.8)
        valEB:SetAutoFocus(false)
        valEB:SetMaxLetters(10)
        valEB:SetNumeric(false)
        valEB:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        valEB:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        valEB:SetJustifyH("CENTER")
        valEB:Hide()

        local function CommitEB()
            local raw = valEB:GetText():gsub("%%", ""):gsub(",", ".")
            local num = parseFn and parseFn(raw) or tonumber(raw)
            if num then
                num = math.max(minVal, math.min(maxVal, num))
                if step and step > 0 then
                    num = math.floor(num / step + 0.5) * step
                end
                sld:SetValue(num)
                if onRelease then onRelease(num) end
            end
            valEB:Hide()
            valTxt:Show()
            valBtn:Show()
        end

        valEB:SetScript("OnEnterPressed", function() CommitEB() end)
        valEB:SetScript("OnEscapePressed", function()
            valEB:Hide()
            valTxt:Show()
            valBtn:Show()
        end)
        valEB:SetScript("OnEditFocusLost", function() CommitEB() end)

        valBtn:SetScript("OnClick", function()
            valTxt:Hide()
            valBtn:Hide()
            -- Pre-fill med rÃ¥ tal (strip % osv.)
            local raw = fmt(sld:GetValue()):gsub("%%", "")
            valEB:SetText(raw)
            valEB:Show()
            valEB:SetFocus()
            valEB:HighlightText()
        end)

        -- Track (styled box)
        local track = W(CreateFrame("Frame", nil, card, "BackdropTemplate"))
        track:SetSize(TW, TRACK_H)
        track:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy - 20)
        track:SetBackdrop({
            bgFile   = "Interface/Buttons/WHITE8X8",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 6,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        track:SetBackdropColor(_C.BG_VERY_DARK[1], _C.BG_VERY_DARK[2], _C.BG_VERY_DARK[3], 1)
        track:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.3)

        -- Gold fill that grows with the value
        local fill = track:CreateTexture(nil, "ARTWORK")
        fill:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)
        fill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
        fill:SetHeight(TRACK_H - 2)
        fill:SetWidth(1)

        -- Invisible WoW Slider (handles drag input)
        sld = W(CreateFrame("Slider", nil, card))
        sld:SetSize(TW, THUMB_H)
        sld:SetPoint("CENTER", track, "CENTER", 0, 0)
        sld:SetOrientation("HORIZONTAL")
        sld:SetMinMaxValues(minVal, maxVal)
        sld:SetValueStep(step)
        sld:SetObeyStepOnDrag(true)
        sld:SetThumbTexture("Interface/Buttons/WHITE8X8")
        local thumb = sld:GetThumbTexture()
        thumb:SetSize(THUMB_W, THUMB_H)
        thumb:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)

        local function UpdateFill(value)
            local pct = (value - minVal) / math.max(1e-6, maxVal - minVal)
            fill:SetWidth(math.max(1, math.floor(pct * (TW - 2))))
        end

        sld:SetScript("OnValueChanged", function(self, value)
            UpdateFill(value)
            valTxt:SetText(fmt(value))
            if not valEB:IsShown() then
                valTxt:Show()
            end
            if onChanged then onChanged(value) end
        end)

        if onRelease then
            sld:SetScript("OnMouseUp", function(self) onRelease(self:GetValue()) end)
        end

        sld:HookScript("OnEnter", function() track:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.7) end)
        sld:HookScript("OnLeave", function() track:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.3) end)

        sld:SetValue(initial or minVal)
        sld._format = fmt
        AttachInfoHover(sld, label, tooltip, image)

        return sld
    end

    -- -----------------------------------------------------------------------
    -- CardSectionDivider: mini section header + rule inside an existing card.
    -- -----------------------------------------------------------------------
    local function CardSectionDivider(card, cy, text)
        local lbl = W(card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy - 4)
        lbl:SetText(text:upper())
        lbl:SetTextColor(1, 0.5, 0, 0.9)
        lbl:SetJustifyH("LEFT")
        local divRule = W(card:CreateTexture(nil, "ARTWORK"))
        divRule:SetColorTexture(1, 0.5, 0, 0.20)
        divRule:SetHeight(1)
        divRule:SetPoint("TOPLEFT",  lbl,  "BOTTOMLEFT",  0, -RULE_ABOVE)
        divRule:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PH, 0)
    end

    -- -----------------------------------------------------------------------
    -- BuildLanguageDropdown: language selector inside a card.
    -- -----------------------------------------------------------------------
    local function BuildLanguageDropdown(card, cy)
        local currentLang = BossHelperDB.language or "enUS"
        local languages   = BossHelper.LOCALES

        local dropdown = W(CreateFrame("Frame", nil, card))
        dropdown:SetSize(170, 26)
        dropdown:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
        dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
        dropdown:SetFrameLevel(1999)

        local initialLabel = "English"
        for _, lang in ipairs(languages) do
            if lang.key == currentLang then initialLabel = lang.label; break end
        end

        local mainBtn = W(CreateCustomButton(dropdown, 170, 26, initialLabel))
        mainBtn:SetPoint("TOP", dropdown, "TOP", 0, 0)
        AttachInfoHover(mainBtn, Translate("SELECT_LANGUAGE_TITLE"),
            { Translate("LANGUAGE_TOOLTIP_1"), Translate("LANGUAGE_TOOLTIP_2") }, IMG.LANG)
        mainBtn.arrow = mainBtn:CreateTexture(nil, "OVERLAY")
        mainBtn.arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
        mainBtn.arrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.8)
        mainBtn.arrow:SetAlpha(0.8)
        mainBtn.arrow:SetSize(20, 10)
        mainBtn.arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -8, 0)
        mainBtn.arrow:SetRotation(0)

        local panel = W(CreateFrame("Frame", nil, rPanel, "BackdropTemplate"))
        panel:SetSize(170, #languages * 26)
        panel:SetPoint("TOP", mainBtn, "BOTTOM", 0, -2)
        panel:Hide()
        panel:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        panel:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
        panel:SetFrameStrata("FULLSCREEN_DIALOG")
        panel:SetFrameLevel(2000)

        local catcher = W(CreateFrame("Frame", nil, UIParent))
        catcher:SetAllPoints(UIParent)
        catcher:EnableMouse(true)
        catcher:Hide()
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:SetFrameLevel(1999)
        rPanel.languageDropdownCatcher = catcher

        local reloadLabel
        local buttons = {}

        local function ClosePanel()
            panel:Hide()
            catcher:Hide()
            if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
        end

        catcher:SetScript("OnMouseDown", function(self)
            if panel:IsShown() then
                panel:Hide()
                self:Hide()
                if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
            end
        end)

        local function SelectLanguage(index, playSound, showNotice)
            local lang = languages[index]
            if not lang then return end
            BossHelperDB.language = lang.key
            if deps.BossHelper then deps.BossHelper.selectedLocale = lang.key end
            if BossHelper       then BossHelper.selectedLocale = lang.key end
            for i, btn in ipairs(buttons) do btn:SetSelected(i == index) end
            mainBtn:SetText(lang.label)
            if showNotice then
                if not reloadLabel then
                    reloadLabel = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
                    reloadLabel:SetPoint("TOPLEFT", dropdown, "TOPRIGHT", 10, 0)
                    reloadLabel:SetTextColor(1, 0.2, 0.2)
                end
                reloadLabel:SetText(Translate("/RELOAD_TEXT"))
                reloadLabel:Show()
                C_Timer.After(10, function()
                    if reloadLabel and reloadLabel.Hide then reloadLabel:Hide() end
                end)
            end
            if playSound then _safeSound(856) end
            if BossData and BossData.Reload then
                pcall(function() BossData:Reload() end)
            elseif deps.BossHelper and deps.BossHelper.Reload then
                pcall(function() deps.BossHelper:Reload() end)
            elseif BossHelper and BossHelper.Reload then
                pcall(function() BossHelper:Reload() end)
            end
        end

        for i, lang in ipairs(languages) do
            local btn = W(CreateCustomButton(panel, 170, 26, lang.label))
            btn:SetPoint("TOP", panel, "TOP", 0, -((i - 1) * 26))
            btn:SetScript("OnClick", function()
                _safeSound(856)
                SelectLanguage(i, true, true)
                ClosePanel()
            end)
            table.insert(buttons, btn)
        end

        local startIndex = 1
        for i, lang in ipairs(languages) do
            if lang.key == currentLang then startIndex = i; break end
        end
        SelectLanguage(startIndex, false, false)

        mainBtn:SetScript("OnClick", function()
            _safeSound(856)
            if panel:IsShown() then
                ClosePanel()
            else
                panel:Show()
                panel:SetFrameStrata("FULLSCREEN_DIALOG")
                panel:SetFrameLevel(2000)
                if rPanel.languageDropdownCatcher then
                    rPanel.languageDropdownCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                    rPanel.languageDropdownCatcher:SetFrameLevel(1999)
                    rPanel.languageDropdownCatcher:Show()
                end
                BossHelper.Anim.PlayDropdownOpen(panel)
                if mainBtn.arrow then mainBtn.arrow:SetRotation(math.pi) end
            end
        end)

        rPanel.languageDropdown = dropdown
        return dropdown
    end

    -- -----------------------------------------------------------------------
    -- PctSlider: percentage (0â€“1) slider that saves to BossHelperDB[dbKey]
    -- and calls applyFn() after each release.
    -- -----------------------------------------------------------------------
    local function PctSlider(card, cy, titleKey, tooltipKeys, dbKey, applyFn, image)
        CardSlider(card, cy,
            Translate(titleKey),
            { Translate(tooltipKeys[1]), Translate(tooltipKeys[2]) },
            0.0, 1.0, 0.01,
            tonumber(BossHelperDB[dbKey]) or 0.95,
            function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end,
            nil,
            function(value)
                BossHelperDB[dbKey] = value
                if applyFn then applyFn() end
            end,
            function(s) local n = tonumber(s); return n and (n / 100) end,
            image)
    end

    -- ===========================================================================
    -- CATEGORY: GENERAL
    -- ===========================================================================
    if category == Translate("GENERAL_CATE") then

        -- Card 1: Display (language + scale)
        do
            local card, CY, Adv, Fin = MakeCard(Translate("SETTINGS_DISPLAY_SECTION"))

            local langLabel = W(card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
            langLabel:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, CY())
            langLabel:SetText(Translate("SELECT_LANGUAGE_TITLE"))
            langLabel:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            Adv(17)

            BuildLanguageDropdown(card, CY())
            Adv(30)

            Adv(10)
            CardSlider(card, CY(),
                Translate("SCALE_SLIDER_TITLE"),
                { Translate("SCALE_SLIDER_TITLE"), Translate("SCALE_TOOLTIP") },
                0.5, 2.0, 0.05,
                BossHelperDB.scale or 1.0,
                function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end,
                nil,
                function(value)
                    BossHelperDB.scale = value
                    if BossUI and BossUI.GetFrame then
                        local f = BossUI.GetFrame()
                        if f then f:SetScale(value) end
                    end
                end,
                function(s) local n = tonumber(s); return n and (n / 100) end)
            Adv(44)

            Fin()
        end

        -- Card 2: Teleport (left)
        do
            local card, CY, Adv, Fin = MakeCard(Translate("TELEPORT_CARD"), "left")

            CardCheck(card, CY(), Translate("TELEPORT_MYTHIC_TAB_TITLE"), Translate("TELEPORT_MYTHIC_TAB_TOOLTIP"),
                BossHelperDB.teleportOnMythicTab ~= false,
                function(v)
                    BossHelperDB.teleportOnMythicTab = v
                    if BossHelper.MythicTeleport and BossHelper.MythicTeleport.UpdateVisibility then
                        BossHelper.MythicTeleport.UpdateVisibility()
                    end
                end, IMG.MYTHIC)
            Adv(28)

            Fin()
        end

        -- Card 3: Behavior + Minimap (right)
        do
            local card, CY, Adv, Fin = MakeCard(Translate("SETTINGS_BEHAVIOR_SECTION"), "right")

            CardCheck(card, CY(), Translate("ANIMATIONS_COMBT_TITLE"), Translate("ANIMATIONS_TOOLTIP"),
                BossHelperDB.allowAnimationsInCombat,
                function(v) BossHelperDB.allowAnimationsInCombat = v end)
            Adv(28)

            CardCheck(card, CY(), Translate("CLOSE_WINDOW_TITLE"), Translate("CLOSE_WINDOW_TOOLTIP"),
                BossHelperDB.closeOnPost,
                function(v) BossHelperDB.closeOnPost = v end, IMG.CLOSE_ON_POST)
            Adv(28)

            CardCheck(card, CY(), Translate("ESC_CLOSE_TITLE"), Translate("ESC_CLOSE_TOOLTIP"),
                BossHelperDB.allowEscClose or false,
                function(v)
                    BossHelperDB.allowEscClose = v
                    if BossUI and BossUI.GetFrame then
                        local f = BossUI.GetFrame()
                        if f then BossHelper:RegisterEscClose(f) end
                    end
                end)
            Adv(28)

            CardCheck(card, CY(), Translate("AUTO_OPEN_NOTES_TITLE"), Translate("AUTO_OPEN_NOTES_TOOLTIP"),
                BossHelperDB.autoOpenBossNotes ~= false,
                function(v) BossHelperDB.autoOpenBossNotes = v end, IMG.NOTES)
            Adv(28)

            CardCheck(card, CY(), Translate("START_PAGE_HIDE_GUIDE_TITLE"), Translate("START_PAGE_HIDE_GUIDE_TOOLTIP"),
                BossHelperDB.hideStartPageGuide or false,
                function(v)
                    BossHelperDB.hideStartPageGuide = v
                    local rp = BossUI and BossUI.GetRightPanel and BossUI.GetRightPanel()
                    local f  = BossUI and BossUI.GetFrame and BossUI.GetFrame()
                    if rp and rp.mainTitle and f then
                        ShowStartPage(f, rp)
                    end
                end)
            Adv(28)

            CardSectionDivider(card, CY(), Translate("SETTINGS_MINIMAP_SECTION"))
            Adv(28)

            CardCheck(card, CY(), Translate("MINIMAP_BTN_TITLE"), Translate("MINIMAP_BTN_TOOLTIP"),
                BossHelperDB.minimap and BossHelperDB.minimap.hide or false,
                function(v)
                    BossHelperDB.minimap = BossHelperDB.minimap or {}
                    BossHelperDB.minimap.hide = v
                    local dbIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
                    if dbIcon then
                        if v then dbIcon:Hide("BossHelper") else dbIcon:Show("BossHelper") end
                    end
                end)
            Adv(28)

            Fin()
        end

    -- ===========================================================================
    -- CATEGORY: AUTO-INVITE
    -- ===========================================================================
    elseif category == Translate("AUTO_INVITE_CATE") then

        -- Full-width enable card
        local updateWordCards  -- forward-declare for main toggle callback
        do
            local card, CY, Adv, Fin = MakeCard(Translate("AUTO_INVITE_CATE"), "full")
            CardCheck(card, CY(), Translate("AUTO_INVITE_TITLE"), Translate("AUTO_INVITE_TOOLTIP"),
                BossHelperDB.autoInviteEnabled,
                function(v)
                    BossHelperDB.autoInviteEnabled = v
                    Inviter.SetEnabled(v)
                    if updateWordCards then updateWordCards(v) end
                end)
            Adv(28)
            Fin()
        end

        -- Rebuild closure
        local function rebuild()
            BossSettings.RebuildCategory(rPanel, category, ctx)
        end

        -- -----------------------------------------------------------------------
        -- Shared ApplyEditVisual (mirrors GeneralNotes implementation)
        -- -----------------------------------------------------------------------
        local function ApplyEditVisual(chip, on)
            if on then
                chip._origAlpha = chip:GetAlpha() or 1
                chip:SetAlpha(0.45)
                if chip.text then chip.text:SetTextColor(0.7, 0.7, 0.7, 1) end
                chip:EnableMouse(false)
            else
                chip:SetAlpha(chip._origAlpha or 1)
                if chip.text then
                    chip.text:SetTextColor(0.98, 0.82, 0.55)  -- restore GOLD
                end
                chip:EnableMouse(true)
            end
        end

        -- -----------------------------------------------------------------------
        -- BuildWordCard: one half-card for a trigger-word list.
        -- -----------------------------------------------------------------------
        local function BuildWordCard(listName, titleKey, col)
            local card, CY, Adv, Fin = MakeCard(Translate(titleKey), col)
            local cardW  = card:GetWidth()
            local chipW  = cardW - CARD_PH * 2
            local CHIP_H = 26
            local PENCIL = "Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png"

            -- Per-card editing state: which chip is currently being edited
            local editingChip  = nil   -- the chip frame being edited
            local editingWord  = nil   -- the original word string
            local cardInput    = nil   -- set later, referenced in chip callbacks

            local words = (Inviter and Inviter.GetWords) and Inviter.GetWords(listName) or {}

            -- ---- Word chips -------------------------------------------------
            if #words == 0 then
                local none = W(card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"))
                none:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH + 4, CY())
                none:SetText(Translate("TRIGGER_NONE"))
                none:SetTextColor(0.45, 0.45, 0.45)
                Adv(CHIP_H)
            else
                for _, word in ipairs(words) do
                    local capturedWord = word
                    local chipY        = CY()

                    local chip = W(CreateCustomButton(card, chipW, CHIP_H, ""))
                    chip:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, chipY)
                    chip.text:ClearAllPoints()
                    chip.text:SetPoint("LEFT",  chip, "LEFT",  8, 0)
                    chip.text:SetPoint("RIGHT", chip, "RIGHT", -32, 0)
                    chip.text:SetJustifyH("LEFT")
                    chip.text:SetWordWrap(false)
                    chip:SetText(word)

                    -- X delete
                    local xIcon = chip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    xIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                    xIcon:SetText("X")
                    xIcon:SetTextColor(1, 0.2, 0.2)
                    xIcon:SetPoint("TOPRIGHT", chip, "TOPRIGHT", 2, -1)
                    local xBtn = W(CreateFrame("Button", nil, chip))
                    xBtn:SetSize(12, 12)
                    xBtn:EnableMouse(true)
                    xBtn:SetPoint("CENTER", xIcon, "CENTER", 0, 0)

                    -- Pencil edit
                    local pencilIcon = chip:CreateTexture(nil, "OVERLAY")
                    pencilIcon:SetTexture(PENCIL)
                    pencilIcon:SetSize(11, 11)
                    pencilIcon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
                    pencilIcon:SetPoint("TOPRIGHT", chip, "TOPRIGHT", -1, -14)
                    local pencilBtn = W(CreateFrame("Button", nil, chip))
                    pencilBtn:SetSize(13, 13)
                    pencilBtn:EnableMouse(true)
                    pencilBtn:SetPoint("CENTER", pencilIcon, "CENTER", 0, 0)

                    xIcon:Hide(); xBtn:Hide(); pencilIcon:Hide(); pencilBtn:Hide()

                    -- Mutually-exclusive hover (same as GeneralNotes)
                    pencilBtn:HookScript("OnEnter", function()
                        pencilIcon:SetVertexColor(1, 1, 1, 1)
                        xIcon:Hide(); xBtn:Hide()
                    end)
                    pencilBtn:HookScript("OnLeave", function()
                        pencilIcon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
                        if not xBtn:IsMouseOver() then
                            xIcon:Hide(); xBtn:Hide(); pencilIcon:Hide(); pencilBtn:Hide()
                        end
                    end)
                    xBtn:HookScript("OnEnter", function()
                        xIcon:SetTextColor(1, 1, 1)
                        pencilIcon:Hide(); pencilBtn:Hide()
                    end)
                    xBtn:HookScript("OnLeave", function()
                        xIcon:SetTextColor(1, 0.2, 0.2)
                        if not pencilBtn:IsMouseOver() then
                            xIcon:Hide(); xBtn:Hide(); pencilIcon:Hide(); pencilBtn:Hide()
                        end
                    end)
                    chip:HookScript("OnEnter", function()
                        if chip:IsMouseEnabled() then
                            xIcon:Show(); xBtn:Show(); pencilIcon:Show(); pencilBtn:Show()
                        end
                    end)
                    chip:HookScript("OnLeave", function()
                        if not pencilBtn:IsMouseOver() and not xBtn:IsMouseOver() then
                            xIcon:Hide(); xBtn:Hide(); pencilIcon:Hide(); pencilBtn:Hide()
                        end
                    end)

                    -- Delete
                    xBtn:SetScript("OnClick", function()
                        if Inviter then Inviter.RemoveWord(listName, capturedWord) end
                        rebuild()
                    end)

                    -- Pencil: grey out chip, put text in card's bottom input
                    pencilBtn:SetScript("OnClick", function()
                        -- Cancel previous edit in this card (if any)
                        if editingChip and editingChip ~= chip then
                            ApplyEditVisual(editingChip, false)
                        end
                        editingChip = chip
                        editingWord = capturedWord
                        ApplyEditVisual(chip, true)
                        xIcon:Hide(); xBtn:Hide(); pencilIcon:Hide(); pencilBtn:Hide()
                        if cardInput then
                            cardInput:SetText(capturedWord)
                            cardInput:SetFocus()
                        end
                    end)

                    Adv(CHIP_H + 3)
                end
            end

            -- ---- Bottom input (add new or commit edit) ----------------------
            Adv(2)
            local eb = W(CreateFrame("EditBox", nil, card, "InputBoxTemplate"))
            eb:SetHeight(22)
            -- InputBoxTemplate's left edge graphic sticks ~5px outside the frame,
            -- so add 5px extra on each side to visually align with the chips.
            eb:SetPoint("TOPLEFT",  card, "TOPLEFT",  CARD_PH + 5,  CY())
            eb:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PH - 0, CY())
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(50)
            cardInput = eb   -- let pencil callbacks above reference it

            local hint = W(card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"))
            hint:SetPoint("LEFT", eb, "LEFT", 4, 0)
            hint:SetText(Translate("TRIGGER_INPUT_HINT"))
            hint:SetTextColor(0.4, 0.4, 0.4)
            eb:HookScript("OnTextChanged", function(self)
                hint:SetShown(self:GetText() == "")
            end)

            local function Commit()
                local newWord = trim(eb:GetText())
                if editingChip then
                    -- Edit mode: replace the old word
                    if newWord ~= "" and newWord ~= editingWord and Inviter then
                        Inviter.RemoveWord(listName, editingWord)
                        Inviter.AddWord(listName, newWord)
                    end
                    editingChip = nil
                    editingWord = nil
                    rebuild()
                elseif newWord ~= "" and Inviter then
                    -- Add mode
                    local ok = Inviter.AddWord(listName, newWord)
                    if ok then rebuild() end
                end
            end
            local function Cancel()
                if editingChip then
                    ApplyEditVisual(editingChip, false)
                    editingChip = nil
                    editingWord = nil
                end
                eb:SetText("")
                eb:ClearFocus()
            end
            eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); Commit() end)
            eb:SetScript("OnEscapePressed", function() Cancel() end)
            eb:SetScript("OnEditFocusLost", Commit)

            Adv(20)   -- tighter bottom padding (was 28)
            Fin()
            return card
        end

        -- Left: Guild & Friends  |  Right: Others
        local cardFriendly = BuildWordCard("friendly", "TRIGGER_FRIENDLY_TITLE", "left")
        local cardOther    = BuildWordCard("other",    "TRIGGER_OTHER_TITLE",    "right")
        updateWordCards = function(enabled)
            GrayCard(cardFriendly, not enabled)
            GrayCard(cardOther,    not enabled)
        end
        updateWordCards(BossHelperDB.autoInviteEnabled)

    -- ===========================================================================
    -- CATEGORY: MINI WINDOW
    -- ===========================================================================
    elseif category == Translate("MINI_WINDOW_CATE") then

        local function ApplyMiniWindow()
            if MiniWindow and MiniWindow.ApplySettings then MiniWindow.ApplySettings() end
        end

        -- Enable switch (full-width)
        local updateMiniSubCards  -- forward-declare for main toggle callback
        do
            local card, CY, Adv, Fin = MakeCard(Translate("MINI_WINDOW_CATE"), "full")
            local rowY       = CY()
            local SIDE_BTN_W = 160

            CardCheck(card, rowY, Translate("MINI_WINDOW_ENABLED_TITLE"), Translate("MINI_WINDOW_ENABLED_TOOLTIP"),
                BossHelperDB.miniWindowEnabled ~= false,
                function(v)
                    BossHelperDB.miniWindowEnabled = v
                    if v then
                        if MiniWindow and MiniWindow.ShowIfInDungeon then MiniWindow.ShowIfInDungeon() end
                    else
                        ApplyMiniWindow()
                    end
                    if updateMiniSubCards then updateMiniSubCards(v) end
                end, IMG.MINI, SIDE_BTN_W + CARD_PH + 4)

            local openBtn = W(CreateCustomButton(card, SIDE_BTN_W, 30, Translate("MINI_WINDOW_OPEN_BTN")))
            openBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PH, rowY + 6)
            AttachInfoHover(openBtn, Translate("MINI_WINDOW_OPEN_BTN"), Translate("MINI_WINDOW_OPEN_BTN_TOOLTIP"), IMG.MINI)
            openBtn:SetScript("OnClick", function()
                if MiniWindow and MiniWindow.ShowIfInDungeon then MiniWindow.ShowIfInDungeon() end
            end)
            Adv(24)
            Fin()
        end

        -- Behavior (left)
        local miniBehaviorCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("SETTINGS_BEHAVIOR_SECTION"), "left")

            CardCheck(card, CY(), Translate("MINI_WINDOW_AUTO_EXPAND_TITLE"), Translate("MINI_WINDOW_AUTO_EXPAND_TOOLTIP"),
                BossHelperDB.miniWindowAutoExpand,
                function(v) BossHelperDB.miniWindowAutoExpand = v end, IMG.MINI)
            Adv(28)

            Fin()
            miniBehaviorCard = card
        end

        -- Appearance (right)
        local miniAppearanceCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("SETTINGS_APPEARANCE_SECTION"), "right")

            PctSlider(card, CY(),
                "MINI_WINDOW_TRANSPARENT_TITLE",
                { "MINI_WINDOW_TRANSPARENT_TITLE", "MINI_WINDOW_TRANSPARENT_TOOLTIP" },
                "miniWindowTransparency", ApplyMiniWindow, IMG.MINI)
            Adv(44)

            CardCheck(card, CY(), Translate("MINI_WINDOW_NO_BORDER_TITLE"), Translate("MINI_WINDOW_NO_BORDER_TOOLTIP"),
                BossHelperDB.miniWindowNoBorder,
                function(v) BossHelperDB.miniWindowNoBorder = v; ApplyMiniWindow() end, IMG.MINI)
            Adv(28)

            CardCheck(card, CY(), Translate("MINI_WINDOW_HIDE_SEP_TITLE"), Translate("MINI_WINDOW_HIDE_SEP_TOOLTIP"),
                BossHelperDB.miniWindowHideSeparator,
                function(v) BossHelperDB.miniWindowHideSeparator = v; ApplyMiniWindow() end, IMG.MINI)
            Adv(28)

            CardCheck(card, CY(), Translate("MINI_WINDOW_ICONS_ONLY_TITLE"), Translate("MINI_WINDOW_ICONS_ONLY_TOOLTIP"),
                BossHelperDB.miniWindowHideButtonChrome,
                function(v) BossHelperDB.miniWindowHideButtonChrome = v; ApplyMiniWindow() end, IMG.MINI)
            Adv(28)

            Fin()
            miniAppearanceCard = card
        end

        updateMiniSubCards = function(enabled)
            GrayCard(miniBehaviorCard,   not enabled)
            GrayCard(miniAppearanceCard, not enabled)
        end
        updateMiniSubCards(BossHelperDB.miniWindowEnabled ~= false)

    -- ===========================================================================
    -- CATEGORY: KEY TRACKER
    -- ===========================================================================
    elseif category == Translate("KEY_TRACKER_CATE") then

        local function RefreshGFPanel()
            if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.UpdateVisibility then
                BossHelper.GroupFinderPanel.UpdateVisibility()
            end
        end
        local function ApplyGFPanel()
            if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.ApplySettings then
                BossHelper.GroupFinderPanel.ApplySettings()
            end
        end

        -- Enable switch (full-width)
        local updateKeySubCards  -- forward-declare for main toggle callback
        do
            local card, CY, Adv, Fin = MakeCard(Translate("KEY_TRACKER_CATE"), "full")

            CardCheck(card, CY(), Translate("KEY_TRACKER_ENABLED_TITLE"), Translate("KEY_TRACKER_ENABLED_TOOLTIP"),
                BossHelperDB.keyTrackerEnabled ~= false,
                function(v)
                    BossHelperDB.keyTrackerEnabled = v
                    RefreshGFPanel()
                    if rPanel and rPanel.keystoneWidget then
                        rPanel.keystoneWidget:SetEnabled(v and (BossHelperDB.showKeysOnStartPage ~= false))
                    end
                    if updateKeySubCards then updateKeySubCards(v) end
                end, IMG.KEY_CARD)
            Adv(28)
            Fin()
        end

        -- Start Page (left)
        local keyStartPageCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("KEY_TRACKER_STARTPAGE_CARD"), "left")

            CardCheck(card, CY(), Translate("KEY_TRACKER_STARTPAGE_TITLE"), Translate("KEY_TRACKER_STARTPAGE_TOOLTIP"),
                BossHelperDB.showKeysOnStartPage ~= false,
                function(v)
                    BossHelperDB.showKeysOnStartPage = v
                    if rPanel and rPanel.keystoneWidget then rPanel.keystoneWidget:SetEnabled(v) end
                end, IMG.KEY_CARD)
            Adv(28)

            CardCheck(card, CY(), Translate("TELEPORT_KEY_CARDS_TITLE"), Translate("TELEPORT_KEY_CARDS_TOOLTIP"),
                BossHelperDB.teleportOnKeyCards ~= false,
                function(v)
                    BossHelperDB.teleportOnKeyCards = v
                    BossHelper.RefreshAllKeystoneWidgets()
                end, IMG.KEY_TELEPORT)
            Adv(28)

            Fin()
            keyStartPageCard = card
        end

        -- Group Finder toggles (right)
        local keyGFTogglesCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("KEY_TRACKER_GF_APPEARANCE"), "right")

            CardCheck(card, CY(), Translate("KEY_TRACKER_GROUPFINDER_TITLE"), Translate("KEY_TRACKER_GROUPFINDER_TOOLTIP"),
                BossHelperDB.showKeysInGroupFinder ~= false,
                function(v) BossHelperDB.showKeysInGroupFinder = v; RefreshGFPanel() end, IMG.KEY_LIST)
            Adv(28)

            CardCheck(card, CY(), Translate("TELEPORT_KEY_LIST_TITLE"), Translate("TELEPORT_KEY_LIST_TOOLTIP"),
                BossHelperDB.teleportOnKeyList ~= false,
                function(v)
                    BossHelperDB.teleportOnKeyList = v
                    BossHelper.RefreshAllKeystoneWidgets()
                end, IMG.KEY_LIST)
            Adv(28)

            Fin()
            keyGFTogglesCard = card
        end

        -- Group Finder Appearance (full)
        local keyAppearanceCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("SETTINGS_APPEARANCE_SECTION"))

            PctSlider(card, CY(),
                "KEY_TRACKER_GF_TRANSPARENT_TITLE",
                { "KEY_TRACKER_GF_TRANSPARENT_TITLE", "KEY_TRACKER_GF_TRANSPARENT_TOOLTIP" },
                "gfPanelTransparency", ApplyGFPanel, IMG.KEY_LIST)
            Adv(44)

            CardCheck(card, CY(), Translate("KEY_TRACKER_GF_NO_BORDER_TITLE"), Translate("KEY_TRACKER_GF_NO_BORDER_TOOLTIP"),
                BossHelperDB.gfNoBorder,
                function(v) BossHelperDB.gfNoBorder = v; ApplyGFPanel() end, IMG.KEY_LIST)
            Adv(28)

            CardCheck(card, CY(), Translate("KEY_TRACKER_GF_HIDE_TITLE_TITLE"), Translate("KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"),
                BossHelperDB.gfHideTitle,
                function(v) BossHelperDB.gfHideTitle = v; ApplyGFPanel() end, IMG.KEY_LIST)
            Adv(28)

            Fin()
            keyAppearanceCard = card
        end

        updateKeySubCards = function(enabled)
            GrayCard(keyStartPageCard,  not enabled)
            GrayCard(keyGFTogglesCard,  not enabled)
            GrayCard(keyAppearanceCard, not enabled)
        end
        updateKeySubCards(BossHelperDB.keyTrackerEnabled ~= false)

    -- ===========================================================================
    -- CATEGORY: DUNGEON CHECK WINDOW
    -- ===========================================================================
    elseif category == Translate("DCW_CATE") then

        local function ApplyDCW()
            if DungeonCheckWindow and DungeonCheckWindow.ApplySettings then
                DungeonCheckWindow.ApplySettings()
            end
        end

        -- Enable switch (full-width)
        local updateDCWSubCards  -- forward-declare for main toggle callback
        do
            local card, CY, Adv, Fin = MakeCard(Translate("DCW_CATE"), "full")
            local rowY       = CY()
            local SIDE_BTN_W = 160

            CardCheck(card, rowY, Translate("DCW_ENABLED_TITLE"), Translate("DCW_ENABLED_TOOLTIP"),
                BossHelperDB.dcwEnabled ~= false,
                function(v)
                    BossHelperDB.dcwEnabled = v
                    ApplyDCW()
                    if v and DungeonCheckWindow and DungeonCheckWindow.Show then
                        DungeonCheckWindow.Show()
                    end
                    if updateDCWSubCards then updateDCWSubCards(v) end
                end, IMG.DCW, SIDE_BTN_W + CARD_PH + 4)

            local openBtn = W(CreateCustomButton(card, SIDE_BTN_W, 30, Translate("DCW_OPEN_BTN")))
            openBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PH, rowY + 6)
            AttachInfoHover(openBtn, Translate("DCW_OPEN_BTN"), Translate("DCW_OPEN_BTN_TOOLTIP"), IMG.DCW)
            openBtn:SetScript("OnClick", function()
                if DungeonCheckWindow and DungeonCheckWindow.Show then DungeonCheckWindow.Show() end
            end)
            Adv(24)
            Fin()
        end

        -- Checks (left)
        local dcwChecksCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("DCW_SETTINGS_BEHAVIOR"), "left")

            local checks = {
                { "DCW_SHOW_SPEC_TITLE",  "DCW_SHOW_SPEC_TOOLTIP",  "dcwShowSpec"       },
                { "DCW_SHOW_DUR_TITLE",   "DCW_SHOW_DUR_TOOLTIP",   "dcwShowDurability" },
                { "DCW_SHOW_FLASK_TITLE", "DCW_SHOW_FLASK_TOOLTIP", "dcwShowFlask"      },
                { "DCW_SHOW_FOOD_TITLE",  "DCW_SHOW_FOOD_TOOLTIP",  "dcwShowFood"       },
                { "DCW_SHOW_BTNS_TITLE",  "DCW_SHOW_BTNS_TOOLTIP",  "dcwShowButtons"    },
            }
            for _, c in ipairs(checks) do
                local titleKey, tipKey, dbKey = c[1], c[2], c[3]
                CardCheck(card, CY(), Translate(titleKey), Translate(tipKey),
                    BossHelperDB[dbKey] ~= false,
                    function(v) BossHelperDB[dbKey] = v; ApplyDCW() end, IMG.DCW)
                Adv(28)
            end

            Fin()
            dcwChecksCard = card
        end

        -- Appearance (right)
        local dcwAppearanceCard
        do
            local card, CY, Adv, Fin = MakeCard(Translate("DCW_SETTINGS_APPEARANCE"), "right")

            PctSlider(card, CY(),
                "DCW_TRANSPARENT_TITLE",
                { "DCW_TRANSPARENT_TITLE", "DCW_TRANSPARENT_TOOLTIP" },
                "dcwTransparency", ApplyDCW, IMG.DCW)
            Adv(44)

            CardCheck(card, CY(), Translate("DCW_NO_BORDER_TITLE"), Translate("DCW_NO_BORDER_TOOLTIP"),
                BossHelperDB.dcwNoBorder,
                function(v) BossHelperDB.dcwNoBorder = v; ApplyDCW() end, IMG.DCW)
            Adv(28)

            Fin()
            dcwAppearanceCard = card
        end

        updateDCWSubCards = function(enabled)
            GrayCard(dcwChecksCard,     not enabled)
            GrayCard(dcwAppearanceCard, not enabled)
        end
        updateDCWSubCards(BossHelperDB.dcwEnabled ~= false)

    end

    settingsContent:SetHeight(math.abs(cardY) + 8)
end

-- ===========================================================================
-- SelectSettingCategory
-- ===========================================================================
function BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, categoryName, btn, ctx)
    ctx = ctx or {}

    if frame.settingsSelectedButton then
        pcall(frame.settingsSelectedButton.SetSelected, frame.settingsSelectedButton, false)
        frame.settingsSelectedButton = nil
    end
    if btn then
        pcall(btn.SetSelected, btn, true)
        frame.settingsSelectedButton = btn
    end

    if rightPanel.logo        then _hide(rightPanel.logo)                  end
    if rightPanel.mainTitle   then _setText(rightPanel.mainTitle,   "")    end
    if rightPanel.mainDesc    then _setText(rightPanel.mainDesc,    "")    end
    if rightPanel.footerText  then _setText(rightPanel.footerText,  "")    end
    if rightPanel.footerText2 then _setText(rightPanel.footerText2, "")    end

    if not rightPanel.rightTitle then
        rightPanel.rightTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        rightPanel.rightTitle:SetPoint("TOP", rightPanel, "TOP", 0, -20)
        rightPanel.rightTitle:SetTextColor(1, 0.5, 0)
        rightPanel.rightTitle:SetJustifyH("CENTER")
    end
    _setText(rightPanel.rightTitle, categoryName)

    CleanupSettingsWidgets(rightPanel)

    BossSettings.BuildSettingsCategoryUI(rightPanel, categoryName, {
        CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton,
        BossHelperDB       = ctx.BossHelperDB       or deps.BossHelperDB,
    })
end

-- ===========================================================================
-- ShowSettings  (main entry point called from BossUI)
-- ===========================================================================
function BossSettings.ShowSettings(ctx)
    ctx = ctx or {}

    local depKeys = { "CreateCustomButton", "BossHelper", "BossHelperDB", "ShowSettingsInfo", "HideSettingsInfo" }
    for _, k in ipairs(depKeys) do
        if ctx[k] then deps[k] = ctx[k] end
    end

    local frame      = ctx.frame
    local leftPanel  = ctx.leftPanel
    local rightPanel = ctx.rightPanel
    local backButton = ctx.backButton
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

    if not (frame and leftPanel and rightPanel and CreateCustomButton) then
        print("|cffFF4500[BossSettings]|r Missing context for ShowSettings()")
        return
    end

    _hide(rightPanel.discordButton)
    _hide(rightPanel.githubButton)
    _hide(rightPanel.bugReportButton)

    frame.currentMode    = "settings"
    frame.selectedBoss   = nil
    frame.currentDungeon = nil

    if rightPanel.phaseDropdown        then _hide(rightPanel.phaseDropdown)        end
    if rightPanel.dropdownClickCatcher then _hide(rightPanel.dropdownClickCatcher) end

    if rightPanel.shortBtnScroll  then _hide(rightPanel.shortBtnScroll) end
    if rightPanel.shortBtnContent then
        pcall(rightPanel.shortBtnContent.SetHeight, rightPanel.shortBtnContent, 1)
    end
    if rightPanel.shortButtons then
        for _, b in ipairs(rightPanel.shortButtons) do
            if b then _hide(b); _setParent(b, nil) end
        end
    end
    rightPanel.shortButtons = {}

    _setText(rightPanel.rightTitle, Translate("SETTINGS"))
    if rightPanel.rightShortText  then _setText(rightPanel.rightShortText,  "") end
    if rightPanel.rightDetailText then _setText(rightPanel.rightDetailText, "") end

    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText(Translate("SETTINGS") or "Settings")
    end

    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then _hide(btn.icon) end
            _hide(btn)
            _setParent(btn, nil)
        end
    end
    frame.bossButtons = {}

    local categories = {
        Translate("GENERAL_CATE"),
        Translate("AUTO_INVITE_CATE"),
        Translate("MINI_WINDOW_CATE"),
        Translate("KEY_TRACKER_CATE"),
        Translate("DCW_CATE"),
    }

    local y = -39
    for _, cat in ipairs(categories) do
        local btn = CreateCustomButton(leftPanel, 180, 30, cat)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn:SetScript("OnClick", function()
            _hideInfo()
            BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, cat, btn, {
                CreateCustomButton = CreateCustomButton,
                BossHelperDB       = deps.BossHelperDB,
            })
            _safeSound(856)
        end)
        table.insert(frame.bossButtons, btn)
        y = y - 35
    end

    if backButton then backButton:Show() end

    if #frame.bossButtons > 0 then
        BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, categories[1],
            frame.bossButtons[1], {
                CreateCustomButton = CreateCustomButton,
                BossHelperDB       = deps.BossHelperDB,
            })
    end
end

return BossSettings
