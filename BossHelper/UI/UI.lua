-- BossUI.lua
-- Alt UI-kode; forventer at BossHelper, BossData og ShowStartPage(frame, rightPanel) er tilgængelige

BossUI = {}

local frame, leftPanel, rightPanel, backButton
local selectedButton = nil
local currentDungeon = nil
local currentLeftCategory = "dungeons" -- track left category (dungeons|affixes)

-- Helper: return the BossData key matching the player's current instance, or nil
local function GetCurrentDungeonKey()
    if not GetInstanceInfo then return nil end
    local instanceName, instanceType = GetInstanceInfo()
    if not instanceName or instanceName == "" or instanceType == "none" then return nil end
    local order = BossData and BossData.DungeonOrder
    if not order then return nil end
    for _, key in ipairs(order) do
        local data = BossData[key]
        if type(data) == "table" then
            -- Match via EJ instanceID (foretrukket) når ID er sat
            if data.instanceID and data.instanceID > 0 then
                local ejName = BossHelper:GetDungeonName(data.instanceID)
                if ejName == instanceName then return key end
            end
        end
    end
    -- Fallback: match by dungeon string key when instanceID is not yet set
    for _, key in ipairs(order) do
        local data = BossData[key]
        if type(data) == "table" and not (data.instanceID and data.instanceID > 0) then
            if key == instanceName then return key end
        end
    end
    return nil
end

-- Helper to hide affix view completely when navigating away
local function HideAffixesView()
    if rightPanel and rightPanel.affixScroll and rightPanel.affixScroll:IsShown() then
        rightPanel.affixScroll:Hide()
        if rightPanel.rightTitle and currentLeftCategory == "affixes" then
            rightPanel.rightTitle:SetText("")
        end
    end
    if leftPanel and leftPanel.affixButton then
        leftPanel.affixButton.isAffixActive = false
        leftPanel.affixButton:SetSelected(false)
    end
    if currentLeftCategory == "affixes" then
        currentLeftCategory = "dungeons"
    end
    if BossHelperDB and BossHelperDB.lastOpenPanel == "affixes" then
        BossHelperDB.lastOpenPanel = nil
    end
end
--Anderts: forward declaration
local BuildShortLineButtons  -- forward declaration
local ShowSettings, SelectSettingCategory, BuildSettingsCategoryUI
-- Forward: General Notes wrappers
local ShowGeneralNotes, SelectNotesCategory
-- Forward: Boss Note panel slide animationer
local OpenBossNotePanel, CloseBossNotePanel
-- Forward: Settings Info panel slide animationer
local OpenSettingsInfoPanel, CloseSettingsInfoPanel

-- BossHelper.Sounds og SafePlaySound er defineret centralt i BossHelper.lua


local function ClearRightPanelSettings()
    if not rightPanel then return end
    if rightPanel.settingsWidgets then
        for _, w in ipairs(rightPanel.settingsWidgets) do
            BossHelper.UI.destroyWidget(w)
        end
        rightPanel.settingsWidgets = nil
    end
    BossHelper.UI.hide(rightPanel.BossSettingsFrame)
    BossHelper.UI.hide(rightPanel.settingsScroll)
    BossHelper.UI.hide(rightPanel.infoScrollFrame)
    rightPanel.selectedPhaseIndex = nil
end

-- Clear widgets created by GeneralNotes page
local function ClearRightPanelNotes()
    if not rightPanel then return end
    for _, key in ipairs({"notesWidgets", "_noteButtons"}) do
        if rightPanel[key] then
            for _, w in ipairs(rightPanel[key]) do BossHelper.UI.destroyWidget(w) end
            rightPanel[key] = nil
        end
    end
    if rightPanel._notesInput then
        BossHelper.UI.destroyWidget(rightPanel._notesInput)
        rightPanel._notesInput = nil
    end
end

-- Helper: ryd alt generisk indhold fra rightPanel
local function ClearRightPanelContent(rPanel)
    if not rPanel then return end
    BossHelper.UI.hide(rPanel.logo)
    BossHelper.UI.setText(rPanel.mainTitle, "")
    BossHelper.UI.setText(rPanel.mainDesc, "")
    BossHelper.UI.setText(rPanel.footerText, "")
    BossHelper.UI.setText(rPanel.footerText2, "")
    BossHelper.UI.setText(rPanel.rightTitle, "")
    BossHelper.UI.hide(rPanel.rightShortScroll)
    BossHelper.UI.hide(rPanel.shortBtnScroll)
    BossHelper.UI.setText(rPanel.rightShortText, "")
    BossHelper.UI.setText(rPanel.rightDetailText, "")
    BossHelper.UI.hide(rPanel.rightDetailScroll)
    rPanel.showingDetails = false
    for _, key in ipairs({"detailToggle","postButton","bossNoteButton","discordButton","githubButton","bugReportButton"}) do
        BossHelper.UI.hide(rPanel[key])
    end
    if rPanel.keystoneWidget then rPanel.keystoneWidget:SetVisible(false) end
end

local function HideSocialButtons()
    BossHelper.UI.hide(rightPanel and rightPanel.discordButton)
    BossHelper.UI.hide(rightPanel and rightPanel.githubButton)
    BossHelper.UI.hide(rightPanel and rightPanel.bugReportButton)
end

local function ShowSocialButtons()
    if not rightPanel then return end
    if rightPanel.discordButton then rightPanel.discordButton:Show() end
    if rightPanel.githubButton  then rightPanel.githubButton:Show()  end
    if rightPanel.bugReportButton then rightPanel.bugReportButton:Show() end
end

-- Animeret slide ind (venstre → fuld bredde) for Boss Note panelet
OpenBossNotePanel = function(animated)
    if not frame or not frame.bossNotePanel then return end
    local bnp  = frame.bossNotePanel
    local anim = BossHelper.Anim
    if bnp._widthTween then bnp._widthTween.running = false end
    local fullW = bnp._fullWidth or 200
    if animated and anim and anim.AnimateWidth and anim.ShouldAnimate() then
        bnp:SetWidth(0)
        bnp:Show()
        anim.AnimateWidth(bnp, 0, fullW, 0.18)
    else
        bnp:SetWidth(fullW)
        bnp:Show()
    end
end

-- Animeret slide ud (fuld bredde → 0) for Boss Note panelet
CloseBossNotePanel = function(animated)
    if not frame or not frame.bossNotePanel then return end
    local bnp  = frame.bossNotePanel
    if not bnp:IsShown() then return end
    local anim  = BossHelper.Anim
    local fullW = bnp._fullWidth or 200
    if animated and anim and anim.AnimateWidth and anim.ShouldAnimate() then
        if bnp._widthTween then bnp._widthTween.running = false end
        local curW = bnp:GetWidth() or fullW
        anim.AnimateWidth(bnp, curW, 0, 0.18, function()
            bnp:Hide()
            bnp:SetWidth(fullW)
        end)
    else
        bnp:Hide()
        bnp:SetWidth(fullW)
    end
end

-- Helper: Luk Boss Note panelet hvis det er åbent (og nulstil knap-tekst)
local function CloseBossNotePanelIfOpen()
    CloseBossNotePanel(true)
    if rightPanel and rightPanel.bossNoteButton then
        rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
    end
end

-- Settings Info Panel: åbn med indhold, luk animeret
local _sip_hideTimer = nil

OpenSettingsInfoPanel = function(title, desc, image)
    if not frame or not frame.settingsInfoPanel then return end
    local sip = frame.settingsInfoPanel
    if _sip_hideTimer then _sip_hideTimer:Cancel(); _sip_hideTimer = nil end
    if sip.Load then sip.Load(title, desc, image) end
    local fullW = sip._fullWidth or 240
    if sip._widthTween then sip._widthTween.running = false end
    if not sip:IsShown() then
        local anim = BossHelper.Anim
        if anim and anim.AnimateWidth and anim.ShouldAnimate() then
            sip:SetWidth(0); sip:Show()
            anim.AnimateWidth(sip, 0, fullW, 0.15)
        else
            sip:SetWidth(fullW); sip:Show()
        end
    else
        sip:SetWidth(fullW)
    end
end

CloseSettingsInfoPanel = function(animated)
    if not frame or not frame.settingsInfoPanel then return end
    local sip  = frame.settingsInfoPanel
    if not sip:IsShown() then return end
    local anim  = BossHelper.Anim
    local fullW = sip._fullWidth or 240
    if animated and anim and anim.AnimateWidth and anim.ShouldAnimate() then
        if sip._widthTween then sip._widthTween.running = false end
        local curW = sip:GetWidth() or fullW
        anim.AnimateWidth(sip, curW, 0, 0.15, function()
            sip:Hide(); sip:SetWidth(fullW)
        end)
    else
        sip:Hide(); sip:SetWidth(fullW)
    end
end

-- Helper: skjul tactic edit-mode UI (bruges fra flere steder)
local function HideEditModeUI()
    BossUI:HideEditModeUI()
end

-- Enter tactic edit mode
local function EnterEditMode()
    BossUI:EnterEditMode()
end

-- Exit tactic edit mode (saveChanges=true → gem, false → annuller)
local function ExitEditMode(saveChanges)
    BossUI:ExitEditMode(saveChanges)
end


-- Lokale aliases til centrale animations-hjælpere (defineret i Animations.lua)
local ShouldAnimateInCombat = BossHelper.Anim.ShouldAnimate
local CrossfadeFrameText    = BossHelper.Anim.CrossfadeText

