-- Functions.lua
-- Her samler vi alle generelle hjælpefunktioner til BossHelper

-- ================================================
-- Registrer et frame så det kan lukkes med ESC
-- ================================================
function BossHelper:RegisterEscClose(frame)
    if not frame or not frame.GetName then
        print("|cffff5555[BossHelper]|r Kan ikke registrere frame til ESC-lukning (mangler navn)")
        return
    end

    local name = frame:GetName()

    -- Fjern altid først, så vi undgår dubletter
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == name then
            table.remove(UISpecialFrames, i)
        end
    end

    -- Tilføj kun hvis indstillingen er aktiv
    if BossHelperDB and BossHelperDB.allowEscClose then
        table.insert(UISpecialFrames, name)
        -- print("BossHelper: ESC lukning aktiveret for -> " .. name)
    else
        -- print("BossHelper: ESC lukning deaktiveret for -> " .. name)
    end
end