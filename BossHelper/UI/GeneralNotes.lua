-- GeneralNotes.lua
-- Provides a general notes page similar to Settings: left panel = categories, right panel = note list + input

if not GeneralNotes then GeneralNotes = {} end

local deps = {}
local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end

function GeneralNotes.Init(d)
	if not d then return end
	for k,v in pairs(d) do deps[k] = v end
end

-- Confirmation popup helpers
local function ShowDeleteConfirm(onConfirm)
	ConfirmDialog.Show({
		title   = Translate("CONFIRM_DELETE_NOTE_TITLE"),
		message = Translate("CONFIRM_DELETE_NOTE"),
		onOk    = onConfirm,
	})
end

local function ShowDeleteCategoryConfirm(catName, onConfirm)
	ConfirmDialog.Show({
		title   = Translate("CONFIRM_DELETE_CATEGORY_TITLE"),
		message = string.format(Translate("CONFIRM_DELETE_CATEGORY"), catName or ""),
		onOk    = onConfirm,
	})
end

-- Ensure saved vars structure exists
local function EnsureDB()
	BossHelperDB = BossHelperDB or {}
	BossHelperDB.generalNotes = BossHelperDB.generalNotes or {}
	BossHelperDB.generalNotesOrder = BossHelperDB.generalNotesOrder or {}
	-- Force desired default category display name to Translate("GENERAL")
	BossHelperDB.generalNotesDefaultName = Translate("GENERAL")
	-- create default category if none
	local hasAny = false
	local firstKey
	for k in pairs(BossHelperDB.generalNotes) do hasAny = true; firstKey = firstKey or k end
	if not hasAny then
		-- Use the desired default name when creating first category
		local def = BossHelperDB.generalNotesDefaultName or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")
		BossHelperDB.generalNotesDefaultName = def
		BossHelperDB.generalNotes[def] = {}
		BossHelperDB.generalNotesDefault = def
	else
		-- ensure we have a stable default key stored; prefer existing stored valid key
		local stored = BossHelperDB.generalNotesDefault
		if not (stored and BossHelperDB.generalNotes[stored]) then
			-- try configured or localized name
			local loc = BossHelperDB.generalNotesDefaultName or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")
			if BossHelperDB.generalNotes[loc] then
				BossHelperDB.generalNotesDefault = loc
			else
				-- fallback to first encountered key
				BossHelperDB.generalNotesDefault = firstKey
			end
		end
	end
	-- Ensure the actual default key in the table matches the desired name "Translate("GENERAL")"
	local desired = BossHelperDB.generalNotesDefaultName or Translate("GENERAL")
	local current = BossHelperDB.generalNotesDefault
	if current ~= desired then
		if BossHelperDB.generalNotes[desired] then
			BossHelperDB.generalNotesDefault = desired
		elseif current and BossHelperDB.generalNotes[current] then
			BossHelperDB.generalNotes[desired] = BossHelperDB.generalNotes[current]
			BossHelperDB.generalNotes[current] = nil
			BossHelperDB.generalNotesDefault = desired
		else
			BossHelperDB.generalNotes[desired] = BossHelperDB.generalNotes[desired] or {}
			BossHelperDB.generalNotesDefault = desired
		end
	end

	-- Sanitize and rebuild category order so default is first and new/unknown keys are appended at the end
	local present = {}
	for k in pairs(BossHelperDB.generalNotes) do present[k] = true end
	local newOrder = {}
	local defName = BossHelperDB.generalNotesDefault or BossHelperDB.generalNotesDefaultName
	if defName and present[defName] then table.insert(newOrder, defName); present[defName] = nil end
	for _, name in ipairs(BossHelperDB.generalNotesOrder or {}) do
		if name ~= defName and present[name] then
			table.insert(newOrder, name)
			present[name] = nil
		end
	end
	local remaining = {}
	for name in pairs(present) do table.insert(remaining, name) end
	table.sort(remaining, function(a,b) return tostring(a) < tostring(b) end)
	for _, name in ipairs(remaining) do table.insert(newOrder, name) end
	BossHelperDB.generalNotesOrder = newOrder
end

-- Apply or restore in-place-edit visual state on a note button
local function ApplyEditVisual(btn, on)
	if on then
		btn._origAlpha = btn:GetAlpha() or 1
		btn:SetAlpha(0.45)
		if btn.text and btn.text.GetTextColor then
			local r,g,b,a = btn.text:GetTextColor()
			btn.text._origColor = {r,g,b,a}
			btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
		end
		if btn.EnableMouse then btn:EnableMouse(false) end
	else
		if btn._origAlpha then btn:SetAlpha(btn._origAlpha) end
		if btn.text and btn.text._origColor then
			local c = btn.text._origColor
			btn.text:SetTextColor(c[1], c[2], c[3], c[4])
		end
		if btn.EnableMouse then btn:EnableMouse(true) end
	end
