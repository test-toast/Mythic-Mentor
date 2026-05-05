-- KeystoneTracker.lua
-- Tracks party members' keystones using LibKeystone.
-- Data is stored in BossHelper.Keystones and auto-requested when joining a group.

local LibKeystone = LibStub and LibStub("LibKeystone", true)
if not LibKeystone then return end

-- Localised globals
local IsInGroup          = IsInGroup
local IsInRaid           = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local UnitName           = UnitName
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

-- LibKeystone callback: only store keys from current group members (not guild-wide)
LibKeystone.Register(BossHelper, function(keyLevel, keyMapID, playerRating, playerName, channel)
    -- Ignore guild broadcasts — only accept PARTY, RAID, INSTANCE_CHAT or direct whispers
    if channel == "GUILD" then return end
    if not playerName then return end

    BossHelper.Keystones[playerName] = {
        keyLevel     = keyLevel,
        keyMapID     = keyMapID,
        playerRating = playerRating,
    }
    if BossHelper.RefreshAllKeystoneWidgets then
        BossHelper.RefreshAllKeystoneWidgets()
    end
end)

-- Reused table to avoid GC allocations on every roster event
local currentNames = {}

local function PruneAndRequest()
    wipe(currentNames)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = UnitName("raid"..i)
            if name then currentNames[name] = true end
        end
    elseif IsInGroup() then
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

    if InCombatLockdown() then return end

    LibKeystone.Request("PARTY")

    -- Clear class colour cache so new members get the correct colour
    if BossHelper.ClearKeystoneColorCache then
        BossHelper.ClearKeystoneColorCache()
    end

    if BossHelper.RefreshAllKeystoneWidgets then
        BossHelper.RefreshAllKeystoneWidgets()
    end
end

local function ClearAndRefresh()
    wipe(BossHelper.Keystones)
    wipe(shortNameCache)
    if BossHelper.RefreshAllKeystoneWidgets then
        BossHelper.RefreshAllKeystoneWidgets()
    end
end

-- Named timer references prevent timers from stacking when events fire rapidly
local GroupRosterTimer
local WeeklyRewardsTimer
local GroupJoinedTimer
local ChallengeModeTimer
local previousGroupSize = GetNumGroupMembers()

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("WEEKLY_REWARDS_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    -- GROUP_LEFT: immediately wipe stale data, no combat guard needed
    if event == "GROUP_LEFT" then
        if GroupRosterTimer then GroupRosterTimer:Cancel() ; GroupRosterTimer = nil end
        previousGroupSize = 0
        ClearAndRefresh()
        return
    end

    -- GROUP_JOINED: short delay so the roster is populated first
    if event == "GROUP_JOINED" then
        if not GroupJoinedTimer then
            GroupJoinedTimer = C_Timer.NewTimer(1, function()
                GroupJoinedTimer = nil
                if not InCombatLockdown() then
                    previousGroupSize = GetNumGroupMembers()
                    PruneAndRequest()
                end
            end)
        end
        return
    end

    -- GROUP_ROSTER_UPDATE fires many times in a row — use a named timer so
    -- only ONE request fires after the roster has settled (5 s, same as MDT).
    if event == "GROUP_ROSTER_UPDATE" then
        if not GroupRosterTimer then
            GroupRosterTimer = C_Timer.NewTimer(5, function()
                GroupRosterTimer = nil
                if InCombatLockdown() then return end
                local currentSize = GetNumGroupMembers()
                if currentSize ~= previousGroupSize then
                    previousGroupSize = currentSize
                    PruneAndRequest()
                end
            end)
        end
        return
    end

    -- CHALLENGE_MODE_COMPLETED: keys are redistributed after a run
    if event == "CHALLENGE_MODE_COMPLETED" then
        if not ChallengeModeTimer then
            ChallengeModeTimer = C_Timer.NewTimer(3, function()
                ChallengeModeTimer = nil
                if not InCombatLockdown() then
                    PruneAndRequest()
                end
            end)
        end
        return
    end

    -- WEEKLY_REWARDS_UPDATE: player may have collected a new key from the Great Vault
    if event == "WEEKLY_REWARDS_UPDATE" then
        if not WeeklyRewardsTimer then
            WeeklyRewardsTimer = C_Timer.NewTimer(3, function()
                WeeklyRewardsTimer = nil
                if InCombatLockdown() then return end
                if IsInGroup() then
                    LibKeystone.Request("PARTY")
                end
                if BossHelper.RefreshAllKeystoneWidgets then
                    BossHelper.RefreshAllKeystoneWidgets()
                end
            end)
        end
        return
    end

    -- PLAYER_ENTERING_WORLD
    C_Timer.After(3, function()
        if InCombatLockdown() then return end
        if IsInGroup() then
            previousGroupSize = GetNumGroupMembers()
            PruneAndRequest()
        end
    end)
end)
