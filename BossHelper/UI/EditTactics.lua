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

local math_max = math.max
local math_abs = math.abs
local math_pi = math.pi
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format

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

-- Shared state for the phase-filter dropdown (populated by CreatePhaseFilterWidget)
local PhaseFilter = { btn=nil, label=nil, arrow=nil, panel=nil, catcher=nil, regions={} }

-- =====================================================================
-- Phase filter dropdown helpers (used by RebuildFilterDropList)
-- =====================================================================
local function CloseFilterDrop()
    if PhaseFilter.panel   then PhaseFilter.panel:Hide()          end
    if PhaseFilter.catcher then PhaseFilter.catcher:Hide()        end
    if PhaseFilter.arrow   then PhaseFilter.arrow:SetRotation(0)  end
end

local function SetFilterLabel(phase)
    if PhaseFilter.label then PhaseFilter.label:SetText(phase or PHASE_NONE) end
end

-- =====================================================================
-- Shared helpers
-- =====================================================================
local function SafePlay(sound)
    if BossHelper and BossHelper.SafePlaySound then BossHelper:SafePlaySound(sound) end
end
local function SetColors(frame, bg, border)
    if bg     then frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4]) end
    if border then frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4]) end
end

-- =====================================================================
-- Kortere alias til EditModeLogic for intern brug
-- =====================================================================
local L = BossHelper.EditModeLogic

-- =====================================================================
-- RefreshLayout
-- =====================================================================
local function RefreshLayout()
    if not editContent then return end
    local y = 0
    for i, row in ipairs(tacticRows) do
        -- Annuller evt. igangværende slide-tween før vi sætter ny anchor
        if row._slideTween then row._slideTween.running = false end
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
    editContent:SetHeight(math_max(y, 10))
end

-- =====================================================================
-- RemoveRow
-- =====================================================================
local function RemoveRow(row)
    for i, r in ipairs(tacticRows) do
        if r == row then table_remove(tacticRows, i); break end
    end
    row:Hide()
    row:SetParent(nil)
    RefreshLayout()
end

-- =====================================================================
-- =====================================================================
-- CreateTacticRow
-- =====================================================================

local function MoveTacticRow(row, dir, flashTxt)
    for i, r in ipairs(tacticRows) do
        if r == row then
            local targetIdx = i + dir
            if targetIdx >= 1 and targetIdx <= #tacticRows then
                local otherRow = tacticRows[targetIdx]
                local _, _, _, _, rowOldY = row:GetPoint(1)
                local _, _, _, _, otherOldY = otherRow:GetPoint(1)
                BossHelper.Anim.FlashArrow(flashTxt)
                tacticRows[i], tacticRows[targetIdx] = tacticRows[targetIdx], tacticRows[i]
                RefreshLayout()
                local _, _, _, _, rowNewY = row:GetPoint(1)
                local _, _, _, _, otherNewY = otherRow:GetPoint(1)
                BossHelper.Anim.SlideRow(row, rowOldY - rowNewY)
                BossHelper.Anim.SlideRow(otherRow, otherOldY - otherNewY)
            end
            break
        end
    end
end

local function CreateRowRoleButtons(row)
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
        _BD(btn, "SMALL", _C.BG_DARK_90, _C.BORDER_GREY)
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
            SetColors(self, _C.BG_DARK_90, _C.BORDER_GREY)
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

end

local function CreateRowDeleteButton(row)
    -- Slet knap
    local delBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
    delBtn:SetSize(60, 22)
    delBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, (FOOTER_H + 2 - 22) / 2 + 3)
    _BD(delBtn, "SMALL", _C.BG_RED, _C.BORDER_RED)
    local delTxt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delTxt:SetPoint("CENTER")
    delTxt:SetText(Translate("DELETE"))
    delTxt:SetTextColor(1, 0.4, 0.4)
    delBtn:SetScript("OnEnter", function(self)
        SetColors(self, {0.55, 0.1, 0.1, 1}, {1, 0.3, 0.3, 1})
        delTxt:SetTextColor(1, 0.8, 0.8)
    end)
    delBtn:SetScript("OnLeave", function(self)
        SetColors(self, _C.BG_RED, _C.BORDER_RED)
        delTxt:SetTextColor(1, 0.4, 0.4)
    end)
    delBtn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        RemoveRow(row)
    end)

