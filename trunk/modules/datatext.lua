--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: datatext.lua
	Description: Datatext Molule for Durability, Gold, Latency, Fps, MS, Friends, Guild, Clock, Bags...
	Version....: 1.6c
	Rev Date...: 08/06/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Hix
		-  a: Hix
		v1.2: Hix
		-  a: Hix
		-  b: Hix
		v1.3: Hix
		-  a: Hix
		-  b: Hix
		v1.4: Zista
		v1.5: Zista
		v1.6: Zista
		-  a: Hix
		-  b: Hix
		-  c: Hix
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Infotext", "AceHook-3.0")
local version = 3316

local db
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local myPlayerRealm = GetRealmName()
local myPlayerFaction = UnitFactionGroup("player")
local myPlayerName = UnitName("player")
local playerReset = ""
local BUTTON_HEIGHT, ICON_SIZE, GAP, TEXT_OFFSET, MAX_ENTRIES = 15, 13, 10, 5
local _,L = ...
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
do
	local tables = setmetatable( {}, { __mode = "k" } )

	new = function(...)
		local t = next(tables)
		if t then tables[t] = nil else t = {} end
		for i=1, select("#",...) do t[i] = select(i,...) end
		return t
	end

	del = function(t)
		tables[wipe(t)] = true
	end

end
for eng, loc in next, LOCALIZED_CLASS_NAMES_MALE   do L[loc] = eng end
for eng, loc in next, LOCALIZED_CLASS_NAMES_FEMALE do L[loc] = eng end


function module:SetDataTextFrames()
	local infos_left = LUI:CreateMeAFrame("FRAME","infos_left",UIParent,100,20,1,"HIGH",0,"TOPLEFT",UIParent,"TOPLEFT",200,3,1)
	infos_left:SetAlpha(1)
	infos_left:Show()
	
	local infos_right = LUI:CreateMeAFrame("FRAME","infos_right",UIParent,100,20,1,"HIGH",0,"TOPRIGHT",UIParent,"TOPRIGHT",0,3,1)
	infos_right:SetAlpha(1)
	infos_right:Show()
end

------------------------------------------------------
-- / FPS & MS / --
------------------------------------------------------

function module:SetFPS()
	if db.Infotext.Fps.Enable == false then return end
	
	local Stat1 = CreateFrame("Frame", "LUI_Info_FPS", infos_left)
	Stat1:EnableMouse(true)
	
	Text_fps  = infos_left:CreateFontString(nil, "OVERLAY")
	Text_fps:SetFont(LSM:Fetch("font", db.Infotext.Fps.Font), db.Infotext.Fps.Size, db.Infotext.Fps.Outline)
	Text_fps:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Fps.X, db.Infotext.Fps.Y)
	Text_fps:SetHeight(db.Infotext.Fps.Size)
	Text_fps:SetTextColor(db.Infotext.Fps.Color.r, db.Infotext.Fps.Color.g, db.Infotext.Fps.Color.b, db.Infotext.Fps.Color.a)
	
	-- Localise functions.
	local floor, GetFramerate, select, GetNetStats = floor, GetFramerate, select, GetNetStats
	
	local int = 1
	local function Update(self, t)
		int = int - t
		if int < 0 then
			int = 1
			
			-- Set text.
			if db.Infotext.Fps.MSValue == "BOTH" then
				local _,_, home, world = GetNetStats()
				Text_fps:SetFormattedText("%dfps   %dms | %dms", floor(GetFramerate()), home, world)
			else
				Text_fps:SetFormattedText("%dfps   %dms", floor(GetFramerate()), select((db.Infotext.Fps.MSValue == "HOME" and 3) or 4, GetNetStats()))
			end
			self:SetAllPoints(Text_fps)
		end		
	end
	
	local function ColourMS(ms)
		local t = ms / 400
		local r = t
		local g = 1 - t
		
		return r, g, 0
	end
	
	local function ColourFPS(fps)
		local t = fps / 60
		local r = 1 - t
		local g = t
		
		return r, g, 0
	end

	Stat1:SetScript("OnUpdate", Update) 
	Stat1:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("FPS & MS:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")
			
			-- Fps stats.
			local fps = floor(GetFramerate())
			GameTooltip:AddLine("FPS:")
			GameTooltip:AddDoubleLine("Current:", fps, 1, 1, 1, ColourFPS(fps))
			GameTooltip:AddLine(" ")
			
			
			local bandIn, bandOut, home, world = GetNetStats()			
			GameTooltip:AddLine("Latency:")
			GameTooltip:AddDoubleLine("Home:", home, 1, 1, 1, ColourMS(home))
			GameTooltip:AddDoubleLine("World:", world, 1, 1, 1, ColourMS(world))
			GameTooltip:AddLine(" ")
			
			GameTooltip:AddLine("Bandwidth:")
			GameTooltip:AddDoubleLine("Current Down:", format("%.2f KB/s", bandIn), 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Current Up:", format("%.2f KB/s", bandOut), 1, 1, 1, 1, 1, 1)
			
			GameTooltip:Show()
		end
	end)
	Stat1:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Update(Stat1, 10)
end

------------------------------------------------------
-- / MEMORY USAGE / --
------------------------------------------------------

function module:SetMemoryUsage()
	if db.Infotext.Memory.Enable == false then return end
	
	local Stat2 = CreateFrame("Frame", "LUI__Info_Memory", infos_left)
	Stat2:EnableMouse(true)

	Text_mb  = infos_left:CreateFontString(nil, "OVERLAY")
	Text_mb:SetFont(LSM:Fetch("font", db.Infotext.Memory.Font), db.Infotext.Memory.Size, db.Infotext.Memory.Outline)
	Text_mb:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Memory.X, db.Infotext.Memory.Y)
	Text_mb:SetHeight(db.Infotext.Memory.Size)
	Text_mb:SetTextColor(db.Infotext.Memory.Color.r, db.Infotext.Memory.Color.g, db.Infotext.Memory.Color.b, db.Infotext.Memory.Color.a)

	-- Localised functions
	local floor, format, sort = floor, string.format, table.sort

	local function formatMem(memory)
		if memory > 1024 then
			return format("%.1fmb", memory / 1024)
		else
			return format("%.1fkb", memory)
		end
	end

	local Total, Mem, MEMORY_TEXT, LATENCY_TEXT
	local Memory = {}
	local function RefreshMem(self)
		UpdateAddOnMemoryUsage()
		Total = 0
		for i = 1, GetNumAddOns() do
			if not Memory[i] then Memory[i] = {} end
			
			Mem = GetAddOnMemoryUsage(i)
			Memory[i][1] = select(2, GetAddOnInfo(i))
			Memory[i][2] = Mem
			Memory[i][3] = IsAddOnLoaded(i)
			Total = Total + Mem
		end
		
		MEMORY_TEXT = formatMem(Total)
		sort(Memory, function(a, b)
			if a and b then
				return a[2] > b[2]
			end
		end)
		
		Text_mb:SetText(MEMORY_TEXT)
		self:SetAllPoints(Text_mb)
	end
		
	local int = 10
	local function Update(self, t)
		int = int - t
		if int < 0 then
			RefreshMem(self)
			int = 10
		end
	end
	
	Stat2:SetScript("OnMouseDown", function() collectgarbage("collect") Update(Stat2, 10) end)
	Stat2:SetScript("OnUpdate", Update) 
	Stat2:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Memory:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")
			for i = 1, #Memory do
				if Memory[i][3] then 
					local red = Memory[i][2]/Total * 2
					local green = 1 - red
					GameTooltip:AddDoubleLine(Memory[i][1], formatMem(Memory[i][2]), 1, 1, 1, red, green+1, 0)						
				end
			end
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine("Total Memory Usage:",formatMem(Total), 1, 1, 1,0.8, 0.8, 0.8)
			
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Hint: Click to Collect Garbage.", 0.0, 1.0, 0.0)
			GameTooltip:Show()
		end
	end)
	Stat2:SetScript("OnLeave", function() GameTooltip:Hide() end)
	
	Update(Stat2, 20)
