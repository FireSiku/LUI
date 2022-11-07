-- Dualspec Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Dualspec", "AceEvent-3.0")

-- local copies
local select, format, tconcat = select, format, table.concat
local tonumber, tostring = tonumber, tostring
local strsplit = string.split
local PanelTemplates_GetSelectedTab = _G.PanelTemplates_GetSelectedTab
local GetTalentInfoByID = _G.GetTalentInfoByID
-- local GetLootTalent = GetLootSpecialization
local PanelTemplates_SetTab = _G.PanelTemplates_SetTab
local GetTalentInfo = _G.GetTalentInfo
local GetActiveSpecGroup = _G.GetActiveSpecGroup
local GetPrimaryTalentTree = _G.GetPrimaryTalentTree
local SetPrimaryTalentTree = _G.SetPrimaryTalentTree
local GetActiveTalentGroup = _G.GetActiveTalentGroup
local GetNumTalentGroups = _G.GetNumTalentGroups
local GetNumTalentTabs = _G.GetNumTalentTabs
local GetTalentInfo = _G.GetTalentInfo
local ShowUIPanel = _G.ShowUIPanel
local HideUIPanel = _G.HideUIPanel

-- constants
local LOOT_SPECIALIZATION_DEFAULT = strsplit("(", LOOT_SPECIALIZATION_DEFAULT):trim()
local SELECT_LOOT_SPECIALIZATION = SELECT_LOOT_SPECIALIZATION
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local LEVEL_UP_DUALSPEC = LEVEL_UP_DUALSPEC
local MAX_SPECS -- Set this during OnCreate
local TALENT_DELIMITER = ""

-- locals
local specCache = {}  -- Keep information about specs.
local talentCache = {} -- Keep information about talents.
local inactiveCache = {} -- Keep information about inactive specs
local needNewCache = false

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

element.Events = (UnitLevel("player") < 10) and {"PLAYER_LEVEL_UP"} or {"PLAYER_TALENT_UPDATE"}

function element.PLAYER_LEVEL_UP()
	if tonumber(level) >= 10 then
		self:UnregisterEvent("PLAYER_LEVEL_UP")
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self.Events = {"PLAYER_TALENT_UPDATE"}

		self.Hidden = false
		self:Show()

		self:PLAYER_TALENT_UPDATE()
	end
end

function element.PLAYER_TALENT_UPDATE()
	for i = 1, GetNumTalentGroups() do
		specCache[i] = specCache[i] or {}
		local thisCache = specCache[i]
		TalentFrame_UpdateSpecInfoCache(thisCache, false, false, i)

		thisCache.defined = thisCache.primaryTabIndex and thisCache.primaryTabIndex ~= 0
		if thisCache.defined then
			thisCache.specName = thisCache[thisCache.primaryTabIndex].name
			thisCache.mainTabIcon = thisCache[thisCache.primaryTabIndex].icon
		else
			thisCache.specName = "|cffff0000Talents undefined!|r"
			thisCache.mainTabIcon = "Interface\\Icons\\Spell_Nature_MoonKey"
		end
	end

	local activeTalentGroup = GetActiveTalentGroup()
	local curCache = specCache[activeTalentGroup]
	if not curCache then
		self.text:SetText("|cffff0000Talents unavailable!|r")
		return
	end

	local text = " "..curCache.specName
	if module.db.profile.ShowSpentPoints then
		if curCache.defined then
			local a = curCache[1].pointsSpent or 0
			local b = curCache[2].pointsSpent or 0
			local c = curCache[3].pointsSpent or 0
			text = (text .. " (" .. a .. "/" .. b .. "/" .. c .. ")")
		end
	end

	-- text:SetText(text)
	-- icon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = {top = 0, right = 0, bottom = 0, left = 0}})
end
function element:UpdateTalents()
	needNewCache = true
	-- element:UpdateSpec()
	element.text = format(L["InfoBags_Text_Format"])
end

function element.OnClick(frame_, button)
	if button == "RightButton" then -- Toggle TalentFrame
		if PlayerTalentFrame:IsVisible() and (PanelTemplates_GetSelectedTab(PlayerTalentFrame) == 1) then
			PlayerTalentFrame:Hide()
		else
			PanelTemplates_SetTab(PlayerTalentFrame, 1)
			PlayerTalentFrame_Refresh()
			PlayerTalentFrame:Show()
		end
	else -- Switch talent spec
		if GetNumTalentGroups() < 2 then return	end

		SetActiveTalentGroup(3 - GetActiveTalentGroup())
	end
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow()
	element:TooltipHeader(LEVEL_UP_DUALSPEC)

	-- local activeSpec = GetSpecialization()
	-- local dualspecHint = ""

	-- for i = 1, MAX_SPECS do
	-- 	local specNum = (format(L["InfoDualspec_Spec_Num"], i))
	-- 	local specName = (specCache[i].name)

	-- 	if i == activeSpec then
	-- 		local highlight = CreateColor(1, 1, 0)
	-- 		specNum = highlight:WrapTextInColorCode(specNum)
	-- 		specName = highlight:WrapTextInColorCode(specName)
	-- 	end
	-- 	GameTooltip:AddDoubleLine(specNum, specName, 1,1,1, 1,1,1)
	-- end


	GameTooltip:SetOwner(self, getOwnerAnchor(self))
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Dual Spec:", 0.4, 0.78, 1)
	GameTooltip:AddLine(" ")

	local activeTalentGroup = GetActiveTalentGroup()

	for i = 1, GetNumTalentGroups() do
		local thisCache = specCache[i]
		local text = (((i == 1) and "Primary" or "Secondary") .. " Spec" .. ((i == activeTalentGroup) and " (active):" or ":"))
		local text2 = thisCache.specName

		if thisCache.primaryTabIndex and thisCache.primaryTabIndex ~= 0 then
			local a = thisCache[1].pointsSpent or 0
			local b = thisCache[2].pointsSpent or 0
			local c = thisCache[3].pointsSpent or 0
			text2 = (text2 .. " (" .. a .. "/" .. b .. "/" .. c .. ")")
		end

		GameTooltip:AddDoubleLine(text, text2, 1,1,1, 1,1,1)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Hint:\n- Left-Click to switch talent group.\n- Right-Click to open Talent Frame.\n- Any Click on the Icon to open Glyph.", 0, 1, 0)
	GameTooltip:Show()

	element:AddHint(dualspecHint) -- .. L["InfoDualspec_Hint_Shift"]
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	MAX_SPECS = GetNumTalentTabs()

	if UnitLevel("player") < 10 then
		self.text:SetText("|cffff0000Talents Unavailable!|r")
		self.Hidden = true
		self:Hide()
	else
		self:PLAYER_TALENT_UPDATE()
	end

	-- element:CacheSpecInfo()
	element:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents")
	-- element:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED", "UpdateSpec")
	element:UpdateTalents()
end
