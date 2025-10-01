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

function BossSettings.Init(d)
    if not d then return end
    for k,v in pairs(d) do deps[k] = v end
end

local function phide(obj)
    if not obj then return end
    pcall(function() if obj.Hide then obj:Hide() end end)
end
local function psetparent(obj, p)
    if not obj then return end
    pcall(function() if obj.SetParent then obj:SetParent(p) end end)
end
local function pclearpoints(obj)
    if not obj then return end
    pcall(function() if obj.ClearAllPoints then obj:ClearAllPoints() end end)
end
local function psettext(obj, txt)
    if not obj then return end
    pcall(function() if obj.SetText then obj:SetText(txt) end end)
end
local function psafesound(sid)
    pcall(function()
        if deps.BossHelper and deps.BossHelper.SafePlaySound then deps.BossHelper:SafePlaySound(sid) end
    end)
end

-- Cleanup helper for rightPanel settings widgets
local function CleanupSettingsWidgets(rPanel)
    if not rPanel or not rPanel.settingsWidgets then return end
    for _, w in ipairs(rPanel.settingsWidgets) do
        if w then
            phide(w)
            psetparent(w, nil)
            pclearpoints(w)
        end
    end
    rPanel.settingsWidgets = nil
end

local function AddSpacer(height)
    last = { offset = (last and last.offset or 0) - (height or 20) }
end

