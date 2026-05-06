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

local deps = {}  -- populated by Init / ShowInfo

function BossInfo.Init(d)
    if not d then return end
    for k, v in pairs(d) do deps[k] = v end
end

-- ---- Shortcuts to shared UI helpers -----------------------------------
local phide      = function(o)      BossHelper.UI.hide(o)         end
local psetparent = function(o, p)   BossHelper.UI.setParent(o, p) end
local psettext   = function(o, txt) BossHelper.UI.setText(o, txt) end
local function psafesound(sid)
    pcall(function()
        if deps.BossHelper and deps.BossHelper.SafePlaySound then
            deps.BossHelper:SafePlaySound(sid)
        end
    end)
end

-- ============================================================
-- CATEGORY LIST — change / add entries here to update the left panel.
-- The string must match one of the elseif branches in BuildInfoCategoryUI.
-- ============================================================
local CATEGORY_LIST = {
    "About",
    "Features",
    "Changelog",
    "Help",
    "Commands",
    "Credits",
}

-- ============================================================
-- Cleanup helper
-- ============================================================
local function CleanupInfoWidgets(rPanel)
    if not rPanel then return end
    if rPanel.settingsWidgets then
        for _, w in ipairs(rPanel.settingsWidgets) do
            BossHelper.UI.destroyWidget(w)
        end
        rPanel.settingsWidgets = nil
    end
    if rPanel.infoScrollContent then
        rPanel.infoScrollContent:Hide()
        rPanel.infoScrollContent:SetParent(nil)
        rPanel.infoScrollContent = nil
    end
end