end

-- Wire up mutually-exclusive hover between edit and delete icon+button pairs.
-- When the button itself is hovered both icons appear; when mouse leaves both, they all hide.
local function AttachEditDeleteHover(btn, editIcon, editBtn, xIcon, xBtn)
	-- Icon-level hover (mutually exclusive)
	editBtn:SetScript("OnEnter", function() editIcon:SetVertexColor(1,1,1,1); xIcon:Hide(); xBtn:Hide() end)
	editBtn:SetScript("OnLeave", function()
		editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
		if not xBtn:IsMouseOver() then editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); xBtn:Hide() end
	end)
	xBtn:SetScript("OnEnter", function() xIcon:SetTextColor(1,1,1); editIcon:Hide(); editBtn:Hide() end)
	xBtn:SetScript("OnLeave", function()
		xIcon:SetTextColor(1, 0.2, 0.2)
		if not editBtn:IsMouseOver() then editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); xBtn:Hide() end
	end)
	-- Button-level hover: show both icons when mouse is over the main button
	local origEnter = btn:GetScript("OnEnter")
	local origLeave = btn:GetScript("OnLeave")
	btn:SetScript("OnEnter", function(self)
		if origEnter then origEnter(self) end
		editIcon:Show(); editBtn:Show(); xIcon:Show(); xBtn:Show()
	end)
	btn:SetScript("OnLeave", function(self)
		if origLeave then origLeave(self) end
		if not editBtn:IsMouseOver() and not xBtn:IsMouseOver() then
			editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); xBtn:Hide()
		end
	end)
end

-- Create and layout a single note button (text, edit icon, delete icon) inside `parent`.
-- Returns btn; edit/delete wiring must be done by caller via onEdit/onDelete callbacks.
local function BuildNoteButton(CreateCustomButton, parent, noteText, btnWidth, minBtnH, padX, padTop, padBot)
	local btn = CreateCustomButton(parent, btnWidth, minBtnH, "")
	btn.text:ClearAllPoints()
	btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", padX, -padTop)
	btn.text:SetPoint("RIGHT",   btn, "RIGHT",   -padX, 0)
	btn.text:SetJustifyH("LEFT")
	btn.text:SetJustifyV("TOP")
	btn.text:SetWordWrap(true)
	btn.text:SetNonSpaceWrap(true)
	btn.text:SetWidth(btnWidth - padX * 2)
	btn:SetText(noteText)

	local textH   = btn.text:GetStringHeight() or 0
	local neededH = math.max(minBtnH, math.ceil(textH + padTop + padBot))
	btn:SetHeight(neededH)
	btn.text:SetHeight(textH)

	-- Delete icon/button
	local xIcon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	xIcon:SetText("X")
	xIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	xIcon:SetTextColor(1, 0.2, 0.2)
	xIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, -1)
	local xBtn = CreateFrame("Button", nil, btn)
	xBtn:SetSize(12, 12)
	xBtn:EnableMouse(true)
	xBtn:SetPoint("CENTER", xIcon, "CENTER", 0, 0)

	-- Edit icon/button
	local editIcon = btn:CreateTexture(nil, "OVERLAY")
	editIcon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
	editIcon:SetSize(11, 11)
	editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
	editIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -14)
	local editBtn = CreateFrame("Button", nil, btn)
	editBtn:SetSize(13, 13)
	editBtn:EnableMouse(true)
	editBtn:SetPoint("CENTER", editIcon, "CENTER", 0, 0)

	-- Start hidden; shown on hover via AttachEditDeleteHover
	editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); xBtn:Hide()

	return btn, editBtn, editIcon, xBtn, xIcon, neededH
end

-- Cleanup helper for rightPanel widgets
local function CleanupNotesWidgets(rPanel)
	if not rPanel or not rPanel.notesWidgets then return end
	for _, w in ipairs(rPanel.notesWidgets) do
		BossHelper.UI.destroyWidget(w)
	end
	rPanel.notesWidgets = nil
end

