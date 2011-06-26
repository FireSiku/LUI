--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: datatext.lua
	Description: Provides LUI datatexts which hold relative info.
	Version....: 1.8
	Rev Date...: 10/06/2011 [dd/mm/yyyy]

	Edits:
		v1.8: Hix
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local module = LUI:NewModule("Infotext", "AceHook-3.0")
local db

--[[
	All these variables need to be moved.
	Need to be placed into their respective stat modules, cause these local (globals) are just messy and will cause problems.
	In the circumstance that these variables need to be accessable from other location of of the stat (i.e. the options)
	then they should be given accessors; functions within the stat module to view and change the variable.
--]]
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local myPlayerRealm = GetRealmName()
local myPlayerFaction = UnitFactionGroup("player")
local myPlayerName = UnitName("player")
local playerReset = ""
local BUTTON_HEIGHT, ICON_SIZE, GAP, TEXT_OFFSET, MAX_ENTRIES = 15, 13, 10, 5
local _, L = ...
local fscale = 1
local block, horde, isGuild = true
local guildEntries, friendEntries, motd, slider, nbEntries = {}, {}
local sliderValue, hasSlider, UpdateTablet, extraHeight = 0
local info, buttons, toasts = {}
local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local totalFriends, onlineFriends, nbRealFriends, realFriendsHeight, nbBroadcast = 0, 0, 0
local WOW, SC2 = 1, 2
local preformatedStatusText, sortIndexes
local colpairs = { ["class"] = 1, ["name"] = 2, ["level"] = 3, ["zone"] = 4, ["note"] = 5, ["status"] = 6, ["rank"] = 7 }
local hordeZones = "Orgrimmar,Undercity,Thunder Bluff,Silvermoon City,Durotar,Tirisfal Glades,Mulgore,Eversong Woods,Northern Barrens,Silverpine Forest,Ghostlands,Azshara,"
local allianceZones = "Ironforge,Stormwind City,Darnassus,The Exodar,Azuremyst Isle,Bloodmyst Isle,Darkshore,Deeprun Tram,Dun Morogh,Elwynn Forest,Loch Modan,Teldrassil,Westfall,"
local new, del
local specCache = {}
local iconCache = {}
local GetNumTalentGroups, GetActiveTalentGroup = GetNumTalentGroups, GetActiveTalentGroup

do
	local tables = setmetatable( {}, { __mode = "k" } )

	new = function(...)
		local _t = next(tables)
		if _t then tables[_t] = nil else _t = {} end
		for i  = 1, select("#", ...) do _t[i] = select(i, ...) end
		return _t
	end

	del = function(_t)
		tables[wipe(_t)] = true
	end

end
for eng, loc in next, LOCALIZED_CLASS_NAMES_MALE   do L[loc] = eng end
for eng, loc in next, LOCALIZED_CLASS_NAMES_FEMALE do L[loc] = eng end

-- Module functions.
function module:GetInfoPanel(frame)
	if not frame then return end

	frame:SetParent(_G["LUI_Infos_"..frame.db.InfoPanel.Vertical..frame.db.InfoPanel.Horizontal])
end

function module:GetInfoPanelPosition(text, database)
	if (not text) or (not database) then return end

	text:ClearAllPoints()
	text:SetPoint(database.InfoPanel.Vertical, _G["LUI_Infos_"..database.InfoPanel.Vertical..database.InfoPanel.Horizontal], database.InfoPanel.Vertical, database.X, database.Y)
end

function module:HideDataText(stat, text, icon)
	if stat then
		-- Unregister events.
		stat:UnregisterAllEvents()

		-- Unregister scripts.
		stat:SetScript("OnEnter", nil)
		stat:SetScript("OnEvent", nil)
		stat:SetScript("OnLeave", nil)
		stat:SetScript("OnMouseDown", nil)
		stat:SetScript("OnUpdate", nil)

		-- Hide	
		stat:Hide()
	end

	if text then
		-- Hide
		text:Hide()
	end

	if icon then
		-- Hide
		icon:Hide()
	end
end

function module:SetDataTextFrames()
	-- Bottom Left.
	LUI_Infos_BottomLeft = LUI:CreateMeAFrame("Frame", "LUI_Infos_BottomLeft", UIParent, 1, 1, 1, "HIGH", 0, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 4, 1)
	LUI_Infos_BottomLeft:SetAlpha(1)
	LUI_Infos_BottomLeft:Show()

	-- Bottom Right.
	LUI_Infos_BottomRight = LUI:CreateMeAFrame("Frame", "LUI_Infos_BottomRight", UIParent, 1, 1, 1, "HIGH", 0, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 4, 1)
	LUI_Infos_BottomRight:SetAlpha(1)
	LUI_Infos_BottomRight:Show()

	-- Top Left.
	LUI_Infos_TopLeft = LUI:CreateMeAFrame("Frame", "LUI_Infos_TopLeft", UIParent, 1, 1, 1, "HIGH", 0, "TOPLEFT", UIParent, "TOPLEFT", 0, -1, 1)
	LUI_Infos_TopLeft:SetAlpha(1)
	LUI_Infos_TopLeft:Show()

	-- Top Right.
	LUI_Infos_TopRight = LUI:CreateMeAFrame("Frame", "LUI_Infos_TopRight", UIParent, 1, 1, 1, "HIGH", 0, "TOPRIGHT", UIParent, "TOPRIGHT", 0, -1, 1)
	LUI_Infos_TopRight:SetAlpha(1)
	LUI_Infos_TopRight:Show()
end


------------------------------------------------------
-- / BAGS / --
------------------------------------------------------

function module:SetBags()
	if not db.Infotext.Bags.Enable then self:HideDataText(self.Bags, LUI_Text_Bags) return end

	-- Add stat to modules namespace.
	self.Bags = CreateFrame("Frame", "LUI_Info_Bags")

	-- Create local shortcuts.
	local BAGS = self.Bags
	BAGS.db = db.Infotext.Bags

	-- Frame settings.
	BAGS:EnableMouse(true)
	self:GetInfoPanel(BAGS)
	BAGS:Show()

	-- Create info text.
	LUI_Text_Bags = BAGS:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Bags, BAGS.db)
	LUI_Text_Bags:SetFont(LSM:Fetch("font", BAGS.db.Font), BAGS.db.Size, BAGS.db.Outline)
	LUI_Text_Bags:SetHeight(BAGS.db.Size)
	LUI_Text_Bags:SetTextColor(BAGS.db.Color.r, BAGS.db.Color.g, BAGS.db.Color.b, BAGS.db.Color.a)
	LUI_Text_Bags:Show()
	BAGS:SetAllPoints(BAGS.Text)

	-- Localised functions.
	local GetContainerNumFreeSlots, GetContainerNumSlots = GetContainerNumFreeSlots, GetContainerNumSlots

	-- Script functions.
	function BAGS:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Bags:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Hint: Click to open Bags.", 0, 1, 0)
		GameTooltip:Show()
	end

	function BAGS:OnEvent()
		local free, total, used = 0, 0, 0

		for i = 0, NUM_BAG_SLOTS do
			free, total = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i)
		end

		used = total - free
		LUI_Text_Bags:SetText("Bags: "..used.."/"..total)

		-- Setup bags tooltip
		self:SetAllPoints(LUI_Text_Bags)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	BAGS:RegisterEvent("BAG_UPDATE")
	BAGS:RegisterEvent("PLAYER_LOGIN")
	BAGS:SetScript("OnEnter", BAGS.OnEnter)
	BAGS:SetScript("OnEvent", BAGS.OnEvent)
	BAGS:SetScript("OnLeave", function() GameTooltip:Hide() end)
	BAGS:SetScript("OnMouseDown", function() OpenAllBags() end)
	BAGS:OnEvent()
end

------------------------------------------------------
-- / Clock / --
------------------------------------------------------

function module:SetClock()
	if not db.Infotext.Clock.Enable then self:HideDataText(self.Clock, LUI_Text_Clock) return end

	-- Add stat to the modules namespace.
	self.Clock = CreateFrame("Frame", "LUI_Info_Clock")

	-- Create local shortcuts.
	local CLOCK = self.Clock
	CLOCK.db = db.Infotext.Clock

	-- Frame settings.
	CLOCK:EnableMouse(true)
	self:GetInfoPanel(CLOCK)
	CLOCK:Show()

	-- Create info texts.
	LUI_Text_Clock = CLOCK:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Clock, CLOCK.db)
	LUI_Text_Clock:SetFont(LSM:Fetch("font", CLOCK.db.Font), CLOCK.db.Size, CLOCK.db.Outline)
	LUI_Text_Clock:SetHeight(CLOCK.db.Size)
	LUI_Text_Clock:SetTextColor(CLOCK.db.Color.r, CLOCK.db.Color.g, CLOCK.db.Color.b, CLOCK.db.Color.a)
	LUI_Text_Clock:Show()
	CLOCK:SetAllPoints(LUI_Text_Clock)

	-- Localised functions.
	local tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo = tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo

	-- Variables.
	local instanceInfo, guildParty = nil, ""

	-- Script functions.
	function CLOCK:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Time:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		local pvp = GetNumWorldPVPAreas()
		for i = 1, pvp do
			local _, name, inprogress, _, timeleft = GetWorldPVPAreaInfo(i)
			local inInstance, instanceType = IsInInstance()
			if not (instanceType == "none") then
				timeleft = QUEUE_TIME_UNAVAILABLE
			elseif inprogress then
				timeleft = WINTERGRASP_IN_PROGRESS
			else
				local hour = tonumber(format("%01.f", floor(timeleft / 3600)))
				local min = format((hour > 0) and "%02.f" or "%01.f", floor(timeleft / 60 - (hour * 60)))
				local sec = format("%02.f", floor(timeleft - (hour * 3600) - (min * 60)))
				timeleft = (hour > 0 and hour..":" or "")..min..":"..sec
			end

			GameTooltip:AddDoubleLine("Time to "..name, timeleft)
		end

		GameTooltip:AddLine(" ")
		if self.db.LocalTime == true then
			local Hr, Min = GetGameTime()
			if Min < 10 then Min = "0"..Min end

			if self.db.Time24 == true then
				if Hr < 10 then Hr = "0"..Hr end
				GameTooltip:AddDoubleLine("Server Time: ", Hr..":"..Min)
			else
				if Hr >= 12 then
					GameTooltip:AddDoubleLine("Server Time: ", (Hr - 12)..":"..Min.." PM")
				else
					if Hr == 0 then Hr = 12 end
					GameTooltip:AddDoubleLine("Server Time: ", Hr..":".. Min.." AM")
				end
			end
		else
			local Hr24 = tonumber(date("%H"))
			local Hr = tonumber(date("%I"))
			local Min = date("%M")
			if self.db.Time24 == true then
				if Hr24 < 10 then Hr24 = "0"..Hr24 end
				GameTooltip:AddDoubleLine("Local Time: ", Hr24..":".. Min)
			else
				if Hr24 >= 12 then
					GameTooltip:AddDoubleLine("Local Time: ", Hr..":"..Min.." PM")
				else
					GameTooltip:AddDoubleLine("Local Time: ", Hr..":"..Min.." AM")
				end
			end
		end

		local oneraid
		for i = 1, GetNumSavedInstances() do
		local name,_, reset, difficulty, locked, extended,_, isRaid, maxPlayers = GetSavedInstanceInfo(i)

		if isRaid and (locked or extended) then
			local tr, tg, tb, diff

			if not oneraid then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Saved Raid(s)")
				oneraid = true
			end

			local function fmttime(sec, table)
				local table = table or {}
				local d, h, m, s = ChatFrame_TimeBreakDown(floor(sec))
				local string = gsub(gsub(format(" %dd %dh %dm "..((d==0 and h==0) and "%ds" or ""), d, h, m, s), " 0[dhms]", " "), "%s+", " ")
				local string = strtrim(gsub(string, "([dhms])", {d = table.days or "d", h = table.hours or "h", m = table.minutes or "m", s = table.seconds or "s"}), " ")
				return strmatch(string, "^%s*$") and "0"..(table.seconds or L"s") or string
			end

			if extended then
				tr, tg, tb = 0.3, 1, 0.3
			else
				tr, tg, tb = 1, 1, 1
			end

			if difficulty == 3 or difficulty == 4 then diff = "H" else diff = "N" end
				GameTooltip:AddDoubleLine(format("%s |cffaaaaaa(%s%s)", name, maxPlayers, diff), fmttime(reset), 1, 1, 1, tr, tg, tb)
			end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint:\n- Left-Click for Calendar Frame.\n- Right-Click for Time Manager Frame.", 0, 1, 0)
		GameTooltip:Show()
	end

	CLOCK.dt = 0
	function CLOCK:OnUpdate(deltaTime)
		self.dt = self.dt + deltaTime
		if self.dt > 1 then
			self.dt = 0

			if (GameTimeFrame.pendingCalendarInvites > 0) then
				LUI_Text_Clock:SetText("(Inv. pending)")
				self:SetAllPoints(LUI_Text_Clock)
			else
				if self.db.LocalTime == true then
					local Hr24 = tonumber(date("%H"))
					local Hr = tonumber(date("%I"))
					local Min = date("%M")

					if self.db.Time24 == true then
						if Hr24 < 10 then Hr24 = "0"..Hr24 end
						LUI_Text_Clock:SetText(Hr24..":"..Min)
					else
						if Hr24 >= 12 then
							LUI_Text_Clock:SetText(Hr..":"..Min.." pm")
						else
							LUI_Text_Clock:SetText(Hr..":"..Min.." am")
						end
					end
				else
					local Hr, Min = GetGameTime()
					if Min < 10 then Min = "0"..Min end

					if self.db.Time24 == true then
						if Hr < 10 then Hr = "0"..Hr end
						LUI_Text_Clock:SetText(Hr..":"..Min)
					else
						if Hr >= 12 then
							LUI_Text_Clock:SetText((Hr - 12)..":"..Min.." pm")
						else
							if Hr == 0 then Hr = 12 end
							LUI_Text_Clock:SetText(Hr..":"..Min.." am")
						end
					end
				end

				-- Instance Info
				if self.db.ShowInstanceDifficulty then
					if instanceInfo then LUI_Text_Clock:SetText(LUI_Text_Clock:GetText().." ("..instanceInfo..guildParty.."|r)") end
				end
			end

			-- Setup clock tooltip.
			self:SetAllPoints(LUI_Text_Clock)

			-- Update tooltip if open.
			if self:IsMouseOver() and GameTooltip:GetOwner() == self then
				self:OnEnter()
			end
		end
	end

	-- Accessors.
	function CLOCK:ShowInstanceDifficulty()
		if self.db.ShowInstanceDifficulty then
			self:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
			self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
			self:RegisterEvent("PLAYER_ENTERING_WORLD")

			self:GUILD_PARTY_STATE_UPDATED()
			self:PLAYER_ENTERING_WORLD()

			self.PLAYER_DIFFICULTY_CHANGED = self.PLAYER_ENTERING_WORLD
			instanceInfo, guildParty = nil, ""
		else
			self:RegisterEvent("PLAYER_ENTERING_WORLD")
			self:UnregisterEvent("GUILD_PARTY_STATE_UPDATED")
			self:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED")

			instanceInfo, guildParty = nil, ""
		end
	end

	-- More Localised funcitons
	local GetNumWorldPVPAreas, GetWorldPVPAreaInfo, GetNumSavedInstances, GetSavedInstanceInfo = GetNumWorldPVPAreas, GetWorldPVPAreaInfo, GetNumSavedInstances, GetSavedInstanceInfo
	local gsub, format, floor, strtrim, strmatch = gsub, format, floor, strtrim, strmatch

	-- Event functions
	function CLOCK:GUILD_PARTY_STATE_UPDATED()
		if InGuildParty() then
			guildParty = " |cff66c7ffG"
		else
			guildParty = ""
		end
	end

	function CLOCK:PLAYER_ENTERING_WORLD()
		local inInstance, instanceType = IsInInstance()
		if inInstance then
			local _,_, instanceDifficulty,_, maxPlayers, dynamicMode, isDynamic = GetInstanceInfo()
			if (instanceType == "raid") then
				if (instanceDifficulty == 3 or instanceDifficulty == 4) or (isDynamic and dynamicMode == 1) then
					instanceInfo = maxPlayers.." |cffff0000H"
				else
					instanceInfo = maxPlayers.." |cff00ff00N"
				end
			elseif (instanceType == "party") then
				if (instanceDifficulty == 1) then
					instanceInfo = maxPlayers.." |cff00ff00N"
				else
					instanceInfo = maxPlayers.." |cffff0000H"
				end
			else
				instanceInfo = nil
			end
		else
			instanceInfo = nil
		end
	end

	CLOCK:SetScript("OnEnter", CLOCK.OnEnter)
	CLOCK:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	CLOCK:SetScript("OnLeave", function() GameTooltip:Hide() end)
	CLOCK:SetScript("OnMouseDown", function(self, button) if button == "RightButton" then TimeManager_Toggle() else GameTimeFrame:Click() end end)
	CLOCK:SetScript("OnUpdate", CLOCK.OnUpdate)
	CLOCK:ShowInstanceDifficulty()
	CLOCK:OnUpdate(10)
end

------------------------------------------------------
-- / CURRENCY / --
------------------------------------------------------

