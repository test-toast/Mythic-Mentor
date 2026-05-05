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
    for k,v in pairs(d) do deps[k] = v end
end

-- Delegate to the shared UI utilities in BossHelper.UI
local phide        = function(o)      BossHelper.UI.hide(o)         end
local psetparent   = function(o, p)   BossHelper.UI.setParent(o, p) end
local pclearpoints = function(o)      BossHelper.UI.clearPoints(o)  end
local psettext     = function(o, txt) BossHelper.UI.setText(o, txt) end
local function psafesound(sid)
    pcall(function()
        if deps.BossHelper and deps.BossHelper.SafePlaySound then deps.BossHelper:SafePlaySound(sid) end
    end)
end

-- Cleanup helper for rightPanel settings widgets
local function CleanupSettingsWidgets(rPanel)
    if not rPanel or not rPanel.settingsWidgets then return end
    for _, w in ipairs(rPanel.settingsWidgets) do
        BossHelper.UI.destroyWidget(w)
    end
    rPanel.settingsWidgets = nil
end

-- Tooltip helper: sæt obj.tooltip = "tekst" eller {"linje1", "linje2", ...}
-- Ingen titel/beskrivelse-opdeling – alle linjer samme farve, fast max-bredde.
local TOOLTIP_WIDTH = 280
local _C = BossHelper.UI.C
local function AttachTooltip(obj)
    if not obj then return end
    if obj.EnableMouse then obj:EnableMouse(true) end

    obj:HookScript("OnEnter", function(self)
        local tip = self.tooltip or self._tooltip
        if not tip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetWidth(TOOLTIP_WIDTH)
        if type(tip) == "table" then
            for i = 1, #tip do
                GameTooltip:AddLine(tostring(tip[i]), _C.TEXT_GOLD[1], _C.TEXT_GOLD[2], _C.TEXT_GOLD[3], true)
            end
        else
            for line in (tostring(tip) .. "\n"):gmatch("([^\n]*)\n") do
                GameTooltip:AddLine(line ~= "" and line or " ", _C.TEXT_GOLD[1], _C.TEXT_GOLD[2], _C.TEXT_GOLD[3], true)
            end
        end
        -- Slider: vis aktuel værdi
        if self.GetValue then
            local ok, val = pcall(self.GetValue, self)
            if ok and val ~= nil then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(Translate("CURRENT_SCALE_TOOLTIP") .. " " .. tostring(val), _C.TEXT_GOLD[1], _C.TEXT_GOLD[2], _C.TEXT_GOLD[3], true)
            end
        end
        GameTooltip:Show()
    end)

    obj:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end