end

------------------------------------------------------
-- / BAGS / --
------------------------------------------------------

function module:SetBags(refresh)
	if db.Infotext.Bags.Enable == false then return end
	
	local Stat4 = CreateFrame("Frame", "LUI_Info_Bags", infos_left)
	Stat4:EnableMouse(true)

	Text_bags  = infos_left:CreateFontString(nil, "OVERLAY")
	Text_bags:SetFont(LSM:Fetch("font", db.Infotext.Bags.Font), db.Infotext.Bags.Size, db.Infotext.Bags.Outline)
	Text_bags:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Bags.X, db.Infotext.Bags.Y)
	Text_bags:SetHeight(db.Infotext.Bags.Size)
	Text_bags:SetTextColor(db.Infotext.Bags.Color.r, db.Infotext.Bags.Color.g, db.Infotext.Bags.Color.b, db.Infotext.Bags.Color.a)
	
	-- Localise functions
	local GetContainerNumFreeSlots, GetContainerNumSlots = GetContainerNumFreeSlots, GetContainerNumSlots
	
	local function OnEvent(self, event, ...)
		local free, total, used = 0, 0, 0
		for i = 0, NUM_BAG_SLOTS do
			free, total = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i)
		end
		used = total - free
		Text_bags:SetText("Bags: "..used.."/"..total)
		self:SetAllPoints(Text_bags)
	end
		
	Stat4:RegisterEvent("PLAYER_LOGIN")
	Stat4:RegisterEvent("BAG_UPDATE")
	Stat4:SetScript("OnEvent", OnEvent)
	Stat4:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Bags:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")

			GameTooltip:AddLine("Hint: Click to open Bags.", 0.0, 1.0, 0.0)
			GameTooltip:Show()
		end		
	end)
	Stat4:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Stat4:SetScript("OnMouseDown", function() OpenAllBags() end)
	if refresh then OnEvent(Stat4, "PLAYER_LOGIN") end
end

------------------------------------------------------
-- / DURABILITY / --
------------------------------------------------------

function module:SetDurability(refresh)
	if db.Infotext.Armor.Enable == false then return end
	
	local Stat6 = CreateFrame("Frame", "LUI_Info_Durability", infos_left)
	Stat6:EnableMouse(true)

	Text_dura  = infos_left:CreateFontString(nil, "OVERLAY")
	Text_dura:SetFont(LSM:Fetch("font", db.Infotext.Armor.Font), db.Infotext.Armor.Size, db.Infotext.Armor.Outline)
	Text_dura:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Armor.X, db.Infotext.Armor.Y)
	Text_dura:SetHeight(db.Infotext.Armor.Size)
	Text_dura:SetTextColor(db.Infotext.Armor.Color.r, db.Infotext.Armor.Color.g, db.Infotext.Armor.Color.b, db.Infotext.Armor.Color.a)
	
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

	-- Localise functions
	local sort = table.sort
	
	local Total = 0
	local current, max	
	local function OnEvent(self, event)
		for i = 1, 11 do
			if GetInventoryItemLink("player", Slots[i][1]) ~= nil then
				current, max = GetInventoryItemDurability(Slots[i][1])
				if current then 
					Slots[i][3] = current / max
					Total = Total + 1
				end
			end
		end
		sort(Slots, function(a, b) return a[3] < b[3] end)
		
		if Total > 0 then
			Text_dura:SetText("Armor: "..floor(Slots[1][3]*100).."%")
		else
			Text_dura:SetText("Armor: 100%")
		end
		
		-- Setup Durability Tooltip
		self:SetAllPoints(Text_dura)
		Total = 0
	end

	Stat6:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	Stat6:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat6:SetScript("OnMouseDown", function() ToggleCharacter("PaperDollFrame") end)
	Stat6:SetScript("OnEvent", OnEvent)
	Stat6:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Armor:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")
			for i = 1, 11 do
				if Slots[i][3] ~= 1000 then
					green = Slots[i][3] * 2
					red = 1 - green
					GameTooltip:AddDoubleLine(Slots[i][2], floor(Slots[i][3]*100).."%", 1 ,1 , 1, red + 1, green, 0)
				end
			end
			
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Hint: Click to open Character Frame.", 0.0, 1.0, 0.0)
			GameTooltip:Show()
		end
	end)
	Stat6:SetScript("OnLeave", function() GameTooltip:Hide() end)
	if refresh then OnEvent(Stat6, "PLAYER_ENTERING_WORLD") end
end

------------------------------------------------------
-- / GOLD / --
------------------------------------------------------