-- Shorthand for safe sound playback
local function SafePlay(sound)
    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(sound) end
end

-- Text processing is now handled in Functions.lua
-- Local wrapper function for compatibility
local function ReplaceRoleIcons(text)
    if BossHelper and BossHelper.ReplaceRoleIcons then
        return BossHelper:ReplaceRoleIcons(text)
    end
    return text -- fallback hvis Functions.lua ikke er loadet endnu
end



-- OpenCopyTextWindow: opens a small popup with text pre-selected so the player can Ctrl+C to copy.
-- The window auto-closes once Ctrl+C is detected. Logic mirrors the SimulationCraft addon exactly.
local function OpenCopyTextWindow(text)
    -- Reuse existing window if already open
    if _G.BossHelper_CopyTextFrame then
        local ef = _G.BossHelper_CopyTextFrame.editBox
        if ef then
            ef:SetText(text or "")
            ef:HighlightText()
        end
        _G.BossHelper_CopyTextFrame:Show()
        return
    end

    local popupW, popupH = 480, 320
    local popup = CreateFrame("Frame", "BossHelper_CopyTextFrame", UIParent, "BackdropTemplate")
    _G.BossHelper_CopyTextFrame = popup
    popup:SetSize(popupW, popupH)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    popup:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    popup:SetBackdropColor(0, 0, 0, 0.9)

    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -16)
    title:SetText(Translate("COPY_TEXT") or "Copy Text")
    title:SetTextColor(1, 0.82, 0.0)

    -- Hint label
    local hint = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
    hint:SetText("|cffaaaaaa Ctrl+C |r|cffdddddd" .. (Translate("COPY_HINT_TEXT") or "— closes window") .. "|r")
    hint:SetJustifyH("CENTER")

    -- Close button (X)
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() popup:Hide() end)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     popup, "TOPLEFT",  16, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -32, 12)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
    end)

    -- EditBox — mirroring SimulationCraft addon setup exactly
    local ctrlDown = false
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetSize(scrollFrame:GetSize())
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetScript("OnEscapePressed", function() popup:Hide() end)
    editBox:SetScript("OnKeyDown", function(self, key)
        if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
            ctrlDown = true
        end
    end)
    editBox:SetScript("OnKeyUp", function(self, key)
        if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
            -- Grace period: in testing Ctrl keyup can fire slightly before C
            C_Timer.After(0.2, function() ctrlDown = false end)
        end
        if ctrlDown then
            if key == "C" or key == "X" then
                -- Small delay so OS clipboard is written before we close
                C_Timer.After(0.1, function()
                    if popup and popup:IsShown() then
                        popup:Hide()
                    end
                end)
            end
        end
    end)

    scrollFrame:SetScrollChild(editBox)
    popup.editBox = editBox

    editBox:SetText(text or "")
    editBox:HighlightText()
    popup:Show()
end

-- Updates the postButton label depending on chat messaging lockdown state.
-- Call this whenever the button is shown, or when lockdown state changes.
local function UpdatePostButtonLabel(btn)
    if not btn then return end
    local isRestricted, reason = C_ChatInfo.InChatMessagingLockdown()
    if isRestricted then
        btn:SetText(Translate("COPY_TEXT") or "Copy Text")
    else
        btn:SetText(Translate("POST_TO_CHAT") or "Post to chat")
    end
end

-- Alle knap-oprettelse og styling er centraliseret i UI/Buttons.lua.
-- Lokalt alias bevares så eksisterende kode i denne fil ikke ændres.
local CreateCustomButton = BossHelper.Buttons.Create

-- Eksponér til EditTactics.lua og andre submoduler.
BossUI.CreateCustomButton = CreateCustomButton

-- ============================================================
-- Fase-dropdown (delt af native-fase og custom-kun faser)
--   parent       = frame at forankre dropdown til
--   rPanel       = rightPanel (gemmer phaseDropdown / clickCatcher)
--   phases       = ordnet liste af fase-navne (strings)
--   textResolver = function(phaseName) → string (taktik-tekst)
-- Returnerer dropdown-frame eller nil (hvis kun én fase).
-- ============================================================
local function CreatePhaseDropdown(parent, rPanel, phases, textResolver)
    if #phases == 1 then
        BuildShortLineButtons(rPanel, textResolver(phases[1]))
        return nil
    end

    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(140, 26)
    dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -40)

    local mainBtn = CreateCustomButton(dropdown, 140, 26, phases[1])
    mainBtn:SetPoint("TOP", dropdown, "TOP", -419, 30)
    mainBtn.arrow = mainBtn:CreateTexture(nil, "OVERLAY")
    mainBtn.arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
    mainBtn.arrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
    mainBtn.arrow:SetSize(20, 10)
    mainBtn.arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -8, 0)
    mainBtn.arrow:SetAlpha(0.8)
    mainBtn.arrow:SetRotation(0)

    local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    panel:SetSize(140, #phases * 26)
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
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetFrameLevel(1999)

    local buttons = {}

    local function SelectPhase(index)
        rPanel.selectedPhaseIndex = index
        for i, btn in ipairs(buttons) do btn:SetSelected(i == index) end
        mainBtn:SetText(phases[index])
        BuildShortLineButtons(rPanel, textResolver(phases[index]))
    end

    for i, phaseName in ipairs(phases) do
        local btn = CreateCustomButton(panel, 140, 26, phaseName)
        btn:SetPoint("TOP", panel, "TOP", 0, -((i - 1) * 26))
        btn:SetScript("OnClick", function()
            SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
            SelectPhase(i)
            panel:Hide()
            if rPanel.phaseDropdownClickCatcher then rPanel.phaseDropdownClickCatcher:Hide() end
            if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
        end)
        table.insert(buttons, btn)
    end

    -- Start med gemt fase-indeks eller første fase
    if rPanel.selectedPhaseIndex and rPanel.selectedPhaseIndex <= #phases then
        SelectPhase(rPanel.selectedPhaseIndex)
    else
        SelectPhase(1)
    end

    -- Click-catcher: lukker panel ved klik udenfor
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1999)
    catcher:SetScript("OnMouseDown", function(self)
        if panel:IsShown() then
            panel:Hide()
            self:Hide()
            if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
        end
    end)
    rPanel.phaseDropdownClickCatcher = catcher

    mainBtn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        if panel:IsShown() then
            panel:Hide()
            if rPanel.phaseDropdownClickCatcher then rPanel.phaseDropdownClickCatcher:Hide() end
            if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
        else
            panel:Show()
            panel:SetFrameStrata("FULLSCREEN_DIALOG")
            panel:SetFrameLevel(2000)
            if rPanel.phaseDropdownClickCatcher then
                rPanel.phaseDropdownClickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                rPanel.phaseDropdownClickCatcher:SetFrameLevel(1999)
                rPanel.phaseDropdownClickCatcher:Show()
            end
            BossHelper.Anim.PlayDropdownOpen(panel)
            if mainBtn.arrow then mainBtn.arrow:SetRotation(math.pi) end
        end
    end)

    dropdown.mainBtn = mainBtn
    return dropdown
end

-- Helper: auto-open eller luk boss note panel når en boss vælges
local function UpdateBossNotePanel(bossKey)
    if not frame.bossNotePanel then return end
    BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
    local notesList = BossHelperDB.bossNotes[currentDungeon] and
                      BossHelperDB.bossNotes[currentDungeon][bossKey]
    local hasNote = (type(notesList) == "string" and notesList ~= "") or
                    (type(notesList) == "table" and #notesList > 0)
    if hasNote and BossHelperDB.autoOpenBossNotes ~= false then
        rightPanel.bossNoteButton:SetText(Translate("BOSS_CLOSE_NOTE"))
        if not frame.bossNotePanel.initialized then CreateBossNoteContent() end
        if frame.bossNotePanel.LoadNotesForBoss then
            frame.bossNotePanel.LoadNotesForBoss(bossKey, currentDungeon)
        end
        OpenBossNotePanel(true)
    else
        CloseBossNotePanel(true)
        rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
    end
end

-- Helper: SelectBoss
local function SelectBoss(bossData, btn)
    HideAffixesView()
    HideEditModeUI()
    CloseSettingsInfoPanel(true)
    ClearRightPanelContent(rightPanel)
    if selectedButton then selectedButton:SetSelected(false) end
    frame.selectedBoss = bossData

    BossUI:ShowBoss(rightPanel, bossData)

    if rightPanel.detailToggle then
        rightPanel.detailToggle:SetText(Translate("SHOW_DETAILS"))
        rightPanel.detailToggle:Show()
    end
    if rightPanel.postButton then
        rightPanel.postButton:Show()
        UpdatePostButtonLabel(rightPanel.postButton)
    end
    if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Show() end
    if rightPanel.editTacticsBtn then
        rightPanel.editTacticsBtn:ClearAllPoints()
        if rightPanel.phaseDropdown and rightPanel.phaseDropdown.mainBtn then
            rightPanel.editTacticsBtn:SetPoint("LEFT", rightPanel.phaseDropdown.mainBtn, "RIGHT", 4, 0)
        else
            rightPanel.editTacticsBtn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 8, -8)
        end
        rightPanel.editTacticsBtn:Show()
    end

    UpdateBossNotePanel(bossData.encounterID)
    if btn then btn:SetSelected(true); selectedButton = btn end
end

