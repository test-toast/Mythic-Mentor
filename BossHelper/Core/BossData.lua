-- BossData.lua
BossData = {}
BossData.DungeonOrder = {
    "Altar of Fangs",
    "Murder Row",
    "Voidscar Arena",
    "The Blinding Vale",
    "Den of Nalorakk",
    "Ruby Life Pools",
    "Kings' Rest",
    "Temple of Sethraliss",
}


-- Funktion til at load lokaliserede dungeons.
-- Dungeon globals follow the naming convention:
--   enUS  → Dungeon1, Dungeon2, ...
--   daDK  → Dungeon1_daDK, Dungeon2_daDK, ...
-- The suffix comes from BossHelper.LOCALES, so adding a new language
-- only requires adding it there + providing the dungeon files.
function BossData:Load(locale)
    locale = locale or BossHelper.selectedLocale or "enUS"

    -- Resolve suffix from the central locale registry
    local suffix = ""
    for _, loc in ipairs(BossHelper.LOCALES) do
        if loc.key == locale then suffix = loc.suffix; break end
    end

    -- Assign each dungeon's localized data table, falling back to enUS
    for i, name in ipairs(BossData.DungeonOrder) do
        BossData[name] = _G["Dungeon" .. i .. suffix] or _G["Dungeon" .. i]
    end
end

-- Initial load efter locale er sat
BossData:Load(BossHelper.selectedLocale)

-- Optional: funktion til dynamisk reload, fx efter sprogskift
function BossData:Reload()
    self:Load(BossHelper.selectedLocale)
end