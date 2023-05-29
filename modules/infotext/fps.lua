-- FPS/Latency Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("FPS")

-- Local copies
local floor, format = floor, format
local GetFramerate = _G.GetFramerate
local GetNetStats = _G.GetNetStats

-- Constants
local MILLISECONDS_ABBR = _G.MILLISECONDS_ABBR
local FRAMERATE_LABEL = _G.FRAMERATE_LABEL
local FPS_ABBR = _G.FPS_ABBR

local GRADIENT_LAG_TOLERANCE = 600 -- Bad at 600, Medium at 300
local DEFAULT_REFRESH_RATE = 60
local FPS_UPDATE_TIME = 1
local KB_PER_MB = 1024

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

element.defaults = {
	profile = {
		X = 450,
	},
}
module:MergeDefaults(element.defaults, "FPS")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function formatBandwidth(bandwidth)
	if bandwidth > KB_PER_MB then
		return format(L["InfoFps_MB_Format"], bandwidth / KB_PER_MB)
	else
		return format(L["InfoFps_KB_Format"], bandwidth)
	end
end

function element:UpdateFPSLatency()
	local _, _, lagHome, lagWorld = GetNetStats()
	element.text = format("%d%s   %d%s | %d%s", floor(GetFramerate()), FPS_ABBR,
	                                            lagHome, MILLISECONDS_ABBR, lagWorld, MILLISECONDS_ABBR)
	element:UpdateTooltip()
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoFps_Header"])

	-- FPS
	local fps = floor(GetFramerate())
	local r, g, b = LUI:RGBGradient(fps / DEFAULT_REFRESH_RATE)
	GameTooltip:AddLine(FRAMERATE_LABEL)
	GameTooltip:AddDoubleLine(L["InfoFps_Current"], fps, 1,1,1, r, g, b)
	GameTooltip:AddLine(" ")

	-- Bandwidth / Latency
	local down, up, lagHome, lagWorld = GetNetStats()
	local r1, g1, b1 = LUI:InverseGradient(lagHome / GRADIENT_LAG_TOLERANCE)
	local r2, g2, b2 = LUI:InverseGradient(lagWorld / GRADIENT_LAG_TOLERANCE)
	GameTooltip:AddLine(L["InfoFps_Latency"])
	GameTooltip:AddDoubleLine(L["InfoFps_Home"], lagHome..MILLISECONDS_ABBR, 1,1,1, r1, g1, b1)
	GameTooltip:AddDoubleLine(L["InfoFps_World"], lagWorld..MILLISECONDS_ABBR, 1,1,1, r2, g2, b2)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["InfoFps_Bandwidth"])
	GameTooltip:AddDoubleLine(L["InfoFps_CurrentDown"], formatBandwidth(down), 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine(L["InfoFps_CurrentUp"], formatBandwidth(up), 1,1,1, 1,1,1)
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:AddUpdate("UpdateFPSLatency", FPS_UPDATE_TIME)
end