end

local function CreateRowArrowButtons(row)
    -- ---------------------------------------------------------------
    -- ---------------------------------------------------------------
    -- Venstre margin: pil op, rækkenummer, pil ned
    -- ---------------------------------------------------------------
    local function CreateArrowInfo(parent, yOffset, display, dir)
        local btn = CreateFrame('Button', nil, parent)
        btn:SetSize(LEFT_MARGIN - 4, 14)
        btn:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', LEFT_MARGIN - 2, yOffset)
        local txt = btn:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        txt:SetAllPoints()
        txt:SetJustifyH('CENTER')
        txt:SetJustifyV('MIDDLE')
        txt:SetText(display)
        txt:SetTextColor(0.98, 0.82, 0.55)
        btn:SetScript('OnEnter', function() txt:SetTextColor(1, 0.9, 0.4) end)
        btn:SetScript('OnLeave', function() txt:SetTextColor(0.98, 0.82, 0.55) end)
        btn:SetScript('OnClick', function() MoveTacticRow(parent, dir, txt) end)
        return btn
    end

    CreateArrowInfo(row, -4, '^', -1)

    local numLabel = row:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    numLabel:SetPoint('TOPRIGHT', row, 'TOPRIGHT', LEFT_MARGIN - 2, -20)
    numLabel:SetSize(LEFT_MARGIN - 4, 14)
    numLabel:SetJustifyH('CENTER')
    numLabel:SetTextColor(0.98, 0.82, 0.55)
    numLabel:SetText('1')
    row.numLabel = numLabel

    CreateArrowInfo(row, -36, 'v', 1)

end

