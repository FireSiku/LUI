---
--  Name ...... : Auras
--  Description : Player Buffs, Debuffs, and Weapon Enchants
--

local addonName, LUI = ...

-- Localized API
local GameTooltip = _G.GameTooltip
local RAID_CLASS_COLORS, NUM_TEMP_ENCHANT_FRAMES = RAID_CLASS_COLORS, NUM_TEMP_ENCHANT_FRAMES
local UnitName, UnitClass, UnitAura, UnitIsPlayer, GameTooltip_UnitColor = UnitName, UnitClass, UnitAura, UnitIsPlayer, GameTooltip_UnitColor
local GetInventoryItemTexture, GetInventoryItemQuality, GetItemQualityColor, GetWeaponEnchantInfo = GetInventoryItemTexture, GetInventoryItemQuality, GetItemQualityColor, GetWeaponEnchantInfo
local GetTime, ceil, select, unpack, pairs, strfind, strmatch, gsub, format, tonumber = GetTime, math.ceil, select, unpack, pairs, string.find, string.match, string.gsub, string.format, tonumber

----------------------------------------------------------------------
-- Initialize
----------------------------------------------------------------------

local module = LUI:Module("Auras")
local Media = LUI.Lib("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local L = LUI.L
local argcheck = LUI.argcheck

local profile, group

----------------------------------------------------------------------
-- Local Variables
----------------------------------------------------------------------

local day, hour, minute = 86400, 3600, 60 -- number of seconds in each

local playerCaster = "|cff%02x%02x%02x%s|r"
local petCaster = "%s <|cff%02x%02x%02x%s|r>"

local initConfig = [=[
	local size = %d
	self:SetWidth(size)
	self:SetHeight(size)
]=]

local headers = {}
local Header, Aura, WeaponEnchant, Proxy = {}, {}, {}, {}

local sortOrders = {
	Index = L["Index"],
	Name = L["Name"],
	Time = L["Time"],
}

local debuffTypeColors = setmetatable({
	none = {0.8, 0, 0}, -- Red (CC0000)
	Magic = {0.2, 0.6, 1}, -- Blue (3399FF)
	Curse = {0.6, 0, 1}, -- Purple (9900FF)
	Disease = {0.6, 0.4, 0}, -- Brown (996600)
	Poison = {0, 0.6, 0}, -- Green (009900)
}, {
	__index = function(t, k)
		return t.none
	end,
})

local timeFormats
do
	timeFormats = {
		[day] = DAY_ONELETTER_ABBR,
		[hour] = HOUR_ONELETTER_ABBR,
		[minute] = MINUTE_ONELETTER_ABBR,
		[1] = "%d",
	}

	for k, v in pairs(timeFormats) do
		timeFormats[k] = gsub(v, "%s", "") -- strip out the spaces
	end
end

----------------------------------------------------------------------
-- Local Functions
----------------------------------------------------------------------

local function getNextUpdate(seconds)
	return seconds - (seconds % (seconds < minute and 1 or seconds < hour and minute or seconds < day and hour or day))
end

local function formatTime(seconds)
	local factor

	if seconds < minute then
		factor = 1
	elseif seconds < hour then
		factor = minute
	elseif seconds < day then
		factor = hour
	else
		factor = day
	end

	return timeFormats[factor], ceil(seconds / factor)
end

----------------------------------------------------------------------
-- Aura Functions
----------------------------------------------------------------------

do
	function Aura:OnUpdate(elapsed)
		-- this prevents the remaining time from being off since the first elapsed will be higher than the actual amount of time elapsed
		-- elapsed is always equal to the time since the last frame refresh (not the time since this was declared as the OnUpdate func)
		if self.nextUpdate then
			self.remaining = self.remaining - elapsed
			if self.remaining > self.nextUpdate then return end
		end

		self.nextUpdate = getNextUpdate(self.remaining)

		self.duration:SetFormattedText(formatTime(self.remaining))
	end

	function Aura:Update(...)
		local name, icon, count, dispelType, duration, expires, caster = UnitAura(...)
		-- Blizzard has a bug with SecureAuraHeaders that causes extra aura buttons to sometimes be shown
		-- It occurs when the consolidation or tempEnchants are shown, an extra button gets added to the end of the list for each one shown
		if not name then return end
		-- if (not duration or type(duration) ~= "number") or (not expires or type(expires) ~= "number") then
		-- 	LUI:Printf("Name: %s, iconID: %s, type: %s, duration: %s, expires: %s, caster: %s", name, icon, count, dispelType, duration, expires, caster)
		-- end

		if duration and duration > 0 then
			self.remaining = expires - GetTime()
			self.nextUpdate = nil -- force an update
			self:SetScript('OnUpdate', self.OnUpdate)
		else
			self:SetScript('OnUpdate', nil)
			self.duration:SetText()
		end

		self.icon:SetTexture(icon)
		if not self.helpful then
			local c = debuffTypeColors[dispelType]
			self.border:SetVertexColor(unpack(c))
		end

		if count and count > 1 then
			self.count:SetFormattedText("%d", count)
		else
			self.count:SetText()
		end

		self.caster = nil
		if caster then
			if UnitIsPlayer(caster) then
				local _, class = UnitClass(caster)
				if class then
					local c = RAID_CLASS_COLORS[class]
					self.caster = format(playerCaster, c.r*255, c.g*255, c.b*255, UnitName(caster))
				end
			elseif caster == "pet" or caster == "vehicle" then
				local _, class = UnitClass("player")
				local c = RAID_CLASS_COLORS[class]
				self.caster = format(petCaster, UnitName(caster), c.r*255, c.g*255, c.b*255, UnitName("player"))
			else
				local group = strmatch(caster, "([p]?[ar][ra][ti][yd])pet")

				if group and not strfind(caster, "target") then
					local owner = group .. strmatch(caster, ".-(%d%d?)$")
					local _, class = UnitClass(owner)
					local c = RAID_CLASS_COLORS[class]
					self.caster = format(petCaster, UnitName(caster), c.r*255, c.g*255, c.b*255, UnitName(owner))
				end
			end

			if not self.caster then
				-- most likely an NPC (color by friendliness)
				local r, g, b = GameTooltip_UnitColor(caster)
				self.caster = format(playerCaster, r*255, g*255, b*255, UnitName(caster))
			end
		end
	end

	function Aura:UpdateTooltip() -- Automatically called from GameTooltip_OnUpdate
		GameTooltip:SetUnitAura(self.header:GetAttribute('unit'), self:GetID(), self.header:GetAttribute('filter'))

		if self.caster then
			GameTooltip:AddLine(self.caster)
			GameTooltip:Show() -- force the tooltip to update its size to incorporate the caster
		end
	end

	function Aura:SetProperties(init)
		local settings = self.header.settings

		if not init then -- The size is handled by the initConfig func if we are creating this aura (we could be in CombatLockdown)
			self:SetWidth(settings.Size)
			self:SetHeight(settings.Size)
		end

		self.gloss:SetWidth(settings.Size * 1.12)
		self.gloss:SetHeight(settings.Size * 1.12)
		local texSize = settings.Size * 1.2
		self.normalTexture:SetWidth(texSize)
		self.normalTexture:SetHeight(texSize)
		if self.border then
			self.border:SetWidth(texSize)
			self.border:SetHeight(texSize)
		end


		self.count:SetFont(Media:Fetch("font", settings.Count.Font), settings.Count.Size, settings.Count.Flag)
		self.count:SetTextColor(unpack(settings.Count.Color))

		if self.duration then -- the Proxy doesn't have a duration
			self.duration:SetFont(Media:Fetch("font", settings.Duration.Font), settings.Duration.Size, settings.Duration.Flag)
			self.duration:SetTextColor(unpack(settings.Duration.Color))
		end

		self.TooltipAnchor = "Anchor_"..LUI.Opposites[settings.Anchor]
	end
end

----------------------------------------------------------------------
-- WeaponEnchant Functions
----------------------------------------------------------------------

do
	function WeaponEnchant:OnUpdate_Charges(elapsed)
		self.nextUpdate = self.nextUpdate - elapsed
		if self.nextUpdate > 0 then return end

		local remaining, charges = select((self.enchantNum * 3) - 1, GetWeaponEnchantInfo())
		remaining = remaining / 1000
		self.nextUpdate = remaining % 1 -- update about every second

		self.duration:SetFormattedText(formatTime(remaining))
		self.count:SetFormattedText("%d", charges)
	end

	function WeaponEnchant:Update(enchantNum, ...)
		self.icon:SetTexture(GetInventoryItemTexture(...))
		self.border:SetVertexColor(GetItemQualityColor(GetInventoryItemQuality(...) or 1))

		local remaining, charges = select((enchantNum * 3) - 1, GetWeaponEnchantInfo()) -- GetWeaponEnchantInfo() returns: hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges
		if charges and charges > 1 then
			self.enchantNum = enchantNum
			self.nextUpdate = 0 -- force an update
			self:SetScript('OnUpdate', self.OnUpdate_Charges)
		elseif remaining then
			self.remaining = remaining / 1000
			self.nextUpdate = nil -- force an update
			self:SetScript('OnUpdate', self.OnUpdate)
		else
			self:SetScript('OnUpdate', nil)
			self.duration:SetText()
		end
	end

	function WeaponEnchant:UpdateTooltip() -- Automatically called from GameTooltip_OnUpdate
		GameTooltip:SetInventoryItem("player", self:GetID())
	end

	WeaponEnchant.OnUpdate = Aura.OnUpdate
	WeaponEnchant.SetProperties = Aura.SetProperties
end

----------------------------------------------------------------------
-- Proxy Functions
----------------------------------------------------------------------

do
	function Proxy:Update(count)
		if count > 1 then
			self.count:SetFormattedText("%d", count)
		else
			self.count:SetText()
		end

		if self.Consolidate:IsShown() then
			self.Consolidate:Update()
		end
	end

	-- call as Consolidate:Update()
	function Proxy:UpdateConsolidated()
		local unit, filter = self:GetAttribute('unit'), self:GetAttribute('filter')

		for i, aura, id in self:ActiveAuras() do
			aura:Update(unit, id, filter)
		end
	end

	function Proxy:SetPosition(anchor)
		self.Consolidate:ClearAllPoints()
		
		local rPoint, x, y = strmatch(anchor, "^[TB][O][PT][T]?[O]?[M]?"), 10, 20
		rPoint = gsub(anchor, rPoint, LUI.Opposites[rPoint])

		if strfind(anchor, "TOP") then
			y = -y
		end
		if strfind(anchor, "RIGHT") then
			x = -x
		end

		self.Consolidate:SetPoint(anchor, self, rPoint, x, y)
	end

	Proxy.SetProperties = Aura.SetProperties
end

----------------------------------------------------------------------
-- Header Functions
----------------------------------------------------------------------

do
	local function auraIterator(self, i)
		i = i + 1
		local aura = self.auras[i]
		if aura and aura:IsShown() then return i, aura, aura:GetID() end
	end

	function Header:ActiveAuras()
		return auraIterator, self, 0
	end

	function Header:Update(event, ...)
		local unit = self:GetAttribute('unit')
		if (unit ~= ... and event ~= "PLAYER_ENTERING_WORLD") or not self:IsShown() then return end

		local filter = self:GetAttribute('filter')

		for i, aura, id in self:ActiveAuras() do
			aura:Update(unit, id, filter)
		end

		if self.helpful then
			self:UpdateWeaponEnchants("_mainEnchanted")

			-- fix for Blizzard's fail coding
			local i, numShown, numConsolidated = 1, 0, 0
			while true do
				local name, _, _, _, _, _, _, _, shouldConsolidate = UnitAura(unit, i, filter)
				if not name then break end
				if not shouldConsolidate or not self.settings.Consolidate then
					numShown = numShown + 1
				else
					numConsolidated = numConsolidated + 1
				end
				i = i + 1
			end
			for i, aura in self:ActiveAuras() do
				if i > numShown then
					aura.blocker:Show()
					aura:SetAlpha(0)
				else
					aura:SetAlpha(1)
					aura.blocker:Hide()
				end
			end

			if self.Proxy and self.Proxy:IsShown() then
				self.Proxy:Update(numConsolidated)
			end
		end
	end

	function Header:UpdateWeaponEnchants(attr)
		if not (attr == "_mainEnchanted" or attr == "_secondaryEnchanted") then return end -- Blizzard failed and forgot about ranged weapons

		local unit = self:GetAttribute('unit')

		for i = 1, NUM_TEMP_ENCHANT_FRAMES do
			local weaponEnchant = self.weaponEnchants[i]

			if weaponEnchant and weaponEnchant:IsShown() then
				weaponEnchant:Update(i, unit, weaponEnchant:GetID())
			end
		end
	end

	function Header:ChildCreated(child)
		child.header = self
		child.helpful = self.helpful

		local template

		if child:GetAttribute('proxy') then
			self.Proxy = child
			template = Proxy
		elseif child:GetAttribute('weaponEnchant') then
			self.weaponEnchants[tonumber(strmatch(child:GetName(), "%d$"))] = child
			template = WeaponEnchant
		else
			self.auras[#self.auras + 1] = child
			template = Aura
		end

		for k, v in pairs(template) do
			child[k] = v
		end

		child.normalTexture:SetDrawLayer("BORDER") -- technically this is the border (the child.border texture is for the colored borders around debuffs and weapon enchants)

		child:SetProperties(true)
	end


	function Header:SetAttr(...)
		self:SetAttribute(...)

		if self.Proxy then
			self.Proxy.Consolidate:SetAttribute(...)
		end
	end

	function Header:Configure()
		local settings = self.settings

		self:SetAttribute('_ignore', true)

		if settings.Consolidate and not self.Proxy then
			module:AddConsolidation(self)
		end

		local anchor = settings.Anchor
		local spacing, rowSpacing = settings.HorizontalSpacing + settings.Size, settings.VerticalSpacing + settings.Size
		if strfind(anchor, "RIGHT") then
			spacing = -spacing
		end
		if strfind(anchor, "TOP") then
			rowSpacing = -rowSpacing
		end

		self:ClearAllPoints()
		self:SetPoint(anchor, settings.X, settings.Y)

		self:SetAttr('minWidth', settings.Size)
		self:SetAttr('minHeight', settings.Size)
		self:SetAttr('point', anchor)
		self:SetAttr('xOffset', spacing)

		self:SetAttribute('wrapAfter', settings.AurasPerRow)
		self:SetAttribute('maxWraps', settings.NumRows)
		self:SetAttr('wrapYOffset', rowSpacing)

		self:SetAttribute('sortMethod', settings.SortMethod)
		self:SetAttribute('sortDirection', (settings.ReverseSort == (settings.SortMethod ~= "Time")) and "-" or "+") -- bit of trickery to make ReverseSort be opposite if SortMethod == "Time"

		if self.helpful then
			self:SetAttribute('consolidateTo', settings.Consolidate and 1 or 0)

			for i = 1, NUM_TEMP_ENCHANT_FRAMES do
				local weaponEnchant = self.weaponEnchants[i]

				if weaponEnchant then
					weaponEnchant:SetProperties()
				end
			end

			if self.Proxy then
				self.Proxy:SetProperties()
				self.Proxy:SetPosition(anchor)

				for i = 1, #self.Proxy.auras do
					self.Proxy.auras[i]:SetProperties()
				end
			end
		end

		for i = 1, #self.auras do
			self.auras[i]:SetProperties()
		end

		self:SetAttribute('_ignore', nil)

		self:SetAttr('initialConfigFunction', format(initConfig, settings.Size))
	end
end

----------------------------------------------------------------------
-- Auras Functions
----------------------------------------------------------------------

function module:NewAuraHeader(auraType, helpful)
	local header = headers[auraType]

	if not header then
		header = CreateFrame("Frame", "LUI_Auras_"..auraType, _G.UIParent, "SecureAuraHeaderTemplate")
		headers[auraType] = header

		header.helpful = helpful
		header.settings = profile[auraType]
		header.auras = {}

		for k, v in pairs(Header) do
			header[k] = v
		end

		header:SetClampedToScreen(true)
		header:SetSize(1, 1) -- the sizing can bug out if this isn't set to something

		header:SetAttribute('filter', helpful and "HELPFUL" or "HARMFUL")

		if helpful then
			header:SetAttribute('template', "LUI_Auras_BuffTemplate")

			header.weaponEnchants = {}

			header:SetAttribute('includeWeapons', 1)
			header:SetAttribute('weaponTemplate', "LUI_Auras_WeaponEnchantTemplate")

			header:HookScript('OnAttributeChanged', header.UpdateWeaponEnchants)
		else
			header:SetAttribute('template', "LUI_Auras_DebuffTemplate")

			header:SetScript('OnUpdate', nil) -- We aren't watching WeaponEnchants with this header
		end

		header:RegisterEvent('PLAYER_ENTERING_WORLD')
		header:HookScript('OnEvent', header.Update)

		RegisterAttributeDriver(header, 'unit', "[vehicleui] vehicle; player")
	end

	header:Configure()
	header:Show()
end

function module:AddConsolidation(header)
	local proxy = CreateFrame("Button", header:GetName().."Consolidation", header, "LUI_Auras_ConsolidateProxyTemplate")
	local consolidate = proxy.Consolidate

	proxy.auras = {}
	consolidate.auras = proxy.auras
	consolidate.helpful = header.helpful
	consolidate.settings = header.settings
	consolidate.ActiveAuras = header.ActiveAuras
	consolidate.ChildCreated = header.ChildCreated
	consolidate.Update = Proxy.UpdateConsolidated

	proxy:SetAttribute('header', consolidate)
	proxy:SetFrameRef('header', consolidate)

	header:SetAttribute('consolidateProxy', proxy)
	header:SetAttribute('consolidateHeader', consolidate)
	header:SetAttribute('consolidateDuration', -1)
	header:SetAttribute('consolidateThreshold', -1)
	header:SetAttribute('consolidateFraction', -1)

	consolidate:SetAttribute('filter', header:GetAttribute('filter'))
	RegisterAttributeDriver(consolidate, 'unit', "[vehicleui] vehicle; player")

	header:ChildCreated(proxy)
end

----------------------------------------------------------------------
-- Defaults
----------------------------------------------------------------------

module.defaults = {
	profile = {
		Buffs = {
			Anchor = "TOPLEFT",
			X = 30,
			Y = -35,
			Size = 35,
			AurasPerRow = 16,
			NumRows = 2,
			HorizontalSpacing = 12,
			VerticalSpacing = 22,
			SortMethod = "Time",
			ReverseSort = false,
			Consolidate = true,
			Count = {
				Font = "vibrocen",
				Size = 18,
				Flag = "OUTLINE",
				Color = {1, 1, 1},
			},
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Flag = "NONE",
				Color = {1, 1, 1},
			},
		},
		Debuffs = {
			Anchor = "TOPLEFT",
			X = 30,
			Y = -160,
			Size = 35,
			AurasPerRow = 16,
			NumRows = 1,
			HorizontalSpacing = 12,
			VerticalSpacing = 22,
			SortMethod = "Time",
			ReverseSort = false,
			Count = {
				Font = "vibrocen",
				Size = 18,
				Flag = "OUTLINE",
				Color = {1, 1, 1},
			},
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Flag = "NONE",
				Color = {1, 1, 1},
			},
		},
	},
}

