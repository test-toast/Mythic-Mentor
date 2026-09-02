-- KeystoneTracker.lua
-- Tracks party members' keystones using LibKeystone.
-- Data is stored in BossHelper.Keystones and auto-requested when joining a group.
-- Redesigned for better efficiency, avoiding duplicated timers and custom addon sync messages.

local LibKeystone = LibStub and LibStub("LibKeystone", true)
if not LibKeystone then return end

-- Localised globals
local IsInGroup          = IsInGroup
local IsInRaid           = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local UnitName           = UnitName
local UnitGUID           = UnitGUID
local InCombatLockdown   = InCombatLockdown
local wipe, pairs        = wipe, pairs

BossHelper.Keystones = {}

-- Cache: playerName -> shortName
local shortNameCache = {}
local function GetShortName(name)
    local s = shortNameCache[name]
    if not s then
        s = name:match("^([^%-]+)") or name
        shortNameCache[name] = s
    end
    return s
end
-- Export so other modules (e.g. StartPage) can use it
BossHelper.GetKeystoneShortName = GetShortName

-- LibKeystone callback: only store keys from current group members
LibKeystone.Register(BossHelper, function(keyLevel, keyMapID, _playerRating, playerName, channel)
    if BossHelperDB and BossHelperDB.keyTrackerEnabled == false then return end
    if channel == "GUILD" or channel == "RAID" or not playerName then return end

    BossHelper.Keystones[playerName] = {
        keyLevel = keyLevel,
        keyMapID = keyMapID,
    }
    
    if BossHelper.RefreshAllKeystoneWidgets then
        BossHelper.RefreshAllKeystoneWidgets()
    end
end)

local currentNames = {}
local updateTimer = nil

local function RefreshWidgetsSafe()
    if InCombatLockdown() then return end
    if BossHelper.RefreshAllKeystoneWidgets then
        BossHelper.RefreshAllKeystoneWidgets()
    end
end

local function PruneAndRequest()
    if BossHelperDB and BossHelperDB.keyTrackerEnabled == false then return end
    updateTimer = nil
    
    if InCombatLockdown() then return end

    wipe(currentNames)
    
    -- M+ foregår kun i party-størrelse, så vi ignorerer raids for keys
    if not IsInRaid() and IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party"..i)
            if name then currentNames[name] = true end
        end
    end
    
    local myName = UnitName("player")
    if myName then currentNames[myName] = true end

    -- Remove keystones for players no longer in the group
    for name in pairs(BossHelper.Keystones) do
        if not currentNames[name] and not currentNames[GetShortName(name)] then
            BossHelper.Keystones[name] = nil
            shortNameCache[name] = nil
        end
    end

    -- LibKeystone.Request accepterer kun PARTY eller GUILD, så en instansgruppe
    -- (delve, dungeon finder, LFR) kan slet ikke nås -- og et PARTY-kald der
    -- giver "You aren't in a party.". Derfor tjekkes HOME-kategorien eksplicit.
    local HOME = LE_PARTY_CATEGORY_HOME or 1
    if IsInGroup(HOME) and not IsInRaid(HOME) then
        LibKeystone.Request("PARTY")
    end

    -- Clear class colour cache so new members get the correct colour
    if BossHelper.ClearKeystoneColorCache then
        BossHelper.ClearKeystoneColorCache()
    end

    RefreshWidgetsSafe()
end

local function ClearKeystones()
    wipe(BossHelper.Keystones)
    wipe(shortNameCache)
    RefreshWidgetsSafe()
end

-- Replaces all the separate named timers from before with a unified debounced update
local function RequestUpdate(delay)
    if updateTimer then
        updateTimer:Cancel()
    end
    updateTimer = C_Timer.NewTimer(delay or 2, PruneAndRequest)
end

local gossipNPCID
local KEYSTONE_VENDOR_NPC_ID = 197711
local KEYSTONE_REROLL_NPC_ID = 197915

local function GetNPCIDFromGUID(guid)
    if not guid or (issecretvalue and issecretvalue(guid)) then return nil end
    local unitType, _, _, _, _, id = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        return tonumber(id)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("GOSSIP_CLOSED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")

frame:SetScript("OnEvent", function(self, event, ...)
    if BossHelperDB and BossHelperDB.keyTrackerEnabled == false then return end

    if event == "PLAYER_REGEN_ENABLED" then
        RefreshWidgetsSafe()
        
    elseif event == "GROUP_LEFT" then
        ClearKeystones()
        
    elseif event == "GROUP_JOINED" then
        RequestUpdate(1)
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        RequestUpdate(3)
        
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "WEEKLY_REWARDS_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        RequestUpdate(3)
        
    elseif event == "BAG_UPDATE_DELAYED" then
        -- Reliably tracks native bag updates to keystone (creation, level changes, rerolls)
        RequestUpdate(2)
        
    elseif event == "GOSSIP_SHOW" then
        gossipNPCID = GetNPCIDFromGUID(UnitGUID("target"))
        
    elseif event == "GOSSIP_CLOSED" then
        if gossipNPCID == KEYSTONE_VENDOR_NPC_ID or gossipNPCID == KEYSTONE_REROLL_NPC_ID then
            RequestUpdate(2)
        end
        gossipNPCID = nil
    end
end)