local function CreateTacticRow(entry)
    if not editContent then return end
    entry = entry or { phase=PHASE_NONE, text="" }

    local row = CreateFrame("Frame", nil, editContent, "BackdropTemplate")
    row:SetSize(ROW_W, MIN_BOX_H + FOOTER_H + 12)
    _BD(row, "FRAME", _C.BG_DARK, _C.BORDER_ORANGE)

    -- Synlig editbox-baggrund (viser tydeligt at man kan skrive her)
    local boxBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
    boxBg:SetPoint("TOPLEFT",     row, "TOPLEFT",     6, -6)
    boxBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6,  FOOTER_H + 2)
    _BD(boxBg, "EDITBOX", _C.BG_VERY_DARK, _C.BORDER_DARK_BLUE)

    -- Pladsholder tekst (vises når boksen er tom og ikke fokuseret)
    local placeholder = boxBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 8, -8)
    placeholder:SetText(Translate("TACTIC_PLACEHOLDER"))
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

    box:SetScript("OnEditFocusGained", function()
        SetColors(boxBg, _C.BG_FOCUSED, _C.BORDER_ORANGE_BRIGHT)
        UpdatePlaceholder()
    end)
    box:SetScript("OnEditFocusLost", function()
        SetColors(boxBg, _C.BG_VERY_DARK, _C.BORDER_DARK_BLUE)
        UpdatePlaceholder()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local function ResizeRow()
        local numLines = box:GetNumLines() or 1
        if numLines < 1 then numLines = 1 end
        local boxH = math_max(numLines * LINE_H + PAD_V, MIN_BOX_H)
        local totalH = boxH + FOOTER_H + 12
        if math_abs(row:GetHeight() - totalH) > 1 then
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

    CreateRowRoleButtons(row)
    CreateRowDeleteButton(row)

    CreateRowArrowButtons(row)

    table_insert(tacticRows, row)
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
            table_insert(remaining, entry)
        end
    end
    for _, row in ipairs(tacticRows) do
        if row.editBox then
            local t = L.Trim(row.editBox:GetText())
            if t ~= "" then
                table_insert(remaining, {phase=currentFilterPhase, text=t})
            end
        end
    end
    allEntries = remaining
end

function BossUI:SyncStagedTactics()
    if BossUI.isInEditMode and currentBoss then
        SyncVisibleRowsToAllEntries()
        BossUI.stagedTactics[currentBoss.encounterID] = allEntries
    end
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
            table_insert(filtered, entry)
        end
    end
    RebuildRows(filtered)
end

-- =====================================================================
-- BossUI:HasUnsavedChanges
-- =====================================================================
function BossUI:HasUnsavedChanges()
    if not BossUI.isInEditMode then return false end
    if BossUI.stagedOrder then return true end

    local f       = BossUI.GetFrame()
    local dungeon = BossUI:GetCurrentDungeon()
    if not dungeon then return false end
    
    if f and f.selectedBoss then
        SyncVisibleRowsToAllEntries()
        BossUI.stagedTactics[f.selectedBoss.encounterID] = allEntries
    end
    
    -- Sammenlign alle staged tactics med DB
    for encID, tactics in pairs(BossUI.stagedTactics or {}) do
        local saved = L.GetCustomEntries(dungeon, encID)
        if #saved ~= #tactics then return true end
        for i, entry in ipairs(tactics) do
            local s = saved[i]
            if not s or s.text ~= entry.text or s.phase ~= entry.phase then
                return true
            end
        end
    end
    
    return false
end

-- =====================================================================
-- BossUI:AttemptActionWithUnsavedChanges
-- =====================================================================
function BossUI:AttemptActionWithUnsavedChanges(callback, skipRefresh)
    if not BossUI.isInEditMode then
        callback()
        return
    end

    if BossUI:HasUnsavedChanges() then
        ConfirmDialog.Show({
            title   = Translate("UNSAVED_CHANGES_TITLE"),
            message = Translate("UNSAVED_CHANGES_MSG"),
            onOk    = function()
                SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
                BossUI:ExitEditMode(false, skipRefresh)
                callback()
            end,
        })
    else
        BossUI:ExitEditMode(false, skipRefresh)
        callback()
    end
end

-- Helper: Toggle boss list styling (widen/shrink, show drag handles)
local function ToggleBossListEditState(isEditing)
    local f = BossUI.GetFrame()
    if not f then return end
    if f.resetOrderBtn then f.resetOrderBtn:SetShown(isEditing) end
    if f.bossButtons then
        local btnW = isEditing and 170 or 180
        local xOff = isEditing and -5 or 0
        local p    = f.leftPanel
        for _, btn in ipairs(f.bossButtons) do
            btn:SetWidth(btnW)
            local _, _, _, _, y = btn:GetPoint(1)
            btn:SetPoint("TOP", p or btn:GetParent(), "TOP", xOff, y)
            if btn.dragGrip then btn.dragGrip:SetShown(isEditing) end
        end
    end
end

-- =====================================================================
-- BossUI:HideEditModeUI
-- =====================================================================
function BossUI:HideEditModeUI()
    local rPanel = BossUI.GetRightPanel()
    if not rPanel then return end
    for _, key in ipairs({"editTacticsPanel","editFilterBtn","saveTacticsBtn","resetTacticsBtn","cancelTacticsBtn","editTacticsBtn"}) do
        BossHelper.UI.hide(rPanel[key])
    end

    BossUI.isInEditMode = false
    ToggleBossListEditState(false)
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

    if rPanel and rPanel.rightTitle then
        local editTitle = BossHelper:GetBossName(boss.encounterID) or Translate("UNKNOWN_BOSS")
        if BossHelper.Anim and BossHelper.Anim.CrossfadeText then
            BossHelper.Anim.CrossfadeText(rPanel.rightTitle, editTitle)
        else
            rPanel.rightTitle:SetText(editTitle)
        end
        rPanel.rightTitle:SetTextColor(1, 0.5, 0) -- orange color
    end

    -- Luk boss notes panel hvis det er åbent (brug animeret close hvis muligt)
    if BossUI and BossUI.CloseBossNotePanelIfOpen then
        BossUI.CloseBossNotePanelIfOpen()
    else
        if f.bossNotePanel and f.bossNotePanel:IsShown() then
            f.bossNotePanel:Hide()
            if rPanel and rPanel.bossNoteButton then
                rPanel.bossNoteButton:SetText(Translate("BOSS_NOTES") or "Boss Notes")
            end
        end
    end

    if not BossUI.isInEditMode then
        BossUI.stagedTactics = {}
        BossUI.stagedOrder = nil
        BossUI.isInEditMode = true
    end

    local entries = nil
    if BossUI.stagedTactics[f.selectedBoss.encounterID] then
        entries = BossUI.stagedTactics[f.selectedBoss.encounterID]
    else
        local dbEntries = L.GetCustomEntries(dungeon, f.selectedBoss.encounterID)
        entries = {}
        if dbEntries then
            for _, e in ipairs(dbEntries) do
                table_insert(entries, {phase=e.phase, text=e.text})
            end
        end
        BossUI.stagedTactics[f.selectedBoss.encounterID] = entries
    end

    if #entries == 0 then
        if boss.phases and #boss.phases > 0 and boss.phaseText then
            for _, phaseName in ipairs(boss.phases) do
                local parsed = L.LoadEntriesFromString(boss.phaseText[phaseName] or "", phaseName)
                for _, e in ipairs(parsed) do table_insert(entries, e) end
            end
        else
            local rawTxt = (boss.short or ""):gsub("\r\n","\n")
            local parsed = L.LoadEntriesFromString(rawTxt, PHASE_NONE)
            for _, e in ipairs(parsed) do table_insert(entries, e) end
        end
    end

    allEntries = entries

    local presentInEntries = {}
    for _, e in ipairs(allEntries) do
        local p = e.phase or PHASE_NONE
        if p == "" then p = PHASE_NONE end
        presentInEntries[p] = true
    end

    local initPhase = nil
    if currentBoss and currentBoss.phases then
        for _, p in ipairs(currentBoss.phases) do
            if presentInEntries[p] then
                initPhase = p
                break
            end
        end
    end
    if not initPhase then
        for _, e in ipairs(allEntries) do
            local p = e.phase or PHASE_NONE
            if p ~= "" and p ~= PHASE_NONE then
                initPhase = p
                break
            end
        end
    end
    if not initPhase then 
        initPhase = PHASE_NONE 
    end
    
    currentFilterPhase = initPhase
    BuildFilteredRows(currentFilterPhase)
    if rPanel.editFilterPhaseWidget then
        rPanel.editFilterPhaseWidget.SetFilterPhase(currentFilterPhase)
    end

    for _, key in ipairs({"shortBtnScroll","phaseDropdown","phaseDropdownClickCatcher","detailToggle","postButton","bossNoteButton","editTacticsBtn"}) do
        BossHelper.UI.hide(rPanel[key])
    end
    for _, key in ipairs({"editTacticsPanel","editFilterBtn","saveTacticsBtn","resetTacticsBtn","cancelTacticsBtn"}) do
        if rPanel[key] then rPanel[key]:Show() end
    end

    BossUI.isInEditMode = true
    ToggleBossListEditState(true)
end

-- =====================================================================
-- BossUI:ExitEditMode
-- =====================================================================
function BossUI:ExitEditMode(saveChanges, skipRefresh)
    local f       = BossUI.GetFrame()
    local rPanel  = BossUI.GetRightPanel()
    local dungeon = BossUI:GetCurrentDungeon()
    if not rPanel then return end

    if saveChanges and dungeon then
        if f and f.selectedBoss then
            SyncVisibleRowsToAllEntries()
            BossUI.stagedTactics[f.selectedBoss.encounterID] = allEntries
        end

        for encID, tactics in pairs(BossUI.stagedTactics or {}) do
            L.SaveCustomEntries(dungeon, encID, tactics)
        end
        
        if BossUI.stagedOrder then
            local db = BossHelperDB or {}
            db.customBossOrders = db.customBossOrders or {}
            db.customBossOrders[dungeon] = (#BossUI.stagedOrder > 0) and BossUI.stagedOrder or nil
        end
    end

    local hadStagedOrder = (BossUI.stagedOrder ~= nil)
    BossUI.stagedTactics = nil
    BossUI.stagedOrder = nil
    
    if hadStagedOrder and BossHelper and BossHelper.MiniWindow and BossHelper.MiniWindow.Refresh then
        BossHelper.MiniWindow.Refresh()
    end

    BossUI:HideEditModeUI()

    for _, row in ipairs(tacticRows) do row:Hide(); row:SetParent(nil) end
    tacticRows = {}
    currentBoss = nil
    allEntries = {}
    currentFilterPhase = PHASE_NONE

    if f and dungeon and not skipRefresh then
        local dungeonName = BossUI:GetCurrentDungeon()
        -- Genindlæs rækkefølge
        if ShowBosses and dungeonName then 
            ShowBosses(dungeonName) 
        end
        
        if f.selectedBoss then
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
end

-- =====================================================================
-- BossUI.GetCustomTacticsText  (bruges af ShowBoss til visning)
-- phaseName=nil  -> returner alle PHASE_NONE entries
-- phaseName=str  -> returner kun entries for den fase
-- =====================================================================
function BossUI.GetCustomTacticsText(dungeon, bossName, phaseName)
    return L.GetCustomTacticsText(dungeon, bossName, phaseName)
end

function BossUI.HasCustomTactics(dungeon, bossName)
    return L.HasCustomTactics(dungeon, bossName)
end

-- Returnerer en ordnet liste af distinkte fasenavne fra custom entries
function BossUI.GetCustomPhases(dungeon, bossName)
    return L.GetCustomPhases(dungeon, bossName)
end

-- =====================================================================
-- Phase Filter Dropdown – helper: one list item
-- =====================================================================
local function CreatePhaseItem(parent, pCopy, y, panelW, index)
    local btn = BossUI.CreateCustomButton(parent, panelW, 26, pCopy)
    btn:SetPoint("TOP", parent, "TOP", 0, -y)

    local isSelected = (pCopy == currentFilterPhase)
    if btn.SetSelected then
        btn:SetSelected(isSelected)
    end

    -- Slet knap (valgfri) for reelle faser
    if pCopy ~= PHASE_NONE then
        local delIcon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        delIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        delIcon:SetText("X")
        delIcon:SetTextColor(1, 0.2, 0.2)
        delIcon:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
        delIcon:Hide()

        local delBtn = CreateFrame("Button", nil, btn)
        delBtn:SetSize(20, 26)
        delBtn:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        delBtn:EnableMouse(true)
        delBtn:SetScript("OnEnter", function()
            -- Ligesom btn:OnEnter i CustomButton
            btn:SetBackdropColor(0.15, 0.15, 0.25, 1)
            btn:SetBackdropBorderColor(1, 0.6, 0.2, 1)
            btn.text:SetTextColor(1, 1, 1)
            delIcon:Show()
            delIcon:SetTextColor(1, 1, 1)
        end)
        delBtn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.06, 0.07, 0.11, 1)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            btn.text:SetTextColor(0.98, 0.82, 0.55)
            delIcon:SetTextColor(1, 0.2, 0.2)
            delIcon:Hide()
        end)
        delBtn:SetScript("OnClick", function()
            CloseFilterDrop()
            ConfirmDialog.Show({
                title   = Translate("DELETE_PHASE_TITLE"),
                message = string_format(Translate("DELETE_PHASE_MSG"), pCopy),
                onOk    = function()
                    SyncVisibleRowsToAllEntries()
                    local remaining = {}
                    for _, entry in ipairs(allEntries) do
                        local ep = entry.phase or PHASE_NONE
                        if ep == "" then ep = PHASE_NONE end
                        if ep ~= pCopy then table_insert(remaining, entry) end
                    end
                    allEntries = remaining
                    local nextPhase = PHASE_NONE
                    for _, entry in ipairs(allEntries) do
                        local ep = entry.phase or PHASE_NONE
                        if ep ~= PHASE_NONE and ep ~= "" then nextPhase = ep; break end
                    end
                    BuildFilteredRows(nextPhase)
                    SetFilterLabel(nextPhase)
                end,
            })
        end)

        btn:HookScript("OnEnter", function() delIcon:Show() end)
        btn:HookScript("OnLeave", function() delIcon:Hide() end)
    end

    btn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        SyncVisibleRowsToAllEntries()
        local hasReal   = false
        for _, e in ipairs(allEntries) do
            local ep = e.phase or ""
            if ep ~= PHASE_NONE and ep ~= "" then hasReal = true; break end
        end
        local target = (not hasReal) and PHASE_NONE or pCopy
        BuildFilteredRows(target)
        SetFilterLabel(target)
        CloseFilterDrop()
    end)

    return btn, 26
