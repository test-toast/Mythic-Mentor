-- Version.lua
-- Håndterer version-broadcast og opdaterings-notifikationer.
-- Kræver at BossHelper.lua er loaded først.

--------------------------------------------------------------------------------
-- Konstanter (deklareres her, så de er tilgængelige fra alle filer)
--------------------------------------------------------------------------------
BossHelper.VERSION_PREFIX            = "BOSSHELPER_VER"
BossHelper._latestSeenVersion        = nil   -- højeste version set fra andre i denne session
BossHelper._updatePopupShownForVersion = nil -- nil = ingen popup vist endnu

--------------------------------------------------------------------------------
-- Udsend vores version til alle relevante kanaler
--------------------------------------------------------------------------------
function BossHelper:BroadcastVersion()
    local ver = tostring(BossHelper.VERSION_STRING or "0")

    local function send(chan)
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            pcall(C_ChatInfo.SendAddonMessage, BossHelper.VERSION_PREFIX, ver, chan)
        elseif SendAddonMessage then
            pcall(SendAddonMessage, BossHelper.VERSION_PREFIX, ver, chan)
        end
    end

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then send("INSTANCE_CHAT") end
    if IsInRaid() then
        send("RAID")
    elseif IsInGroup() then
        send("PARTY")
    end
    if IsInGuild and IsInGuild() then send("GUILD") end
end

--------------------------------------------------------------------------------
-- Behandl en indkommende version fra en anden spiller
--------------------------------------------------------------------------------
function BossHelper:HandleIncomingVersion(otherVersion, sender)
    otherVersion = tostring(otherVersion or "0")

    -- Spor den højeste version set i denne session
    if not self._latestSeenVersion
       or self:CompareVersions(self._latestSeenVersion, otherVersion) < 0 then
        self._latestSeenVersion = otherVersion
    end

    -- Hvis den anden spiller har en nyere version end os → notificer én gang
    if self:CompareVersions(self.VERSION_STRING, otherVersion) < 0 then
        if BossHelperDB and BossHelperDB.notifiedLatestVersion == otherVersion then
            return -- allerede notificeret for denne version
        end

        -- Gem så vi ikke viser det igen næste session (medmindre en endnu nyere dukker op)
        if BossHelperDB then BossHelperDB.notifiedLatestVersion = otherVersion end

        -- Vis opdaterings-banner i UI
        if BossUI and BossUI.ShowUpdateBanner then
            BossUI:ShowUpdateBanner(otherVersion)
        end
    end
end

--------------------------------------------------------------------------------
-- Vis en StaticPopup om tilgængelig opdatering (kaldt fra andre steder)
--------------------------------------------------------------------------------
function BossHelper:ShowUpdatePopup(latestVersion)
    if self._updatePopupShownForVersion == latestVersion then return end
    self._updatePopupShownForVersion = latestVersion

    local popupText = string.format(
        Translate("UPDATE_POPUP_TEXT"),
        tostring(self.VERSION_STRING),
        tostring(latestVersion)
    )

    if not StaticPopupDialogs["BOSSHELPER_UPDATE_AVAILABLE"] then
        StaticPopupDialogs["BOSSHELPER_UPDATE_AVAILABLE"] = {
            text         = popupText,
            button1      = Translate("UPDATE_POPUP_BTN_GITHUB"),
            button2      = OKAY,
            OnAccept     = function()
                if BossHelper and BossHelper.ShowGitHubLinkPopup then
                    BossHelper:ShowGitHubLinkPopup()
                end
            end,
            timeout      = 0,
            whileDead    = 1,
            hideOnEscape = 1,
            preferredIndex = 3,
        }
    else
        StaticPopupDialogs["BOSSHELPER_UPDATE_AVAILABLE"].text = popupText
    end

    StaticPopup_Show("BOSSHELPER_UPDATE_AVAILABLE")
end