function module:SetCurrency()
	if not db.Infotext.Currency.Enable then self:HideDataText(self.Currency, LUI_Text_Currency, LUI_Text_CurrencyIcon) return end

	-- Add stat to modules namespace.
	self.Currency = CreateFrame("Frame", "LUI_Info_Currency")

	-- Create local shortcuts.
	local CUR = self.Currency
	CUR.db = db.Infotext.Currency

	-- Frame settings.
	CUR:EnableMouse(true)
	self:GetInfoPanel(CUR)
	CUR:Show()

	-- Create info text.
	LUI_Text_Currency = CUR:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Currency, CUR.db)
	LUI_Text_Currency:SetFont(LSM:Fetch("font", CUR.db.Font), CUR.db.Size, CUR.db.Outline)
	LUI_Text_Currency:SetHeight(CUR.db.Size)
	LUI_Text_Currency:SetTextColor(CUR.db.Color.r, CUR.db.Color.g, CUR.db.Color.b, CUR.db.Color.a)
	LUI_Text_Currency:Show()
	CUR:SetAllPoints(LUI_Text_Currency)

	-- Create info text icon.
	LUI_Text_CurrencyIcon = CreateFrame("Button", "LUI_Text_CurrencyIcon", CUR)
	LUI_Text_CurrencyIcon:SetPoint("RIGHT", LUI_Text_Currency, "LEFT", -2, 0)
	LUI_Text_CurrencyIcon:SetWidth(15)
	LUI_Text_CurrencyIcon:SetHeight(15)
	LUI_Text_CurrencyIcon:SetFrameStrata("TOOLTIP")
	LUI_Text_CurrencyIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }})
	LUI_Text_CurrencyIcon:Show()

	-- Script functions.
	function CUR:OnEnter()
		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Currency:", 0.4, 0.78, 1)

		for i = 1, GetCurrencyListSize() do
			local name, isHeader,_,_,_, count, icon = GetCurrencyListInfo(i)
			if isHeader ~= true then
				if name ~= nil then
					if count ~= 0 and count ~= nil then
						GameTooltip:AddDoubleLine(name, count, 255, 255, 255, 255, 255, 255)
					else
						GameTooltip:AddDoubleLine(name, "--", 255, 255, 255, 255, 255, 255)
					end
				end
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(name)
			end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint:\n- Any Click to open Currency frame.", 0, 1, 0)
		GameTooltip:Show()
	end

	function CUR:OnEvent(event)
		if event == "PLAYER_ENTERING_WORLD" then
			if UnitFactionGroup("player") == "Horde" then
				LUI_Text_CurrencyIcon:SetBackdrop({bgFile = "Interface\\PVPFrame\\PVP-Currency-Horde", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }})
			else
				LUI_Text_CurrencyIcon:SetBackdrop({bgFile = "Interface\\PVPFrame\\PVP-Currency-Alliance", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }})
			end

			LUI_Text_Currency:SetText("Currency")
		end

		-- Setup currency tooltip.
		self:SetAllPoints(LUI_Text_Currency)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	CUR:RegisterEvent("PLAYER_ENTERING_WORLD")
	CUR:SetScript("OnEnter", CUR.OnEnter)
	CUR:SetScript("OnEvent", CUR.OnEvent)
	CUR:SetScript("OnLeave", function() GameTooltip:Hide() end)
	CUR:SetScript("OnMouseDown", function(self, button)
		ToggleCharacter("TokenFrame")
	end)
	CUR:OnEvent("PLAYER_ENTERING_WORLD")
end

------------------------------------------------------
-- / DPS / --
------------------------------------------------------

function module:SetDPS()
	if not db.Infotext.Dps.Enable then self:HideDataText(self.DPS, LUI_Text_DPS) return end

	-- Add stat to the modules namespace.
	self.DPS = CreateFrame("Frame", "LUI_Info_DPS")

	-- Create local shortcuts.
	local DPS = self.DPS
	DPS.db = db.Infotext.Dps

	-- Frame settings.
	DPS:EnableMouse(true)
	self:GetInfoPanel(DPS)
	DPS:Show()

	local active = DPS.db.Active
	if active ~= "dps" and active ~= "hps" and active ~= "dtps" and active ~= "htps" then DPS.db.Active = "dps" active = "dps" end

	-- Create info text.
	LUI_Text_DPS = DPS:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_DPS, DPS.db)
	LUI_Text_DPS:SetFont(LSM:Fetch("font", DPS.db.Font), DPS.db.Size, DPS.db.Outline)
	LUI_Text_DPS:SetHeight(DPS.db.Size)
	LUI_Text_DPS:SetTextColor(DPS.db.Color.r, DPS.db.Color.g, DPS.db.Color.b, DPS.db.Color.a)
	LUI_Text_DPS:Show()
	DPS:SetAllPoints(LUI_Text_DPS)

	if active == "dps" then LUI_Text_DPS:SetText("DPS: ")
	elseif active == "hps" then LUI_Text_DPS:SetText("HPS: ")
	elseif active == "dtps" then LUI_Text_DPS:SetText("DTPS: ")
	elseif active == "htps" then LUI_Text_DPS:SetText("HTPS: ") end

	-- Localised functions.
	local UnitGUID, GetTime = UnitGUID, GetTime

	-- Variables.
	local playerId, petId, combatStartTime, combatTimeElapsed = nil, nil, 0, combatTimeElapsed or 1
	local totalDamage, playerDamage, petDamage, totalHealing, effectiveHealing, overHealing, totalDamageTaken, totalHealingTaken, effectiveHealingTaken, overHealingTaken = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	local textFormat = {
		dps = "DPS: %.1f",
		hps = "HPS: %.1f",
		dtps = "DTPS: %.1f",
		htps = "HTPS: %.1f",
	}
	local events = {
		dps = {
			SWING_DAMAGE = true,
			RANGE_DAMAGE = true,
			SPELL_DAMAGE = true,
			SPELL_PERIODIC_DAMAGE = true,
			DAMAGE_SHIELD = true,
			DAMAGE_SPLIT = true,
		},
		hps = {
			SPELL_PERIODIC_HEAL = true,
			SPELL_HEAL = true,
			SPELL_AURA_APPLIED = true,
			SPELL_AURA_REFRESH = true,
		},
		dtps = {
			SWING_DAMAGE = true,
			RANGE_DAMAGE = true,
			SPELL_DAMAGE = true,
			SPELL_PERIODIC_DAMAGE = true,
			DAMAGE_SHIELD = true,
			DAMAGE_SPLIT = true,
		},
		htps = {
			SPELL_PERIODIC_HEAL = true,
			SPELL_HEAL = true,
			SPELL_AURA_APPLIED = true,
			SPELL_AURA_REFRESH = true,
		},
	}
	local shields = {
		[select(1, GetSpellInfo(17))] = true, -- Power Word: Shield
		[select(1, GetSpellInfo(47515))] = true, -- Divine Aegis
		[select(1, GetSpellInfo(76669))] = true, -- Illuminated Healing
	}

	-- Script functions.
	function DPS:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		local name = UnitName("player")
		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Combat Info", 1, 1, 1)

		GameTooltip:AddLine("DPS:", 0.4, 0.78, 1)
		GameTooltip:AddDoubleLine(name..":", format("%.1f", playerDamage / combatTimeElapsed))
		if petDamage and (petDamage > 0) then
			GameTooltip:AddDoubleLine("Pet:", format("%.1f", petDamage / combatTimeElapsed))
		end

		GameTooltip:AddLine("HPS:", 0.4, 0.78, 1)
		GameTooltip:AddDoubleLine("Effective:", format("%.1f", effectiveHealing / combatTimeElapsed))
		GameTooltip:AddDoubleLine("Overhealing:", format("%.1f", overHealing / combatTimeElapsed))

		GameTooltip:AddLine("DTPS:", 0.4, 0.78, 1)
		GameTooltip:AddDoubleLine(name..":", format("%.1f", totalDamageTaken / combatTimeElapsed))

		GameTooltip:AddLine("HTPS:", 0.4, 0.78, 1)
		GameTooltip:AddDoubleLine("Effective:", format("%.1f", effectiveHealingTaken / combatTimeElapsed))
		GameTooltip:AddDoubleLine("Overhealing:", format("%.1f", overHealingTaken / combatTimeElapsed))
		
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint: Click to change meter type.", 0, 1, 0)
		GameTooltip:Show()
	end

	DPS.dt = 0
	function DPS:OnUpdate(deltaTime)
		DPS.dt = DPS.dt + deltaTime
		if DPS.dt > 1 then
			DPS.dt = 0

			-- SetText
			combatTimeElapsed = GetTime() - combatStartTime
			local total = 0
			if active == "dps" then
				total = totalDamage / combatTimeElapsed
			elseif active == "hps" then
				total = totalHealing / combatTimeElapsed
			elseif active == "dtps" then
				total = totalDamageTaken / combatTimeElapsed
			elseif active == "htps" then
				total = totalHealingTaken / combatTimeElapsed
			end

			LUI_Text_DPS:SetFormattedText(textFormat[active], total)

			-- Setup dps tooltip.
			self:SetAllPoints(LUI_Text_DPS)

			-- Update tooltip if open.
			if self:IsMouseOver() and GameTooltip:GetOwner() == self then
				self:OnEnter()
			end
		end
	end

	-- Event fucntions.
	function DPS:COMBAT_LOG_EVENT_UNFILTERED(_, eventType,_, Id,_,_, TargetId,_,_, spellID, spellName,_, amount, amount2)
		local record = false
		for mode in pairs(events) do
			if events[mode][eventType] then
				record = true
			end
		end
		if record == false then return end
		if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") then
			if not shields[spellName] then
				return
			else
				amount = amount2
			end
		end

		if Id == playerId or Id == petId then
			if eventType == "SWING_DAMAGE" then
				amount = spellID
			end

			if events["dps"][eventType] then
				totalDamage = totalDamage + amount
				if Id == playerId then playerDamage = playerDamage + amount end
				if Id == petId then petDamage = petDamage + amount end
			end

			if events["hps"][eventType] then
				totalHealing = totalHealing + amount
				effectiveHealing = effectiveHealing + (amount - amount2)
				overHealing = overHealing + amount2
			end

		end
		if TargetId == playerId then
			if eventType == "SWING_DAMAGE" then
				amount = spellID
			end

			if events["dtps"][eventType] then
				totalDamageTaken = totalDamageTaken + amount
			end

			if events["htps"][eventType] then
				totalHealingTaken = totalHealingTaken + amount
				effectiveHealingTaken = effectiveHealingTaken + (amount - amount2)
				overHealingTaken = overHealingTaken + amount2
			end

		end
	end

	function DPS:PLAYER_ENTERING_WORLD()
		playerId = UnitGUID("player")
		petId = UnitGUID("pet")
	end

	function DPS:PLAYER_REGEN_DISABLED()
		combatStartTime = GetTime()
		combatTimeElapsed = 0
		totalDamage, playerDamage, petDamage = 0, 0, 0
		totalHealing, effectiveHealing, overHealing = 0, 0, 0
		totalDamageTaken = 0
		totalHealingTaken, effectiveHealingTaken, overHealingTaken = 0, 0, 0
		elapsedTime = 0.5

		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:SetScript("OnUpdate", self.OnUpdate)
	end

	function DPS:PLAYER_REGEN_ENABLED()
		self:OnUpdate(10)

		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:SetScript("OnUpdate", nil)
	end

	function DPS:UNIT_PET(unit)
		if unit == "player" then
			petId = UnitGUID("pet")
		end
	end

	DPS:RegisterEvent("PLAYER_ENTERING_WORLD")
	DPS:RegisterEvent("PLAYER_REGEN_DISABLED")
	DPS:RegisterEvent("PLAYER_REGEN_ENABLED")
	DPS:RegisterEvent("UNIT_PET")
	DPS:SetScript("OnEnter", DPS.OnEnter)
	DPS:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	DPS:SetScript("OnLeave", function() GameTooltip:Hide() end)
	DPS:SetScript("OnMouseDown", function(self, button)
		local total = 0

		if active == "dps" then
			active = "hps"
			total = totalHealing / combatTimeElapsed
		elseif active == "hps" then
			active = "dtps"
			total = totalDamageTaken / combatTimeElapsed
		elseif active == "dtps" then
			active = "htps"
			total = totalHealingTaken / combatTimeElapsed
		else
			active = "dps"
			total = totalDamage / combatTimeElapsed
		end

		self.db.Active = active

		LUI_Text_DPS:SetFormattedText(textFormat[active], total)
		self:SetAllPoints(LUI_Text_DPS)
	end)
	DPS:PLAYER_ENTERING_WORLD()
	DPS:OnUpdate(10)
end

------------------------------------------------------
-- / DUALSPEC / --
------------------------------------------------------

