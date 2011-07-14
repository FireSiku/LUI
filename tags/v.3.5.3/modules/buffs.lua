--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: buffs.lua
	Description: Buffs Module
	Version....: 1.3
	Rev Date...: 10/11/2010
	
	Edits:
		v1.0: Loui
		v1.1: Thaly
		v1.2: Thaly
		-  b: Thaly
		v1.3: Thaly
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Auras", "AceHook-3.0")

local db
local positions = {"TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT"}
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local sortorders = {"NAME", "INDEX", "TIME"}
local AuraAnchorsOnEnable

local function CreatePanel(height, width, x, y, anchorPoint, anchorPointRel, anchor, level, parent, strata)
	local Panel = CreateFrame("Frame", nil, parent)
	Panel:SetFrameLevel(level)
	Panel:SetFrameStrata(strata)
	Panel:SetHeight(height)
	Panel:SetWidth(width)
	Panel:SetPoint(anchorPoint, anchor, anchorPointRel, x, y)
	Panel:SetBackdrop( { 
	  bgFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Normal", 
	  edgeFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border", 
	  tile = false, tileSize = 0, edgeSize = 3, 
	  insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	--Panel:SetBackdropColor(0.3,0.3,0.3,1)
	Panel:SetBackdropColor(1,0,0,1)
	Panel:SetBackdropBorderColor(0,0,0,0)
	
	return Panel
end

local function CreateGlossPanel(height, width, x, y, anchorPoint, anchorPointRel, anchor, level, parent, strata, type, debuffcolor)
	local Panel = CreateFrame("Frame", nil, parent)
	Panel:SetFrameLevel(level)
	Panel:SetFrameStrata(strata)
	Panel:SetHeight(height)
	Panel:SetWidth(width)
	Panel:SetPoint(anchorPoint, anchor, anchorPointRel, x, y)
	Panel:SetBackdrop( { 
	  bgFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Normal", 
	  edgeFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border", 
	  tile = false, tileSize = 0, edgeSize = 3, 
	  insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	Panel:SetBackdropColor(0.3,0.3,0.3,0)
	Panel:SetBackdropBorderColor(0,0,0,0)
	
	if type == "debuff" then
		local overlay = Panel:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border")
		overlay:SetAllPoints(Panel)
		overlay:SetAlpha(1)
		--overlay:SetVertexColor(1,0,0,0.6)
		overlay:SetVertexColor(debuffcolor.r, debuffcolor.g, debuffcolor.b)
		--overlay:SetTexCoord(0.1,0.9,0.1,0.9)
		Panel.overlay = overlay
	else
		local overlay = Panel:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
		overlay:SetAllPoints(Panel)
		overlay:SetAlpha(1)
		overlay:SetTexCoord(0.1,0.9,0.1,0.9)
		Panel.overlay = overlay
	end

	return Panel
end 

local function CreateBarPanel(height, width, x, y, anchorPoint, anchorPointRel, anchor, level, parent, strata)
	local Panel = CreateFrame("Frame", nil, parent)
	Panel:SetFrameLevel(level)
	Panel:SetFrameStrata(strata)
	Panel:SetHeight(height)
	Panel:SetWidth(width)
	Panel:SetPoint(anchorPoint, anchor, anchorPointRel, x, y)
	Panel:SetBackdrop( { 
	  bgFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Normal", 
	  edgeFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border", 
	  tile = false, tileSize = 0, edgeSize = 3, 
	  insets = { left = -3, right = -3, top = -3, bottom = -3 }
	})
	Panel:SetBackdropColor(0.2,0.2,0.2,0.9)
	Panel:SetBackdropBorderColor(0.2,0.2,0.2,0.9)

	local overlay = Panel:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
	overlay:SetAllPoints(Panel)
	overlay:SetAlpha(0.7)
	overlay:SetTexCoord(0.1,0.9,0.1,0.9)
	Panel.overlay = overlay

	return Panel
end

function module:EnableBlizzardBuffs()	
	BuffFrame:RegisterEvent("UNIT_AURA")
	BuffFrame:Show()
	TemporaryEnchantFrame:Show()
	ConsolidatedBuffs:Show()
	ConsolidatedBuffsContainer:Show()
	CONSOLIDATE_BUFFS = 1
	ConsolidatedBuffs.Show = ConsolidatedBuffs.OrigShow
	ConsolidatedBuffs:Show()
end

function module:DisableBlizzardBuffs()
	if db.Auras.DisableBlizzard ~= true then return end
	
	BuffFrame:UnregisterAllEvents()
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
	ConsolidatedBuffs:Hide()
	ConsolidatedBuffsContainer:Hide()
	CONSOLIDATE_BUFFS = 0
	ConsolidatedBuffs.OrigShow = ConsolidatedBuffs.Show
	ConsolidatedBuffs.Show = ConsolidatedBuffs.Hide
end

function module:SetBuffs()
	if db.Auras.Enable ~= true then return end
	
	local buff_spacing, debuff_spacing, aura_spacing_row
	
	if db.Auras.Anchor == "TOPLEFT" then
		buff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size)
		debuff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size)
		
		aura_spacing_row = - ( tonumber(db.Auras.Spacing_row) )
	elseif db.Auras.Anchor == "TOPRIGHT" then
		buff_spacing = -(  tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size) )
		debuff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size) )
		
		aura_spacing_row = - ( tonumber(db.Auras.Spacing_row) )
	elseif db.Auras.Anchor == "BOTTOMLEFT" then
		buff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size)
		debuff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size)
		
		aura_spacing_row = tonumber(db.Auras.Spacing_row)
	else
		buff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size) )
		debuff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size) )
		
		aura_spacing_row = tonumber(db.Auras.Spacing_row)
	end
	
	local dummy = function() return end

	local DebuffTypeColor = { }
	DebuffTypeColor["none"]	= { r = 0.80, g = 0, b = 0 }
	DebuffTypeColor["Magic"]	= { r = 0.20, g = 0.60, b = 1.00 }
	DebuffTypeColor["Curse"]	= { r = 0.60, g = 0.00, b = 1.00 }
	DebuffTypeColor["Disease"]	= { r = 0.60, g = 0.40, b = 0 }
	DebuffTypeColor["Poison"]	= { r = 0.00, g = 0.60, b = 0 }
	DebuffTypeColor[""]	= DebuffTypeColor["none"]

	local buffHeader = CreateFrame("Frame", "LUIBuffs", UIParent, "SecureAuraHeaderTemplate")
	local debuffHeader = CreateFrame("Frame", "LUIDebuffs", UIParent, "SecureAuraHeaderTemplate")

	local function AuraButton_Create(button, filter)
		local size
		if filter == "HELPFUL" then size = tonumber(db.Auras.Buffs.Size) else size = tonumber(db.Auras.Debuffs.Size) end
		
		-- texture
		button.texture = button:CreateTexture(nil, "OVERLAY")
		button.texture:SetPoint("TOPLEFT")
		button.texture:SetPoint("BOTTOMRIGHT")
		button.texture:SetDrawLayer("OVERLAY")
		button.texture:SetTexCoord(.1, .9, .1, .9)
		
		-- panel/gloss
		button.overlay2 = button:CreateTexture(nil, "OVERLAY")
		button.overlay2:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
		button.overlay2:SetAllPoints(button)
		button.overlay2:SetAlpha(0.4)
		button.overlay2:SetBlendMode("ADD")
		button.overlay2:SetTexCoord(.1, .9, .1, .9)
				
		button.panel = CreatePanel(size+15, size+15, 0, 0, "CENTER", "CENTER", button, 3, button, "BACKGROUND")
		if filter == "HELPFUL" then
			button.gloss = CreateGlossPanel(size+2, size+2, 0, 0, "CENTER", "CENTER", button, 3, button, "BACKGROUND")
		else
			local debuffType = select(5, UnitAura("player", button:GetID(), filter))
			local color
			if (debuffType ~= nil) then
				color = DebuffTypeColor[debuffType]
			else
				color = DebuffTypeColor["none"]
			end
			button.gloss = CreateGlossPanel(size+2, size+2, 0, 0, "CENTER", "CENTER", button, 3, button, "BACKGROUND", "debuff", color)
		end
		
		-- subframe for texts
		button.vframe = CreateFrame("Frame", nil, button)
		button.vframe:SetAllPoints(button)
		button.vframe:SetFrameLevel(3)
		
		-- duration text
		button.duration = button.vframe:CreateFontString(nil, "OVERLAY")
		if filter == "HELPFUL" then
			button.duration:SetFont(LSM:Fetch("font", db.Auras.Buffs.Duration.Font), tonumber(db.Auras.Buffs.Duration.Size), db.Auras.Buffs.Duration.Outline)
			button.duration:SetTextColor(db.Auras.Buffs.Duration.Color.r, db.Auras.Buffs.Duration.Color.g, db.Auras.Buffs.Duration.Color.b ,1)
		else
			button.duration:SetFont(LSM:Fetch("font", db.Auras.Debuffs.Duration.Font), tonumber(db.Auras.Debuffs.Duration.Size), db.Auras.Debuffs.Duration.Outline)
			button.duration:SetTextColor(db.Auras.Debuffs.Duration.Color.r, db.Auras.Debuffs.Duration.Color.g, db.Auras.Debuffs.Duration.Color.b ,1)
		end
		button.duration:SetDrawLayer("OVERLAY")
		button.duration:SetPoint("BOTTOM", .5, -16)
		
		-- stack count
		button.count = button.vframe:CreateFontString(nil, "OVERLAY")
		if filter == "HELPFUL" then
			button.count:SetFont(LSM:Fetch("font", db.Auras.Buffs.Count.Font), tonumber(db.Auras.Buffs.Count.Size), db.Auras.Buffs.Count.Outline)
			button.count:SetTextColor(db.Auras.Buffs.Count.Color.r, db.Auras.Buffs.Count.Color.g, db.Auras.Buffs.Count.Color.b ,1)
		else
			button.count:SetFont(LSM:Fetch("font", db.Auras.Debuffs.Count.Font), tonumber(db.Auras.Debuffs.Count.Size), db.Auras.Debuffs.Count.Outline)
			button.count:SetTextColor(db.Auras.Debuffs.Count.Color.r, db.Auras.Debuffs.Count.Color.g, db.Auras.Debuffs.Count.Color.b ,1)
		end
		button.count:SetDrawLayer("OVERLAY")
		button.count:SetPoint("TOPLEFT", -1, -1)

		button.lastUpdate = 0
		button.filter = filter
	end

	local function AuraButton_UpdateCooldown(button, elapsed)
		if button.lastUpdate < 1 then
			button.lastUpdate = button.lastUpdate + elapsed
			return
		end
		
		button.lastUpdate = 0
		
		local name, _, _, _, _, duration, expirationTime = UnitAura("player", button:GetID(), button.filter)
		if name and duration > 0 then
			button.remaining = expirationTime - GetTime()
			button.duration:SetText(SecondsToTimeAbbrev(button.remaining))
			
			if GameTooltip:IsOwned(button) then
				GameTooltip:SetUnitAura("player", button:GetID(), button.filter)
			end
		end
	end

	local function AuraButton_UpdateTooltip(button, elapsed)
		if button.lastUpdate < 1 then
			button.lastUpdate = button.lastUpdate + elapsed
			return
		end
		
		button.lastUpdate = 0
		
		if GameTooltip:IsOwned(button) then
			local name = UnitAura("player", button:GetID(), button.filter)
			if name then
				GameTooltip:SetUnitAura("player", button:GetID(), button.filter)
			end
		end
	end
	
	local function AuraButton_Update(button, filter)
		if not button.panel then AuraButton_Create(button, filter) end
		
		local name, _, icon, count, debuffType, duration, expirationTime = UnitAura("player", button:GetID(), filter)
		if name then
			button.texture:SetTexture(icon)
			
			if filter == "HARMFUL" then
				local color
				if (debuffType ~= nil) then
					color = DebuffTypeColor[debuffType]
				else
					color = DebuffTypeColor["none"]
				end
				button.gloss.overlay:SetVertexColor(unpack(color))
			end
			
			if duration > 0 then
				button.remaining = expirationTime - GetTime()
				button:SetScript("OnUpdate", AuraButton_UpdateCooldown)
				AuraButton_UpdateCooldown(button, 5)
			else
				button.duration:SetText("")
				button:SetScript("OnUpdate", AuraButton_UpdateTooltip)
			end
			
			if count and count > 1 then
				button.count:SetText(count)
			else
				button.count:SetText("")
			end
		else
			button.duration:SetText("")
			button.count:SetText("")
			button:SetScript("OnUpdate", nil)
		end
	end

	local function TempEnchantButton_UpdateCooldown(button, elapsed)
		if button.lastUpdate < 1 then
			button.lastUpdate = button.lastUpdate + elapsed
			return
		end
		
		button.lastUpdate = 0
		
		local _, MHtime, _, _, OHtime = GetWeaponEnchantInfo()
		if button.slotID == 16 then
			button.remaining = MHtime/1000
		else
			button.remaining = OHtime/1000
		end
		
		button.duration:SetText(SecondsToTimeAbbrev(button.remaining))
		
		if GameTooltip:IsOwned(button) then
			GameTooltip:SetInventoryItem("player", button.slotID)
		end
	end

	local function TempEnchantButton_Update(button, slot, hasEnchant, remaining)
		if not button.panel then AuraButton_Create(button, "HELPFUL") end
		
		if hasEnchant then
			button.slotID = GetInventorySlotInfo(slot)
			local icon = GetInventoryItemTexture("player", button.slotID)
			button.texture:SetTexture(icon)
			
			local quality = GetInventoryItemQuality("player", button.slotID)
			local r, g, b = GetItemQualityColor(quality or 1)
			button.gloss.overlay:SetVertexColor(r,g,b)
			
			button:SetScript("OnUpdate", TempEnchantButton_UpdateCooldown)
			TempEnchantButton_UpdateCooldown(button, 5)
		else
			button.duration:SetText("")
			button:SetScript("OnUpdate", nil)
		end
	end

	local function UpdateAuraAnchors(header, event, unit)
		if unit ~= "player" and event ~= "PLAYER_ENTERING_WORLD" then return end
		
		for _, button in header:ActiveButtons() do AuraButton_Update(button, header.filter) end
		
		if header.filter == "HELPFUL" then
			local MHenchant, MHtime, _, OHenchant, OHtime = GetWeaponEnchantInfo()
			local Enchant1 = buffHeader:GetAttribute("tempEnchant1")
			local Enchant2 = buffHeader:GetAttribute("tempEnchant2")
			
			if Enchant1 then TempEnchantButton_Update(Enchant1, "MainHandSlot", MHenchant, MHtime) end
			if Enchant2 then TempEnchantButton_Update(Enchant2, "SecondaryHandSlot", OHenchant, OHtime) end
		end
	end
	AuraAnchorsOnEnable = UpdateAuraAnchors
	
	local function SetHeaderAttributes(header, templatename, aurasize, isBuff)
		local temp = templatename..aurasize
		
		header:SetAttribute("unit", "player")
		header:SetAttribute("filter", isBuff and "HELPFUL" or "HARMFUL")
        header:SetAttribute("template", temp)
		header:SetAttribute("seperateOwn", 0)
		header:SetAttribute("minWidth", aurasize)
		header:SetAttribute("minHeight", aurasize)
		
		header:SetAttribute("point", db.Auras.Anchor)
		header:SetAttribute("xOffset", isBuff and buff_spacing or debuff_spacing)
		header:SetAttribute("yOffset", 0)
		header:SetAttribute("wrapAfter", isBuff and tonumber(db.Auras.Num_row) or 16)
		header:SetAttribute("wrapXOffset", 0)
		header:SetAttribute("wrapYOffset", aura_spacing_row)
		header:SetAttribute("maxWraps", isBuff and tonumber(db.Auras.Row_max) or 1)
		
		header:SetAttribute("sortMethod", db.Auras.Sort)
		header:SetAttribute("sortDirection", db.Auras.SortReverse and "-" or "+")
		
		header.filter = isBuff and "HELPFUL" or "HARMFUL"
		
		if isBuff then
			header:SetAttribute("includeWeapons", 1)
            header:SetAttribute("weaponTemplate", temp)
			header:RegisterEvent("UNIT_INVENTORY_CHANGED")
			header:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		end
		
		header:RegisterEvent("PLAYER_ENTERING_WORLD")
		header:HookScript("OnEvent", UpdateAuraAnchors)
	end

	local function btn_iterator(self, i)
		i = i + 1
		local child = self:GetAttribute("child" .. i)
		if child and child:IsShown() then return i, child, child:GetAttribute("index") end
	end
	function buffHeader:ActiveButtons() return btn_iterator, self, 0 end
	function debuffHeader:ActiveButtons() return btn_iterator, self, 0 end

	SetHeaderAttributes(buffHeader, "LUIAuraButtonTemplate", tonumber(db.Auras.Buffs.Size), true)
	SetHeaderAttributes(debuffHeader, "LUIAuraButtonTemplate", tonumber(db.Auras.Debuffs.Size), false)

	buffHeader:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Buffs.X), tonumber(db.Auras.Buffs.Y))
	debuffHeader:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Debuffs.X), tonumber(db.Auras.Debuffs.Y))
	
	buffHeader:Show()
	debuffHeader:Show()
	
	SecondsToTimeAbbrev = function(time)
		local hr, m, s, text
		if time <= 0 then text = ""
		elseif(time < 3600 and time > 60) then
			hr = floor(time / 3600)
			m = floor(mod(time, 3600) / 60 + 1)
			text = format("%dm", m)
		elseif time < 60 then
			m = floor(time / 60)
			s = mod(time, 60)
			text = (m == 0 and format("%d", s))
		else
			hr = floor(time / 3600 + 1)
			text = format("%dh", hr)
		end
		return text
	end
