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

-- ---------- Sound config ----------
-- Centraliserede lyd-IDs så vi ikke hardcoder tal rundt omkring
BossHelper = BossHelper or {}
BossHelper.Sounds = BossHelper.Sounds or {
    NORMAL_BUTTON  = 1115,   -- normal lyd til knapper
    BOSS_SELECT    = 841,   -- når man vælger en boss
    DUNGEON_SELECT = 841,  -- når man vælger en dungeon i listen
    POST_TO_CHAT   = 271864,   -- når 'Post to chat' afsluttes
    BACK_BUTTON    = 84240,   -- når man klikker på back
    OPEN_SETTINGS  = 84240,   -- når settings åbnes
    CLOSE_SETTINGS = 84240,   -- når settings åbnes
    OPEN_MENU      = 175320,   -- når addonet åbnes
    CLOSE_MENU     = 170887,   -- når addonet lukkes
}

-- Fallback SafePlaySound, hvis BossHelper ikke allerede har en
if not BossHelper.SafePlaySound then
    function BossHelper:SafePlaySound(soundID)
        if type(soundID) == "number" then
            pcall(PlaySound, soundID, "Master")
        end
    end
end
-- ---------- end sound config ----------


-- --- NYT: helper til at rydde settings-widgets hvis de eksisterer ---
local function ClearRightPanelSettings()
    if not rightPanel then return end
    if rightPanel.settingsWidgets then
        for _, w in ipairs(rightPanel.settingsWidgets) do
            if w then
                pcall(function() if w.Hide then w:Hide() end end)
                pcall(function() if w.SetParent then w:SetParent(nil) end end)
                pcall(function() if w.ClearAllPoints then w:ClearAllPoints() end end)
            end
        end
        rightPanel.settingsWidgets = nil
    end

    -- ekstra kendte navne
    pcall(function() if rightPanel.BossSettingsFrame then rightPanel.BossSettingsFrame:Hide() end end)
    pcall(function() if rightPanel.settingsScroll then rightPanel.settingsScroll:Hide() end end)
    pcall(function() if rightPanel.infoScrollFrame then rightPanel.infoScrollFrame:Hide() end end)

    -- ryd evt. fasevalget, så dropdown/fase ikke hænger ved
    pcall(function() rightPanel.selectedPhaseIndex = nil end)
end

-- Clear widgets created by GeneralNotes page
local function ClearRightPanelNotes()
    if not rightPanel then return end
    if rightPanel.notesWidgets then
        for _, w in ipairs(rightPanel.notesWidgets) do
            if w then
                pcall(function() if w.Hide then w:Hide() end end)
                pcall(function() if w.SetParent then w:SetParent(nil) end end)
                pcall(function() if w.ClearAllPoints then w:ClearAllPoints() end end)
            end
        end
        rightPanel.notesWidgets = nil
    end
    if rightPanel._noteButtons then
        for _, b in ipairs(rightPanel._noteButtons) do
            if b then
                pcall(function() if b.Hide then b:Hide() end end)
                pcall(function() if b.SetParent then b:SetParent(nil) end end)
                pcall(function() if b.ClearAllPoints then b:ClearAllPoints() end end)
            end
        end
        rightPanel._noteButtons = nil
    end
    if rightPanel._notesInput then
        pcall(function() if rightPanel._notesInput.Hide then rightPanel._notesInput:Hide() end end)
        pcall(function() if rightPanel._notesInput.SetParent then rightPanel._notesInput:SetParent(nil) end end)
        rightPanel._notesInput = nil
    end
end

-- Helper: Luk Boss Note panelet hvis det er åbent (og nulstil knap-tekst)
local function CloseBossNotePanelIfOpen()
    if frame and frame.bossNotePanel and frame.bossNotePanel:IsShown() then
        frame.bossNotePanel:Hide()
    end
    if rightPanel and rightPanel.bossNoteButton then
        rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
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


-- Animation / combat helper (put dette tidligt i BossUI.lua)
BossHelperDB = BossHelperDB or {}
local function ShouldAnimateInCombat()
    -- Hvis brugeren eksplicit har slået animationer i combat til -> tillad altid
    if BossHelperDB.allowAnimationsInCombat then
        return true
    end
    -- Ellers: kun animation hvis vi ikke er i combat
    return not InCombatLockdown()
end

-- Gør helper globalt tilgængelig for andre filer (f.eks. StartPage.lua)
_G.BossHelper_ShouldAnimateInCombat = ShouldAnimateInCombat


-- Crossfade helper: fade out, kør callback når færdig, så fade in
local function CrossfadeFrameText(fontString, newText, duration)
    duration = duration or 0.12
    if not fontString then return end

    -- hvis animationer ikke er tilladt -> sæt tekst direkte (fallback)
    if not ShouldAnimateInCombat() then
        fontString:SetText(newText or "")
        return
    end

    -- fade out/in via AnimationGroup (kun hvis tilladt)
    local outAG = fontString:CreateAnimationGroup()
    local a1 = outAG:CreateAnimation("Alpha")
    a1:SetFromAlpha(1)
    a1:SetToAlpha(0)
    a1:SetDuration(duration)
    a1:SetSmoothing("OUT")
    outAG:SetScript("OnFinished", function()
        fontString:SetText(newText or "")
        -- fade in
        local inAG = fontString:CreateAnimationGroup()
        local a2 = inAG:CreateAnimation("Alpha")
        a2:SetFromAlpha(0)
        a2:SetToAlpha(1)
        a2:SetDuration(duration)
        a2:SetSmoothing("IN")
        inAG:Play()
    end)
    outAG:Play()
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

