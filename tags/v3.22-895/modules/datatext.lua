--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: datatext.lua
	Description: Provides LUI datatexts which hold relative info.
	Version....: 1.9
	Rev Date...: 16/07/2011 [dd/mm/yyyy]

	Edits:
		v1.8: Hix
		v1.9: Zista
]]

if false then return end -- change false to true if working with new infotext module

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Infotext", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db, dbd

local CLASS_BUTTONS = CLASS_ICON_TCOORDS
local BNET_CLIENT_WOW = BNET_CLIENT_WOW

------------------------------------------------------
-- / LOCAL VARIABLES / --
------------------------------------------------------

local myPlayerName = UnitName("player")
local myPlayerFaction, localeFaction = UnitFactionGroup("player")
local otherFaction = myPlayerFaction == "Horde" and "Alliance" or "Horde"
local myPlayerRealm = GetRealmName()

local InfoStats = {}

local goldPlayerArray = {["ALL"] = "ALL"}
local guildEntries, friendEntries, totalFriends, onlineFriends = {}, {}, 0, 0

------------------------------------------------------
-- / LOCAL FUNCTIONS / --
------------------------------------------------------

local function SetInfoPanel(stat)
	if type(stat) == "string" then stat = InfoStats[stat] end
	if not stat then return end

	local parent = _G["LUI_Infos_" .. db[stat.db].InfoPanel.Vertical .. db[stat.db].InfoPanel.Horizontal]

	stat.text:ClearAllPoints()
	stat.text:SetPoint(db[stat.db].InfoPanel.Vertical, parent, db[stat.db].InfoPanel.Vertical, db[stat.db].X, db[stat.db].Y)

	stat:SetParent(parent)
	stat:ClearAllPoints()
	stat:SetAllPoints(stat.text)
end

local function NewText(stat)
	if not stat then return end
	if stat.text then return stat.text end

	local fs = stat:CreateFontString(stat:GetName().."_Text", "OVERLAY")
	fs:SetJustifyH("LEFT")
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(1.25, -1.25)

	stat.text = fs

	SetInfoPanel(stat)
end

local function SetFontSettings(stat)
	if type(stat) == "string" then stat = InfoStats[stat] end
	if not stat then return end

	stat.text:SetFont(Media:Fetch("font", db[stat.db].Font), db[stat.db].FontSize, db[stat.db].Outline)
	local color = db[stat.db].Color
	stat.text:SetTextColor(color.r, color.g, color.b, color.a)
end

local function NewIcon(stat, tex)
	if not stat then return end
	if stat.icon then return stat.icon end

	local icon = CreateFrame("Button", stat:GetName().."Icon", stat)
	icon:SetPoint("RIGHT", stat.text, "LEFT", -2, 0)
	icon:SetWidth(15)
	icon:SetHeight(15)
	icon:SetFrameStrata("HIGH")
	--icon:SetBackdrop({bgFile = tex or [[Interface\Icons\Spell_Nature_MoonKey]], edgeFile = nil, tile = false, edgeSize = 0, insets = {top = 0, bottom, 0, left = 0, right = 0}})
	icon:Show()

	stat.icon = icon
end

local function NewStat(statDB)
	if InfoStats[statDB] then return InfoStats[statDB] end
	if db[statDB] and not db[statDB].Enable then return {Created = false} end

	local stat = CreateFrame("Frame", "LUI_Info_" .. statDB, LUI_Infos_TopRight)
	stat.db = statDB
	stat:EnableMouse(true)

	stat.Enable = function(stat)
		if stat.OnUpdate then
			stat.dt = 0
			stat:SetScript("OnUpdate", stat.OnUpdate)
			stat:OnUpdate(100)
		end
		if stat.Events then
			for i=1, #stat.Events do
				stat:RegisterEvent(stat.Events[i])
			end
			stat:SetScript("OnEvent", (type(stat.OnEvent) == "function" and stat.OnEvent or (function(self, event, ...) self[event](self, ...) end)))
		end
		if stat.OnEnter then
			stat:SetScript("OnEnter", stat.OnEnter)
		end
		if stat.OnLeave then
			stat:SetScript("OnLeave", stat.OnLeave)
		end
		if stat.OnClick then
			stat:SetScript("OnMouseDown", stat.OnClick)
		end
		if stat.OnEnable then stat:OnEnable() end
	end
	if db[statDB] then
		NewText(stat)
		SetFontSettings(stat)
	end
	InfoStats[statDB] = stat
	return stat
end


local function SetInfoTextFrames()
	if not LUI_Infos_TopLeft then
		LUI:CreateMeAFrame("FRAME","LUI_Infos_TopLeft",UIParent,1,1,1,"HIGH",0,"TOPLEFT",UIParent,"TOPLEFT",0,-1,1)
	end
	LUI_Infos_TopLeft:SetAlpha(1)
	LUI_Infos_TopLeft:Show()
	RegisterStateDriver(LUI_Infos_TopLeft, "visibility", "[petbattle] hide; show")

	if not LUI_Infos_TopRight then
		LUI:CreateMeAFrame("FRAME","LUI_Infos_TopRight",UIParent,1,1,1,"HIGH",0,"TOPRIGHT",UIParent,"TOPRIGHT",0,-1,1)
	end
	LUI_Infos_TopRight:SetAlpha(1)
	LUI_Infos_TopRight:Show()
	RegisterStateDriver(LUI_Infos_TopRight, "visibility", "[petbattle] hide; show")

	if not LUI_Infos_BottomLeft then
		LUI:CreateMeAFrame("FRAME","LUI_Infos_BottomLeft",UIParent,1,1,1,"HIGH",0,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,4,1)
	end
	LUI_Infos_BottomLeft:SetAlpha(1)
	LUI_Infos_BottomLeft:Show()
	RegisterStateDriver(LUI_Infos_BottomLeft, "visibility", "[petbattle] hide; show")

	if not LUI_Infos_BottomRight then
		LUI:CreateMeAFrame("FRAME","LUI_Infos_BottomRight",UIParent,1,1,1,"HIGH",0,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,4,1)
	end
	LUI_Infos_BottomRight:SetAlpha(1)
	LUI_Infos_BottomRight:Show()
	RegisterStateDriver(LUI_Infos_BottomRight, "visibility", "[petbattle] hide; show")
end

local function CombatTips()
	return ((not InCombatLockdown()) or (not db.CombatLock))
end

local function UpdateTooltip(frame, func, ...)
	if frame:IsMouseOver() and GameTooltip:GetOwner() == frame then
		if func == nil then func = "OnEnter" end
		if type(func) == "function" then
			func(...)
		elseif type(func) == "string" and type(frame[func]) == "function" then
			if select("#", ...) == 0 then
				frame[func](frame)
			else
				frame[func](...)
			end
		end
	end
end

local function isTop(frame)
	if frame.db and db[frame.db] then
		return (db[frame.db].InfoPanel.Vertical == "Top")
	else
		return (select(2, frame:GetCenter()) > UIParent:GetHeight() / 2)
	end
end

local function getOwnerAnchor(frame)
	return (isTop(frame) and "ANCHOR_BOTTOM" or "ANCHOR_TOP")
end





------------------------------------------------------
-- / BAGS / --
------------------------------------------------------

