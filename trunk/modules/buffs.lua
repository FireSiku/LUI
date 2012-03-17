--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: buffs.lua
	Description: Buffs Module
	Version....: 1.4
	Rev Date...: 11/02/2012
	
	Edits:
		v1.0: Loui
		v1.1: Thaly
		v1.2: Thaly
		-  b: Thaly
		v1.3: Thaly
		v1.4: Thaly
]]

local addonname, LUI = ...
local module = LUI:Module("Auras")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db, dbd
local positions = {"TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT"}
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local sortorders = {"NAME", "INDEX", "TIME"}
local AuraAnchorsOnEnable

local UnitAura = UnitAura

LUI.Versions.auras = 1.4

local function CreatePanel(height, width, x, y, anchorPoint, anchorPointRel, anchor, level, parent, strata)
	local Panel = CreateFrame("Frame", nil, parent)
	Panel:SetFrameLevel(level)
	Panel:SetFrameStrata(strata)
	Panel:SetHeight(height)
	Panel:SetWidth(width)
	Panel:SetPoint(anchorPoint, anchor, anchorPointRel, x, y)
	Panel:SetBackdrop({ 
		bgFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Normal", 
		edgeFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border", 
		tile = false, tileSize = 0, edgeSize = 3, 
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
	Panel:SetBackdropColor(1, 0, 0, 1)
	Panel:SetBackdropBorderColor(0, 0, 0, 0)
	
	return Panel
end

local function CreateGlossPanel(height, width, x, y, anchorPoint, anchorPointRel, anchor, level, parent, strata, isDebuff, color)
	local Panel = CreateFrame("Frame", nil, parent)
	Panel:SetFrameLevel(level)
	Panel:SetFrameStrata(strata)
	Panel:SetHeight(height)
	Panel:SetWidth(width)
	Panel:SetPoint(anchorPoint, anchor, anchorPointRel, x, y)
	Panel:SetBackdrop({ 
		bgFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Normal", 
		edgeFile = "Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border", 
		tile = false, tileSize = 0, edgeSize = 3, 
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	})
	Panel:SetBackdropColor(0.3, 0.3, 0.3, 0)
	Panel:SetBackdropBorderColor(0, 0, 0, 0)
	
	if isDebuff then
		local overlay = Panel:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Border")
		overlay:SetAllPoints(Panel)
		overlay:SetAlpha(1)
		overlay:SetVertexColor(color.r, color.g, color.b)
		Panel.overlay = overlay
	else
		local overlay = Panel:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
		overlay:SetAllPoints(Panel)
		overlay:SetAlpha(1)
		overlay:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		Panel.overlay = overlay
	end

	return Panel
end 

function module:EnableBlizzardBuffs()	
	LUI:Module("Unitframes"):Module("HideBlizzard"):Show("aura", true)
end

function module:DisableBlizzardBuffs()
	if db.General.DisableBlizzard ~= true then return end
	
	LUI:Module("Unitframes"):Module("HideBlizzard"):Hide("aura", true)
end

function module:SetBuffs()
	if db.Enable ~= true then return end
	
	if LUIBuffs then
		LUIBuffs:Show()
		LUIDebuffs:Show()
		self:Refresh()
		return
	end
	
	local buff_spacing, debuff_spacing, aura_spacing_row, opposite, consolx, consoly
	
	if db.General.Anchor == "TOPLEFT" then
		buff_spacing = db.General.Spacing + db.Buffs.Size
		debuff_spacing = db.General.Spacing + db.Debuffs.Size
		
		aura_spacing_row = - db.General.Spacing_row
		opposite = "BOTTOMRIGHT"
		consolx = 6
		consoly = -6
	elseif db.General.Anchor == "TOPRIGHT" then
		buff_spacing = - (db.General.Spacing + db.Buffs.Size)
		debuff_spacing = - (db.General.Spacing + db.Debuffs.Size)
		
		aura_spacing_row = - db.General.Spacing_row
		opposite = "BOTTOMLEFT"
		consolx = -6
		consoly = -6
	elseif db.General.Anchor == "BOTTOMLEFT" then
		buff_spacing = db.General.Spacing + db.Buffs.Size
		debuff_spacing = db.General.Spacing + db.Debuffs.Size
		
		aura_spacing_row = db.General.Spacing_row
		opposite = "TOPRIGHT"
		consolx = 6
		consoly = 6
	else
		buff_spacing = - (db.General.Spacing + db.Buffs.Size)
		debuff_spacing = - (db.General.Spacing + db.Debuffs.Size)
		
		aura_spacing_row = db.General.Spacing_row
		opposite = "TOPLEFT"
		consolx = -6
		consoly = 6
	end
	
	local dummy = function() return end
	
	local DebuffTypeColor = {
		none = {r = .8, g = 0, b = 0},
		Magic = {r = 0.2, g = 0.6, b = 1},
		Curse = {r = 0.6, g = 0, b = 1},
		Disease = {r = 0.6, g = 0.4, b = 0},
		Poison = {r = 0, g = 0.6, b = 0},
		[""] = {r = .8, g = 0, b = 0}
	}
	
	local buffHeader = CreateFrame("Frame", "LUIBuffs", UIParent, "SecureAuraHeaderTemplate")
	local debuffHeader = CreateFrame("Frame", "LUIDebuffs", UIParent, "SecureAuraHeaderTemplate")
	local consolidateHeader = CreateFrame("Frame", "LUIConsolidate", UIParent, "SecureFrameTemplate")
	consolidateHeader:SetFrameStrata("DIALOG")
	local proxy = CreateFrame("Frame", buffHeader:GetName() .. "ProxyButton", buffHeader, "LUIAuraProxyTemplate"..db.Buffs.Size)
	
	local SecondsToTimeAbbrev = function(t)
		if t <= 0 then
			return ""
		elseif t < 60 then
			local s = mod(t, 60)
			return format("%d", s)
		elseif t < 3600 then
			local m = floor(mod(t, 3600) / 60 + 1)
			return format("%dm", m)
		else
			local hr = floor(t / 3600 + 1)
			return format("%dh", hr)
		end
	end
	
	local function AuraButton_Create(button, filter)
		local size = filter == "HELPFUL" and db.Buffs.Size or db.Debuffs.Size
		
		button.header = button:GetParent()
		if string.find(button:GetName(), "Consolidate") then button:SetFrameStrata("DIALOG") end
		
		-- texture
		button.texture = button:CreateTexture(nil, "OVERLAY")
		button.texture:SetPoint("TOPLEFT")
		button.texture:SetPoint("BOTTOMRIGHT")
		button.texture:SetTexCoord(.1, .9, .1, .9)
		
		-- panel/gloss
		button.overlay2 = button:CreateTexture(nil, "OVERLAY")
		button.overlay2:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
		button.overlay2:SetAllPoints(button)
		button.overlay2:SetAlpha(0.4)
		button.overlay2:SetBlendMode("ADD")
		button.overlay2:SetTexCoord(.1, .9, .1, .9)
		
		-- blocker frame
		button.block = CreateFrame("Frame", nil, button)
		button.block:SetAllPoints(button)
		button.block:EnableMouse(true)
		button.block:Hide()
		
		button.panel = CreatePanel(size + 15, size + 15, 0, 0, "CENTER", "CENTER", button, 3, button, button.header == consolidateHeader and "MEDIUM" or "BACKGROUND")
		if filter == "HELPFUL" then
			button.gloss = CreateGlossPanel(size + 2, size + 2, 0, 0, "CENTER", "CENTER", button, 7, button, button.header == consolidateHeader and "MEDIUM" or "BACKGROUND")
		else
			local debuffType = select(5, UnitAura("player", button:GetID(), filter))
			button.gloss = CreateGlossPanel(size + 2, size + 2, 0, 0, "CENTER", "CENTER", button, 3, button, "BACKGROUND", true, DebuffTypeColor[debuffType or "none"])
		end
		
		-- subframe for texts
		button.vframe = CreateFrame("Frame", nil, button)
		button.vframe:SetAllPoints(button)
		button.vframe:SetFrameLevel(3)
		
		-- duration text
		button.duration = button.vframe:CreateFontString(nil, "OVERLAY")
		if filter == "HELPFUL" then
			button.duration:SetFont(Media:Fetch("font", db.Buffs.Duration.Font), db.Buffs.Duration.Size, db.Buffs.Duration.Outline)
			button.duration:SetTextColor(db.Buffs.Duration.Color.r, db.Buffs.Duration.Color.g, db.Buffs.Duration.Color.b ,1)
		else
			button.duration:SetFont(Media:Fetch("font", db.Debuffs.Duration.Font), db.Debuffs.Duration.Size, db.Debuffs.Duration.Outline)
			button.duration:SetTextColor(db.Debuffs.Duration.Color.r, db.Debuffs.Duration.Color.g, db.Debuffs.Duration.Color.b ,1)
		end
		button.duration:SetDrawLayer("OVERLAY")
		button.duration:SetPoint("BOTTOM", .5, -16)
		
		-- stack count
		button.count = button.vframe:CreateFontString(nil, "OVERLAY")
		if filter == "HELPFUL" then
			button.count:SetFont(Media:Fetch("font", db.Buffs.Count.Font), db.Buffs.Count.Size, db.Buffs.Count.Outline)
			button.count:SetTextColor(db.Buffs.Count.Color.r, db.Buffs.Count.Color.g, db.Buffs.Count.Color.b ,1)
		else
			button.count:SetFont(Media:Fetch("font", db.Debuffs.Count.Font), db.Debuffs.Count.Size, db.Debuffs.Count.Outline)
			button.count:SetTextColor(db.Debuffs.Count.Color.r, db.Debuffs.Count.Color.g, db.Debuffs.Count.Color.b ,1)
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
		
		local name, _, _, _, _, duration, expirationTime = UnitAura(button.header:GetAttribute("unit"), button:GetID(), button.filter)
		if name and duration > 0 then
			button.remaining = expirationTime - GetTime()
			button.duration:SetText(SecondsToTimeAbbrev(button.remaining))
			
			if GameTooltip:IsOwned(button) then
				if button:GetAlpha() == 1 then
					GameTooltip:SetUnitAura(button.header:GetAttribute("unit"), button:GetID(), button.filter)
				else
					GameTooltip:Hide()
				end
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
			local name = UnitAura(button.header:GetAttribute("unit"), button:GetID(), button.filter)
			if name then
				if button:GetAlpha() == 1 then
					GameTooltip:SetUnitAura(button.header:GetAttribute("unit"), button:GetID(), button.filter)
				else
					GameTooltip:Hide()
				end
			end
		end
	end
	
	local function AuraButton_Update(button, filter)
		if not button.panel then AuraButton_Create(button, filter) end
		
		local name, _, icon, count, debuffType, duration, expirationTime = UnitAura(button.header:GetAttribute("unit"), button:GetID(), filter)
		if name then
			button.texture:SetTexture(icon)
			if filter == "HARMFUL" then
				local c = DebuffTypeColor[debuffType or "none"]
				button.gloss.overlay:SetVertexColor(c.r, c.g, c.b)
			end
			
			if duration > 0 then
				button.remaining = expirationTime - GetTime()
				button:SetScript("OnUpdate", AuraButton_UpdateCooldown)
				AuraButton_UpdateCooldown(button, 5)
			else
				button.remaining = nil
				button.duration:SetText()
				button:SetScript("OnUpdate", AuraButton_UpdateTooltip)
			end
			
			if count and count > 1 then
				button.count:SetFormattedText("%d", count)
			else
				button.count:SetText()
			end
		else
			button.duration:SetText()
			button.count:SetText()
			button:SetScript("OnUpdate", nil)
		end
	end

	local function TempEnchantButton_UpdateCooldown(button, elapsed)
		if button.lastUpdate < 1 then
			button.lastUpdate = button.lastUpdate + elapsed
			return
		end
		
		if not button.texture:GetTexture() then
			local icon = GetInventoryItemTexture(button.header:GetAttribute("unit"), button.slotID)
			button.texture:SetTexture(icon)
		end
		
		button.lastUpdate = 0
		
		local _, MHtime, _, _, OHtime, _, _, RAtime = GetWeaponEnchantInfo()
		if button.slotID == 16 then
			button.remaining = MHtime/1000
		elseif button.slotID == 17 then
			button.remaining = OHtime/1000
		else
			button.remaining = RAtime/1000
		end
		
		button.duration:SetText(SecondsToTimeAbbrev(button.remaining))
		
		if GameTooltip:IsOwned(button) then
			GameTooltip:SetInventoryItem(button.header:GetAttribute("unit"), button.slotID)
		end
	end

	local function TempEnchantButton_Update(button, slot, hasEnchant, remaining)
		if not button.panel then AuraButton_Create(button, "HELPFUL") end
		
		if hasEnchant then
			button.slotID = GetInventorySlotInfo(slot)
			local icon = GetInventoryItemTexture(button.header:GetAttribute("unit"), button.slotID)
			button.texture:SetTexture(icon)
			
			local quality = GetInventoryItemQuality(button.header:GetAttribute("unit"), button.slotID)
			local r, g, b = GetItemQualityColor(quality or 1)
			button.gloss.overlay:SetVertexColor(r,g,b)
			
			button:SetScript("OnUpdate", TempEnchantButton_UpdateCooldown)
			TempEnchantButton_UpdateCooldown(button, 5)
		else
			button.duration:SetText()
			button:SetScript("OnUpdate", nil)
		end
	end

	local function UpdateAuraAnchors(header, event, unit)
		if unit ~= "player" and unit ~= "vehicle" and event ~= "PLAYER_ENTERING_WORLD" then return end
		
		for _, button in header:ActiveButtons() do
			AuraButton_Update(button, header.filter)
		end
		
		local num, i, count = 0, 0, 0
		if header == buffHeader then
			while true do
				local name, _, _, _, _, _, _, _, _, consolidate = UnitAura("player", i + 1)
				if not name then break end
				if not consolidate or not db.General.Consolidate then
					num = num + 1
				else
					count = count + 1
				end
				i = i + 1
			end
			
			for i, button in header:ActiveButtons() do
				button:SetAlpha(i > num and 0 or 1)
				if button.block then
				button.block[i > num and "Show" or "Hide"](button.block)
				else
					print(button:GetName())
				end
			end
			
			proxy.count:SetText(count > 1 and count or "")
		end
		
		if header == buffHeader then
			local MHenchant, MHtime, _, OHenchant, OHtime, _, RAenchant, RAtime = GetWeaponEnchantInfo()
			local Enchant1 = header:GetAttribute("tempEnchant1")
			local Enchant2 = header:GetAttribute("tempEnchant2")
			local Enchant3 = header:GetAttribute("tempEnchant3")
			
			if Enchant1 then TempEnchantButton_Update(Enchant1, "MainHandSlot", MHenchant, MHtime) end
			if Enchant2 then TempEnchantButton_Update(Enchant2, "SecondaryHandSlot", OHenchant, OHtime) end
			if Enchant3 then TempEnchantButton_Update(Enchant3, "RangedSlot", RAenchant, RAtime) end
			
			UpdateAuraAnchors(consolidateHeader, event, unit)
		end
	end
	AuraAnchorsOnEnable = UpdateAuraAnchors
	
	local function SetHeaderAttributes(header, templatename, aurasize, isBuff, isConsolidate)
		local temp = templatename..aurasize
		
		header:SetClampedToScreen(true)
		
		header:SetAttribute("unit", "player")
		header:SetAttribute("filter", isBuff and "HELPFUL" or "HARMFUL")
        header:SetAttribute("template", temp)
		header:SetAttribute("seperateOwn", 0)
		header:SetAttribute("minWidth", aurasize)
		header:SetAttribute("minHeight", aurasize)
		
		header:SetAttribute("point", db.General.Anchor)
		header:SetAttribute("xOffset", isBuff and buff_spacing or debuff_spacing)
		header:SetAttribute("yOffset", 0)
		header:SetAttribute("wrapAfter", isConsolidate and 8 or db.General.Num_row)
		header:SetAttribute("wrapXOffset", 0)
		header:SetAttribute("wrapYOffset", aura_spacing_row)
		header:SetAttribute("maxWraps", isConsolidate and 3 or isBuff and db.General.Row_max or 1)
		
		header:SetAttribute("sortMethod", db.General.Sort)
		header:SetAttribute("sortDirection", db.General.SortReverse and "-" or "+")
		
		header.filter = isBuff and "HELPFUL" or "HARMFUL"
		
		if isBuff then
			header:SetAttribute("consolidateTo", db.General.Consolidate and 1 or 0)
			header:SetAttribute("consolidateDuration", -1)
			header:SetAttribute("consolidateThreshold", -1)
			header:SetAttribute("consolidateFraction", -1)
			
			header:SetAttribute("includeWeapons", 1)
            header:SetAttribute("weaponTemplate", temp)
			
			header:RegisterEvent("UNIT_INVENTORY_CHANGED")
			header:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		end
		
		if isConsolidate then
			SecureHandlerSetFrameRef(proxy, "header", consolidateHeader)
		else
			header:RegisterEvent("PLAYER_ENTERING_WORLD")
			header:HookScript("OnEvent", UpdateAuraAnchors)
		end
		
		RegisterAttributeDriver(header, "unit", "[vehicleui] vehicle; player")
	end

	local function btn_iterator(self, i)
		i = i + 1
		local child = self:GetAttribute("child" .. i)
		if child and child:IsShown() then return i, child, child:GetAttribute("index") end
	end
	
	function buffHeader:ActiveButtons() return btn_iterator, self, 0 end
	function debuffHeader:ActiveButtons() return btn_iterator, self, 0 end
	function consolidateHeader:ActiveButtons() return btn_iterator, self, 0 end
	
	proxy.header = proxy:GetParent()
	
	proxy.texture = proxy:CreateTexture(nil, "OVERLAY")
	proxy.texture:SetPoint("TOPLEFT")
	proxy.texture:SetPoint("BOTTOMRIGHT")
	proxy.texture:SetDrawLayer("OVERLAY")
	proxy.texture:SetTexture("Interface\\Buttons\\BuffConsolidation")
	proxy.texture:SetTexCoord(19/128, 45/128, 19/64, 45/64)
	--proxy.texture:SetTexture("Interface\\Icons\\Pvpcurrency-honor-"..(UnitFactionGroup("player") == "Horde" and [[horde]] or [[alliance]]))
	--proxy.texture:SetTexCoord(.05, .95, .05, .95)
	
	proxy.overlay2 = proxy:CreateTexture(nil, "OVERLAY")
	proxy.overlay2:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\buttons\\Gloss")
	proxy.overlay2:SetAllPoints(proxy)
	proxy.overlay2:SetAlpha(0.4)
	proxy.overlay2:SetBlendMode("ADD")
	proxy.overlay2:SetTexCoord(.1, .9, .1, .9)
	
	proxy.panel = CreatePanel(db.Buffs.Size + 15, db.Buffs.Size + 15, 0, 0, "CENTER", "CENTER", proxy, 3, proxy, "BACKGROUND")
	proxy.gloss = CreateGlossPanel(db.Buffs.Size + 2, db.Buffs.Size + 2, 0, 0, "CENTER", "CENTER", proxy, 3, proxy, "BACKGROUND")
	
	-- subframe for texts
	proxy.vframe = CreateFrame("Frame", nil, proxy)
	proxy.vframe:SetAllPoints(proxy)
	proxy.vframe:SetFrameLevel(3)
	
	-- count
	proxy.count = proxy.vframe:CreateFontString(nil, "OVERLAY")
	proxy.count:SetFont(Media:Fetch("font", db.Buffs.Count.Font), db.Buffs.Count.Size, db.Buffs.Count.Outline)
	proxy.count:SetTextColor(db.Buffs.Count.Color.r, db.Buffs.Count.Color.g, db.Buffs.Count.Color.b ,1)
	proxy.count:SetDrawLayer("OVERLAY")
	proxy.count:SetPoint("TOPLEFT", -1, -1)
	
	SetHeaderAttributes(buffHeader, "LUIAuraButtonTemplate", db.Buffs.Size, true)
	SetHeaderAttributes(debuffHeader, "LUIAuraButtonTemplate", db.Debuffs.Size)
	SetHeaderAttributes(consolidateHeader, "LUIAuraButtonTemplate", db.Buffs.Size, true, true)
	
	buffHeader:SetAttribute("consolidateProxy", proxy)
	buffHeader:SetAttribute("consolidateHeader", consolidateHeader)
	
	buffHeader:SetPoint(db.General.Anchor, UIParent, db.General.Anchor, db.Buffs.X, db.Buffs.Y)
	debuffHeader:SetPoint(db.General.Anchor, UIParent, db.General.Anchor, db.Debuffs.X, db.Debuffs.Y)
	
	consolidateHeader:SetParent(proxy)
	consolidateHeader:ClearAllPoints()
	consolidateHeader:SetPoint(db.General.Anchor, proxy, opposite, consolx, consoly)
	
	buffHeader:Show()
	debuffHeader:Show()
	consolidateHeader:Hide()
	
	local BG = CreateFrame("Frame", nil, consolidateHeader)
	BG:SetPoint("TOPLEFT", consolidateHeader, "TOPLEFT", -10, 10)
	BG:SetPoint("BOTTOMRIGHT", consolidateHeader, "BOTTOMRIGHT", 10, -25)
	BG:SetFrameStrata("HIGH")
	BG:SetFrameLevel(BG:GetFrameLevel() - 2)
	BG:SetBackdrop({ 
		bgFile = Media:Fetch("background", "Blizzard Tooltip"), 
		edgeFile = Media:Fetch("border", "Stripped_medium"), 
		tile = false, edgeSize = 14, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	BG:SetBackdropColor(0.18, 0.18, 0.18, 1)
	BG:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	
	local dropdown = CreateFrame("Button", "LUIBuffsProxyOpenButton", proxy, "SecureHandlerClickTemplate")
	dropdown:SetAllPoints()
	dropdown:RegisterForClicks("AnyUp")
	dropdown:SetAttribute("_onclick", [[
		local header = self:GetParent():GetFrameRef("header")
		
		if header:IsShown() then
			header:Hide()
		else
			header:Show()
		end
	]])
end

module.defaults = {
	profile = {
		Enable = true,
		General = {
			Consolidate = true,
			DisableBlizzard = true,
			Num_row = 16,
			Row_max = 2,
			Spacing_row = 52,
			Spacing = 12,
			Anchor = "TOPLEFT",
			Sort = "TIME",
			SortReverse = false,
		},
		Buffs = {
			X = 30,
			Y = -35,
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
				Outline = "OUTLINE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
		Debuffs = {
			X = 30,
			Y = -160,
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
				Outline = "OUTLINE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
	}
}

module.optionsName = "Auras"
module.getter = "generic"
module.setter = "Refresh"

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" then
		db(info, value)
	end
	
	if not db.Enable then return end
	
	local buff_spacing, debuff_spacing, aura_spacing_row, opposite, consolx, consoly
	
	if db.General.Anchor == "TOPLEFT" then
		buff_spacing = db.General.Spacing + db.Buffs.Size
		debuff_spacing = db.General.Spacing + db.Debuffs.Size
		
		aura_spacing_row = - db.General.Spacing_row
		opposite = "BOTTOMRIGHT"
		consolx = 6
		consoly = -6
	elseif db.General.Anchor == "TOPRIGHT" then
		buff_spacing = - (db.General.Spacing + db.Buffs.Size)
		debuff_spacing = - (db.General.Spacing + db.Debuffs.Size)
		
		aura_spacing_row = - db.General.Spacing_row
		opposite = "BOTTOMLEFT"
		consolx = -6
		consoly = -6
	elseif db.General.Anchor == "BOTTOMLEFT" then
		buff_spacing = db.General.Spacing + db.Buffs.Size
		debuff_spacing = db.General.Spacing + db.Debuffs.Size
		
		aura_spacing_row = db.General.Spacing_row
		opposite = "TOPRIGHT"
		consolx = 6
		consoly = 6
	else
		buff_spacing = - (db.General.Spacing + db.Buffs.Size)
		debuff_spacing = - (db.General.Spacing + db.Debuffs.Size)
		
		aura_spacing_row = db.General.Spacing_row
		opposite = "TOPLEFT"
		consolx = -6
		consoly = 6
	end
	
	LUIBuffs:ClearAllPoints()
	LUIBuffs:SetPoint(db.General.Anchor, UIParent, db.General.Anchor, db.Buffs.X, db.Buffs.Y)
	LUIBuffs:SetAttribute("point", db.General.Anchor)
	LUIBuffs:SetAttribute("xOffset", buff_spacing)
	LUIBuffs:SetAttribute("wrapYOffset", aura_spacing_row)
	LUIBuffs:SetAttribute("maxWraps", db.General.Row_max)
	LUIBuffs:SetAttribute("wrapAfter", db.General.Num_row)
	LUIBuffs:SetAttribute("sortMethod", db.General.Sort)
	LUIBuffs:SetAttribute("sortDirection", db.General.SortReverse and "-" or "+")
	LUIBuffs:SetAttribute("consolidateTo", db.General.Consolidate and 1 or 0)
	
	LUIDebuffs:ClearAllPoints()
	LUIDebuffs:SetPoint(db.General.Anchor, UIParent, db.General.Anchor, db.Debuffs.X, db.Debuffs.Y)
	LUIDebuffs:SetAttribute("point", db.General.Anchor)
	LUIDebuffs:SetAttribute("xOffset", debuff_spacing)
	LUIDebuffs:SetAttribute("wrapYOffset", aura_spacing_row)
	LUIDebuffs:SetAttribute("wrapAfter", db.General.Num_row)
	LUIDebuffs:SetAttribute("sortMethod", db.General.Sort)
	LUIDebuffs:SetAttribute("sortDirection", db.General.SortReverse and "-" or "+")
	
	LUIBuffsProxyButton.count:SetFont(Media:Fetch("font", db.Buffs.Count.Font), db.Buffs.Count.Size, db.Buffs.Count.Outline)
	LUIBuffsProxyButton.count:SetTextColor(db.Buffs.Count.Color.r, db.Buffs.Count.Color.g, db.Buffs.Count.Color.b ,1)
	
	local num = db.General.Num_row * db.General.Row_max
	for i = 1, num do
		local button = _G["LUIBuffsAuraButton"..i]
		if button then
			if button.duration then
				button.duration:SetFont(Media:Fetch("font", db.Buffs.Duration.Font), db.Buffs.Duration.Size, db.Buffs.Duration.Outline)
				button.duration:SetTextColor(db.Buffs.Duration.Color.r, db.Buffs.Duration.Color.g, db.Buffs.Duration.Color.b ,1)
			end
			if button.count then
				button.count:SetFont(Media:Fetch("font", db.Buffs.Count.Font), db.Buffs.Count.Size, db.Buffs.Count.Outline)
				button.count:SetTextColor(db.Buffs.Count.Color.r, db.Buffs.Count.Color.g, db.Buffs.Count.Color.b ,1)
			end
		end
	end
	
	for i = 1, 24 do
		local button = _G["LUIBuffsConsolidateButton"..i]
		if button then
			if button.duration then
				button.duration:SetFont(Media:Fetch("font", db.Buffs.Duration.Font), db.Buffs.Duration.Size, db.Buffs.Duration.Outline)
				button.duration:SetTextColor(db.Buffs.Duration.Color.r, db.Buffs.Duration.Color.g, db.Buffs.Duration.Color.b ,1)
			end
			if button.count then
				button.count:SetFont(Media:Fetch("font", db.Buffs.Count.Font), db.Buffs.Count.Size, db.Buffs.Count.Outline)
				button.count:SetTextColor(db.Buffs.Count.Color.r, db.Buffs.Count.Color.g, db.Buffs.Count.Color.b ,1)
			end
		end
	end
	
	for i = 1, db.General.Num_row do
		local button = _G["LUIDebuffsAuraButton"..i]
		if button then
			if button.duration then
				button.duration:SetFont(Media:Fetch("font", db.Debuffs.Duration.Font), db.Debuffs.Duration.Size, db.Debuffs.Duration.Outline)
				button.duration:SetTextColor(db.Debuffs.Duration.Color.r, db.Debuffs.Duration.Color.g, db.Debuffs.Duration.Color.b ,1)
			end
			if button.count then
				button.count:SetFont(Media:Fetch("font", db.Debuffs.Count.Font), db.Debuffs.Count.Size, db.Debuffs.Count.Outline)
				button.count:SetTextColor(db.Debuffs.Count.Color.r, db.Debuffs.Count.Color.g, db.Debuffs.Count.Color.b ,1)
			end
		end
	end
	
	LUIBuffs:Hide()
	LUIBuffs:Show()
	AuraAnchorsOnEnable(LUIBuffs)
	LUIDebuffs:Hide()
	LUIDebuffs:Show()
	AuraAnchorsOnEnable(LUIDebuffs)
end

function module:LoadOptions()
	local dryCall = function() self:Refresh() end
	local UIRL = function() StaticPopup_Show("RELOAD_UI") end
	
	local function CreateTextOptions(tag, kind, order)
		local options = self:NewGroup(kind, order, true, {
			Size = self:NewSlider("Size", "Choose your "..tag.." "..kind.." Fontsize.", 1, 1, 40, 1, true),
			Font = self:NewSelect("Font", "Choose your "..tag.." "..kind.." Font.", 2, widgetLists.font, "LSM30_Font", true),
			Outline = self:NewSelect("Font Flag", "Choose your "..tag.." "..kind.." Font Flag.", 3, fontflags, nil, dryCall),
			Color = self:NewColorNoAlpha(tag, tag.." "..kind, 4, dryCall),
		})
		
		return options
	end
	
	local function CreateSpecificOptions(tag, order)
		local options = self:NewGroup(tag, order, {
			header = self:NewHeader(tag.." Options", 1),
			Size = self:NewSlider("Size", "Choose the Size for your "..tag..".", 2, 15, 35, 1, UIRL),
			[""] = self:NewPosition(tag, 3, nil, dryCall),
			Duration = CreateTextOptions(tag, "Duration", 5),
			Count = CreateTextOptions(tag, "Count", 6),
		})
		
		return options
	end
	
	local options = {
		General = self:NewGroup("General", 1, {
			header = self:NewHeader("General Options", 1),
			Row_max = self:NewInputNumber("Max Rows", "Maximal Amount of Rows for Buffs.", 2, dryCall, nil, nil, nil, "%.0f"),
			Num_row = self:NewInputNumber("Amount per Row", "Choose an Amount of Buffs/Debuffs per Row.", 3, dryCall, nil, nil, nil, "%.0f"),
			Spacing = self:NewInputNumber("Spacing", "Spacing between your Buffs/Debuffs.", 4, dryCall),
			Spacing_row = self:NewInputNumber("Spacing between Rows", "Spacing between your Buff Rows.", 5, dryCall),
			Anchor = self:NewSelect("Initial Anchor", "Choose the initial Anchor for your Auras.", 6, positions, nil, dryCall),
			Sort = self:NewSelect("Sorting Order", "Choose the Sorting order for your Buffs/Debuffs.", 7, sortorders, nil, dryCall),
			SortReverse = self:NewToggle("Reverse Sorting", "Choose whether you want to reverse the Sorting or not.", 8, true),
			Consolidate = self:NewToggle("Consolidate Buffs", "Choose whether you want to consolidate your Buffs or not.", 9, true),
		}),
		Buffs = CreateSpecificOptions("Buffs", 2),
		Debuffs = CreateSpecificOptions("Debuffs", 3),
	}
	
	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	
	if LUICONFIG.Versions.auras ~= LUI.Versions.auras then
		db:ResetProfile()
		LUICONFIG.Versions.auras = LUI.Versions.auras
	end
end

function module:OnEnable()
	self:SetBuffs()
	self:DisableBlizzardBuffs()
end

function module:OnDisable()
	if LUIBuffs then LUIBuffs:Hide() end
	if LUIDebuffs then LUIDebuffs:Hide() end
	self:EnableBlizzardBuffs()
end