end

-- =====================================================================
-- Phase Filter Dropdown – helper: "New Phase" knap i bunden
-- =====================================================================
local function CreateNewPhaseButton(parent, panelW, y)
    local btn = BossUI.CreateCustomButton(parent, panelW, 26, "+ " .. (Translate("NEW_PHASE") or "New Phase"))
    btn:SetPoint("TOP", parent, "TOP", 0, -y)
    btn.text:SetTextColor(0.4, 0.9, 0.4)

    btn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        CloseFilterDrop()
        ConfirmDialog.Show({
            title   = Translate("NEW_PHASE") or "New Phase",
            message = Translate("NEW_PHASE_MSG") or "Enter the name of the new phase:",
            isInput = true,
            onOk    = function(txt)
                txt = L.Trim(txt or "")
                if txt ~= "" then
                    SyncVisibleRowsToAllEntries()
                    
                    -- Tjek om vi kun har "No Phase", og flyt taktikker i så fald
                    local hasOtherPhases = false
                    for _, entry in ipairs(allEntries) do
                        local ep = entry.phase or ""
                        if ep ~= PHASE_NONE and ep ~= "" then
                            hasOtherPhases = true
                            break
                        end
                    end

                    if not hasOtherPhases then
                        for _, entry in ipairs(allEntries) do
                            local p = entry.phase or ""
                            if p == PHASE_NONE or p == "" then entry.phase = txt end
                        end
                    end

                    BuildFilteredRows(txt)
                    SetFilterLabel(txt)
                end
            end,
        })
    end)
    return btn, y + 26
