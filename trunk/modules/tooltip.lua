--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: tooltip.lua
	Description: Tooltip Module
	Version....: 1.5
	Rev Date...: 02/01/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Hix
		v1.2: Hix
		v1.3: Hix
		-  e: Loui/Hix
		v1.4: Hix
		v1.5: Zista
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local module = LUI:NewModule("Tooltip", "AceHook-3.0", "AceEvent-3.0")

local db
local hooks = { }
local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]
local Tooltips = {GameTooltip,ItemRefTooltip,ShoppingTooltip1,ShoppingTooltip2,ShoppingTooltip3,WorldMapTooltip}

function module:UpdateTooltip()
	for _, tt in pairs(Tooltips) do
		tt:SetBackdrop( { 
			bgFile = LSM:Fetch("background", db.Tooltip.Background.Texture), 
			edgeFile = LSM:Fetch("border", db.Tooltip.Border.Texture), 
			tile = false, edgeSize = db.Tooltip.Border.Size, 
			insets = { left = db.Tooltip.Border.Insets.Left, right = db.Tooltip.Border.Insets.Right, top = db.Tooltip.Border.Insets.Top, bottom = db.Tooltip.Border.Insets.Bottom }
		})
	end
end

function module:SetTooltip()
	
	if db.Tooltip.Enable ~= true then return end

	LUITooltipColors = {
		reaction = {
			[1] = { 222/255, 95/255,  95/255 }, -- Hated
			[2] = { 222/255, 95/255,  95/255 }, -- Hostile
			[3] = { 222/255, 95/255,  95/255 }, -- Unfriendly
			[4] = { 218/255, 197/255, 92/255 }, -- Neutral
			[5] = { 75/255,  175/255, 76/255 }, -- Friendly
			[6] = { 75/255,  175/255, 76/255 }, -- Honored
			[7] = { 75/255,  175/255, 76/255 }, -- Revered
			[8] = { 75/255,  175/255, 76/255 }, -- Exalted	
		},
		class = {
			["DEATHKNIGHT"] = { 196/255,  30/255,  60/255 },
			["DRUID"]       = { 255/255, 125/255,  10/255 },
			["HUNTER"]      = { 171/255, 214/255, 116/255 },
			["MAGE"]        = { 104/255, 205/255, 255/255 },
			["PALADIN"]     = { 245/255, 140/255, 186/255 },
			["PRIEST"]      = { 212/255, 212/255, 212/255 },
			["ROGUE"]       = { 255/255, 243/255,  82/255 },
			["SHAMAN"]      = {  41/255,  79/255, 155/255 },
			["WARLOCK"]     = { 148/255, 130/255, 201/255 },
			["WARRIOR"]     = { 199/255, 156/255, 110/255 },
		},
	}

	local LUITooltip = CreateFrame( "Frame", "tooltip", UIParent)

	local _G = getfenv(0)
	
	module:UpdateTooltip()

	local gsub, find, format = string.gsub, string.find, string.format

	local linkTypes = {item = true, enchant = true, spell = true, quest = true, unit = true, talent = true, achievement = true, glyph = true}

	local classification = {
		worldboss = "|cffAF5050Boss|r",
		rareelite = "|cffAF5050+ Rare|r",
		elite = "|cffAF5050+|r",
		rare = "|cffAF5050Rare|r",
	}

	local NeedBackdropBorderRefresh = false

	module:SecureHook("GameTooltip_SetDefaultAnchor", function(frame, parent)
		if db.Tooltip.Cursor == true then
			frame:SetOwner(parent, "ANCHOR_CURSOR")
		else
			frame:SetOwner(parent, "ANCHOR_NONE")
			frame:SetPoint(db.Tooltip.Point, UIParent, db.Tooltip.Point, db.Tooltip.X, db.Tooltip.Y)
		end
		frame.default = 1
	end)

	module:HookScript(GameTooltip, "OnUpdate", function(frame, ...)
		if frame:GetAnchorType() == "ANCHOR_CURSOR" and NeedBackdropBorderRefresh == true and db.Tooltip.Cursor ~= true then
			NeedBackdropBorderRefresh = false
			frame:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
			frame:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
		elseif frame:GetAnchorType() == "ANCHOR_NONE" then
			if InCombatLockdown() and db.Tooltip.Hidecombat == true then
				frame:SetAlpha(0)
			else
				frame:SetAlpha(1)
				frame:ClearAllPoints()
				frame:SetPoint(db.Tooltip.Point, UIParent, db.Tooltip.Point, db.Tooltip.X, db.Tooltip.Y)
			end
		end
	end)

	local function Hex(color)
		return string.format('|cff%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
	end

	local function GetColor(unit)
		if(UnitIsPlayer(unit) and not UnitHasVehicleUI(unit)) then
			local _, class = UnitClass(unit)
			local color = RAID_CLASS_COLORS[class]
			if not color then return end -- sometime unit too far away return nil for color :(
			local r,g,b = color.r, color.g, color.b
			return Hex(color), r, g, b	
		else
			local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
			if not color then return end -- sometime unit too far away return nil for color :(
			local r,g,b = color.r, color.g, color.b		
			return Hex(color), r, g, b		
		end
	end

	-- function to short-display HP value on StatusBar
	local function ShortValue(value)
		if value >= 1e7 then
			return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
		elseif value >= 1e6 then
			return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
		elseif value >= 1e5 then
			return ('%.0fk'):format(value / 1e3)
		elseif value >= 1e3 then
			return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
		else
			return value
		end
	end

	-- update HP value on status bar
	GameTooltipStatusBar:SetScript("OnValueChanged", function(self, value)
		if not value then
			return
		end
		local min, max = self:GetMinMaxValues()
		
		if (value < min) or (value > max) then
			return
		end
		local _, unit = GameTooltip:GetUnit()
		
		-- fix target of target returning nil
		if (not unit) then
			local GMF = GetMouseFocus()
			unit = GMF and GMF:GetAttribute("unit")
		end

		if not self.text then
			self.text = self:CreateFontString(nil, "OVERLAY")
			self.text:SetPoint("CENTER", GameTooltipStatusBar, 0, LUI:Scale(6))
			local Infotext = LUI:GetModule(Infotext, true)
			self.text:SetFont(LSM:Fetch("font", (Infotext and Infotext.db.profile.Bags.Font or "vibroceb")), 12, "THINOUTLINE")
			self.text:Show()
			if unit then
				min, max = UnitHealth(unit), UnitHealthMax(unit)
				local hp = ShortValue(min).." / "..ShortValue(max)
				if UnitIsGhost(unit) then
					self.text:SetText("Ghost")
				elseif min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) then
					self.text:SetText("Dead")
				else
					self.text:SetText(hp)
				end
			end
		else
			if unit then
				min, max = UnitHealth(unit), UnitHealthMax(unit)
				local hp = ShortValue(min).." / "..ShortValue(max)
				self.text:Show()
				if UnitIsGhost(unit) then
					self.text:SetText("Ghost")
				elseif min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) then
					self.text:SetText("Dead")
				else
					self.text:SetText(hp)
				end
			else
				self.text:Hide()
			end
		end
	end)

	local healthBar = GameTooltipStatusBar
	healthBar:ClearAllPoints()
	healthBar:SetHeight(LUI:Scale(6))
	healthBar:SetPoint("BOTTOMLEFT", healthBar:GetParent(), "TOPLEFT", LUI:Scale(2), LUI:Scale(5))
	healthBar:SetPoint("BOTTOMRIGHT", healthBar:GetParent(), "TOPRIGHT", -LUI:Scale(2), LUI:Scale(5))
	healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.Tooltip.Health.Texture))

	local healthBarBG = CreateFrame( "Frame", "StatusBarBG", healthBar)
	healthBarBG:SetFrameLevel(healthBar:GetFrameLevel() - 1)
	healthBarBG:SetPoint("TOPLEFT", -LUI:Scale(2), LUI:Scale(2))
	healthBarBG:SetPoint("BOTTOMRIGHT", LUI:Scale(2), -LUI:Scale(2))
	healthBarBG:SetBackdrop( { 
		bgFile = LUI_Media.blank, 
		edgeFile = LUI_Media.blank, 
		tile = false, edgeSize = 0, 
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	healthBarBG:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
	healthBarBG:SetBackdropBorderColor(0,0,0,0)

	module:HookScript(GameTooltip, "OnTooltipSetUnit", function(frame)
		local lines = frame:NumLines()
		local GMF = GetMouseFocus()
		local unit = (select(2, frame:GetUnit())) or (GMF and GMF:GetAttribute("unit"))
		
		-- A mage's mirror images sometimes doesn't return a unit, this would fix it
		if (not unit) and (UnitExists("mouseover")) then
			unit = "mouseover"
		end
		
		-- Sometimes when you move your mouse quicky over units in the worldframe, we can get here without a unit
		if not unit then frame:Hide() return end
		
		-- for hiding tooltip on unitframes
		if (frame:GetOwner() ~= UIParent and db.Tooltip.Hideuf) then frame:Hide() return end
		
		-- A "mouseover" unit is better to have as we can then safely say the tip should no longer show when it becomes invalid.
		if (UnitIsUnit(unit,"mouseover")) then
			unit = "mouseover"
		end

		local race = UnitRace(unit)
		local class = UnitClass(unit)
		local level = UnitLevel(unit)
		local guild = GetGuildInfo(unit)
		local name, realm = UnitName(unit)
		local crtype = UnitCreatureType(unit)
		local classif = UnitClassification(unit)
		local title = UnitPVPName(unit)
		local r, g, b = GetQuestDifficultyColor(level).r, GetQuestDifficultyColor(level).g, GetQuestDifficultyColor(level).b

		local color = GetColor(unit)	
		if not color then color = "|CFFFFFFFF" end -- just safe mode for when GetColor(unit) return nil for unit too far away

		_G["GameTooltipTextLeft1"]:SetFormattedText("%s%s%s", color, title or name, realm and realm ~= "" and " - "..realm.."|r" or "|r")

		if(UnitIsPlayer(unit)) then
			if UnitIsAFK(unit) then
				frame:AppendText((" %s"):format(CHAT_FLAG_AFK))
			elseif UnitIsDND(unit) then 
				frame:AppendText((" %s"):format(CHAT_FLAG_DND))
			end

			local offset = 2
			if guild then
				_G["GameTooltipTextLeft2"]:SetFormattedText("%s", IsInGuild() and GetGuildInfo("player") == guild and "|cff0090ff"..guild.."|r" or "|cff00ff10"..guild.."|r")
				offset = offset + 1
			end

			for i= offset, lines do
				if(_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) then
					_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r %s %s%s", r*255, g*255, b*255, level > 0 and level or "??", race, color, class.."|r")
					break
				end
			end
		else
			for i = 2, (lines-1) do
				if(_G["GameTooltipTextLeft"..i]:GetText() ~= nil) then
					if((_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) or (crtype and _G["GameTooltipTextLeft"..i]:GetText():find("^"..crtype))) then
						if level == -1 and classif == "elite" then classif = "worldboss" end
						_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r%s %s", r*255, g*255, b*255, classif ~= "worldboss" and level ~= 0 and level or "", classification[classif] or "", crtype or "")
						break
					end
				end
			end
		end

		local pvpLine
		for i = 1, lines do
			local text = _G["GameTooltipTextLeft"..i]:GetText()
			if text and text == PVP_ENABLED then
				pvpLine = _G["GameTooltipTextLeft"..i]
				pvpLine:SetText()
				break
			end
		end

		-- ToT line
		if UnitExists(unit.."target") and unit~="player" then
			local hex, r, g, b = GetColor(unit.."target")
			if not r and not g and not b then r, g, b = 1, 1, 1 end
			GameTooltip:AddLine(UnitName(unit.."target"), r, g, b)
		end
		
		-- Sometimes this wasn't getting reset, the fact a cleanup isn't performed at this point, now that it was moved to "OnTooltipCleared" is very bad, so this is a fix
		frame.fadeOut = nil
	end)

	local BorderColor = function(self)
		local GMF = GetMouseFocus()
		local unit = (select(2, self:GetUnit())) or (GMF and GMF:GetAttribute("unit"))
			
		local reaction = unit and UnitReaction(unit, "player")
		local player = unit and UnitIsPlayer(unit)
		local tapped = unit and UnitIsTapped(unit)
		local tappedbyme = unit and UnitIsTappedByPlayer(unit)
		local connected = unit and UnitIsConnected(unit)
		local dead = unit and UnitIsDead(unit)

		if player then
			local class = select(2, UnitClass(unit))
			local c = LUITooltipColors.class[class]
			r, g, b = c[1], c[2], c[3]
			self:SetBackdropBorderColor(r, g, b)
			healthBarBG:SetBackdropBorderColor(r, g, b)
			healthBar:SetStatusBarColor(r, g, b)
		elseif reaction then
			local c = LUITooltipColors.reaction[reaction]
			r, g, b = c[1], c[2], c[3]
			self:SetBackdropBorderColor(r, g, b)
			healthBarBG:SetBackdropBorderColor(r, g, b)
			healthBar:SetStatusBarColor(r, g, b)
		else
			local _, link = self:GetItem()
			local quality = link and select(3, GetItemInfo(link))
			if quality and quality >= 2 then
				local r, g, b = GetItemQualityColor(quality)
				self:SetBackdropBorderColor(r, g, b)
			else
				self:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
				healthBarBG:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
				healthBar:SetStatusBarColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
			end
		end
		
		-- need this
		NeedBackdropBorderRefresh = true
	end

	local SetStyle = function(self)
		self:SetScale(db.Tooltip.Scale)
		self:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
		self:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
		BorderColor(self)
	end

	module:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		for _, tt in pairs(Tooltips) do
			if not module:IsHooked(tt, "OnShow") then
				module:HookScript(tt, "OnShow", SetStyle)
			end
		end
		
		module:UnregisterEvent("PLAYER_ENTERING_WORLD")
		
		-- Hide tooltips in combat for actions, pet actions and shapeshift
		if db.Tooltip.Hidebuttons then
			local CombatHideActionButtonsTooltip = function(self)
				if not IsShiftKeyDown() then
					self:Hide()
				end
			end
		 
			hooksecurefunc(GameTooltip, "SetAction", CombatHideActionButtonsTooltip)
			hooksecurefunc(GameTooltip, "SetPetAction", CombatHideActionButtonsTooltip)
			hooksecurefunc(GameTooltip, "SetShapeshift", CombatHideActionButtonsTooltip)
		end
	end)
end


local defaults = {
	Tooltip = {
		Enable = true,
		Hidecombat = false,
		Hidebuttons = false,
		Hideuf = false,
		Cursor = false,
		X = -150,
		Y = 0,
		Point = "RIGHT",
		Scale = 1,
		Health = {
			Texture = "LUI_Minimalist",
		},
		Background = {
			Texture = "Blizzard Tooltip",
			Color = {
				r = 0.18,
				g = 0.18,
				b = 0.18,
				a = 1,
			},
		},
		Border = {
			Texture = "Stripped_medium",
			Size = 14,
			Insets = {
				Left = 0,
				Right = 0,
				Top = 0,
				Bottom = 0,
			},
			Color = {
				r = 0.3,
				g = 0.3,
				b = 0.3,
				a = 1,
			},
		},
	},
}

function module:LoadOptions()
	local options = {
		Tooltip = {
			name = "Tooltip",
			type = "group",
			childGroups = "tab",
			disabled = function() return not db.Tooltip.Enable end,
			args = {
				Header = {
					name = "Tooltip",
					type = "header",
					order = 1,
				},
				Settings = {
					name = "Settings",
					type = "group",
					order = 3,
					args = {
						Enable = {
							name = "Enable",
							desc = "Enable LUI Tooltip.",
							type = "toggle",
							width = "full",
							get = function() return db.Tooltip.Enable end,
							set = function()
									db.Tooltip.Enable = not db.Tooltip.Enable
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 1,
						},
						HideCombat = {
							name = "Show In Combat",
							desc = "If Tooltips will show while in combat or not.",
							type = "toggle",
							width = "full",
							get = function() return not db.Tooltip.Hidecombat end,
							set = function()
									db.Tooltip.Hidecombat = not db.Tooltip.Hidecombat
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 2,
						},
						HideButtons = {
							name = "Show For Abilities In Combat",
							desc = "If Tooltips will show for abilities or not during combat.",
							type = "toggle",
							width = "full",
							get = function() return not db.Tooltip.Hidebuttons end,
							set = function()
									db.Tooltip.Hidebuttons = not db.Tooltip.Hidebuttons
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 3,
						},
						HideUnitFrames = {
							name = "Show For UnitFrames",
							desc = "If Tooltips will show for unitframes or not.",
							type = "toggle",
							width = "full",
							get = function() return not db.Tooltip.Hideuf end,
							set = function()
									db.Tooltip.Hideuf = not db.Tooltip.Hideuf
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 4,
						},
						AnchorToCursor = {
							name = "Anchor To Cursor",
							desc = "If Tooltips will show at the cursor's position.",
							type = "toggle",
							width = "full",
							get = function() return db.Tooltip.Cursor end,
							set = function()
									db.Tooltip.Cursor = not db.Tooltip.Cursor
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 5,
						},
						Scale = {
							name = "Tooltip Scale",
							desc = "Choose the scale of your Tooltip.\n\nDefault: "..LUI.defaults.profile.Tooltip.Scale,
							type = "input",
							order = 6,
							get = function() return tostring(db.Tooltip.Scale) end,
							set = function(self, scale)
									if (scale == nil) or (scale == "") then
										scale = "0"
									end
									
									db.Tooltip.Scale = tonumber(scale)
								end,
						},
					},					
				},
				Position = {
					name = "Position",
					type = "group",
					order = 4,
					args = {
						Description = {
							name = "The tooltip is anchored to the right of the screen.",
							type = "description",
							width = "full",
							order = 1,
						},
						PosX = {
							name = "X Value",
							desc = "X value for your Tooltip.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Tooltip.X, 
							type = "input",
							width = "half",
							order = 2,
							get = function() return tostring(db.Tooltip.X) end,
							set = function(self, x)
									if (x == nil) or (x == "") then
										x = "0"
									end
									db.Tooltip.X = tonumber(x)
								end,
						},
						PosY = {
							name = "Y Value",
							desc = "Y value for your Tooltip.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Tooltip.Y, 
							type = "input",
							width = "half",
							order = 3,
							get = function() return tostring(db.Tooltip.Y) end,
							set = function(self, y)
									if (y == nil) or (y == "") then
										y = "0"
									end
									db.Tooltip.Y = tonumber(y)
								end,
						},
					},
				},
				HealthBar = {
					name = "Health Bar",
					type = "group",
					order = 5,
					args = {
						Texture = {
							name = "Texture",
							desc = "Choose your Tooltip's Health Bar texture.\n\nDefault: "..LUI.defaults.profile.Tooltip.Health.Texture,
							type = "select",
							order = 1,
							dialogControl = "LSM30_Statusbar",
							values = widgetLists.statusbar,
							get = function() return db.Tooltip.Health.Texture end,
							set = function(self, texture)
									db.Tooltip.Health.Texture = texture
									GameTooltipStatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.Tooltip.Health.Texture))
								end,						
						},
					},
				},
				Background = {
					name = "Background",
					type = "group",
					order = 6,
					args = {
						Color = {
							name = "Background Color",
							desc = "Choose a color for the Tooltip's Background",
							type = "color",
							width = "full",
							order = 1,
							hasAlpha = true,
							get = function() return db.Tooltip.Background.Color.r, db.Tooltip.Background.Color.g, db.Tooltip.Background.Color.b, db.Tooltip.Background.Color.a end,
							set = function(self, r, g, b, a)
									db.Tooltip.Background.Color.r = r
									db.Tooltip.Background.Color.g = g
									db.Tooltip.Background.Color.b = b
									db.Tooltip.Background.Color.a = a
								end,									
						},
						Texture = {
							name = "Texture",
							desc = "Choose your Tooltip's Background texture.\n\nDefault: "..LUI.defaults.profile.Tooltip.Background.Texture,
							type = "select",
							order = 2,
							dialogControl = "LSM30_Background",
							values = widgetLists.background,
							get = function() return db.Tooltip.Background.Texture end,
							set = function(self, texture)
									db.Tooltip.Background.Texture = texture
									module:UpdateTooltip()
								end,						
						},
					},
				},
				Border = {
					name = "Border",
					type = "group",
					order = 7,
					args = {
						Color = {
							name = "Border Color",
							desc = "Choose a color for your Tooltip's Border",
							type = "color",
							width = "full",
							order = 1,
							hasAlpha = true,
							get = function() return db.Tooltip.Border.Color.r, db.Tooltip.Border.Color.g, db.Tooltip.Border.Color.b, db.Tooltip.Border.Color.a end,
							set = function(self, r, g, b, a)
									db.Tooltip.Border.Color.r = r
									db.Tooltip.Border.Color.g = g
									db.Tooltip.Border.Color.b = b
									db.Tooltip.Border.Color.a = a
								end,									
						},
						Texture = {
							name = "Texture",
							desc = "Choose your Tooltip's Border texture.\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Texture,
							type = "select",
							order = 2,
							dialogControl = "LSM30_Border",
							values = widgetLists.border,
							get = function() return db.Tooltip.Border.Texture end,
							set = function(self, texture)
									db.Tooltip.Border.Texture = texture
									module:UpdateTooltip()
								end,						
						},
						Size = {
							name = "Border Size",
							desc = "Value for your Tooltip's Border size.\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Size,
							type = "input",
							order = 3,
							get = function() return tostring(db.Tooltip.Border.Size) end,
							set = function(self, size)
									if (size == nil) or (size == "") then
										size = "0"
									end
									db.Tooltip.Border.Size = tonumber(size)
									module:UpdateTooltip()
								end,
						},
						Insets = {
							name = "Border Insets",
							type = "group",
							guiInline = true,
							order = 4,
							args = {
								Description = {
									name = "Set the insets for your Tooltip's Border.",
									type = "description",
									width = "full",
									order = 1,
								},
								Left = {
									name = "Left",
									desc = "Value for the Left inset of your Tooltip's Border\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Insets.Left,
									type = "input",
									width = "half",
									order = 2,
									get = function() return tostring(db.Tooltip.Border.Insets.Left) end,
									set = function(self, left)
											if (left == nil) or (left == "") then
												left = "0"
											end
											db.Tooltip.Border.Insets.Left = tonumber(left)
											module:UpdateTooltip()
										end,
								},
								Right = {
									name = "Right",
									desc = "Value for the Right inset of your Tooltip's Border\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Insets.Right,
									type = "input",
									width = "half",
									order = 3,
									get = function() return tostring(db.Tooltip.Border.Insets.Right) end,
									set = function(self, right)
											if (right == nil) or (right == "") then
												right = "0"
											end
											db.Tooltip.Border.Insets.Right = tonumber(right)
											module:UpdateTooltip()
										end,
								},
								Top = {
									name = "Top",
									desc = "Value for the Top inset of your Tooltip's Border\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Insets.Top,
									type = "input",
									width = "half",
									order = 4,
									get = function() return tostring(db.Tooltip.Border.Insets.Top) end,
									set = function(self, top)
											if (top == nil) or (top == "") then
												top = "0"
											end
											db.Tooltip.Border.Insets.Top = tonumber(top)
											module:UpdateTooltip()
										end,
								},
								Bottom = {
									name = "Bottom",
									desc = "Value for the Bottom inset of your Tooltip's Border\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Insets.Bottom,
									type = "input",
									width = "half",
									order = 5,
									get = function() return tostring(db.Tooltip.Border.Insets.Bottom) end,
									set = function(self, bottom)
											if (bottom == nil) or (bottom == "") then
												bottom = "0"
											end
											db.Tooltip.Border.Insets.Bottom = tonumber(bottom)
											module:UpdateTooltip()
										end,
								},
							}
						},
					},
				},			
			},
		},
	}
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterModule(self)
end

function module:OnEnable()
	self:SetTooltip()
end

function module:OnDisable()
	LUI:ClearFrames()
end