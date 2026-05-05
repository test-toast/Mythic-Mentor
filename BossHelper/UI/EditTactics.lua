-- EditTactics.lua
-- Redigering af Boss-taktiker - et kort per taktik med fase-dropdown
-- Afhaenger af BossUI.lua (skal loades efter)

-- =====================================================================
-- Konstanter
-- =====================================================================
local MIN_BOX_H  = 40   -- minimum bokshøjde
local LINE_H     = 16
local PAD_V      = 4
local ROW_GAP    = 6
local PLUS_H     = 28
local ROW_W      = 520
local LEFT_MARGIN = 14  -- plads til pile på højre side
local BOX_LEFT = 0      -- afstand fra venstre kant til selve boksen
local BOX_W      = ROW_W - LEFT_MARGIN - 16
local FOOTER_H   = 32
local PHASE_NONE = "No phase"

-- Kortere navne til delte UI-præseter (defineret i BossHelper.lua)
local _B  = BossHelper.UI.Backdrop   -- backdrop-præseter
local _C  = BossHelper.UI.C          -- farvepalette
local _BD = BossHelper.UI.ApplyBackdrop  -- backdrop + farver i ét kald

-- =====================================================================
-- Modul-lokale variable
-- =====================================================================
local tacticRows         = {}
local editContent        = nil
local addRowBtn          = nil
local currentBoss        = nil
local allEntries         = {}   -- alle taktik-entries på tværs af faser
local currentFilterPhase = PHASE_NONE  -- hvilken fase der vises i scrollet

-- =====================================================================
-- GetCustomEntries / SaveCustomEntries
-- =====================================================================
local function GetCustomEntries(dungeon, bossName)
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.customTactics = BossHelperDB.customTactics or {}
    BossHelperDB.customTactics[dungeon] = BossHelperDB.customTactics[dungeon] or {}
    local raw = BossHelperDB.customTactics[dungeon][bossName]
    if raw == nil then return {} end
    if type(raw) == "string" then
        local entries = {}
        for line in raw:gmatch("([^\n]+)") do
            line = line:gsub("^%s+",""):gsub("%s+$","")
            if line ~= "" then table.insert(entries, {phase=PHASE_NONE, text=line}) end
        end
        BossHelperDB.customTactics[dungeon][bossName] = entries
        return entries
    end
    return raw
end

local function SaveCustomEntries(dungeon, bossName, entries)
    BossHelperDB = BossHelperDB or {}
    BossHelperDB.customTactics = BossHelperDB.customTactics or {}
    BossHelperDB.customTactics[dungeon] = BossHelperDB.customTactics[dungeon] or {}
    if #entries == 0 then
        BossHelperDB.customTactics[dungeon][bossName] = nil
    else
        BossHelperDB.customTactics[dungeon][bossName] = entries
    end
end