end

-- =====================================================================
-- Phase Filter Dropdown – rebuild list (module-level, uses PhaseFilter)
-- =====================================================================
local function RebuildFilterDropList()
    local panel   = PhaseFilter.panel
    local panelW  = 140

    -- Clear previous contents
    for _, c in ipairs({panel:GetChildren()}) do c:Hide(); c:SetParent(nil) end
    for _, r in ipairs(PhaseFilter.regions) do if r and r.Hide then r:Hide() end end
    PhaseFilter.regions = {}

    -- Collect phases
    local seen, phases = {}, {}
    local presentInEntries = {}

    -- Find ud af hvilke faser der faktisk eksisterer (for at skjule slettede native faser)
    for _, entry in ipairs(allEntries) do
        local p = entry.phase or PHASE_NONE
        if p == "" then p = PHASE_NONE end
        presentInEntries[p] = true
    end
    if currentFilterPhase ~= PHASE_NONE then
        presentInEntries[currentFilterPhase] = true
    end

    -- 1. Tilføj standat/native faser i den rækkefølge de har i filen
    if currentBoss and currentBoss.phases then
        for _, p in ipairs(currentBoss.phases) do
            if presentInEntries[p] and not seen[p] then
                seen[p] = true
                table_insert(phases, p)
            end
        end
    end

    -- 2. Tilføj custom faser i den rækkefølge de optræder i entries
    for _, entry in ipairs(allEntries) do
        local p = entry.phase or PHASE_NONE
        if p == "" then p = PHASE_NONE end
        if p ~= PHASE_NONE and not seen[p] then
            seen[p] = true
            table_insert(phases, p)
        end
    end

    if currentFilterPhase ~= PHASE_NONE and not seen[currentFilterPhase] then
        seen[currentFilterPhase] = true; table_insert(phases, currentFilterPhase)
    end
    if #phases == 0 then table_insert(phases, PHASE_NONE) end

    local y = 4
    for i, p in ipairs(phases) do
        local _, itemH = CreatePhaseItem(panel, p, y, panelW, i)
        y = y + itemH
    end

    local _, newY = CreateNewPhaseButton(panel, panelW, y)
    panel:SetSize(panelW + 8, newY + 4)
