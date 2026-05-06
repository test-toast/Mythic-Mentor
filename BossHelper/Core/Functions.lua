-- Functions.lua
-- Her samler vi alle generelle hjælpefunktioner til BossHelper

-- ================================================
-- Registrer et frame så det kan lukkes med ESC
-- ================================================
function BossHelper:RegisterEscClose(frame)
    if not frame or not frame.GetName then
        print(BossHelper.CHAT_TAG_ERR .. " " .. Translate("ESC_REGISTER_FAILED"))
        return
    end

    local name = frame:GetName()

    -- Fjern altid først, så vi undgår dubletter
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == name then
            table.remove(UISpecialFrames, i)
        end
    end

    -- Tilføj kun hvis indstillingen er aktiv
    if BossHelperDB and BossHelperDB.allowEscClose then
        table.insert(UISpecialFrames, name)
    end
end

-- ================================================
-- Shared popup frame factory
-- Builds the common moveable backdrop frame used by all link popups.
-- cfg = { name, width, height, alpha }  (all optional except name)
-- ================================================
local POPUP_BACKDROP = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local function _CreateBasePopupFrame(cfg)
    local popup = CreateFrame("Frame", cfg.name, UIParent, "BackdropTemplate")
    popup:SetSize(cfg.width or 350, cfg.height or 120)
    popup:SetPoint("CENTER")
    popup:SetBackdrop(POPUP_BACKDROP)
    popup:SetBackdropColor(0, 0, 0, cfg.alpha or 0.8)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(100)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
    xBtn:SetScript("OnClick", function() popup:Hide() end)

    return popup
end

-- Creates a copyable read-only EditBox anchored below `anchor`.
local function _CreateLinkBox(popup, width, anchor, link)
    local box = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    box:SetSize(width or 300, 20)
    box:SetPoint("TOP", anchor, "BOTTOM", 0, -6)
    box:SetAutoFocus(false)
    box:SetText(link or "")
    box:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed", function() popup:Hide() end)
    return box
end

-- Creates an instruction label anchored below `anchor`.
local function _AddCopyInstructions(popup, anchor)
    local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOP", anchor, "BOTTOM", 0, -12)
    lbl:SetText(Translate("COPY_LINK"))
    lbl:SetTextColor(0.8, 0.8, 0.8)
    return lbl
end

-- Factory for the common single-link popup (Discord / GitHub).
-- titleKey  = Translate key for the popup title
-- titleColor = { r, g, b }
-- linkKey   = key in BossHelper.Links
-- Returns popup, linkBox
local function _MakeSingleLinkPopup(self, frameName, titleKey, titleColor, linkKey)
    local popup = _CreateBasePopupFrame({ name = frameName, width = 350, height = 120 })

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -20)
    title:SetText(Translate(titleKey))
    title:SetTextColor(titleColor[1], titleColor[2], titleColor[3])

    -- Anchor box to center of popup (keeps original layout)
    local box = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    box:SetSize(300, 20)
    box:SetPoint("CENTER", popup, "CENTER", 0, 10)
    box:SetAutoFocus(false)
    box:SetText(BossHelper.Links[linkKey] or "")
    box:SetScript("OnEnterPressed", function(b) b:HighlightText() end)
    box:SetScript("OnEscapePressed", function() popup:Hide() end)

    local inst = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inst:SetPoint("TOP", box, "BOTTOM", 0, -10)
    inst:SetText(Translate("COPY_LINK"))
    inst:SetTextColor(0.8, 0.8, 0.8)

    self:RegisterEscClose(popup)
    return popup, box
end

-- ================================================
-- Discord Link Popup
-- ================================================
function BossHelper:ShowDiscordLinkPopup()
    if not self.discordPopup then
        self.discordPopup, self.discordLinkBox = _MakeSingleLinkPopup(
            self, "BossHelperDiscordPopup",
            "JOIN_DISCORD", { 0.5, 0.7, 1 }, "DISCORD"
        )
    end
    self.discordLinkBox:SetText(BossHelper.Links.DISCORD)
    self.discordPopup:Show()
    self.discordLinkBox:SetFocus()
    self.discordLinkBox:HighlightText()
end

-- ================================================
-- GitHub Link Popup
-- ================================================
function BossHelper:ShowGitHubLinkPopup()
    if not self.githubPopup then
        self.githubPopup, self.githubLinkBox = _MakeSingleLinkPopup(
            self, "BossHelperGitHubPopup",
            "VISIT_GITHUB", { 0.9, 0.9, 0.9 }, "GITHUB"
        )
    end
    self.githubLinkBox:SetText(BossHelper.Links.GITHUB)
    self.githubPopup:Show()
    self.githubLinkBox:SetFocus()
    self.githubLinkBox:HighlightText()
end

