--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: minusbuff.lua
	Description: Automatically remove all those annoying buffs for you.
	Version....: 1.0
	Rev Date...: 06/10/2012 [dd/mm/yyyy]
	Author.....: Mule
]]

-- ####################################################################################################################
-- ##### External references ##########################################################################################
-- ####################################################################################################################
local _, LUI = ...
local module = LUI:Module("RemoveThatBuff", "AceEvent-3.0")
local Profiler = LUI.Profiler

-- ####################################################################################################################
-- ##### Database and defaults shortcuts ##############################################################################
-- ####################################################################################################################
local db, dbd

Profiler.TraceScope(module, "RemoveThatBuff", "LUI")

module.defaults = {
	profile = {
		Enable = false,
		Buffs = {
		},
	},
}

module.presetList = {
	["Mohawked!"] = true,
	["Jack-o'-Lanterned!"] = true,
	["Pirate Costume"] = true,
	["Leper Gnome Costume"] = true,
	["Bat Costume"] = true,
	["Ghost Costume"] = true,
	["Ninja Costume"] = true,
	["Wisp Costume"] = true,
	["Skeleton Costume"] = true,
	["Turkey Feathers"] = true,
	["Rabbit Costume"] = true,
}

function module:UNIT_AURA(_, unitid, ...)
	if unitid ~= "player" or InCombatLockdown() then
		return
	else
		for i = 1, 40 do
			local name = UnitAura("player", i)
			if db.Buffs[name] then
				CancelUnitBuff("player", i)
			end
		end
	end
end

module.optionsName = "RemoveThatBuff"
module.getter = "generic"
module.setter = "generic"

function module:AddBuff(_, buffname)
	db.Buffs[buffname] = true
end

function module:LoadOptions()
	local buffList = {}

	local disabled = {
		Enable = function() return not db.Enable end,
		NoBuffsSelected = function() return not removeBuffsKey end,
		NoBuffs = function() return not next(buffList) end,
	}

	local function buffsGet(_) return removeBuffsKey end
	local function buffsSet(_, value)  removeBuffsKey = value end
	local function removeBuffs()
		if removeBuffsKey then
			db.Buffs[removeBuffsKey] = nil
			removeBuffsKey = nil
		end
	end

	local function addDefaultList()
		for name, _ in pairs(module.presetList) do
			db.Buffs[name] = true
		end
	end

	local function buffs()
		wipe(buffList)
		for name, _ in pairs(db.Buffs) do
			buffList[name] = name
		end
		return buffList
	end

	local options = {
		Title = self:NewHeader("RemoveThatBuff", 1),
		Enable = self:NewToggle("Enable RemoveThatBuff", nil, 2, true),
		AddPresets = self:NewExecute("Add Presets", "Add a list of 11 buffs (this will retain your additions).  Buffs that will be added:\nMohawked!\nJack-o'-Lanterned!\nPirate Costume\nLeper Gnome Costume\nBat Costume\nGhost Costume\nNinja Costume\nWisp Costume\nSkeleton Costume\nTurkey Feathers\nRabbit Costume", 3, addDefaultList, nil, nil, disabled.Enable),
		AddBuffs = self:NewGroup("Add Buffs", 4, LUI.dummy, "AddBuff", true, disabled.Enable, {
			InputBuff = self:NewInput("Enter the name of a buff", nil, 2, false)
		}),
		RemoveBuffs = self:NewGroup("Remove Buffs", 5, buffsGet, buffsSet, true, disabled.Enable, {
			Select = self:NewSelect("Select Buff", "Select the buff which you want to remove from the list.", 1, buffs, nil, false, "double", disabled.NoBuffs or disabled.Enable),
			Remove = self:NewExecute("Remove selected buff", "Removes the selected buff from the list.", 2, removeBuffs, nil, nil, disabled.NoBuffsSelected or disabled.Enable),
		}),
	}
	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function module:OnEnable()
	self:RegisterEvent("UNIT_AURA")
end

function module:OnDisable()
	self:UnregisterAllEvents()
end
