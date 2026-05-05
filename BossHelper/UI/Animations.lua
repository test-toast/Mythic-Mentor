-- Animations.lua
-- Alle animations-hjælpere samlet ét sted – nemt at justere varighed,
-- smoothing og skala-faktorer uden at rode i de øvrige UI-filer.

BossHelper       = BossHelper or {}
BossHelper.Anim  = BossHelper.Anim or {}

local Anim = BossHelper.Anim

-- ============================================================
-- Tuning-konstanter  (juster her for at ændre "følelsen")
-- ============================================================
Anim.Config = {
    -- Tekst-crossfade
    CROSSFADE_DURATION   = 0.12,   -- sekunder

    -- Knap hover: let zoom ind
    BTN_ENTER_SCALE      = 1.06,
    BTN_ENTER_DURATION   = 0.12,
    BTN_ENTER_SMOOTHING  = "OUT",

    -- Knap selected: pulse-bounce
    BTN_PULSE_SCALE_OUT  = 1.10,
    BTN_PULSE_SCALE_IN   = 1 / 1.10,
    BTN_PULSE_DURATION   = 0.10,

    -- Dropdown åbner: slide ned + fade ind
    DROPDOWN_SLIDE_Y     = 6,       -- pixel offset
    DROPDOWN_DURATION    = 0.12,
    DROPDOWN_SMOOTHING   = "OUT",

    -- Affix-side: kolonner glider op + fade ind (staggered)
    AFFIX_COL_SLIDE_Y    = -10,    -- px nedefra (negativt = glider op til anchor)
    AFFIX_COL_DURATION   = 0.18,
    AFFIX_COL_STAGGER    = 0.05,   -- sekunder imellem kolonner

    -- Logo-pop på startside
    LOGO_POP_SCALE       = 1.18,
    LOGO_POP_UP_DURATION = 0.12,
    LOGO_POP_DN_DURATION = 0.12,
    LOGO_POP_DELAY_FRAC  = 0.35,   -- andel af fadeTime inden pop starter
    LOGO_POP_DELAY_MIN   = 0.06,   -- minimum sekunder
    -- Keystone-widget: slide animation per kort/knap i stablet visning
    KEYSTONE_SLIDE_DURATION = 0.30,   -- sekunder per kort
    KEYSTONE_SLIDE_SMOOTHING = "OUT",
    KEYSTONE_STAGGER        = 0.04,   -- sekunder imellem hvert kort

    -- Taktik-rækkepil: slide-animation når rækker byttes
    TACTIC_ROW_SLIDE_DURATION = 0.22,  -- sekunder
}

function Anim.ShouldAnimate()
    BossHelperDB = BossHelperDB or {}
    if BossHelperDB.allowAnimationsInCombat then return true end
    return not InCombatLockdown()
end

-- Bevarer den globale reference som StartPage.lua og BossSettings.lua
-- bruger som fallback (kan fjernes når alle filer er opdateret).
_G.BossHelper_ShouldAnimateInCombat = Anim.ShouldAnimate

-- ============================================================
-- Tekst-crossfade  (fade ud → skift tekst → fade ind)
-- ============================================================
function Anim.CrossfadeText(fontString, newText, duration)
    duration = duration or Anim.Config.CROSSFADE_DURATION
    if not fontString then return end

    if not Anim.ShouldAnimate() then
        fontString:SetText(newText or "")
        return
    end

    local outAG = fontString:CreateAnimationGroup()
    local a1    = outAG:CreateAnimation("Alpha")
    a1:SetFromAlpha(1)
    a1:SetToAlpha(0)
    a1:SetDuration(duration)
    a1:SetSmoothing("OUT")

    outAG:SetScript("OnFinished", function()
        fontString:SetText(newText or "")
        local inAG = fontString:CreateAnimationGroup()
        local a2   = inAG:CreateAnimation("Alpha")
        a2:SetFromAlpha(0)
        a2:SetToAlpha(1)
        a2:SetDuration(duration)
        a2:SetSmoothing("IN")
        inAG:Play()
    end)

    outAG:Play()
end

