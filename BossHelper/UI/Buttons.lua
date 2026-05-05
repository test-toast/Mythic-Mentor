-- Buttons.lua
-- Centraliseret knap-fabrik og styling for BossHelper.
-- Alle knap-typer og deres styling samles her for nem vedligeholdelse.
--
-- Eksponerede funktioner:
--   BossHelper.Buttons.Create(parent, width, height, text)
--       → Standard-knap med backdrop, hover, selected-tilstand og animationer.
--
--   BossHelper.Buttons.CreateNav(parent, xOffset, icon, iconSize,
--                                enterBg, enterBorder, clickFn)
--       → 24×24 ikon-nav-knap forankret til TOPRIGHT (brugt i topmenu).
--
--   BossHelper.Buttons.CreateIconOnly(parent, size, anchorFrame, xOffset,
--                                     texturePath, hoverColor,
--                                     tooltipKey, tooltipDescKey, onClickFn)
--       → Ikon-knap uden backdrop (f.eks. sociale links på startside).

BossHelper         = BossHelper or {}
BossHelper.Buttons = BossHelper.Buttons or {}

local Buttons = BossHelper.Buttons

-- ============================================================
-- Styling-konstanter
-- Justér her for at ændre udseendet på alle knapper på én gang.
-- ============================================================
local S = {
    -- Standard (inaktiv)
    BG_NORMAL       = {0.06, 0.07, 0.11, 1  },
    BORDER_NORMAL   = {0.3,  0.3,  0.3,  0.8},
    TEXT_NORMAL     = {0.98, 0.82, 0.55     },

    -- Hover (ikke valgt)
    BG_HOVER        = {0.15, 0.15, 0.25, 1  },
    BORDER_HOVER    = {1,    0.6,  0.2,  1  },
    TEXT_HOVER      = {1,    0.95, 0.75     },

    -- Valgt (selected)
    BG_SEL          = {1,    0.5,  0,    1  },
    BORDER_SEL      = {1,    0.5,  0,    1  },
    TEXT_SEL        = {1,    1,    1        },

    -- Nav-knap (inaktiv)
    NAV_BG_NORMAL   = {0.08, 0.09, 0.13, 0.95},
    NAV_BORDER_NORMAL = {0.3, 0.3, 0.3, 0.8  },
}