-- =====================================================================
-- RefreshLayout
-- =====================================================================
local function RefreshLayout()
    if not editContent then return end
    local y = 0
    for i, row in ipairs(tacticRows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", editContent, "TOPLEFT", BOX_LEFT, -y)
        row:Show()
        -- Opdater rækkenummer
        if row.numLabel then
            row.numLabel:SetText(i)
        end
        y = y + row:GetHeight() + ROW_GAP
    end
    if addRowBtn then
        addRowBtn:ClearAllPoints()
        addRowBtn:SetPoint("TOPLEFT", editContent, "TOPLEFT", BOX_LEFT, -y)
        y = y + PLUS_H + ROW_GAP
    end
    editContent:SetHeight(math.max(y, 10))
end

-- =====================================================================
-- RemoveRow
-- =====================================================================
local function RemoveRow(row)
    for i, r in ipairs(tacticRows) do
        if r == row then table.remove(tacticRows, i); break end
    end
    row:Hide()
    row:SetParent(nil)
    RefreshLayout()
end

-- =====================================================================
-- CreatePhaseDropdownWidget
-- =====================================================================
local function CreatePhaseDropdownWidget(parent, boss, initialPhase)
    local selectedPhase = initialPhase or PHASE_NONE

    local mainBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    mainBtn:SetSize(200, 24)
    mainBtn:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=10,
        insets={left=3,right=3,top=3,bottom=3},
    })
    mainBtn:SetBackdropColor(0.06, 0.07, 0.11, 0.95)
    mainBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local mainLabel = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainLabel:SetPoint("LEFT", mainBtn, "LEFT", 6, 0)
    mainLabel:SetPoint("RIGHT", mainBtn, "RIGHT", -18, 0)
    mainLabel:SetJustifyH("LEFT")
    mainLabel:SetTextColor(0.95, 0.85, 0.6)
    mainLabel:SetText(selectedPhase)

    local arrow = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -4, 0)
    arrow:SetText("v")
    arrow:SetTextColor(0.7, 0.7, 0.7)

    local dropPanel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropPanel:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=5,right=5,top=5,bottom=5},
    })
    dropPanel:SetBackdropColor(0.06, 0.07, 0.11, 0.98)
    dropPanel:SetBackdropBorderColor(1, 0.6, 0.2, 0.9)
    dropPanel:SetFrameStrata("TOOLTIP")
    dropPanel:SetFrameLevel(3000)
    dropPanel:Hide()

    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(2999)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function()
        dropPanel:Hide()
        catcher:Hide()
        arrow:SetText("v")
    end)

    mainBtn.GetPhase = function() return selectedPhase end
    mainBtn.SetPhase = function(_, p)
        selectedPhase = p
        mainLabel:SetText(p)
    end

    local function RebuildDropList()
        for _, c in ipairs({dropPanel:GetChildren()}) do c:Hide(); c:SetParent(nil) end
        for _, c in ipairs({dropPanel:GetRegions()}) do
            if c.SetParent then pcall(function() c:SetParent(nil) end) end
        end

        local seen = {}
        local allPhases = { PHASE_NONE }
        seen[PHASE_NONE] = true
        if boss and boss.phases then
            for _, p in ipairs(boss.phases) do
                if not seen[p] then seen[p]=true; table.insert(allPhases, p) end
            end
        end
        for _, row in ipairs(tacticRows) do
            if row.phaseWidget then
                local cp = row.phaseWidget:GetPhase()
                if cp and cp ~= "" and not seen[cp] then
                    seen[cp]=true; table.insert(allPhases, cp)
                end
            end
        end

            local ITEM_H = 22
            local y = 4
            local panelW = 210 + 16

        local function MakeItem(label, onClick)
            local item = CreateFrame("Button", nil, dropPanel)
            item:SetSize(panelW - 8, ITEM_H)
            item:SetPoint("TOPLEFT", dropPanel, "TOPLEFT", 4, -y)
            local itembg = item:CreateTexture(nil, "BACKGROUND")
            itembg:SetAllPoints()
            itembg:SetColorTexture(1, 0.5, 0, 0)
            local fs = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetAllPoints()
            fs:SetJustifyH("LEFT")
            fs:SetText("  "..label)
            fs:SetTextColor(0.9, 0.85, 0.7)
            item:SetScript("OnEnter", function()
                itembg:SetColorTexture(1, 0.5, 0, 0.25)
                fs:SetTextColor(1,0.9,0.4)
            end)
            item:SetScript("OnLeave", function()
                itembg:SetColorTexture(1, 0.5, 0, 0)
                fs:SetTextColor(0.9,0.85,0.7)
            end)
            item:SetScript("OnClick", function()
                onClick(label)
                dropPanel:Hide()
                catcher:Hide()
                arrow:SetText("v")
            end)
            y = y + ITEM_H
            -- separator
            local itemsep = dropPanel:CreateTexture(nil, "ARTWORK")
            itemsep:SetColorTexture(1, 0.5, 0, 0.3)
            itemsep:SetSize(panelW - 12, 1)
            itemsep:SetPoint("TOPLEFT", dropPanel, "TOPLEFT", 6, -y)
            y = y + 3
        end

        for _, p in ipairs(allPhases) do
            MakeItem(p, function(lbl)
                selectedPhase = lbl
                mainLabel:SetText(lbl)
            end)
        end

        -- Separator
        local sep = dropPanel:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(0.3,0.3,0.3,0.5)
        sep:SetSize(panelW-8, 1)
        sep:SetPoint("TOPLEFT", dropPanel, "TOPLEFT", 4, -y)
        y = y + 6

        -- ("Ny fase" label removed)

        -- Input felt til ny fase
        local newBox = CreateFrame("EditBox", nil, dropPanel, "InputBoxTemplate")
        newBox:SetSize(panelW - 20, 20)
        newBox:SetPoint("TOPLEFT", dropPanel, "TOPLEFT", 10, -y)
        newBox:SetAutoFocus(false)
        newBox:SetText("")
        newBox:SetScript("OnEnterPressed", function(self)
            local txt = self:GetText():gsub("^%s+",""):gsub("%s+$","")
            if txt ~= "" then
                selectedPhase = txt
                mainLabel:SetText(txt)
            end
            self:SetText("")
            dropPanel:Hide()
            catcher:Hide()
            arrow:SetText("v")
        end)
        newBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            dropPanel:Hide()
            catcher:Hide()
            arrow:SetText("v")
        end)
        y = y + 28

        dropPanel:SetSize(panelW, y + 4)
    end

    mainBtn:SetScript("OnClick", function()
        if dropPanel:IsShown() then
            dropPanel:Hide()
            catcher:Hide()
            arrow:SetText("v")
        else
            RebuildDropList()
            dropPanel:ClearAllPoints()
            dropPanel:SetPoint("TOPLEFT", mainBtn, "BOTTOMLEFT", 0, -2)
            dropPanel:Show()
            catcher:Show()
            arrow:SetText("^")
        end
    end)

    return mainBtn
end

