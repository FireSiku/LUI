--[[
	Project.: LUI NextGenWoWUserInterface
	File....: LUI.lua
	Version.: 3.403
	Rev Date: 13/02/2011
	Author..: Louí [EU-Das Syndikat] <In Fidem>
]]

local addonname, LUI = ...
local L = LUI.L

local AceAddon = LibStub("AceAddon-3.0")

-- this is a temp globalization (should make it check for alpha verion to globalize or not once all other files don't need global)
_G.LUI = LUI
_G.oUF = LUI.oUF

local Media = LibStub("LibSharedMedia-3.0")
local Profiler = LUI.Profiler
local widgetLists = AceGUIWidgetLSMlists
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

LUI.Versions = {lui = 3403}

LUI.dummy = function() return end

local LIVE_TOC = 80000
local LIVE_BUILD = 27101
-- Check the build to compare with PTR
local _, CURRENT_BUILD, _, CURRENT_TOC = GetBuildInfo()
if tonumber(CURRENT_BUILD) > LIVE_BUILD then
	LUI.PTR = true
	--LUI:Print("Using Code Designed for New Patch")
end
local ProfileName = UnitName("player").." - "..GetRealmName()

-- Work around for IsDisabledByParentalControls() errors. Simply hide the frame. It will still error but that's OK.
UIParent:HookScript("OnEvent", function(s, e, a1, a2) if e:find("ACTION_FORBIDDEN") and ((a1 or "")..(a2 or "")):find("IsDisabledByParentalControls") then StaticPopup_Hide(e) end; end)
-- Come on Blizzard, please fix this soon!

-- REGISTER FONTS
Media:Register("font", "vibrocen", [[Interface\Addons\LUI\media\fonts\vibrocen.ttf]])
Media:Register("font", "vibroceb", [[Interface\Addons\LUI\media\fonts\vibroceb.ttf]])
Media:Register("font", "Prototype", [[Interface\Addons\LUI\media\fonts\prototype.ttf]])
Media:Register("font", "neuropol", [[Interface\AddOns\LUI\media\fonts\neuropol.ttf]])
Media:Register("font", "AvantGarde_LT_Medium", [[Interface\AddOns\LUI\media\fonts\AvantGarde_LT_Medium.ttf]])
Media:Register("font", "Arial Narrow", [[Interface\AddOns\LUI\media\fonts\ARIALN.TTF]])
Media:Register("font", "Pepsi", [[Interface\AddOns\LUI\media\fonts\pepsi.ttf]])

-- REGISTER BORDERS
Media:Register("border", "glow", [[Interface\Addons\LUI\media\textures\borders\glow.tga]])
Media:Register("border", "Stripped", [[Interface\Addons\LUI\media\textures\borders\Stripped.tga]])
Media:Register("border", "Stripped_hard", [[Interface\Addons\LUI\media\textures\borders\Stripped_hard.tga]])
Media:Register("border", "Stripped_medium", [[Interface\Addons\LUI\media\textures\borders\Stripped_medium.tga]])

-- REGISTER STATUSBARS
Media:Register("statusbar", "oUF LUI", [[Interface\AddOns\LUI\media\textures\statusbars\oUF_LUI.tga]])
Media:Register("statusbar", "LUI_Gradient", [[Interface\AddOns\LUI\media\textures\statusbars\gradient32x32.tga]])
Media:Register("statusbar", "LUI_Minimalist", [[Interface\AddOns\LUI\media\textures\statusbars\Minimalist.tga]])
Media:Register("statusbar", "LUI_Ruben", [[Interface\AddOns\LUI\media\textures\statusbars\Ruben.tga]])
Media:Register("statusbar", "Smelly", [[Interface\AddOns\LUI\media\textures\statusbars\Smelly.tga]])
Media:Register("statusbar", "Neal", [[Interface\AddOns\LUI\media\textures\statusbars\Neal]])
Media:Register("statusbar", "RenaitreMinion", [[Interface\AddOns\LUI\media\textures\statusbars\RenaitreMinion.tga]])
Media:Register("statusbar", "Otravi", [[Interface\AddOns\LUI\media\textures\statusbars\Otravi.tga]])
Media:Register("statusbar", "Empty", [[Interface\AddOns\LUI\media\textures\blank]])

local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.Media = {
	["blank"] = [[Interface\AddOns\LUI\media\textures\blank]],
	["normTex"] = [[Interface\AddOns\LUI\media\textures\statusbars\normTex]], -- texture used for nameplates healthbar
	["glowTex"] = [[Interface\AddOns\LUI\media\textures\statusbars\glowTex]], -- the glow texture around some frame.
	["cross"] = [[Interface\AddOns\LUI\media\textures\icons\cross]], -- Worldmap Move Button.
	["party"] = [[Interface\AddOns\LUI\media\textures\icons\Party]], -- Worldmap Party Icon.
	["raid"] = [[Interface\AddOns\LUI\media\textures\icons\Raid]], -- Worldmap Raid Icon.
	["mail"] = [[Interface\AddOns\LUI\media\textures\icons\mail]], -- Minimap Mail Icon.
	["btn_normal"] = [[Interface\AddOns\LUI\media\textures\buttons\Normal]], -- Standard Button Texture example: Auras
	["btn_border"] = [[Interface\AddOns\LUI\media\textures\buttons\Border]], -- Button Border
	["btn_gloss"] = [[Interface\AddOns\LUI\media\textures\buttons\Gloss]], -- Button Overlay
}

LUI.FontFlags = {
	NONE = L["None"],
	OUTLINE = L["Outline"],
	THICKOUTLINE = L["Thick Outline"],
	MONOCHROME = L["Monochrome"],
}

LUI.Points = {
	CENTER = L["Center"],
	TOP = L["Top"],
	BOTTOM = L["Bottom"],
	LEFT = L["Left"],
	RIGHT = L["Right"],
	TOPLEFT = L["Top Left"],
	TOPRIGHT = L["Top Right"],
	BOTTOMLEFT = L["Bottom Left"],
	BOTTOMRIGHT = L["Bottom Right"],
}
LUI.Corners = {
	TOPLEFT = L["Top Left"],
	TOPRIGHT = L["Top Right"],
	BOTTOMLEFT = L["Bottom Left"],
	BOTTOMRIGHT = L["Bottom Right"],
}
LUI.Sides = {
	TOP = L["Top"],
	BOTTOM = L["Bottom"],
	LEFT = L["Left"],
	RIGHT = L["Right"],
}
LUI.Opposites = {
	-- Sides
	TOP = "BOTTOM",
	BOTTOM = "TOP",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	-- Corners
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
}

local screen_height, screen_width = 1920, 1080
local screenRes = {GetScreenResolutions()}
local currentRes = GetCurrentResolution()
if currentRes == 0 then currentRes = #screenRes end
if screenRes[currentRes] then
	screen_height = string.match(screenRes[currentRes], "%d+x(%d+)")
	screen_width = string.match(screenRes[currentRes], "(%d+)x%d+")
end
local _, class = UnitClass("player")

------------------------------------------------------
-- / CREATING DEFAULTS / --
------------------------------------------------------

LUI.defaults = {
	profile = {
		General = {
			IsConfigured = false,
			HideErrors = false,
			HideTalentSpam = false,
			AutoInvite = false,
			AutoInviteOnlyFriend = true,
			AutoInviteKeyword = "",
			AutoAcceptInvite = false,
			BlizzFrameScale = 1,
			ModuleMessages = true,
			DamageFont = "neuropol",
			DamageFontSize = 25,
			DamageFontSizeCrit = 34,
			["*"] = {},
		},
		Recount = {
			Font = "vibrocen",
			FontHack = true,
			FontSize = 13,
		},
	},
	global = {
		luiconfig = {},
	},
}

local db_
local db = setmetatable({}, {
	__index = function(t, k)
		return db_[k]
	end,
	__newindex = function(t, k, v)
		db_[k] = v
	end
})

local function CheckResolution()
	local ScreenWidth = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "(%d+)x%d+")
	local ScreenHeight = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")

	if ScreenWidth == "1280" and ScreenHeight == "1024" then
		-- Repostion Info Texts
		local Infotext = LUI:Module("Infotext", true)
		if Infotext and false then -- broken with false until proper positions have been determined
			Infotext.db.defaults.profile.Bags.X = -100
			Infotext.db.defaults.profile.Durability.X = 10
			Infotext.db.defaults.profile.FPS.X = 120
			Infotext.db.defaults.profile.Memory.X = 190
		end

		LUI.defaults.profile.Frames.Dps.X = -968
		LUI.defaults.profile.Frames.Dps.Y = 863

		LUI.defaults.profile.Frames.Tps.X = 5
		LUI.defaults.profile.Frames.Tps.Y = 882

		-- Reposition Auras
		local auras = LUI:Module("Auras")
		auras.db.General.Anchor = "TOPRIGHT"
		auras.db.Buffs.X = -170
		auras.db.Buffs.Y = -75
		auras.db.Debuffs.X = -170
		auras.db.Debuffs.Y = -185
	end
