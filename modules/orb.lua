--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: orb.lua
	Description: Orb Module
	Version....: 1.0
	Rev Date...: 10/10/2010
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Orb", "AceHook-3.0")

local db

function module:CreateMeAnOrbFrame(fart,fname,fparent,fstrata,flevel,fwidth,fheight,fanchor,fxpos,fypos,fscale,fdrag,finherit)
	local f = CreateFrame(fart,fname,fparent,finherit)
	f:SetFrameStrata(fstrata)
	f:SetFrameLevel(flevel)
	f:SetWidth(fwidth)
	f:SetHeight(fheight)
	f:SetPoint(fanchor,fxpos,fypos)
	f:SetScale(fscale)
	return f 
end 
  
function module:CreateMeATexture(fhooked,tstrata,tfile,tspecial)
	local t = fhooked:CreateTexture(nil,tstrata)
	t:SetTexture(tfile)
	if tspecial == "fill" then
		t:SetPoint("BOTTOM",fhooked,"BOTTOM",0,0)
		t:SetWidth(fhooked:GetWidth())
		t:SetHeight(fhooked:GetHeight())
	else
		t:SetAllPoints(fhooked)
	end
	return t
end 

function module:CreateMeAGalaxy(f,x,y,size,alpha,dur,tex,useorb)
	local h = CreateFrame("Frame",nil,f)
	h:SetHeight(size)
	h:SetWidth(size)
	h:SetPoint("CENTER",x,y-10)
	h:SetAlpha(alpha)
	h:SetFrameLevel(5)

	local t = h:CreateTexture()
	t:SetAllPoints(h)
	t:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\orb\\"..tex)
	t:SetBlendMode("ADD")
	t:SetVertexColor(galaxytab[useorb].r,galaxytab[useorb].g,galaxytab[useorb].b)
	h.t = t

	local ag = h:CreateAnimationGroup()
	h.ag = ag
	
	local a1 = h.ag:CreateAnimation("Rotation")
	a1:SetDegrees(360)
	a1:SetDuration(dur)
	h.ag.a1 = a1

	h:SetScript("OnUpdate",function(self,elapsed)
		local t = self.total
		if (not t) then
			self.total = 0
			return
		end
		t = t + elapsed
		if (t<1) then
			self.total = t
			return
		else
			h.ag:Play()
		end
	end)
	
	return h
end

function module:CreateMeAnOrb(orbname,orbsize,orbanchorframe,orbpoint,orbposx,orbposy,orbscale,orbfilltex,useorb)
	local default_locked = 1
	local usegalaxy = 1
	local frame_to_scale
	
	local hglow1, hglow2, mglow1, mglow2, hfill, mfill
	local hgal1,hgal2,hgal3,mgal1,mgal2,mgal3
	local fog_smoother = 1.3
	
	local orb_r = db.Colors.orb[1]
	local orb_g = db.Colors.orb[2]
	local orb_b = db.Colors.orb[3]

	orbtab = {
		[0] = {r = orb_r, g = orb_g, b = orb_b, scale = 0.9, z = -12, x = -0.5, y = -0.8, anim = "SPELLS\WhiteRadiationFog.m2"},
		[1] = {r = 0.8, g = 0, b = 0, scale = 0.8, z = -12, x = 0.8, y = -1.7, anim = "SPELLS\\RedRadiationFog.m2"}, -- red
		[2] = {r = 0.2, g = 0.8, b = 0, scale = 0.75, z = -12, x = 0, y = -1.1, anim = "SPELLS\\GreenRadiationFog.m2"}, -- green
		[3] = {r = 0, g = 0.35,   b = 0.9, scale = 0.75, z = -12, x = 1.2, y = -1, anim = "SPELLS\\BlueRadiationFog.m2"}, -- blue
		[4] = {r = 0.9, g = 0.7, b = 0.1, scale = 0.75, z = -12, x = -0.3, y = -1.2, anim = "SPELLS\\OrangeRadiationFog.m2"}, -- yellow
		[5] = {r = 0.1, g = 0.8,   b = 0.7, scale = 0.9, z = -12, x = -0.5, y = -0.8, anim = "SPELLS\\WhiteRadiationFog.m2"}, -- runic
	}
	
	galaxytab = {
		[0] = {r = orb_r, g = orb_g, b = orb_b, },
		[1] = {r = 0.90, g = 0.1, b = 0.1, }, -- red
		[2] = {r = 0.25, g = 0.9, b = 0.25, }, -- green
		[3] = {r = 0, g = 0.35,   b = 0.9, }, -- blue
		[4] = {r = 0.9, g = 0.8, b = 0.35, }, -- yellow
		[5] = {r = 0.35, g = 0.9,   b = 0.9, }, -- runic
	}

	local orb1 = self:CreateMeAnOrbFrame("Button",orbname,orbanchorframe,"BACKGROUND",4,orbsize,orbsize,orbpoint,orbposx,orbposy,orbscale,nil)

	orb1:SetScript("OnEnter", function(self)
		OrbAlphaIn:Show()
	end)
	
	orb1:SetScript("OnLeave", function(self)
		OrbAlphaOut:Show()
	end)

	local orb1_fill = self:CreateMeATexture(orb1,"ARTWORK","Interface\\AddOns\\LUI\\media\\textures\\orb\\"..orbfilltex,"fill")
	orb1_fill:SetVertexColor(orbtab[useorb].r,orbtab[useorb].g,orbtab[useorb].b)
	LUI_OrbFill = orb1_fill
	LUI_OrbGalaxy1 = self:CreateMeAGalaxy(orb1,0,13,40,0.9,35,"galaxy2",useorb)
	LUI_OrbGalaxy2 = self:CreateMeAGalaxy(orb1,0,10,65,0.9,45,"galaxy",useorb)
	LUI_OrbGalaxy3 = self:CreateMeAGalaxy(orb1,-5,10,53,0.9,18,"galaxy3",useorb)
end

function module:SetOrbColor()
	local orb = {unpack(db.Colors.orb)}
	LUI_OrbFill:SetVertexColor(unpack(db.Colors.orb))
	LUI_OrbGalaxy1.t:SetVertexColor(unpack(db.Colors.orb))
	LUI_OrbGalaxy2.t:SetVertexColor(unpack(db.Colors.orb))
	LUI_OrbGalaxy3.t:SetVertexColor(unpack(db.Colors.orb))
end

function module:OnInitialize()
	self.db = LUI.db.profile
	db = self.db
end

function module:OnEnable()
end

function module:OnDisable()
end