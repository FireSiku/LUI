--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: movable.lua
	Description: Unitframe Movable Features (will be converted to an own module)
]] 

local addonname, LUI = ...
local module = LUI:Module("Unitframes")

local oUF = LUI.oUF

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
	Arena = "oUF_LUI_arena"
}

local _LOCK
local _BACKDROP = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}

local backdropPool = {}

local setAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then k, k2 = strsplit("_", k) end
		if _G[v] and module.db[k] then
			local point, _, rpoint, x, y = backdropPool[_G[v]]:GetPoint()
			
			if k2 then
				if module.db[k][k2] then
					module.db[k][k2].General.X = x
					module.db[k][k2].General.Y = y
					module.db[k][k2].General.Point = point
				end
			else
				module.db[k].X = x * (module.db[k].Scale or 1)
				module.db[k].Y = y * (module.db[k].Scale or 1)
				module.db[k].Point = point
			end
			
			local scale = module.db[k].Scale or 1
			_G[v]:ClearAllPoints()
			_G[v]:SetPoint(point, UIParent, rpoint, x, y)
		end
	end
	
	for k, v in pairs(ufNames) do
		if _G[v] and _G[v].V2Tex then _G[v].V2Tex:Reposition() end
	end
end

local resetAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then k, k2 = strsplit("_", k) end
		if _G[v] and module.db[k] then
			if backdropPool[_G[v]] then backdropPool[_G[v]]:ClearAllPoints() end
			
			if k2 then
				if module.db[k][k2] then
					_G[v]:ClearAllPoints()
					_G[v]:SetPoint(module.db[k][k2].General.Point, UIParent, module.db[k][k2].General.Point, module.db[k][k2].General.X, module.db[k][k2].General.Y)
				end
			else
				_G[v]:ClearAllPoints()
				_G[v]:SetPoint(module.db[k].Point, UIParent, module.db[k].Point, module.db[k].X / (module.db[k].Scale or 1), module.db[k].Y / (module.db[k].Scale or 1))
			end
		end
	end
	
	for k, v in pairs(ufNames) do
		if _G[v] and _G[v].V2Tex then _G[v].V2Tex:Reposition() end
	end
end

local smartName
do
	local nameCache = {}
	
	local validNames = {"player", "target", "focus", "raid", "pet", "party", "maintank", "mainassist", "arena"}

	local validName = function(smartName)
		if tonumber(smartName) then return smartName end

		if type(smartName) == "string" then
			if smartName == "mt" then
				return "maintank"
			end
			if smartName == "castbar" then
				return " castbar"
			end

			for _, v in next, validNames do
				if v == smartName then
					return smartName
				end
			end

			if (
				smartName:match("^party%d?$") or
				smartName:match("^arena%d?$") or
				smartName:match("^boss%d?$") or
				smartName:match("^partypet%d?$") or
				smartName:match("^raid%d?%d?$") or
				smartName:match("%w+target$") or
				smartName:match("%w+pet$")
			) then
				return smartName
			end
		end
	end

	local guessName = function(...)
		local name = validName(...)

		local n = select("#", ...)
		if n > 1 then
			for i = 2, n do
				local inp = validName(select(i, ...))
				if inp then name = (name or "")..inp end
			end
		end

		return name
	end

	local smartString = function(name)
		if nameCache[name] then return nameCache[name] end

		local n = name:gsub("(%l)(%u)", "%1_%2"):gsub("([%l%u])(%d)", "%1_%2_"):lower()
		n = guessName(string.split("_", n))
		if n then
			nameCache[name] = n
			return n
		end

		return name
	end

	smartName = function(obj)
		if type(obj) == "string" then
			return smartString(obj)
		else
			local name = obj:GetName()
			if name then return smartString(name) end
			return obj.unit or "<unknown>"
		end
	end
end

local hider = CreateFrame("Frame")
hider:SetScript("OnEvent", function()
	if _LOCK then
		for k, bdrop in next, backdropPool do bdrop:Hide() end
		_LOCK = nil
		
		StaticPopup_Hide("DRAG_UNITFRAMES")
		LUI:Print("UnitFrame anchors hidden due to combat. The changed positions are NOT saved!")
		hider:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
end)

local getBackdrop
do
	local OnShow = function(self)
		return self.name:SetText(smartName(self.obj))
	end

	local OnDragStart = function(self)
		self:StartMoving()

		local frame = self.obj
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", self)
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
	end

	getBackdrop = function(obj)
		if not obj and not obj:GetCenter() then return end
		
		if math.floor(obj:GetHeight()) == 0 then obj:SetHeight(obj:GetChildren():GetHeight()) end

		if backdropPool[obj] then
			backdropPool[obj]:SetScale(obj:GetScale())
			backdropPool[obj]:SetPoint(obj:GetPoint())
			backdropPool[obj]:SetSize(obj:GetSize())
			return backdropPool[obj]
		end

		local backdrop = CreateFrame("Frame")
		backdrop:SetParent(UIParent)
		backdrop:Hide()

		backdrop:SetScale(obj:GetScale())
		backdrop:SetPoint(obj:GetPoint())
		backdrop:SetSize(obj:GetSize())
		
		backdrop:SetBackdrop(_BACKDROP)
		backdrop:SetBackdropColor(0, .9, 0)
		backdrop:SetBackdropBorderColor(0, .9, 0)
		
		backdrop:SetFrameStrata("TOOLTIP")

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

		backdrop:SetScript("OnDragStart", OnDragStart)
		backdrop:SetScript("OnDragStop", OnDragStop)

		backdropPool[obj] = backdrop

		return backdrop
	end
end

StaticPopupDialogs["DRAG_UNITFRAMES"] = {
	preferredIndex = 3,
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
	OnCancel = resetAllPositions,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function module:MoveUnitFrames(override)
	if InCombatLockdown() and not override then
		return LUI:Print("UnitFrames cannot be moved while in combat.")
	end
	
	if oUF_LUI_party then oUF_LUI_party:Show() end
	
	if (not _LOCK) and (not override) then
		hider:RegisterEvent("PLAYER_REGEN_DISABLED")
		StaticPopup_Show("DRAG_UNITFRAMES")
		
		for k, v in pairs(ufNames) do
			if _G[v] then
				local bd = getBackdrop(_G[v])
				if bd then bd:Show() end
			end
		end

		_LOCK = true
	else
		for k, bdrop in next, backdropPool do
			bdrop:Hide()
		end
		
		StaticPopup_Hide("DRAG_UNITFRAMES")
		_LOCK = nil
		
		hider:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
end