end

local function RGBToHex(r, g, b)
	r = r <= 255 and r >= 0 and r or 0
	g = g <= 255 and g >= 0 and g or 0
	b = b <= 255 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r, g, b)
end

function LUI:Kill(object)
	object.Show = LUI.dummy
	object:Hide()
end

local function scale(x)
	local scaleUI = UIParent:GetEffectiveScale()
	local mult = 768/screen_height/scaleUI
	LUI.mult = mult
	return mult*math.floor(x/mult+.5)
end

function LUI:Scale(x) return scale(x) end

function LUI:CreatePanel(f, w, h, a1, p, a2, x, y)
	local sh = scale(h)
	local sw = scale(w)
	f:SetFrameLevel(1)
	f:SetHeight(sh)
	f:SetWidth(sw)
	f:SetFrameStrata("BACKGROUND")
	f:SetPoint(a1, p, a2, x, y)
	f:SetBackdrop({
		bgFile = LUI.Media.blank,
		edgeFile = LUI.Media.blank,
		tile = false, tileSize = 0, edgeSize = LUI.mult,
		insets = { left = -LUI.mult, right = -LUI.mult, top = -LUI.mult, bottom = -LUI.mult}
	})
	f:SetBackdropColor(.1,.1,.1,1)
	f:SetBackdropBorderColor(.6,.6,.6,1)
end

function LUI:StyleButton(b, checked)
	local name = b:GetName()

	local button          = _G[name]
	local icon            = _G[name.."Icon"]
	local count           = _G[name.."Count"]
	local border          = _G[name.."Border"]
	local hotkey          = _G[name.."HotKey"]
	local cooldown        = _G[name.."Cooldown"]
	local nametext        = _G[name.."Name"]
	local flash           = _G[name.."Flash"]
	local normaltexture   = _G[name.."NormalTexture"]
	local icontexture     = _G[name.."IconTexture"]

	local hover = b:CreateTexture("frame", nil, self) -- hover
	hover:SetColorTexture(1,1,1,0.2)
	hover:SetHeight(button:GetHeight())
	hover:SetWidth(button:GetWidth())
	hover:SetPoint("TOPLEFT",button,2,-2)
	hover:SetPoint("BOTTOMRIGHT",button,-2,2)
	button:SetHighlightTexture(hover)

	local pushed = b:CreateTexture("frame", nil, self) -- pushed
	pushed:SetColorTexture(0.9,0.8,0.1,0.3)
	pushed:SetHeight(button:GetHeight())
	pushed:SetWidth(button:GetWidth())
	pushed:SetPoint("TOPLEFT",button,2,-2)
	pushed:SetPoint("BOTTOMRIGHT",button,-2,2)
	button:SetPushedTexture(pushed)

	local Infotext = self:Module("Infotext", true)
	count:SetFont(Media:Fetch("font", (Infotext and Infotext.db.profile.FPS.Font or "vibroceb")), (Infotext and Infotext.db.profile.FPS.FontSize or 12), "OUTLINE")

	if checked then
		local checked = b:CreateTexture("frame", nil, self) -- checked
		checked:SetColorTexture(0,1,0,0.3)
		checked:SetHeight(button:GetHeight())
		checked:SetWidth(button:GetWidth())
		checked:SetPoint("TOPLEFT",button,2,-2)
		checked:SetPoint("BOTTOMRIGHT",button,-2,2)
		button:SetCheckedTexture(checked)
	end
end

------------------------------------------------------
-- / CREATE ME A FRAME FUNC / --
------------------------------------------------------

function LUI:CreateMeAFrame(fart,fname,fparent,fwidth,fheight,fscale,fstrata,flevel,fpoint,frelativeFrame,frelativePoint,fofsx,fofsy,falpha,finherit)
	local f = CreateFrame(fart,fname,fparent,finherit)
	local sw = scale(fwidth)
	local sh = scale(fheight)
	local sx = scale(fofsx)
	local sy = scale(fofsy)
	f:SetWidth(sw)
	f:SetHeight(sh)
	--f:SetScale(fscale)
	f:SetFrameStrata(fstrata)
	f:SetFrameLevel(flevel)
	f:SetPoint(fpoint,frelativeFrame,frelativePoint,sx,sy)
	f:SetAlpha(falpha)
	return f
end

------------------------------------------------------
-- / SYNC ADDON VERSION / --
------------------------------------------------------

function LUI:SyncAddonVersion()
	local luiversion, version, newVersion = GetAddOnMetadata(addonname, "Version"), "", ""
	local myRealm, myFaction, inGroup = GetRealmName(), (UnitFactionGroup("player") == "Horde" and 0 or 1), false

	while luiversion ~= nil do
		local pos = strfind(luiversion, "%.")
		if pos then
			version = version .. format("%03d.", strsub(luiversion, 1, pos-1))


			luiversion = strsub(luiversion, pos+1)
		else
			version = version .. format("%03d", luiversion)
			luiversion = nil
			newVersion = version
		end
	end

	local function sendVersion(distribution, target) -- (distribution [, target])
		if distribution == "WHISPER" and not target then
			return
		elseif distribution == "RAID" or distribution == "PARTY" then
			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				self.channel = "INSTANCE_CHAT"
			end
		end

		LUI:SendCommMessage("LUI_Version", version, distribution, target)
	end

	local function checkVersion(prefix, text, distribution, from)
		if version < text and newVersion < text then -- your version out of date (only print once)
			newVersion = text
			LUI:Print(format(L["Version %s available for download."], gsub(text, "%d+", tonumber)))
		elseif version > text and distribution ~= "WHISPER" then -- their version out of date (tell them)
			sendVersion("WHISPER", from)
		end
	end

	local function groupUpdate(groupType)
		if not groupType then return end
		if groupType == "Party" and GetNumGroupMembers() > 0 then return end

		if (groupType == "Party" and (GetNumSubgroupMembers() >= 1) or (GetNumGroupMembers() >= 1)) then
			if inGroup then return end
			inGroup = true
			sendVersion("RAID")
		else
			inGroup = false
		end
	end

	LUI:RegisterComm("LUI_Version", checkVersion)

	for i = 1, GetNumFriends() do -- send to friends via whisper on login
		local name, _, _, _, connected = GetFriendInfo(i)
		if name and connected then
			sendVersion("WHISPER", name)
		end
	end
	for i = 1, BNGetNumFriends() do -- send to BN friends (on your realm) via whisper on login
		local _, _, _, toonName, toonID, client, isOnline = BNGetFriendInfo(i)
		if toonName and isOnline and client == "WoW" then
			local _, _, _, realmName, _, faction = BNGetToonInfo(toonID or 0)
			if realmName == myRealm and faction == myFaction then
				sendVersion("WHISPER", toonName)
			end
		end
	end
	sendVersion("GUILD") -- send to guild on login
	LUI:RegisterEvent("GROUP_ROSTER_UPDATE", groupUpdate, "Party") -- send to party on join party
	LUI:RegisterEvent("GROUP_ROSTER_UPDATE", groupUpdate, "Raid") -- send to raid on join raid
end

------------------------------------------------------
-- / SET DAMAGE FONT / --
------------------------------------------------------

