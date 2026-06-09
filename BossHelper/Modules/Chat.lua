-- Chat.lua
-- Håndterer alle beskeder der sendes til gruppe/raid chat.
-- Kræver at BossHelper.lua er loaded først (BossHelper, BossHelper.Sounds, etc.).

local BossHelper = _G.BossHelper

local MESSAGE_INTERVAL = 1.5 -- sekunder mellem beskeder
local MAX_LENGTH       = 250 -- hold lidt under WoW's 255-tegns grænse

--------------------------------------------------------------------------------
-- ChatManager: Indkapsler logikken for at sætte chatbeskeder i kø og sende dem
--------------------------------------------------------------------------------
local ChatManager = {
    queue = {},
    isSending = false
}

-- Returnerer den aktive gruppe-kanal, eller nil hvis man ikke er i en gruppe
function ChatManager:GetChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

-- Deler lange afsnit op for at undgå at ramme WoW's tegngrænse
function ChatManager:SplitText(text)
    local parts, buffer = {}, ""
    for word in text:gmatch("%S+") do
        if buffer == "" then
            buffer = word
        elseif #buffer + 1 + #word <= MAX_LENGTH then
            buffer = buffer .. " " .. word
        else
            table.insert(parts, buffer)
            buffer = word
        end
    end
    if buffer ~= "" then table.insert(parts, buffer) end
    return parts
end

-- Beder ChatManager om at processere køen
function ChatManager:ProcessQueue()
    if self.isSending then return end
    self.isSending = true
    self:SendNext()
end

-- Sender næste besked i køen
function ChatManager:SendNext()
    if #self.queue == 0 then
        self.isSending = false
        BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT)
        return
    end

    local entry = table.remove(self.queue, 1)
    if entry.channel then
        local ok, err = pcall(SendChatMessage, entry.msg, entry.channel)
        if not ok then
            DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " " .. Translate("CHAT_SEND_FAILED") .. tostring(err))
        end
    else
        -- Ikke i gruppe → vis lokalt
        DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG .. " " .. entry.msg)
    end

    if #self.queue > 0 then
        C_Timer.After(MESSAGE_INTERVAL, function()
            self:SendNext()
        end)
    else
        self.isSending = false
        BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT)
    end
end

-- Tilføjer en streng til køen, håndterer newlines og max længde
function ChatManager:QueueMessage(msg, includeFooter)
    local channel = self:GetChannel()
    if not channel then
        DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " " .. Translate("CHAT_NOT_IN_GROUP"))
    end

    local before = #self.queue

    for para in msg:gmatch("([^\n]+)") do
        local trimmed = strtrim(para)
        if trimmed == "" then
            table.insert(self.queue, { msg = " ", channel = channel })
        else
            for _, part in ipairs(self:SplitText(trimmed)) do
                table.insert(self.queue, { msg = part, channel = channel })
            end
        end
    end

    if includeFooter then
        table.insert(self.queue, { msg = "-- Provided by Mythic Mentor --", channel = channel })
    end

    self:ProcessQueue()
    return #self.queue - before
end

-- Offentliggør nogle stats til UI'en
function BossHelper:GetMessageQueueLength()
    return #ChatManager.queue
end

function BossHelper:IsMessageQueueSending()
    return ChatManager.isSending
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function BossHelper:SendSmartMessage(msg)
    if msg and msg ~= "" then
        return ChatManager:QueueMessage(msg, true)
    end
    return 0
end

function BossHelper:SendSingleSmartMessage(msg)
    if msg and msg ~= "" then
        return ChatManager:QueueMessage(msg, false)
    end
    return 0
end

function BossHelper:SendDungeonMessages(dungeon)
    if not dungeon or not dungeon.bosses then
        DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " Dungeon ikke fundet eller ingen bosser!")
        return
    end

    for _, boss in ipairs(dungeon.bosses) do
        local bossName = self:GetBossName(boss.encounterID) or "?"
        
        if boss.short and boss.short ~= "" then
            self:SendSingleSmartMessage("|cff00ff00[" .. bossName .. "]|r")
            self:SendSingleSmartMessage(boss.short)
        end

        if boss.phases and boss.phaseText then
            for _, phaseName in ipairs(boss.phases) do
                local text = boss.phaseText[phaseName]
                if text and text ~= "" then
                    self:SendSingleSmartMessage("|cff00ffff[" .. bossName .. " - " .. phaseName .. "]|r")
                    self:SendSingleSmartMessage(text)
                end
            end
        end
    end
end
