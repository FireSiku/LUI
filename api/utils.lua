--- Core API only contains generic API methods found in LUI object.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

local type, pairs = type, pairs
local strmatch, tostring = strmatch, tostring
local tinsert, tremove = tinsert, tremove
local math, min, max = math, math.min, math.max
local GetFunctionCPUUsage = _G.GetFunctionCPUUsage
local GetCVar = _G.GetCVar

-- Constants
local MAX_AVG_ENTRIES = 10000
local MS_PER_SECOND = 1000

-- ####################################################################################################################
-- ##### TexCoord Atlas API ###########################################################################################
-- ####################################################################################################################

-- Instead of having TexCoords Constants peppered amongst various files, keep them all centralized in here
-- TexCoords are calculated such as 2/64 means 2 pixels to the left of a 64px file.
local gTexCoordAtlas = {
	MicroBtn_Default =     { 125/256, 159/256, 2/32, 30/32 },
	MicroBtn_First 	 =     {   1/256,  47/256, 2/32, 30/32 },
	MicroBtn_Last 	 =     {  62/256, 111/256, 2/32, 30/32 },
	MicroBtn_Icon	 =     {    0/32,   32/32, 0/32, 32/32 },
	CleanUp =              {    4/28,   24/28, 3/26, 22/26 },
	sidebar_base =         { 195/256, 252/256,  78/512, 443/512,},
	sidebar_drawer =       { 113/256, 213/256, 136/512, 383/512, },
	sidebar_button =       { 104/256, 124/256, 138/512, 381/512, },
	sidebar_button_hover = { 103/256, 125/256, 137/512, 382/512, },
	nav_button_left2 =     {  23/128,  97/128, 103/128, 128/128 },		-- 74, 25
	nav_button_right2 =    {  29/128, 102/128, 101/128, 126/128 },		-- 74, 25
	nav_button_left1 =     {    1/64,   61/64, 37/64, 61/64 },			-- 60, 24
	nav_button_right1 =    {    3/64,   63/64, 40/64, 64/64 },			-- 60, 24
	left_border =          { 20/1024,  595/1024, 231/512, 492/512 },
	left_border_back =     { 20/1024,  595/1024, 231/512, 492/512 },

}

--- Returns TexCoords based on the given string that matches the table above
function LUI:GetCoordAtlas(atlas)
	local t = gTexCoordAtlas[atlas]
	if not t then
		error("LUI:GetCoordAtlas(atlas): "..atlas.." not found.")
	end
	return t[1], t[2], t[3], t[4]
end

-- ####################################################################################################################
-- ##### LibWindow Wrapper ############################################################################################
-- ####################################################################################################################
-- Wrapper around LibWindow for sake of implementation

local LibWin = LibStub("LibWindow-1.1")

-- This call initializes a frame for use with LibWindow, and tells it where configuration data lives.
-- Note: Since LUI supports profiles, it is needed to do a new .RegisterConfig and .RestorePosition to every frame
--       that is being affected in the :Refresh call.
-- TODO: Implement a way to remember what frames have been affected, and automatically handle this.
function LUI:RegisterConfig(frame, storage, names)
	if not names then
		--By default, the names need to be lower case, but all of LUI's db options are using PascalCase.
		names = {
			x = "X", y = "Y",
			point = "Point",
			scale = "Scale",
		}
	end
	LibWin.RegisterConfig(frame, storage, names)
end

-- This computes which quadrant the frame lives in, and saves its position relative to the right corner.
-- Usage: frame:SetScript("OnDragStop", LUI.SavePosition)
-- No need to call this yourself if you used :MakeDraggable on the frame.
function LUI:SavePosition(frame)
	LibWin.SavePosition(frame)
end

-- Restore frame and scale from config data
function LUI:RestorePosition(frame)
	LibWin.RestorePosition(frame)
end

-- Sets the scale of the frame without causing it to move and saves it.
function LUI:SetScale(frame, scale)
	LibWin.SetScale(frame, scale)
end

-- Adds drag handlers to the frame and makes it movable.
-- Positioning information is automatically stored according to :RegisterConfig().
function LUI:MakeDraggable(frame)
	LibWin.MakeDraggable(frame)
end

--Other functions LibWindow has that arent implemented because I dont believe will be used:
--LibWin.EnableMouseOnAlt
--LibWin.EnableMouseWheelScaling

-- ####################################################################################################################
-- ##### Generic Utility API ##########################################################################################
-- ####################################################################################################################
-- Clean up: It's very likely Blizzard already implemented some of these utilities.

--- Count the number of entries in a table. This is done because #Table only returns array.
---@param t table Table to Count
---@param isPrint? boolean If provided, the count will be printed.
---@return integer
function LUI:Count(t, isPrint)
	local count = 0
	if type(t) == "table" then
		for _ in pairs(t) do count = count + 1 end
	end

	if isPrint then LUI:Print(count) end
	return count