function module:SetBags()
	local stat = NewStat("Bags")

	if db.Bags.Enable and not stat.Created then
		-- Localized functions
		local GetContainerNumFreeSlots, GetContainerNumSlots = GetContainerNumFreeSlots, GetContainerNumSlots

		local bagTypes = {
			[0x0000] = "Normal", -- 0
			[0x0001] = "Quiver", -- 1
			[0x0002] = "Ammo Pouch", -- 2
			[0x0004] = "Soul Bag", -- 4
			[0x0008] = "Leatherworking Bag", -- 8
			[0x0010] = "Inscription Bag", -- 16
			[0x0020] = "Herb Bag", -- 32
			[0x0040] = "Enchanting Bag", -- 64
			[0x0080] = "Engineering Bag", -- 128
			[0x0100] = "Keyring", -- 256
			[0x0200] = "Gem Bag", -- 512
			[0x0400] = "Mining Bag", -- 1024
			-- [0x0800] = "", -- 2048
			[0x1000] = "Vanity Pets", -- 4096
			-- [0x2000] = "", -- 8192
			-- [0x4000] = "", -- 16384
			[0x8000] = "Tackle Box", -- 32768
		}

		-- Event functions
		stat.Events = {"BAG_UPDATE"}

		stat.BAG_UPDATE = function(self, bagID) -- Change occured to items in player inventory
			local free, total, used = 0, 0, 0

			for i = 0, NUM_BAG_SLOTS do
				free, total = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i)
			end

			used = total - free
			self.text:SetFormattedText("Bags: %d/%d", used, total)

			-- Update tooltip if open.
			UpdateTooltip(self)
		end

		-- Script functions
		stat.OnEnable = stat.BAG_UPDATE

		stat.OnClick = function() -- Toggle bags
			OpenAllBags() -- ToggleAllBags() may be a better function
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				local freeslots, totalslots = {}, {}
				for i=0, NUM_BAG_SLOTS do
					local free, bagType = GetContainerNumFreeSlots(i)
					local total = GetContainerNumSlots(i)
					if bagType then
						freeslots[bagType] = (freeslots[bagType] and freeslots[bagType] + free) or free
						totalslots[bagType] = (totalslots[bagType] and totalslots[bagType] + total) or total
					end
				end

				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Bags:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				for k, v in pairs(freeslots) do
					GameTooltip:AddDoubleLine((bagTypes[k] or "Unknown")..":", totalslots[k]-v.."/"..totalslots[k], 1, 1, 1, 1, 1, 1)
				end
				GameTooltip:AddLine(" ")

				GameTooltip:AddLine("Hint: Click to open Bags.", 0.0, 1.0, 0.0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / CLOCK / --
------------------------------------------------------

function module:SetClock()
	local stat = NewStat("Clock")

	if db.Clock.Enable and not stat.Created then
		-- Localized functions
		local tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo = tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo
		local GetNumSavedInstances, GetSavedInstanceInfo = GetNumSavedInstances, GetSavedInstanceInfo
		local gsub, format, floor, strtrim, strmatch = gsub, format, floor, strtrim, strmatch

		local instanceInfo, guildParty = nil, ""
		local invitesPending = false

		-- Event functions
		stat.Events = {"CALENDAR_UPDATE_PENDING_INVITES", "PLAYER_ENTERING_WORLD"}
		-- , "UPDATE_24HOUR", "UPDATE_LOCALTIME"

		stat.CALENDAR_UPDATE_PENDING_INVITES = function(self) -- A change to number of pending invites for calendar events occurred
			invitesPending = GameTimeFrame and (GameTimeFrame.pendingCalendarInvites > 0) or false
		end


		stat.GUILD_PARTY_STATE_UPDATED = function(self) -- Number of guildmates in group changed
			if InGuildParty() then
				guildParty = " |cff66c7ffG"
			else
				guildParty = ""
			end
		end

		stat.PLAYER_DIFFICULTY_CHANGED = function(self) -- Instance difficulty changed
			local inInstance, instanceType = IsInInstance()
			if inInstance then
				local _,_, instanceDifficulty,_, maxPlayers, dynamicMode, isDynamic, _, instanceGroupSize = GetInstanceInfo()
				if (instanceType == "raid" or instanceType == "party") then
					if instanceDifficulty == 14 then
						instanceInfo = instanceGroupSize.." |cffffcc00N" -- Flexible renamed Normal in 6.0
					elseif instanceDifficulty == 7 or instanceDifficulty == 17 then
						instanceInfo = maxPlayers.." |cff00ccffL"        -- Looking for Raid
					elseif instanceDifficulty == 1 or instanceDifficulty == 3 or instanceDifficulty == 4 or instanceDifficulty == 12 then
						instanceInfo = maxPlayers.." |cff00ff00N"        -- Legacy Normal
					elseif instanceDifficulty == 15 then
						instanceInfo = maxPlayers.." |cff00ff00H"        -- Normal renamed Heroic in 6.0
					elseif instanceDifficulty == 16 or instanceDifficulty == 23 then
						instanceInfo = maxPlayers.." |cffff0000M"        -- Heroic renamed Mythic in 6.0
					elseif instanceDifficulty == 8 then
						instanceInfo = maxPlayers.." |cffff0000C"        -- Challenge Mode
					elseif instanceDifficulty == 24 then
						instanceInfo = maxPlayers.." |cff00ff00T"        -- Timewalking Dungeon
					else
						instanceInfo = maxPlayers.." |cffff0000H"        -- Legacy Heroic
					end
				else
					instanceInfo = nil
				end
			else
				instanceInfo = nil
			end
		end

		stat.INSTANCE_GROUP_SIZE_CHANGED = stat.PLAYER_DIFFICULTY_CHANGED -- Flexible raid size changed (I hope)

		stat.PLAYER_ENTERING_WORLD = function(self) -- Zoning in/out or logging in
			if db.Clock.ShowInstanceDifficulty then
				self:PLAYER_DIFFICULTY_CHANGED()
			end
		end

		stat.UPDATE_24HOUR = function(self)
			db.Clock.Time24 = not db.Clock.Time24
		end

		stat.UPDATE_LOCALTIME = function(self)
			db.Clock.LocalTime = not db.Clock.LocalTime
		end

		-- Script functions
		stat.OnEnable = function(self)
			if db.Clock.ShowInstanceDifficulty then
				self:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
				self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
				self:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
				self:GUILD_PARTY_STATE_UPDATED()
			else
				self:UnregisterEvent("GUILD_PARTY_STATE_UPDATED")
				self:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED")
				self:UnregisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
				instanceInfo, guildParty = nil, ""
			end

			if not module:IsHooked(GameTimeFrame, "OnClick") then
				module:SecureHookScript(GameTimeFrame, "OnClick", stat.CALENDAR_UPDATE_PENDING_INVITES) -- hook the OnClick function of the GameTimeFrame to update the pending invites
			end
			if not module:IsHooked(TimeManagerMilitaryTimeCheck, "OnClick") then
				module:SecureHookScript(TimeManagerMilitaryTimeCheck, "OnClick", stat.UPDATE_24HOUR)
			end
			if not module:IsHooked(TimeManagerLocalTimeCheck, "OnClick") then
				module:SecureHookScript(TimeManagerLocalTimeCheck, "OnClick", stat.UPDATE_LOCALTIME)
			end
			self:CALENDAR_UPDATE_PENDING_INVITES()

			self:PLAYER_ENTERING_WORLD()
		end

		stat.OnDisable = function(self)
			module:Unhook(GameTimeFrame, "OnClick")
		end

		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime
			if self.dt > 1 then
				self.dt = 0

				if (invitesPending) then
					self.text:SetText("(Inv. pending)")
				else
					local Hr, Min, PM
					if db.Clock.LocalTime == true then
						Hr, Min = tonumber(date("%H")), date("%M")
					else
						Hr, Min = GetGameTime()
					end
					PM = ((Hr >= 12) and " pm" or " am")

					if not db.Clock.Time24 then
						if Hr > 12 then
							Hr = Hr - 12
						elseif Hr == 0 then
							Hr = 12
						end
					end

					-- time
					local text = format("%d:%.2d%s", Hr, Min, (db.Clock.Time24 and "" or PM))
					-- instance info
					local text2 = ((db.Clock.ShowInstanceDifficulty and instanceInfo) and (" ("..instanceInfo..guildParty.."|r)") or "")

					self.text:SetText(text..text2)
				end

				-- update tooltip if open
				UpdateTooltip(self)
			end
		end

		stat.OnClick = function(self, button)
			if button == "RightButton" then -- Toggle TimeManagerFrame
				TimeManager_Toggle()
				if (db.Clock.Time24) then -- check 24 Hour Mode
					TimeManagerMilitaryTimeCheck:SetChecked(true)
				else
					TimeManagerMilitaryTimeCheck:SetChecked(false)
				end
				if (db.Clock.LocalTime) then -- check Local Time
					TimeManagerLocalTimeCheck:SetChecked(true)
				else
					TimeManagerLocalTimeCheck:SetChecked(false)
				end
			else -- Toggle CalendarFrame
				GameTimeFrame:Click() -- using just :Click() wont fire the hook
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Time:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				local Hr, Min, PM
				if (invitesPending) then -- Show main time in tooltip if invites are pending
					if db.Clock.LocalTime == true then
						Hr, Min = tonumber(date("%H")), date("%M")
					else
						Hr, Min = GetGameTime()
						Min = Min < 10 and "0"..Min or Min
					end
					PM = ((Hr >= 12) and " pm" or " am")

					if not db.Clock.Time24 then
						if Hr > 12 then
							Hr = Hr - 12
						elseif Hr == 0 then
							Hr = 12
						end
					end

					local text1 = (db.Clock.LocalTime and "Local Time:" or "Server Time:")
					local text2 = (Hr..":"..Min..(not db.Clock.Time24 and PM or ""))

					GameTooltip:AddDoubleLine(text1, text2)
				end

				-- Show alternate time in tooltip
				if db.Clock.LocalTime == true then
					Hr, Min = GetGameTime()
					Min = Min < 10 and "0"..Min or Min
				else
					Hr, Min = tonumber(date("%H")), date("%M")
				end
				PM = ((Hr >= 12) and " pm" or " am")

				if not db.Clock.Time24 then
					if Hr > 12 then
						Hr = Hr - 12
					elseif Hr == 0 then
						Hr = 12
					end
				end

				local text1 = (db.Clock.LocalTime and "Server Time:" or "Local Time:")
				local text2 = (Hr..":"..Min..(not db.Clock.Time24 and PM or ""))

				GameTooltip:AddDoubleLine(text1, text2)

				-- Saved raid info
				local function formatTime(sec)
					local d, h, m, s = ChatFrame_TimeBreakDown(floor(sec))
					local str = gsub(gsub(format(" %dd %dh %dm "..((d==0 and h==0) and "%ds" or ""), d, h, m, s), " 0[dhms]", " "), "%s+", " ")
					local str = strtrim(gsub(str, "([dhms])", {d = "d", h = "h", m = "m", s = "s"}), " ")
					return strmatch(str, "^%s*$") and "0"..("s") or str
				end

				local oneraid
				for i = 1, GetNumSavedInstances() do
					local name,_, reset, difficulty, locked, extended,_, isRaid, maxPlayers = GetSavedInstanceInfo(i)
					if isRaid and (locked or extended) then
						local tr, tg, tb, diff

						if not oneraid then
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine("Saved Raid(s) :")
							oneraid = true
						end

						if extended then
							tr, tg, tb = 0.3, 1, 0.3
						else
							tr, tg, tb = 1, 1, 1
						end

						if difficulty == 16 or difficulty == 23 then
							diff = "M"
						elseif difficulty == 2 or difficulty == 5 or difficulty == 6 or difficulty == 11 or difficulty == 15 then
							diff = "H"
						elseif difficulty == 7 or difficulty == 17 then
							diff = "L"
						else
							diff = "N"
						end
						GameTooltip:AddDoubleLine(format("%s |cffaaaaaa(%s%s)", name, maxPlayers, diff), formatTime(reset), 1, 1, 1, tr, tg, tb)
					end
				end

				-- World Bosses
				for i = 1, GetNumSavedWorldBosses() do
					if not oneraid then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Saved Raid(s) :")
						oneraid = true
					end

					local name, _, reset = GetSavedWorldBossInfo(i)
					GameTooltip:AddDoubleLine(format("%s |cffaaaaaa(%s)", name, RAID_INFO_WORLD_BOSS), formatTime(reset), 1,1,1, 1,1,1)
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint:\n- Left-Click for Calendar Frame.\n- Right-Click for Time Manager Frame.", 0, 1, 0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / CURRENCY / --
------------------------------------------------------

function module:SetCurrency()
	local stat = NewStat("Currency")

	if db.Currency.Enable and not stat.Created then
		NewIcon(stat)

		local CurrencyList
		stat.Currencies = function(self)
			if CurrencyList then return CurrencyList end

			local CurrencyList = {[0] = "None",}
			for i=1, 2048 do
				local n, _,_,_,_,_,d = GetCurrencyInfo(i)
				if n ~= "" and d then
					CurrencyList[i] = n
				end
			end
			return CurrencyList
		end

		-- Events
		stat.Events = { "CURRENCY_DISPLAY_UPDATE" }

		-- Script functions
		local factionTex
		if UnitFactionGroup("player") == "Neutral" then factionTex = LUI.blank
		else factionTex = [[Interface\PVPFrame\PVP-Currency-]] .. UnitFactionGroup("player")
		end
		stat.OnEnable = function(self)
			local tex = factionTex
			self.icon:SetBackdrop({bgFile = tex, edgeFile = nil, tile = false, edgeSize = 0, insets = {top = 0, right = 0, bottom = 0, left = 0}})
			self.text:SetText("Currency")
			self:CURRENCY_DISPLAY_UPDATE()
		end

		stat.OnClick = function(self, button)
			if button == "RightButton" then
				LUI:Open()
				LibStub("AceConfigDialog-3.0"):SelectGroup(addonname, module:GetName(), "Currency")
			else -- Toggle CurrencyFrame
				ToggleCharacter("TokenFrame")
			end
		end

		stat.CURRENCY_DISPLAY_UPDATE = function (self)
			if db.Currency.Display == 0 then
				self.text:SetText("Currency")
				return
			end

			local name, count = GetCurrencyInfo(db.Currency.Display)
			name = name:sub(1, db.Currency.DisplayLimit)
			name = (#name > 0 and name..":") or name
			self.text:SetFormattedText("%s %d", name, count)
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Currency:", 0.4, 0.78, 1)

				for i = 1, GetCurrencyListSize() do
					local name, isHeader, _, _, _, count = GetCurrencyListInfo(i)
					if isHeader then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(name)
					elseif name then
						if count and count ~= 0 then
							GameTooltip:AddDoubleLine(name, count, 1,1,1, 1,1,1)
						else
							GameTooltip:AddDoubleLine(name, "--", 1,1,1, 1,1,1)
						end
					end
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint:", 0, 1, 0)
				GameTooltip:AddLine("- Left Click to open Currency frame.", 0, 1, 0)
				GameTooltip:AddLine("- Right Click to open LUI Currency Options.", 0, 1, 0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / DUALSPEC / --
------------------------------------------------------

function module:SetDualSpec()
	local stat = NewStat("DualSpec")

	if db.DualSpec.Enable and not stat.Created then
		NewIcon(stat)
		stat.icon:SetScript("OnMouseDown", function(self, button) -- Toggle Specialization
			if not PlayerTalentFrame then
				LoadAddOn("Blizzard_TalentUI")
			end

			if PlayerTalentFrame and PlayerTalentFrame:IsShown() and (PanelTemplates_GetSelectedTab(PlayerTalentFrame) == 3) then
				HideUIPanel(PlayerTalentFrame)
			else
				PanelTemplates_SetTab(PlayerTalentFrame, 3)
				PlayerTalentFrame_Refresh()
				ShowUIPanel(PlayerTalentFrame)
			end
		end)

		-- Localized functions
		local GetActiveSpecGroup, GetSpecializationInfo, GetSpecialization = GetActiveSpecGroup, GetSpecializationInfo, GetSpecialization
		local tonumber, tostring = tonumber, tostring

		-- Local variables

        local numSpecs = GetNumSpecializations() -- num of specs available
		local specCache = {}
		for i = 1, numSpecs do -- for each spec choice
			if not specCache[i] then
				specCache[i] = {}
				local _, name, _, icon = GetSpecializationInfo(i)
				specCache[i].name = name
				specCache[i].icon = icon

				if not specCache[i].name then
					specCache[i].name = "|cffff0000Talents undefined!|r"
					specCache[i].icon = [[Interface\Icons\Spell_Nature_MoonKey]]
				end
			end
		end
        local switch1, switch2, switch3 = nil, nil, nil -- specs to switch to

		-- Event functions
		stat.Events = (UnitLevel("player") < 10) and {"PLAYER_LEVEL_UP"} or {"PLAYER_TALENT_UPDATE"}

		stat.PLAYER_LEVEL_UP = function(self, level)
			if tonumber(level) >= 10 then
				self:UnregisterEvent("PLAYER_LEVEL_UP")
				self:RegisterEvent("PLAYER_TALENT_UPDATE")
				self.Events = {"PLAYER_TALENT_UPDATE"}

				self.Hidden = false
				self:Show()

				self:PLAYER_TALENT_UPDATE()
			end
		end

		stat.PLAYER_TALENT_UPDATE = function(self)
			--local activeTalentGroup = GetActiveSpecGroup()
			local activeSpec = GetSpecialization()
			local curCache = specCache[activeSpec]
			if not curCache then
				self.text:SetText("|cffff0000Talents unavailable!|r")
				return
			end
			local text = " "..curCache.name

			self.text:SetText(text)
			self.icon:SetNormalTexture(curCache.icon)
			--self.icon:SetBackdrop({bgFile = tostring(curCache.icon), edgeFile = nil, tile = false, edgeSize = 0, insets = {top = 0, right = 0, bottom = 0, left = 0}})

			-- Update tooltip if open
			UpdateTooltip(self)
		end

		-- Script functions
		stat.OnEnable = function(self)
			if UnitLevel("player") < 10 then
				self.text:SetText("|cffff0000Talents Unavailable!|r")
				self.Hidden = true
				self:Hide()
			else
				self:PLAYER_TALENT_UPDATE()
			end
		end

		stat.OnClick = function(self, button)
            --[[
            if IsShiftKeyDown() then -- on shift toggle talent frame, function copied from original
                if PlayerTalentFrame:IsVisible() and (PanelTemplates_GetSelectedTab(PlayerTalentFrame) == 1) then
    				HideUIPanel(PlayerTalentFrame)
    			else
    				PanelTemplates_SetTab(PlayerTalentFrame, 1)
    				PlayerTalentFrame_Refresh()
    				ShowUIPanel(PlayerTalentFrame)
    			end
            ]]-- comment block is original functionality supported via shift click
			if button == "LeftButton" and switch1 then -- switch 1 if valid
                SetSpecialization( switch1 )
            elseif button == "RightButton" and switch2 then -- switch 2
                SetSpecialization( switch2 )
            elseif button == "MiddleButton" and switch3 then -- switch 3
                SetSpecialization( switch3 )
            end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Specialization", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				local activeSpecGroup = GetSpecialization() -- get current spec ID
                switch1, switch2, switch3 = nil, nil, nil -- reset switch vars

				for i = 1, numSpecs do -- loop through all specs
                    if i ~= activeSpecGroup then -- not the active spec, is a switch option
                        if not switch1 then -- switch1 not set yet, use it
                            switch1 = i
                        elseif not switch2 then -- use switch2
                            switch2 = i
                        elseif not switch3 then -- use switch3
                            switch3 = i
                        end
                    end

                    local colorY, colorW = "|cFFFFFF00", "|r" -- text color flags
                    local text = ((( i == activeSpecGroup ) and colorY  or "" ) .. "Spec " .. i .. ":" .. colorW ) -- numerate specs, coloring active
                    local text2 = ((( i == activeSpecGroup ) and colorY  or "" ) .. ( specCache[ i ].name or "None" ) .. colorW ) -- list spec names, coloring active

					GameTooltip:AddDoubleLine(text, text2, 1,1,1, 1,1,1)
				end

				GameTooltip:AddLine(" \nHint:", 0, 1, 0 ) -- hint shows what spec a click will switch to
                GameTooltip:AddLine(
                ( switch1 and "- Left-Click to switch to " .. ( specCache[ switch1 ].name or "Error" ) or "" ) ..
                ( switch2 and ".\n- Right-Click to switch to " .. ( specCache[ switch2 ].name or "Error" ) or "" ) ..
                ( switch3 and ".\n- Middle-Click to switch to " .. ( specCache[ switch3 ].name or "Error" ) or "" ) ..
                --[[ ".\n- Shift-Click to toggle talent frame" .. ]] ".", 0, 1, 0 ) -- original functionality hint commented out
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / DURABILITY / --
------------------------------------------------------

function module:SetDurability()
	local stat = NewStat("Durability")

	if db.Durability.Enable and not stat.Created then
		-- Localized functions
		local GetInventoryItemLink, GetInventoryItemDurability = GetInventoryItemLink, GetInventoryItemDurability
		local sort, floor = sort, floor

		-- Local variables
		local slots = {
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

		-- Event functions
		stat.Events = {"UPDATE_INVENTORY_DURABILITY"}
		stat.UPDATE_INVENTORY_DURABILITY = function(self)
			local total = 0

			for i = 1, #slots do
				if GetInventoryItemLink("player", slots[i][1]) then
					local current, maxVal = GetInventoryItemDurability(slots[i][1])
					if current then
						slots[i][3] = current / maxVal
						total = total + 1
					end
				end
			end

			sort(slots, function(a, b) return a[3] < b[3] end)

			if total > 0 then
				self.text:SetFormattedText("Armor: %d%%", slots[1][3] * 100)
			else
				self.text:SetText("Armor: 100%")
			end

			-- Update tooltip if open
			UpdateTooltip(self)
		end

		-- Script functions
		stat.OnEnable = stat.UPDATE_INVENTORY_DURABILITY

		stat.OnClick = function(self, button) -- Toggle Character PaperDollFrame
			ToggleCharacter("PaperDollFrame")
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Armor:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				for i = 1, #slots do
					if slots[i][3] ~= 1000 then
						local green = slots[i][3] * 2
						local red = 2 - green
						GameTooltip:AddDoubleLine(slots[i][2], floor(slots[i][3] * 100) .. "%", 1,1,1, red,green,0)
					end
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint: Click to open Character Frame.", 0, 1, 0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / FPS & MS / --
------------------------------------------------------

function module:SetFPS()
	local stat = NewStat("FPS")

	if db.FPS.Enable and not stat.Created then
		-- Localized functions
		local GetFramerate, GetNetStats = GetFramerate, GetNetStats
		local floor = floor

		-- Local functions
		local function getFPSColor(fps)
			local green = fps / 60 * 2
			local red = 2 - green

			return red, green, 0
		end

		local function getLatColor(ms)
			local red = ms / 400 * 2
			local green = 2 - red

			return red, green, 0
		end

		local function formatBandwidth(bandwidth)
			if bandwidth > 1024 then
				return format("%.2f MB/s", bandwidth / 1024)
			else
				return format("%.2f KB/s", bandwidth)
			end
		end

		-- Script functions
		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime
			if self.dt > 1 then
				self.dt = 0

				-- Set value
				local _, _, lagHome, lagWorld = GetNetStats()
				if db.FPS.MSValue == "Both" then
					self.text:SetFormattedText("%dfps    %dms | %dms", floor(GetFramerate()), lagHome, lagWorld)
				else
					self.text:SetFormattedText("%dfps    %dms", floor(GetFramerate()), (db.FPS.MSValue == "Home") and lagHome or lagWorld)
				end

				-- Update tooltip if open
				UpdateTooltip(self)
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("FPS / Latency:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				-- FPS
				local fps = floor(GetFramerate())
				GameTooltip:AddLine("FPS:")
				GameTooltip:AddDoubleLine("Current:", fps, 1,1,1, getFPSColor(fps))
				GameTooltip:AddLine(" ")

				-- Bandwidth / Latency
				local down, up, lagHome, lagWorld = GetNetStats()
				GameTooltip:AddLine("Latency:")
				GameTooltip:AddDoubleLine("Home:", lagHome.."ms", 1,1,1, getLatColor(lagHome))
				GameTooltip:AddDoubleLine("World:", lagWorld.."ms", 1,1,1, getLatColor(lagWorld))

				GameTooltip:AddLine("Bandwidth usage:")
				GameTooltip:AddDoubleLine("Current Down:", formatBandwidth(down), 1,1,1, 1,1,1)
				GameTooltip:AddDoubleLine("Current Up:", formatBandwidth(up), 1,1,1, 1,1,1)

				GameTooltip:Show()
			end
		end
		stat.OnLeave = function(self)
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / GOLD / --
------------------------------------------------------

function module:SetGold()
	local stat = NewStat("Gold")

	if db.Gold.Enable and not stat.Created then
		-- Localized functions
		local GetMoney, GetBackpackCurrencyInfo, GetItemQualityColor, GetItemInfo = GetMoney, GetBackpackCurrencyInfo, GetItemQualityColor, GetItemInfo
		local format, floor, abs, mod, select = format, floor, abs, mod, select

		-- Local variables
		local profit, spent, oldMoney, serverGold = 0, 0, 0, 0
		local colors = {
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

		-- Local functions
		local function formatMoney(money)
			if db.Gold.Shorten then
				local shortnum = function(v)
					if v <= 9999 then
						return v
					elseif v >= 1000000 then
						return format("%.1fM", v/1000000)
					elseif v >= 10000 then
						return format("%.1fk", v/1000)
					end
				end

				return shortnum(money / 10000)
			end


			money = abs(money)
			local gold, silver, copper = floor(money / 10000), mod(floor(money / 100), 100), mod(floor(money), 100)

			if gold ~= 0 then
				return format(db.Gold.ColorType and "%s|cffffd700g|r %d|cffc7c7cfs|r" or "%sg %ds", BreakUpLargeNumbers(gold), silver)
			elseif silver ~= 0 then
				return format(db.Gold.ColorType and "%d|cffc7c7cfs|r %d|cffeda55fc|r" or "%ss %dc", silver, copper)
			else
				return format(db.Gold.ColorType and "%d|cffeda55fc|r" or "%sc", copper)
			end
		end

		local function formatTooltipMoney(money)
			money = abs(money)
			local gold, silver, copper = floor(money / 10000), mod(floor(money / 100), 100), mod(floor(money), 100)
			local cash = format("%s|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", BreakUpLargeNumbers(gold), silver, copper)

			return cash
		end

		-- Stat functions
		stat.RefreshServerTotal = function(self)
			serverGold = 0

			for _, faction in pairs(db.realm.Gold) do
				for player, gold in pairs(faction) do
					serverGold = serverGold + gold
				end
			end
		end

		stat.ResetGold = function(self, player, faction)
			if not player then return end

			if player == "ALL" then
				db.realm.Gold = {
					[myPlayerFaction] = {
						[myPlayerName] = GetMoney(),
					},
					[otherFaction] = {},
				}
				goldPlayerArray = {["ALL"] = "ALL", [myPlayerName] = myPlayerName,}
			elseif faction then
				if player == myPlayerName then
					db.realm.Gold[faction][player] = GetMoney()
				else
					db.realm.Gold[faction][player] = nil
					goldPlayerArray[player] = nil
				end
			end

			oldMoney = GetMoney()
			self:RefreshServerTotal()
			self:PLAYER_MONEY()
		end

		-- Event functions
		stat.Events = {"PLAYER_MONEY"}
		stat.PLAYER_MONEY = function(self)
			local newMoney = GetMoney()

			local change = newMoney - oldMoney	-- Positive if we gain money
			serverGold = serverGold + change	-- Add change to server total

			if oldMoney > newMoney then			-- Lost Money
				spent = spent - change
			else								-- Gained Moeny
				profit = profit + change
			end

			-- Set value
			self.text:SetText(formatMoney(db.Gold.ServerTotal and serverGold or newMoney))

			-- Update gold db
			db.realm.Gold[myPlayerFaction][myPlayerName] = newMoney

			-- Update gold count
			oldMoney = newMoney

			-- Update tooltip if open
			UpdateTooltip(self)
		end

		-- Script functions
		stat.OnEnable = function(self)
			oldMoney = GetMoney()
			self:RefreshServerTotal()
			self:PLAYER_MONEY()
		end

		stat.OnReset = stat.PLAYER_MONEY

		stat.OnClick = function(self, button)
			if button == "RightButton" then -- reset session
				profit = 0
				spent = 0
				oldMoney = GetMoney()
				UpdateTooltip(self)
			else -- toggle server/toon gold
				db.Gold.ServerTotal = not db.Gold.ServerTotal
				self:PLAYER_MONEY()
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Money:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				GameTooltip:AddLine("Session:")
				GameTooltip:AddDoubleLine("Earned:", formatMoney(profit), 1,1,1, 1,1,1)
				GameTooltip:AddDoubleLine("Spent:", formatMoney(spent), 1,1,1, 1,1,1)

				if profit < spent then
					GameTooltip:AddDoubleLine("Deficit:", formatMoney(profit-spent), 1,0,0, 1,1,1)
				elseif profit > spent then
					GameTooltip:AddDoubleLine("Profit:", formatMoney(profit-spent), 0,1,0, 1,1,1)
				end

				local factionGold = {
					Horde = 0,
					Alliance = 0,
				}

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Character:")
				for player, gold in pairs(db.realm.Gold[myPlayerFaction]) do
					GameTooltip:AddDoubleLine(player, formatTooltipMoney(gold), colors[myPlayerFaction].r, colors[myPlayerFaction].g, colors[myPlayerFaction].b, 1,1,1)
					factionGold[myPlayerFaction] = factionGold[myPlayerFaction] + gold
				end
				for player, gold in pairs(db.realm.Gold[otherFaction]) do
					GameTooltip:AddDoubleLine(player, formatTooltipMoney(gold), colors[otherFaction].r, colors[otherFaction].g, colors[otherFaction].b, 1,1,1)
					factionGold[otherFaction] = factionGold[otherFaction] + gold
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Server:")
				if factionGold[otherFaction] > 0 then
					GameTooltip:AddDoubleLine(myPlayerFaction..":", formatTooltipMoney(factionGold[myPlayerFaction]), colors[myPlayerFaction].r, colors[myPlayerFaction].g, colors[myPlayerFaction].b, 1,1,1)
					GameTooltip:AddDoubleLine(otherFaction..":", formatTooltipMoney(factionGold[otherFaction]), colors[otherFaction].r, colors[otherFaction].g, colors[otherFaction].b, 1,1,1)
				end
				GameTooltip:AddDoubleLine("Total:", formatTooltipMoney(factionGold[myPlayerFaction] + factionGold[otherFaction]), 1,1,1, 1,1,1)

				for i = 1, MAX_WATCHED_TOKENS do
					local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)

					if name and i == 1 then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Currency:")
					end

					local r, g, b = 1, 1, 1
					if itemID then
						r, g, b = GetItemQualityColor(select(3, GetItemInfo(itemID)))
					end
					if name and count then
						GameTooltip:AddDoubleLine(name, count, r,g,b, 1,1,1)
					end
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint:\n- Left-Click to toggle server/toon gold.\n- Right-Click to reset Session.", 0, 1, 0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

--------------------------------------------------------------------
-- /GUILD and FRIENDS/ --
--------------------------------------------------------------------

local GF_Colors = {
	Note = {0.14, 0.76, 0.15},
	OfficerNote = {1, 0.56, 0.25},
	MotD = {1, 0.8, 0},
	Broadcast = {1, 0.1, 0.1},
	Title = {1, 1, 1},
	Rank = {0.1, 0.9, 1},
	Realm = {1, 0.8, 0},
	Status = {0.7, 0.7, 0.7},
	OrderA = {1, 1, 1, 0.1},
	ContestedZone = {1, 1, 0},
	SanctuaryZone = {0, 1, 1},
	FriendlyZone = {0, 1, 0},
	EnemyZone = {1, 0, 0},
	RemoteChatZone = {0, 1, 1},
}

-- Localized functions
local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

local BNGetFriendInfo, BNGetToonInfo, BNGetNumFriends, BNFeaturesEnabled, BNConnected = BNGetFriendInfo, BNGetToonInfo, BNGetNumFriends, BNFeaturesEnabled, BNConnected
local GetNumGroupMembers, GetNumSubgroupMembers, UnitInRaid, UnitInParty, InviteUnit = GetNumGroupMembers, GetNumSubgroupMembers, UnitInRaid, UnitInParty, InviteUnit
local CanEditMOTD, GetGuildRosterMOTD, CanEditPublicNote, CanEditOfficerNote = CanEditMOTD, GetGuildRosterMOTD, CanEditPublicNote, CanEditOfficerNote
local GetQuestDifficultyColor, RemoveFriend, SetGuildRosterSelection, SetItemRef = GetQuestDifficultyColor, RemoveFriend, SetGuildRosterSelection, SetItemRef
local unpack, next, sort, tonumber, format, floor, min, max, wipe, select = unpack, next, sort, tonumber, format, floor, min, max, wipe, select

function module:SetGF()
	local stat = NewStat("GF")
	stat.Hidden = true

	if (db.Guild.Enable or db.Friends.Enable) and not stat.Created then
		stat:SetFrameStrata("TOOLTIP")
		stat:SetFrameLevel(1)
		stat:SetClampedToScreen(true)

		stat.LocClassNames = {}

		local MOBILE_BUSY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:14:14:0:0:16:16:0:16:0:16|t";
		local MOBILE_AWAY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:14:14:0:0:16:16:0:16:0:16|t";

		-- Local variables
		local motd, slider, nbEntries
		local nbRealFriends, realFriendsHeight, nbBroadcast = 0, nil, nil
		local btnHeight, iconSize, gap, textOffset, maxEntries = 15, 13, 10, 5, nil
		local sliderValue, hasSlider, extraHeight = 0, nil, nil
		local tables, broadcasts, toasts, buttons
		local slider, highlight, texOrder1, sep, sep2

		local horde = myPlayerFaction == "Horde"

		local hordeZones = "Orgrimmar,Undercity,Thunder Bluff,Silvermoon City,Durotar,Tirisfal Glades,Mulgore,Eversong Woods,Northern Barrens,Silverpine Forest,Ghostlands,Azshara,"
		local allianceZones = "Ironforge,Stormwind City,Darnassus,The Exodar,Azuremyst Isle,Bloodmyst Isle,Darkshore,Deeprun Tram,Dun Morogh,Elwynn Forest,Loch Modan,Teldrassil,Westfall,"
		local sanctuaryZones = "Dalaran,Shattrath,The Maelstrom,"
		local mobileZones = "Remote Chat,ed"

		local statuses = { -- values inherited from the chat frame
			[1] = CHAT_FLAG_AFK,
			[2] = CHAT_FLAG_DND,
		}
		local colpairs = {
			["class"] = 1,
			["name"] = 2,
			["level"] = 3,
			["zone"] = 4,
			["note"] = 5,
			["status"] = 6,
			["rank"] = 7
		}
		local sortIndexes = {
			[true] = {	-- Guild
				colpairs[db.Guild.sortCols[1]],
				colpairs[db.Guild.sortCols[2]],
				colpairs[db.Guild.sortCols[3]]
			},
			[false] ={	-- Friends
				colpairs[db.Friends.sortCols[1]],
				colpairs[db.Friends.sortCols[2]],
				colpairs[db.Friends.sortCols[3]]
			},
		}

		-- Local functions
		local function GorF()
			return stat.IsGuild and "Guild" or "Friends"
		end

		local function CreateTex(parent, anchor, offsetX)
			local tex = parent:CreateTexture()
			tex:SetWidth(iconSize)
			tex:SetHeight(iconSize)
			tex:SetPoint("LEFT", anchor or parent, anchor and "RIGHT" or "LEFT", offsetX or 0, 0)
			return tex
		end

		local function CreateFS(parent, justify, anchor, offsetX, color)
			local fs = parent:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1")
			if justify then fs:SetJustifyH(justify) end
			if anchor then fs:SetPoint("LEFT", anchor, "RIGHT", offsetX or gap, 0) end
			if color then fs:SetTextColor(unpack(color)) end
			return fs
		end

		local function formatedStatusText(status, append, isMobile)
			if (isMobile) then
				if status == 2 then return MOBILE_BUSY_ICON..(append or "");
				elseif status == 1 then return MOBILE_AWAY_ICON..(append or "");
				else return ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)..(append or "");
				end
			else
				if not statuses[status] then return append or "" end
				local r,g,b = unpack(GF_Colors.Status)
				return ("|cff%.2x%.2x%.2x%s|r %s"):format(r*255, g*255, b*255, statuses[status], append or "")
			end
		end

		local function GetZoneColor(zone)
			return unpack(GF_Colors[
				mobileZones:find(zone..",") and ("RemoteChatZone") or
				hordeZones:find(zone..",") and (horde and "FriendlyZone" or "EnemyZone") or
				allianceZones:find(zone..",") and (horde and "EnemyZone" or "FriendlyZone") or
				sanctuaryZones:find(zone..",") and ("SanctuaryZone") or ("ContestedZone")
			])
		end

		local function MOTD_OnClose(edit)
			edit:ClearAllPoints()
			edit:SetParent(edit.prevParent)
			edit:SetPoint(unpack(edit.prevPoint))
			module:Unhook(edit, "OnHide")
		end

		local function EditMOTD()
			stat:Hide()
			if not GuildTextEditFrame then GuildFrame_LoadUI() end
			local edit = GuildTextEditFrame
			edit.prevPoint = {edit:GetPoint()}
			edit.prevParent = edit:GetParent()
			edit:ClearAllPoints()
			edit:SetParent(UIParent)
			edit:SetPoint("CENTER", 0, 180)
			GuildTextEditFrame_Show("motd")
			if not module:IsHooked(edit, "OnHide") then
				module:HookScript(edit, "OnHide", MOTD_OnClose)
			end
		end

		local function EditBroadcast()
			stat:Hide()
			StaticPopup_Show("SET_BN_BROADCAST")
		end

		local function SetClassIcon(tex, class)
			tex:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
			local offset, left, right, bottom, top = 0.025, unpack(CLASS_BUTTONS[class])
			tex:SetTexCoord(left+offset, right-offset, bottom+offset, top-offset)
		end

		local function SetStatusLayout(statusTex, fs)
			statusTex:Hide()
			fs:SetPoint("LEFT", statusTex, "LEFT")
		end

		local function SetButtonData(index, inGroup)
			local button = buttons[index]

			if index == 0 then
				button.name:SetText(inGroup)
				return button, button.name:GetStringWidth()
			end

			local class, name, level, zone, notes, status, _, rank, isMobile, realIndex, fullName = unpack((stat.IsGuild and guildEntries or friendEntries)[index])
			button.unit = fullName
			button.realIndex = realIndex
			button.name:SetText(formatedStatusText(status, name, isMobile))
			if name and class and RAID_CLASS_COLORS[class] then
				local color = RAID_CLASS_COLORS[class]
				button.name:SetTextColor(color.r, color.g, color.b)
				SetClassIcon(button.class, class)
				SetStatusLayout(button.status, button.name)
				color = GetQuestDifficultyColor(level)
				button.level:SetTextColor(color.r, color.g, color.b)
				button.zone:SetTextColor(GetZoneColor(zone))
			end

			button.level:SetText(level)
			button.zone:SetText(zone)
			button.note:SetText(notes)
			button.rank:SetText(rank)

			return button,
			button.name:GetStringWidth(),
			button.level:GetStringWidth(),
			button.zone:GetStringWidth(),
			button.note:GetStringWidth(),
			rank and button.rank:GetStringWidth() or -gap
		end

		local function SetToastData(index, inGroup)
			local toast, bc, color = toasts[index], nil, nil
			--presenceID is the BNAccountID, toonID refers to BNGameAccountID, name preserved for compatibility sake. Clean code in V4.
			local presenceID, givenName, battletag, isBattletag, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcast, notes = BNGetFriendInfo(index)
			if not BNGetGameAccountInfo then BNGetGameAccountInfo = BNGetToonInfo end
			local _, _, _, realm, _, faction, race, class, _, zone, level, gameText = BNGetGameAccountInfo(toonID or 0)

			if faction == 'Alliance' then faction = 1
			else faction = 0
			end

			if broadcast and broadcast ~= "" then
				nbBroadcast = nbBroadcast + 1
				bc = broadcasts[nbBroadcast]
				bc.text:SetText(broadcast)
				toast.bcIndex = nbBroadcast
			else
				toast.bcIndex = nil
			end

			toast.presenceID = presenceID
			toast.unit = toonName
			toast.realID = givenName

			SetStatusLayout(toast.status, toast.name)

			toast.client = client

			if client == BNET_CLIENT_WOW then
				toast.faction:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Factions]])
				toast.faction:SetTexCoord(faction == 1 and 0.03 or 0.53, faction == 1 and 0.47 or 0.97, 0.03, 0.97)
				zone = (zone == nil or zone == "") and UNKNOWN or zone
				toast.zone:SetPoint("LEFT", toast.faction, "RIGHT", textOffset, 0)
				toast.zone:SetTextColor(GetZoneColor(zone))
				toast.sameRealm = realm == myPlayerRealm

				if not toast.sameRealm then
					local r,g,b = unpack(GF_Colors.Realm)
					zone = ("%1$s |cff%3$.2x%4$.2x%5$.2x- %2$s"):format(zone, realm, r*255, g*255, b*255)
				end
				class = stat.LocClassNames[class]
				if class then
					SetClassIcon(toast.class, class)
					color = RAID_CLASS_COLORS[class]
					toast.name:SetTextColor(color.r, color.g, color.b)
				else
					toast.class:SetTexture("")
				end
			else
				toast.class:SetTexture(BNet_GetClientTexture(client))
				toast.class:SetTexCoord(0.2, 0.8, 0.2, 0.8)
				toast.name:SetTextColor(0.8, 0.8, 0.8)
				toast.faction:SetTexture("")
				zone = gameText
				toast.zone:SetPoint("LEFT", toast.name, "RIGHT", gap, 0)
				toast.zone:SetTextColor(1, 0.77, 0)
			end

			toast.name:SetText(formatedStatusText(isAFK and 1 or isDND and 2, format("|cff00b2f0%s|r%s", toast.realID, (toonName and format(" - %s", toonName) or ""))))

			if level and level ~= "" then
				toast.level:SetText(level)
				color = GetQuestDifficultyColor(tonumber(level))
				toast.level:SetTextColor(color.r, color.g, color.b)
			else
				toast.level:SetText()
			end

			toast.zone:SetText(zone)
			toast.note:SetText(notes)

			return toast, client,
			toast.name:GetStringWidth(),
			client ~= BNET_CLIENT_WOW and -gap or toast.level:GetStringWidth(),
			toast.zone:GetStringWidth(),
			toast.note:GetStringWidth()
		end

		local function UpdateScrollButtons(nbEntries)
			for i=1, #buttons do buttons[i]:Hide() end
			local baseOffset = -realFriendsHeight
			local sliderValue = hasSlider and sliderValue or 0
			for i=1, nbEntries do
				local button = buttons[sliderValue+i]
				button:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, baseOffset - (i-1)*btnHeight)
				button:Show()
			end
		end

		local function SortMates(a, b)
			local s = sortIndexes[stat.IsGuild]
			local si, lv = s[1], 1
			if a[si] == b[si] then
				si, lv = s[2], 2
				if a[si] ==  b[si] then
					si, lv = s[3], 3
				end
			end
			if db[GorF()].sortASC[lv] then
				return a[si] < b[si]
			else
				return a[si] > b[si]
			end
		end

		-- Metatables (localized above)
		tables = setmetatable({}, {__mode = "k"})

		broadcasts = setmetatable({}, {
			__index = function(t, k)
				local bc = CreateFrame("Button", nil, stat)
				t[k] = bc
				bc:SetHeight(btnHeight)
				bc:SetNormalFontObject(GameFontNormal)
				bc:EnableMouseWheel(true)
				bc:SetScript("OnMouseWheel", stat.OnScroll)
				bc.icon = CreateTex(bc, nil, iconSize + textOffset)
				bc.icon:SetTexture([[Interface\FriendsFrame\BroadcastIcon]])
				bc.icon:SetTexCoord(.1,.9,.1,.9)
				bc.text = CreateFS( bc, "LEFT", bc.icon, textOffset, GF_Colors.Broadcast )
				bc.text:SetHeight(btnHeight)
				return bc
			end
		})

		toasts = setmetatable({}, {
			__index = function(t, k)
				local btn = CreateFrame("Button", nil, stat)
				t[k] = btn
				btn.index = k
				btn:SetNormalFontObject(GameFontNormal)
				btn:RegisterForClicks("AnyUp")
				btn:SetScript("OnEnter", stat.OnBtnEnter)
				btn:SetScript("OnLeave", stat.OnBtnLeave)

				btn:EnableMouseWheel(true)
				btn:SetScript("OnMouseWheel", stat.OnScroll)
				btn:SetScript("OnClick", stat.OnBtnClick)

				btn:SetHeight(btnHeight)

				btn.class = CreateTex(btn)
				btn.status = CreateTex(btn, btn.class, textOffset)
				btn.status:SetTexCoord(.1, .9, .1, .9)
				btn.name  = CreateFS(btn, "LEFT", btn.status, textOffset)
				btn.level = CreateFS(btn, "CENTER", btn.name, gap)
				btn.faction = CreateTex(btn, btn.level, gap)
				btn.zone  = CreateFS(btn, "LEFT", btn.faction, textOffset)
				btn.note = CreateFS(btn, "CENTER", btn.zone, gap, GF_Colors.Note)
				return btn
			end
		})

		buttons = setmetatable({}, {
			__index = function(t, k)
				local btn = CreateFrame("Button", nil, stat)
				t[k] = btn
				btn.index = k
				btn:SetNormalFontObject(GameFontNormal)
				btn:RegisterForClicks("AnyUp")
				btn:SetScript("OnEnter", stat.OnBtnEnter)
				btn:SetScript("OnLeave", stat.OnBtnLeave)

				btn:EnableMouseWheel(true)
				btn:SetScript("OnMouseWheel", stat.OnScroll)

				if k == 0 then	-- MotD / Broadcast
					motd = btn
					motd.name = CreateFS(btn, "LEFT")
					motd:Show()
					motd.name:SetJustifyV("TOP")
					motd.name:SetPoint("TOPLEFT", motd, "TOPLEFT")
					motd:SetPoint("TOPLEFT", stat, "TOPLEFT", gap, -gap)

					sep = motd:CreateTexture()
					sep:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
					sep:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, btnHeight)
					sep:SetPoint("BOTTOMRIGHT", motd, "BOTTOMRIGHT", 0, 0)
				else
					btn:SetHeight(btnHeight)
					btn.class = CreateTex(btn)
					btn.status = CreateTex(btn, btn.class, textOffset)
					btn.status:SetTexCoord(.1, .9, .1, .9)

					btn.name = CreateFS(btn, "LEFT", btn.class, textOffset)
					btn.level = CreateFS(btn, "CENTER", btn.name)
					btn.zone  = CreateFS(btn, "LEFT", btn.level)
					btn.note = CreateFS(btn, "CENTER", btn.zone, gap, GF_Colors.Note)
					btn.rank  = CreateFS(btn, "RIGHT",  btn.note, gap, GF_Colors.Rank)
				end
				return btn
			end
		})

		-- Frames
		slider = CreateFrame("Slider", nil, stat)
		slider:SetWidth(16)
		slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
		slider:SetBackdrop({
			bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
			edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
			edgeSize = 8, tile = true, tileSize = 8,
			insets = {left=3, right=3, top=6, bottom=6}
		})
		slider:SetValueStep(1)
		slider:SetScript("OnLeave", stat.OnBtnLeave)
		slider:SetScript("OnValueChanged", function(self, value)
			if hasSlider then
				sliderValue = value
				if stat:IsMouseOver() then UpdateScrollButtons(maxEntries) end
			end
		end)

		-- Textures
		highlight = stat:CreateTexture()
		highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		highlight:SetBlendMode("ADD")
		highlight:SetAlpha(0)

		texOrder1 = stat:CreateTexture()
		texOrder1:SetTexture([[Interface\Buttons\WHITE8X8]])
		texOrder1:SetBlendMode("ADD")

		sep2 = stat:CreateTexture()
		sep2:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])

		-- Stat functions
		stat.new = function(self, ...)
			local t = next(tables)
			if t then tables[t] = nil else t = {} end
			for i=1, select("#",...) do t[i] = select(i,...) end
			return t
		end
		stat.del = function(self, t)
			tables[wipe(t)] = true
		end

		stat.Update = function(self)
			local totalRF, onlineRF, entries = 0, 0, nil

			if self.IsGuild then
				entries = guildEntries
				nbRealFriends = 0
			else
				entries = friendEntries
				totalRF, onlineRF = BNGetNumFriends()
				nbRealFriends = onlineRF
			end

			local nbTotalEntries = #entries + nbRealFriends
			local rid_width, button = 0, nil

			realFriendsHeight = 0

			local nameC, levelC, zoneC, notesC, rankC = 0, 0, 0, 0, -gap
			local nameW, levelW, zoneW, notesW, rankW
			local hideNotes = not db[GorF()].ShowNotes

			local inGroup = GetNumGroupMembers() > 0 and UnitInRaid("player") or GetNumSubgroupMembers() > 0 and UnitInParty("player") or nil
			local tnC, lC, zC, nC = 0, -gap, -gap, 0
			local spanZoneC = 0

			if nbRealFriends > 0 then
				nbBroadcast = 0
				for i=1, nbRealFriends do
					local button, client, tnW, lW, zW, nW, spanZoneW = SetToastData(i, inGroup)

					if tnW > tnC then tnC = tnW end

					if client == BNET_CLIENT_WOW then
						if lW > lC then lC = lW end
						if zW > zC then zC = zW end
					else
						if zW > spanZoneC then spanZoneC = zW end
					end

					if nW > nC then nC = nW end
				end

				realFriendsHeight = (nbRealFriends + nbBroadcast) * btnHeight + (#entries>0 and gap or 0)
				if hideNotes then nC = -gap end

				spanZoneC = max(spanZoneC, lC + gap + iconSize + textOffset + zC)
				rid_width = iconSize + textOffset + tnC + spanZoneC + nC + 2*gap

				if #entries>0 then
					local t = toasts[nbRealFriends]
					local offsetY = t.bcIndex and btnHeight or 0
					sep2:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, 2-offsetY)
					sep2:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 0, 2-offsetY-btnHeight)
					sep2:Show()
				end
			end
			if self.IsGuild or #entries==0 then sep2:Hide() end

			sort(entries, SortMates)
			for i = 1, #entries do
				button, nameW, levelW, zoneW, notesW, rankW = SetButtonData(i, inGroup)
				button:SetScript("OnClick", self.OnBtnClick)
				if nameW > nameC then nameC = nameW end
				if levelW and levelW>0 then
					if levelW > levelC then levelC = levelW end
					if  zoneW >  zoneC then  zoneC = zoneW  end
					if notesW > notesC then notesC = notesW end
					if  rankW >  rankC then  rankC = rankW  end
					if hideNotes then button.note:Hide() else button.note:Show() end
					button.rank:SetPoint("LEFT", hideNotes and button.zone or button.note, "RIGHT", gap, 0) -- If Rank text is out of place, set these back to TOPLEFT and TOPRIGHT
				end
			end

			if hideNotes then notesC = -gap end
			local maxWidth = max( rid_width, iconSize + textOffset + nameC + levelC + zoneC + notesC + rankC + gap * 4 )

			-- motd / broadcast
			--noinspection ArrayElementZero
			motd = buttons[0] -- fix for errors caused by motd being nil
			motd:SetScript("OnClick",nil)
			local guildMOTD = self.IsGuild and GetGuildRosterMOTD()
			if self.IsGuild and (nbTotalEntries>0 and guildMOTD or nbTotalEntries==0) or not self.IsGuild and (BNFeaturesEnabled() and totalRF>0 or nbTotalEntries==0 or not BNConnected()) then -- TODO look for better way to phrase this
				motd.name:SetJustifyH("LEFT")
				motd.name:SetTextColor(unpack(GF_Colors.Title))
				local r, g, b = unpack(GF_Colors.MotD)
				local motdText = ("%%s:  |cff%.2x%.2x%.2x%%s"):format(r*255, g*255, b*255)
				if self.IsGuild then
					SetButtonData(0, nbTotalEntries>0 and motdText:format("MOTD", guildMOTD) or "     |cffff2020"..ERR_GUILD_PLAYER_NOT_IN_GUILD)
					if nbTotalEntries>0 and CanEditMOTD() then motd:SetScript("OnClick", EditMOTD) end
				else
					if not BNConnected() then
						motd.name:SetJustifyH("CENTER")
						SetButtonData(0, "|cffff2020"..BATTLENET_UNAVAILABLE)
					elseif nbTotalEntries == 0 then
						SetButtonData(0, "     |cffff2020".."No friends online.")
					else
						SetButtonData(0, motdText:format("Broadcast", select(4, BNGetInfo()) or ""))
						motd:SetScript("OnClick", EditBroadcast)
					end
				end

				if nbTotalEntries == 0 then
					extraHeight = 0
					sep:Hide()
					maxWidth = min(motd.name:GetStringWidth() + gap*2, 300)
				else
					extraHeight = btnHeight
					sep:Show()
				end
				motd.name:SetWidth(maxWidth)
				extraHeight = extraHeight + motd.name:GetHeight()

				motd:SetWidth(maxWidth)
				motd:SetHeight(extraHeight)

				buttons[1]:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, -realFriendsHeight)
			else
				extraHeight = 0
				motd.name:SetText()
				motd:SetHeight(1)
				motd:SetWidth(maxWidth)
				buttons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", gap, -gap)
			end

			for i=1, #toasts do toasts[i]:Hide() end
			for i=1, #broadcasts do broadcasts[i]:Hide() end
			if not self.IsGuild and nbRealFriends > 0 then
				local header, bcOffset = motd, 0
				local bcWidth = maxWidth - 2*(iconSize - textOffset) - 2*gap
				for i=1, nbRealFriends do
					local b = toasts[i]
					b:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, (1 - i - bcOffset) * btnHeight)
					if b.bcIndex then
						bcOffset = bcOffset + 1
						local bc = broadcasts[b.bcIndex]
						bc.text:SetWidth(bcWidth)
						bc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, (1 - i - bcOffset) * btnHeight)
						bc:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -iconSize - textOffset, (-i - bcOffset) * btnHeight)
						bc:Show()
					end
					b:Show()
				end
			end

			maxEntries = floor((UIParent:GetHeight() - extraHeight - gap*2)/btnHeight - 2)
			slider:SetHeight(btnHeight * maxEntries)
			hasSlider = #entries > maxEntries
			if hasSlider then
				slider:SetMinMaxValues(0, #entries - maxEntries)
				slider:SetValue(sliderValue)
				slider:Show()
			else
				slider:Hide()
			end
			nbEntries = min(maxEntries, #entries)

			UpdateScrollButtons(nbEntries)

			for i=1, nbRealFriends do
				button = toasts[i]
				button:SetWidth( maxWidth )
				button.name:SetWidth(tnC)
				if button.client == BNET_CLIENT_WOW then
					button.level:SetWidth(lC)
					button.zone:SetWidth(zC)
				else
					button.zone:SetWidth(spanZoneC)
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
				local col = db[GorF()].sortCols[1]
				local obj = buttons[1][col]
				if obj:IsShown() then
					texOrder1:SetPoint("TOPLEFT", obj, "TOPLEFT", -.25*gap, 2 )
					texOrder1:SetWidth(obj:GetWidth() + gap*.5)
					texOrder1:SetHeight(nbEntries * btnHeight + 1)
					local asc = db[GorF()].sortASC[1]
					if col == "level" then asc = not asc end
					local a1, r1, g1, b1 = GF_Colors.OrderA[4], unpack(GF_Colors.OrderA)
					local a2, r2, g2, b2 = 0, GameTooltip:GetBackdropColor()
					if asc then r1,g1,b1,a1, r2,g2,b2,a2 = r2,g2,b2,a2, r1,g1,b1,a1 end
					-- texOrder1:SetGradientAlpha("VERTICAL", r1,g1,b1,a1, r2,g2,b2,a2)
					texOrder1:SetAlpha(0)
				else
					texOrder1:SetAlpha(0)
				end
			else
				texOrder1:SetAlpha(0)
			end

			if hasSlider then slider:SetPoint("TOPRIGHT", buttons[1], "TOPRIGHT", 19 + textOffset, 0) end

			self:SetWidth(maxWidth + gap*2 + (hasSlider and 16 + textOffset*2 or 0))
			self:SetHeight(extraHeight + realFriendsHeight + btnHeight * nbEntries + gap*2)
			local frame = self.IsGuild and self.Guild or self.Friends
			if frame:IsMouseOver() then
				frame:UpdateHints()
			elseif highlight:GetPoint() then
				self:ShowHints(select(2, highlight:GetPoint()))
			end
			if not (self.onBlock or self:IsMouseOver()) then self:Hide() end
		end

		stat.Anchor = function(self, frame, guild)
			CloseDropDownMenus()
			self.IsGuild = guild
			self:Show()
			self.onBlock = true
			self:ClearAllPoints()
			self:SetPoint(isTop(frame) and "TOP" or "BOTTOM", frame, isTop(frame) and "BOTTOM" or "TOP")

			local Tooltip = LUI:Module("Tooltip", true)
			if Tooltip and Tooltip:IsEnabled() then
				local backdrop = {
					bgFile = Media:Fetch("background", LUI.db.profile.Tooltip.Background.Texture),
					edgeFile = Media:Fetch("border", LUI.db.profile.Tooltip.Border.Texture),
					tile = false,
					edgeSize = LUI.db.profile.Tooltip.Border.Size,
					insets = {
						left = LUI.db.profile.Tooltip.Border.Insets.Left,
						right = LUI.db.profile.Tooltip.Border.Insets.Right,
						top = LUI.db.profile.Tooltip.Border.Insets.Top,
						bottom = LUI.db.profile.Tooltip.Border.Insets.Bottom
					}
				}
				local bgColor = LUI.db.profile.Tooltip.Background.Color
				local borderColor = LUI.db.profile.Tooltip.Border.Color

				self:SetBackdrop(backdrop)
				self:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
				self:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
			else
				self:SetBackdrop(GameTooltip:GetBackdrop())
				self:SetBackdropColor(GameTooltip:GetBackdropColor())
				self:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
			end

			self:Update()
		end

		stat.OnScroll = function(self, delta)
			slider:SetValue(sliderValue - delta * (IsModifierKeyDown() and 10 or 3))
		end

		-- Btn functions (each Btn is a character in the list)
		stat.OnBtnEnter = function(b)
			if b and b.index then
				highlight:SetAllPoints(b)
				if b.index > 0 then
					highlight:SetAlpha(1)
					stat:ShowHints(b)
				end
			end
		end

		stat.OnBtnLeave = function(b)
			highlight:ClearAllPoints()
			GameTooltip:Hide()
			if b and b.index and b.index > 0 then highlight:SetAlpha(0) end
			if not stat:IsMouseOver() then stat:Hide() end
		end

		stat.OnBtnClick = function(b, button) -- button arg is mouse button
			if not(b) then return end
			if (stat.IsGuild or not b.presenceID) and button == "RightButton" and not IsControlKeyDown() then -- sort by column
				local btn, ofx = buttons[1], gap*.25
				local pos = GetCursorPosition() / b:GetEffectiveScale()
				for v, i in pairs(colpairs) do
					local btnv = btn[v]
					if btnv:IsShown() and pos >= btnv:GetLeft() - ofx and pos <= btnv:GetRight() + ofx then
						local sortCols, sortASC = db[GorF()].sortCols, db[GorF()].sortASC
						if sortCols[1] == v then
							sortASC[1] = not sortASC[1]
						else
							sortCols[3] = sortCols[2]
							sortASC[3] = sortASC[2]
							sortCols[2] = sortCols[1]
							sortASC[2] = sortASC[1]
							sortCols[1] = v
							sortASC[1] = v ~= "level"
							sortIndexes[stat.IsGuild][3] = sortIndexes[stat.IsGuild][2]
							sortIndexes[stat.IsGuild][2] = sortIndexes[stat.IsGuild][1]
						end
						sortIndexes[stat.IsGuild][1] = i
						return stat:IsShown() and stat:Update()
					end
				end
			elseif button == "MiddleButton" and not stat.IsGuild then -- remove friend
				if b.presenceID then
					StaticPopup_Show("CONFIRM_REMOVE_FRIEND", b.realID, nil, b.presenceID)
				else
					RemoveFriend(b.unit)
				end
			elseif IsAltKeyDown() then -- invite unit
				if b.presenceID then
					if b.client ~= BNET_CLIENT_WOW then return end
					FriendsFrame_BattlenetInvite(nil, b.presenceID)
				else
					InviteUnit(b.unit)
				end
			elseif IsControlKeyDown() then -- edit note
				if not stat.IsGuild then
					FriendsFrame.NotesID = b.presenceID or b.realIndex
					if b.presenceID then
						StaticPopup_Show("SET_BNFRIENDNOTE", b.realID)
					else
						StaticPopup_Show("SET_FRIENDNOTE", b.unit)
					end
				elseif button == "LeftButton" and CanEditPublicNote() or button ~= "LeftButton" and CanEditOfficerNote() then
					SetGuildRosterSelection(b.realIndex)
					StaticPopup_Show(button == "LeftButton" and "SET_GUILDPLAYERNOTE" or "SET_GUILDOFFICERNOTE")
				end
			else -- leftclick = whisper, shift leftclick = /who
				if b.presenceID then
					local name = b.realID..":"..b.presenceID
					SetItemRef("BNplayer:"..name, ("|HBNplayer:%1$s|h[%1$s]|h"):format(name), button )
				else

					SetItemRef("player:"..b.unit, ("|Hplayer:%1$s|h[%1$s]|h"):format(b.unit), button )
				end
			end
		end

		stat.ShowHints = function(self, btn)
			if db[GorF()].ShowHints and btn and btn.unit then
				local point = self.IsGuild and self.Guild or self.Friends
				if (select(1, self:GetCenter()) > UIParent:GetWidth()/2) then
					GameTooltip:SetOwner(point, isTop(self) and "ANCHOR_BOTTOMLEFT" or "ANCHOR_LEFT", -(self:GetWidth()-point:GetWidth())/2, 0)
				else
					GameTooltip:SetOwner(point, isTop(self) and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_RIGHT", (self:GetWidth()-point:GetWidth())/2, 0)
				end
				GameTooltip:AddLine"Hints:"
				GameTooltip:AddLine("|cffff8020Click|r to whisper.", .2,1,.2)
				if not btn.presenceID or btn.client == BNET_CLIENT_WOW then
				    GameTooltip:AddLine("|cffff8020Alt+Click|r to invite.", .2,1,.2)
				end
				if not btn.presenceID then
					GameTooltip:AddLine("|cffff8020Shift+Click|r to query informations.", .2, 1, .2)
				end
				if (not self.IsGuild or CanEditPublicNote()) then GameTooltip:AddLine("|cffff8020Ctrl+Click|r to edit note.", .2, 1, .2) end
				if self.IsGuild then
					if CanEditOfficerNote() then GameTooltip:AddLine("|cffff8020Ctrl+RightClick|r to edit officer note.", .2, 1, .2) end
				else
					GameTooltip:AddLine("|cffff8020MiddleClick|r to remove friend.", .2, 1, .2)
				end
				if not btn.presenceID then
					GameTooltip:AddLine("|cffff8020RightClick|r to sort by column.", .2, 1, .2)
				end
				GameTooltip:SetFrameLevel(2) -- keep tooltip above friends/guild list
				GameTooltip:Show()
			end
		end

		-- Main Stat functions (Guild Stat and Friends Stat)
		stat.OnStatLeave = function(self)
			self.onBlock = nil
			GameTooltip:Hide()
			if not self:IsMouseOver() then
				self:Hide()
			end
		end

		-- Hooks
		local function guildRoster()
			if stat.Guild then
				stat.Guild.dt = 0
			end
		end
		local function showFriends()
			if stat.Friends then
				stat.Friends.dt = 0
			end
		end

		-- Script functions
		stat.OnEnable = function(self)
			self:Hide()

			for eng, loc in pairs(LOCALIZED_CLASS_NAMES_MALE)   do stat.LocClassNames[loc] = eng end
			for eng, loc in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do stat.LocClassNames[loc] = eng end

			module:SecureHook("GuildRoster", guildRoster)
			module:SecureHook("ShowFriends", showFriends)
		end

		stat.OnDisable = function(self)
			module:Unhook("GuildRoster")
			module:Unhook("ShowFriends")
		end

		stat.OnLeave = function(self)
			GameTooltip:Hide()
			if not self:IsMouseOver() then self:Hide() end
		end

		stat.Created = true
	end
end

function module:SetGuild()
	local stat = NewStat("Guild")

	if db.Guild.Enable and not stat.Created then
		if not InfoStats.GF or not InfoStats.GF.Created then module:SetGF() end
		local tooltip = InfoStats.GF

		tooltip.Guild = stat

		-- Localized functions
		local IsInGuild, GetNumGuildMembers, GetGuildRosterInfo = IsInGuild, GetNumGuildMembers, GetGuildRosterInfo
		local unpack, format = unpack, format

		-- Stat functions
		stat.UpdateText = function(self)
			self.text:SetText(IsInGuild() and (db.Guild.ShowTotal and "Guild: %d/%d" or "Guild: %d"):format(#guildEntries, GetNumGuildMembers(true)) or "No Guild")
		end

		stat.UpdateHints = function(self)
			if tooltip.onBlock then
				if db.Guild.ShowHints and IsInGuild() then
					if (select(1, self:GetCenter()) > UIParent:GetWidth()/2) then
						GameTooltip:SetOwner(self, isTop(self) and "ANCHOR_BOTTOMLEFT" or "ANCHOR_LEFT", -(tooltip:GetWidth()-self:GetWidth())/2, 0)
					else
						GameTooltip:SetOwner(self, isTop(self) and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_RIGHT", (tooltip:GetWidth()-self:GetWidth())/2, 0)
					end
					GameTooltip:AddLine("Hints:")
					GameTooltip:AddLine("|cffff8020Click|r to open Guild Roster.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020RightClick|r to display Guild Information.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020Button4|r to toggle notes.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020Button5|r to toggle hints.", 0.2, 1, 0.2)
					GameTooltip:SetFrameLevel(2) -- keep tooltip above friends/guild list
					GameTooltip:Show()
				else
					GameTooltip:Hide()
				end
			end
		end

		-- Event functions
		stat.Events = {"GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE"}

		stat.GUILD_ROSTER_UPDATE = function(self)
			for k, v in pairs(guildEntries) do
				tooltip:del(v)
				guildEntries[k]=nil
			end
			local r,g,b = unpack(GF_Colors.OfficerNote)
			local offcolor = ("\124cff%.2x%.2x%.2x"):format(r*255, g*255, b*255)
			for i=1, GetNumGuildMembers(true) do
				local fullName, rank, rankIndex, level, class, zone, note, offnote, connected, status, cFN, achiPoints, achiRank, isMobile = GetGuildRosterInfo(i)
				local displayName, realmName = strsplit("-",tostring(fullName))
				local name = db.Guild.hideRealm and displayName or fullName
				if isMobile then
					zone = "Remote Chat"
				end
				if connected or isMobile then
					local notes = note ~= "" and (offnote == "" and note or ("%s |cffffcc00-|r %s%s"):format(note, offcolor, offnote)) or offnote == "" and "|cffffcc00-" or offcolor..offnote
					guildEntries[#guildEntries+1] = tooltip:new(tooltip.LocClassNames[class] or "", name or "", level or 0, zone or UNKNOWN, notes, status, rankIndex or 0, rank or 0, isMobile, i, fullName)
				end
			end
			self:UpdateText()
			if tooltip.IsGuild and tooltip:IsShown() then tooltip:Update() end
		end

		stat.PLAYER_GUILD_UPDATE = function(self, unit)
			if unit and unit ~= "player" then return end
			if IsInGuild() then GuildRoster() end
		end

		-- Script functions
		stat.OnEnable = function(self)
			if IsInGuild() then GuildRoster() end
			self:UpdateText()
		end

		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime
			if self.dt > 15 then
				if IsInGuild() then
					GuildRoster()
				else
					self.dt = 0
				end
			end
		end

		stat.OnClick = function(self, button)
			if not GuildFrame then GuildFrame_LoadUI() end
			if button == "LeftButton" then -- toggle Guild Roster
				if not GuildFrame or not GuildFrame:IsShown() or (GuildRosterFrame and GuildRosterFrame:IsShown()) then
					ToggleGuildFrame()
				end
				if GuildFrame and GuildFrame:IsShown() then
					GuildFrameTab2:Click()
				end
			elseif button == "RightButton" then -- toggle Guild Info
				if not GuildFrame or not GuildFrame:IsShown() or (GuildMainFrame and GuildMainFrame:IsShown()) then
					ToggleGuildFrame()
				end
				if GuildFrame and GuildFrame:IsShown() then
					GuildFrameTab1:Click()
				end
			elseif button == "Button4" then -- toggle guild and officer notes
				db.Guild.ShowNotes = not db.Guild.ShowNotes
				tooltip:Update()
			elseif button == "Button5" then -- toggle mouseclick hints
				db.Guild.ShowHints = not db.Guild.ShowHints
				self:UpdateHints()
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				if IsInGuild() then GuildRoster() end
				tooltip:Anchor(self, true)
			end
		end
		stat.OnLeave = function()
			tooltip:OnStatLeave()
		end

		stat.Created = true
	end
end

-- Localized functions
local GetNumFriends, BNGetNumFriends, GetFriendInfo, BNSetCustomMessage = GetNumFriends, BNGetNumFriends, GetFriendInfo, BNSetCustomMessage
local gsub, format = gsub, format

function module:SetFriends()
	local stat = NewStat("Friends")

	if db.Friends.Enable and not stat.Created then
		if not InfoStats.GF or not InfoStats.GF.Created then module:SetGF() end
		local tooltip = InfoStats.GF

		tooltip.Friends = stat

		-- Local variables
		local friendOnline, friendOffline = ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h",""), ERR_FRIEND_OFFLINE_S:gsub("%%s","")

		-- Stat functions
		stat.UpdateText = function(self, updatePanel)
			local totalRF, onlineRF = BNGetNumFriends()
			self.text:SetText((db.Friends.ShowTotal and "Friends: %d/%d" or "Friends: %d"):format(onlineFriends + onlineRF, totalFriends + totalRF))
			if updatePanel then self:BN_FRIEND_INFO_CHANGED() end
		end

		stat.UpdateHints = function(self)
			if tooltip.onBlock then
				if db.Friends.ShowHints then
					if (select(1, self:GetCenter()) > UIParent:GetWidth()/2) then
						GameTooltip:SetOwner(self, isTop(self) and "ANCHOR_BOTTOMLEFT" or "ANCHOR_LEFT", -(tooltip:GetWidth()-self:GetWidth())/2, 0)
					else
						GameTooltip:SetOwner(self, isTop(self) and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_RIGHT", (tooltip:GetWidth()-self:GetWidth())/2, 0)
					end
					GameTooltip:AddLine("Hints:")
					GameTooltip:AddLine("|cffff8020Click|r to open Friends List.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020RightClick|r to add a Friend.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020Button4|r to toggle notes.", 0.2, 1, 0.2)
					GameTooltip:AddLine("|cffff8020Button5|r to toggle hints.", 0.2, 1, 0.2)
					GameTooltip:SetFrameLevel(2) -- keep tooltip above friends/guild list
					GameTooltip:Show()
				else
					GameTooltip:Hide()
				end
			end
		end

		-- Event functions
		stat.Events = {"FRIENDLIST_UPDATE", "CHAT_MSG_SYSTEM", "BN_FRIEND_INFO_CHANGED", "BN_CUSTOM_MESSAGE_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE",
			"BN_FRIEND_ACCOUNT_OFFLINE", "BN_CONNECTED", "BN_DISCONNECTED"}

		stat.FRIENDLIST_UPDATE = function(self)
			for k, v in pairs(friendEntries) do
				tooltip:del(v)
				friendEntries[k]=nil
			end
			totalFriends, onlineFriends = GetNumFriends()
			for i = 1, onlineFriends do
				local name, level, class, zone, connected, status, note = GetFriendInfo(i)
				friendEntries[i] = tooltip:new(tooltip.LocClassNames[class] or "", name or "", level or 0, zone or UNKNOWN, note or "|cffffcc00-", status, "", "", nil, i, name or "")
			end
			self:UpdateText()
			if not tooltip.IsGuild and tooltip:IsShown() then tooltip:Update() end
		end

		stat.CHAT_MSG_SYSTEM = function(self, msg)
			if msg:find(friendOnline) or msg:find(friendOffline) then ShowFriends() end
		end

		stat.BN_FRIEND_INFO_CHANGED = function(self)
			if tooltip:IsShown() then tooltip:Update() end
		end

		stat.BN_CUSTOM_MESSAGE_CHANGED = stat.BN_FRIEND_INFO_CHANGED
		stat.BN_FRIEND_ACCOUNT_ONLINE = stat.UpdateText
		stat.BN_FRIEND_ACCOUNT_OFFLINE = stat.UpdateText
		stat.BN_CONNECTED = stat.UpdateText
		stat.BN_DISCONNECTED = stat.UpdateText

		-- Script functions
		stat.OnEnable = function(self)
			StaticPopupDialogs.SET_BN_BROADCAST = {
				preferredIndex = 3,
				text = BN_BROADCAST_TOOLTIP,
				button1 = ACCEPT,
				button2 = CANCEL,
				hasEditBox = 1,
				editBoxWidth = 350,
				maxLetters = 127,
				OnAccept = function(self)
					BNSetCustomMessage(self.editBox:GetText())
				end,
				OnShow = function(self)
					self.editBox:SetText(select(4, BNGetInfo()))
					self.editBox:SetFocus()
				end,
				OnHide = ChatEdit_FocusActiveWindow,
				EditBoxOnEnterPressed = function(self)
					BNSetCustomMessage(self:GetText())
					self:GetParent():Hide()
				end,
				EditBoxOnEscapePressed = function(self)
					self:GetParent():Hide()
				end,
				timeout = 0,
				exclusive = 1,
				whileDead = 1,
				hideOnEscape = 1
			}

			ShowFriends()
			self:UpdateText()
		end

		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime

			if self.dt > 15 then
				ShowFriends()
			end
		end

		stat.OnClick = function(self, button)
			if button == "RightButton" or IsModifierKeyDown() then -- show add friend dialog box
				tooltip:Hide()
				FriendsFrameAddFriendButton:Click()
			elseif button == "LeftButton" then -- toggle friends list
				ToggleFriendsFrame(1)
			elseif button == "Button4" then -- toggle player notes
				db.Friends.ShowNotes = not db.Friends.ShowNotes
				tooltip:Update()
			elseif button == "Button5" then -- toggle mouseclick hints
				db.Friends.ShowHints = not db.Friends.ShowHints
				self:UpdateHints()
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				ShowFriends()
				tooltip:Anchor(self, false)
			end
		end
		stat.OnLeave = function()
			tooltip:OnStatLeave()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / INSTANCE / --
------------------------------------------------------

function module:SetInstance()
	local stat = NewStat("Instance")

	if db.Instance.Enable and not stat.Created then
		-- Localized functions
		local GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime = GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime
		local sort, time = sort, time

		-- Local variables
		local instances = {}
		stat.inst = instances

		-- Event functions
		stat.Events = {"PLAYER_ENTERING_WORLD", "UPDATE_INSTANCE_INFO", "INSTANCE_BOOT_START", "INSTANCE_BOOT_STOP"}

		stat.PLAYER_ENTERING_WORLD = function(self)
			RequestRaidInfo()
		end

		stat.UPDATE_INSTANCE_INFO = function(self)
			for i = 1, GetNumSavedInstances() do
				local name, id, reset, _, _, _, _, _, _, difficulty = GetSavedInstanceInfo(i)

				if reset and reset > 0 then
					instances[i] = {
						name = (name .. " - " .. difficulty),
						id = id,
						reset = reset,
						curTime = time(),
					}
				end
			end

			for i, v in ipairs(instances) do
				if time() >= (v.curTime + v.reset) then
					wipe(instances[i])
					instances[i] = nil
				end
			end

			sort(instances, function(a, b)
				return a.name < b.name
			end)

			-- Set value
			self.text:SetFormattedText("Instance [%d]", #instances)

			-- Update tooltip if open
			UpdateTooltip(self)
		end

		stat.INSTANCE_BOOT_START = stat.UPDATE_INSTANCE_INFO
		stat.INSTANCE_BOOT_STOP = stat.UPDATE_INSTANCE_INFO

		-- Script functions
		stat.OnEnable = function(self)
			self.text:SetText("Instance [0]")
			self:PLAYER_ENTERING_WORLD()
		end

		stat.OnClick = function(self, button) -- Toggle RaidInfoFrame
			if RaidInfoFrame:IsVisible() then
				RaidInfoFrame:Hide()
				if FriendsFrame:IsVisible() then
					FriendsFrame:Hide()
				end
			else
				ToggleFriendsFrame(4)
				RaidInfoFrame:Show()
			end
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				local numInstances = #instances

				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Instance Info:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				if numInstances == 0 then
					GameTooltip:AddLine("[No saved instances]")
				else
					GameTooltip:AddDoubleLine("Instance:", "Time Remaining:")
					GameTooltip:AddLine(" ")
				end

				for i = 1, numInstances do
					local instance = instances[i]
					if instance and (time() <= (instance.curTime + instance.reset)) then
						GameTooltip:AddDoubleLine(instance.name .. " (" .. instance.id .. ")", SecondsToTime((instance.curTime + instance.reset) - time()), 1,1,1, 1,1,1)
					end
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint:\n- Any Click to open Raid Info frame.", 0, 1, 0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end

------------------------------------------------------
-- / MEMORY USAGE / --
------------------------------------------------------

function module:SetMemory()
	local stat = NewStat("Memory")

	if db.Memory.Enable and not stat.Created then
		-- Localized functions
		local UpdateAddOnMemoryUsage, IsAddOnLoaded, InCombatLockdown = UpdateAddOnMemoryUsage, IsAddOnLoaded, InCombatLockdown
		local GetNumAddOns, GetAddOnInfo, GetAddOnMemoryUsage = GetNumAddOns, GetAddOnInfo, GetAddOnMemoryUsage
		local floor, format, sort, collectgarbage, select = floor, format, sort, collectgarbage, select

		-- Local variables
		local total
		local memory = {}

		-- Local functions
		local function formatMem(kb)
			if kb > 1024 then
				return format("%.1fmb", kb / 1024)
			else
				return format("%.1fkb", kb)
			end
		end

		-- Script functions
		stat.OnUpdate = function(self, deltaTime)
			if InCombatLockdown() then return end
			self.dt = self.dt + deltaTime
			if self.dt > 10 then
				self.dt = 0

				UpdateAddOnMemoryUsage()

				total = 0
				for i = 1, GetNumAddOns() do
					if not memory[i] then memory[i] = {} end

					memory[i][1] = select(2, GetAddOnInfo(i))
					memory[i][2] = GetAddOnMemoryUsage(i)
					memory[i][3] = IsAddOnLoaded(i)
					total = total + memory[i][2]
				end

				-- Set value
				self.text:SetText(formatMem(total))

				-- Update tooltip if open
				UpdateTooltip(self)
			end
		end

		stat.OnClick = function(self) -- run garbagecollect
			if InCombatLockdown() then return end
			collectgarbage("collect")
			self:OnUpdate(10)
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Memory:", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")

				sort(memory, function(a, b)
					if a and b then
						return a[2] > b[2]
					end
				end)

				for i = 1, #memory do
					if memory[i][3] then
						local red = memory[i][2]/total * 3
						local green = 2 - red
						GameTooltip:AddDoubleLine(memory[i][1], formatMem(memory[i][2]), 1,1,1, red,green,0)
					end
				end

				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine("Total Memory Usage:", formatMem(total), 1,1,1, .8,.8,.8)

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Hint: Click to Collect Garbage.", 0,1,0)
				GameTooltip:Show()
			end
		end
		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end


------------------------------------------------------
-- / WEAPON INFO USAGE / --
------------------------------------------------------

function module:SetWeaponInfo()
	local stat = NewStat("WeaponInfo")

	if db.WeaponInfo.Enable and not stat.Created then

		stat.Events = {"UNIT_INVENTORY_CHANGED", "UNIT_AURA"}

		stat.UNIT_INVENTORY_CHANGED = function(self, unit)
			--print(string.format("Called, unit == %s", tostring(unit)))
			--if unit ~= "player" then return end
			local mspeed, ospeed = UnitAttackSpeed("player")
			local text = string.format("MH: %.2fs", tonumber(mspeed))
			if ospeed ~= nil and ospeed ~= 0 then
				text = text .. string.format(", OH: %.2fs", tonumber(ospeed))
			end
			self.text:SetFormattedText(text)
			UpdateTooltip(self)
		end

		stat.UNIT_AURA = stat.UNIT_INVENTORY_CHANGED

		stat.OnEnable = function(self)
			self:UNIT_INVENTORY_CHANGED(self, "player")
		end

		-- Local variables
		local total
		local weaponinfo = {}

		stat.UpdateText = function(self)
			self.text:SetText("Test")
			UpdateTooltip(self)
		end

		stat.OnEnter = function(self)
			if CombatTips() then
				local mspeed, ospeed = UnitAttackSpeed("player")
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Weapon Speed:", 0.4, 0.78, 1)
				GameTooltip:AddLine("Main Hand Weapon: ", 0.4, 0.78, 1)
				GameTooltip:AddLine("Offhand Weapon: ", 0.4, 0.78, 1)
				GameTooltip:AddLine(" ")
				GameTooltip:Show()
			end
		end

		stat.OnLeave = function()
			GameTooltip:Hide()
		end

		stat.Created = true
	end
end


------------------------------------------------------
-- / Equipment Sets / --
------------------------------------------------------

function module:SetEquipmentSets()

	local stat = NewStat("EquipmentSets")

	if db.EquipmentSets.Enable and not stat.Created then

		stat.Events = {"UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"}

		stat.UNIT_INVENTORY_CHANGED = function(self, unit)
			local text = "No set equipped."
			for set = 1, C_EquipmentSet.GetNumEquipmentSets() do
				local name, _, setID, isEquipped, _, _, _, numMissing, _ = C_EquipmentSet.GetEquipmentSetInfo(set)
				if isEquipped then
					text = string.format("%s%s", db.EquipmentSets.Text, name)
				end
			end
			self.text:SetFormattedText(text)
			UpdateTooltip(self)
		end

		stat.PLAYER_EQUIPMENT_CHANGED = stat.UNIT_INVENTORY_CHANGED

		stat.OnEnable = function(self)
			self:UNIT_INVENTORY_CHANGED(self, "player")
		end

		--[[stat.OnEnter = function(self)
			if CombatTips() then
				GameTooltip:SetOwner(self, getOwnerAnchor(self))
				GameTooltip:ClearLines()
				GameTooltip:AddLine(text, 0.4, 0.78, 1)
				for set = 1,GetNumEquipmentSets() do
					local name, _, setID, isEquipped, _, _, _, numMissing, _ = GetEquipmentSetInfo(set)
					GameTooltip:AddLine(string.format("Equipment Set: %s, Equipped: %s", name, tostring(isEquipped)))
					if numMissing > 0 then
						GameTooltip:AddLine(string.format("   Missing Items: %s", tostring(missing)))
					end
				end
				GameTooltip:AddLine(" ")
				GameTooltip:Show()
			end
		end

		stat.OnLeave = function()
			GameTooltip:Hide()
		end]]--

		stat.Created = true
	end

end

------------------------------------------------------
-- / Loot Specialization / --
------------------------------------------------------

function module:SetLootSpec()

	local stat = NewStat("LootSpec")

	if db.LootSpec.Enable and not stat.Created then

		stat.Events = {"PLAYER_LOOT_SPEC_UPDATED"}

		stat.PLAYER_LOOT_SPEC_UPDATED = function(self, unit)
			local name = ""
			local lootspec = GetLootSpecialization()
			if lootspec == 0 then
			   local curspec = GetSpecialization()
			   _, name, _, _, _, _ = GetSpecializationInfo(curspec)
			else
			   _, name, _, _, _, _ = GetSpecializationInfoByID(lootspec)
			end
			text = string.format("%s%s", db.LootSpec.Text, name)
			self.text:SetFormattedText(text)
			UpdateTooltip(self)
		end

		stat.OnEnable = function(self)
			self:PLAYER_LOOT_SPEC_UPDATED(self, "player")
		end

		stat.Created = true
	end

end

------------------------------------------------------
-- / Movement Speed / --
------------------------------------------------------

function module:SetMoveSpeed()

	local stat = NewStat("MoveSpeed")

	if db.MoveSpeed.Enable and not stat.Created then

		local baseSpeed = BASE_MOVEMENT_SPEED
		-- Script functions
		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime
			if self.dt > 0.5 then
				self.dt = 0

				local unit = "player"
				if UnitInVehicle("player") then
					unit = "vehicle"
				end
				local speed, runSpeed = GetUnitSpeed(unit)
				if speed == 0 then
					speed = runSpeed
				end

				-- Set value
				self.text:SetText(format("Speed: %d%%", speed / baseSpeed * 100))
			end
		end

		stat.Created = true
	end

end

------------------------------------------------------
-- / STAT FUNCTIONS / --
------------------------------------------------------

local function EnableStat(stat)
	module["Set"..stat]()
	if InfoStats[stat] then
		if InfoStats[stat].Created then
			if not InfoStats[stat].Hidden then InfoStats[stat]:Show() end
			InfoStats[stat]:Enable()
		else
			InfoStats[stat]:Hide()
		end
	end
end

local function DisableStat(stat)
	if not InfoStats[stat] or not InfoStats[stat].Created then return end
	InfoStats[stat]:UnregisterAllEvents()
	InfoStats[stat]:SetScript("OnUpdate", nil)
	if InfoStats[stat].OnDisable then InfoStats[stat]:OnDisable() end
	InfoStats[stat]:Hide()
end

local function ToggleStat(stat)
	if db[stat] and not db[stat].Enable then
		DisableStat(stat)
	else
		EnableStat(stat)
	end
end

local function ResetStat(stat)
	if not InfoStats[stat] or not InfoStats[stat].Created then return end
	if InfoStats[stat].text then
		SetInfoPanel(stat)
		SetFontSettings(stat)
	end
	if InfoStats[stat].OnReset then InfoStats[stat]:OnReset() end
	if InfoStats[stat].OnUpdate then InfoStats[stat]:OnUpdate(100) end
end





------------------------------------------------------
-- / MODULE FUNCTIONS / --
------------------------------------------------------

module.optionsName = "Info Text"
module.childGroups = "select"
module.defaults = {
	profile = {
		Enable = true,
		CombatLock = false,
		Bags = {
			Enable = true,
			X = 200,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
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
			Time24 = GetLocale() ~= "enUS",
			ShowInstanceDifficulty = true,
			X = -55,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
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
			Display = 0,
			DisplayLimit = 40,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		MoveSpeed = {
			Enable = true,
			X = -590,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
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
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		Durability = {
			Enable = true,
			X = 345,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		FPS = {
			Enable = true,
			MSValue = "Both",
			X = 500,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
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
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			ShowTotal = false,
			ShowHints = true,
			ShowNotes = true,
			sortCols = {"name", "name", "name"},
			sortASC = {true, true, true},
		},
		Gold = {
			Enable = true,
			ServerTotal = false,
			X = 55,
			Y = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			ColorType = false,
			Shorten = false,
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			PlayerReset = myPlayerName,
		},
		Guild = {
			Enable = true,
			X = -485,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			ShowTotal = false,
			hideRealm = true,
			ShowHints = true,
			ShowNotes = true,
			sortCols = {"class", "name", "name"},
			sortASC = {true, true, true},
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
			FontSize = 12,
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
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		WeaponInfo = {
			Enable = false,
			X = -350,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		EquipmentSets = {
			Enable = false,
			Text = "Equipped Set: ",
			X = -225,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
		LootSpec = {
			Enable = false,
			Text = "Loot Spec: ",
			X = -75,
			Y = 0,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
			Font = "vibroceb",
			FontSize = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
		},
	},
	realm = {
		Gold = {
			[myPlayerFaction] = {
				[myPlayerName] = 0,
			},
			[otherFaction] = {},
		},
	}
}


function module:LoadOptions()
	-- Local variables
	local msvalues = {"Both", "Home", "World"}
	local fontflags = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"}

	db.Gold.PlayerReset = dbd.Gold.PlayerReset
	for _, faction in pairs(db.realm.Gold) do
		for player, gold in pairs(faction) do
			goldPlayerArray[player] = player
		end
	end

	-- Local functions
	local function copyDefaults(dest, src)
		for k, v in pairs(src) do
			if type(v) == "table" then
				if not rawget(dest, k) then rawset(dest, k, {}) end
				if type(dest[k]) == "table" then
					copyDefaults(dest[k], v)
				end
			else
				if rawget(dest, k) == nil then
					rawset(dest, k, v)
				end
			end
		end
	end
	local function resetGold()
		local stat = InfoStats.Gold
		if not stat then return end

		if db.Gold.PlayerReset == "ALL" then
			stat:ResetGold(db.Gold.PlayerReset)
		else
			for faction, data in pairs(db.realm.Gold) do
				if data[db.Gold.PlayerReset] then
					stat:ResetGold(db.Gold.PlayerReset, faction)
					break
				end
			end
		end

		db.Gold.PlayerReset = dbd.Gold.PlayerReset
	end

	local function StatDisabled(info)
		for i, v in ipairs(info) do
			if v == module:GetName() then
				return not db[info[i+1]].Enable
			end
		end
	end

	-- Local options creators.
	local function NameLabel(info, statName) -- (info [, statName])
		statName = statName or info[#info]
		return (db[info[#info]].Enable and statName or ("|cff888888"..statName.."|r"))
	end
	local function PositionOptions(order, statName) -- (order [, statName])
		local horizontal = {"Left", "Right"}
		local vertical = {"Top", "Bottom"}

		local option = {
			name = "Info Panel and Position",
			type = "group",
			order = order,
			disabled = StatDisabled,
			guiInline = true,
			args = {
				X = {
					name = "X Offset",
					desc = function(info)
						return ("X offset for the " .. (statName or info[#info-2]) .. " info text.\n\n" ..
								"Note:\nPositive values = right\nNegative values = left\n" ..
								"Default: " .. dbd[info[#info-2]].X
						)
					end,
					type = "input",
					order = 1,
					get = function(info) return tostring(db[info[#info-2]].X) end,
					set = function(info, value)
						if value == nil or value == "" then value = "0" end
						db[info[#info-2]].X = tonumber(value)
						SetInfoPanel(info[#info-2])
					end,
				},
				Y = {
					name = "Y Offset",
					desc = function(info)
						return ("Y offset for the " .. (statName or info[#info-2]) .. " info text.\n\n" ..
								"Note:\nPositive values = up\nNegative values = down\n" ..
								"Default: " .. dbd[info[#info-2]].Y
						)
					end,
					type = "input",
					order = 2,
					disabled = function(info) return not db[info[#info-2]].Enable end,
					get = function(info) return tostring(db[info[#info-2]].Y) end,
					set = function(info, value)
						if value == nil or value == "" then value = "0" end
						db[info[#info-2]].Y = tonumber(value)
						SetInfoPanel(info[#info-2])
					end,
				},
				Horizontal = {
					name = "Horizontal",
					desc = function(info)
						return ("Select the horizontal panel that the " .. (statName or info[#info-2]) .. " info text will be anchored to.\n\n" ..
								"Default: " .. dbd[info[#info-2]].InfoPanel.Horizontal
						)
					end,
					type = "select",
					order = 3,
					values = horizontal,
					get = function(info)
						for k, v in pairs(horizontal) do
							if db[info[#info-2]].InfoPanel.Horizontal == v then return k end
						end
					end,
					set = function(info, value)
						db[info[#info-2]].InfoPanel.Horizontal = horizontal[value]
						db[info[#info-2]].X = 0
						SetInfoPanel(info[#info-2])
					end,
				},
				Vertical = {
					name = "Vertical",
					desc = function(info)
						return ("Select the vertical panel that the " .. (statName or info[#info-2]) .. " info text will be anchored to.\n\n" ..
								"Default: " .. dbd[info[#info-2]].InfoPanel.Vertical
						)
					end,
					type = "select",
					order = 3,
					values = vertical,
					get = function(info)
						for k, v in pairs(vertical) do
							if db[info[#info-2]].InfoPanel.Vertical == v then return k end
						end
					end,
					set = function(info, value)
						db[info[#info-2]].InfoPanel.Vertical = vertical[value]
						db[info[#info-2]].Y = 0
						SetInfoPanel(info[#info-2])
					end,
				},
			}
		}

		return option
	end
	local function FontOptions(order, statName) -- (order [, statName])
		local option = {
			name = "Font Settings",
			type = "group",
			disabled = StatDisabled,
			order = order,
			guiInline = true,
			args = {
				FontSize = {
					name = "Size",
					desc = function(info)
						return ("Choose your " .. (statName or info[#info-2]) .. " info text's fontsize.\n\n" ..
								"Default: " .. dbd[info[#info-2]].FontSize
						)
					end,
					type = "range",
					order = 1,
					min = 1,
					max = 40,
					step = 1,
					get = function(info) return db[info[#info-2]].FontSize end,
					set = function(info, value)
						db[info[#info-2]].FontSize = value
						SetFontSettings(info[#info-2])
					end,
				},
				Color = {
					name = "Color",
					desc = function(info)
						local defaults = dbd[info[#info-2]].Color
						return ("Choose your " .. (statName or info[#info-2]) .. " info text's colour.\n\n" ..
								"Defaults:\nr = " .. defaults.r .. "\ng = " .. defaults.g .. "\nb = " .. defaults.b .. "\na = " .. defaults.a
						)
					end,
					type = "color",
					hasAlpha = true,
					get = function(info)
						local color = db[info[#info-2]].Color
						return color.r, color.g, color.b, color.a
					end,
					set = function(info, r, g, b, a)
						local color = db[info[#info-2]].Color
						color.r = r
						color.g = g
						color.b = b
						color.a = a

						SetFontSettings(info[#info-2])
					end,
					order = 2,
				},
				Font = {
					name = "Font",
					desc = function(info)
						return ("Choose your " .. (statName or info[#info-2]) .. " info text's font.\n\n" ..
								"Default: " .. dbd[info[#info-2]].Font
						)
					end,
					type = "select",
					dialogControl = "LSM30_Font",
					values = widgetLists.font,
					get = function(info) return db[info[#info-2]].Font end,
					set = function(info, value)
						db[info[#info-2]].Font = value
						SetFontSettings(info[#info-2])
					end,
					order = 3,
				},
				Outline = {
					name = "Font Flag",
					desc = function(info)
						return ("Choose your " .. (statName or info[#info-2]) .. " info text's font flag.\n\n" ..
								"Default: " .. dbd[info[#info-2]].Outline
						)
					end,
					type = "select",
					values = fontflags,
					get = function(info)
						for k, v in pairs(fontflags) do
							if db[info[#info-2]].Outline == v then
								return k
							end
						end
					end,
					set = function(info, value)
						db[info[#info-2]].Outline = fontflags[value]
						SetFontSettings(info[#info-2])
					end,
					order = 4,
				},
			},
		}

		return option
	end
	local function ResetOption(order)
		local option = {
			name = "Reset Settings",
			type = "execute",
			disabled = StatDisabled,
			order = order,
			func = function(info)
				local statDB = info[#info-1]

				for k, v in pairs(db[statDB]) do
					db[statDB][k] = nil
				end
				copyDefaults(db[statDB], dbd[statDB])
				db[statDB].Enable = true

				ResetStat(statDB)
				DisableStat(statDB)
				EnableStat(statDB)
			end
		}

		return option
	end

	-- Options table
	local options = {
		CombatLock = {
			name = "Combat Lock Down",
			desc = "Hide tooltip info for datatext stats while in combat.",
			type = "toggle",
			get = function() return db.CombatLock end,
			set = function(info, value) db.CombatLock = value end,
			order = 1,
		},
		Bags = {
			name = NameLabel,
			type = "group",
			order = 2,
			args = {
				Header = {
					name = "Bags",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Bag Status or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Bags.Enable end,
					set = function(info, value)
						db.Bags.Enable = value
						ToggleStat("Bags")
					end,
					order = 2,
				},
				Position = PositionOptions(3),
				Font = FontOptions(4),
				Reset = ResetOption(5),
			},
		},
		Clock = {
			name = NameLabel,
			type = "group",
			order = 3,
			args = {
				Header = {
					name = "Clock",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Clock or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Clock.Enable end,
					set = function(info, value)
						db.Clock.Enable = value
						ToggleStat("Clock")
					end,
					order = 2,
				},
				ShowInstanceDifficulty = {
					name = "Show Instance Difficulty",
					desc = "Whether you want to show the Instance Difficulty or not.",
					type = "toggle",
					width = "full",
					disabled = StatDisabled,
					get = function() return db.Clock.ShowInstanceDifficulty end,
					set = function(info, value)
						db.Clock.ShowInstanceDifficulty = value
						InfoStats.Clock:OnEnable()
					end,
					order = 3,
				},
				EnableLocalTime = {
					name = "Local Time",
					desc = "Whether you want to show your Local Time or Server Time.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Clock.LocalTime end,
					set = function(info, value) db.Clock.LocalTime = value end,
					order = 4,
				},
				EnableTime24 = {
					name = "24h Clock",
					desc = "Whether you want to show 24 or 12 hour Clock.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Clock.Time24 end,
					set = function(info, value) db.Clock.Time24 = value end,
					order = 5,
				},
				Position = PositionOptions(6),
				Font = FontOptions(7),
				Reset = ResetOption(8),
			},
		},
		Currency = {
			name = NameLabel,
			type = "group",
			order = 4,
			args = {
				Header = {
					name = "Currency",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Currency Info or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Currency.Enable end,
					set = function(info, value)
						db.Currency.Enable = value
						ToggleStat("Currency")
					end,
					order = 2,
				},				
				Display = {
					name = "Currency On Display",
					desc = "Select the currency to display",
					type = "select",
					order = 3,
					values = function() return (InfoStats.Currency and InfoStats.Currency.Created and InfoStats.Currency:Currencies()) or {"None"} end,
					get = function(info)
						return db.Currency.Display
					end,
					set = function(info, value)
						db.Currency.Display = value
						if InfoStats.Currency and InfoStats.Currency.Created then InfoStats.Currency:CURRENCY_DISPLAY_UPDATE() end
					end,
				},
				DisplayLimit = LUI:NewSlider("Length Limit", "Set the length limit of the currency's text display.", 4, db.Currency, "DisplayLimit", dbd.Currency, 0, 40, 1,
					function()
						if InfoStats.Currency and InfoStats.Currency.Created then InfoStats.Currency:CURRENCY_DISPLAY_UPDATE() end
					end),
				Position = PositionOptions(5),
				Font = FontOptions(6),
				Reset = ResetOption(7),
			},
		},
		MoveSpeed = {
			name = NameLabel,
			type = "group",
			order = 4,
			args = {
				Header = {
					name = "Movement Speed",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show Movement Speed info or not.",
					type = "toggle",
					width = "full",
					get = function() return db.MoveSpeed.Enable end,
					set = function(info, value)
						db.MoveSpeed.Enable = value
						ToggleStat("MoveSpeed")
					end,
					order = 2,
				},
				Position = PositionOptions(5),
				Font = FontOptions(6),
				Reset = ResetOption(7),
			},
		},
		DualSpec = {
			name = function(info) return NameLabel(info, "Dual Spec") end,
			type = "group",
			order = 6,
			args = {
				Header = {
					name = "Dual Spec",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Spec or not. (Only for level 10+)",
					type = "toggle",
					width = "full",
					get = function() return db.DualSpec.Enable end,
					set = function(info, value)
						db.DualSpec.Enable = value
						ToggleStat("DualSpec")
					end,
					order = 2,
				},
				ShowSpentPoints = {
					name = "Spent points",
					desc = "Show spent talent points \"(x/x/x)\".",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.DualSpec.ShowSpentPoints end,
					set = function(info, value)
						db.DualSpec.ShowSpentPoints = value
						InfoStats.DualSpec:PLAYER_TALENT_UPDATE()
					end,
					order = 3,
				},
				Position = PositionOptions(4, "Dual Spec"),
				Font = FontOptions(5, "Dual Spec"),
				Reset = ResetOption(6),
			},
		},
		Durability = {
			name = NameLabel,
			type = "group",
			order = 7,
			args = {
				Header = {
					name = "Durability",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Durability or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Durability.Enable end,
					set = function(info, value)
						db.Durability.Enable = value
						ToggleStat("Durability")
					end,
					order = 2,
				},
				Position = PositionOptions(3),
				Font = FontOptions(4),
				Reset = ResetOption(5),
			},
		},
		FPS = {
			name = function(info) return NameLabel(info, "FPS / MS") end,
			type = "group",
			order = 9,
			args = {
				Header = {
					name = "FPS / MS",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your FPS / MS or not.",
					type = "toggle",
					width = "full",
					get = function() return db.FPS.Enable end,
					set = function(info, value)
						db.FPS.Enable = value
						ToggleStat("FPS")
					end,
					order = 2,
				},
				MSValue = {
					name = "MS Value",
					desc = "Wether you want your MS to show World, Home or both latency values.\n\nDefault: "..dbd.FPS.MSValue,
					type = "select",
					disabled = StatDisabled,
					values = msvalues,
					get = function()
						for k, v in pairs(msvalues) do
							if db.FPS.MSValue == v then return k end
						end
					end,
					set = function(info, value) db.FPS.MSValue = msvalues[value] end,
					order = 3,
				},
				Position = PositionOptions(4, "FPS / MS"),
				Font = FontOptions(5, "FPS / MS"),
				Reset = ResetOption(6),
			},
		},
		Friends = {
			name = NameLabel,
			type = "group",
			order = 8,
			args = {
				Header = {
					name = "Friends",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Friends Status or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Friends.Enable end,
					set = function(info, value)
						db.Friends.Enable = value
						ToggleStat("Friends")
					end,
					order = 2,
				},
				ShowTotal = {
					name = "Show Total",
					desc = "Whether you want to show total number of Friends online or not.",
					type = "toggle",
					width = "full",
					disabled = StatDisabled,
					get = function() return db.Friends.ShowTotal end,
					set = function(info, value)
						db.Friends.ShowTotal = value
						InfoStats.Friends:UpdateText()
						ShowFriends()
					end,
					order = 3,
				},
				ShowHints = {
					name = "Show Hints",
					desc = "Whether you want to show mouseclick hints or not.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Friends.ShowHints end,
					set = function(info, value) db.Friends.ShowHints = value end,
					order = 4,
				},
				ShowNotes = {
					name = "Show Notes",
					desc = "Whether you want to show friend notes or not.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Friends.ShowNotes end,
					set = function(info, value) db.Friends.ShowNotes = value end,
					order = 5,
				},
				Position = PositionOptions(6),
				Font = FontOptions(7),
				Reset = ResetOption(8),
			},
		},
		Gold = {
			name = NameLabel,
			type = "group",
			order = 10,
			args = {
				Header = {
					name = "Gold",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Gold Amount or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Gold.Enable end,
					set = function(info, value)
						db.Gold.Enable = value
						ToggleStat("Gold")
					end,
					order = 2,
				},
				ServerTotal = {
					name = "Server Total",
					desc = "Whether you want your gold display to show your server total gold, or your current toon's gold.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Gold.ServerTotal end,
					set = function(info, value)
						db.Gold.ServerTotal = value
						InfoStats.Gold:PLAYER_MONEY()
					end,
					order = 3,
				},
				ColorType = {
					name = "Color By Type",
					desc = "Weather or not to color the coin letters by the type of coin.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Gold.ColorType end,
					set = function(info, value)
						db.Gold.ColorType = value
						InfoStats.Gold:PLAYER_MONEY()
					end,
					order = 4,
				},
				Shorten = {
					name = "Shorten gold value",
					desc = "Whether you want to shorten your gold number (8000 to 8k and etc...) or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Gold.Shorten end,
					set = function(info, value)
						db.Gold.Shorten = value
						InfoStats.Gold:PLAYER_MONEY()
					end,
					order = 5,
				},
				GoldPlayerReset = {
					name = "Reset Player",
					desc = "Choose the player you want to clear Gold data for.\n",
					type = "select",
					disabled = StatDisabled,
					order = 6,
					values = goldPlayerArray,
					get = function()
						return goldPlayerArray[db.Gold.PlayerReset] or "ALL"
					end,
					set = function(info, value)
						db.Gold.PlayerReset = value
					end,
				},
				GoldReset = {
					name = "Reset",
					type = "execute",
					disabled = StatDisabled,
					order = 7,
					func = resetGold,
				},
				Position = PositionOptions(8),
				Font = FontOptions(9),
				Reset = ResetOption(10),
			},
		},
		Guild = {
			name = NameLabel,
			type = "group",
			order = 11,
			args = {
				Header = {
					name = "Guild",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Guild Status or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Guild.Enable end,
					set = function(info, value)
						db.Guild.Enable = value
						ToggleStat("Guild")
					end,
					order = 2,
				},
				ShowTotal = {
					name = "Show Total",
					desc = "Whether you want to show total number of Guildmates online or not.",
					type = "toggle",
					--width = "full",
					disabled = StatDisabled,
					get = function() return db.Guild.ShowTotal end,
					set = function(info, value)
						db.Guild.ShowTotal = value
						InfoStats.Guild:UpdateText()
						GuildRoster()
					end,
					order = 3,
				},
				hideRealm = {
					name = "Hide Realm Names",
					desc = "Whether you want to show realm name of Guildmates next to their name.",
					type = "toggle",
					--width = "full",
					disabled = StatDisabled,
					get = function() return db.Guild.hideRealm end,
					set = function(info, value)
						db.Guild.hideRealm = value
						InfoStats.Guild:GUILD_ROSTER_UPDATE()
						InfoStats.Guild:UpdateText()
						GuildRoster()
					end,
					order = 4,
				},
				ShowHints = {
					name = "Show Hints",
					desc = "Whether you want to show mouseclick hints or not.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Guild.ShowHints end,
					set = function(info, value) db.Guild.ShowHints = value end,
					order = 4,
				},
				ShowNotes = {
					name = "Show Notes",
					desc = "Whether you want to show guild/officer notes or not.",
					type = "toggle",
					disabled = StatDisabled,
					get = function() return db.Guild.ShowNotes end,
					set = function(info, value) db.Guild.ShowNotes = value end,
					order = 5,
				},
				Position = PositionOptions(6),
				Font = FontOptions(7),
				Reset = ResetOption(8),
			},
		},
		Instance = {
			name = function(info) return NameLabel(info, "Instance Info") end,
			type = "group",
			order = 12,
			args = {
				Header = {
					name = "Instance",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Instance Info or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Instance.Enable end,
					set = function(info, value)
						db.Instance.Enable = value
						ToggleStat("Instance")
					end,
					order = 2,
				},
				Position = PositionOptions(3, "Instance Info"),
				Font = FontOptions(4, "Instance Info"),
				Reset = ResetOption(5),
			},
		},
		Memory = {
			name = function(info) return NameLabel(info, "Memory Usage") end,
			type = "group",
			order = 13,
			args = {
				Header = {
					name = "Memory Usage",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Memory Usage or not.",
					type = "toggle",
					width = "full",
					get = function() return db.Memory.Enable end,
					set = function(info, value)
						db.Memory.Enable = value
						ToggleStat("Memory")
					end,
					order = 2,
				},
				Position = PositionOptions(3, "Memory Usage"),
				Font = FontOptions(4, "Memory Usage"),
				Reset = ResetOption(5),
			},
		},
		WeaponInfo = {
			name = function(info) return NameLabel(info, "Weapon Information") end,
			type = "group",
			order = 14,
			args = {
				Header = {
					name = "Weapon Information",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Weapon Information or not.",
					type = "toggle",
					width = "full",
					get = function() return db.WeaponInfo.Enable end,
					set = function(info, value)
						db.WeaponInfo.Enable = value
						ToggleStat("WeaponInfo")
					end,
					order = 2,
				},
				Position = PositionOptions(3, "Weapon Information"),
				Font = FontOptions(4, "Weapon Information"),
				Reset = ResetOption(5),
			},
		},
		EquipmentSets = {
			name = function(info) return NameLabel(info, "Equipment Sets") end,
			type = "group",
			order = 15,
			args = {
				Header = {
					name = "Weapon Information",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your Equipment Set Information or not.",
					type = "toggle",
					width = "full",
					get = function() return db.EquipmentSets.Enable end,
					set = function(info, value)
						db.EquipmentSets.Enable = value
						ToggleStat("EquipmentSets")
					end,
					order = 2,
				},
				Text = {
					name = "Text Prefix",
					desc = "Prefix for equipment set display.",
					type = "input",
					disabled = StatDisabled,
					width = "full",
					get = function() return db.EquipmentSets.Text end,
					set = function(info, value)
						db.EquipmentSets.Text = value
						ToggleStat("EquipmentSets")
					end,
					order = 3,
				},
				Position = PositionOptions(4, "Equipment Information"),
				Font = FontOptions(5, "Equipment Information"),
				Reset = ResetOption(6),
			},
		},
		LootSpec = {
			name = function(info) return NameLabel(info, "Loot Spec") end,
			type = "group",
			order = 16,
			args = {
				Header = {
					name = "Loot Spec",
					type = "header",
					order = 1,
				},
				Enable = {
					name = "Enable",
					desc = "Whether you want to show your current loot spec or not.",
					type = "toggle",
					width = "full",
					get = function() return db.LootSpec.Enable end,
					set = function(info, value)
						db.LootSpec.Enable = value
						ToggleStat("LootSpec")
					end,
					order = 2,
				},
				Text = {
					name = "Text Prefix",
					desc = "Prefix for loot spec display.",
					type = "input",
					disabled = StatDisabled,
					width = "full",
					get = function() return db.LootSpec.Text end,
					set = function(info, value)
						db.LootSpec.Text = value
						ToggleStat("LootSpec")
					end,
					order = 3,
				},
				Position = PositionOptions(4, "Loot Spec"),
				Font = FontOptions(5, "Loot Spec"),
				Reset = ResetOption(6),
			},
		},
	}

	return options
end

function module:Refresh()
	for stat in pairs(InfoStats) do
		ResetStat(stat)
		DisableStat(stat)
		EnableStat(stat)
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)

end

function module:OnEnable()
	SetInfoTextFrames()
	EnableStat("Bags")
	EnableStat("Clock")
	EnableStat("Currency")
	EnableStat("DualSpec")
	EnableStat("Durability")
	EnableStat("FPS")
	EnableStat("Gold")
	EnableStat("GF")
	EnableStat("Guild")
	EnableStat("Friends")
	EnableStat("Instance")
	EnableStat("Memory")
	EnableStat("WeaponInfo")
	EnableStat("EquipmentSets")
	EnableStat("LootSpec")
	EnableStat("MoveSpeed")
end

function module:OnDisable()
	DisableStat("FPS")
	DisableStat("Memory")
	DisableStat("Bags")
	DisableStat("Durability")
	DisableStat("Gold")
	DisableStat("Clock")
	DisableStat("Guild")
	DisableStat("Friends")
	DisableStat("GF")
	DisableStat("WeaponInfo")
	DisableStat("EquipmentSet")
	DisableStat("LootSpec")
	DisableStat("MoveSpeed")
	LUI_Infos_TopLeft:Hide()
	LUI_Infos_TopRight:Hide()
	LUI_Infos_BottomLeft:Hide()
	LUI_Infos_BottomRight:Hide()
end