-- =====================================================================
-- CreateTacticRow
-- =====================================================================
local function CreateTacticRow(entry)
    if not editContent then return end
    entry = entry or { phase=PHASE_NONE, text="" }

    local row = CreateFrame("Frame", nil, editContent, "BackdropTemplate")
    row:SetSize(ROW_W, MIN_BOX_H + FOOTER_H + 12)
    row:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=5,right=5,top=5,bottom=5},
    })
    row:SetBackdropColor(0.06, 0.07, 0.11, 0.95)
    row:SetBackdropBorderColor(1, 0.6, 0.2, 0.6)

    -- Synlig editbox-baggrund (viser tydeligt at man kan skrive her)
    local boxBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
    boxBg:SetPoint("TOPLEFT",     row, "TOPLEFT",     6, -6)
    boxBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6,  FOOTER_H + 2)
    boxBg:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=14,
        insets={left=4,right=4,top=4,bottom=4},
    })
    boxBg:SetBackdropColor(0.02, 0.03, 0.06, 1)
    boxBg:SetBackdropBorderColor(0.12, 0.15, 0.26, 1)

    -- Pladsholder tekst (vises når boksen er tom og ikke fokuseret)
    local placeholder = boxBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 8, -8)
    placeholder:SetText(Translate and Translate("TACTIC_PLACEHOLDER") or "Write tactic here...")
    placeholder:SetTextColor(0.4, 0.4, 0.5, 1)

    -- Multi-line EditBox
    local box = CreateFrame("EditBox", nil, boxBg)
    box:SetFontObject("GameFontNormal")
    box:SetTextColor(0.95, 0.95, 0.95)
    box:SetAutoFocus(false)
    box:SetMultiLine(true)
    box:SetWidth(BOX_W - 24)
    box:SetPoint("TOPLEFT",  boxBg, "TOPLEFT",  6, -6)
    box:SetPoint("TOPRIGHT", boxBg, "TOPRIGHT", -6, -6)
    box:SetText(entry.text or "")
    box:SetCursorPosition(0)

    local function UpdatePlaceholder()
        local txt = box:GetText() or ""
        if txt == "" and not box:HasFocus() then
            placeholder:Show()
        else
            placeholder:Hide()
        end
    end
    UpdatePlaceholder()

    box:SetScript("OnTextChanged", function(self)
        UpdatePlaceholder()
        ResizeRow()
    end)
    box:SetScript("OnEditFocusGained", function(self)
        boxBg:SetBackdropBorderColor(1, 0.6, 0.2, 0.9)
        boxBg:SetBackdropColor(0.08, 0.07, 0.05, 1)
        UpdatePlaceholder()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        boxBg:SetBackdropBorderColor(0.12, 0.15, 0.26, 1)
        boxBg:SetBackdropColor(0.02, 0.03, 0.06, 1)
        UpdatePlaceholder()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local function ResizeRow()
        local numLines = box:GetNumLines() or 1
        if numLines < 1 then numLines = 1 end
        local boxH = math.max(numLines * LINE_H + PAD_V, MIN_BOX_H)
        local totalH = boxH + FOOTER_H + 12
        if math.abs(row:GetHeight() - totalH) > 1 then
            row:SetHeight(totalH)
            RefreshLayout()
        end
    end

    box:SetScript("OnTextChanged", function(self)
        UpdatePlaceholder()
        ResizeRow()
    end)
    C_Timer.After(0, ResizeRow)
    row.editBox = box

    -- Separator linje fjernet: visuel adskillelse mellem tekstfelt og knapper er fjernet

    -- Rolle-toggle knapper (Tank / Healer / DPS)
    -- Bruger samme texture + UV-koordinater som Functions.lua:ReplaceRoleIcons
    local roleData = {
        { tooltip="Tank",   texCoord={0/256, 61/256, 69/256, 130/256} },
        { tooltip="Healer", texCoord={69/256, 130/256, 0/256, 64/256}  },
        { tooltip="DPS",    texCoord={69/256, 130/256, 69/256, 130/256} },
    }
    local BTN_SIZE = 24
    local xOff = 8
    for _, info in ipairs(roleData) do
        local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", xOff, (FOOTER_H + 2 - BTN_SIZE) / 2 + 3)
        btn:SetBackdrop({
            bgFile="Interface/ChatFrame/ChatFrameBackground",
            edgeFile="Interface/Tooltips/UI-Tooltip-Border",
            tile=true, tileSize=16, edgeSize=8,
            insets={left=2,right=2,top=2,bottom=2},
        })
        btn:SetBackdropColor(0.06, 0.07, 0.11, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
        local tc = info.texCoord
        icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        local infoCopy = info
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.25, 1)
            self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(infoCopy.tooltip, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.06, 0.07, 0.11, 0.9)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            GameTooltip:Hide()
        end)
        -- Insert role keyword into the row's editbox at the cursor position
        btn:SetScript("OnClick", function()
            local eb = row.editBox
            if not eb then return end
            local cur = eb:GetText() or ""
            local pos = eb:GetCursorPosition() or #cur
            local newText = cur:sub(1, pos) .. infoCopy.tooltip .. cur:sub(pos + 1)
            eb:SetText(newText)
            eb:SetCursorPosition(pos + #infoCopy.tooltip)
            eb:SetFocus()
        end)
        xOff = xOff + BTN_SIZE + 4
    end

    -- Slet knap
    local delBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
    delBtn:SetSize(60, 22)
    delBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, (FOOTER_H + 2 - 22) / 2 + 3)
    delBtn:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2},
    })
    delBtn:SetBackdropColor(0.35, 0.07, 0.07, 0.9)
    delBtn:SetBackdropBorderColor(0.6, 0.18, 0.18, 0.8)
    local delTxt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delTxt:SetPoint("CENTER")
    delTxt:SetText(Translate and Translate("DELETE") or "Delete")
    delTxt:SetTextColor(1, 0.4, 0.4)
    delBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.55, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        delTxt:SetTextColor(1, 0.8, 0.8)
    end)
    delBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.35, 0.07, 0.07, 0.9)
        self:SetBackdropBorderColor(0.6, 0.18, 0.18, 0.8)
        delTxt:SetTextColor(1, 0.4, 0.4)
    end)
    delBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
        RemoveRow(row)
    end)

    -- ---------------------------------------------------------------
    -- Venstre margin: pil op, rækkenummer, pil ned
    -- (sidder UDENFOR rækken, i mellemrummet til venstre)
    -- ---------------------------------------------------------------
    local arrowUp = CreateFrame("Button", nil, row)
    arrowUp:SetSize(LEFT_MARGIN - 4, 14)
    arrowUp:SetPoint("TOPRIGHT", row, "TOPRIGHT", LEFT_MARGIN - 2, -4)
    local upTxt = arrowUp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    upTxt:SetAllPoints()
    upTxt:SetJustifyH("CENTER")
    upTxt:SetJustifyV("MIDDLE")
    upTxt:SetText("^")
    upTxt:SetTextColor(0.98, 0.82, 0.55)
    arrowUp:SetScript("OnEnter", function() upTxt:SetTextColor(1, 0.9, 0.4) end)
    arrowUp:SetScript("OnLeave", function() upTxt:SetTextColor(0.98, 0.82, 0.55) end)
    arrowUp:SetScript("OnClick", function()
        for i, r in ipairs(tacticRows) do
            if r == row and i > 1 then
                tacticRows[i], tacticRows[i-1] = tacticRows[i-1], tacticRows[i]
                RefreshLayout()
                break
            end
        end
    end)

    local numLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    numLabel:SetPoint("TOPRIGHT",  row, "TOPRIGHT", LEFT_MARGIN - 2, -20)
    numLabel:SetSize(LEFT_MARGIN - 4, 14)
    numLabel:SetJustifyH("CENTER")
    numLabel:SetTextColor(0.98, 0.82, 0.55)
    numLabel:SetText("1")
    row.numLabel = numLabel

    local arrowDown = CreateFrame("Button", nil, row)
    arrowDown:SetSize(LEFT_MARGIN - 4, 14)
    arrowDown:SetPoint("TOPRIGHT", row, "TOPRIGHT", LEFT_MARGIN - 2, -36)
    local downTxt = arrowDown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    downTxt:SetAllPoints()
    downTxt:SetJustifyH("CENTER")
    downTxt:SetJustifyV("MIDDLE")
    downTxt:SetText("v")
    downTxt:SetTextColor(0.98, 0.82, 0.55)
    arrowDown:SetScript("OnEnter", function() downTxt:SetTextColor(1, 0.9, 0.4) end)
    arrowDown:SetScript("OnLeave", function() downTxt:SetTextColor(0.98, 0.82, 0.55) end)
    arrowDown:SetScript("OnClick", function()
        for i, r in ipairs(tacticRows) do
            if r == row and i < #tacticRows then
                tacticRows[i], tacticRows[i+1] = tacticRows[i+1], tacticRows[i]
                RefreshLayout()
                break
            end
        end
    end)

    table.insert(tacticRows, row)
    return row