end

-- =====================================================================
-- Phase Filter Dropdown Widget (thin orchestrator)
-- =====================================================================
local function CreatePhaseFilterWidget(rPanel)
    local dropdown = CreateFrame("Frame", nil, rPanel, "BackdropTemplate")
    dropdown:SetSize(140, 26)
    dropdown:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 8, -8)

    local filterBtn = BossUI.CreateCustomButton(dropdown, 140, 26, PHASE_NONE)
    filterBtn:SetPoint("TOP", dropdown, "TOP", 0, 0)

    local filterBtnLabel = filterBtn.text

    local filterArrow = filterBtn:CreateTexture(nil, "OVERLAY")
    filterArrow:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Arrow_Down_icon.png")
    filterArrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
    filterArrow:SetSize(20, 10)
    filterArrow:SetPoint("RIGHT", filterBtn, "RIGHT", -8, 0)
    filterArrow:SetAlpha(0.8)
    filterBtn.arrow = filterArrow

    filterBtn:HookScript("OnEnter", function(self)
        filterArrow:SetVertexColor(1, 0.9, 0.4, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Translate("FILTER_PHASE_TOOLTIP"), 1, 0.82, 0.3)
        GameTooltip:Show()
    end)
    filterBtn:HookScript("OnLeave", function(self)
        filterArrow:SetVertexColor(0.98, 0.82, 0.55, 0.8)
        GameTooltip:Hide()
    end)

    local dropPanel = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    BossHelper.UI.ApplyBackdrop(dropPanel, "EDITBOX", BossHelper.UI.C.BG_PANEL, BossHelper.UI.C.BORDER_AMBER)
    dropPanel:SetFrameStrata("FULLSCREEN_DIALOG")
    dropPanel:SetFrameLevel(2000)
    dropPanel:Hide()
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetFrameLevel(1999)

    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1998)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", CloseFilterDrop)

    -- Populate shared state so helpers can find these frames
    PhaseFilter.btn     = filterBtn
    PhaseFilter.label   = filterBtnLabel
    PhaseFilter.arrow   = filterArrow
    PhaseFilter.panel   = dropPanel
    PhaseFilter.catcher = catcher
    PhaseFilter.regions = {}

    filterBtn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        if dropPanel:IsShown() then
            CloseFilterDrop()
        else
            RebuildFilterDropList()
            dropPanel:ClearAllPoints()
            dropPanel:SetPoint("TOP", filterBtn, "BOTTOM", 0, -2)
            dropPanel:Show()
            catcher:Show()
            filterArrow:SetRotation(math_pi)
            if BossHelper.Anim and BossHelper.Anim.PlayDropdownOpen then
                BossHelper.Anim.PlayDropdownOpen(dropPanel)
            end
        end
    end)

    filterBtn.SetFilterPhase = SetFilterLabel
    dropdown:Hide()
    rPanel.editFilterBtn          = dropdown
    rPanel.editFilterPhaseWidget  = filterBtn
    return dropdown