-- CreateCustomButton (opgraderet med animationer, men respekterer ShouldAnimateInCombat())
local function CreateCustomButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)

    btn:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    btn.bg:SetPoint("TOPLEFT", 4, -4)
    btn.bg:SetPoint("BOTTOMRIGHT", -4, 4)
    btn.bg:SetColorTexture(1, 0.8, 0.4, 1)

    local t = Translate(text)
    --print("Creating button with text: ", text, " -> localized: ", t)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(t or "")
    btn.text:SetTextColor(0.98, 0.82, 0.55)

    btn.icon = nil
    function btn:SetIcon(texture)
        if not texture then
            if btn.icon then btn.icon:Hide() end
            return
        end
        if not btn.icon then
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(20, 20)
            btn.icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        end
        btn.icon:SetTexture(texture)
        btn.icon:SetAlpha(1)
        btn.icon:Show()
    end

    function btn:SetText(s)
        if btn.text then btn.text:SetText(s) end
    end

    -- Forbered animation-grupper kun hvis animationer er tilladt
    local enterAG, pulseAG
    if ShouldAnimateInCombat() then
        enterAG = btn:CreateAnimationGroup()
        local enterScale = enterAG:CreateAnimation("Scale")
        enterScale:SetScale(1.06, 1.06)
        enterScale:SetDuration(0.12)
        enterScale:SetSmoothing("OUT")
        local enterAlpha = enterAG:CreateAnimation("Alpha")
        enterAlpha:SetFromAlpha(1)
        enterAlpha:SetToAlpha(1)
        enterAlpha:SetDuration(0.12)

        pulseAG = btn:CreateAnimationGroup()
        pulseAG:SetLooping("NONE")
        local pulseOut = pulseAG:CreateAnimation("Scale")
        pulseOut:SetScale(1.10, 1.10)
        pulseOut:SetDuration(0.10)
        pulseOut:SetSmoothing("OUT")
        local pulseIn = pulseAG:CreateAnimation("Scale")
        pulseIn:SetScale(1/1.10, 1/1.10)
        pulseIn:SetDuration(0.10)
        pulseIn:SetSmoothing("IN")
    end

    local function StopAllAnims()
        if enterAG and enterAG:IsPlaying() then enterAG:Stop() end
        if pulseAG and pulseAG:IsPlaying() then pulseAG:Stop() end
    end

    btn:SetScript("OnEnter", function(self)
        -- stop gamle animationer og play hover-lyd
        StopAllAnims()
        if enterAG then enterAG:Play() end

        if not self._isSelected then
            self.bg:SetColorTexture(0.15, 0.15, 0.25, 1)
            self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
            self.text:SetTextColor(1, 0.95, 0.75)
        else
            self.bg:SetColorTexture(1, 0.5, 0, 1)
            self:SetBackdropBorderColor(1, 0.5, 0, 1)
            self.text:SetTextColor(1, 1, 1)
        end
    end)


    btn:SetScript("OnLeave", function(self)
        StopAllAnims()

        if not self._isSelected then
            self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            self.text:SetTextColor(0.98, 0.82, 0.55)
        else
            self.bg:SetColorTexture(1, 0.5, 0, 1)
            self:SetBackdropBorderColor(1, 0.5, 0, 1)
            self.text:SetTextColor(1, 1, 1)
        end
    end)

    function btn:SetSelected(on)
        self._isSelected = on
        if on then
            self.bg:SetColorTexture(1, 0.5, 0, 1)
            self:SetBackdropBorderColor(1, 0.5, 0, 1)
            self.text:SetTextColor(1, 1, 1)
            if pulseAG then pulseAG:Play() end
        else
            self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            self.text:SetTextColor(0.98, 0.82, 0.55)
        end
    end

    btn:SetSelected(false)
    return btn
end

-- Expose for use in EditTactics.lua
BossUI.CreateCustomButton = CreateCustomButton

