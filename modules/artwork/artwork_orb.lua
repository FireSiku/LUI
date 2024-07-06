-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")
local db

--Table to hold all panels frames.
local TEX_DIR = [[Interface\AddOns\LUI\media\templates\v4\]]
local OLD_DIR = [[Interface\AddOns\LUI\media\templates\v3\]]

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:CreateOrb()
	db = self.db.profile
	local r, g, b = LUI:GetClassColor("MAGE")
	
	local orb = CreateFrame("Button", "LUIArtwork_Orb", UIParent)
	orb:SetFrameStrata("BACKGROUND")
	orb:SetSize(55, 55)
	orb:SetPoint("TOP", 0, -100)

	local fill = orb:CreateTexture(nil, "ARTWORK")
	fill:SetTexture(TEX_DIR.."orb_back.tga")
	fill:SetAllPoints(orb)
	fill:SetVertexColor(r, g, b, 1)

	--local galaxy1 = self:CreateGalaxy(orb, 0, 13, 40, 0.9, 35, "galaxy2")
	local galaxy1 = CreateFrame("Frame", "", orb)
	galaxy1:SetSize(40, 40)
	galaxy1:SetPoint("CENTER", 0, 3)
	galaxy1:SetAlpha(0.9)
	
	local galaxy1Tex = galaxy1:CreateTexture(nil, "ARTWORK")
	galaxy1Tex:SetTexture(TEX_DIR.."orb_galaxy1.tga")
	galaxy1Tex:SetAllPoints(galaxy1)
	galaxy1Tex:SetBlendMode("ADD")
	galaxy1Tex:SetVertexColor(r, g, b, 1)

	local galaxy1anim = galaxy1:CreateAnimationGroup()
	galaxy1anim.rotation = galaxy1anim:CreateAnimation("Rotation")
	galaxy1anim.rotation:SetDegrees(360)
	galaxy1anim.rotation:SetDuration(35)
	C_Timer.NewTicker(1, function() galaxy1anim:Play() end)

	--LUI.Orb.Galaxy3 = CreateMeAGalaxy(LUI.Orb, -5, 10, 53, 0.9, 18, "galaxy3", orb[1], orb[2], orb[3])
	local galaxy2 = CreateFrame("Frame", "", orb)
	galaxy2:SetSize(53, 53)
	galaxy2:SetPoint("CENTER", orb, "CENTER")
	galaxy2:SetAlpha(0.9)
	
	local galaxy2Tex = galaxy2:CreateTexture(nil, "ARTWORK")
	galaxy2Tex:SetTexture(TEX_DIR.."orb_galaxy2.tga")
	galaxy2Tex:SetAllPoints(galaxy2)
	galaxy2Tex:SetBlendMode("ADD")
	galaxy2Tex:SetVertexColor(r, g, b, 1)

	local galaxy2anim = galaxy2:CreateAnimationGroup()
	galaxy2anim.rotation = galaxy2anim:CreateAnimation("Rotation")
	galaxy2anim.rotation:SetDegrees(360)
	galaxy2anim.rotation:SetDuration(18)
	C_Timer.NewTicker(1, function() galaxy2anim:Play() end)

	module.Orb = orb
	orb.Back = fill
	orb.Galaxy1 = galaxy1Tex
	orb.Galaxy2 = galaxy2Tex

	local cycleRing = CreateFrame("Frame", "LUIOrbCycleRing", orb, "BackdropTemplate")
	cycleRing:SetSize(115, 115)
	cycleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	cycleRing:SetFrameStrata("BACKGROUND")
	cycleRing:SetBackdrop({
		bgFile = OLD_DIR.."ring_inner4",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	cycleRing:SetBackdropColor(0.25, 0.25, 0.25, 0.5)
	cycleRing:SetBackdropBorderColor(0, 0, 0, 0)

	local outerRing = CreateFrame("Frame", "LUIOrbOuterRing", orb, "BackdropTemplate")
	outerRing:SetSize(103, 103)
	outerRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	outerRing:SetFrameStrata("LOW")
	outerRing:SetBackdrop({
		bgFile = OLD_DIR.."ring",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	outerRing:SetBackdropColor(0.25, 0.25, 0.25, 1)
	outerRing:SetBackdropBorderColor(0, 0, 0, 0)

	local middleRing = CreateFrame("Frame", "LUIOrbMiddleRing", orb, "BackdropTemplate")
	middleRing:SetSize(115, 115)
	middleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	middleRing:SetFrameStrata("LOW")
	middleRing:SetBackdrop({
		bgFile = OLD_DIR.."ring_inner2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	middleRing:SetBackdropBorderColor(0, 0, 0, 0)

	--LUI.Orb.Ring7 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 77, 75, 1, "LOW", 3, "CENTER", LUI.Orb, "CENTER", 1, -1, 1)
	local innerRing = CreateFrame("Frame", "LUIOrbInnerRing", orb, "BackdropTemplate")
	innerRing:SetSize(77, 75)
	innerRing:SetPoint("CENTER", orb, "CENTER", 1, -1)
	innerRing:SetFrameStrata("LOW")
	innerRing:SetBackdrop({
		bgFile = OLD_DIR.."ring",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	innerRing:SetBackdropBorderColor(0, 0, 0, 0)
	innerRing:SetFrameLevel(middleRing:GetFrameLevel() + 1)
end

-- ####################################################################################################################
-- ##### Snippets of Old Code #############################################################################################
-- ####################################################################################################################
--[[ 
	local MainAnchor = LUI:CreateMeAFrame("Frame", nil, UIParent, 100, 100, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, 15, 1)

	LUI.Orb.LostGalaxy = CreateMeAGalaxy(LUI.Orb, 0, 10, 65, 0, 45, "galaxy", orb[1], orb[2], orb[3])

	local function SetFrameBackdrop(frame, fileName)
		frame.Backdrop = {
			bgFile = directory..fileName, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0} }
		frame:SetBackdrop(frame.Backdrop)
		frame:SetBackdropBorderColor(0,0,0,0)
	end

	LUI.Orb.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 68, 68, 1, "LOW", 0, "CENTER", LUI.Orb, "CENTER", 1, 0, 0)
	SetFrameBackdrop(LUI.Orb.Hover, "ring_inner")
	LUI.Orb.Hover:SetBackdropColor(unpack(orb_hover))
	LUI.Orb.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Orb.Hover:Show()

	function module:SetOrbColors()
	local orb = ThemesDB.orb
	local r, g, b, a = unpack(orb)
	LUI.Orb.Fill:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy1.t:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy2.t:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy3.t:SetVertexColor(r, g, b, a)
end

function module:SetOrbCycleColor()
	LUI.Orb.Cycle:SetBackdropColor(unpack(ThemesDB.orb_cycle))
end

function module:SetOrbHoverColor()
	LUI.Orb.Hover:SetBackdropColor(unpack(ThemesDB.orb_hover))
end
--]]
