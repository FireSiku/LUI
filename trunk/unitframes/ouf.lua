--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: ouf.lua
	Description: oUF Module
	Version....: 1.0
]] 

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
	Boss = "oUF_LUI_boss1",
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
end

local defaults = {
	oUF = {
		Settings = {
			Enable = true,
			show_v2_textures = true,
			show_v2_party_textures = true,
			show_v2_arena_textures = true,
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
				if not _G[f].V2Tex then oUF_LUI.funcs.V2Textures(_G[f], _G[f].__unit) end
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
				if not f.V2Tex then oUF_LUI.funcs.V2Textures(f, f.__unit) end
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
				if not f.V2Tex then oUF_LUI.funcs.V2Textures(f, f.__unit) end
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
					if not _G[frame].Castbar then oUF_LUI.funcs.Castbar(_G[frame], _G[frame].__unit, db.oUF[unit]) end
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
					if not p.Castbar then oUF_LUI.funcs.Castbar(p, p.__unit, db.oUF.Party) end
					p:EnableElement("Castbar")
				end
				
				if a and db.oUF.Arena.Castbar.Enable then
					if not a.Castbar then oUF_LUI.funcs.Castbar(a, a.__unit, db.oUF.Arena) end
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
			disabled = function() return not IsAddOnLoaded("oUF") end,
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
						MoveFrames = LUI:NewExecute("Move UnitFrames", "Show dummy frames for all of the UnitFrames and make them draggable", 5, function() module:MoveUnitFrames() end, nil, function() return not db.oUF.Settings.Enable end),
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

function module:OnEnable()
end