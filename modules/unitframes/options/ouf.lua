--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: ouf.lua
	Description: oUF Module
	Version....: 1.0
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Unitframes
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")

---@class oUF
local oUF = LUI.oUF

local widgetLists = AceGUIWidgetLSMlists
local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", ""}

function module:CreateSettings(order)
	local toggleV2 = function(info, Enable)
		for _, f in pairs({"oUF_LUI_targettarget", "oUF_LUI_targettargettarget", "oUF_LUI_focustarget", "oUF_LUI_focus"}) do
			if _G[f] then
				if not _G[f].V2Tex then
					if f == "oUF_LUI_targettarget" then
						module.funcs.V2Textures(oUF_LUI_targettarget, oUF_LUI_target)
					elseif f == "oUF_LUI_targettargettarget" then
						module.funcs.V2Textures(_G.oUF_LUI_targettargettarget, oUF_LUI_targettarget)
					elseif f == "oUF_LUI_focustarget" then
						module.funcs.V2Textures(oUF_LUI_focustarget, oUF_LUI_focus)
					elseif f == "oUF_LUI_focus" then
						module.funcs.V2Textures(oUF_LUI_focus, oUF_LUI_player)
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
		for i = 1, _G.MAX_BOSS_FRAMES do
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
							if module.db.profile[unit].Castbar.General.Enable ~= false then
								if not frame.Castbar then module.funcs.Castbar(frame, frame.__unit, module.db.profile[unit]) end
								frame:EnableElement("Castbar")
							end
						else
							if frame.Castbar then
								frame:DisableElement("Castbar")
								frame.Castbar:Hide()
							end
						end
						frame:UpdateAllElements('refreshUnit')
					end
				end
			end
		end
	end

	local updateAuraTimer = function()
		for unit, frames in pairs(module.framelist) do
			local db = module.db.profile[unit]
			if db and db.Aura then
				for _, frameName in pairs(frames) do
					local frame = _G[frameName]
					if frame then
						if db.Aura.Buffs and db.Aura.Buffs.Enable then
							module.funcs.Buffs(frame, frame.__unit, db)
						end
						if db.Aura.Debuffs and db.Aura.Debuffs.Enable then
							module.funcs.Debuffs(frame, frame.__unit, db)
						end
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
