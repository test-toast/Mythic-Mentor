local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
if not LDB then return end

-- Opret LDB-objekt for Titan Panel
local ldbObject = LDB:NewDataObject("BossHelper", {
    type = "launcher",
    icon = "Interface\\AddOns\\BossHelper\\Media\\Mythic Mentor no te 256x256.tga",
    text = "Mythic Mentor",
    OnClick = function(self, button)
        if button == "LeftButton" then
            BossHelper:Toggle()
        elseif button == "RightButton" then
            TitanPanelRightClickMenu_Toggle(TitanPanelRightClickMenu_PrepareBossHelperMenu, "BossHelper")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Mythic Mentor")
        tooltip:AddLine("Venstreklik: Åbn Mythic Mentor")
        tooltip:AddLine("Højreklik: Åbn menu")
    end,
})

-- Højreklik-menu til Titan knap
function TitanPanelRightClickMenu_PrepareBossHelperMenu()
    local level = UIDROPDOWNMENU_MENU_LEVEL
    local value = UIDROPDOWNMENU_MENU_VALUE

    if level == 1 then
        TitanPanelRightClickMenu_AddTitle("Mythic Mentor")

        -- Først: tilføj alle dungeons
        if BossData then
            for dungeonKey, dungeonData in pairs(BossData) do
                if type(dungeonData) == "table" and dungeonData.bosses then
                    local dungeonName = dungeonData.displayName or dungeonKey
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = dungeonName
                    info.hasArrow = true
                    info.notCheckable = true
                    info.value = { type = "dungeon", key = dungeonKey }
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end

        -- Separator: visuel linje mellem dungeons og Titan standard-knapper
        TitanPanelRightClickMenu_AddSeparator(level)


        -- Nederst: standard Titan-knapper
        TitanPanelRightClickMenu_AddToggleIcon("BossHelper")
        TitanPanelRightClickMenu_AddToggleLabelText("BossHelper")
        TitanPanelRightClickMenu_AddToggleRightSide("BossHelper")

        TitanPanelRightClickMenu_AddSpacer(level)

        local hideText = TITAN_PANEL_MENU_HIDE or "Hide"
        TitanPanelRightClickMenu_AddCommand(hideText, "BossHelper", TITAN_PANEL_MENU_FUNC_HIDE)

    elseif level == 2 and value and value.type == "dungeon" then
        local dungeonData = BossData[value.key]
        TitanPanelRightClickMenu_AddTitle(dungeonData.displayName or value.key, level)

        -- Tilføj bosser
        for _, boss in ipairs(dungeonData.bosses) do
            local bossName = boss.displayName or boss.realName
            local info = UIDropDownMenu_CreateInfo()
            info.text = bossName
            info.hasArrow = boss.phases and #boss.phases > 0
            info.notCheckable = true
            info.value = { type = "boss", dungeon = value.key, boss = boss.realName }
            info.func = function()
                -- Hvis ingen faser → send boss-besked direkte
                if not (boss.phases and #boss.phases > 0) then
                    BossHelper:SendDungeonMessages({bosses = {boss}})
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end

    elseif level == 3 and value and value.type == "boss" then
        local dungeonData = BossData[value.dungeon]
        local boss
        for _, b in ipairs(dungeonData.bosses) do
            if b.realName == value.boss then boss = b break end
        end
        if boss and boss.phases then
            TitanPanelRightClickMenu_AddTitle(boss.displayName or boss.realName, level)
            for _, phase in ipairs(boss.phases) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = phase.name or ("Phase " .. _)
                info.notCheckable = true
                info.func = function()
                    BossHelper:SendSmartMessage(boss.phaseText[phase.name])
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end


