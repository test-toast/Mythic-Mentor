-- BossUI.lua
-- Alt UI-kode; forventer at BossHelper, BossData og ShowStartPage(frame, rightPanel) er tilgængelige

BossUI = {}

local frame, leftPanel, rightPanel, backButton
local selectedButton = nil
local currentDungeon = nil
--Anderts: forward declaration
local BuildShortLineButtons  -- forward declaration
local ShowSettings, SelectSettingCategory, BuildSettingsCategoryUI

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

    -- ryd evt. fasevalget, så dropdown/fase ikke hænger ved
    pcall(function() rightPanel.selectedPhaseIndex = nil end)
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

-- Udskift Tank / Healer / DPS med ikoner
local function ReplaceRoleIcons(text)
    -- Tank: ikon + rød tekst
    -- Healer
    text = text:gsub("([Hh]ealer)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:0:64|t|cFF00FF00%1|r")
    -- Tank
    text = text:gsub("([Tt]ank)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:0:61:69:130|t|cFF0099FF%1|r")
    -- DPS
    text = text:gsub("([Dd][Pp][Ss])", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:69:130|t|cFFFF0000%1|r")
    
    -- ruRU
    -- Хилер (Healer)
    text = text:gsub("(Хилер)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:0:64|t|cFF00FF00%1|r")
    text = text:gsub("(хилер)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:0:64|t|cFF00FF00%1|r")

    -- Танк (Tank)
    text = text:gsub("(Танк)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:0:61:69:130|t|cFF0099FF%1|r")
    text = text:gsub("(танк)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:0:61:69:130|t|cFF0099FF%1|r")

    -- ДПС (DPS)
    text = text:gsub("(ДПС)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:69:130|t|cFFFF0000%1|r")

    -- deDE
    -- Heiler (Healer)
    text = text:gsub("([Hh]eiler)", "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:256:69:130:0:64|t|cFF00FF00%1|r")

    
    return text
end


-- CreateCustomButton (opgraderet med animationer, men respekterer ShouldAnimateInCombat())
local function CreateCustomButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)

    btn:SetBackdrop({
        bgFile = "Interface/Tooltips/ChatBubble-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    btn:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
    btn:SetBackdropBorderColor(0.06, 0.06, 0.06, 0.8)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
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
    local enterAG, leaveAG, pulseAG
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

        leaveAG = btn:CreateAnimationGroup()
        local leaveScale = leaveAG:CreateAnimation("Scale")
        leaveScale:SetScale(1/1.06, 1/1.06)
        leaveScale:SetDuration(0.12)
        leaveScale:SetSmoothing("OUT")

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
        if leaveAG and leaveAG:IsPlaying() then leaveAG:Stop() end
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
            self.bg:SetColorTexture(1, 0.7, 0.1, 1)
            self:SetBackdropBorderColor(1, 0.7, 0.1, 1)
            self.text:SetTextColor(1, 1, 1)
        end
    end)


    btn:SetScript("OnLeave", function(self)
        StopAllAnims()
        if leaveAG then leaveAG:Play() end

        if not self._isSelected then
            self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
            self:SetBackdropBorderColor(0.06, 0.06, 0.06, 0.8)
            self.text:SetTextColor(0.98, 0.82, 0.55)
        else
            self.bg:SetColorTexture(1, 0.7, 0.1, 1)
            self:SetBackdropBorderColor(1, 0.7, 0.1, 1)
            self.text:SetTextColor(1, 1, 1)
        end
    end)

    function btn:SetSelected(on)
        self._isSelected = on
        if on then
            self.bg:SetColorTexture(1, 0.7, 0.1, 1)
            self:SetBackdropBorderColor(1, 0.7, 0.1, 1)
            self.text:SetTextColor(1, 1, 1)
            if pulseAG then pulseAG:Play() end
        else
            self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
            self:SetBackdropBorderColor(0.06, 0.06, 0.06, 0.8)
            self.text:SetTextColor(0.98, 0.82, 0.55)
        end
    end

    btn:SetSelected(false)
    return btn
end


-- Helper: SelectBoss
local function SelectBoss(bossName, btn)
    if rightPanel.logo then rightPanel.logo:Hide() end
    if rightPanel.mainTitle then rightPanel.mainTitle:SetText("") end
    if rightPanel.mainDesc then rightPanel.mainDesc:SetText("") end
    if rightPanel.footerText then rightPanel.footerText:SetText("") end
    if rightPanel.footerText2 then rightPanel.footerText2:SetText("") end
    if rightPanel.rightTitle then rightPanel.rightTitle:SetText("") end
    if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
    if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end

    if selectedButton then
        selectedButton:SetSelected(false)
    end

    frame.selectedBoss = bossName
    if rightPanel.rightTitle then rightPanel.rightTitle:SetText(bossName) end

    local dungeonData = BossData[currentDungeon]
    if dungeonData then
        local boss = nil
        for _, b in ipairs(dungeonData.bosses) do
            if b.realName == bossName then
                boss = b
                break
            end
        end

        if boss then
            BossUI:ShowBoss(rightPanel, boss)
        end
    end

    rightPanel.showingDetails = false
    if rightPanel.detailToggle then
        rightPanel.detailToggle:SetText(Translate("COMING_SOON"))
    end

    if rightPanel.postButton then rightPanel.postButton:Show() end
    if rightPanel.detailToggle then rightPanel.detailToggle:Show() end

    if btn then
        btn:SetSelected(true)
        selectedButton = btn
    end
end

-- ShowDungeons
local function ShowDungeons()
    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then btn.icon:Hide() end
            btn:Hide()
        end
    end
    frame.bossButtons = {}

    local y = -20

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
            local nameToShow = dungeonData.displayName or dungeonKey
            local btn = CreateCustomButton(leftPanel, 180, 30, nameToShow)
            btn:SetPoint("TOP", leftPanel, "TOP", 0, y)

            for _, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
                local name, _, _, textureID = C_ChallengeMode.GetMapUIInfo(mapID)
                if name == dungeonData.realName or name == dungeonKey then
                    if textureID and textureID ~= 0 then
                        btn:SetIcon(textureID)
                        break
                    end
                end
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
            y = y - 40
        end
    end

    if not frame.selectedBoss then
        backButton:Hide()
        ShowStartPage(frame, rightPanel)
    else
        backButton:Show()
    end
end

-- ShowBosses
function ShowBosses(dungeonName)
    currentDungeon = dungeonName

    -- Brugeren er ikke længere i settings når vi åbner boss-listen
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.lastOpenPanel = nil


    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            if btn.icon then btn.icon:Hide() end
            btn:Hide()
        end
    end
    frame.bossButtons = {}

    local y = -20
    local dungeonData = BossData[dungeonName]
    if not dungeonData or not dungeonData.bosses then return end

    for _, bossData in ipairs(dungeonData.bosses) do
        local btn = CreateCustomButton(leftPanel, 180, 30, bossData.displayName or bossData.realName)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)

        local iconTexture = bossData.icon or BossHelper:GetBossPortraitFileID(dungeonData.realName, bossData.realName, bossData.realName, bossData)
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
            SelectBoss(bossData.realName, btn)
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.BOSS_SELECT) end
        end)


        table.insert(frame.bossButtons, btn)
        y = y - 40
    end

    backButton:Show()
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
    CrossfadeFrameText(rPanel.rightTitle, boss.displayName or boss.realName or "Ukendt boss")

    -- Dropdown til faser med custom buttons
    if boss.phases and #boss.phases > 0 then
        if rPanel.phaseDropdown then
            rPanel.phaseDropdown:Hide()
            rPanel.phaseDropdown = nil
        end

        local function CreatePhaseDropdown(parent, boss)
            local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            dropdown:SetSize(140, 26)
            dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -40)

            -- Main-knap
            local mainBtn = CreateCustomButton(dropdown, 140, 26, boss.phases[1])
            mainBtn:SetPoint("TOP", dropdown, "TOP", -419, 30)

            -- Panel med fase-knapper
            local panel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
            panel:SetSize(140, #boss.phases * 26)
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

                mainBtn:SetText(boss.phases[index])
                BuildShortLineButtons(rPanel, boss.phaseText[boss.phases[index]] or "")
            end

            for i, phaseName in ipairs(boss.phases) do
                local btn = CreateCustomButton(panel, 140, 26, phaseName)
                btn:SetPoint("TOP", panel, "TOP", 0, -((i-1)*26))
                btn:SetScript("OnClick", function()
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                    SelectPhase(i)
                    panel:Hide()
                    if rPanel.dropdownClickCatcher then
                        rPanel.dropdownClickCatcher:Hide()
                        rPanel.dropdownActivePanel = nil
                    end
                end)
                table.insert(buttons, btn)
            end

            -- Start med gemt fase eller første fase
            if rPanel.selectedPhaseIndex then
                SelectPhase(rPanel.selectedPhaseIndex)
            else
                SelectPhase(1)
            end

            -- Opret (eller genbrug) click-catcher parented til UIParent så vi fanger klik udenfor hele UI'et
            if not rPanel.dropdownClickCatcher then
                local catcher = CreateFrame("Frame", "BossHelper_DropdownClickCatcher", UIParent)
                catcher:SetAllPoints(UIParent)
                catcher:EnableMouse(true)
                catcher:Hide()
                catcher:SetFrameStrata("FULLSCREEN_DIALOG")
                catcher:SetFrameLevel(1999) -- lavere end panelet så panelen kan modtage clicks
                catcher:SetScript("OnMouseDown", function(self)
                    if rPanel.dropdownActivePanel and rPanel.dropdownActivePanel:IsShown() then
                        rPanel.dropdownActivePanel:Hide()
                        self:Hide()
                        rPanel.dropdownActivePanel = nil
                    end
                end)
                rPanel.dropdownClickCatcher = catcher
            end

            -- Main-knap toggler panel
            mainBtn:SetScript("OnClick", function()
                if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                if panel:IsShown() then
                    panel:Hide()
                    if rPanel.dropdownClickCatcher then
                        rPanel.dropdownClickCatcher:Hide()
                        rPanel.dropdownActivePanel = nil
                    end
                else
                    -- Vis panel og aktiver catcheren
                    panel:Show()
                    -- sikr at panel er over catcheren
                    panel:SetFrameStrata("FULLSCREEN_DIALOG")
                    panel:SetFrameLevel(2000)
                    if rPanel.dropdownClickCatcher then
                        rPanel.dropdownClickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
                        rPanel.dropdownClickCatcher:SetFrameLevel(1999)
                        rPanel.dropdownClickCatcher:Show()
                    end
                    rPanel.dropdownActivePanel = panel

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
                    -- Play animation if allowed (din funktion ShouldAnimateInCombat)
                    if ShouldAnimateInCombat and ShouldAnimateInCombat() then
                        ag:Play()
                    end
                end
            end)

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
        BuildShortLineButtons(rPanel, boss.short or "")
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
                        else
                            -- Ryd gamle settings-widgets uanset hvad
                            ClearRightPanelSettings()

                            BossHelperDB = BossHelperDB or {}
                            if BossHelperDB.lastOpenPanel == "settings" then
                                -- hvis sidste åbne panel var settings, åbn settings igen
                                ShowSettings()
                            else
                                -- ellers vis normal start
                                pcall(function()
                                    if rightPanel and rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
                                    if rightPanel and rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
                                end)
                                ShowStartPage(frame, rightPanel)
                                ShowDungeons()
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
    BossHelperDB = BossHelperDB or {}

    -- sikr UI er oprettet (hvis ShowSettings bliver kaldt før CreateUI)
    if not frame and BossUI and BossUI.CreateUI then BossUI:CreateUI() end

    -- skjul normal start-content først, så settings ikke overlapper
    if rightPanel then
        pcall(function()
            if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
            if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
            if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
            if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
            rightPanel.showingDetails = false
            if rightPanel.postButton then rightPanel.postButton:Hide() end
            if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
        end)
    end


    -- ryd eventuelle gamle settings-widgets (ekstra sikkert)
    ClearRightPanelSettings()

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
    frame:SetFrameStrata("HIGH")
    frame.bossButtons = {}

    -- Afspil lyd når vinduet lukkes (ESC eller CloseButton)
    frame:SetScript("OnHide", function(self)
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
        frame:Hide()
    end)
    closeButton:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(1, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.6, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    closeButton:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.08, 0.09, 0.13, 0.95)
        self:SetBackdropBorderColor(0.06, 0.06, 0.06, 0.8)
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
        self:SetBackdropBorderColor(0.06, 0.06, 0.06, 0.8)
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
    leftPanel:SetBackdropColor(0.05, 0.05, 0.1, 0.9)
    leftPanel:SetBackdropBorderColor(1, 0.5, 0, 0.8)

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

    rightPanel.rightDetailText = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightPanel.rightDetailText:SetPoint("TOPLEFT", rightPanel.rightShortScroll or rightPanel, "BOTTOMLEFT", 0, -5)
    rightPanel.rightDetailText:SetSize(550, 200)
    rightPanel.rightDetailText:SetJustifyH("LEFT")
    rightPanel.rightDetailText:SetJustifyV("TOP")
    rightPanel.rightDetailText:SetWordWrap(true)

    rightPanel.showingDetails = false
    

    --alt Back Button
    backButton = CreateCustomButton(leftPanel, 180, 30, "BACK")
    backButton:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 10)
    backButton:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.BACK_BUTTON) end
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
        rightPanel.showingDetails = false
        if rightPanel.detailToggle then pcall(rightPanel.detailToggle.SetText, rightPanel.detailToggle, Translate("COMING_SOON")) end

        -- Ryd op i settings-widgets hvis vi kom fra Settings
        ClearRightPanelSettings()


        -- Gem back-knappen og vis startside + dungeons
        backButton:Hide()
        ShowStartPage(frame, rightPanel)
        ShowDungeons()
    end)
    backButton:Hide()


    rightPanel.detailToggle = CreateCustomButton(rightPanel, 160, 34, Translate("COMING_SOON"))
    rightPanel.detailToggle:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 10, 10)
    rightPanel.detailToggle:Hide()
    rightPanel.detailToggle:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
        if not frame.selectedBoss or not currentDungeon then return end
        local dungeonData = BossData[currentDungeon]
        if not dungeonData or not dungeonData.bosses then return end

        local boss = nil
        for _, b in ipairs(dungeonData.bosses) do
            if b.realName == frame.selectedBoss then
                boss = b
                break
            end
        end
        if not boss then return end

        if rightPanel.showingDetails then
            rightPanel.rightDetailText:SetText("")
            rightPanel.detailToggle:SetText(Translate("COMING_SOON"))
            rightPanel.showingDetails = false
        else
            rightPanel.rightDetailText:SetText(boss.details or "")
            rightPanel.detailToggle:SetText(Translate("HIDE_DETAILS"))
            rightPanel.showingDetails = true
        end
    end)

        rightPanel.postButton = CreateCustomButton(rightPanel, 160, 34, "POST_TO_CHAT")
        rightPanel.postButton:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
        rightPanel.postButton:Hide()

        -- Fill-overlay (vokser fra højre -> venstre)
        do
            local btn = rightPanel.postButton
            btn.fill = btn:CreateTexture(nil, "ARTWORK")
            -- placér til højre og sæt initial width 0 så den vokser mod venstre
            btn.fill:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -4, -4)
            btn.fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 4)
            btn.fill:SetColorTexture(1, 0.65, 0.15, 0.95) -- varm orange fill
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
        
            local dungeonData = BossData[currentDungeon]
            if not dungeonData or not dungeonData.bosses then return end

            -- Vi bygger præcis den tekst vi tidligere sendte (samme logik)
            for _, b in ipairs(dungeonData.bosses) do
                if b.realName == frame.selectedBoss then
                    local textToSend = b.short or ""

                    -- Hvis der er faser og en fase er valgt, tilføj kun den fase
                    if b.phases and #b.phases > 0 and rightPanel.selectedPhaseIndex then
                        local phaseName = b.phases[rightPanel.selectedPhaseIndex]
                        local phaseText = b.phaseText and b.phaseText[phaseName] or ""
                        textToSend = textToSend .. "\n\n" .. phaseName .. ":\n" .. phaseText
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

                    break
                end
            end
        end)

    -- Vis startside og dungeons når UI bliver oprettet
    ShowStartPage(frame, rightPanel)
    ShowDungeons() 
end

