--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: movable.lua
	Description: Unitframe Movable Features (will be converted to an own module)
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Unitframes
local module = LUI:GetModule("Unitframes")

local RoundToSignificantDigits = _G.RoundToSignificantDigits --[[@as function]]

local ufNames = {
	player = "oUF_LUI_player",
	target = "oUF_LUI_target",
	targettarget = "oUF_LUI_targettarget",
	targettargettarget = "oUF_LUI_targettargettarget",
	focus = "oUF_LUI_focus",
	focustarget = "oUF_LUI_focustarget",
	pet = "oUF_LUI_pet",
	pettarget = "oUF_LUI_pettarget",
	party = "oUF_LUI_party",
	maintank = "oUF_LUI_maintank",
	boss = "oUF_LUI_boss",
	raid = "oUF_LUI_raid",
	player_Castbar = "oUF_LUI_player_Castbar",
	target_Castbar = "oUF_LUI_target_Castbar",
	arena = "oUF_LUI_arena"
}

local _LOCK
local _BACKDROP = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}

local backdropPool = {}

local function GetMoveObject(unit, frameName)
	local previewObject = module.GetUnitframePreviewAnchor and module:GetUnitframePreviewAnchor(unit)
	return previewObject or _G[frameName]
end

local setAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then k, k2 = strsplit("_", k) end
		local object = GetMoveObject(k, v)
		if object and module.db.profile[k] and backdropPool[object] then
			local point, _, rpoint, x, y = backdropPool[object]:GetPoint()
			local scale = module.db.profile[k].Scale or 1
			x, y = RoundToSignificantDigits(x, 1), RoundToSignificantDigits(y, 1)

			if k2 then
				if module.db.profile[k][k2] then
					module.db.profile[k][k2].General.X = x

					module.db.profile[k][k2].General.Y = y
					module.db.profile[k][k2].General.Point = point
				end
			else
				module.db.profile[k].X = RoundToSignificantDigits(x * scale, 1)
				module.db.profile[k].Y = RoundToSignificantDigits(y * scale, 1)
				module.db.profile[k].Point = point
			end
			
			object:ClearAllPoints()
			object:SetPoint(point, UIParent, rpoint, x, y)
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
		local object = GetMoveObject(k, v)
		if object and module.db.profile[k] then
			if backdropPool[object] then backdropPool[object]:ClearAllPoints() end
			
			if k2 then
				if module.db.profile[k][k2] then
					object:ClearAllPoints()
					object:SetPoint(module.db.profile[k][k2].General.Point, UIParent, module.db.profile[k][k2].General.Point, module.db.profile[k][k2].General.X, module.db.profile[k][k2].General.Y)
				end
			else
				object:ClearAllPoints()
				object:SetPoint(module.db.profile[k].Point, UIParent, module.db.profile[k].Point, module.db.profile[k].X / (module.db.profile[k].Scale or 1), module.db.profile[k].Y / (module.db.profile[k].Scale or 1))
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
			if obj.LUIMoveName then return obj.LUIMoveName end
			local name = obj:GetName()
			if name then return smartString(name) end
			return obj.__unit or "<unknown>"
		end
	end
end

local hider = CreateFrame("Frame")
hider:SetScript("OnEvent", function()
	if _LOCK then
		for k, bdrop in next, backdropPool do bdrop:Hide() end
		_LOCK = nil
		
		_G.StaticPopup_Hide("DRAG_UNITFRAMES")
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
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
	end

	getBackdrop = function(obj)
		if not obj or not obj:GetCenter() then return end
		
		if math.floor(obj:GetHeight()) == 0 then obj:SetHeight(obj:GetChildren():GetHeight()) end

		if backdropPool[obj] then
			backdropPool[obj]:SetScale(obj:GetScale())
			backdropPool[obj]:SetPoint(obj:GetPoint())
			backdropPool[obj]:SetSize(obj:GetSize())
			return backdropPool[obj]
		end

		local backdrop = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
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
		name:SetFont(_G.GameFontNormal:GetFont(), 12)
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
	if _G.InCombatLockdown() and not override then
		return LUI:Print("UnitFrames cannot be moved while in combat.")
	end
	
	-- Only reveal the party header when opening move mode. The combat hider
	-- closes this dialog with override=true and must not touch protected frame
	-- visibility during lockdown.
	if not override and oUF_LUI_party then oUF_LUI_party:Show() end
	
	if (not _LOCK) and (not override) then
		hider:RegisterEvent("PLAYER_REGEN_DISABLED")
		StaticPopup_Show("DRAG_UNITFRAMES")
		
		for k, v in pairs(ufNames) do
			local object = GetMoveObject(k, v)
			if object then
				local bd = getBackdrop(object)
				if bd then bd:Show() end
			end
		end

		_LOCK = true
	else
		for k, bdrop in next, backdropPool do
			bdrop:Hide()
		end
		
		_G.StaticPopup_Hide("DRAG_UNITFRAMES")
		_LOCK = nil
		
		hider:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
end