-- ================================================
-- Update Links Popup (GitHub + CurseForge) – shown by the update banner
-- ================================================
function BossHelper:ShowUpdateLinksPopup()
    if not self.updateLinksPopup then
        local popup = _CreateBasePopupFrame({ name = "BossHelperUpdateLinksPopup", width = 400, height = 200, alpha = 0.85 })

        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -16)
        title:SetText("Mythic Mentor Links")

        local ghLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ghLabel:SetPoint("TOP", title, "BOTTOM", 0, -18)
        ghLabel:SetText("GitHub:")
        ghLabel:SetTextColor(0.9, 0.9, 0.9)

        local ghBox = _CreateLinkBox(popup, 320, ghLabel, BossHelper.Links.GITHUB)

        local cfLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cfLabel:SetPoint("TOP", ghBox, "BOTTOM", 0, -14)
        cfLabel:SetText("CurseForge:")
        cfLabel:SetTextColor(1.0, 0.85, 0.4)

        local cfBox = _CreateLinkBox(popup, 320, cfLabel, BossHelper.Links.CURSEFORGE)

        _AddCopyInstructions(popup, cfBox)

        self.updateLinksPopup  = popup
        self.updateLinksGithub = ghBox
        self.updateLinksCurse  = cfBox
        self:RegisterEscClose(popup)
    end

    self.updateLinksGithub:SetText(BossHelper.Links.GITHUB)
    self.updateLinksCurse:SetText(BossHelper.Links.CURSEFORGE)
    self.updateLinksPopup:Show()
end

-- ================================================
-- Bug Report Popup
-- ================================================
function BossHelper:ShowBugReportPopup()
    if not self.bugReportPopup then
        local popup = _CreateBasePopupFrame({ name = "BossHelperBugReportPopup", width = 400, height = 250 })

        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -20)
        title:SetText(Translate("REPORT_BUG"))
        title:SetTextColor(1, 0.3, 0.3)

        local desc = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        desc:SetPoint("TOP", title, "BOTTOM", 0, -15)
        desc:SetSize(350, 40)
        desc:SetText(Translate("BUG_GUIDE"))
        desc:SetTextColor(1, 1, 1)
        desc:SetJustifyH("CENTER")

        local discordLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        discordLabel:SetPoint("TOP", desc, "BOTTOM", 0, -20)
        discordLabel:SetText("Discord:")
        discordLabel:SetTextColor(0.5, 0.7, 1)

        local discordBox = _CreateLinkBox(popup, 300, discordLabel, BossHelper.Links.DISCORD)

        local githubLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        githubLabel:SetPoint("TOP", discordBox, "BOTTOM", 0, -15)
        githubLabel:SetText("GitHub Issues:")
        githubLabel:SetTextColor(0.9, 0.9, 0.9)

        local githubBox = _CreateLinkBox(popup, 300, githubLabel, BossHelper.Links.GITHUB_ISSUES)

        _AddCopyInstructions(popup, githubBox)

        self.bugReportPopup = popup
        self.bugDiscordBox  = discordBox
        self.bugGithubBox   = githubBox
        self:RegisterEscClose(popup)
    end

    self.bugDiscordBox:SetText(BossHelper.Links.DISCORD)
    self.bugGithubBox:SetText(BossHelper.Links.GITHUB_ISSUES)
    self.bugReportPopup:Show()
end

-- ================================================
-- Text Processing Functions
-- ================================================

-- colorHex er nu centraliseret i BossHelper.COLOR_TAGS (defineret i BossHelper.lua)
local colorHex = BossHelper.COLOR_TAGS

-- Hovedfunktion til tekstbehandling
function BossHelper:ReplaceRoleIcons(text)
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

    --------------------------------------------------------------------
    -- Tilføj farver baseret på [category:text] systemet
    --------------------------------------------------------------------
    -- Matcher [category:text] format og erstatter med farvet tekst
    text = text:gsub("%[([^%]:]+):([^%]]+)%]", function(category, content)
        -- Fjern eventuelle mellemrum omkring kategori-navnet
        category = category:gsub("^%s*", ""):gsub("%s*$", "")
        
        -- Find den tilsvarende hex-farve
        local hex = colorHex[category] or "|cFFFFFFFF" -- fallback = hvid
        
        -- Returner farvet tekst uden [] og kategori
        return hex .. content .. "|r"
    end)
    
    --------------------------------------------------------------------
    -- Process center tags - just clean them up, centering handled elsewhere
    --------------------------------------------------------------------
    text = text:gsub("{center}([^{]+){/center}", "%1")
    
    return text
end

-- ================================================
-- CreateMixedAlignmentContent Function
-- ================================================
function BossHelper:CreateMixedAlignmentContent(text, detailContent)
    -- Clear existing content
    if detailContent.mixedContentFrames then
        for _, frame in ipairs(detailContent.mixedContentFrames) do
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    detailContent.mixedContentFrames = {}
    
    -- Split text into paragraphs and detect center tags
    local paragraphs = {}
    local currentY = 0
    
    for paragraph in text:gmatch("([^\n]*)\n?") do
        if paragraph ~= "" then
            local isCentered = paragraph:match("{center}") ~= nil
            local cleanText = paragraph:gsub("{center}", ""):gsub("{/center}", "")
            table.insert(paragraphs, {text = cleanText, centered = isCentered})
        end
    end
    
    -- Create FontStrings for each paragraph
    for i, para in ipairs(paragraphs) do
        local fontString = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        
        if para.centered then
            -- For centered text, offset 35px to the right from center
            fontString:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 35, currentY)
            fontString:SetWidth(485) -- Reduce width to account for offset
            fontString:SetJustifyH("CENTER")
        else
            -- Normal left-aligned text
            fontString:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 0, currentY)
            fontString:SetWidth(520)
            fontString:SetJustifyH("LEFT")
        end
        
        fontString:SetWordWrap(true)
        fontString:SetJustifyV("TOP")
        
        fontString:SetText(self:ReplaceRoleIcons(para.text))
        
        local height = fontString:GetStringHeight()
        currentY = currentY - height - 10 -- Add some spacing
        
        table.insert(detailContent.mixedContentFrames, fontString)
    end
    
    return math.abs(currentY)
end