-- BossHelper.lua
BossHelper = {}

--------------------------------------------------------------------------------
-- Hent Mythic+ dungeons
--------------------------------------------------------------------------------
function BossHelper:GetMythicPlusDungeons()
    local dungeons = {}
    for i, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
        local name, _, _, textureID = C_ChallengeMode.GetMapUIInfo(mapID)
        if name and textureID then
            table.insert(dungeons, {id = mapID, name = name, texture = textureID})
        end
    end
    return dungeons
end

--------------------------------------------------------------------------------
-- Localisering af UI
--------------------------------------------------------------------------------
-- Var for holding language selected by user
    BossHelperDB = BossHelperDB or {}         -- sørg for at SavedVariables eksisterer
    BossHelper.selectedLocale = BossHelperDB.language or "enUS"
--BossHelper.selectedLocale = "enUS"
-- function load localization file based on selected locale
function BossHelper:LoadLocale()
    BossHelperDB = BossHelperDB or {}         -- sørg for at SavedVariables eksisterer
    BossHelper.selectedLocale = BossHelperDB.language or "enUS"
    
    local locale = BossHelper.selectedLocale or "enUS"
        local locales = {
            enUS = L_enUS,
            daDK = L_daDK,
            ruRU = L_ruRU,
            deDE = L_deDE,
            -- tilføj flere sprog her
        }
    self.Lfile = locales[locale] or L_enUS
end
-- Load default locale at startup
BossHelper:LoadLocale()

--------------------------------------------------------------------------------
-- load localized string som Loadlocale file with global function
--------------------------------------------------------------------------------
function BossHelper:Translate(key)
    if self.Lfile and self.Lfile[key] then
        return self.Lfile[key]
    else
        return key -- fallback to key if not found
    end
end

Translate = function(key) return BossHelper:Translate(key) end


--------------------------------------------------------------------------------
-- Sikker afspilning af lyd
--------------------------------------------------------------------------------
function BossHelper:SafePlaySound(soundId)
    if type(soundId) ~= "number" then return end
    if not PlaySound then return end
    pcall(PlaySound, soundId)
end

--------------------------------------------------------------------------------
-- Chat system (robust version med kø og throttling)
--------------------------------------------------------------------------------
BossHelper._messageQueue = BossHelper._messageQueue or {}
BossHelper._isSending = false

local MESSAGE_INTERVAL = 1.5 -- sekunder mellem beskeder
local MAX_LENGTH = 250       -- hold lidt under 255
BossHelper.MESSAGE_INTERVAL = MESSAGE_INTERVAL

-- Starter kø-processor
local function StartMessageProcessor()
    if BossHelper._isSending then return end
    BossHelper._isSending = true

    local function ProcessQueue()
        if #BossHelper._messageQueue == 0 then
            BossHelper._isSending = false

            -- Spil "Accept"-lyd når ALLE beskeder er sendt
            if PlayButtonSound then
                PlayButtonSound(SOUND.ACCEPT)
            end
            return
        end


        local entry = table.remove(BossHelper._messageQueue, 1)

        if entry then
            if entry.channel then
                -- normal gruppe/raid besked
                local ok, err = pcall(SendChatMessage, entry.msg, entry.channel, nil, entry.target)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[BossHelper]|r Chat send fejlede: " .. tostring(err))
                end

                --Anders: Dette sender en reklame men den kommer samtidig med den sidste besked vi vil gerne have et delay
                --if #BossHelper._messageQueue == 0 then
                    --pcall(SendChatMessage, "This messages was send by Mythic Mentor", entry.channel, nil, entry.target)
                --end
            else
                -- ikke i gruppe -> vis lokalt
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[BossHelper]|r " .. entry.msg)
            end
        end
        
        if #BossHelper._messageQueue > 0 then
            C_Timer.After(BossHelper.MESSAGE_INTERVAL, ProcessQueue)
        else
            BossHelper._isSending = false
        end
    end

    -- Send første besked med det samme
    ProcessQueue()
