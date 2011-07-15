--[[
	Project.: LUI NextGenWoWUserInterface
	File....: LUI.lua
	Version.: 3.403
	Rev Date: 13/02/2011
	Author..: Louí [EU-Das Syndikat] <In Fidem>
]] 

local _, ns = ...
oUF = ns.oUF or oUF

local AceAddon = LibStub("AceAddon-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
LUI = AceAddon:NewAddon("LUI", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceSerializer-3.0") -- localize
local LUIHook = LUI:NewModule("LUIHook", "AceHook-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

LUI.oUF = {}

LUI.dummy = function() return end

-- REGISTER FONTS
LSM:Register("font", "vibrocen", [[Interface\Addons\LUI\media\fonts\vibrocen.ttf]])
LSM:Register("font", "vibroceb", [[Interface\Addons\LUI\media\fonts\vibroceb.ttf]])
LSM:Register("font", "Prototype", [[Interface\Addons\LUI\media\fonts\prototype.ttf]])
LSM:Register("font", "neuropol", [[Interface\AddOns\LUI\media\fonts\neuropol.ttf]])
LSM:Register("font", "AvantGarde_LT_Medium", [[Interface\AddOns\LUI\media\fonts\AvantGarde_LT_Medium.ttf]])
LSM:Register("font", "Arial Narrow", [[Interface\AddOns\LUI\media\fonts\ARIALN.TTF]])
LSM:Register("font", "Pepsi", [[Interface\AddOns\LUI\media\fonts\pepsi.ttf]])

-- REGISTER BORDERS
LSM:Register("border", "glow", [[Interface\Addons\LUI\media\textures\borders\glow.tga]])
LSM:Register("border", "Stripped", [[Interface\Addons\LUI\media\textures\borders\Stripped.tga]])
LSM:Register("border", "Stripped_hard", [[Interface\Addons\LUI\media\textures\borders\Stripped_hard.tga]])
LSM:Register("border", "Stripped_medium", [[Interface\Addons\LUI\media\textures\borders\Stripped_medium.tga]])

-- REGISTER STATUSBARS
LSM:Register("statusbar", "oUF LUI", [[Interface\AddOns\LUI\media\textures\statusbars\oUF_LUI.tga]])
LSM:Register("statusbar", "LUI_Gradient", [[Interface\AddOns\LUI\media\textures\statusbars\gradient32x32.tga]])
LSM:Register("statusbar", "LUI_Minimalist", [[Interface\AddOns\LUI\media\textures\statusbars\Minimalist.tga]])
LSM:Register("statusbar", "LUI_Ruben", [[Interface\AddOns\LUI\media\textures\statusbars\Ruben.tga]])
LSM:Register("statusbar", "Smelly", [[Interface\AddOns\LUI\media\textures\statusbars\Smelly.tga]])
LSM:Register("statusbar", "Neal", [[Interface\AddOns\LUI\media\textures\statusbars\Neal]])
LSM:Register("statusbar", "RenaitreMinion", [[Interface\AddOns\LUI\media\textures\statusbars\RenaitreMinion.tga]])

LUI_Media = {
	["blank"] = [[Interface\AddOns\LUI\media\textures\blank]],
	["normTex"] = [[Interface\AddOns\LUI\media\textures\statusbars\normTex]], -- texture used for nameplates healthbar
	["glowTex"] = [[Interface\AddOns\LUI\media\textures\statusbars\glowTex]], -- the glow texture around some frame.
	["chatcopy"] = [[Interface\AddOns\LUI\media\textures\icons\chatcopy]], -- the copy icon in your chatframe.
	["cross"] = [[Interface\AddOns\LUI\media\textures\icons\cross]], -- Worldmap Move Button.
	["party"] = [[Interface\AddOns\LUI\media\textures\icons\Party]], -- Worldmap Party Icon.
	["raid"] = [[Interface\AddOns\LUI\media\textures\icons\Raid]], -- Worldmap Raid Icon.
	["mail"] = [[Interface\AddOns\LUI\media\textures\icons\mail]], -- Minimap Mail Icon.
	["btn_normal"] = [[Interface\AddOns\LUI\media\textures\buttons\Normal]], -- Standard Button Texture example: Auras
	["btn_border"] = [[Interface\AddOns\LUI\media\textures\buttons\Border]], -- Button Border
	["btn_gloss"] = [[Interface\AddOns\LUI\media\textures\buttons\Gloss]], -- Button Overlay
}

LUI_ModuleCount = 0

local screen_height = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")
local screen_width = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "(%d+)x%d+")
local _, class = UnitClass("player")
local hooks = { }

LUI_versions = {
	lui = 3403,
	grid = 3300,
	bartender = 3300,
	omen = 3300,
	recount = 3300,
	forte = 3300,
}

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
			AutoInviteKeyword = "",
			AutoAcceptInvite = false,
			BlizzFrameScale = 1,
			ModuleMessages = true,
			DamageFont = "neuropol",
			DamageFontSize = 25,
			DamageFontSizeCrit = 34,
		},
		Recount = {
			FontHack = true,
			FontSize = 13,
		},
	}
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

