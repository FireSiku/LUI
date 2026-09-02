--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class oUF
local oUF = LUI.oUF

local function FormatName(self)
	if not self or not self.Info then return end

	local info = self.Info
	local name = "[name]"

	if info.ColorNameByClass then name = "[raidcolor]"..name.."|r" end

	local level = info.ColorLevelByDifficulty and "[difficulty][level]|r" or "[level]"

	if info.ShowClassification then
		level = info.ShortClassification and level.."[shortclassification]" or level.."[classification]"
	end

	local race = "[race]"

	local class = info.ColorClassByClass and "[raidcolor][smartclass]|r" or "[smartclass]"

	self:Tag(info, info.Format:gsub(" %+ ", " "):gsub("Name", name):gsub("Level", level):gsub("Race", race):gsub("Class", class))
	self:UpdateAllElements('refreshUnit')
end
oUF:RegisterMetaFunction("FormatName", FormatName)

local function FormatRaidName(self)
	if not self or not self.Info then return end

	local info = self.Info
	local tag = "[name]"

	if info.ColorNameByClass then tag = "[raidcolor]"..tag.."|r" end

	self:Tag(info, tag)
	self:UpdateAllElements('refreshUnit')
end
oUF:RegisterMetaFunction("FormatRaidName", FormatRaidName)