-- Helper: SelectBoss
local function SelectBoss(bossData, btn)
    HideAffixesView()
    -- Annuller edit mode hvis aktiv (uden at gemme)
    HideEditModeUI()
    if rightPanel.logo then rightPanel.logo:Hide() end
    if rightPanel.mainTitle then rightPanel.mainTitle:SetText("") end
    if rightPanel.mainDesc then rightPanel.mainDesc:SetText("") end
    if rightPanel.footerText then rightPanel.footerText:SetText("") end
    if rightPanel.footerText2 then rightPanel.footerText2:SetText("") end
    if rightPanel.rightTitle then rightPanel.rightTitle:SetText("") end
    if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
    if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
    if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end

    if selectedButton then
        selectedButton:SetSelected(false)
    end

    frame.selectedBoss = bossData  -- gem reference til boss-objektet

    BossUI:ShowBoss(rightPanel, bossData)

    rightPanel.showingDetails = false
    if rightPanel.detailToggle then
        rightPanel.detailToggle:SetText(Translate("SHOW_DETAILS"))
    end

    if rightPanel.postButton then
        rightPanel.postButton:Show()
        UpdatePostButtonLabel(rightPanel.postButton)
    end
    if rightPanel.detailToggle then rightPanel.detailToggle:Show() end
    
    -- Skjul Discord knappen på boss sider
    if rightPanel.discordButton then rightPanel.discordButton:Hide() end
    -- Skjul GitHub knappen på boss sider
    if rightPanel.githubButton then rightPanel.githubButton:Hide() end
    -- Skjul Bug Report knappen på boss sider
    if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
    if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Show() end -- Vis BossNote knap når man ser en boss
    -- Vis edit-taktik knap når man ser en boss
    if rightPanel.editTacticsBtn then
        rightPanel.editTacticsBtn:ClearAllPoints()
        if rightPanel.phaseDropdown and rightPanel.phaseDropdown.mainBtn then
            rightPanel.editTacticsBtn:SetPoint("LEFT", rightPanel.phaseDropdown.mainBtn, "RIGHT", 4, 0)
        else
            rightPanel.editTacticsBtn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 8, -8)
        end
        rightPanel.editTacticsBtn:Show()
    end

    -- Åbn automatisk bossNote panel kun hvis der er en gemt note
    if frame.bossNotePanel then
        -- Tjek om der er en gemt note for denne boss
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
        -- Setting: auto open boss notes (default true if nil)
        local autoOpenNotes = (BossHelperDB.autoOpenBossNotes ~= false)
        
        local bossKey = bossData.encounterID
        local hasNote = false
        if BossHelperDB.bossNotes[currentDungeon] and 
           BossHelperDB.bossNotes[currentDungeon][bossKey] then
            local notesList = BossHelperDB.bossNotes[currentDungeon][bossKey]
            -- Tjek både gamle string format og nye array format
            if type(notesList) == "string" then
                hasNote = (notesList ~= "")
            elseif type(notesList) == "table" then
                hasNote = (#notesList > 0)
            end
        end
        
        if hasNote and autoOpenNotes then
            -- Åbn panelet kun hvis der er en note
            frame.bossNotePanel:Show()
            rightPanel.bossNoteButton:SetText(Translate("BOSS_CLOSE_NOTE"))
            
            -- Opret indhold i bossNote panel hvis det ikke allerede eksisterer
            if not frame.bossNotePanel.initialized then
                CreateBossNoteContent()
            end
            
            -- Load notes for current boss
            if frame.bossNotePanel.LoadNotesForBoss then
                frame.bossNotePanel.LoadNotesForBoss(bossKey, currentDungeon)
            end
        else
            -- Skjul panelet hvis der ikke er en note
            frame.bossNotePanel:Hide()
            rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
        end
    end

    if btn then
        btn:SetSelected(true)
        selectedButton = btn
    end
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
                if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.DUNGEON_SELECT) end
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
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
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
                -- Re-show social / link buttons if they exist
                pcall(function() if rightPanel.discordButton then rightPanel.discordButton:Show() end end)
                pcall(function() if rightPanel.githubButton then rightPanel.githubButton:Show() end end)
                pcall(function() if rightPanel.bugReportButton then rightPanel.bugReportButton:Show() end end)
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
        if frame.bossNotePanel and frame.bossNotePanel:IsShown() then
            frame.bossNotePanel:Hide()
        end
        
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
    -- keep dungeon list visible (do not hide boss buttons list itself)
    if frame and frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            -- buttons remain so player can switch dungeon after viewing affixes
        end
    end
    -- clear right panel (including StartPage elements)
    if rightPanel then
        -- Hide/clear generic boss UI
        pcall(function() if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end end)
        pcall(function() if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end end)
        pcall(function() if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end end)
        pcall(function() if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end end)
        pcall(function() if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end end)
        if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
        if rightPanel.postButton then rightPanel.postButton:Hide() end
        if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Hide() end
    -- Hide social / link buttons too
    pcall(function() if rightPanel.discordButton then rightPanel.discordButton:Hide() end end)
    pcall(function() if rightPanel.githubButton then rightPanel.githubButton:Hide() end end)
    pcall(function() if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end end)
        -- Hide StartPage specific elements if they exist
        pcall(function() if rightPanel.logo then rightPanel.logo:Hide() end end)
        pcall(function() if rightPanel.mainTitle then rightPanel.mainTitle:SetText("") end end)
        pcall(function() if rightPanel.mainDesc then rightPanel.mainDesc:SetText("") end end)
        pcall(function() if rightPanel.footerText then rightPanel.footerText:SetText("") end end)
        pcall(function() if rightPanel.footerText2 then rightPanel.footerText2:SetText("") end end)
    end
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

            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.BOSS_SELECT) end
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

        -- Byg fase-dropdown (native faser + eventuelle custom-kun faser)
        local function CreatePhaseDropdown(parent, boss)
            local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            dropdown:SetSize(140, 26)
            dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -40)

            -- Merged faseliste: native faser + custom-kun faser (ikke "No phase")
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

            -- Hvis kun én fase eksisterer, vis den direkte uden dropdown
            if #mergedPhases == 1 then
                local phaseName = mergedPhases[1]
                local customText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, phaseName)
                local nativeText = boss.phaseText and boss.phaseText[phaseName]
                BuildShortLineButtons(rPanel, customText or nativeText or "")
                dropdown:Hide()
                dropdown:SetParent(nil)
                return nil
            end

            -- Main-knap
            local mainBtn = CreateCustomButton(dropdown, 140, 26, mergedPhases[1] or boss.phases[1])
            mainBtn:SetPoint("TOP", dropdown, "TOP", -419, 30)
            -- Tilføj pil-ikon til dropdown-knappen
            mainBtn.arrow = mainBtn:CreateTexture(nil, "OVERLAY")
            mainBtn.arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
            mainBtn.arrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
            mainBtn.arrow:SetSize(20, 10)
            mainBtn.arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -8, 0)
            mainBtn.arrow:SetAlpha(0.8)
            mainBtn.arrow:SetRotation(0) -- pil ned

            -- Panel med fase-knapper
            local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
            panel:SetSize(140, #mergedPhases * 26)
            panel:SetPoint("TOP", mainBtn, "BOTTOM", 0, -2)
            panel:Hide()
            panel:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            panel:SetBackdropColor(0.08, 0.09, 0.13, 0.95)

            -- Frame-level / strata så den kommer over det meste
            panel:SetFrameStrata("FULLSCREEN_DIALOG")
            panel:SetFrameLevel(2000)
            dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
            dropdown:SetFrameLevel(1999)

            local buttons = {}

            local function SelectPhase(index)
                rPanel.selectedPhaseIndex = index
                for i, btn in ipairs(buttons) do
                    btn:SetSelected(i == index)
                end
                mainBtn:SetText(mergedPhases[index])
                -- Brug custom tekst hvis tilgængelig, ellers native phaseText
                local customText = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, mergedPhases[index])
                local nativeText = boss.phaseText and boss.phaseText[mergedPhases[index]]
                BuildShortLineButtons(rPanel, customText or nativeText or "")
            end

            for i, phaseName in ipairs(mergedPhases) do
                local btn = CreateCustomButton(panel, 140, 26, phaseName)
                btn:SetPoint("TOP", panel, "TOP", 0, -((i-1)*26))
                btn:SetScript("OnClick", function()
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                    SelectPhase(i)
                    panel:Hide()
                    if rPanel.phaseDropdownClickCatcher then
                        rPanel.phaseDropdownClickCatcher:Hide()
                    end
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end -- pil ned
                end)
                table.insert(buttons, btn)
            end

            -- Start med gemt fase eller første fase (bounds-tjek så vi ikke indexer en fase der ikke findes)
            if rPanel.selectedPhaseIndex and rPanel.selectedPhaseIndex <= #mergedPhases then
                SelectPhase(rPanel.selectedPhaseIndex)
            else
                SelectPhase(1)
            end

            -- Opret click-catcher for denne dropdown, parented til UIParent
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
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end -- pil ned
                end
            end)
            rPanel.phaseDropdownClickCatcher = catcher

            -- Main-knap toggler panel
            mainBtn:SetScript("OnClick", function()
                if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                if panel:IsShown() then
                    panel:Hide()
                    if rPanel.phaseDropdownClickCatcher then
                        rPanel.phaseDropdownClickCatcher:Hide()
                    end
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end -- pil ned
                else
                    panel:Show()
                    panel:SetFrameStrata("FULLSCREEN_DIALOG")
                    panel:SetFrameLevel(2000)
                    if rPanel.phaseDropdownClickCatcher then
                        rPanel.phaseDropdownClickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                        rPanel.phaseDropdownClickCatcher:SetFrameLevel(1999)
                        rPanel.phaseDropdownClickCatcher:Show()
                    end
                    -- Optional lille slide/alpha animation hvis du vil
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
                    if mainBtn.arrow then mainBtn.arrow:SetRotation(math.pi) end -- pil op
                end
            end)

            dropdown.mainBtn = mainBtn
            return dropdown
        end

        rPanel.phaseDropdown = CreatePhaseDropdown(rPanel, boss)

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
                -- Multiple custom faser → byg fase-dropdown
                local dropdown = CreateFrame("Frame", nil, rPanel, "BackdropTemplate")
                dropdown:SetSize(140, 26)
                dropdown:SetPoint("TOPRIGHT", rPanel, "TOPRIGHT", -10, -40)

                local mainBtn = CreateCustomButton(dropdown, 140, 26, customPhaseList[1])
                mainBtn:SetPoint("TOP", dropdown, "TOP", -419, 30)
                mainBtn.arrow = mainBtn:CreateTexture(nil, "OVERLAY")
                mainBtn.arrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
                mainBtn.arrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
                mainBtn.arrow:SetSize(20, 10)
                mainBtn.arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -8, 0)
                mainBtn.arrow:SetAlpha(0.8)
                mainBtn.arrow:SetRotation(0)

                local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
                panel:SetSize(140, #customPhaseList * 26)
                panel:SetPoint("TOP", mainBtn, "BOTTOM", 0, -2)
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
                local function SelectCustomPhase(index)
                    rPanel.selectedPhaseIndex = index
                    for i, btn in ipairs(buttons) do btn:SetSelected(i == index) end
                    mainBtn:SetText(customPhaseList[index])
                    local txt = BossUI.GetCustomTacticsText and BossUI.GetCustomTacticsText(currentDungeon, boss.encounterID, customPhaseList[index])
                    BuildShortLineButtons(rPanel, txt or "")
                end

                for i, phaseName in ipairs(customPhaseList) do
                    local btn = CreateCustomButton(panel, 140, 26, phaseName)
                    btn:SetPoint("TOP", panel, "TOP", 0, -((i-1)*26))
                    btn:SetScript("OnClick", function()
                        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                        SelectCustomPhase(i)
                        panel:Hide()
                        if rPanel.phaseDropdownClickCatcher then rPanel.phaseDropdownClickCatcher:Hide() end
                        if mainBtn.arrow then mainBtn.arrow:SetRotation(0) end
                    end)
                    table.insert(buttons, btn)
                end

                if rPanel.selectedPhaseIndex and rPanel.selectedPhaseIndex <= #customPhaseList then
                    SelectCustomPhase(rPanel.selectedPhaseIndex)
                else
                    SelectCustomPhase(1)
                end

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
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
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
                        local ag = panel:CreateAnimationGroup()
                        local t = ag:CreateAnimation("Translation")
                        t:SetOffset(0, 6)
                        t:SetDuration(0.12)
                        t:SetSmoothing("OUT")
                        local a = ag:CreateAnimation("Alpha")
                        a:SetFromAlpha(0)
                        a:SetToAlpha(1)
                        a:SetDuration(0.12)
                        if ShouldAnimateInCombat and ShouldAnimateInCombat() then ag:Play() end
                        if mainBtn.arrow then mainBtn.arrow:SetRotation(math.pi) end
                    end
                end)
                dropdown.mainBtn = mainBtn
                rPanel.phaseDropdown = dropdown
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
        icon = "Interface\\AddOns\\BossHelper\\Media\\Mythic Mentor no te 256x256.tga",
        text = "Mythic Mentor",                 -- teksten TitanPanel kan vise
        label = "Mythic Mentor",                -- nogle LDB-plugins bruger label også
        OnClick = function(_, button)
            if button == "LeftButton" then
                if not frame then
                    if BossUI and BossUI.CreateUI then BossUI:CreateUI() end
                end
                if frame and frame:IsShown() then
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_MENU) end
                    frame:Hide()
                else
                    if frame then
                        frame:Show()
                        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.OPEN_MENU) end
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
                                pcall(function()
                                    if rightPanel and rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
                                    if rightPanel and rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
                                end)
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
                --print("|cffFF4500[BossHelper]|r Right-click: No action")
            end
        end,

        OnTooltipShow = function(tt)
            if not tt or not tt.AddLine then return end
            tt:AddLine("Mythic Mentor")
            tt:AddLine("Left-click: Open Mythic Mentor")
            tt:AddLine("")
        end,
    })


    local function RegisterMinimapIcon()
        -- sikre at savedtable har minimerbar profiltab
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.minimap = BossHelperDB.minimap or { hide = false }
        LibDBIcon:Register("BossHelper", ldbObject, BossHelperDB.minimap)
    end

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
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT) end
            BossHelper:SendSingleSmartMessage(ln) 
        end)

        -- Fjern hover scale-animation (kun farveændring, ingen scale)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.15, 0.15, 0.25, 1)
            self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
            self.text:SetTextColor(1, 0.95, 0.75)
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
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
            -- Ingen animation: sikr at knappen er synlig og fuld alpha
            if btn.SetAlpha then pcall(btn.SetAlpha, btn, 1) end
            if btn.Show then pcall(btn.Show, btn) end
        end

        table.insert(rPanel.shortButtons, btn)
        totalY = totalY + neededH + spacing
    end

    -- adjust scroll content height
    rPanel.shortBtnContent:SetHeight(math.max(totalY - spacing, 1))
