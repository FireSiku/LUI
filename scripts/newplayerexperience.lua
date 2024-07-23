---@class LUIAddon
local LUI = select(2, ...)
local script = LUI:NewScript("NewPlayerExp", "AceEvent-3.0", "AceHook-3.0")

local function S(x) return LUI:Scale(x) end

local GetShapeshiftFormInfo = _G.GetShapeshiftFormInfo
local FlyoutHasSpell = _G.FlyoutHasSpell
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetActionInfo = _G.GetActionInfo

local function moveUp(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", S(0), S(30))
end

local function moveAway(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", S(-300), S(-60))
end

function script:SetTutorialFrames()
	script:SecureHook(_G.TutorialKeyboardMouseFrame_Frame, "ShowTutorial", moveUp)
	moveUp(_G.TutorialKeyboardMouseFrame_Frame)

	script:SecureHook(_G.TutorialSingleKey_Frame, "ShowTutorial", moveUp)
	moveUp(_G.TutorialSingleKey_Frame)
	
	script:SecureHook(_G.TutorialMainFrame_Frame, "ShowTutorial", moveAway)
	moveAway(_G.TutorialMainFrame_Frame)

	script:SecureHook(_G.TutorialWalk_Frame, "ShowTutorial", moveAway)
	moveAway(_G.TutorialWalk_Frame)
end

-- Required for tutorial to let you point to abilities, adjusted for Bartender4.
-- https://www.townlong-yak.com/framexml/live/Blizzard_TutorialManager/Blizzard_TutorialHelper.lua
function script:GetActionButtonBySpellID(helper, spellID)
	if (type(spellID) ~= "number") then return end
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
	-- backup for stance bars
	for i = 1, GetNumShapeshiftForms() do
		local btn =  _G["BT4StanceButton"..i]
		local icon, isActive, isCastable, sID = GetShapeshiftFormInfo(btn:GetID())
		if (sID == spellID) then
			return btn
		end
	end
end

function script:FormatString(helper, str)
	-- Spell Names and Icons e.g. {$1234}
	str = string.gsub(str, "{%$(%d+)}", function(spellID)
			local name, _, icon = GetSpellInfo(spellID)
			return string.format("|cFF00FFFF%s|r", name)
		end)
	-- Spell Keybindings e.g. {KB|1234}
	str = string.gsub(str, "{KB|(%d+)}", function(spellID)
			local bindingString;
			if (spellID) then
				local btn = TutorialHelper:GetActionButtonBySpellID(tonumber(spellID))
				if btn then bindingString = btn:GetHotkey() end
			end
			return string.format("%s", bindingString or "?")
		end)
	-- Atlas icons e.g. {Atlas|NPE_RightClick:16}
	str = string.gsub(str, "{Atlas|([%w_-]+):?(%d*)}", function(atlasName, size)
				size = tonumber(size) or 0
				return CreateAtlasMarkup(atlasName, size, size)
			end)
	return str
end

function script:FindEmptyButton()
	for i = 1, 24 do
		local btn = _G["BT4Button"..i]
		if btn then
			local _, sID = GetActionInfo(btn:CalculateAction())
			if not sID then
				return btn;
			end
		end
	end
end

function script:ADDON_LOADED(event, addon)
	if addon == "Blizzard_NewPlayerExperience" then
		if IsAddOnLoaded("Bartender4") then self.BT4 = true end
		if self.BT4 then
			script:RawHook(_G.TutorialHelper, "FormatString", "FormatString", true)
			script:RawHook(_G.TutorialHelper, "GetActionButtonBySpellID", "GetActionButtonBySpellID", true)
			script:RawHook(_G.TutorialHelper, "FindEmptyButton", "FindEmptyButton", true)
		end
		
		script:SetTutorialFrames()
	end
end

script:RegisterEvent("ADDON_LOADED")