end

-- =====================================================================
-- RebuildRows
-- =====================================================================
local function RebuildRows(entries)
    for _, row in ipairs(tacticRows) do row:Hide(); row:SetParent(nil) end
    tacticRows = {}
    for _, entry in ipairs(entries) do CreateTacticRow(entry) end
    RefreshLayout()
end

-- =====================================================================
-- SyncVisibleRowsToAllEntries
-- Kopierer de synlige rækker (for currentFilterPhase) tilbage til allEntries
-- =====================================================================
local function SyncVisibleRowsToAllEntries()
    local remaining = {}
    for _, entry in ipairs(allEntries) do
        if entry.phase ~= currentFilterPhase then
            table.insert(remaining, entry)
        end
    end
    for _, row in ipairs(tacticRows) do
        if row.editBox then
            local t = row.editBox:GetText() or ""
            t = t:gsub("^%s+",""):gsub("%s+$","")
            if t ~= "" then
                table.insert(remaining, {phase=currentFilterPhase, text=t})
            end
        end
    end
    allEntries = remaining
end

-- =====================================================================
-- BuildFilteredRows
-- Vis kun entries for den valgte fase (sync sker IKKE her)
-- =====================================================================
local function BuildFilteredRows(phaseName)
    currentFilterPhase = phaseName
    local filtered = {}
    for _, entry in ipairs(allEntries) do
        if entry.phase == phaseName then
            table.insert(filtered, entry)
        end
    end
    RebuildRows(filtered)
end

-- =====================================================================
-- BossUI:HideEditModeUI
-- =====================================================================
function BossUI:HideEditModeUI()
    local rPanel = BossUI.GetRightPanel()
    if not rPanel then return end
    if rPanel.editTacticsPanel  then rPanel.editTacticsPanel:Hide()  end
    if rPanel.editFilterBtn      then rPanel.editFilterBtn:Hide()      end
    if rPanel.saveTacticsBtn     then rPanel.saveTacticsBtn:Hide()     end
    if rPanel.resetTacticsBtn    then rPanel.resetTacticsBtn:Hide()    end
    if rPanel.cancelTacticsBtn   then rPanel.cancelTacticsBtn:Hide()   end
    if rPanel.editTacticsBtn     then rPanel.editTacticsBtn:Hide()     end
end

-- =====================================================================
-- BossUI:EnterEditMode
-- =====================================================================
function BossUI:EnterEditMode()
    local f       = BossUI.GetFrame()
    local rPanel  = BossUI.GetRightPanel()
    local dungeon = BossUI:GetCurrentDungeon()
    if not f or not f.selectedBoss or not dungeon then return end
    local dungeonData = BossData[dungeon]
    if not dungeonData then return end

    local boss = nil
    for _, b in ipairs(dungeonData.bosses) do
        if b == f.selectedBoss then boss = b; break end
    end
    if not boss then return end
    currentBoss = boss

    local entries = GetCustomEntries(dungeon, f.selectedBoss.encounterID)

    if #entries == 0 then
        if boss.phases and #boss.phases > 0 and boss.phaseText then
            for _, phaseName in ipairs(boss.phases) do
                local txt = boss.phaseText[phaseName] or ""
                txt = txt:gsub("^%s+",""):gsub("%s+$","")
                if txt ~= "" then
                    for line in txt:gmatch("([^\n]+)") do
                        line = line:gsub("^%s+",""):gsub("%s+$","")
                        if line ~= "" then
                            table.insert(entries, {phase=phaseName, text=line})
                        end
                    end
                end
            end
        else
            local txt = (boss.short or ""):gsub("\r\n","\n")
            for line in txt:gmatch("([^\n]+)") do
                line = line:gsub("^%s+",""):gsub("%s+$","")
                if line ~= "" then
                    table.insert(entries, {phase=PHASE_NONE, text=line})
                end
            end
        end
    end

    allEntries = entries
    local initPhase
    if currentBoss and currentBoss.phases and #currentBoss.phases > 0 then
        -- Boss har native faser – brug første native fase
        initPhase = currentBoss.phases[1]
    else
        initPhase = (allEntries[1] and allEntries[1].phase) or PHASE_NONE
        if initPhase == "" then initPhase = PHASE_NONE end
    end
    currentFilterPhase = initPhase
    BuildFilteredRows(currentFilterPhase)
    if rPanel.editFilterPhaseWidget then
        rPanel.editFilterPhaseWidget.SetFilterPhase(currentFilterPhase)
    end

    if rPanel.shortBtnScroll            then rPanel.shortBtnScroll:Hide()            end
    if rPanel.phaseDropdown             then rPanel.phaseDropdown:Hide()             end
    if rPanel.phaseDropdownClickCatcher then rPanel.phaseDropdownClickCatcher:Hide() end
    if rPanel.detailToggle              then rPanel.detailToggle:Hide()              end
    if rPanel.postButton                then rPanel.postButton:Hide()                end
    if rPanel.bossNoteButton            then rPanel.bossNoteButton:Hide()            end
    if rPanel.editTacticsBtn            then rPanel.editTacticsBtn:Hide()            end

    if rPanel.editTacticsPanel then rPanel.editTacticsPanel:Show() end
    if rPanel.editFilterBtn     then rPanel.editFilterBtn:Show()     end
    if rPanel.saveTacticsBtn    then rPanel.saveTacticsBtn:Show()    end
    if rPanel.resetTacticsBtn   then rPanel.resetTacticsBtn:Show()   end
    if rPanel.cancelTacticsBtn  then rPanel.cancelTacticsBtn:Show()  end