----------------------------------------------------------------------
-- Options
----------------------------------------------------------------------

module.getter = "GetDBVar"
module.setter = function(info, value)
	module:SetDBVar(info, value)
	headers[info[2]]:Configure()
end

function module:LoadOptions()
	local function refresh(info)
		headers[info[2]]:Configure()
	end

	local function CreateTextOptions(auraType, kind, order)
		local options = self:NewGroup(kind, order, true, {
			Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
			Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
			Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 1, 40, 1, true),
			Color = self:NewColorNoAlpha(format("%s %s", auraType, kind), nil, 4, refresh),
		})

		return options
	end

	local function CreateAuraOptions(auraType, order)
		local options = self:NewGroup(auraType, order, false, InCombatLockdown, {
			header = self:NewHeader(format(L["%s Options"], auraType), 1),
			Size = self:NewSlider(L["Size"], format(L["Choose the Size for your %s"], auraType), 2, 15, 65, 1, true),
			Anchor = self:NewSelect(L["Anchor"], format(L["Choose the corner to anchor your %s to"], auraType), 3, LUI.Corners, false, refresh),
			X = self:NewInputNumber(L["Horizontal Position"], format(L["Adjust the horizontal position"], auraType), 4, refresh),
			Y = self:NewInputNumber(L["Vertical Position"], format(L["Adjust the vertical position"], auraType), 5, refresh),
			NumRows = self:NewSlider(L["Number of rows"], format(L["Choose the maximum number of rows for your %s"], auraType), 6, 1, 10, 1, true),
			AurasPerRow = self:NewSlider(L["Number per row"], format(L["Choose the maximum number of %s for each row"], auraType), 7, 1, 40, 1, true),
			HorizontalSpacing = self:NewInputNumber(L["Spacing"], format(L["Choose the amount of space between each of your %s"], auraType), 8, refresh),
			VerticalSpacing = self:NewInputNumber(L["Row Spacing"], format(L["Choose the amount of space between each row of your %s"], auraType), 9, refresh),
			Consolidate = auraType == L["Buffs"] and self:NewToggle(format(L["Consolidate %s"], auraType), format(L["Choose whether you want to consolidate your %s or not"], auraType), 10, true) or nil,
			SortMethod = self:NewSelect(L["Sorting Order"], format(L["Choose the sorting order for your %s"], auraType), 11, sortOrders, false, refresh),
			ReverseSort = self:NewToggle(L["Reverse Sorting"], L["Choose whether you want to reverse the sorting order or not"], 12, true, "normal"),
			Count = CreateTextOptions(auraType, L["Count"], 13),
			Duration = CreateTextOptions(auraType, L["Duration"], 14),
		})

		return options
	end

	local options = {
		Buffs = CreateAuraOptions(L["Buffs"], 1),
		Debuffs = CreateAuraOptions(L["Debuffs"], 2),
	}

	return options
