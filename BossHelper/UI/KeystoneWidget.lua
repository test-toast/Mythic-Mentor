-- KeystoneWidget.lua
-- Genbrugelig keystone-kort widget.
-- Brug: local widget = BossHelper.UI.CreateKeystoneWidget(parent)
--       widget.frame:SetPoint(...)   -- placer frit
--       widget:Refresh()             -- kald manuelt eller via BossHelper.RefreshAllKeystoneWidgets()
--       widget:Destroy()             -- når widgetten ikke skal bruges mere

BossHelper.UI = BossHelper.UI or {}

-- ============================================================
-- Konstanter
-- ============================================================
local CARD_W  = 68
local CARD_H  = 74
local CARD_GAP = 5

-- Samle/kort-bunke konstanter
local STACK_PEEK   = 6   -- px hvert stablede kort stikker ud til højre
local COLLAPSE_BTN = 16  -- bredde på samle/udfolde-knappen

-- List-layout (brugt af GroupFinderPanel)
local ROW_W   = 160
local ROW_H   = 36
local ROW_GAP = 4
local ICON_SZ = 26

local C = BossHelper.UI.C

-- ============================================================
-- Lokaliserede globals
-- ============================================================
local IsInRaid           = IsInRaid
local IsInGroup          = IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local UnitName, UnitClass = UnitName, UnitClass
local type, pairs, wipe  = type, pairs, wipe

-- ============================================================
-- Delt dungeon-info cache  (mapID ændrer sig aldrig)
-- ============================================================
local dungeonInfoCache = {}
local function GetDungeonInfo(mapID)
    local cached = dungeonInfoCache[mapID]
    if not cached then
        local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        cached = { name = name or "", texture = texture }
        dungeonInfoCache[mapID] = cached
    end
    return cached
end

-- ============================================================
-- Delt class-farve cache  (ryddes eksternt via BossHelper.ClearKeystoneColorCache)
-- ============================================================
local classColorCache = {}
BossHelper.ClearKeystoneColorCache = function() wipe(classColorCache) end

local function GetUnitClassColor(playerName)
    local cached = classColorCache[playerName]
    if cached then return cached[1], cached[2], cached[3] end

    local function tryUnit(unit)
        local name, realm = UnitName(unit)
        if not name then return end
        local full = (realm and realm ~= "") and (name.."-"..realm) or name
        if full == playerName or name == playerName then
            local _, class = UnitClass(unit)
            if class then
                local col = C_ClassColor.GetClassColor(class)
                if col then
                    classColorCache[playerName] = { col.r, col.g, col.b }
                    return col.r, col.g, col.b
                end
            end
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local r, g, b = tryUnit("raid"..i)
            if r then return r, g, b end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local r, g, b = tryUnit("party"..i)
            if r then return r, g, b end
        end
    end
    local r, g, b = tryUnit("player")
    if r then return r, g, b end
    return 1, 1, 1
end

