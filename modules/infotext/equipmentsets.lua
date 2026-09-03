-- EquipmentSets Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("EquipmentSets", "AceEvent-3.0")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:UpdateEquipmentSet()
	local db = module.db.profile.EquipmentSets
	for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
		local name, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
		if isEquipped then
			element.text = format("%s%s", db.Text, name)
			return
		end
	end
	element.text = "No Equipped Set"
end

function element.OnClick()
	_G.ToggleCharacter("PaperDollFrame")
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEquipmentSet")
	element:RegisterEvent("EQUIPMENT_SWAP_FINISHED", "UpdateEquipmentSet")
	element:RegisterEvent("EQUIPMENT_SETS_CHANGED", "UpdateEquipmentSet")
	element:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateEquipmentSet")
	element:UpdateEquipmentSet()
end

element.RefreshSettings = element.UpdateEquipmentSet