-- ShowDungeons
local function ShowDungeons()
    currentLeftCategory = "dungeons"
    if leftPanel and leftPanel.affixButton then leftPanel.affixButton:SetSelected(false) end
    -- Set left panel title
    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText(Translate("DUNGEONS"))
    end

    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then btn.icon:Hide() end
            btn:Hide()
        end
    end
    frame.bossButtons = {}

    local y = -39  -- Align with rightPanel content at -39

    local order = BossData.DungeonOrder
    if not order then
        order = {}
        for k,v in pairs(BossData) do
            if type(v) == "table" and v.bosses then
                table.insert(order, k)
            end
        end
        table.sort(order)
    end

    for _, dungeonKey in ipairs(order) do
        local dungeonData = BossData[dungeonKey]
        if dungeonData then
            local nameToShow = BossHelper:GetDungeonName(dungeonData.instanceID) or dungeonKey
            local btn = CreateCustomButton(leftPanel, 180, 30, nameToShow)
            btn:SetPoint("TOP", leftPanel, "TOP", 0, y)

            local textureID = BossHelper:GetDungeonTextureID(dungeonData.instanceID)
            if textureID then
                btn:SetIcon(textureID)
            end

            if btn.icon and btn.icon:IsShown() then
                btn.text:ClearAllPoints()
                btn.icon:SetSize(22, 22)
                btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 6, 0)
                btn.text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
                btn.text:SetJustifyH("LEFT")
                btn.text:SetWordWrap(false)
                btn.text:SetWidth(120)
            else
                btn.text:ClearAllPoints()
                btn.text:SetPoint("CENTER", 0, 0)
                btn.text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            end

            btn:SetScript("OnClick", function()
                SafePlay(BossHelper.Sounds.DUNGEON_SELECT)
                ShowBosses(dungeonKey)
            end)


            table.insert(frame.bossButtons, btn)
            -- match tighter spacing across panels
            y = y - 35
        end
    end

    -- Single Affixes button appended after dungeon list
    if not leftPanel.affixButton then
        local aBtn = CreateCustomButton(leftPanel, 180, 30, Translate("AFFIXES") or "Affixes")
        leftPanel.affixButton = aBtn
        aBtn.isAffixActive = false
        aBtn:SetScript("OnClick", function(self)
            SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
            if self.isAffixActive then
                -- Toggle off: go back to start page + dungeon list
                self.isAffixActive = false
                self:SetSelected(false)
                currentLeftCategory = "dungeons"
                -- Hide affix specific scroll
                if rightPanel and rightPanel.affixScroll then rightPanel.affixScroll:Hide() end
                if rightPanel and rightPanel.rightTitle then rightPanel.rightTitle:SetText("") end
                -- Show start page again (with dungeons list still present)
                ShowStartPage(frame, rightPanel)
                ShowSocialButtons()
            else
                -- Activate affixes view
                self.isAffixActive = true
                self:SetSelected(true)
                ShowAffixes()
            end
        end)
    end
    leftPanel.affixButton:ClearAllPoints()
    leftPanel.affixButton:SetPoint("TOP", leftPanel, "TOP", 0, y)
    -- Only show if we are at dungeon list root (no selected boss, not in settings/info/notes)
    if not frame.selectedBoss and (not BossHelperDB or not BossHelperDB.lastOpenPanel) then
        leftPanel.affixButton:Show()
    else
        leftPanel.affixButton:Hide()
    end

    if not frame.selectedBoss then
        backButton:Hide()
        ShowStartPage(frame, rightPanel)
        
        -- Luk automatisk bossNote panel når man ikke ser en boss
        CloseBossNotePanel(true)
        
        -- Skjul bossNote knappen når man ikke ser en boss
        if rightPanel.bossNoteButton then
            rightPanel.bossNoteButton:Hide()
            rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
        end
    else
        backButton:Show()
    end
end

-- ShowAffixes: displays current week's Mythic+ affixes on right panel
-- Made global (was local) so the dynamically created Affixes button (defined before this in execution) can call it
function ShowAffixes()
    currentLeftCategory = "affixes"
    frame.selectedBoss = nil
    if selectedButton then selectedButton:SetSelected(false); selectedButton = nil end
    if leftPanel and leftPanel.affixButton then leftPanel.affixButton:SetSelected(true) end
    if leftPanel and leftPanel.affixButton then leftPanel.affixButton.isAffixActive = true end
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.lastOpenPanel = "affixes"
    if backButton then backButton:Hide() end
    -- dungeon buttons remain visible so player can switch dungeons after viewing affixes
    -- Ryd rightPanel-indhold inden affixes vises
    ClearRightPanelContent(rightPanel)
    -- also hide boss note side panel if open
    if frame and frame.bossNotePanel and frame.bossNotePanel:IsShown() then
        frame.bossNotePanel:Hide()
    end
    if rightPanel and rightPanel.rightTitle then
        CrossfadeFrameText(rightPanel.rightTitle, Translate("THIS_WEEK_AFFIXES") or "This Week Affixes")
    end
    if rightPanel then
        if BossHelper_Affixes_Show then
            local ok, err = pcall(BossHelper_Affixes_Show, rightPanel)
            if not ok then
                print("|cffFF4500[BossHelper]|r Affix view error:", err)
            end
        else
            print("|cffFF4500[BossHelper]|r Affixes module not loaded (BossHelper_Affixes_Show nil)")
        end
    end
end

-- Helper to reopen last saved affix view (called from LDB logic)
local function TryRestoreAffixes()
    if BossHelperDB and BossHelperDB.lastOpenPanel == "affixes" then
        ShowAffixes()
        return true
    end
    return false
end

-- ShowBosses
function ShowBosses(dungeonName)
    currentDungeon = dungeonName
    CloseSettingsInfoPanel(true)

    -- Brugeren er ikke længere i settings når vi åbner boss-listen
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.lastOpenPanel = nil

    local dungeonData = BossData[dungeonName]
    if not dungeonData or not dungeonData.bosses then return end

    -- Set left panel title to dungeon name
    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText(BossHelper:GetDungeonName(dungeonData.instanceID) or dungeonName)
    end

    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then btn.icon:Hide() end
            btn:Hide()
        end
    end
    frame.bossButtons = {}

    local y = -39  -- Align with rightPanel content at -39

    for _, bossData in ipairs(dungeonData.bosses) do
        local bossName = BossHelper:GetBossName(bossData.encounterID) or Translate("UNKNOWN_BOSS")
        local btn = CreateCustomButton(leftPanel, 180, 30, bossName)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn._bossData = bossData  -- gem reference til boss-data for re-selektion

        local iconTexture = bossData.icon or BossHelper:GetBossPortraitFileID(bossData.encounterID, bossData)
        if iconTexture then
            btn:SetIcon(iconTexture)
            btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, 6)
            btn.icon:SetSize(52, 32)
            btn.text:ClearAllPoints()
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 6, -6)
            btn.text:SetPoint("RIGHT", btn, "RIGHT", -6, -6)
            btn.text:SetWordWrap(false)
            btn.text:SetJustifyH("LEFT")
        else
            btn.text:ClearAllPoints()
            btn.text:SetPoint("CENTER", 0, 0)
        end

        btn:SetScript("OnClick", function()
            SelectBoss(bossData, btn)
            SafePlay(BossHelper.Sounds.BOSS_SELECT)
        end)


        table.insert(frame.bossButtons, btn)
        y = y - 35
    end

    backButton:Show()
    if leftPanel and leftPanel.affixButton then leftPanel.affixButton:Hide() end
end

