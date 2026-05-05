-- Chat.lua
-- Håndterer alle beskeder der sendes til gruppe/raid chat.
-- Kræver at BossHelper.lua er loaded først (BossHelper, BossHelper.Sounds, etc.).

--------------------------------------------------------------------------------
-- Kø og throttle-config
--------------------------------------------------------------------------------
local MESSAGE_INTERVAL = 1.5 -- sekunder mellem beskeder
local MAX_LENGTH       = 250 -- hold lidt under WoW's 255-tegns grænse

BossHelper._messageQueue   = BossHelper._messageQueue or {}
BossHelper._isSending      = false
BossHelper.MESSAGE_INTERVAL = MESSAGE_INTERVAL

--------------------------------------------------------------------------------
-- Intern: start kø-processoren (kører indtil køen er tom)
--------------------------------------------------------------------------------
local function StartMessageProcessor()
    if BossHelper._isSending then return end
    BossHelper._isSending = true

    local function ProcessQueue()
        if #BossHelper._messageQueue == 0 then
            BossHelper._isSending = false
            -- Spil lyd når ALLE beskeder er sendt
            BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT)
            return
        end

        local entry = table.remove(BossHelper._messageQueue, 1)
        if entry then
            if entry.channel then
                local ok, err = pcall(SendChatMessage, entry.msg, entry.channel, nil, entry.target)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage(
                        BossHelper.CHAT_TAG_ERR .. " Chat send fejlede: " .. tostring(err)
                    )
                end
            else
                -- Ikke i gruppe → vis lokalt
                DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG .. " " .. entry.msg)
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

--------------------------------------------------------------------------------
-- Intern: find aktiv gruppe-kanal, eller nil når ikke i gruppe
--------------------------------------------------------------------------------
local function _GetChatChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

--------------------------------------------------------------------------------
-- Intern: split ét afsnit i dele der ikke overstiger MAX_LENGTH
--------------------------------------------------------------------------------
local function _SplitParagraph(par)
    local parts, buffer = {}, ""
    for word in par:gmatch("%S+") do
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

--------------------------------------------------------------------------------
-- Intern: sæt alle linjer i msg i kø; inkluder eventuelt en footer-linje.
-- Returnerer antal tilføjede entries.
--------------------------------------------------------------------------------
local function _QueueMessages(msg, includeFooter)
    local channel = _GetChatChannel()
    if not channel then
        DEFAULT_CHAT_FRAME:AddMessage(
            BossHelper.CHAT_TAG_ERR .. " Not in a group – messages will only be shown to you."
        )
    end

    local paragraphs = {}
    for para in msg:gmatch("([^\n]+)") do
        table.insert(paragraphs, para)
    end
    if #paragraphs == 0 then table.insert(paragraphs, msg) end

    local before = #BossHelper._messageQueue
    for _, para in ipairs(paragraphs) do
        local trimmed = para:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed == 0 then
            table.insert(BossHelper._messageQueue, { msg = " ", channel = channel })
        else
            for _, part in ipairs(_SplitParagraph(trimmed)) do
                table.insert(BossHelper._messageQueue, { msg = part, channel = channel })
            end
        end
    end

    if includeFooter then
        table.insert(BossHelper._messageQueue, {
            msg     = "-- Provided by Mythic Mentor --",
            channel = channel,
        })
    end

    return #BossHelper._messageQueue - before
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Send msg til gruppen med "Provided by Mythic Mentor" attribution footer.
function BossHelper:SendSmartMessage(msg)
    if not msg or msg == "" then return 0 end
    local added = _QueueMessages(msg, true)
    StartMessageProcessor()
    return added
end

-- Send msg til gruppen uden footer (enkelt-linje brug).
function BossHelper:SendSingleSmartMessage(msg)
    if not msg or msg == "" then return 0 end
    local added = _QueueMessages(msg, false)
    StartMessageProcessor()
    return added
end

-- Send alle boss-beskeder for en hel dungeon (inkl. faser).
function BossHelper:SendDungeonMessages(dungeon)
    if not dungeon or not dungeon.bosses then
        DEFAULT_CHAT_FRAME:AddMessage(
            BossHelper.CHAT_TAG_ERR .. " Dungeon ikke fundet eller ingen bosser!"
        )
        return
    end

    for _, boss in ipairs(dungeon.bosses) do
        local bossName = BossHelper:GetBossName(boss.encounterID) or "?"

        if boss.short and boss.short ~= "" then
            BossHelper:SendSmartMessage("|cff00ff00[" .. bossName .. "]|r")
            BossHelper:SendSmartMessage(boss.short)
        end

        if boss.phases and boss.phaseText then
            for _, phaseName in ipairs(boss.phases) do
                local text = boss.phaseText[phaseName]
                if text and text ~= "" then
                    BossHelper:SendSmartMessage("|cff00ffff[" .. bossName .. " - " .. phaseName .. "]|r")
                    BossHelper:SendSmartMessage(text)
                end
            end
        end
    end
end
