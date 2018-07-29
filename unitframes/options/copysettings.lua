--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: copysettings.lua
	Description: oUF Copy Settings
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local Forte = LUI:Module("Forte")

local oUF = LUI.oUF

local units = {"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}

local function CopySettings(srcTable, dstTable, withSizes, withPosition)
	if type(srcTable) ~= "table" then return end
	if type(dstTable) ~= "table" then return end
	
	for k, v in pairs(srcTable) do
		if dstTable[k] ~= nil then
			if type(srcTable[k]) == "table" then
				CopySettings(srcTable[k], dstTable[k], withSizes, withPosition)
			elseif srcTable[k] ~= nil and dstTable[k] ~= nil then
				if k == "Height" or k == "Width" then
					if withSizes then dstTable[k] = srcTable[k] end
				elseif k == "Point" or k == "RelativePoint" or k == "X" or k == "Y" then
					if withPosition then dstTable[k] = srcTable[k] end
				else
					dstTable[k] = srcTable[k]
				end
			end
		end
	end
end

local CopyFuncs = {
	Castbar = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Castbar, module.db[dstUnit].Castbar, withSizes, withPosition)
	end,
	
	Auras = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Aura, module.db[dstUnit].Aura, withSizes, withPosition)
	end,
	
	Bars = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Health, module.db[dstUnit].Health, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Power, module.db[dstUnit].Power, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Full, module.db[dstUnit].Full, withSizes, withPosition)
		CopySettings(module.db[srcUnit].HealPrediction, module.db[dstUnit].HealPrediction, withSizes, withPosition)
	end,
	
	Icons = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Icons, module.db[dstUnit].Icons, withSizes, withPosition)
	end,
	
	Background = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Backdrop, module.db[dstUnit].Backdrop, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Border, module.db[dstUnit].Border, withSizes, withPosition)
	end,
	
	Texts = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Texts, module.db[dstUnit].Texts, withSizes, withPosition)
	end,
	
	Portrait = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Portrait, module.db[dstUnit].Portrait, withSizes, withPosition)
	end,
	
	Fader = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit].Fader, module.db[dstUnit].Fader, withSizes, withPosition)
	end,
	
	All = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(module.db[srcUnit], module.db[dstUnit], withSizes, withPosition)
	end
}

local settings = {
	toCopy = "All",
	srcUnit = "Player",
	dstUnit = "Target",
	withSizes = false,
	withPosition = false
}
	
StaticPopupDialogs["COPY_SETTINGS"] = {
	preferredIndex = 3,
	text = "Are you sure you want to copy the Settings?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function(self)
			CopyFuncs[settings.toCopy](settings.srcUnit, settings.dstUnit, settings.withSizes, settings.withPosition)
			module.ApplySettings(settings.dstUnit)
		end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local Current = function()
	local s = "Currently copying "..settings.toCopy.." from "..settings.srcUnit
	if settings.withSizes and settings.withPosition then
		s = s..", including Sizes and Positions"
	elseif settings.withSizes then
		s = s..", including Sizes"
	elseif settings.withPosition then
		s = s..", including Positions"
	end
	s = s.."."
	return s
end

function module:CreateCopyOptions(unit, order)
	local disabledFunc = function()
		if settings.toCopy == "All" or settings.toCopy == "Background" then return false end
		if module.db[unit][settings.toCopy] then return false end
		return true
	end
	
	-- partwise old way
	local options = {
		name = "Copy Settings",
		type = "group",
		order = order,
		disabled = function() return not self.db.Enable end,
		args = {
			desc = self:NewDesc("This is the Unitframe CopySettings page. Here you can choose which settings you want to copy from or to this/these Unitframe(s).", 1),
			empty1 = self:NewDesc(" ", 2),
			currently = self:NewDesc(Current, 3),
			Paste = self:NewExecute("Paste Settings", "Paste the chosen Settings.", 4, function() settings.dstUnit = unit; StaticPopup_Show("COPY_SETTINGS") end, nil, nil, disabledFunc),
			empty2 = self:NewDesc(" ", 5),
			Sizes = {
				name = "Include Sizes",
				type = "toggle",
				order = 6,
				get = function() return settings.withSizes end,
				set = function() settings.withSizes = not settings.withSizes end
			},
			Positions = {
				name = "Include Positions",
				type = "toggle",
				order = 7,
				get = function() return settings.withPosition end,
				set = function() settings.withPosition = not settings.withPosition end
			},
			empty3 = self:NewDesc(" ", 8),
			Castbar = self.db[unit].Castbar and self:NewExecute("Copy Castbar", "Move the Castbar Settings of this Unitframe into the temporary storage.", 8, function() settings.toCopy = "Castbar"; settings.srcUnit = unit end) or nil,
			Aura = self.db[unit].Aura and self:NewExecute("Copy Aura", "Move the Aura Settings of this Unitframe into the temporary storage.", 9, function() settings.toCopy = "Auras"; settings.srcUnit = unit end) or nil,
			Bars = self:NewExecute("Copy Bars", "Move the Bar Settings of this Unitframe into the temporary storage.", 10, function() settings.toCopy = "Bars"; settings.srcUnit = unit end),
			Icons = self.db[unit].Icons and self:NewExecute("Copy Icons", "Move the Icon Settings of this Unitframe into the temporary storage.", 11, function() settings.toCopy = "Icons"; settings.srcUnit = unit end) or nil,
			Background = self:NewExecute("Copy Background", "Move the Background Settings of this Unitframe into the temporary storage.", 12, function() settings.toCopy = "Background"; settings.srcUnit = unit end),
			Texts = self:NewExecute("Copy Texts", "Move the Text Settings of this Unitframe into the temporary storage.", 13, function() settings.toCopy = "Texts"; settings.srcUnit = unit end),
			Portrait = self:NewExecute("Copy Portrait", "Move the Portrait Settings of this Unitframe into the temporary storage.", 14, function() settings.toCopy = "Portrait"; settings.srcUnit = unit end),
			Fader = self.db[unit].Fader and self:NewExecute("Copy Fader", "Move the Fader Settings of this Unitframe into the temporary storage.", 15, function() settings.toCopy = "Fader"; settings.srcUnit = unit end) or nil,
			All = self:NewExecute("Copy All", "Move all Settings of this Unitframe into the temporary storage.", 16, function() settings.toCopy = "All"; settings.srcUnit = unit end),
		}
	}
	
	return options
end