function BossUI:ShowBoss(rPanel, boss)
    -- Skjul tidligere dropdown og click-catcher, hvis de findes
    if rPanel.phaseDropdown then
        rPanel.phaseDropdown:Hide()
    end
    if rPanel.dropdownClickCatcher then
        rPanel.dropdownClickCatcher:Hide()
    end

    if not rPanel.rightTitle then
        rPanel.rightTitle = rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        rPanel.rightTitle:SetPoint("TOP", rPanel, "TOP", 0, -20)
        rPanel.rightTitle:SetTextColor(1, 0.5, 0)
        rPanel.rightTitle:SetJustifyH("CENTER")
    end

    -- Scroll og text
    if not rPanel.rightShortText or not rPanel.rightShortContent or not rPanel.rightShortScroll then
        if not rPanel.rightShortText then
            rPanel.rightShortText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            rPanel.rightShortText:SetPoint("TOPLEFT", 10, -40)
            rPanel.rightShortText:SetSize(550, 160)
            rPanel.rightShortText:SetJustifyH("LEFT")
            rPanel.rightShortText:SetJustifyV("TOP")
            rPanel.rightShortText:SetWordWrap(true)
        end
    end

    -- Detaljer
    if not rPanel.rightDetailText then
        local anchorTarget = rPanel.rightShortScroll or rPanel.rightShortText or rPanel
        rPanel.rightDetailText = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rPanel.rightDetailText:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", 0, -5)
        rPanel.rightDetailText:SetSize(550, 250)
        rPanel.rightDetailText:SetJustifyH("LEFT")
        rPanel.rightDetailText:SetJustifyV("TOP")
        rPanel.rightDetailText:SetWordWrap(true)
    end

    -- Titel
    CrossfadeFrameText(rPanel.rightTitle, BossHelper:GetBossName(boss.encounterID) or Translate("UNKNOWN_BOSS"))

    -- Dropdown til faser med custom buttons
    if boss.phases and #boss.phases > 0 then
        if rPanel.phaseDropdown then
            rPanel.phaseDropdown:Hide()
            rPanel.phaseDropdown = nil
        end

        -- Byg merged faseliste: native faser + custom-kun faser (ikke "No phase")
        local mergedPhases = {}
        local nativeSet = {}
        for _, p in ipairs(boss.phases) do
            table.insert(mergedPhases, p)
            nativeSet[p] = true
        end
        local customPhaseList = BossUI.GetCustomPhases and BossUI.GetCustomPhases(currentDungeon, boss.encounterID) or {}
        for _, p in ipairs(customPhaseList) do
            if not nativeSet[p] and p ~= "No phase" then
                table.insert(mergedPhases, p)
            end
        end

        local function nativeTextResolver(phaseName)
            local customText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, phaseName)
            return customText or (boss.phaseText and boss.phaseText[phaseName]) or ""
        end

        rPanel.phaseDropdown = CreatePhaseDropdown(rPanel, rPanel, mergedPhases, nativeTextResolver)

   else
        if rPanel.phaseDropdown then
            rPanel.phaseDropdown:Hide()
            rPanel.phaseDropdown = nil
        end
    
        --rPanel.rightShortText:SetText(ReplaceRoleIcons(boss.short or ""))
        --Anders: build buttons from lines in boss.short
        -- Check for custom tactics first
        local hasCustomNonPhase = BossUI.HasCustomTactics and BossUI.HasCustomTactics(currentDungeon, boss.encounterID)
        if hasCustomNonPhase then
            local customPhaseList = BossUI.GetCustomPhases and BossUI.GetCustomPhases(currentDungeon, boss.encounterID) or {}
            if #customPhaseList > 1 then
                -- Multiple custom faser → genbrugelig dropdown
                local function customTextResolver(phaseName)
                    return (BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, phaseName)) or ""
                end
                rPanel.phaseDropdown = CreatePhaseDropdown(rPanel, rPanel, customPhaseList, customTextResolver)
            else
                -- Enkelt eller ingen custom fase → vis flat liste
                local txt = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, customPhaseList[1])
                if not txt then
                    BossHelperDB = BossHelperDB or {}
                    local ct = BossHelperDB.customTactics
                    local raw = ct and ct[currentDungeon] and ct[currentDungeon][boss.encounterID]
                    local allLines = {}
                    if type(raw) == "string" then allLines = { raw }
                    elseif type(raw) == "table" then
                        for _, entry in ipairs(raw) do
                            local t = (entry.text or ""):gsub("^%s+",""):gsub("%s+$","")
                            if t ~= "" then table.insert(allLines, t) end
                        end
                    end
                    txt = table.concat(allLines, "\n")
                end
                BuildShortLineButtons(rPanel, txt or "")
            end
        else
            BuildShortLineButtons(rPanel, boss.short or "")
        end
    end


    -- Opdater content-højde
    if rPanel.rightShortContent then
        local measuredHeight = nil
        if rPanel.rightShortText.GetStringHeight then
            measuredHeight = rPanel.rightShortText:GetStringHeight()
        end
        local approxLineHeight = 18
        local lines = 1
        local currentText = rPanel.rightShortText:GetText() or ""
        local _, n = string.gsub(currentText, "\n", "\n")
        lines = n + 1
        local h = measuredHeight or math.max(lines * approxLineHeight, 60)
        rPanel.rightShortContent:SetHeight(h + 10)
    end

    -- Skjul detaljer
    rPanel.rightDetailText:SetText("")
    if rPanel.rightDetailScroll then rPanel.rightDetailScroll:Hide() end
    rPanel.showingDetails = false
end


-- Minimap / LibDBIcon support
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)

-- Hvis LibDataBroker eller LibDBIcon ikke findes, fortsæt uden fejl (optional deps)
if LDB and LibDBIcon then
    -- sørg for saved var er til stede
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.minimap = BossHelperDB.minimap or { hide = false }

    local ldbObject = LDB:NewDataObject("BossHelper", {
        type = "data source",                -- <--- data source giver tekst
        icon = "Interface\\AddOns\\BossHelper\\Media\\Mythic Mentor no te 512x512.png",
        text = "Mythic Mentor",                 -- teksten TitanPanel kan vise
        label = "Mythic Mentor",                -- nogle LDB-plugins bruger label også
        OnClick = function(_, button)
            if button == "LeftButton" then
                if not frame then
                    if BossUI and BossUI.CreateUI then BossUI:CreateUI() end
                end
                if frame and frame:IsShown() then
                    SafePlay(BossHelper.Sounds.CLOSE_MENU)
                    frame:Hide()
                else
                    if frame then
                        frame:Show()
                        SafePlay(BossHelper.Sounds.OPEN_MENU)
                        if currentDungeon and frame.selectedBoss then
                            ShowBosses(currentDungeon)
                            -- Find og vælg den gemte boss igen for at trigge note panel logik
                            local savedBoss = frame.selectedBoss  -- reference til boss-objektet
                            for _, btn in ipairs(frame.bossButtons or {}) do
                                if btn._bossData == savedBoss then
                                    SelectBoss(savedBoss, btn)
                                    break
                                end
                            end
                        else
                            -- Ryd gamle settings-widgets uanset hvad
                            ClearRightPanelSettings()

                            BossHelperDB = BossHelperDB or {}
                            if BossHelperDB.lastOpenPanel == "settings" then
                                -- åbn settings igen
                                ClearRightPanelNotes()
                                ShowSettings()
                            elseif BossHelperDB.lastOpenPanel == "info" then
                                -- åbn info igen
                                ClearRightPanelNotes()
                                ShowInfo()
                            elseif BossHelperDB.lastOpenPanel == "notes" then
                                -- åbn general notes igen
                                ShowGeneralNotes()
                            elseif BossHelperDB.lastOpenPanel == "affixes" then
                                -- genskab affixes direkte (uden startpage overlay)
                                ShowAffixes()
                            else
                                -- vis normal start
                                BossHelper.UI.hide(rightPanel.rightShortScroll)
                                BossHelper.UI.hide(rightPanel.shortBtnScroll)
                                ClearRightPanelNotes()
                                ShowStartPage(frame, rightPanel)
                                ShowDungeons()
                                -- Auto-select current dungeon if inside a known one
                                local autoKey = GetCurrentDungeonKey()
                                if autoKey then
                                    ShowBosses(autoKey)
                                    -- Auto-click the first boss button
                                    if frame.bossButtons and frame.bossButtons[1] then
                                        local firstBtn = frame.bossButtons[1]
                                        firstBtn:GetScript("OnClick")(firstBtn)
                                    end
                                end
                            end
                        end
                    end
                end
            elseif button == "RightButton" then

            end
        end,

        OnTooltipShow = function(tt)
            if not tt or not tt.AddLine then return end
            tt:AddLine("Mythic Mentor")
            tt:AddLine("Left-click: Open Mythic Mentor")
            tt:AddLine("")
        end,
    })


    -- vent til login, så savedvars er loadet korrekt
    -- PLAYER_LOGIN handler
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- registrer minimap knap
        if LibDBIcon and ldbObject then
            LibDBIcon:Register("BossHelper", ldbObject, BossHelperDB.minimap)
        end

        -- Titan Panel vil automatisk opdage ldbObject,
        -- så du skal ikke gøre mere for Titan support
    end)

    -- Chat-lockdown events: opdater postButton tekst når chat-adgang ændres
    eventFrame:RegisterEvent("CHAT_DISABLED_CHANGED")
    local orig_OnEvent = eventFrame:GetScript("OnEvent")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "CHAT_DISABLED_CHANGED" then
            if rightPanel and rightPanel.postButton and rightPanel.postButton:IsShown() then
                UpdatePostButtonLabel(rightPanel.postButton)
            end
        else
            if orig_OnEvent then orig_OnEvent(self, event, ...) end
        end
    end)
end