end


-- --- Settings er i BossSettings.lua ---
-- Wrapper / fallback (kald BossSettings med kontekst)
function ShowSettings()
    HideAffixesView()
    HideEditModeUI()
    BossHelperDB = BossHelperDB or {}

    -- sikr UI er oprettet (hvis ShowSettings bliver kaldt før CreateUI)
    if not frame and BossUI and BossUI.CreateUI then BossUI:CreateUI() end

    -- skjul normal start-content først, så settings ikke overlapper
    if rightPanel then
        pcall(function()
            if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
            if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
            if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
            -- Skjul Discord knappen på indstillinger siden
            if rightPanel.discordButton then rightPanel.discordButton:Hide() end
            -- Skjul GitHub knappen på indstillinger siden
            if rightPanel.githubButton then rightPanel.githubButton:Hide() end
            -- Skjul Bug Report knappen på indstillinger siden
            if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
            if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
            if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end
            rightPanel.showingDetails = false
            if rightPanel.postButton then rightPanel.postButton:Hide() end
            if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
            if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Hide() end
        end)
    end
    -- Hide Affixes button on settings page
    if leftPanel and leftPanel.affixButton then
        leftPanel.affixButton:Hide()
        leftPanel.affixButton.isAffixActive = false
        leftPanel.affixButton:SetSelected(false)
    end


    -- ryd eventuelle gamle settings-widgets (ekstra sikkert)
    ClearRightPanelSettings()
    ClearRightPanelNotes()
    -- Luk Boss Note panelet hvis det var åbent
    CloseBossNotePanelIfOpen()

    -- sørg for at listen til settings-widgets findes, og giv BossSettings en helper til at tilføje widgets
    if rightPanel then
        rightPanel.settingsWidgets = rightPanel.settingsWidgets or {}
    end
    local function AddSettingsWidget(w)
        if rightPanel and w then table.insert(rightPanel.settingsWidgets, w) end
        return w
    end

    -- marker at settings er åbnet (gem i savedvars så det huskes over /reload)
    BossHelperDB.lastOpenPanel = "settings"

    if BossSettings and BossSettings.ShowSettings then
        BossSettings.ShowSettings{
            frame = frame,
            leftPanel = leftPanel,
            rightPanel = rightPanel,
            backButton = backButton,
            CreateCustomButton = CreateCustomButton,
            BossHelper = BossHelper,
            BossHelperDB = BossHelperDB,
            AddSettingsWidget = AddSettingsWidget, -- <<-- helper medsendes
        }
    else
        print("|cffFF4500[BossUI]|r BossSettings not loaded!")
    end
end

