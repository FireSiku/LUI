--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: forte.lua
	Description: FortExorcist Module
	Version....: 1.0
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Forte", "AceHook-3.0")
local _, class = UnitClass("player")

local db

function module:SetPosForte()
	if not LUI.isForteTimerLoaded or not db.Forte.Lock or not db.oUF.Settings.Enable then return end

	local fxwidth = tonumber(db.oUF.Player.Width)
	local fxscale = tonumber(FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["scale"])
	fxwidth = fxwidth / fxscale
	
	local f = oUF_LUI_player
	local uiScale = UIParent:GetEffectiveScale()
	local s = f:GetEffectiveScale()
	
	Timer_X = f:GetLeft() * uiScale + (f:GetWidth() / 2 * s )
	Timer_Y = f:GetBottom() * uiScale + (f:GetHeight() * s ) + 9
	
	if class == "DEATHKNIGHT" then
		if db.oUF.Player.Runes.Enable == true then
			if db.oUF.Player.Runes.Lock == true then
				Timer_Y = Timer_Y + (tonumber(db.oUF.Player.Runes.Height)*f.Runes:GetEffectiveScale())
			end
		end
	elseif class == "SHAMAN" then
		if db.oUF.Player.Totems.Enable == true then
			if db.oUF.Player.Totems.Lock == true then
				Timer_Y = Timer_Y + (tonumber(db.oUF.Player.Totems.Height)*f.TotemBar[1]:GetEffectiveScale())
			end
		end
	elseif class == "DRUID" then
		if db.oUF.Player.Eclipse.Enable == true and oUF_LUI_player.EclipseBar:IsShown() then
			if db.oUF.Player.Eclipse.Lock == true then
				Timer_Y = Timer_Y + (tonumber(db.oUF.Player.Eclipse.Height)*f.EclipseBar:GetEffectiveScale())
			end
		end
	elseif class == "PALADIN" then
		if db.oUF.Player.HolyPower.Enable == true then
			if db.oUF.Player.HolyPower.Lock == true then
				Timer_Y = Timer_Y + (tonumber(db.oUF.Player.HolyPower.Height)*f.HolyPower:GetEffectiveScale())
			end
		end
	elseif class == "WARLOCK" then
		if db.oUF.Player.SoulShards.Enable == true then
			if db.oUF.Player.SoulShards.Lock == true then
				Timer_Y = Timer_Y + (tonumber(db.oUF.Player.SoulShards.Height)*f.SoulShards:GetEffectiveScale())
			end
		end
	end
	
	Timer_X = Timer_X + tonumber(db.Forte.Timer_PaddingX)
	Timer_Y = Timer_Y + tonumber(db.Forte.Timer_PaddingY)
	
	FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Width"] = fxwidth
	FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["x"] = Timer_X
	FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["y"] = Timer_Y
	
	FW:RefreshFrames()
end

function module:SetPosForteCooldown()
	if not LUI.isForteCooldownLoaded or not db.Forte.CDLock then return end
	
	local uiScale = UIParent:GetEffectiveScale()
	local Cooldown_X = (UIParent:GetWidth() * uiScale / 2) + tonumber(db.Forte.Cooldown_PaddingX)
	local Cooldown_Y = tonumber(db.Forte.Cooldown_PaddingY) * uiScale
	
	FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["x"] = Cooldown_X
	FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["y"] = Cooldown_Y

	FW:RefreshFrames()
end