-- Anders: build buttons from boss.short lines
-- Auto-wrap and auto-height buttons for each line in 'text'
function BuildShortLineButtons(rPanel, text)
    -- ensure a scroll area for line buttons
    if not rPanel.shortBtnScroll then
        local scroll = CreateFrame("ScrollFrame", nil, rPanel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 10, -40)
        scroll:SetPoint("RIGHT", rPanel, "RIGHT", -30, 0)
        scroll:SetHeight(300)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
        end)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(1, 1)
        scroll:SetScrollChild(content)

        rPanel.shortBtnScroll  = scroll
        rPanel.shortBtnContent = content

        rPanel.shortBtnContent:SetWidth(540)
        rPanel.shortBtnScroll:SetFrameLevel((rPanel:GetFrameLevel() or 1) + 2)
    end

    -- hide old text block and show buttons area
    if rPanel.rightShortScroll then
        rPanel.rightShortText:SetText("")
        rPanel.rightShortScroll:Hide()
    end
    rPanel.shortBtnScroll:Show()

    -- clear old buttons
    if rPanel.shortButtons then
        for _, b in ipairs(rPanel.shortButtons) do
            b:Hide()
            b:SetParent(nil)
        end
    end
    rPanel.shortButtons = {}

    -- split text into non-empty, trimmed lines
    local lines = {}
    text = (text or ""):gsub("\r\n", "\n")
    for line in text:gmatch("([^\n]+)") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then table.insert(lines, line) end
    end

    -- build variable-height buttons
    local totalY = 0
    local btnWidth   = 540
    local minBtnH    = 26
    local paddingX   = 8   -- left/right padding for text
    local paddingTop = 6   -- top padding for text
    local paddingBot = 6   -- bottom padding for text
    local spacing    = 6   -- space between buttons

    local canAnimate = ShouldAnimateInCombat()

    for i, ln in ipairs(lines) do
        local btn = CreateCustomButton(rPanel.shortBtnContent, btnWidth, minBtnH, "")
        btn:SetPoint("TOPLEFT", rPanel.shortBtnContent, "TOPLEFT", 0, -totalY)

        -- re-anchor the text for multi-line layout inside the button
        btn.text:ClearAllPoints()
        btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", paddingX, -paddingTop)
        btn.text:SetPoint("RIGHT",   btn, "RIGHT",   -paddingX, 0)
        btn.text:SetJustifyH("LEFT")
        btn.text:SetJustifyV("TOP")
        btn.text:SetWordWrap(true)

        -- set text and compute required height
        btn:SetText(ReplaceRoleIcons(ln))
        btn.text:SetWidth(btnWidth - (paddingX * 2))
        local textH = btn.text:GetStringHeight() or 0
        if textH == 0 then
            btn.text:SetText(btn.text:GetText() or "")
            textH = btn.text:GetStringHeight() or 0
        end
        local neededH = math.max(minBtnH, math.ceil(textH + paddingTop + paddingBot))
        btn:SetHeight(neededH)

        -- optional click action per line:
        btn:SetScript("OnClick", function() 
            SafePlay(BossHelper.Sounds.POST_TO_CHAT)
            BossHelper:SendSingleSmartMessage(ln) 
        end)

        -- Fjern hover scale-animation (kun farveændring, ingen scale)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.25, 1)
            self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
            self.text:SetTextColor(1, 0.95, 0.75)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.06, 0.07, 0.11, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            self.text:SetTextColor(0.98, 0.82, 0.55)
        end)

        if canAnimate then
            -- entry animation: translation (fra 10px under) + fade in, med lille delay afhængig af i (stagger)
            local ag = btn:CreateAnimationGroup()
            local trans = ag:CreateAnimation("Translation")
            trans:SetOffset(0, -10)
            trans:SetDuration(0.18)
            trans:SetSmoothing("OUT")
            local alpha = ag:CreateAnimation("Alpha")
            alpha:SetFromAlpha(0)
            alpha:SetToAlpha(1)
            alpha:SetDuration(0.18)
            -- start delay (stagger), men hold det lavt for mange linjer
            local delay = math.min((i-1) * 0.03, 0.35)
            trans:SetStartDelay(delay)
            alpha:SetStartDelay(delay)
            ag:Play()
        else
            btn:SetAlpha(1)
            btn:Show()
        end

        table.insert(rPanel.shortButtons, btn)
        totalY = totalY + neededH + spacing
    end

    -- adjust scroll content height
    rPanel.shortBtnContent:SetHeight(math.max(totalY - spacing, 1))
end


-- ============================================================
-- PrepareForNavigation: fælles opsætning før enhver side
-- (settings / info / generalNotes / affixes)
-- ============================================================
local function PrepareForNavigation()
    HideAffixesView()
    HideEditModeUI()
    BossHelperDB = BossHelperDB or {}
    if not frame and BossUI and BossUI.CreateUI then BossUI:CreateUI() end
    ClearRightPanelContent(rightPanel)
    if leftPanel and leftPanel.affixButton then
        leftPanel.affixButton:Hide()
        leftPanel.affixButton.isAffixActive = false
        leftPanel.affixButton:SetSelected(false)
    end
    ClearRightPanelSettings()
    CloseBossNotePanelIfOpen()
    CloseSettingsInfoPanel(true)
end

-- --- Settings er i BossSettings.lua ---
function ShowSettings()
    PrepareForNavigation()
    ClearRightPanelNotes()
    BossHelperDB.lastOpenPanel = "settings"

    if rightPanel then
        rightPanel.settingsWidgets = rightPanel.settingsWidgets or {}
    end
    local function AddSettingsWidget(w)
        if rightPanel and w then table.insert(rightPanel.settingsWidgets, w) end
        return w
    end

    if BossSettings and BossSettings.ShowSettings then
        -- Åbn info-panelet straks i tom tilstand
        if frame and frame.settingsInfoPanel then
            local sip = frame.settingsInfoPanel
            if sip.Reset then sip.Reset() end
            if not sip:IsShown() then
                local anim = BossHelper.Anim
                local fullW = sip._fullWidth or 220
                if anim and anim.AnimateWidth and anim.ShouldAnimate() then
                    sip:SetWidth(0); sip:Show()
                    anim.AnimateWidth(sip, 0, fullW, 0.15)
                else
                    sip:SetWidth(fullW); sip:Show()
                end
            end
        end
        BossSettings.ShowSettings{
            frame = frame,
            leftPanel = leftPanel,
            rightPanel = rightPanel,
            backButton = backButton,
            CreateCustomButton = CreateCustomButton,
            BossHelper = BossHelper,
            BossHelperDB = BossHelperDB,
            AddSettingsWidget = AddSettingsWidget,
            ShowSettingsInfo = function(title, desc, image)
                OpenSettingsInfoPanel(title, desc, image)
            end,
            HideSettingsInfo = function()
                -- Gør ingenting – panelet beholder det sidst viste indhold
            end,
        }
    else
        print("|cffFF4500[BossUI]|r BossSettings not loaded!")
    end
end

-- --- Info er i BossInfo.lua ---
function ShowInfo()
    PrepareForNavigation()
    ClearRightPanelNotes()
    BossHelperDB.lastOpenPanel = "info"

    if BossInfo and BossInfo.ShowInfo then
        BossInfo.ShowInfo{
            frame = frame,
            leftPanel = leftPanel,
            rightPanel = rightPanel,
            backButton = backButton,
            CreateCustomButton = CreateCustomButton,
            BossHelper = BossHelper,
            BossHelperDB = BossHelperDB,
        }
    else
        print("|cffFF4500[BossUI]|r BossInfo not loaded!")
    end
end

function SelectInfoCategory(categoryName, btn)
    if BossInfo and BossInfo.SelectInfoCategory then
        BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, categoryName, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = BossHelperDB })
    end
end

-- --- General Notes er i GeneralNotes.lua ---
function ShowGeneralNotes()
    PrepareForNavigation()
    -- Bemærk: ClearRightPanelNotes IKKE kaldt her – GeneralNotes bygger selv sin widget-liste
    BossHelperDB.lastOpenPanel = "notes"

    if GeneralNotes and GeneralNotes.ShowGeneralNotes then
        GeneralNotes.ShowGeneralNotes{
            frame = frame,
            leftPanel = leftPanel,
            rightPanel = rightPanel,
            backButton = backButton,
            CreateCustomButton = CreateCustomButton,
            BossHelper = BossHelper,
            BossHelperDB = BossHelperDB,
        }
    else
        print("|cffFF4500[BossUI]|r GeneralNotes not loaded!")
    end
end

function SelectNotesCategory(categoryName, btn)
    if GeneralNotes and GeneralNotes.SelectNotesCategory then
        GeneralNotes.SelectNotesCategory(frame, leftPanel, rightPanel, categoryName, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = BossHelperDB })
    end
end

-- CreateBossNoteContent - delegerer til GeneralNotes.InitBossNotePanel
function CreateBossNoteContent()
    if GeneralNotes and GeneralNotes.InitBossNotePanel then
        GeneralNotes.InitBossNotePanel(frame.bossNotePanel, {
            getFrame      = BossUI.GetFrame,
            getRightPanel = BossUI.GetRightPanel,
            getDungeon    = function() return currentDungeon end,
            CreateCustomButton = CreateCustomButton,
        })
    end
end




function SelectSettingCategory(categoryName, btn)
    if BossSettings and BossSettings.SelectSettingCategory then
        BossSettings.SelectSettingCategory(frame, leftPanel, rightPanel, categoryName, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = BossHelperDB })
    end
end

-- BuildSettingsCategoryUI wrapper (in case andre steder kalder den direkte)
local function BuildSettingsCategoryUI(rPanel, category)
    if BossSettings and BossSettings.BuildSettingsCategoryUI then
        return BossSettings.BuildSettingsCategoryUI(rPanel, category, { CreateCustomButton = CreateCustomButton, BossHelperDB = BossHelperDB })
    end
end


function BossUI.GetFrame()
    return frame
end

function BossUI.GetRightPanel()
    return rightPanel
end

-- Public: return the BossData key for the current instance (or nil)
function BossUI:GetCurrentDungeonKey()
    return GetCurrentDungeonKey()
end

-- Public: return the currently selected dungeon key (or nil if none)
function BossUI:GetCurrentDungeon()
    return currentDungeon
end

-- Public: open fresh with auto-select of current dungeon (used by slash command)
function BossUI:OpenFreshWithAutoSelect()
    if not frame then return end
    ClearRightPanelSettings()
    ClearRightPanelNotes()
    ShowStartPage(frame, rightPanel)
    ShowDungeons()
    local autoKey = GetCurrentDungeonKey()
    if autoKey then
        ShowBosses(autoKey)
        -- Auto-click the first boss button
        if frame.bossButtons and frame.bossButtons[1] then
            local firstBtn = frame.bossButtons[1]
            firstBtn:GetScript("OnClick")(firstBtn)
        end
    end
end

