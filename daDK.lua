-- Functions.lua
-- Her samler vi alle generelle hjælpefunktioner til BossHelper

-- ================================================
-- Registrer et frame så det kan lukkes med ESC
-- ================================================
function BossHelper:RegisterEscClose(frame)
    if not frame or not frame.GetName then
        print("|cffff5555[MythicMentor]|r Kan ikke registrere frame til ESC-lukning (mangler navn)")
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
        -- print("BossHelper: ESC lukning aktiveret for -> " .. name)
    else
        -- print("BossHelper: ESC lukning deaktiveret for -> " .. name)
    end
end

-- ================================================
-- Discord Link Popup Function
-- ================================================
function BossHelper:ShowDiscordLinkPopup()
    -- Discord link - ændre dette til dit Discord link
    local discordLink = "https://discord.gg/sYFdZDPKr3"
    
    -- Opret popup frame hvis det ikke eksisterer
    if not self.discordPopup then
        local popup = CreateFrame("Frame", "BossHelperDiscordPopup", UIParent, "BackdropTemplate")
        popup:SetSize(350, 120)
        popup:SetPoint("CENTER")
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.8)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(100)
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
        
        -- Title
        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -20)
        title:SetText(Translate("JOIN_DISCORD"))
        title:SetTextColor(0.5, 0.7, 1)
        
        -- Link editbox
        local linkBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        linkBox:SetSize(300, 20)
        linkBox:SetPoint("CENTER", popup, "CENTER", 0, 10)
        linkBox:SetText(discordLink)
        linkBox:SetAutoFocus(false)
        linkBox:HighlightText()
        linkBox:SetScript("OnEscapePressed", function() popup:Hide() end)
        linkBox:SetScript("OnEnterPressed", function() linkBox:HighlightText() end)
        
        -- Instructions
        local instructions = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOP", linkBox, "BOTTOM", 0, -10)
        instructions:SetText(Translate("COPY_LINK"))
        instructions:SetTextColor(0.8, 0.8, 0.8)
        

        
        -- X button
        local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
        xBtn:SetScript("OnClick", function() popup:Hide() end)
        
        self.discordPopup = popup
        self.discordLinkBox = linkBox
        
        -- Register for ESC close
        self:RegisterEscClose(popup)
    end
    
    -- Update link and show
    self.discordLinkBox:SetText(discordLink)
    self.discordPopup:Show()
    self.discordLinkBox:SetFocus()
    self.discordLinkBox:HighlightText()
end

-- ================================================
-- GitHub Link Popup Function
-- ================================================
function BossHelper:ShowGitHubLinkPopup()
    -- GitHub link - ændre dette til dit GitHub repository link
    local githubLink = "https://github.com/test-toast/Mythic-Mentor"
    
    -- Opret popup frame hvis det ikke eksisterer
    if not self.githubPopup then
        local popup = CreateFrame("Frame", "BossHelperGitHubPopup", UIParent, "BackdropTemplate")
        popup:SetSize(350, 120)
        popup:SetPoint("CENTER")
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.8)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(100)
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
        
        -- Title
        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -20)
        title:SetText(Translate("VISIT_GITHUB"))
        title:SetTextColor(0.9, 0.9, 0.9)
        
        -- Link editbox
        local linkBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        linkBox:SetSize(300, 20)
        linkBox:SetPoint("CENTER", popup, "CENTER", 0, 10)
        linkBox:SetText(githubLink)
        linkBox:SetAutoFocus(false)
        linkBox:HighlightText()
        linkBox:SetScript("OnEscapePressed", function() popup:Hide() end)
        linkBox:SetScript("OnEnterPressed", function() linkBox:HighlightText() end)
        
        -- Instructions
        local instructions = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOP", linkBox, "BOTTOM", 0, -10)
        instructions:SetText(Translate("COPY_LINK"))
        instructions:SetTextColor(0.8, 0.8, 0.8)
        

        
        -- X button
        local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
        xBtn:SetScript("OnClick", function() popup:Hide() end)
        
        self.githubPopup = popup
        self.githubLinkBox = linkBox
        
        -- Register for ESC close
        self:RegisterEscClose(popup)
    end
    
    -- Update link and show
    self.githubLinkBox:SetText(githubLink)
    self.githubPopup:Show()
    self.githubLinkBox:SetFocus()
    self.githubLinkBox:HighlightText()
end