function module:SetDualSpec()
	if not db.Infotext.DualSpec.Enable then self:HideDataText(self.DualSpec, LUI_Text_DualSpec, LUI_Text_DualSpecIcon) return end
	if UnitLevel("player") < 10 then return end

	-- Add stat to modules namespace.
	self.DualSpec = CreateFrame("Frame", "LUI_Info_DualSpec")

	-- Create local shortcuts.
	local DS = self.DualSpec
	DS.db = db.Infotext.DualSpec

	-- Frame settings.
	DS:EnableMouse(true)
	self:GetInfoPanel(DS)
	DS:Show()

	-- Create info text.
	LUI_Text_DualSpec = DS:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_DualSpec, DS.db)
	LUI_Text_DualSpec:SetFont(LSM:Fetch("font", DS.db.Font), DS.db.Size, DS.db.Outline)
	LUI_Text_DualSpec:SetHeight(DS.db.Size)
	LUI_Text_DualSpec:SetTextColor(DS.db.Color.r, DS.db.Color.g, DS.db.Color.b, DS.db.Color.a)
	LUI_Text_DualSpec:Show()
	DS:SetAllPoints(LUI_Text_DualSpec)

	-- Create info text icon.
	LUI_Text_DualSpecIcon = CreateFrame("Button", "LUI_Text_DualSpecIcon", DS)
	LUI_Text_DualSpecIcon:SetPoint("RIGHT", LUI_Text_DualSpec, "LEFT", -2, 0)
	LUI_Text_DualSpecIcon:SetWidth(15)
	LUI_Text_DualSpecIcon:SetHeight(15)
	LUI_Text_DualSpecIcon:SetFrameStrata("TOOLTIP")
	LUI_Text_DualSpecIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }})
	LUI_Text_DualSpecIcon:Show()
	
	-- Script functions.
	function DS:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Dual Spec:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		for i = 1, GetNumTalentGroups() do
			specCache[i] = specCache[i] or {}
			local thisCache = specCache[i]
			TalentFrame_UpdateSpecInfoCache(thisCache, false, false, i)

			if thisCache.primaryTabIndex and thisCache.primaryTabIndex ~= 0 then
				thisCache.specName = thisCache[thisCache.primaryTabIndex].name
				thisCache.mainTabIcon = thisCache[thisCache.primaryTabIndex].icon
			else
				thisCache.specName = "|cffff0000Talents undefined!|r"
				thisCache.mainTabIcon = "Interface\\Icons\\Spell_Nature_MoonKey"
			end
		end

		local activeGroupNum = GetActiveTalentGroup()
		local curCache = specCache[activeGroupNum]
		local a = curCache[1].pointsSpent or 0
		local b = curCache[2].pointsSpent or 0
		local c = curCache[3].pointsSpent or 0

		if self.db.ShowSpentPoints then
			if a <= 0 and b <= 0 and c <= 0 then
	       		LUI_Text_DualSpec:SetText(" |cffff0000Talents undefined!|r")
				LUI_Text_DualSpecIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			else
		   		LUI_Text_DualSpec:SetText(" "..curCache.specName.." ("..a.."/"..b.."/"..c..")")
				LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			end
		else
			LUI_Text_DualSpec:SetText(" "..curCache.specName)
			LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
		end

		if a <= 0 and b <= 0 and c <= 0 then
			GameTooltip:AddLine(" |cffff0000Talents undefined!|r")
	   		LUI_Text_DualSpecIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
		else
			if activeGroupNum == 1 then
				GameTooltip:AddDoubleLine("Primary Spec:", curCache.specName.." ("..a.."/"..b.."/"..c..")", 255, 255, 255, 255, 255, 255)
			else
				GameTooltip:AddDoubleLine("Secondary Spec:", curCache.specName.." ("..a.."/"..b.."/"..c..")", 255, 255, 255, 255, 255, 255)
			end
			LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
		end

		if GetNumTalentGroups() >= 2 then
			local nextGroup = -activeGroupNum + 3
			local nextCache = specCache[nextGroup]

			local a3 = nextCache[1].pointsSpent or 0
			local b3 = nextCache[2].pointsSpent or 0
			local c3 = nextCache[3].pointsSpent or 0

			if a3 <= 0 and b3 <= 0 and c3 <= 0 then
				GameTooltip:AddLine(" |cffff0000Talents undefined!|r")
				LUI_Text_DualSpecIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			else
				if activeGroupNum == 2 then
					GameTooltip:AddDoubleLine("Primary Spec:", nextCache.specName.." ("..a3.."/"..b3.."/"..c3..")", 255, 255, 255, 255, 255, 255)
				else
					GameTooltip:AddDoubleLine("Secondary Spec:", nextCache.specName.." ("..a3.."/"..b3.."/"..c3..")", 255, 255, 255, 255, 255, 255)
				end
				LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			end
		else
			GameTooltip:AddLine(" |cffff0000Talents undefined!|r")
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint:\n- Left-Click to switch talent.\n- Right-Click to open Talent Frame.\n- Any Click on the Icon to open Glyph.", 0, 1, 0)
		GameTooltip:Show()
	end

	function DS:OnEvent()
		if UnitLevel("player") < 10 then return end

		for i = 1, GetNumTalentGroups() do
			specCache[i] = specCache[i] or {}
			local thisCache = specCache[i]
			TalentFrame_UpdateSpecInfoCache(thisCache, false, false, i)

			if thisCache.primaryTabIndex and thisCache.primaryTabIndex ~= 0 then
				thisCache.specName = thisCache[thisCache.primaryTabIndex].name
				thisCache.mainTabIcon = thisCache[thisCache.primaryTabIndex].icon
			else
				thisCache.specName = "|cffff0000Talents undefined!|r"
				thisCache.mainTabIcon = "Interface\\Icons\\Spell_Nature_MoonKey"
			end
		end

		local activeGroupNum = GetActiveTalentGroup()
		local curCache = specCache[activeGroupNum]
		local a = curCache[1].pointsSpent or 0
		local b = curCache[2].pointsSpent or 0
		local c = curCache[3].pointsSpent or 0

		if self.db.ShowSpentPoints then
			if a <= 0 and b <= 0 and c <= 0 then
	       		LUI_Text_DualSpec:SetText(" |cffff0000Talents undefined!|r")
	       		LUI_Text_DualSpecIcon:SetBackdrop({bgFile = "Interface\\Icons\\Spell_Nature_MoonKey", edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			else
		   		LUI_Text_DualSpec:SetText(" "..curCache.specName.." ("..a.."/"..b.."/"..c..")")
				LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
			end
		else
			LUI_Text_DualSpec:SetText(" "..curCache.specName)
			LUI_Text_DualSpecIcon:SetBackdrop({bgFile = tostring(curCache.mainTabIcon), edgeFile = nil, tile = false, edgeSize = 0, insets = { top = 0, right = 0, bottom = 0, left = 0 }});
		end
		
		-- Setup dual spec tooltip.
		self:SetAllPoints(LUI_Text_DualSpec)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	DS:RegisterEvent("PLAYER_TALENT_UPDATE")
	DS:SetScript("OnEnter", DS.OnEnter)
	DS:SetScript("OnEvent", DS.OnEvent)
	DS:SetScript("OnLeave", function() GameTooltip:Hide() end)
	DS:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			if PlayerTalentFrame:IsVisible() and (PanelTemplates_GetSelectedTab(PlayerTalentFrame) == 1) then
				PlayerTalentFrame:Hide();
			else
				PanelTemplates_SetTab(PlayerTalentFrame, 1);
				PlayerTalentFrame_Refresh();
				PlayerTalentFrame:Show()
			end
		else
			if GetNumTalentGroups() < 2 then return	end

			local curSpec = GetActiveTalentGroup()
			local newSpec = -curSpec + 3

			SetActiveTalentGroup(newSpec)
		end
	end)
	DS:OnEvent()
end

------------------------------------------------------
-- / DURABILITY / --
------------------------------------------------------

function module:SetDurability()
	if not db.Infotext.Armor.Enable then self:HideDataText(self.Durability, LUI_Text_Durability) return end

	-- Add stat to modules namespace.
	self.Durability = CreateFrame("Frame", "LUI_Info_Durability")

	-- Create local shortcuts.
	local DUR = self.Durability
	DUR.db = db.Infotext.Armor

	-- Frame settings.
	DUR:EnableMouse(true)
	self:GetInfoPanel(DUR)
	DUR:Show()

	-- Create info text.
	LUI_Text_Durability = DUR:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Durability, DUR.db)
	LUI_Text_Durability:SetFont(LSM:Fetch("font", DUR.db.Font), DUR.db.Size, DUR.db.Outline)
	LUI_Text_Durability:SetHeight(DUR.db.Size)
	LUI_Text_Durability:SetTextColor(DUR.db.Color.r, DUR.db.Color.g, DUR.db.Color.b, DUR.db.Color.a)
	LUI_Text_Durability:Show()
	DUR:SetAllPoints(LUI_Text_Durability)

	-- Localised functions.
	local sort = table.sort

	-- Variables.
	local Slots = {
		[1] = {1, "Head", 1000},
		[2] = {3, "Shoulder", 1000},
		[3] = {5, "Chest", 1000},
		[4] = {6, "Waist", 1000},
		[5] = {9, "Wrist", 1000},
		[6] = {10, "Hands", 1000},
		[7] = {7, "Legs", 1000},
		[8] = {8, "Feet", 1000},
		[9] = {16, "Main Hand", 1000},
		[10] = {17, "Off Hand", 1000},
		[11] = {18, "Ranged", 1000}
	}
	local Total, Current, Max = 0, 0, 0

	-- Script functions.
	function DUR:OnEnter()
		if db.Infotext.ComabtLock then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Armor:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		for i = 1, 11 do
			if Slots[i][3] ~= 1000 then
				green = Slots[i][3] * 2
				red = 1 - green
				GameTooltip:AddDoubleLine(Slots[i][2], floor(Slots[i][3] * 100).."%", 1, 1, 1, red + 1, green, 0)
			end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint: Click to open Character Frame.", 0, 1, 0)
		GameTooltip:Show()
	end
		
	function DUR:OnEvent()
		Total = 0

		for i = 1, 11 do
			if GetInventoryItemLink("player", Slots[i][1]) ~= nil then
				Current, Max = GetInventoryItemDurability(Slots[i][1])
				if Current then
					Slots[i][3] = Current / Max
					Total = Total + 1
				end
			end
		end

		sort(Slots, function(a, b) return a[3] < b[3] end)

		if Total > 0 then
			LUI_Text_Durability:SetText("Armor: "..floor(Slots[1][3] * 100).."%")
		else
			LUI_Text_Durability:SetText("Armor: 100%")
		end

		-- Setup durability tooltip.
		self:SetAllPoints(LUI_Text_Durability)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	DUR:RegisterEvent("PLAYER_ENTERING_WORLD")
	DUR:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	DUR:SetScript("OnEnter", DUR.OnEnter)
	DUR:SetScript("OnEvent", DUR.OnEvent)
	DUR:SetScript("OnLeave", function() GameTooltip:Hide() end)
	DUR:SetScript("OnMouseDown", function() ToggleCharacter("PaperDollFrame") end)
	DUR:OnEvent()
end

------------------------------------------------------
-- / FPS & MS / --
------------------------------------------------------

function module:SetFPS()
	if not db.Infotext.Fps.Enable then self:HideDataText(self.FPS, LUI_Text_FPS) return end

	-- Add new stat to modules namespace.
	self.FPS = CreateFrame("Frame", "LUI_Info_FPS")

	-- Create local shortcuts.
	local FPS = self.FPS
	FPS.db = db.Infotext.Fps

	-- Frame settings.
	FPS:EnableMouse(true)
	self:GetInfoPanel(FPS)
	FPS:Show()

	-- Create info text.
	LUI_Text_FPS = FPS:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_FPS, FPS.db)
	LUI_Text_FPS:SetFont(LSM:Fetch("font", FPS.db.Font), FPS.db.Size, FPS.db.Outline)
	LUI_Text_FPS:SetHeight(FPS.db.Size)
	LUI_Text_FPS:SetTextColor(FPS.db.Color.r, FPS.db.Color.g, FPS.db.Color.b, FPS.db.Color.a)
	LUI_Text_FPS:Show()
	FPS:SetAllPoints(LUI_Text_FPS)

	-- Localised functions.
	local floor, GetFramerate, select, GetNetStats = floor, GetFramerate, select, GetNetStats

	-- Stat functions.
	function FPS.ColourFPS(fps)
		local t = fps / 60
		local r = 1 - t
		local g = t

		return r, g, 0
	end
	
	function FPS.ColourMS(ms)
		local t = ms / 400
		local r = t
		local g = 1 - t

		return r, g, 0
	end

	-- Script functions.
	function FPS:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("FPS & MS:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		-- Fps stats.
		local fps = floor(GetFramerate())
		GameTooltip:AddLine("FPS:")
		GameTooltip:AddDoubleLine("Current:", fps, 1, 1, 1, self.ColourFPS(fps))
		GameTooltip:AddLine(" ")


		local bandIn, bandOut, home, world = GetNetStats()
		GameTooltip:AddLine("Latency:")
		GameTooltip:AddDoubleLine("Home:", home, 1, 1, 1, self.ColourMS(home))
		GameTooltip:AddDoubleLine("World:", world, 1, 1, 1, self.ColourMS(world))
		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Bandwidth:")
		GameTooltip:AddDoubleLine("Current Down:", format("%.2f KB/s", bandIn), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("Current Up:", format("%.2f KB/s", bandOut), 1, 1, 1, 1, 1, 1)

		GameTooltip:Show()
	end

	FPS.dt = 0
	function FPS:OnUpdate(deltaTime)
		self.dt = self.dt + deltaTime
		if self.dt > 1 then
			self.dt = 0

			-- Set text.
			if self.db.MSValue == "Both" then
				local _,_, home, world = GetNetStats()
				LUI_Text_FPS:SetFormattedText("%dfps    %dms | %dms", floor(GetFramerate()), home, world)
			else
				LUI_Text_FPS:SetFormattedText("%dfps    %dms", floor(GetFramerate()), select((self.db.MSValue == "Home" and 3) or 4, GetNetStats()))
			end

			-- Setup fps tooltip.
			self:SetAllPoints(LUI_Text_FPS)

			-- Update tooltip if open.
			if self:IsMouseOver() and GameTooltip:GetOwner() == self then
				self:OnEnter()
			end
		end
	end

	FPS:SetScript("OnEnter", FPS.OnEnter)
	FPS:SetScript("OnLeave", function() GameTooltip:Hide() end)
	FPS:SetScript("OnUpdate", FPS.OnUpdate)
	FPS:OnUpdate(10)
end

------------------------------------------------------
-- / GOLD / --
------------------------------------------------------

function module:SetGold()
	if not db.Infotext.Gold.Enable then self:HideDataText(self.Gold, LUI_Text_Gold) return end

	-- Add stat to modules namespace.
	self.Gold = CreateFrame("Frame", "LUI_Info_Gold")

	-- Create local shortcuts.
	local GOLD = self.Gold
	GOLD.db = db.Infotext.Gold

	-- Frame settings.
	GOLD:EnableMouse(true)
	self:GetInfoPanel(GOLD)
	GOLD:Show()

	-- Create info text.
	LUI_Text_Gold = GOLD:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Gold, GOLD.db)
	LUI_Text_Gold:SetFont(LSM:Fetch("font", GOLD.db.Font), GOLD.db.Size, GOLD.db.Outline)
	LUI_Text_Gold:SetHeight(GOLD.db.Size)
	LUI_Text_Gold:SetTextColor(GOLD.db.Color.r, GOLD.db.Color.g, GOLD.db.Color.b, GOLD.db.Color.a)
	LUI_Text_Gold:Show()
	GOLD:SetAllPoints(LUI_Text_Gold)
	
	-- Localised functions
	local format, floor, abs, mod = format, floor, math.abs, mod

	-- Variables.
	local Profit, OldMoney, ServerGold, Spent = 0, 0, 0, 0
	local colours	= {
		["Alliance"] = {
			r = 0,
			g = 0.6,
			b = 1,
		},
		["Horde"] = {
			r = 0.8,
			g = 0,
			b = 0,
		},
	}

	-- Stat functions.
	function GOLD.FormatMoney(money)
		money = abs(money)
		local gold, silver, copper = floor(money / 10000), mod(floor(money / 100), 100), mod(floor(money), 100)

		if gold ~= 0 then
			if GOLD.db.ColorType then
				return format("%s|cffffd700g|r %s|cffc7c7cfs|r", gold, silver)
			else
				return format("%sg %ss", gold, silver)
			end
		elseif silver ~= 0 then
			if GOLD.db.ColorType then
				return format("%s|cffc7c7cfs|r %s|cffeda55fc|r", silver, copper)
			else
				return format("%ss %sc", silver, copper)
			end
		else
			if GOLD.db.ColorType then
				return format("%s|cffeda55f c|r", copper)
			else
				return format("%sc", copper)
			end
		end
	end

	function GOLD.FormatTooltipMoney(money)
		money = abs(money)
		local gold, silver, copper = floor(money / 10000), mod(floor(money / 100), 100), mod(floor(money), 100)
		local cash = format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", gold, silver, copper)
		return cash
	end

	-- Script functions.
	function GOLD:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end

		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Money:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Session:")
		GameTooltip:AddDoubleLine("Earned:", self.FormatMoney(Profit), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("Spent:", self.FormatMoney(Spent), 1, 1, 1, 1, 1, 1)

		local dif = Profit - Spent
		if Profit < Spent then
			GameTooltip:AddDoubleLine("Deficit:", self.FormatMoney(dif), 1, 0, 0, 1, 1, 1)
		elseif (dif) > 0 then
			GameTooltip:AddDoubleLine("Profit:", self.FormatMoney(dif), 0, 1, 0, 1, 1, 1)
		end

		local totalGold = 0
		local totalPlayerFaction = 0
		local totalOtherFaction = 0
		local otherFaction = ((myPlayerFaction == "Alliance") and "Horde") or "Alliance"

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Character:")
		for k, v in pairs(LUIGold.gold[myPlayerRealm][myPlayerFaction]) do
			GameTooltip:AddDoubleLine(k, self.FormatTooltipMoney(v), colours[myPlayerFaction].r, colours[myPlayerFaction].g, colours[myPlayerFaction].b, 1, 1, 1)
			totalGold = totalGold + v
			totalPlayerFaction = totalPlayerFaction + v
		end
		for k, v in pairs(LUIGold.gold[myPlayerRealm][otherFaction]) do
			GameTooltip:AddDoubleLine(k, self.FormatTooltipMoney(v), colours[otherFaction].r, colours[otherFaction].g, colours[otherFaction].b, 1, 1, 1)
			totalGold = totalGold + v
			totalOtherFaction = totalOtherFaction + v
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Server:")
		if totalOtherFaction > 0 then
			GameTooltip:AddDoubleLine(myPlayerFaction..":", self.FormatTooltipMoney(totalPlayerFaction), colours[myPlayerFaction].r, colours[myPlayerFaction].g, colours[myPlayerFaction].b, 1, 1, 1)
			GameTooltip:AddDoubleLine(otherFaction..":", self.FormatTooltipMoney(totalOtherFaction), colours[otherFaction].r, colours[otherFaction].g, colours[otherFaction].b, 1, 1, 1)
		end

		GameTooltip:AddDoubleLine("Total:", self.FormatTooltipMoney(totalGold), 1, 1, 1, 1, 1, 1)

		for i = 1, MAX_WATCHED_TOKENS do
			local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)
			if name and i == 1 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Currency:")
			end
			local r, g, b = 1 ,1, 1
			if itemID then r, g, b = GetItemQualityColor(select(3, GetItemInfo(itemID))) end
			if name and count then GameTooltip:AddDoubleLine(name, count, r, g, b, 1, 1, 1) end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint:\n- Left-Click to toggle server/toon gold.\n- Right-Click to reset Session.", 0, 1, 0)
		GameTooltip:Show()
	end

	function GOLD:OnEvent(event)
		if event == "PLAYER_ENTERING_WORLD" then
			OldMoney = GetMoney()

			if (LUIGold == nil) then LUIGold = {} end
			if (LUIGold.gold == nil) then LUIGold.gold = {} end
			if (LUIGold.gold[myPlayerRealm] == nil) then LUIGold.gold[myPlayerRealm] = {} end
			if (LUIGold.gold[myPlayerRealm]["Alliance"] == nil) then LUIGold.gold[myPlayerRealm]["Alliance"] = {} end
			if (LUIGold.gold[myPlayerRealm]["Horde"] == nil) then LUIGold.gold[myPlayerRealm]["Horde"] = {} end
			LUIGold.gold[myPlayerRealm][myPlayerFaction][myPlayerName] = GetMoney()

			-- Gather total server gold.
			ServerGold = 0
			for k, v in pairs(LUIGold.gold[myPlayerRealm]["Alliance"]) do
				ServerGold = ServerGold + v
			end
			for k, v in pairs(LUIGold.gold[myPlayerRealm]["Horde"]) do
				ServerGold = ServerGold + v
			end

			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end

		local NewMoney = GetMoney()
		local Change = NewMoney - OldMoney	-- Positive if we gain money
		ServerGold = ServerGold + Change	-- Add change to the server total.

		if OldMoney > NewMoney then			-- Lost Money
			Spent = Spent - Change
		else								-- Gained Moeny
			Profit = Profit + Change
		end

		if self.db.ShowToonMoney then
			LUI_Text_Gold:SetText(self.FormatMoney(NewMoney))
		else
			LUI_Text_Gold:SetText(self.FormatMoney(ServerGold))
		end

		-- Setup money tooltip.
		self:SetAllPoints(LUI_Text_Gold)

		-- Update gold database.
		LUIGold.gold[myPlayerRealm][myPlayerFaction][myPlayerName] = GetMoney()

		-- Update gold count.
		OldMoney = NewMoney

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	-- Accessors
	function GOLD:ResetGold(player, faction)
		if not player then return end

		if player == "ALL" then
			LUIGold = {}
		elseif faction ~= nil then
			LUIGold.gold[myPlayerRealm][faction][player] = nil
		end

		-- Update server total.
		self.GatherServerTotal()

		-- Update info text display.
		self:OnEvent()
	end

	GOLD:RegisterEvent("PLAYER_ENTERING_WORLD")
	GOLD:RegisterEvent("PLAYER_MONEY")
	GOLD:SetScript("OnEnter", GOLD.OnEnter)
	GOLD:SetScript("OnEvent", GOLD.OnEvent)
	GOLD:SetScript("OnLeave", function() GameTooltip:Hide() end)
	GOLD:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			Profit = 0
			Spent = 0
			OldMoney = GetMoney()
		else
			self.db.ShowToonMoney = not self.db.ShowToonMoney
			self:OnEvent()
		end
	end)
	GOLD:OnEvent("PLAYER_ENTERING_WORLD")
