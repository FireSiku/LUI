-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

--Table to hold all panels frames.
local TEX_DIR = [[Interface\AddOns\LUI\media\templates\v4\]]
local OLD_DIR = [[Interface\AddOns\LUI\media\templates\v3\]]

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:CreateOrb()

	local orb = CreateFrame("Button", "LUIArtwork_Orb", UIParent)
	orb:SetFrameStrata("BACKGROUND")
	orb:SetPoint("TOP", UIParent, "TOP", 0, -8)
	orb:SetSize(55, 55)

	local fill = orb:CreateTexture(nil, "ARTWORK")
	fill:SetTexture(TEX_DIR.."orb_back.tga")
	fill:SetAllPoints(orb)

	-- First Galaxy Anim
	local galaxy1 = CreateFrame("Frame", "LUIArtwork_OrbGalaxy1", orb)
	galaxy1:SetPoint("CENTER", 0, 3)
	galaxy1:SetSize(40, 40)
	galaxy1:SetAlpha(0.9)
	
	local galaxy1Tex = galaxy1:CreateTexture(nil, "ARTWORK")
	galaxy1Tex:SetTexture(TEX_DIR.."orb_galaxy1.tga")
	galaxy1Tex:SetAllPoints(galaxy1)
	galaxy1Tex:SetBlendMode("ADD")
	
	local galaxy1anim = galaxy1:CreateAnimationGroup()
	galaxy1anim.rotation = galaxy1anim:CreateAnimation("Rotation")
	galaxy1anim.rotation:SetDegrees(360)
	galaxy1anim.rotation:SetDuration(35)
	C_Timer.NewTicker(1, function() galaxy1anim:Play() end)

	-- Second Galaxy Anim
	local galaxy2 = CreateFrame("Frame", "LUIArtwork_OrbGalaxy2", orb)
	galaxy2:SetSize(53, 53)
	galaxy2:SetPoint("CENTER", orb, "CENTER")
	galaxy2:SetAlpha(0.9)
	
	local galaxy2Tex = galaxy2:CreateTexture(nil, "ARTWORK")
	galaxy2Tex:SetTexture(TEX_DIR.."orb_galaxy2.tga")
	galaxy2Tex:SetAllPoints(galaxy2)
	galaxy2Tex:SetBlendMode("ADD")

	local galaxy2anim = galaxy2:CreateAnimationGroup()
	galaxy2anim.rotation = galaxy2anim:CreateAnimation("Rotation")
	galaxy2anim.rotation:SetDegrees(360)
	galaxy2anim.rotation:SetDuration(18)
	C_Timer.NewTicker(1, function() galaxy2anim:Play() end)

	-- "Lost" Galaxy Anim. This was part of the orb originally, but the texture went missing shortly after, back in 2011.
	-- Adding it back as an optional effect as the effect is much stronger than the others. 
	local galaxy3 = CreateFrame("Frame", "LUIArtwork_OrbGalaxy3", orb)
	galaxy3:SetSize(60, 60)
	galaxy3:SetPoint("CENTER", orb, "CENTER", 1, 1)
	galaxy3:SetAlpha(0.9)
	
	local galaxy3Tex = galaxy3:CreateTexture(nil, "ARTWORK")
	galaxy3Tex:SetTexture(TEX_DIR.."orb_galaxy_lost.tga")
	galaxy3Tex:SetAllPoints(galaxy3)
	galaxy3Tex:SetBlendMode("ADD")

	local galaxy3anim = galaxy3:CreateAnimationGroup()
	galaxy3anim.rotation = galaxy3anim:CreateAnimation("Rotation")
	galaxy3anim.rotation:SetDegrees(360)
	galaxy3anim.rotation:SetDuration(30)
	C_Timer.NewTicker(1, function() galaxy3anim:Play() end)

	-- Additional textures around the Orb
	local cycleRing = CreateFrame("Frame", "LUIArtwork_OrbCycleRing", orb, "BackdropTemplate")
	cycleRing:SetSize(115, 115)
	cycleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	cycleRing:SetFrameStrata("BACKGROUND")
	cycleRing:SetBackdrop({
		bgFile = OLD_DIR.."ring_inner4", edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
	})
	cycleRing:SetBackdropColor(0.25, 0.25, 0.25, 0.75)
	cycleRing:SetBackdropBorderColor(0, 0, 0, 0)

	local outerRing = CreateFrame("Frame", "LUIArtwork_OrbOuterRing", orb, "BackdropTemplate")
	outerRing:SetSize(103, 103)
	outerRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	outerRing:SetFrameStrata("LOW")
	outerRing:SetBackdrop({
		bgFile = OLD_DIR.."ring", edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		
	})
	outerRing:SetBackdropColor(0.25, 0.25, 0.25, 1)
	outerRing:SetBackdropBorderColor(0, 0, 0, 0)

	local middleRing = CreateFrame("Frame", "LUIArtwork_OrbMiddleRing", orb, "BackdropTemplate")
	middleRing:SetSize(115, 115)
	middleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	middleRing:SetFrameStrata("LOW")
	middleRing:SetBackdrop({
		bgFile = OLD_DIR.."ring_inner2", edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
	})
	middleRing:SetBackdropBorderColor(0, 0, 0, 0)

	local innerRing = CreateFrame("Frame", "LUIArtwork_OrbInnerRing", orb, "BackdropTemplate")
	innerRing:SetSize(77, 75)
	innerRing:SetPoint("CENTER", orb, "CENTER", 1, -1)
	innerRing:SetFrameStrata("LOW")
	innerRing:SetBackdrop({
		bgFile = OLD_DIR.."ring", edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
	})
	innerRing:SetBackdropBorderColor(0, 0, 0, 0)
	innerRing:SetFrameLevel(middleRing:GetFrameLevel() + 1)

	module.Orb = orb
	orb.Back = fill
	orb.Galaxy1 = galaxy1Tex
	orb.Galaxy2 = galaxy2Tex
	orb.Galaxy3 = galaxy3Tex
	orb.LostGalaxy = galaxy3
	orb.Cycle = cycleRing

	module:RefreshOrb()
end

function module:SetOrbRingColor(r, g, b)
	module.Orb.Cycle:SetBackdropColor(r, g, b, 0.75)
end

function module:RefreshOrb()
	local db = self.db.profile.LUITextures.NavBar
	local orb = module.Orb
	
	if not db.ShowOrb then
		orb:Hide()
		return
	else
		orb:Show()
	end

	local r, g, b = LUI:GetClassColor("MAGE")
	orb.Back:SetVertexColor(r, g, b, 1)
	orb.Galaxy1:SetVertexColor(r, g, b, 1)
	orb.Galaxy2:SetVertexColor(r, g, b, 1)
	orb.Galaxy3:SetVertexColor(r, g, b, 1)
	--orb.Cycle:SetBackdropColor(unpack(db.orb_cycle))

	if db.LostGalaxy then
		orb.LostGalaxy:Show()
	else
		orb.LostGalaxy:Hide()
	end
end
