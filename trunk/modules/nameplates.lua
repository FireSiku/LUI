--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: nameplates.lua
	Description: Nameplate Module
	Version....: 1.2.2
	Rev Date...: 27/04/2011 [dd/mm/yyyy]

	Edits:
		v1.0: Loui
		v1.1: Hix
		v1.2: Loui
		v1.2.1: Xolsom (WoW 4.1 Fix)
		v1.2.2: Xolsom (Castbar Fix)
]]

-- External references.
local _, LUI = ...
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local module = LUI:NewModule("Nameplates")

local db
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

function module:SetNameplates()
	if db.Nameplates.Enable ~= true then return end

	local tNamePlates = CreateFrame( "Frame", "tNamePlates", UIParent)
	tNamePlates:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	SetCVar("bloatthreat", 0) -- stop resizing nameplate according to threat level.

	local overlayTexture = [=[Interface\Tooltips\Nameplate-Border]=]

	local select = select

	local isValidFrame = function(frame)
		--if frame:GetName() then return end

		local overlayRegion = select(2, frame:GetRegions())

		return overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == overlayTexture
	end

	local updateTime = function(self, curValue)
		local minValue, maxValue = self:GetMinMaxValues()
		if self.channeling then
			self.time:SetFormattedText("%.1f ", curValue)
		else
			self.time:SetFormattedText("%.1f ", maxValue - curValue)
		end
	end

	local threatUpdate = function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		if self.elapsed >= 0.2 then
			if not self.oldglow:IsShown() then
				self.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
			else
				local r, g, b = self.oldglow:GetVertexColor()
				if g + b == 0 then
					self.healthBar.hpGlow:SetBackdropBorderColor(1, 0, 0)
				else
					self.healthBar.hpGlow:SetBackdropBorderColor(1, 1, 0)
				end
			end

			self.healthBar:SetStatusBarColor(self.r, self.g, self.b)

			self.elapsed = 0
		end
	end

	local updatePlate = function(self)
		local r, g, b = self.healthBar:GetStatusBarColor()
		local newr, newb, newg
		if g + b == 0 then
			-- Hostile unit
			newr, newg, newb = db.Nameplates.HealthBar.Colors.HostileUnit.r, db.Nameplates.HealthBar.Colors.HostileUnit.g, db.Nameplates.HealthBar.Colors.HostileUnit.b
			self.healthBar:SetStatusBarColor(newr, newg, newb)
		elseif r + b == 0 then
			-- Friendly unit
			newr, newg, newb = db.Nameplates.HealthBar.Colors.FriendlyUnit.r, db.Nameplates.HealthBar.Colors.FriendlyUnit.g, db.Nameplates.HealthBar.Colors.FriendlyUnit.b
			self.healthBar:SetStatusBarColor(newr, newg, newb)
		elseif r + g == 0 then
			-- Friendly player
			newr, newg, newb = db.Nameplates.HealthBar.Colors.FriendlyPlayer.r, db.Nameplates.HealthBar.Colors.FriendlyPlayer.g, db.Nameplates.HealthBar.Colors.FriendlyPlayer.b
			self.healthBar:SetStatusBarColor(newr, newg, newb)
		elseif 2 - (r + g) < 0.05 and b == 0 then
			-- Neutral unit
			newr, newg, newb = db.Nameplates.HealthBar.Colors.NeutralUnit.r, db.Nameplates.HealthBar.Colors.NeutralUnit.g, db.Nameplates.HealthBar.Colors.NeutralUnit.b
			self.healthBar:SetStatusBarColor(newr, newg, newb)
		else
			-- Hostile player - class colored.
			newr, newg, newb = r, g, b
		end

		self.r, self.g, self.b = newr, newg, newb

		self.healthBar:ClearAllPoints()
		self.healthBar:SetPoint("CENTER", self.healthBar:GetParent())
		self.healthBar:SetHeight(LUI:Scale(db.Nameplates.HealthBar.Height))
		self.healthBar:SetWidth(LUI:Scale(db.Nameplates.HealthBar.Width))

		self.healthBar.hpBackground:SetVertexColor(self.r * 0.20, self.g * 0.20, self.b * 0.20)

		self.castBar:ClearAllPoints()
		self.castBar:SetPoint("TOP", self.healthBar, "BOTTOM", LUI:Scale(db.Nameplates.CastBar.XOffset), LUI:Scale(db.Nameplates.CastBar.YOffset))
		self.castBar:SetHeight(LUI:Scale(db.Nameplates.CastBar.Height))
		self.castBar:SetWidth(LUI:Scale(db.Nameplates.CastBar.Width))

		self.highlight:ClearAllPoints()
		self.highlight:SetAllPoints(self.healthBar)

		local nameString = self.oldname:GetText()
		if string.len(nameString) < 22 then
			self.name:SetText(nameString)
		else
			self.name:SetFormattedText(nameString:sub(0, 19).." ...")
		end


		local level, elite, mylevel = tonumber(self.level:GetText()), self.elite:IsShown(), UnitLevel("player")
		self.level:ClearAllPoints()
		self.level:SetPoint("RIGHT", self.healthBar, "LEFT", LUI:Scale(-2), 0)
		if self.boss:IsShown() then
			self.level:SetText("B")
			self.level:SetTextColor(0.8, 0.05, 0)
			self.level:Show()
		elseif not elite and level == mylevel then
			self.level:Hide()
		else
			self.level:SetFormattedText("%d:%s", level, (elite and "+" or ""))
		end
	end

	local fixCastbar = function(self)
		self.castbarOverlay:Hide()

		self:SetHeight(LUI:Scale(db.Nameplates.CastBar.Height))
		--self:SetWidth(LUI:Scale(db.Nameplates.CastBar.Width))
		self:ClearAllPoints()
		self:SetPoint("TOP", self.healthBar, "BOTTOM", LUI:Scale(db.Nameplates.CastBar.XOffset), LUI:Scale(db.Nameplates.CastBar.YOffset))
	end

	local colorCastBar = function(self, shielded)
		if shielded then
			self:SetStatusBarColor(0.8, 0.05, 0)
			self.cbGlow:SetBackdropBorderColor(0.75, 0.75, 0.75)
			self.icGlow:SetBackdropBorderColor(0.75, 0.75, 0.75)
		else
			self.cbGlow:SetBackdropBorderColor(0, 0, 0)
			self.icGlow:SetBackdropBorderColor(0, 0, 0)
		end
	end

	local onSizeChanged = function(self)
		self.needFix = true
	end

	local onValueChanged = function(self, curValue)
		updateTime(self, curValue)
		if self.needFix then
			fixCastbar(self)
			self.needFix = nil
		end
	end

	local onShow = function(self)
		self.channeling  = UnitChannelInfo("target")
		fixCastbar(self)
		colorCastBar(self, self.shieldedRegion:IsShown())
	end

	local onHide = function(self)
		self.highlight:Hide()
		self.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
	end

	local onEvent = function(self, event, unit)
		if unit == "target" then
			if self:IsShown() then
				colorCastBar(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
			end
		end
	end

	local createPlate = function(frame)
		if frame.done then return end

		frame.nameplate = true

		frame.healthBar, frame.castBar = frame:GetChildren()
		local healthBar, castBar = frame.healthBar, frame.castBar
		--local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
		local glowRegion, overlayRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
		local _, castbarOverlay, shieldedRegion, spellIconRegion = frame.castBar:GetRegions();
		local font, fontSize, fontFlag, fontColor = LSM:Fetch("font", db.Nameplates.FontSettings.Font), db.Nameplates.FontSettings.Size, db.Nameplates.FontSettings.Flag, db.Nameplates.FontSettings.Color

		local barTexture = LUI_Media.normTex
		local glowTexture = LUI_Media.glowTex
		local backdrop = {
			edgeFile = glowTexture, edgeSize = LUI:Scale(3),
			insets = {left = LUI:Scale(3), right = LUI:Scale(3), top = LUI:Scale(3), bottom = LUI:Scale(3)}
		}

		frame.oldname = nameTextRegion
		nameTextRegion:Hide()

		local newNameRegion = frame:CreateFontString()
		DTEST3 = newNameRegion
		newNameRegion:SetPoint("BOTTOM", healthBar, "TOP", LUI:Scale(db.Nameplates.Name.XOffset), LUI:Scale(db.Nameplates.Name.YOffset))
		newNameRegion:SetFont(font, fontSize, fontFlag)
		newNameRegion:SetTextColor(fontColor.r, fontColor.g, fontColor.b)
		newNameRegion:SetShadowOffset(LUI.mult, -LUI.mult)
		frame.name = newNameRegion

		frame.level = levelTextRegion
		levelTextRegion:SetFont(font, fontSize, fontOutline)
		levelTextRegion:SetShadowOffset(LUI.mult, -LUI.mult)

		healthBar:SetStatusBarTexture(barTexture)

		healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
		healthBar.hpBackground:SetAllPoints(healthBar)
		healthBar.hpBackground:SetTexture(LUI_Media.blank)
		healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

		healthBar.hpGlow = CreateFrame( "Frame", nil, healthBar)
		healthBar.hpGlow:SetFrameLevel(healthBar:GetFrameLevel() -1 > 0 and healthBar:GetFrameLevel() -1 or 0)
		healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", LUI:Scale(-3), LUI:Scale(3))
		healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", LUI:Scale(3), LUI:Scale(-3))
		healthBar.hpGlow:SetBackdrop(backdrop)
		healthBar.hpGlow:SetBackdropColor(0, 0, 0)
		healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)

		castBar.castbarOverlay = castbarOverlay
		castBar.healthBar = healthBar
		castBar.shieldedRegion = shieldedRegion
		castBar:SetStatusBarTexture(barTexture)

		castBar:HookScript("OnShow", onShow)
		castBar:HookScript("OnSizeChanged", onSizeChanged)
		castBar:HookScript("OnValueChanged", onValueChanged)
		castBar:HookScript("OnEvent", onEvent)
		castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

		castBar.time = castBar:CreateFontString(nil, "ARTWORK")
		castBar.time:SetPoint("RIGHT", castBar, "LEFT", LUI:Scale(-2), 0)
		castBar.time:SetFont(font, fontSize, fontOutline)
		castBar.time:SetTextColor(fontColor.r, fontColor.g, fontColor.b)
		castBar.time:SetShadowOffset(LUI.mult, -LUI.mult)

		castBar.cbBackground = castBar:CreateTexture(nil, "BACKGROUND")
		castBar.cbBackground:SetAllPoints(castBar)
		castBar.cbBackground:SetTexture(LUI_Media.blank)
		castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15)

		castBar.cbGlow = CreateFrame( "Frame", nil, castBar)
		castBar.cbGlow:SetFrameLevel(castBar:GetFrameLevel() -1 > 0 and castBar:GetFrameLevel() -1 or 0)
		castBar.cbGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", LUI:Scale(-3), LUI:Scale(3))
		castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", LUI:Scale(3), LUI:Scale(-3))
		castBar.cbGlow:SetBackdrop(backdrop)
		castBar.cbGlow:SetBackdropColor(0.25, 0.25, 0.25, 0)
		castBar.cbGlow:SetBackdropBorderColor(0, 0, 0)

		castBar.Holder = CreateFrame( "Frame", nil, castBar)
		castBar.Holder:SetFrameLevel(castBar.Holder:GetFrameLevel() + 1)
		castBar.Holder:SetAllPoints()

		spellIconRegion:ClearAllPoints()
		spellIconRegion:SetParent(castBar)
		spellIconRegion:SetTexCoord(.08, .92, .08, .92)
		spellIconRegion:SetPoint("BOTTOMLEFT", castBar, "BOTTOMRIGHT", 5, 0.25)
		spellIconRegion:SetSize(LUI:Scale(15), LUI:Scale(15))

		spellIconRegion.IconBackdrop = CreateFrame( "Frame", nil, castBar)
		spellIconRegion.IconBackdrop:SetPoint("TOPLEFT", spellIconRegion, "TOPLEFT", LUI:Scale(-3), LUI:Scale(3))
		spellIconRegion.IconBackdrop:SetPoint("BOTTOMRIGHT", spellIconRegion, "BOTTOMRIGHT", LUI:Scale(3), LUI:Scale(-3))
		spellIconRegion.IconBackdrop:SetBackdrop(backdrop)
		spellIconRegion.IconBackdrop:SetBackdropColor(0, 0, 0)
		spellIconRegion.IconBackdrop:SetBackdropBorderColor(0, 0, 0)

		highlightRegion:SetTexture(barTexture)
		highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
		frame.highlight = highlightRegion

		raidIconRegion:ClearAllPoints()
		raidIconRegion:SetPoint("CENTER", healthBar, "CENTER", 0, LUI:Scale(-4))
		raidIconRegion:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp")
		raidIconRegion:SetSize(LUI:Scale(15), LUI:Scale(15))

		frame.oldglow = glowRegion
		frame.elite = stateIconRegion
		frame.boss = bossIconRegion
		castBar.icGlow = spellIconRegion.IconBackdrop

		frame.done = true

		glowRegion:SetTexture(nil)
		overlayRegion:SetTexture(nil)
		shieldedRegion:SetTexture(nil)
		castbarOverlay:SetTexture(nil)
		stateIconRegion:SetTexture(nil)
		bossIconRegion:SetTexture(nil)

		updatePlate(frame)
		frame:SetScript("OnShow", updatePlate)
		frame:SetScript("OnHide", onHide)

		frame.elapsed = 0
		frame:SetScript("OnUpdate", threatUpdate)
	end

	local numKids = 0
	local lastUpdate = 0
	DTEST = createPlate;
	DTEST2 = isValidFrame;

	tNamePlates:SetScript("OnUpdate", function(self, elapsed)
		lastUpdate = lastUpdate + elapsed

		if lastUpdate > 0.05 then
			lastUpdate = 0

			local newNumKids = WorldFrame:GetNumChildren()
			if newNumKids ~= numKids then
				for i = numKids + 1, newNumKids do
					local frame = select(i, WorldFrame:GetChildren())

					if isValidFrame(frame) then
						createPlate(frame)
					end
				end
				numKids = newNumKids
			end
		end
	end)

	tNamePlates:RegisterEvent("PLAYER_REGEN_ENABLED")
	function tNamePlates:PLAYER_REGEN_ENABLED()
		if db.Nameplates.HideOutOfCombat == true then
			SetCVar("nameplateShowEnemies", 0)
		end
	end

	tNamePlates:RegisterEvent("PLAYER_REGEN_DISABLED")
	function tNamePlates.PLAYER_REGEN_DISABLED()
		if db.Nameplates.ShowEnterCombat == true then
			SetCVar("nameplateShowEnemies", 1)
		end
	end
