local addonname, LUI = ...
local script = LUI:NewScript("NewPlayerExp", "AceEvent-3.0", "AceHook-3.0")
local barMod = LUI:GetModule("Bars")

local function S(x) return LUI:Scale(x) end

local function moveUp(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", S(0), S(30))
end

local function moveAway(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", S(-300), S(-60))
end

local function isUsingLUIBars()
	local db = barMod.db.profile.General
	if not (IsAddOnLoaded("Bartender4") or IsAddOnLoaded("Dominos") or IsAddOnLoaded("Macaroon")) then
		return db.Enable
	end 
end

-- Required for tutorial to let you point to abilities.
function script:GetActionButtonBySpellID(helper, spellID)
	if not isUsingLUIBars() or (type(spellID) ~= "number") then return end
	for i = 1, 12 do
		local btn = _G["LUIBarBottom1Button"..i]
		if btn and btn:IsVisible() then
			local actionType, sID, subType = GetActionInfo(btn.action)
			if (sID == spellID) then
				return btn
			elseif (actionType == "flyout" and FlyoutHasSpell(sID, spellID)) then
				return btn
			end
		end
	end
	-- backup for stance bars
	for i = 1, 10 do
		local btn = _G["StanceButton" .. i]
		local icon, isActive, isCastable, sID = GetShapeshiftFormInfo(btn:GetID())
		if (sID == spellID) then
			return btn
		end
	end
end

function script:SetTutorialFrames()
	script:SecureHook(NPE_TutorialKeyboardMouseFrame_Frame, "ShowTutorial", moveUp)
	moveUp(NPE_TutorialKeyboardMouseFrame_Frame)

	script:SecureHook(NPE_TutorialSingleKey_Frame, "ShowTutorial", moveUp)
	moveUp(NPE_TutorialSingleKey_Frame)
	
	script:SecureHook(NPE_TutorialMainFrame_Frame, "ShowTutorial", moveAway)
	moveAway(NPE_TutorialMainFrame_Frame)

	script:SecureHook(NPE_TutorialWalk_Frame, "ShowTutorial", moveAway)
	moveAway(NPE_TutorialWalk_Frame)

	--script:SecureHook(NPE_TutorialSingleKey_Frame, "ShowTutorial", moveAway)
end

local arrowDirections = {"UP", "LEFT", "RIGHT", "DOWN"}
function script:ShowPointerArrow(frame, direction)
	--Look for previous arrow and Hide
	for i = 1, #arrowDirections do
		local arrow1 = frame["Arrow_"..arrowDirections[i]..1]
		local arrow2 = frame["Arrow_"..arrowDirections[i]..2]
		if arrow1 then
			arrow1:Hide()
			--arrow1.Anim:Stop()
			arrow2:Hide()
			--arrow2.Anim:Stop()
			if frame.AnimDelayTimer then frame.AnimDelayTimer:Cancel() end
		end
	end
	-- -- Show the desired arrow
	local arrow1 = frame["Arrow_"..direction..1]
	local arrow2 = frame["Arrow_"..direction..2]
	local point = (direction == "UP") and "TOP" or (direction == "DOWN") and "BOTTOM" or direction
	arrow1:ClearAllPoints()
	-- arrow2:ClearAllPoints()
	local offsetX = (direction == "UP" or direction == "DOWN") and 0 or NegateIf(25, direction == "RIGHT")
	local offsetY = (direction == "LEFT" or direction == "RIGHT") and 0 or NegateIf(25, direction == "DOWN")
	arrow1:SetPoint(LUI.Opposites[point], frame, point, offsetX, offsetY)
	-- arrow2:SetPoint(point, arrow2:GetParent(), LUI.Opposites[point])
	arrow1:Show();
	arrow1.Anim:Play();
	-- --Second arrow starts half way through tx he first arrow's animation (1 second)
	-- frame.AnimDelayTimer = C_Timer.NewTimer(0.5, function()
	-- 	arrow2:Show();
	-- 	arrow2.Anim:Play()
	-- end)
end

function script:ShouldReAnchorPointer(frame)
	local text = frame.Content.Text:GetText()
	local buttons, anchor = LUI.MicroMenu.Buttons, nil
	--LUI:Print(text)
	if text == NPEV2_SPELLBOOK_TUTORIAL then
		anchor = buttons.Spellbook
	elseif text == format(NPEV2_SHOW_BAGS, TutorialHelper:GetBagBinding()) then
		anchor = buttons.Bags
	else
		return
	end
	frame.currentTarget = anchor
	frame:ClearAllPoints()
	frame:SetPoint("TOP", anchor, "BOTTOM", 0, -100)
	script:ShowPointerArrow(frame, "UP")
end

-- Make sure the New Player Experience frame is pointing to the right button.
function script:SetPointerFrame()
	script:SecureHook(NPE_TutorialPointerFrame, "Show", function(table, content, direction, anchorFrame, x, y, opposite)
		local newPointer = anchorFrame.currentNPEPointer
		script:ShouldReAnchorPointer(newPointer)
	end)
	if NPE_PointerFrame_1 then
		script:ShouldReAnchorPointer(NPE_PointerFrame_1)
	end
end

function script:ADDON_LOADED(event, addon)
	if addon == "Blizzard_NewPlayerExperience" then
		script:RawHook(TutorialHelper, "GetActionButtonBySpellID", "GetActionButtonBySpellID", true)
		script:SetTutorialFrames()
		script:SetPointerFrame()
	end
end

-- Spellbook: NPEV2_SPELLBOOK_TUTORIAL, NPEV2_CALL_QUEST_ABILITY_TUTORIAL??, 
-- Bags: TUTORIAL58, TUTORIAL59

script:RegisterEvent("ADDON_LOADED")