-- ============================================================
-- Knap hover-animationer
-- Kalder:  BossHelper.Anim.ApplyButtonHover(btn)
-- Gemmer:  btn._enterAG  btn._pulseAG
-- ============================================================
function Anim.ApplyButtonHover(btn)
    if not Anim.ShouldAnimate() then return end

    local cfg = Anim.Config
    -- Skaler kun content-frame (tekst + ikon) – backdrop på btn skalerer ikke.
    local target = btn.content or btn

    -- Hover: let zoom ind
    local enterAG    = target:CreateAnimationGroup()
    local enterScale = enterAG:CreateAnimation("Scale")
    enterScale:SetScale(cfg.BTN_ENTER_SCALE, cfg.BTN_ENTER_SCALE)
    enterScale:SetDuration(cfg.BTN_ENTER_DURATION)
    enterScale:SetSmoothing(cfg.BTN_ENTER_SMOOTHING)
    local enterAlpha = enterAG:CreateAnimation("Alpha")
    enterAlpha:SetFromAlpha(1)
    enterAlpha:SetToAlpha(1)
    enterAlpha:SetDuration(cfg.BTN_ENTER_DURATION)

    -- Selected: pulse-bounce
    local pulseAG  = target:CreateAnimationGroup()
    pulseAG:SetLooping("NONE")
    local pulseOut = pulseAG:CreateAnimation("Scale")
    pulseOut:SetScale(cfg.BTN_PULSE_SCALE_OUT, cfg.BTN_PULSE_SCALE_OUT)
    pulseOut:SetDuration(cfg.BTN_PULSE_DURATION)
    pulseOut:SetSmoothing("OUT")
    local pulseIn  = pulseAG:CreateAnimation("Scale")
    pulseIn:SetScale(cfg.BTN_PULSE_SCALE_IN, cfg.BTN_PULSE_SCALE_IN)
    pulseIn:SetDuration(cfg.BTN_PULSE_DURATION)
    pulseIn:SetSmoothing("IN")

    btn._enterAG = enterAG
    btn._pulseAG = pulseAG
end

-- ============================================================
-- Dropdown åbner: slide ned + fade ind
-- ============================================================
function Anim.PlayDropdownOpen(panel)
    if not Anim.ShouldAnimate() then return end

    local cfg = Anim.Config
    local ag  = panel:CreateAnimationGroup()

    local t = ag:CreateAnimation("Translation")
    t:SetOffset(0, cfg.DROPDOWN_SLIDE_Y)
    t:SetDuration(cfg.DROPDOWN_DURATION)
    t:SetSmoothing(cfg.DROPDOWN_SMOOTHING)

    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(0)
    a:SetToAlpha(1)
    a:SetDuration(cfg.DROPDOWN_DURATION)

    ag:Play()
end

-- ============================================================
-- Affix-kolonner: staggered slide-op + fade-ind
-- Kalder:  BossHelper.Anim.PlayAffixColumnsIn(colFrames)
-- colFrames = tabel med kolonneframes (fra _colFrames i Affixes.lua)
-- ============================================================
function Anim.PlayAffixColumnsIn(colFrames)
    if not Anim.ShouldAnimate() then return end
    local cfg = Anim.Config
    for i, col in ipairs(colFrames) do
        C_Timer.After((i - 1) * cfg.AFFIX_COL_STAGGER, function()
            if not col or not col.IsShown or not col:IsShown() then return end
            local ag = col:CreateAnimationGroup()

            local tr = ag:CreateAnimation("Translation")
            tr:SetOffset(0, cfg.AFFIX_COL_SLIDE_Y)
            tr:SetDuration(cfg.AFFIX_COL_DURATION)
            tr:SetSmoothing("OUT")

            local al = ag:CreateAnimation("Alpha")
            al:SetFromAlpha(0)
            al:SetToAlpha(1)
            al:SetDuration(cfg.AFFIX_COL_DURATION)
            al:SetSmoothing("IN")

            ag:Play()
        end)
    end
end

-- ============================================================
-- Startside-hjælpere
-- ============================================================

-- Nulstil frames til synlig/fuld-alpha (annullerer evt. igangværende fades).
function Anim.ResetRegions(regions)
    for _, r in ipairs(regions) do
        if r then
            pcall(function() UIFrameFadeRemoveFrame(r) end)
            if r.Show  then pcall(r.Show,     r)    end
            if r.SetAlpha then pcall(r.SetAlpha, r, 1) end
            if r._scaleAG and r._scaleAG.IsPlaying and r._scaleAG:IsPlaying() then
                pcall(function() r._scaleAG:Stop() end)
            end
        end
    end
end

-- Fade alle frames fra 0 → 1 over fadeTime sekunder.
function Anim.FadeInRegions(regions, fadeTime)
    for _, r in ipairs(regions) do
        if r then
            if r.SetAlpha then pcall(r.SetAlpha, r, 0) end
            if r.Show     then pcall(r.Show, r)        end
            UIFrameFadeIn(r, fadeTime, 0, 1)
        end
    end
