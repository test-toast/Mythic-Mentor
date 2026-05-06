-- MythicTeleport.lua
-- Samlet teleport-logik for BossHelper:
--   1. Delt spell-tabel og hjælpefunktioner (bruges af KeystoneWidget + denne fil)
--   2. Klikbare teleport-knapper oven på dungeon-ikonerne i Mythic+ fanen
--      (ChallengesFrame / Blizzard_ChallengesUI).
--
-- VIGTIGT: Denne fil skal loade FØR KeystoneWidget.lua (se BossHelper.toc).

BossHelper = BossHelper or {}

-- ============================================================
-- Spell IDs: mapID → teleport-spell  (enkelt kilde til sandheden)
-- Opdatér disse når en ny M+ sæson starter.
-- ============================================================
BossHelper.TeleportSpells = {
    [402] = 393273,  -- Algeth'ar Academy
    [558] = 1254572, -- Magisters' Terrace
    [560] = 1254559, -- Maisara Caverns
    [559] = 1254563, -- Nexus-Point Xenas
    [556] = 1254555, -- Pit of Saron
    [239] = 1254551, -- Seat of the Triumvirate
    [161] = 159898,  -- Skyreach
    [557] = 1254400, -- Windrunner Spire
}

-- Slå teleport-spell op for et dungeon mapID (bruges af KeystoneWidget og denne fil)
function BossHelper.GetTeleportSpell(mapID)
    return BossHelper.TeleportSpells[mapID]
end

-- Opdatér CooldownFrame på en teleport-knap (bruges af KeystoneWidget og denne fil)
function BossHelper.UpdateTeleportCooldown(btn)
    if not btn.cooldown then return end
    if not btn.spellID then
        btn.cooldown:Clear()
        return
    end
    local info = C_Spell.GetSpellCooldown(btn.spellID)
    if info and info.duration > 0 then
        btn.cooldown:SetCooldown(info.startTime, info.duration)
    else
        btn.cooldown:Clear()
    end
end

-- Sæt teleport-attributter på en knap med dirty-check (undgår unødvendige SetAttribute-kald).
-- spellID = spell at caste, eller nil.  tpEnabled = boolean fra bruger-indstilling.
-- Returnerer tidligt hvis i kamp (SecureActionButtons kan ikke ændres i combat lockdown).
function BossHelper.ApplyTeleportButton(btn, spellID, tpEnabled)
    if InCombatLockdown() then return end
    local effective = (tpEnabled and spellID) or nil
    if btn._appliedSpellID == effective then return end  -- ingen ændring
    btn._appliedSpellID = effective
    if effective then
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", effective)
    else
        btn:SetAttribute("type", nil)
        btn:SetAttribute("spell", nil)
    end
    btn.spellID = effective
    if btn.highlightTex then
        btn.highlightTex:SetColorTexture(0, 0, 0, effective and 0.5 or 0)
    end
end

-- Intern reference til tabellen for kortere opkald i denne fil
local TELEPORT_SPELLS = BossHelper.TeleportSpells

-- ============================================================
-- Lokal tilstand
-- ============================================================
local iconButtons   = {}   -- [iconFrame] = buttonFrame
local initialized   = false

-- ============================================================
-- Vis/skjul alle knapper baseret på setting
-- ============================================================
BossHelper.MythicTeleport = BossHelper.MythicTeleport or {}
function BossHelper.MythicTeleport.UpdateVisibility()
    local show = not (BossHelperDB and BossHelperDB.teleportOnMythicTab == false)
    for _, btn in pairs(iconButtons) do
        btn:SetShown(show)
    end
end

-- ============================================================
-- Opret en knap oven på et dungeon-ikon
-- ============================================================
local function CreateTeleportButton(parent, spellID)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    btn:SetAllPoints(parent)
    btn:RegisterForClicks("AnyDown", "AnyUp")
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellID)
    btn.spellID = spellID

    -- Mørkening ved hover
    local hover = btn:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(0, 0, 0, 0.45)

    -- Lille dungeon-badge i hjørnet så spilleren ved at knappen er klikbar
    -- teleport icon
    
    -- local badge = btn:CreateTexture(nil, "OVERLAY")
    -- badge:SetAtlas("Dungeon", true)
    -- badge:SetPoint("BOTTOMLEFT", -4, -4)
    -- badge:SetSize(26, 26)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        -- Kald forælderens OnEnter så Blizzards tooltip stadig vises
        local parentEnter = parent:GetScript("OnEnter")
        if parentEnter then parentEnter(parent) end

        GameTooltip:AddLine(" ")

        if InCombatLockdown() then
            local info = C_Spell.GetSpellInfo(self.spellID)
            GameTooltip:AddLine(info and info.name or "Teleport", 1, 1, 1)
            GameTooltip:AddLine("|cFFFF4444" .. Translate("TELEPORT_IN_COMBAT") .. "|r")
            GameTooltip:Show()
            return
        end

        if C_SpellBook.IsSpellInSpellBook(self.spellID, nil, true) then
            local info = C_Spell.GetSpellInfo(self.spellID)
            GameTooltip:AddLine(info and info.name or "Teleport", 1, 1, 1)

            local cd = C_Spell.GetSpellCooldown(self.spellID)
            if cd and type(cd.duration) == "number" and not issecretvalue(cd.duration) then
                if cd.duration == 0 then
                    GameTooltip:AddLine("|cFF00FF00" .. Translate("TELEPORT_READY") .. "|r")
                else
                    local remaining = math.ceil(cd.startTime + cd.duration - GetTime())
                    GameTooltip:AddLine("|cFFFF4444" .. Translate("TELEPORT_COOLDOWN") .. SecondsToTime(remaining) .. "|r")
                end
            end
        else
            local info = C_Spell.GetSpellInfo(self.spellID)
            GameTooltip:AddLine(info and info.name or "Teleport", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cFF888888" .. Translate("TELEPORT_NOT_LEARNED") .. "|r")
        end

        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(parent) then GameTooltip:Hide() end
    end)

    return btn
end

-- ============================================================
-- Gennemgå alle DungeonIcons og tilknyt knapper
-- ============================================================
local function EnsureButtons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end
    local show = not (BossHelperDB and BossHelperDB.teleportOnMythicTab == false)

    for _, icon in pairs(ChallengesFrame.DungeonIcons) do
        local spellID = TELEPORT_SPELLS[icon.mapID]
        if spellID then
            if not iconButtons[icon] then
                iconButtons[icon] = CreateTeleportButton(icon, spellID)
            elseif iconButtons[icon].spellID ~= spellID then
                -- Spell-ID ændret (ny sæson?) – opdatér knappen
                iconButtons[icon]:SetAttribute("spell", spellID)
                iconButtons[icon].spellID = spellID
            end
            iconButtons[icon]:SetShown(show)
        end
    end
end

-- ============================================================
-- Initialisering – venter på Blizzard_ChallengesUI
-- ============================================================
local function Initialize()
    if initialized then return true end
    if not C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then return false end
    if not ChallengesFrame then return false end
    if type(ChallengesFrame.Update) ~= "function" then return false end

    -- Hook ChallengesFrame.Update så knapper oprettes/opdateres når fanen refreshes
    hooksecurefunc(ChallengesFrame, "Update", function()
        if InCombatLockdown() then return end
        EnsureButtons()
    end)

    EnsureButtons()
    initialized = true
    return true
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_ChallengesUI" then
            Initialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Forsøg ved login i tilfælde af at UI allerede er indlæst
        if Initialize() then
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)
