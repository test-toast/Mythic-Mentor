-- Auto-Invite with two separate trigger-word lists:
--   "friendly"  – guild members, Battle.net friends, or friend-list friends
--   "other"     – everyone else
-- Multiple trigger words are supported per list.

-- Localized globals – avoids _G lookup on every call
local IsInGroup            = IsInGroup
local UnitIsGroupLeader    = UnitIsGroupLeader
local UnitIsGroupAssistant = UnitIsGroupAssistant
local strlower             = strlower
local strfind              = string.find
local tinsert              = table.insert
local tremove              = table.remove
local wipe                 = wipe

local triggersFriendly = {}
local triggersOther    = {}
local debugMode        = false
local guildGUIDs       = {}

-- Cached once in ADDON_LOADED – eliminates repeated nil/table checks on the hot path
local db           = nil   -- BossHelperDB reference
local inviteFn     = nil   -- C_PartyInfo.InviteUnit or InviteUnit
local fnBNetByGUID = nil   -- C_BattleNet.GetGameAccountInfoByGUID
local fnIsFriend   = nil   -- C_FriendList.IsFriend

Inviter = Inviter or {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------
local function dbg(...)
    if debugMode then print("|cff00ff00[AutoInvite:DBG]|r", ...) end
end

local function safeInvite(name)
    if not inviteFn then
        print("|cff00ff00[AutoInvite]|r " .. Translate("INVITE_FN_UNAVAILABLE"))
        return false
    end
    if IsInGroup() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        print("|cff00ff00[AutoInvite]|r " .. Translate("INVITE_NOT_LEADER"))
        return false
    end
    local ok, err = pcall(inviteFn, name)
    if not ok then
        dbg("Invite error:", tostring(err))
        print("|cff00ff00[AutoInvite]|r " .. Translate("INVITE_FAILED_FOR") .. name)
        return false
    end
    return true
end

local function refreshGuildGUIDs()
    wipe(guildGUIDs)
    local n = GetNumGuildMembers and GetNumGuildMembers() or 0
    for i = 1, n do
        local guid = select(17, GetGuildRosterInfo(i))
        if guid then guildGUIDs[guid] = true end
    end
    dbg("Guild GUIDs refreshed, count:", n)
end

local function isFriendly(guid)
    if not guid or guid == "" then return false end
    if guildGUIDs[guid]                    then return true end
    if fnBNetByGUID and fnBNetByGUID(guid) then return true end
    if fnIsFriend   and fnIsFriend(guid)   then return true end
    return false
end

local function matchInList(list, msg)
    local lower = strlower(msg)
    for i = 1, #list do
        if strfind(lower, list[i], 1, true) then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
function Inviter.GetWords(listName)
    if listName == "friendly" then return triggersFriendly
    elseif listName == "other" then return triggersOther
    end
    return {}
end

function Inviter.AddWord(listName, word)
    word = (word or ""):match("^%s*(.-)%s*$"):lower()
    if word == "" then return false, "empty" end
    local list = (listName == "friendly") and triggersFriendly or triggersOther
    for i = 1, #list do
        if list[i] == word then return false, "exists" end
    end
    tinsert(list, word)
    if db then
        if listName == "friendly" then
            db.triggerWordsFriendly = triggersFriendly
        else
            db.triggerWordsOther = triggersOther
        end
    end
    return true
end

function Inviter.RemoveWord(listName, word)
    word = (word or ""):lower()
    local list = (listName == "friendly") and triggersFriendly or triggersOther
    for i = 1, #list do
        if list[i] == word then
            tremove(list, i)
            if db then
                if listName == "friendly" then
                    db.triggerWordsFriendly = triggersFriendly
                else
                    db.triggerWordsOther = triggersOther
                end
            end
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Event frame
-- ---------------------------------------------------------------------------
local AutoInviteFrame = CreateFrame("Frame")
AutoInviteFrame:RegisterEvent("ADDON_LOADED")
AutoInviteFrame:RegisterEvent("PLAYER_LOGOUT")

function Inviter.SetEnabled(enabled)
    if enabled then
        AutoInviteFrame:RegisterEvent("CHAT_MSG_WHISPER")
        AutoInviteFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
        refreshGuildGUIDs()
    else
        AutoInviteFrame:UnregisterEvent("CHAT_MSG_WHISPER")
        AutoInviteFrame:UnregisterEvent("GUILD_ROSTER_UPDATE")
    end
end

AutoInviteFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if (...) ~= "BossHelper" then return end

        BossHelperDB = BossHelperDB or {}
        db = BossHelperDB

        -- Migrate old single triggerWord → friendly list
        if db.triggerWord ~= nil and db.triggerWordsFriendly == nil then
            db.triggerWordsFriendly = { db.triggerWord }
            db.triggerWord = nil
        end

        triggersFriendly = type(db.triggerWordsFriendly) == "table" and db.triggerWordsFriendly or { "invite!" }
        triggersOther    = type(db.triggerWordsOther)    == "table" and db.triggerWordsOther    or {}
        db.triggerWordsFriendly = triggersFriendly
        db.triggerWordsOther    = triggersOther

        if db.debugMode ~= nil then debugMode = db.debugMode end

        -- Cache API references once; avoids repeated nil/table checks on the hot path
        inviteFn     = (C_PartyInfo and C_PartyInfo.InviteUnit) or _G.InviteUnit
        fnBNetByGUID = C_BattleNet  and C_BattleNet.GetGameAccountInfoByGUID
        fnIsFriend   = C_FriendList and C_FriendList.IsFriend

        self:UnregisterEvent("ADDON_LOADED")

        -- Register active events only when auto-invite is enabled
        if db.autoInviteEnabled then
            AutoInviteFrame:RegisterEvent("CHAT_MSG_WHISPER")
            AutoInviteFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
            -- Trigger initial guild GUID cache (API varies by client version)
            if C_GuildInfo and C_GuildInfo.GuildRoster then
                C_GuildInfo.GuildRoster()
            elseif GuildRoster then
                GuildRoster()
            end
        end

    elseif event == "PLAYER_LOGOUT" then
        if db then
            db.triggerWordsFriendly = triggersFriendly
            db.triggerWordsOther    = triggersOther
        end

    elseif event == "GUILD_ROSTER_UPDATE" then
        refreshGuildGUIDs()

    elseif event == "CHAT_MSG_WHISPER" then
        -- CHAT_MSG_WHISPER args: msg, sender, lang, channel, target, flags,
        --   unused1, channelID, unused2, unused3, lineID, guid, bnSenderID, ...
        local msg, sender, _, _, _, _, _, _, _, _, _, guid = ...

        if not msg then return end

        local friendly = isFriendly(guid)
        local list = friendly and triggersFriendly or triggersOther
        dbg("Sender:", sender, "| friendly:", tostring(friendly),
            "| list size:", #list)

        if matchInList(list, msg) then
            if safeInvite(sender) then
                print("|cff00ff00[AutoInvite]|r Invited:", sender)
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Slash command handler  (used by Commands.lua via /mminv)
-- ---------------------------------------------------------------------------
function Inviter.HandleCommand(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    rest = (rest or ""):match("^%s*(.-)%s*$")
    BossHelperDB = BossHelperDB or {}

    if cmd == "addfriendly" and rest ~= "" then
        local ok, reason = Inviter.AddWord("friendly", rest)
        if ok then
            print("|cff00ff00[AutoInvite]|r Added friendly trigger:", rest:lower())
        elseif reason == "exists" then
            print("|cff00ff00[AutoInvite]|r Already in friendly list:", rest:lower())
        end

    elseif cmd == "addother" and rest ~= "" then
        local ok, reason = Inviter.AddWord("other", rest)
        if ok then
            print("|cff00ff00[AutoInvite]|r Added 'other' trigger:", rest:lower())
        elseif reason == "exists" then
            print("|cff00ff00[AutoInvite]|r Already in 'other' list:", rest:lower())
        end

    elseif cmd == "removefriendly" and rest ~= "" then
        if Inviter.RemoveWord("friendly", rest) then
            print("|cff00ff00[AutoInvite]|r Removed friendly trigger:", rest:lower())
        else
            print("|cff00ff00[AutoInvite]|r Not found in friendly list:", rest:lower())
        end

    elseif cmd == "removeother" and rest ~= "" then
        if Inviter.RemoveWord("other", rest) then
            print("|cff00ff00[AutoInvite]|r Removed 'other' trigger:", rest:lower())
        else
            print("|cff00ff00[AutoInvite]|r Not found in 'other' list:", rest:lower())
        end

    elseif cmd == "list" or cmd == "" then
        local fStr = #triggersFriendly > 0 and table.concat(triggersFriendly, ", ") or "(none)"
        local oStr = #triggersOther    > 0 and table.concat(triggersOther,    ", ") or "(none)"
        print("|cff00ff00[AutoInvite]|r Friendly triggers: " .. fStr)
        print("|cff00ff00[AutoInvite]|r Other triggers:    " .. oStr)

    elseif cmd == "debug" and (rest == "on" or rest == "off") then
        debugMode = (rest == "on")
        BossHelperDB.debugMode = debugMode
        print("|cff00ff00[AutoInvite]|r Debug mode:", debugMode and "on" or "off")

    else
        print("|cff00ff00[AutoInvite]|r Commands:")
        print("  /mminv addfriendly <word>    - Add trigger for guild/friends")
        print("  /mminv addother <word>       - Add trigger for everyone else")
        print("  /mminv removefriendly <word> - Remove from guild/friends list")
        print("  /mminv removeother <word>    - Remove from 'other' list")
        print("  /mminv list                  - Show all triggers")
        print("  /mminv debug on|off          - Toggle debug logging")
    end
end