end

function module:Refresh()
	for auraType, header in pairs(headers) do
		header:Configure()
		header:Update("PLAYER_ENTERING_WORLD")
	end
end

local function OnAnyEvent(self, event, addon)
	for i=1, BUFF_MAX_DISPLAY do
		local buff = _G["LUI_Auras_BuffsAuraButton"..i]
		if buff then
			group:AddButton(buff)
		end
		if not buff then break end
	end
	
	for i=1, BUFF_MAX_DISPLAY do
		local debuff = _G["LUI_Auras_DebuffsAuraButton"..i]
		if debuff then
			group:AddButton(debuff)
		end
		if not debuff then break end
	end
	
	for i=1, NUM_TEMP_ENCHANT_FRAMES do
		local f = _G["TempEnchant"..i]
		if TempEnchant then
			group:AddButton(f)
		end
		_G["TempEnchant"..i.."Border"]:SetVertexColor(.75, 0, 1)
	end
	group:ReSkin()
end

function module:SetupSkins()

	local f = CreateFrame("Frame")

	hooksecurefunc("CreateFrame", function (_, name, parent) --dont need to do this for TempEnchant enchant frames because they are hard created in xml
		if type(name) ~= "string" then return end
		if strfind(name, "LUI_Auras") then
			group:AddButton(_G[name])
			group:ReSkin() -- Needed to prevent issues with stack text appearing under the frame.
		end
	end
	)
		
	f:SetScript("OnEvent", OnAnyEvent)
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("UNIT_AURA")
end

----------------------------------------------------------------------
-- AceAddon Load Functions
----------------------------------------------------------------------

function module:DBCallback()
	profile = self.db.profile

	for auraType, header in pairs(headers) do
		header.settings = profile[auraType]

		if header.Proxy then
			header.Proxy.Consolidate.settings = profile[auraType]
		end
	end

	module:Refresh()
end

function module:OnInitialize()
	profile = LUI:Namespace(self, true, 2.0)
end

function module:OnEnable()
	LUI.Blizzard:Hide("aura")

	self:NewAuraHeader("Buffs", true)
	self:NewAuraHeader("Debuffs")
	if Masque then
		group = Masque:Group("LUI", "Buffs & Debuffs")
		self:SetupSkins()
	end
end

function module:OnDisable()
	for auraType, header in pairs(headers) do
		header:Hide()
	end

	LUI.Blizzard:Show("aura")
end
