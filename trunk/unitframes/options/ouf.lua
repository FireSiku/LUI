--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: _ouf.lua
	Description: oUF Module
	Version....: 1.0
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db

local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

local ufNames = {
	Player = "oUF_LUI_player",
	Target = "oUF_LUI_target",
	ToT = "oUF_LUI_targettarget",
	ToToT = "oUF_LUI_targettargettarget",
	Focus = "oUF_LUI_focus",
	FocusTarget = "oUF_LUI_focustarget",
	Pet = "oUF_LUI_pet",
	PetTarget = "oUF_LUI_pettarget",
	Party = "oUF_LUI_party",
	Maintank = "oUF_LUI_maintank",
	Boss = "oUF_LUI_boss",
	Player_Castbar = "oUF_LUI_player_Castbar",
	Target_Castbar = "oUF_LUI_target_Castbar",
	Arena = "oUF_LUI_arena1",
}

local _LOCK
local _BACKDROP = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}

local round = function(n)
	return math.floor(n + .5)
end

local positions = {}
local backdropPool = {}

local getPoint = function(obj, anchor)
	if anchor then
		if (not positions.__INITIAL) or (not positions.__INITIAL[obj]) then return end
		local UIx, UIy = UIParent:GetCenter()
		local Ipoint, Iparent, Irpoint, Ix, Iy = string.split('\031', positions.__INITIAL[obj])

		-- Frame doesn't really have a positon yet.
		if(not Ix) then return end
		
		local UIx, UIy = UIParent:GetCenter()
		local UIWidth, UIHeight = UIParent:GetRight(), UIParent:GetTop()
		local UIS = UIParent:GetEffectiveScale()
		local S = anchor:GetEffectiveScale()
		
		if strfind("LEFT", Ipoint) then 
			x = anchor:GetLeft()
		elseif strfind("RIGHT", Ipoint) then
			x = anchor:GetRight()
		else
			x = anchor:GetCenter()
		end
		
		if strfind("LEFT", Irpoint) then 
			x = x
		elseif strfind("RIGHT", Irpoint) then
			x = x - UIWidth
		else
			x = x - UIx
		end
		
		if strfind("TOP", Ipoint) then 
			y = anchor:GetTop()
		elseif strfind("BOTTOM", Ipoint) then
			y = anchor:GetBottom()
		else
			y = select(2, anchor:GetCenter())
		end
		
		if strfind("TOP", Irpoint) then 
			y = y - UIHeight
		elseif strfind("BOTTOM", Irpoint) then
			y = y
		else
			y = y - UIy
		end
		
		return string.format(
			'%s\031%s\031%s\031%d\031%d',
			Ipoint, 'UIParent', Irpoint, round(x * UIS / S),  round(y * UIS / S)
		)
	else
		local point, _, rpoint, x, y = obj:GetPoint()

		return string.format(
			'%s\031%s\031%s\031%d\031%d',
			point, 'UIParent', rpoint, round(x), round(y)
		)
	end
end

local getObjectInformation  = function(obj)
	local identifier = obj:GetName() or obj.unit

	-- Are we dealing with header units?
	local isHeader
	local parent = obj:GetParent()

	if parent then
		if parent:GetAttribute('initialConfigFunction') and parent.style then
			isHeader = parent
		elseif parent:GetAttribute('oUF-onlyProcessChildren') then
			isHeader = parent:GetParent()
		elseif parent:GetParent() and parent:GetParent():GetAttribute('initialConfigFunction') and parent:GetParent().style then
			isHeader = parent:GetParent()
		end
		if isHeader then identifier = isHeader:GetName() end
		
	end

	return identifier, isHeader
end

local saveDefaultPosition = function(obj)
	local identifier, isHeader = getObjectInformation(obj)
	if not positions.__INITIAL then
		positions.__INITIAL = {}
	end

	if not positions.__INITIAL[identifier] then
		local point = getPoint(isHeader or obj)
		
		positions.__INITIAL[identifier] = point
	end
end

local savePosition = function(obj, anchor)
	local identifier, isHeader = getObjectInformation(obj)
	
	positions[identifier] = getPoint(identifier, anchor)
end

local setAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then
			k, k2 = strsplit("_", k)
		end
		if positions[v] and _G[v] and db.oUF[k] then
			str = getPoint(v, backdropPool[_G[v]])
			local point, parent, rpoint, x, y = string.split('\031', str)
			if k2 then
				if db.oUF[k][k2] then
					db.oUF[k].Castbar.X = tostring(x)
					db.oUF[k].Castbar.Y = tostring(y)
				end
			else
				db.oUF[k].X = tostring(x)
				db.oUF[k].Y = tostring(y)
			end
			_G[v]:ClearAllPoints()
			_G[v]:SetPoint(point, parent, rpoint, x, y)
			
			positions[v] = nil
			positions.__INITIAL[v] = nil
		end
	end
end

local resetAllPositions = function()
	if not positions.__INITIAL then return end
	for k, v in pairs(positions.__INITIAL) do
		if _G[k] then
			_G[k]:ClearAllPoints()
			local point, parent, rpoint, x, y = string.split('\031', v)
			_G[k]:SetPoint(point, parent, rpoint, x, y)
			positions[k] = nil
			positions.__INITIAL[k] = nil
			
			local backdrop = backdropPool[_G[k]]
			if backdrop then
				backdrop:ClearAllPoints()
				backdrop:SetAllPoints(_G[k])
			end
		end
	end
end