function module:SetGold(refresh)
	if db.Infotext.Gold.Enable == false then return end
	
	local Stat7 = CreateFrame("Frame", "LUI_Info_Gold", infos_left)
	Stat7:EnableMouse(true)

	Text_gold  = infos_left:CreateFontString(nil, "OVERLAY")
	Text_gold:SetFont(LSM:Fetch("font", db.Infotext.Gold.Font), db.Infotext.Gold.Size, db.Infotext.Gold.Outline)
	Text_gold:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Gold.X, db.Infotext.Gold.Y)
	Text_gold:SetHeight(db.Infotext.Gold.Size)
	Text_gold:SetTextColor(db.Infotext.Gold.Color.r, db.Infotext.Gold.Color.g, db.Infotext.Gold.Color.b, db.Infotext.Gold.Color.a)

	local Profit	= 0
	local Spent		= 0
	local OldMoney	= 0
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
	
	-- Localised functions
	local format, floor, abs, mod = format, floor, math.abs, mod

	local function formatMoney(money)
		local gold = floor(abs(money) / 10000)
		local silver = mod(floor(abs(money) / 100), 100)
		local copper = mod(floor(abs(money)), 100)
		if gold ~= 0 then
			if db.Infotext.Gold.ColorType then
				return format("%s|cffffd700g|r %s|cffc7c7cfs|r", gold, silver)
			else
				return format("%sg %ss", gold, silver)
			end
		elseif silver ~= 0 then
			if db.Infotext.Gold.ColorType then
				return format("%s|cffc7c7cfs|r %s|cffeda55fc|r", silver, copper)
			else
				return format("%ss %sc", silver, copper)
			end
		else
			if db.Infotext.Gold.ColorType then
				return format("%s|cffeda55f c|r", copper)
			else
				return format("%sc", copper)
			end
		end
	end
	
	local function FormatTooltipMoney(money)
		local gold, silver, copper = abs(money / 10000), abs(mod(money / 100, 100)), abs(mod(money, 100))
		local cash = format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", gold, silver, copper)		
		return cash
	end	
	
	local function ShowGold(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Money:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")
			
			GameTooltip:AddLine("Session:")
			GameTooltip:AddDoubleLine("Earned:", formatMoney(Profit), 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Spent:", formatMoney(Spent), 1, 1, 1, 1, 1, 1)
			if Profit < Spent then
				GameTooltip:AddDoubleLine("Deficit:", formatMoney(Profit-Spent), 1, 0, 0, 1, 1, 1)
			elseif (Profit - Spent) > 0 then
				GameTooltip:AddDoubleLine("Profit:", formatMoney(Profit-Spent), 0, 1, 0, 1, 1, 1)
			end				
			GameTooltip:AddLine(" ")
		
			local totalGold = 0
			local totalPlayerFaction = 0
			local totalOtherFaction = 0
			local otherFaction = ((myPlayerFaction == "Alliance") and "Horde") or "Alliance"
			
			GameTooltip:AddLine("Character:")
			for k, v in pairs(LUIGold.gold[myPlayerRealm][myPlayerFaction]) do
				GameTooltip:AddDoubleLine(k, FormatTooltipMoney(v), colours[myPlayerFaction].r, colours[myPlayerFaction].g, colours[myPlayerFaction].b, 1, 1, 1)
				totalGold = totalGold + v
				totalPlayerFaction = totalPlayerFaction + v
			end
			for k, v in pairs(LUIGold.gold[myPlayerRealm][otherFaction]) do
				GameTooltip:AddDoubleLine(k, FormatTooltipMoney(v), colours[otherFaction].r, colours[otherFaction].g, colours[otherFaction].b, 1, 1, 1)
				totalGold = totalGold + v
				totalOtherFaction = totalOtherFaction + v
			end 
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Server:")
			if totalOtherFaction > 0 then
				GameTooltip:AddDoubleLine(myPlayerFaction..":", FormatTooltipMoney(totalPlayerFaction), colours[myPlayerFaction].r, colours[myPlayerFaction].g, colours[myPlayerFaction].b, 1, 1, 1)
				GameTooltip:AddDoubleLine(otherFaction..":", FormatTooltipMoney(totalOtherFaction), colours[otherFaction].r, colours[otherFaction].g, colours[otherFaction].b, 1, 1, 1)
			end
			GameTooltip:AddDoubleLine("Total:", FormatTooltipMoney(totalGold), 1, 1, 1, 1, 1, 1)
			
			for i = 1, MAX_WATCHED_TOKENS do
				local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)
				if name and i == 1 then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(CURRENCY)
				end
				local r, g, b = 1,1,1
				if itemID then r, g, b = GetItemQualityColor(select(3, GetItemInfo(itemID))) end
				if name and count then GameTooltip:AddDoubleLine(name, count, r, g, b, 1, 1, 1) end
			end
			
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Hint:\n- Left-Click to open Bags.\n- Right-Click to reset Session.", 0.0, 1.0, 0.0)
			GameTooltip:Show()
		end
	end
	
	local function OnEvent(self, event)
		if event == "PLAYER_ENTERING_WORLD" then
			OldMoney = GetMoney()
			
			if (LUIGold == nil) then LUIGold = {} end			
			if (LUIGold.gold == nil) then LUIGold.gold = {} end
			if (LUIGold.gold[myPlayerRealm] == nil) then LUIGold.gold[myPlayerRealm] = {} end
			if (LUIGold.gold[myPlayerRealm]["Alliance"] == nil) then LUIGold.gold[myPlayerRealm]["Alliance"] = {} end
			if (LUIGold.gold[myPlayerRealm]["Horde"] == nil) then LUIGold.gold[myPlayerRealm]["Horde"] = {} end
			
			Stat7:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
		
		local NewMoney = GetMoney()
		local Change = NewMoney - OldMoney -- Positive if we gain money
		
		if OldMoney > NewMoney then		-- Lost Money
			Spent = Spent - Change
		else							-- Gained Moeny
			Profit = Profit + Change
		end

		Text_gold:SetText(formatMoney(NewMoney))
		
		-- Setup Money Tooltip
		self:SetAllPoints(Text_gold)
		
		LUIGold.gold[myPlayerRealm][myPlayerFaction][myPlayerName] = GetMoney()
		
		OldMoney = NewMoney
		
		if self:IsMouseOver() and GameTooltip:GetOwner() == self then
			ShowGold(self)
		end
	end
		
	Stat7:RegisterEvent("PLAYER_MONEY")
	Stat7:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat7:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			Profit = 0
			Spent = 0
			OldMoney = GetMoney()
		else
			OpenAllBags()
		end 
	end)
	Stat7:SetScript("OnEvent", OnEvent)
	Stat7:SetScript("OnEnter", ShowGold)
	Stat7:SetScript("OnLeave", function() GameTooltip:Hide() end)
	if refresh then OnEvent(Stat7, "PLAYER_ENTERING_WORLD") end
end

function module:ResetGold(player,faction)
	if player == nil then return end
	
	if player == "ALL" then
		LUIGold = {}
	elseif faction ~= nil then
		LUIGold.gold[myPlayerRealm][faction][player] = nil
	end
end

------------------------------------------------------
-- / TIME / --
------------------------------------------------------