-- Public helpers for update banner
function BossUI:ShowUpdateBanner(latestVersion)
    if not frame or not frame.updateBanner then return end
    local current = (BossHelper and BossHelper.VERSION_STRING) or ""
    local template = Translate and Translate("UPDATE_AVAILABLE_BANNER") or nil
    local text
    if type(template) == "string" then
        text = string.format(template, tostring(current), tostring(latestVersion or "?"))
    else
        text = string.format("New update available – Yours: %s  New: %s  (click to open)", tostring(current), tostring(latestVersion or "?"))
    end
    frame.updateBanner.text:SetText(text)
    frame.updateBanner:Show()
end

function BossUI:HideUpdateBanner()
    if frame and frame.updateBanner then frame.updateBanner:Hide() end
end

function BossUI:RefreshUpdateBanner()
    if not frame or not frame.updateBanner then return end
    -- Show banner if SavedVariables says there is a newer version we haven't updated to yet
    local cur = (BossHelper and BossHelper.VERSION_STRING) or "0"
    local tgt = BossHelperDB and BossHelperDB.notifiedLatestVersion or nil
    if tgt and BossHelper and BossHelper.CompareVersions and BossHelper:CompareVersions(cur, tgt) < 0 then
        self:ShowUpdateBanner(tgt)
    else
        self:HideUpdateBanner()
    end
end


-- ============================================================
-- Helpers for the top-right icon buttons (settings / info / notes)
-- Must be called from within CreateUI after `frame` is assigned.
-- ============================================================

-- Factory: creates a 24x24 icon-only nav button anchored to TOPRIGHT of frame.
-- enterBg / enterBorder = {r,g,b} hover colors.
local function CreateNavIconButton(xOffset, icon, iconSize, enterBg, enterBorder, clickFn)
    return BossHelper.Buttons.CreateNav(frame, xOffset, icon, iconSize, enterBg, enterBorder, clickFn)
end

-- Returns an OnClick that toggles a named panel open/closed.
local function MakeNavToggle(panelKey, openFn)
    return function()
        BossHelperDB = BossHelperDB or {}
        if BossHelperDB.lastOpenPanel == panelKey then
            SafePlay(BossHelper.Sounds.CLOSE_SETTINGS)
            backButton:GetScript("OnClick")()
        else
            SafePlay(BossHelper.Sounds.OPEN_SETTINGS)
            openFn()
        end
    end
end