end

------------------------------------------------------
-- / GUILD and FRIENDS / --
------------------------------------------------------

function module:SetGuild_Friends()
	if db.Infotext.Guild_Friends.Guild.Enable == false and db.Infotext.Guild_Friends.Friends.Enable == false then return end

	local f = CreateFrame("Frame", "LUI_Info_Guild/Friends", LUI_Infos_TopRight)
	f:SetScale(fscale)
	local t = CreateFrame("Frame", "LUI_Info_updater", LUI_Infos_TopRight)
	local highlight = f:CreateTexture()
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(0)

	local function ShowHints(btn)
		if db.Infotext.Guild_Friends.ShowHints and btn and btn.unit then
			local showBelow = UIParent:GetHeight()/fscale-f:GetTop() < f:GetBottom()
			GameTooltip:SetOwner(f, (showBelow and "ANCHOR_BOTTOM" or "ANCHOR_TOP"))
			GameTooltip:AddLine"Hints:"
			GameTooltip:AddLine("|cffff8020Click|r to whisper.", .2,1,.2)
			if (not btn.presenceID or btn.sameRealm) then GameTooltip:AddLine("|cffff8020Alt+Click|r to invite.", .2,1,.2) end
			if not btn.presenceID then GameTooltip:AddLine("|cffff8020Shift+Click|r to query informations.", .2, 1, .2) end
			if (not isGuild or CanEditPublicNote()) then GameTooltip:AddLine("|cffff8020Ctrl+Click|r to edit note.", .2, 1, .2) end
			if isGuild then
				if CanEditOfficerNote() then GameTooltip:AddLine("|cffff8020Ctrl+RightClick|r to edit officer note.", .2, 1, .2) end
			else
				GameTooltip:AddLine("|cffff8020MiddleClick|r to remove friend.", .2, 1, .2)
			end
			if not btn.presenceID then
				GameTooltip:AddLine("|cffff8020RightClick|r to sort by column.", .2, 1, .2)
			end
			if GameTooltip:NumLines() > 1 then GameTooltip:Show() end
		end
	end

	local function UpdateBlockHints()
		if f.onBlock then
			if db.Infotext.Guild_Friends.ShowHints then
				GameTooltip:SetOwner(f, "ANCHOR_LEFT", 0, -77)
				GameTooltip:SetClampedToScreen(true)
				GameTooltip:AddLine("Hints:")
				GameTooltip:AddLine("|cffff8020Click|r to open "..(isGuild and "Guild Roster." or "Friends List."), 0.2, 1, 0.2)
				GameTooltip:AddLine("|cffff8020RightClick|r to "..(isGuild and "display Guild Information." or "add a Friend."), 0.2, 1, 0.2)
				GameTooltip:AddLine("|cffff8020Button4|r to toggle notes.", 0.2, 1, 0.2)
				GameTooltip:AddLine("|cffff8020Button5|r to toggle hints.", 0.2, 1, 0.2)
				GameTooltip:Show()
			else
				GameTooltip:Hide()
			end
		end
	end

	local function Menu_OnEnter(b)
		if b and b.index then
			highlight:SetAllPoints(b)
			if b.index > 0 then
				highlight:SetAlpha(1)
				ShowHints(b)
			end
		end
	end

	local function Menu_OnLeave(b)
		highlight:ClearAllPoints()
		GameTooltip:Hide()
		if b and b.index and b.index > 0 then highlight:SetAlpha(0) end
		if not f:IsMouseOver() then f:Hide() end
	end

	local function Block_OnLeave(self)
		f.onBlock = nil
		GameTooltip:Hide()
		if not f:IsMouseOver() then
			f:Hide()
		end
	end

	local function UpdateGuildText()
		if IsInGuild() then
			f.Guild.text:SetText((db.Infotext.Guild_Friends.ShowTotal and "Guild: %d/%d" or "Guild: %d"):format(#guildEntries, GetNumGuildMembers(true)))
		else
			f.Guild.text:SetText("No Guild")
		end
	end

	local function UpdateFriendText(updatePanel)
		local totalRF, onlineRF = BNGetNumFriends()
		f.Friends.text:SetText((db.Infotext.Guild_Friends.ShowTotal and "Friends: %d/%d" or "Friends: %d"):format( onlineFriends + onlineRF, totalFriends + totalRF ))
		if updatePanel then f:BN_FRIEND_INFO_CHANGED() end
	end

	local friendOnline, friendOffline = ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h",""), ERR_FRIEND_OFFLINE_S:gsub("%%s","")
	function f:CHAT_MSG_SYSTEM( msg )
		if msg:find(friendOnline) or msg:find(friendOffline) then ShowFriends() end
	end

	function f:FRIENDLIST_UPDATE()
		for k,v in next,friendEntries do del(v) friendEntries[k]=nil end
		totalFriends, onlineFriends = GetNumFriends()
		for i = 1, onlineFriends do
			local name, level, class, zone, connected, status, note = GetFriendInfo(i)
			friendEntries[i] = new( L[class] or "", name or "", level or 0, zone or UNKNOWN, note or "|cffffcc00-", status or "", "", "", i )
		end
		UpdateFriendText()
		if not isGuild and f:IsShown() then UpdateTablet() end
	end

	function f:GUILD_ROSTER_UPDATE()
		for k, v in next, guildEntries do del(v) guildEntries[k]=nil end
		local r,g,b = unpack(db.Infotext.Guild_Friends.Color.OfficerNote)
		local officerColor = ("\124cff%.2x%.2x%.2x"):format( r*255, g*255, b*255 )
		for i=1, GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, zone, note, offnote, connected, status = GetGuildRosterInfo(i)
			if connected then
				local notes = note ~= "" and (offnote == "" and note or ("%s |cffffcc00-|r %s%s"):format(note, officerColor, offnote)) or
					offnote == "" and "|cffffcc00-" or officerColor..offnote
				guildEntries[#guildEntries+1] = new( L[class] or "", name or "", level or 0, zone or UNKNOWN, notes, status or "", rankIndex or 0, rank or 0, i )
			end
		end
		UpdateGuildText()
		if isGuild and f:IsShown() then UpdateTablet() end
	end

	function f:PLAYER_GUILD_UPDATE(unit)
		if unit and unit ~= "player" then return end
		if IsInGuild() then GuildRoster() end
	end

	local function GetZoneColor(zone)
		return unpack( db.Infotext.Guild_Friends.Color[
			hordeZones:find(zone..",") and (horde and "FriendlyZone" or "EnemyZone") or
			allianceZones:find(zone..",") and (horde and "EnemyZone" or "FriendlyZone") or
			"ContestedZone"
		] )
	end

	local function MOTD_OnClose(edit)
		edit:ClearAllPoints()
		edit:SetParent(edit.prevParent)
		edit:SetPoint(unpack(edit.prevPoint))
	end

	local function EditMOTD()
		f:Hide()
		if not GuildTextEditFrame then LoadAddOn"Blizzard_GuildUI" end
		local edit = GuildTextEditFrame
		edit.prevPoint = { edit:GetPoint() }
		edit.prevParent = edit:GetParent()
		edit:ClearAllPoints()
		edit:SetParent(UIParent)
		edit:SetPoint("CENTER", 0, 180)
		GuildTextEditFrame_Show"motd"
		edit:HookScript("OnHide", MOTD_OnClose)
	end

	local function EditBroadcast()
		f:Hide()
		StaticPopup_Show("SET_BN_BROADCAST")
	end

	local function OnGuildmateClick( self, button )
		if not( self and self.unit ) then return end
		if (isGuild or not self.presenceID) and button == "RightButton" and not IsControlKeyDown() then
			local btn, ofx = buttons[1], GAP*.25
			local pos = GetCursorPosition() / self:GetEffectiveScale()
			for v, i in next, colpairs do
				local b = btn[v]
				if b:IsShown() and pos >= b:GetLeft() - ofx and pos <= b:GetRight() + ofx then
					local sortCols, sortASC = db.Infotext.Guild_Friends.sortCols[isGuild], db.Infotext.Guild_Friends.sortASC[isGuild]
					if sortCols[1] == v then
						sortASC[1] = not sortASC[1]
					else
						sortCols[3] = sortCols[2]
						sortASC[3] = sortASC[2]
						sortCols[2] = sortCols[1]
						sortASC[2] = sortASC[1]
						sortCols[1] = v
						sortASC[1] = v ~= "level"
						sortIndexes[isGuild][3] = sortIndexes[isGuild][2]
						sortIndexes[isGuild][2] = sortIndexes[isGuild][1]
					end
					sortIndexes[isGuild][1] = i
					return f:IsShown() and UpdateTablet()
				end
			end
		elseif button == "MiddleButton" and not isGuild then
			if self.presenceID then
				StaticPopup_Show("CONFIRM_REMOVE_FRIEND", self.realID, nil, self.presenceID)
			else
				RemoveFriend( self.unit )
			end
		elseif IsAltKeyDown() then
			if self.presenceID and not self.sameRealm then return end
			InviteUnit( self.unit )
		elseif IsControlKeyDown() then
			if not isGuild then
				FriendsFrame.NotesID = self.presenceID or self.realIndex
				if self.presenceID then
					StaticPopup_Show( "SET_BNFRIENDNOTE", self.realID )
				else
					StaticPopup_Show( "SET_FRIENDNOTE", self.unit )
				end
			elseif button == "LeftButton" and CanEditPublicNote() or button ~= "LeftButton" and CanEditOfficerNote() then
				SetGuildRosterSelection( self.realIndex )
				StaticPopup_Show( button == "LeftButton" and "SET_GUILDPLAYERNOTE" or "SET_GUILDOFFICERNOTE" )
			end
		else
			local name = self.presenceID and self.realID or self.unit
			SetItemRef( "player:"..name, ("|Hplayer:%1$s|h[%1$s]|h"):format(name), "LeftButton" )
		end
	end

	local function Scroll(self, delta)
		slider:SetValue( sliderValue - delta * (IsModifierKeyDown() and 10 or 3) )
	end


	local function CreateFS( parent, justify, anchor, offsetX, color )
		local fs = parent:CreateFontString( nil, "OVERLAY", "SystemFont_Shadow_Med1" )
		if justify then fs:SetJustifyH( justify ) end
		if anchor then fs:SetPoint( "LEFT", anchor, "RIGHT", offsetX or GAP, 0 ) end
		if color then fs:SetTextColor(unpack(color)) end
		return fs
	end

	local function CreateTex( parent, anchor, offsetX )
		local tex = parent:CreateTexture()
		tex:SetWidth( ICON_SIZE )
		tex:SetHeight( ICON_SIZE )
		tex:SetPoint( "LEFT", anchor or parent, anchor and "RIGHT" or "LEFT", offsetX or 0, 0 )
		return tex
	end


	local sep2, sep = f:CreateTexture()
	sep2:SetTexture"Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider"

	local broadcasts = setmetatable( {}, { __index = function( table, index )
		local bc = CreateFrame( "Button", nil, f )
		table[index] = bc
		bc:SetHeight(BUTTON_HEIGHT)
		bc:SetNormalFontObject(GameFontNormal)
	--	bc:RegisterForClicks"LeftButtonUp"
	--	bc:SetScript("OnClick", FriendBroadcast_OnClick)
		bc:EnableMouseWheel(true)
		bc:SetScript( "OnMouseWheel", Scroll )
		bc.icon = CreateTex( bc, nil, ICON_SIZE + TEXT_OFFSET )
		bc.icon:SetTexture"Interface\\FriendsFrame\\BroadcastIcon"
		bc.icon:SetTexCoord(.1,.9,.1,.9)
		bc.text = CreateFS( bc, "LEFT", bc.icon, TEXT_OFFSET, db.Infotext.Guild_Friends.Color.Broadcast )
		bc.text:SetHeight(BUTTON_HEIGHT)
		return bc
	end } )

	toasts = setmetatable( {}, { __index = function( table, key )
		local button = CreateFrame( "Button", nil, f )
		table[key] = button
		button.index = key
		button:SetNormalFontObject(GameFontNormal)
		button:RegisterForClicks"AnyUp"
		button:SetScript( "OnEnter", Menu_OnEnter )
		button:SetScript( "OnLeave", Menu_OnLeave )

		button:EnableMouseWheel(true)
		button:SetScript( "OnMouseWheel", Scroll )
		button:SetScript( "OnClick", OnGuildmateClick )

		button:SetHeight( BUTTON_HEIGHT )

		button.class = CreateTex( button )
		button.status = CreateTex( button, button.class, TEXT_OFFSET )
		button.status:SetTexCoord(.1, .9, .1, .9)
		button.name  = CreateFS( button, "LEFT", button.status, TEXT_OFFSET )
		button.level = CreateFS( button, "CENTER", button.name, GAP )
		button.faction = CreateTex( button, button.level, GAP )
		button.zone  = CreateFS( button, "LEFT", button.faction, TEXT_OFFSET )
		button.note = CreateFS( button, "CENTER", button.zone, GAP, db.Infotext.Guild_Friends.Color.Note )
		return button
	end } )

	buttons = setmetatable( { }, { __index = function( table, key )
		local button = CreateFrame( "Button", nil, f )
		table[key] = button
		button.index = key
		button:SetNormalFontObject(GameFontNormal)
		button:RegisterForClicks"AnyUp"
		button:SetScript( "OnEnter", Menu_OnEnter )
		button:SetScript( "OnLeave", Menu_OnLeave )

		button:EnableMouseWheel(true)
		button:SetScript( "OnMouseWheel", Scroll)

		if key == 0 then
			motd = button
			motd.name = CreateFS( motd, "LEFT" )
			motd:Show()
			motd.name:SetJustifyV"TOP"
			motd.name:SetPoint( "TOPLEFT", motd, "TOPLEFT" )
			motd:SetPoint( "TOPLEFT", f, "TOPLEFT", GAP, -GAP )

			sep = motd:CreateTexture()
			sep:SetTexture"Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider"
			sep:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, BUTTON_HEIGHT)
			sep:SetPoint("BOTTOMRIGHT", motd, "BOTTOMRIGHT", 0, 0)
		else
			button:SetHeight( BUTTON_HEIGHT )
			button.class = button:CreateTexture()
			button.class:SetWidth( ICON_SIZE ) button.class:SetHeight( ICON_SIZE )
			button.class:SetPoint( "LEFT", button, "LEFT" )

			button.status = CreateTex( button, button.class, TEXT_OFFSET )
			button.status:SetTexCoord(.1, .9, .1, .9)

			button.name = CreateFS( button, "LEFT" )
			button.name:SetPoint( "LEFT", button.class, "RIGHT", TEXT_OFFSET, 0 )
			button.level = CreateFS( button, "CENTER", button.name )
			button.zone  = CreateFS( button, "LEFT", button.level )
			button.note = CreateFS( button, "CENTER", button.zone, GAP, db.Infotext.Guild_Friends.Color.Note )
			button.rank  = CreateFS( button, "RIGHT",  button.note, GAP, db.Infotext.Guild_Friends.Color.Rank )
		end
		return button
	end } )

	local function SetClassIcon( tex, class )
		tex:SetTexture"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
		local offset, left, right, bottom, top = 0.025, unpack( CLASS_BUTTONS[class] )
		tex:SetTexCoord( left+offset, right-offset, bottom+offset, top-offset )
	end

	local function SetStatusLayout(statusTex, fs )
		statusTex:Hide()
		fs:SetPoint("LEFT", statusTex, "LEFT")
	end

	local function SetButtonData( index, inGroup )
		local button = buttons[index]

		if index == 0 then
			button.name:SetText(inGroup)
			return button, button.name:GetStringWidth()
		end

		local class, name, level, zone, notes, status, _, rank, realIndex = unpack( (isGuild and guildEntries or friendEntries)[index] )
		button.unit = name
		button.realIndex = realIndex
		button.name:SetFormattedText( (status and preformatedStatusText or "")..(name or""), status )
		if name then
			local color = RAID_CLASS_COLORS[class]
			button.name:SetTextColor( color.r, color.g, color.b )
			SetClassIcon( button.class, class )
			SetStatusLayout(button.status, button.name )
			color = GetQuestDifficultyColor(level)
			button.level:SetTextColor( color.r, color.g, color.b )
			button.zone:SetTextColor( GetZoneColor(zone) )
		end

		button.level:SetText( level or "" )
		button.zone:SetText( zone or "" )
		button.note:SetText( notes or "" )
		button.rank:SetText( rank or "" )

		return	button,
			button.name:GetStringWidth(),
			button.level:GetStringWidth(),
			button.zone:GetStringWidth(),
			button.note:GetStringWidth(),
			rank and button.rank:GetStringWidth() or -GAP
	end


	local function SetToastData( index, inGroup )
		local toast, bc, color = toasts[index]
		local presenceID, givenName, surname, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcast, notes = BNGetFriendInfo(index)
		local _, _, game, realm, faction, race, class, guild, zone, level, gameText = BNGetToonInfo(toonID or 0)
		local statusText = (isAFK or isDND) and (preformatedStatusText):format(isAFK and CHAT_FLAG_AFK or isDND and CHAT_FLAG_DND) or ""

		if broadcast and broadcast ~= "" then
			nbBroadcast = nbBroadcast + 1
			bc = broadcasts[nbBroadcast]
			bc.text:SetText(broadcast)
			toast.bcIndex = nbBroadcast
		else	toast.bcIndex = nil end

		toast.presenceID = presenceID
		toast.unit = toonName
		toast.realID = BATTLENET_NAME_FORMAT:format(givenName, surname)

		SetStatusLayout(toast.status, toast.name )

		client = client == BNET_CLIENT_WOW and WOW or BNET_CLIENT_SC2 and SC2 or 0
		toast.client = client

		if client == WOW then
			toast.faction:SetTexture"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions"
			toast.faction:SetTexCoord( faction == 1 and 0.03 or 0.53, faction == 1 and 0.47 or 0.97, 0.03, 0.97 )
			zone = (not zone or zone == "") and UNKNOWN or zone
			toast.zone:SetPoint("TOPLEFT", toast.faction, "TOPRIGHT", TEXT_OFFSET, 0)
			toast.zone:SetTextColor( GetZoneColor(zone) )
			toast.sameRealm = realm == playerRealm

			if not toast.sameRealm then
				-- hide faction icon and move zone to level
				local r,g,b = unpack(db.Infotext.Guild_Friends.Color.Realm)
				zone = ("%1$s |cff%3$.2x%4$.2x%5$.2x- %2$s"):format(zone, realm, r*255, g*255, b*255)
			end
			class = L[class]
			if class then
				SetClassIcon( toast.class, class )
				color = RAID_CLASS_COLORS[class]
				toast.name:SetTextColor( color.r, color.g, color.b )
			else
				toast.class:SetTexture""
			end
		elseif client == SC2 then
			toast.class:SetTexture"Interface\\FriendsFrame\\Battlenet-Sc2icon"
			toast.class:SetTexCoord( .2, .8, .2, .8 )
			toast.name:SetTextColor( .8, .8, .8 )
			toast.faction:SetTexture""
			zone = gameText
			toast.zone:SetPoint("TOPLEFT", toast.name, "TOPRIGHT", GAP, 0)
			toast.zone:SetTextColor( 1, .77, 0 )
		end

		local rid = "|cff00b2f0"..toast.realID.."|r"
		toast.name:SetFormattedText( statusText.."%1$s - %2$s", rid, toonName or "")

		if level and level ~= "" then
			toast.level:SetText(level)
			color = GetQuestDifficultyColor(tonumber(level))
			toast.level:SetTextColor( color.r, color.g, color.b )
		else	toast.level:SetText"" end

	--	toast.raceIcon:SetTexture"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"
	--	toast.raceIcon:SetTexCoord(  )
		toast.zone:SetText(zone or "")
		toast.note:SetText(notes or "")

		return	toast, client,
			toast.name:GetStringWidth(),
			client == SC2 and -GAP or toast.level:GetStringWidth(),
			toast.zone:GetStringWidth(),
			toast.note:GetStringWidth()
	end

	local function UpdateScrollButtons(nbEntries)
		for i=1, #buttons do buttons[i]:Hide() end
		local baseOffset = -realFriendsHeight
		local sliderValue = hasSlider and sliderValue or 0
		for i=1, nbEntries do
			local button = buttons[sliderValue+i]
			button:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, baseOffset - (i-1)*BUTTON_HEIGHT)
			button:Show()
		end
	end

	local function SortMates(a,b)
		local s = sortIndexes[isGuild]
		local si, lv = s[1], 1
		if a[si] == b[si] then
			si, lv = s[2], 2
			if a[si] ==  b[si] then
				si, lv = s[3], 3
			end
		end
		if db.Infotext.Guild_Friends.sortASC[isGuild][lv] then
			return a[si] < b[si]
		else
			return a[si] > b[si]
		end
	end

	local texOrder1 = f:CreateTexture()
	texOrder1:SetTexture"Interface\\Buttons\\WHITE8X8"
	texOrder1:SetBlendMode"ADD"

	UpdateTablet = function()
		local totalRF, onlineRF, entries = 0, 0

		if isGuild then
			entries = guildEntries
			nbRealFriends = 0
		else
			entries = friendEntries
			totalRF, onlineRF = BNGetNumFriends()
			nbRealFriends = onlineRF
		end

		local nbTotalEntries = #entries + nbRealFriends
		local rid_width, button = 0

		realFriendsHeight = 0

		local nameC, levelC, zoneC, notesC, rankC = 0, 0, 0, 0, -GAP
		local nameW, levelW, zoneW, notesW, rankW
		local hideNotes = not db.Infotext.Guild_Friends.showNotes

		local inGroup = GetNumRaidMembers()>0 and UnitInRaid or GetNumPartyMembers()>0 and UnitInParty or nil
		local tnC, lC, zC, nC = 0, -GAP, -GAP, 0
		local spanZoneC = 0

		if nbRealFriends > 0 then
			nbBroadcast = 0
			for i=1, nbRealFriends do
				local button, client, tnW, lW, zW, nW, spanZoneW = SetToastData(i,inGroup)

				if tnW>tnC then tnC=tnW end

				if client == WOW then
					if lW>lC then lC=lW end
					if zW>zC then zC=zW end
				elseif client == SC2 then
					if zW > spanZoneC then spanZoneC = zW end
				end

				if nW>nC then nC=nW end
			end

			realFriendsHeight = (nbRealFriends+nbBroadcast) * BUTTON_HEIGHT + (#entries>0 and GAP or 0)
			if hideNotes then nC = -GAP end

			spanZoneC = max( spanZoneC, lC + GAP + ICON_SIZE + TEXT_OFFSET + zC )
			rid_width = ICON_SIZE + TEXT_OFFSET + tnC + spanZoneC + nC + 2*GAP

			if #entries>0 then
				local t = toasts[nbRealFriends]
				local offsetY = t.bcIndex and BUTTON_HEIGHT or 0
				sep2:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, 2-offsetY)
				sep2:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 0, 2-offsetY-BUTTON_HEIGHT)
				sep2:Show()
			end
		end
		if isGuild or #entries==0 then sep2:Hide() end

		sort(entries,SortMates)
		for i = 1, #entries do
			button, nameW, levelW, zoneW, notesW, rankW = SetButtonData( i, inGroup )
			button:SetScript( "OnClick", OnGuildmateClick )
			if nameW > nameC then nameC = nameW end
			if levelW and levelW>0 then
				if levelW > levelC then levelC = levelW end
				if  zoneW >  zoneC then  zoneC = zoneW  end
				if notesW > notesC then notesC = notesW end
				if  rankW >  rankC then  rankC = rankW  end
				if hideNotes then button.note:Hide() else button.note:Show() end
				button.rank:SetPoint( "TOPLEFT", hideNotes and button.zone or button.note, "TOPRIGHT", GAP, 0 )
			end
		end

		if hideNotes then notesC = -GAP end
		local maxWidth = max( rid_width, ICON_SIZE + TEXT_OFFSET + nameC + levelC + zoneC + notesC + rankC + GAP * 4 )

		-- motd / broadcast
		local canEditMOTD = CanEditMOTD()
		motd:SetScript("OnClick",nil)
		local guildMOTD = isGuild and GetGuildRosterMOTD()
		if isGuild and (nbTotalEntries>0 and guildMOTD or nbTotalEntries==0) or not isGuild and (BNFeaturesEnabled() and totalRF>0 or nbTotalEntries==0) then
			motd.name:SetJustifyH"LEFT"
			motd.name:SetTextColor( unpack(db.Infotext.Guild_Friends.Color.Title) )
			local r, g, b = unpack(db.Infotext.Guild_Friends.Color.MotD)
			local motdText = ("%%s:  |cff%.2x%.2x%.2x%%s"):format(r*255, g*255, b*255)
			if isGuild then
				SetButtonData( 0, nbTotalEntries>0 and motdText:format("MOTD", guildMOTD) or "     |cffff2020"..ERR_GUILD_PLAYER_NOT_IN_GUILD )
				if nbTotalEntries>0 and canEditMOTD then motd:SetScript( "OnClick", EditMOTD ) end
			else
				if nbTotalEntries == 0 then
					SetButtonData( 0, "     |cffff2020".."No friends online." )
				elseif not BNConnected() then
					motd.name:SetJustifyH"CENTER"
					SetButtonData( 0, "|cffff2020"..BATTLENET_UNAVAILABLE )
				else
					SetButtonData( 0, motdText:format("Broadcast", select(3, BNGetInfo()) or "") )
					motd:SetScript("OnClick", EditBroadcast)
				end
			end
			if nbTotalEntries==0 then
				extraHeight = 0
				sep:Hide()
				maxWidth = min( motd.name:GetStringWidth()+GAP*2, 300 )
			else
				extraHeight = BUTTON_HEIGHT
				sep:Show()
			end
			motd.name:SetWidth( maxWidth )
			extraHeight = extraHeight + motd.name:GetHeight()

			motd:SetWidth( maxWidth )
			motd:SetHeight( extraHeight )

			buttons[1]:SetPoint( "TOPLEFT", motd, "BOTTOMLEFT", 0, -realFriendsHeight )
		else
			extraHeight = 0
			motd.name:SetText""
			motd:SetHeight(1) motd:SetWidth(maxWidth)
			buttons[1]:SetPoint( "TOPLEFT", f, "TOPLEFT", GAP, -GAP )
		end

		for i=1, #toasts do toasts[i]:Hide() end
		for i=1, #broadcasts do broadcasts[i]:Hide() end
		if not isGuild and nbRealFriends>0 then
			local header, bcOffset = motd, 0
			local bcWidth = maxWidth - 2*(ICON_SIZE - TEXT_OFFSET) -2*GAP
			for i=1, nbRealFriends do
				local b = toasts[i]
				b:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, (1-i-bcOffset)*BUTTON_HEIGHT)
				if b.bcIndex then
					bcOffset = bcOffset + 1
					local bc = broadcasts[b.bcIndex]
					bc.text:SetWidth(bcWidth)
					bc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, (1-i-bcOffset)*BUTTON_HEIGHT)
					bc:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -ICON_SIZE-TEXT_OFFSET, (-i-bcOffset)*BUTTON_HEIGHT)
					bc:Show()
				end
				b:Show()
			end
		end

		MAX_ENTRIES = floor( (UIParent:GetHeight()/fscale - extraHeight - GAP*2) / BUTTON_HEIGHT - 2 / fscale )
		slider:SetHeight(BUTTON_HEIGHT*MAX_ENTRIES)
		hasSlider = #entries > MAX_ENTRIES
		if hasSlider then
			slider:SetMinMaxValues( 0, #entries - MAX_ENTRIES )
			slider:SetValue(sliderValue)
			slider:Show()
		else	slider:Hide() end
		nbEntries = math.min( MAX_ENTRIES, #entries )

		UpdateScrollButtons(nbEntries)

		for i=1, nbRealFriends do
			button = toasts[i]
			button:SetWidth( maxWidth )
			button.name:SetWidth(tnC)
			if button.client == SC2 then
				button.zone:SetWidth(spanZoneC)
			elseif button.client == WOW then
				button.level:SetWidth(lC)
				button.zone:SetWidth(zC)
			end
			button.note:SetWidth(nC)
		end

		for i=1, #entries do
			button = buttons[i]
			button:SetWidth( maxWidth )
			button.name:SetWidth(nameC)
			button.level:SetWidth(levelC)
			button.zone:SetWidth(zoneC)
			button.note:SetWidth(notesC)
			button.rank:SetWidth(rankC)
		end

		if nbEntries>0 then
			local col = db.Infotext.Guild_Friends.sortCols[isGuild][1]
			local obj = buttons[1][col]
			if obj:IsShown() then
				texOrder1:SetPoint("TOPLEFT", obj, "TOPLEFT", -.25*GAP, 2 )
				texOrder1:SetWidth(obj:GetWidth()+GAP*.5) texOrder1:SetHeight(nbEntries*BUTTON_HEIGHT+1)
				local asc = db.Infotext.Guild_Friends.sortASC[isGuild][1]
				if col == "level" then asc = not asc end
				local a1, r1, g1, b1 = db.Infotext.Guild_Friends.Color.OrderA[4], unpack(db.Infotext.Guild_Friends.Color.OrderA)
				local a2, r2, g2, b2 = 0, unpack(db.Infotext.Guild_Friends.Color.Background)
				if asc then r1,g1,b1,a1, r2,g2,b2,a2 = r2,g2,b2,a2, r1,g1,b1,a1 end
				texOrder1:SetGradientAlpha("VERTICAL", r1,g1,b1,a1, r2,g2,b2,a2)
			else
				texOrder1:SetAlpha(0)
			end
		else
			texOrder1:SetAlpha(0)
		end

		if hasSlider then slider:SetPoint("TOPRIGHT", buttons[1], "TOPRIGHT", 19 + TEXT_OFFSET, 0) end

		f:SetWidth( maxWidth + GAP*2 + (hasSlider and 16 + TEXT_OFFSET*2 or 0) )
		f:SetHeight( extraHeight + realFriendsHeight + BUTTON_HEIGHT * nbEntries + GAP*2 )
		if not (f.onBlock or f:IsMouseOver()) then f:Hide() end
	end

	local function AnchorTablet(frame)
		CloseDropDownMenus()
		f:Show()
		f.isTop, f.onBlock = select(2, frame:GetCenter()) > UIParent:GetHeight() / 2, true
		f:ClearAllPoints()
		f:SetPoint(f.isTop and "TOP" or "BOTTOM", frame, f.isTop and "BOTTOM" or "TOP")
		f:SetBackdropColor( unpack( db.Infotext.Guild_Friends.Color.Background ) )
		f:SetBackdropBorderColor( unpack( db.Infotext.Guild_Friends.Color.Border ) )
		UpdateBlockHints()
		UpdateTablet()
	end


	--------------------------------------------------------------------
	-- /GUILD/ --
	--------------------------------------------------------------------

	if db.Infotext.Guild_Friends.Guild.Enable == true then

		local Stat9 = CreateFrame("Frame", "LUI_Info_Guild", LUI_Infos_TopRight)
		Stat9:EnableMouse(true)

		f.Guild = CreateFrame("Frame", "LUI Guild", Stat9)

		f.Guild.text = LUI_Infos_TopRight:CreateFontString("LUI_Guild", "OVERLAY")
		f.Guild.text:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
		f.Guild.text:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Guild.Font), db.Infotext.Guild_Friends.Guild.Size, db.Infotext.Guild_Friends.Guild.Outline)
		f.Guild.text:SetHeight(db.Infotext.Guild_Friends.Guild.Size)
		f.Guild.text:SetTextColor(db.Infotext.Guild_Friends.Guild.Color.r, db.Infotext.Guild_Friends.Guild.Color.g, db.Infotext.Guild_Friends.Guild.Color.b, db.Infotext.Guild_Friends.Guild.Color.a)
		f.Guild.text:SetText("LUI_Friends")

		f.Guild:SetAllPoints(f.Guild.text)
		f.Guild:SetScript("OnEnter", function(self)
			if db.Infotext.CombatLock and InCombatLockdown() then return end

			isGuild = true
			if IsInGuild() then GuildRoster() end
			AnchorTablet(self)
		end)
		f.Guild:SetScript("OnLeave", Block_OnLeave)
		f.Guild:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				if not GuildFrame or not GuildFrame:IsShown() or (GuildRosterFrame and GuildRosterFrame:IsShown()) then
					ToggleGuildFrame()
				end
				if GuildFrame and GuildFrame:IsShown() then
					GuildFrameTab2:Click()
				end
			elseif button == "RightButton" then
				if not GuildFrame or not GuildFrame:IsShown() or (GuildMainFrame and GuildMainFrame:IsShown()) then
					ToggleGuildFrame()
				end
				if GuildFrame and GuildFrame:IsShown() then
					GuildFrameTab1:Click()
				end
			elseif button == "Button4" then
				db.Infotext.Guild_Friends.showNotes = not db.Infotext.Guild_Friends.showNotes
				UpdateTablet()
			elseif button == "Button5" then
				db.Infotext.Guild_Friends.ShowHints = not db.Infotext.Guild_Friends.ShowHints
				UpdateBlockHints()
			end
		end)

		f:RegisterEvent("GUILD_ROSTER_UPDATE")
		f:RegisterEvent("PLAYER_GUILD_UPDATE")

		f:GUILD_ROSTER_UPDATE()
	end

	--------------------------------------------------------------------
	-- /FRIENDS/ --
	--------------------------------------------------------------------

	if db.Infotext.Guild_Friends.Friends.Enable == true then

		local Stat10 = CreateFrame("Frame", "LUI_Info_Friends", LUI_Infos_TopRight)
		Stat10:EnableMouse(true)

		f.Friends = CreateFrame("Frame", "LUI Friends", Stat10)

		f.Friends.text = LUI_Infos_TopRight:CreateFontString("LUI_Friends", "OVERLAY")
		f.Friends.text:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
		f.Friends.text:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Friends.Font), db.Infotext.Guild_Friends.Friends.Size, db.Infotext.Guild_Friends.Friends.Outline)
		f.Friends.text:SetHeight(db.Infotext.Guild_Friends.Friends.Size)
		f.Friends.text:SetTextColor(db.Infotext.Guild_Friends.Friends.Color.r, db.Infotext.Guild_Friends.Friends.Color.g, db.Infotext.Guild_Friends.Friends.Color.b, db.Infotext.Guild_Friends.Friends.Color.a)
		f.Friends.text:SetText("LUI_Guild")

		f.Friends:SetAllPoints(f.Friends.text)
		f.Friends:SetScript("OnEnter", function(self)
			if db.Infotext.CombatLock and InCombatLockdown() then return end

			isGuild = false
			ShowFriends()
			AnchorTablet(self)
		end)
		f.Friends:SetScript("OnLeave", Block_OnLeave)
		f.Friends:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" or IsModifierKeyDown() then
				f:Hide()
				FriendsFrameAddFriendButton:Click()
			elseif button == "LeftButton" then
				ToggleFriendsFrame(1)
			elseif button == "Button4" then
				db.Infotext.Guild_Friends.showNotes = not db.Infotext.Guild_Friends.showNotes
				UpdateTablet()
			elseif button == "Button5" then
				db.Infotext.Guild_Friends.ShowHints = not db.Infotext.Guild_Friends.ShowHints
				UpdateBlockHints()
			end
		end)

		StaticPopupDialogs.SET_BN_BROADCAST = {
			text = BN_BROADCAST_TOOLTIP,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = 1,
			editBoxWidth = 350,
			maxLetters = 127,
			OnAccept = function(self) BNSetCustomMessage(self.editBox:GetText()) end,
			OnShow = function(self) self.editBox:SetText( select(3, BNGetInfo()) ) self.editBox:SetFocus() end,
			OnHide = ChatEdit_FocusActiveWindow,
			EditBoxOnEnterPressed = function(self) BNSetCustomMessage(self:GetText()) self:GetParent():Hide() end,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 1
		}

		f:RegisterEvent("FRIENDLIST_UPDATE")
		f:RegisterEvent("CHAT_MSG_SYSTEM")
		f:RegisterEvent("BN_FRIEND_INFO_CHANGED")
		f:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
		f:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
		f:RegisterEvent("BN_CUSTOM_MESSAGE_CHANGED")
		f:RegisterEvent("BN_CONNECTED")
		f:RegisterEvent("BN_DISCONNECTED")

		ShowFriends()
	end

	local guildTimer, friendTimer = 0, 0

	local orgGuildRoster = GuildRoster
	GuildRoster = function(...)
		guildTimer = 0
		return orgGuildRoster(...)
	end

	local orgShowFriends = ShowFriends
	ShowFriends = function(...)
		friendTimer = 0
		return orgShowFriends(...)
	end

	local function OnUpdate( self, elapsed )
		guildTimer, friendTimer = guildTimer + elapsed, friendTimer + elapsed
		if guildTimer > 15 then
			if IsInGuild() then GuildRoster() else guildTimer = 0 end
		end
		if friendTimer > 15 then ShowFriends() end
	end

	function f:BN_FRIEND_INFO_CHANGED()
		if f:IsShown() then
			UpdateTablet()
		end
	end

	f.BN_CUSTOM_MESSAGE_CHANGED = f.BN_FRIEND_INFO_CHANGED
	f.BN_FRIEND_ACCOUNT_ONLINE = UpdateFriendText
	f.BN_FRIEND_ACCOUNT_OFFLINE = UpdateFriendText
	f.BN_CONNECTED = UpdateFriendText
	f.BN_DISCONNECTED = UpdateFriendText

	f:Hide()

	local r,g,b = unpack(db.Infotext.Guild_Friends.Color.Status)
	preformatedStatusText = db.Infotext.Guild_Friends.ClassColoredStatus and "%s " or ("|cff%.2x%.2x%.2x%%s|r "):format(r*255,g*255,b*255)
	sortIndexes = {
		[true] = { colpairs[db.Infotext.Guild_Friends.sortCols[true ][1]], colpairs[db.Infotext.Guild_Friends.sortCols[true ][2]], colpairs[db.Infotext.Guild_Friends.sortCols[true ][3]] },
		[false] ={ colpairs[db.Infotext.Guild_Friends.sortCols[false][1]], colpairs[db.Infotext.Guild_Friends.sortCols[false][2]], colpairs[db.Infotext.Guild_Friends.sortCols[false][3]] },
	}
	texOrder1:SetVertexColor(unpack(db.Infotext.Guild_Friends.Color.OrderA))

	horde = UnitFactionGroup("player") == "Horde"
	f:SetBackdrop({
		bgFile = LSM:Fetch("background", db.Infotext.Guild_Friends.BGTexture),
		edgeFile = LSM:Fetch("border", db.Infotext.Guild_Friends.BorderTexture),
		edgeSize=14, tile = false, tileSize=0,
		insets = { left=0, right=0, top=0, bottom=0 }})
	f:SetFrameStrata("TOOLTIP")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)

	slider = CreateFrame("Slider", "LUI_Info_G/F_slider", f)
	slider:SetWidth(16)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		edgeSize = 8, tile = true, tileSize = 8,
		insets = {left=3, right=3, top=6, bottom=6}
	})
	slider:SetValueStep(1)
	slider:SetScript("OnLeave", Menu_OnLeave)
	slider:SetScript("OnValueChanged", function(self, value)
		if hasSlider then
			sliderValue = value
			if f:IsMouseOver() then UpdateScrollButtons(MAX_ENTRIES) end
		end
	end)

	if IsInGuild(buttons[0]) then GuildRoster() else guildTimer = 0 end

	t:SetScript("OnUpdate", OnUpdate)
	f:SetScript("OnEnter", Menu_OnEnter)
	f:SetScript("OnLeave", Menu_OnLeave)
	f:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

	StaticPopupDialogs.COLORS_RESET = {
		text = "The Colors have been reset to thier default settings",
		button1 = "OK",
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		hideOnEscape = 1
	}
