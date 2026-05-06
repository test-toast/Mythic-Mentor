-- Commands.lua
-- Alle slash-kommandoer til BossHelper / Mythic Mentor.
-- Denne fil loades sidst så alle UI-moduler er klar.

--------------------------------------------------------------------------------
-- /mm  /mythicmentor  --  åbn/luk hoved-UI
--------------------------------------------------------------------------------
SLASH_BOSSHELPER1 = "/mm"
SLASH_BOSSHELPER2 = "/mythicmentor"
SlashCmdList["BOSSHELPER"] = function(msg)
    if BossUI and BossUI.GetFrame then
        local frame = BossUI:GetFrame()
        if frame then
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
                -- Auto-select current dungeon when opening fresh (no previous dungeon/boss selected)
                if BossUI.GetCurrentDungeon and BossUI:GetCurrentDungeon() == nil
                   and BossUI.OpenFreshWithAutoSelect then
                    BossUI:OpenFreshWithAutoSelect()
                end
            end
        else
            print(BossHelper.CHAT_TAG_ERR .. " " .. Translate("CMD_UI_NOT_READY"))
        end
    else
        print(BossHelper.CHAT_TAG_ERR .. " " .. Translate("CMD_UI_NOT_LOADED"))
    end
end

--------------------------------------------------------------------------------
-- /mmw  --  åbn/luk mini-vindue
--------------------------------------------------------------------------------
SLASH_BOSSHELPER_MMW1 = "/mmw"
SlashCmdList["BOSSHELPER_MMW"] = function()
    if MiniWindow and MiniWindow.Toggle then
        MiniWindow.Toggle()
    end
end

--------------------------------------------------------------------------------
-- /mmc  --  åbn dungeon check vindue
--------------------------------------------------------------------------------
SLASH_BOSSHELPER_MMC1 = "/mmc"
SlashCmdList["BOSSHELPER_MMC"] = function()
    if DungeonCheckWindow and DungeonCheckWindow.Show then
        DungeonCheckWindow.Show()
    else
        print(BossHelper.CHAT_TAG_ERR .. " " .. Translate("CMD_DCW_NOT_LOADED"))
    end
end

--------------------------------------------------------------------------------
-- /mminv  --  auto-invite styring
--------------------------------------------------------------------------------
SLASH_MMINV1 = "/mminv"
SlashCmdList["MMINV"] = function(msg)
    if Inviter and Inviter.HandleCommand then
        Inviter.HandleCommand(msg)
    end
end
