-- StartPage.lua

-- ============================================================
-- Hjælpefunktioner
-- ============================================================

local ShouldAnimate    = BossHelper.Anim.ShouldAnimate

-- ============================================================
-- Lokaliserede globals
-- ============================================================
local C = BossHelper.UI.C
local type = type

-- Generisk knap med ikon, hover-farve og tooltip (via centralt Buttons-modul)
local function CreateIconButton(parent, size, anchorFrame, xOffset, texturePath, hoverColor, tooltipKey, tooltipDescKey, onClickFn)
    return BossHelper.Buttons.CreateIconOnly(parent, size, anchorFrame, xOffset, texturePath, hoverColor, tooltipKey, tooltipDescKey, onClickFn)
end

-- ============================================================
-- Oprettelse af UI-elementer (køres kun én gang)
-- ============================================================

local function CreateStartPageElements(rightPanel)
    rightPanel.mainTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    rightPanel.mainTitle:SetPoint("TOP", rightPanel, "TOP", 0, -220)
    rightPanel.mainTitle:SetTextColor(1, 0.5, 0)

    rightPanel.logo = rightPanel:CreateTexture(nil, "ARTWORK")
    rightPanel.logo:SetSize(256, 256)
    rightPanel.logo:SetPoint("TOP", rightPanel, "TOP", 0, -10)
    rightPanel.logo:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Mythic Mentor 512x512.png")

    rightPanel.mainDesc = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rightPanel.mainDesc:SetPoint("TOP", rightPanel.logo, "BOTTOM", 0, -20)
    rightPanel.mainDesc:SetSize(500, 100)
    rightPanel.mainDesc:SetJustifyH("CENTER")
    rightPanel.mainDesc:SetJustifyV("TOP")

    rightPanel.footerText = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightPanel.footerText:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
    rightPanel.footerText:SetTextColor(0.7, 0.7, 0.7)

    -- Keystone-widget (genbrugelig, placeres frit via widget.frame:SetPoint)
    rightPanel.keystoneWidget = BossHelper.UI.CreateKeystoneWidget(rightPanel)
    rightPanel.keystoneWidget.frame:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 8, 8)

    rightPanel.discordButton = CreateIconButton(
        rightPanel, 25, nil, 10,
        "Interface\\AddOns\\BossHelper\\Media\\icon\\discord_logo.png",
        { 0.8, 0.8, 1 }, "JOIN_DISCORD", "DISCORD_TOOLTIP",
        function()
            if BossHelper and BossHelper.ShowDiscordLinkPopup then
                BossHelper:ShowDiscordLinkPopup()
            end
        end
    )

    rightPanel.githubButton = CreateIconButton(
        rightPanel, 22, rightPanel.discordButton, 5,
        "Interface\\AddOns\\BossHelper\\Media\\icon\\github_logo.png",
        { 0.8, 0.8, 1 }, "VISIT_GITHUB", "GITHUB_TOOLTIP",
        function()
            if BossHelper and BossHelper.ShowGitHubLinkPopup then
                BossHelper:ShowGitHubLinkPopup()
            end
        end
    )

    rightPanel.bugReportButton = CreateIconButton(
        rightPanel, 22, rightPanel.githubButton, 5,
        "Interface\\AddOns\\BossHelper\\Media\\icon\\bug_logo.png",
        { 1, 0.6, 0.6 }, "REPORT_BUG", "BUG_TOOLTIP",
        function()
            if BossHelper and BossHelper.ShowBugReportPopup then
                BossHelper:ShowBugReportPopup()
            end
        end
    )
end

-- Lokale aliases til Animations.lua
local ResetRegions         = BossHelper.Anim.ResetRegions
local FadeInRegions        = BossHelper.Anim.FadeInRegions
local PlayLogoPopAnimation = BossHelper.Anim.PlayLogoPop

-- ============================================================
-- Hovedfunktion
-- ============================================================

function ShowStartPage(frame, rightPanel)
    if not rightPanel then return end

    if not rightPanel.mainTitle then
        CreateStartPageElements(rightPanel)
    end

    -- Skjul boss-specifikke knapper
    if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
    if rightPanel.postButton then rightPanel.postButton:Hide() end
    rightPanel.showingDetails = false

    -- Vis social/utility-knapper
    if rightPanel.discordButton then rightPanel.discordButton:Show() end
    if rightPanel.githubButton then rightPanel.githubButton:Show() end
    if rightPanel.bugReportButton then rightPanel.bugReportButton:Show() end

    -- Sæt indhold
    rightPanel.mainTitle:SetText("")
    rightPanel.mainDesc:SetText(Translate("SELECT_DUNGEON_HINT"))
    local ver = (BossHelper and BossHelper.VERSION_STRING)
        or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("BossHelper", "Version"))
        or (GetAddOnMetadata and GetAddOnMetadata("BossHelper", "Version"))
        or "unknown"
    rightPanel.footerText:SetText("Burning Toast Studio • v" .. tostring(ver))

    local showKeys = not BossHelperDB or BossHelperDB.showKeysOnStartPage ~= false
    rightPanel.keystoneWidget:SetEnabled(showKeys)

    local regions = {
        rightPanel.logo, rightPanel.mainTitle, rightPanel.mainDesc,
        rightPanel.footerText,
        rightPanel.discordButton, rightPanel.githubButton, rightPanel.bugReportButton,
    }
    if showKeys and rightPanel.keystoneWidget.frame:IsShown() then
        table.insert(regions, rightPanel.keystoneWidget.frame)
    end

    ResetRegions(regions)

    if not ShouldAnimate() then
        if rightPanel.logo and rightPanel.logo.SetScale then rightPanel.logo:SetScale(1) end
        return
    end

    local fadeTime = 0.14
    FadeInRegions(regions, fadeTime)
    PlayLogoPopAnimation(rightPanel.logo, fadeTime)
end