function CheckResolution()
	local ScreenWidth = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "(%d+)x%d+")
	local ScreenHeight = string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")
	
	if ScreenWidth == "1280" and ScreenHeight == "1024" then
		-- Repostion Info Texts
		LUI.defaults.profile.Infotext.Bags.X = -100
		LUI.defaults.profile.Infotext.Armor.X = 10
		LUI.defaults.profile.Infotext.Fps.X = 120
		LUI.defaults.profile.Infotext.Memory.X = 190
		
		LUI.defaults.profile.Frames.Dps.X = -968
		LUI.defaults.profile.Frames.Dps.Y = 863
		
		LUI.defaults.profile.Frames.Tps.X = 5
		LUI.defaults.profile.Frames.Tps.Y = 882
		
		-- Repositon Auras
		LUI.defaults.profile.Auras.Spacing = "-12"
		LUI.defaults.profile.Auras.Anchor = "TOPRIGHT"
		LUI.defaults.profile.Auras.Growth = "LEFT"
		LUI.defaults.profile.Auras.Buffs.X = "-170"
		LUI.defaults.profile.Auras.Buffs.Y = "-75"
		LUI.defaults.profile.Auras.Debuffs.X = "-170"
		LUI.defaults.profile.Auras.Debuffs.Y = "-185"
	end
end

local function RGBToHex(r, g, b)
	r = r <= 255 and r >= 0 and r or 0
	g = g <= 255 and g >= 0 and g or 0
	b = b <= 255 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r, g, b)
end

local moduleCount = 0
function LUI:GetModuleCount()
	moduleCount = moduleCount + 2
	return moduleCount
end

function LUI:Kill(object)
	object.Show = LUI.dummy
	object:Hide()
end

local function scale(x)
	scaleUI = UIParent:GetEffectiveScale()
	mult = 768/screen_height/scaleUI
	LUI.mult = mult
	return mult*math.floor(x/mult+.5)
end

function LUI:Scale(x) return scale(x) end