-- ================================================
-- Update Links Popup (GitHub + CurseForge) - for banner
-- ================================================
function BossHelper:ShowUpdateLinksPopup()
    local githubLink = "https://github.com/test-toast/Mythic-Mentor"
    local curseLink  = "https://www.curseforge.com/wow/addons/mythic-mentor"

    if not self.updateLinksPopup then
        local popup = CreateFrame("Frame", "BossHelperUpdateLinksPopup", UIParent, "BackdropTemplate")
        popup:SetSize(400, 200)
        popup:SetPoint("CENTER")
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.85)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(100)
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -16)
    title:SetText("Mythic Mentor Links")

        -- GitHub row
    local ghLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ghLabel:SetPoint("TOP", title, "BOTTOM", 0, -18)
        ghLabel:SetText("GitHub:")
        ghLabel:SetTextColor(0.9, 0.9, 0.9)

        local ghBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    ghBox:SetSize(320, 20)
    ghBox:SetPoint("TOP", ghLabel, "BOTTOM", 0, -6)
        ghBox:SetAutoFocus(false)
        ghBox:SetText(githubLink)
        ghBox:HighlightText()
        ghBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
        ghBox:SetScript("OnEscapePressed", function() popup:Hide() end)

        -- CurseForge row
    local cfLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cfLabel:SetPoint("TOP", ghBox, "BOTTOM", 0, -14)
        cfLabel:SetText("CurseForge:")
        cfLabel:SetTextColor(1.0, 0.85, 0.4)

        local cfBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    cfBox:SetSize(320, 20)
    cfBox:SetPoint("TOP", cfLabel, "BOTTOM", 0, -6)
        cfBox:SetAutoFocus(false)
        cfBox:SetText(curseLink)
        cfBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
        cfBox:SetScript("OnEscapePressed", function() popup:Hide() end)

        -- Instructions
    local inst = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    inst:SetPoint("TOP", cfBox, "BOTTOM", 0, -12)
        inst:SetText(Translate and Translate("COPY_LINK") or "Ctrl+C to copy link")
        inst:SetTextColor(0.8, 0.8, 0.8)

        -- Close button
        local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
        xBtn:SetScript("OnClick", function() popup:Hide() end)

        self.updateLinksPopup = popup
        self.updateLinksGithub = ghBox
        self.updateLinksCurse = cfBox

        self:RegisterEscClose(popup)
    end

    -- Update and show
    if self.updateLinksGithub then self.updateLinksGithub:SetText(githubLink) end
    if self.updateLinksCurse then self.updateLinksCurse:SetText(curseLink) end
    self.updateLinksPopup:Show()
end

-- ================================================
-- Bug Report Popup Function
-- ================================================
function BossHelper:ShowBugReportPopup()
    -- Bug report links
    local discordLink = "https://discord.gg/sYFdZDPKr3"
    local githubLink = "https://github.com/test-toast/Mythic-Mentor/issues"
    
    -- Opret popup frame hvis det ikke eksisterer
    if not self.bugReportPopup then
        local popup = CreateFrame("Frame", "BossHelperBugReportPopup", UIParent, "BackdropTemplate")
        popup:SetSize(400, 250)
        popup:SetPoint("CENTER")
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.8)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(100)
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
        
        -- Title
        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -20)
        title:SetText(Translate("REPORT_BUG"))
        title:SetTextColor(1, 0.3, 0.3)
        
        -- Description
        local desc = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        desc:SetPoint("TOP", title, "BOTTOM", 0, -15)
        desc:SetSize(350, 40)
        desc:SetText(Translate("BUG_GUIDE"))
        desc:SetTextColor(1, 1, 1)
        desc:SetJustifyH("CENTER")
        
        -- Discord link section
        local discordLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        discordLabel:SetPoint("TOP", desc, "BOTTOM", 0, -20)
        discordLabel:SetText("Discord:")
        discordLabel:SetTextColor(0.5, 0.7, 1)
        
        local discordBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        discordBox:SetSize(300, 20)
        discordBox:SetPoint("TOP", discordLabel, "BOTTOM", 0, -5)
        discordBox:SetText(discordLink)
        discordBox:SetAutoFocus(false)
        discordBox:SetScript("OnEscapePressed", function() popup:Hide() end)
        discordBox:SetScript("OnEnterPressed", function() discordBox:HighlightText() end)
        
        -- GitHub link section
        local githubLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        githubLabel:SetPoint("TOP", discordBox, "BOTTOM", 0, -15)
        githubLabel:SetText("GitHub Issues:")
        githubLabel:SetTextColor(0.9, 0.9, 0.9)
        
        local githubBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        githubBox:SetSize(300, 20)
        githubBox:SetPoint("TOP", githubLabel, "BOTTOM", 0, -5)
        githubBox:SetText(githubLink)
        githubBox:SetAutoFocus(false)
        githubBox:SetScript("OnEscapePressed", function() popup:Hide() end)
        githubBox:SetScript("OnEnterPressed", function() githubBox:HighlightText() end)
        
        -- Instructions
        local instructions = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions:SetPoint("TOP", githubBox, "BOTTOM", 0, -15)
        instructions:SetText(Translate("COPY_LINK"))
        instructions:SetTextColor(0.8, 0.8, 0.8)
        
        -- X button
        local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
        xBtn:SetScript("OnClick", function() popup:Hide() end)
        
        self.bugReportPopup = popup
        self.bugDiscordBox = discordBox
        self.bugGithubBox = githubBox
        
        -- Register for ESC close
        self:RegisterEscClose(popup)
    end
    
    -- Update links and show
    self.bugDiscordBox:SetText(discordLink)
    self.bugGithubBox:SetText(githubLink)
    self.bugReportPopup:Show()
end

-- ================================================
-- Text Processing Functions
-- ================================================

-- Farveord til hex-koder
local colorHex = {
    Boss          = "|cFFFF6600",   -- dyb orange
    BossAbilities = "|cFFFF0000",   -- rød
    Buff          = "|cFF00FF00",   -- grøn
    Debuff        = "|cFFFFAA33",   -- mørk orange

    Objectives    = "|cFF3399FF",   -- blå
    Miscellaneous = "|cFF00FFFF",   -- cyan
    Important     = "|cFFCC00FF",   -- lilla
}

-- Escape specialtegn til Lua mønstre
local function escapeLuaPattern(str)
    return str:gsub("([^%w%s])", "%%%1")
end

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