end

-- =====================================================================
-- BuildEditModeUI sub-builders
-- =====================================================================
local function CreatePencilButton(rPanel)
    local btn = BossUI.CreateCustomButton(rPanel, 24, 24, "")
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(rPanel:GetFrameLevel() + 10)
    btn:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 8, -8)
    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
    icon:SetSize(14, 14)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 1)
    icon:SetVertexColor(0.98, 0.82, 0.55, 1)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.6, 0.2, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Translate("EDIT_TACTICS_TOOLTIP"), 1, 0.82, 0.3)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.06, 0.07, 0.11, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        BossUI:EnterEditMode()
    end)
    btn:Hide()
    rPanel.editTacticsBtn = btn
end

local function CreateEditScrollPanel(rPanel)
    local panel = CreateFrame("Frame", nil, rPanel, "BackdropTemplate")
    panel:SetPoint("TOPLEFT",     rPanel, "TOPLEFT",     8, -40)
    panel:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -8,  46)
    _BD(panel, "FRAME", _C.BG_PANEL, _C.BORDER_ORANGE_MED)
    panel:Hide()
    rPanel.editTacticsPanel = panel

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     6,  -6)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26,  6)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(ROW_W + LEFT_MARGIN)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    editContent = content

    local plusBtn = BossUI.CreateCustomButton(content, ROW_W, PLUS_H, Translate("ADD_TACTIC_BTN"))
    plusBtn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
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
end