-- ============================================================
-- BuildInfoCategoryUI
--   Builds card-based content for each info category inside rPanel.
--   Uses the same card visual style as BossSettings.
-- ============================================================
function BossInfo.BuildInfoCategoryUI(rPanel, category, ctx)
    -- Ensure persistent scroll frame
    if not rPanel.infoScrollFrame then
        local sf = CreateFrame("ScrollFrame", nil, rPanel, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     rPanel, "TOPLEFT",     10, -40)
        sf:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -30, 4)
        sf:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, max)))
        end)
        rPanel.infoScrollFrame = sf
    end
    rPanel.infoScrollFrame:Show()

    -- Fresh content frame for each category switch
    local content = CreateFrame("Frame", nil, rPanel.infoScrollFrame)
    content:SetWidth(540)
    content:SetHeight(1)
    rPanel.infoScrollFrame:SetScrollChild(content)
    rPanel.infoScrollContent = content

    rPanel.settingsWidgets = rPanel.settingsWidgets or {}

    local _C  = BossHelper.UI.C
    local _BD = BossHelper.UI.ApplyBackdrop
    local function W(w) table.insert(rPanel.settingsWidgets, w); return w end

    -- ---- Card layout constants (matches BossSettings) -----------------
    local CARD_W   = 540   -- card width
    local CARD_X   = 2     -- card left offset inside content
    local CARD_PH  = 10    -- horizontal padding inside card
    local CARD_PV  = 10    -- vertical padding (top)
    local CARD_PVB = 10    -- vertical padding (bottom)
    local CARD_GAP = 10    -- gap between cards

    local cardY    = 0   -- tracks next-card top (negative = down)
    local allCards = {}  -- all cards in the current category, for repositioning

    -- Collapsed card height: just title + equal padding so text is vertically centred
    local CARD_HEADER_H = CARD_PV + 10 + CARD_PV  -- = 33

    -- Reposition every card using their CURRENT frame heights (works mid-animation)
    local function RepositionCards()
        local y = 0
        for _, entry in ipairs(allCards) do
            entry.frame:ClearAllPoints()
            entry.frame:SetPoint("TOPLEFT", content, "TOPLEFT", CARD_X, y)
            y = y - entry.frame:GetHeight() - CARD_GAP
        end
        content:SetHeight(math.max(math.abs(y) + 20, 100))
    end

    -- Animate card height + arrow rotation + body-element alpha simultaneously (cosine-ease)
    local function AnimateCardToggle(cardEntry, arrowTex, targetCollapsed)
        local f     = cardEntry.frame
        local fromH = f:GetHeight()
        local toH   = targetCollapsed and CARD_HEADER_H or cardEntry.fullHeight

        local ROT_COLLAPSED = math.pi  -- arrow points up   (collapsed)
        local ROT_EXPANDED  = 0        -- arrow points down (expanded, ▼)
        local fromRot = cardEntry._arrowRot or (targetCollapsed and ROT_EXPANDED or ROT_COLLAPSED)
        local toRot   = targetCollapsed and ROT_COLLAPSED or ROT_EXPANDED

        cardEntry.collapsed = targetCollapsed
        cardEntry._arrowRot = toRot

        local anim    = BossHelper and BossHelper.Anim
        local canAnim = anim and anim.ShouldAnimate and anim.ShouldAnimate()

        if not canAnim then
            f:SetHeight(toH)
            if arrowTex then arrowTex:SetRotation(toRot) end
            for _, el in ipairs(cardEntry.bodyElements) do
                if targetCollapsed then
                    el:Hide(); pcall(function() el:SetAlpha(1) end)
                else
                    el:Show(); pcall(function() el:SetAlpha(1) end)
                end
            end
            RepositionCards()
            return
        end

        -- Alpha direction: expanding fades in (0→1), collapsing fades out (1→0)
        local fromA = targetCollapsed and 1 or 0
        local toA   = targetCollapsed and 0 or 1

        -- Show body at alpha=0 before expanding so they clip inside the growing frame
        if not targetCollapsed then
            for _, el in ipairs(cardEntry.bodyElements) do
                pcall(function() el:SetAlpha(0); el:Show() end)
            end
        end

        local duration = 0.18
        local start    = GetTime()
        if f._heightTween then f._heightTween.running = false end
        f._heightTween = { running = true }
        f:SetHeight(fromH)
        f:SetScript("OnUpdate", function(self)
            if not f._heightTween.running then self:SetScript("OnUpdate", nil); return end
            local t     = math.min((GetTime() - start) / duration, 1)
            local eased = (1 - math.cos(t * math.pi)) * 0.5
            -- height
            f:SetHeight(fromH + (toH - fromH) * eased)
            -- arrow rotation
            if arrowTex then arrowTex:SetRotation(fromRot + (toRot - fromRot) * eased) end
            -- body element alpha (FontStrings + Textures all support SetAlpha)
            local a = fromA + (toA - fromA) * eased
            for _, el in ipairs(cardEntry.bodyElements) do
                pcall(function() el:SetAlpha(a) end)
            end
            RepositionCards()
            if t >= 1 then
                self:SetScript("OnUpdate", nil)
                f._heightTween.running = false
                for _, el in ipairs(cardEntry.bodyElements) do
                    if targetCollapsed then
                        el:Hide(); pcall(function() el:SetAlpha(1) end)
                    else
                        pcall(function() el:SetAlpha(1) end)
                    end
                end
            end
        end)
    end

    -- ---- MakeCard ------------------------------------------------------
    -- Creates a styled card with orange title + divider rule.
    -- Returns: card, add(type, ...), fin()
    --
    -- opts (optional table):
    --   collapsible   = true   card header is clickable to collapse/expand
    --   startExpanded = true   start expanded (only relevant when collapsible)
    --
    -- add() variants:
    --   add("text",      "string" [, r, g, b])
    --   add("header",    "string")
    --   add("bullet",    "string" [, indent])
    --   add("subbullet", "string" [, indent])
    --   add("keyval",    "key",   "value")
    --   add("spacer",    pixels)
    -- --------------------------------------------------------------------
    local function MakeCard(title, opts)
        opts = opts or {}
        local collapsible    = opts.collapsible  or false
        local startCollapsed = collapsible and (opts.startExpanded ~= true)

        local card = W(CreateFrame("Frame", nil, content, "BackdropTemplate"))
        card:SetWidth(CARD_W)
        card:SetHeight(50)
        _BD(card, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", CARD_X, cardY)

        -- Card title (small, uppercase, orange) — centred vertically when collapsed
        local titleFs = W(card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, -CARD_PV)
        titleFs:SetText(title:upper())
        titleFs:SetTextColor(1, 0.5, 0)
        titleFs:SetJustifyH("LEFT")

        -- Arrow texture (same asset as language dropdown), rotated for collapsed state
        local arrowTex
        if collapsible then
            arrowTex = card:CreateTexture(nil, "OVERLAY")
            arrowTex:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
            arrowTex:SetVertexColor(1, 0.5, 0, 0.9)
            arrowTex:SetSize(20, 10)
            arrowTex:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PH, -(CARD_PV - 1))
            local initRot = startCollapsed and math.pi or 0
            arrowTex:SetRotation(initRot)
            table.insert(rPanel.settingsWidgets, arrowTex)
        end

        -- bodyElements: FontStrings/Textures created by add() + the rule;
        -- all are shown/hidden together on collapse.
        local bodyElements = {}
        local function WB(w)
            table.insert(bodyElements, w)
            table.insert(rPanel.settingsWidgets, w)
            return w
        end

        -- Divider rule under the title — part of body so it hides when collapsed
        local rule = WB(card:CreateTexture(nil, "ARTWORK"))
        rule:SetColorTexture(1, 0.5, 0, 0.25)
        rule:SetHeight(1)
        rule:SetWidth(CARD_W - CARD_PH * 2)
        rule:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -4)

        local cy = -(CARD_PV + 13 + 4 + 1 + 8)  -- after title + gap + rule + gap

        local function add(itype, a1, a2, a3, a4)
            if itype == "spacer" then
                cy = cy - (a1 or 8)
                return
            end

            if itype == "header" then
                local fs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
                fs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
                fs:SetWidth(CARD_W - CARD_PH * 2)
                fs:SetWordWrap(true)
                fs:SetJustifyH("LEFT")
                fs:SetText(a1)
                fs:SetTextColor(1, 0.5, 0)
                cy = cy - (fs:GetStringHeight() or 16) - 6
                return
            end

            if itype == "text" then
                local r = (type(a2) == "number") and a2 or _C.TEXT_GOLD[1]
                local g = a3 or _C.TEXT_GOLD[2]
                local b = a4 or _C.TEXT_GOLD[3]
                local fs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                fs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
                fs:SetWidth(CARD_W - CARD_PH * 2)
                fs:SetWordWrap(true)
                fs:SetJustifyH("LEFT")
                fs:SetText(a1)
                fs:SetTextColor(r, g, b)
                cy = cy - (fs:GetStringHeight() or 16) - 5
                return
            end

            if itype == "bullet" then
                local indent = (type(a2) == "number") and a2 or 0
                local bx = CARD_PH + indent

                local dot = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                dot:SetPoint("TOPLEFT", card, "TOPLEFT", bx, cy)
                dot:SetText("|cffFF8C00•|r")
                dot:SetWidth(14)
                dot:SetJustifyH("LEFT")

                local fs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                fs:SetPoint("TOPLEFT", card, "TOPLEFT", bx + 16, cy)
                fs:SetWidth(CARD_W - CARD_PH * 2 - indent - 16)
                fs:SetWordWrap(true)
                fs:SetJustifyH("LEFT")
                fs:SetText(a1)
                fs:SetTextColor(_C.TEXT_GOLD[1], _C.TEXT_GOLD[2], _C.TEXT_GOLD[3])
                cy = cy - (fs:GetStringHeight() or 16) - 5
                return
            end

            if itype == "subbullet" then
                local indent = (type(a2) == "number") and a2 or 20
                local bx = CARD_PH + indent

                local dot = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                dot:SetPoint("TOPLEFT", card, "TOPLEFT", bx, cy)
                dot:SetText("|cff888888–|r")
                dot:SetWidth(14)
                dot:SetJustifyH("LEFT")

                local fs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                fs:SetPoint("TOPLEFT", card, "TOPLEFT", bx + 16, cy)
                fs:SetWidth(CARD_W - CARD_PH * 2 - indent - 16)
                fs:SetWordWrap(true)
                fs:SetJustifyH("LEFT")
                fs:SetText(a1)
                fs:SetTextColor(0.72, 0.72, 0.72)
                cy = cy - (fs:GetStringHeight() or 16) - 4
                return
            end

            if itype == "keyval" then
                local key, val = a1, a2
                local kw = 155

                local kfs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                kfs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH, cy)
                kfs:SetWidth(kw)
                kfs:SetJustifyH("LEFT")
                kfs:SetText(tostring(key or ""))
                kfs:SetTextColor(1, 0.62, 0.22)

                local vfs = WB(card:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                vfs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PH + kw + 6, cy)
                vfs:SetWidth(CARD_W - CARD_PH * 2 - kw - 6)
                vfs:SetWordWrap(true)
                vfs:SetJustifyH("LEFT")
                vfs:SetText(tostring(val or ""))
                vfs:SetTextColor(_C.TEXT_GOLD[1], _C.TEXT_GOLD[2], _C.TEXT_GOLD[3])

                local lineH = math.max(kfs:GetStringHeight() or 16, vfs:GetStringHeight() or 16)
                cy = cy - lineH - 6
                return
            end
        end

        -- Track this card so RepositionCards / AnimateCardToggle can access it
        local cardEntry = {
            frame        = card,
            bodyElements = bodyElements,
            collapsed    = startCollapsed,
            fullHeight   = nil,
            _arrowRot    = startCollapsed and math.pi or 0,
        }
        table.insert(allCards, cardEntry)

        -- Clickable header for collapsible cards
        if collapsible then
            local btn = W(CreateFrame("Button", nil, card))
            btn:SetPoint("TOPLEFT",     card, "TOPLEFT", 0, 0)
            btn:SetPoint("BOTTOMRIGHT", card, "TOPLEFT", CARD_W, -CARD_HEADER_H)
            btn:SetScript("OnClick", function()
                AnimateCardToggle(cardEntry, arrowTex, not cardEntry.collapsed)
            end)
            btn:SetScript("OnEnter", function() titleFs:SetTextColor(1, 0.75, 0.2) end)
            btn:SetScript("OnLeave", function() titleFs:SetTextColor(1, 0.5,  0)   end)
        end

        local function fin()
            local fullH = math.abs(cy) + CARD_PVB
            cardEntry.fullHeight = fullH
            if startCollapsed then
                for _, el in ipairs(bodyElements) do el:Hide() end
                card:SetHeight(CARD_HEADER_H)
                cardY = cardY - CARD_HEADER_H - CARD_GAP
            else
                card:SetHeight(fullH)
                cardY = cardY - fullH - CARD_GAP
            end
            content:SetHeight(math.max(math.abs(cardY) + 20, 100))
        end

        return card, add, fin
    end

    -- ==================================================================
    -- CATEGORY CONTENT
    -- ==================================================================

    if category == "About" then
        do
            local _, add, fin = MakeCard("Mythic Mentor")
            add("text", "Simple in-game Mythic+ guide that shows quick boss tactics, lets you share them instantly with your group, and keeps everything accessible without leaving the game.")
            add("spacer", 10)
            add("text", "Built by Burning Toast Studio — Simple, Fast, & Easy.")
            fin()
        end
        do
            local _, add, fin = MakeCard("Version Info")
            add("keyval", "Current Version",  BossHelper.VERSION_STRING or "unknown")
            add("keyval", "Season",           "Season 1 – Midnight")
            add("keyval", "Language Support", "EN  ·  DA  ·  DE  ·  FR  ·  RU")
            fin()
        end
        do
            local _, add, fin = MakeCard("Links")
            add("keyval", "Discord",     "  Join us for news, tips, and support")
            add("keyval", "CurseForge",  "  Download & track updates")
            add("keyval", "GitHub",      "  Source code & bug reports")
            fin()
        end

    elseif category == "Features" then
        do
            local _, add, fin = MakeCard("Boss Tactics")
            add("bullet", "Easy to read tactics for every boss in all current M+ dungeons")
            add("bullet", "Post tactics directly to party chat (or copy in instances)")
            add("bullet", "Detailed boss tactics for all current M+ dungeons (Work in progress)")
            fin()
        end
        do
            local _, add, fin = MakeCard("Affix Guide")
            add("bullet", "Easy to read tactics for every affix.")
            add("bullet", "Show every affix in which key level it appears in.")
            add("bullet", "automatically update every week when the affixes rotate.")
            fin()
        end
        do
            local _, add, fin = MakeCard("Mini-Window")
            add("bullet", "Opens automatically when you enter a Mythic+ dungeon")
            add("bullet", "Shows tactics for the current boss encounter")
            add("bullet", "Automatically switches to the next boss when you defeat a boss.")
            fin()
        end
        do
            local _, add, fin = MakeCard("Dungeon Check Window")
            add("bullet", "Opens automatically when you enter a Mythic+ dungeon")
            add("bullet", "Shows spec, role, gear durability, flask and food status")
            add("bullet", "Party leaders can run a Ready Check or Countdown from this window")
            add("bullet", "Closes automatically when the dungeon timer starts")
            fin()
        end
        do
            local _, add, fin = MakeCard("Key Tracker")
            add("bullet", "Shows all party keystones on the Start Page and in the Group Finder panel")
            add("bullet", "Click on the dungeon image on a keystone to teleport directly there (if available)")
            fin()
        end
        do
            local _, add, fin = MakeCard("Edit/notes")
            add("bullet", "Edit any tactic or write your own from scratch")
            add("bullet", "Custom notes for each boss and general dungeon reminders")
            fin()
        end
        do
            local _, add, fin = MakeCard("Quality of Life")
            add("bullet", "Minimap button with left-click open/close")
            add("bullet", "Titan Panel integration for quick access")
            add("bullet", "Auto-invite via configurable keyword trigger")
            add("bullet", "Full multi-language support")
            fin()
        end

    elseif category == "Changelog" then
        do
            local ver = BossHelper.VERSION_STRING or "unknown"
            local _, add, fin = MakeCard("v" .. ver .. "  —  May 6, 2026", {collapsible=true, startExpanded=true})
            add("header", "New")
            add("bullet", "Dungeon Check Window:")
            add("subbullet", "Appears automatically when entering a dungeon and auto-closes when dungeon starts.")
            add("subbullet", "Shows the player's specialization, roll and talent loadout.")
            add("subbullet", "Displays overall gear durability percentage.")
            add("subbullet", "Shows flask / food consumable status and bag counts.")
            add("subbullet", "Includes leader-only Ready Check & Countdown buttons.")
            add("spacer", 6)
            add("bullet", "Mini Window:")
            add("subbullet", "added setting to enable/disable the Mini Window. When disabled the mini window is fully inactive (no timers, no event handlers, and no frame work) to avoid unnecessary performance cost.")
            add("subbullet", "added a button to open the Mini Window from Settings.")
            add("subbullet", "`/mmw` and the Settings button now fall back to the last-known dungeon or the first dungeon in `BossData.DungeonOrder` when no current dungeon is available.")
            add("spacer", 6)
            add("bullet", "Key Tracker:")
            add("subbullet", "added setting to enable/disable the Key Tracker. When disabled no keystone data is collected and all key-tracker UI (Start Page widget and Group Finder panel) is hidden.")
            add("subbullet", "Keystone tracker implementation (LibKeystone callbacks and roster timers), `GroupFinderPanel` and `StartPage` now short-circuit and do no work when the Key Tracker is disabled.")
            add("subbullet", "Added a small leader crown icon on the key image/card for the party leader uses (`Interface\\GroupFrame\\UI-Group-LeaderIcon`).")
            add("spacer", 6)
            add("bullet", "Settings:")
            add("subbullet", "Added custom checkbox and slider controls that match the addon's UI style.")
            add("subbullet", "Added inline-edit for slider values (click the numeric readout to type a value).")
            add("subbullet", "Added setting to hide the minimap button.")
            add("subbullet", "Added (Hide start page guide) setting, hides the hint text on the start page and centers the logo in the panel.")
            add("subbullet", "Added a settings info panel with images and descriptive text (replaces tooltips).")
            add("subbullet", "Added a new hover effect for settings: subtle top and bottom stripes appear on hover.")
            add("subbullet", "Added visual (gray-out) behavior for dependent settings when a feature is disabled: affected setting cards are dimmed and input is blocked until re-enabled.")
            add("spacer", 6)
            add("bullet", "Teleports:")
            add("subbullet", "Added clickable Mythic+ dungeon images to teleport to that dungeon.")
            add("subbullet", "Added clickable images on Key Tracker (Key Cards and Key List) to teleport directly to the dungeon.")
            add("spacer", 6)
            add("bullet", "Auto-Invite:")
            add("subbullet", "Added a multi-trigger Auto-Invite system with two separate trigger-word lists: (Guild & Friends) and (Others).")
            add("subbullet", "SavedVariables migration: existing single `triggerWord` is migrated automatically into the new `triggerWordsFriendly` list on first load.")
            add("subbullet", "Slash commands: `/mminv addfriendly|addother|removefriendly|removeother|list|debug` to manage triggers and debug mode.")
            add("subbullet", "Invite logic: detects guild members, Battle.net friends and friend-list friends; caches guild GUIDs and API references; uses safe invite call and group-permission checks.")
            add("spacer", 6)
            add("spacer", 8)
            add("header", "Changed")
            add("bullet", "Key Tracker:")
            add("subbullet", "Refactored the Keystone widget to iterate unit slots (`player`, `party1`, ...) instead of matching names, more robust against realm/shortname variations.")
            add("subbullet", "The Keystone widget now hides in raids and only displays for party members.")
            add("spacer", 6)
            add("bullet", "Settings:")
            add("subbullet", "Overhauled settings UI into card-style panels.")
            add("subbullet", "Card-based layout matching Edit Tactics visual style.")
            add("subbullet", "Two-column support so related settings can sit left/right.")
            add("subbullet", "Updated several setting labels to the gold color to match other UI labels; adjusted language dropdown width to match sliders.")
            add("spacer", 6)
            add("bullet", "Info page:")
            add("subbullet", "Overhauled the Info page with a card-based layout matching the rest of the UI.")
            add("subbullet", "Added a reusable `MakeCard` builder exposing `add` / `fin` helpers for text, header, bullet, subbullet, keyval, and spacer row types.")
            add("subbullet", "Expanded from 4 categories to 6: About, Features, Changelog, Help, Commands, and Credits.")
            add("spacer", 6)
            add("bullet", "UI:")
            add("subbullet", "Adjusted scroll frames to scroll by 20 px per step for smoother navigation.")
            add("spacer", 6)
            add("bullet", "Locales:")
            add("subbullet", "Updated Russian and French boss tactics.")
            add("spacer", 8)
            add("header", "Fixed")
            add("bullet", "Removed debug print on boss death (ENCOUNTER_END) that showed encounter/journal ID matching.")
            add("spacer", 6)
            add("bullet", "Key Tracker:")
            add("subbullet", "Fixed an issue where a player could appear both with a keystone and as having no key.")
            add("subbullet", "Fixed an issue where the Key Card widget could appear on non-start pages (e.g. Settings or Info). The widget now respects being hidden and will not be shown by background refreshes.")
            add("spacer", 6)
            add("bullet", "Settings:")
            add("subbullet", "Fixed slider tooltip formatting which previously showed very long floating-point values.")
            fin()
        end


        do
            local ver = BossHelper.VERSION_STRING or "unknown"
            local _, add, fin = MakeCard("v2.1.0  —  April 23, 2026", {collapsible=true})
            add("header", "New")
            add("bullet", "Small boss tactics window.")
            add("bullet", "M+ Key Tracking now shows all party keys.")
            add("bullet", "Added more small animations.")
            add("spacer", 8)
            add("header", "Changed")
            add("bullet", "New icons (Close, Settings, Info, Notes, and Edit).")
            add("bullet", "Removed old images (now 1 MB, previously 3 MB).")
            add("bullet", "Removed small gaps between borders and backgrounds (buttons and panels).")
            add("bullet", "Overhauled the Affix tap now custom taktik to evry affix and beder guidning.")
            add("bullet", "Overhauled the Settings tab.")
            add("bullet", "Move the Vision nr over i højre side.")
            add("bullet", "Refactored codebase for better organization, modularity, and performance.")
            add("spacer", 8)
            add("header", "Fixed")
            add("bullet", "Fixed Reset button in Edit Mode; now resets to original tactics.")
            add("bullet", "Fixed hover effect on buttons where the background visually grew beyond button borders.")
            add("bullet", "Fixed Boss Notes button sometimes remaining active when switching to another tab.")
            fin()
        end


        do
            local ver = BossHelper.VERSION_STRING or "unknown"
            local _, add, fin = MakeCard("v2.0.0  —  April 13, 2026", {collapsible=true})
            add("header", "New")
            add("bullet", "Edit Tactics: You can now edit all boss tactics or create your own")
            add("bullet", "Custom confirmation popups")
            add("bullet", "All tactics have been translated into Danish, German, French, and Russian")
            add("spacer", 8)
            add("header", "Changed")
            add("bullet", "In active instances (e.g. Mythic+), a copy window is now shown since Blizzard’s chat lockdown system prevents addons from writing directly to chat during encounters.")
            add("bullet", "Updated left panel background to match the right panel design")
            add("bullet", "Changed button border color to dark grey instead of black")
            add("bullet", "Hover animation now only appears on hover (removed from de-hover state)")
            add("spacer", 8)
            add("header", "Fixed")
            add("bullet", "Core: Added UI toggle, moved update-banner refresh into PLAYER_LOGIN, and made sound playback safe.")
            add("bullet", "Messaging: Fixed PlayButtonSound nil guard and stabilized the message queue.")
            add("bullet", "Auto-invite: Fixed slash command and removed unused global trigger; use Inviter.SetTrigger().")
            add("bullet", "Settings: Fixed language dropdown initial label bug, removed duplicate rightPanel declaration, and used Translate(SETTINGS).")
            add("bullet", "UI: Replaced hardcoded texts with localization keys; added UNKNOWN_BOSS and COPY_HINT_TEXT.")
            add("bullet", "Fixed missing image for Xenas Kasreth (Nexus-Point)")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.3.3  —  April 10, 2026", {collapsible=true})
            add("header", "Update")
            add("bullet", "Updated TOC")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.3.2  —  April 7, 2026", {collapsible=true})
            add("header", "New")
            add("bullet", "Auto-selects the current dungeon.")
            add("spacer", 8)
            add("header", "Update")
            add("bullet", "Improved boss tactics.")
            add("spacer", 8)
            add("header", "Fixed")
            add("bullet", "Fixed an issue where the button would sometimes turn black after hover; it now stays a consistent dark bluish color.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.3.1  —  April 6, 2026", {collapsible=true})
            add("header", "Fixed")
            add("bullet", "Windrunner Spire dungeon not showing.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.3.0  —  April 5, 2026", {collapsible=true})
            add("header", "New")
            add("bullet", "Added custom notes for bosses and general encounters")
            add("bullet", "Added affix information")
            add("bullet", "Introduced new settings options")
            add("spacer", 8)
            add("header", "Update")
            add("bullet", "Added new boss tactics for Midnight")
            add("bullet", "Various minor improvements and optimizations for better performance and stability.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.2.1  —  Sep 15, 2025", {collapsible=true})
            add("header", "New")
            add("bullet", "Added Russian and German language support.")
            add("spacer", 8)
            add("header", "Update")
            add("bullet", "Refined Boss tactics.")
            add("bullet", "Various minor improvements and optimizations for better performance and stability.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.2.0  —  Sep 14, 2025", {collapsible=true})
            add("header", "New")
            add("bullet", "Added language selection: English (default) and Danish, more languages coming soon.")
            add("spacer", 8)
            add("header", "Update")
            add("bullet", "General improvements and optimizations for smoother performance")
            add("bullet", "Updated TOC file for proper addon loading.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.1.0  —  Sep 6, 2025", {collapsible=true})
            add("header", "Update")
            add("bullet", "Updated UI.")
            add("bullet", "Added setting to toggle closing the addon with ESC.")
            add("bullet", "Moved the Phase Button to the left.")
            add("bullet", "Small improvements.")
            fin()
        end


        do
            local _, add, fin = MakeCard("v1.0.0  —  Sep 5, 2025", {collapsible=true})
            add("header", "Note")
            add("bullet", "The very first public release of Mythic Mentor!")
            add("bullet", "Mythic Mentor is now officially live and ready to help you and your group tackle Mythic+ dungeons!")
            add("spacer", 8)
            add("header", "Includes full core features:")
            add("bullet", "Boss tactics for every encounter.")
            add("bullet", "Party chat strategy sharing.")
            add("bullet", "Auto‑Invite system with custom keyword support (e.g., invite!).")
            add("bullet", "Titan Panel integration for quick access.")
            fin()
        end

    elseif category == "Help" then
        do
            local _, add, fin = MakeCard("Getting Started")
            add("text", "1.  Select a dungeon from the left panel.")
            add("text", "2.  Select a boss to view its tactics.")
            add("text", "3.  Use  'Post to Chat' (or copy in instances) to share tactics with your group.")
            fin()
        end
        do
            local _, add, fin = MakeCard("Support")
            add("bullet", "Join our Discord server for help, questions, and feedback")
            add("bullet", "Report bugs via the  bug  icon on the Start Page or on GitHub")
            fin()
        end

    elseif category == "Commands" then
        do
            local _, add, fin = MakeCard("Slash Commands")
            add("keyval", "/MM",           "Open / close the addon window")
            add("keyval", "/MythicMentor", "Open / close the addon window")
            add("keyval", "/mmw",          "Open the Mini Window")
            add("keyval", "/mmc",          "Open the Dungeon Check Window")
            fin()
        end
        do
            local _, add, fin = MakeCard("Minimap Button")
            add("bullet", "Left-click  —  open / close the addon window")
            add("bullet", "Can be hidden from   Settings - General")
            fin()
        end
        do
            local _, add, fin = MakeCard("Auto-Invite")
            add("text", "The Auto-Invite module listens for a configurable keyword in whispers.")
            add("bullet", "Set the keyword from the Settings panel under  Inviter")
            add("bullet", "Any player who whispers that keyword will receive a group invite")
            fin()
        end

    elseif category == "Credits" then
        do
            local _, add, fin = MakeCard("Burning Toast Studio")
            add("keyval", "testtoast", "Developer")
            add("keyval", "QuteBytes", "Developer")
            fin()
        end
        do
            local _, add, fin = MakeCard("Acknowledgements")
            add("keyval", "World of Duckcraft", "boss tactics inspiration")
            add("keyval", "Funkeh",             "LibDBIcon-1.0")
            add("keyval", "Funkeh",             "LibKeystone")
            fin()
        end
        do
            local _, add, fin = MakeCard("License")
            add("text", "Released under the MIT License. See  MIT_LICENSE.txt  in the addon folder for the full text.")
            fin()
        end

    else
        -- Fallback for future categories not yet implemented
        do
            local _, add, fin = MakeCard(category)
            add("text", "No content defined for this category yet.", 0.6, 0.6, 0.6)
            fin()
        end
    end

    -- Final content height guard
    content:SetHeight(math.max(math.abs(cardY) + 20, 100))