function module:SetClock()
	if db.Infotext.Clock.Enable == false then return end
	
	local Stat8 = CreateFrame("Frame", "LUI_Info_Clock", infos_right)
	Stat8:EnableMouse(true)

	Text_time  = infos_right:CreateFontString(nil, "OVERLAY")
	Text_time:SetFont(LSM:Fetch("font", db.Infotext.Clock.Font), db.Infotext.Clock.Size, db.Infotext.Clock.Outline)
	Text_time:SetPoint("CENTER", infos_right, "CENTER", db.Infotext.Clock.X, db.Infotext.Clock.Y)
	Text_time:SetHeight(db.Infotext.Clock.Size)
	Text_time:SetTextColor(db.Infotext.Clock.Color.r, db.Infotext.Clock.Color.g, db.Infotext.Clock.Color.b, db.Infotext.Clock.Color.a)
	
	-- Localised functions
	local tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo = tonumber, date, GetGameTime, IsInInstance, GetInstanceInfo

	local int = 1
	local instanceInfo, guildParty = nil, ""
	local function Update(self, t)		
		int = int - t
		if int < 0 then
			if ( GameTimeFrame.pendingCalendarInvites > 0 ) then
				Text_time:SetText("(Inv. pending)")
				self:SetAllPoints(Text_time)
			else
				if db.Infotext.Clock.LocalTime == true then
					local Hr24 = tonumber(date("%H"))
					local Hr = tonumber(date("%I"))
					local Min = date("%M")
					
					if db.Infotext.Clock.Time24 == true then 
						Text_time:SetText(Hr24..":"..Min)
					else
						if Hr24 >= 12 then
							Text_time:SetText(Hr..":"..Min.." pm")
						else
							Text_time:SetText(Hr..":"..Min.." am")
						end
					end
				else
					local Hr, Min = GetGameTime()
					if Min < 10 then Min = "0"..Min end
					
					if db.Infotext.Clock.Time24 == true then
						Text_time:SetText(Hr..":"..Min)
					else
						if Hr >= 12 then
							Text_time:SetText((Hr - 12)..":"..Min.." pm")
						else
							if Hr == 0 then Hr = 12 end
							Text_time:SetText(Hr..":"..Min.." am")
						end
					end
				end
				
				-- Instance Info
				if db.Infotext.Clock.ShowInstanceDifficulty == true then
					if instanceInfo then Text_time:SetText(Text_time:GetText().." ("..instanceInfo..guildParty.."|r)") end
				end
			end

			-- Prepare tooltip and reset timer.
			self:SetAllPoints(Text_time)
			int = 1
		end
	end
	
	-- More Localised funcitons
	local GetNumWorldPVPAreas, GetWorldPVPAreaInfo, format, floor, GetNumSavedInstances, GetSavedInstanceInfo = GetNumWorldPVPAreas, GetWorldPVPAreaInfo, format, floor, GetNumSavedInstances, GetSavedInstanceInfo
	local gsub, strtrim, strmatch = gsub, strtrim, strmatch

	function Stat8:GUILD_PARTY_STATE_UPDATED()
		if InGuildParty() then
			guildParty = " |cff66c7ffG"
		else
			guildParty = ""
		end
	end
		
	function Stat8:PLAYER_ENTERING_WORLD()
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
	
	function module:ClockShowInstanceDifficulty()
		if db.Infotext.Clock.ShowInstanceDifficulty then
			Stat8:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
			Stat8:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
			Stat8:RegisterEvent("PLAYER_ENTERING_WORLD")
			Stat8:GUILD_PARTY_STATE_UPDATED()
			Stat8:PLAYER_ENTERING_WORLD()
			Stat8.PLAYER_DIFFICULTY_CHANGED = Stat8.PLAYER_ENTERING_WORLD
			instanceInfo, guildParty = nil, ""
		else
			Stat8:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
			Stat8:RegisterEvent("PLAYER_ENTERING_WORLD")
			instanceInfo, guildParty = nil, ""
		end
	end
	
	module:ClockShowInstanceDifficulty()
	Stat8:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Time:", 0.4, 0.78, 1)
			GameTooltip:AddLine(" ")
			
			local pvp = GetNumWorldPVPAreas()
			for i = 1, pvp do
				local _, name, inprogress, _, timeleft = GetWorldPVPAreaInfo(i)
				local inInstance, instanceType = IsInInstance()
				if not ( instanceType == "none" ) then
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
			
			if db.Infotext.Clock.LocalTime == true then
				local Hr, Min = GetGameTime()			
				if Min<10 then Min = "0"..Min end
				
				if db.Infotext.Clock.Time24 == true then         
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
				if db.Infotext.Clock.Time24 == true then
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
			GameTooltip:AddLine("Hint:\n- Left-Click for Calendar Frame.\n- Right-Click for Time Manager Frame.", 0.0, 1.0, 0.0)
			GameTooltip:Show()
		end
	end)	
	Stat8:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Stat8:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	Stat8:SetScript("OnUpdate", Update)
	Stat8:SetScript("OnMouseDown", function(self, button) if button == "RightButton" then TimeManager_Toggle() else GameTimeFrame:Click() end end)
	Update(Stat8, 10)
end

--------------------------------------------------------------------
-- /GUILD and FRIENDS/ --
--------------------------------------------------------------------