local function CreateEditActionButtons(rPanel)
    local createBtn = BossUI.CreateCustomButton

    local saveBtn = createBtn(rPanel, 120, 34, Translate("SAVE_CHANGES") or "Save Changes")
    saveBtn:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -10, 10)
    saveBtn:SetScript("OnClick", function()
        SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
        BossUI:ExitEditMode(true)
    end)
    saveBtn:Hide()
    rPanel.saveTacticsBtn = saveBtn

    local resetBtn = createBtn(rPanel, 120, 34, Translate("RESET_TACTICS_TITLE") or "Reset Tactics")
    resetBtn:SetPoint("BOTTOMLEFT", rPanel, "BOTTOMLEFT", 10, 10)
    resetBtn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.6, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    resetBtn:SetScript("OnClick", function()
        local f       = BossUI.GetFrame()
        local dungeon = BossUI:GetCurrentDungeon()
        if not f or not f.selectedBoss or not dungeon then return end
        ConfirmDialog.Show({
            title   = Translate("RESET_TACTICS_TITLE"),
            message = Translate("RESET_TACTICS_MSG"),
            onOk    = function()
                BossUI.stagedTactics[f.selectedBoss.encounterID] = {}
                SafePlay(BossHelper.Sounds.NORMAL_BUTTON)
                BossUI:EnterEditMode()
            end,
        })
    end)
    resetBtn:Hide()
    rPanel.resetTacticsBtn = resetBtn

    local cancelBtn = createBtn(rPanel, 100, 34, Translate("CANCEL") or "Cancel")
    cancelBtn:SetPoint("BOTTOMRIGHT", rPanel.saveTacticsBtn, "BOTTOMLEFT", -6, 0)
    cancelBtn:SetScript("OnClick", function()
        BossUI:AttemptActionWithUnsavedChanges(function() end)
    end)
    cancelBtn:Hide()
    rPanel.cancelTacticsBtn = cancelBtn
end

-- =====================================================================
-- BossUI:BuildEditModeUI  (kallas fra BossUI:CreateUI)
-- =====================================================================
function BossUI:BuildEditModeUI(rPanel)
    CreatePencilButton(rPanel)
    CreatePhaseFilterWidget(rPanel)
    CreateEditScrollPanel(rPanel)
    CreateEditActionButtons(rPanel)
end