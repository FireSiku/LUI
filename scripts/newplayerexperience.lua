local addonname, LUI = ...
local script = LUI:NewScript("NewPlayerExp", "AceEvent-3.0", "AceHook-3.0")
local barMod = LUI:GetModule("Bars")

local function S(x) return LUI:Scale(x) end

local UnitLevel = _G.UnitLevel
local IsAddOnLoaded = _G.IsAddOnLoaded
local GetActionInfo = _G.GetActionInfo
local FlyoutHasSpell = _G.FlyoutHasSpell
local GetShapeshiftFormInfo = _G.GetShapeshiftFormInfo

local WorldMapFrame = _G.WorldMapFrame
local TutorialHelper = _G.TutorialHelper

local TutorialData = {}
TutorialData.LevelAbilitiesTable = {
	WARRIOR = {
		1464,	-- Start with Slam
		100,	-- Charge, level 2
		23922,	-- Shield Slam, level 3
		1715,	-- Hamstring, level 4
		34428,	-- Victory Rush, level 5
		2565,	-- Shield Block, level 6
		6552,	-- Pummel, level 7
		nil,	-- 319157, Charge Rank 2, level 8
		1680,	-- Whirlwind, level 9
	};
	PALADIN = {
		35395,	-- Start with Crusader Strike
		53600,	-- Shield of the Righteous, level 2
		20271,	-- Judgment, level 3
		19750,	-- Flash of Light, level 4
		853,	-- Hammer of Justice, level 5
		26573,	-- Consecration, level 6
		85673,	-- Word of Glory, level 7
		nil,	-- 327977, Judgement Rank 2, level 8
		633,	-- Lay on Hands, level 8
	};
	HUNTER = {
		56641,	-- Start with Steady Shot
		185358,	-- Arcane Shot, level 2
		195645,	-- Wing Clip, level 3
		781,	-- Disengage, level 4
		186257,	-- Aspect of the Cheetah, level 5
		5384,	-- Feign Death, level 6
		257284,	-- Hunter's Mark, level 7
		186265,	-- Aspect of the Turtle, level 8
		109304,	-- Exhilaration, level 9
	};
	ROGUE = {
		1752,	-- Start with Sinister Strike
		196819,	-- Eviscerate, level 2
		nil,	-- 1833 Cheap Shot, level 3 - Rogues also get Stealth, 1784
		nil,	-- 
		2983,	-- Sq, level 5
		1766,	-- Kick, level 6
		nil,	-- 8676, Ambush, level 7
		185311,	-- Crimson Vial, level 8
		315496,	-- Slice and Dice, level 9
	};
	PRIEST = {
		585,	-- Start with Smite
		589,	-- Shadow Word: Pain, level 2
		2061,	-- Flash Heal, level 3
		17,		-- Power Word: Shield, level 4
		8092,	-- Mind Blast, level 5
		21562,	-- Power Word: Fortitude, level 6
		8122,	-- Psychic Scream, level 7
		19236,	-- Desperate Prayer, level 8
		586,	-- Fade, level 9
	};
	SHAMAN = {
		188196,	-- Start with Lightning Bolt
		73899,	-- Primal Strike, level 2
		188389,	-- Flame Shock, level 3
		8004,	-- Healing Surge, level 4
		2484,	-- Earthbind Totem, level 5
		nil,	-- 318044,	Lightning Bolt Rank 2, level 6
		318038,	-- Flametongue Weapon, level 7
		nil,	-- 20608,-- Reincarnation, level 8
		192106,	-- Lightning Shield, level 9
	};
	MAGE = {
		116,	-- Start with Frostbolt
		319836,	-- Fire Blast, level 2
		122,	-- Frost Nova, level 3
		1953,	-- Blink, level 4
		190336,	-- Conjure Refreshment, level 5
		1449,	-- Arcane Explosion, level 6
		2139,	-- Counterspell, level 7
		1459,	-- Arcane Intellect, level 8
		130,	-- Slow Fall, level 9
	};
	WARLOCK = {
		686,	-- Start with Shadow Bolt
		172,	-- Corruption, level 2
		688,	-- Summon Imp, level 3
		104773,	-- Unending Resolve, level 4
		5782,	-- Fear, level 5
		702,	-- Curse of Weakness, level 6
		6201,	-- Create Healthstone, level 7
		755,	-- Health Funnel, level 8
		234153,	-- Drain Life, level 9
	};
	MONK = {
		100780,	-- Start with Tiger Palm
		100784,	-- Blackout Kick, level 2
		109132,	-- Roll, level 3
		116670,	-- Vivify, level 4
		117952,	-- Crackling Jade Lightning, level 5
		119381,	-- Leg Sweep, level 6
		101546,	-- Spinning Crane Kick, level 7
		322101,	-- Expel Harm, level 8
		nil,	-- 328669, Roll Rank 2, level 9
	};
	DRUID = {
		5176,	-- Start with Wrath
		8921,	-- Moonfire, level 2
		8936,	-- Regrowth, level 3
		339,	-- Entangling Roots, level 4
		nil,	-- 5221, Shred, level 5
		1850,	-- Dash, level 6
		nil,	-- 22568, Ferocious Bite, level 7
		nil,	-- 33917, Mangle, level 8
		nil,	-- 326646, Moonfire Rank 2, level 9
	};
}

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
	if (type(spellID) ~= "number") then return end
	if self.BT4 then
		-- Bartender4 path, until this feature has been added in BT4 proper.
		for i = 1, 24 do
			local btn = _G["BT4Button"..i]
			if btn and btn:IsVisible() then
				local actionType, sID, subType = GetActionInfo(btn:CalculateAction())
				if (sID == spellID) then
					return btn
				elseif (actionType == "flyout" and FlyoutHasSpell(sID, spellID)) then
					return btn
				end
			end
		end
	else
		-- LUI Bars
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
	end
	-- backup for stance bars
	for i = 1, 10 do
		local btn = self.BT4 and _G["BT4StanceButton"..i] or _G["StanceButton"..i]
		local icon, isActive, isCastable, sID = GetShapeshiftFormInfo(btn:GetID())
		if (sID == spellID) then
			return btn
		end
	end