end

------------------------------------------------------
-- / INSTANCE / --
------------------------------------------------------

function module:SetInstance()
	if not db.Infotext.Instance.Enable then self:HideDataText(self.Instance, LUI_Text_Instance) return end

	-- Add stat to the modules namespace.
	self.Instance = CreateFrame("Frame", "LUI_Info_Instance")

	-- Create local shortcuts.
	local INST = self.Instance
	INST.db = db.Infotext.Instance

	-- Frame settings.
	INST:EnableMouse(true)
	self:GetInfoPanel(INST)
	INST:Show()

	-- Create info text.
	LUI_Text_Instance = INST:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Instance, INST.db)
	LUI_Text_Instance:SetFont(LSM:Fetch("font", INST.db.Font), INST.db.Size, INST.db.Outline)
	LUI_Text_Instance:SetHeight(INST.db.Size)
	LUI_Text_Instance:SetTextColor(INST.db.Color.r, INST.db.Color.g, INST.db.Color.b, INST.db.Color.a)
	LUI_Text_Instance:Show()
	INST:SetAllPoints(LUI_Text_Instance)
   
	local instances = {}

	-- Stat functions.
	function INST.UpdateInstanceInfo()
		local numInstances = GetNumSavedInstances()

		for i = 1, numInstances do
			local instance = {}
			local instanceDifficulty
			instance.name, instance.ID, instance.remaining, _, _, _, _, _, _, instanceDifficulty = GetSavedInstanceInfo(i)
			instance.name = instance.name .. ' - ' .. instanceDifficulty
			instance.curtime = time()

			if (instance.remaining ~= 0) then
			instances[i] = instance
			end
		end

		table.sort(instances, function(a, b) return a.name < b.name end)
		LUI_Text_Instance:SetText("Instance ["..#(instances).."]")
		return true
	end

	-- Script functions.
	function INST:OnEnter()
		local numInstance = #(instances)
		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Instance Info:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		if numInstance == 0 then
			GameTooltip:AddLine("[No saved instances]")
		else
			GameTooltip:AddDoubleLine("Instance:", "Time Remaining:")
			GameTooltip:AddLine(" ")
		end

		for i = 1, numInstance do
			local instance = instances[i]
			if (instance ~= nil) then
			if (time() <= (instance.curtime + instance.remaining)) then
				GameTooltip:AddDoubleLine(instance.name.." ("..instance.ID..")", SecondsToTime((instance.curtime + instance.remaining) - time()), 255, 255, 255, 255, 255, 255)
			else
				instance = nil
			end
			end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint:\n- Any Click to open Raid Info frame.", 0, 1, 0)
		GameTooltip:Show()
		LUI_Text_Instance:SetText("Instance ["..numInstance.."]")
	end

	function INST:OnEvent(event)
		if event == "PLAYER_ENTERING_WORLD" then
			RequestRaidInfo()
			LUI_Text_Instance:SetText("Instance [0]")
		else
			self.UpdateInstanceInfo()
		end

		-- Setup instance tooltip.
		self:SetAllPoints(LUI_Text_Instance)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	INST:RegisterEvent("INSTANCE_BOOT_START");
	INST:RegisterEvent("INSTANCE_BOOT_STOP");
	INST:RegisterEvent("PLAYER_ENTERING_WORLD");
	INST:RegisterEvent("UPDATE_INSTANCE_INFO");
	INST:SetScript("OnEnter", INST.OnEnter)
	INST:SetScript("OnEvent", INST.OnEvent)
	INST:SetScript("OnLeave", function() GameTooltip:Hide() end)
	INST:SetScript("OnMouseDown", function(self, button)
		if RaidInfoFrame:IsVisible() then
			RaidInfoFrame:Hide()
			if FriendsFrame:IsVisible() then
				FriendsFrame:Hide()
			end
		else
			ToggleFriendsFrame(4)
			RaidInfoFrame:Show()
		end
	end)
	INST:OnEvent("PLAYER_ENTERING_WORLD")
end

------------------------------------------------------
-- / MEMORY USAGE / --
------------------------------------------------------

function module:SetMemoryUsage()
	if not db.Infotext.Memory.Enable then self:HideDataText(self.Memory, LUI_Text_Memory) return end

	-- Add stat to modules namespace.
	self.Memory = CreateFrame("Frame", "LUI_Info_Memory")

	-- Create local shortcuts.
	local MEM = self.Memory
	MEM.db = db.Infotext.Memory

	-- Frame settings.
	MEM:EnableMouse(true)
	self:GetInfoPanel(MEM)
	MEM:Show()

	LUI_Text_Memory = MEM:CreateFontString(nil, "OVERLAY")
	self:GetInfoPanelPosition(LUI_Text_Memory, MEM.db)
	LUI_Text_Memory:SetFont(LSM:Fetch("font", MEM.db.Font), MEM.db.Size, MEM.db.Outline)
	LUI_Text_Memory:SetHeight(MEM.db.Size)
	LUI_Text_Memory:SetTextColor(MEM.db.Color.r, MEM.db.Color.g, MEM.db.Color.b, MEM.db.Color.a)
	LUI_Text_Memory:Show()
	MEM:SetAllPoints(LUI_Text_Memory)

	-- Localised functions.
	local floor, format, sort = floor, string.format, table.sort

	-- Variables.
	local Total
	local Memory = {}

	-- Stat functions.
	function MEM.FormatMemory(kb)
		if kb > 1024 then
			return format("%.1fmb", kb / 1024)
		else
			return format("%.1fkb", kb)
		end
	end

	function MEM:RefreshMemory()
		UpdateAddOnMemoryUsage()

		Total = 0
		for i = 1, GetNumAddOns() do
			if not Memory[i] then Memory[i] = {} end

			Memory[i][1] = select(2, GetAddOnInfo(i))
			Memory[i][2] = GetAddOnMemoryUsage(i)
			Memory[i][3] = IsAddOnLoaded(i)
			Total = Total + Memory[i][2]
		end

		-- Update info text.		
		LUI_Text_Memory:SetText(self.FormatMemory(Total))

		-- Setup memory tooltip.
		self:SetAllPoints(LUI_Text_Memory)

		-- Update tooltip if open.
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			self:OnEnter()
		end
	end

	-- Script functions.
	function MEM:OnEnter()
		if db.Infotext.CombatLock and InCombatLockdown() then return end
		
		GameTooltip:SetOwner(self, "ANCHOR_"..(self.db.InfoPanel.Vertical == "Top" and "BOTTOM" or "TOP"))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Memory:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")

		sort(Memory, function(a, b)
			if a and b then
				return a[2] > b[2]
			end
		end)

		for i = 1, #Memory do
			if Memory[i][3] then
				local red = Memory[i][2] / Total * 2
				local green = 1 - red
				GameTooltip:AddDoubleLine(Memory[i][1], self.FormatMemory(Memory[i][2]), 1, 1, 1, red, green + 1, 0)
			end
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("Total Memory Usage:", self.FormatMemory(Total), 1, 1, 1, 0.8, 0.8, 0.8)

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hint: Click to Collect Garbage.", 0, 1, 0)
		GameTooltip:Show()
	end

	MEM.dt = 0
	function MEM:OnUpdate(deltaTime)
		self.dt = self.dt + deltaTime
		if self.dt > 10 then
			self.dt = 0
			self:RefreshMemory()
		end
	end

	MEM:SetScript("OnEnter", MEM.OnEnter)
	MEM:SetScript("OnLeave", function() GameTooltip:Hide() end)
	MEM:SetScript("OnMouseDown", function(self) collectgarbage("collect") self:OnUpdate(10) end)
	MEM:SetScript("OnUpdate", MEM.OnUpdate)
	MEM:OnUpdate(100)
end

--  END INFO TEXT --

local defaults = {
	Infotext = {
		Enable = true,
		CombatLock = false,
		Armor = {
			Enable = true,
			X = 345,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Bags = {
			Enable = true,
			X = 200,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Clock = {
			Enable = true,
			LocalTime = true,
			Time24 = true,
			ShowInstanceDifficulty = true,
			X = -55,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Currency = {
			Enable = false,
			X = 180,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Dps = {
			Enable = true,
			Active = "dps",
			X = -610,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		DualSpec = {
			Enable = false,
			ShowSpentPoints = true,
			X = 320,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Fps = {
			Enable = true,
			MSValue = "Both",
			X = 500,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Gold = {
			Enable = true,
			ShowToonMoney = true,
			X = 55,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			ColorType = false,
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Guild_Friends = {
			Color = {
				Background = { 0.18, 0.18, 0.18, 1 },
				Border = { 0.3, 0.3, 0.3, 1 },
				Note = { 0.14, 0.76, 0.15 },
				OfficerNote = { 1, 0.56, 0.25 },
				MotD = { 1, 0.8, 0 },
				Broadcast = { 1, 0.1, 0.1 },
				Title = { 1, 1, 1 },
				Rank = { 0.1, 0.9, 1 },
				Realm = { 1, 0.8, 0 },
				Status = { 0.7, 0.7, 0.7 },
				OrderA = { 1, 1, 1, 0.1 },
				ContestedZone = { 1, 1, 0 },
				FriendlyZone = { 0, 1, 0 },
				EnemyZone = { 1, 0, 0 },
			},
			ShowTotal = false,
			ShowHints = true,
			showNotes = true,
			sortCols = {
				[true] = { "class", "name", "name" },
				[false] = { "name", "name", "name" },
			},
			sortASC = {
				[true] = { true, true, true },
				[false] = { true, true, true },
			},
			ClassColoredStatus = false,
			BGTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			Guild = {
				Enable = true,
				X = -485,
				Y = -6,
				Font = "vibroceb",
				Size = 12,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1,
				},
			},
			Friends = {
				Enable = true,
				X = -375,
				Y = -6,
				Font = "vibroceb",
				Size = 12,
				Outline = "NONE",
				Color = {
					r = 1,
					g = 1,
					b = 1,
					a = 1,
				},
			},
		},
		Instance = {
			Enable = false,
			X = 60,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Memory = {
			Enable = true,
			X = 610,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
	},
}

function module:LoadOptions()
	-- Local options creators.
	local function PostionOptions(statName, infoTextName, order, statDB, statDefaults)
		local horizontal = { "Left", "Right", }
		local vertical = { "Bottom", "Top", }
		local option = {
			name = "Info Panel and Position",
			type = "group",
			order = order,
			disabled = function() return not statDB.Enable end,
			guiInline = true,
			args = {
				X = {
					name = "X Offset",
					desc = "X offset for the "..statName.." info text.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..statDefaults.X,
					type = "input",
					order = 1,
					disabled = function() return not statDB.Enable end,
					get = function() return tostring(statDB.X) end,
					set = function(self, x)
								if x == nil or x == "" then
									x = "0"
								end

								statDB.X = tonumber(x)
								module:GetInfoPanelPosition(_G[infoTextName], statDB)
							end,
				},
				Y = {
					name = "Y Offset",
					desc = "Y offset for the "..statName.." info text.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..statDefaults.Y,
					type = "input",
					order = 2,
					disabled = function() return not statDB.Enable end,
					get = function() return tostring(statDB.Y) end,
					set = function(self, y)
								if y == nil or y == "" then
									y = "0"
								end

								statDB.Y = tonumber(y)
								module:GetInfoPanelPosition(_G[infoTextName], statDB)
							end,
				},
				Horizontal = {
					name = "Horizontal",
					desc = "Select the horizontal panel that the "..statName.." info text will be anchored to.\n\nDefault: "..statDefaults.InfoPanel.Horizontal,
					type = "select",
					order = 3,
					values = horizontal,
					get = function()
							for k, v in pairs(horizontal) do
								if statDB.InfoPanel.Horizontal == v then return k end
							end
						end,
					set = function(self, value)
							statDB.InfoPanel.Horizontal = horizontal[value]
							statDB.X = 0
							module:GetInfoPanelPosition(_G[infoTextName], statDB)
						end,
				},
				Vertical = {
					name = "Vertical",
					desc = "Select the vertical panel that the "..statName.." info text will be anchored to.\n\nDefault: "..statDefaults.InfoPanel.Vertical,
					type = "select",
					order = 4,
					values = vertical,
					get = function()
							for k, v in pairs(vertical) do
								if statDB.InfoPanel.Vertical == v then return k end
							end
						end,
					set = function(self, value)
							statDB.InfoPanel.Vertical = vertical[value]
							statDB.Y = 0
							module:GetInfoPanelPosition(_G[infoTextName], statDB)
						end,
				},				
			}
		}

		return option
	end
	local function FontOptions(statName, infoText, order, statDB, statDefaults)
		local option = {
			name = "Font Settings",
			type = "group",
			disabled = function() return not statDB.Enable end,
			order = order,
			guiInline = true,
			args = {
				FontSize = {
					name = "Size",
					desc = "Choose your "..statName.." info text's fontsize.\n\nDefault: "..statDefaults.Size,
					type = "range",
					order = 1,
					min = 1,
					max = 40,
					step = 1,
					get = function() return statDB.Size end,
					set = function(_, size)
							statDB.Size = size
							_G[infoTextName]:SetFont(LSM:Fetch("font", statDB.Font), statDB.Size, statDB.Outline)
						end,
				},
				Color = {
					name = "Color",
					desc = "Choose your "..statName.." info text's colour.\n\nDefaults:\nr = "..statDefaults.Color.r.."\ng = "..statDefaults.Color.b.."\na = "..statDefaults.Color.a,
					type = "color",
					hasAlpha = true,
					get = function() return statDB.Color.r, statDB.Color.g, statDB.Color.b, statDB.Color.a end,
					set = function(_, r, g, b, a)
							statDB.Color.r = r
							statDB.Color.g = g
							statDB.Color.b = b
							statDB.Color.a = a

							_G[infoTextName]:SetTextColor(r, g, b, a)
						end,
					order = 2,
				},
				Font = {
					name = "Font",
					desc = "Choose your "..statName.." info text's font.\n\nDefault: "..statDefaults.Font,
					type = "select",
					dialogControl = "LSM30_Font",
					values = widgetLists.font,
					get = function() return statDB.Font end,
					set = function(self, font)
							statDB.Font = font
							_G[infoTextName]:SetFont(LSM:Fetch("font", statDB.Font), statDB.Size, statDB.Outline)
						end,
					order = 3,
				},
				FontFlag = {
					name = "Font Flag",
					desc = "Choose your "..statName.." info text's font flag.\n\nDefault: "..statDefaults.Outline,
					type = "select",
					values = fontflags,
					get = function()
							for k, v in pairs(fontflags) do
								if statDB.Outline == v then
									return k
								end
							end
						end,
					set = function(self, flag)
							statDB.Outline = fontflags[flag]
							_G[infoTextName]:SetFont(LSM:Fetch("font", statDB.Font), statDB.Size, statDB.Outline)
						end,
					order = 4,
				},
			},
		}

		return option
	end

	local options = {
		Infotext = {
			name = "Info Text",
			type = "group",
			order = 65,
			disabled = function() return not db.Infotext.Enable end,
			childGroups = "select",
			args = {
				General = {
					name = "General",
					type = "group",
					order = 1,
					args = {
						Header = {
							name = "General",
							type = "header",
							order = 1,
						},
						CombatLock = {
							name = "Combat Lock Down",
							desc = "Hide tooltip info for datatext stats while in combat.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.CombatLock end,
							set = function() db.Infotext.CombatLock = not db.Infotext.CombatLock end,
							order = 2,
						},
						ResetToDefaults = {
							name = "Reset To Defaults",
							type = "execute",
							func = function()
									db.Infotext = defaults.Infotext
									StaticPopup_Show("RELOAD_UI")
								end,
							order = 3,
						},
					},
				},
				Bags = {
					name = function() return (db.Infotext.Bags.Enable and "Bags") or "|cff888888Bags|r" end,
					type = "group",
					order = 2,
					args = {
						Header = {
							name = "Bags",
							type = "header",
							order = 1,
						},
						BagsEnable = {
							name = "Enable",
							desc = "Whether you want to show your Bag Status or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Bags.Enable end,
							set = function()
									db.Infotext.Bags.Enable = not db.Infotext.Bags.Enable
									module:SetBags()
								end,
							order = 2,
						},
						Position = PostionOptions("Bags", "LUI_Text_Bags", 3, db.Infotext.Bags, LUI.defaults.profile.Infotext.Bags),
						Font = FontOptions("Bags", "LUI_Text_Bags", 4, db.Infotext.Bags, LUI.defaults.profile.Infotext.Bags),
					},
				},
				Clock = {
					name = function() return (db.Infotext.Clock.Enable and "Clock") or "|cff888888Clock|r" end,
					type = "group",
					order = 3,
					args = {
						Header = {
							name = "Clock",
							type = "header",
							order = 1,
						},
						ClockEnable = {
							name = "Enable",
							desc = "Whether you want to show your Clock or not.",
							type = "toggle",
							get = function() return db.Infotext.Clock.Enable end,
							set = function()
										db.Infotext.Clock.Enable = not db.Infotext.Clock.Enable
										module:SetClock()
									end,
							order = 2,
						},
						ShowInstanceDifficulty = {
							name = "Show Instance Difficulty",
							desc = "Whether you want to show the Instance Difficulty or not.",
							type = "toggle",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.ShowInstanceDifficulty end,
							set = function()
										db.Infotext.Clock.ShowInstanceDifficulty = not db.Infotext.Clock.ShowInstanceDifficulty
										module.Clock:ShowInstanceDifficulty()
									end,
							order = 3,
						},
						EnableLocalTime = {
							name = "Local Time",
							desc = "Whether you want to show your Local Time or Server Time.",
							type = "toggle",
							width = "50%",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.LocalTime end,
							set = function() db.Infotext.Clock.LocalTime = not db.Infotext.Clock.LocalTime end,
							order = 4,
						},
						EnableTime24 = {
							name = "24h Clock",
							desc = "Whether you want to show 24 or 12 hour Clock.",
							type = "toggle",
							width = "50%",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.Time24 end,
							set = function() db.Infotext.Clock.Time24 = not db.Infotext.Clock.Time24 end,
							order = 5,
						},
						Position = PostionOptions("Clock", "LUI_Text_Clock", 6, db.Infotext.Clock, LUI.defaults.profile.Infotext.Clock),
						Font = FontOptions("Clock", "LUI_Text_Clock", 7, db.Infotext.Clock, LUI.defaults.profile.Infotext.Clock),
					},
				},
				Currency = {
					name = function() return (db.Infotext.Currency.Enable and "Currency Info") or "|cff888888Currency Info|r" end,
					type = "group",
					order = 4,
					args = {
						Header = {
							name = "Currency",
							type = "header",
							order = 1,
						},
						CurrencyEnable = {
							name = "Enable",
							desc = "Whether you want to show your Currency Info or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Currency.Enable end,
							set = function()
										db.Infotext.Currency.Enable = not db.Infotext.Currency.Enable
										module:SetCurrency()
									end,
							order = 2,
						},
						Position = PostionOptions("Currency", "LUI_Text_Currency", 3, db.Infotext.Currency, LUI.defaults.profile.Infotext.Currency),
						Font = FontOptions("Currency", "LUI_Text_Currency", 4, db.Infotext.Currency, LUI.defaults.profile.Infotext.Currency),
					},
				},
				DPS = {
					name = function() return (db.Infotext.Dps.Enable and "DPS") or "|cff888888DPS|r" end,
					type = "group",
					order = 5,
					args = {
						Header = {
							name = "DPS",
							type = "header",
							order = 1,
						},
						DpsEnable = {
							name = "Enable",
							desc = "Whether you want to show your DPS or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Dps.Enable end,
							set = function()
										db.Infotext.Dps.Enable = not db.Infotext.Dps.Enable
										module:SetDPS()
									end,
							order = 2,
						},
						Position = PostionOptions("DPS", "LUI_Text_DPS", 3, db.Infotext.Dps, LUI.defaults.profile.Infotext.Dps),
						Font = FontOptions("DPS", "LUI_Text_DPS", 4, db.Infotext.Dps, LUI.defaults.profile.Infotext.Dps),
					},
				},
				DualSpec = {
					name = function() return (db.Infotext.DualSpec.Enable and "Dual Spec") or "|cff888888Dual Spec|r" end,
					type = "group",
					order = 6,
					args = {
						Header = {
							name = "Dual Spec",
							type = "header",
							order = 1,
						},
						DualSpecEnable = {
							name = "Enable",
							desc = "Whether you want to show your Spec or not. (Only for level 10+)",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.DualSpec.Enable end,
							set = function()
										db.Infotext.DualSpec.Enable = not db.Infotext.DualSpec.Enable
										module:SetDualSpec()
									end,
							order = 2,
						},
						DualSpecShowSpentPoints = {
							name = "Spent points",
							desc = "Show spent talent points \"(x/x/x)\".",
							type = "toggle",
							width = "full",
							disabled = function() return not db.Infotext.DualSpec.Enable end,
							get = function() return db.Infotext.DualSpec.ShowSpentPoints end,
							set = function() db.Infotext.DualSpec.ShowSpentPoints = not db.Infotext.DualSpec.ShowSpentPoints end,
							order = 3,
						},
						Position = PostionOptions("DualSpec", "LUI_Text_DualSpec", 4, db.Infotext.DualSpec, LUI.defaults.profile.Infotext.DualSpec),
						Font = FontOptions("DualSpec", "LUI_Text_DualSpec", 5, db.Infotext.DualSpec, LUI.defaults.profile.Infotext.DualSpec),
					},
				},
				Durability = {
					name = function() return (db.Infotext.Armor.Enable and "Durability") or "|cff888888Durability|r" end,
					type = "group",
					order = 7,
					args = {
						Header = {
							name = "Durability",
							type = "header",
							order = 1,
						},
						ArmorEnable = {
							name = "Enable",
							desc = "Whether you want to show your Durability or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Armor.Enable end,
							set = function()
										db.Infotext.Armor.Enable = not db.Infotext.Armor.Enable
										module:SetDurability()
									end,
							order = 2,
						},
						Position = PostionOptions("Durability", "LUI_Text_Durability", 3, db.Infotext.Armor, LUI.defaults.profile.Infotext.Armor),
						Font = FontOptions("Durability", "LUI_Text_Durability", 4, db.Infotext.Armor, LUI.defaults.profile.Infotext.Armor),
					},
				},
				FPS = {
					name = function() return (db.Infotext.Fps.Enable and "FPS / MS") or "|cff888888FPS / MS|r" end,
					type = "group",
					order = 8,
					args = {
						Header = {
							name = "FPS / MS",
							type = "header",
							order = 1,
						},
						FpsEnable = {
							name = "Enable",
							desc = "Whether you want to show your FPS / MS or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Fps.Enable end,
							set = function()
										db.Infotext.Fps.Enable = not db.Infotext.Fps.Enable
										module:SetFPS()
									end,
							order = 2,
						},
						MSValue = {
							name = "MS Value",
							desc = "Wether you want your MS to show World, Home or both latency values.\n\nDefault: World",
							type = "select",
							disabled = function() return not db.Infotext.Fps.Enable end,
							values = { "Both", "Home", "World", },
							get = function()
									local t = { "Both", "Home", "World", }

									for k, v in pairs(t) do
										if db.Infotext.Fps.MSValue == v then return k end
									end
								end,
							set = function(self, value)
									local t = { "Both", "Home", "World", }
									db.Infotext.Fps.MSValue = t[value]
								end,
							order = 3,
						},
						Position = PostionOptions("FPS", "LUI_Text_FPS", 4, db.Infotext.Fps, LUI.defaults.profile.Infotext.Fps),
						Font = FontOptions("FPS", "LUI_Text_FPS", 5, db.Infotext.Fps, LUI.defaults.profile.Infotext.Fps),
					},
				},
				Gold = {
					name = function() return (db.Infotext.Gold.Enable and "Gold") or "|cff888888Gold|r" end,
					type = "group",
					order = 9,
					args = {
						Header = {
							name = "Gold",
							type = "header",
							order = 1,
						},
						GoldEnable = {
							name = "Enable",
							desc = "Whether you want to show your Gold Amount or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Gold.Enable end,
							set = function()
										db.Infotext.Gold.Enable = not db.Infotext.Gold.Enable
										module:SetGold()
									end,
							order = 2,
						},
						ToonMoney = {
							name = "Server Total",
							desc = "Whether you want your gold display to show your server total gold, or your current toon's gold.",
							type = "toggle",
							disabled = function() return not db.Infotext.Gold.Enable end,
							get = function() return not db.Infotext.Gold.ShowToonMoney end,
							set = function()
									db.Infotext.Gold.ShowToonMoney = not db.Infotext.Gold.ShowToonMoney
									module.Gold:OnEvent()
								end,
							order = 3,
						},
						ColorType = {
							name = "Color By Type",
							desc = "Weather or not to color the coin letters by the type of coin.",
							type = "toggle",
							get = function() return db.Infotext.Gold.ColorType end,
							set = function(self)
								db.Infotext.Gold.ColorType = not db.Infotext.Gold.ColorType
								module.Gold:OnEvent()
							end,
							order = 4,
						},
						GoldPlayerReset = {
							name = "Reset Player",
							desc = "Choose the player you want to clear Gold data for.\n",
							type = "select",
							order = 5,
							values = function()
								local realmPlayerArray = {"ALL"}

								if LUIGold.gold ~= nil then
									if LUIGold.gold[myPlayerRealm] ~= nil then
										for f in pairs(LUIGold.gold[myPlayerRealm]) do
											if f == "Horde" or f == "Alliance" then
												for p, g in pairs(LUIGold.gold[myPlayerRealm][f]) do
													table.insert(realmPlayerArray, p)
												end
											end
										end
									end
								end

								return realmPlayerArray
							end,
							get = function()
								local realmPlayerArray = {"ALL"}

								if LUIGold.gold ~= nil then
									if LUIGold.gold[myPlayerRealm] ~= nil then
										for f in pairs(LUIGold.gold[myPlayerRealm]) do
											if f == "Horde" or f == "Alliance" then
												for p, g in pairs(LUIGold.gold[myPlayerRealm][f]) do
													table.insert(realmPlayerArray, p)
												end
											end
										end
									end
								end

								for k, v in pairs(realmPlayerArray) do
									if v == playerReset then
										return k
									end
								end

								playerReset = "ALL"
								return 1
							end,
							set = function(self, player)
								local realmPlayerArray = {"ALL"}

								if LUIGold.gold ~= nil then
									if LUIGold.gold[myPlayerRealm] ~= nil then
										for f in pairs(LUIGold.gold[myPlayerRealm]) do
											if f == "Horde" or f == "Alliance" then
												for p,g in pairs(LUIGold.gold[myPlayerRealm][f]) do
													table.insert(realmPlayerArray, p)
												end
											end
										end
									end
								end

								for i = 1, #realmPlayerArray do
									if i == player and realmPlayerArray[i] ~= "" then
										playerReset = realmPlayerArray[i]
										return
									end
								end
							end,
						},
						GoldReset = {
							name = "Reset",
							type = "execute",
							order = 6,
							func = function()
								if playerReset == "ALL" then
									module.Gold:ResetGold("ALL")
									return
								end

								if LUIGold.gold ~= nil then
									if LUIGold.gold[myPlayerRealm] ~= nil then
										local breakloop = false
										for f in pairs(LUIGold.gold[myPlayerRealm]) do
											if f == "Horde" or f == "Alliance" then
												for p, g in pairs(LUIGold.gold[myPlayerRealm][f]) do
													if playerReset == p then
														module.Gold:ResetGold(p, f)
														breakloop = true
														break
													end
												end
											end
											if breakloop == true then
												break
											end
										end
									end
								end
							end,
						},
						Position = PostionOptions("Gold", "LUI_Text_Gold", 7, db.Infotext.Gold, LUI.defaults.profile.Infotext.Gold),
						Font = FontOptions("Gold", "LUI_Text_Gold", 8, db.Infotext.Gold, LUI.defaults.profile.Infotext.Gold),
					},
				},
				Guild_Friends = {
					name = "Guild / Friends",
					type = "group",
					order = 10,
					childGroups = "tab",
					args = {
						General = {
							name = "General",
							type = "group",
							order = 1,
							args = {
								header = {
									name = "General",
									type = "header",
									order = 1,
								},
								Settings = {
									name = "Settings",
									type = "group",
									order = 2,
									guiInline = true,
									args = {
										ShowTotal = {
											name = "Show Total",
											desc = "Show total number of Friends and Guildmates.\n\nNote: This may take a few seconds to update.",
											type = "toggle",
											order = 1,
											get = function() return db.Infotext.Guild_Friends.ShowTotal end,
											set = function(self,ShowTotal)
													db.Infotext.Guild_Friends.ShowTotal = ShowTotal
													GuildRoster()
													ShowFriends()
												end,
										},
										ShowHints = {
											name = "Show Hints",
											desc = "Wether you want to show the hints or not.",
											type = "toggle",
											order = 2,
											get = function() return db.Infotext.Guild_Friends.ShowHints end,
											set = function(self,ShowHints)
													db.Infotext.Guild_Friends.ShowHints = ShowHints
												end,
										},
										ClassColoredStatus = {
											name = "Class Colored Status",
											desc = "Color the status of Friends and Guildmates by class color.",
											type = "toggle",
											order = 3,
											get = function() return db.Infotext.Guild_Friends.ClassColoredStatus end,
											set = function(self,ClassColoredStatus)
													db.Infotext.Guild_Friends.ClassColoredStatus = ClassColoredStatus
													local r,g,b = unpack(db.Infotext.Guild_Friends.Color.Status)
													preformatedStatusText = ClassColoredStatus and "%s " or ("|cff%.2x%.2x%.2x%%s|r "):format(r*255,g*255,b*255)
												end,
										},
									},
								},
								Textures = {
									name = "Textures",
									type = "group",
									order = 3,
									guiInline = true,
									args = {
										BGTexture = {
											name = "Background Texture",
											type = "select",
											order = 1,
											dialogControl = "LSM30_Background",
											values = widgetLists.background,
											get = function() return db.Infotext.Guild_Friends.BGTexture end,
											set = function(self, texture)
													db.Infotext.Guild_Friends.BGTexture = texture
													_G["LUI Guild/Friends"]:SetBackdrop({
															bgFile = LSM:Fetch("background", db.Infotext.Guild_Friends.BGTexture),
															edgeFile = LSM:Fetch("border", db.Infotext.Guild_Friends.BorderTexture),
															edgeSize=14, tile = false, tileSize=0,
															insets = { left=0, right=0, top=0, bottom=0 }})
												end,
										},
										BorderTexture = {
											name = "Border Texture",
											type = "select",
											order = 2,
											dialogControl = "LSM30_Border",
											values = widgetLists.border,
											get = function() return db.Infotext.Guild_Friends.BorderTexture end,
											set = function(self, texture)
													db.Infotext.Guild_Friends.BorderTexture = texture
													_G["LUI Guild/Friends"]:SetBackdrop({
															bgFile = LSM:Fetch("background", db.Infotext.Guild_Friends.BGTexture),
															edgeFile = LSM:Fetch("border", db.Infotext.Guild_Friends.BorderTexture),
															edgeSize=14, tile = false, tileSize=0,
															insets = { left=0, right=0, top=0, bottom=0 }})
												end,
										},
									},
								},
							},
						},
						Guild = {
							name = "Guild",
							type = "group",
							order = 2,
							args = {
								header92g = {
									name = "Guild",
									type = "header",
									order = 1,
								},
								GuildEnable = {
									name = "Enable",
									desc = "Whether you want to show your Guild Status or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Infotext.Guild_Friends.Guild.Enable end,
									set = function()
												db.Infotext.Guild_Friends.Guild.Enable = not db.Infotext.Guild_Friends.Guild.Enable
												StaticPopup_Show("RELOAD_UI")
											end,
									order = 2,
								},
								GuildX = {
									name = "X Value",
									desc = "X Value for your Guild Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.X,
									type = "input",
									disabled = function() return not db.Infotext.Guild_Friends.Guild.Enable end,
									get = function() return tostring(db.Infotext.Guild_Friends.Guild.X) end,
									set = function(self,GuildX)
												if GuildX == nil or GuildX == "" then
													GuildX = "0"
												end

												db.Infotext.Guild_Friends.Guild.X = tonumber(GuildX)
												LUI_Guild:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
											end,
									order = 3,
								},
								GuildY = {
									name = "Y Value",
									desc = "Y Value for your Guild Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Y,
									type = "input",
									disabled = function() return not db.Infotext.Guild_Friends.Guild.Enable end,
									get = function() return tostring(db.Infotext.Guild_Friends.Guild.Y) end,
									set = function(self, GuildY)
												if GuildY == nil or GuildY == "" then
													GuildY = "0"
												end

												db.Infotext.Guild_Friends.Guild.Y = tonumber(GuildY)
												LUI_Guild:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
											end,
									order = 4,
								},
								TextSettings = {
									name = "Font Settings",
									type = "group",
									disabled = function() return not db.Infotext.Guild_Friends.Guild.Enable end,
									order = 5,
									guiInline = true,
									args = {
										FontSize = {
											name = "Size",
											desc = "Choose your Guild Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Size,
											type = "range",
											min = 1,
											max = 40,
											step = 1,
											get = function() return db.Infotext.Guild_Friends.Guild.Size end,
											set = function(_, FontSize)
													db.Infotext.Guild_Friends.Guild.Size = FontSize
													LUI_Guild:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Guild.Font), FontSize, db.Infotext.Guild_Friends.Guild.Outline)
												end,
											order = 1,
										},
										Color = {
											name = "Color",
											desc = "Choose an individual Guild Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Color.b.."\na = "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Color.a,
											type = "color",
											hasAlpha = true,
											get = function() return db.Infotext.Guild_Friends.Guild.Color.r, db.Infotext.Guild_Friends.Guild.Color.g, db.Infotext.Guild_Friends.Guild.Color.b, db.Infotext.Guild_Friends.Guild.Color.a end,
											set = function(_, r, g, b, a)
													db.Infotext.Guild_Friends.Guild.Color.r = r
													db.Infotext.Guild_Friends.Guild.Color.g = g
													db.Infotext.Guild_Friends.Guild.Color.b = b
													db.Infotext.Guild_Friends.Guild.Color.a = a

													LUI_Guild:SetTextColor(r, g, b, a)
												end,
											order = 2,
										},
										Font = {
											name = "Font",
											desc = "Choose the Font for your Guild Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Font,
											type = "select",
											dialogControl = "LSM30_Font",
											values = widgetLists.font,
											get = function() return db.Infotext.Guild_Friends.Guild.Font end,
											set = function(self, Font)
													db.Infotext.Guild_Friends.Guild.Font = Font
													LUI_Guild:SetFont(LSM:Fetch("font", Font), db.Infotext.Guild_Friends.Guild.Size, db.Infotext.Guild_Friends.Guild.Outline)
												end,
											order = 3,
										},
										FontFlag = {
											name = "Font Flag",
											desc = "Choose the Font Flag for your Guild Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Guild.Outline,
											type = "select",
											values = fontflags,
											get = function()
													for k, v in pairs(fontflags) do
														if db.Infotext.Guild_Friends.Guild.Outline == v then
															return k
														end
													end
												end,
											set = function(self, FontFlag)
													db.Infotext.Guild_Friends.Guild.Outline = fontflags[FontFlag]
													LUI_Guild:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Guild.Font), db.Infotext.Guild_Friends.Guild.Size, db.Infotext.Guild_Friends.Guild.Outline)
												end,
											order = 4,
										},
									},
								},
							},
						},
						Friends = {
							name = "Friends",
							type = "group",
							order = 3,
							args = {
								header92f = {
									name = "Friends",
									type = "header",
									order = 1,
								},
								FriendsEnable = {
									name = "Enable",
									desc = "Whether you want to show your Friends Status or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Infotext.Guild_Friends.Friends.Enable end,
									set = function()
												db.Infotext.Guild_Friends.Friends.Enable = not db.Infotext.Guild_Friends.Friends.Enable
												StaticPopup_Show("RELOAD_UI")
											end,
									order = 2,
								},
								FriendsX = {
									name = "X Value",
									desc = "X Value for your Friends Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.X,
									type = "input",
									disabled = function() return not db.Infotext.Guild_Friends.Friends.Enable end,
									get = function() return tostring(db.Infotext.Guild_Friends.Friends.X) end,
									set = function(self,FriendsX)
												if FriendsX == nil or FriendsX == "" then
													FriendsX = "0"
												end

												db.Infotext.Guild_Friends.Friends.X = tonumber(FriendsX)
												LUI_Friends:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
											end,
									order = 3,
								},
								FriendsY = {
									name = "Y Value",
									desc = "Y Value for your Friends Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Y,
									type = "input",
									disabled = function() return not db.Infotext.Guild_Friends.Friends.Enable end,
									get = function() return tostring(db.Infotext.Guild_Friends.Friends.Y) end,
									set = function(self,FriendsY)
												if FriendsY == nil or FriendsY == "" then
													FriendsY = "0"
												end

												db.Infotext.Guild_Friends.Friends.Y = tonumber(FriendsY)
												LUI_Friends:SetPoint("RIGHT", LUI_Infos_TopRight, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
											end,
									order = 4,
								},
								TextSettings = {
									name = "Font Settings",
									type = "group",
									disabled = function() return not db.Infotext.Guild_Friends.Friends.Enable end,
									order = 5,
									guiInline = true,
									args = {
										FontSize = {
											name = "Size",
											desc = "Choose your Friends Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Size,
											type = "range",
											min = 1,
											max = 40,
											step = 1,
											get = function() return db.Infotext.Guild_Friends.Friends.Size end,
											set = function(_, FontSize)
													db.Infotext.Guild_Friends.Friends.Size = FontSize
													LUI_Friends:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Friends.Font), FontSize, db.Infotext.Guild_Friends.Friends.Outline)
												end,
											order = 1,
										},
										Color = {
											name = "Color",
											desc = "Choose an individual Friends Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Color.b.."\na = "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Color.a,
											type = "color",
											hasAlpha = true,
											get = function() return db.Infotext.Guild_Friends.Friends.Color.r, db.Infotext.Guild_Friends.Friends.Color.g, db.Infotext.Guild_Friends.Friends.Color.b, db.Infotext.Guild_Friends.Friends.Color.a end,
											set = function(_, r, g, b, a)
													db.Infotext.Guild_Friends.Friends.Color.r = r
													db.Infotext.Guild_Friends.Friends.Color.g = g
													db.Infotext.Guild_Friends.Friends.Color.b = b
													db.Infotext.Guild_Friends.Friends.Color.a = a

													LUI_Friends:SetTextColor(r, g, b, a)
												end,
											order = 2,
										},
										Font = {
											name = "Font",
											desc = "Choose the Font for your Friends Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Font,
											type = "select",
											dialogControl = "LSM30_Font",
											values = widgetLists.font,
											get = function() return db.Infotext.Guild_Friends.Friends.Font end,
											set = function(self, Font)
													db.Infotext.Guild_Friends.Friends.Font = Font
													LUI_Friends:SetFont(LSM:Fetch("font", Font), db.Infotext.Guild_Friends.Friends.Size, db.Infotext.Guild_Friends.Friends.Outline)
												end,
											order = 3,
										},
										FontFlag = {
											name = "Font Flag",
											desc = "Choose the Font Flag for your Friends Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Guild_Friends.Friends.Outline,
											type = "select",
											values = fontflags,
											get = function()
													for k, v in pairs(fontflags) do
														if db.Infotext.Guild_Friends.Friends.Outline == v then
															return k
														end
													end
												end,
											set = function(self, FontFlag)
													db.Infotext.Guild_Friends.Friends.Outline = fontflags[FontFlag]
													LUI_Friends:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Friends.Font), db.Infotext.Guild_Friends.Friends.Size, db.Infotext.Guild_Friends.Friends.Outline)
												end,
											order = 4,
										},
									},
								},
							},
						},
						Colors = {
							name = "Colors",
							type = "group",
							order = 4,
							args = {
								header = {
									name = "Colors",
									type = "header",
									order = 1,
								},
								note = {
									name = "Some colors will not be changed until the UI has been reloaded.",
									type = "description",
									order = 45,
								},
								Reset = {
									name = "Reset Colors",
									type = "execute",
									order = 50,
									func = function(self, reset)
											db.Infotext.Guild_Friends.Color = defaults.Info.Guild_Friends.Color
											StaticPopup_Show("COLORS_RESET")
										end,
								},
							},
						},
					},
				},
				Instance = {
					name = function() return (db.Infotext.Instance.Enable and "Instance Info") or "|cff888888Instance Info|r" end,
					type = "group",
					order = 11,
					args = {
						Header = {
							name = "Instance",
							type = "header",
							order = 1,
						},
						InstanceEnable = {
							name = "Enable",
							desc = "Whether you want to show your Instance Info or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Instance.Enable end,
							set = function()
										db.Infotext.Instance.Enable = not db.Infotext.Instance.Enable
										module:SetInstance()
									end,
							order = 2,
						},
						Position = PostionOptions("Instance", "LUI_Text_Instance", 3, db.Infotext.Instance, LUI.defaults.profile.Infotext.Instance),
						Font = FontOptions("Instance", "LUI_Text_Instance", 4, db.Infotext.Instance, LUI.defaults.profile.Infotext.Instance),
					},
				},
				MemoryUsage = {
					name = function() return (db.Infotext.Memory.Enable and "Memory Usage") or "|cff888888Memory Usage|r" end,
					type = "group",
					order = 12,
					args = {
						Header = {
							name = "Memory Usage",
							type = "header",
							order = 1,
						},
						MemoryEnable = {
							name = "Enable",
							desc = "Whether you want to show your Memory Usage or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Memory.Enable end,
							set = function()
										db.Infotext.Memory.Enable = not db.Infotext.Memory.Enable
										module:SetMemoryUsage()
									end,
							order = 2,
						},
						Position = PostionOptions("Memory", "LUI_Text_Memory", 3, db.Infotext.Memory, LUI.defaults.profile.Infotext.Memory),
						Font = FontOptions("Memory", "LUI_Text_Memory", 4, db.Infotext.Memory, LUI.defaults.profile.Infotext.Memory),
					},
				},
			},
		},
	}

	local colorOptions = {"Background", "Border", "Note", "OfficerNote", "MotD", "Broadcast", "Title", "Rank", "Realm", "Status", "OrderA", "ContestedZone", "FriendlyZone", "EnemyZone"}
	local colorDesc = {
		Background = "Background Color of the Guild and Friends List frames.\n\nNote: most textures will ignore changing this color.",
		Border = "Border Color of the Guild and Friends List frames.\n\nNote: most textures will ignore changing this color.",
		Note = "Color of Friend Notes and Guild Notes.",
		OfficerNote = "Color of Guild Officer Notes.",
		MotD = "Color of the Guild Message of the Day.",
		Broadcast = "Color of your Real ID friend's broadcasts",
		Title = "Color of the Title of a group. (ex: Broadcast, MotD)",
		Rank = "Color of players Guild Ranks.",
		Realm = "Color of the realm your Real ID friends are on.",
		Status = "Color of status text. (ex: Away, Busy)",
		OrderA = "Color of the highlight used to show what the list is being sorted by.",
		ContestedZone = "Color of neutral zone names.",
		FriendlyZone = "Color of "..(horde and "Horde" or "Alliance").." zone names.",
		EnemyZone = "Color of "..(horde and "Alliance" or "Horde").." zone names.",
	}
	for k, v in pairs(colorOptions) do
		local alpha = false
		if #db.Infotext.Guild_Friends.Color[v] == 4 then
			alpha = true
		end
		options.Infotext.args.Guild_Friends.args.Colors.args[v] = {
			name = v,
			desc = colorDesc[v],
			type = "color",
			order = k+1,
			hasAlpha = alpha,
			get = function()
					return unpack(db.Infotext.Guild_Friends.Color[v])
				end,
			set = function(self, r, g, b, a)
					if alpha == true then
						db.Infotext.Guild_Friends.Color[v] = {r, g, b, a}
					else
						db.Infotext.Guild_Friends.Color[v] = {r, g, b}
					end
				end,
		}
	end

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
	self:SetDataTextFrames()
	self:SetBags()
	self:SetClock()
	self:SetCurrency()
	self:SetDPS()
	self:SetDualSpec()
	self:SetDurability()
	self:SetFPS()
	self:SetGold()
	self:SetGuild_Friends()
	self:SetInstance()
	self:SetMemoryUsage()
end

function module:OnDisable()
	local frameList = {"LUI_Infos_TopLeft", "LUI_Infos_TopRight"}
	LUI:ClearFrames(frameList)
end