end

-- =====================================================================
-- BossUI:ExitEditMode
-- =====================================================================
function BossUI:ExitEditMode(saveChanges)
    local f       = BossUI.GetFrame()
    local rPanel  = BossUI.GetRightPanel()
    local dungeon = BossUI:GetCurrentDungeon()
    if not rPanel then return end

    if saveChanges and f and f.selectedBoss and dungeon then
        SyncVisibleRowsToAllEntries()
        SaveCustomEntries(dungeon, f.selectedBoss.encounterID, allEntries)
    end

    for _, row in ipairs(tacticRows) do row:Hide(); row:SetParent(nil) end
    tacticRows = {}
    currentBoss = nil
    allEntries = {}
    currentFilterPhase = PHASE_NONE

    if rPanel.editTacticsPanel then rPanel.editTacticsPanel:Hide() end
    if rPanel.editFilterBtn     then rPanel.editFilterBtn:Hide()     end
    if rPanel.saveTacticsBtn    then rPanel.saveTacticsBtn:Hide()    end
    if rPanel.resetTacticsBtn   then rPanel.resetTacticsBtn:Hide()   end
    if rPanel.cancelTacticsBtn  then rPanel.cancelTacticsBtn:Hide()  end

    if f and f.selectedBoss and dungeon then
        local dungeonData = BossData[dungeon]
        if dungeonData then
            for _, b in ipairs(dungeonData.bosses) do
                if b == f.selectedBoss then
                    BossUI:ShowBoss(rPanel, b)
                    break
                end
            end
        end
        if rPanel.editTacticsBtn then rPanel.editTacticsBtn:Show() end
        if rPanel.detailToggle   then rPanel.detailToggle:Show()   end
        if rPanel.postButton     then rPanel.postButton:Show()     end
        if rPanel.bossNoteButton then rPanel.bossNoteButton:Show() end
    end
end

-- =====================================================================
-- BossUI.GetCustomTacticsText  (bruges af ShowBoss til visning)
-- phaseName=nil  -> returner alle PHASE_NONE entries
-- phaseName=str  -> returner kun entries for den fase
-- =====================================================================
function BossUI.GetCustomTacticsText(dungeon, bossName, phaseName)
    BossHelperDB = BossHelperDB or {}
    local ct = BossHelperDB.customTactics
    if not ct or not ct[dungeon] then return nil end
    local raw = ct[dungeon][bossName]
    if raw == nil then return nil end
    if type(raw) == "string" then return raw end
    local lines = {}
    for _, entry in ipairs(raw) do
        local match = false
        if phaseName == nil then
            match = (entry.phase == PHASE_NONE or entry.phase == nil or entry.phase == "")
        else
            match = (entry.phase == phaseName)
        end
        if match then
            local t = (entry.text or ""):gsub("^%s+",""):gsub("%s+$","")
            if t ~= "" then table.insert(lines, t) end
        end
    end
    if #lines == 0 then return nil end
    return table.concat(lines, "\n")
end

function BossUI.HasCustomTactics(dungeon, bossName)
    BossHelperDB = BossHelperDB or {}
    local ct = BossHelperDB.customTactics
    if not ct or not ct[dungeon] then return false end
    local raw = ct[dungeon][bossName]
    if raw == nil then return false end
    if type(raw) == "string" then return raw ~= "" end
    return #raw > 0
end

-- Returnerer en ordnet liste af distinkte fasenavne fra custom entries
function BossUI.GetCustomPhases(dungeon, bossName)
    BossHelperDB = BossHelperDB or {}
    local ct = BossHelperDB.customTactics
    if not ct or not ct[dungeon] then return {} end
    local raw = ct[dungeon][bossName]
    if raw == nil then return {} end
    if type(raw) == "string" then return {"No phase"} end
    local seen = {}
    local phases = {}
    for _, entry in ipairs(raw) do
        local p = entry.phase or "No phase"
        if p == "" then p = "No phase" end
        if not seen[p] then
            seen[p] = true
            table.insert(phases, p)
        end
    end
    return phases
end