end

local defaults = {
	Nameplates = {
		Enable = true,
		HideOutOfCombat = true,
		ShowEnterCombat = true,
		FontSettings = {
			Font = "vibroceb",
			Flag = "OUTLINE",
			Size = 10,
			Color = {
				r = 0.84,
				g = 0.75,
				b = 0.65,
			},
		},
		HealthBar = {
			Colors = {
				FriendlyUnit = {
					r = 0.33,
					g = 0.59,
					b = 0.33,
				},
				FriendlyPlayer = {
					r = 0.31,
					g = 0.45,
					b = 0.63,
				},
				HostileUnit = {
					r = 0.69,
					g = 0.31,
					b = 0.31,
				},
				NeutralUnit = {
					r = 0.65,
					g = 0.63,
					b = 0.35,
				},
			},
			Height = 7,
			Width = 110,
		},
		CastBar = {
			Enable = true,
			Height = 5,
			Width = 110,
			XOffset = 0,
			YOffset = -4,
		},
		Name = {
			Enable = true,
			XOffset = 0,
			YOffset = 3,
		},
	},
}

function module:LoadOptions()
	local options = {
		Nameplates = {
			name = "Nameplates",
			type = "group",
			childGroups = "tab",
			disabled = function() return not db.Nameplates.Enable end,
			args = {
				Header = {
					name = "Nameplates",
					type = "header",
					order = 1,
				},
				Settings = {
					name = "Settings",
					type = "group",
					order = 3,
					args = {
						HideOutOfCombat = {
							name = "Auto Hide Nameplates",
							desc = "Hide Nameplates when not in combat automatically.",
							type = "toggle",
							width = "full",
							order = 1,
							get = function() return db.Nameplates.HideOutOfCombat end,
							set = function()
									db.Nameplates.HideOutOfCombat = not db.Nameplates.HideOutOfCombat
								end,
						},
						ShowEnterCombat = {
							name = "Auto Show Nameplates",
							desc = "Show Nameplates when entering combat automatically.",
							type = "toggle",
							width = "full",
							order = 2,
							get = function() return db.Nameplates.ShowEnterCombat end,
							set = function()
									db.Nameplates.ShowEnterCombat = not db.Nameplates.ShowEnterCombat
								end,
						},
						CastBar = {
							name = "Display Cast Bar",
							desc = "Enable LUI Nameplates' Cast Bar.\n",
							type = "toggle",
							width = "full",
							order = 3,
							disabled = true,
							get = function() return db.Nameplates.CastBar.Enable end,
							set = function()
									db.Nameplates.CastBar.Enable = not db.Nameplates.CastBar.Enable
								end,
						},
						Name = {
							name = "Display Name",
							desc = "Enable LUI Nameplates' Name Text.\n",
							type = "toggle",
							width = "full",
							order = 4,
							disabled = true,
							get = function() return db.Nameplates.Name.Enable end,
							set = function()
									db.Nameplates.Name.Enable = not db.Nameplates.Name.Enable
								end,
						},
					},
				},
				FontSettings = {
					name = "Font",
					type = "group",
					order = 4,
					args = {
						Color = {
							name = "Color",
							desc = "Choose an individual color for your Nameplates' Font.\n\nDefaults:\nr = "..LUI.defaults.profile.Nameplates.FontSettings.Color.r.."\ng = "..LUI.defaults.profile.Nameplates.FontSettings.Color.g.."\nb = "..LUI.defaults.profile.Nameplates.FontSettings.Color.b,
							type = "color",
							order = 1,
							hasAlpha = false,
							get = function() return db.Nameplates.FontSettings.Color.r, db.Nameplates.FontSettings.Color.g, db.Nameplates.FontSettings.Color.b end,
							set = function(self, r, g, b)
									db.Nameplates.FontSettings.Color.r = r
									db.Nameplates.FontSettings.Color.g = g
									db.Nameplates.FontSettings.Color.b = b
								end,
						},
						Size = {
							name = "Size",
							desc = "Choose a Font Size to be used by Nameplates.\n\nDefault: "..LUI.defaults.profile.Nameplates.FontSettings.Size,
							type = "input",
							order = 2,
							get = function() return tostring(db.Nameplates.FontSettings.Size) end,
							set = function(self, size)
									if (size == nil) or (size == "") then
										size = "0"
									end

									db.Nameplates.FontSettings.Size = tonumber(size)
								end,
						},
						Font = {
							name = "Font",
							desc = "Choose a Font to be used by Nameplates.\n\nDefault: "..LUI.defaults.profile.Nameplates.FontSettings.Font,
							type = "select",
							dialogControl = "LSM30_Font",
							values = widgetLists.font,
							order = 3,
							get = function() return db.Nameplates.FontSettings.Font end,
							set = function(self, font)
									db.Nameplates.FontSettings.Font = font
								end,
						},
						Flag = {
							name = "Outline",
							desc = "Choose a Font Flag to be used by Nameplates.\n\nDefault: "..LUI.defaults.profile.Nameplates.FontSettings.Flag,
							type = "select",
							values = fontflags,
							order = 4,
							get = function()
									for k, v in pairs(fontflags) do
										if db.Nameplates.FontSettings.Flag == v then
											return k
										end
									end
								end,
							set = function(self, flag)
									db.Nameplates.FontSettings.Flag = fontflags[flag]
								end,
						},
					},
				},
				HealthBar = {
					name = "Health Bar",
					type = "group",
					order = 5,
					args = {
						Size = {
							name = "Size",
							type = "group",
							guiInline = true,
							order = 1,
							args = {
								Height = {
									name = "Height",
									desc = "Set the Height of your Nameplates' Health Bar.\n\nDefault: "..LUI.defaults.profile.Nameplates.HealthBar.Height,
									type = "input",
									order = 1,
									get = function() return tostring(db.Nameplates.HealthBar.Height) end,
									set = function(self, height)
											if (height == nil) or (height == "") then
												height = "0"
											end

											db.Nameplates.HealthBar.Height = tonumber(height)
										end,
								},
								Width = {
									name = "Width",
									desc = "Set the Width of your Nameplates' Health Bar.\n\nDefault: "..LUI.defaults.profile.Nameplates.HealthBar.Width,
									type = "input",
									order = 2,
									get = function() return tostring(db.Nameplates.HealthBar.Width) end,
									set = function(self, width)
											if (width == nil) or (width == "") then
												width = "0"
											end

											db.Nameplates.HealthBar.Width = tonumber(width)
										end,
								},
							},
						},
						Colors = {
							name = "Colors",
							type = "group",
							guiInline = true,
							order = 2,
							args = {
								FriendlyUnit = {
									name = "Friendly Unit",
									desc = "Choose an individual color for Friendly Units.\n\nDefaults:\nr = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyUnit.r.."\ng = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyUnit.g.."\nb = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyUnit.b,
									type = "color",
									order = 1,
									hasAlpha = false,
									get = function() return db.Nameplates.HealthBar.Colors.FriendlyUnit.r, db.Nameplates.HealthBar.Colors.FriendlyUnit.g, db.Nameplates.HealthBar.Colors.FriendlyUnit.b end,
									set = function(self, r, g, b)
											db.Nameplates.HealthBar.Colors.FriendlyUnit.r = r
											db.Nameplates.HealthBar.Colors.FriendlyUnit.g = g
											db.Nameplates.HealthBar.Colors.FriendlyUnit.b = b
										end,
								},
								FriendlyPlayer = {
									name = "Friendly Player",
									desc = "Choose an individual color for Friendly Players.\n\nDefaults:\nr = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyPlayer.r.."\ng = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyPlayer.g.."\nb = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.FriendlyPlayer.b,
									type = "color",
									order = 2,
									hasAlpha = false,
									get = function() return db.Nameplates.HealthBar.Colors.FriendlyPlayer.r, db.Nameplates.HealthBar.Colors.FriendlyPlayer.g, db.Nameplates.HealthBar.Colors.FriendlyPlayer.b end,
									set = function(self, r, g, b)
											db.Nameplates.HealthBar.Colors.FriendlyPlayer.r = r
											db.Nameplates.HealthBar.Colors.FriendlyPlayer.g = g
											db.Nameplates.HealthBar.Colors.FriendlyPlayer.b = b
										end,
								},
								HostileUnit = {
									name = "Hostile Unit",
									desc = "Choose an individual color for Hostile Units.\n\nDefaults:\nr = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.HostileUnit.r.."\ng = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.HostileUnit.g.."\nb = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.HostileUnit.b,
									type = "color",
									order = 3,
									hasAlpha = false,
									get = function() return db.Nameplates.HealthBar.Colors.HostileUnit.r, db.Nameplates.HealthBar.Colors.HostileUnit.g, db.Nameplates.HealthBar.Colors.HostileUnit.b end,
									set = function(self, r, g, b)
											db.Nameplates.HealthBar.Colors.HostileUnit.r = r
											db.Nameplates.HealthBar.Colors.HostileUnit.g = g
											db.Nameplates.HealthBar.Colors.HostileUnit.b = b
										end,
								},
								NeutralUnit = {
									name = "Neutral Unit",
									desc = "Choose an individual color for Neutral Units.\n\nDefaults:\nr = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.NeutralUnit.r.."\ng = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.NeutralUnit.g.."\nb = "..LUI.defaults.profile.Nameplates.HealthBar.Colors.NeutralUnit.b,
									type = "color",
									order = 4,
									hasAlpha = false,
									get = function() return db.Nameplates.HealthBar.Colors.NeutralUnit.r, db.Nameplates.HealthBar.Colors.NeutralUnit.g, db.Nameplates.HealthBar.Colors.NeutralUnit.b end,
									set = function(self, r, g, b)
											db.Nameplates.HealthBar.Colors.NeutralUnit.r = r
											db.Nameplates.HealthBar.Colors.NeutralUnit.g = g
											db.Nameplates.HealthBar.Colors.NeutralUnit.b = b
										end,
								},
							},
						},
					},
				},
				CastBar = {
					name = "Cast Bar",
					type = "group",
					order = 6,
					disabled = function() return not db.Nameplates.CastBar.Enable end,
					args = {
						Size = {
							name = "Size",
							type = "group",
							guiInline = true,
							order = 1,
							args = {
								Height = {
									name = "Height",
									desc = "Set the Height of your Nameplates' Cast Bar.\n\nDefault: "..LUI.defaults.profile.Nameplates.CastBar.Height,
									type = "input",
									width = "half",
									order = 1,
									get = function() return tostring(db.Nameplates.CastBar.Height) end,
									set = function(self, height)
											if (height == nil) or (height == "") then
												height = "0"
											end
											db.Nameplates.CastBar.Height = tonumber(height)
										end,
								},
								Width = {
									name = "Width",
									desc = "Set the Width of your Nameplates' Cast Bar.\n\nDefault: "..LUI.defaults.profile.Nameplates.CastBar.Width,
									type = "input",
									width = "half",
									order = 2,
									get = function() return tostring(db.Nameplates.CastBar.Width) end,
									set = function(self, width)
											if (width == nil) or (width == "") then
												width = "0"
											end
											db.Nameplates.CastBar.Width = tonumber(width)
										end,
								},
							},
						},
						Offset = {
							name = "Offset",
							type = "group",
							guiInline = true,
							order = 2,
							args = {
								XOffset = {
									name = "X Offset",
									desc = "Set the X Offset of your Nameplates' Cast Bar.\n\nNotes:\nPositive values = right\nNegitive values = left\nDefault: "..LUI.defaults.profile.Nameplates.CastBar.XOffset,
									type = "input",
									width = "half",
									order = 1,
									get = function() return tostring(db.Nameplates.CastBar.XOffset) end,
									set = function(self, x)
											if (x == nil) or (x == "") then
												x = "0"
											end
											db.Nameplates.CastBar.XOffset = tonumber(x)
										end,
								},
								YOffset = {
									name = "Y Offset",
									desc = "Set the Y Offset of your Nameplates' Cast Bar.\n\nNotes:\nPositive values = up\nNegitive values = down\nDefault: "..LUI.defaults.profile.Nameplates.CastBar.YOffset,
									type = "input",
									width = "half",
									order = 2,
									get = function() return tostring(db.Nameplates.CastBar.YOffset) end,
									set = function(self, y)
											if (y == nil) or (y == "") then
												y = "0"
											end
											db.Nameplates.CastBar.YOffset = tonumber(y)
										end,
								},
							},
						},
					},
				},
				NameText = {
					name = "Name",
					type = "group",
					order = 7,
					disabled = function() return not db.Nameplates.Name.Enable end,
					args = {
						Offset = {
							name = "Offset",
							type = "group",
							guiInline = true,
							order = 1,
							args = {
								XOffset = {
									name = "X Offset",
									desc = "Set the X Offset of your Nameplates' Name Text.\n\nNotes:\nPositive values = right\nNegitive values = left\nDefault: "..LUI.defaults.profile.Nameplates.Name.XOffset,
									type = "input",
									width = "half",
									order = 1,
									get = function() return tostring(db.Nameplates.Name.XOffset) end,
									set = function(self, x)
											if (x == nil) or (x == "") then
												x = "0"
											end
											db.Nameplates.Name.XOffset = tonumber(x)
										end,
								},
								YOffset = {
									name = "Y Offset",
									desc = "Set the Y Offset of your Nameplates' Name Text.\n\nNotes:\nPositive values = up\nNegitive values = down\nDefault: "..LUI.defaults.profile.Nameplates.Name.YOffset,
									type = "input",
									width = "half",
									order = 2,
									get = function() return tostring(db.Nameplates.Name.YOffset) end,
									set = function(self, y)
											if (y == nil) or (y == "") then
												y = "0"
											end
											db.Nameplates.Name.YOffset = tonumber(y)
										end,
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

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	self.db = LUI.db.profile
	db = self.db

	LUI:RegisterModule(self)
end

function module:OnEnable()
	self:SetNameplates()
end

function module:OnDisable()
	LUI:ClearFrames()
end