-- ============================================================
-- Enkelt kort-bygger  (intern)
-- ============================================================
local function BuildKeystoneCard(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    BossHelper.UI.ApplyBackdrop(card, "ITEM", C.BG_DARK, C.BORDER_GREY)

    card.dungeonTex = card:CreateTexture(nil, "ARTWORK")
    card.dungeonTex:SetSize(CARD_W - 8, 40)
    card.dungeonTex:SetPoint("TOP", card, "TOP", 0, -4)
    card.dungeonTex:SetTexCoord(0, 1, 0, 1)

    -- Halvgennemsigtig gradient i bunden af billedet så teksten er læselig
    local fade = card:CreateTexture(nil, "OVERLAY")
    fade:SetSize(CARD_W - 8, 12)
    fade:SetPoint("BOTTOM", card.dungeonTex, "BOTTOM", 0, 0)
    fade:SetColorTexture(0.06, 0.07, 0.11, 0.75)

    -- +N overlay
    card.levelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.levelText:SetPoint("BOTTOMRIGHT", card.dungeonTex, "BOTTOMRIGHT", -3, 0)
    card.levelText:SetTextColor(C.TEXT_GOLD[1], C.TEXT_GOLD[2], C.TEXT_GOLD[3])
    card.levelText:SetShadowColor(0, 0, 0, 1)
    card.levelText:SetShadowOffset(1, -1)

    -- Dungeon navn
    card.dungeonName = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.dungeonName:SetPoint("TOP", card.dungeonTex, "BOTTOM", 0, 4)
    card.dungeonName:SetSize(CARD_W - 6, 22)
    card.dungeonName:SetJustifyH("CENTER")
    card.dungeonName:SetTextColor(0.65, 0.65, 0.85)
    card.dungeonName:SetWordWrap(false)
    card.dungeonName:SetNonSpaceWrap(false)

    -- Spillernavn (class-farvet)
    card.playerName = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.playerName:SetPoint("TOP", card.dungeonName, "BOTTOM", 0, 6)
    card.playerName:SetSize(CARD_W - 6, 13)
    card.playerName:SetJustifyH("CENTER")
    card.playerName:SetWordWrap(false)
    card.playerName:SetNonSpaceWrap(false)

    return card
end

-- ============================================================
-- List-række-bygger  (kun til GroupFinderPanel)
-- ============================================================
local function BuildKeystoneRow(parent)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(ROW_W, ROW_H)
    BossHelper.UI.ApplyBackdrop(row, "ITEM", C.BG_DARK, C.BORDER_GREY)

    -- Ikon til venstre
    row.dungeonTex = row:CreateTexture(nil, "ARTWORK")
    row.dungeonTex:SetSize(ICON_SZ, ICON_SZ)
    row.dungeonTex:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.dungeonTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Skygge-gradient i bunden af ikonet (som på kortene)
    local fade = row:CreateTexture(nil, "OVERLAY")
    fade:SetSize(ICON_SZ, 10)
    fade:SetPoint("BOTTOM", row.dungeonTex, "BOTTOM", 0, 0)
    fade:SetColorTexture(0.06, 0.07, 0.11, 0.75)

    -- +N overlay nede til højre på ikonet (3 px ekstra ned)
    row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.levelText:SetPoint("BOTTOMRIGHT", row.dungeonTex, "BOTTOMRIGHT", 0, -2)
    row.levelText:SetTextColor(C.TEXT_GOLD[1], C.TEXT_GOLD[2], C.TEXT_GOLD[3])
    row.levelText:SetShadowColor(0, 0, 0, 1)
    row.levelText:SetShadowOffset(1, -1)

    -- Tekstblok: dungeon + spillernavn centreret lodret i rækken
    local textBlock = CreateFrame("Frame", nil, row)
    textBlock:SetPoint("LEFT", row.dungeonTex, "RIGHT", 6, 0)
    textBlock:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    textBlock:SetPoint("TOP", row, "TOP", 0, 0)
    textBlock:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)

    -- Dungeon navn
    row.dungeonName = textBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.dungeonName:SetPoint("BOTTOM", textBlock, "CENTER", 0, 1)
    row.dungeonName:SetPoint("LEFT", textBlock, "LEFT", 0, 0)
    row.dungeonName:SetPoint("RIGHT", textBlock, "RIGHT", 0, 0)
    row.dungeonName:SetTextColor(0.65, 0.65, 0.85)
    row.dungeonName:SetJustifyH("LEFT")
    row.dungeonName:SetWordWrap(false)
    row.dungeonName:SetNonSpaceWrap(false)

    -- Spillernavn
    row.playerName = textBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.playerName:SetPoint("TOP", textBlock, "CENTER", 0, -1)
    row.playerName:SetPoint("LEFT", textBlock, "LEFT", 0, 0)
    row.playerName:SetPoint("RIGHT", textBlock, "RIGHT", 0, 0)
    row.playerName:SetJustifyH("LEFT")
    row.playerName:SetWordWrap(false)
    row.playerName:SetNonSpaceWrap(false)

    return row
end

-- ============================================================
-- Widget-liste  (alle aktive instanser)
-- ============================================================
BossHelper.keystoneWidgets = BossHelper.keystoneWidgets or {}

-- Kalder Refresh() på alle registrerede widgets — bruges af KeystoneTracker
function BossHelper.RefreshAllKeystoneWidgets()
    for _, widget in pairs(BossHelper.keystoneWidgets) do
        widget:Refresh()
    end
end

-- Reused across all Refresh() calls to avoid GC allocations
local refreshEntries = {}
local refreshSeen    = {}

