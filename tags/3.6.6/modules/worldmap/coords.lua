--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: coords.lua
	Description: WorldMap Coordinates Module
]]

-- External references.
local addonname, LUI = ...
local WorldMap = LUI:Module("WorldMap")
local module = WorldMap:Module("Coords")

local L = LUI.L
local db, dbd

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local cursor, player = L["Cursor"], L["Player"]

local coordstemplate = "%%s: %%.%df, %%.%df"
local coordsformat

local coords

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function getMouse()
	local left, top = WorldMapDetailFrame:GetLeft(), WorldMapDetailFrame:GetTop()
	local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()
	local scale = WorldMapDetailFrame:GetEffectiveScale()

	local x, y = GetCursorPosition()
	local cx = (x/scale - left) / width
	local cy = (top - y/scale) / height

	if cx < 0 or cx > 1 or cy < 0 or cy > 1 then
		return
	end

	return cx, cy
end

local function coords_OnUpdate(self, elapsed)
	local cx, cy = getMouse()
	local px, py = GetPlayerMapPosition("player")
	
	if cx then
		self.cursor:SetFormattedText(coordsformat, cursor, 100 * cx, 100 * cy)
	else
		self.cursor:SetText()
	end
	
	if px == 0 then
		self.player:SetText()
	else
		self.player:SetFormattedText(coordsformat, player, px * 100, py * 100)
	end
end

--------------------------------------------------
-- Coords Functions
--------------------------------------------------

function module:SetCoords()
	if not coords then
		coords = CreateFrame("Frame", "LUI_WorldMap_Coordinates", WorldMapFrame)
		
		coords.cursor = coords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		coords.player = coords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		
		coords:SetScript("OnUpdate", coords_OnUpdate)
		
		WorldMapFrame.coords = coords
		WorldMap.elementsToHide.Coords = coords
	end
	
	if WorldMap.db.char.miniMap then
		coords.cursor:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 25, -2)
		coords.player:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", 10, -2)
	else
		coords.cursor:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 50, 10)
		coords.player:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", -50, 10)
	end
	
	coords:Show()
	
	WorldMap:UpdateMapElements(true)
end

--------------------------------------------------
-- Module Functions
--------------------------------------------------

module.defaults = {
	profile = {
		Enable = true,
		Accuracy = 1,
	},
}

function module:LoadOptions()
	local function coordsDisabled()
		return not self:IsEnabled()
	end
	
	local options = self:NewGroup("Coordinates", 4, "generic", "Refresh", {
		Enable = self:NewToggle("Enable", nil, 1, true, "normal"),
		Accuracy = self:NewSlider("Accuracy", "Adjust the number of decimal places the coordinates are accurate to.", 2, 0, 2, 1, true, false, nil, coordsDisabled),
	})
	
	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		if info[#info] == "Enable" then
			return self:Toggle()
		end
		
		self:SetDBVar(info, value)
	end
	
	coordsformat = coordstemplate:format(db.Accuracy, db.Accuracy)
	
	self:SetCoords()
end

function module:OnInitialize()
	db, dbd = WorldMap:Namespace(self)
end

module.DBCallback = module.OnInitialize

module.OnEnable = module.Refresh

function module:OnDisable()
	WorldMap.elementsToHide.Coords = nil
	coords:Hide()
end