end

-- Logo-pop animation: zoom op og ned igen.
function Anim.PlayLogoPop(logo, fadeTime)
    pcall(function()
        if logo._scaleAG and logo._scaleAG.IsPlaying and logo._scaleAG:IsPlaying() then
            logo._scaleAG:Stop()
        end

        local cfg  = Anim.Config
        local ag   = logo:CreateAnimationGroup()
        ag:SetLooping("NONE")

        local up = ag:CreateAnimation("Scale")
        up:SetScale(cfg.LOGO_POP_SCALE, cfg.LOGO_POP_SCALE)
        up:SetDuration(cfg.LOGO_POP_UP_DURATION)
        up:SetSmoothing("OUT")

        local down = ag:CreateAnimation("Scale")
        down:SetScale(1 / cfg.LOGO_POP_SCALE, 1 / cfg.LOGO_POP_SCALE)
        down:SetDuration(cfg.LOGO_POP_DN_DURATION)
        down:SetSmoothing("IN")

        ag:SetScript("OnFinished", function()
            if logo and logo.SetScale then logo:SetScale(1) end
        end)

        logo._scaleAG = ag

        local delay = math.max(fadeTime * cfg.LOGO_POP_DELAY_FRAC, cfg.LOGO_POP_DELAY_MIN)
        C_Timer.After(delay, function()
            if logo and logo._scaleAG then
                local ok = pcall(function() logo._scaleAG:Play() end)
                if not ok then pcall(function() logo:SetScale(1) end) end
            end
        end)
    end)
end

-- ============================================================
-- Simple tweens: height and alpha using OnUpdate (used by MiniWindow)
-- Moved here so all animation tuning is centralized.
-- ============================================================
function Anim.AnimateHeight(frame, fromH, toH, duration, onComplete)
    if not frame then
        if onComplete then pcall(onComplete) end
        return
    end
    if duration == nil then duration = 0.18 end
    if duration <= 0 or not Anim.ShouldAnimate() then
        if frame.SetHeight then pcall(function() frame:SetHeight(toH) end) end
        if onComplete then pcall(onComplete) end
        return
    end

    if frame._heightTween then frame._heightTween.running = false end
    frame._heightTween = { running = true }
    local start = GetTime()
    if frame.SetHeight then pcall(function() frame:SetHeight(fromH) end) end
    frame:SetScript("OnUpdate", function(self)
        local t = (GetTime() - start) / duration
        if not frame._heightTween.running then
            self:SetScript("OnUpdate", nil)
            return
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if frame.SetHeight then pcall(function() frame:SetHeight(toH) end) end
            frame._heightTween.running = false
            if onComplete then pcall(onComplete) end
        else
            local eased = (1 - math.cos(t * math.pi)) / 2
            local h = fromH + (toH - fromH) * eased
            if frame.SetHeight then pcall(function() frame:SetHeight(h) end) end
        end
    end)
end

function Anim.AnimateAlpha(widget, fromA, toA, duration)
    if not widget then return end
    if duration == nil then duration = Anim.Config.CROSSFADE_DURATION or 0.12 end
    if duration <= 0 or not Anim.ShouldAnimate() then
        if widget.SetAlpha then pcall(function() widget:SetAlpha(toA) end) end
        if toA == 0 and widget.Hide then pcall(function() widget:Hide() end) end
        return
    end

    if widget._alphaTween then widget._alphaTween.running = false end
    widget._alphaTween = { running = true }
    local start = GetTime()
    if widget.SetAlpha then pcall(function() widget:SetAlpha(fromA) end) end
    if widget.Show then pcall(function() widget:Show() end) end
    widget:SetScript("OnUpdate", function(self)
        local t = (GetTime() - start) / duration
        if not widget._alphaTween.running then
            self:SetScript("OnUpdate", nil)
            return
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if widget.SetAlpha then pcall(function() widget:SetAlpha(toA) end) end
            widget._alphaTween.running = false
            if toA == 0 and widget.Hide then pcall(function() widget:Hide() end) end
        else
            local a = fromA + (toA - fromA) * t
            if widget.SetAlpha then pcall(function() widget:SetAlpha(a) end) end
        end
    end)
end

