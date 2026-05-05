-- GeneralNotes.lua
-- Provides a general notes page similar to Settings: left panel = categories, right panel = note list + input

if not GeneralNotes then GeneralNotes = {} end

local deps = {}

function GeneralNotes.Init(d)
	if not d then return end
	for k,v in pairs(d) do deps[k] = v end
end

local function phide(obj)
	if not obj then return end
	pcall(function() if obj.Hide then obj:Hide() end end)
end
local function psetparent(obj, p)
	if not obj then return end
	pcall(function() if obj.SetParent then obj:SetParent(p) end end)
end
local function pclearpoints(obj)
	if not obj then return end
	pcall(function() if obj.ClearAllPoints then obj:ClearAllPoints() end end)
end
local function psettext(obj, txt)
	if not obj then return end
	pcall(function() if obj.SetText then obj:SetText(txt) end end)
end

-- Confirmation popup helper for note deletion
local function ShowDeleteConfirm(onConfirm)
	ConfirmDialog.Show({
		title   = (Translate and Translate("CONFIRM_DELETE_NOTE_TITLE")) or "Slet note",
		message = (Translate and Translate("CONFIRM_DELETE_NOTE")) or "Er du sikker på, at du vil slette denne note?",
		onOk    = onConfirm,
	})
end

-- Confirmation popup helper for category deletion
local function ShowDeleteCategoryConfirm(catName, onConfirm)
	local baseMsg = (Translate and Translate("CONFIRM_DELETE_CATEGORY")) or "Er du sikker på, at du vil slette kategorien '%s'? Alle noter vil blive fjernet."
	ConfirmDialog.Show({
		title   = (Translate and Translate("CONFIRM_DELETE_CATEGORY_TITLE")) or "Slet kategori",
		message = string.format(baseMsg, catName or ""),
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

-- Cleanup helper for rightPanel widgets
local function CleanupNotesWidgets(rPanel)
	if not rPanel or not rPanel.notesWidgets then return end
	for _, w in ipairs(rPanel.notesWidgets) do
		if w then
			phide(w)
			psetparent(w, nil)
			pclearpoints(w)
		end
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
	psettext(rPanel.rightTitle, category)

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

	local buildButtons

	-- helpers to manage visual edit state on a note button
	local function beginEditing(btn, item, noteText, input)
		-- If another note was being edited, rebuild to clear its visuals
		if rPanel._editingRef and rPanel._editingRef.btn and rPanel._editingRef.btn:IsShown() then
			-- restore is handled by rebuild; do a light rebuild to normalize
			buildButtons()
		end
		-- mark this note as being edited
		rPanel._editingRef = { cat = item.cat, index = item.index, btn = btn }
		if input then
			input:SetText((noteText or ""):gsub("^• ", ""))
			input:SetFocus()
		end
		-- grey out and make semi-transparent; also reduce interactivity
		pcall(function()
			btn._origAlpha = btn:GetAlpha() or 1
			btn:SetAlpha(0.45)
			if btn.text and btn.text.GetTextColor then
				local r,g,b,a = btn.text:GetTextColor()
				btn.text._origColor = {r,g,b,a}
				btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
			end
			if btn.EnableMouse then btn:EnableMouse(false) end
		end)
	end
	buildButtons = function()
		-- clear existing (if any)
		if rPanel._noteButtons then
			for _, b in ipairs(rPanel._noteButtons) do
				phide(b)
				psetparent(b, nil)
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

		for i = 1, #items do
			local item = items[i]
			local noteText = item.text
			if noteText and noteText ~= "" then
				local btn = CreateCustomButton(content, btnWidth, minBtnH, "")
				btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -totalY)

				btn.text:ClearAllPoints()
				btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", paddingX, -paddingTop)
				btn.text:SetPoint("RIGHT", btn, "RIGHT", -paddingX, 0)
				btn.text:SetJustifyH("LEFT")
				btn.text:SetJustifyV("TOP")
				btn.text:SetWordWrap(true)
				btn.text:SetNonSpaceWrap(true)
				btn.text:SetWidth(btnWidth - (paddingX * 2))
				btn:SetText(noteText)

				local textH = btn.text:GetStringHeight() or 0
				if textH == 0 then
					btn.text:SetText(btn.text:GetText() or "")
					textH = btn.text:GetStringHeight() or 0
				end
				local neededH = math.max(minBtnH, math.ceil(textH + paddingTop + paddingBot))
				btn:SetHeight(neededH)

				-- Click to send to chat
				btn:SetScript("OnClick", function()
					if deps.BossHelper and deps.BossHelper.SafePlaySound and deps.BossHelper.Sounds then
						deps.BossHelper:SafePlaySound(deps.BossHelper.Sounds.POST_TO_CHAT)
					end
					if deps.BossHelper and deps.BossHelper.SendSingleSmartMessage then
						deps.BossHelper:SendSingleSmartMessage(noteText)
					end
				end)

				-- Edit + Delete icons
				local deleteIcon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				deleteIcon:SetText("X")
				deleteIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
				deleteIcon:SetTextColor(1, 0.2, 0.2)
				local deleteBtn = CreateFrame("Button", nil, btn)
				deleteBtn:SetSize(12, 12)
				deleteBtn:EnableMouse(true)

				local editIcon = btn:CreateTexture(nil, "OVERLAY")
				editIcon:SetTexture("Interface\\AddOns\\BossHelper\\Media\\icon\\Pencil.png")
				editIcon:SetSize(11, 11)
				editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
				local editBtn = CreateFrame("Button", nil, btn)
				editBtn:SetSize(13, 13)
				editBtn:EnableMouse(true)

				deleteIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, -1)
				deleteBtn:SetPoint("CENTER", deleteIcon, "CENTER", 0, 0)
				editIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -14)
				editBtn:SetPoint("CENTER", editIcon, "CENTER", 0, 0)

				editBtn:SetScript("OnClick", function()
					-- Start in-place edit: do NOT remove the note, just mark visually and push text to input
					beginEditing(btn, item, noteText, rPanel._notesInput)
				end)

				deleteBtn:SetScript("OnClick", function()
					ShowDeleteConfirm(function()
						-- if deleting the one being edited, cancel edit state first
						if rPanel._editingRef and rPanel._editingRef.cat == item.cat and rPanel._editingRef.index == item.index then
							rPanel._editingRef = nil
							if rPanel._notesInput then rPanel._notesInput:SetText("") end
						end
						local src = BossHelperDB.generalNotes[item.cat]
						if type(src) == "table" and src[item.index] then
							table.remove(src, item.index)
						end
						buildButtons()
					end)
				end)

				-- Mutually exclusive icon hover
				editBtn:SetScript("OnEnter", function(self)
					editIcon:SetVertexColor(1, 1, 1, 1)
					deleteIcon:Hide(); deleteBtn:Hide()
				end)
				editBtn:SetScript("OnLeave", function(self)
					editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
					if not deleteBtn:IsMouseOver() then
						editIcon:Hide(); editBtn:Hide(); deleteIcon:Hide(); deleteBtn:Hide()
					end
				end)
				deleteBtn:SetScript("OnEnter", function(self)
					deleteIcon:SetTextColor(1, 1, 1)
					editIcon:Hide(); editBtn:Hide()
				end)
				deleteBtn:SetScript("OnLeave", function(self)
					deleteIcon:SetTextColor(1, 0.2, 0.2)
					if not editBtn:IsMouseOver() then
						editIcon:Hide(); editBtn:Hide(); deleteIcon:Hide(); deleteBtn:Hide()
					end
				end)

				editIcon:Hide(); deleteIcon:Hide(); editBtn:Hide(); deleteBtn:Hide()
				local origEnter = btn:GetScript("OnEnter")
				btn:SetScript("OnEnter", function(self)
					if origEnter then origEnter(self) end
					editIcon:Show(); deleteIcon:Show(); editBtn:Show(); deleteBtn:Show()
				end)
				local origLeave = btn:GetScript("OnLeave")
				btn:SetScript("OnLeave", function(self)
					if origLeave then origLeave(self) end
					if not editBtn:IsMouseOver() and not deleteBtn:IsMouseOver() then
						editIcon:Hide(); deleteIcon:Hide(); editBtn:Hide(); deleteBtn:Hide()
					end
				end)

				table.insert(rPanel._noteButtons, btn)
				table.insert(rPanel._noteButtons, editBtn)
				table.insert(rPanel._noteButtons, deleteBtn)
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
		local txt = (self:GetText() or ""):trim()
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
				if btn.icon then phide(btn.icon) end
				phide(btn)
				psetparent(btn, nil)
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

		-- Add small rename (pencil) icon for all categories
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

		-- Category icon hovers: mutually exclusive and hide when not over either icon
		editBtn:SetScript("OnEnter", function()
			editIcon:SetVertexColor(1, 1, 1, 1)
		end)
		editBtn:SetScript("OnLeave", function()
			editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
		end)
		editBtn:SetScript("OnClick", function()
			-- Disallow renaming the default category
			if catName == defaultName then
				if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffFF4500[MythicMentor]|r You cannot rename the default category.") end
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
					local newName = (self:GetText() or ""):trim()
					local oldName = self._oldName
					self:ClearFocus(); self:Hide()
					if newName == "" or newName == oldName then return end
					EnsureDB()
					if BossHelperDB.generalNotes[newName] then
						if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffFF4500[MythicMentor]|r Category already exists.") end
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
			xIcon:Hide(); delBtn:Hide(); -- edit icon also hidden by default

			local origEnter = btn:GetScript("OnEnter")
			btn:SetScript("OnEnter", function(self)
				if origEnter then origEnter(self) end
				xIcon:Show(); delBtn:Show(); editIcon:Show(); editBtn:Show()
			end)
			local origLeave = btn:GetScript("OnLeave")
			btn:SetScript("OnLeave", function(self)
				if origLeave then origLeave(self) end
				if not delBtn:IsMouseOver() then xIcon:Hide(); delBtn:Hide() end
				if not editBtn:IsMouseOver() then editIcon:Hide(); editBtn:Hide() end
			end)

			-- Mutually exclusive: hovering one icon hides the other; leaving an icon hides both unless over the other
			editBtn:SetScript("OnEnter", function()
				editIcon:SetVertexColor(1, 1, 1, 1)
				xIcon:Hide(); delBtn:Hide()
			end)
			editBtn:SetScript("OnLeave", function()
				editIcon:SetVertexColor(0.98, 0.82, 0.55, 1)
				if not delBtn:IsMouseOver() then
					editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); delBtn:Hide()
				end
			end)

			delBtn:SetScript("OnEnter", function()
				xIcon:SetTextColor(1, 1, 1)
				editIcon:Hide(); editBtn:Hide()
			end)
			delBtn:SetScript("OnLeave", function()
				xIcon:SetTextColor(1, 0.2, 0.2)
				if not editBtn:IsMouseOver() then
					editIcon:Hide(); editBtn:Hide(); xIcon:Hide(); delBtn:Hide()
				end
			end)
			delBtn:SetScript("OnClick", function()
				-- safety: don't delete default
				if catName == defaultName then
					if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffFF4500[MythicMentor]|r You cannot delete the default category.") end
					return
				end
				ShowDeleteCategoryConfirm(catName, function()
					-- remove and rebuild selecting default
					BossHelperDB.generalNotes[catName] = nil
					local ord = BossHelperDB.generalNotesOrder or {}
					for i, n in ipairs(ord) do if n == catName then table.remove(ord, i) break end end
					BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton, preferCategory = defaultName })
				end)
			end)
			table.insert(frame.bossButtons, delBtn)
		else
			-- default category: keep rename icon hidden and do not hook hover
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
				local name = (self:GetText() or ""):trim()
				if name == "" then self:ClearFocus(); self:Hide(); return end
				EnsureDB()
				if BossHelperDB.generalNotes[name] then
					DEFAULT_CHAT_FRAME:AddMessage("|cffFF4500[MythicMentor]|r Category already exists.")
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

	-- Auto-select preferred or default category (fallback to first)
	if #frame.bossButtons > 0 then
		local targetName = ctx.preferCategory
		local selected = false
		if targetName then
			for _, b in ipairs(frame.bossButtons) do
				if b.text and b.text.GetText and b.SetSelected then
					local t = b.text:GetText()
					if t == targetName then
						pcall(b.SetSelected, b, true)
						frame.settingsSelectedButton = b
						BuildNotesUI(rightPanel, targetName, ctx)
						selected = true
						break
					end
				end
			end
		end
		-- Prefer default category if none chosen
		if not selected then
			local defaultName = (BossHelperDB and BossHelperDB.generalNotesDefault)
				or (BossHelperDB and BossHelperDB.generalNotesDefaultName)
				or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")
			for _, b in ipairs(frame.bossButtons) do
				if b.text and b.text.GetText and b.SetSelected then
					local t = b.text:GetText()
					if t == defaultName then
						pcall(b.SetSelected, b, true)
						frame.settingsSelectedButton = b
						BuildNotesUI(rightPanel, defaultName, ctx)
						selected = true
						break
					end
				end
			end
		end
		if not selected then
			-- first real category button is the first we pushed before addBtn
			local firstBtn
			for _, b in ipairs(frame.bossButtons) do
				if b.text and b.text.GetText then firstBtn = b break end
			end
			if firstBtn then
				pcall(firstBtn.SetSelected, firstBtn, true)
				frame.settingsSelectedButton = firstBtn
				BuildNotesUI(rightPanel, firstBtn.text and firstBtn.text:GetText() or firstCat or ((BossHelperDB and BossHelperDB.generalNotesDefaultName) or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")), ctx)
			end
		end
	else
		-- No categories (shouldn't happen), create one
		local def = BossHelperDB.generalNotesDefaultName or (Translate("DEFAULT_CATEGORY") or Translate("GENERAL") or "General")
		BossHelperDB.generalNotesDefaultName = def
		BossHelperDB.generalNotes[def] = {}
		BossHelperDB.generalNotesDefault = def
		BuildCategories(frame, leftPanel, rightPanel, ctx)
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
	pcall(function()
		if rightPanel.rightShortScroll then rightPanel.rightShortScroll:Hide() end
		if rightPanel.shortBtnScroll then rightPanel.shortBtnScroll:Hide() end
		if rightPanel.rightShortText then rightPanel.rightShortText:SetText("") end
		if rightPanel.rightDetailText then rightPanel.rightDetailText:SetText("") end
		if rightPanel.rightDetailScroll then rightPanel.rightDetailScroll:Hide() end
		rightPanel.showingDetails = false
		if rightPanel.postButton then rightPanel.postButton:Hide() end
		if rightPanel.detailToggle then rightPanel.detailToggle:Hide() end
		if rightPanel.discordButton then rightPanel.discordButton:Hide() end
		if rightPanel.githubButton then rightPanel.githubButton:Hide() end
		if rightPanel.bugReportButton then rightPanel.bugReportButton:Hide() end
		if rightPanel.bossNoteButton then rightPanel.bossNoteButton:Hide() end
	end)

	-- clear old widgets
	CleanupNotesWidgets(rightPanel)

	-- mark last open
	BossHelperDB = BossHelperDB or {}
	BossHelperDB.lastOpenPanel = "notes"

	-- Build left categories and right notes
	-- Ensure any lingering inline editors are hidden before building
	pcall(function() if leftPanel and leftPanel._notesCatInput then leftPanel._notesCatInput:Hide() end end)
	pcall(function() if leftPanel and leftPanel._catRenameEdit then leftPanel._catRenameEdit:Hide() end end)
	BuildCategories(frame, leftPanel, rightPanel, { CreateCustomButton = CreateCustomButton })

	if backButton then backButton:Show() end
end

-- Optional: explicit category select from outer wrapper
function GeneralNotes.SelectNotesCategory(frame, leftPanel, rightPanel, categoryName, btn, ctx)
	BuildNotesUI(rightPanel, categoryName, ctx or { CreateCustomButton = deps.CreateCustomButton })
end

return GeneralNotes
