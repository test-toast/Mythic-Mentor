-- Core/EditModeLogic.lua

BossHelper.EditModeLogic = {}
local L = BossHelper.EditModeLogic

local table_insert = table.insert
local table_concat = table.concat
local string_gsub = string.gsub
local string_gmatch = string.gmatch

local PHASE_NONE = "No phase"

function L.Trim(s)
    return string_gsub(string_gsub(s or "", "^%s+",""), "%s+$","")
end

function L.LoadEntriesFromString(rawStr, phaseName)
    local entries = {}
    for line in string_gmatch(rawStr or "", "([^\n]+)") do
        line = L.Trim(line)
        if line ~= "" then table_insert(entries, {phase=phaseName, text=line}) end
    end
    return entries
end

function L.GetCustomEntries(dungeon, bossName)
    local db = BossHelperDB
    if not db then return {} end
    db.customTactics = db.customTactics or {}
    db.customTactics[dungeon] = db.customTactics[dungeon] or {}
    
    local raw = db.customTactics[dungeon][bossName]
    if raw == nil then return {} end
    if type(raw) == "string" then
        local entries = L.LoadEntriesFromString(raw, PHASE_NONE)
        db.customTactics[dungeon][bossName] = entries
        return entries
    end
    return raw
end

function L.SaveCustomEntries(dungeon, bossName, entries)
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.customTactics = BossHelperDB.customTactics or {}
    BossHelperDB.customTactics[dungeon] = BossHelperDB.customTactics[dungeon] or {}
    if not entries or #entries == 0 then
        BossHelperDB.customTactics[dungeon][bossName] = nil
    else
        BossHelperDB.customTactics[dungeon][bossName] = entries
    end
end

-- =====================================================================
-- Public API for UI
-- =====================================================================

function L.GetCustomTacticsText(dungeon, bossName, phaseName)
    local raw = L.GetCustomEntries(dungeon, bossName)
    if #raw == 0 then return nil end

    local lines = {}
    phaseName = phaseName or PHASE_NONE
    for _, entry in ipairs(raw) do
        local ep = entry.phase or PHASE_NONE
        if ep == "" then ep = PHASE_NONE end
        if ep == phaseName then
            local t = L.Trim(entry.text)
            if t ~= "" then table_insert(lines, t) end
        end
    end
    return #lines > 0 and table_concat(lines, "\n") or nil
end

function L.HasCustomTactics(dungeon, bossName)
    local raw = L.GetCustomEntries(dungeon, bossName)
    return #raw > 0
end

function L.GetCustomPhases(dungeon, bossName)
    local raw = L.GetCustomEntries(dungeon, bossName)
    if #raw == 0 then return {} end
    
    local seen, phases = {}, {}
    for _, entry in ipairs(raw) do
        local p = entry.phase or PHASE_NONE
        if p == "" then p = PHASE_NONE end
        if not seen[p] then seen[p] = true; table_insert(phases, p) end
    end
    return phases
end
