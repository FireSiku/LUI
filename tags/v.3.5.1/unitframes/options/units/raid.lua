--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: raid.lua
	Description: oUF Raid Module
	Version....: 1.0
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_Raid")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

local db

local ufNamesListRaid = {}
do
	for i = 1, 5 do
		for j = 1, 5 do
			table.insert(ufNamesListRaid, "oUF_LUI_raid_25_"..i.."UnitButton"..j)
		end
	end

	for i = 1, 8 do
		for j = 1, 5 do
			table.insert(ufNamesListRaid, "oUF_LUI_raid_40_"..i.."UnitButton"..j)
		end
	end
end

local defaults = {
	Raid = {
		Enable = true,
		Height = "33",
		Width = "77.5",
		X = "-28.5",
		Y = "40.5",
		Point = "BOTTOMRIGHT",
		Padding = "4",
		GroupPadding = "4",
		Border = {
			Aggro = true,
			Target = true,
			EdgeFile = "glow",
			EdgeSize = 5,
			Insets = {
				Left = "3",
				Right = "3",
				Top = "3",
				Bottom = "3",
			},
			Color = {
				r = "0",
				g = "0",
				b = "0",
				a = "1",
			},
		},
		Backdrop = {
			Texture = "Blizzard Tooltip",
			Padding = {
				Left = "-4",
				Right = "4",
				Top = "4",
				Bottom = "-4",
			},
			Color = {
				r = 0,
				g = 0,
				b = 0,
				a = 1,
			},
		},
		Health = {
			Height = "26",
			Padding = "0",
			Color = "Individual",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Gradient",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			BGInvert = false,
			Smooth = true,
			IndividualColor = {
				r = 0.25,
				g = 0.25,
				b = 0.25,
			},
		},
		Power = {
			Enable = true,
			Height = "5",
			Padding = "-2",
			Color = "By Class",
			Texture = "LUI_Minimalist",
			TextureBG = "LUI_Minimalist",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			BGInvert = false,
			Smooth = true,
			IndividualColor = {
				r = 0.8,
				g = 0.8,
				b = 0.8,
			},
		},
		Full = {
			Enable = false,
			Height = "14",
			Texture = "LUI_Minimalist",
			Padding = "-12",
			Alpha = 1,
			Color = {
				r = "0.11",
				g = "0.11",
				b = "0.11",
				a = "1",
			},
		},
		HealPrediction = {
			Enable = false,
			Texture = "LUI_Gradient",
			MyColor = {
				r = 0,
				g = 0.5,
				b = 0,
				a = 0.25
			},
			OtherColor = {
				r = 0,
				g = 1,
				b = 0,
				a = 0.25
			}
		},
		CornerAura = {
			Enable = true,
			Size = "8",
			Inset = "1",
		},
		RaidDebuff = {
			Enable = true,
			Size = "16",
		},
		Portrait = {
			Enable = false,
			Height = "28",
			Width = "77.5",
			X = "0",
			Y = "0",
			Alpha = 1,
		},
		Icons = {
			Lootmaster = {
				Enable = false,
				Size = 16,
				X = "17",
				Y = "10",
				Point = "TOPLEFT",
			},
			Leader = {
				Enable = false,
				Size = 17,
				X = "0",
				Y = "10",
				Point = "TOPLEFT",
			},
			Role = {
				Enable = false,
				Size = 22,
				X = "15",
				Y = "10",
				Point = "TOPRIGHT",
			},
			Raid = {
				Enable = false,
				Size = 25,
				X = "0",
				Y = "10",
				Point = "CENTER",
			},
			ReadyCheck = {
				Enable = true,
				Size = 20,
				X = "0",
				Y = "0",
				Point = "CENTER",
			},
		},
		Texts = {
			Name = {
				Enable = true,
				Font = "vibroceb",
				Size = 11,
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Format = "Name",
				Length = "Medium",
				ColorByClass = true,
				ShowDead = true,
			},
			Health = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "-43",
				Color = "Individual",
				ShowAlways = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Absolut Short",
				ShowDead = false,
			},
			Power = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "-66",
				Color = "By Class",
				ShowFull = true,
				ShowEmpty = true,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Absolut Short",
			},
			HealthPercent = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "6",
				Color = "Individual",
				ShowAlways = false,
				IndividualColor = {
					r = "1",
					g = "1",
					b = "1",
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
				ShowDead = true,
			},
			PowerPercent = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
			},
			HealthMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShortValue = true,
				ShowAlways = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "RIGHT",
				RelativePoint = "RIGHT",
			},
			PowerMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 12,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShortValue = true,
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "RIGHT",
				RelativePoint = "RIGHT",
			},
		},
	}
}