-- Build the right panel note list + input for selected category
local function BuildNotesUI(rPanel, category, ctx)
	CleanupNotesWidgets(rPanel)
	-- reset editing target when switching categories/building fresh
	rPanel._editingTargetCat = nil
	-- clear any lingering edit reference (buttons will be rebuilt)
	rPanel._editingRef = nil

	local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
	EnsureDB()
	-- Determine if this category is the default (GENERAL) view that should aggregate all notes
	local defaultName = (BossHelperDB and (BossHelperDB.generalNotesDefault or BossHelperDB.generalNotesDefaultName)) or Translate("GENERAL")
	local showAll = (category == defaultName)

	-- Ensure the selected category table exists (for adding notes when not in aggregate view, or adding to GENERAL)
	if type(BossHelperDB.generalNotes[category]) ~= "table" then
		BossHelperDB.generalNotes[category] = {}
	end

	-- Title
	if not rPanel.rightTitle then
		rPanel.rightTitle = rPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
		rPanel.rightTitle:SetPoint("TOP", rPanel, "TOP", 0, -20)
		rPanel.rightTitle:SetTextColor(1, 0.5, 0)
		rPanel.rightTitle:SetJustifyH("CENTER")
	end
	BossHelper.UI.setText(rPanel.rightTitle, category)

	-- Scroll area for notes
	local scroll = CreateFrame("ScrollFrame", nil, rPanel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", rPanel, "TOPLEFT", 10, -40)
	scroll:SetPoint("RIGHT", rPanel, "RIGHT", -30, 0)
	scroll:SetHeight(300)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)

	rPanel.notesWidgets = rPanel.notesWidgets or {}
	table.insert(rPanel.notesWidgets, scroll)
	table.insert(rPanel.notesWidgets, content)

	-- Build existing notes into buttons (newest first)
	local totalY = 0
	local btnWidth   = 540
	local minBtnH    = 26
	local paddingX   = 8
	local paddingTop = 6
	local paddingBot = 6
	local spacing    = 6

	local function beginEditing(btn, item, noteText, input)
		if rPanel._editingRef and rPanel._editingRef.btn and rPanel._editingRef.btn:IsShown() then
			buildButtons()
		end
		rPanel._editingRef = { cat = item.cat, index = item.index, btn = btn }
		if input then
			input:SetText((noteText or ""):gsub("^• ", ""))
			input:SetFocus()
		end
		ApplyEditVisual(btn, true)
	end

	local buildButtons
	buildButtons = function()
		-- clear existing (if any)
		if rPanel._noteButtons then
			for _, b in ipairs(rPanel._noteButtons) do
				BossHelper.UI.destroyWidget(b)
			end
		end
		rPanel._noteButtons = {}
		totalY = 0

		-- Build a flat list of items to display: { text = string, cat = categoryName, index = indexInSource }
		local items = {}
		if showAll then
			-- iterate categories by saved order so users see a predictable grouping
			local order = BossHelperDB.generalNotesOrder or {}
			for _, catName in ipairs(order) do
				local list = BossHelperDB.generalNotes[catName]
				if type(list) == "table" then
					for j = #list, 1, -1 do
						local t = list[j]
						if t and t ~= "" then table.insert(items, { text = t, cat = catName, index = j }) end
					end
				end
			end
		else
			local list = BossHelperDB.generalNotes[category] or {}
			for j = #list, 1, -1 do
				local t = list[j]
				if t and t ~= "" then table.insert(items, { text = t, cat = category, index = j }) end
			end
		end

		for _, item in ipairs(items) do
			local noteText = item.text
			if noteText and noteText ~= "" then
				local btn, editBtn, editIcon, xBtn, xIcon, neededH =
					BuildNoteButton(CreateCustomButton, content, noteText, btnWidth, minBtnH, paddingX, paddingTop, paddingBot)
				btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -totalY)

				btn:SetScript("OnClick", function()
					if deps.BossHelper then
						deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds.POST_TO_CHAT)
						deps.BossHelper:SendSingleSmartMessage(noteText)
					end
				end)
				editBtn:SetScript("OnClick", function()
					beginEditing(btn, item, noteText, rPanel._notesInput)
				end)
				xBtn:SetScript("OnClick", function()
					ShowDeleteConfirm(function()
						if rPanel._editingRef and rPanel._editingRef.cat == item.cat and rPanel._editingRef.index == item.index then
							rPanel._editingRef = nil
							if rPanel._notesInput then rPanel._notesInput:SetText("") end
						end
						local src = BossHelperDB.generalNotes[item.cat]
						if type(src) == "table" then table.remove(src, item.index) end
						buildButtons()
					end)
				end)
				AttachEditDeleteHover(btn, editIcon, editBtn, xIcon, xBtn)

				table.insert(rPanel._noteButtons, btn)
				table.insert(rPanel._noteButtons, editBtn)
				table.insert(rPanel._noteButtons, xBtn)
				totalY = totalY + neededH + spacing
			end
		end
		content:SetHeight(math.max(totalY - spacing, 1))
	end

	buildButtons()

	-- Input box at bottom (match width of note buttons area)
	local input = CreateFrame("EditBox", nil, rPanel, "InputBoxTemplate")
	input:ClearAllPoints()
	-- Add a small extra inset (4px) on both sides to visually match the note buttons' inner margins
	input:SetPoint("BOTTOMLEFT", rPanel, "BOTTOMLEFT", 14, 12)
	input:SetPoint("BOTTOMRIGHT", rPanel, "BOTTOMRIGHT", -34, 12)
	input:SetHeight(20)
	input:SetAutoFocus(false)
	input:SetFontObject("ChatFontNormal")
	input:SetText("")
	rPanel._notesInput = input
	table.insert(rPanel.notesWidgets, input)

	local inputLabel = rPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inputLabel:ClearAllPoints()
	-- Center the label horizontally above the input field
	inputLabel:SetPoint("BOTTOM", input, "TOP", 0, 4)
	inputLabel:SetText(Translate("ADD_NOTE_TIP"))
	inputLabel:SetTextColor(0.98, 0.82, 0.55)
	table.insert(rPanel.notesWidgets, inputLabel)

	-- Commit function shared by Enter and focus-lost
	local function commitIfEditingOrAdd(self)
		local txt = trim(self:GetText())
		if rPanel._editingRef then
			-- Update existing note in-place if non-empty; if empty, cancel and leave original untouched
			if txt ~= "" then
				local ref = rPanel._editingRef
				local src = BossHelperDB.generalNotes[ref.cat]
				if type(src) == "table" and src[ref.index] then
					src[ref.index] = txt
				end
			end
			self:SetText("")
			rPanel._editingRef = nil
			buildButtons()
			return true
		else
			-- Normal add flow
			if txt ~= "" then
				local targetCat = (showAll and defaultName or category)
				BossHelperDB.generalNotes[targetCat] = BossHelperDB.generalNotes[targetCat] or {}
				table.insert(BossHelperDB.generalNotes[targetCat], txt)
				self:SetText("")
				buildButtons()
				return true
			end
		end
		return false
	end

	input:SetScript("OnEnterPressed", function(self)
		commitIfEditingOrAdd(self)
		-- Clear legacy editing target
		rPanel._editingTargetCat = nil
		self:ClearFocus()
	end)

	input:SetScript("OnEscapePressed", function(self)
		-- Cancel editing/add; rebuild to restore visuals
		self:SetText("")
		rPanel._editingRef = nil
		rPanel._editingTargetCat = nil
		buildButtons()
		self:ClearFocus()
	end)

	input:SetScript("OnEditFocusLost", function(self)
		-- Auto-commit edits if any text; do not add empty notes
		commitIfEditingOrAdd(self)
	end)