-- Horisontal slide-tween: animerer bredden fra fromW til toW
function Anim.AnimateWidth(frame, fromW, toW, duration, onComplete)
    if not frame then
        if onComplete then pcall(onComplete) end
        return
    end
    if duration == nil then duration = 0.18 end
    if duration <= 0 or not Anim.ShouldAnimate() then
        if frame.SetWidth then pcall(function() frame:SetWidth(toW) end) end
        if onComplete then pcall(onComplete) end
        return
    end

    if frame._widthTween then frame._widthTween.running = false end
    frame._widthTween = { running = true }
    local start = GetTime()
    if frame.SetWidth then pcall(function() frame:SetWidth(fromW) end) end
    frame:SetScript("OnUpdate", function(self)
        local t = (GetTime() - start) / duration
        if not frame._widthTween.running then
            self:SetScript("OnUpdate", nil)
            return
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if frame.SetWidth then pcall(function() frame:SetWidth(toW) end) end
            frame._widthTween.running = false
            if onComplete then pcall(onComplete) end
        else
            local eased = (1 - math.cos(t * math.pi)) / 2
            local w = fromW + (toW - fromW) * eased
            if frame.SetWidth then pcall(function() frame:SetWidth(w) end) end
        end
    end)
end

-- ============================================================
-- Keystone-widget: placer et kort eller knap ved `toX` (LEFT offset
-- fra parent section). Animerer fra `fromX` med OUT-smoothing.
-- Bruges af BossHelper.UI.CreateKeystoneWidget til samle/udfolde.
-- ============================================================
function Anim.PlaceKeystoneCard(card, section, fromX, toX, animate, delay)
    if card._ag then card._ag:Stop() end
    if not animate or fromX == toX then
        card:ClearAllPoints()
        card:SetPoint("LEFT", section, "LEFT", toX, 0)
        return
    end
    local cfg = Anim.Config
    card:ClearAllPoints()
    card:SetPoint("LEFT", section, "LEFT", fromX, 0)
    if not card._ag then
        card._ag = card:CreateAnimationGroup()
        card._tr = card._ag:CreateAnimation("Translation")
        card._tr:SetSmoothing(cfg.KEYSTONE_SLIDE_SMOOTHING)
    end
    card._tr:SetDuration(cfg.KEYSTONE_SLIDE_DURATION)
    card._tr:SetStartDelay(delay or 0)
    card._tr:SetOffset(toX - fromX, 0)
    card._ag:SetScript("OnFinished", function()
        card:ClearAllPoints()
        card:SetPoint("LEFT", section, "LEFT", toX, 0)
    end)
    card._ag:Play()
end

-- ============================================================
-- Taktik-rækkepil: glid en række fra sin gamle Y-position til
-- den nye anchor (sat af RefreshLayout).
--   row         – Frame der skal animeres
--   fromYOffset – gammel Y (parent-koordinat) minus ny Y.
--                 Positivt = rækken starter OVENFOR den nye pos.
--                 Negativt = rækken starter NEDENFOR.
-- ============================================================
function Anim.SlideRow(row, fromYOffset, duration)
    if not row or fromYOffset == 0 then return end
    duration = duration or Anim.Config.TACTIC_ROW_SLIDE_DURATION
    if not Anim.ShouldAnimate() then return end

    -- Annuller evt. igangværende tween
    if row._slideTween then row._slideTween.running = false end

    -- Hent den nye anchor som RefreshLayout netop har sat
    local point, relativeTo, relPoint, anchorX, anchorY = row:GetPoint(1)
    if not point then return end

    row._slideTween = { running = true }
    local start = GetTime()

    row:SetScript("OnUpdate", function(self)
        local tween = row._slideTween
        if not tween or not tween.running then
            self:SetScript("OnUpdate", nil)
            return
        end
        local t = (GetTime() - start) / duration
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            tween.running = false
            self:ClearAllPoints()
            self:SetPoint(point, relativeTo, relPoint, anchorX, anchorY)
        else
            -- Ease-out cubic
            local eased = 1 - (1 - t) * (1 - t) * (1 - t)
            local offsetY = fromYOffset * (1 - eased)
            self:ClearAllPoints()
            self:SetPoint(point, relativeTo, relPoint, anchorX, anchorY + offsetY)
        end
    end)
end

-- Flash en FontString's tekstfarve til hvid og tilbage igen (klik-feedback)
function Anim.FlashArrow(fontString, normalR, normalG, normalB)
    if not fontString then return end
    fontString:SetTextColor(1, 1, 1)
    C_Timer.After(0.12, function()
        if fontString and fontString.SetTextColor then
            fontString:SetTextColor(normalR or 0.98, normalG or 0.82, normalB or 0.55)
        end
    end)
end
