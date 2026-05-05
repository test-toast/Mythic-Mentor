-- BossInfo.lua
-- API: BossInfo.ShowInfo(ctx)
-- ctx = {
--   frame = frame,
--   leftPanel = leftPanel,
--   rightPanel = rightPanel,
--   backButton = backButton,
--   CreateCustomButton = CreateCustomButton,    -- required
--   BossHelper = BossHelper,                    -- optional, for lyd/calls
--   BossHelperDB = BossHelperDB                 -- optional, til checkbox init
-- }


if not BossInfo then BossInfo = {} end

local deps = {} -- internal deps (populated fra Init eller ShowInfo args)

function BossInfo.Init(d)
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

-- Cleanup helper for rightPanel info widgets
local function CleanupInfoWidgets(rPanel)
    if not rPanel then return end
    if rPanel.settingsWidgets then
        for _, w in ipairs(rPanel.settingsWidgets) do
            if w then
                phide(w)
                psetparent(w, nil)
                pclearpoints(w)
            end
        end
        rPanel.settingsWidgets = nil
    end
    -- Discard old content frame; it will be rebuilt fresh for next category
    if rPanel.infoScrollContent then
        phide(rPanel.infoScrollContent)
        rPanel.infoScrollContent:SetParent(nil)
        rPanel.infoScrollContent = nil
    end
end

-- BuildInfoCategoryUI (bygger indholdet for hver info-kategori)
function BossInfo.BuildInfoCategoryUI(rPanel, category, ctx)
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
    local BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB

    -- Create scroll frame once on rPanel; reuse across category switches
    if not rPanel.infoScrollFrame then
        local sf = CreateFrame("ScrollFrame", nil, rPanel, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 10, -50)
        sf:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -30, 10)
        rPanel.infoScrollFrame = sf
    end
    local sf = rPanel.infoScrollFrame
    sf:Show()

    -- Fresh content frame for each category switch
    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(510)
    content:SetHeight(1)
    sf:SetScrollChild(content)
    rPanel.infoScrollContent = content

    local startX, startY = 10, -10
    local last = nil

    local function AddInfoText(text, font)
        font = font or "GameFontNormal"
        local lbl = content:CreateFontString(nil, "OVERLAY", font)
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", startX, startY + (last and last.offset or 0))
        lbl:SetText(text)
        lbl:SetJustifyH("LEFT")
        lbl:SetWidth(490)
        lbl:SetWordWrap(true)

        rPanel.settingsWidgets = rPanel.settingsWidgets or {}
        table.insert(rPanel.settingsWidgets, lbl)

        local textHeight = lbl:GetStringHeight() or 16
        last = { offset = (last and last.offset or 0) - textHeight - 10 }
        return lbl
    end

    local function AddSpacer(height)
        last = { offset = (last and last.offset or 0) - (height or 20) }
    end

    if category == "Mythic Mentor" then
        AddInfoText("About Mythic Mentor", "GameFontHighlightLarge")
        AddSpacer(10)
        AddInfoText("A minimalist M+ Boss Helper addon that helps you master Mythic+ dungeons.")
        AddSpacer()
        AddInfoText("Features:")
        AddInfoText("• Detailed boss tactics for all M+ dungeons")
        AddInfoText("• Multiple language support (EN, DA, DE, RU)")
        AddInfoText("• Minimap Button for quick access")
        AddInfoText("• Auto-invite functionality")
        AddInfoText("• Custom boss notes")

    elseif category == "ChangeLog" then
        AddInfoText("Change Log", "GameFontHighlightLarge")
        AddSpacer(10)
        local verStr
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            verStr = C_AddOns.GetAddOnMetadata("BossHelper", "Version")
        elseif GetAddOnMetadata then
            verStr = GetAddOnMetadata("BossHelper", "Version")
        end
        AddInfoText("Version: " .. (verStr or "unknown"))
        AddSpacer()
        AddInfoText("New:")
        AddInfoText("• Edit Tactics: You can now edit all boss tactics or create your own")
        AddInfoText("• Custom confirmation popups")
        AddInfoText("• All tactics have been translated into Danish, German, French, and Russian")
        AddSpacer()
        AddInfoText("• Changes")
        AddInfoText("• In active instances (e.g. Mythic+), a copy window is now shown since Blizzard’s chat lockdown system prevents addons from writing directly to chat during encounters.")
        AddInfoText("• Updated left panel background to match the right panel design")
        AddInfoText("• Changed button border color to dark grey instead of black")
        AddInfoText("• Hover animation now only appears on hover (removed from de-hover state)")
        AddSpacer()
        AddInfoText("• Bug Fixes")
        AddInfoText("• Core: Added UI toggle, moved update-banner refresh into PLAYER_LOGIN, and made sound playback safe.")
        AddInfoText("• Messaging: Fixed PlayButtonSound nil guard and stabilized the message queue.")
        AddInfoText("• Auto-invite: Fixed slash command and removed unused global trigger; use Inviter.SetTrigger().")
        AddInfoText("• Settings: Fixed language dropdown initial label bug, removed duplicate rightPanel declaration, and used Translate(SETTINGS).")
        AddInfoText("• UI: Replaced hardcoded texts with localization keys; added UNKNOWN_BOSS and COPY_HINT_TEXT.")
        AddInfoText("• Fixed missing image for Xenas Kasreth (Nexus-Point)")

    elseif category == "Help" then
        AddInfoText("Help & Support", "GameFontHighlightLarge")
        AddSpacer(10)
        AddInfoText("How to use the addon:")
        AddInfoText("1. Select the dungeon you need to run")
        AddInfoText("2. Select the boss you need help with")
        AddInfoText("3. Read the tactics and use 'Post to Chat' to share with your group")
        AddInfoText("4. or read your own notes in the 'Boss Notes' section")
        AddSpacer()
        AddInfoText("• Read general notes in the 'General Notes' section")
        AddSpacer()
        AddInfoText("Join our Discord for more help or questions.")
        AddSpacer()
        AddInfoText("Hotkeys:")
        AddInfoText("• Left-click minimap: Open/close addon")
        AddSpacer()
        AddInfoText("Commands:")
        AddInfoText("• /MM or /MythicMentor: Open addon")

    elseif category == "Credits" then
        AddInfoText("Credits & Acknowledgements", "GameFontHighlightLarge")
        AddSpacer(10)
        AddInfoText("Developed by:")
        AddInfoText("• testtoast")
        AddInfoText("• QuteBytes")
        AddInfoText("From Burning Toast Studio")
        AddSpacer()
        AddInfoText("Credits:")
        AddInfoText("• Thanks to World of Duckcraft for boss tactics.")
    end

    -- Resize content to fit all text so scroll range is correct
    content:SetHeight(math.abs(last and last.offset or 0) + 20)
