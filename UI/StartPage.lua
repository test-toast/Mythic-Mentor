-- StartPage.lua
-- ShowStartPage med robust fade + logo "pop" (scale -> normal)
function ShowStartPage(frame, rightPanel)
    if not rightPanel then return end

    -- Helper: check om vi må animate (tjek global helper først, fallback til savedvar)
    local function ShouldAnimate()
        if _G.BossHelper_ShouldAnimateInCombat then
            local ok, res = pcall(_G.BossHelper_ShouldAnimateInCombat)
            if ok and type(res) == "boolean" then return res end
        end
        BossHelperDB = BossHelperDB or {}
        if BossHelperDB.allowAnimationsInCombat then return true end
        return not InCombatLockdown()
    end

    -- Opret elementer hvis nødvendigt (som før)
    if not rightPanel.mainTitle then
        rightPanel.mainTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        rightPanel.mainTitle:SetPoint("TOP", rightPanel, "TOP", 0, -220)
        rightPanel.mainTitle:SetTextColor(1, 0.5, 0)
    end

    if not rightPanel.logo then
        rightPanel.logo = rightPanel:CreateTexture(nil, "ARTWORK")
        rightPanel.logo:SetSize(256, 256)
        rightPanel.logo:SetPoint("TOP", rightPanel, "TOP", 0, -10)
        rightPanel.logo:SetTexture("Interface\\AddOns\\BossHelper\\Media\\Mythic Mentor 512x512.tga")
    end

    if not rightPanel.mainDesc then
        rightPanel.mainDesc = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        rightPanel.mainDesc:SetPoint("TOP", rightPanel.logo, "BOTTOM", 0, -20)
        rightPanel.mainDesc:SetSize(500, 100)
        rightPanel.mainDesc:SetJustifyH("CENTER")
        rightPanel.mainDesc:SetJustifyV("TOP")
    end

    if not rightPanel.footerText then
        rightPanel.footerText = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rightPanel.footerText:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
        rightPanel.footerText:SetTextColor(0.7, 0.7, 0.7)
    end

    if not rightPanel.footerText2 then
        rightPanel.footerText2 = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rightPanel.footerText2:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 10, 10)
        rightPanel.footerText2:SetTextColor(0.7, 0.7, 0.7)
    end

    -- Skjul knapperne på forsiden
    if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
    if rightPanel.postButton then rightPanel.postButton:Hide() end
    rightPanel.showingDetails = false

    -- Indholdstekst
    rightPanel.mainTitle:SetText("") -- indsæt titel hvis ønsket
    rightPanel.mainDesc:SetText(Translate("SELECT_DUNGEON_HINT"))
    rightPanel.footerText:SetText("Burning Toast Studio")
    rightPanel.footerText2:SetText("v1.2.1")

    -- Fjern evt. gamle fades/animationer (sikkerhed)
    local regions = { rightPanel.logo, rightPanel.mainTitle, rightPanel.mainDesc, rightPanel.footerText, rightPanel.footerText2 }
    for _, r in ipairs(regions) do
        if r then
            pcall(function() UIFrameFadeRemoveFrame(r) end)
            if r.Show then pcall(r.Show, r) end
            if r.SetAlpha then pcall(r.SetAlpha, r, 1) end
            -- hvis tidligere skale-animationer er gemt, stop dem
            if r._scaleAG and r._scaleAG.IsPlaying and r._scaleAG:IsPlaying() then
                pcall(function() r._scaleAG:Stop() end)
            end
        end
    end

    -- Hvis animationer ikke er tilladt (fx i combat eller brugeren har slået dem fra), vis straks og sæt skala 1
    if not ShouldAnimate() then
        if rightPanel.logo and rightPanel.logo.SetScale then rightPanel.logo:SetScale(1) end
        for _, r in ipairs(regions) do
            if r and r.SetAlpha then pcall(r.SetAlpha, r, 1) end
            if r and r.Show then pcall(r.Show, r) end
        end
        return
    end

    -- Fade ind (stabile UIFrameFadeIn calls)
    local fadeTime = 0.14
    if rightPanel.logo then
        rightPanel.logo:SetAlpha(0)
        rightPanel.logo:Show()
        UIFrameFadeIn(rightPanel.logo, fadeTime, 0, 1)
    end
    if rightPanel.mainTitle then
        rightPanel.mainTitle:SetAlpha(0)
        UIFrameFadeIn(rightPanel.mainTitle, fadeTime, 0, 1)
    end
    if rightPanel.mainDesc then
        rightPanel.mainDesc:SetAlpha(0)
        UIFrameFadeIn(rightPanel.mainDesc, fadeTime, 0, 1)
    end
    if rightPanel.footerText then
        rightPanel.footerText:SetAlpha(0)
        UIFrameFadeIn(rightPanel.footerText, fadeTime, 0, 1)
    end
    if rightPanel.footerText2 then
        rightPanel.footerText2:SetAlpha(0)
        UIFrameFadeIn(rightPanel.footerText2, fadeTime, 0, 1)
    end

    -- Logo "pop" (scale op og tilbage til normal) med sikker fallback.
    -- Vi starter pop'en kort efter faden starter, så det føles synkront.
    pcall(function()
        -- stop tidligere hvis eksisterer
        if rightPanel.logo._scaleAG and rightPanel.logo._scaleAG.IsPlaying and rightPanel.logo._scaleAG:IsPlaying() then
            rightPanel.logo._scaleAG:Stop()
        end

        -- create new animation group for scale
        local ag = rightPanel.logo:CreateAnimationGroup()
        ag:SetLooping("NONE")
        local up = ag:CreateAnimation("Scale")
        up:SetScale(1.18, 1.18)      -- skaler op ~18%
        up:SetDuration(0.12)
        up:SetSmoothing("OUT")
        local down = ag:CreateAnimation("Scale")
        down:SetScale(1/1.18, 1/1.18) -- skaler tilbage til 1
        down:SetDuration(0.12)
        down:SetSmoothing("IN")

        -- sikre endelig skala = 1 (i tilfælde af rounding/afslutningsproblemer)
        ag:SetScript("OnFinished", function()
            if rightPanel and rightPanel.logo and rightPanel.logo.SetScale then
                rightPanel.logo:SetScale(1)
            end
        end)

        rightPanel.logo._scaleAG = ag

        -- start efter lidt delay så faden er i gang (men ikke for lang)
        local delay = math.max(fadeTime * 0.35, 0.06) -- lille synkronisering
        C_Timer.After(delay, function()
            -- double-check logo stadig eksisterer
            if rightPanel and rightPanel.logo and rightPanel.logo._scaleAG then
                local ok, err = pcall(function() rightPanel.logo._scaleAG:Play() end)
                if not ok then
                    -- fallback: sæt skala direkte hvis animation fejler
                    pcall(function() rightPanel.logo:SetScale(1) end)
                end
            end
        end)
    end)
end