end

function BossHelper:SendSmartMessage(msg)
    if not msg or msg == "" then return 0 end

    local channel, target
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        -- Ikke i gruppe -> info til spiller
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[BossHelper]|r Not in a group, messages will only be sent to you.")
        channel = nil -- vi bruger local fallback
    end

    -- Split på linjeskift
    local paragraphs = {}
    for para in msg:gmatch("([^\n]+)") do
        table.insert(paragraphs, para)
    end
    if #paragraphs == 0 then table.insert(paragraphs, msg) end

    -- Split lange linjer
    local function splitParagraph(par)
        local parts, buffer = {}, ""
        for word in par:gmatch("%S+") do
            if buffer == "" then
                buffer = word
            else
                if #buffer + 1 + #word <= MAX_LENGTH then
                    buffer = buffer .. " " .. word
                else
                    table.insert(parts, buffer)
                    buffer = word
                end
            end
        end
        if buffer ~= "" then table.insert(parts, buffer) end
        return parts
    end

    -- Læg alt i køen, returner antal nye entries
    local before = #BossHelper._messageQueue

    for _, para in ipairs(paragraphs) do
        local trimmed = para:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed == 0 then
            table.insert(BossHelper._messageQueue, {msg = " ", channel = channel, target = target})
        else
            for _, part in ipairs(splitParagraph(trimmed)) do
                table.insert(BossHelper._messageQueue, {msg = part, channel = channel, target = target})
            end
        end
    end

    table.insert(BossHelper._messageQueue, {msg = "-- Provided by Mythic Mentor --", channel = channel, target = target})

    local added = #BossHelper._messageQueue - before

    StartMessageProcessor()

    return added -- antal beskeder vi lagde i kø
end

--------
-- Single button send message
--------
function BossHelper:SendSingleSmartMessage(msg)
    if not msg or msg == "" then return 0 end

    local channel, target
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        -- Ikke i gruppe -> info til spiller
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[BossHelper]|r Not in a group, messages will only be sent to you.")
        channel = nil -- vi bruger local fallback
    end

    -- Split på linjeskift
    local paragraphs = {}
    for para in msg:gmatch("([^\n]+)") do
        table.insert(paragraphs, para)
    end
    if #paragraphs == 0 then table.insert(paragraphs, msg) end

    -- Split lange linjer
    local function splitParagraph(par)
        local parts, buffer = {}, ""
        for word in par:gmatch("%S+") do
            if buffer == "" then
                buffer = word
            else
                if #buffer + 1 + #word <= MAX_LENGTH then
                    buffer = buffer .. " " .. word
                else
                    table.insert(parts, buffer)
                    buffer = word
                end
            end
        end
        if buffer ~= "" then table.insert(parts, buffer) end
        return parts
    end

    -- Læg alt i køen, returner antal nye entries
    local before = #BossHelper._messageQueue

    for _, para in ipairs(paragraphs) do
        local trimmed = para:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed == 0 then
            table.insert(BossHelper._messageQueue, {msg = " ", channel = channel, target = target})
        else
            for _, part in ipairs(splitParagraph(trimmed)) do
                table.insert(BossHelper._messageQueue, {msg = part, channel = channel, target = target})
            end
        end
    end

    --table.insert(BossHelper._messageQueue, {msg = "-- Provided by Mythic Mentor --", channel = channel, target = target})

    local added = #BossHelper._messageQueue - before

    StartMessageProcessor()

    return added -- antal beskeder vi lagde i kø
end