end

--Give us a sorted table to work with, fill the array with the keys, then sort based on the values in original table
--then we can just use a for loop to get a sorted result and call original[ sorted[i] ] for the value
--Went with a return-less approach that you need to provide the sort table because otherwise,
--I would need to create a new table every single call, and that would create needless garbage.\

--- Returns a sorted table to work it by filling the array portion of `sortT` with the keys of `origT`, then sorting the results.  
--- Then we can just use a loop to get the sorted results with original[ sorted[i] ] for the value.
---@param sortT table Table that will be wiped to contain the sorting order.
---@param origT table Original dictionary table that contains list of keys to be sorted.
---@param sortFunc function The sorting function to be used.
function LUI:SortTable(sortT, origT, sortFunc)
	wipe(sortT)
	for k in pairs(origT) do sortT[#sortT+1] = k end
	table.sort(sortT, sortFunc)
end

--Copy a table recursively.

--- Copy a table recursively
---@param source table
---@param target table
---@return table
function LUI:CopyTable(source, target)
	if type(target) ~= "table" then target = {} end
	for k, v in pairs(source) do
		if type(v) == "table" then
			target[k] = LUI:CopyTable(v, target[k])
		elseif not target[k] then
			target[k] = v
		end
	end
	return target
end

--- Print a table to the chat frame

--- Print a table to the chat frame
---@param tbl table
function LUI:PrintTable(tbl)
	if type(tbl) ~= "table" then return LUI:Print("Tried to Print a nil table.") end
	LUI:Print("-------------------------")
	for k, v in pairs(tbl) do
		LUI:Print(k,v)
	end
	LUI:Print("-------------------------")
end

--takes table, second arg for recursion. Prints an entire table to default chat.

--- Print a table recursively, with indentation
---@param tbl table
---@param msg string Used by recursion
---@param recurse string Used by recursion
---@overload fun(tbl: table)
function LUI:PrintFullTable(tbl, msg, recurse)
	if type(tbl) ~= "table" then return LUI:Print("Tried to Print a nil table.") end
	if not recurse then LUI:Print("-------------------------") end
	msg = msg or ""
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			LUI:Print(msg,k,v)
			LUI:PrintFullTable(v,msg.."-- ", true)
		else LUI:Print(msg,k,v) end
	end
	if not recurse then LUI:Print("-------------------------") end
end

--- Print a table recursively, with indentation
---@param tbl table
---@param msg string Used by recursion
---@param recurse string Used by recursion
---@overload fun(tbl: table)
function LUI:PrintObjectTree(tbl, msg, recurse)
	if type(tbl) ~= "table" then return LUI:Print("Tried to Print a nil table.") end
	if not recurse then LUI:Print("-------------------------") end
	msg = msg or ""
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			LUI:Print(msg, k, type(v), v.GetObjectType and v:GetObjectType())
			LUI:PrintFullTable(v, msg.."-- ", true)
		else LUI:Print(msg,k,type(v), v) end
	end
	if not recurse then LUI:Print("-------------------------") end
end

-- ####################################################################################################################
-- ##### Dev Functions ################################################################################################
-- ####################################################################################################################

--- Function to add a bright border around a given frame to help seeing it and its size.
---@param frame Frame
function LUI:HighlightBorder(frame)
	local glowBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\AddOns\\LUI\\media\\borders\\glow.tga",
		--tile=0, tileSize=0,
		edgeSize=5,
		insets={left=3, right=3, top=3, bottom=3}
	}
	frame:SetBackdrop(glowBackdrop)
	frame:SetBackdropColor(0,0,0,0)
	frame:SetBackdropBorderColor(1,1,0,1)
end

-- ####################################################################################################################
-- ##### Scaling Functions ############################################################################################
-- ####################################################################################################################
-- UI Scale is normalized to a height of 768px regardless of actual screen resolution.
-- As a result of how WoW handles UI coordinates, having an improperly set UI scale may result in various glitches with interface addons.
-- For instance, a one pixel wide border on a frame may have a varying width depending on the frame's position and size.
-- To rectify this behaviour, you should set your UI scale so that your screen height matches with the UI coordinates.

local mult = 1

--- Updates the scale factor for Scaling calculations. Only needs to be called at login or when resolution changes.
function LUI:UpdateScaleMultiplier()
	local screenHeight = string.match(GetCVar("gxWindowedResolution"), "%d+x(%d+)")
	local uiScale = UIParent:GetScale()
	mult = 768 / screenHeight / uiScale
end

--- Return a normalized value for pixel-perfect textures.
---@param x number
---@return number
function LUI.V4Scale(x)
	return mult * floor(x / mult + 0.5)
end

LUI:RegisterEvent("UI_SCALE_CHANGED", "UpdateScaleMultiplier")