-- Tooltip helper: sæt obj.tooltip = "tekst" eller {"Title", "line1", "line2"}
local function AttachTooltip(obj)
    if not obj then return end
    -- sørg for at objektet kan modtage mouse events
    if obj.EnableMouse then obj:EnableMouse(true) end

    -- brug HookScript så vi ikke overskriver andre scripts
    obj:HookScript("OnEnter", function(self)
        local tip = self.tooltip or self._tooltip
        if not tip then return end
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if type(tip) == "table" then
            GameTooltip:SetText(tip[1], 1, 0.82, 0)
            for i = 2, #tip do
                GameTooltip:AddLine(tip[i], 1, 1, 1, true)
            end
        else
            GameTooltip:SetText(tip)
        end
        -- if object has GetValue (e.g. slider), show current value
        if self.GetValue then
            local ok, val = pcall(self.GetValue, self)
            if ok and val ~= nil then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(Translate("CURRENT_SCALE_TOOLTIP") .. " " .. tostring(val), 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end)

    obj:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end



-- BuildSettingsCategoryUI (tilstræbt at matche tidligere logik)
function BossSettings.BuildSettingsCategoryUI(rPanel, category, ctx)
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
    local BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB

    local startX, startY = 20, -60
    local last = nil

    local function AddCheck(name, tooltip, initial)
        local cb = CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate")
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText(name)
        cb.tooltip = tooltip
        AttachTooltip(cb)
        if initial ~= nil then pcall(cb.SetChecked, cb, initial) end

        if last then
            cb:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + last.offset)
        else
            cb:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY)
        end

        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, cb)
        last = { offset = (last and last.offset or 0) - 30 }
    end

    local function AddLabel(text)
        local lbl = rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + (last and last.offset or 0))
        lbl:SetText(text)
        lbl:SetJustifyH("LEFT")
        lbl:SetWidth(520)

         -- overlay frame so label can get hover
        local hit = CreateFrame("Frame", nil, rPanel)
        hit:SetSize(520, lbl:GetStringHeight() or 16)
        hit:SetPoint("TOPLEFT", lbl, "TOPLEFT", 0, 0)
        hit.tooltip = nil -- set if you want a general tooltip for labels
        -- if you want label text as tooltip automatically uncomment:
        -- hit.tooltip = text
        AttachTooltip(hit)
        table.insert(rPanel.settingsWidgets, hit)   

        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, lbl)
        last = { offset = (last and last.offset or 0) - 20 }
    end


        --------------------------------------------------------------------------------
        -- category General
        --------------------------------------------------------------------------------
    if category == Translate("GENERAL_CATE") then
        --------------------------------------------------------------------------------
        -- Language selection (custom drop-down som PhaseDropdown)
        --------------------------------------------------------------------------------
        do
            local BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB or {}
            local currentLang = BossHelperDB.language or "enUS"

            local languages = {
                { key = "enUS", label = "English" },
                { key = "daDK", label = "Danish" },
                { key = "ruRU", label = "Russian" },
                { key = "deDE", label = "German" },
                
            }

            local function CreateLanguageDropdown(parent, startX, startY, last)
                local dropdown = CreateFrame("Frame", "BossHelperLanguageDropdown", parent, "BackdropTemplate")
                dropdown:SetSize(200, 26)
                dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", (startX or 10) + 5, (startY or -10) + (last and last.offset or 0))

                -- Main-knap (viser aktuelt valgt sprog)
                local initialLabel = (currentLang == "enUS") and "English" or "Danish" or "Russian" or "German"
                local mainBtn = CreateCustomButton(dropdown, 200, 26, initialLabel)
                mainBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
                mainBtn.tooltip = {
                    Translate("LANGUAGE_TOOLTIP_1"),
                    Translate("LANGUAGE_TOOLTIP_2")
                }
                AttachTooltip(mainBtn)

                -- Panel med sprog-knapper
                local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
                panel:SetSize(200, #languages * 26)
                panel:SetPoint("TOPLEFT", mainBtn, "BOTTOMLEFT", 0, -2)
                panel:Hide()
                panel:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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

                -- SelectLanguage: tager ansvar for at gemme, opdatere UI, spille lyd og genindlæse data
                local function SelectLanguage(index, playSound, showNotice)
                    local lang = languages[index]
                    if not lang then return end

                    -- Gem i SavedVariables
                    BossHelperDB.language = lang.key
                    currentLang = lang.key

                    -- Opdater runtime locales hvis de findes
                    if deps and deps.BossHelper then deps.BossHelper.selectedLocale = lang.key end
                    if BossHelper then BossHelper.selectedLocale = lang.key end

                    -- Marker korrekt knap (afhængigt af CreateCustomButton API)
                    for i, btn in ipairs(buttons) do
                        if btn.SetSelected then
                            btn:SetSelected(i == index)
                        else
                            -- fallback: just change the text style if SetSelected isn't available
                            if i == index then
                                btn:SetText("|cff00ff00" .. btn:GetText() .. "|r")
                            else
                                btn:SetText(languages[i].label)
                            end
                        end
                    end

                    -- Opdater main-knap tekst
                    mainBtn:SetText(lang.label)

                    -- Opret reload-label én gang (skjult som standard)
                    if not dropdown.reloadLabel then
                        dropdown.reloadLabel = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        dropdown.reloadLabel:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)
                        dropdown.reloadLabel:SetTextColor(1, 0.2, 0.2)
                        dropdown.reloadLabel:Hide()
                    end

                    -- Vis notice hvis vi ønsker det (typisk ved brugerklik)
                    if showNotice then
                        dropdown.reloadLabel:SetText(Translate("/RELOAD_TEXT"))
                        dropdown.reloadLabel:Show()
                        -- Skjul automatisk efter 10 sekunder
                        C_Timer.After(10, function()
                            if dropdown.reloadLabel and dropdown.reloadLabel.Hide then
                                dropdown.reloadLabel:Hide()
                            end
                        end)
                    end

                    -- Spil lyd hvis bedt om det
                    if playSound and deps and deps.BossHelper and deps.BossHelper.SafePlaySound then
                        deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds and deps.BossHelper.Sounds.NORMAL_BUTTON or 856)
                    end

                    -- GENINDLÆS boss-data / taktik, så UI opdateres uden krævet /reload
                    if BossData and BossData.Reload then
                        pcall(function() BossData:Reload() end)
                    elseif deps and deps.BossHelper and deps.BossHelper.Reload then
                        pcall(function() deps.BossHelper:Reload() end)
                    elseif BossHelper and BossHelper.Reload then
                        pcall(function() BossHelper:Reload() end)
                    end

                    -- Ekstra: opdatér settings-panel hvis det har en Refresh/metode
                    if parent and parent.Refresh then
                        pcall(function() parent:Refresh() end)
                    elseif rPanel and rPanel.Refresh then
                        pcall(function() rPanel:Refresh() end)
                    end
                end

                -- Opret knapper i dropdown-panelet
                for i, lang in ipairs(languages) do
                    local btn = CreateCustomButton(panel, 200, 26, lang.label)
                    btn:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -((i - 1) * 26))
                    btn:SetScript("OnClick", function()
                        -- Vi lader SelectLanguage spille lyden og vise notice
                        SelectLanguage(i, true, true)
                        panel:Hide()
                        if parent.dropdownClickCatcher then
                            parent.dropdownClickCatcher:Hide()
                            parent.dropdownActivePanel = nil
                        end
                    end)
                    table.insert(buttons, btn)
                end

                -- Start med korrekt valgt knap (init uden at vise /reload besked)
                local startIndex = 1
                for i, lang in ipairs(languages) do
                    if lang.key == currentLang then
                        startIndex = i
                        break
                    end
                end
                SelectLanguage(startIndex, false, false) -- init: no sound, no notice

                -- Click-catcher, så vi kan lukke dropdown når man klikker udenfor
                if not parent.dropdownClickCatcher then
                    local catcher = CreateFrame("Frame", "BossHelper_DropdownClickCatcher", UIParent)
                    catcher:SetAllPoints(UIParent)
                    catcher:EnableMouse(true)
                    catcher:Hide()
                    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
                    catcher:SetFrameLevel(1999)
                    catcher:SetScript("OnMouseDown", function(self)
                        if parent.dropdownActivePanel and parent.dropdownActivePanel:IsShown() then
                            parent.dropdownActivePanel:Hide()
                            self:Hide()
                            parent.dropdownActivePanel = nil
                        end
                    end)
                    parent.dropdownClickCatcher = catcher
                end

                -- Main-knap toggler panel
                mainBtn:SetScript("OnClick", function()
                    if deps and deps.BossHelper and deps.BossHelper.SafePlaySound then
                        deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds and deps.BossHelper.Sounds.NORMAL_BUTTON or 856)
                    end
                    if panel:IsShown() then
                        panel:Hide()
                        if parent.dropdownClickCatcher then
                            parent.dropdownClickCatcher:Hide()
                            parent.dropdownActivePanel = nil
                        end
                    else
                        panel:Show()
                        panel:SetFrameStrata("FULLSCREEN_DIALOG")
                        panel:SetFrameLevel(2000)
                        if parent.dropdownClickCatcher then
                            parent.dropdownClickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                            parent.dropdownClickCatcher:SetFrameLevel(1999)
                            parent.dropdownClickCatcher:Show()
                        end
                        parent.dropdownActivePanel = panel

                        -- PRÆCIS samme animation som PhaseDropdown hvis vi har det
                        local ag = panel:CreateAnimationGroup()
                        local t = ag:CreateAnimation("Translation")
                        t:SetOffset(0, 6)
                        t:SetDuration(0.12)
                        t:SetSmoothing("OUT")
                        local a = ag:CreateAnimation("Alpha")
                        a:SetFromAlpha(0)
                        a:SetToAlpha(1)
                        a:SetDuration(0.12)
                        if ShouldAnimateInCombat and ShouldAnimateInCombat() then
                            ag:Play()
                        end
                    end
                end)

                return dropdown
            end

            -- Gem dropdown som settings-widget
            rPanel.settingsWidgets = rPanel.settingsWidgets or {}
            rPanel.languageDropdown = CreateLanguageDropdown(rPanel, startX, startY, last)
            table.insert(rPanel.settingsWidgets, rPanel.languageDropdown)

            -- så label over dropdown
            local langLabel = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            langLabel:SetParent(rPanel)
            langLabel:SetTextColor(1, 0.82, 0)
            langLabel:SetText(Translate("SELECT_LANGUAGE_TITLE"))
            langLabel:SetJustifyH("CENTER")
            langLabel:SetWidth(200)
            langLabel:SetHeight(20)
            langLabel:SetPoint("BOTTOM", rPanel.languageDropdown, "TOP", 0, 2)
            langLabel:Show()

            table.insert(rPanel.settingsWidgets, langLabel)

            -- Opdater offset under dropdown
            last = { offset = (last and last.offset or 0) - 45 } -- lidt ekstra plads under dropdown
        end



        --------------------------------------------------------------------------------
        -- thin gray separator
        --------------------------------------------------------------------------------
        local sep = rPanel:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(0.5, 0.5, 0.5, 0.5) -- gray line
        sep:SetSize(200, 1)
        sep:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX + 5, startY + (last and last.offset or 0))
        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, sep)

        last = { offset = (last and last.offset or 0) - 20 } -- a bit extra spacing

        --------------------------------------------------------------------------------
        -- Scale slider
        --------------------------------------------------------------------------------
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

            -- Text on slider
            _G[scaleSlider:GetName().."Low"]:SetText("50%")
            _G[scaleSlider:GetName().."High"]:SetText("200%")
            _G[scaleSlider:GetName().."Text"]:SetText(Translate("SCALE_SLIDER_TITLE"))
            _G[scaleSlider:GetName().."Text"]:SetTextColor(1, 0.82, 0)
            _G[scaleSlider:GetName().."Low"]:SetTextColor(1, 0.82, 0)
            _G[scaleSlider:GetName().."High"]:SetTextColor(1, 0.82, 0)


            -- Value text below slider
            scaleSlider.valueText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            scaleSlider.valueText:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -2)
            scaleSlider.valueText:SetText(string.format("%.1f", scaleSlider:GetValue()))

            -- Tooltip for slider
            scaleSlider.tooltip = { 
                Translate("SCALE_SLIDER_TITLE"),
                Translate("SCALE_TOOLTIP") 
            }
            AttachTooltip(scaleSlider)

            -- Update text when slider changes
            scaleSlider:SetScript("OnValueChanged", function(self, value)
                if self.valueText then
                    self.valueText:SetText(string.format("%.2f", value))
                end
                -- refresh tooltip if open and owned by this slider
                if GameTooltip:IsOwned(self) then
                    GameTooltip:ClearLines()
                    GameTooltip:SetText("Addon Scale", 1, 0.82, 0)
                    GameTooltip:AddLine(string.format("%.2f", value), 1,1,1)
                    GameTooltip:Show()
                end
            end)


            -- Save value and change UI scale
            scaleSlider:SetScript("OnMouseUp", function(self)
                local value = self:GetValue()
                if BossHelperDB then
                    BossHelperDB.scale = value
                end
                if BossUI and BossUI.GetFrame then
                    local f = BossUI.GetFrame()
                    if f then f:SetScale(value) end
                end
            end)

            -- Save reference for reuse
            rPanel._widgets.scaleSlider = scaleSlider
        end

        -- Place and show slider each time UI is built
        local scaleSlider = rPanel._widgets.scaleSlider
        scaleSlider:SetParent(rPanel)
        scaleSlider:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX + 5, startY + (last and last.offset or 0) - 10)
        scaleSlider:Show()
        if scaleSlider.valueText then scaleSlider.valueText:Show() end

        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, scaleSlider)

        last = { offset = (last and last.offset or 0) - 75 }

        --------------------------------------------------------------------------------
        -- thin gray separator
        --------------------------------------------------------------------------------
        --local sep = rPanel:CreateTexture(nil, "ARTWORK")
        --sep:SetColorTexture(0.5, 0.5, 0.5, 0.5) -- gray line
        --sep:SetSize(215, 1)
        --sep:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + (last and last.offset or 0))
        --rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        --table.insert(rPanel.settingsWidgets, sep)

        --last = { offset = (last and last.offset or 0) - 20 } -- a bit extra spacing

        --------------------------------------------------------------------------------
        -- Allow animations in combat (checkbox)
        --------------------------------------------------------------------------------
        do
            local initial = false
            if BossHelperDB and BossHelperDB.allowAnimationsInCombat then initial = true end

            local cb_anim = CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate")
            cb_anim.text = cb_anim:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cb_anim.text:SetPoint("LEFT", cb_anim, "RIGHT", 4, 0)
            cb_anim.text:SetText(Translate("ANIMATIONS_TOOLTIP"))
            cb_anim.tooltip = Translate("ANIMATIONS_TOOLTIP")
            AttachTooltip(cb_anim)
            cb_anim:SetChecked(initial)

            if last then
                cb_anim:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + last.offset)
            else
                cb_anim:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY)
            end

            -- Save chosen state directly in savedvars when user clicks
            cb_anim:SetScript("OnClick", function(self)
                BossHelperDB = BossHelperDB or {}
                BossHelperDB.allowAnimationsInCombat = self:GetChecked() and true or false
                -- optional sound/feedback
                if deps.BossHelper and deps.BossHelper.SafePlaySound then
                    deps.BossHelper:SafePlaySound(856)
                end
            end)

            rPanel.settingsWidgets = rPanel.settingsWidgets or {}
            table.insert(rPanel.settingsWidgets, cb_anim)
            last = { offset = (last and last.offset or 0) - 30 }
        end

        --------------------------------------------------------------------------------
        -- Close window on Post (checkbox)
        --------------------------------------------------------------------------------
        do
            local initial = false
            if BossHelperDB and BossHelperDB.closeOnPost then initial = true end

            local cb_close = CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate")
            cb_close.text = cb_close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cb_close.text:SetPoint("LEFT", cb_close, "RIGHT", 4, 0)
            cb_close.text:SetText(Translate("CLOSE_WINDOW_TITLE"))
            cb_close.tooltip = Translate("CLOSE_WINDOW_TOOLTIP")
            AttachTooltip(cb_close)
            cb_close:SetChecked(initial)

            if last then
                cb_close:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + last.offset)
            else
                cb_close:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY)
            end

            cb_close:SetScript("OnClick", function(self)
                BossHelperDB = BossHelperDB or {}
                BossHelperDB.closeOnPost = self:GetChecked() and true or false
                if deps.BossHelper and deps.BossHelper.SafePlaySound then deps.BossHelper:SafePlaySound(856) end
            end)

            rPanel.settingsWidgets = rPanel.settingsWidgets or {}
            table.insert(rPanel.settingsWidgets, cb_close)
            last = { offset = (last and last.offset or 0) - 30 }
        end

        --------------------------------------------------------------------------------
        -- Allow ESC to close BossHelper window (checkbox)
        --------------------------------------------------------------------------------
        do
            BossHelperDB = BossHelperDB or {}
            local initial = BossHelperDB.allowEscClose or false

            local cb_esc = CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate")
            cb_esc.text = cb_esc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cb_esc.text:SetPoint("LEFT", cb_esc, "RIGHT", 4, 0)
            cb_esc.text:SetText(Translate("ESC_CLOSE_TITLE"))
            cb_esc.tooltip = Translate("ESC_CLOSE_TOOLTIP")
            AttachTooltip(cb_esc)
            cb_esc:SetChecked(initial)

            if last then
                cb_esc:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + last.offset)
            else
                cb_esc:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY)
            end

            -- Når spilleren ændrer setting
            cb_esc:SetScript("OnClick", function(self)
                BossHelperDB.allowEscClose = self:GetChecked()

                -- Opdater framen med det samme
                if BossUI and BossUI.GetFrame then
                    local f = BossUI.GetFrame()
                    if f then
                        BossHelper:RegisterEscClose(f)
                    end
                end

                if deps.BossHelper and deps.BossHelper.SafePlaySound then
                    deps.BossHelper:SafePlaySound(856)
                end
            end)

            rPanel.settingsWidgets = rPanel.settingsWidgets or {}
            table.insert(rPanel.settingsWidgets, cb_esc)
            last = { offset = (last and last.offset or 0) - 30 }

            