-- --- Info er i BossInfo.lua ---
-- Wrapper / fallback (kald BossInfo med kontekst)
function ShowInfo()
    HideAffixesView()
    HideEditModeUI()
    BossHelperDB = BossHelperDB or {}

    -- sikr UI er oprettet (hvis ShowInfo bliver kaldt før CreateUI)
    if not frame and BossUI and BossUI.CreateUI then BossUI:CreateUI() end

    -- skjul normal start-content først, så info ikke overlapper
    if rightPanel then
        pcall(function()
            -- Skjul startpage elementer
            if rightPanel.logo then rightPanel.logo:Hide() end
            if rightPanel.mainTitle then rightPanel.mainTitle:SetText("") end
            if rightPanel.mainDesc then rightPanel.mainDesc:SetText("") end
            if rightPanel.footerText then rightPanel.footerText:SetText("") end
            if rightPanel.footerText2 then rightPanel.footerText2:SetText("") end
            
            -- Skjul andre UI elementer
            if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
            if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
            if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
            if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
            if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end
            rightPanel.showingDetails = false
            if rightPanel.postButton then rightPanel.postButton:Hide() end
            if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
            -- Skjul Discord knappen på info siden
            if rightPanel.discordButton then rightPanel.discordButton:Hide() end
            -- Skjul GitHub knappen på info siden
            if rightPanel.githubButton then rightPanel.githubButton:Hide() end
            -- Skjul Bug Report knappen på info siden
            if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
        end)
    end
    -- Hide affix button on info page
    if leftPanel and leftPanel.affixButton then
        leftPanel.affixButton:Hide()
        leftPanel.affixButton.isAffixActive = false
        leftPanel.affixButton:SetSelected(false)
    end

    -- ryd eventuelle gamle settings-widgets (ekstra sikkert)
    ClearRightPanelSettings()
    ClearRightPanelNotes()
    -- Luk Boss Note panelet hvis det var åbent
    CloseBossNotePanelIfOpen()

    -- marker at info er åbnet (gem i savedvars så det huskes over /reload)
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

-- (Notes top-level side fjernet: vi beholder kun boss-specifikke noter via bossNotePanelet)
-- Tilføjet: General Notes som en separat side med kategorier

function ShowGeneralNotes()
    HideAffixesView()
    HideEditModeUI()
    BossHelperDB = BossHelperDB or {}

    -- ensure UI exists
    if not frame and BossUI and BossUI.CreateUI then BossUI:CreateUI() end

    -- hide other content on right panel
    if rightPanel then
        pcall(function()
            if rightPanel.logo then rightPanel.logo:Hide() end
            if rightPanel.mainTitle then rightPanel.mainTitle:SetText("") end
            if rightPanel.mainDesc then rightPanel.mainDesc:SetText("") end
            if rightPanel.footerText then rightPanel.footerText:SetText("") end
            if rightPanel.footerText2 then rightPanel.footerText2:SetText("") end
            if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
            if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
            if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
            if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
            if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end
            rightPanel.showingDetails = false
            if rightPanel.postButton then rightPanel.postButton:Hide() end
            if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
            if rightPanel.discordButton then rightPanel.discordButton:Hide() end
            if rightPanel.githubButton then rightPanel.githubButton:Hide() end
            if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
            if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Hide() end
        end)
    end
    -- Hide affix button on general notes page
    if leftPanel and leftPanel.affixButton then
        leftPanel.affixButton:Hide()
        leftPanel.affixButton.isAffixActive = false
        leftPanel.affixButton:SetSelected(false)
    end

    ClearRightPanelSettings()
    -- Luk Boss Note panelet hvis det var åbent
    CloseBossNotePanelIfOpen()

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