-- ============================================================
-- Fabriksfunktion
-- ============================================================
-- Returnerer et widget-objekt:
--   widget.frame         — container-frame; brug :SetPoint(...) til placering
--   widget:Refresh()     — genopfrisk kortene fra BossHelper.Keystones
--   widget:SetVisible(b) — vis/skjul hele widgetten
--   widget:Destroy()     — frigør og afregistrér
--
-- Eksempel:
--   local w = BossHelper.UI.CreateKeystoneWidget(MyParentFrame)
--   w.frame:SetPoint("BOTTOMLEFT", MyParentFrame, "BOTTOMLEFT", 8, 8)
--
-- layout = "card" (standard) — vandrette kort (bruges på startside)
-- layout = "list"            — lodrette rækker med ikon til venstre (bruges i GroupFinderPanel)
function BossHelper.UI.CreateKeystoneWidget(parent, layout)
    layout = layout or "card"
    local isList = (layout == "list")

    local initW = isList and ROW_W or CARD_W
    local initH = isList and ROW_H  or CARD_H
    local section = CreateFrame("Frame", nil, parent)
    section:SetSize(initW, initH)
    section:Hide()

    local cards = {}

    -- --------------------------------------------------------
    -- Card-layout: samle/udfolde-tilstand  (kun brugt i card-mode)
    -- --------------------------------------------------------
    local collapsed   = (BossHelperDB and BossHelperDB.keystoneCollapsed == true) or false
    local collapseBtn = nil  -- forward-deklaration; sættes nedenfor

    -- Delegerer til Anim.PlaceKeystoneCard (Animations.lua)
    local function PlaceCard(card, fromX, toX, animate, delay)
        BossHelper.Anim.PlaceKeystoneCard(card, section, fromX, toX, animate, delay)
    end

    -- Placer alle synlige kort ud fra `collapsed`; animér hvis ønsket.
    local function ApplyCardLayout(animate)
        local n = #refreshEntries
        if n == 0 then
            if collapseBtn then collapseBtn:Hide() end
            return
        end

        local stackW   = CARD_W + (n - 1) * STACK_PEEK
        local totalW   = n * CARD_W + (n - 1) * CARD_GAP
        local btnExtra = (n > 1) and (COLLAPSE_BTN + 4) or 0

        if collapseBtn then
            if n > 1 then
                collapseBtn:Show()
                collapseBtn.arrow:SetText(collapsed and ">>" or "<<")
                -- Knappen animeres fra modsat tilstands position til ny position
                local btnFromX = collapsed and (totalW + 4) or (stackW + 4)
                local btnToX   = collapsed and (stackW + 4) or (totalW + 4)
                PlaceCard(collapseBtn, btnFromX, btnToX, animate, 0)
            else
                collapseBtn:Hide()
            end
        end

        if collapsed then
            -- Stablet: kort 1 forrest, kort N bagest (stikker mest ud til højre)
            section:SetSize(stackW + btnExtra, CARD_H)
            -- Kort 1 øverst (højest frame-level), kort N nederst
            for i = 1, n do
                if cards[i] then
                    cards[i]:SetFrameLevel(section:GetFrameLevel() + (n - i + 2))
                end
            end
            for i = 1, n do
                if cards[i] then
                    local fromX = (i - 1) * (CARD_W + CARD_GAP)
                    local toX   = (i - 1) * STACK_PEEK
                    local stagger = BossHelper.Anim.Config.KEYSTONE_STAGGER
                    PlaceCard(cards[i], fromX, toX, animate, animate and (i - 1) * stagger or 0)
                end
            end
        else
            -- Udfoldet: normal vandret layout
            section:SetSize(totalW + btnExtra, CARD_H)
            -- Frame-levels nulstilles EFTER animationen er færdig for at undgå
            -- at kortene popper frem i z-rækkefølge midt i animationen.
            if animate then
                local cfg = BossHelper.Anim.Config
                local resetDelay = (n - 1) * cfg.KEYSTONE_STAGGER + cfg.KEYSTONE_SLIDE_DURATION + 0.05
                C_Timer.After(resetDelay, function()
                    for i = 1, n do
                        if cards[i] then
                            cards[i]:SetFrameLevel(section:GetFrameLevel() + 1)
                        end
                    end
                end)
            else
                for i = 1, n do
                    if cards[i] then
                        cards[i]:SetFrameLevel(section:GetFrameLevel() + 1)
                    end
                end
            end
            for i = 1, n do
                if cards[i] then
                    local fromX = (i - 1) * STACK_PEEK
                    local toX   = (i - 1) * (CARD_W + CARD_GAP)
                    local stagger = BossHelper.Anim.Config.KEYSTONE_STAGGER
                    PlaceCard(cards[i], fromX, toX, animate, animate and (i - 1) * stagger or 0)
                end
            end
        end
    end

    -- Opret samle-knappen (kun i card-layout)
    if not isList then
        -- Kun pil-tekst, ingen backdrop – samme stil som CreateIconOnly.
        collapseBtn = CreateFrame("Button", nil, section)
        collapseBtn:SetSize(COLLAPSE_BTN, CARD_H)
        collapseBtn:SetPoint("LEFT", section, "LEFT", 0, 0)  -- position styres af ApplyCardLayout/PlaceCard

        collapseBtn.arrow = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        collapseBtn.arrow:SetPoint("CENTER")
        collapseBtn.arrow:SetText("<<")
        collapseBtn.arrow:SetTextColor(
            BossHelper.UI.C.TEXT_ORANGE[1],
            BossHelper.UI.C.TEXT_ORANGE[2],
            BossHelper.UI.C.TEXT_ORANGE[3])

        collapseBtn:SetScript("OnEnter", function(self)
            self.arrow:SetTextColor(1, 1, 1)
        end)
        collapseBtn:SetScript("OnLeave", function(self)
            self.arrow:SetTextColor(
                BossHelper.UI.C.TEXT_ORANGE[1],
                BossHelper.UI.C.TEXT_ORANGE[2],
                BossHelper.UI.C.TEXT_ORANGE[3])
        end)
        collapseBtn:SetScript("OnClick", function()
            collapsed = not collapsed
            BossHelperDB = BossHelperDB or {}
            BossHelperDB.keystoneCollapsed = collapsed
            ApplyCardLayout(true)
        end)
        collapseBtn:Hide()
    end

    -- --------------------------------------------------------
    -- Refresh
    -- --------------------------------------------------------
    local function Refresh()
        -- Reuse module-level tables to avoid GC allocations
        wipe(refreshEntries)
        wipe(refreshSeen)

        -- Lokal spillers nøgle
        if C_MythicPlus then
            local myLevel = C_MythicPlus.GetOwnedKeystoneLevel()
            local myMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
            local myName  = UnitName("player")
            if type(myLevel) == "number" and myLevel > 0
            and type(myMapID) == "number" and myMapID > 0 then
                refreshEntries[#refreshEntries+1] = {
                    playerName = myName,
                    keyLevel   = myLevel,
                    keyMapID   = myMapID,
                }
                refreshSeen[myName] = true
            end
        end

        -- Party-members fra LibKeystone
        if BossHelper.Keystones then
            local getShort = BossHelper.GetKeystoneShortName
            for name, data in pairs(BossHelper.Keystones) do
                local shortName = getShort and getShort(name) or (name:match("^([^%-]+)") or name)
                if not refreshSeen[name] and not refreshSeen[shortName]
                and type(data.keyLevel) == "number" and data.keyLevel > 0
                and type(data.keyMapID) == "number" and data.keyMapID > 0 then
                    refreshEntries[#refreshEntries+1] = {
                        playerName = name,
                        shortName  = shortName,
                        keyLevel   = data.keyLevel,
                        keyMapID   = data.keyMapID,
                    }
                    refreshSeen[name] = true
                end
            end
        end

        -- Tilføj gruppe-medlemmer uden key
        if IsInRaid() or IsInGroup() then
            local function tryAddNoKey(unit)
                local name = UnitName(unit)
                if not name then return end
                local shortName = name:match("^([^%-]+)") or name
                if not refreshSeen[name] and not refreshSeen[shortName] then
                    refreshEntries[#refreshEntries+1] = {
                        playerName = name,
                        shortName  = shortName,
                        noKey      = true,
                    }
                    refreshSeen[name] = true
                end
            end
            tryAddNoKey("player")
            if IsInRaid() then
                for i = 1, GetNumGroupMembers() do
                    tryAddNoKey("raid"..i)
                end
            else
                for i = 1, GetNumGroupMembers() - 1 do
                    tryAddNoKey("party"..i)
                end
            end
        end

        -- Skjul gamle kort
        for _, card in ipairs(cards) do
            card:Hide()
        end

        if #refreshEntries == 0 then
            section:Hide()
            return
        end

        if isList then
            -- List-layout: lodrette rækker, ikon til venstre
            local totalH = #refreshEntries * ROW_H + (#refreshEntries - 1) * ROW_GAP
            section:SetSize(ROW_W, totalH)
            section:Show()

            for i, entry in ipairs(refreshEntries) do
                if not cards[i] then
                    cards[i] = BuildKeystoneRow(section)
                end
                local card = cards[i]
                card:ClearAllPoints()
                card:SetPoint("TOP", section, "TOP", 0, -((i-1) * (ROW_H + ROW_GAP)))
                card:Show()

                card.dungeonTex:SetDesaturated(entry.noKey and true or false)
                if entry.noKey then
                    if card._lastMapID ~= "NO_KEY" then
                        card.dungeonTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(Translate("NO_KEY") or "No key")
                        card._lastMapID = "NO_KEY"
                    end
                    if card._lastLevel ~= 0 then
                        card.levelText:SetText("")
                        card._lastLevel = 0
                    end
                else
                    local info = GetDungeonInfo(entry.keyMapID)
                    if card._lastMapID ~= entry.keyMapID then
                        card.dungeonTex:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(info.name)
                        card._lastMapID = entry.keyMapID
                    end
                    if card._lastLevel ~= entry.keyLevel then
                        card.levelText:SetText("+"..entry.keyLevel)
                        card._lastLevel = entry.keyLevel
                    end
                end

                local shortName = entry.shortName or (entry.playerName:match("^([^%-]+)") or entry.playerName)
                local r, g, b = GetUnitClassColor(entry.playerName)
                card.playerName:SetText(shortName)
                card.playerName:SetTextColor(r, g, b)
            end
        else
            -- Card-layout: vandrette kort (standard, bruges på startside)
            -- Data-opdatering; positionering sker via ApplyCardLayout()
            for i, entry in ipairs(refreshEntries) do
                if not cards[i] then
                    cards[i] = BuildKeystoneCard(section)
                end
                local card = cards[i]
                card:Show()

                card.dungeonTex:SetDesaturated(entry.noKey and true or false)
                if entry.noKey then
                    if card._lastMapID ~= "NO_KEY" then
                        card.dungeonTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(Translate("NO_KEY") or "No key")
                        card._lastMapID = "NO_KEY"
                    end
                    if card._lastLevel ~= 0 then
                        card.levelText:SetText("")
                        card._lastLevel = 0
                    end
                else
                    local info = GetDungeonInfo(entry.keyMapID)
                    if card._lastMapID ~= entry.keyMapID then
                        card.dungeonTex:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(info.name)
                        card._lastMapID = entry.keyMapID
                    end
                    if card._lastLevel ~= entry.keyLevel then
                        card.levelText:SetText("+"..entry.keyLevel)
                        card._lastLevel = entry.keyLevel
                    end
                end

                local shortName = entry.shortName or (entry.playerName:match("^([^%-]+)") or entry.playerName)
                local r, g, b = GetUnitClassColor(entry.playerName)
                card.playerName:SetText(shortName)
                card.playerName:SetTextColor(r, g, b)
            end
            section:Show()
            ApplyCardLayout(false)
        end
    end

    -- --------------------------------------------------------
    -- Widget-objekt
    -- --------------------------------------------------------
    local id = tostring(section)  -- unik nøgle baseret på frame-adresse
    local enabled = true          -- kan deaktiveres udefra via :SetEnabled(false)

    local widget = {
        frame = section,

        Refresh = function(self)
            if not enabled then section:Hide(); return end
            Refresh()
        end,

        SetEnabled = function(self, val)
            enabled = val
            if not val then
                section:Hide()
            else
                Refresh()
            end
        end,

        SetVisible = function(self, visible)
            if visible then
                Refresh()
            else
                section:Hide()
            end
        end,

        Destroy = function(self)
            BossHelper.keystoneWidgets[id] = nil
            section:Hide()
            section:SetParent(nil)
        end,
    }

    BossHelper.keystoneWidgets[id] = widget
    return widget
end