--------------------------------------------------------------------------------
-- Boss portrætter via Encounter Journal
--------------------------------------------------------------------------------
function BossHelper:GetBossPortraitFileID(dungeonName, bossName, realName, bossData)
    if bossData and bossData.icon then
        return bossData.icon
    end

    for i = 1, 100 do
        local instanceID, name = EJ_GetInstanceByIndex(i, false)
        if not name then break end
        if name == dungeonName then
            EJ_SelectInstance(instanceID)
            for j = 1, 50 do
                local encName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(j, instanceID)
                if not encName then break end
                if encName == (realName or bossName) then
                    local _, _, _, displayID, iconFile = EJ_GetCreatureInfo(1, journalEncounterID)
                    if iconFile then
                        if bossData then bossData.icon = iconFile end
                        return iconFile
                    end
                end
            end
            return nil
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Send alle bossbeskeder for en dungeon (inklusive faser)
--------------------------------------------------------------------------------
function BossHelper:SendDungeonMessages(dungeon)
    if not dungeon or not dungeon.bosses then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[BossHelper]|r Dungeon ikke fundet eller ingen bosser!")
        return
    end

    for _, boss in ipairs(dungeon.bosses) do
        -- Send short tekst
        if boss.short and boss.short ~= "" then
            BossHelper:SendSmartMessage("|cff00ff00["..boss.displayName.."]|r")
            BossHelper:SendSmartMessage(boss.short)
        end

        -- Send faser hvis de findes
        if boss.phases and boss.phaseText then
            for _, phaseName in ipairs(boss.phases) do
                local text = boss.phaseText[phaseName]
                if text and text ~= "" then
                    BossHelper:SendSmartMessage("|cff00ffff["..boss.displayName.." - "..phaseName.."]|r")
                    BossHelper:SendSmartMessage(text)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Loader events
--------------------------------------------------------------------------------
local _loader = CreateFrame("Frame")
_loader:RegisterEvent("ADDON_LOADED")
_loader:RegisterEvent("PLAYER_LOGIN")

_loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BossHelper" then
        -- Sørg for at SavedVariables tabellen eksisterer
        BossHelperDB = BossHelperDB or {}
        -- load localisering file
        BossHelper:LoadLocale()
        BossData:Load(BossHelper.selectedLocale)

        -------------------------------------------------------------------------
        -- DEFAULT SETTINGS (kun hvis de ikke allerede er sat)
        -------------------------------------------------------------------------
        if BossHelperDB.scale == nil then
            BossHelperDB.scale = 1.0
        end

        if BossHelperDB.allowAnimationsInCombat == nil then
            BossHelperDB.allowAnimationsInCombat = true
        end

        if BossHelperDB.closeOnPost == nil then
            BossHelperDB.closeOnPost = false
        end

        if BossHelperDB.allowEscClose == nil then
            BossHelperDB.allowEscClose = true
        end

        if BossHelperDB.autoInviteEnabled == nil then
            BossHelperDB.autoInviteEnabled = false
        end

        if BossHelperDB.triggerWord == nil then
            BossHelperDB.triggerWord = "invite!"
        end
        -------------------------------------------------------------------------

        -- Opret UI hvis BossUI er klar
        if BossUI and BossUI.CreateUI then
            BossUI:CreateUI()
            BossHelper._uiCreated = true
        end

        -- Registrer ESC-lukning hvis indstillingen er aktiv
        if BossUI and BossUI.GetFrame then
            local f = BossUI:GetFrame()
            if f then
                BossHelper:RegisterEscClose(f)
            end
        end

        -- Fjern ADDON_LOADED, da vi ikke behøver at køre det igen
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        -- init scale og andre saved vars
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.scale = BossHelperDB.scale or 1.0

        -- Sørg for at UI'et er oprettet ved login
        if BossUI and BossUI.CreateUI and not BossHelper._uiCreated then
            BossUI:CreateUI()
            BossHelper._uiCreated = true
        end

        -- Registrer ESC-lukning efter login også
        if BossUI and BossUI.GetFrame then
            local f = BossUI:GetFrame()
            if f then
                BossHelper:RegisterEscClose(f)
            end
        end
    end
end)


--------------------------------------------------------------------------------
-- Init (kan bruges til at registrere flere events senere)
--------------------------------------------------------------------------------
function BossHelper:Init()
    -- Placeholder
end