end

-- ============================================================
-- SelectInfoCategory
--   Highlights the chosen left-panel button and rebuilds right-panel content.
-- ============================================================
function BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, categoryName, btn, ctx)
    ctx = ctx or {}

    -- Deselect previous button
    if frame.infoSelectedButton then
        pcall(frame.infoSelectedButton.SetSelected, frame.infoSelectedButton, false)
        frame.infoSelectedButton = nil
    end
    if btn then
        pcall(btn.SetSelected, btn, true)
        frame.infoSelectedButton = btn
    end

    -- Clear right-panel chrome
    if rightPanel.logo        then phide(rightPanel.logo) end
    if rightPanel.mainTitle   then psettext(rightPanel.mainTitle,   "") end
    if rightPanel.mainDesc    then psettext(rightPanel.mainDesc,    "") end
    if rightPanel.footerText  then psettext(rightPanel.footerText,  "") end
    if rightPanel.footerText2 then psettext(rightPanel.footerText2, "") end

    -- Ensure the section title label exists
    if not rightPanel.rightTitle then
        rightPanel.rightTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        rightPanel.rightTitle:SetPoint("TOP", rightPanel, "TOP", 0, -20)
        rightPanel.rightTitle:SetTextColor(1, 0.5, 0)
        rightPanel.rightTitle:SetJustifyH("CENTER")
    end
    psettext(rightPanel.rightTitle, categoryName)

    -- Rebuild content
    CleanupInfoWidgets(rightPanel)
    BossInfo.BuildInfoCategoryUI(rightPanel, categoryName, {
        CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton,
        BossHelperDB       = ctx.BossHelperDB       or deps.BossHelperDB,
    })
