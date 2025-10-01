local frame = CreateFrame("Frame")

-- Liste over *alle* resurrection spells (combat + normal)
local resSpells = {
    -- Combat Resurrection
    [20484] = "Rebirth",                 -- Druid
    [61999] = "Raise Ally",              -- Death Knight
    [20707] = "Soulstone Resurrection",  -- Warlock
    [391054] = "Intercession",           -- Paladin

    -- Normal Resurrection
    [2006] = "Resurrection",             -- Priest
    [7328] = "Redemption",               -- Paladin
    [50769] = "Revive",                  -- Druid
    [2008] = "Ancestral Spirit",         -- Shaman
    [115178] = "Resuscitate",            -- Monk
    [212036] = "Mass Resurrection",      -- Priest (mass res)
}

-- Gemmer pending resses for at tracke ACCEPT
local pendingRes = {}

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("RESURRECT_REQUEST")

-- Når en spiller accepterer en resurrection
local function OnResAccept(name)
    if pendingRes[name] then
        local caster, spellName = pendingRes[name].caster, pendingRes[name].spell
        print(string.format("%s accepted %s from %s!", name, spellName, caster))
        pendingRes[name] = nil
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        -- Når et resurrection spell bliver castet
        if subEvent == "SPELL_CAST_SUCCESS" and resSpells[spellID] then
            -- Gem til senere accept
            pendingRes[destName] = { caster = sourceName, spell = spellName }

            -- Print til chat
            print(string.format("%s used %s on %s!", sourceName, spellName, destName))
        end

    elseif event == "RESURRECT_REQUEST" then
        -- Når nogen får res-vinduet frem
        local targetName = ...
        -- Vent et øjeblik og tjek om de accepterer
        C_Timer.After(0.5, function()
            OnResAccept(targetName)
        end)
    end
end)
