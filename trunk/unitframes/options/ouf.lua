--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: ouf.lua
	Description: oUF Module
	Version....: 1.0
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local oUF = LUI.oUF
local Blizzard = LUI.Blizzard

module.defaults.profile.Settings = {
	ShowV2Textures = true,
	ShowV2PartyTextures = true,
	ShowV2ArenaTextures = true,
	ShowV2BossTextures = true,
	Castbars = true,
	HideBlizzRaid = false,
	AuratimerFont = "Prototype",
	AuratimerSize = 12,
	AuratimerFlag = "OUTLINE",
}

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}

function module:CreateSettings(order)
	local toggleV2 = function(info, Enable)
		for _, f in pairs({"oUF_LUI_targettarget", "oUF_LUI_targettargettarget", "oUF_LUI_focustarget", "oUF_LUI_focus"}) do
			if _G[f] then
				if not _G[f].V2Tex then
					if f == "oUF_LUI_targettarget" then
						module.funcs.V2Textures(oUF_LUI_targettarget, oUF_LUI_target)
					elseif f == "oUF_LUI_targettargettarget" then
						module.V2Textures(oUF_LUI_targettargettarget, oUF_LUI_targettarget)
					elseif f == "oUF_LUI_focustarget" then
						module.oUF_LUI.funcs.V2Textures(oUF_LUI_focustarget, oUF_LUI_focus)
					elseif f == "oUF_LUI_focus" then
						module.oUF_LUI.funcs.V2Textures(oUF_LUI_focus, oUF_LUI_player)
					end
				end
				if Enable then
					_G[f].V2Tex:Show()
				else
					_G[f].V2Tex:Hide()
				end
			end
		end
	end

	local toggleV2Party = function(info, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_partyUnitButton"..i.."target"]
			if f then
				if not f.V2Tex then module.funcs.V2Textures(f, _G["oUF_LUI_partyUnitButton"..i]) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end

	local toggleV2Arena = function(info, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_arenatarget"..i]
			if f then
				if not f.V2Tex then module.funcs.V2Textures(f, _G["oUF_LUI_arena"..i]) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end

	local toggleV2Boss = function(info, Enable)
		for i = 1, MAX_BOSS_FRAMES do
			local f = _G["oUF_LUI_bosstarget"..i]
			if f then
				if not f.V2Tex then module.funcs.V2Textures(f, _G["oUF_LUI_boss"..i]) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end

	local toggleCB = function(info, Enable)
		for unit, frames in pairs(self.framelist) do
			if self.defaults[unit].Castbar then
				for _, frame in pairs(frames) do
					if _G[frame] then
						frame = _G[frame]
						if Enable then
							if module.db[unit].Castbar.Enable ~= false then
								if not frame.Castbar then module.funcs.Castbar(frame, frame.__unit, module.db[unit]) end
								frame:EnableElement("Castbar")
								if unit == "Player" then
									Blizzard:Hide("castbar")
								end
							end
						else
							if frame.Castbar then
								frame:DisableElement("Castbar")
								frame.Castbar:Hide()
								if unit == "Player" then
									Blizzard:Show("castbar")
								end
							end
						end
						frame:UpdateAllElements()
					end
				end
			end
		end
	end

	local updateAuraTimer = function()
		for k, v in pairs(oUF.objects) do
			if v.Buffs then
				for i = 1, 50 do
					if v.Buffs[i] then
						v.Buffs[i].remaining:SetFont(Media:Fetch("font",  module.db.Settings.AuratimerFont), module.db.Settings.AuratimerSize, module.db.Settings.AuratimerFlag)
					else
						break
					end
				end
			end
			if v.Debuffs then
				for i = 1, 50 do
					if v.Debuffs[i] then
						v.Debuffs[i].remaining:SetFont(Media:Fetch("font",  module.db.Settings.AuratimerFont), module.db.Settings.AuratimerSize, module.db.Settings.AuratimerFlag)
					else
						break
					end
				end
			end
		end
	end

	local options = self:NewGroup("Settings", order, true, {
		ShowV2Textures = self:NewToggle("Show LUI v2 Connector Frames", "Whether you want to show LUI v2 Frame Connectors or not.", 1, toggleV2),
		ShowV2PartyTextures = self:NewToggle("Show LUI v2 Connector Frames for Party Frames", "Whether you want to show LUI v2 Frame Connectors on Party Frames or not.", 2, toggleV2Party),
		ShowV2ArenaTextures = self:NewToggle("Show LUI v2 Connector Frames for Arena Frames", "Whether you want to show LUI v2 Frame Connectors on Arena Frames or not.", 3, toggleV2Arena),
		ShowV2BossTextures = self:NewToggle("Show LUI v2 Connector Frames for Boss Frames", "Whether you want to show LUI v2 Frame Connectors on Boss Frames or not.", 4, toggleV2Boss),
		empty1 = self:NewDesc(" ", 5),
		Castbars = self:NewToggle("Enable Castbars", "Whether you want to use oUF Castbars or not.", 6, toggleCB),
		empty2 = self:NewDesc(" ", 7),
		AuratimerFont = self:NewSelect("Auratimer Font", "Choose the Font for Auratimers.", 8, widgetLists.font, "LSM30_Font", updateAuraTimer),
		AuratimerSize = self:NewSlider("Size", "Choose the Auratimers Fontsize.", 9, 5, 20, 1, updateAuraTimer),
		AuratimerFlag = self:NewSelect("Font Flag", "Choose the Font Flag for the Auratimers.", 10, fontflags, nil, updateAuraTimer),
		empty3 = self:NewDesc(" ", 11),
		Move = self:NewExecute("Move Unitframes", nil, 12, function() module:MoveUnitFrames() end),
	})

	return options
end