function module:LoadOptions()
	local oufdb = db.oUF.Raid
	local oufdefaults = LUI.defaults.profile.oUF.Raid
	
	local ToggleInfoText = function(Info, Enable)
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then
				if Enable then
					_G[frame].Info:Show()
				else
					_G[frame].Info:Hide()
				end
			end
		end
	end
	
	local ApplyInfoText = function()
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then LUI.oUF.funcs.RaidInfo(_G[frame], _G[frame].__unit, oufdb) end
		end
	end
	
	local ToggleCornerAura = function(Info, Enable)
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then
				if not _G[frame].SingleAuras then LUI.oUF.funcs.SingleAuras(_G[frame], _G[frame].__unit, oufdb) end
				if Enable then
					_G[frame]:EnableElement("SingleAuras")
				else
					_G[frame]:DisableElement("SingleAuras")
				end
			end
		end
	end
	
	local ApplyCornerAura = function()
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then LUI.oUF.funcs.CornerAura(_G[frame], _G[frame].__unit, oufdb) end
		end
	end
	
	local ToggleRaidDebuff = function(Info, Enable)
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then
				if not _G[frame].RaidDebuffs then LUI.oUF.funcs.RaidDebuffs(_G[frame], _G[frame].__unit, oufdb) end
				if Enable then
					_G[frame]:EnableElement("RaidDebuffs")
				else
					_G[frame]:DisableElement("RaidDebuffs")
				end
			end
		end
	end
	
	local ApplyRaidDebuff = function()
		for _, frame in pairs(ufNamesListRaid) do
			if _G[frame] then LUI.oUF.funcs.RaidDebuffs(_G[frame], _G[frame].__unit, oufdb) end
		end
	end
	
	local ChangeGroupPadding = function()
		for i = 2, 5 do
			_G["oUF_LUI_raid_25_"..i]:ClearAllPoints()
			_G["oUF_LUI_raid_25_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_25_"..i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
		end
		
		for i = 2, 8 do
			_G["oUF_LUI_raid_40_"..i]:ClearAllPoints()
			_G["oUF_LUI_raid_40_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_40_"..i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
		end
		
		local width40 = (5 * tonumber(db.oUF.Raid.Height) - 3 * tonumber(db.oUF.Raid.GroupPadding)) / 8
		
		LUI.oUF.RecreateNameCache()
		
		for i = 1, 8 do
			_G["oUF_LUI_raid_40_"..i]:SetAttribute("initialConfigFunction", [[
				self:SetHeight(]]..db.oUF.Raid.Height..[[)
				self:SetWidth(]]..width40..[[)
			]])
			for j = 1, 5 do
				if _G["oUF_LUI_raid_40_"..i.."UnitButton"..j] then
					_G["oUF_LUI_raid_40_"..i.."UnitButton"..j]:SetWidth(width40)
					_G["oUF_LUI_raid_40_"..i.."UnitButton"..j]:FormatRaidName()
				end
			end
		end
	end
	
	local options = {
		Raid = {
			args = {
				General = {
					args = {
						General = {
							args = {
								GroupPadding = LUI:NewInputNumber("Group Padding", "Choose the Padding between your Raidframe Groups", 8, oufdb, "GroupPadding", oufdefaults, ChangeGroupPadding, nil, function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end),
							},
						},
					},
				},
				Texts = {
					args = {
						Name = {
							name = "Name",
							type = "group",
							order = 1,
							args = {
								Enable = LUI:NewToggle("Enable", "Whether you want to show the Raid Name or not.", 1, oufdb.Texts.Name, "Enable", oufdefaults.Texts.Name, ApplyInfoText),
								FontSettings = {
									name = "Font Settings",
									type = "group",
									disabled = function() return not oufdb.Texts.Name.Enable end,
									guiInline = true,
									order = 2,
									args = {
										FontSize = LUI:NewSlider("Size", "Choose the Raid Name Fontsize.", 1, oufdb.Texts.Name, "Size", oufdefaults.Texts.Name, 1, 40, 1, ApplyInfoText),
										empty = LUI:NewEmpty(2),
										Font = LUI:NewSelect("Font", "Choose the Font for Raid Name.", 3, widgetLists.font, "LSM30_Font", oufdb.Texts.Name, "Font", oufdefaults.Texts.Name, ApplyInfoText),
										FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for Raid Name.", 4, fontflags, nil, oufdb.Texts.Name, "Outline", oufdefaults.Texts.Name, ApplyInfoText),
										empty2 = LUI:NewEmpty(5),
										ColorByClass = LUI:NewToggle("Color Name by Class", "Whether you want to color the Raid Name by Class or not.", 6, oufdb.Texts.Name, "ColorByClass", oufdefaults.Texts.Name, ApplyInfoText, "normal"),
										Color = LUI:NewColorNoAlpha("", "Name Text", 7, oufdb.Texts.Name.IndividualColor, oufdefaults.Texts.Name.IndividualColor, ApplyInfoText),
										empty3 = LUI:NewEmpty(8),
										ShowDead = LUI:NewToggle("Show Dead/AFK/Disconnected", "Whether you want to switch the Name to Dead/AFK/Disconnected or not.", 9, oufdb.Texts.Name, "ShowDead", oufdefaults.Texts.Name, ApplyInfoText),
									},
								},
							},
						},
					},
				},
				Other = {
					name = "Raid Specific",
					type = "group",
					disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
					order = 9,
					childGroups = "tab",
					args = {
						EnableSingleAuras = LUI:NewToggle("Enable Corner Auras", "Whether you want to show the Corner Indicator Icons or not.", 1, oufdb.CornerAura, "Enable", oufdefaults.CornerAura, ToggleCornerAura),
						SingleAuras = {
							name = "Corner Auras",
							type = "group",
							order = 2,
							guiInline = true,
							disabled = function() return not oufdb.CornerAura.Enable end,
							args = {
								Size = LUI:NewInputNumber("Size", "Choose the Size for the Corner Aura Indicators", 1, oufdb.CornerAura, "Size", oufdefaults.CornerAura, ApplyCornerAura),
								Inset = LUI:NewInputNumber("Inset", "Choose the Inset for the Corner Aura Indicators", 2, oufdb.CornerAura, "Inset", oufdefaults.CornerAura, ApplyCornerAura),
								empty = LUI:NewEmpty(3),
							},
						},
						empty = LUI:NewEmpty(3),
						Enable = LUI:NewToggle("Enable Raid Debuffs", "Whether you want to show the Centered Raid Debuffs or not.", 4, oufdb.RaidDebuff, "Enable", oufdefaults.RaidDebuff, ToggleRaidDebuff),
						RaidDebuffs = {
							name = "Raid Debuffs",
							type = "group",
							order = 5,
							guiInline = true,
							disabled = function() return not oufdb.RaidDebuff.Enable end,
							args = {
								Size = LUI:NewInputNumber("Size", "Choose the Size for the Raid Debuff Icons.", 2, oufdb.RaidDebuff, "Size", oufdefaults.RaidDebuff, ApplyRaidDebuff),
							},
						},
					},
				},
			},
		},
	}
	
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile.oUF, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterUnitFrame(self)
end

function module:OnEnable()
end