end

function script:FindEmptyButton()
	if self.BT4 then
		for i = 1, 24 do
			local btn = _G["BT4Button"..i]
			if btn then
				local _, sID = GetActionInfo(btn:CalculateAction())
				if not sID then
					return btn;
				end
			end
		end
	else
		-- LUI Bars
		for i = 1, 12 do
			local btn = _G["LUIBarBottom1Button"..i]
			if btn then
				local _, sID = GetActionInfo(btn.action)
				if not sID then
					return btn;
				end
			end
		end
	end
end

function script:SetTutorialFrames()
	script:SecureHook(_G.NPE_TutorialKeyboardMouseFrame_Frame, "ShowTutorial", moveUp)
	moveUp(_G.NPE_TutorialKeyboardMouseFrame_Frame)

	script:SecureHook(_G.NPE_TutorialSingleKey_Frame, "ShowTutorial", moveUp)
	moveUp(_G.NPE_TutorialSingleKey_Frame)
	
	script:SecureHook(_G.NPE_TutorialMainFrame_Frame, "ShowTutorial", moveAway)
	moveAway(_G.NPE_TutorialMainFrame_Frame)

	script:SecureHook(_G.NPE_TutorialWalk_Frame, "ShowTutorial", moveAway)
	moveAway(_G.NPE_TutorialWalk_Frame)
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
	arrow2:ClearAllPoints()
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
	local anchor
	local buttons = LUI.MicroMenu.Buttons
	local text = frame.Content.Text:GetText()
	if not frame:IsShown() and text then frame:Show() end
	if text == _G.NPEV2_SPELLBOOK_TUTORIAL then
		anchor = buttons.Spellbook
		-- HACK: When using BT4, Spellbook warning would always appear on reload.-
		if self.BT4 and not script:ShowSpellbook() then
			frame:Hide()
			-- This function isn't always called on level up, make sure to show it if needed.
			script:RegisterEvent("PLAYER_LEVEL_CHANGED", function()
				script:ShouldReAnchorPointer(frame)
			end)
			return
		end
	elseif text == format(_G.NPEV2_SHOW_BAGS, TutorialHelper:GetBagBinding()) then
		anchor = buttons.Bags
	elseif text == _G.NPEV2_LFD_INTRO then
		anchor = buttons.LFG
		-- Make sure warning is only visible while you're on Exile Reach
		if WorldMapFrame:GetMapID() ~= 1409 then
			frame:Hide()
			return
		end
	elseif text == _G.NPEV2_MOUNT_TUTORIAL_P2_NEW_MOUNT_ADDED then
		anchor = buttons.Pets
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
	script:SecureHook(_G.NPE_TutorialPointerFrame, "Show", function(table, content, direction, anchorFrame, x, y, opposite)
		local newPointer = anchorFrame.currentNPEPointer
		script:ShouldReAnchorPointer(newPointer)
	end)
	-- If the frames already exist, hook will not be called so we have to check manually.
	for i = 1, 3 do
		local frame = _G["NPE_PointerFrame_"..i]
		if frame then
			script:ShouldReAnchorPointer(frame)
		end
	end
end

function script:ShowSpellbook()
	local LevelUpTutorial_spellIDlookUp = TutorialHelper:FilterByClass(TutorialData.LevelAbilitiesTable);
	local playerLevel = UnitLevel("player");
	for startLevel = 1, playerLevel do
		local spellID = LevelUpTutorial_spellIDlookUp[startLevel];

		local button = TutorialHelper:GetActionButtonBySpellID(spellID);
		if not button then
			return true
		end
	end
end

function script:ADDON_LOADED(event, addon)
	if addon == "Blizzard_NewPlayerExperience" then
		if IsAddOnLoaded("Bartender4") then self.BT4 = true end
		if isUsingLUIBars() or self.BT4 then
			script:RawHook(TutorialHelper, "GetActionButtonBySpellID", "GetActionButtonBySpellID", true)
			script:RawHook(TutorialHelper, "FindEmptyButton", "FindEmptyButton", true)
		end
		
		script:SetTutorialFrames()
		script:SetPointerFrame()
	end
end

script:RegisterEvent("ADDON_LOADED")