function LUI:SetDamageFont()
	local DamageFont = Media:Fetch("font", db.General.DamageFont)

	_G.COMBAT_TEXT_SCROLLSPEED = 1.9
	_G.COMBAT_TEXT_FADEOUT_TIME = 1.3
	_G.DAMAGE_TEXT_FONT = DamageFont
	_G.COMBAT_TEXT_HEIGHT = db.General.DamageFontSize
	_G.COMBAT_TEXT_CRIT_MAXHEIGHT = db.General.DamageFontSizeCrit
	_G.COMBAT_TEXT_CRIT_MINHEIGHT = db.General.DamageFontSizeCrit - 2
end

------------------------------------------------------
-- / LOAD EXTRA MODULES / --
------------------------------------------------------

function LUI:LoadExtraModules()
	for i=1, GetNumAddOns() do
		local name, _, _, enabled, loadable = GetAddOnInfo(i)
		if strfind(name, "LUI_") and enabled and loadable then
			LoadAddOn(i)
		end
	end
end

------------------------------------------------------
-- / UPDATE / --
------------------------------------------------------

function LUI:Update()
	local updateBG = LUI:CreateMeAFrame("FRAME","updateBG",UIParent,2400,2000,1,"HIGH",5,"CENTER",UIParent,"CENTER",0,0,1)
	updateBG:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	updateBG:SetBackdropColor(0,0,0,1)
	updateBG:SetBackdropBorderColor(0,0,0,0)
	updateBG:SetAlpha(1)
	updateBG:Show()

	local updatelogo = LUI:CreateMeAFrame("FRAME","updatelogo",UIParent,512,512,1,"HIGH",6,"CENTER",UIParent,"CENTER",0,150,1)
	updatelogo:SetBackdrop({bgFile=fdir.."logo", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	updatelogo:SetBackdropBorderColor(0,0,0,0)
	updatelogo:Show()

	local update = LUI:CreateMeAFrame("FRAME","update",updatelogo,512,512,1,"HIGH",6,"BOTTOM",updatelogo,"BOTTOM",0,-130,1)
	update:SetBackdrop({bgFile=fdir.."update", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	update:SetBackdropColor(1,1,1,1)
	update:SetBackdropBorderColor(0,0,0,0)
	update:Show()

	local update_hover = LUI:CreateMeAFrame("FRAME","update_hover",updatelogo,512,512,1,"HIGH",7,"BOTTOM",updatelogo,"BOTTOM",0,-130,1)
	update_hover:SetBackdrop({bgFile=fdir.."update_hover", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	update_hover:SetBackdropColor(1,1,1,1)
	update_hover:SetBackdropBorderColor(0,0,0,0)
	update_hover:Hide()

	local update_frame = LUI:CreateMeAFrame("BUTTON","update_frame",updatelogo,310,80,1,"HIGH",8,"BOTTOM",updatelogo,"BOTTOM",-5,90,1)
	update_frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	update_frame:SetBackdropColor(1,1,1,0)
	update_frame:SetBackdropBorderColor(0,0,0,0)
	update_frame:Show()

	update_frame:SetScript("OnEnter", function(self)
		update:Hide()
		update_hover:Show()
	end)

	update_frame:SetScript("OnLeave", function(self)
		update_hover:Hide()
		update:Show()
	end)

	update_frame:RegisterForClicks("AnyUp")
	update_frame:SetScript("OnClick", function(self)

		if IsAddOnLoaded("Grid") then
			LUI.db.global.luiconfig[ProfileName].Versions.grid = nil
			LUI:InstallGrid()
		end

		if IsAddOnLoaded("Recount") then
			LUI.db.global.luiconfig[ProfileName].Versions.recount = nil
			LUI:InstallRecount()
		end

		if IsAddOnLoaded("Details") then
			LUICONFIG.Versions.details = nil
			LUI:InstallDetails()
		end

		if IsAddOnLoaded("Omen") or IsAddOnLoaded("Omen3") then
			LUI.db.global.luiconfig[ProfileName].Versions.omen = nil
			LUI:InstallOmen()
		end

		if IsAddOnLoaded("Forte_Core") then
			LUI.db.global.luiconfig[ProfileName].Versions.forte = nil
			LUI:InstallForte()
		end

		LUI.db.global.luiconfig[ProfileName].Versions.lui = LUI.Versions.lui
		ReloadUI()
	end)
end

------------------------------------------------------
-- / CONFIGURE / --
------------------------------------------------------

function LUI:Configure()
	if InterfaceOptionsFrame:IsShown() then
		InterfaceOptionsFrame:Hide()
	end

	local configureBG = LUI:CreateMeAFrame("FRAME","configureBG",UIParent,2400,2000,1,"HIGH",5,"CENTER",UIParent,"CENTER",0,0,1)
	configureBG:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	configureBG:SetBackdropColor(0,0,0,1)
	configureBG:SetBackdropBorderColor(0,0,0,0)
	configureBG:SetAlpha(1)
	configureBG:Show()

	local logo = LUI:CreateMeAFrame("FRAME","logo",UIParent,512,512,1,"HIGH",6,"CENTER",UIParent,"CENTER",0,150,1)
	logo:SetBackdrop({bgFile=fdir.."logo", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	logo:SetBackdropBorderColor(0,0,0,0)
	logo:Show()

	local install = LUI:CreateMeAFrame("FRAME","install",logo,512,512,1,"HIGH",6,"BOTTOM",logo,"BOTTOM",0,-130,1)
	install:SetBackdrop({bgFile=fdir.."install", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	install:SetBackdropColor(1,1,1,1)
	install:SetBackdropBorderColor(0,0,0,0)
	install:Show()

	local install_hover = LUI:CreateMeAFrame("FRAME","install_hover",logo,512,512,1,"HIGH",7,"BOTTOM",logo,"BOTTOM",0,-130,1)
	install_hover:SetBackdrop({bgFile=fdir.."install_hover", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	install_hover:SetBackdropColor(1,1,1,1)
	install_hover:SetBackdropBorderColor(0,0,0,0)
	install_hover:Hide()

	local install_frame = LUI:CreateMeAFrame("BUTTON","install_frame",logo,310,80,1,"HIGH",8,"BOTTOM",logo,"BOTTOM",-5,90,1)
	install_frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	install_frame:SetBackdropColor(1,1,1,0)
	install_frame:SetBackdropBorderColor(0,0,0,0)
	install_frame:Show()

	install_frame:SetScript("OnEnter", function(self)
		install:Hide()
		install_hover:Show()
	end)

	install_frame:SetScript("OnLeave", function(self)
		install_hover:Hide()
		install:Show()
	end)

	install_frame:RegisterForClicks("AnyUp")
	install_frame:SetScript("OnClick", function(self)

		SetCVar("buffDurations", 1)
		SetCVar("scriptErrors", 1)
		SetCVar("uiScale", 0.6949)
		SetCVar("useUiScale", 1)
		SetCVar("chatMouseScroll", 1)
		SetCVar("chatStyle", "classic")

		if LUI.db.global.luiconfig[ProfileName].Versions then
			wipe(LUI.db.global.luiconfig[ProfileName].Versions)
		end

		LUI:InstallGrid()
		LUI:InstallRecount()
		LUI:InstallOmen()
		LUI:InstallBartender()
		LUI:InstallForte()
		LUI:InstallDetails()

		LUI.db.global.luiconfig[ProfileName].Versions.lui = LUI.Versions.lui
		LUI.db.global.luiconfig[ProfileName].IsConfigured = true
		-- This is commented out for now as it causes issues.
		-- Sorry, if you're using 1280x1024 things might look
		-- funky, but LUI will at least install properly.
		--CheckResolution()
		ReloadUI()
	end)
end

------------------------------------------------------
-- / MODULES / --
------------------------------------------------------

local function getModulePrototype(parent)
	local prototype = {
		Toggle = parent.Toggle,
		GetDBVar = parent.GetDBVar,
		SetDBVar = parent.SetDBVar,
		GetDefaultVal = parent.GetDefaultVal,
	}

	if parent == LUI then
		prototype.Module = parent.Module
		prototype.Namespace = parent.Namespace
	end

	return prototype
end

-- LUI:Module(name [, silent]) to get module (if silent is true and the module does not exist, it will not be created)
-- LUI:Module(name [, prototype] [, libs...]) -- to create module or add to module
function LUI:Module(name, prototype, ...)
	local i = 1
	local module = self:GetModule(name, true)
	if module then
		if type(prototype) == "string" then
			AceAddon:EmbedLibraries(module, prototype, ...)
		elseif type(prototype) == "table" then
			AceAddon:EmbedLibraries(module, ...)

			-- set prototype
			local mt = getmetatable(module)
			if self.defaultModulePrototype then
				mt.__index = setmetatable(prototype, {__index = self.defaultModulePrototype})
			else
				mt.__index = prototype
			end
			setmetatable(module, mt)
		end
	elseif prototype ~= true then -- check silent
		if not next(self.modules) then
			self:SetDefaultModuleLibraries("LUIDevAPI")
			self:SetDefaultModulePrototype(getModulePrototype(self))
		end

		-- add the defaultPrototype as a metatable to the prototype if it exists
		if type(prototype) == "table" and self.defaultModulePrototype then
			setmetatable(prototype, {__index = self.defaultModulePrototype})
		end

		module = self:NewModule(name, prototype, ...)

		if self ~= LUI then
			module.isNestedModule = true
		end
	end

	return module
end

function LUI:Toggle(state)
	if state == nil then
		state = not self:IsEnabled()
	end
	state = state and "Enable" or "Disable"

	local success = self[state](self)

	if self.db.parent then
		self.db.parent.profile.modules[self:GetName()] = self:IsEnabled()
	end
	return success
end

function LUI:GetDBVar(info)
	local value = self.db.profile

	local start = self.isNestedModule and 3 or 2
	for i=start, #info-1 do
		value = value[info[i]]
		if type(value) ~= "table" then
			error("Error accessing db\nCould not access "..strjoin(".", info[start-1], "db.profile", unpack(info, start, value == nil and i or i+1)).."\ndb layout must be the same as info", 2)
		end
	end
	return value[info[#info]]
end

function LUI:SetDBVar(info, value)
	local dbloc = self.db.profile

	local start = self.isNestedModule and 3 or 2
	for i=start, #info-1 do
		dbloc = dbloc[info[i]]
		if type(dbloc) ~= "table" then
			error("Error accessing db\nCould not access "..strjoin(".", info[start-1], "db.profile", unpack(info, start, dbloc == nil and i or i+1)).."\ndb layout must be the same as info", 2)
		end
	end
	dbloc[info[#info]] = value
end

function LUI:GetDefaultVal(info)
	local dbloc = self.db.defaults.profile

	local start = self.isNestedModule and 3 or 2
	for i=start, #info-1 do
		local key = info[i]
		if not dbloc[key] then
			key = "*"
		end

		dbloc = dbloc[key]

		if type(dbloc) ~= "table" then
			error("Error accessing defaults\nCould not access "..strjoin(".", info[start-1], "db.defaults.profile", unpack(info, start, dbloc == nil and i or i+1)).."\ndefaults layout must be the same as info", 2)
		end
	end

	local key = info[#info]
	if dbloc[key] == nil then
		key = "*"
	end

	return dbloc[key]
end

local function conflictChecker(...)
	for i=1, select("#", ...) do
		if IsAddOnLoaded(select(i, ...)) then
			return select(i, ...)
		end
	end
end
function LUI:CheckConflict(...) -- self is module
	local conflict = false
	if type(self.conflicts) == "table" then
		conflict = conflictChecker(unpack(self.conflicts))
	else
		conflict = conflictChecker((";"):split(self.conflicts))
	end

	if conflict then
		-- disable without calling OnDisable function
		AceAddon.statuses[self.name] = false
		self:SetEnabledState(false)
		-- same for child modules
		for name, module in self:IterateModules() do
			AceAddon.statuses[module.name] = false
			module:SetEnabledState(false)
		end
		if db.General.ModuleMessages then
			LUI:Printf("|cffFF0000%s could not be enabled because of a conflicting addon: %s.", self:GetName(), conflict)
		end
		return
	else
		return LUI.hooks[self].OnEnable(self, ...)
	end
end

------------------------------------------------------
-- / SCRIPTS / --
------------------------------------------------------

do
	local scripts = {}

	function LUI:NewScript(name, ...)
		local script = {}
		scripts[name] = script

		local errormsg
		for i=1, select("#", ...) do
			local lib = select(i, ...)
			if type(lib) ~= "string" then
				errormsg = "Error generating script: "..name.." - library names must be string values!"
			elseif not LibStub(lib, true) then
				errormsg = "Error generating script: "..name.." - '"..lib.."' library does not exist!"
			elseif type(LibStub(lib).Embed) ~= "function" then
				errormsg = "Error generating script: "..name.." - '"..lib.."' library is not Embedable!"
			end
			if errormsg then
				return self:Print(errormsg)
			end

			LibStub(lib):Embed(script)
		end

		return script
	end

	function LUI:FetchScript(name)
		return scripts[name]
	end
end

------------------------------------------------------
-- / OPTIONS MENU / --
------------------------------------------------------

local options, moduleList, moduleOptions, newModuleOptions, frameOptions = nil, {}, {}, {}, {}

function LUI:MergeOptions(target, source, sort)
	if type(target) ~= "table" then target = {} end
	for k, v in pairs(target) do
		if k == "type" and v ~= "group" then
			target = {}
			break
		end
	end
	for k, v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:MergeOptions(target[k], v)

			-- Sort modules by name if they don't have an order.
			if sort then target[k].order = target[k].order or 10 end
		else
			target[k] = v
		end
	end
	return target
end

local function getOptions()
	if not LUI.options then
		LUI.options = {
			name = "LUI",
			type = "group",
			args = {
				General = {
					name = "General",
					order = 1,
					type = "group",
					childGroups = "tab",
					args = {
						Welcome = {
							name = "Welcome",
							type = "group",
							order = 1,
							args = {
								IntroImage = {
									order = 1,
									image = [[Interface\AddOns\LUI\media\textures\logo]],
									imageWidth = 512,
									width = "full",
									imageHeight = 128,
									imageCoords = { 0, 1, 0, 1 },
									type = "description",
									name = " ",
								},
								empty5 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 2,
								},
								IntroText = {
									order = 3,
									width = "full",
									type = "description",
									name = L["Welcome to LUI v3"].."\n\n"..L["Please read the FAQ"].."\n\n\n",
								},
								VerText = {
									order = 4,
									width = "full",
									type = "description",
									name = L["Version: "]..GetAddOnMetadata(addonname, "Version"),
								},
								RevText = {
									order = 5,
									width = "full",
									type = "description",
									name = function()
										local revision = LUI.Rev
										if revision and strmatch(revision,"-%d+") then
											revision = gsub( strmatch(revision,"-%d+"), "-", "r")
										elseif revision and strmatch(revision, "%d") then
											revision = "r"..revision
										end
										return L["Revision: "]..(revision or "???")
									end,
								},
							},
						},
						Settings = {
							name = "Settings",
							type = "group",
							order = 2,
							args = {
								header2 = {
									name = "General Options",
									type = "header",
									order = 1,
								},
								empty5 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 2,
								},
								empty512s = {
									name = "   ",
									width = "full",
									type = "description",
									order = 3,
								},
								AlwaysShowDesc = {
									order = 4,
									width = "full",
									type = "description",
									name = "LUI will show automatically all Frames which were shown after logging out.\n\nYou can set some Rules here that LUI should always show some Frames regardless of how you are logging off."
								},
								empty6 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 5,
								},
								alwaysShowMinimap = {
									name = "Show Minimap",
									desc = "Whether you want to show the Minimap by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.Minimap.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.Minimap
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 6,
								},
								alwaysShowChat = {
									name = "Show Chat",
									desc = "Whether you want to show the Chat Panel by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.Chat.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.Chat
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 7,
								},
								alwaysShowOmen = {
									name = "Show TPS",
									desc = "Whether you want to show your TPS Panel by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.Tps.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.Tps
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 8,
								},
								alwaysShowRecount = {
									name = "Show DPS",
									desc = "Whether you want to show your DPS Panel by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.Dps.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.Dps
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 9,
								},
								alwaysShowGrid = {
									name = "Show Raid",
									desc = "Whether you want to show your Raid Panel by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.Raid.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.Raid
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 10,
								},
								alwaysShowMicroMenu = {
									name = "Show MicroMenu",
									desc = "Whether you want to show the Micromenu by entering World or not.\n",
									type = "toggle",
									get = function() return LUI:Module("Panels").db.profile.MicroMenu.AlwaysShow end,
									set = function()
										local a = LUI:Module("Panels").db.profile.MicroMenu
										a.AlwaysShow = not a.AlwaysShow
									end,
									order = 12,
								},
								empty22225 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 13,
								},
								header90 = {
									name = "Misc Options",
									type = "header",
									order = 30,
								},
								BlizzFrameScale = {
									name = "Blizzard Frame Scale",
									desc = "Set the scale of the Blizzard Frames.\nEx: CharacterFrame, SpellBookFrame, etc...",
									type = "range",
									min = 0.5,
									max = 2.0,
									step = 0.05,
									isPercent = true,
									width = "double",
									get = function() return db.General.BlizzFrameScale end,
									set = function(info, value)
										if scale == nil or scale == "" then scale = 1 end
										db.General.BlizzFrameScale = value
										LUI:FetchScript("BlizzScale"):ApplyBlizzScaling()
									end,
									order = 32,
								},
								empty3 = {
									name = " ",
									width = "full",
									type = "description",
									order = 33,
								},
								BlockErrors = {
									name = "Hide Blizzard Error Messages",
									desc = "Hide Blizzard Errors like: Not enough energy or Not enough Mana",
									type = "toggle",
									width = "full",
									get = function() return db.General.HideErrors end,
									set = function(info, value)
										db.General.HideErrors = value
										LUI:FetchScript("ErrorHider"):ErrorMessageHandler()
									end,
									order = 34,
								},
								HideTalentSpam = {
									name = "Hide Talent Change Spam",
									desc = "Filters out the chat window spam that occurs when you switch specs",
									type = "toggle",
									width = "full",
									get = function() return db.General.HideTalentSpam end,
									set = function(info, value)
										db.General.HideTalentSpam = value
										LUI:FetchScript("TalentSpam"):SetTalentSpam()
									end,
									order = 35,
								},
								ModuleMessages = {
									name = "Show Module Messages",
									desc = "Show messages when LUI modules are enabled or disabled",
									type = "toggle",
									width = "full",
									get = function() return db.General.ModuleMessages end,
									set = function() db.General.ModuleMessages = not db.General.ModuleMessages end,
									order = 36,
								},
								AutoAcceptInvite = {
									name = "Enable Auto Accept Invites",
									desc = "Choose if you want to accept all Invites from Guildmembers/Friends or not.",
									type = "toggle",
									width = "full",
									get = function() return db.General.AutoAcceptInvite end,
									set = function(info, value)
										db.General.AutoAcceptInvite = value
										LUI:FetchScript("AutoInvite"):SetAutoAccept()
									end,
									order = 37,
								},
								AutoInvite = {
									name = "Enable AutoInvite",
									desc = "Choose if you want to Enable AutoInvite or not.\n\nYou can type '/lui invite' to enable/disable this option.",
									type = "toggle",
									width = "full",
									get = function() return db.General.AutoInvite end,
									set = function(info, value)
										db.General.AutoInvite = value
										LUI:FetchScript("AutoInvite"):SetAutoInvite()
									end,
									order = 38,
								},
								AutoInviteOnlyFriend = {
									name = "Only Friends/Guildmates",
									desc = "If AutoInvite should invite only your friends/guildmates or anyone.",
									type = "toggle",
									width = "full",
									disabled = function() return not db.General.AutoInvite end,
									get = function() return db.General.AutoInviteOnlyFriend end,
									set = function(info, value)
										db.General.AutoInviteOnlyFriend = value
									end,
									order = 39,
								},
								AutoInviteKeyword = {
									name = "Auto Invite Keyword",
									desc = "Choose any Keyword for Auto Invite",
									type = "input",
									disabled = function() return not db.General.AutoInvite end,
									get = function() return db.General.AutoInviteKeyword end,
									set = function(info, value)
										if value == nil then value = "" end
										db.General.AutoInviteKeyword = value
									end,
									order = 40,
								},
								header91 = {
									name = "Damage Font/Size",
									type = "header",
									order = 45,
								},
								DamageFont = {
									name = "Font",
									desc = "Choose your Font!\n\nNote:\nYou have to Relog!.\nType /rl\n\nDefault: neuropol",
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function()
										return db.General.DamageFont
									end,
									set = function(self, DamageFont)
										db.General.DamageFont = DamageFont
									end,
									order = 46,
								},
								empty3445 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 47,
								},
								DamageFontSize = {
									name = "Fontsize",
									desc = "Choose your Fontsize!\n\nNote:\nYou have to Relog!.\nType /rl\n\nDefault: 38",
									type = "range",
									min = 20,
									max = 60,
									step = 1,
									get = function() return db.General.DamageFontSize end,
									set = function(_, DamageFontSize)
										db.General.DamageFontSize = DamageFontSize
									end,
									order = 48,
								},
								empty34456 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 49,
								},
								DamageFontSizeCrit = {
									name = "Fontsize Crits",
									desc = "Choose your Fontsize for Crits!\n\nNote:\nYou have to Relog!.\nType /rl\n\nDefault: 41",
									type = "range",
									min = 20,
									max = 60,
									step = 1,
									get = function() return db.General.DamageFontSizeCrit end,
									set = function(_, DamageFontSizeCrit)
										db.General.DamageFontSizeCrit = DamageFontSizeCrit
									end,
									order = 50,
								},
								empty34457 = {
									name = "   ",
									width = "full",
									type = "description",
									order = 51,
								},
								HideBlizzardRaid = {
									name = "Hide Blizzard Raid Frames",
									desc = "Hide Blizzard Raid Frames (only available when LUI Unitframes are disabled)",
									type = "toggle",
									width = "full",
									disabled = function() return LUI:Module("Unitframes").db.Enable end,
									get = function() return LUI:Module("Unitframes").db.Settings.HideBlizzRaid end,
									set = function(info, value)
										LUI:Module("Unitframes").db.Settings.HideBlizzRaid = value
										if value then
											LUI:Module("Unitframes"):Module("HideBlizzard"):Hide("raid", true)
										else
											LUI:Module("Unitframes"):Module("HideBlizzard"):Show("raid")
										end
									end,
									order = 52,
								},
							},
						},
						Addons = {
							name = "Addons",
							type = "group",
							order = 4,
							args = {
								Header1 = {
									name = "Restore Addon Defaults",
									type = "header",
									order = 1,
								},
								ResetBartender = {
									order = 2,
									type = "execute",
									name = "Restore Bartender",
									func = function()
										LUI.db.global.luiconfig[ProfileName].Versions.bartender = nil
										LUI:InstallBartender()
										StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("Bartender4") end,
									hidden = function() return not IsAddOnLoaded("Bartender4") end,
								},
								ResetForte = {
									order = 2,
									type = "execute",
									name = "Restore ForteXorcist",
									func = function()
										LUI.db.global.luiconfig[ProfileName].Versions.forte = nil
										LUI:InstallForte()
										StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("ForteXorcist") end,
									hidden = function() return not IsAddOnLoaded("ForteXorcist") end,
								},
								ResetGrid = {
									order = 2,
									type = "execute",
									name = "Restore Grid",
									func = function()
										LUI.db.global.luiconfig[ProfileName].Versions.grid = nil
										LUI:InstallGrid()
										StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("Grid") end,
									hidden = function() return not IsAddOnLoaded("Grid") end,
								},
								ResetOmen = {
									order = 2,
									type = "execute",
									name = "Restore Omen",
									func = function()
										LUI.db.global.luiconfig[ProfileName].Versions.omen = nil
										LUI:InstallOmen()
										StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("Omen") end,
									hidden = function() return not IsAddOnLoaded("Omen") end,
								},
								ResetRecount = {
									order = 2,
									type = "execute",
									name = "Restore Recount",
									func = function()
										LUI.db.global.luiconfig[ProfileName].Versions.recount = nil
										LUI:InstallRecount()
										StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("Recount") end,
									hidden = function() return not IsAddOnLoaded("Recount") end,
								},
								ResetDetails = {
									order = 2,
									type = "execute",
									name = "Restore Details!",
									func = function()
										LUICONFIG.Versions.details = nil
										LUI:InstallDetails()
										LUI:GetModule("Panels"):ApplyBackground("Dps")
										--StaticPopup_Show("RELOAD_UI")
									end,
									disabled = function() return not IsAddOnLoaded("Details") end,
									hidden = function() return not IsAddOnLoaded("Details") end,
								},
								Header2 = {
									name = "Recount Settings",
									type = "header",
									order = 3,
									hidden = function() return not IsAddOnLoaded("Recount") end,
								},
								RecountHack = {
									name = "Force Font Size",
									desc = "Whether or not to apply a font size fix to Recount.",
									type = "toggle",
									order = 4,
									disabled = function() return not IsAddOnLoaded("Recount") end,
									hidden = function() return not IsAddOnLoaded("Recount") end,
									get = function() return db.Recount.FontHack end,
									set = function() LUI.RecountFontHack:Toggle() end,
								},
								RecountFontSize = {
									name = "Font Size",
									desc = "Set the font size for Recount's bars.",
									type = "range",
									min = 0,
									max = 100,
									step = 1,
									disabled = function() return not IsAddOnLoaded("Recount") or not db.Recount.FontHack end,
									hidden = function() return not IsAddOnLoaded("Recount") end,
									get = function() return db.Recount.FontSize end,
									set = function(self, size)
										db.Recount.FontSize = size
										Recount:BarsChanged()
									end,
									order = 5,
								},
								RecountFont = {
									name = "Font",
									desc = "Choose the font that Recount will use. This is to overcome issues with Recount loading before LUI.",
									type = "select",
									disabled = function() return not IsAddOnLoaded("Recount") end,
									hidden = function() return not IsAddOnLoaded("Recount") end,
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function()
										return db.Recount.Font
									end,
									set = function(self, font)
										db.Recount.Font = font
										Recount:BarsChanged()
									end,
									order = 6,
								},
								Header3 = {
									name = "Restore ALL Addon Defaults",
									type = "header",
									order = 7,
								},
								ResetDesc = {
									order = 8,
									width = "full",
									type = "description",
									name = "ATTENTION:\nAll SavedVariables from Grid, Recount, Omen, Bartender and ForteXorcist will be reset!"
								},
								Reset = {
									order = 9,
									type = "execute",
									name = "Restore Defaults",
									func = function()
										StaticPopup_Show("RESTORE_DETAULTS")
									end,
								},
							},
						},
						Thanks = {
							name = "Thanks",
							type = "group",
							order = 5,
							args = {
								empty5 = {
									name = " ",
									width = "full",
									type = "description",
									order = 2,
								},
								IntroText = {
									order = 3,
									width = "full",
									type = "description",
									name = "The development and sustained maintenance of LUI V3 wasn't the work of a single so I would like to take the time to list a few people that deserves thanks for their support".."\n",
								},
								Staff = {
									order = 4,
									width = "full",
									type = "description",
									fontSize = "medium",
									name = "Current V3 Devs: |cffe6cc80Siku, Mule|r\n",
								},
								OldStaff = {
									order = 5,
									width = "full",
									type = "description",
									fontSize = "medium",
									name = "Former V3 Devs: |cffe6cc80Loui, Sinaris, Zista, hix, Thaly, Shendrela, Darkruler, Yunai|r\n\n",
								},
								Donators = {
									order = 6,
									width = "full",
									type = "description",
									name = "I would also like to thank everyone that donated to the project, you are all wonderful people. A special mention goes to my current and former Patrons:".."\n",
								},
								HighPatrons = {
									order = 7,
									width = "full",
									type = "description",
									fontSize = "large",
									name = "|cffa335eeSkinny Man Music, Qoke, StephenFOlson, Fearon Whitcomb, Coy Linnerooth, Spencer Sommers".."\n",
								},
								OtherPatrons = {
									order = 8,
									width = "full",
									type = "description",
									fontSize = "medium",
									name = "|cff1eff00Adam Moody, Andrew DePaola, Angryrice, Anthony Béchard, apexius, Azona, BIRDki, Brandon Burr, Chris Manring, Confatalis, Curtis Motzner, Dalton Matheson, David Cook, Dochouse, Grant Sundstrom, gnuheike, Hansth, Ian Huisman, Joseph Arnett, Kris Springer, Lyra, Lysa Richey, Mathias Reffeldt, Max McBurn, Melvin de Grauw, Michael Swancott, Michael Walker, Michelle Larrew, Mike, McCabe, Mike Williams, Nick Giovanni, necr0, Oscar Olofsson, Philipp Rissle, Preston Cheek, Ranarok, Richard Scholten, Romain Gorgibus, Saturos Zed, Scott Crawford,Sean O'Shea, Shawn Pitts, Slawomir Baran, Srg Kuja, Steph Lee, Tobias Lidén, Xenthe, Ziri".."\n",
								},
							},
						},
					},
				},
				Space = {
					name = "",
					order = 8,
					type = "group",
					args = {},
				},
				Modules = {
					name = "|cffffffffModules:|r",
					order = 9,
					type = "group",
					args = {
						Header = LUI:NewHeader("Module List", 1),
						UpdatedModules = LUI:NewHeader("Old Modules", 150),
					},
				},
			},
		}
		LUI.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LUI.db)
		LUI.options.args.profiles.order = 4

		local copyProfile, selectModules = {}, nil
		do
			selectModules = function(...)
				local name = addonname.."_ProfileCopier"

				local options = {
					name = "Select Modules",
					type = "group",
					args = {
						title = {
							order = 1,
							type = "description",
							name = function() return "Copying profile: "..copyProfile.name.."\nWhich modules should be copied?" end,
						},
						copy = {
							order = -1,
							type = "execute",
							name = "Copy Selected Modules",
							func = function()
								for k, v in pairs(copyProfile) do
									if k ~= "name" and v == true then
										local module = LUI:Module(k, true)
										if module then
											LUI.db.CopyProfile(module.db, copyProfile.name)
										end
									end
								end
								ACD:Close(name)
							end,
						},
					},
				}
				local moduleChkbox = {
					type = "toggle",
					name = function(info) return info[#info] end,
					get = function(info) return copyProfile[info[#info]] end,
					set = function(info, value) copyProfile[info[#info]] = value end,
					disabled = function(info)
						local module = LUI:Module(info[#info], true)
						if module then
							return (not(module.db and module.db.profiles and module.db.profiles[copyProfile.name]) and true or false)
						end
					end,
				}
				for i, v in ipairs(newModuleOptions) do
					if type(v) == "string" then
						options.args[v] = moduleChkbox
					end
				end
				LibStub("AceConfig-3.0"):RegisterOptionsTable(name, options)

				selectModules = function(info, value)
					copyProfile.name = value
					local parent = ACD.OpenFrames.LUI
					ACD:SetDefaultSize(name, 300, parent.status.height)
					ACD:Open(name)
					local f = ACD.OpenFrames[name]
					f.frame:SetScale(db.General.BlizzFrameScale)
					f:SetCallback("OnClose", function(widget, event)
						wipe(copyProfile)
						widget.frame:SetScale(1)
						local appName = widget:GetUserData("appName")
						ACD.OpenFrames[appName] = nil
						LibStub("AceGUI-3.0"):Release(widget)
					end)
					f:SetPoint("TOPLEFT", parent.frame, "TOPRIGHT")
					f.status.top = f.frame:GetTop()
					f.status.left = f.frame:GetLeft()
				end
				selectModules(...)
			end
		end
		LUI.options.args.profiles.plugins = {
			LUI = {
				copyDesc = {
					order = 45,
					type = "description",
					name = "\nCopy the settings from the profile of only select modules into the currently active profile.",
				},
				copySettings = {
					order = 46,
					type = "select",
					name = "Copy From Select Modules",
					desc = "Copy the settings from the profile of only select modules into the currently active profile.",
					get = false,
					set = selectModules,
					values = "ListProfiles",
					disabled = "HasNoProfiles",
					arg = "nocurrent",
				},
			},
		}

		for k, v in pairs(moduleList) do
			LUI.options.args.Modules.args = LUI:MergeOptions(LUI.options.args.Modules.args, (type(v) == "function") and v() or v)
		end

		for k, v in pairs(moduleOptions) do
			LUI.options.args = LUI:MergeOptions(LUI.options.args, (type(v) == "function") and v() or v, true)
		end

		for k, v in pairs(newModuleOptions) do -- all modules need to be converted over to this
			local module = type(v) == "string" and LUI:Module(v) or v
			local options = type(module.LoadOptions) == "function" and module:LoadOptions() or module.options

			if options then
				LUI.options.args[module:GetName()] = module:NewGroup(module.optionsName or module:GetName(), module.order or 10, module.childGroups or "tab",
					module.getter or "skip", module.setter or "skip", false, function() return not module:IsEnabled() end, options)
			end
		end
	end

	-- Do a garbage collection, that was a LOT of tables and functions that got created
	collectgarbage("collect")

	return LUI.options
end

function LUI:RegisterOptions(module)
	table.insert(moduleOptions, module.LoadOptions)
end

function LUI:RegisterAddon(module, addon)
	if IsAddOnLoaded(addon) then
		LUI:RegisterOptions(module)
	end
end

function LUI:RegisterModule(module, moduledb, addFunc)
	local mName = module:GetName()
	moduledb = moduledb or mName

	table.insert(moduleList, {
		[mName] = {
			type = "execute",
			name = function() return (mName .. ": |cff" .. (db[moduledb].Enable and "00FF00Enabled" or "FF0000Disabled") .. "|r") end,
			order = 200,
			func = function()
				db[moduledb].Enable = not db[moduledb].Enable
				if db[moduledb].Enable then
					--module:Enable()
					if db.General.ModuleMessages then LUI:Print(mName.." Module Enabled") end
				else
					--module:Disable()
					if db.General.ModuleMessages then LUI:Print(mName.." Module Disabled") end
				end
				if addFunc ~= nil then addFunc() end

				StaticPopup_Show("RELOAD_UI") -- TODO: This can be removed once all the modules have an OnDisable function added and formatted correctly
			end,
		},
	})

	LUI:RegisterOptions(module)

	if LUI.defaultModuleState ~= false and db[moduledb].Enable ~= nil then
		module:SetEnabledState(db[moduledb].Enable)
	end
end

local function mergeOldDB(dest, src)
	if type(dest) ~= "table" then dest = {} end
	for k, v in pairs(src) do
		if type(v) == type(dest[k]) then
			if type(v) == "table" then
				dest[k] = mergeOldDB(dest[k], v)
			else
				dest[k] = v
			end
		end
	end
	return dest
end

function LUI:NewNamespace(module, enableButton, version)
	local mName = module:GetName()

	-- Add options loader function to list
	if not module.isNestedModule then
		table.insert(newModuleOptions, mName)
	end

	-- Register namespace
	local mdb = self.db:RegisterNamespace(mName, module.defaults)

	-- Create db metatable
	module.db = setmetatable({}, {
		__index = function(t, k)
			if mdb[k] then
				return mdb[k]
			else
				return mdb.profile[k]
			end
		end,
		__newindex = function(t, k, v)
			if mdb[k] then
				mdb[k] = v
			else
				mdb.profile[k] = v
			end
		end,
		__call = function(t, info, value)
			local dbloc = mdb.profile
			for i=2, #info-1 do
				dbloc = dbloc[info[i]]
				if type(dbloc) ~= "table" then
					error("Error accessing db:\nCould not access "..strjoin(".", info[1], "db.profile", unpack(info, 2, dbloc == nil and i or i+1)).."\ndb layout must be the same as info", 2)
				end
			end
			if value ~= nil then
				dbloc[info[#info]] = value
			else
				return dbloc[info[#info]]
			end
		end,
	})

	-- Create defaults metatable (the module.defaults table was handed off to AceDB and now exists as module.db.defaults)
	module.defaults = setmetatable({}, {
		__index = function(t, k)
			if mdb.defaults[k] then
				return mdb.defaults[k]
			else
				return mdb.defaults.profile[k]
			end
		end,
		__newindex = function(t, k, v)
			if mdb.defaults[k] then
				mdb.defaults[k] = v
			else
				mdb.defaults.profile[k] = v
			end
		end,
		__call = function(t, info, value)
			local dbloc = mdb.defaults.profile
			for i=2, #info-1 do
				dbloc = dbloc[info[i]]
				if type(dbloc) ~= "table" then
					error("Error accessing db:\nCould not access "..strjoin(".", info[1], "db.defaults.profile", unpack(info, 2, dbloc == nil and i or i+1)).."\ndb layout must be the same as info", 2)
				end
			end
			if value ~= nil then
				dbloc[info[#info]] = value
			else
				return dbloc[info[#info]]
			end
		end,
	})

	---[[	PROFILER
	-- Add module database metatable functions to profiler.
	Profiler.TraceScope(getmetatable(module.db), "db", "LUI."..mName)
	Profiler.TraceScope(getmetatable(module.defaults), "dbd", "LUI."..mName)
	--]]

	-- Look for outdated db vars and transfer them over
	if LUI.db.profile[mName] then
		mergeOldDB(module.db.profile, LUI.db.profile[mName])
		LUI.db.profile[mName] = nil
	end

	-- Set module enabled state
	if not self.enabledState or (module.addon and not IsAddOnLoaded(module.addon)) then
		module:SetEnabledState(false)
	elseif module.db.profile.Enable ~= nil then
		module:SetEnabledState(module.db.profile.Enable)
	end

	-- Hook conflicting addon checker
	if module.conflicts then
		LUI:RawHook(module, "OnEnable", LUI.CheckConflict)
	end

	-- Register Callbacks
	if type(module.Refresh) == "function" then
		module.db.RegisterCallback(module, "OnProfileChanged", LUI.RefreshModule, module)
		module.db.RegisterCallback(module, "OnProfileCopied", LUI.RefreshModule, module)
		module.db.RegisterCallback(module, "OnProfileReset", LUI.RefreshModule, module)
	end

	-- Create Enable button for module if applicable
	if enableButton then
		table.insert(moduleList, {
			[mName] = {
				type = "execute",
				name = function() return (mName .. ": |cff" .. (module:IsEnabled() and "00FF00Enabled" or "FF0000Disabled") .. "|r") end,
				desc = function() return ("Left Click: " .. (module:IsEnabled() and "Enable" or "Disable") .. " this module.\nShift Click: Reset modules settings.") end,
				func = function()
					if IsShiftKeyDown() then
						local enabled = module.db.profile.Enable
						module.db:ResetProfile()
						module.db.profile.Enable = enabled -- keep enabled/disabled state (callback from ResetProfile is based on modules enabled state, not the db var)

						if db.General.ModuleMessages then
							LUI:Print(mName .. " module settings reset.")
						end
					else
						module.db.profile.Enable = not module.db.profile.Enable
						if module[module.db.profile.Enable and "Enable" or "Disable"](module) then
							if db.General.ModuleMessages then
								LUI:Print(mName .. " module |cff" .. (module.db.profile.Enable and "00FF00enabled" or "FF0000disabled") .. "|r.")
							end
						else
							module.db.profile.Enable = module:IsEnabled()
						end
					end
				end,
			},
		})
	end

	-- Check for module version update
	if version and version ~= LUI.db.global.luiconfig[ProfileName].Versions[mName] then
		if module.OnVersionUpdate then
			module:OnVersionUpdate(LUI.db.global.luiconfig[ProfileName].Versions[mName], version)
		else
			module.db:ResetProfile()
		end
		LUI.db.global.luiconfig[ProfileName].Versions[mName] = version
	end

	return module.db, module.defaults
end

function LUI:Namespace(module, toggleButton, version) -- no metatables (note: do not use defaults.Enable for the enabled state, it is handled by the parent module)
	local mName = module:GetName()
	if self.db.children and self.db.children[mName] then return module.db.profile, module.db.defaults.profile end

	-- Add options loader function to list
	if not module.isNestedModule and (not module.addon or IsAddOnLoaded(module.addon)) then
		table.insert(newModuleOptions, mName)
	end

	-- Register namespace
	module.db = LUI.db.RegisterNamespace(self.db, mName, module.defaults)

	-- Look for outdated db vars and transfer them over
	if self.db.profile[mName] then
		mergeOldDB(module.db.profile, self.db.profile[mName])
		self.db.profile[mName] = nil
	end

	-- Create modules table in parent's db if it doesn't exist already
	self.db.profile.modules = self.db.profile.modules or {}

	-- Look for incorrect Enable var usage
	if rawget(module.db.profile, "Enable") ~= nil then
		if rawget(module.db.defaults.profile, "Enable") ~= nil then
			module:SetEnabledState(false)
			error(format("Incorrect use of Enable db var in %s", tostring(module)), 2)
		elseif self.db.profile.modules[mName] == nil then -- old var in user's SavedVariables (move it over)
			self.db.profile.modules[mName] = module.db.profile.Enable
		end
		module.db.profile.Enable = nil
	end

	-- Set Enabled state
	if not self.enabledState or (module.addon and not IsAddOnLoaded(module.addon)) then
		module:SetEnabledState(false)
	elseif self.db.profile.modules[mName] ~= nil then
		module:SetEnabledState(self.db.profile.modules[mName])
	elseif module.defaultState ~= nil then
		module:SetEnabledState(module.defaultState)
		self.db.profile.modules[mName] = module.defaultState
	end

	if not module.isNestedModule then
		-- Hook conflicting addon checker
		if module.conflicts then
			LUI:RawHook(module, "OnEnable", LUI.CheckConflict)
		end

		-- Register DB Callbacks
		if type(module.DBCallback) == "function" then
			module.db.RegisterCallback(module, "OnProfileChanged", "DBCallback")
			module.db.RegisterCallback(module, "OnProfileCopied", "DBCallback")
			module.db.RegisterCallback(module, "OnProfileReset", "DBCallback")
		end

		-- Create toggle button
		if toggleButton then
			table.insert(moduleList, {
				[mName] = {
					type = "execute",
					name = function() return format("%s: |cff%s|r", module.optionsName or mName, module:IsEnabled() and "00FF00Enabled" or "FF0000Disabled") end,
					desc = "Left Click: Toggle between Enabled and Disabled.\nShift Click: Reset module's settings.",
					func = function()
						if IsShiftKeyDown() then
							module.db:ResetProfile()

							if db.General.ModuleMessages then
								LUI:Printf("%s module settings reset.", module.optionsName or mName)
							end
						elseif module:Toggle() then
							if db.General.ModuleMessages then
								LUI:Printf("%s module |cff%s|r", module.optionsName or mName, module:IsEnabled() and "00FF00enabled" or "FF0000disabled")
							end
						end
					end,
				},
			})
		end
	end

	-- Check for module version update
	if version and version ~= self.db.global.luiconfig[ProfileName].Versions[mName] then
		if module.OnVersionUpdate then
			module:OnVersionUpdate(self.db.global.luiconfig[ProfileName].Versions[mName], version)
		else
			module.db:ResetProfile()
		end
		LUI.db.global.luiconfig[ProfileName].Versions[mName] = version
	end

	return module.db.profile, module.db.defaults.profile
end


------------------------------------------------------
-- / SETUP LUI / --
------------------------------------------------------

function LUI:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LUIDB", LUI.defaults, true)
	db_ = self.db.profile

	_G.LUICONFIG = _G.LUICONFIG or {}
	_G.LUICONFIG.Versions = _G.LUICONFIG.Versions or {}

	if self.db.global.luiconfig[ProfileName] and self.db.global.luiconfig[ProfileName].IsConfigured then
		if self.db.global.luiconfig[ProfileName].Versions.lui ~= LUI.Versions.lui then
			self:Disable()
			self:Update()
		else
			self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
			self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
			self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

			self:RegisterChatCommand(addonname, "ChatCommand")

			self:RegisterEvent("ADDON_LOADED", "SetDamageFont", self)
			self:LoadExtraModules()
		end
	elseif _G.LUICONFIG.IsConfigured then
		self.db.global.luiconfig[ProfileName] = CopyTable(_G.LUICONFIG)
		if self.db.global.luiconfig[ProfileName].IsConfigured then
		  wipe(_G.LUICONFIG)
		end
	else
		self.db.global.luiconfig[ProfileName] = {
			Versions = {},
		}
		self:Disable()
		self.db:SetProfile(ProfileName)
		self:Configure()
	end

	StaticPopupDialogs["RELOAD_UI"] = { -- TODO: Remove all need for this
		preferredIndex = 3,
		text = L["The UI needs to be reloaded!"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = ReloadUI,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}

	StaticPopupDialogs["RESTORE_DETAULTS"] = {
		preferredIndex = 3,
		text = "Do you really want to restore all defaults. All your settings will be lost!",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = Configure,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}
end

function LUI:OnEnable()
	db_ = self.db.profile
	--CheckResolution()

--	print(" ")
--	print("Welcome to |c0090ffffLUI v3|r for Patch 3.3.5 !")
--	print("For more Information visit lui.maydia.org")

	self:SyncAddonVersion()
end

function LUI:MergeDefaults(target, source)
	if type(target) ~= "table" then target = {} end
	for k, v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:MergeDefaults(target[k], v)
		elseif not target[k] then
			target[k] = v
		end
	end
	return target
end

function LUI:RefreshDefaults()
	self.db:RegisterDefaults(LUI.defaults)
end

function LUI:Refresh(dbEvent)
	db_ = self.db.profile

	if not IsLoggedIn() then return end -- in case db callbacks fire before the OnEnable function

	if dbEvent then -- remove once all modules are using namespaces
		return ReloadUI()
	end

	for name, module in self:IterateModules() do
		if module.db and module.db.profile and module.db.profile.Enable ~= nil then
			module[module.db.profile.Enable and "Enable" or "Disable"](module)
		end
	end
end

function LUI:RefreshModule(...) -- LUI.RefreshModule(module, callback_event, db, ...)
	if AceAddon.statuses[self.name] then -- check if self is enabled and if OnEnable script has ran
		self:Refresh(...)
	end
end

local optionsLoaded = false
function LUI:Open(force, ...)
	function LUI:Open(force, ...)
		if ACD.OpenFrames.LUI and not force then
			ACD:Close(addonname)
		else
			-- Do not open options in combat unless already opened before.
			if InCombatLockdown() and not optionsLoaded then
			--Find a better way to word this.
				LUI:Print("Unable to open the options for the first time while in combat.")
			else
				ACD:Open(addonname, nil, ...)
				ACD.OpenFrames.LUI.frame:SetScale(db.General.BlizzFrameScale)
				--ACD.OpenFrames.LUI:SetCallback("OnClose", function(widget, event)
				--	widget.frame:SetScale(1)
				----	local appName = widget:GetUserData("appName")
				--	ACD.OpenFrames[appName] = nil
				--	LibStub("AceGUI-3.0"):Release(widget)
				--end)
				optionsLoaded = true
			end
		end
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonname, getOptions)
	ACD:SetDefaultSize(addonname, 720,525)

	local function refreshOptions()
		if ACD.OpenFrames.LUI then
			ACR:NotifyChange(addonname)
		end
	end
	self:RegisterEvent("PLAYER_REGEN_ENABLED", refreshOptions)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", refreshOptions)

	return LUI:Open(force, ...)
end

LUI.chatcommands = {
	["debug"] = "Debug",
	["config"] = "Open",
	["install"] = "Configure",
}

function LUI:ChatCommand(input)
	if not input or input:trim() == "" then
		self:Open()
	else
		local arg = self:GetArgs(input)
		local cmd = arg and LUI.chatcommands[arg:lower()] or nil
		if cmd then
			if type(cmd) == "function" then
				cmd()
			else
				self[cmd](self)
			end
		elseif arg then
			self:Print("Unknown command: "..arg)
		end
	end
end