-- CreateBossNoteContent - Opret indhold til BossNote panelet
function CreateBossNoteContent()
    local panel = frame.bossNotePanel
    if not panel then return end
    
    -- Titel
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -15)
    title:SetTextColor(0.8, 0.3, 1) -- lilla farve
    title:SetText(Translate("BOSS_NOTES"))
    
    -- Scroll frame for noter (toppen af panelet) - justeret størrelse
    local notesScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    notesScroll:SetSize(160, 310) -- bred nok til noter, reduceret højde lidt
    notesScroll:SetPoint("TOP", title, "BOTTOM", -10, -8) -- justeret position
    
    local notesContent = CreateFrame("Frame", nil, notesScroll)
    notesContent:SetSize(180, 1) -- lidt bredere end scroll frame
    notesScroll:SetScrollChild(notesContent)
    
    -- Text frame for at vise noter
    local notesText = notesContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notesText:SetPoint("TOPLEFT", notesContent, "TOPLEFT", 5, -5)
    notesText:SetWidth(160)
    notesText:SetJustifyH("LEFT")
    notesText:SetJustifyV("TOP")
    notesText:SetWordWrap(true)
    notesText:SetText("")
    
    -- Input EditBox i bunden - flyttet længere ned
    local inputBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    inputBox:SetSize(170, 20)
    inputBox:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    inputBox:SetAutoFocus(false)
    inputBox:SetFontObject("ChatFontNormal")
    inputBox:SetText("")

    -- Track current in-place edit (index in source list and button reference)
    panel._editingRef = nil

    -- Helper: start editing a given visible note button
    local function BeginEditing(btn, idx, noteText)
        -- restore any previous button visuals if present
        if panel._editingRef and panel._editingRef.btn and panel._editingRef.btn ~= btn then
            local pbtn = panel._editingRef.btn
            pcall(function()
                if pbtn._origAlpha then pbtn:SetAlpha(pbtn._origAlpha) end
                if pbtn.text and pbtn.text._origColor then
                    local c = pbtn.text._origColor
                    pbtn.text:SetTextColor(c[1], c[2], c[3], c[4])
                end
                if pbtn.EnableMouse then pbtn:EnableMouse(true) end
            end)
        end

        panel._editingRef = { index = idx, btn = btn }
        if inputBox then
            inputBox:SetText((noteText or ""):gsub("^• ", ""))
            inputBox:SetFocus()
        end
        -- Apply grey/transparent visual
        pcall(function()
            btn._origAlpha = btn:GetAlpha() or 1
            btn:SetAlpha(0.45)
            if btn.text and btn.text.GetTextColor then
                local r,g,b,a = btn.text:GetTextColor()
                btn.text._origColor = {r,g,b,a}
                btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
            end
            if btn.EnableMouse then btn:EnableMouse(false) end
        end)
    end
    
    -- Label for input
    local inputLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    inputLabel:SetPoint("BOTTOM", inputBox, "TOP", 0, 3)
    inputLabel:SetText(Translate("ADD_NOTE_TIP"))
    inputLabel:SetTextColor(0.98, 0.82, 0.55)
    
    -- Array til at holde styr på note knapper
    panel.noteButtons = panel.noteButtons or {}
    
    -- Funktion til at opdatere noter display
    local function UpdateNotesDisplay(bossName, dungeonName)
        if not (bossName and dungeonName) then 
            -- Skjul alle gamle note knapper
            if panel.noteButtons then
                for _, btn in ipairs(panel.noteButtons) do
                    btn:Hide()
                    btn:SetParent(nil)
                end
            end
            panel.noteButtons = {}
            notesText:SetText("")
            return 
        end
        
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
        BossHelperDB.bossNotes[dungeonName] = BossHelperDB.bossNotes[dungeonName] or {}
        BossHelperDB.bossNotes[dungeonName][bossName] = BossHelperDB.bossNotes[dungeonName][bossName] or {}
        
        local notesList = BossHelperDB.bossNotes[dungeonName][bossName]
        if type(notesList) == "string" then
            -- Konverter gamle string noter til array format
            if notesList ~= "" then
                BossHelperDB.bossNotes[dungeonName][bossName] = {notesList}
                notesList = BossHelperDB.bossNotes[dungeonName][bossName]
            else
                BossHelperDB.bossNotes[dungeonName][bossName] = {}
                notesList = {}
            end
        end
        
        -- Skjul og ryd op i alle gamle note knapper og deres børn
        if panel.noteButtons then
            for _, btn in ipairs(panel.noteButtons) do
                -- Skjul og ryd børn (edit og delete knapper)
                local children = {btn:GetChildren()}
                for _, child in ipairs(children) do
                    child:Hide()
                    child:SetParent(nil)
                end
                -- Skjul og ryd hovedknappen
                btn:Hide()
                btn:SetParent(nil)
            end
        end
        panel.noteButtons = {}
        
        -- Skjul text (vi bruger knapper i stedet)
        notesText:SetText("")
        
        -- Lav knapper for hver note (nyeste øverst)
        local totalY = 0
        local btnWidth = 160 -- kortere note baggrund så scroll bar får plads
        local minBtnH = 26
        local paddingX = 8
        local paddingTop = 6
        local paddingBot = 6
        local spacing = 6
        local iconSpace = 0 -- ingen ekstra plads - teksten kan gå helt til højre
        
        for i = #notesList, 1, -1 do
            if notesList[i] and notesList[i] ~= "" then
                local btn = CreateCustomButton(notesContent, btnWidth, minBtnH, "")
                btn:SetPoint("TOPLEFT", notesContent, "TOPLEFT", 0, -totalY)

                -- Sæt tekst med bullet point
                btn.text:ClearAllPoints()
                btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", paddingX, -paddingTop)
                btn.text:SetPoint("RIGHT", btn, "RIGHT", -paddingX, 0)
                btn.text:SetJustifyH("LEFT")
                btn.text:SetJustifyV("TOP")
                btn.text:SetWordWrap(true)
                btn.text:SetNonSpaceWrap(true)
                btn.text:SetWidth(btnWidth - (paddingX * 2))
                btn:SetText(notesList[i])

                local textH = btn.text:GetStringHeight() or 0
                if textH == 0 then
                    btn.text:SetText(btn.text:GetText() or "")
                    textH = btn.text:GetStringHeight() or 0
                end

                local neededH = math.max(minBtnH, math.ceil(textH + paddingTop + paddingBot))
                btn:SetHeight(neededH)

                btn.text:ClearAllPoints()
                btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", paddingX, -paddingTop)
                btn.text:SetPoint("RIGHT", btn, "RIGHT", -paddingX, 0) -- ingen iconSpace så teksten fylder hele bredden
                btn.text:SetHeight(textH)

                btn:SetScript("OnClick", function()
                    if BossHelper and BossHelper.SafePlaySound then
                        BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT)
                    end
                    BossHelper:SendSingleSmartMessage(notesList[i])
                end)

                local deleteIcon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                deleteIcon:SetText("X")
                deleteIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                deleteIcon:SetTextColor(1, 0.2, 0.2)

                local deleteBtn = CreateFrame("Button", nil, btn)
                deleteBtn:SetSize(12, 12)
                deleteBtn:EnableMouse(true)

                local editIcon = btn:CreateTexture(nil, "OVERLAY")
                editIcon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
                editIcon:SetSize(11, 11)
                editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)

                local editBtn = CreateFrame("Button", nil, btn)
                editBtn:SetSize(13, 13)
                editBtn:EnableMouse(true)

                -- Delete knappen helt til højre i toppen
                deleteIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, -1)
                deleteBtn:SetPoint("CENTER", deleteIcon, "CENTER", 0, 0)

                -- Edit knappen lige under delete knappen
                editIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -14)
                editBtn:SetPoint("CENTER", editIcon, "CENTER", 0, 0)

                local noteText = notesList[i]
                editBtn:SetScript("OnClick", function()
                    -- In-place edit: do not remove, just mark visually and populate input
                    BeginEditing(btn, i, noteText)
                end)

                deleteBtn:SetScript("OnClick", function()
                    ConfirmDialog.Show({
                        title   = (Translate and Translate("CONFIRM_DELETE_NOTE_TITLE")) or "Slet note",
                        message = (Translate and Translate("CONFIRM_DELETE_NOTE")) or "Er du sikker på, at du vil slette denne boss note?",
                        onOk    = function()
                        local currentNotes = BossHelperDB.bossNotes[dungeonName][bossName]
                        -- if deleting the one being edited, cancel edit state first
                        if panel._editingRef and panel._editingRef.index == i then
                            panel._editingRef = nil
                            inputBox:SetText("")
                        end
                        table.remove(currentNotes, i)
                        UpdateNotesDisplay(bossName, dungeonName)
                        end,
                    })
                end)

                -- Gør ikonerne gensidigt eksklusive på hover
                editBtn:SetScript("OnEnter", function(self)
                    editIcon:SetVertexColor(1, 1, 1, 1)
                    deleteIcon:Hide(); deleteBtn:Hide()
                end)
                editBtn:SetScript("OnLeave", function(self)
                    editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
                    if not deleteBtn:IsMouseOver() then
                        editIcon:Hide(); editBtn:Hide(); deleteIcon:Hide(); deleteBtn:Hide()
                    end
                end)

                deleteBtn:SetScript("OnEnter", function(self)
                    deleteIcon:SetTextColor(1, 1, 1)
                    editIcon:Hide(); editBtn:Hide()
                end)
                deleteBtn:SetScript("OnLeave", function(self)
                    deleteIcon:SetTextColor(1, 0.2, 0.2)
                    if not editBtn:IsMouseOver() then
                        editIcon:Hide(); editBtn:Hide(); deleteIcon:Hide(); deleteBtn:Hide()
                    end
                end)

                -- Skjul edit og delete knapper som standard
                editIcon:Hide()
                deleteIcon:Hide()
                editBtn:Hide()
                deleteBtn:Hide()
                
                -- Vis knapperne når musen er over noten (og behold original hover effekt)
                local originalOnEnter = btn:GetScript("OnEnter")
                btn:SetScript("OnEnter", function(self)
                    -- Kør original hover effekt først
                    if originalOnEnter then originalOnEnter(self) end
                    -- Vis edit/delete knapper
                    editIcon:Show()
                    deleteIcon:Show()
                    editBtn:Show()
                    deleteBtn:Show()
                end)
                
                -- Skjul knapperne når musen forlader noten (og behold original hover effekt)
                local originalOnLeave = btn:GetScript("OnLeave")
                btn:SetScript("OnLeave", function(self)
                    -- Tjek om musen er over edit eller delete knapper
                    local mouseOverChild = false
                    if editBtn:IsMouseOver() or deleteBtn:IsMouseOver() then
                        mouseOverChild = true
                    end
                    
                    -- Kun kør leave effekt hvis musen ikke er over børn
                    if not mouseOverChild then
                        -- Kør original hover effekt først
                        if originalOnLeave then originalOnLeave(self) end
                        -- Skjul edit/delete knapper
                        editIcon:Hide()
                        deleteIcon:Hide()
                        editBtn:Hide()
                        deleteBtn:Hide()
                    end
                end)

                -- Re-apply edit visuals if this index is currently being edited
                if panel._editingRef and panel._editingRef.index == i then
                    -- update ref button pointer to this rebuilt button
                    panel._editingRef.btn = btn
                    pcall(function()
                        btn._origAlpha = btn:GetAlpha() or 1
                        btn:SetAlpha(0.45)
                        if btn.text and btn.text.GetTextColor then
                            local r,g,b,a = btn.text:GetTextColor()
                            btn.text._origColor = {r,g,b,a}
                            btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
                        end
                        if btn.EnableMouse then btn:EnableMouse(false) end
                    end)
                end

                table.insert(panel.noteButtons, btn)
                table.insert(panel.noteButtons, editBtn)
                table.insert(panel.noteButtons, deleteBtn)
                btn.editIcon = editIcon
                btn.deleteIcon = deleteIcon
                totalY = totalY + neededH + spacing
            end
        end

        
        -- Opdater scroll content højde
        notesContent:SetHeight(math.max(totalY - spacing, 250))
    end
    
    -- Commit helper for both editing updates and adding new notes
    local function CommitIfEditingOrAdd(self)
        local noteText = (self:GetText() or ""):trim()
        local currentBoss = frame.selectedBoss and frame.selectedBoss.encounterID
        local currentDung = currentDungeon
        if not (currentBoss and currentDung) then return false end

        BossHelperDB = BossHelperDB or {}
        BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
        BossHelperDB.bossNotes[currentDung] = BossHelperDB.bossNotes[currentDung] or {}
        BossHelperDB.bossNotes[currentDung][currentBoss] = BossHelperDB.bossNotes[currentDung][currentBoss] or {}
        local list = BossHelperDB.bossNotes[currentDung][currentBoss]

        if panel._editingRef then
            local idx = panel._editingRef.index
            if noteText ~= "" and type(list) == "table" and list[idx] ~= nil then
                list[idx] = noteText
            end
            self:SetText("")
            panel._editingRef = nil
            UpdateNotesDisplay(currentBoss, currentDung)
            return true
        else
            if noteText ~= "" then
                table.insert(list, noteText)
                self:SetText("")
                UpdateNotesDisplay(currentBoss, currentDung)
                return true
            end
        end
        return false
    end

    -- Håndter Enter-tryk for at tilføje eller gemme redigering
    inputBox:SetScript("OnEnterPressed", function(self)
        CommitIfEditingOrAdd(self)
        self:ClearFocus()
    end)

    -- Escape: annuller redigering/tilføjelse
    inputBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        panel._editingRef = nil
        local currentBoss = frame.selectedBoss and frame.selectedBoss.encounterID
        local currentDung = currentDungeon
        if currentBoss and currentDung then
            UpdateNotesDisplay(currentBoss, currentDung)
        end
        self:ClearFocus()
    end)

    -- Fokus tabt: gem redigering hvis muligt (tilføjer ikke tomme noter)
    inputBox:SetScript("OnEditFocusLost", function(self)
        CommitIfEditingOrAdd(self)
    end)
    
    -- Load saved notes when boss changes
    panel.LoadNotesForBoss = function(bossName, dungeonName)
        UpdateNotesDisplay(bossName, dungeonName)
    end
    
    -- Close button for panel
    local closeBtn = CreateCustomButton(panel, 20, 20, "X")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
    closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    closeBtn:SetScript("OnClick", function()
        rightPanel.bossNoteButton:GetScript("OnClick")() -- trigger samme logik som hovedknappen
    end)
    
    panel.initialized = true
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
        banner:SetBackdrop({
            bgFile   = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        banner:SetBackdropColor(0.12, 0.08, 0.02, 0.95) -- dark amber
        banner:SetBackdropBorderColor(1.0, 0.7, 0.2, 0.9)
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
        
        if BossHelper and BossHelper.SafePlaySound and BossHelper.Sounds and BossHelper.Sounds.CLOSE_MENU then
            if BossHelperDB and BossHelperDB.allowEscClose then
                BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_MENU)
            end
        end
    end)


    local closeButton = CreateCustomButton(frame, 24, 24, "X")
    closeButton.text:ClearAllPoints()
    closeButton.text:SetPoint("CENTER", closeButton, "CENTER", 2, 0)
    closeButton:SetFrameStrata("HIGH")
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -17, -7)
    closeButton.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    closeButton:SetScript("OnClick", function()
        --if BossHelper and BossHelper.SafePlaySound and BossHelper.Sounds and BossHelper.Sounds.CLOSE_MENU then
        --    BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_MENU)
       -- end
        -- Luk også bossNote panel når hele addonet lukkes
        if frame.bossNotePanel and frame.bossNotePanel:IsShown() then
            frame.bossNotePanel:Hide()
            if rightPanel.bossNoteButton then
                rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
            end
        end
        frame:Hide()
    end)
    closeButton:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(1, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.6, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    closeButton:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        self.text:SetTextColor(0.98, 0.82, 0.55)
    end)

    -- Settings-knap
    local settingsButton = CreateCustomButton(frame, 24, 24, "")
    settingsButton:SetFrameStrata("HIGH")
    settingsButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    settingsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -7) -- lidt til venstre for close-knappen

    -- Tilføj ikon som en Texture (så vi kan styre placering/størrelse)
    settingsButton.icon = settingsButton:CreateTexture(nil, "OVERLAY")
    settingsButton.icon:SetTexture("Interface\\GossipFrame\\BinderGossipIcon") -- klassisk gear ikon
    settingsButton.icon:SetSize(16, 16) -- gør ikonet mindre
    settingsButton.icon:SetPoint("CENTER", settingsButton, "CENTER", 0, 0) -- centrer det

    settingsButton:SetScript("OnClick", function()
    BossHelperDB = BossHelperDB or {}

    if BossHelperDB.lastOpenPanel == "settings" then
        -- play close (vi går tilbage)
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_SETTINGS) end
        backButton:GetScript("OnClick")()
    else
        -- play open settings
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.OPEN_SETTINGS) end
        ShowSettings()
    end
