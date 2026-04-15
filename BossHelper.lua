-- BossData.lua
BossData = {}
BossData.DungeonOrder = {
    "Maisara Caverns",
    "Magister's Terrace",
    "Nexus-Point Xenas",
    "Windrunner Spire",
    "Skyreach",
    "Pit of Saron",
    "Seat of the Triumvirate",
    "Algeth'ar Academy",
}


-- Funktion til at load lokaliserede dungeons
function BossData:Load(locale)
    locale = locale or BossHelper.selectedLocale or "enUS"

    if locale == "enUS" then
        BossData["Maisara Caverns"]          = Dungeon1
        BossData["Magister's Terrace"]       = Dungeon2
        BossData["Nexus-Point Xenas"]        = Dungeon3
        BossData["Windrunner Spire"]         = Dungeon4
        BossData["Skyreach"]                 = Dungeon5
        BossData["Pit of Saron"]             = Dungeon6
        BossData["Seat of the Triumvirate"]  = Dungeon7
        BossData["Algeth'ar Academy"]        = Dungeon8
    elseif locale == "daDK" then
        BossData["Maisara Caverns"]          = Dungeon1_daDK
        BossData["Magister's Terrace"]       = Dungeon2_daDK
        BossData["Nexus-Point Xenas"]        = Dungeon3_daDK
        BossData["Windrunner Spire"]         = Dungeon4_daDK
        BossData["Skyreach"]                 = Dungeon5_daDK
        BossData["Pit of Saron"]             = Dungeon6_daDK
        BossData["Seat of the Triumvirate"]  = Dungeon7_daDK
        BossData["Algeth'ar Academy"]        = Dungeon8_daDK
    elseif locale == "ruRU" then
        BossData["Maisara Caverns"]          = Dungeon1_ruRU
        BossData["Magister's Terrace"]       = Dungeon2_ruRU
        BossData["Nexus-Point Xenas"]        = Dungeon3_ruRU
        BossData["Windrunner Spire"]         = Dungeon4_ruRU
        BossData["Skyreach"]                 = Dungeon5_ruRU
        BossData["Pit of Saron"]             = Dungeon6_ruRU
        BossData["Seat of the Triumvirate"]  = Dungeon7_ruRU
        BossData["Algeth'ar Academy"]        = Dungeon8_ruRU
    elseif locale == "deDE" then
        BossData["Maisara Caverns"]          = Dungeon1_deDE
        BossData["Magister's Terrace"]       = Dungeon2_deDE
        BossData["Nexus-Point Xenas"]        = Dungeon3_deDE
        BossData["Windrunner Spire"]         = Dungeon4_deDE
        BossData["Skyreach"]                 = Dungeon5_deDE
        BossData["Pit of Saron"]             = Dungeon6_deDE
        BossData["Seat of the Triumvirate"]  = Dungeon7_deDE
        BossData["Algeth'ar Academy"]        = Dungeon8_deDE
    elseif locale == "frFR" then
        BossData["Maisara Caverns"]          = Dungeon1_frFR
        BossData["Magister's Terrace"]       = Dungeon2_frFR
        BossData["Nexus-Point Xenas"]        = Dungeon3_frFR
        BossData["Windrunner Spire"]         = Dungeon4_frFR
        BossData["Skyreach"]                 = Dungeon5_frFR
        BossData["Pit of Saron"]             = Dungeon6_frFR
        BossData["Seat of the Triumvirate"]  = Dungeon7_frFR
        BossData["Algeth'ar Academy"]        = Dungeon8_frFR
    else
        BossData["Maisara Caverns"]          = Dungeon1
        BossData["Magister's Terrace"]       = Dungeon2
        BossData["Nexus-Point Xenas"]        = Dungeon3
        BossData["Windrunner Spire"]         = Dungeon4
        BossData["Skyreach"]                 = Dungeon5
        BossData["Pit of Saron"]             = Dungeon6
        BossData["Seat of the Triumvirate"]  = Dungeon7
        BossData["Algeth'ar Academy"]        = Dungeon8
    end
end

-- Initial load efter locale er sat
BossData:Load(BossHelper.selectedLocale)

-- Optional: funktion til dynamisk reload, fx efter sprogskift
function BossData:Reload()
    self:Load(BossHelper.selectedLocale)
end

--
--local locale = BossHelper.selectedLocale
--
----Hvis der skal fleres lokale-specifikke oversættelser, tilføj dem her.
--if locale == "daDK" then
--    BossData["Eco-Dome Al'dani"]            = Dungeon1_daDK
--    BossData["Tazavesh: Streets of Wonder"] = Dungeon2_daDK
--    BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3_daDK
--    BossData["Halls of Atonement"]          = Dungeon4_daDK
--    BossData["Ara-Kara, City of Echoes"]    = Dungeon5_daDK
--    BossData["The Dawnbreaker"]             = Dungeon6_daDK
--    BossData["Operation: Floodgate"]        = Dungeon7_daDK
--    BossData["Priory of the Sacred Flame"]  = Dungeon8_daDK
--else
--    -- Tilføj dungeons fra globale variabler
--    BossData["Eco-Dome Al'dani"]            = Dungeon1
--    BossData["Tazavesh: Streets of Wonder"] = Dungeon2
--    BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3
--    BossData["Halls of Atonement"]          = Dungeon4
--    BossData["Ara-Kara, City of Echoes"]    = Dungeon5
--    BossData["The Dawnbreaker"]             = Dungeon6
--    BossData["Operation: Floodgate"]        = Dungeon7
--    BossData["Priory of the Sacred Flame"]  = Dungeon8
--end