-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

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
	galaxy1anim:SetLooping("REPEAT")
	galaxy1anim:Play()

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
	galaxy2anim:SetLooping("REPEAT")
	galaxy2anim:Play()

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
	galaxy3anim:SetLooping("REPEAT")
	galaxy3anim:Play()

	-- Additional textures around the Orb
	local cycleRing = CreateFrame("Frame", "LUIArtwork_OrbCycleRing", orb)
	cycleRing:SetSize(115, 115)
	cycleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	cycleRing:SetFrameStrata("BACKGROUND")
	local cycleRingTexture = LUI:CreateFrameTexture(cycleRing, OLD_DIR.."ring_inner4")
	cycleRingTexture:SetVertexColor(0.25, 0.25, 0.25, 0.75)

	-- Clicker
	local orbClicker = CreateFrame("Button", "LUIArtwork_OrbClicker", orb, "SecureHandlerClickTemplate")
	orbClicker:SetSize(115, 115)
	orbClicker:SetPoint("CENTER", orb, "CENTER", 0, -1)
	orbClicker:SetFrameStrata("BACKGROUND")
	
	local tex = orbClicker:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("CENTER", orb, "CENTER", 0, -1)
	tex:SetTexture(OLD_DIR.."ring_inner4")

	-- Animations, taken from navbar
	local ANIM_DURATION = 0.5
	local ALPHA = 0.75
	local alphaIn = tex:CreateAnimationGroup()
	local a1 = alphaIn:CreateAnimation("Alpha")
	a1:SetFromAlpha(0)
	a1:SetToAlpha(ALPHA)
	a1:SetDuration(ANIM_DURATION)
	alphaIn:SetScript("OnFinished", function() tex:SetAlpha(ALPHA) end)

	local alphaOut = tex:CreateAnimationGroup()
	local a2 = alphaOut:CreateAnimation("Alpha")
	a2:SetFromAlpha(ALPHA)
	a2:SetToAlpha(0)
	a2:SetDuration(ANIM_DURATION)
	alphaOut:SetScript("OnFinished", function() tex:SetAlpha(0) end)

	local locked = false -- To prevent rapid clicking issues
	orbClicker:RegisterForClicks("AnyUp")
	orbClicker:SetScript("OnClick", function()
		if locked then return end
		local forceShow = false
		if tex:GetAlpha() == 0 then
			locked = true
			alphaIn:Play()
			forceShow = true
		elseif math.floor(tex:GetAlpha()*100+0.5) == ALPHA*100 then
			locked = true
			alphaOut:Play()
		end
		locked = false
		for kind, button in module:IterateNavButtons() do
			local db = module.db.profile.LUITextures[kind]
			local frame = _G[db.Anchor]
			if forceShow and frame and not frame:IsShown() then
				if kind == "Chat" and not (button.tex.alphaOut:IsPlaying() or button.tex.alphaIn:IsPlaying()) then
					module:SetChatVisible(true)
				end
				button.tex.alphaIn:Play()
				module:AlphaIn(kind, button)
				db.IsShown = true
			elseif not forceShow and frame and frame:IsShown() then
				if kind == "Chat" and not (button.tex.alphaOut:IsPlaying() or button.tex.alphaIn:IsPlaying()) then
					module:SetChatVisible(false)
				end
				button.tex.alphaOut:Play()
				module:AlphaOut(kind, button)
				db.IsShown = false
			end
		end
		
	end)
	SecureHandlerWrapScript(orbClicker, "PostClick", orbClicker, [[
		if not PlayerInCombat() then return end
		local show = not self:GetAttribute("panelsOpen")
		self:SetAttribute("panelsOpen", show)
		local count = self:GetAttribute("protectedCount") or 0
		for i = 1, count do
			local frame = self:GetFrameRef("protected"..i)
			if frame then
				if show then frame:Show() else frame:Hide() end
			end
		end
	]])

	-- Additional textures around the Orb
	local outerRing = CreateFrame("Frame", "LUIArtwork_OrbOuterRing", orb)
	outerRing:SetSize(103, 103)
	outerRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	outerRing:SetFrameStrata("LOW")
	LUI:CreateFrameTexture(outerRing, OLD_DIR.."ring"):SetVertexColor(0.25, 0.25, 0.25, 1)

	local middleRing = CreateFrame("Frame", "LUIArtwork_OrbMiddleRing", orb)
	middleRing:SetSize(115, 115)
	middleRing:SetPoint("CENTER", orb, "CENTER", 0, -1)
	middleRing:SetFrameStrata("LOW")
	LUI:CreateFrameTexture(middleRing, OLD_DIR.."ring_inner2")

	local innerRing = CreateFrame("Frame", "LUIArtwork_OrbInnerRing", orb)
	innerRing:SetSize(77, 75)
	innerRing:SetPoint("CENTER", orb, "CENTER", 1, -1)
	innerRing:SetFrameStrata("LOW")
	LUI:CreateFrameTexture(innerRing, OLD_DIR.."ring")
	innerRing:SetFrameLevel(middleRing:GetFrameLevel() + 1)

	module.Orb = orb
	orb.Back = fill
	orb.Galaxy1 = galaxy1Tex
	orb.Galaxy2 = galaxy2Tex
	orb.Galaxy3 = galaxy3Tex
	orb.LostGalaxy = galaxy3
	orb.Cycle = cycleRingTexture
	orb.Clicker = orbClicker
	orb.ClickerTex = tex

	module:RefreshOrb()
end

function module:SyncOrbState()
	if not module.Orb then return end
	local anyShown = false
	for kind in module:IterateNavButtons() do
		if module.db.profile.LUITextures[kind].IsShown then
			anyShown = true
			break
		end
	end
	module.Orb.ClickerTex:SetAlpha(anyShown and 0.75 or 0)
	if not InCombatLockdown() then
		module.Orb.Clicker:SetAttribute("panelsOpen", anyShown)
	end
end

function module:SetOrbRingColor(r, g, b)
	module.Orb.Cycle:SetVertexColor(r, g, b, 0.75)
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

	local r, g, b = self:RGBA("Orb")
	orb.Back:SetVertexColor(r, g, b, 1)
	orb.Galaxy1:SetVertexColor(r, g, b, 1)
	orb.Galaxy2:SetVertexColor(r, g, b, 1)
	orb.Galaxy3:SetVertexColor(r, g, b, 1)
	orb.ClickerTex:SetVertexColor(r, g, b, 0.75)
	if db.LostGalaxy then
		orb.LostGalaxy:Show()
	else
		orb.LostGalaxy:Hide()
	end
end