-- ============================================================
-- BossHelper.Buttons.Create
--
-- Opretter en standard backdrop-knap med:
--   • Hover-animationer (zoom + farve-skift)
--   • Selected-tilstand (puls-animation + orange fremhævning)
--   • Valgfrit ikon (venstre-justeret)
--   • btn:SetText(s)       – opdatér label
--   • btn:SetIcon(texture) – sæt eller skjul ikon
--   • btn:SetSelected(bool)– markér/afmarkér som valgt
--
-- parent  = forælderframe
-- width   = bredde i pixel
-- height  = højde i pixel
-- text    = (valgfrit) lokaliseringsnøgle eller tekst-streng
-- ============================================================
function Buttons.Create(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)

    BossHelper.UI.ApplyBackdrop(btn, "BTN", S.BG_NORMAL, S.BORDER_NORMAL)

    -- Content-frame: kun dette skaleres ved hover – baggrunden (backdrop) skalerer ikke.
    local content = CreateFrame("Frame", nil, btn)
    content:SetAllPoints(btn)
    btn.content = content

    -- Label
    local labelText = (Translate and Translate(text)) or text or ""
    btn.text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER", content, "CENTER", 0, 0)
    btn.text:SetText(labelText)
    btn.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])

    -- Ikon-slot (tomt ved start; udfyldes med SetIcon)
    btn.icon = nil

    -- ---- Metoder ----------------------------------------

    --- Sæt eller skjul ikon-tekstur (venstre-justeret, 20×20).
    function btn:SetIcon(texture)
        if not texture then
            if self.icon then self.icon:Hide() end
            return
        end
        if not self.icon then
            local c = self.content or self
            self.icon = c:CreateTexture(nil, "ARTWORK")
            self.icon:SetSize(20, 20)
            self.icon:SetPoint("LEFT", c, "LEFT", 6, 0)
        end
        self.icon:SetTexture(texture)
        self.icon:SetAlpha(1)
        self.icon:Show()
    end

    --- Opdatér knap-teksten.
    function btn:SetText(s)
        if self.text then self.text:SetText(s or "") end
    end

    -- ---- Animationer ------------------------------------
    BossHelper.Anim.ApplyButtonHover(btn)
    local enterAG = btn._enterAG
    local pulseAG = btn._pulseAG

    local function StopAllAnims()
        if enterAG and enterAG:IsPlaying() then enterAG:Stop() end
        if pulseAG and pulseAG:IsPlaying() then pulseAG:Stop() end
    end

    -- ---- Scripts ----------------------------------------

    btn:SetScript("OnEnter", function(self)
        StopAllAnims()
        if enterAG then enterAG:Play() end

        if not self._isSelected then
            self:SetBackdropColor(S.BG_HOVER[1],     S.BG_HOVER[2],     S.BG_HOVER[3],     S.BG_HOVER[4])
            self:SetBackdropBorderColor(S.BORDER_HOVER[1], S.BORDER_HOVER[2], S.BORDER_HOVER[3], S.BORDER_HOVER[4])
            self.text:SetTextColor(S.TEXT_HOVER[1], S.TEXT_HOVER[2], S.TEXT_HOVER[3])
        else
            self:SetBackdropColor(S.BG_SEL[1],     S.BG_SEL[2],     S.BG_SEL[3],     S.BG_SEL[4])
            self:SetBackdropBorderColor(S.BORDER_SEL[1], S.BORDER_SEL[2], S.BORDER_SEL[3], S.BORDER_SEL[4])
            self.text:SetTextColor(S.TEXT_SEL[1], S.TEXT_SEL[2], S.TEXT_SEL[3])
        end
    end)

    btn:SetScript("OnLeave", function(self)
        StopAllAnims()

        if not self._isSelected then
            self:SetBackdropColor(S.BG_NORMAL[1],     S.BG_NORMAL[2],     S.BG_NORMAL[3],     S.BG_NORMAL[4])
            self:SetBackdropBorderColor(S.BORDER_NORMAL[1], S.BORDER_NORMAL[2], S.BORDER_NORMAL[3], S.BORDER_NORMAL[4])
            self.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        else
            self:SetBackdropColor(S.BG_SEL[1],     S.BG_SEL[2],     S.BG_SEL[3],     S.BG_SEL[4])
            self:SetBackdropBorderColor(S.BORDER_SEL[1], S.BORDER_SEL[2], S.BORDER_SEL[3], S.BORDER_SEL[4])
            self.text:SetTextColor(S.TEXT_SEL[1], S.TEXT_SEL[2], S.TEXT_SEL[3])
        end
    end)

    --- Markér knappen som valgt (orange) eller fravalgt (mørk).
    function btn:SetSelected(on)
        self._isSelected = on
        if on then
            self:SetBackdropColor(S.BG_SEL[1],     S.BG_SEL[2],     S.BG_SEL[3],     S.BG_SEL[4])
            self:SetBackdropBorderColor(S.BORDER_SEL[1], S.BORDER_SEL[2], S.BORDER_SEL[3], S.BORDER_SEL[4])
            self.text:SetTextColor(S.TEXT_SEL[1], S.TEXT_SEL[2], S.TEXT_SEL[3])
            if pulseAG then pulseAG:Play() end
        else
            self:SetBackdropColor(S.BG_NORMAL[1],     S.BG_NORMAL[2],     S.BG_NORMAL[3],     S.BG_NORMAL[4])
            self:SetBackdropBorderColor(S.BORDER_NORMAL[1], S.BORDER_NORMAL[2], S.BORDER_NORMAL[3], S.BORDER_NORMAL[4])
            self.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
    end

    btn:SetSelected(false)
    return btn