end)





    settingsButton:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.1, 0.5, 1, 1)
        self:SetBackdropBorderColor(0.6, 0.8, 1, 1)
    end)

    settingsButton:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)

    -- Info-knap (samme stil som Settings-knap)
    local infoButton = CreateCustomButton(frame, 24, 24, "")
    infoButton:SetFrameStrata("HIGH")
    infoButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    infoButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -67, -7) -- til venstre for settings-knappen

    -- Tilføj ikon som en Texture (info ikon)
    infoButton.icon = infoButton:CreateTexture(nil, "OVERLAY")
    infoButton.icon:SetTexture("Interface\\Common\\help-i") -- info ikon
    infoButton.icon:SetSize(22, 22)
    infoButton.icon:SetPoint("CENTER", infoButton, "CENTER", 0, 0) -- centrer det

    infoButton:SetScript("OnClick", function()
        BossHelperDB = BossHelperDB or {}

        if BossHelperDB.lastOpenPanel == "info" then
            -- play close (vi går tilbage)
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_SETTINGS) end
            backButton:GetScript("OnClick")()
        else
            -- play open info
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.OPEN_SETTINGS) end
            ShowInfo()
        end
    end)

    infoButton:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.1, 0.8, 0.3, 1) -- grøn farve for info
        self:SetBackdropBorderColor(0.3, 0.8, 0.6, 1)
    end)

    infoButton:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)

    -- Notes-knap (åbner General Notes)
    local notesButton = CreateCustomButton(frame, 24, 24, "")
    notesButton:SetFrameStrata("HIGH")
    notesButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    notesButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -92, -7)

    notesButton.icon = notesButton:CreateTexture(nil, "OVERLAY")
    notesButton.icon:SetTexture("Interface\\GossipFrame\\WorkOrderGossipIcon") -- notes ikon
    notesButton.icon:SetSize(18, 18)
    notesButton.icon:SetPoint("CENTER", notesButton, "CENTER", 0, 0)

    notesButton:SetScript("OnClick", function()
        BossHelperDB = BossHelperDB or {}
        if BossHelperDB.lastOpenPanel == "notes" then
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_SETTINGS) end
            backButton:GetScript("OnClick")()
        else
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.OPEN_SETTINGS) end
            ShowGeneralNotes()
        end
    end)

    notesButton:SetScript("OnEnter", function(self)
        -- Lilla hover som matcher BossNotePanel kanten (0.8, 0.3, 1)
        self.bg:SetColorTexture(0.45, 0.20, 0.70, 1)
        self:SetBackdropBorderColor(0.8, 0.3, 1, 1)
    end)
    notesButton:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)


    leftPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftPanel:SetSize(200, 400)
    leftPanel:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    leftPanel:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
    leftPanel:SetBackdropBorderColor(1, 0.5, 0, 0.8)

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
    rightPanel:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    rightPanel:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
    rightPanel:SetBackdropBorderColor(1, 0.5, 0, 0.8)

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
    bossNotePanel:SetSize(200, 400) -- samme størrelse som leftPanel
    bossNotePanel:SetPoint("TOPLEFT", rightPanel, "TOPRIGHT", 10, 0) -- fast position ved siden af rightPanel
    bossNotePanel:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    bossNotePanel:SetBackdropColor(0.1, 0.08, 0.15, 0.9) -- lidt forskellig farve
    bossNotePanel:SetBackdropBorderColor(0.8, 0.3, 1, 0.8) -- lilla kant
    bossNotePanel:Hide() -- skjult som standard
    frame.bossNotePanel = bossNotePanel

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
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.BACK_BUTTON) end
        HideAffixesView()
        -- Reset selection state
        if selectedButton then
            selectedButton:SetSelected(false)
            selectedButton = nil
        end
        frame.selectedBoss = nil
        currentDungeon = nil

        -- brugeren er nu på start/ikke-settings, ryd evt. saved-flag
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.lastOpenPanel = nil


        -- Skjul dropdown og click-catcher (sikkert med pcall)
        if rightPanel.phaseDropdown then pcall(rightPanel.phaseDropdown.Hide, rightPanel.phaseDropdown) end
        if rightPanel.dropdownClickCatcher then pcall(rightPanel.dropdownClickCatcher.Hide, rightPanel.dropdownClickCatcher) end

        -- Annuller edit mode hvis aktiv
        HideEditModeUI()

        -- Clear short-buttons area (scroll + content + knapper)
        if rightPanel.shortBtnScroll then pcall(rightPanel.shortBtnScroll.Hide, rightPanel.shortBtnScroll) end
        if rightPanel.shortBtnContent then pcall(rightPanel.shortBtnContent.SetHeight, rightPanel.shortBtnContent, 1) end
        if rightPanel.shortButtons then
            for _, b in ipairs(rightPanel.shortButtons) do
                if b then
                    pcall(b.Hide, b)
                    pcall(b.SetParent, b, nil)
                    if b.ClearAllPoints then pcall(b.ClearAllPoints, b) end
                end
            end
        end
        rightPanel.shortButtons = {}

        -- Skjul også det gamle scroll-text hvis det er vist
        if rightPanel.rightShortScroll then pcall(rightPanel.rightShortScroll.Hide, rightPanel.rightShortScroll) end
        if rightPanel.rightShortText then pcall(rightPanel.rightShortText.SetText, rightPanel.rightShortText, "") end

        -- Reset titel / detaljer
        if rightPanel.rightTitle then pcall(rightPanel.rightTitle.SetText, rightPanel.rightTitle, "") end
        if rightPanel.rightDetailText then pcall(rightPanel.rightDetailText.SetText, rightPanel.rightDetailText, "") end
        if rightPanel.rightDetailScroll then pcall(rightPanel.rightDetailScroll.Hide, rightPanel.rightDetailScroll) end
        rightPanel.showingDetails = false
        if rightPanel.detailToggle then pcall(rightPanel.detailToggle.SetText, rightPanel.detailToggle, Translate("SHOW_DETAILS")) end

        -- Ryd op i settings-widgets hvis vi kom fra Settings
        ClearRightPanelSettings()
    -- Ryd op i notes-widgets hvis vi kom fra GeneralNotes
    ClearRightPanelNotes()

        -- Luk automatisk bossNote panel når man går tilbage
        if frame.bossNotePanel and frame.bossNotePanel:IsShown() then
            frame.bossNotePanel:Hide()
        end
        
        -- Skjul bossNote knappen når man forlader boss-visning
        if rightPanel.bossNoteButton then
            rightPanel.bossNoteButton:Hide()
            rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
        end

        -- Gem back-knappen og vis startside + dungeons
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
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
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
        rightPanel.bossNoteButton:SetScript("OnClick", function()            if frame.bossNotePanel:IsShown() then
                -- Luk bossNote panel
                frame.bossNotePanel:Hide()
                rightPanel.bossNoteButton:SetText(Translate("BOSS_NOTES"))
                if BossHelper and BossHelper.SafePlaySound then 
                    BossHelper:SafePlaySound(BossHelper.Sounds.CLOSE_SETTINGS) 
                end
            else
                -- Åbn bossNote panel ved siden af hovedvinduet
                frame.bossNotePanel:Show()

                rightPanel.bossNoteButton:SetText(Translate("BOSS_CLOSE_NOTE"))
                if BossHelper and BossHelper.SafePlaySound then
                    BossHelper:SafePlaySound(BossHelper.Sounds.OPEN_SETTINGS)
                end
                
                -- Opret indhold i bossNote panel hvis det ikke allerede eksisterer
                if not frame.bossNotePanel.initialized then
                    CreateBossNoteContent()
                end
                
                -- Load notes for current boss
                if frame.bossNotePanel.LoadNotesForBoss and frame.selectedBoss and currentDungeon then
                    local bossKey = frame.selectedBoss.encounterID
                    frame.bossNotePanel.LoadNotesForBoss(bossKey, currentDungeon)
                end
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

                     -- spil en lyd
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT) end

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