local smartName
do
	local nameCache = {}
	local validNames = {
		'player',
		'target',
		'focus',
		'raid',
		'pet',
		'party',
		'maintank',
		'mainassist',
		'arena',
	}

	local validName = function(smartName)
		if tonumber(smartName) then
			return smartName
		end

		if type(smartName) == 'string' then
			if smartName == 'mt' then
				return 'maintank'
			end
			if smartName == 'castbar' then
				return ' castbar'
			end

			for _, v in next, validNames do
				if v == smartName then
					return smartName
				end
			end

			if (
				smartName:match'^party%d?$' or
				smartName:match'^arena%d?$' or
				smartName:match'^boss%d?$' or
				smartName:match'^partypet%d?$' or
				smartName:match'^raid%d?%d?$' or
				smartName:match'%w+target$' or
				smartName:match'%w+pet$'
			) then
				return smartName
			end
		end
	end

	local function guessName(...)
		local name = validName(select(1, ...))

		local n = select('#', ...)
		if n > 1 then
			for i=2, n do
				local inp = validName(select(i, ...))
				if inp then
					name = (name or '') .. inp
				end
			end
		end

		return name
	end

	local smartString = function(name)
		if nameCache[name] then
			return nameCache[name]
		end

		local n = name:gsub('(%l)(%u)', '%1_%2'):gsub('([%l%u])(%d)', '%1_%2_'):lower()
		n = guessName(string.split('_', n))
		if n then
			nameCache[name] = n
			return n
		end

		return name
	end

	smartName = function(obj, header)
		if type(obj) == 'string' then
			return smartString(obj)
		elseif header then
			return smartString(header:GetName())
		else
			local name = obj:GetName()
			if name then
				return smartString(name)
			end

			return obj.unit or '<unknown>'
		end
	end
end

do
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(self, event)
		return self[event](self)
	end)

	function frame:PLAYER_REGEN_DISABLED()
		if _LOCK then
			for k, bdrop in next, backdropPool do
				print(k, bdrop)
				bdrop:Hide()
			end
			_LOCK = nil
			
			StaticPopup_Hide("DRAG_UNITFRAMES")
			LUI:Print("UnitFrame anchors hidden due to combat.")
		end
	end
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
end

local getBackdrop
do
	local OnShow = function(self)
		return self.name:SetText(smartName(self.obj, self.header))
	end

	local OnDragStart = function(self)
		saveDefaultPosition(self.obj)
		self:StartMoving()

		local frame = self.header or self.obj
		frame:ClearAllPoints();
		frame:SetPoint("TOPLEFT", self);
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
		savePosition(self.obj, self)
	end

	getBackdrop = function(obj, isHeader)
		local target = isHeader or obj
		if not target and not target:GetCenter() then return end
		if backdropPool[target] then return backdropPool[target] end

		local backdrop = CreateFrame("Frame")
		backdrop:SetParent(UIParent)
		backdrop:Hide()

		backdrop:SetBackdrop(_BACKDROP)
		backdrop:SetFrameStrata("TOOLTIP")
		backdrop:SetAllPoints(target)

		backdrop:EnableMouse(true)
		backdrop:SetMovable(true)
		backdrop:RegisterForDrag("LeftButton")

		backdrop:SetScript("OnShow", OnShow)

		local name = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		name:SetPoint("CENTER")
		name:SetJustifyH("CENTER")
		name:SetFont(GameFontNormal:GetFont(), 12)
		name:SetTextColor(1, 1, 1)

		backdrop.name = name
		backdrop.obj = obj
		backdrop.header = isHeader

		backdrop:SetBackdropBorderColor(0, .9, 0)
		backdrop:SetBackdropColor(0, .9, 0)

		-- Work around the fact that headers with no units displayed are 0 in height.
		if isHeader and math.floor(isHeader:GetHeight()) == 0 then
			local height = isHeader:GetChildren():GetHeight()
			isHeader:SetHeight(height)
		end

		backdrop:SetScript("OnDragStart", OnDragStart)
		backdrop:SetScript("OnDragStop", OnDragStop)

		backdropPool[target] = backdrop

		return backdrop
	end
end

