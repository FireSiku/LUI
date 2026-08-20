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

	local name
	if info.Length == "Long" then
		name = "[NameLong]"
	elseif info.Length == "Short" then
		name = "[NameShort]"
	else
		name = "[NameMedium]"
	end

	if info.ColorNameByClass then name = "[GetNameColor]"..name.."|r" end

	local level = info.ColorLevelByDifficulty and "[DiffColor][level]|r" or "[level]"

	if info.ShowClassification then
		level = info.ShortClassification and level.."[shortclassification]" or level.."[classification]"
	end

	local race = "[race]"

	local class = info.ColorClassByClass and "[GetNameColor][smartclass]|r" or "[smartclass]"

	self:Tag(info, info.Format:gsub(" %+ ", " "):gsub("Name", name):gsub("Level", level):gsub("Race", race):gsub("Class", class))
	self:UpdateAllElements('refreshUnit')
end
oUF:RegisterMetaFunction("FormatName", FormatName)

local function FormatRaidName(self)
	if not self or not self.Info then return end

	local info = self.Info
	local parent = self:GetParent()
	local grandParent = parent and parent:GetParent()
	local groupName = grandParent and grandParent:GetName()

	-- Normal raid frames are children of the 25/40-player raid headers. Preview
	-- frames are spawned as standalone frames, so they intentionally have no
	-- raid-header grandparent and use the 25-player name format.
	local tag = groupName == "oUF_LUI_raid_40" and "[RaidName40]" or "[RaidName25]"

	if info.ColorByClass then tag = "[GetNameColor]"..tag.."|r" end

	self:Tag(info, tag)
	self:UpdateAllElements('refreshUnit')
end
oUF:RegisterMetaFunction("FormatRaidName", FormatRaidName)