end


        --------------------------------------------------------------------------------
        -- category Auto-Invite
        --------------------------------------------------------------------------------
    elseif category == Translate("AUTO_INVITE_CATE") then

        --------------------------------------------------------------------------------
        -- Enable/disable Auto-Invite
        --------------------------------------------------------------------------------
        local cb = CreateFrame("CheckButton", nil, rPanel, "UICheckButtonTemplate")
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText(Translate("AUTO_INVITE_TITLE"))
        cb:SetChecked(BossHelperDB and BossHelperDB.autoInviteEnabled)
        cb.tooltip = Translate("AUTO_INVITE_TOOLTIP")
        AttachTooltip(cb)


        if last then
            cb:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + last.offset)
        else
            cb:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY)
        end

        cb:SetScript("OnClick", function(self)
            BossHelperDB.autoInviteEnabled = self:GetChecked()
        end)

        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, cb)
        last = { offset = (last and last.offset or 0) - 50 }

        --------------------------------------------------------------------------------
        -- Trigger word input
        --------------------------------------------------------------------------------
        local function AddEditBox(labelText, initialText, callback)
            local lbl = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX + 5, startY + (last and last.offset or 0))
            lbl:SetText(labelText)

            local eb = CreateFrame("EditBox", nil, rPanel, "InputBoxTemplate")
            eb:SetSize(160, 20)
            eb:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -5)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(50)
            eb:SetText(initialText or "")
            eb.tooltip = Translate("TRIGGER_WORD_TOOLTIP")
            AttachTooltip(eb)

            eb:SetScript("OnEnterPressed", function(self)
                if callback then callback(self:GetText():trim()) end
                self:ClearFocus()
            end)
            eb:SetScript("OnEditFocusLost", function(self)
                if callback then callback(self:GetText():trim()) end
            end)

            rPanel.settingsWidgets = rPanel.settingsWidgets or {}
            table.insert(rPanel.settingsWidgets, lbl)
            table.insert(rPanel.settingsWidgets, eb)

            last = { offset = (last and last.offset or 0) - 40 }
            return eb
        end

        local triggerBox = AddEditBox(Translate("TRIGGER_WORD_TITLE"), BossHelperDB and BossHelperDB.triggerWord or "invite!", function(txt)
            if txt ~= "" then
                BossHelperDB.triggerWord = txt
                _G.triggerWord = txt
                Inviter.SetTrigger(txt)
            end
        end)

        --------------------------------------------------------------------------------
        -- category Notifications
        --------------------------------------------------------------------------------
    --elseif category == "Notifications" then
    --    AddLabel("Notification options:")
    --    AddCheck("Announce tactics to party", "Sender taktikker til gruppen.", true)
    --    AddCheck("Use raid warning", "Brug raid warning i stedet for chat.", false)


        --------------------------------------------------------------------------------
        -- category Profile
        --------------------------------------------------------------------------------
    --elseif category == "Profile" then
    --    AddLabel("Profile options:")
    --    local info = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --    info:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + (last and last.offset or 0))
    --    info:SetText("Current profile: Default (Work in Progress).")
    --    rPanel.settingsWidgets = rPanel.settingsWidgets or {}
    --    table.insert(rPanel.settingsWidgets, info)
    --    last = { offset = (last and last.offset or 0) - 30 }

        --------------------------------------------------------------------------------
        -- category Advanced
        --------------------------------------------------------------------------------
    --elseif category == "Advanced" then
    --    AddLabel("Advanced / debug options:")
    --    AddCheck("Enable debug logging", "Log mere info til fejlretning.", false)