end

-- SelectInfoCategory (tracks left-button state in frame.infoSelectedButton)
function BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, categoryName, btn, ctx)
    ctx = ctx or {}
    -- deselect previous
    if frame.infoSelectedButton then
        pcall(frame.infoSelectedButton.SetSelected, frame.infoSelectedButton, false)
        frame.infoSelectedButton = nil
    end
    if btn then
        pcall(btn.SetSelected, btn, true)
        frame.infoSelectedButton = btn
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
    CleanupInfoWidgets(rightPanel)

    -- rebuild
    BossInfo.BuildInfoCategoryUI(rightPanel, categoryName, { CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton, BossHelperDB = ctx.BossHelperDB or deps.BossHelperDB })
end

-- ShowInfo (ctx must include: frame,leftPanel,rightPanel,backButton,CreateCustomButton)
function BossInfo.ShowInfo(ctx)
    ctx = ctx or {}
    -- copy some deps if supplied
    if ctx.CreateCustomButton then deps.CreateCustomButton = ctx.CreateCustomButton end
    if ctx.BossHelper then deps.BossHelper = ctx.BossHelper end
    if ctx.BossHelperDB then deps.BossHelperDB = ctx.BossHelperDB end

    local frame = ctx.frame
    local leftPanel = ctx.leftPanel
    local rightPanel = ctx.rightPanel
    local backButton = ctx.backButton

    -- Skjul Discord knappen på info siden
    if rightPanel and rightPanel.discordButton then rightPanel.discordButton:Hide() end
    -- Skjul GitHub knappen på info siden
    if rightPanel and rightPanel.githubButton then rightPanel.githubButton:Hide() end
    -- Skjul Bug Report knappen på info siden
    if rightPanel and rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

    if not (frame and leftPanel and rightPanel and CreateCustomButton) then
        print("|cffFF4500[BossInfo]|r Missing context for ShowInfo()")
        return
    end

    frame.currentMode = "info"
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
            if b and b.Hide then 
                b:Hide() 
                b:SetParent(nil)
            end
        end
    end
    rightPanel.shortButtons = {}

    psettext(rightPanel.rightTitle, Translate and Translate("INFO") or "Information")
    if rightPanel.rightShortText then psettext(rightPanel.rightShortText, "") end
    if rightPanel.rightDetailText then psettext(rightPanel.rightDetailText, "") end

    -- Set left panel title to match dungeon/boss display pattern
    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText(Translate and Translate("INFO") or "Information")
    end

    -- clear old left buttons
    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            phide(btn)
            psetparent(btn, nil)
        end
    end
    frame.bossButtons = {}

    -- define your info categories
    local categories = { 
        "Mythic Mentor",
        "ChangeLog", 
        "Help",
        "Credits"
    }

    local y = -39  -- Align with rightPanel content at -39 to match ShowDungeons/ShowBosses
    for _, cat in ipairs(categories) do
        local btn = (CreateCustomButton)(leftPanel, 180, 30, cat)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn:SetScript("OnClick", function()
            BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, cat, btn, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
            psafesound(856)
        end)
    table.insert(frame.bossButtons, btn)
    y = y - 35
    end

    if backButton then backButton:Show() end

    -- initial view: select first category
    if #frame.bossButtons > 0 then
        local first = frame.bossButtons[1]
        BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, categories[1], first, { CreateCustomButton = CreateCustomButton, BossHelperDB = deps.BossHelperDB })
    end
end

return BossInfo