function module:SetGuild_Friends()
	if db.Infotext.Guild_Friends.Guild.Enable == false and db.Infotext.Guild_Friends.Friends.Enable == false then return end
	
	local f = CreateFrame("Frame", "LUI_Info_Guild/Friends", infos_right)
	f:SetScale(fscale)
	local t = CreateFrame("Frame", "LUI_Info_updater", infos_right)
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
	
		local Stat9 = CreateFrame("Frame", "LUI_Info_Guild", infos_right)
		Stat9:EnableMouse(true)
		
		f.Guild = CreateFrame("Frame", "LUI Guild", Stat9)

		f.Guild.text = infos_right:CreateFontString("LUI_Guild", "OVERLAY")
		f.Guild.text:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
		f.Guild.text:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Guild.Font), db.Infotext.Guild_Friends.Guild.Size, db.Infotext.Guild_Friends.Guild.Outline)
		f.Guild.text:SetHeight(db.Infotext.Guild_Friends.Guild.Size)
		f.Guild.text:SetTextColor(db.Infotext.Guild_Friends.Guild.Color.r, db.Infotext.Guild_Friends.Guild.Color.g, db.Infotext.Guild_Friends.Guild.Color.b, db.Infotext.Guild_Friends.Guild.Color.a)
		f.Guild.text:SetText("LUI_Friends")
		
		f.Guild:SetAllPoints(f.Guild.text)
		f.Guild:SetScript("OnEnter", function(self)
			if not InCombatLockdown() then
				isGuild = true
				if IsInGuild() then GuildRoster() end
				AnchorTablet(self)
			end
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
		
		local Stat10 = CreateFrame("Frame", "LUI_Info_Friends", infos_right)
		Stat10:EnableMouse(true)
		
		f.Friends = CreateFrame("Frame", "LUI Friends", Stat10)
		
		f.Friends.text = infos_right:CreateFontString("LUI_Friends", "OVERLAY")
		f.Friends.text:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
		f.Friends.text:SetFont(LSM:Fetch("font", db.Infotext.Guild_Friends.Friends.Font), db.Infotext.Guild_Friends.Friends.Size, db.Infotext.Guild_Friends.Friends.Outline)
		f.Friends.text:SetHeight(db.Infotext.Guild_Friends.Friends.Size)
		f.Friends.text:SetTextColor(db.Infotext.Guild_Friends.Friends.Color.r, db.Infotext.Guild_Friends.Friends.Color.g, db.Infotext.Guild_Friends.Friends.Color.b, db.Infotext.Guild_Friends.Friends.Color.a)
		f.Friends.text:SetText("LUI_Guild")
		
		f.Friends:SetAllPoints(f.Friends.text)
		f.Friends:SetScript("OnEnter", function(self)
			if not InCombatLockdown() then
				isGuild = false
				ShowFriends()
				AnchorTablet(self)
			end
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
-- / DPS / --
------------------------------------------------------

function module:SetDPS(refresh)
	if db.Infotext.Dps.Enable == false then return end
	
	local Stat11 = CreateFrame("Frame", "LUI_Info_DPS", infos_right)
	Stat11:EnableMouse(true)
	
	local active = db.Infotext.Dps.active
	if active ~= "dps" and active ~= "hps" and active ~= "dtps" and active ~= "htps" then db.Infotext.Dps.active = "dps" active = "dps" end
	
	Text_dps = infos_right:CreateFontString(nil, "OVERLAY")
	Text_dps:SetFont(LSM:Fetch("font", db.Infotext.Dps.Font), db.Infotext.Dps.Size, db.Infotext.Dps.Outline)
	Text_dps:SetPoint("LEFT", infos_right, "LEFT", db.Infotext.Dps.X,db.Infotext.Dps.Y)
	Text_dps:SetHeight(db.Infotext.Dps.Size)
	Text_dps:SetTextColor(db.Infotext.Dps.Color.r, db.Infotext.Dps.Color.g, db.Infotext.Dps.Color.b, db.Infotext.Dps.Color.a)
	Stat11:SetAllPoints(Text_dps)
	
	if active == "dps" then Text_dps:SetText("DPS: ")
	elseif active == "hps" then Text_dps:SetText("HPS: ")
	elseif active == "dtps" then Text_dps:SetText("DTPS: ")
	elseif active == "htps" then Text_dps:SetText("HTPS: ") end
	
	
	-- Localised functions
	local UnitGUID, GetTime = UnitGUID, GetTime

	-- Local variables
	local playerId, petId, combatStartTime, combatTimeElapsed, elapsedTime
	local totalDamage, playerDamage, petDamage, totalHealing, effectiveHealing, overHealing, totalDamageTaken, totalHealingTaken, effectiveHealingTaken, overHealingTaken = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	combatTimeElapsed = combatTimeElapsed or 1
	
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

	local function OnUpdate(self, t)
		elapsedTime = elapsedTime - t
		if elapsedTime < 0 then
			elapsedTime = 0.5
			
			-- SetText
			combatTimeElapsed = GetTime() - combatStartTime
			local total
			if active == "dps" then
				total = totalDamage / combatTimeElapsed
			elseif active == "hps" then
				total = totalHealing / combatTimeElapsed
			elseif active == "dtps" then
				total = totalDamageTaken / combatTimeElapsed
			elseif active == "htps" then
				total = totalHealingTaken / combatTimeElapsed
			end
				
			Text_dps:SetFormattedText(textFormat[active], total)
			self:SetAllPoints(Text_dps)
		end
	end
	
	function Stat11:COMBAT_LOG_EVENT_UNFILTERED(_, eventType, _, Id, _, _, TargetId, _, _, spellID, spellName, _, amount, amount2)
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

	function Stat11:PLAYER_ENTERING_WORLD()
		playerId = UnitGUID("player")
		petId = UnitGUID("pet")
	end
	
	function Stat11:PLAYER_REGEN_DISABLED()
		combatStartTime = GetTime()
		combatTimeElapsed = 0
		totalDamage, playerDamage, petDamage = 0, 0, 0
		totalHealing, effectiveHealing, overHealing = 0, 0, 0
		totalDamageTaken = 0
		totalHealingTaken, effectiveHealingTaken, overHealingTaken = 0, 0, 0
		elapsedTime = 0.5
		
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:SetScript("OnUpdate", OnUpdate)
	end

	function Stat11:PLAYER_REGEN_ENABLED()
		OnUpdate(self, 10)
		
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:SetScript("OnUpdate", nil)
	end
	
	function Stat11:UNIT_PET(unit)
		if unit == "player" then
			petId = UnitGUID("pet")
		end
	end
	
	Stat11:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat11:RegisterEvent("PLAYER_REGEN_DISABLED")
	Stat11:RegisterEvent("PLAYER_REGEN_ENABLED")
	Stat11:RegisterEvent("UNIT_PET")
	Stat11:SetScript("OnMouseDown", function(self, button)
		local total
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
		db.Infotext.Dps.active = active
		
		Text_dps:SetFormattedText(textFormat[active], total)
		self:SetAllPoints(Text_dps)
	end)
	Stat11:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			local name = UnitName("player")
			
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
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
			GameTooltip:AddLine("Hint: Click to change meter type.", 0.0, 1.0, 0.0)

			GameTooltip:Show()
		end
	end)
	Stat11:SetScript("OnLeave", function() GameTooltip:Hide() end)		
	Stat11:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	if refresh then Stat11:PLAYER_ENTERING_WORLD() end
end

local defaults = {
	Infotext = {
		Enable = true,
		Gold = {
			Enable = true,
			X = -200,
			Y = 0,
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
		Bags = {
			Enable = true,
			X = -50,
			Y = 0,
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
		Armor = {
			Enable = true,
			X = 100,
			Y = 0,
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
			X = 260,
			Y = 0,
			MSValue = "WORLD",
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
			X = -535,
			Y = 0,
			Font = "vibroceb",
			Size = 12,
			Outline = "NONE",
			Color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			active = "dps",
		},
		Memory = {
			Enable = true,
			X = 340,
			Y = 0,
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
			X = -5,
			Y = 0,
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
			ShowTotal = true,
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
				Enable = false,
				X = -380,
				Y = 0,
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
				Enable = false,
				X = -280,
				Y = 0,
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
	},
}

function module:LoadOptions()
	local options = {
		Infotext = {
			name = "Info Text",
			type = "group",
			order = 65,
			disabled = function() return not db.Infotext.Enable end,
			childGroups = "select",
			args = {
				Bags = {
					name = "Bags",
					type = "group",
					order = 1,
					args = {
						header94 = {
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
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						BagsX = {
							name = "X Value",
							desc = "X Value for your Bags Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Bags.X,
							type = "input",
							disabled = function() return not db.Infotext.Bags.Enable end,
							get = function() return tostring(db.Infotext.Bags.X) end,
							set = function(self, BagsX)
										if BagsX == nil or BagsX == "" then
											BagsX = "0"
										end
										db.Infotext.Bags.X = tonumber(BagsX)
										Text_bags:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Bags.X, db.Infotext.Bags.Y)
									end,
							order = 3,
						},
						BagsY = {
							name = "Y Value",
							desc = "Y Value for your Bags Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Bags.Y,
							type = "input",
							disabled = function() return not db.Infotext.Bags.Enable end,
							get = function() return tostring(db.Infotext.Bags.Y) end,
							set = function(self,BagsY)
										if BagsY == nil or BagsY == "" then
											BagsY = "0"
										end
										db.Infotext.Bags.Y = tonumber(BagsY)
										Text_bags:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Bags.X, db.Infotext.Bags.Y)
									end,
							order = 4,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Bags.Enable end,
							order = 5,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Bag Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Bags.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Bags.Size end,
									set = function(_, FontSize)
											db.Infotext.Bags.Size = FontSize
											Text_bags:SetFont(LSM:Fetch("font", db.Infotext.Bags.Font), FontSize, db.Infotext.Bags.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Bags Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Bags.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Bags.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Bags.Color.b.."\na = "..LUI.defaults.profile.Infotext.Bags.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Bags.Color.r, db.Infotext.Bags.Color.g, db.Infotext.Bags.Color.b, db.Infotext.Bags.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Bags.Color.r = r
											db.Infotext.Bags.Color.g = g
											db.Infotext.Bags.Color.b = b
											db.Infotext.Bags.Color.a = a
											
											Text_bags:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Bags Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Bags.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Bags.Font end,
									set = function(self, Font)
											db.Infotext.Bags.Font = Font
											Text_bags:SetFont(LSM:Fetch("font", Font), db.Infotext.Bags.Size, db.Infotext.Bags.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Bags Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Bags.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Bags.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Bags.Outline = fontflags[FontFlag]
											Text_bags:SetFont(LSM:Fetch("font", db.Infotext.Bags.Font), db.Infotext.Bags.Size, db.Infotext.Bags.Outline)
										end,
									order = 4,
								},
							},
						},
					},
				},
				Clock = {
					name = "Clock",
					type = "group",
					order = 2,
					args = {
						header93 = {
							name = "Clock",
							type = "header",
							order = 13,
						},
						ClockEnable = {
							name = "Enable",
							desc = "Whether you want to show your Clock or not.",
							type = "toggle",
							get = function() return db.Infotext.Clock.Enable end,
							set = function()
										db.Infotext.Clock.Enable = not db.Infotext.Clock.Enable
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 14,
						},
						ShowInstanceDifficulty = {
							name = "Show Instance Difficulty",
							desc = "Whether you want to show the Instance Difficulty or not.",
							type = "toggle",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.ShowInstanceDifficulty end,
							set = function()
										db.Infotext.Clock.ShowInstanceDifficulty = not db.Infotext.Clock.ShowInstanceDifficulty
										module:ClockShowInstanceDifficulty()
									end,
							order = 15,
						},
						EnableLocalTime = {
							name = "Local Time",
							desc = "Whether you want to show your Local Time or Server Time.",
							type = "toggle",
							width = "50%",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.LocalTime end,
							set = function()
										db.Infotext.Clock.LocalTime = not db.Infotext.Clock.LocalTime
									end,
							order = 16,
						},
						EnableTime24 = {
							name = "24h Clock",
							desc = "Whether you want to show 24 or 12 hour Clock.",
							type = "toggle",
							width = "50%",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return db.Infotext.Clock.Time24 end,
							set = function()
										db.Infotext.Clock.Time24 = not db.Infotext.Clock.Time24
									end,
							order = 17,
						},
						ClockX = {
							name = "X Value",
							desc = "X Value for your Clock.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Clock.X,
							type = "input",
							disabled = function() return not db.Infotext.Clock.Enable end,
							get = function() return tostring(db.Infotext.Clock.X) end,
							set = function(self, ClockX)
										if ClockX == nil or ClockX == "" then
											ClockX = "0"
										end
										
										db.Infotext.Clock.X = tonumber(ClockX)
										Text_time:SetPoint("CENTER", infos_right, "CENTER", db.Infotext.Clock.X, db.Infotext.Clock.Y)
									end,
							order = 18,
						},
						ClockY = {
							name = "Y Value",
							disabled = function() return not db.Infotext.Clock.Enable end,
							desc = "Y Value for your Clock.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Clock.Y,
							type = "input",
							get = function() return tostring(db.Infotext.Clock.Y) end,
							set = function(self,ClockY)
										if ClockY == nil or ClockY == "" then
											ClockY = "0"
										end
										db.Infotext.Clock.Y = tonumber(ClockY)
										Text_time:SetPoint("CENTER", infos_right, "CENTER", db.Infotext.Clock.X, db.Infotext.Clock.Y)
									end,
							order = 19,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Clock.Enable end,
							order = 20,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Clock Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Clock.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Clock.Size end,
									set = function(_, FontSize)
											db.Infotext.Clock.Size = FontSize
											Text_time:SetFont(LSM:Fetch("font", db.Infotext.Clock.Font), FontSize, db.Infotext.Clock.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Clock Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Clock.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Clock.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Clock.Color.b.."\na = "..LUI.defaults.profile.Infotext.Clock.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Clock.Color.r, db.Infotext.Clock.Color.g, db.Infotext.Clock.Color.b, db.Infotext.Clock.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Clock.Color.r = r
											db.Infotext.Clock.Color.g = g
											db.Infotext.Clock.Color.b = b
											db.Infotext.Clock.Color.a = a
											
											Text_time:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Clock Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Clock.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Clock.Font end,
									set = function(self, Font)
											db.Infotext.Clock.Font = Font
											Text_time:SetFont(LSM:Fetch("font", Font), db.Infotext.Clock.Size, db.Infotext.Clock.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Clock Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Clock.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Clock.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Clock.Outline = fontflags[FontFlag]
											Text_time:SetFont(LSM:Fetch("font", db.Infotext.Clock.Font), db.Infotext.Clock.Size, db.Infotext.Clock.Outline)
										end,
									order = 4,
								},
							},
						},
					},
				},
				DPS = {
					name = "DPS",
					type = "group",
					order = 3,
					args = {
						header96 = {
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
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						DpsX = {
							name = "X Value",
							desc = "X Value for your DPS Notice.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Dps.X,
							type = "input",
							disabled = function() return not db.Infotext.Dps.Enable end,
							get = function() return tostring(db.Infotext.Dps.X) end,
							set = function(self, DpsX)
										if DpsX == nil or DpsX == "" then
											DpsX = "-535"
										end
										db.Infotext.Dps.X = tonumber(DpsX)
										Text_dps:SetPoint("LEFT", infos_right, "LEFT", db.Infotext.Dps.X, db.Infotext.Dps.Y)
									end,
							order = 3,
						},
						DpsY = {
							name = "Y Value",
							desc = "Y Value for your DPS Notice.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Infotext.Dps.Y,
							type = "input",
							disabled = function() return not db.Infotext.Dps.Enable end,
							get = function() return tostring(db.Infotext.Dps.Y) end,
							set = function(self, DpsY)
										if DpsY == nil or DpsY == "" then
											DpsY = "0"
										end
										db.Infotext.Dps.Y = tonumber(DpsY)
										Text_dps:SetPoint("LEFT", infos_right, "LEFT", db.Infotext.Dps.X, db.Infotext.Dps.Y)
									end,
							order = 4,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Dps.Enable end,
							order = 5,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Dps Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Dps.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Dps.Size end,
									set = function(_, FontSize)
											db.Infotext.Dps.Size = FontSize
											Text_dps:SetFont(LSM:Fetch("font", db.Infotext.Dps.Font), FontSize, db.Infotext.Dps.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Dps Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Dps.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Dps.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Dps.Color.b.."\na = "..LUI.defaults.profile.Infotext.Dps.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Dps.Color.r, db.Infotext.Dps.Color.g, db.Infotext.Dps.Color.b, db.Infotext.Dps.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Dps.Color.r = r
											db.Infotext.Dps.Color.g = g
											db.Infotext.Dps.Color.b = b
											db.Infotext.Dps.Color.a = a
											
											Text_dps:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Dps Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Dps.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Dps.Font end,
									set = function(self, Font)
											db.Infotext.Dps.Font = Font
											Text_dps:SetFont(LSM:Fetch("font", Font), db.Infotext.Dps.Size, db.Infotext.Dps.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Dps Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Dps.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Dps.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Dps.Outline = fontflags[FontFlag]
											Text_dps:SetFont(LSM:Fetch("font", db.Infotext.Dps.Font), db.Infotext.Dps.Size, db.Infotext.Dps.Outline)
										end,
									order = 4,
								},
							},
						},
					},
				},
				Durability = {
					name = "Durability",
					type = "group",
					order = 4,
					args = {
						header95 = {
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
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						ArmorX = {
							name = "X Value",
							desc = "X Value for your Durability.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Armor.X,
							type = "input",
							disabled = function() return not db.Infotext.Armor.Enable end,
							get = function() return tostring(db.Infotext.Armor.X) end,
							set = function(self,ArmorX)
										if ArmorX == nil or ArmorX == "" then
											ArmorX = "0"
										end
										
										db.Infotext.Armor.X = tonumber(ArmorX)
										Text_dura:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Armor.X, db.Infotext.Armor.Y)
									end,
							order = 3,
						},
						ArmorY = {
							name = "Y Value",
							desc = "Y Value for your Durability.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Armor.Y,
							type = "input",
							disabled = function() return not db.Infotext.Armor.Enable end,
							get = function() return tostring(db.Infotext.Armor.Y) end,
							set = function(self,ArmorY)
										if ArmorY == nil or ArmorY == "" then
											ArmorY = "0"
										end
										
										db.Infotext.Armor.Y = tonumber(ArmorY)
										Text_dura:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Armor.X, db.Infotext.Armor.Y)
									end,
							order = 4,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Armor.Enable end,
							order = 5,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Armor Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Armor.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Armor.Size end,
									set = function(_, FontSize)
											db.Infotext.Armor.Size = FontSize
											Text_dura:SetFont(LSM:Fetch("font", db.Infotext.Armor.Font), FontSize, db.Infotext.Armor.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Armor Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Armor.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Armor.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Armor.Color.b.."\na = "..LUI.defaults.profile.Infotext.Armor.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Armor.Color.r, db.Infotext.Armor.Color.g, db.Infotext.Armor.Color.b, db.Infotext.Armor.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Armor.Color.r = r
											db.Infotext.Armor.Color.g = g
											db.Infotext.Armor.Color.b = b
											db.Infotext.Armor.Color.a = a
											
											Text_dura:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Armor Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Armor.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Armor.Font end,
									set = function(self, Font)
											db.Infotext.Armor.Font = Font
											Text_dura:SetFont(LSM:Fetch("font", Font), db.Infotext.Armor.Size, db.Infotext.Armor.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Armor Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Armor.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Armor.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Armor.Outline = fontflags[FontFlag]
											Text_dura:SetFont(LSM:Fetch("font", db.Infotext.Armor.Font), db.Infotext.Armor.Size, db.Infotext.Armor.Outline)
										end,
									order = 4,
								},
							},
						},
					},
				},
				FPS = {
					name = "FPS/MS",
					type = "group",
					order = 5,
					args = {
						header96 = {
							name = "FPS/MS",
							type = "header",
							order = 1,
						},
						FpsEnable = {
							name = "Enable",
							desc = "Whether you want to show your Fps/Ms or not.",
							type = "toggle",
							width = "full",
							get = function() return db.Infotext.Fps.Enable end,
							set = function()
										db.Infotext.Fps.Enable = not db.Infotext.Fps.Enable
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						FpsX = {
							name = "X Value",
							desc = "X Value for your FPS/MS Notice.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Fps.X,
							type = "input",
							disabled = function() return not db.Infotext.Fps.Enable end,
							get = function() return tostring(db.Infotext.Fps.X) end,
							set = function(self, FpsX)
										if FpsX == nil or FpsX == "" then
											FpsX = "0"
										end
										
										db.Infotext.Fps.X = tonumber(FpsX)
										Text_fps:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Fps.X, db.Infotext.Fps.Y)
									end,
							order = 3,
						},
						FpsY = {
							name = "Y Value",
							desc = "Y Value for your FPS/MS Notice.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Fps.Y,
							type = "input",
							disabled = function() return not db.Infotext.Fps.Enable end,
							get = function() return tostring(db.Infotext.Fps.Y) end,
							set = function(self, FpsY)
										if FpsY == nil or FpsY == "" then
											FpsY = "0"
										end
										
										db.Infotext.Fps.Y = tonumber(FpsY)
										Text_fps:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Fps.X, db.Infotext.Fps.Y)
									end,
							order = 4,
						},
						MSValue = {
							name = "MS Value",
							desc = "Wether you want your MS to show World, Home or both latency values.\n\nDefault: WORLD",
							type = "input",
							disabled = function() return not db.Infotext.Fps.Enable end,
							get = function() return db.Infotext.FPS.MSValue end,
							set = function(self, value)
										value = strupper(value)
										if (value == "HOME") or (value == "WORLD") or (value == "BOTH") then
											db.Infotext.FPS.MSValue = value
										end
									end,
							order = 5,																				
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Fps.Enable end,
							order = 6,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Fps Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Fps.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Fps.Size end,
									set = function(_, FontSize)
											db.Infotext.Fps.Size = FontSize
											Text_fps:SetFont(LSM:Fetch("font", db.Infotext.Fps.Font), FontSize, db.Infotext.Fps.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Fps Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Fps.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Fps.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Fps.Color.b.."\na = "..LUI.defaults.profile.Infotext.Fps.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Fps.Color.r, db.Infotext.Fps.Color.g, db.Infotext.Fps.Color.b, db.Infotext.Fps.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Fps.Color.r = r
											db.Infotext.Fps.Color.g = g
											db.Infotext.Fps.Color.b = b
											db.Infotext.Fps.Color.a = a
											
											Text_fps:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Fps Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Fps.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Fps.Font end,
									set = function(self, Font)
											db.Infotext.Fps.Font = Font
											Text_fps:SetFont(LSM:Fetch("font", Font), db.Infotext.Fps.Size, db.Infotext.Fps.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Fps Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Fps.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Fps.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Fps.Outline = fontflags[FontFlag]
											Text_fps:SetFont(LSM:Fetch("font", db.Infotext.Fps.Font), db.Infotext.Fps.Size, db.Infotext.Fps.Outline)
										end,
									order = 4,
								},
							},
						},
					},
				},
				Gold = {
					name = "Gold",
					type = "group",
					order = 6,
					args = {
						header92 = {
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
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						GoldPlayerReset = {
							name = "Reset Player",
							desc = "Choose the player you want to clear Gold data for.\n",
							type = "select",
							values = function()
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
								return realmPlayerArray
							end,
							get = function()
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
								for k,v in pairs(realmPlayerArray) do
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
							order = 3,
						},
						GoldReset = {
							order = 4,
							type = "execute",
							name = "Reset",
							func = function()
								if playerReset == "ALL" then
									module:ResetGold("ALL")
									return
								end
								if LUIGold.gold ~= nil then 
									if LUIGold.gold[myPlayerRealm] ~= nil then
										local breakloop = false
										for f in pairs(LUIGold.gold[myPlayerRealm]) do
											if f == "Horde" or f == "Alliance" then
												for p,g in pairs(LUIGold.gold[myPlayerRealm][f]) do
													if playerReset == p then
														module:ResetGold(p, f)
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
						GoldX = {
							name = "X Value",
							desc = "X Value for your Gold Amount.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Gold.X,
							type = "input",
							disabled = function() return not db.Infotext.Gold.Enable end,
							get = function() return tostring(db.Infotext.Gold.X) end,
							set = function(self, GoldX)
										if GoldX == nil or GoldX == "" then
											GoldX = "0"
										end
										
										db.Infotext.Gold.X = tonumber(GoldX)
										Text_gold:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Gold.X, db.Infotext.Gold.Y)
									end,
							order = 5,
						},
						GoldY = {
							name = "Y Value",
							desc = "Y Value for your Gold Amount.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Gold.Y,
							type = "input",
							disabled = function() return not db.Infotext.Gold.Enable end,
							get = function() return tostring(db.Infotext.Gold.Y) end,
							set = function(self, GoldY)
										if GoldY == nil or GoldY == "" then
											GoldY = "0"
										end
										db.Infotext.Gold.Y = tonumber(GoldY)
										Text_gold:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Gold.X, db.Infotext.Gold.Y)
									end,
							order = 6,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Gold.Enable end,
							order = 7,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Gold Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Gold.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Gold.Size end,
									set = function(_, FontSize)
											db.Infotext.Gold.Size = FontSize
											Text_gold:SetFont(LSM:Fetch("font", db.Infotext.Gold.Font), FontSize, db.Infotext.Gold.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Gold Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Gold.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Gold.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Gold.Color.b.."\na = "..LUI.defaults.profile.Infotext.Gold.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Gold.Color.r, db.Infotext.Gold.Color.g, db.Infotext.Gold.Color.b, db.Infotext.Gold.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Gold.Color.r = r
											db.Infotext.Gold.Color.g = g
											db.Infotext.Gold.Color.b = b
											db.Infotext.Gold.Color.a = a
											
											Text_gold:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Gold Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Gold.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Gold.Font end,
									set = function(self, Font)
											db.Infotext.Gold.Font = Font
											Text_gold:SetFont(LSM:Fetch("font", Font), db.Infotext.Gold.Size, db.Infotext.Gold.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Gold Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Gold.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Gold.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Gold.Outline = fontflags[FontFlag]
											Text_gold:SetFont(LSM:Fetch("font", db.Infotext.Gold.Font), db.Infotext.Gold.Size, db.Infotext.Gold.Outline)
										end,
									order = 4,
								},
								ColorType = {
									name = "Color By Type",
									desc = "Weather or not to color the coin letters by the type of coin.\n\nNote:\nYou have to reload the UI.\nType /rl",
									type = "toggle",
									get = function() return db.Infotext.Gold.ColorType end,
									set = function(self)
										db.Infotext.Gold.ColorType = not db.Infotext.Gold.ColorType
									end,
									order = 5,
								},
							},
						},
					},
				},
				Guild_Friends = {
					name = "Guild / Friends",
					type = "group",
					order = 7,
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
												LUI_Guild:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
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
												LUI_Guild:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Guild.X, db.Infotext.Guild_Friends.Guild.Y)
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
												LUI_Friends:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
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
												LUI_Friends:SetPoint("RIGHT", infos_right, "LEFT", db.Infotext.Guild_Friends.Friends.X, db.Infotext.Guild_Friends.Friends.Y)
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
				MemoryUsage = {
					name = "Memory Usage",
					type = "group",
					order = 8,
					args = {
						header97 = {
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
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 2,
						},
						MemoryX = {
							name = "X Value",
							desc = "X Value for your Addon Memory Notice.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Memory.X,
							type = "input",
							disabled = function() return not db.Infotext.Memory.Enable end,
							get = function() return tostring(db.Infotext.Memory.X) end,
							set = function(self,MemoryX)
										if MemoryX == nil or MemoryX == "" then
											MemoryX = "0"
										end
										
										db.Infotext.Memory.X = tonumber(MemoryX)
										Text_mb:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Memory.X, db.Infotext.Memory.Y)
									end,
							order = 3,
						},
						MemoryY = {
							name = "Y Value",
							desc = "Y Value for your Addon Memory Notice.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Infotext.Memory.Y,
							type = "input",
							disabled = function() return not db.Infotext.Memory.Enable end,
							get = function() return tostring(db.Infotext.Memory.Y) end,
							set = function(self, MemoryY)
										if MemoryY == nil or MemoryY == "" then
											MemoryY = "0"
										end
										
										db.Infotext.Memory.Y = tonumber(MemoryY)
										Text_mb:SetPoint("CENTER", infos_left, "CENTER", db.Infotext.Memory.X, db.Infotext.Memory.Y)
									end,
							order = 4,
						},
						TextSettings = {
							name = "Font Settings",
							type = "group",
							disabled = function() return not db.Infotext.Memory.Enable end,
							order = 5,
							guiInline = true,
							args = {
								FontSize = {
									name = "Size",
									desc = "Choose your Memory Info Text Fontsize!\n\nDefault: "..LUI.defaults.profile.Infotext.Memory.Size,
									type = "range",
									min = 1,
									max = 40,
									step = 1,
									get = function() return db.Infotext.Memory.Size end,
									set = function(_, FontSize)
											db.Infotext.Memory.Size = FontSize
											Text_mb:SetFont(LSM:Fetch("font", db.Infotext.Memory.Font), FontSize, db.Infotext.Memory.Outline)
										end,
									order = 1,
								},
								Color = {
									name = "Color",
									desc = "Choose an individual Memory Info Text Color.\n\nDefaults:\nr = "..LUI.defaults.profile.Infotext.Memory.Color.r.."\ng = "..LUI.defaults.profile.Infotext.Memory.Color.g.."\nb = "..LUI.defaults.profile.Infotext.Memory.Color.b.."\na = "..LUI.defaults.profile.Infotext.Memory.Color.a,
									type = "color",
									hasAlpha = true,
									get = function() return db.Infotext.Memory.Color.r, db.Infotext.Memory.Color.g, db.Infotext.Memory.Color.b, db.Infotext.Memory.Color.a end,
									set = function(_, r, g, b, a)
											db.Infotext.Memory.Color.r = r
											db.Infotext.Memory.Color.g = g
											db.Infotext.Memory.Color.b = b
											db.Infotext.Memory.Color.a = a
											
											Text_mb:SetTextColor(r, g, b, a)
										end,
									order = 2,
								},
								Font = {
									name = "Font",
									desc = "Choose the Font for your Memory Info Text!\n\nDefault: "..LUI.defaults.profile.Infotext.Memory.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function() return db.Infotext.Memory.Font end,
									set = function(self, Font)
											db.Infotext.Memory.Font = Font
											Text_mb:SetFont(LSM:Fetch("font", Font), db.Infotext.Memory.Size, db.Infotext.Memory.Outline)
										end,
									order = 3,
								},
								FontFlag = {
									name = "Font Flag",
									desc = "Choose the Font Flag for your Memory Info Text.\n\nDefault: "..LUI.defaults.profile.Infotext.Memory.Outline,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Infotext.Memory.Outline == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Infotext.Memory.Outline = fontflags[FontFlag]
											Text_mb:SetFont(LSM:Fetch("font", db.Infotext.Memory.Font), db.Infotext.Memory.Size, db.Infotext.Memory.Outline)
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
	
	if LUIGold.version ~= version then
		module:ResetGold("ALL")
		LUIGold.version = version
	end
	
	LUI:RegisterModule(self)
end

function module:OnEnable()
	self:SetDataTextFrames()
	self:SetFPS()
	self:SetMemoryUsage()
	self:SetBags(true)
	self:SetDurability(true)
	self:SetGuild_Friends()
	self:SetGold(true)
	self:SetClock()
	self:SetDPS(true)
end

function module:OnDisable()
	local frameList = {"infos_left", "infos_right"}
	LUI:ClearFrames(frameList)
end