end

local defaults = {
	Auras = {
		Enable = true,
		DisableBlizzard = true,
		Num_row = "16",
		Row_max = "2",
		Spacing_row = "52",
		Spacing = "12",
		Anchor = "TOPLEFT",
		Sort = "TIME",
		SortReverse = false,
		Buffs = {
			X = "30",
			Y = "-35",
			Size = 29,
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
			Count = {
				Font = "vibrocen",
				Size = 18,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
		Debuffs = {
			X = "30",
			Y = "-160",
			Size = 29,
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
			Count = {
				Font = "vibrocen",
				Size = 18,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
	},
}

local function ReapplyBuffStyle()
	local num = tonumber(db.Auras.Num_row) * tonumber(db.Auras.Row_max)
	for i = 1, num do
		local button = _G["LUIBuffsAuraButton"..i]
		if button then
			button.duration:SetFont(LSM:Fetch("font", db.Auras.Buffs.Duration.Font), tonumber(db.Auras.Buffs.Duration.Size), db.Auras.Buffs.Duration.Outline)
			button.duration:SetTextColor(db.Auras.Buffs.Duration.Color.r, db.Auras.Buffs.Duration.Color.g, db.Auras.Buffs.Duration.Color.b ,1)
			
			button.count:SetFont(LSM:Fetch("font", db.Auras.Buffs.Count.Font), tonumber(db.Auras.Buffs.Count.Size), db.Auras.Buffs.Count.Outline)
			button.count:SetTextColor(db.Auras.Buffs.Count.Color.r, db.Auras.Buffs.Count.Color.g, db.Auras.Buffs.Count.Color.b ,1)
		end
	end
end

local function ReapplyDebuffStyle()
	for i = 1, 16 do
		local button = _G["LUIDebuffsAuraButton"..i]
		if button then
			button.duration:SetFont(LSM:Fetch("font", db.Auras.Debuffs.Duration.Font), tonumber(db.Auras.Debuffs.Duration.Size), db.Auras.Debuffs.Duration.Outline)
			button.duration:SetTextColor(db.Auras.Debuffs.Duration.Color.r, db.Auras.Debuffs.Duration.Color.g, db.Auras.Debuffs.Duration.Color.b ,1)
			
			button.count:SetFont(LSM:Fetch("font", db.Auras.Debuffs.Count.Font), tonumber(db.Auras.Debuffs.Count.Size), db.Auras.Debuffs.Count.Outline)
			button.count:SetTextColor(db.Auras.Debuffs.Count.Color.r, db.Auras.Debuffs.Count.Color.g, db.Auras.Debuffs.Count.Color.b ,1)
		end
	end
end

function module:LoadOptions()
	local options = {
		Auras = {
			name = "Auras",
			type = "group",
			disabled = function() return not db.Auras.Enable end,
			childGroups = "tab",
			args = {
				Settings = {
					name = "Settings",
					type = "group",
					order = 3,
					args = {
						PlayerBuffsEnable = {
							name = "Enable Player Auras",
							desc = "Wether you want to show your Buffs/Debuffs or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Auras.Enable end,
							set = function(self,PlayerBuffsEnable)
									db.Auras.Enable = not db.Auras.Enable
									if db.Auras.Enable == true then
										db.Auras.DisableBlizzard = true
									end
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 1,
						},
						DisableBlizzardBuffs = {
							name = "Disable Default Auras",
							desc = "Wether you want to disable the Default Blizzard Buffs or not.\n\nNote: If LUI Buffs is enabled, this option is automatically activated.",
							type = "toggle",
							width = "full",
							disabled = function() return db.Auras.Enable end,
							get = function() return db.Auras.DisableBlizzard end,
							set = function()
									db.Auras.DisableBlizzard = not db.Auras.DisableBlizzard
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 2,
						},
						RowMax = {
							name = "Max Rows",
							desc = "Maximal Amount of Rows for Buffs.\nDefault: "..LUI.defaults.profile.Auras.Row_max,
							type = "input",
							disabled = function() return not db.Auras.Enable end,
							get = function() return db.Auras.Row_max end,
							set = function(self,RowMax)
									if RowMax == nil or RowMax == "" then
										RowMax = "0"
									end
									db.Auras.Row_max = RowMax
									LUIBuffs:SetAttribute("maxWraps", tonumber(RowMax))
								end,
							order = 3,
						},
						NumRow = {
							name = "Amount per Row",
							desc = "Choose an Amount of Buffs/Debuffs per Row.\nDefault: "..LUI.defaults.profile.Auras.Num_row,
							type = "input",
							disabled = function() return not db.Auras.Enable end,
							get = function() return db.Auras.Num_row end,
							set = function(self,NumRow)
									if NumRow == nil or NumRow == "" then
										NumRow = "0"
									end
									db.Auras.Num_row = NumRow
									LUIBuffs:SetAttribute("wrapAfter", tonumber(NumRow))
								end,
							order = 4,
						},
						Spacing = {
							name = "Spacing",
							desc = "Spacing between your Buffs/Debuffs.\nDefault: "..LUI.defaults.profile.Auras.Spacing,
							type = "input",
							disabled = function() return not db.Auras.Enable end,
							get = function() return db.Auras.Spacing end,
							set = function(self,Spacing)
									if Spacing == nil or Spacing == "" then
										Spacing = "0"
									end
									db.Auras.Spacing = Spacing
									
									local mult
									if LUIBuffs:GetAttribute("xOffset") < 0 then
										mult = -1
									else
										mult = 1
									end
									LUIBuffs:SetAttribute("xOffset", mult * (tonumber(Spacing) + tonumber(db.Auras.Buffs.Size)))
									LUIDebuffs:SetAttribute("xOffset", mult * (tonumber(Spacing) + tonumber(db.Auras.Debuffs.Size)))
								end,
							order = 5,
						},
						SpacingRow = {
							name = "Spacing between Rows",
							desc = "Spacing between your Buff Rows.\nDefault: "..LUI.defaults.profile.Auras.Spacing_row,
							type = "input",
							disabled = function() return not db.Auras.Enable end,
							get = function() return db.Auras.Spacing_row end,
							set = function(self,SpacingRow)
									if SpacingRow == nil or SpacingRow == "" then
										SpacingRow = "0"
									end
									db.Auras.Spacing_row = SpacingRow
									
									local mult
									if LUIBuffs:GetAttribute("wrapYOffset") < 0 then
										mult = -1
									else
										mult = 1
									end
									LUIBuffs:SetAttribute("wrapYOffset", tonumber(SpacingRow))
								end,
							order = 6,
						},
						Anchor = {
							name = "Initial Anchor",
							desc = "Choose the initinal Anchor for your Auras.\nDefault: "..LUI.defaults.profile.Auras.Anchor,
							type = "select",
							disabled = function() return not db.Auras.Enable end,
							values = positions,
							get = function()
									for k, v in pairs(positions) do
										if db.Auras.Anchor == v then
											return k
										end
									end
								end,
							set = function(self, Anchor)
									db.Auras.Anchor = positions[Anchor]
									
									local buff_spacing, debuff_spacing, aura_spacing_row
									
									if db.Auras.Anchor == "TOPLEFT" then
										buff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size)
										debuff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size)
										
										aura_spacing_row = - ( tonumber(db.Auras.Spacing_row) )
									elseif db.Auras.Anchor == "TOPRIGHT" then
										buff_spacing = -(  tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size) )
										debuff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size) )
										
										aura_spacing_row = - ( tonumber(db.Auras.Spacing_row) )
									elseif db.Auras.Anchor == "BOTTOMLEFT" then
										buff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size)
										debuff_spacing = tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size)
										
										aura_spacing_row = tonumber(db.Auras.Spacing_row)
									else
										buff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Buffs.Size) )
										debuff_spacing = - ( tonumber(db.Auras.Spacing) + tonumber(db.Auras.Debuffs.Size) )
										
										aura_spacing_row = tonumber(db.Auras.Spacing_row)
									end
									
									LUIBuffs:ClearAllPoints()
									LUIBuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Buffs.X), tonumber(db.Auras.Buffs.Y))
									LUIBuffs:SetAttribute("point", db.Auras.Anchor)
									LUIBuffs:SetAttribute("xOffset", buff_spacing)
									LUIBuffs:SetAttribute("wrapYOffset", aura_spacing_row)
									
									LUIDebuffs:ClearAllPoints()
									LUIDebuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Debuffs.X), tonumber(db.Auras.Debuffs.Y))
									LUIDebuffs:SetAttribute("point", db.Auras.Anchor)
									LUIDebuffs:SetAttribute("xOffset", debuff_spacing)
									LUIDebuffs:SetAttribute("wrapYOffset", aura_spacing_row)
								end,
							order = 7,
						},
						SortOrder = {
							name = "Sorting Order",
							desc = "Choose the Sorting order for your Buffs/Debuffs.",
							type = "select",
							disabled = function() return not db.Auras.Enable end,
							values = sortorders,
							get = function()
									for k, v in pairs(sortorders) do
										if db.Auras.Sort == v then
											return k
										end
									end
								end,
							set = function(_, SortOrder)
									db.Auras.Sort = sortorders[SortOrder]
									LUIBuffs:SetAttribute("sortMethod", db.Auras.Sort)
									LUIDebuffs:SetAttribute("sortMethod", db.Auras.Sort)
								end,
							order = 8,
						},
						SortReverse = {
							name = "Reverse Sorting",
							desc = "Choose wether you want to reverse the Sorting or not.",
							type = "toggle",
							disabled = function() return not db.Auras.Enable end,
							get = function() return db.Auras.SortReverse end,
							set = function()
									db.Auras.SortReverse = not db.Auras.SortReverse
									LUIBuffs:SetAttribute("sortDirection", db.Auras.SortReverse and "-" or "+")
									LUIDebuffs:SetAttribute("sortDirection", db.Auras.SortReverse and "-" or "+")
								end,
							order = 9,
						},
					},
				},
				Buffs = {
					name = "Buffs",
					type = "group",
					disabled = function() return not db.Auras.Enable end,
					order = 4,
					args = {
						Size = {
							name = "Size",
							desc = "Choose a Size for your Buffs\nDefault: "..LUI.defaults.profile.Auras.Buffs.Size,
							type = "range",
							min = 15,
							max = 35,
							step = 1,
							get = function() return db.Auras.Buffs.Size end,
							set = function(self,Size)
									db.Auras.Buffs.Size = Size
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 1,
						},
						emptyapb = {
							order = 3,
							width = "full",
							type = "description",
							name = " ",
						},
						BuffsX = {
							name = "X Value",
							desc = "X Value for your Player Buffs.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Auras.Buffs.X,
							type = "input",
							get = function() return db.Auras.Buffs.X end,
							set = function(self,BuffsX)
									if BuffsX == nil or BuffsX == "" then
										BuffsX = "0"
									end
									db.Auras.Buffs.X = BuffsX
									LUIBuffs:ClearAllPoints()
									LUIBuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Buffs.X), tonumber(db.Auras.Buffs.Y))
								end,
							order = 4,
						},
						BuffsY = {
							name = "Y Value",
							desc = "Y Value for your Player Buffs.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Auras.Buffs.Y,
							type = "input",
							get = function() return db.Auras.Buffs.Y end,
							set = function(self,BuffsY)
									if BuffsY == nil or BuffsY == "" then
										BuffsY = "0"
									end
									db.Auras.Buffs.Y = BuffsY
									LUIBuffs:ClearAllPoints()
									LUIBuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Buffs.X), tonumber(db.Auras.Buffs.Y))
								end,
							order = 5,
						},
						Duration = {
							name = "Duration",
							type = "group",
							guiInline = true,
							order = 6,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Auras Duration Fontsize!\n Default: "..LUI.defaults.profile.Auras.Buffs.Duration.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Auras.Buffs.Duration.Size end,
									set = function(_, FontSize)
											db.Auras.Buffs.Duration.Size = FontSize
											ReapplyBuffStyle()
										end,
									order = 1,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for Auras Duration!\n\nDefault: "..LUI.defaults.profile.Auras.Buffs.Duration.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Auras.Buffs.Duration.Font end,
									set = function(self, Font)
											db.Auras.Buffs.Duration.Font = Font
											ReapplyBuffStyle()
										end,
									order = 2,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Auras Duration.\nDefault: "..LUI.defaults.profile.Auras.Buffs.Duration.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Auras.Buffs.Duration.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Auras.Buffs.Duration.Outline = fontflags[FontFlag]
											ReapplyBuffStyle()
										end,
									order = 3,
								},
								Color = {
									name = "Color",
									desc = "Choose the Color for your Aura Duration.",
									type = "color",
									hasAlpha = false,
									get = function() return db.Auras.Buffs.Duration.Color.r, db.Auras.Buffs.Duration.Color.g, db.Auras.Buffs.Duration.Color.b end,
									set = function(_,r,g,b)
											db.Auras.Buffs.Duration.Color.r = r
											db.Auras.Buffs.Duration.Color.g = g
											db.Auras.Buffs.Duration.Color.b = b
											ReapplyBuffStyle()
										end,
									order = 4,
								},
							},
						},
						Count = {
							name = "Count",
							type = "group",
							guiInline = true,
							order = 7,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Auras Count Fontsize!\n Default: "..LUI.defaults.profile.Auras.Buffs.Count.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Auras.Buffs.Count.Size end,
									set = function(_, FontSize)
											db.Auras.Buffs.Count.Size = FontSize
											ReapplyBuffStyle()
										end,
									order = 1,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Auras Count!\n\nDefault: "..LUI.defaults.profile.Auras.Buffs.Count.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Auras.Buffs.Count.Font end,
									set = function(self, Font)
											db.Auras.Buffs.Count.Font = Font
											ReapplyBuffStyle()
										end,
									order = 2,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Auras Count.\nDefault: "..LUI.defaults.profile.Auras.Buffs.Count.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Auras.Buffs.Count.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Auras.Buffs.Count.Outline = fontflags[FontFlag]
											ReapplyBuffStyle()
										end,
									order = 3,
								},
								Color = {
									name = "Color",
									desc = "Choose the Color for your Aura Count.",
									type = "color",
									hasAlpha = false,
									get = function() return db.Auras.Buffs.Count.Color.r, db.Auras.Buffs.Count.Color.g, db.Auras.Buffs.Count.Color.b end,
									set = function(_,r,g,b)
											db.Auras.Buffs.Count.Color.r = r
											db.Auras.Buffs.Count.Color.g = g
											db.Auras.Buffs.Count.Color.b = b
											ReapplyBuffStyle()
										end,
									order = 4,
								},
							},
						},
					},
				},
				Debuffs = {
					name = "Debuffs",
					type = "group",
					disabled = function() return not db.Auras.Enable end,
					order = 5,
					args = {
						Size = {
							name = "Size",
							desc = "Choose a Size for your Debuffs\nDefault: "..LUI.defaults.profile.Auras.Debuffs.Size,
							type = "range",
							min = 15,
							max = 35,
							step = 1,
							get = function() return db.Auras.Debuffs.Size end,
							set = function(self,Size)
									db.Auras.Debuffs.Size = Size
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 1,
						},
						emptyapb = {
							order = 3,
							width = "full",
							type = "description",
							name = " ",
						},
						DebuffsX = {
							name = "Debuffs X Value",
							desc = "X Value for your Player Debuffs.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Auras.Debuffs.X,
							type = "input",
							get = function() return db.Auras.Debuffs.X end,
							set = function(self,DebuffsX)
									if DebuffsX == nil or DebuffsX == "" then
										DebuffsX = "0"
									end
									db.Auras.Debuffs.X = DebuffsX
									LUIDebuffs:ClearAllPoints()
									LUIDebuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Debuffs.X), tonumber(db.Auras.Debuffs.Y))
								end,
							order = 4,
						},
						DebuffsY = {
							name = "Debuffs Y Value",
							desc = "Y Value for your Player Debuffs.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Auras.Debuffs.Y,
							type = "input",
							get = function() return db.Auras.Debuffs.Y end,
							set = function(self,DebuffsY)
									if DebuffsY == nil or DebuffsY == "" then
										DebuffsY = "0"
									end
									db.Auras.Debuffs.Y = DebuffsY
									LUIDebuffs:ClearAllPoints()
									LUIDebuffs:SetPoint(db.Auras.Anchor, UIParent, db.Auras.Anchor, tonumber(db.Auras.Debuffs.X), tonumber(db.Auras.Debuffs.Y))
								end,
							order = 5,
						},
						Duration = {
							name = "Duration",
							type = "group",
							guiInline = true,
							order = 6,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Auras Duration Fontsize!\n Default: "..LUI.defaults.profile.Auras.Debuffs.Duration.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Auras.Debuffs.Duration.Size end,
									set = function(_, FontSize)
											db.Auras.Debuffs.Duration.Size = FontSize
											ReapplyDebuffStyle()
										end,
									order = 1,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for Auras Duration!\n\nDefault: "..LUI.defaults.profile.Auras.Debuffs.Duration.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Auras.Debuffs.Duration.Font end,
									set = function(self, Font)
											db.Auras.Debuffs.Duration.Font = Font
											ReapplyDebuffStyle()
										end,
									order = 2,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Auras Duration.\nDefault: "..LUI.defaults.profile.Auras.Debuffs.Duration.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Auras.Debuffs.Duration.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Auras.Debuffs.Duration.Outline = fontflags[FontFlag]
											ReapplyDebuffStyle()
										end,
									order = 3,
								},
								Color = {
									name = "Color",
									desc = "Choose the Color for your Aura Duration.",
									type = "color",
									hasAlpha = false,
									get = function() return db.Auras.Debuffs.Duration.Color.r, db.Auras.Debuffs.Duration.Color.g, db.Auras.Debuffs.Duration.Color.b end,
									set = function(_,r,g,b)
											db.Auras.Debuffs.Duration.Color.r = r
											db.Auras.Debuffs.Duration.Color.g = g
											db.Auras.Debuffs.Duration.Color.b = b
											ReapplyDebuffStyle()
										end,
									order = 4,
								},
							},
						},
						Count = {
							name = "Count",
							type = "group",
							guiInline = true,
							order = 7,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Auras Count Fontsize!\n Default: "..LUI.defaults.profile.Auras.Debuffs.Count.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Auras.Debuffs.Count.Size end,
									set = function(_, FontSize)
											db.Auras.Debuffs.Count.Size = FontSize
											ReapplyDebuffStyle()
										end,
									order = 1,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Auras Count!\n\nDefault: "..LUI.defaults.profile.Auras.Buffs.Count.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Auras.Debuffs.Count.Font end,
									set = function(self, Font)
											db.Auras.Debuffs.Count.Font = Font
											ReapplyDebuffStyle()
										end,
									order = 2,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Auras Count.\nDefault: "..LUI.defaults.profile.Auras.Debuffs.Count.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Auras.Debuffs.Count.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Auras.Debuffs.Count.Outline = fontflags[FontFlag]
											ReapplyDebuffStyle()
										end,
									order = 3,
								},
								Color = {
									name = "Color",
									desc = "Choose the Color for your Aura Count.",
									type = "color",
									hasAlpha = false,
									get = function() return db.Auras.Debuffs.Count.Color.r, db.Auras.Debuffs.Count.Color.g, db.Auras.Debuffs.Count.Color.b end,
									set = function(_,r,g,b)
											db.Auras.Debuffs.Count.Color.r = r
											db.Auras.Debuffs.Count.Color.g = g
											db.Auras.Debuffs.Count.Color.b = b
											ReapplyDebuffStyle()
										end,
									order = 4,
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
	
	local SetAuraAnchors = function()
		if db.Auras.Enable then
			AuraAnchorsOnEnable(LUIBuffs, "PLAYER_ENTERING_WORLD")
			AuraAnchorsOnEnable(LUIDebuffs, "PLAYER_ENTERING_WORLD")
		end
	end
	
	LUI:RegisterModule(self, nil, SetAuraAnchors)
end

function module:OnEnable()
	self:SetBuffs()
	self:DisableBlizzardBuffs()
end

function module:OnDisable()
	LUI:ClearFrames()
	self:EnableBlizzardBuffs()
end