end

-- Builds left categories and wires selection
local function BuildCategories(frame, leftPanel, rightPanel, ctx)
	local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton
	EnsureDB()

	-- Set left title
	if leftPanel and leftPanel.leftTitle then
		leftPanel.leftTitle:SetText(Translate("GENERAL_NOTES"))
	end

	-- Clear old buttons (reuse frame.bossButtons pool)
	if frame.bossButtons then
		for _, btn in ipairs(frame.bossButtons) do
			-- Keep the inline category EditBox intact across rebuilds
			if btn ~= (leftPanel and leftPanel._notesCatInput) and btn ~= (leftPanel and leftPanel._catRenameEdit) then
				BossHelper.UI.hide(btn.icon)
				BossHelper.UI.destroyWidget(btn)
			end
		end
	end
	frame.bossButtons = {}

	local y = -39
	local firstCat
	local defaultName = (BossHelperDB and BossHelperDB.generalNotesDefault)
		or (BossHelperDB and BossHelperDB.generalNotesDefaultName)
		or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")
	local iterList = BossHelperDB.generalNotesOrder or {}
	for _, catName in ipairs(iterList) do
		if BossHelperDB.generalNotes[catName] then
		firstCat = firstCat or catName
		local btn = CreateCustomButton(leftPanel, 180, 30, catName)
		btn:SetPoint("TOP", leftPanel, "TOP", 0, y)
		btn:SetScript("OnClick", function()
			if deps.BossHelper and deps.BossHelper.SafePlaySound then deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds.NORMAL_BUTTON or 856) end
			-- deselect previous
			if frame.settingsSelectedButton then
				pcall(frame.settingsSelectedButton.SetSelected, frame.settingsSelectedButton, false)
				frame.settingsSelectedButton = nil
			end
			pcall(btn.SetSelected, btn, true)
			frame.settingsSelectedButton = btn
			BuildNotesUI(rightPanel, catName, ctx)
		end)

			-- Rename (pencil) icon for all categories
		local editIcon = btn:CreateTexture(nil, "OVERLAY")
		editIcon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
		editIcon:SetSize(11, 11)
		editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
		editIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -14)
		local editBtn = CreateFrame("Button", nil, btn)
		editBtn:SetSize(13, 13)
		editBtn:SetPoint("CENTER", editIcon, "CENTER", 0, 0)
		editBtn:EnableMouse(true)
		editIcon:Hide(); editBtn:Hide()
		editBtn:SetScript("OnEnter", function() editIcon:SetVertexColor(1,1,1,1) end)
		editBtn:SetScript("OnLeave", function() editIcon:SetVertexColor(0.98, 0.82, 0.55, 1) end)
		editBtn:SetScript("OnClick", function()
			-- Disallow renaming the default category
			if catName == defaultName then
				if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " You cannot rename the default category.") end
				return
			end
			-- Open inline rename box anchored to this button
			local eb = leftPanel._catRenameEdit
			if not eb then
				eb = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
				eb:SetAutoFocus(true)
				eb:SetMaxLetters(40)
				eb:Hide()
				leftPanel._catRenameEdit = eb
				-- keep above
				eb:SetFrameStrata(leftPanel:GetFrameStrata() or "MEDIUM")
				eb:SetFrameLevel((btn:GetFrameLevel() or 1) + 20)
				-- Handlers
				eb:SetScript("OnEnterPressed", function(self)
				local newName = trim(self:GetText())
					local oldName = self._oldName
					self:ClearFocus(); self:Hide()
					if newName == "" or newName == oldName then return end
					EnsureDB()
					if BossHelperDB.generalNotes[newName] then
						if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " Category already exists.") end
						return
					end
					-- move table and update default pointer if needed
					BossHelperDB.generalNotes[newName] = BossHelperDB.generalNotes[oldName] or {}
					BossHelperDB.generalNotes[oldName] = nil
					if BossHelperDB.generalNotesDefault == oldName then
						BossHelperDB.generalNotesDefault = newName
						BossHelperDB.generalNotesDefaultName = newName
					end
					-- update order list positionally
					BossHelperDB.generalNotesOrder = BossHelperDB.generalNotesOrder or {}
					for i, n in ipairs(BossHelperDB.generalNotesOrder) do
						if n == oldName then
							BossHelperDB.generalNotesOrder[i] = newName
							break
						end
					end
					BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton, preferCategory = newName })
				end)
					eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:Hide() end)
					-- Auto-hide when focus is lost
					eb:SetScript("OnEditFocusLost", function(self) self:Hide() end)
			end
			-- re-anchor to this button and show
			eb:ClearAllPoints()
			eb:SetParent(leftPanel)
			eb:SetPoint("LEFT", btn, "LEFT", 10, 0)
			eb:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
			eb:SetHeight(18)
			eb:SetFrameStrata(leftPanel:GetFrameStrata() or "MEDIUM")
			eb:SetFrameLevel((btn:GetFrameLevel() or 1) + 20)
			eb:SetText(catName)
			eb._oldName = catName
			eb:Show()
			eb:SetFocus()
		end)
		-- ensure editBtn cleans with others
		table.insert(frame.bossButtons, editBtn)
		-- Add small delete X for non-default categories
		if catName ~= defaultName then
			local xIcon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			xIcon:SetText("X")
			xIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
			xIcon:SetTextColor(1, 0.2, 0.2)
			xIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, -1)
			local delBtn = CreateFrame("Button", nil, btn)
			delBtn:SetSize(12, 12)
			delBtn:SetPoint("CENTER", xIcon, "CENTER", 0, 0)
			delBtn:EnableMouse(true)
			xIcon:Hide(); delBtn:Hide()

			AttachEditDeleteHover(btn, editIcon, editBtn, xIcon, delBtn)

			delBtn:SetScript("OnClick", function()
				ShowDeleteCategoryConfirm(catName, function()
					BossHelperDB.generalNotes[catName] = nil
					local ord = BossHelperDB.generalNotesOrder or {}
					for i, n in ipairs(ord) do if n == catName then table.remove(ord, i); break end end
					BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton, preferCategory = defaultName })
				end)
			end)
			table.insert(frame.bossButtons, delBtn)
		else
			-- default category: no hover/rename/delete
			editIcon:Hide(); editBtn:Hide()
		end
		table.insert(frame.bossButtons, btn)
		y = y - 35
		end
	end

	-- Add Category button (bottom of left panel, above Back)
	local addBtn = CreateCustomButton(leftPanel, 180, 30, (Translate("ADD_CATEGORY")))
	addBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 45)
	addBtn.tooltip = "Create a new category"
	addBtn:SetScript("OnClick", function()
		-- lazy-create inline input box above the button
		local eb = leftPanel._notesCatInput
		if not eb then
			eb = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
			eb:SetAutoFocus(true)
			eb:SetMaxLetters(40)
			eb:SetText("")
			eb:Hide()
			leftPanel._notesCatInput = eb

			-- keep above other controls in left panel
			eb:SetFrameStrata(leftPanel:GetFrameStrata() or "MEDIUM")
			eb:SetFrameLevel((addBtn:GetFrameLevel() or 1) + 10)

			eb:SetScript("OnEnterPressed", function(self)
			local name = trim(self:GetText())
				if name == "" then self:ClearFocus(); self:Hide(); return end
				EnsureDB()
				if BossHelperDB.generalNotes[name] then
					DEFAULT_CHAT_FRAME:AddMessage(BossHelper.CHAT_TAG_ERR .. " Category already exists.")
					return
				end
				BossHelperDB.generalNotes[name] = {}
				BossHelperDB.generalNotesOrder = BossHelperDB.generalNotesOrder or {}
				table.insert(BossHelperDB.generalNotesOrder, name)
				self:SetText("")
				self:ClearFocus()
				self:Hide()
				-- rebuild and select the new category
				BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton, preferCategory = name })
			end)
			eb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:Hide(); self:ClearFocus() end)
			-- Auto-hide when focus is lost (e.g., navigating away or clicking elsewhere)
			eb:SetScript("OnEditFocusLost", function(self) self:Hide() end)
		end
		-- Re-parent and re-anchor every time to the new addBtn (after rebuilds)
		eb:SetParent(leftPanel)
		eb:ClearAllPoints()
		-- Match button width with a small inset so the template border doesn't overshoot
		eb:SetPoint("BOTTOMLEFT", addBtn, "TOPLEFT", 8, 6)
		eb:SetPoint("BOTTOMRIGHT", addBtn, "TOPRIGHT", -2, 6)
		eb:SetHeight(20)
		eb:SetFrameStrata(leftPanel:GetFrameStrata() or "MEDIUM")
		eb:SetFrameLevel((addBtn:GetFrameLevel() or 1) + 10)
		-- Toggle behavior: if shown, hide; if hidden, show and focus
		if eb:IsShown() then
			eb:ClearFocus()
			eb:Hide()
		else
			eb:Show()
			eb:SetFocus()
		end
	end)
	table.insert(frame.bossButtons, addBtn)

	-- Auto-select: preferred name → default name → first button
	local function SelectByName(name)
		if not name then return false end
		for _, b in ipairs(frame.bossButtons) do
			if b.SetSelected and b.text and b.text:GetText() == name then
				b:SetSelected(true)
				frame.settingsSelectedButton = b
				BuildNotesUI(rightPanel, name, ctx)
				return true
			end
		end
		return false
	end

	local defName = (BossHelperDB and (BossHelperDB.generalNotesDefault or BossHelperDB.generalNotesDefaultName)) or Translate("GENERAL")
	if not SelectByName(ctx.preferCategory) and not SelectByName(defName) then
		-- Fallback: first button in the list
		local firstBtn = frame.bossButtons[1]
		if firstBtn and firstBtn.SetSelected then
			firstBtn:SetSelected(true)
			frame.settingsSelectedButton = firstBtn
			BuildNotesUI(rightPanel, firstBtn.text and firstBtn.text:GetText() or defName, ctx)
		end
	end