end

-- ============================================================
-- BossHelper.Buttons.CreateNav
--
-- Opretter en 24×24 ikon-nav-knap forankret til TOPRIGHT af parent.
-- Bruges til settings-, info- og notes-knapper i topmenuen.
--
-- parent      = frame som knappen ankres til TOPRIGHT af
-- xOffset     = horisontal offset fra TOPRIGHT (typisk negativ)
-- icon        = sti til ikon-tekstur
-- iconSize    = ikon-størrelse i pixel
-- enterBg     = {r, g, b} baggrundsfarve ved hover
-- enterBorder = {r, g, b} kantfarve ved hover
-- clickFn     = function() der køres ved klik
-- ============================================================
function Buttons.CreateNav(parent, xOffset, icon, iconSize, enterBg, enterBorder, clickFn)
    local btn = Buttons.Create(parent, 24, 24, "")
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(parent:GetFrameLevel() + 10)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xOffset, -7)

    -- Ikon
    btn.icon = btn:CreateTexture(nil, "OVERLAY")
    btn.icon:SetTexture(icon)
    btn.icon:SetSize(iconSize, iconSize)
    btn.icon:SetPoint("CENTER", btn, "CENTER", 0, 0)

    local col = BossHelper.UI.C.TEXT_ORANGE
    if col then btn.icon:SetVertexColor(unpack(col)) end

    -- Scripts (tilsidesætter dem fra Buttons.Create)
    btn:SetScript("OnClick", clickFn)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(enterBg[1], enterBg[2], enterBg[3], 1)
        self:SetBackdropBorderColor(enterBorder[1], enterBorder[2], enterBorder[3], 1)
        if self.icon then self.icon:SetVertexColor(1, 1, 1, 1) end
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(S.NAV_BG_NORMAL[1],     S.NAV_BG_NORMAL[2],     S.NAV_BG_NORMAL[3],     S.NAV_BG_NORMAL[4])
        self:SetBackdropBorderColor(S.NAV_BORDER_NORMAL[1], S.NAV_BORDER_NORMAL[2], S.NAV_BORDER_NORMAL[3], S.NAV_BORDER_NORMAL[4])
        local iconCol = BossHelper.UI.C.TEXT_ORANGE
        if self.icon and iconCol then self.icon:SetVertexColor(unpack(iconCol)) end
    end)

    return btn
end

-- ============================================================
-- BossHelper.Buttons.CreateIconOnly
--
-- Opretter en ikon-knap uden backdrop.
-- Bruges til sociale links (Discord, GitHub, BugReport) på startsiden.
--
-- parent         = forælderframe
-- size           = knap-størrelse i pixel (kvadratisk)
-- anchorFrame    = frame at forankre til; nil bruger parent som anker
-- xOffset        = horisontal offset
-- texturePath    = sti til ikon-tekstur
-- hoverColor     = {r, g, b} vertex-farve ved hover
-- tooltipKey     = lokaliseringsnøgle til tooltip-titel (kan være nil)
-- tooltipDescKey = lokaliseringsnøgle til tooltip-beskrivelse (kan være nil)
-- onClickFn      = function() der køres ved klik
-- ============================================================
function Buttons.CreateIconOnly(parent, size, anchorFrame, xOffset, texturePath, hoverColor, tooltipKey, tooltipDescKey, onClickFn)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)

    if anchorFrame then
        btn:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", xOffset, 0)
    else
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -10)
    end

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(texturePath)

    btn:SetScript("OnEnter", function(self)
        tex:SetVertexColor(hoverColor[1], hoverColor[2], hoverColor[3])
        if tooltipKey then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(Translate(tooltipKey, 1, 1, 1))
            if tooltipDescKey then
                GameTooltip:AddLine(Translate(tooltipDescKey, 0.8, 0.8, 0.8))
            end
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function()
        tex:SetVertexColor(1, 1, 1)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", onClickFn)
    btn:EnableMouse(true)
    return btn
end
