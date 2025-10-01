-- Default trigger word
local triggerWord = "invite!"
local debugMode = false

Inviter = Inviter or {}

function Inviter.SetTrigger(trigger)
    triggerWord = trigger
end

-- Simple debug print
local function dbg(...)
    if debugMode then
        print("|cff00ff00[AutoInvite:DBG]|r", ...)
    end
end

-- Safe invite helper
local function safeInvite(name)
    local inviteFn = (C_PartyInfo and C_PartyInfo.InviteUnit) or _G.InviteUnit
    if not inviteFn then
        dbg("Invite function unavailable")
        print("|cff00ff00[AutoInvite]|r Invite function not available")
        return false
    end

    if IsInGroup() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        dbg("Not leader/assistant; cannot invite")
        print("|cff00ff00[AutoInvite]|r You are not leader/assistant")
        return false
    end

    local ok, err = pcall(inviteFn, name)
    if not ok then
        dbg("Invite error:", tostring(err))
        print("|cff00ff00[AutoInvite]|r Invite failed for:", name)
        return false
    end
    return true
end

-- Frame til at håndtere events
local AutoInviteFrame = CreateFrame("Frame")
AutoInviteFrame:RegisterEvent("ADDON_LOADED")
AutoInviteFrame:RegisterEvent("PLAYER_LOGOUT")
AutoInviteFrame:RegisterEvent("CHAT_MSG_WHISPER")

AutoInviteFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "BossHelper" then
        -- Sørg for at SavedVariables eksisterer
        BossHelperDB = BossHelperDB or {}

        -- Brug gemt triggerWord eller fallback
        triggerWord = BossHelperDB.triggerWord or "invite!"

    elseif event == "PLAYER_LOGOUT" then
        -- Gem triggerWord inden logout/reload
        BossHelperDB = BossHelperDB or {}
        BossHelperDB.triggerWord = triggerWord

    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = arg1, arg2
        -- tjek om auto-invite er slået til
        if not (BossHelperDB and BossHelperDB.autoInviteEnabled) then
            dbg("AutoInvite disabled")
            return
        end

        if msg and triggerWord ~= "" then
            local lowerMsg = string.lower(msg)
            local lowerTrig = string.lower(triggerWord)
            local idx = string.find(lowerMsg, lowerTrig, 1, true) -- plain search
            dbg("find(msg, trigger, 1, true) ->", tostring(idx))
            if idx then
                if safeInvite(sender) then
                    print("|cff00ff00[AutoInvite]|r Invited:", sender)
                end
            end
        else
            dbg("Skipping: empty msg or empty trigger")
        end
    end
end)

-- Slash command: /mm
SLASH_MM1 = "/mm"
SlashCmdList["MM"] = function(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    rest = (rest or ""):match("^%s*(.-)%s*$") -- trim
    BossHelperDB = BossHelperDB or {}

    if cmd == "settrigger" and rest ~= "" then
        triggerWord = rest
        BossHelperDB.triggerWord = triggerWord
        print("|cff00ff00[AutoInvite]|r Trigger word set to:", triggerWord)

    elseif cmd == "showtrigger" then
        print("|cff00ff00[AutoInvite]|r Current trigger word is:", triggerWord)

    elseif cmd == "debug" and (rest == "on" or rest == "off") then
        debugMode = (rest == "on")
        BossHelperDB.debugMode = debugMode
        print("|cff00ff00[AutoInvite]|r Debug mode:", debugMode and "on" or "off")

    else
        print("|cff00ff00[AutoInvite]|r Commands:")
        print("/mm settrigger <word> - Set trigger word for auto invitation")
        print("/mm showtrigger - Show current trigger word")
        print("/mm debug on|off - Toggle debug logging (For developers)")
    end
end