-- CreateUI
function BossUI:CreateUI()
    -- Hvis UI allerede er oprettet, undgå at oprette igen
    if frame and frame.Create then return end

    frame = CreateFrame("Frame", "BossHelperFrame", UIParent, "BackdropTemplate")
    frame:SetSize(800, 400)
    frame:SetPoint("CENTER")
    frame:SetScale(BossHelperDB and BossHelperDB.scale or 1.0)
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnShow", function(self)
        if BossUI and BossUI.RefreshUpdateBanner then BossUI:RefreshUpdateBanner() end
    end)
    frame:SetFrameStrata("HIGH")
    frame.bossButtons = {}

    -- Persistent update banner (hidden by default)
    do
        local banner = CreateFrame("Button", nil, frame, "BackdropTemplate")
    banner:ClearAllPoints()
    banner:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 6)
    banner:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 6)
    banner:SetFrameStrata(frame:GetFrameStrata() or "HIGH")
    banner:SetFrameLevel((frame:GetFrameLevel() or 0) + 20)
        banner:SetHeight(24)
        BossHelper.UI.ApplyBackdrop(banner, "ITEM", {0.12, 0.08, 0.02, 0.95}, {1.0, 0.7, 0.2, 0.9})
        banner:Hide()

        local txt = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("CENTER", banner, "CENTER", 0, 0)
        txt:SetTextColor(1, 0.95, 0.75)
        txt:SetJustifyH("CENTER")
        txt:SetText("")
        banner.text = txt

        banner:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1.0, 0.85, 0.4, 1)
        end)
        banner:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(1.0, 0.7, 0.2, 0.9)
        end)
        banner:SetScript("OnClick", function()
            if BossHelper and BossHelper.ShowUpdateLinksPopup then
                BossHelper:ShowUpdateLinksPopup()
            elseif BossHelper and BossHelper.ShowGitHubLinkPopup then
                -- Fallback if new popup isn't available
                BossHelper:ShowGitHubLinkPopup()
            end
        end)

        frame.updateBanner = banner
    end

    -- Afspil lyd når vinduet lukkes (ESC eller CloseButton)
    frame:SetScript("OnHide", function(self)
        -- Luk også bossNote panel når hele addonet lukkes med ESC
        if self.bossNotePanel and self.bossNotePanel:IsShown() then
            self.bossNotePanel:Hide()
            if rightPanel and rightPanel.bossNoteButton then
                rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
            end
        end
        
        if BossHelperDB and BossHelperDB.allowEscClose then
            SafePlay(BossHelper.Sounds.CLOSE_MENU)
        end
    end)


    local closeButton = CreateCustomButton(frame, 24, 24, "")
    -- use X icon instead of text
    closeButton:SetIcon("Interface\\AddOns\\BossHelper\\Media\\icon\\x2.png")
    if closeButton.icon then
        closeButton.icon:SetSize(16, 16)
        closeButton.icon:ClearAllPoints()
        closeButton.icon:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
        if BossHelper and BossHelper.UI and BossHelper.UI.C and BossHelper.UI.C.TEXT_ORANGE then
            closeButton.icon:SetVertexColor(unpack(BossHelper.UI.C.TEXT_ORANGE))
        end
    end
    if closeButton.text then closeButton.text:Hide() end
    closeButton:SetFrameStrata("HIGH")
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -17, -7)
    closeButton:SetScript("OnClick", function()
        if frame.bossNotePanel and frame.bossNotePanel:IsShown() then
            frame.bossNotePanel:Hide()
            if rightPanel.bossNoteButton then
                rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
            end
        end
        frame:Hide()
    end)
    closeButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.6, 1)
        if self.icon then self.icon:SetVertexColor(1, 1, 1) end
    end)
    closeButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        if self.icon and BossHelper and BossHelper.UI and BossHelper.UI.C and BossHelper.UI.C.TEXT_ORANGE then
            self.icon:SetVertexColor(unpack(BossHelper.UI.C.TEXT_ORANGE))
        end
    end)

    local settingsButton = CreateNavIconButton(-42, "Interface\\AddOns\\BossHelper\\Media\\icon\\settings.png",    13,
        {0.1, 0.5, 1},      {0.6, 0.8, 1},   MakeNavToggle("settings", ShowSettings))
    local infoButton     = CreateNavIconButton(-67, "Interface\\AddOns\\BossHelper\\Media\\icon\\info.png",                  13,
        {0.1, 0.8, 0.3},    {0.3, 0.8, 0.6}, MakeNavToggle("info",     ShowInfo))
    local notesButton    = CreateNavIconButton(-92, "Interface\\AddOns\\BossHelper\\Media\\icon\\square-pen.png", 13,
        {0.45, 0.20, 0.70}, {0.8, 0.3, 1},   MakeNavToggle("notes",    ShowGeneralNotes))


    leftPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftPanel:SetSize(200, 400)
    BossHelper.UI.ApplyBackdrop(leftPanel, "EDITBOX", BossHelper.UI.C.BG_PANEL, BossHelper.UI.C.BORDER_AMBER)

    -- Left panel title
    leftPanel.leftTitle = leftPanel:CreateFontString(nil, "OVERLAY")
    leftPanel.leftTitle:SetFont("Fonts\\FRIZQT___CYR.TTF", 16, "OUTLINE")
    leftPanel.leftTitle:SetPoint("TOP", leftPanel, "TOP", 0, -15)  -- Moved down to align with rightPanel
    leftPanel.leftTitle:SetWidth(180)  -- Set width to fit within panel (200px - padding)
    leftPanel.leftTitle:SetWordWrap(false)  -- Disable word wrapping
    leftPanel.leftTitle:SetNonSpaceWrap(false)  -- Ensure text stays on one line
    leftPanel.leftTitle:SetTextColor(1, 0.5, 0)  -- orange color to match rightPanel
    leftPanel.leftTitle:SetJustifyH("CENTER")

    rightPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 10, 0)
    rightPanel:SetSize(580, 400)
    BossHelper.UI.ApplyBackdrop(rightPanel, "EDITBOX", BossHelper.UI.C.BG_PANEL, BossHelper.UI.C.BORDER_AMBER)

    -- Initial banner refresh once panels exist
    C_Timer.After(0, function()
        if BossUI and BossUI.RefreshUpdateBanner then BossUI:RefreshUpdateBanner() end
        -- Re-anchor banner to the rightPanel width and position above it
        if frame and frame.updateBanner and rightPanel then
            frame.updateBanner:ClearAllPoints()
            frame.updateBanner:SetPoint("BOTTOMLEFT", rightPanel, "TOPLEFT", 0, 6)
            frame.updateBanner:SetPoint("BOTTOMRIGHT", rightPanel, "TOPRIGHT", 0, 6)
        end
    end)

    -- BossNote Panel (fast forbundet til hovedvinduet)
    local bossNotePanel = CreateFrame("Frame", "BossNoteWindow", frame, "BackdropTemplate")
    bossNotePanel:SetSize(200, 400)
    bossNotePanel:SetPoint("TOPLEFT", rightPanel, "TOPRIGHT", 10, 0)
    BossHelper.UI.ApplyBackdrop(bossNotePanel, "EDITBOX", {0.1, 0.08, 0.15, 0.9}, {0.8, 0.3, 1, 0.8})
    bossNotePanel:SetClipsChildren(true)
    bossNotePanel._fullWidth = 200
    bossNotePanel:Hide()
    frame.bossNotePanel = bossNotePanel

    -- Settings Info Panel (hover-forklaring ved settings)
    do
        local _C  = BossHelper.UI.C
        local _BD = BossHelper.UI.ApplyBackdrop

        local sip = CreateFrame("Frame", "BossSettingsInfoWindow", frame, "BackdropTemplate")
        sip:SetSize(200, 400)
        sip:SetPoint("TOPLEFT", rightPanel, "TOPRIGHT", 10, 0)
        _BD(sip, "EDITBOX", _C.BG_PANEL, _C.BORDER_AMBER)
        sip:SetClipsChildren(true)
        sip._fullWidth = 200
        sip:Hide()
        frame.settingsInfoPanel = sip

        -- Layout konstanter (matcher settings-cards)
        local PAD = 8     -- ydre margin inde i sip
        local IPH = 8     -- indre horisontal padding i kort
        local IPV = 8     -- indre vertikal padding i kort
        local CW  = 200 - PAD * 2    -- kortbredde = 184
        local IW  = CW - IPH * 2     -- billed-/tekstbredde = 168

        -- Titel (orange, øverst i panelet, over kortet)
        local titleFS = sip:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        titleFS:SetPoint("TOP", sip, "TOP", 0, -14)
        titleFS:SetWidth(CW)
        titleFS:SetTextColor(1, 0.5, 0)
        titleFS:SetJustifyH("CENTER")
        titleFS:SetWordWrap(false)
        sip._titleFS = titleFS

        -- Én kombineret kort (BG_DARK + BORDER_ORANGE ligesom settings-cards)
        local card = CreateFrame("Frame", nil, sip, "BackdropTemplate")
        card:SetWidth(CW)
        card:SetHeight(60)   -- justeres dynamisk i Load()
        _BD(card, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)
        card:Hide()
        sip._card = card

        -- Billede øverst inde i kortet
        local imgTex = card:CreateTexture(nil, "ARTWORK")
        imgTex:SetSize(IW, IW)
        imgTex:SetPoint("TOP",  card, "TOP",  0,    -IPV)
        imgTex:SetPoint("LEFT", card, "LEFT", IPH,   0)
        imgTex:Hide()
        if card.CreateMaskTexture and imgTex.AddMaskTexture then
            local imgMask = card:CreateMaskTexture()
            imgMask:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Masks\\CoverFadeMask")
            imgMask:SetAllPoints(imgTex)
            imgTex:AddMaskTexture(imgMask)
        end
        sip._imgTex = imgTex

        -- Beskrivelsestekst nedenunder billedet (eller øverst hvis intet billede)
        local descFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descFS:SetWidth(IW)
        descFS:SetJustifyH("LEFT")
        descFS:SetJustifyV("TOP")
        descFS:SetWordWrap(true)
        descFS:SetTextColor(0.98, 0.82, 0.55)
        sip._descFS = descFS

        -- Empty-state hint shown centered when no setting is hovered
        local emptyHint = sip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        emptyHint:SetWidth(IW)
        emptyHint:SetJustifyH("CENTER")
        emptyHint:SetJustifyV("MIDDLE")
        emptyHint:SetWordWrap(true)
        emptyHint:SetTextColor(0.98, 0.82, 0.55)
        emptyHint:SetPoint("CENTER", sip, "CENTER", 0, -8)
        emptyHint:Hide()
        sip._emptyHint = emptyHint

        sip.Load = function(title, desc, imagePath)
            titleFS:SetText(title or "")
            descFS:SetText(desc or "")

            descFS:ClearAllPoints()
            if imagePath then
                imgTex:SetTexture(imagePath)
                imgTex:Show()
                -- tekst under billedet
                descFS:SetPoint("TOPLEFT", imgTex, "BOTTOMLEFT", 0, -IPV)
                local th = descFS:GetStringHeight()
                card:SetHeight(IPV + IW + IPV + th + IPV)
            else
                imgTex:Hide()
                -- tekst fra toppen af kortet
                descFS:SetPoint("TOPLEFT", card, "TOPLEFT", IPH, -IPV)
                local th = descFS:GetStringHeight()
                card:SetHeight(math.max(40, th + IPV * 2))
            end

            card:ClearAllPoints()
            card:SetPoint("TOPLEFT",  sip, "TOPLEFT",  PAD, -42)
            card:SetPoint("TOPRIGHT", sip, "TOPRIGHT", -PAD, -42)
            card:Show()
            if sip._emptyHint then sip._emptyHint:Hide() end
        end

        sip.Reset = function()
            -- Clear title and show centered hint in panel body
            titleFS:SetText("")
            imgTex:Hide()
            card:Hide()
            if sip._emptyHint then
                sip._emptyHint:SetText(Translate("SETTINGS_HOVER_HINT") or "Hover over a setting to see info.")
                sip._emptyHint:Show()
            end
        end
    end

    rightPanel.rightTitle = rightPanel:CreateFontString(nil, "OVERLAY")
    --rightPanel.rightTitle:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    rightPanel.rightTitle:SetFont("Fonts\\FRIZQT___CYR.TTF", 22, "OUTLINE")
    rightPanel.rightTitle:SetPoint("TOP", rightPanel, "TOP", 0, -10)
    rightPanel.rightTitle:SetTextColor(1, 0.5, 0)
    rightPanel.rightTitle:SetJustifyH("CENTER")

    -- Scrollable shortText
    do
        local scroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -40)
        scroll:SetPoint("RIGHT", rightPanel, "RIGHT", -30, 0)
        scroll:SetHeight(300) -- visningshøjde, juster efter ønske
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
        end)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(1, 1)
        scroll:SetScrollChild(content)

        local fstr = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fstr:SetPoint("TOPLEFT", 0, 0)
        fstr:SetWidth(550)         -- wrap-bredde; juster hvis du ændrer panelbredden
        fstr:SetJustifyH("LEFT")
        fstr:SetJustifyV("TOP")
        fstr:SetWordWrap(true)

        rightPanel.rightShortScroll   = scroll
        rightPanel.rightShortContent  = content
        rightPanel.rightShortText     = fstr
    end

    -- Create scrollable detail area
    rightPanel.rightDetailScroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
    rightPanel.rightDetailScroll:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -40)
    rightPanel.rightDetailScroll:SetPoint("RIGHT", rightPanel, "RIGHT", -30, 0)
    rightPanel.rightDetailScroll:SetPoint("BOTTOM", rightPanel, "BOTTOM", 0, 60)
    rightPanel.rightDetailScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
    end)
    
    local detailContent = CreateFrame("Frame", nil, rightPanel.rightDetailScroll)
    detailContent:SetSize(520, 1)
    rightPanel.rightDetailScroll:SetScrollChild(detailContent)
    rightPanel.rightDetailContent = detailContent
    
    rightPanel.rightDetailText = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightPanel.rightDetailText:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 0, 0)
    rightPanel.rightDetailText:SetWidth(520)
    rightPanel.rightDetailText:SetJustifyH("LEFT")
    rightPanel.rightDetailText:SetJustifyV("TOP")
    rightPanel.rightDetailText:SetWordWrap(true)
    
    -- Wrapper function for mixed-alignment content creation
    rightPanel.CreateMixedAlignmentContent = function(text)
        if BossHelper and BossHelper.CreateMixedAlignmentContent then
            return BossHelper:CreateMixedAlignmentContent(text, detailContent)
        end
        return 0 -- fallback hvis Functions.lua ikke er loadet endnu
    end
    
    rightPanel.rightDetailScroll:Hide()

    rightPanel.showingDetails = false
    

    --alt Back Button
    backButton = CreateCustomButton(leftPanel, 180, 30, "BACK")
    backButton:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 10)
    backButton:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.BACK_BUTTON)
        HideAffixesView()
        HideEditModeUI()
        if selectedButton then selectedButton:SetSelected(false); selectedButton = nil end
        frame.selectedBoss = nil
        currentDungeon = nil
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.lastOpenPanel = nil

        BossHelper.UI.hide(rightPanel.phaseDropdown)
        BossHelper.UI.hide(rightPanel.dropdownClickCatcher)
        for _, b in ipairs(rightPanel.shortButtons or {}) do BossHelper.UI.destroyWidget(b) end
        rightPanel.shortButtons = {}
        if rightPanel.shortBtnContent then rightPanel.shortBtnContent:SetHeight(1) end

        ClearRightPanelContent(rightPanel)
        ClearRightPanelSettings()
        ClearRightPanelNotes()
        CloseBossNotePanelIfOpen()
        CloseSettingsInfoPanel(true)

        backButton:Hide()
        ShowStartPage(frame, rightPanel)
        ShowDungeons()
    end)
    backButton:Hide()

    -- (Removed old dual category bar; single Affixes button added dynamically in ShowDungeons)


    rightPanel.detailToggle = CreateCustomButton(rightPanel, 160, 34, Translate("SHOW_DETAILS"))
    rightPanel.detailToggle:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 10, 10)
    rightPanel.detailToggle:Hide()
    rightPanel.detailToggle:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        if not frame.selectedBoss or not currentDungeon then return end
        local boss = frame.selectedBoss  -- frame.selectedBoss er nu en direkte reference til boss-objektet
        if not boss then return end

        if rightPanel.showingDetails then
            -- Hide details and show short content again
            rightPanel.rightDetailText:SetText("")
            rightPanel.rightDetailScroll:Hide()
            rightPanel.detailToggle:SetText(Translate("SHOW_DETAILS"))
            rightPanel.showingDetails = false
            
            -- Show short content again
            if rightPanel.shortBtnScroll then
                rightPanel.shortBtnScroll:Show()
            end
            -- Rebuild short content via ShowBoss (håndterer custom faser og dropdown korrekt)
            BossUI:ShowBoss(rightPanel, boss)
        else
            -- Show details and hide short content
            local detailText = boss.details or ""
            
            -- Use mixed alignment for proper centering
            local totalHeight = rightPanel.CreateMixedAlignmentContent(detailText)
            rightPanel.rightDetailContent:SetHeight(math.max(totalHeight + 20, 100))
            
            -- Hide the old single text frame
            rightPanel.rightDetailText:SetText("")
            
            rightPanel.detailToggle:SetText(Translate("HIDE_DETAILS"))
            rightPanel.showingDetails = true
            
            -- Hide short content and show details
            if rightPanel.shortBtnScroll then
                rightPanel.shortBtnScroll:Hide()
            end
            rightPanel.rightDetailScroll:Show()
        end
    end)

        rightPanel.postButton = CreateCustomButton(rightPanel, 160, 34, "POST_TO_CHAT")
        rightPanel.postButton:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
        rightPanel.postButton:Hide()
        -- Auto-update label whenever the button becomes visible (covers all Show() paths)
        rightPanel.postButton:SetScript("OnShow", function(self)
            UpdatePostButtonLabel(self)
        end)

        -- BossNote knap (kun vis når man ser en boss)
        rightPanel.bossNoteButton = CreateCustomButton(rightPanel, 100, 34, Translate("BOSS_NOTES"))
        rightPanel.bossNoteButton:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -180, 10) -- til venstre for postButton
        rightPanel.bossNoteButton:Hide()
        
        -- BossNote knap funktionalitet
        rightPanel.bossNoteButton:SetScript("OnClick", function()
            if frame.bossNotePanel:IsShown() then
                CloseBossNotePanel(true)
                rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
                SafePlay(BossHelper.Sounds.CLOSE_SETTINGS)
            else
                rightPanel.bossNoteButton:SetText(Translate("BOSS_CLOSE_NOTE"))
                SafePlay(BossHelper.Sounds.OPEN_SETTINGS)
                if not frame.bossNotePanel.initialized then CreateBossNoteContent() end
                if frame.bossNotePanel.LoadNotesForBoss and frame.selectedBoss and currentDungeon then
                    frame.bossNotePanel.LoadNotesForBoss(frame.selectedBoss.encounterID, currentDungeon)
                end
                OpenBossNotePanel(true)
            end
        end)

        BossUI:BuildEditModeUI(rightPanel)

        -- Fill-overlay (vokser fra højre -> venstre)
        do
            local btn = rightPanel.postButton
            btn.fill = btn:CreateTexture(nil, "ARTWORK")
            -- placér til højre og sæt initial width 0 så den vokser mod venstre
            btn.fill:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -4, -4)
            btn.fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 4)
            btn.fill:SetColorTexture(1, 0.5, 0, 0.95) -- varm orange fill
            btn.fill:SetWidth(0)
            btn.fill:Hide()

            -- helper til stop/cleanup af ticker
            btn._stopFill = function(self)
                if self._fillTicker then
                    pcall(function() self._fillTicker:Cancel() end)
                    self._fillTicker = nil
                end
                if self.fill then
                    self.fill:Hide()
                    self.fill:SetWidth(0)
                end
                if self.Enable then pcall(self.Enable, self) end
            end

            -- animate fill over duration seconds
            btn._startFill = function(self, duration)
                duration = tonumber(duration) or 0
                if duration <= 0 then
                    -- ingen animation, blot flash hurtigt
                    self.fill:Show()
                    self.fill:SetWidth(self:GetWidth() - 8)
                    C_Timer.After(0.12, function() if self and self._stopFill then self:_stopFill() end end)
                    return
                end

                -- hvis animationer er ikke-allowed (fx brugeren valgte off i combat), skip
                local canAnimate = true
                if _G.BossHelper_ShouldAnimateInCombat then
                    local ok,res = pcall(_G.BossHelper_ShouldAnimateInCombat)
                    if ok then canAnimate = res else canAnimate = true end
                end
                if not canAnimate then
                    -- vis instant feedback uden animation
                    self.fill:Show()
                    self.fill:SetWidth(self:GetWidth() - 8)
                    C_Timer.After(0.12, function() if self and self._stopFill then self:_stopFill() end end)
                    return
                end

                -- start animation
                if self._fillTicker then pcall(function() self._fillTicker:Cancel() end) end
                self.fill:Show()
                self.fill:SetWidth(0)
                local fullW = math.max(0, (self:GetWidth() - 8))
                local start = GetTime()
                self:Disable() -- undgå ekstra klik mens vi sender
                self._fillTicker = C_Timer.NewTicker(0.01, function(ticker)
                    if not self then
                        ticker:Cancel()
                        return
                    end
                    local now = GetTime()
                    local progress = (now - start) / duration
                    if progress >= 1 then
                        self.fill:SetWidth(fullW)
                        ticker:Cancel()
                        self._fillTicker = nil
                        -- lille pause før vi skjuler fyldet så brugeren kan se at det er færdigt
                        C_Timer.After(0.08, function()
                            if self and self._stopFill then self:_stopFill() end
                        end)
                    else
                        self.fill:SetWidth(math.floor(fullW * progress))
                    end
                end)
            end
        end

        rightPanel.postButton:SetScript("OnClick", function()
            if not frame.selectedBoss or not currentDungeon then
                print("|cffFF4500[BossHelper]|r Select a boss first!")
                return
            end

            -- frame.selectedBoss er en direkte reference til boss-objektet
            local b = frame.selectedBoss
            if b then
                    local textToSend = b.short or ""

                    -- Hvis der er native faser og en fase er valgt
                    if b.phases and #b.phases > 0 and rightPanel.selectedPhaseIndex then
                        local phaseName = b.phases[rightPanel.selectedPhaseIndex]
                        -- Brug custom tekst hvis tilgængelig, ellers native phaseText
                        local customPhaseText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, b.encounterID, phaseName)
                        local phaseText = customPhaseText or (b.phaseText and b.phaseText[phaseName]) or ""
                        textToSend = textToSend .. "\n\n" .. phaseName .. ":\n" .. phaseText
                    elseif BossUI.HasCustomTactics and BossUI.HasCustomTactics(currentDungeon, b.encounterID) then
                        -- Custom taktikker uden native faser (evt. custom faser)
                        local customPhaseList = BossUI.GetCustomPhases and BossUI.GetCustomPhases(currentDungeon, b.encounterID) or {}
                        if #customPhaseList > 1 and rightPanel.selectedPhaseIndex and rightPanel.selectedPhaseIndex <= #customPhaseList then
                            local phaseName = customPhaseList[rightPanel.selectedPhaseIndex]
                            local customText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, b.encounterID, phaseName)
                            if customText and customText ~= "" then textToSend = customText end
                        else
                            local customText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, b.encounterID, nil)
                            if customText and customText ~= "" then textToSend = customText end
                        end
                    end

                    -- Tjek om chat-adgang er låst: brug copy-vindue i stedet for chat
                    local isRestricted, reason = C_ChatInfo.InChatMessagingLockdown()
                    if isRestricted then
                        OpenCopyTextWindow(textToSend)
                        return
                    end

                    -- Send beskeden via BossHelper (den returnerer antal queue-entries den lagde)
                    local added = 0
                    local ok, res = pcall(function() return BossHelper:SendSmartMessage(textToSend) end)
                    if ok and type(res) == "number" then
                        added = res
                    else
                        -- fallback: hvis SendSmartMessage fejler, skriv lokalt og sæt added = 1
                        DEFAULT_CHAT_FRAME:AddMessage("|cffFF4500[BossHelper]|r Failed to enqueue messages (fallback).")
                        added = 1
                    end

                    -- Beregn estimeret varighed
                    local interval = BossHelper.MESSAGE_INTERVAL or 1.5
                    local queueLen = #BossHelper._messageQueue or 0

                    -- Estimat: hvis systemet ikke allerede sender (_isSending==false) så første send sker med det samme,
                    -- så tiden er (added-1) * interval ; ellers tid ≈ queueLen * interval
                    local totalTime = 0
                    if BossHelper._isSending then
                        totalTime = queueLen * interval
                    else
                        -- hvis added==0, sæt minimal tid
                        if added <= 1 then totalTime = 0.1 else totalTime = (added - 1) * interval end
                    end

                    -- Start fill-animation / eller fallback hvis animationer ikke tilladt
                    if rightPanel.postButton and rightPanel.postButton._startFill then
                        rightPanel.postButton:_startFill(totalTime)
                    end

                    SafePlay(BossHelper.Sounds.POST_TO_CHAT)
                    -- Luk vinduet med det samme hvis indstillingen er slået til
                    BossHelperDB = BossHelperDB or {}
                    if BossHelperDB.closeOnPost then
                        pcall(function() frame:Hide() end)
                    end
            end
        end)

    -- Vis startside og dungeons når UI bliver oprettet
    ShowStartPage(frame, rightPanel)
    ShowDungeons() 
end