end

-- Public API: ShowGeneralNotes(ctx)
function GeneralNotes.ShowGeneralNotes(ctx)
	ctx = ctx or {}
	if ctx.CreateCustomButton then deps.CreateCustomButton = ctx.CreateCustomButton end
	if ctx.BossHelper then deps.BossHelper = ctx.BossHelper end

	local frame = ctx.frame
	local leftPanel = ctx.leftPanel
	local rightPanel = ctx.rightPanel
	local backButton = ctx.backButton
	local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

	if not (frame and leftPanel and rightPanel and CreateCustomButton) then
		print("|cffFF4500[GeneralNotes]|r Missing context for ShowGeneralNotes()")
		return
	end

	frame.currentMode = "notes"
	frame.selectedBoss = nil
	frame.currentDungeon = nil

	-- hide other UI on rightPanel
	BossHelper.UI.hide(rightPanel.rightShortScroll)
	BossHelper.UI.hide(rightPanel.shortBtnScroll)
	BossHelper.UI.setText(rightPanel.rightShortText, "")
	BossHelper.UI.setText(rightPanel.rightDetailText, "")
	BossHelper.UI.hide(rightPanel.rightDetailScroll)
	rightPanel.showingDetails = false
	for _, key in ipairs({"postButton","detailToggle","discordButton","githubButton","bugReportButton","bossNoteButton"}) do
		BossHelper.UI.hide(rightPanel[key])
	end

	-- clear old widgets
	CleanupNotesWidgets(rightPanel)

	-- mark last open
	BossHelperDB = BossHelperDB or {}
	BossHelperDB.lastOpenPanel = "notes"

	-- Hide any lingering inline editors before building
	BossHelper.UI.hide(leftPanel and leftPanel._notesCatInput)
	BossHelper.UI.hide(leftPanel and leftPanel._catRenameEdit)
	BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton })

	if backButton then backButton:Show() end