-- =====================================================================
-- BossUI:BuildEditModeUI  (kaldes fra BossUI:CreateUI)
-- =====================================================================
function BossUI:BuildEditModeUI(rPanel)
    local createBtn = BossUI.CreateCustomButton

    -- Blyant-knap
    local editTacticsBtn = createBtn(rPanel, 24, 24, "")
    editTacticsBtn:SetFrameStrata("HIGH")
    editTacticsBtn:SetFrameLevel(rPanel:GetFrameLevel() + 10)
    editTacticsBtn:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 8, -8)
    editTacticsBtn.pencilIcon = editTacticsBtn:CreateTexture(nil, "OVERLAY")
    editTacticsBtn.pencilIcon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
    editTacticsBtn.pencilIcon:SetSize(14, 14)
    editTacticsBtn.pencilIcon:SetPoint("CENTER", editTacticsBtn, "CENTER", 0, 1)
    editTacticsBtn.pencilIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
    editTacticsBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.15, 0.15, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Translate and Translate("EDIT_TACTICS_TOOLTIP") or "Edit Tactics", 1, 0.82, 0.3)
        GameTooltip:Show()
    end)
    editTacticsBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.06, 0.07, 0.11, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        GameTooltip:Hide()
    end)
    editTacticsBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
        ConfirmDialog.Show({
            title   = (Translate and Translate("EDIT_TACTICS_BETA_TITLE")) or "Edit Tactics \u2013 Beta",
            message = (Translate and Translate("EDIT_TACTICS_BETA_MSG")) or "Editing boss tactics is a new feature.\n\nBugs may occur. Your changes are saved locally and do not affect other players.\n\nDo you want to continue?",
            onOk    = function() BossUI:EnterEditMode() end,
        })
    end)
    editTacticsBtn:Hide()
    rPanel.editTacticsBtn = editTacticsBtn

    -- Ydre edit-panel med scroll
    local editTacticsPanel = CreateFrame("Frame", nil, rPanel, "BackdropTemplate")
    editTacticsPanel:SetPoint("TOPLEFT",     rPanel, "TOPLEFT",     8,  -40)
    editTacticsPanel:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -8,  46)
    editTacticsPanel:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=5,right=5,top=5,bottom=5},
    })
    editTacticsPanel:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
    editTacticsPanel:SetBackdropBorderColor(1, 0.6, 0.2, 0.8)
    editTacticsPanel:Hide()
    rPanel.editTacticsPanel = editTacticsPanel

    -- ---------------------------------------------------------------
    -- Fase-filter dropdown (direkte på rPanel, øverst til venstre)
    -- ---------------------------------------------------------------
    local filterBtn = CreateFrame("Button", nil, rPanel, "BackdropTemplate")
    filterBtn:SetSize(140, 26)
    filterBtn:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 8, -8)
    filterBtn:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=10,
        insets={left=3,right=3,top=3,bottom=3},
    })
    filterBtn:SetBackdropColor(0.06, 0.07, 0.11, 0.95)
    filterBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local filterBtnLabel = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterBtnLabel:SetPoint("CENTER", filterBtn, "CENTER", 0, 0)
    filterBtnLabel:SetJustifyH("CENTER")
    filterBtnLabel:SetTextColor(0.95, 0.85, 0.6)
    filterBtnLabel:SetText(PHASE_NONE)

    local filterArrow = filterBtn:CreateTexture(nil, "OVERLAY")
    filterArrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
    filterArrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
    filterArrow:SetSize(20, 10)
    filterArrow:SetPoint("RIGHT", filterBtn, "RIGHT", -8, 0)
    filterBtn.arrow = filterArrow
    filterBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
        filterBtnLabel:SetTextColor(1, 0.9, 0.4)
        if self.arrow then self.arrow:SetVertexColor(1, 0.9, 0.4, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Translate and Translate("FILTER_PHASE_TOOLTIP") or "Filter Phase", 1, 0.82, 0.3)
        GameTooltip:Show()
    end)
    filterBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.06, 0.07, 0.11, 0.95)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        filterBtnLabel:SetTextColor(0.95, 0.85, 0.6)
        if self.arrow then self.arrow:SetVertexColor(0.98, 0.82, 0.55, 0.8) end
        GameTooltip:Hide()
    end)

    local filterDropPanel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    filterDropPanel:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=5,right=5,top=5,bottom=5},
    })
    filterDropPanel:SetBackdropColor(0.06, 0.07, 0.11, 0.98)
    filterDropPanel:SetBackdropBorderColor(1, 0.6, 0.2, 0.9)
    filterDropPanel:SetFrameStrata("TOOLTIP")
    filterDropPanel:SetFrameLevel(3000)
    filterDropPanel:Hide()

    local filterCatcher = CreateFrame("Frame", nil, UIParent)
    filterCatcher:SetAllPoints(UIParent)
    filterCatcher:EnableMouse(true)
    filterCatcher:SetFrameStrata("TOOLTIP")
    filterCatcher:SetFrameLevel(2999)
    filterCatcher:Hide()
    filterCatcher:SetScript("OnMouseDown", function()
        filterDropPanel:Hide()
        filterCatcher:Hide()
        if filterBtn.arrow then filterBtn.arrow:SetRotation(0) end
    end)

    local filterDropDynamicRegions = {}

    local function RebuildFilterDropList()
        for _, c in ipairs({filterDropPanel:GetChildren()}) do c:Hide(); c:SetParent(nil) end
        for _, r in ipairs(filterDropDynamicRegions) do
            if r and r.Hide then r:Hide() end
        end
        filterDropDynamicRegions = {}
        local seen = {}
        local phases = {}
        -- Inkluder native faser fra dungeon-filen
        if currentBoss and currentBoss.phases then
            for _, p in ipairs(currentBoss.phases) do
                if not seen[p] then seen[p]=true; table.insert(phases, p) end
            end
        end
        -- Inkluder ikke-PHASE_NONE custom entries
        for _, entry in ipairs(allEntries) do
            local p = entry.phase or ""
            if p == "" then p = PHASE_NONE end
            if p ~= PHASE_NONE and not seen[p] then seen[p]=true; table.insert(phases, p) end
        end
        -- Inkluder currentFilterPhase hvis den er en rigtig fase (ikke PHASE_NONE)
        if currentFilterPhase ~= PHASE_NONE and not seen[currentFilterPhase] then
            seen[currentFilterPhase] = true
            table.insert(phases, currentFilterPhase)
        end
        -- Hvis ingen rigtige faser eksisterer, vis PHASE_NONE
        if #phases == 0 then
            table.insert(phases, PHASE_NONE)
            seen[PHASE_NONE] = true
        end
        local ITEM_H = 22
        local y = 4
        local panelW = filterBtn:GetWidth() + 16
        for _, p in ipairs(phases) do
            local item = CreateFrame("Button", nil, filterDropPanel)
            item:SetSize(panelW - 8, ITEM_H)
            item:SetPoint("TOPLEFT", filterDropPanel, "TOPLEFT", 4, -y)
            local itembg = item:CreateTexture(nil, "BACKGROUND")
            itembg:SetAllPoints()
            local pCopy = p
            if pCopy == currentFilterPhase then
                itembg:SetColorTexture(1, 0.5, 0, 0.35)
            else
                itembg:SetColorTexture(1, 0.5, 0, 0)
            end
            local fs = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
            fs:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -18, 0)
            fs:SetJustifyH("LEFT")
            fs:SetText("  "..p)
            if pCopy == currentFilterPhase then
                fs:SetTextColor(1, 0.9, 0.4)
            else
                fs:SetTextColor(0.9, 0.85, 0.7)
            end
            item:SetScript("OnEnter", function()
                itembg:SetColorTexture(1, 0.5, 0, 0.25)
                fs:SetTextColor(1,0.9,0.4)
            end)
            item:SetScript("OnLeave", function()
                if pCopy == currentFilterPhase then
                    itembg:SetColorTexture(1, 0.5, 0, 0.35)
                    fs:SetTextColor(1, 0.9, 0.4)
                else
                    itembg:SetColorTexture(1, 0.5, 0, 0)
                    fs:SetTextColor(0.9, 0.85, 0.7)
                end
            end)
            item:SetScript("OnClick", function()
                SyncVisibleRowsToAllEntries()
                -- Tjek om der stadig er rigtige faser tilbage
                local hasNativePhases = currentBoss and currentBoss.phases and #currentBoss.phases > 0
                local hasRealEntries = false
                for _, e in ipairs(allEntries) do
                    local ep = e.phase or ""
                    if ep ~= PHASE_NONE and ep ~= "" then hasRealEntries = true; break end
                end
                local targetPhase = pCopy
                if not hasNativePhases and not hasRealEntries then
                    targetPhase = PHASE_NONE
                end
                BuildFilteredRows(targetPhase)
                filterBtnLabel:SetText(targetPhase)
                filterDropPanel:Hide()
                filterCatcher:Hide()
                if filterBtn.arrow then filterBtn.arrow:SetRotation(0) end
            end)

            -- Slet-knap (X) til højre – kun for rigtige faser, ikke "No phase"
            if pCopy ~= PHASE_NONE then
                local delIcon = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                delIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                delIcon:SetText("X")
                delIcon:SetTextColor(1, 0.2, 0.2)
                delIcon:SetPoint("RIGHT", item, "RIGHT", -4, 0)
                delIcon:Hide()

                local delBtn = CreateFrame("Button", nil, item)
                delBtn:SetSize(18, ITEM_H)
                delBtn:SetPoint("RIGHT", item, "RIGHT", 0, 0)
                delBtn:EnableMouse(true)
                delBtn:SetScript("OnEnter", function()
                    delIcon:Show()
                    delIcon:SetTextColor(1, 1, 1)
                    itembg:SetColorTexture(1, 0.5, 0, 0.25)
                end)
                delBtn:SetScript("OnLeave", function()
                    delIcon:SetTextColor(1, 0.2, 0.2)
                    if pCopy == currentFilterPhase then
                        itembg:SetColorTexture(1, 0.5, 0, 0.35)
                    else
                        itembg:SetColorTexture(1, 0.5, 0, 0)
                    end
                end)

                -- show/hide delete icon when hovering the whole item
                local prevEnter = item:GetScript("OnEnter")
                item:SetScript("OnEnter", function(self)
                    if prevEnter then pcall(prevEnter, self) end
                    delIcon:Show()
                end)
                local prevLeave = item:GetScript("OnLeave")
                item:SetScript("OnLeave", function(self)
                    if prevLeave then pcall(prevLeave, self) end
                    delIcon:Hide()
                end)
                delBtn:SetScript("OnClick", function()
                    filterDropPanel:Hide()
                    filterCatcher:Hide()
                    if filterBtn.arrow then filterBtn.arrow:SetRotation(0) end
                    ConfirmDialog.Show({
                        title   = (Translate and Translate("DELETE_PHASE_TITLE")) or "Delete Phase",
                        message = string.format((Translate and Translate("DELETE_PHASE_MSG")) or "Are you sure you want to delete the phase '%s' and all its tactics?\n\nThis cannot be undone.", pCopy),
                        onOk    = function()
                        SyncVisibleRowsToAllEntries()
                        local remaining = {}
                        for _, entry in ipairs(allEntries) do
                            local ep = entry.phase or PHASE_NONE
                            if ep == "" then ep = PHASE_NONE end
                            if ep ~= pCopy then
                                table.insert(remaining, entry)
                            end
                        end
                        allEntries = remaining
                        -- Find næste fase at vise
                        local nextPhase = PHASE_NONE
                        local hasNative = currentBoss and currentBoss.phases and #currentBoss.phases > 0
                        if hasNative then
                            for _, np in ipairs(currentBoss.phases) do
                                if np ~= pCopy then nextPhase = np; break end
                            end
                        else
                            for _, entry in ipairs(allEntries) do
                                local ep = entry.phase or PHASE_NONE
                                if ep ~= PHASE_NONE and ep ~= "" then
                                    nextPhase = ep; break
                                end
                            end
                        end
                        BuildFilteredRows(nextPhase)
                        filterBtnLabel:SetText(nextPhase)
                        end,
                    })
                end)
            end

            y = y + ITEM_H
            -- separator
            local itemsep = filterDropPanel:CreateTexture(nil, "ARTWORK")
            itemsep:SetColorTexture(1, 0.5, 0, 0.3)
            itemsep:SetSize(panelW - 12, 1)
            itemsep:SetPoint("TOPLEFT", filterDropPanel, "TOPLEFT", 6, -y)
            table.insert(filterDropDynamicRegions, itemsep)
            y = y + 3
        end

        -- Separator
        local sep = filterDropPanel:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        sep:SetSize(panelW - 8, 1)
        sep:SetPoint("TOPLEFT", filterDropPanel, "TOPLEFT", 4, -y)
        table.insert(filterDropDynamicRegions, sep)
        y = y + 6

        -- ("Ny fase:" label removed)

        -- Input felt til ny fase
        local newBox = CreateFrame("EditBox", nil, filterDropPanel, "InputBoxTemplate")
        newBox:SetSize(panelW - 20, 20)
        newBox:SetPoint("TOPLEFT", filterDropPanel, "TOPLEFT", 10, -y)
        newBox:SetAutoFocus(false)
        newBox:SetText("")
            local function CommitNewPhase(self)
            local txt = self:GetText():gsub("^%s+",""):gsub("%s+$","")
            if txt ~= "" then
                SyncVisibleRowsToAllEntries()
                -- Flyt PHASE_NONE entries over i den nye fase (første rigtige fase)
                if currentFilterPhase == PHASE_NONE then
                    for _, entry in ipairs(allEntries) do
                        local p = entry.phase or ""
                        if p == PHASE_NONE or p == "" then
                            entry.phase = txt
                        end
                    end
                end
                BuildFilteredRows(txt)
                filterBtnLabel:SetText(txt)
            end
            self:SetText("")
            filterDropPanel:Hide()
            filterCatcher:Hide()
                if filterBtn.arrow then filterBtn.arrow:SetRotation(0) end
        end
        newBox:SetScript("OnEnterPressed", CommitNewPhase)
        newBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            filterDropPanel:Hide()
            filterCatcher:Hide()
            if filterBtn.arrow then filterBtn.arrow:SetRotation(0) end
        end)
        y = y + 28

        filterDropPanel:SetSize(panelW, y + 4)
    end

    filterBtn:SetScript("OnClick", function()
        if filterDropPanel:IsShown() then
            filterDropPanel:Hide()
            filterCatcher:Hide()
            filterArrow:SetText("v")
        else
            RebuildFilterDropList()
            filterDropPanel:ClearAllPoints()
            filterDropPanel:SetPoint("TOPLEFT", filterBtn, "BOTTOMLEFT", 0, -2)
            filterDropPanel:Show()
            filterCatcher:Show()
            if filterBtn.arrow then filterBtn.arrow:SetRotation(math.pi) end
        end
    end)

    filterBtn.SetFilterPhase = function(p)
        filterBtnLabel:SetText(p or PHASE_NONE)
    end
    rPanel.editFilterPhaseWidget = filterBtn
    filterBtn:Hide()
    rPanel.editFilterBtn = filterBtn

    -- ---------------------------------------------------------------
    -- Scroll-frame (starter under filter-headeren)
    -- ---------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, editTacticsPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     editTacticsPanel, "TOPLEFT",     6, -6)
    scroll:SetPoint("BOTTOMRIGHT", editTacticsPanel, "BOTTOMRIGHT", -26,  6)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(ROW_W + LEFT_MARGIN)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    editContent = content

    local plusBtn = createBtn(content, ROW_W, PLUS_H, (Translate and Translate("ADD_TACTIC_BTN")) or "+ Add Tactic")
    plusBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
        CreateTacticRow({phase=currentFilterPhase, text=""})
        RefreshLayout()
        local last = tacticRows[#tacticRows]
        if last and last.editBox then
            C_Timer.After(0.05, function()
                if last.editBox then last.editBox:SetFocus() end
            end)
        end
    end)
    addRowBtn = plusBtn

    -- Gem
    local saveTacticsBtn = createBtn(rPanel, 100, 34, (Translate and Translate("SAVE")) or "Save")
    saveTacticsBtn:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -10, 10)
    saveTacticsBtn:SetScript("OnClick", function()
        if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
        BossUI:ExitEditMode(true)
    end)
    saveTacticsBtn:Hide()
    rPanel.saveTacticsBtn = saveTacticsBtn

    -- Nulstil
    local resetTacticsBtn = createBtn(rPanel, 100, 34, (Translate and Translate("RESET")) or "Reset")
    resetTacticsBtn:SetPoint("BOTTOMLEFT", rPanel, "BOTTOMLEFT", 10, 10)
    -- Use HookScript so we keep CreateCustomButton's hover animations
    resetTacticsBtn:HookScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.6, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    resetTacticsBtn:SetScript("OnClick", function()
        local f       = BossUI.GetFrame()
        local dungeon = BossUI:GetCurrentDungeon()
        if not f or not f.selectedBoss or not dungeon then return end
        ConfirmDialog.Show({
            title   = (Translate and Translate("RESET_TACTICS_TITLE")) or "Reset Tactics",
            message = (Translate and Translate("RESET_TACTICS_MSG")) or "Are you sure you want to reset all tactics for this boss?\n\nThis cannot be undone.",
            onOk    = function()
                SaveCustomEntries(dungeon, f.selectedBoss, {})
                if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                BossUI:ExitEditMode(false)
            end,
        })
    end)
    resetTacticsBtn:Hide()
    rPanel.resetTacticsBtn = resetTacticsBtn

    -- Annuller
    local cancelTacticsBtn = createBtn(rPanel, 100, 34, (Translate and Translate("CANCEL")) or "Cancel")
    cancelTacticsBtn:SetPoint("BOTTOMRIGHT", rPanel.saveTacticsBtn, "BOTTOMLEFT", -6, 0)
    cancelTacticsBtn:SetScript("OnClick", function()
        -- Tjek om der er ændringer ved at sammenligne nuværende rækker med gemt state
        local hasChanges = false
        local f       = BossUI.GetFrame()
        local dungeon = BossUI:GetCurrentDungeon()
        if f and f.selectedBoss and dungeon then
            SyncVisibleRowsToAllEntries()
            local saved = GetCustomEntries(dungeon, f.selectedBoss)
            if #saved ~= #allEntries then
                hasChanges = true
            else
                for i, entry in ipairs(allEntries) do
                    local s = saved[i]
                    if not s or s.text ~= entry.text or s.phase ~= entry.phase then
                        hasChanges = true; break
                    end
                end
            end
        end
        if hasChanges then
            ConfirmDialog.Show({
                title   = (Translate and Translate("UNSAVED_CHANGES_TITLE")) or "Unsaved Changes",
                message = (Translate and Translate("UNSAVED_CHANGES_MSG")) or "You have unsaved changes.\n\nAre you sure you want to cancel without saving?",
                onOk    = function()
                    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
                    BossUI:ExitEditMode(false)
                end,
            })
        else
            if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(BossHelper.Sounds.NORMAL_BUTTON) end
            BossUI:ExitEditMode(false)
        end
    end)
    cancelTacticsBtn:Hide()
    rPanel.cancelTacticsBtn = cancelTacticsBtn
end