-- BuildSettingsCategoryUI
function BossSettings.BuildSettingsCategoryUI(rPanel, category, ctx)
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
    local BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB

    rPanel.settingsWidgets = rPanel.settingsWidgets or {}

    -- -------------------------------------------------------------------------
    -- Helpers
    -- -------------------------------------------------------------------------
    local function W(w)
        table.insert(rPanel.settingsWidgets, w)
        return w
    end

    -- Section header: gold title + horizontal rule
    local function AddSectionHeader(text, anchorFrame, anchorPoint, offX, offY, width)
        width = width or 240
        local hdr = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        hdr:SetPoint(anchorPoint or "TOPLEFT", anchorFrame, anchorPoint or "TOPLEFT", offX or 0, offY or 0)
        hdr:SetText(text:upper())
        hdr:SetTextColor(1, 0.5, 0)
        hdr:SetJustifyH("LEFT")

        local rule = W(rPanel:CreateTexture(nil, "ARTWORK"))
        rule:SetColorTexture(1, 0.5, 0, 0.25)
        rule:SetHeight(1)
        rule:SetWidth(width)
        rule:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -3)
        return hdr, rule
    end

    -- Compact checkbox: label to the right
    local function AddCheck(anchorFrame, anchorPoint, offX, offY, label, tooltip, initial, onToggle)
        local cb = W(CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate"))
        cb:SetSize(26, 26)
        cb:SetPoint(anchorPoint, anchorFrame, anchorPoint, offX, offY)
        local fs = W(cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
        fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        fs:SetText(label)
        fs:SetWidth(200)
        fs:SetWordWrap(false)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.98, 0.82, 0.55)
        cb.tooltip = tooltip
        AttachTooltip(cb)
        if initial ~= nil then pcall(cb.SetChecked, cb, initial) end
        if onToggle then
            cb:SetScript("OnClick", function(self)
                onToggle(self:GetChecked() and true or false)
                if deps.BossHelper and deps.BossHelper.SafePlaySound then deps.BossHelper:SafePlaySound(856) end
            end)
        end
        return cb
    end

    --------------------------------------------------------------------------------
    -- category General  — two-column layout
    --   Left column  (x=20):  Display section  — Language dropdown + Scale slider
    --   Right column (x=300): Behavior section — 4 checkboxes
    --------------------------------------------------------------------------------
    if category == Translate("GENERAL_CATE") then

        local COL_L = 20   -- left column x
        local COL_R = 300  -- right column x
        local TOP_Y = -50  -- top y for both columns

        -- ==== LEFT COLUMN: Display ============================================
        local dispHdr, dispRule = AddSectionHeader(
            Translate("SETTINGS_DISPLAY_SECTION"), rPanel, "TOPLEFT", COL_L, TOP_Y, 240)

        -- Language label + dropdown
        local langLabel = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        langLabel:SetPoint("TOPLEFT", dispRule, "BOTTOMLEFT", 0, -14)
        langLabel:SetText(Translate("SELECT_LANGUAGE_TITLE"))
        langLabel:SetTextColor(0.9, 0.9, 0.9)

        -- ---- language dropdown (extracted from old code, anchor rewritten) ----
        do
            local currentLang = BossHelperDB.language or "enUS"
            local languages = BossHelper.LOCALES

            local dropdown = W(CreateFrame("Frame", nil, rPanel, "BackdropTemplate"))
            dropdown:SetSize(200, 26)
            dropdown:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -4)

            local initialLabel = "English"
            for _, lang in ipairs(languages) do
                if lang.key == currentLang then initialLabel = lang.label; break end
            end
            local mainBtn = CreateCustomButton(dropdown, 200, 26, initialLabel)
            mainBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
            mainBtn.tooltip = { Translate("LANGUAGE_TOOLTIP_1"), Translate("LANGUAGE_TOOLTIP_2") }
            AttachTooltip(mainBtn)
            mainBtn.arrow = mainBtn:CreateTexture(nil, "OVERLAY")
            mainBtn.arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
            mainBtn.arrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
            mainBtn.arrow:SetSize(20, 10)
            mainBtn.arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -8, 0)
            mainBtn.arrow:SetRotation(0)

            local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
            panel:SetSize(200, #languages * 26)
            panel:SetPoint("TOPLEFT", mainBtn, "BOTTOMLEFT", 0, -2)
            panel:Hide()
            panel:SetBackdrop({
                bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            panel:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
            panel:SetFrameStrata("FULLSCREEN_DIALOG")
            panel:SetFrameLevel(2000)
            dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
            dropdown:SetFrameLevel(1999)

            local buttons = {}
            local function SelectLanguage(index, playSound, showNotice)
                local lang = languages[index]
                if not lang then return end
                BossHelperDB.language = lang.key
                currentLang = lang.key
                if deps and deps.BossHelper then deps.BossHelper.selectedLocale = lang.key end
                if BossHelper then BossHelper.selectedLocale = lang.key end
                for i, btn in ipairs(buttons) do
                    if btn.SetSelected then
                        btn:SetSelected(i == index)
                    else
                        if i == index then btn:SetText("|cff00ff00" .. btn:GetText() .. "|r")
                        else btn:SetText(languages[i].label) end
                    end
                end
                mainBtn:SetText(lang.label)
                if not dropdown.reloadLabel then
                    dropdown.reloadLabel = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    dropdown.reloadLabel:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)
                    dropdown.reloadLabel:SetTextColor(1, 0.2, 0.2)
                    dropdown.reloadLabel:Hide()
                end
                if showNotice then
                    dropdown.reloadLabel:SetText(Translate("/RELOAD_TEXT"))
                    dropdown.reloadLabel:Show()
                    C_Timer.After(10, function()
                        if dropdown.reloadLabel and dropdown.reloadLabel.Hide then dropdown.reloadLabel:Hide() end
                    end)
                end
                if playSound and deps and deps.BossHelper and deps.BossHelper.SafePlaySound then
                    deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds and deps.BossHelper.Sounds.NORMAL_BUTTON or 856)
                end
                if BossData and BossData.Reload then pcall(function() BossData:Reload() end)
                elseif deps and deps.BossHelper and deps.BossHelper.Reload then pcall(function() deps.BossHelper:Reload() end)
                elseif BossHelper and BossHelper.Reload then pcall(function() BossHelper:Reload() end) end
                if rPanel and rPanel.Refresh then pcall(function() rPanel:Refresh() end) end
            end

            for i, lang in ipairs(languages) do
                local btn = CreateCustomButton(panel, 200, 26, lang.label)
                btn:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -((i - 1) * 26))
                btn:SetScript("OnClick", function()
                    SelectLanguage(i, true, true)
                    panel:Hide()
                    if dropdown.clickCatcher then dropdown.clickCatcher:Hide(); dropdown.activePanel = nil end
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
                end)
                table.insert(buttons, btn)
            end

            local startIndex = 1
            for i, lang in ipairs(languages) do
                if lang.key == currentLang then startIndex = i; break end
            end
            SelectLanguage(startIndex, false, false)

            if not dropdown.clickCatcher then
                local catcher = CreateFrame("Frame", nil, UIParent)
                catcher:SetAllPoints(UIParent)
                catcher:EnableMouse(true)
                catcher:Hide()
                catcher:SetFrameStrata("FULLSCREEN_DIALOG")
                catcher:SetFrameLevel(1999)
                catcher:SetScript("OnMouseDown", function(self)
                    if dropdown.activePanel and dropdown.activePanel:IsShown() then
                        dropdown.activePanel:Hide()
                        self:Hide()
                        dropdown.activePanel = nil
                        if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
                    end
                end)
                dropdown.clickCatcher = catcher
            end

            mainBtn:SetScript("OnClick", function()
                if deps and deps.BossHelper and deps.BossHelper.SafePlaySound then
                    deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds and deps.BossHelper.Sounds.NORMAL_BUTTON or 856)
                end
                if panel:IsShown() then
                    panel:Hide()
                    if dropdown.clickCatcher then dropdown.clickCatcher:Hide(); dropdown.activePanel = nil end
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
                else
                    panel:Show()
                    panel:SetFrameStrata("FULLSCREEN_DIALOG")
                    panel:SetFrameLevel(2000)
                    if dropdown.clickCatcher then
                        dropdown.clickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                        dropdown.clickCatcher:SetFrameLevel(1999)
                        dropdown.clickCatcher:Show()
                    end
                    dropdown.activePanel = panel
                    BossHelper.Anim.PlayDropdownOpen(panel)
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(math.pi) end
                end
            end)

            rPanel.languageDropdown = dropdown
        end

        -- Scale slider (below language dropdown)
        local scaleAnchor = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        scaleAnchor:SetPoint("TOPLEFT", rPanel.languageDropdown, "BOTTOMLEFT", 0, -18)
        scaleAnchor:SetText(Translate("SCALE_SLIDER_TITLE"))
        scaleAnchor:SetTextColor(0.9, 0.9, 0.9)

        rPanel._widgets = rPanel._widgets or {}
        if not rPanel._widgets.scaleSlider then
            local scaleSlider = CreateFrame("Slider", "BossHelperScaleSlider", rPanel, "OptionsSliderTemplate")
            scaleSlider:SetWidth(200)
            scaleSlider:SetHeight(20)
            scaleSlider:SetOrientation("HORIZONTAL")
            scaleSlider:SetMinMaxValues(0.5, 2.0)
            scaleSlider:SetValueStep(0.05)
            scaleSlider:SetObeyStepOnDrag(true)
            scaleSlider:SetValue(BossHelperDB and BossHelperDB.scale or 1.0)
            _G[scaleSlider:GetName().."Low"]:SetText("50%")
            _G[scaleSlider:GetName().."High"]:SetText("200%")
            _G[scaleSlider:GetName().."Text"]:SetText("")  -- label above instead
            _G[scaleSlider:GetName().."Low"]:SetTextColor(0.7, 0.7, 0.7)
            _G[scaleSlider:GetName().."High"]:SetTextColor(0.7, 0.7, 0.7)
            scaleSlider.valueText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            scaleSlider.valueText:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -2)
            scaleSlider.valueText:SetText(string.format("%.2f", scaleSlider:GetValue()))
            scaleSlider.tooltip = { Translate("SCALE_SLIDER_TITLE"), Translate("SCALE_TOOLTIP") }
            AttachTooltip(scaleSlider)
            scaleSlider:SetScript("OnValueChanged", function(self, value)
                if self.valueText then self.valueText:SetText(string.format("%.2f", value)) end
                if GameTooltip:IsOwned(self) then
                    GameTooltip:ClearLines()
                    GameTooltip:SetText(Translate("SCALE_SLIDER_TITLE"), 1, 0.82, 0)
                    GameTooltip:AddLine(string.format("%.2f", value), 1,1,1)
                    GameTooltip:Show()
                end
            end)
            scaleSlider:SetScript("OnMouseUp", function(self)
                local value = self:GetValue()
                if BossHelperDB then BossHelperDB.scale = value end
                if BossUI and BossUI.GetFrame then
                    local f = BossUI.GetFrame()
                    if f then f:SetScale(value) end
                end
            end)
            rPanel._widgets.scaleSlider = scaleSlider
        end
        local scaleSlider = rPanel._widgets.scaleSlider
        scaleSlider:SetParent(rPanel)
        scaleSlider:SetPoint("TOPLEFT", scaleAnchor, "BOTTOMLEFT", 0, -6)
        scaleSlider:Show()
        if scaleSlider.valueText then scaleSlider.valueText:Show() end
        W(scaleSlider)

        -- ==== RIGHT COLUMN: Behavior ==========================================
        local behHdr, behRule = AddSectionHeader(
            Translate("SETTINGS_BEHAVIOR_SECTION"), rPanel, "TOPLEFT", COL_R, TOP_Y, 220)

        BossHelperDB = BossHelperDB or {}

        -- 4 checkboxes, each 26px apart
        local cb1 = AddCheck(behRule, "TOPLEFT", 0, -12,
            Translate("ANIMATIONS_COMBT_TITLE"), Translate("ANIMATIONS_TOOLTIP"),
            BossHelperDB.allowAnimationsInCombat,
            function(v) BossHelperDB.allowAnimationsInCombat = v end)

        local cb2 = AddCheck(cb1, "TOPLEFT", 0, -26,
            Translate("CLOSE_WINDOW_TITLE"), Translate("CLOSE_WINDOW_TOOLTIP"),
            BossHelperDB.closeOnPost,
            function(v) BossHelperDB.closeOnPost = v end)

        local cb3 = AddCheck(cb2, "TOPLEFT", 0, -26,
            Translate("ESC_CLOSE_TITLE"), Translate("ESC_CLOSE_TOOLTIP"),
            BossHelperDB.allowEscClose or false,
            function(v)
                BossHelperDB.allowEscClose = v
                if BossUI and BossUI.GetFrame then
                    local f = BossUI.GetFrame()
                    if f then BossHelper:RegisterEscClose(f) end
                end
            end)

        AddCheck(cb3, "TOPLEFT", 0, -26,
            Translate("AUTO_OPEN_NOTES_TITLE"), Translate("AUTO_OPEN_NOTES_TOOLTIP"),
            BossHelperDB.autoOpenBossNotes ~= false,
            function(v) BossHelperDB.autoOpenBossNotes = v end)


        --------------------------------------------------------------------------------
        -- category Auto-Invite — single column layout
        --------------------------------------------------------------------------------
    elseif category == Translate("AUTO_INVITE_CATE") then

        local COL = 20
        local TOP = -50

        -- Section header
        local invHdr, invRule = AddSectionHeader(
            Translate("AUTO_INVITE_CATE"), rPanel, "TOPLEFT", COL, TOP, 240)

        -- Enable checkbox
        local cbInv = AddCheck(invRule, "TOPLEFT", 0, -12,
            Translate("AUTO_INVITE_TITLE"), Translate("AUTO_INVITE_TOOLTIP"),
            BossHelperDB and BossHelperDB.autoInviteEnabled,
            function(v) BossHelperDB.autoInviteEnabled = v end)

        -- Trigger word label + editbox
        local trigLbl = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        trigLbl:SetPoint("TOPLEFT", cbInv, "BOTTOMLEFT", 0, -16)
        trigLbl:SetText(Translate("TRIGGER_WORD_TITLE"))
        trigLbl:SetTextColor(0.9, 0.9, 0.9)

        local eb = W(CreateFrame("EditBox", nil, rPanel, "InputBoxTemplate"))
        eb:SetSize(180, 22)
        eb:SetPoint("TOPLEFT", trigLbl, "BOTTOMLEFT", 0, -4)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(50)
        eb:SetText(BossHelperDB and BossHelperDB.triggerWord or "invite!")
        eb.tooltip = Translate("TRIGGER_WORD_TOOLTIP")
        AttachTooltip(eb)
        eb:SetScript("OnEnterPressed", function(self)
            local txt = trim(self:GetText())
            if txt ~= "" then BossHelperDB.triggerWord = txt; Inviter.SetTrigger(txt) end
            self:ClearFocus()
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            local txt = trim(self:GetText())
            if txt ~= "" then BossHelperDB.triggerWord = txt; Inviter.SetTrigger(txt) end
        end)

        --------------------------------------------------------------------------------
        -- category Mini Window — two-column layout
        --   Left column (x=20):  Appearance section — transparency slider
        --   Right column (x=300): Options section   — 3 checkboxes
        --------------------------------------------------------------------------------
    elseif category == Translate("MINI_WINDOW_CATE") then

        local COL_L = 20
        local COL_R = 300
        local TOP_Y = -50

        -- ==== LEFT: Appearance ===============================================
        local appHdr, appRule = AddSectionHeader(
            Translate("SETTINGS_APPEARANCE_SECTION"), rPanel, "TOPLEFT", COL_L, TOP_Y, 240)

        local transLbl = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        transLbl:SetPoint("TOPLEFT", appRule, "BOTTOMLEFT", 0, -14)
        transLbl:SetText(Translate("MINI_WINDOW_TRANSPARENT_TITLE"))
        transLbl:SetTextColor(0.9, 0.9, 0.9)

        rPanel._widgets = rPanel._widgets or {}
        if not rPanel._widgets.miniTransparencySlider then
            local initVal = (BossHelperDB and tonumber(BossHelperDB.miniWindowTransparency)) or 0.95
            local sld = CreateFrame("Slider", "BossHelperMiniWindowTransparencySlider", rPanel, "OptionsSliderTemplate")
            sld:SetWidth(200)
            sld:SetHeight(20)
            sld:SetOrientation("HORIZONTAL")
            sld:SetMinMaxValues(0.0, 1.0)
            sld:SetValueStep(0.01)
            sld:SetObeyStepOnDrag(true)
            sld:SetValue(initVal)
            _G[sld:GetName().."Low"]:SetText("0%")
            _G[sld:GetName().."High"]:SetText("100%")
            _G[sld:GetName().."Text"]:SetText("")
            _G[sld:GetName().."Low"]:SetTextColor(0.7, 0.7, 0.7)
            _G[sld:GetName().."High"]:SetTextColor(0.7, 0.7, 0.7)
            sld.valueText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sld.valueText:SetPoint("TOP", sld, "BOTTOM", 0, -2)
            sld.valueText:SetText(string.format("%d%%", math.floor(sld:GetValue() * 100 + 0.5)))
            sld.tooltip = { Translate("MINI_WINDOW_TRANSPARENT_TITLE"), Translate("MINI_WINDOW_TRANSPARENT_TOOLTIP") }
            AttachTooltip(sld)
            sld:SetScript("OnValueChanged", function(self, value)
                if self.valueText then self.valueText:SetText(string.format("%d%%", math.floor(value * 100 + 0.5))) end
                if GameTooltip:IsOwned(self) then
                    GameTooltip:ClearLines()
                    GameTooltip:SetText(Translate("MINI_WINDOW_TRANSPARENT_TITLE"), 1, 0.82, 0)
                    GameTooltip:AddLine(string.format("%d%%", math.floor(value * 100 + 0.5)), 1,1,1)
                    GameTooltip:Show()
                end
            end)
            sld:SetScript("OnMouseUp", function(self)
                local v = tonumber(self:GetValue()) or 0
                BossHelperDB = BossHelperDB or {}
                BossHelperDB.miniWindowTransparency = v
                if MiniWindow and MiniWindow.ApplySettings then MiniWindow.ApplySettings() end
            end)
            rPanel._widgets.miniTransparencySlider = sld
        end

        local miniSlider = rPanel._widgets.miniTransparencySlider
        miniSlider:SetParent(rPanel)
        miniSlider:SetPoint("TOPLEFT", transLbl, "BOTTOMLEFT", 0, -6)
        miniSlider:Show()
        if miniSlider.valueText then miniSlider.valueText:Show() end
        W(miniSlider)

        -- Appearance checkboxes (below slider)
        local mCb1 = AddCheck(miniSlider, "TOPLEFT", 0, -30,
            Translate("MINI_WINDOW_NO_BORDER_TITLE"), Translate("MINI_WINDOW_NO_BORDER_TOOLTIP"),
            BossHelperDB and BossHelperDB.miniWindowNoBorder,
            function(v)
                BossHelperDB.miniWindowNoBorder = v
                if MiniWindow and MiniWindow.ApplySettings then MiniWindow.ApplySettings() end
            end)

        local mCb2 = AddCheck(mCb1, "TOPLEFT", 0, -26,
            Translate("MINI_WINDOW_HIDE_SEP_TITLE"), Translate("MINI_WINDOW_HIDE_SEP_TOOLTIP"),
            BossHelperDB and BossHelperDB.miniWindowHideSeparator,
            function(v)
                BossHelperDB.miniWindowHideSeparator = v
                if MiniWindow and MiniWindow.ApplySettings then MiniWindow.ApplySettings() end
            end)

        AddCheck(mCb2, "TOPLEFT", 0, -26,
            Translate("MINI_WINDOW_ICONS_ONLY_TITLE"), Translate("MINI_WINDOW_ICONS_ONLY_TOOLTIP"),
            BossHelperDB and BossHelperDB.miniWindowHideButtonChrome,
            function(v)
                BossHelperDB.miniWindowHideButtonChrome = v
                if MiniWindow and MiniWindow.ApplySettings then MiniWindow.ApplySettings() end
            end)

        -- ==== RIGHT: Behavior ================================================
        local behHdrMini, behRuleMini = AddSectionHeader(
            Translate("SETTINGS_BEHAVIOR_SECTION"), rPanel, "TOPLEFT", COL_R, TOP_Y, 220)

        AddCheck(behRuleMini, "TOPLEFT", 0, -12,
            Translate("MINI_WINDOW_AUTO_EXPAND_TITLE"), Translate("MINI_WINDOW_AUTO_EXPAND_TOOLTIP"),
            BossHelperDB and BossHelperDB.miniWindowAutoExpand,
            function(v)
                BossHelperDB.miniWindowAutoExpand = v
            end)

        --------------------------------------------------------------------------------
        -- category Key Tracker — two-column layout
        --   Left column (x=20):  Display section   — show/hide checkboxes
        --   Right column (x=300): Group Finder Panel appearance — slider + checkboxes
        --------------------------------------------------------------------------------
    elseif category == Translate("KEY_TRACKER_CATE") then

        local COL_L = 20
        local COL_R = 300
        local TOP_Y = -50

        BossHelperDB = BossHelperDB or {}

        -- ==== LEFT: Display =====================================================
        local dispHdr, dispRule = AddSectionHeader(
            Translate("KEY_TRACKER_SECTION"), rPanel, "TOPLEFT", COL_L, TOP_Y, 240)

        local cb1 = AddCheck(dispRule, "TOPLEFT", 0, -12,
            Translate("KEY_TRACKER_STARTPAGE_TITLE"), Translate("KEY_TRACKER_STARTPAGE_TOOLTIP"),
            BossHelperDB.showKeysOnStartPage ~= false,
            function(v)
                BossHelperDB.showKeysOnStartPage = v
                -- Live-opdater StartPage widget hvis det er synligt
                if rightPanel and rightPanel.keystoneWidget then
                    rightPanel.keystoneWidget:SetEnabled(v)
                end
            end)

        AddCheck(cb1, "TOPLEFT", 0, -26,
            Translate("KEY_TRACKER_GROUPFINDER_TITLE"), Translate("KEY_TRACKER_GROUPFINDER_TOOLTIP"),
            BossHelperDB.showKeysInGroupFinder ~= false,
            function(v)
                BossHelperDB.showKeysInGroupFinder = v
                -- Live-opdater Group Finder panelet med det samme
                if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.UpdateVisibility then
                    BossHelper.GroupFinderPanel.UpdateVisibility()
                end
            end)

        -- ==== RIGHT: Group Finder Panel appearance ==============================
        local gfHdr, gfRule = AddSectionHeader(
            Translate("KEY_TRACKER_GF_APPEARANCE"), rPanel, "TOPLEFT", COL_R, TOP_Y, 220)

        -- Background transparency label
        local gfTransLbl = W(rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        gfTransLbl:SetPoint("TOPLEFT", gfRule, "BOTTOMLEFT", 0, -14)
        gfTransLbl:SetText(Translate("KEY_TRACKER_GF_TRANSPARENT_TITLE"))
        gfTransLbl:SetTextColor(0.9, 0.9, 0.9)

        rPanel._widgets = rPanel._widgets or {}
        if not rPanel._widgets.gfTransparencySlider then
            local initVal = (BossHelperDB and tonumber(BossHelperDB.gfPanelTransparency)) or 0.95
            local sld = CreateFrame("Slider", "BossHelperGFTransparencySlider", rPanel, "OptionsSliderTemplate")
            sld:SetWidth(200)
            sld:SetHeight(20)
            sld:SetOrientation("HORIZONTAL")
            sld:SetMinMaxValues(0.0, 1.0)
            sld:SetValueStep(0.01)
            sld:SetObeyStepOnDrag(true)
            sld:SetValue(initVal)
            _G[sld:GetName().."Low"]:SetText("0%")
            _G[sld:GetName().."High"]:SetText("100%")
            _G[sld:GetName().."Text"]:SetText("")
            _G[sld:GetName().."Low"]:SetTextColor(0.7, 0.7, 0.7)
            _G[sld:GetName().."High"]:SetTextColor(0.7, 0.7, 0.7)
            sld.valueText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sld.valueText:SetPoint("TOP", sld, "BOTTOM", 0, -2)
            sld.valueText:SetText(string.format("%d%%", math.floor(initVal * 100 + 0.5)))
            sld.tooltip = { Translate("KEY_TRACKER_GF_TRANSPARENT_TITLE"), Translate("KEY_TRACKER_GF_TRANSPARENT_TOOLTIP") }
            AttachTooltip(sld)
            sld:SetScript("OnValueChanged", function(self, value)
                if self.valueText then self.valueText:SetText(string.format("%d%%", math.floor(value * 100 + 0.5))) end
                if GameTooltip:IsOwned(self) then
                    GameTooltip:ClearLines()
                    GameTooltip:SetText(Translate("KEY_TRACKER_GF_TRANSPARENT_TITLE"), 1, 0.82, 0)
                    GameTooltip:AddLine(string.format("%d%%", math.floor(value * 100 + 0.5)), 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            sld:SetScript("OnMouseUp", function(self)
                local v = tonumber(self:GetValue()) or 0
                BossHelperDB = BossHelperDB or {}
                BossHelperDB.gfPanelTransparency = v
                if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.ApplySettings then
                    BossHelper.GroupFinderPanel.ApplySettings()
                end
            end)
            rPanel._widgets.gfTransparencySlider = sld
        end
        local gfSlider = rPanel._widgets.gfTransparencySlider
        gfSlider:SetParent(rPanel)
        gfSlider:SetPoint("TOPLEFT", gfTransLbl, "BOTTOMLEFT", 0, -6)
        gfSlider:Show()
        if gfSlider.valueText then gfSlider.valueText:Show() end
        W(gfSlider)

        -- No border checkbox
        local gfCb1 = AddCheck(gfSlider, "TOPLEFT", 0, -30,
            Translate("KEY_TRACKER_GF_NO_BORDER_TITLE"), Translate("KEY_TRACKER_GF_NO_BORDER_TOOLTIP"),
            BossHelperDB and BossHelperDB.gfNoBorder,
            function(v)
                BossHelperDB.gfNoBorder = v
                if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.ApplySettings then
                    BossHelper.GroupFinderPanel.ApplySettings()
                end
            end)

        -- Hide title checkbox
        AddCheck(gfCb1, "TOPLEFT", 0, -26,
            Translate("KEY_TRACKER_GF_HIDE_TITLE_TITLE"), Translate("KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"),
            BossHelperDB and BossHelperDB.gfHideTitle,
            function(v)
                BossHelperDB.gfHideTitle = v
                if BossHelper.GroupFinderPanel and BossHelper.GroupFinderPanel.ApplySettings then
                    BossHelper.GroupFinderPanel.ApplySettings()
                end
            end)
    end
end

-- SelectSettingCategory (tracks left-button state in frame.settingsSelectedButton)
function BossSettings.SelectSettingCategory(frame,leftPanel,rightPanel, categoryName, btn, ctx)
    ctx = ctx or {}
    -- deselect previous
    if frame.settingsSelectedButton then
        pcall(frame.settingsSelectedButton.SetSelected, frame.settingsSelectedButton, false)
        frame.settingsSelectedButton = nil
    end
    if btn then
        pcall(btn.SetSelected, btn, true)
        frame.settingsSelectedButton = btn
    end

    -- clear some rightPanel chrome
    if rightPanel.logo then phide(rightPanel.logo) end
    if rightPanel.mainTitle then psettext(rightPanel.mainTitle, "") end
    if rightPanel.mainDesc then psettext(rightPanel.mainDesc, "") end
    if rightPanel.footerText then psettext(rightPanel.footerText, "") end
    if rightPanel.footerText2 then psettext(rightPanel.footerText2, "") end

    if not rightPanel.rightTitle then
        rightPanel.rightTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        rightPanel.rightTitle:SetPoint("TOP", rightPanel, "TOP", 0, -20)
        rightPanel.rightTitle:SetTextColor(1, 0.5, 0)
        rightPanel.rightTitle:SetJustifyH("CENTER")
    end
    psettext(rightPanel.rightTitle, categoryName)

    -- cleanup old widgets
    CleanupSettingsWidgets(rightPanel)

    -- rebuild
    BossSettings.BuildSettingsCategoryUI(rightPanel, categoryName, { CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton, BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB })
end

-- ShowSettings (ctx must include: frame,leftPanel,rightPanel,backButton,CreateCustomButton)
function BossSettings.ShowSettings(ctx)
    ctx = ctx or {}
    -- copy some deps if supplied
    if ctx.CreateCustomButton then deps.CreateCustomButton = ctx.CreateCustomButton end
    if ctx.BossHelper then deps.BossHelper = ctx.BossHelper end
    if ctx.BossHelperDB then deps.BossHelperDB = ctx.BossHelperDB end

    local frame = ctx.frame
    local leftPanel = ctx.leftPanel
    local rightPanel = ctx.rightPanel

    BossHelper.UI.hide(rightPanel and rightPanel.discordButton)
    BossHelper.UI.hide(rightPanel and rightPanel.githubButton)
    BossHelper.UI.hide(rightPanel and rightPanel.bugReportButton)
    local backButton = ctx.backButton
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

    if not (frame and leftPanel and rightPanel and CreateCustomButton) then
        print("|cffFF4500[BossSettings]|r Missing context for ShowSettings()")
        return
    end

    frame.currentMode = "settings"
    frame.selectedBoss = nil
    frame.currentDungeon = nil

    -- hide dropdowns/catchers if present
    if rightPanel.phaseDropdown then phide(rightPanel.phaseDropdown) end
    if rightPanel.dropdownClickCatcher then phide(rightPanel.dropdownClickCatcher) end

    -- hide/clear short buttons & text on right panel
    if rightPanel.shortBtnScroll then phide(rightPanel.shortBtnScroll) end
    if rightPanel.shortBtnContent then pcall(rightPanel.shortBtnContent.SetHeight, rightPanel.shortBtnContent, 1) end
    if rightPanel.shortButtons then
        for _, b in ipairs(rightPanel.shortButtons) do
            if b then
                phide(b)
                psetparent(b, nil)
            end
        end
    end
    rightPanel.shortButtons = {}

    psettext(rightPanel.rightTitle, Translate("SETTINGS"))
    if rightPanel.rightShortText then psettext(rightPanel.rightShortText, "") end
    if rightPanel.rightDetailText then psettext(rightPanel.rightDetailText, "") end

    -- Set left panel title
    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText(Translate("SETTINGS") or "Settings")
    end

    -- clear old left buttons
    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then phide(btn.icon) end
            phide(btn)
            psetparent(btn, nil)
        end
    end
    frame.bossButtons = {}

    -- define your settings categories
    local categories = { 
        Translate("GENERAL_CATE"), 
        Translate("AUTO_INVITE_CATE"),
        Translate("MINI_WINDOW_CATE"),
        Translate("KEY_TRACKER_CATE"),
    }
    --local categories = { "General", "Auto-Invite", "Notifications", "Profile", "Advanced" }

    local y = -39  -- Align with rightPanel content at -39
    for _, cat in ipairs(categories) do
        local btn = (CreateCustomButton)(leftPanel, 180, 30, cat)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn:SetScript("OnClick", function()
            BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, cat, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
            psafesound(856)
        end)
    table.insert(frame.bossButtons, btn)
    y = y - 35
    end

    if backButton then backButton:Show() end

    -- initial view: select first category
    if #frame.bossButtons > 0 then
        local first = frame.bossButtons[1]
        BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, categories[1], first, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
    end
end

return BossSettings