end

-- ============================================================
-- ShowInfo (entry point called by BossUI)
-- ============================================================
function BossInfo.ShowInfo(ctx)
    ctx = ctx or {}

    if ctx.CreateCustomButton then deps.CreateCustomButton = ctx.CreateCustomButton end
    if ctx.BossHelper         then deps.BossHelper         = ctx.BossHelper         end
    if ctx.BossHelperDB       then deps.BossHelperDB       = ctx.BossHelperDB       end

    local frame      = ctx.frame
    local leftPanel  = ctx.leftPanel
    local rightPanel = ctx.rightPanel
    local backButton = ctx.backButton
    local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

    -- Hide social buttons while in info view
    BossHelper.UI.hide(rightPanel and rightPanel.discordButton)
    BossHelper.UI.hide(rightPanel and rightPanel.githubButton)
    BossHelper.UI.hide(rightPanel and rightPanel.bugReportButton)

    if not (frame and leftPanel and rightPanel and CreateCustomButton) then
        print("|cffFF4500[BossInfo]|r Missing context for ShowInfo()")
        return
    end

    frame.currentMode    = "info"
    frame.selectedBoss   = nil
    frame.currentDungeon = nil

    -- Hide irrelevant right-panel widgets
    if rightPanel.phaseDropdown        then phide(rightPanel.phaseDropdown)        end
    if rightPanel.dropdownClickCatcher then phide(rightPanel.dropdownClickCatcher) end
    if rightPanel.shortBtnScroll       then phide(rightPanel.shortBtnScroll)       end
    if rightPanel.shortButtons then
        for _, b in ipairs(rightPanel.shortButtons) do
            if b and b.Hide then b:Hide(); b:SetParent(nil) end
        end
    end
    rightPanel.shortButtons = {}

    psettext(rightPanel.rightTitle, (Translate and Translate("INFO")) or "Information")
    if rightPanel.rightShortText  then psettext(rightPanel.rightShortText,  "") end
    if rightPanel.rightDetailText then psettext(rightPanel.rightDetailText, "") end

    if leftPanel and leftPanel.leftTitle then
        leftPanel.leftTitle:SetText((Translate and Translate("INFO")) or "Information")
    end

    -- Clear old left-panel buttons
    if frame.bossButtons then
        for _, btn in ipairs(frame.bossButtons) do
            phide(btn)
            psetparent(btn, nil)
        end
    end
    frame.bossButtons = {}

    -- Build left-panel category buttons from CATEGORY_LIST
    local y = -39  -- aligns with ShowDungeons / ShowBosses
    for _, cat in ipairs(CATEGORY_LIST) do
        local btn = CreateCustomButton(leftPanel, 180, 30, cat)
        btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
        btn:SetScript("OnClick", function()
            BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, cat, btn, {
                CreateCustomButton = CreateCustomButton,
                BossHelperDB       = deps.BossHelperDB,
            })
            psafesound(856)
        end)
        table.insert(frame.bossButtons, btn)
        y = y - 35
    end

    if backButton then backButton:Show() end

    -- Select first category automatically
    if #frame.bossButtons > 0 then
        BossInfo.SelectInfoCategory(frame, leftPanel, rightPanel, CATEGORY_LIST[1], frame.bossButtons[1], {
            CreateCustomButton = CreateCustomButton,
            BossHelperDB       = deps.BossHelperDB,
        })
    end
end

return BossInfo