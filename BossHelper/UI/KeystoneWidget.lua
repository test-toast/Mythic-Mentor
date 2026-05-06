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
local UnitIsGroupLeader   = UnitIsGroupLeader
local type, pairs, wipe  = type, pairs, wipe

-- Teleport-funktioner er defineret i MythicTeleport.lua (loader før denne fil)
-- og eksponeret på BossHelper.GetTeleportSpell / BossHelper.UpdateTeleportCooldown.

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

    -- Teleport-knap: klik på dungeon-billedet for at teleportere
    card.teleportBtn = CreateFrame("Button", nil, card, "SecureActionButtonTemplate")
    card.teleportBtn:SetSize(CARD_W - 8, 40)
    card.teleportBtn:SetPoint("TOP", card, "TOP", 0, -4)
    card.teleportBtn:RegisterForClicks("AnyDown", "AnyUp")
    card.teleportBtn:SetFrameLevel(card:GetFrameLevel() + 5)

    -- Cooldown-swipe over billedet
    card.teleportBtn.cooldown = CreateFrame("Cooldown", nil, card.teleportBtn, "CooldownFrameTemplate")
    card.teleportBtn.cooldown:SetAllPoints(card.teleportBtn)
    card.teleportBtn.cooldown:SetDrawEdge(false)
    card.teleportBtn.cooldown:SetDrawSwipe(false)
    card.teleportBtn.cooldown:SetHideCountdownNumbers(false)
    card.teleportBtn.cooldown:SetFrameLevel(card.teleportBtn:GetFrameLevel() + 1)
    local cdFont = card.teleportBtn.cooldown:GetRegions()
    if cdFont and cdFont.SetFont then
        cdFont:SetFont(cdFont:GetFont(), 9, "OUTLINE")
        cdFont:ClearAllPoints()
        cdFont:SetPoint("TOPLEFT", card.teleportBtn.cooldown, "TOPLEFT", 2, -2)
        cdFont:SetJustifyH("LEFT")
    end

    -- Hover-mørkening (HIGHLIGHT-laget vises automatisk ved hover)
    local cardHighlight = card.teleportBtn:CreateTexture(nil, "HIGHLIGHT")
    cardHighlight:SetAllPoints(card.teleportBtn)
    cardHighlight:SetColorTexture(0, 0, 0, 0.5)
    card.teleportBtn.highlightTex = cardHighlight

    card.teleportBtn:SetScript("OnEnter", function(self)
        if self.spellID and BossHelperDB and BossHelperDB.teleportOnKeyCards ~= false then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end)
    card.teleportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card.teleportBtn:RegisterEvent("SPELLS_CHANGED")
    card.teleportBtn:SetScript("OnEvent", function(self, event)
        if event == "SPELLS_CHANGED" then BossHelper.UpdateTeleportCooldown(self) end
    end)

    -- Top-lag over teleportBtn så levelText og crownIcon aldrig dækkes af hover-mørkening
    card.topLayer = CreateFrame("Frame", nil, card)
    card.topLayer:SetAllPoints(card.dungeonTex)
    card.topLayer:SetFrameLevel(card.teleportBtn:GetFrameLevel() + 10)

    -- Halvgennemsigtig gradient i bunden af billedet så teksten er læselig
    local fade = card:CreateTexture(nil, "OVERLAY")
    fade:SetSize(CARD_W - 8, 12)
    fade:SetPoint("BOTTOM", card.dungeonTex, "BOTTOM", 0, 0)
    fade:SetColorTexture(0.06, 0.07, 0.11, 0.75)

    -- +N overlay
    card.levelText = card.topLayer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.levelText:SetPoint("BOTTOMRIGHT", card.topLayer, "BOTTOMRIGHT", -3, 0)
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

    -- Krone-ikon øverst i midten af billedet (kun synlig for party leader)
    card.crownIcon = card.topLayer:CreateTexture(nil, "OVERLAY", nil, 2)
    card.crownIcon:SetSize(16, 16)
    card.crownIcon:SetPoint("LEFT", card.topLayer, "LEFT", 0, -14)
    card.crownIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    card.crownIcon:Hide()

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

    -- Teleport-knap: klik på dungeon-ikonet for at teleportere
    row.teleportBtn = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
    row.teleportBtn:SetSize(ICON_SZ, ICON_SZ)
    row.teleportBtn:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.teleportBtn:RegisterForClicks("AnyDown", "AnyUp")
    row.teleportBtn:SetFrameLevel(row:GetFrameLevel() + 5)

    -- Cooldown-swipe over ikonet
    row.teleportBtn.cooldown = CreateFrame("Cooldown", nil, row.teleportBtn, "CooldownFrameTemplate")
    row.teleportBtn.cooldown:SetAllPoints(row.teleportBtn)
    row.teleportBtn.cooldown:SetDrawEdge(false)
    row.teleportBtn.cooldown:SetDrawSwipe(false)
    row.teleportBtn.cooldown:SetHideCountdownNumbers(false)
    row.teleportBtn.cooldown:SetFrameLevel(row.teleportBtn:GetFrameLevel() + 1)
    local cdFontRow = row.teleportBtn.cooldown:GetRegions()
    if cdFontRow and cdFontRow.SetFont then
        cdFontRow:SetFont(cdFontRow:GetFont(), 8, "OUTLINE")
        cdFontRow:ClearAllPoints()
        cdFontRow:SetPoint("TOPLEFT", row.teleportBtn.cooldown, "TOPLEFT", 0, 0)
        cdFontRow:SetJustifyH("LEFT")
    end

    -- Hover-mørkening (HIGHLIGHT-laget vises automatisk ved hover)
    local rowHighlight = row.teleportBtn:CreateTexture(nil, "HIGHLIGHT")
    rowHighlight:SetAllPoints(row.teleportBtn)
    rowHighlight:SetColorTexture(0, 0, 0, 0.5)
    row.teleportBtn.highlightTex = rowHighlight

    row.teleportBtn:SetScript("OnEnter", function(self)
        if self.spellID and BossHelperDB and BossHelperDB.teleportOnKeyList ~= false then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end)
    row.teleportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.teleportBtn:RegisterEvent("SPELLS_CHANGED")
    row.teleportBtn:SetScript("OnEvent", function(self, event)
        if event == "SPELLS_CHANGED" then BossHelper.UpdateTeleportCooldown(self) end
    end)

    -- Top-lag over teleportBtn så levelText og crownIcon aldrig dækkes af hover-mørkening
    row.topLayer = CreateFrame("Frame", nil, row)
    row.topLayer:SetSize(ICON_SZ, ICON_SZ)
    row.topLayer:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.topLayer:SetFrameLevel(row.teleportBtn:GetFrameLevel() + 10)

    -- Skygge-gradient i bunden af ikonet (som på kortene)
    local fade = row:CreateTexture(nil, "OVERLAY")
    fade:SetSize(ICON_SZ, 10)
    fade:SetPoint("BOTTOM", row.dungeonTex, "BOTTOM", 0, 0)
    fade:SetColorTexture(0.06, 0.07, 0.11, 0.75)

    -- +N overlay nede til højre på ikonet (3 px ekstra ned)
    row.levelText = row.topLayer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.levelText:SetPoint("BOTTOMRIGHT", row.topLayer, "BOTTOMRIGHT", 0, -2)
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

    -- Krone-ikon øverst i midten af ikonet (kun synlig for party leader)
    row.crownIcon = row.topLayer:CreateTexture(nil, "OVERLAY", nil, 2)
    row.crownIcon:SetSize(14, 14)
    row.crownIcon:SetPoint("TOP", row.topLayer, "TOP", 0, 8)
    row.crownIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    row.crownIcon:Hide()

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
            -- Kort 1 øverst (højest frame-level), kort N nederst.
            -- Afstand på 20 pr. kort sikrer at børne-frames (topLayer = kort+15,
            -- cooldown = kort+6) fra et bageste kort ALDRIG overskriver et forreste.
            for i = 1, n do
                if cards[i] then
                    cards[i]:SetFrameLevel(section:GetFrameLevel() + (n - i + 1) * 20)
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

        -- Cache bruger-indstillinger én gang per Refresh-kald
        local db = BossHelperDB
        local tpCardsOn = not (db and db.teleportOnKeyCards == false)
        local tpListOn  = not (db and db.teleportOnKeyList  == false)

        -- Hjælper: byg entry for ét unit-slot
        local function AddSlot(unit)
            local name, realm = UnitName(unit)
            if not name then return end
            local shortName = name:match("^([^%-]+)") or name
            local fullName  = (realm and realm ~= "") and (name.."-"..realm) or name

            -- Slå keystone op: lokal spiller via C_MythicPlus, andre via BossHelper.Keystones
            local keyLevel, keyMapID
            if unit == "player" and C_MythicPlus then
                keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
                keyMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
            end
            if (not keyLevel or keyLevel == 0) and BossHelper.Keystones then
                local data = BossHelper.Keystones[fullName] or BossHelper.Keystones[name] or BossHelper.Keystones[shortName]
                if data then
                    keyLevel = data.keyLevel
                    keyMapID = data.keyMapID
                end
            end

            local hasKey = type(keyLevel) == "number" and keyLevel > 0
                       and type(keyMapID) == "number" and keyMapID > 0
            refreshEntries[#refreshEntries+1] = {
                playerName = shortName,
                unit       = unit,
                keyLevel   = hasKey and keyLevel or nil,
                keyMapID   = hasKey and keyMapID or nil,
                noKey      = not hasKey,
            }
        end

        -- Iterér unit-slots i fast rækkefølge
        -- Raid vises ikke — for mange spillere og ikke relevant for M+
        if not IsInRaid() then
            AddSlot("player")
            if IsInGroup() then
                for i = 1, GetNumGroupMembers() - 1 do
                    AddSlot("party"..i)
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
                    BossHelper.ApplyTeleportButton(card.teleportBtn, nil, false)
                else
                    local info = GetDungeonInfo(entry.keyMapID)
                    if card._lastMapID ~= entry.keyMapID then
                        card.dungeonTex:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(info.name)
                        card._lastMapID = entry.keyMapID
                    end
                    BossHelper.ApplyTeleportButton(card.teleportBtn, BossHelper.GetTeleportSpell(entry.keyMapID), tpListOn)
                    if card._lastLevel ~= entry.keyLevel then
                        card.levelText:SetText("+"..entry.keyLevel)
                        card._lastLevel = entry.keyLevel
                    end
                end

                BossHelper.UpdateTeleportCooldown(card.teleportBtn)
                local shortName = entry.shortName or (entry.playerName:match("^([^%-]+)") or entry.playerName)
                local r, g, b = GetUnitClassColor(entry.playerName)
                card.playerName:SetText(shortName)
                card.playerName:SetTextColor(r, g, b)
                card.crownIcon:SetShown(entry.unit ~= nil and UnitIsGroupLeader(entry.unit) == true)
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
                    BossHelper.ApplyTeleportButton(card.teleportBtn, nil, false)
                else
                    local info = GetDungeonInfo(entry.keyMapID)
                    if card._lastMapID ~= entry.keyMapID then
                        card.dungeonTex:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                        card.dungeonName:SetText(info.name)
                        card._lastMapID = entry.keyMapID
                    end
                    BossHelper.ApplyTeleportButton(card.teleportBtn, BossHelper.GetTeleportSpell(entry.keyMapID), tpCardsOn)
                    if card._lastLevel ~= entry.keyLevel then
                        card.levelText:SetText("+"..entry.keyLevel)
                        card._lastLevel = entry.keyLevel
                    end
                end

                BossHelper.UpdateTeleportCooldown(card.teleportBtn)
                local shortName = entry.shortName or (entry.playerName:match("^([^%-]+)") or entry.playerName)
                local r, g, b = GetUnitClassColor(entry.playerName)
                card.playerName:SetText(shortName)
                card.playerName:SetTextColor(r, g, b)
                card.crownIcon:SetShown(entry.unit ~= nil and UnitIsGroupLeader(entry.unit) == true)
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
    local visAllowed = true       -- kan sættes til false via :SetVisible(false); forhindrer Refresh() i at vise widgetten

    local widget = {
        frame = section,

        Refresh = function(self)
            if not enabled or not visAllowed then section:Hide(); return end
            Refresh()
        end,

        SetEnabled = function(self, val)
            enabled = val
            if not val then
                section:Hide()
            else
                visAllowed = true  -- eksplicit aktivering nulstiller visnings-spærren
                Refresh()
            end
        end,

        SetVisible = function(self, vis)
            visAllowed = vis
            if vis then
                if enabled then Refresh() end
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