end

-- Optional: explicit category select from outer wrapper
function GeneralNotes.SelectNotesCategory(frame, leftPanel, rightPanel, categoryName, btn, ctx)
	BuildNotesUI(rightPanel, categoryName, ctx or { CreateCustomButton = deps.CreateCustomButton })
end

-- InitBossNotePanel: initialise a bossNotePanel frame with note list + input.
-- Called from BossUI instead of the old CreateBossNoteContent() global.
-- ctx = { frame=, rightPanel=, currentDungeon=func, CreateCustomButton= }
function GeneralNotes.InitBossNotePanel(panel, ctx)
	if not panel then return end
	local getFrame       = ctx.getFrame
	local getRightPanel  = ctx.getRightPanel
	local getDungeon     = ctx.getDungeon
	local CreateCustomButton = ctx.CreateCustomButton or deps.CreateCustomButton

	-- Title
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", panel, "TOP", 0, -15)
	title:SetTextColor(0.8, 0.3, 1)
	title:SetText(Translate("BOSS_NOTES"))

	-- Scroll area
	local notesScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	notesScroll:SetSize(160, 310)
	notesScroll:SetPoint("TOP", title, "BOTTOM", -10, -8)
	local notesContent = CreateFrame("Frame", nil, notesScroll)
	notesContent:SetSize(180, 1)
	notesScroll:SetScrollChild(notesContent)

	-- Hidden placeholder text (buttons used instead)
	local notesText = notesContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	notesText:SetPoint("TOPLEFT", notesContent, "TOPLEFT", 5, -5)
	notesText:SetWidth(160)
	notesText:SetJustifyH("LEFT")
	notesText:SetJustifyV("TOP")
	notesText:SetWordWrap(true)
	notesText:SetText("")

	-- Input EditBox
	local inputBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	inputBox:SetSize(170, 20)
	inputBox:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
	inputBox:SetAutoFocus(false)
	inputBox:SetFontObject("ChatFontNormal")
	inputBox:SetText("")

	panel._editingRef = nil

	local function BeginEditing(btn, idx, noteText)
		if panel._editingRef and panel._editingRef.btn and panel._editingRef.btn ~= btn then
			ApplyEditVisual(panel._editingRef.btn, false)
		end
		panel._editingRef = { index = idx, btn = btn }
		inputBox:SetText((noteText or ""):gsub("^• ", ""))
		inputBox:SetFocus()
		ApplyEditVisual(btn, true)
	end

	local inputLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inputLabel:SetPoint("BOTTOM", inputBox, "TOP", 0, 3)
	inputLabel:SetText(Translate("ADD_NOTE_TIP"))
	inputLabel:SetTextColor(0.98, 0.82, 0.55)

	panel.noteButtons = {}

	local function UpdateNotesDisplay(bossName, dungeonName)
		for _, btn in ipairs(panel.noteButtons) do BossHelper.UI.destroyWidget(btn) end
		panel.noteButtons = {}
		notesText:SetText("")
		if not (bossName and dungeonName) then return end

		BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
		BossHelperDB.bossNotes[dungeonName] = BossHelperDB.bossNotes[dungeonName] or {}
		BossHelperDB.bossNotes[dungeonName][bossName] = BossHelperDB.bossNotes[dungeonName][bossName] or {}
		local notesList = BossHelperDB.bossNotes[dungeonName][bossName]
		if type(notesList) == "string" then
			BossHelperDB.bossNotes[dungeonName][bossName] = (notesList ~= "") and {notesList} or {}
			notesList = BossHelperDB.bossNotes[dungeonName][bossName]
		end

		local totalY = 0
		local spacing = 6

		for i = #notesList, 1, -1 do
			local noteText = notesList[i]
			if noteText and noteText ~= "" then
				local btn, editBtn, editIcon, xBtn, xIcon, neededH =
					BuildNoteButton(CreateCustomButton, notesContent, noteText, 160, 26, 8, 6, 6)
				btn:SetPoint("TOPLEFT", notesContent, "TOPLEFT", 0, -totalY)

				btn:SetScript("OnClick", function()
					BossHelper:SafePlaySound(BossHelper.Sounds.POST_TO_CHAT)
					BossHelper:SendSingleSmartMessage(noteText)
				end)
				editBtn:SetScript("OnClick", function() BeginEditing(btn, i, noteText) end)
				xBtn:SetScript("OnClick", function()
					ShowDeleteConfirm(function()
						if panel._editingRef and panel._editingRef.index == i then
							panel._editingRef = nil; inputBox:SetText("")
						end
						table.remove(BossHelperDB.bossNotes[dungeonName][bossName], i)
						UpdateNotesDisplay(bossName, dungeonName)
					end)
				end)
				AttachEditDeleteHover(btn, editIcon, editBtn, xIcon, xBtn)

				if panel._editingRef and panel._editingRef.index == i then
					panel._editingRef.btn = btn
					ApplyEditVisual(btn, true)
				end

				table.insert(panel.noteButtons, btn)
				table.insert(panel.noteButtons, editBtn)
				table.insert(panel.noteButtons, xBtn)
				totalY = totalY + neededH + spacing
			end
		end
		notesContent:SetHeight(math.max(totalY - spacing, 250))
	end

	-- Commit: update edited note or add new note
	local function CommitOrAdd(self)
		local txt      = trim(self:GetText())
		local f        = getFrame and getFrame()
		local rPanel   = getRightPanel and getRightPanel()
		local bossKey  = f and f.selectedBoss and f.selectedBoss.encounterID
		local dungKey  = getDungeon and getDungeon()
		if not (bossKey and dungKey) then return false end

		BossHelperDB.bossNotes = BossHelperDB.bossNotes or {}
		BossHelperDB.bossNotes[dungKey] = BossHelperDB.bossNotes[dungKey] or {}
		BossHelperDB.bossNotes[dungKey][bossKey] = BossHelperDB.bossNotes[dungKey][bossKey] or {}
		local list = BossHelperDB.bossNotes[dungKey][bossKey]

		if panel._editingRef then
			if txt ~= "" and type(list) == "table" and list[panel._editingRef.index] ~= nil then
				list[panel._editingRef.index] = txt
			end
			self:SetText("")
			panel._editingRef = nil
			UpdateNotesDisplay(bossKey, dungKey)
			return true
		else
			if txt ~= "" then
				table.insert(list, txt)
				self:SetText("")
				UpdateNotesDisplay(bossKey, dungKey)
				return true
			end
		end
		return false
	end

	inputBox:SetScript("OnEnterPressed", function(self) CommitOrAdd(self); self:ClearFocus() end)
	inputBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		panel._editingRef = nil
		local f = getFrame and getFrame()
		local bossKey = f and f.selectedBoss and f.selectedBoss.encounterID
		local dungKey = getDungeon and getDungeon()
		if bossKey and dungKey then UpdateNotesDisplay(bossKey, dungKey) end
		self:ClearFocus()
	end)
	inputBox:SetScript("OnEditFocusLost", function(self) CommitOrAdd(self) end)

	panel.LoadNotesForBoss = function(bossName, dungeonName)
		UpdateNotesDisplay(bossName, dungeonName)
	end

	-- Close button
	local closeBtn = CreateCustomButton(panel, 20, 20, "X")
	closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
	closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	closeBtn:SetScript("OnClick", function()
		local rPanel = getRightPanel and getRightPanel()
		if rPanel and rPanel.bossNoteButton then
			rPanel.bossNoteButton:GetScript("OnClick")()
		end
	end)

	panel.initialized = true
end

return GeneralNotes