function module:SetColors()
	if not LUI.isForteTimerLoaded then return end
	
	if db.Forte.IndividualSparkColor == true then
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["SparkColor"] = {unpack(db.Forte.SparkColor)}
	else
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["SparkColor"] = {unpack(db.Colors.color_top)}
	end
	
	local fxColor = {unpack(db.Forte.Color)}
	
	if db.Forte.IndividualColor == true then
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["HighlightColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["CooldownsColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["DebuffsColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["HealColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["FailColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["CrowdColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["BuffColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["FriendlyBuffColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["CurseColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["PetColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["MagicColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["DrainColor"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Shared3Color"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Shared2Color"] = {unpack(fxColor)}
		FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["SelfDebuffColor"] = {unpack(fxColor)}
	end
	
	FW:RefreshFrames()
end

function module:SetForte()
	self:SetColors()
	self:SetPosForte()
	self:SetPosForteCooldown()
end

local defaults = {
	Forte = {
		Enable = true,
		CDLock = "true",
		Lock = "true",
		IndividualColor = false,
		IndividualSparkColor = false,
		Color = {0.24,0.24,0.24},
		SparkColor = {0.8,0.8,0.8},
		Timer_PaddingX = "0",
		Timer_PaddingY = "0",
		Cooldown_PaddingX = "0",
		Cooldown_PaddingY = "120",
	},
}

function module:LoadOptions()
	local options = {
		Forte = {
			name = "ForteXorcist",
			type = "group",
			order = 70,
			childGroups = "tab",
			disabled = function() return not IsAddOnLoaded("Forte_Core") end,
			args = {
				Spelltimer = {
					name = "Spelltimer",
					type = "group",
					disabled = function()
							if IsAddOnLoaded("Forte_Core") and IsAddOnLoaded("Forte_Timer") then
								if FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Enable"] ~= nil then
									if FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Enable"] == true then
										return false
									else
										return true
									end
								else
									return true
								end
							else
								return true
							end
						end,
					order = 2,
					args = {
						Position = {
							name = "Position",
							type = "group",
							order = 1,
							guiInline = true,
							args = {
								ForteLock = {
									name = "Lock Spelltimer",
									desc = "Whether the Spelltimer should stick to your PlayerFrame or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.Lock end,
									set = function(self,ForteLock)
											db.Forte.Lock = not db.Forte.Lock
											if ForteLock == true then
												module:SetPosForte()
											end
										end,
									order = 1,
								},
								PaddingX = {
									name = "Padding X",
									desc = "Choose the X Padding for your Forte SpellTimer.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Timer_PaddingX,
									type = "input",
									get = function() return db.Forte.Timer_PaddingX end,
									set = function(self,PaddingX)
											if PaddingX == nil or PaddingX == "" then
												PaddingX = "0"
											end
											db.Forte.Timer_PaddingX = PaddingX
											module:SetPosForte()
										end,
									order = 2,
								},
								PaddingY = {
									name = "Padding Y",
									desc = "Choose the Y Padding for your Forte SpellTimer.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Timer_PaddingY,
									type = "input",
									get = function() return db.Forte.Timer_PaddingY end,
									set = function(self,PaddingY)
											if PaddingY == nil or PaddingY == "" then
												PaddingY = "0"
											end
											db.Forte.Timer_PaddingY = PaddingY
											module:SetPosForte()
										end,
									order = 3,
								},
							},
						},
						Colors = {
							name = "Colors",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								header1 = {
									name = "Bar Color",
									type = "header",
									order = 1,
								},
								IndividualColor = {
									name = "Individual Color",
									desc = "Whether you want to use an individual Color for all your tracked Buffs/Debuffs or not.\n\nNote: If you want different colors for each of your spells please disable both options (HealthbarColor/Individual Color) and type /fx to enter FortExorcist Options and go to Spelltimer -> Coloring/Filtering",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.IndividualColor end,
									set = function(self,IndividualColor)
											db.Forte.IndividualColor = not db.Forte.IndividualColor
											if IndividualColor == true then
												if db.Forte.UseHealthbarColor == true then
													db.Forte.UseHealthbarColor = false
												end
												
												module:SetColors()
											end
										end,
									order = 2,
								},
								Color = {
									name = "Bar Color",
									desc = "Choose an individual Bar Color.",
									type = "color",
									width = "full",
									disabled = function() return not db.Forte.IndividualColor end,
									hasAlpha = false,
									get = function() return unpack(db.Forte.Color) end,
									set = function(_,r,g,b)
											db.Forte.Color = {r,g,b}
											
											module:SetColors()
										end,
									order = 4,
								},
								header2 = {
									name = "Spark Color",
									type = "header",
									order = 5,
								},
								IndividualSparkColor = {
									name = "Individual Spark Color",
									desc = "Whether you want to use an individual Spark Color for all your tracked Buffs/Debuffs or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.IndividualSparkColor end,
									set = function(self,IndividualSparkColor)
											db.Forte.IndividualSparkColor = not db.Forte.IndividualSparkColor
											if IndividualSparkColor == true then
												if db.Forte.UseThemeColor == true then
													db.Forte.UseThemeColor = false
												end
												
												module:SetColors()
											end
										end,
									order = 6,
								},
								SparkColor = {
									name = "Spark Color",
									desc = "Choose an individual Spark Color.",
									type = "color",
									width = "full",
									disabled = function() return not db.Forte.IndividualSparkColor end,
									hasAlpha = false,
									get = function() return unpack(db.Forte.SparkColor) end,
									set = function(_,r,g,b)
											db.Forte.SparkColor = {r,g,b}
											
											module:SetColors()
										end,
									order = 7,
								},
							},
						},
					},
				},
				Cooldowntimer = {
					name = "Cooldowntimer",
					type = "group",
					disabled = function()
							if IsAddOnLoaded("Forte_Core") and IsAddOnLoaded("Forte_Cooldown") then
								if FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["Enable"] ~= nil then
									if FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["Enable"] == true then
										return false
									else
										return true
									end
								else
									return true
								end
							else
								return true
							end
						end,
					order = 3,
					args = {
						Position = {
							name = "Position",
							type = "group",
							order = 1,
							guiInline = true,
							args = {
								ForteCDLock = {
									name = "Lock Cooldown Timer",
									desc = "Whether the Cooldown Timer should stick to your Bar or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.CDLock end,
									set = function(self,ForteCDLock)
											db.Forte.CDLock = not db.Forte.CDLock
											if ForteCDLock ~= false then
												module:SetPosForteCooldown()
											end
										end,
									order = 1,
								},
								PaddingX = {
									name = "Padding X",
									desc = "Choose the X Padding for your Forte Cooldowntimer.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Cooldown_PaddingX,
									type = "input",
									get = function() return db.Forte.Cooldown_PaddingX end,
									set = function(self,PaddingX)
											if PaddingX == nil or PaddingX == "" then
												PaddingX = "0"
											end
											db.Forte.Cooldown_PaddingX = PaddingX
											module:SetPosForteCooldown()
										end,
									order = 2,
								},
								PaddingY = {
									name = "Padding Y",
									desc = "Choose the Y Padding for your Forte Cooldowntimer.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Cooldown_PaddingY,
									type = "input",
									get = function() return db.Forte.Cooldown_PaddingY end,
									set = function(self,PaddingY)
											if PaddingY == nil or PaddingY == "" then
												PaddingY = "0"
											end
											db.Forte.Cooldown_PaddingY = PaddingY
											module:SetPosForteCooldown()
										end,
									order = 3,
								},
							},
						},
					},
				},
			},
		},
	}
	return options
end

function LUI:InstallForte()
	if not IsAddOnLoaded("Forte_Core") then return end
	if LUICONFIG.Versions.forte == LUI_versions.forte and LUICONFIG.IsForteInstalled == true then return end
	
	self.db = LUI.db.profile
	db = self.db

	local CharName = UnitName("player")
	local ServerName = GetRealmName()
	local ProfileName = CharName.." - "..ServerName	
	local health_r, health_g, health_b = unpack(db.Forte.Color)
	local ProfileNameForte = CharName.."-"..ServerName
	local ForteTimerArray = FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Filter"]
	local ForteCooldownArray = FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["Filter"]
	local ForteProfileFound = false
	
	for i, v in ipairs(FC_Saved.ProfileNames) do
		if v[1] == CharName then
			ForteProfileFound = true
			break;
		end
	end
	
	if ForteProfileFound == false then
		tinsert(FC_Saved.ProfileNames,{CharName, CharName})
	end
		
	ForteDefaults = {
		[CharName] = {
			["RemoveAfterCombat"] = false,
			["TimerInstantSoundEnable"] = false,
			["RightClickIconOptions"] = true,
			["GlobalFrameNames"] = true,
			["FrameSnap"] = true,
			["GlobalAlpha"] = 1,
			["AnimateScroll"] = false,
			["ShardEnable"] = false,
			["SoulstoneEnable"] = false,
			["HealthstoneEnable"] = false,
			["SummonEnable"] = false,
			["Timer"] = {
				["HighlightColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["FocusBgColor"] = {
					1, -- [1]
					1, -- [2]
					0.5019607843137255, -- [3]
					1, -- [4]
				},
				["MaxEnable"] = false,
				["CustomTag"] = false,
				["Expand"] = true,
				["SelfDebuffColor"] = {
					health_r-0.3, -- [1]
					health_g-0.3, -- [2]
					health_b-0.3, -- [3]
				},
				["HideTime"] = 2,
				["CurseEnable"] = true,
				["MagicEnable"] = true,
				["CustomTagMsg"] = "id target :: spell stacks",
				["TicksEnable"] = false,
				["FadeTime"] = 0.5,
				["PetEnable"] = true,
				["HealEnable"] = true,
				["y"] = 261,
				["BuffEnable"] = true,
				["ExpiredEnable"] = false,
				["ExpiredColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
					0.1, -- [4]
				},
				["Filter"] = {
				},
				["DrainColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["GroupID"] = false,
				["scale"] = 1.2,
				["TargetColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					1, -- [4]
				},
				["MagicColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["Target"] = true,
				["IgnoreLong"] = false,
				["ShowID"] = false,
				["MaximizeName"] = false,
				["MaxTimeEnable"] = false,
				["FocusEnable"] = false,
				["PetColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["Max"] = 10,
				["Backdrop"] = {
					"Interface\\AddOns\\Forte_Core\\Textures\\Background", -- [1]
					"Interface\\AddOns\\LUI\\media\\textures\\statusbars\\glowTex", -- [2]
					false, -- [3]
					16, -- [4]
					6, -- [5]
					5, -- [6]
				},
				["HighlightEnable"] = true,
				["CooldownsEnable"] = true,
				["FailEnable"] = true,
				["Height"] = 17,
				["CurseColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["x"] = 475,
				["DrainEnable"] = true,
				["alpha"] = 1,
				["RaidTargetsAlpha"] = 0.7,
				["Enable"] = true,
				["TargetBgColor"] = {
					0, -- [1]
					0, -- [2]
					0, -- [3]
					1, -- [4]
				},
				["SpacingHeight"] = 0,
				["Fade"] = true,
				["FocusBgEnable"] = false,
				["BarBackgroundAlpha"] = 0.5,
				["Time"] = true,
				["Focus"] = true,
				["Blink"] = 3,
				["TicksNext"] = false,
				["FailTime"] = 2,
				["RaidTargets"] = false,
				["NormalAlpha"] = 0.4,
				["FadeSpeed"] = 0.3,
				["MaxTime"] = 30,
				["CrowdEnable"] = true,
				["Spell"] = false,
				["LabelHeight"] = 16,
				["LabelFont"] = "Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",
				["Width"] = 210,
				["BuffColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["SparkColor"] = {
					color_r, -- [1]
					color_g, -- [2]
					color_b, -- [3]
					0.5, -- [4]
				},
				["Ticks"] = false,
				["NormalBgColor"] = {
					0, -- [1]
					0, -- [2]
					0, -- [3]
					0.7300000190734863, -- [4]
				},
				["TimeColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					1, -- [4]
				},
				["FriendlyBuffColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["FriendlyBuffEnable"] = true,
				["CrowdColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["Other"] = true,
				["OneMax"] = false,
				["SparkEnable"] = true,
				["Flip"] = false,
				["Texture"] = "Interface\\AddOns\\LUI\\media\\textures\\statusbars\\Minimalist",
				["HideLongerEnable"] = false,
				["HideNonStacking"] = false,
				["HideLonger"] = 30,
				["FailColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["DebuffsEnable"] = true,
				["TimeSpace"] = 25,
				["FontSize"] = 10,
				["Space"] = 1,
				["Background"] = true,
				["Outwands"] = true,
				["BlinkEnable"] = false,
				["HealColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["DebuffsColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["TicksColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					1, -- [4]
				},
				["TargetEnable"] = false,
				["HideLongerNoBoss"] = false,
				["CastSpark"] = false,
				["TargetBgEnable"] = false,
				["SelfDebuffEnable"] = true,
				["NormalColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					1, -- [4]
				},
				["CooldownsColor"] = {
					health_r, -- [1]
					health_g, -- [2]
					health_b, -- [3]
				},
				["FocusColor"] = {
					1, -- [1]
					1, -- [2]
					0.5, -- [3]
					1, -- [4]
				},
				["lock"] = true,
				["Test"] = false,
				["ForceMax"] = false,
				["LabelFontSize"] = 10,
				["Font"] = "Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",
			},
			["Cooldown"] = {
				["ResTimerEnable"] = false,
				["BgColor"] = {
					0, -- [1]
					0, -- [2]
					0, -- [3]
					0, -- [4]
				},
				["SpellEnable"] = true,
				["AlphaMax"] = 0.6,
				["Tags"] = 5,
				["PetEnable"] = true,
				["y"] = 73,
				["BuffEnable"] = true,
				["Filter"] = {
					["unknown"] = {
						{
							-1, -- [1]
						}, -- [1]
					},
					["Blessed Medallion of Karabor"] = {
						{
							-1, -- [1]
						}, -- [1]
					},
					["Recently Bandaged"] = {
						{
							-2, -- [1]
							1, -- [2]
							0.65, -- [3]
							0, -- [4]
						}, -- [1]
					},
				},
				["MinRangeEnable"] = false,
				["IconTextEnable"] = true,
				["scale"] = 0.7,
				["PotionColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["HealthstoneColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["PetColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["MaxRangeEnable"] = false,
				["Max"] = 300,
				["Backdrop"] = {
					"Interface\\AddOns\\Forte_Core\\Textures\\Background", -- [1]
					"Interface\\Addons\\LUI\\media\\textures\\statusbars\\glowTex", -- [2]
					false, -- [3]
					16, -- [4]
					5, -- [5]
					2, -- [6]
				},
				["Font"] = "Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",
				["DebuffEnable"] = true,
				["Height"] = 40,
				["FontSize"] = 15,
				["MinRange"] = 0,
				["Enable"] = true,
				["Loga"] = 0.255,
				["Vertical"] = false,
				["MaxRange"] = 3600,
				["lock"] = true,
				["PotionEnable"] = true,
				["CustomTagsMsg"] = "0 1 10 30 60 120 180 240",
				["SoulstoneEnable"] = false,
				["Texture"] = "Interface\\AddOns\\LUI\\media\\textures\\statusbars\\Minimalist",
				["DebuffColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["Spark"] = true,
				["Width"] = 551,
				["BuffColor"] = {
					0.01568627450980392, -- [1]
					0.01568627450980392, -- [2]
					0.01568627450980392, -- [3]
				},
				["TextColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					1, -- [4]
				},
				["Swing"] = false,
				["Flip"] = false,
				["Detail"] = true,
				["alpha"] = 1,
				["IconTextColor"] = {
					1, -- [1]
					1, -- [2]
					1, -- [3]
					0, -- [4]
				},
				["IconFont"] = "Interface\\AddOns\\Forte_Core\\Fonts\\GOTHIC.TTF",
				["Warn"] = true,
				["Splash"] = true,
				["ResTimerColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["EnchantColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["EnchantEnable"] = true,
				["PowerupColor"] = {
					0.01568627450980392, -- [1]
					0.01568627450980392, -- [2]
					0.01568627450980392, -- [3]
				},
				["SoulstoneColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["GroupOverride"] = true,
				["Alpha"] = 0.1,
				["ItemEnable"] = true,
				["CustomTags"] = false,
				["SpellColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["BarColor"] = {
					0.8627450980392157, -- [1]
					0.8627450980392157, -- [2]
					0.8627450980392157, -- [3]
					0.3500000238418579, -- [4]
				},
				["Ignore"] = true,
				["IconFontSize"] = 11,
				["HealthstoneEnable"] = false,
				["ItemColor"] = {
					0.07450980392156863, -- [1]
					0.07450980392156863, -- [2]
					0.07450980392156863, -- [3]
				},
				["SplashFactor"] = 6,
				["Test"] = false,
				["Hide"] = true,
				["PowerupEnable"] = true,
				["x"] = 609,
			},
			["Splash"] = {
				["SplashGlow"] = true,
				["SecondSplashMax"] = 3,
				["Enable"] = true,
				["lock"] = true,
				["scale"] = 2,
				["y"] = 384.0000092153639,
				["alpha"] = 0.7,
				["x"] = 614.4000447540723,
			},
			["RAID"] = false,
			["PARTY"] = false,
		}
	}
	
	FC_Saved.Profiles[CharName] = ""
	FC_Saved.Profiles[CharName] = {}

	for k,v in pairs(ForteDefaults) do
		FC_Saved.Profiles[k] = v
	end
	
	FC_Saved.Profiles[CharName]["Timer"]["Filter"] = ForteTimerArray
	FC_Saved.Profiles[CharName]["Cooldown"]["Filter"] = ForteCooldownArray
	
	FW:UseProfile(CharName)
		
	LUICONFIG.Versions.forte = LUI_versions.forte
	LUICONFIG.IsForteInstalled = true
end

local function ConfigureForte()
	LUI:InstallForte()
	ReloadUI()
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	StaticPopupDialogs["INSTALL_FORTE"] = {
	  text = "ForteXorcist Addon found!\nDo you want to apply all LUI Styles to ForteXorcist Spelltimer/Cooldowntimer?",
	  button1 = YES,
	  button2 = NO,
	  OnAccept = ConfigureForte,
	  timeout = 0,
	  whileDead = 1,
	  hideOnEscape = 1
	}
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterAddon(self, "Forte_Core")
end

function module:OnEnable()
	if IsAddOnLoaded("Forte_Core") then
		if not FW.Settings then
			FW:RegisterVariablesEvent(SetForte)
			return
		end
	end
	
	if IsAddOnLoaded("Forte_Core") and IsAddOnLoaded("Forte_Timer") then
		if FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Enable"] ~= nil then
			if FC_Saved.Profiles[FC_Saved.PROFILE]["Timer"]["Enable"] == true then
				LUI.isForteTimerLoaded = true
			end
		end
	end
	
	if IsAddOnLoaded("Forte_Core") and IsAddOnLoaded("Forte_Cooldown") then
		if FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["Enable"] ~= nil then
			if FC_Saved.Profiles[FC_Saved.PROFILE]["Cooldown"]["Enable"] == true then
				LUI.isForteCooldownLoaded = true
			end
		end
	end
	
	if IsAddOnLoaded("Forte_Core") and LUICONFIG.IsConfigured == true then
		if LUICONFIG.IsForteInstalled == nil or LUICONFIG.IsForteInstalled == false then
			StaticPopup_Show("INSTALL_FORTE")
		end
	end
	
	if IsAddOnLoaded("Forte_Core") and LUICONFIG.IsForteInstalled == true then
		self:SetForte()
	end
end