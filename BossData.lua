-- BossData.lua
BossData = {}
BossData.DungeonOrder = {
    "Eco-Dome Al'dani",
    "Tazavesh: Streets of Wonder",
    "Tazavesh: So'leah's Gambit",
    "Halls of Atonement",
    "Ara-Kara, City of Echoes",
    "The Dawnbreaker",
    "Operation: Floodgate",
    "Priory of the Sacred Flame",
}


-- Funktion til at load lokaliserede dungeons
function BossData:Load(locale)
    locale = locale or BossHelper.selectedLocale or "enUS"

    if locale == "enUS" then
        BossData["Eco-Dome Al'dani"]            = Dungeon1
        BossData["Tazavesh: Streets of Wonder"] = Dungeon2
        BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3
        BossData["Halls of Atonement"]          = Dungeon4
        BossData["Ara-Kara, City of Echoes"]    = Dungeon5
        BossData["The Dawnbreaker"]             = Dungeon6
        BossData["Operation: Floodgate"]        = Dungeon7
        BossData["Priory of the Sacred Flame"]  = Dungeon8
    elseif locale == "daDK" then
        BossData["Eco-Dome Al'dani"]            = Dungeon1_daDK
        BossData["Tazavesh: Streets of Wonder"] = Dungeon2_daDK
        BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3_daDK
        BossData["Halls of Atonement"]          = Dungeon4_daDK
        BossData["Ara-Kara, City of Echoes"]    = Dungeon5_daDK
        BossData["The Dawnbreaker"]             = Dungeon6_daDK
        BossData["Operation: Floodgate"]        = Dungeon7_daDK
        BossData["Priory of the Sacred Flame"]  = Dungeon8_daDK
    elseif locale == "ruRU" then
        BossData["Eco-Dome Al'dani"]            = Dungeon1_ruRU
        BossData["Tazavesh: Streets of Wonder"] = Dungeon2_ruRU
        BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3_ruRU
        BossData["Halls of Atonement"]          = Dungeon4_ruRU
        BossData["Ara-Kara, City of Echoes"]    = Dungeon5_ruRU
        BossData["The Dawnbreaker"]             = Dungeon6_ruRU
        BossData["Operation: Floodgate"]        = Dungeon7_ruRU
        BossData["Priory of the Sacred Flame"]  = Dungeon8_ruRU
    elseif locale == "deDE" then
        BossData["Eco-Dome Al'dani"]            = Dungeon1_deDE
        BossData["Tazavesh: Streets of Wonder"] = Dungeon2_deDE
        BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3_deDE
        BossData["Halls of Atonement"]          = Dungeon4_deDE
        BossData["Ara-Kara, City of Echoes"]    = Dungeon5_deDE
        BossData["The Dawnbreaker"]             = Dungeon6_deDE
        BossData["Operation: Floodgate"]        = Dungeon7_deDE
        BossData["Priory of the Sacred Flame"]  = Dungeon8_deDE
    else
        BossData["Eco-Dome Al'dani"]            = Dungeon1
        BossData["Tazavesh: Streets of Wonder"] = Dungeon2
        BossData["Tazavesh: So'leah's Gambit"]  = Dungeon3
        BossData["Halls of Atonement"]          = Dungeon4
        BossData["Ara-Kara, City of Echoes"]    = Dungeon5
        BossData["The Dawnbreaker"]             = Dungeon6
        BossData["Operation: Floodgate"]        = Dungeon7
        BossData["Priory of the Sacred Flame"]  = Dungeon8
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