--
    --    local dumpBtn = (CreateCustomButton or deps.CreateCustomButton)(rPanel, 160, 30, "Dump SavedVars")
    --    dumpBtn:SetPoint("TOPLEFT", rPanel, "TOPLEFT", startX, startY + (last and last.offset or 0) - 30)
    --    dumpBtn:SetScript("OnClick", function()
    --        print("|cffFF4500[BossHelper]|r SavedVars dump:")
    --        if deps.BossHelperDB then
    --            print("BossHelperDB:")
    --            Print(deps.BossHelperDB)
    --        else
    --            Print("No BossHelperDB available")
    --        end
    --    end)
    --    rPanel.settingsWidgets = rPanel.settingsWidgets or {}
    --    table.insert(rPanel.settingsWidgets, dumpBtn)
    --    last = { offset = (last and last.offset or 0) - 40 }
    end

        --------------------------------------------------------------------------------
        -- Footer
        --------------------------------------------------------------------------------
    --local footer = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    --footer:SetPoint("BOTTOMLEFT", rPanel, "BOTTOMLEFT", 10, 10)
    --footer:SetText("Tip: changes are not saved in this example - add savedvar-updates in callbacks.")
    --rPanel.settingsWidgets = rPanel.settingsWidgets or {}
    --table.insert(rPanel.settingsWidgets, footer)
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

    psettext(rightPanel.rightTitle, "Settings")
    if rightPanel.rightShortText then psettext(rightPanel.rightShortText, "") end
    if rightPanel.rightDetailText then psettext(rightPanel.rightDetailText, "") end

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
        Translate("AUTO_INVITE_CATE")
    }
    --local categories = { "General", "Auto-Invite", "Notifications", "Profile", "Advanced" }

    local y = -20
    for _, cat in ipairs(categories) do
        local btn = (CreateCustomButton)(leftPanel, 180, 30, cat)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn:SetScript("OnClick", function()
            BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, cat, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
            psafesound(856)
        end)
        table.insert(frame.bossButtons, btn)
        y = y - 40
    end

    if backButton then backButton:Show() end

    -- initial view: select first category
    if #frame.bossButtons > 0 then
        local first = frame.bossButtons[1]
        BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, categories[1], first, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
    end
end

return BossSettings