function LUI:CreatePanel(f, w, h, a1, p, a2, x, y)
	sh = scale(h)
	sw = scale(w)
	f:SetFrameLevel(1)
	f:SetHeight(sh)
	f:SetWidth(sw)
	f:SetFrameStrata("BACKGROUND")
	f:SetPoint(a1, p, a2, x, y)
	f:SetBackdrop({
	  bgFile = LUI_Media.blank, 
	  edgeFile = LUI_Media.blank, 
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
	hover:SetTexture(1,1,1,0.2)
	hover:SetHeight(button:GetHeight())
	hover:SetWidth(button:GetWidth())
	hover:SetPoint("TOPLEFT",button,2,-2)
	hover:SetPoint("BOTTOMRIGHT",button,-2,2)
	button:SetHighlightTexture(hover)

	local pushed = b:CreateTexture("frame", nil, self) -- pushed
	pushed:SetTexture(0.9,0.8,0.1,0.3)
	pushed:SetHeight(button:GetHeight())
	pushed:SetWidth(button:GetWidth())
	pushed:SetPoint("TOPLEFT",button,2,-2)
	pushed:SetPoint("BOTTOMRIGHT",button,-2,2)
	button:SetPushedTexture(pushed)
	
	count:SetFont(LSM:Fetch("font", db.Infotext.Fps.Font), db.Infotext.Fps.Size, "OUTLINE")
 
	if checked then
		local checked = b:CreateTexture("frame", nil, self) -- checked
		checked:SetTexture(0,1,0,0.3)
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

function LUI:ClearFrames(frameList)
	--[[if not frameList then return end
	
	for _, frame in pairs(frameList) do
		if _G[frame] then
			for i=1, _G[frame]:GetNumRegions() do
				local region = select(i, _G[frame]:GetRegions()):GetName()
				if region then
					_G[region]:Hide()
					_G[region] = nil
				end
			end
			for i=1, _G[frame]:GetNumChildren() do
				local child = select(i, _G[frame]:GetChildren())
				if child then
					LUI:ClearFrames({child:GetName()})
				end
			end
			_G[frame]:UnregisterAllEvents()
			_G[frame]:SetScript("OnUpdate", nil)
			_G[frame]:Hide()
			_G[frame]:SetParent(nil)
			_G[frame] = nil
		end
	end
	collectgarbage()]]
end

------------------------------------------------------
-- / SET DAMAGE FONT / --
------------------------------------------------------

SetDamageFont = CreateFrame("Frame", "SetDamageFont");
SetDamageFont:RegisterEvent("ADDON_LOADED")
SetDamageFont:SetScript("OnEvent", function(self)
	SetDamageFont:ApplyDamageFont()
end)

function SetDamageFont:ApplyDamageFont()
	local DamageFont = LSM:Fetch("font", db.General.DamageFont)

	COMBAT_TEXT_SCROLLSPEED = 1.9
	COMBAT_TEXT_FADEOUT_TIME = 1.3 
	DAMAGE_TEXT_FONT = DamageFont
	COMBAT_TEXT_HEIGHT = db.General.DamageFontSize
	COMBAT_TEXT_CRIT_MAXHEIGHT = db.General.DamageFontSizeCrit
	COMBAT_TEXT_CRIT_MINHEIGHT = db.General.DamageFontSizeCrit - 2
end

------------------------------------------------------
-- / SET BLIZZARD FRAME SIZES / --
------------------------------------------------------

local function SetBlizzFrameSizes()
	local blizzFrames = {
		CalendarFrame,
		CharacterFrame,
		DressUpFrame,
		ItemSocketingFrame,
		SpellBookFrame,
		PlayerTalentFrame,
		QuestLogFrame,
		QuestFrame,
		QuestLogDetailFrame,
		ArchaeologyFrame,
		GossipFrame,
		AchievementFrame,
		MerchantFrame,
		TradeFrame,
		MailFrame,
		OpenMailFrame,
		TradeSkillFrame,
		ClassTrainerFrame,
		ReforgingFrame,
		LookingForGuildFrame,
		GuildFrame,
		FriendsFrame,
		PVPFrame,
		LFDParentFrame,
		LFRParentFrame,
		HelpFrame,
		MacroFrame,
		GameMenuFrame,
		VideoOptionsFrame,
		InterfaceOptionsFrame,
		KeyBindingFrame,
	}
	
	for _, frame in pairs(blizzFrames) do
		if frame then frame:SetScale(db.General.BlizzFrameScale) end
	end
	
	if AuctionFrame and not IsAddOnLoaded("Auc-Advanced") then
		AuctionFrame:SetScale(db.General.BlizzFrameScale)
	end
end

------------------------------------------------------
-- / HIDE TALENT CHANGE SPAM / --
------------------------------------------------------

local function HideTalentSpam()
	if not LUI:IsHooked("SetActiveTalentGroup") then
		local spam1 = gsub(ERR_LEARN_ABILITY_S:gsub("%.", "%."), "%%s", "(.*)")
		local spam2 = gsub(ERR_LEARN_SPELL_S:gsub("%.", "%."), "%%s", "(.*)")
		local spam3 = gsub(ERR_SPELL_UNLEARNED_S:gsub("%.", "%."), "%%s", "(.*)")
		
		local function SpamFilter(self, event, msg)
			if strfind(msg, spam1) or strfind(msg, spam2) or strfind(msg, spam3) then return true end
		end
		
		local function clearSpam(event, unit)
			if unit ~= "player" then return end
			LUI:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
			LUI:UnregisterEvent("UNIT_SPELLCAST_STOP")
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", SpamFilter)
		end
		
		local function SetActiveTalentGroupSpamFree(...)
			if db.General.HideTalentSpam == true then
				LUI:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", clearSpam)
				LUI:RegisterEvent("UNIT_SPELLCAST_STOP", clearSpam)
				ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SpamFilter)
			end
			return LUI.hooks.SetActiveTalentGroup(...)
		end
		
		LUI:RawHook("SetActiveTalentGroup", SetActiveTalentGroupSpamFree, true)
	end
end

------------------------------------------------------
-- / UPDATE / --
------------------------------------------------------

function LUI:Update()
	local updateBG = LUI:CreateMeAFrame("FRAME","updateBG",UIParent,2400,2000,1,"HIGH",5,"CENTER",UIParent,"CENTER",0,0,1)
	updateBG:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	updateBG:SetBackdropColor(0,0,0,1)
	updateBG:SetBackdropBorderColor(0,0,0,0)
	updateBG:SetAlpha(1)
	updateBG:Show() 
	
	local updatelogo = LUI:CreateMeAFrame("FRAME","updatelogo",UIParent,512,512,1,"HIGH",6,"CENTER",UIParent,"CENTER",0,150,1)
	updatelogo:SetBackdrop({bgFile=fdir.."logo", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	updatelogo:SetBackdropBorderColor(0,0,0,0)
	updatelogo:Show()
	
	local update = LUI:CreateMeAFrame("FRAME","update",updatelogo,512,512,1,"HIGH",6,"BOTTOM",updatelogo,"BOTTOM",0,-130,1)
	update:SetBackdrop({bgFile=fdir.."update", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	update:SetBackdropColor(1,1,1,1)
	update:SetBackdropBorderColor(0,0,0,0)
	update:Show()
	
	local update_hover = LUI:CreateMeAFrame("FRAME","update_hover",updatelogo,512,512,1,"HIGH",7,"BOTTOM",updatelogo,"BOTTOM",0,-130,1)
	update_hover:SetBackdrop({bgFile=fdir.."update_hover", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	update_hover:SetBackdropColor(1,1,1,1)
	update_hover:SetBackdropBorderColor(0,0,0,0)
	update_hover:Hide()
	
	local update_frame = LUI:CreateMeAFrame("BUTTON","update_frame",updatelogo,310,80,1,"HIGH",8,"BOTTOM",updatelogo,"BOTTOM",-5,90,1)
	update_frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
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
			LUICONFIG.Versions.grid = nil
			LUI:InstallGrid()
		end
		
		if IsAddOnLoaded("Recount") then
			LUICONFIG.Versions.recount = nil
			LUI:InstallRecount()
		end
		
		if IsAddOnLoaded("Omen") or IsAddOnLoaded("Omen3") then
			LUICONFIG.Versions.omen = nil
			LUI:InstallOmen()
		end
		
		if IsAddOnLoaded("Forte_Core") then
			LUICONFIG.Versions.forte = nil
			LUI:InstallForte()
		end
	
		LUICONFIG.Versions.lui = LUI_versions.lui
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
	configureBG:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	configureBG:SetBackdropColor(0,0,0,1)
	configureBG:SetBackdropBorderColor(0,0,0,0)
	configureBG:SetAlpha(1)
	configureBG:Show() 
	
	local logo = LUI:CreateMeAFrame("FRAME","logo",UIParent,512,512,1,"HIGH",6,"CENTER",UIParent,"CENTER",0,150,1)
	logo:SetBackdrop({bgFile=fdir.."logo", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	logo:SetBackdropBorderColor(0,0,0,0)
	logo:Show()
	
	local install = LUI:CreateMeAFrame("FRAME","install",logo,512,512,1,"HIGH",6,"BOTTOM",logo,"BOTTOM",0,-130,1)
	install:SetBackdrop({bgFile=fdir.."install", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	install:SetBackdropColor(1,1,1,1)
	install:SetBackdropBorderColor(0,0,0,0)
	install:Show()
	
	local install_hover = LUI:CreateMeAFrame("FRAME","install_hover",logo,512,512,1,"HIGH",7,"BOTTOM",logo,"BOTTOM",0,-130,1)
	install_hover:SetBackdrop({bgFile=fdir.."install_hover", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	install_hover:SetBackdropColor(1,1,1,1)
	install_hover:SetBackdropBorderColor(0,0,0,0)
	install_hover:Hide()
	
	local install_frame = LUI:CreateMeAFrame("BUTTON","install_frame",logo,310,80,1,"HIGH",8,"BOTTOM",logo,"BOTTOM",-5,90,1)
	install_frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
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
		SetCVar("consolidateBuffs", 0)
		SetCVar("scriptErrors", 1)
		SetCVar("uiScale", 0.6949)
		SetCVar("useUiScale", 1)
		SetCVar("chatMouseScroll", 1)
		SetCVar("chatStyle", "classic")
		
		if LUICONFIG.Versions ~= nil then
			for k,v in pairs(LUICONFIG.Versions) do
				LUICONFIG.Versions[k] = nil
			end
		end
		
		LUI:InstallGrid()
		LUI:InstallRecount()
		LUI:InstallOmen()
		LUI:InstallBartender()
		LUI:InstallForte()

		LUICONFIG.Versions.lui = LUI_versions.lui
		LUICONFIG.IsConfigured = true
		ReloadUI()
	end)
end

------------------------------------------------------
-- / OPTIONS MENU / --
------------------------------------------------------

local options, moduleList, moduleOptions, frameOptions, unitframeOptions = nil, {}, {}, {}, {}

function LUI:MergeOptions(target, source, sort)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(target) do
		if k == "type" and v ~= "group" then
			target = {}
			break
		end
	end
	for k,v in pairs(source) do
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
									name = "Welcome to |c0090ffffLUI v3|r the first and only NextGeneration\nWorld of Warcraft User Interface.\n\nPlease read the FAQ if you have Questions!\nFor more information please visit\n|cff8080ffhttp://www.wow-lui.com|r\n|cff8080ffhttp://wowinterface.com|r\n\nEnjoy!\n\n\n|r",
								},
								VerText = {
									order = 4,
									width = "full",
									type = "description",
									name = "Version: "..GetAddOnMetadata("LUI", "Version"),
								},
								RevText = {
									order = 5,
									width = "full",
									type = "description",
									name = function()
											if GetAddOnMetadata("LUI", "X-Curse-Packaged-Version") then 
												return "Revision: "..GetAddOnMetadata("LUI", "X-Curse-Packaged-Version") 
											else	return "Revision: ???"
											end
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
									name = "LUI will show automaticly all Frames which were shown after logging out.\n\nYou can set some Rules here that LUI should always show some Frames regardless of how you are logging off."
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
									get = function() return db.Frames.AlwaysShowMinimap end,
									set = function()
												db.Frames.AlwaysShowMinimap = not db.Frames.AlwaysShowMinimap
											end,
									order = 6,
								},
								alwaysShowChat = {
									name = "Show Chat",
									desc = "Whether you want to show the Chat by entering World or not.\n",
									type = "toggle",
									get = function() return db.Frames.AlwaysShowChat end,
									set = function()
												db.Frames.AlwaysShowChat = not db.Frames.AlwaysShowChat
											end,
									order = 7,
								},
								alwaysShowOmen = {
									name = "Show Omen",
									desc = "Whether you want to show Omen by entering World or not.\n",
									type = "toggle",
									get = function() return db.Frames.AlwaysShowOmen end,
									set = function()
												db.Frames.AlwaysShowOmen = not db.Frames.AlwaysShowOmen
											end,
									order = 8,
								},
								alwaysShowRecount = {
									name = "Show Recount",
									desc = "Whether you want to show Recount by entering World or not.\n",
									type = "toggle",
									get = function() return db.Frames.AlwaysShowRecount end,
									set = function()
												db.Frames.AlwaysShowRecount = not db.Frames.AlwaysShowRecount
											end,
									order = 9,
								},
								alwaysShowGrid = {
									name = "Show Grid",
									desc = "Whether you want to show Grid by entering World or not.\n",
									type = "toggle",
									get = function() return db.Frames.AlwaysShowGrid end,
									set = function()
												db.Frames.AlwaysShowGrid = not db.Frames.AlwaysShowGrid
											end,
									order = 10,
								},
								alwaysShowMicroMenu = {
									name = "Show MicroMenu",
									desc = "Whether you want to show the Micromenu by entering World or not.\n",
									type = "toggle",
									get = function() return db.Frames.AlwaysShowMicroMenu end,
									set = function()
												db.Frames.AlwaysShowMicroMenu = not db.Frames.AlwaysShowMicroMenu
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
									set = function(self, scale)
											if scale == nil or scale == "" then
												scale = 1
											end
											db.General.BlizzFrameScale = scale
											SetBlizzFrameSizes()
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
									set = function()
											db.General.HideErrors = not db.General.HideErrors
											StaticPopup_Show("RELOAD_UI")
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
									set = function()
											db.General.AutoAcceptInvite = not db.General.AutoAcceptInvite
										end,
									order = 37,
								},
								AutoInvite = {
									name = "Enable Autoinvite",
									desc = "Choose if you want to Enable Autoinvite or not.",
									type = "toggle",
									width = "full",
									get = function() return db.General.Autoinvite end,
									set = function()
											db.General.Autoinvite = not db.General.Autoinvite
										end,
									order = 38,
								},
								AutoInviteKeyword = {
									name = "Auto Invite Keyword",
									desc = "Choose any Keyword for Auto Invite",
									type = "input",
									disabled = function() return not db.General.Autoinvite end,
									get = function() return db.General.AutoInviteKeyword end,
									set = function(self,AutoInviteKeyword)
												if AutoInviteKeyword == nil or AutoInviteKeyword == "" then
													AutoInviteKeyword = ""
												end
												db.General.AutoInviteKeyword = AutoInviteKeyword
											end,
									order = 39,
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
										LUICONFIG.Versions.bartender = nil
										LUI:InstallBartender()
										StaticPopup_Show("RELOAD_UI")
									end,
								},
								ResetForte = {
									order = 2,
									type = "execute",
									name = "Restore ForteXorcist",
									func = function()
										LUICONFIG.Versions.forte = nil
										LUI:InstallForte()
										StaticPopup_Show("RELOAD_UI")
									end,
								},
								ResetGrid = {
									order = 2,
									type = "execute",
									name = "Restore Grid",
									func = function()
										LUICONFIG.Versions.grid = nil
										LUI:InstallGrid()
										StaticPopup_Show("RELOAD_UI")
									end,
								},
								ResetOmen = {
									order = 2,
									type = "execute",
									name = "Restore Omen",
									func = function()
										LUICONFIG.Versions.omen = nil
										LUI:InstallOmen()
										StaticPopup_Show("RELOAD_UI")
									end,
								},
								ResetRecount = {
									order = 2,
									type = "execute",
									name = "Restore Recount",
									func = function()
										LUICONFIG.Versions.recount = nil
										LUI:InstallRecount()
										StaticPopup_Show("RELOAD_UI")
									end,
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
									min = 6,
									max = 32,
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
								Header3 = {
									name = "Restore ALL Addon Defaults",
									type = "header",
									order = 6,
								},
								ResetDesc = {
									order = 7,
									width = "full",
									type = "description",
									name = "ATTENTION:\nAll SavedVariables from Grid, Recount, Omen, Bartender and ForteXorcist will be resetted!"
								},
								Reset = {
									order = 8,
									type = "execute",
									name = "Restore Defaults",
									func = function()
										StaticPopup_Show("RESTORE_DETAULTS")
									end,
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
					},
				},
			},
		}
		LUI.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LUI.db)
		LUI.options.args.profiles.order = 4
		
		for k,v in pairs(moduleList) do
			LUI.options.args.Modules.args = LUI:MergeOptions(LUI.options.args.Modules.args, (type(v) == "function") and v() or v)
		end
		
		for k,v in pairs(moduleOptions) do
			LUI.options.args = LUI:MergeOptions(LUI.options.args, (type(v) == "function") and v() or v, true)
		end
		
		for k,v in pairs(frameOptions) do
			LUI.options.args.Frames.args = LUI:MergeOptions(LUI.options.args.Frames.args, (type(v) == "function") and v() or v)
		end
		
		for k,v in pairs(unitframeOptions) do
			LUI.options.args.UnitFrames.args = LUI:MergeOptions(LUI.options.args.UnitFrames.args, (type(v) == "function") and v() or v)
		end
	end
	
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

function LUI:RegisterUnitFrame(module)
	table.insert(unitframeOptions, module.LoadOptions)
end

function LUI:RegisterFrame(module)
	table.insert(frameOptions, module.LoadOptions)
end

function LUI:RegisterModule(module, moduledb, addFunc)
	local mName = module:GetName()
	local moduledb = moduledb and moduledb or mName
	
	table.insert(moduleList, {
		[mName] = {
			type = "execute",
			name = function()
				if db[moduledb].Enable then
					return "|cff00FF00"..mName.." Enabled|r"
				else
					return "|cffFF0000"..mName.." Disabled|r"
				end
			end,
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
				--LUI:Print("The reload UI in the LUI:RegisterModule function can be removed once all the modules have an OnDisable function added and formatted correctly")
				StaticPopup_Show("RELOAD_UI")
			end,
		},
	})
	
	LUI:RegisterOptions(module)
	
	module:SetEnabledState(db[moduledb].Enable)
end

------------------------------------------------------
-- / SETUP LUI / --
------------------------------------------------------

function LUI:OnEnable()
	db_ = self.db.profile
	local isAllShown = false
	CheckResolution()
	
	SLASH_RELOADUI1 = "/rl"
	SlashCmdList.RELOADUI = ReloadUI
	
	fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"
	
	if LUICONFIG.IsConfigured == false then
		self.db:SetProfile(UnitName("player").." - "..GetRealmName())
		self:Configure()
	else
		if LUICONFIG.Versions.lui ~= LUI_versions.lui then
			self:Update()
		else
			local CharName = UnitName("player")
			
			SetDamageFont:ApplyDamageFont()
			
			local LoginMsg = false
			if(LoginMsg==true) then
				print(" ")
				print("Welcome on |c0090ffffLUI v3|r for Patch 3.3.5 !")
				print("For more Information visit www.wow-lui.com")
			end
		end
	end
	
	LUI:RegisterEvent("ADDON_LOADED", function(event, name)
		if strsub(name, 1, 8) == "Blizzard" then SetBlizzFrameSizes() end
	end)
	SetBlizzFrameSizes()
	HideTalentSpam()
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:Hide()
	CompactRaidFrameContainer:UnregisterEvent("RAID_ROSTER_UPDATE")
	CompactRaidFrameContainer:UnregisterEvent("UNIT_PET")
	CompactRaidFrameContainer:Hide()
end

function LUI:OnInitialize()
	
	self.db = LibStub("AceDB-3.0"):New("LUIDB", LUI.defaults, true)
	db_ = self.db.profile
	LUI_DB = self.db.profile
	
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	
	self.elementsToHide = {}
	
	self:SetupOptions()
	
	LUICONFIG = LUICONFIG or {}
	if LUICONFIG.IsConfigured == nil then
		LUICONFIG.IsConfigured = false
	end
	
	LUIGold = LUIGold or {}
	
	if LUICONFIG.Versions == nil then
		versiondefaults = {
			lui = 0,
			theme = 0,
			grid = 0,
			bartender = 0,
			omen = 0,
			recount = 0,
			forte = 0,
		}

		LUICONFIG.Versions = versiondefaults
	end
	
	StaticPopupDialogs["RELOAD_UI"] = {
		text = "The UI needs to be reloaded!",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = ReloadUI,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}
	
	StaticPopupDialogs["RESTORE_DETAULTS"] = {
		text = "Do you really want to restore all defaults. All your settings will be lost!",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = Configure,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}
	
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:Hide()
	CompactRaidFrameContainer:UnregisterEvent("RAID_ROSTER_UPDATE")
	CompactRaidFrameContainer:UnregisterEvent("UNIT_PET")
	CompactRaidFrameContainer:Hide()
end

function LUI:MergeDefaults(target, source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
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

function LUI:Refresh()
	db_ = self.db.profile

	for k,v in self:IterateModules() do
		if k ~= "Position" then
			if type(v.Refresh) == "function" then
				v:Refresh()
			end
		end
	end
end

function LUI:Open(force)
	function LUI:Open(force)
		if AceConfigDialog.OpenFrames.LUI and not force then
			AceConfigDialog:Close("LUI")
		else
			AceConfigDialog:Open("LUI")
			AceConfigDialog.OpenFrames.LUI.frame:SetScale(db.General.BlizzFrameScale)
			AceConfigDialog.OpenFrames.LUI:SetCallback("OnClose", function(widget, event)
				widget.frame:SetScale(1)
				local appName = widget:GetUserData("appName")
				AceConfigDialog.OpenFrames[appName] = nil
				LibStub("AceGUI-3.0"):Release(widget)
			end)
		end
	end
	
	self.optionsFrames = {}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LUI", getOptions)
	AceConfigDialog:SetDefaultSize("LUI", 720,525)
	
	return LUI:Open(force)
end

function LUI:ChatCommand(input)
	if not input or input:trim() == "" then
		LUI:Open()
	else
		LibStub("AceConfigCmd-3.0").HandleCommand(LUI, "lui", "LUI", input)
	end
end

function LUI:SetupOptions()
	--self.optionsFrames = {}
	--LibStub("AceConfig-3.0"):RegisterOptionsTable("LUI", getOptions)
	
	--AceConfigDialog:SetDefaultSize("LUI", 720,525)
	self:RegisterChatCommand( "lui", "ChatCommand")
	self:RegisterChatCommand( "LUI", "ChatCommand")
end