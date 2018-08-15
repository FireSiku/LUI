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

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Tooltip", "AceHook-3.0", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local hooks = { }
local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]
local Tooltips = {GameTooltip,ItemRefTooltip,ItemRefShoppingTooltip1,ItemRefShoppingTooltip2,ShoppingTooltip1,ShoppingTooltip2,FriendsTooltip,FloatingGarrisonFollowerTooltip,GarrisonFollowerAbilityTooltip, WorldMapTooltip, WorldMapCompareTooltip1, WorldMapCompareTooltip2, ReputationParagonTooltip, ContributionBuffTooltip, ContributionTooltip}
local LUITooltipColors
local LUITooltipColors, LUITooltipBackdrop

function module:UpdateTooltip()
	for _, tt in pairs(Tooltips) do
		tt:SetBackdrop(LUITooltipBackdrop)
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
			["DEMONHUNTER"] = { 163/255,  48/255, 201/255,},
			["DRUID"]       = { 255/255, 125/255,  10/255 },
			["HUNTER"]      = { 171/255, 214/255, 116/255 },
			["MAGE"]        = { 104/255, 205/255, 255/255 },
			["PALADIN"]     = { 245/255, 140/255, 186/255 },
			["PRIEST"]      = { 212/255, 212/255, 212/255 },
			["ROGUE"]       = { 255/255, 243/255,  82/255 },
			["SHAMAN"]      = {  41/255,  79/255, 155/255 },
			["WARLOCK"]     = { 148/255, 130/255, 201/255 },
			["WARRIOR"]     = { 199/255, 156/255, 110/255 },
			["MONK"]        = {   0/255, 255/255, 151/255 },
		},
	}

	local LUITooltip = CreateFrame( "Frame", "tooltip", UIParent)

	local _G = getfenv(0)

	LUITooltipBackdrop = {
		bgFile = Media:Fetch("background", db.Tooltip.Background.Texture),
		edgeFile = Media:Fetch("border", db.Tooltip.Border.Texture),
		tile = false, edgeSize = db.Tooltip.Border.Size,
		insets = { left = db.Tooltip.Border.Insets.Left, right = db.Tooltip.Border.Insets.Right, top = db.Tooltip.Border.Insets.Top, bottom = db.Tooltip.Border.Insets.Bottom }
	}

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
		if db.Tooltip.Cursor then
			frame:SetOwner(parent, "ANCHOR_CURSOR")
		else
			frame:SetOwner(parent, "ANCHOR_NONE")
			frame:ClearAllPoints()
			frame:SetPoint(db.Tooltip.Point, UIParent, db.Tooltip.Point, db.Tooltip.X, db.Tooltip.Y)
		end
		frame.default = 1
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

	local GetTooltipUnit = function(self)
		if not self.GetUnit then return end
		--local GMF = GetMouseFocus()
		--local unit = (select(2, self:GetUnit())) or (GMF and GMF:GetAttribute("unit"))
		local unit = select(2, self:GetUnit())
		return unit
	end

	local healthBar = GameTooltipStatusBar
	healthBar:ClearAllPoints()
	healthBar:SetHeight(LUI:Scale(6))
	healthBar:SetPoint("BOTTOMLEFT", healthBar:GetParent(), "TOPLEFT", LUI:Scale(2), LUI:Scale(5))
	healthBar:SetPoint("BOTTOMRIGHT", healthBar:GetParent(), "TOPRIGHT", -LUI:Scale(2), LUI:Scale(5))
	healthBar:SetStatusBarTexture(Media:Fetch("statusbar", db.Tooltip.Health.Texture))

	local healthBarBG = CreateFrame( "Frame", "StatusBarBG", healthBar)
	healthBarBG:SetFrameLevel(healthBar:GetFrameLevel() - 1)
	healthBarBG:SetPoint("TOPLEFT", -LUI:Scale(2), LUI:Scale(2))
	healthBarBG:SetPoint("BOTTOMRIGHT", LUI:Scale(2), -LUI:Scale(2))
	healthBarBG:SetBackdrop( {
		bgFile = LUI.Media.blank,
		edgeFile = LUI.Media.blank,
		tile = false, edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	healthBarBG:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
	healthBarBG:SetBackdropBorderColor(0,0,0,0)

	local BorderColor = function(self)

		local c
		local r = db.Tooltip.Border.Color.r
		local g = db.Tooltip.Border.Color.g
		local b = db.Tooltip.Border.Color.b
		local a = db.Tooltip.Border.Color.a

		local unit = GetTooltipUnit(self)

		local reaction = unit and UnitReaction(unit, "player")
		local player = unit and UnitIsPlayer(unit)
		local tapped = unit and UnitIsTapDenied(unit)
		local itemLink = (not unit and self.GetItem) and select(2, self:GetItem())

		if player then
			local class = select(2, UnitClass(unit))
			local c = LUITooltipColors.class[class] or {1, 1, 1}
			r, g, b = c[1], c[2], c[3]
			self:SetBackdropBorderColor(r, g, b)
			healthBarBG:SetBackdropBorderColor(r, g, b)
			healthBar:SetStatusBarColor(r, g, b)
		elseif reaction then
			if tapped then
				c = {db.Tooltip.Border.Tapped.r,db.Tooltip.Border.Tapped.g,db.Tooltip.Border.Tapped.b}
			else
				c = LUITooltipColors.reaction[reaction]
			end
			r, g, b = c[1], c[2], c[3]
			self:SetBackdropBorderColor(r, g, b)
			healthBarBG:SetBackdropBorderColor(r, g, b)
			healthBar:SetStatusBarColor(r, g, b)
		elseif itemLink then
			local _, link = self:GetItem()
			local quality = link and select(3, GetItemInfo(link))
			if quality and quality >= 2 then
				r, g, b = GetItemQualityColor(quality)
				self:SetBackdropBorderColor(r, g, b)
			else
				self:SetBackdropBorderColor(r, g, b, a)
				healthBarBG:SetBackdropBorderColor(r, g, b, a)
				healthBar:SetStatusBarColor(r, g, b, a)
			end
		else
			self:SetBackdropBorderColor(r, g, b, a)
			healthBarBG:SetBackdropBorderColor(r, g, b, a)
			healthBar:SetStatusBarColor(r, g, b, a)
		end
		-- need this
		NeedBackdropBorderRefresh = true
	end

	local SetStyle = function(self)
		if db.Tooltip.Hidecombat and InCombatLockdown() then
			return self:Hide()
		end
		self:SetBackdrop(LUITooltipBackdrop)
		self:SetScale(db.Tooltip.Scale)
		self:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
		self:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
		BorderColor(self)
		--self:Show()
	end
	module:SecureHook("GameTooltip_UpdateStyle", SetStyle)

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
		--if (not unit) then
		--	local GMF = GetMouseFocus()
		--	unit = GMF and GMF:GetAttribute("unit")
		--end

		if not self.text then
			self.text = self:CreateFontString(nil, "OVERLAY")
			self.text:SetPoint("CENTER", GameTooltipStatusBar, 0, LUI:Scale(6))
			local Infotext = LUI:Module(Infotext, true)
			self.text:SetFont(Media:Fetch("font", (Infotext and Infotext.db.profile.Bags.Font or "vibroceb")), 12, "THINOUTLINE")
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

	module:HookScript(GameTooltip, "OnTooltipSetUnit", function(frame)
		local genderTable = { "", "Male ", "Female " };
		local lines = frame:NumLines()

		if db.Tooltip.Hidecombat and InCombatLockdown() then
			return frame:Hide()
		end

		SetStyle(frame)

		local unit = GetTooltipUnit(frame)

		-- Sometimes when you move your mouse quicky over units in the worldframe, we can get here without a unit
		if not unit then
			return frame:Hide()
		end

		-- for hiding tooltip on unitframes
		if (frame:GetOwner() ~= UIParent and db.Tooltip.Hideuf) then
			return frame:Hide()
		end

		-- A "mouseover" unit is better to have as we can then safely say the tip should no longer show when it becomes invalid.
		--if (UnitIsUnit(unit,"mouseover")) then
		--	unit = "mouseover"
		--end

		local sex = UnitSex(unit)
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
		--if not race then race = "Helpful NPC" end -- For helpful NPCs that join your raid.

		-- Turns out that Title and name returns nil for spectating pet battles, but if that line is skipped, everything works fine.
		if name then _G["GameTooltipTextLeft1"]:SetFormattedText("%s%s%s", color, title or name, realm and realm ~= "" and " - "..realm.."|r" or "|r") end

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
				if(_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) and race then
					_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r %s%s %s%s", r*255, g*255, b*255, level > 0 and level or "??", (db.Tooltip.ShowSex and genderTable[sex] or ""), race, color, class.."|r")
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

		-- -- Sometimes this wasn't getting reset, the fact a cleanup isn't performed at this point, now that it was moved to "OnTooltipCleared" is very bad, so this is a fix
		-- frame.fadeOut = nil
	end)

	module:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		for _, tt in pairs(Tooltips) do
			if not module:IsHooked(tt, "OnShow") then
				module:HookScript(tt, "OnShow", SetStyle)
			end
		end

		module:UnregisterEvent("PLAYER_ENTERING_WORLD")

		-- Hide tooltips in combat for actions, pet actions and shapeshift
		local CombatHideActionButtonsTooltip = function(self)
			if db.Tooltip.Hidebuttons and InCombatLockdown() and not IsShiftKeyDown() then
				self:Hide()
			end
		end
		hooksecurefunc(GameTooltip, "SetAction", CombatHideActionButtonsTooltip)
		hooksecurefunc(GameTooltip, "SetPetAction", CombatHideActionButtonsTooltip)
		hooksecurefunc(GameTooltip, "SetShapeshift", CombatHideActionButtonsTooltip)

	end)

	-- Contribution frame requires special handling because of the way V3 works, ContributionTooltip is nil at the moment of running UpdateTooltips
	module:RegisterEvent("CONTRIBUTION_COLLECTOR_OPEN", function()
		local ccTooltips = { ContributionTooltip, ContributionBuffTooltip }
		for _, tt in pairs(ccTooltips) do
			if not module:IsHooked(tt, "OnShow") then
				module:HookScript(tt, "OnShow", function()
					tt:SetBackdrop( {
						bgFile = Media:Fetch("background", db.Tooltip.Background.Texture),
						edgeFile = Media:Fetch("border", db.Tooltip.Border.Texture),
						tile = false, edgeSize = db.Tooltip.Border.Size,
						insets = { left = db.Tooltip.Border.Insets.Left, right = db.Tooltip.Border.Insets.Right, top = db.Tooltip.Border.Insets.Top, bottom = db.Tooltip.Border.Insets.Bottom }
					})
					tt:SetBackdropColor(db.Tooltip.Background.Color.r,db.Tooltip.Background.Color.g,db.Tooltip.Background.Color.b,db.Tooltip.Background.Color.a)
					tt:SetBackdropBorderColor(db.Tooltip.Border.Color.r,db.Tooltip.Border.Color.g,db.Tooltip.Border.Color.b,db.Tooltip.Border.Color.a)
					BorderColor(tt)
				end)
			end
		end
		module:UnregisterEvent("CONTRIBUTION_COLLECTOR_OPEN")
	end)
end


local defaults = {
	Tooltip = {
		Enable = true,
		Hidecombat = false,
		Hidebuttons = false,
		Hideuf = false,
		Cursor = false,
		ShowSex = false,
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
			Tapped = {
				r = 0.15,
				g = 0.15,
				b = 0.15,
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
						ShowUnitSex = {
							name = "Show The Unit's Sex",
							desc = "If the unit's sex will show in the tooltip.",
							type = "toggle",
							width = "full",
							get = function() return db.Tooltip.ShowSex end,
							set = function()
									db.Tooltip.ShowSex = not db.Tooltip.ShowSex
								end,
							order = 6,
						},
						Scale = {
							name = "Tooltip Scale",
							desc = "Choose the scale of your Tooltip.\n\nDefault: "..LUI.defaults.profile.Tooltip.Scale,
							type = "input",
							order = 7,
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
									GameTooltipStatusBar:SetStatusBarTexture(Media:Fetch("statusbar", db.Tooltip.Health.Texture))
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
						Tapped = {
							name = "Tapped Color",
							desc = "Choose a color for your Tooltip's Border for tapped units",
							type = "color",
							order = 2,
							hasAlpha = false,
							get = function() return db.Tooltip.Border.Tapped.r, db.Tooltip.Border.Tapped.g, db.Tooltip.Border.Tapped.b end,
							set = function(self, r, g, b)
									db.Tooltip.Border.Tapped.r = r
									db.Tooltip.Border.Tapped.g = g
									db.Tooltip.Border.Tapped.b = b
								end,
						},
						Texture = {
							name = "Texture",
							desc = "Choose your Tooltip's Border texture.\n\nDefault: "..LUI.defaults.profile.Tooltip.Border.Texture,
							type = "select",
							order = 3,
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
							order = 4,
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
							order = 5,
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

function LUIDebug_PrintTooltips()
	for k, v in pairs(_G) do
		if strmatch(k, "Tooltip%d?$") and type(v) == "table" then
			LUI:Print(k)
		end
	end
end