StaticPopupDialogs["DRAG_UNITFRAMES"] = {
	text = "oUF_LUI UnitFrames are dragable.",
	button1 = "Save",
	button3 = "Reset",
	button2 = "Cancel",
	OnShow = function()
		LibStub("AceConfigDialog-3.0"):Close("LUI")
		GameTooltip:Hide()
	end,
	OnHide = function()
		module:MoveUnitFrames(true)
	end,
	OnAccept = setAllPositions,
	OnAlt = resetAllPositions,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function module:MoveUnitFrames(override)
	if InCombatLockdown() and not override then
		return LUI:Print("UnitFrames cannot be moved while in combat.")
	end
	
	if (not _LOCK) and (not override) then
		StaticPopup_Show("DRAG_UNITFRAMES")
		for k, obj in next, oUF.objects do
			if obj.MoveableFrames then
				local identifier, isHeader = getObjectInformation(obj)
				local backdrop = getBackdrop(obj, isHeader)
				if backdrop then backdrop:Show() end
				if _G[obj:GetName().."_Castbar"] then
					local backdrop = getBackdrop(_G[obj:GetName().."_Castbar"])
					if backdrop then backdrop:Show() end
				end
			end
		end

		_LOCK = true
	else
		for k, bdrop in next, backdropPool do
			bdrop:Hide()
		end
		
		StaticPopup_Hide("DRAG_UNITFRAMES")
		_LOCK = nil
	end
end

local frameShow = PlayerFrame.Show

function module:EnableBlizzard(unit)
	local function RegisterBlizzUnitFrame(frame, ...)
		frame.Show = frameShow
		
		for i=1, select('#', ...) do
			frame:RegisterEvent(select(i, ...))
		end
	end
	
	if(unit == 'player') then
		RegisterBlizzUnitFrame(PlayerFrame,
			"UNIT_LEVEL", "UNIT_COMBAT", "UNIT_FACTION", "UNIT_MAXPOWER", "PLAYER_ENTERING_WORLD", "PLAYER_ENTER_COMBAT",
			"PLAYER_LEAVE_COMBAT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "PARTY_MEMBERS_CHANGED",
			"PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "VOICE_START", "VOICE_STOP", "RAID_ROSTER_UPDATE", "READY_CHECK",
			"READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE", "UNIT_ENTERING_VEHICLE", "UNIT_EXITING_VEHICLE",
			"UNIT_EXITED_VEHICLE", "PLAYER_FLAGS_CHANGED", "PLAYER_ROLES_ASSIGNED", "PLAYTIME_CHANGED"
		)
		PlayerFrame:Show()
		
		unit = 'playerCastbar'
	end
	
	if(unit == 'playerCastbar') then
		RegisterBlizzUnitFrame(CastingBarFrame,
			"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
			"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD"
		)
	end
	
	if(unit == 'pet') then
		RegisterBlizzUnitFrame(PetFrame,
			"UNIT_PET", "UNIT_COMBAT", "UNIT_AURA", "PET_ATTACK_START", "PET_ATTACK_STOP", "UNIT_POWER", "PET_UI_UPDATE", "PET_RENAMEABLE"
		)
		
		unit = 'petCastbar'
	end
	
	if(unit == 'petCastbar') then
		RegisterBlizzUnitFrame(PetCastingBarFrame,
			"UNIT_PET", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
			"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD"
		)
	end
	
	if(unit == 'target') then
		RegisterBlizzUnitFrame(TargetFrame,
			"PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "CVAR_UPDATE", "UNIT_LEVEL", "UNIT_FACTION",
			"UNIT_CLASSIFICATION_CHANGED", "UNIT_AURA", "PLAYER_FLAGS_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_TARGET_UPDATE"
		)
		
		RegisterBlizzUnitFrame(TargetFrame.spellbar,
			"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_TARGET_CHANGED"
		)
		
		RegisterBlizzUnitFrame(ComboFrame,
			"PLAYER_TARGET_CHANGED", "UNIT_COMBO_POINTS"
		)
	end
	
	if(unit == 'focus') then
		RegisterBlizzUnitFrame(FocusFrame,
			"PLAYER_ENTERING_WORLD", "PLAYER_FOCUS_CHANGED", "UNIT_HEALTH", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_CLASSIFICATION_CHANGED",
			"UNIT_AURA", "PLAYER_FLAGS_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_TARGET_UPDATE", "VARIABLES_LOADED"
		)
		
		RegisterBlizzUnitFrame(FocusFrame.spellbar,
			"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_FOCUS_CHANGED"
		)
		
		FocusFrame_SetSmallSize(not GetCVarBool("fullSizeFocusFrame"))
	end
	
	if(unit == 'targettarget') then
		RegisterBlizzUnitFrame(TargetFrameToT, false)
	end
	
	if(unit:match'(boss)%d?$' == 'boss') then
		local id = unit:match'boss(%d)'
		if(id) then
			RegisterBlizzUnitFrame(_G['Boss'..id..'TargetFrame'],
				"UNIT_TARGETABLE_CHANGED", id == 1 and "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or nil
			)
		else
			for i=1, 4 do
				RegisterBlizzUnitFrame(_G['Boss'..i..'TargetFrame'],
					"UNIT_TARGETABLE_CHANGED", i == 1 and "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or nil
				)
			end
		end
	end
	
	if(unit:match'(party)%d?$' == 'party') then
		local id = unit:match'party(%d)'
		if(id) then
			RegisterBlizzUnitFrame(_G['PartyMemberFrame'..id],
				"PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "MUTELIST_UPDATE",
				"IGNORELIST_UPDATE", "UNIT_FACTION", "UNIT_AURA", "UNIT_PET", "VOICE_START", "VOICE_STOP", "VARIABLES_LOADED",
				"VOICE_STATUS_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE",
				"UNIT_EXITED_VEHICLE", "UNIT_HEALTH", "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_PHASE"
			)
		else
			for i=1, 4 do
				RegisterBlizzUnitFrame(_G['PartyMemberFrame'..i],
					"PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "MUTELIST_UPDATE",
					"IGNORELIST_UPDATE", "UNIT_FACTION", "UNIT_AURA", "UNIT_PET", "VOICE_START", "VOICE_STOP", "VARIABLES_LOADED",
					"VOICE_STATUS_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE",
					"UNIT_EXITED_VEHICLE", "UNIT_HEALTH", "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_PHASE"
				)
			end
		end
	end
	
	if(unit:match'(arena)%d?$' == 'arena') then
		if not ArenaEnemyFrame1 then Arena_LoadUI_() end
		local id = unit:match'arena(%d)'
		if(id) then
			RegisterBlizzUnitFrame(_G['ArenaEnemyFrame'..id],
				"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD"
			)
		else
			for i=1, 5 do
				RegisterBlizzUnitFrame(_G['ArenaEnemyFrame'..i],
					"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD"
				)
			end
		end
	end
end

local ufUnits = {
	Player = "player",
	Target = "target",
	ToT = "targettarget",
	ToToT = "targettargettarget",
	Focus = "focus",
	FocusTarget = "focustarget",
	Pet = "pet",
	PetTarget = "pettarget",
}

local toggleFuncs = {
	Default = function(unit) 
		if db.oUF[unit].Enable == nil or db.oUF[unit].Enable then -- == nil needed for player/target
			if _G["oUF_LUI_"..ufUnits[unit]] then
				_G["oUF_LUI_"..ufUnits[unit]]:Enable()
				_G["oUF_LUI_"..ufUnits[unit]]:UpdateAllElements()
				_G["oUF_LUI_"..ufUnits[unit]]:ClearAllPoints()
				_G["oUF_LUI_"..ufUnits[unit]]:SetPoint("CENTER", UIParent, "CENTER", tonumber(db.oUF[unit].X), tonumber(db.oUF[unit].Y))
			else
				oUF:Spawn(ufUnits[unit], "oUF_LUI_"..ufUnits[unit]):SetPoint("CENTER", UIParent, "CENTER", tonumber(db.oUF[unit].X), tonumber(db.oUF[unit].Y))
			end
		else
			if _G["oUF_LUI_"..ufUnits[unit]] then _G["oUF_LUI_"..ufUnits[unit]]:Disable() end
		end
	end,
	
	Boss = function()
		if db.oUF.Boss.Enable then
			if oUF_LUI_boss1 then
				for i = 1, MAX_BOSS_FRAMES do
					_G["oUF_LUI_boss"..i]:Enable()
					_G["oUF_LUI_boss"..i]:UpdateAllElements()
					_G["oUF_LUI_boss"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_boss"..i]:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Boss.X), tonumber(db.oUF.Boss.Y))
					else
						_G["oUF_LUI_boss"..i]:SetPoint('TOP', _G["oUF_LUI_boss"..i-1], 'BOTTOM', 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
			else
				local boss = {}
				for i = 1, MAX_BOSS_FRAMES do
					boss[i] = oUF:Spawn("boss"..i, "oUF_LUI_boss"..i)
					if i == 1 then
						boss[i]:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Boss.X), tonumber(db.oUF.Boss.Y))
					else
						boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
				
				if db.oUF.BossTarget.Enable == true then
					local bosstarget = {}
					for i = 1, MAX_BOSS_FRAMES do
						bosstarget[i] = oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i)
						bosstarget[i]:SetPoint(db.oUF.BossTarget.Point, boss[i], db.oUF.BossTarget.RelativePoint, tonumber(db.oUF.BossTarget.X), tonumber(db.oUF.BossTarget.Y))
					end
				end
			end
		else
			for i = 1, MAX_BOSS_FRAMES do
				if _G["oUF_LUI_boss"..i] then _G["oUF_LUI_boss"..i]:Disable() end
				if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Disable() end
			end
		end
	end,
	
	BossTarget = function()
		if db.oUF.Boss.Enable and db.oUF.BossTarget.Enable then
			if not oUF_LUI_bosstarget1 then
				local bosstarget = {}
				for i = 1, MAX_BOSS_FRAMES do
					bosstarget[i] = oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i)
					bosstarget[i]:SetPoint(db.oUF.BossTarget.Point, _G["oUF_LUI_boss"..i], db.oUF.BossTarget.RelativePoint, tonumber(db.oUF.BossTarget.X), tonumber(db.oUF.BossTarget.Y))
				end
			else
				for i = 1, MAX_BOSS_FRAMES do
					if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Enable() end
				end
			end
		else
			for i = 1, MAX_BOSS_FRAMES do
				if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Disable() end
			end
		end
	end,
	
	Party = function()
		if db.oUF.Party.Enable then
			if oUF_LUI_party then
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint("LEFT", UIParent, "LEFT", tonumber(db.oUF.Party.X), tonumber(db.oUF.Party.Y))
				oUF_LUI_party:SetAttribute("yOffset", - tonumber(db.oUF.Party.Padding))
				oUF_LUI_party:SetAttribute("showPlayer", db.oUF.Party.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..db.oUF.Party.Height..[[)
						self:SetWidth(]]..db.oUF.Party.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
						self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
						self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
						self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
						self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
					end
				]])
				
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Enable()
						_G["oUF_LUI_partyUnitButton"..i]:UpdateAllElements()
					end
				end
				
				if not InCombatLockdown() then
					if not db.oUF.Party.ShowInRaid then
						local numraid = GetNumRaidMembers()
						if numraid > 0 and (numraid > 5 or numraid ~= GetNumPartyMembers() + 1) then
							oUF_LUI_party:Hide()
						else
							oUF_LUI_party:Show()
						end
					else
						oUF_LUI_party:Show()
					end
				end
			else
				local party = oUF:SpawnHeader("oUF_LUI_party", nil, nil,
					"showParty", true,
					"showPlayer", db.oUF.Party.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"yOffset", - tonumber(db.oUF.Party.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..db.oUF.Party.Height..[[)
							self:SetWidth(]]..db.oUF.Party.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
							self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
							self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
							self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
							self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
						end
					]]
				)
				
				party:SetPoint("LEFT", UIParent, "LEFT", tonumber(db.oUF.Party.X), tonumber(db.oUF.Party.Y))
				
				local partyToggle = CreateFrame("Frame")
				partyToggle:RegisterEvent("PLAYER_LOGIN")
				partyToggle:RegisterEvent("RAID_ROSTER_UPDATE")
				partyToggle:RegisterEvent("PARTY_LEADER_CHANGED")
				partyToggle:RegisterEvent("PARTY_MEMBERS_CHANGED")
				partyToggle:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")

						if not db.oUF.Party.ShowInRaid then
							local numraid = GetNumRaidMembers()
							if numraid > 0 and (numraid > 5 or numraid ~= GetNumPartyMembers() + 1) then
								party:Hide()
							else
								party:Show()
							end
						else
							party:Show()
						end
					end
				end)
			end
		else
			if oUF_LUI_party then
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then _G["oUF_LUI_partyUnitButton"..i]:Disable() end
				end
				oUF_LUI_party:Hide()
			end
		end
	end,
	
	PartyTarget = function()
		if db.oUF.Party.Enable and db.oUF.PartyTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(db.oUF.PartyTarget.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyTarget.RelativePoint, tonumber(db.oUF.PartyTarget.X), tonumber(db.oUF.PartyTarget.Y))
				end
			end
			
			oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "party" then
					self:SetHeight(]]..db.oUF.Party.Height..[[)
					self:SetWidth(]]..db.oUF.Party.Width..[[)
				elseif unit == "partytarget" then
					self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
					self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
					self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
				elseif unit == "partypet" then
					self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
					self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
					self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
				end
			]])
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,
	
	PartyPet = function()
		if db.oUF.Party.Enable and db.oUF.PartyPet.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(db.oUF.PartyPet.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyPet.RelativePoint, tonumber(db.oUF.PartyPet.X), tonumber(db.oUF.PartyPet.Y))
				end
			end
			
			oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "party" then
					self:SetHeight(]]..db.oUF.Party.Height..[[)
					self:SetWidth(]]..db.oUF.Party.Width..[[)
				elseif unit == "partytarget" then
					self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
					self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
					self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
				elseif unit == "partypet" then
					self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
					self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
					self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
				end
			]])
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then _G["oUF_LUI_partyUnitButton"..i.."pet"]:Disable() end
			end
		end
	end,
	
	Arena = function()
		if db.oUF.Arena.Enable then
			SetCVar("showArenaEnemyFrames", 0)
			
			if oUF_LUI_arena then
				for i = 1, 5 do
					_G["oUF_LUI_arena"..i]:Enable()
					_G["oUF_LUI_arena"..i]:UpdateAllElements()
					_G["oUF_LUI_arena"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_arena"..i]:SetPoint("TOPRIGHT", oUF_LUI_arena, "TOPRIGHT", 0, 0)
					else
						_G["oUF_LUI_arena"..i]:SetPoint("TOP", _G["oUF_LUI_arena"..i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end
				oUF_LUI_arena:Show()
			else
				local arenaParent = CreateFrame("Frame", "oUF_LUI_arena", UIParent)
				arenaParent:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Arena.X), tonumber(db.oUF.Arena.Y))
				arenaParent:SetWidth(tonumber(db.oUF.Arena.Width))
				arenaParent:SetHeight(tonumber(db.oUF.Arena.Height))

				local arena = {}

				for i = 1, 5 do
					arena[i] = oUF:Spawn("arena"..i, "oUF_LUI_arena"..i)
					if i == 1 then
						arena[i]:SetPoint("TOPRIGHT", arenaParent, "TOPRIGHT", 0, 0)
					else
						arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end

				if db.oUF.ArenaTarget.Enable == true then
					local arenatarget = {}
					for i = 1, 5 do
						arenatarget[i] = oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i)
						arenatarget[i]:SetPoint(db.oUF.ArenaTarget.Point, arena[i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
					end
				end

				if db.oUF.ArenaPet.Enable == true then
					local arenapet = {}
					for i = 1, 5 do
						arenapet[i] = oUF:Spawn("arena"..i.."pet", "oUF_LUI_arenapet"..i)
						arenapet[i]:SetPoint(db.oUF.ArenaPet.Point, arena[i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaTarget.Y))
					end
				end

				arenaParent:RegisterEvent("PLAYER_LOGIN")
				arenaParent:RegisterEvent("PLAYER_ENTERING_WORLD")
				arenaParent:RegisterEvent("ARENA_OPPONENT_UPDATE")
				arenaParent:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")
						
						local c = 0
						for i = 1, 5 do
							if arena[i]:IsShown() then c = i end
						end

						if c > 0 then
							self:SetHeight(tonumber(db.oUF.Arena.Height) * c + tonumber(db.oUF.Arena.Padding) * (c-1))
						end
					end
				end)
			end
		else
			if db.oUF.Arena.UseBlizzard == true then
				SetCVar("showArenaEnemyFrames", 1)
			else
				SetCVar("showArenaEnemyFrames", 0)
			end
			
			for i = 1, 5 do
				if _G["oUF_LUI_arena"..i] then _G["oUF_LUI_arena"..i]:Disable() end
			end
			oUF_LUI_arena:Hide()
		end
	end,
	
	ArenaTarget = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements()
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then _G["oUF_LUI_arenatarget"..i]:Disable() end
			end
		end
	end,
	
	ArenaPet = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaPet.Enable == true then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements()
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then _G["oUF_LUI_arenapet"..i]:Disable() end
			end
		end
	end,
	
	Maintank = function()
		if db.oUF.Maintank.Enable then
			if oUF_LUI_maintank then
				oUF_LUI_maintank:ClearAllPoints()
				oUF_LUI_maintank:SetPoint("TOPRIGHT", UIParent, "RIGHT", tonumber(db.oUF.Maintank.X), tonumber(db.oUF.Maintank.Y))
				oUF_LUI_maintank:SetAttribute("yOffset", - tonumber(db.oUF.Maintank.Padding))
				oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "raidtargettarget" then
						self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
					elseif unit == "raidtarget" then
						self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
					elseif unit == "raid" then
						self:SetHeight(]]..db.oUF.Maintank.Height..[[)
						self:SetWidth(]]..db.oUF.Maintank.Width..[[)
					end
				]])
				oUF_LUI_maintank:Show()
				
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then
						_G["oUF_LUI_maintankUnitButton"..i]:Enable()
						_G["oUF_LUI_maintankUnitButton"..i]:UpdateAllElements()
					end
				end
			else
				local tank = oUF:SpawnHeader("oUF_LUI_maintank", nil, nil,
					"showRaid", true,
					"groupFilter", "MAINTANK",
					"template", "oUF_LUI_maintank",
					"showPlayer", true,
					"wrapAfter", 4,
					"yOffset", - tonumber(db.oUF.Maintank.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "raidtargettarget" then
							self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
						elseif unit == "raidtarget" then
							self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
						elseif unit == "raid" then
							self:SetHeight(]]..db.oUF.Maintank.Height..[[)
							self:SetWidth(]]..db.oUF.Maintank.Width..[[)
						end
					]]
				)
				
				tank:SetPoint("TOPRIGHT", UIParent, "RIGHT", tonumber(db.oUF.Maintank.X), tonumber(db.oUF.Maintank.Y))
				tank:Show()
			end
		else
			if oUF_LUI_maintank then
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then _G["oUF_LUI_maintankUnitButton"..i]:Disable() end
				end
				oUF_LUI_maintank:Hide()
			end
		end
	end,
	
	MaintankTarget = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:Enable()
					--_G["oUF_LUI_maintankUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(db.oUF.MaintankTarget.Point, _G["oUF_LUI_maintankUnitButton"..i], db.oUF.MaintankTarget.RelativePoint, tonumber(db.oUF.MaintankTarget.X), tonumber(db.oUF.MaintankTarget.Y))
				end
			end
			
			oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "raidtargettarget" then
					self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
				elseif unit == "raidtarget" then
					self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
				elseif unit == "raid" then
					self:SetHeight(]]..db.oUF.Maintank.Height..[[)
					self:SetWidth(]]..db.oUF.Maintank.Width..[[)
				end
			]])
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
			end
		end
	end,
	
	MaintankToT = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable and db.oUF.MaintankToT.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:UpdateAllElements()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(db.oUF.MaintankToT.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], db.oUF.MaintankToT.RelativePoint, tonumber(db.oUF.MaintankToT.X), tonumber(db.oUF.MaintankToT.Y))
				end
			end
			
			oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "raidtargettarget" then
					self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
				elseif unit == "raidtarget" then
					self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
				elseif unit == "raid" then
					self:SetHeight(]]..db.oUF.Maintank.Height..[[)
					self:SetWidth(]]..db.oUF.Maintank.Width..[[)
				end
			]])
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
			end
		end
	end,

	Raid = function()
		if db.oUF.Raid.Enable then
			if oUF_LUI_raid then
				for i = 1, 5 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then frame:Enable() end
					end
				end
				
				for i = 1, 8 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then frame:Enable() end
					end
				end
			else
				local raidAnchor = CreateFrame("Frame", "oUF_LUI_raid", UIParent)
				raidAnchor:SetWidth(tonumber(db.oUF.Raid.Width) * 5 + tonumber(db.oUF.Raid.GroupPadding) * 4)
				raidAnchor:SetHeight(tonumber(db.oUF.Raid.Height) * 5 + tonumber(db.oUF.Raid.Padding) * 4)
				raidAnchor:SetPoint(db.oUF.Raid.Point, UIParent, db.oUF.Raid.Point, tonumber(db.oUF.Raid.X), tonumber(db.oUF.Raid.Y))
				
				local raid25 = CreateFrame("Frame", "oUF_LUI_raid_25", raidAnchor)
				raid25:SetWidth(1)
				raid25:SetHeight(1)
				raid25:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				
				local raid25table = {}
				for i = 1, 5 do
					raid25table[i] = oUF:SpawnHeader("oUF_LUI_raid_25_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - tonumber(db.oUF.Raid.Padding),
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..db.oUF.Raid.Height..[[)
							self:SetWidth(]]..db.oUF.Raid.Width..[[)
						]]
					)
					raid25table[i]:SetParent(raid25)
					raid25table[i]:Show()
					if i == 1 then
						raid25table[i]:SetPoint("TOPLEFT", raid25, "TOPLEFT", 0, 0)
					else
						raid25table[i]:SetPoint("TOPLEFT", raid25table[i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
					end
				end
				
				local raid40 = CreateFrame("Frame", "oUF_LUI_raid_40", raidAnchor)
				raid40:SetWidth(1)
				raid40:SetHeight(1)
				raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				
				local width40 = (5 * tonumber(db.oUF.Raid.Height) - 3 * tonumber(db.oUF.Raid.GroupPadding)) / 8
				
				local raid40table = {}
				for i = 1, 8 do
					raid40table[i] = oUF:SpawnHeader("oUF_LUI_raid_40_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - tonumber(db.oUF.Raid.Padding),
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..db.oUF.Raid.Height..[[)
							self:SetWidth(]]..width40..[[)
						]]
					)
					raid40table[i]:SetParent(raid40)
					raid40table[i]:Show()
					if i == 1 then
						raid40table[i]:SetPoint("TOPLEFT", raid40, "TOPLEFT", 0, 0)
					else
						raid40table[i]:SetPoint("TOPLEFT", raid40table[i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
					end
				end
				
				raidAnchor:RegisterEvent("PLAYER_LOGIN")
				raidAnchor:RegisterEvent("RAID_ROSTER_UPDATE")
				raidAnchor:RegisterEvent("PARTY_LEADER_CHANGED")
				raidAnchor:RegisterEvent("PARTY_MEMBERS_CHANGED")
				
				raidAnchor:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")
						
						local numraid = GetNumRaidMembers()
						if numraid > 25 then
							raid25:Hide()
							raid40:Show()
						else
							raid40:Hide()
							raid25:Show()
						end
					end
				end)
			end
		else
			for i = 1, 5 do
				for j = 1, 5 do
					local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
					if frame then frame:Disable() end
				end
			end
			
			for i = 1, 8 do
				for j = 1, 5 do
					local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
					if frame then frame:Disable() end
				end
			end
		end
	end,
}

function module:Toggle(unit)
	oUF:SetActiveStyle("LUI")
	if toggleFuncs[unit] then
		toggleFuncs[unit]()
	else
		toggleFuncs["Default"](unit)
	end
end

local defaults = {
	oUF = {
		Settings = {
			Enable = true,
			show_v2_textures = true,
			show_v2_party_textures = true,
			show_v2_arena_textures = true,
			show_v2_boss_textures = true,
			Castbars = true,
			Auras = {
				auratimer_font = "Prototype",
				auratimer_size = 12,
				auratimer_flag = "OUTLINE",
			},
		},
	}
}

function module:LoadOptions()
	local ToggleV2 = function(self, Enable)
		for _, f in pairs({"oUF_LUI_targettarget", "oUF_LUI_targettargettarget", "oUF_LUI_focustarget", "oUF_LUI_focus"}) do
			if _G[f] then
				if not _G[f].V2Tex then LUI.oUF.funcs.V2Textures(_G[f], _G[f].__unit) end
				if Enable then
					_G[f].V2Tex:Show()
				else
					_G[f].V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Party = function(self, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_partyUnitButton"..i.."target"]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Arena = function(self, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_arenatarget"..i]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Boss = function(self, Enable)
		for i = 1, MAX_BOSS_FRAMES do
			local f = _G["oUF_LUI_bosstarget"..i]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleCB = function(self, Enable)
		for unit, frame in pairs({Player = "oUF_LUI_player", Target = "oUF_LUI_target", Focus = "oUF_LUI_focus", Pet = "oUF_LUI_pet"}) do
			if Enable then
				if _G[frame] and db.oUF[unit].Castbar.Enable then
					if not _G[frame].Castbar then LUI.oUF.funcs.Castbar(_G[frame], _G[frame].__unit, db.oUF[unit]) end
					_G[frame]:EnableElement("Castbar")
				end
			else
				if _G[frame] and _G[frame].Castbar then
					_G[frame].Castbar:Hide()
					_G[frame]:DisableElement("Castbar")
					module:EnableBlizzard(strlower(unit).."Castbar")
				end
			end
			_G[frame]:UpdateAllElements()
		end
		
		for i = 1, 5 do
			local p = _G["oUF_LUI_partyUnitButton"..i]
			local a = _G["oUF_LUI_arena"..i]
			
			if Enable then
				if p and db.oUF.Party.Castbar.Enable then
					if not p.Castbar then LUI.oUF.funcs.Castbar(p, p.__unit, db.oUF.Party) end
					p:EnableElement("Castbar")
				end
				
				if a and db.oUF.Arena.Castbar.Enable then
					if not a.Castbar then LUI.oUF.funcs.Castbar(a, a.__unit, db.oUF.Arena) end
					a:EnableElement("Castbar")
				end
			else
				if p and p.Castbar then
					p.Castbar:Hide()
					p:DisableElement("Castbar")
				end
				
				if a and a.Castbar then
					a.Castbar:Hide()
					a:DisableElement("Castbar")
				end
			end
		end
	end
	
	local ToggleCBLatency = function(self, Enable)
		if Enable then
			oUF_LUI_player.Castbar.SafeZone:Show()
		else
			oUF_LUI_player.Castbar.SafeZone:Hide()
		end
	end
	
	local ToggleCBIcon = function(self, Enable)
		db.oUF.Player.Castbar.Icon = Enable
		db.oUF.Target.Castbar.Icon = Enable
										
		for k, v in pairs({Player = "oUF_LUI_player", Target = "oUF_LUI_target"}) do
			if _G[v] and _G[v].Castbar then
				if Enable then
					_G[v].Castbar.Icon:Show()
					_G[v].Castbar.IconOverlay:Show()
					_G[v].Castbar.IconBackdrop:Show()
				else
					_G[v].Castbar.Icon:Hide()
					_G[v].Castbar.IconOverlay:Hide()
					_G[v].Castbar.IconBackdrop:Hide()
				end
			end
			_G[v]:UpdateAllElements()
		end
	end
	
	local ToggleCBIconFP = function(self, Enable)
		db.oUF.Focus.Castbar.Icon = Enable
		db.oUF.Pet.Castbar.Icon = Enable
		
		for k, v in pairs({Focus = "oUF_LUI_focus", Pet = "oUF_LUI_pet"}) do
			if _G[v] and _G[v].Castbar then
				if Enable then
					_G[v].Castbar.Icon:Show()
					_G[v].Castbar.IconOverlay:Show()
					_G[v].Castbar.IconBackdrop:Show()
				else
					_G[v].Castbar.Icon:Hide()
					_G[v].Castbar.IconOverlay:Hide()
					_G[v].Castbar.IconBackdrop:Hide()
				end
			end
			_G[v]:UpdateAllElements()
		end
	end
	
	local ToggleCBIconPA = function(self, Enable)
		db.oUF.Party.Castbar.Icon = Enable
		db.oUF.Arena.Castbar.Icon = Enable
											
		for _, prefix in pairs({Party = "oUF_LUI_partyUnitButton", Arena = "oUF_LUI_arena"}) do
			for i = 1, 5 do
				local f = _G[prefix..i]
				if f and f.Castbar then
					if Enable then
						f.Castbar.Icon:Show()
						f.Castbar.IconOverlay:Show()
						f.Castbar.IconBackdrop:Show()
					else
						f.Castbar.Icon:Hide()
						f.Castbar.IconOverlay:Hide()
						f.Castbar.IconBackdrop:Hide()
					end
				f:UpdateAllElements()
				end
			end
		end							
	end
	
	local UpdateAuraTimer = function()
		for k, v in pairs(oUF.objects) do
			if v.Buffs then
				for i = 1, 50 do
					if v.Buffs[i] then
						v.Buffs[i].remaining:SetFont(LSM:Fetch("font",  db.oUF.Settings.Auras.auratimer_font), db.oUF.Settings.Auras.auratimer_size, db.oUF.Settings.Auras.auratimer_flag)
					else
						break
					end
				end
			end
			if v.Debuffs then
				for i = 1, 50 do
					if v.Debuffs[i] then
						v.Debuffs[i].remaining:SetFont(LSM:Fetch("font",  db.oUF.Settings.Auras.auratimer_font), db.oUF.Settings.Auras.auratimer_size, db.oUF.Settings.Auras.auratimer_flag)
					else
						break
					end
				end
			end
		end
	end
	
	local options = {
		UnitFrames = {
			name = "UnitFrames",
			type = "group",
			order = 20,
			args = {
				header7 = LUI:NewHeader("UnitFrames", 1),
				Settings = {
					name = "Settings",
					type = "group",
					guiInline = true,
					order = 2,
					args = {
						Enable = LUI:NewToggle("Enable oUF LUI", "Whether you want to use LUI UnitFrames or not", 1, db.oUF.Settings, "Enable", nil, function() StaticPopup_Show("RELOAD_UI") end),
						ShowV2Tex = LUI:NewToggle("Show LUI v2 Connector Frames", "Whether you want to show LUI v2 Frame Connectors or not.", 2, db.oUF.Settings, "show_v2_textures", LUI.defaults.profile.oUF.Settings, ToggleV2, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Party = LUI:NewToggle("Show LUI v2 Connector Frames for Party Frames", "Whether you want to show LUI v2 Frame Connectors on the Party Frames or not.", 3, db.oUF.Settings, "show_v2_party_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Party, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Arena = LUI:NewToggle("Show LUI v2 Connector Frames for Arena Frames", "Whether you want to show LUI v2 Frame Connectors on the Arena Frames or not.", 4, db.oUF.Settings, "show_v2_arena_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Arena, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Boss = LUI:NewToggle("Show LUI v2 Connector Frames for Boss Frames", "Whether you want to show LUI v2 Frame Connectors on the Boss Frames or not.", 5, db.oUF.Settings, "show_v2_boss_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Boss, nil, function() return not db.oUF.Settings.Enable end),
						MoveFrames = LUI:NewExecute("Move UnitFrames", "Show dummy frames for all of the UnitFrames and make them draggable", 6, function() module:MoveUnitFrames() end, nil, function() return not db.oUF.Settings.Enable end),
					},
				},
				CastbarSettings = {
					name = "Castbars",
					type = "group",
					guiInline = true,
					disabled = function() return not db.oUF.Settings.Enable end,
					order = 3,
					args = {
						CBEnable = LUI:NewToggle("Enable Castbars", "Whether you want to use oUF Castbars or not.", 1, db.oUF.Settings, "Castbars", LUI.defaults.profile.oUF.Settings, ToggleCB),
						CBLatency = LUI:NewToggle("Castbar Latency", "Whether you want to show your Castbar Latency or not.", 2, db.oUF.Player.Castbar, "Latency", LUI.defaults.profile.oUF.Settings, ToggleCBLatency, nil, function() return not db.oUF.Settings.Castbars end),
						CBIcons = LUI:NewToggle("Castbar Icons", "Whether you want to show Icons on Player/Target Castbar or not.", 3, db.oUF.Player.Castbar, "Icon", LUI.defaults.profile.oUF.Player.Castbar, ToggleCBIcon, nil, function() return not db.oUF.Settings.Castbars end),
						CBIconsFP = LUI:NewToggle("Castbar Icons Focus/Pet", "Whether you want to show Icons on Focus/Pet Castbar or not.", 4, db.oUF.Focus.Castbar, "Icon", LUI.defaults.profile.oUF.Focus.Castbar, ToggleCBIconFP, nil, function() return not db.oUF.Settings.Castbars end),
						CBIconsPA = LUI:NewToggle("Castbar Icons Arena/Party", "Whether you want to show Icons on Arena/Party Castbar or not.", 5, db.oUF.Party.Castbar, "Icon", LUI.defaults.profile.oUF.Party.Castbar, ToggleCBIconPA, nil, function() return not db.oUF.Settings.Castbars end),
					},
				},
				AuraSettings = {
					name = "Auras",
					type = "group",
					guiInline = true,
					order = 4,
					args = {
						AuratimerFont = LUI:NewSelect("Auratimer Font", "Choose the Font for Auratimers.", 1, widgetLists.font, "LSM30_Font", db.oUF.Settings.Auras, "auratimer_font", LUI.defaults.profile.oUF.Settings.Auras, UpdateAuraTimer),
						AuratimerFontsize = LUI:NewSlider("Size", "Choose the Auratimers Fontsize.", 2, db.oUF.Settings.Auras, "auratimer_size", LUI.defaults.profile.oUF.Settings.Auras, 5, 20, 1, UpdateAuraTimer),
						AuratimerFontflag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the Auratimers.", 3, fontflags, nil, db.oUF.Settings.Auras, "auratimer_flag", LUI.defaults.profile.oUF.Settings.Auras, UpdateAuraTimer),
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
	
	LUI:RegisterOptions(self)
end

-- the OnEnable function is in the layout.lua file
--function module:OnEnable()
--end