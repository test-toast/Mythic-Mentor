-- EncounterIDLookup.lua
-- Konverter journalEncounterID (bruges til navn/billede via EJ API)
-- til dungeonEncounterID (bruges af ENCOUNTER_END / ENCOUNTER_START events).
--
-- Blizzard API reference:
--   EJ_GetEncounterInfo(journalEncounterID)
--   → returværdi #7: dungeonEncounterID  (samme ID som ENCOUNTER_END sender)
--
-- Mapping:
--   dungeon-fil:  encounterID = journalEncounterID  → navn, billede
--   denne fil:    journalEncounterID → dungeonEncounterID → boss-kill matching

local _cache = {}

-- Slår dungeonEncounterID op for et journalEncounterID.
-- Resultater caches per session, da de aldrig ændrer sig.
function BossHelper:GetDungeonEncounterID(journalEncounterID)
    if not journalEncounterID or journalEncounterID <= 0 then return nil end

    local cached = _cache[journalEncounterID]
    if cached ~= nil then
        -- false bruges som sentinel: lookup forsøgt, men EJ returnerede intet
        return cached ~= false and cached or nil
    end

    local _, _, _, _, _, _, dungeonEncounterID = EJ_GetEncounterInfo(journalEncounterID)
    _cache[journalEncounterID] = dungeonEncounterID or false
    return dungeonEncounterID
end
