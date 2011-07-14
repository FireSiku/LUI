--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: themes.lua
	Description: Themes Module
	Version....: 1.3
	Rev Date...: 16/01/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.2: Zista
		v1.3: Zista
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")

local module = LUI:NewModule("Themes")
local ACR = LibStub("AceConfigRegistry-3.0")
local version = 3313

local db
local ClassArray = {"Death Knight", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}
local importThemeName

function module:ApplyTheme()
	self:Refresh_Micromenu()
	self:Refresh_RaidMenu()
	self:Refresh_Editbox()
	self:Refresh_Minimap()
	self:Refresh_Bars()
	self:Refresh_Sidebars()
	self:Refresh_NavigationHoverColors()
	self:Refresh_NavigationColors()
	self:Refresh_TopInfoColors()
	self:Refresh_BottomInfoColors()
	self:Refresh_OrbCycleColor()
	self:Refresh_OrbHoverColor()
	self:Refresh_OrbColor()
	self:Refresh_Chat()
	self:Refresh_Tps()
	self:Refresh_Dps()
	self:Refresh_Raid()
	--self:Refresh_Forte()
end

function module:Refresh_Forte()
	if LUI:GetModule("Panels", true) then
		if db.Forte.Enable then
			local Forte = LUI:GetModule("Forte")
			Forte:SetColors()
		end
	end
end

function module:Refresh_Chat()
	if LUI:GetModule("Panels", true) then
		local Panels = LUI:GetModule("Panels")
		Panels:SetChatBackground()
	end
end

function module:Refresh_Tps()
	if LUI:GetModule("Panels", true) then
		local Panels = LUI:GetModule("Panels")
		Panels:SetTpsBackground()
	end
end

function module:Refresh_Dps()
	if LUI:GetModule("Panels", true) then
		local Panels = LUI:GetModule("Panels")
		Panels:SetDpsBackground()
	end
end

function module:Refresh_Raid()
	if LUI:GetModule("Panels", true) then
		local Panels = LUI:GetModule("Panels")
		Panels:SetRaidBackground()
	end
end

function module:Refresh_NavigationHoverColors()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetNavigationHoverColors()
	end
end

function module:Refresh_NavigationColors()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetNavigationColors()
	end
end

function module:Refresh_TopInfoColors()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetTopInfoColors()
	end
end

function module:Refresh_BottomInfoColors()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetBottomInfoColors()
	end
end

function module:Refresh_OrbColor()
	if LUI:GetModule("Orb", true) then
		local Orb = LUI:GetModule("Orb")
		Orb:SetOrbColor()
	end
end

function module:Refresh_OrbCycleColor()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetOrbCycleColor()
	end
end

function module:Refresh_OrbHoverColor()
	if LUI:GetModule("Frames", true) then
		local Frames = LUI:GetModule("Frames")
		Frames:SetOrbHoverColor()
	end
end

function module:Refresh_Sidebars()
	if LUI:GetModule("Bars", true) then
		local Bars = LUI:GetModule("Bars")
		Bars:SetSidebarColors()
	end
end

function module:Refresh_Bars()
	if LUI:GetModule("Bars", true) then
		local Bars = LUI:GetModule("Bars")
		Bars:SetBarColors()
	end
end

function module:Refresh_Minimap()
	if LUI:GetModule("Minimap", true) then
		if db.Minimap.Enable then
			local Minimap = LUI:GetModule("Minimap")
			Minimap:SetColors()
		end
	end
end

function module:Refresh_Editbox()
	if LUI:GetModule("Chat", true) then
		if db.Chat.Enable then
			local Chat = LUI:GetModule("Chat")
			Chat:SetColors()
		end
	end
end

function module:Refresh_Micromenu()
	if LUI:GetModule("Micromenu", true) then
		local Micromenu = LUI:GetModule("Micromenu")
		Micromenu:SetColors()
	end
end

function module:Refresh_RaidMenu()
	if LUI:GetModule("RaidMenu", true) then
		if db.RaidMenu.Enable then
			RaidMenu_Parent:SetBackdropColor(unpack(db.Colors.micromenu_bg2))
			RaidMenu:SetBackdropColor(unpack(db.Colors.micromenu_bg))
			local micro_r, micro_g, micro_b = unpack(db.Colors.micromenu)
			RaidMenu_Border:SetBackdropColor(micro_r, micro_g, micro_b, 1)
			RaidMenu_Header:SetFont(LSM:Fetch("font", "vibroceb"), LUI:Scale(20), "THICKOUTLINE")
			
			RaidMenu_Header:SetTextColor(1,1,1,1)
		end
	end
end

function module:CheckTheme()
	local theme
	for k, v in pairs(LUI_Themes) do
		if db.Colors.theme == k then
			theme = k
		end
	end
	if not theme then
		local _, class = UnitClass("player")
		
		if class == "WARRIOR" then
			db.Colors.theme = "Warrior"
		elseif class == "PRIEST" then
			db.Colors.theme = "Priest"
		elseif class == "DRUID" then
			db.Colors.theme = "Druid"
		elseif class == "HUNTER" then
			db.Colors.theme = "Hunter"
		elseif class == "MAGE" then
			db.Colors.theme = "Mage"
		elseif class == "PALADIN" then
			db.Colors.theme = "Paladin"
		elseif class == "SHAMAN" then
			db.Colors.theme = "Shaman"
		elseif class == "WARLOCK" then
			db.Colors.theme = "Warlock"
		elseif class == "ROGUE" then
			db.Colors.theme = "Rogue"
		elseif class == "DEATHKNIGHT" then
			db.Colors.theme = "Death Knight"
		elseif class == "DEATH KNIGHT" then
			db.Colors.theme = "Death Knight"
		end
		
		module:LoadTheme(db.Colors.theme)
	else

		if not db.Colors.color_top then
			db.Colors.color_top = {unpack(LUI_Themes[db.Colors.theme].color_top)}
		end
		
		if not db.Colors.color_bottom then
			db.Colors.color_bottom = {unpack(LUI_Themes[db.Colors.theme].color_bottom)}
		end
		
		if not db.Colors.chat then
			db.Colors.chat = {unpack(LUI_Themes[db.Colors.theme].chat)}
		end
		
		if not db.Colors.chatborder then
			db.Colors.chatborder = {unpack(LUI_Themes[db.Colors.theme].chatborder)}
		end
		
		if not db.Colors.chat2 then
			db.Colors.chat2 = {unpack(LUI_Themes[db.Colors.theme].chat2)}
		end
		
		if not db.Colors.chat2border then
			db.Colors.chat2border = {unpack(LUI_Themes[db.Colors.theme].chat2border)}
		end
		
		if not db.Colors.editbox then
			db.Colors.editbox = {unpack(LUI_Themes[db.Colors.theme].editbox)}
		end
		
		if not db.Colors.tps then
			db.Colors.tps = {unpack(LUI_Themes[db.Colors.theme].tps)}
		end
		
		if not db.Colors.tpsborder then
			db.Colors.tpsborder = {unpack(LUI_Themes[db.Colors.theme].tpsborder)}
		end
		
		if not db.Colors.dps then
			db.Colors.dps = {unpack(LUI_Themes[db.Colors.theme].dps)}
		end
		
		if not db.Colors.dpsborder then
			db.Colors.dpsborder = {unpack(LUI_Themes[db.Colors.theme].dpsborder)}
		end
		
		if not db.Colors.raid then
			db.Colors.raid = {unpack(LUI_Themes[db.Colors.theme].raid)}
		end
		
		if not db.Colors.raidborder then
			db.Colors.raidborder = {unpack(LUI_Themes[db.Colors.theme].raidborder)}
		end
		
		if not db.Colors.bar then
			db.Colors.bar = {unpack(LUI_Themes[db.Colors.theme].bar)}
		end
		
		if not db.Colors.bar2 then
			db.Colors.bar2 = {unpack(LUI_Themes[db.Colors.theme].bar2)}
		end
		
		if not db.Colors.sidebar then
			db.Colors.sidebar = {unpack(LUI_Themes[db.Colors.theme].sidebar)}
		end
		
		if not db.Colors.minimap then
			db.Colors.minimap = {unpack(LUI_Themes[db.Colors.theme].minimap)}
		end
		
		if not db.Colors.micromenu then
			db.Colors.micromenu = {unpack(LUI_Themes[db.Colors.theme].micromenu)}
		end
		
		if not db.Colors.micromenu_bg then
			db.Colors.micromenu_bg = {unpack(LUI_Themes[db.Colors.theme].micromenu_bg)}
		end
		
		if not db.Colors.micromenu_bg2 then
			db.Colors.micromenu_bg2 = {unpack(LUI_Themes[db.Colors.theme].micromenu_bg2)}
		end
		
		if not db.Colors.micromenu_btn then
			db.Colors.micromenu_btn = {unpack(LUI_Themes[db.Colors.theme].micromenu_btn)}
		end

		if not db.Colors.micromenu_btn_hover then
			db.Colors.micromenu_btn_hover = {unpack(LUI_Themes[db.Colors.theme].micromenu_btn_hover)}
		end
		
		if not db.Colors.navi then
			db.Colors.navi = {unpack(LUI_Themes[db.Colors.theme].navi)}
		end
		
		if not db.Colors.navi_hover then
			db.Colors.navi_hover = {unpack(LUI_Themes[db.Colors.theme].navi_hover)}
		end
		
		if not db.Colors.orb then
			db.Colors.orb = {unpack(LUI_Themes[db.Colors.theme].orb)}
		end
		
		if not db.Colors.orb_cycle then
			db.Colors.orb_cycle = {unpack(LUI_Themes[db.Colors.theme].orb_cycle)}
		end
		
		if not db.Colors.orb_hover then	
			db.Colors.orb_hover = {unpack(LUI_Themes[db.Colors.theme].orb_hover)}
		end
	end
end

function module:LoadTheme(theme)

	if LUI_Themes[theme].color_top then
		db.Colors.color_top = {unpack(LUI_Themes[theme].color_top)}
	end
	
	if LUI_Themes[theme].color_bottom then
		db.Colors.color_bottom = {unpack(LUI_Themes[theme].color_bottom)}
	end
	
	if LUI_Themes[theme].chat then
		db.Colors.chat = {unpack(LUI_Themes[theme].chat)}
	end
	
	if LUI_Themes[theme].chatborder then
		db.Colors.chatborder = {unpack(LUI_Themes[theme].chatborder)}
	end
	
	if LUI_Themes[theme].chat2 then
		db.Colors.chat2 = {unpack(LUI_Themes[theme].chat2)}
	end
	
	if LUI_Themes[theme].chat2border then
		db.Colors.chat2border = {unpack(LUI_Themes[theme].chat2border)}
	end
	
	if LUI_Themes[theme].editbox then
		db.Colors.editbox = {unpack(LUI_Themes[theme].editbox)}
	end
	
	if LUI_Themes[theme].tps then
		db.Colors.tps = {unpack(LUI_Themes[theme].tps)}
	end
	
	if LUI_Themes[theme].tpsborder then
		db.Colors.tpsborder = {unpack(LUI_Themes[theme].tpsborder)}
	end
	
	if LUI_Themes[theme].dps then
		db.Colors.dps = {unpack(LUI_Themes[theme].dps)}
	end
	
	if LUI_Themes[theme].dpsborder then
		db.Colors.dpsborder = {unpack(LUI_Themes[theme].dpsborder)}
	end
	
	if LUI_Themes[theme].raid then
		db.Colors.raid = {unpack(LUI_Themes[theme].raid)}
	end
	
	if LUI_Themes[theme].raidborder then
		db.Colors.raidborder = {unpack(LUI_Themes[theme].raidborder)}
	end
	
	if LUI_Themes[theme].bar then
		db.Colors.bar = {unpack(LUI_Themes[theme].bar)}
	end
	
	if LUI_Themes[theme].bar2 then
		db.Colors.bar2 = {unpack(LUI_Themes[theme].bar2)}
	end
	
	if LUI_Themes[theme].sidebar then
		db.Colors.sidebar = {unpack(LUI_Themes[theme].sidebar)}
	end
	
	if LUI_Themes[theme].minimap then
		db.Colors.minimap = {unpack(LUI_Themes[theme].minimap)}
	end
	
	if LUI_Themes[theme].micromenu then
		db.Colors.micromenu = {unpack(LUI_Themes[theme].micromenu)}
	end
	
	if LUI_Themes[theme].micromenu_bg then
		db.Colors.micromenu_bg = {unpack(LUI_Themes[theme].micromenu_bg)}
	end
	
	if LUI_Themes[theme].micromenu_bg2 then
		db.Colors.micromenu_bg2 = {unpack(LUI_Themes[theme].micromenu_bg2)}
	end
	
	if LUI_Themes[theme].micromenu_btn then
		db.Colors.micromenu_btn = {unpack(LUI_Themes[theme].micromenu_btn)}
	end

	if LUI_Themes[theme].micromenu_btn_hover then
		db.Colors.micromenu_btn_hover = {unpack(LUI_Themes[theme].micromenu_btn_hover)}
	end
	
	if LUI_Themes[theme].navi then
		db.Colors.navi = {unpack(LUI_Themes[theme].navi)}
	end
	
	if LUI_Themes[theme].navi_hover then
		db.Colors.navi_hover = {unpack(LUI_Themes[theme].navi_hover)}
	end
	
	if LUI_Themes[theme].orb then
		db.Colors.orb = {unpack(LUI_Themes[theme].orb)}
	end
	
	if LUI_Themes[theme].orb_cycle then
		db.Colors.orb_cycle = {unpack(LUI_Themes[theme].orb_cycle)}
	end
	
	if LUI_Themes[theme].orb_hover then	
		db.Colors.orb_hover = {unpack(LUI_Themes[theme].orb_hover)}
	end
end

function module:SaveTheme(theme)
	if theme == "" or theme == nil then return end
	if LUI_Themes[theme] ~= nil then StaticPopup_Show("ALREADY_A_THEME") return end
	
	LUI_Themes[theme] = {
		color_top = {unpack(db.Colors.color_top)},
		color_bottom = {unpack(db.Colors.color_bottom)},
		chat = {unpack(db.Colors.chat)},
		chatborder = {unpack(db.Colors.chatborder)},
		chat2 = {unpack(db.Colors.chat2)},
		chat2border = {unpack(db.Colors.chat2border)},
		editbox = {unpack(db.Colors.editbox)},
		tps = {unpack(db.Colors.tps)},
		tpsborder = {unpack(db.Colors.tpsborder)},
		dps = {unpack(db.Colors.dps)},
		dpsborder = {unpack(db.Colors.dpsborder)},
		raid = {unpack(db.Colors.raid)},
		raidborder = {unpack(db.Colors.raidborder)},
		bar = {unpack(db.Colors.bar)},
		bar2 = {unpack(db.Colors.bar2)},
		sidebar = {unpack(db.Colors.sidebar)},
		minimap = {unpack(db.Colors.minimap)},
		micromenu = {unpack(db.Colors.micromenu)},
		micromenu_bg = {unpack(db.Colors.micromenu_bg)},
		micromenu_bg2 = {unpack(db.Colors.micromenu_bg2)},
		micromenu_btn = {unpack(db.Colors.micromenu_btn)},
		micromenu_btn_hover = {unpack(db.Colors.micromenu_btn_hover)},
		navi = {unpack(db.Colors.navi)},
		navi_hover = {unpack(db.Colors.navi_hover)},
		orb = {unpack(db.Colors.orb)},
		orb_cycle = {unpack(db.Colors.orb_cycle)},
		orb_hover = {unpack(db.Colors.orb_hover)},
	}
	db.Colors.theme = theme
	ACR:NotifyChange("LUI")
end

function module:DeleteTheme(theme)
	if theme == "" or theme == nil then theme = db.Colors.theme end
	
	for k, v in pairs(ClassArray) do
		if theme == v then
			LUI:Print("CLASS THEMES CAN NOT BE DELETED!!!")
			return
		end
	end
	
	LUI_Themes[theme] = nil
	db.Colors.theme = ""
	module:CheckTheme()
	module:ApplyTheme()
	ACR:NotifyChange("LUI")
end

function module:ImportThemeName(name)
	if name == nil or name == "" then return end
	if LUI_Themes[name] ~= nil then StaticPopup_Show("ALREADY_A_THEME") return end
	importThemeName = name
	StaticPopup_Show("IMPORT_THEME_DATA")
end

function module:ImportThemeData(str, name)
	if str == nil or str == "" then return end
	if name == nil or name == "" then
		if importThemeName ~= nil then
			name = importThemeName
		else
			LUI:Print("Invalid Theme Name")
		end
	end
	importThemeName = nil
	if LUI_Themes[name] ~= nil then StaticPopup_Show("ALREADY_A_THEME") return end
	
	local valid, data = LUI:Deserialize(str)
	if not valid then
		LUI:Print("Error importing theme!")
		return
	end
	LUI_Themes[name] = data
	db.Colors.theme = name
	module:LoadTheme(name)
	module:ApplyTheme()
	LUI:Print("Successfully imported "..name.." theme!")
	ACR:NotifyChange("LUI")
end

function module:ExportTheme(theme)
	if theme == "" or theme == nil then theme = db.Colors.theme end
	if LUI_Themes[theme] == nil then return end
	
	local data = LUI:Serialize(LUI_Themes[theme])
	if data == nil then return end
	local breakDown
	for i = 1, math.ceil(strlen(data)/100) do
		local part = (strsub(data, (((i-1)*100)+1), (i*100))).." "
		breakDown = (breakDown and breakDown or "")..part
	end
	return breakDown
end

function module:ThemeArray()
	local ClassThemeArray = {}
	local TempThemeArray = {}
	local LUIThemeArray = {}
	local isClass
	
	for t in pairs(LUI_Themes) do
		isClass = false
		for k,v in pairs(ClassArray) do
			if t == v then
				isClass = true
				table.insert(ClassThemeArray, t)
				break
			end
		end
		if isClass == false then
			table.insert(TempThemeArray, t)
		end
	end
	table.sort(ClassThemeArray)
	table.sort(TempThemeArray)
	
	for k,v in pairs(ClassThemeArray) do
		table.insert(LUIThemeArray, v)
	end
	
	if #TempThemeArray > 0 then
		table.insert(LUIThemeArray, "")
		for k,v in pairs(TempThemeArray) do
			table.insert(LUIThemeArray, v)
		end
	end
	
	return LUIThemeArray
end

local themes = {
	["Deep Freeze"] = {
		color_top = {0.28, 0.52, 0.85, 0.65},
		color_bottom = {0.28, 0.52, 0.85, 0.65},
		chat = {0.28, 0.52, 0.85, 0.46},
		chatborder = {0.28, 0.52, 0.85, 0.46},
		chat2 = {0.28, 0.52, 0.85, 0.46},
		chat2border = {0.28, 0.52, 0.85, 0.46},
		editbox = {0.28, 0.52, 0.85, 0.46},
		tps = {0.28, 0.52, 0.85, 0.46},
		tpsborder = {0.28, 0.52, 0.85, 0.46},
		dps = {0.28, 0.52, 0.85, 0.46},
		dpsborder = {0.28, 0.52, 0.85, 0.46},
		raid = {0.28, 0.52, 0.85, 0.46},
		raidborder = {0.28, 0.52, 0.85, 0.46},
		bar = {0.33, 0.61, 1, 0.7},
		bar2 = {0.33, 0.61, 1, 0.5},
		sidebar = {0.28, 0.52, 0.85, 0.55},
		minimap = {0.33, 0.61, 1, 1},
		micromenu = {0.45, 0.71, 0.98},
		micromenu_bg = {0.15, 0.41, 0.68, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.28, 0.52, 0.85, 0.8},
		micromenu_btn_hover = {0.28, 0.52, 0.85, 0.8},
		navi = {0.28, 0.52, 0.85, 0.63},
		navi_hover = {0.28, 0.52, 0.85, 0.65},
		orb = {0.44, 0.60, 0.80},
		orb_cycle = {0.28, 0.52, 0.85, 0.65},
		orb_hover = {0.28, 0.52, 0.85, 0.65},
	},
	["Goldenboy"] = {
		color_top = {0.85, 0.58, 0.33, 0.73},
		color_bottom = {0.85, 0.58, 0.33, 0.73},
		chat = {0, 0, 0, 0.45},
		chatborder = {0, 0, 0, 0.45},
		chat2 = {0, 0, 0, 0.45},
		chat2border = {0, 0, 0, 0.45},
		editbox = {0, 0, 0, 0.45},
		tps = {0, 0, 0, 0.45},
		tpsborder = {0, 0, 0, 0.45},
		dps = {0, 0, 0, 0.45},
		dpsborder = {0, 0, 0, 0.45},
		raid = {0, 0, 0, 0.45},
		raidborder = {0, 0, 0, 0.45},
		bar = {0.85, 0.58, 0.33, 0.75},
		bar2 = {0.85, 0.58, 0.33, 0.65},
		sidebar = {0.85, 0.58, 0.33, 0.5},
		minimap = {0.85, 0.58, 0.33, 0.2},
		micromenu = {0.85, 0.58, 0.33},
		micromenu_bg = {0.85, 0.58, 0.33, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.85, 0.58, 0.33, 0.8},
		micromenu_btn_hover = {0.85, 0.58, 0.33, 0.8},
		navi = {0.02, 0.02, 0.02, 1},
		navi_hover = {0.85, 0.58, 0.33, 0.73},
		orb = {0.85, 0.58, 0.33},
		orb_cycle = {0.85, 0.58, 0.33, 0.73},
		orb_hover = {0.85, 0.58, 0.33, 0.73},
	},
	["Bloodprince"] = {
		color_top = {0.75, 0.25, 0.20, 0.6},
		color_bottom = {0.75, 0.25, 0.20, 0.6},
		chat = {0, 0, 0, 0.45},
		chatborder = {0, 0, 0, 0.45},
		chat2 = {0, 0, 0, 0.45},
		chat2border = {0, 0, 0, 0.45},
		editbox = {0, 0, 0, 0.45},
		tps = {0, 0, 0, 0.45},
		tpsborder = {0, 0, 0, 0.45},
		dps = {0, 0, 0, 0.45},
		dpsborder = {0, 0, 0, 0.45},
		raid = {0, 0, 0, 0.45},
		raidborder = {0, 0, 0, 0.45},
		bar = {0, 0, 0, 0.7},
		bar2 = {0, 0, 0, 0.6},
		sidebar = {0.75, 0.25, 0.20, 0.5},
		minimap = {0.4, 0, 0, 0.7},
		micromenu = {0.7, 0.16, 0.12},
		micromenu_bg = {0.4, 0, 0, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.75, 0.25, 0.20, 0.8},
		micromenu_btn_hover = {0.75, 0.25, 0.20, 0.8},
		navi = {0.3, 0.05, 0.02, 1},
		navi_hover = {0.75, 0.25, 0.20, 0.6},
		orb = {0.71, 0.33, 0.27},
		orb_cycle = {0.75, 0.25, 0.20, 0.6},
		orb_hover = {0.75, 0.25, 0.20, 0.6},
	},
	["Absinth"] = {
		color_top = {0.63, 0.6, 0.62, 0.65},
		color_bottom = {0.63, 0.6, 0.62, 0.65},
		chat = {0.11, 0.67, 0.13, 0.4},
		chatborder = {0.11, 0.67, 0.13, 0.4},
		chat2 = {0.11, 0.67, 0.13, 0.4},
		chat2border = {0.11, 0.67, 0.13, 0.4},
		editbox = {0.11, 0.67, 0.13, 0.4},
		tps = {0.11, 0.67, 0.13, 0.4},
		tpsborder = {0.11, 0.67, 0.13, 0.4},
		dps = {0.11, 0.67, 0.13, 0.4},
		dpsborder = {0.11, 0.67, 0.13, 0.4},
		raid = {0.11, 0.67, 0.13, 0.4},
		raidborder = {0.11, 0.67, 0.13, 0.4},
		bar = {0, 0, 0, 0.7},
		bar2 = {0, 0, 0, 0.6},
		sidebar = {0.6, 0.6, 0.6, 0.5},
		minimap = {0.43, 1, 0.43, 1},
		micromenu = {0.9, 0.9, 0.9},
		micromenu_bg = {0.6, 0.6, 0.6, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.63, 0.6, 0.62, 0.8},
		micromenu_btn_hover = {0.63, 0.6, 0.62, 0.8},
		navi = {0.38, 0.85, 0, 0.26},
		navi_hover = {0.63, 0.6, 0.62, 0.65},
		orb = {0.28, 0.8, 0.36},
		orb_cycle = {0.63, 0.6, 0.62, 0.65},
		orb_hover = {0.63, 0.6, 0.62, 0.65},
	},
	["Demonic Pact"] = {
		color_top = {0.55, 0.38, 0.85, 0.55},
		color_bottom = {0.55, 0.38, 0.85, 0.55},
		chat = {1, 1, 1, 0.27},
		chatborder = {1, 1, 1, 0.27},
		chat2 = {1, 1, 1, 0.27},
		chat2border = {1, 1, 1, 0.27},
		editbox = {1, 1, 1, 0.27},
		tps = {1, 1, 1, 0.27},
		tpsborder = {1, 1, 1, 0.27},
		dps = {1, 1, 1, 0.27},
		dpsborder = {1, 1, 1, 0.27},
		raid = {1, 1, 1, 0.27},
		raidborder = {1, 1, 1, 0.27},
		bar = {0.53, 0.48, 0.9, 0.8},
		bar2 = {0.53, 0.48, 0.9, 0.7},
		sidebar = {0.53, 0.48, 0.9, 0.5},
		minimap = {0.71, 0.66, 0.85, 1},
		micromenu = {0.76, 0.72, 1},
		micromenu_bg = {0.46, 0.42, 0.7, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.55, 0.38, 0.85, 0.8},
		micromenu_btn_hover = {0.55, 0.38, 0.85, 0.8},
		navi = {0.45, 0.32, 0.83, 0.26},
		navi_hover = {0.55, 0.38, 0.85, 0.45},
		orb = {0.29, 0.25, 0.31},
		orb_cycle = {0.55, 0.38, 0.85, 0.45},
		orb_hover = {0.55, 0.38, 0.85, 0.45},
	},
	["Orangemarmalade"] = {
		color_top = {1, 0.43, 0, 0.55},
		color_bottom = {1, 0.43, 0, 0.55},
		chat = {0, 0, 0, 0.83},
		chatborder = {0, 0, 0, 0.86},
		chat2 = {0, 0, 0, 0.83},
		chat2border = {0, 0, 0, 0.86},
		editbox = {0, 0, 0, 0.5},
		tps = {0, 0, 0, 0.83},
		tpsborder = {0, 0, 0, 0.86},
		dps = {0, 0, 0, 0.83},
		dpsborder = {0, 0, 0, 0.86},
		raid = {0, 0, 0, 0.83},
		raidborder = {0, 0, 0, 0.86},
		bar = {1, 0.48, 0, 0.81},
		bar2 = {1, 0.48, 0, 0.81},
		sidebar = {1, 0.48, 0, 0.5},
		minimap = {0.85, 0.35, 0, 0.58},
		micromenu = {1, 0.54, 0.32},
		micromenu_bg = {0.7, 0.24, 0.02, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {1, 0.43, 0, 0.8},
		micromenu_btn_hover = {1, 0.43, 0, 0.8},
		navi = {0.72, 0.75, 0.72, 0.38},
		navi_hover = {1, 0.43, 0, 0.4},
		orb = {0.8, 0.38, 0.05},
		orb_cycle = {1, 0.43, 0, 0.4},
		orb_hover = {1, 0.43, 0, 0.4},
	},
	["Warrior"] = {
		color_top = {1, 0.78, 0.55, 0.55},
		color_bottom = {1, 0.78, 0.55, 0.55},
		chat = {1, 0.78, 0.55, 0.4},
		chatborder = {1, 0.78, 0.55, 0.4},
		chat2 = {1, 0.78, 0.55, 0.4},
		chat2border = {1, 0.78, 0.55, 0.4},
		editbox = {1, 0.78, 0.55, 0.4},
		tps = {1, 0.78, 0.55, 0.4},
		tpsborder = {1, 0.78, 0.55, 0.4},
		dps = {1, 0.78, 0.55, 0.4},
		dpsborder = {1, 0.78, 0.55, 0.4},
		raid = {1, 0.78, 0.55, 0.4},
		raidborder = {1, 0.78, 0.55, 0.4},
		bar = {1, 0.78, 0.55, 0.7},
		bar2 = {1, 0.78, 0.55, 0.6},
		sidebar = {1, 0.78, 0.55, 0.5},
		minimap = {1, 0.78, 0.55, 1},
		micromenu = {1, 0.78, 0.55},
		micromenu_bg = {0.7, 0.48, 0.25, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {1, 0.78, 0.55, 0.8},
		micromenu_btn_hover = {1, 0.78, 0.55, 0.8},
		navi = {1, 0.78, 0.55, 0.6},
		navi_hover = {1, 0.78, 0.55, 0.4},
		orb = {1, 0.78, 0.55},
		orb_cycle = {1, 0.78, 0.55, 0.4},
		orb_hover = {1, 0.78, 0.55, 0.4},
	},
	["Priest"] = {
		color_top = {0.9, 0.9, 0.9, 0.5},
		color_bottom = {0.9, 0.9, 0.9, 0.5},
		chat = {0.9, 0.9, 0.9, 0.4},
		chatborder = {0.9, 0.9, 0.9, 0.4},
		chat2 = {0.9, 0.9, 0.9, 0.4},
		chat2border = {0.9, 0.9, 0.9, 0.4},
		editbox = {0.9, 0.9, 0.9, 0.4},
		tps = {0.9, 0.9, 0.9, 0.4},
		tpsborder = {0.9, 0.9, 0.9, 0.4},
		dps = {0.9, 0.9, 0.9, 0.4},
		dpsborder = {0.9, 0.9, 0.9, 0.4},
		raid = {0.9, 0.9, 0.9, 0.4},
		raidborder = {0.9, 0.9, 0.9, 0.4},
		bar = {0.9, 0.9, 0.9, 0.7},
		bar2 = {0.9, 0.9, 0.9, 0.6},
		sidebar = {0.9, 0.9, 0.9, 0.4},
		minimap = {0.9, 0.9, 0.9, 1},
		micromenu = {0.9, 0.9, 0.9},
		micromenu_bg = {0.6, 0.6, 0.6, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.9, 0.9, 0.9, 0.8},
		micromenu_btn_hover = {0.9, 0.9, 0.9, 0.8},
		navi = {0.9, 0.9, 0.9, 0.6},
		navi_hover = {0.9, 0.9, 0.9, 0.4},
		orb = {0.9, 0.9, 0.9},
		orb_cycle = {0.9, 0.9, 0.9, 0.4},
		orb_hover = {0.9, 0.9, 0.9, 0.4},
	},
	["Druid"] = {
		color_top = {1, 0.44, 0.15, 0.5},
		color_bottom = {1, 0.44, 0.15, 0.5},
		chat = {1, 0.44, 0.15, 0.4},
		chatborder = {1, 0.44, 0.15, 0.4},
		chat2 = {1, 0.44, 0.15, 0.4},
		chat2border = {1, 0.44, 0.15, 0.4},
		editbox = {1, 0.44, 0.15, 0.4},
		tps = {1, 0.44, 0.15, 0.4},
		tpsborder = {1, 0.44, 0.15, 0.4},
		dps = {1, 0.44, 0.15, 0.4},
		dpsborder = {1, 0.44, 0.15, 0.4},
		raid = {1, 0.44, 0.15, 0.4},
		raidborder = {1, 0.44, 0.15, 0.4},
		bar = {1, 0.44, 0.15, 0.7},
		bar2 = {1, 0.44, 0.15, 0.6},
		sidebar = {1, 0.44, 0.15, 0.5},
		minimap = {1, 0.44, 0.15, 1},
		micromenu = {1, 0.44, 0.15},
		micromenu_bg = {1, 0.44, 0.15, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {1, 0.44, 0.15, 0.8},
		micromenu_btn_hover = {1, 0.44, 0.15, 0.8},
		navi = {1, 0.44, 0.15, 0.6},
		navi_hover = {1, 0.44, 0.15, 0.4},
		orb = {1, 0.44, 0.15},
		orb_cycle = {1, 0.44, 0.15, 0.4},
		orb_hover = {1, 0.44, 0.15, 0.4},
	},
	["Hunter"] = {
		color_top = {0.22, 0.91, 0.18, 0.5},
		color_bottom = {0.22, 0.91, 0.18, 0.5},
		chat = {0.22, 0.91, 0.18, 0.4},
		chatborder = {0.22, 0.91, 0.18, 0.4},
		chat2 = {0.22, 0.91, 0.18, 0.4},
		chat2border = {0.22, 0.91, 0.18, 0.4},
		editbox = {0.22, 0.91, 0.18, 0.4},
		tps = {0.22, 0.91, 0.18, 0.4},
		tpsborder = {0.22, 0.91, 0.18, 0.4},
		dps = {0.22, 0.91, 0.18, 0.4},
		dpsborder = {0.22, 0.91, 0.18, 0.4},
		raid = {0.22, 0.91, 0.18, 0.4},
		raidborder = {0.22, 0.91, 0.18, 0.4},
		bar = {0.22, 0.91, 0.18, 0.7},
		bar2 = {0.22, 0.91, 0.18, 0.6},
		sidebar = {0.22, 0.91, 0.18, 0.4},
		minimap = {0.22, 0.91, 0.18, 1},
		micromenu = {0.22, 0.91, 0.18},
		micromenu_bg = {0, 0.61, 0, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.22, 0.91, 0.18, 0.8},
		micromenu_btn_hover = {0.22, 0.91, 0.18, 0.8},
		navi = {0.22, 0.91, 0.18, 0.6},
		navi_hover = {0.22, 0.91, 0.18, 0.4},
		orb = {0.22, 0.91, 0.18},
		orb_cycle = {0.22, 0.91, 0.18, 0.4},
		orb_hover = {0.22, 0.91, 0.18, 0.4},
	},
	["Mage"] = {
		color_top = {0.12, 0.58, 0.89, 0.5},
		color_bottom = {0.12, 0.58, 0.89, 0.5},
		chat = {0.12, 0.58, 0.89, 0.4},
		chatborder = {0.12, 0.58, 0.89, 0.4},
		chat2 = {0.12, 0.58, 0.89, 0.4},
		chat2border = {0.12, 0.58, 0.89, 0.4},
		editbox = {0.12, 0.58, 0.89, 0.4},
		tps = {0.12, 0.58, 0.89, 0.4},
		tpsborder = {0.12, 0.58, 0.89, 0.4},
		dps = {0.12, 0.58, 0.89, 0.4},
		dpsborder = {0.12, 0.58, 0.89, 0.4},
		raid = {0.12, 0.58, 0.89, 0.4},
		raidborder = {0.12, 0.58, 0.89, 0.4},
		bar = {0.12, 0.58, 0.89, 0.8},
		bar2 = {0.12, 0.58, 0.89, 0.6},
		sidebar = {0.12, 0.58, 0.89, 0.4},
		minimap = {0.12, 0.58, 0.89, 1},
		micromenu = {0.12, 0.58, 0.89},
		micromenu_bg = {0, 0.22, 0.47, 1},
		micromenu_bg2 = {0.12, 0.12, 0.12, 0.6},
		micromenu_btn = {0.12, 0.58, 0.89, 0.8},
		micromenu_btn_hover = {0.12, 0.58, 0.89, 0.8},
		navi = {0.12, 0.58, 0.89, 0.6},
		navi_hover = {0.12, 0.58, 0.89, 0.4},
		orb = {0.12, 0.58, 0.89},
		orb_cycle = {0.12, 0.58, 0.89, 0.4},
		orb_hover = {0.12, 0.58, 0.89, 0.4},
	},
	["Paladin"] = {
		color_top = {0.96, 0.21, 0.73, 0.5},
		color_bottom = {0.96, 0.21, 0.73, 0.5},
		chat = {0.96, 0.21, 0.73, 0.4},
		chatborder = {0.96, 0.21, 0.73, 0.4},
		chat2 = {0.96, 0.21, 0.73, 0.4},
		chat2border = {0.96, 0.21, 0.73, 0.4},
		editbox = {0.96, 0.21, 0.73, 0.4},
		tps = {0.96, 0.21, 0.73, 0.4},
		tpsborder = {0.96, 0.21, 0.73, 0.4},
		dps = {0.96, 0.21, 0.73, 0.4},
		dpsborder = {0.96, 0.21, 0.73, 0.4},
		raid = {0.96, 0.21, 0.73, 0.4},
		raidborder = {0.96, 0.21, 0.73, 0.4},
		bar = {0.96, 0.21, 0.73, 0.7},
		bar2 = {0.96, 0.21, 0.73, 0.6},
		sidebar = {0.96, 0.21, 0.73, 0.4},
		minimap = {0.96, 0.21, 0.73, 1},
		micromenu = {0.96, 0.21, 0.73},
		micromenu_bg = {0.66, 0, 0.43, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.96, 0.21, 0.73, 0.8},
		micromenu_btn_hover = {0.96, 0.21, 0.73, 0.8},
		navi = {0.96, 0.21, 0.73, 0.6},
		navi_hover = {0.96, 0.21, 0.73, 0.4},
		orb = {0.96, 0.21, 0.73},
		orb_cycle = {0.96, 0.21, 0.73, 0.4},
		orb_hover = {0.96, 0.21, 0.73, 0.4},
	},
	["Shaman"] = {
		color_top = {0.04, 0.39, 0.98, 0.5},
		color_bottom = {0.04, 0.39, 0.98, 0.5},
		chat = {0.04, 0.39, 0.98, 0.4},
		chatborder = {0.04, 0.39, 0.98, 0.4},
		chat2 = {0.04, 0.39, 0.98, 0.4},
		chat2border = {0.04, 0.39, 0.98, 0.4},
		editbox = {0.04, 0.39, 0.98, 0.4},
		tps = {0.04, 0.39, 0.98, 0.4},
		tpsborder = {0.04, 0.39, 0.98, 0.4},
		dps = {0.04, 0.39, 0.98, 0.4},
		dpsborder = {0.04, 0.39, 0.98, 0.4},
		raid = {0.04, 0.39, 0.98, 0.4},
		raidborder = {0.04, 0.39, 0.98, 0.4},
		bar = {0.04, 0.39, 0.98, 0.7},
		bar2 = {0.04, 0.39, 0.98, 0.6},
		sidebar = {0.04, 0.39, 0.98, 0.4},
		minimap = {0.04, 0.39, 0.98, 1},
		micromenu = {0.04, 0.39, 0.98},
		micromenu_bg = {0, 0.09, 0.68, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.8},
		micromenu_btn = {0.04, 0.39, 0.98, 0.8},
		micromenu_btn_hover = {0.04, 0.39, 0.98, 0.8},
		navi = {0.04, 0.39, 0.98, 0.6},
		navi_hover = {0.04, 0.39, 0.98, 0.4},
		orb = {0.04, 0.39, 0.98},
		orb_cycle = {0.04, 0.39, 0.98, 0.4},
		orb_hover = {0.04, 0.39, 0.98, 0.4},
	},
	["Warlock"] = {
		color_top = {0.57, 0.22, 1, 0.5},
		color_bottom = {0.57, 0.22, 1, 0.5},
		chat = {0.57, 0.22, 1, 0.4},
		chatborder = {0.57, 0.22, 1, 0.4},
		chat2 = {0.57, 0.22, 1, 0.4},
		chat2border = {0.57, 0.22, 1, 0.4},
		editbox = {0.57, 0.22, 1, 0.4},
		tps = {0.57, 0.22, 1, 0.4},
		tpsborder = {0.57, 0.22, 1, 0.4},
		dps = {0.57, 0.22, 1, 0.4},
		dpsborder = {0.57, 0.22, 1, 0.4},
		raid = {0.57, 0.22, 1, 0.4},
		raidborder = {0.57, 0.22, 1, 0.4},
		bar = {0.57, 0.22, 1, 0.7},
		bar2 = {0.57, 0.22, 1, 0.5},
		sidebar = {0.57, 0.22, 1, 0.4},
		minimap = {0.57, 0.22, 1, 1},
		micromenu = {0.57, 0.22, 1},
		micromenu_bg = {0.27, 0, 0.7, 0.8},
		micromenu_bg2 = {0, 0, 0, 0.7},
		micromenu_btn = {0.57, 0.22, 1, 0.8},
		micromenu_btn_hover = {0.57, 0.22, 1, 0.8},
		navi = {0.57, 0.22, 1, 0.6},
		navi_hover = {0.57, 0.22, 1, 0.4},
		orb = {0.57, 0.22, 1},
		orb_cycle = {0.57, 0.22, 1, 0.4},
		orb_hover = {0.57, 0.22, 1, 0.4},
	},
	["Rogue"] = {
		color_top = {0.95, 0.86, 0.16, 0.5},
		color_bottom = {0.95, 0.86, 0.16, 0.5},
		chat = {0.95, 0.86, 0.16, 0.4},
		chatborder = {0.95, 0.86, 0.16, 0.4},
		chat2 = {0.95, 0.86, 0.16, 0.4},
		chat2border = {0.95, 0.86, 0.16, 0.4},
		editbox = {0.95, 0.86, 0.16, 0.4},
		tps = {0.95, 0.86, 0.16, 0.4},
		tpsborder = {0.95, 0.86, 0.16, 0.4},
		dps = {0.95, 0.86, 0.16, 0.4},
		dpsborder = {0.95, 0.86, 0.16, 0.4},
		raid = {0.95, 0.86, 0.16, 0.4},
		raidborder = {0.95, 0.86, 0.16, 0.4},
		bar = {0.95, 0.86, 0.16, 0.7},
		bar2 = {0.95, 0.86, 0.16, 0.5},
		sidebar = {0.95, 0.86, 0.16, 0.4},
		minimap = {0.95, 0.86, 0.16, 1},
		micromenu = {0.95, 0.86, 0.16},
		micromenu_bg = {0.65, 0.56, 0, 0.8},
		micromenu_bg2 = {0, 0, 0, 1},
		micromenu_btn = {0.95, 0.86, 0.16, 0.8},
		micromenu_btn_hover = {0.95, 0.86, 0.16, 0.8},
		navi = {0.95, 0.86, 0.16, 0.6},
		navi_hover = {0.95, 0.86, 0.16, 0.4},
		orb = {0.95, 0.86, 0.16},
		orb_cycle = {0.95, 0.86, 0.16, 0.4},
		orb_hover = {0.95, 0.86, 0.16, 0.4},
	},
	["Death Knight"] = {
		color_top = {0.80, 0.1, 0.1, 0.5},
		color_bottom = {0.80, 0.1, 0.1, 0.5},
		chat = {0.80, 0.1, 0.1, 0.4},
		chatborder = {0.80, 0.1, 0.1, 0.4},
		chat2 = {0.80, 0.1, 0.1, 0.4},
		chat2border = {0.80, 0.1, 0.1, 0.4},
		editbox = {0.80, 0.1, 0.1, 0.4},
		tps = {0.80, 0.1, 0.1, 0.4},
		tpsborder = {0.80, 0.1, 0.1, 0.4},
		dps = {0.80, 0.1, 0.1, 0.4},
		dpsborder = {0.80, 0.1, 0.1, 0.4},
		raid = {0.80, 0.1, 0.1, 0.4},
		raidborder = {0.80, 0.1, 0.1, 0.4},
		bar = {0.80, 0.1, 0.1, 0.8},
		bar2 = {0.80, 0.1, 0.1, 0.6},
		sidebar = {0.80, 0.1, 0.1, 0.4},
		minimap = {0.80, 0.1, 0.1, 1},
		micromenu = {0.80, 0.1, 0.1},
		micromenu_bg = {0.7, 0, 0, 0.8},
		micromenu_bg2 = {0.1, 0.1, 0.1, 0.8},
		micromenu_btn = {0.80, 0.1, 0.1, 0.8},
		micromenu_btn_hover = {0.80, 0.1, 0.1, 0.8},
		navi = {0.80, 0.1, 0.1, 0.6},
		navi_hover = {0.80, 0.1, 0.1, 0.4},
		orb = {0.80, 0.1, 0.1},
		orb_cycle = {0.80, 0.1, 0.1, 0.4},
		orb_hover = {0.80, 0.1, 0.1, 0.4},
	},
}

local defaults = {
	Colors = {
		theme = "",
		color_top = nil,
		color_bottom = nil,
		chat = nil,
		chatborder = nil,
		chat2 = nil,
		chat2border = nil,
		editbox = nil,
		tps = nil,
		tpsborder = nil,
		dps = nil,
		dpsborder = nil,
		raid = nil,
		raidborder = nil,
		bar = nil,
		bar2 = nil,
		sidebar = nil,
		minimap = nil,
		micromenu = nil,
		micromenu_bg = nil,
		micromenu_bg2 = nil,
		micromenu_btn = nil,
		micromenu_btn_hover = nil,
		navi = nil,
		navi_hover = nil,
		orb = nil,
		orb_cycle = nil,
		orb_hover = nil,
	},
}

function module:StaticPopups()
	StaticPopupDialogs["ALREADY_A_THEME"] = {
		text = "That theme already exists.\nPlease choose another name.",
		button1 = "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}
	
	StaticPopupDialogs["SAVE_THEME"] = {
		text = 'Enter the name for your new theme',
		button1 = "Save Theme",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				module:SaveTheme(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:SaveTheme(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["DELETE_THEME"] = {
		text = 'Are you sure you want to delete the current theme?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) module:DeleteTheme() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_THEME"] = {
		text = 'Enter a name for your new theme',
		button1 = "Continue",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				module:ImportThemeName(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:ImportThemeName(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_THEME_DATA"] = {
		text = "Paste the new theme string here:",
		button1 = "Import Theme",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 2000,
		OnAccept = function(self)
				module:ImportThemeData(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:ImportThemeData(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["EXPORT_THEME"] = {
		text = "Copy the following to share it with others:",
		button1 = "Close",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 2000,
		OnShow = function(self)
				self.editBox:SetText(module:ExportTheme())
				self.editBox:SetFocus()
				self.editBox:HighlightText()
			end,
		EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
		EditBoxOnExitPressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["RESET_THEMES"] = {
		text = "Are you sure you want to reset all your themes?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self)
				LUI_Themes = nil
				LUI_Themes = themes
				if LUI_Themes[db.Colors.theme] == nil then db.Colors.theme = "" end
				module:CheckTheme()
				module:ApplyTheme()
				ACR:NotifyChange("LUI")
			end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

function module:LoadOptions()
	local options = {
		Layouts = {
			name = "Colors",
			type = "group",
			order = 2,
			childGroups = "tab",
			args = {
				Theme = {
					name = "Theme",
					type = "group",
					order = 1,
					args = {
						SetTheme = {
							name = "Theme",
							desc = "Choose any Theme you prefer Most.",
							type = "select",
							values = function()
								local LUIThemeArray = module:ThemeArray()
								return LUIThemeArray
							end,
							get = function() 
								local LUIThemeArray = module:ThemeArray()
								
								for k,v in pairs(LUIThemeArray) do
									if tostring(v) == tostring(db.Colors.theme) then
										return k
									end
								end
							end,
							set = function(self, SetTheme)
								local LUIThemeArray = module:ThemeArray()
								
								for k,v in pairs(LUIThemeArray) do
									if k == SetTheme then
										if v ~= "" then
											db.Colors.theme = tostring(v)
											
											module:LoadTheme(db.Colors.theme)
											module:ApplyTheme()
										end
									end
								end
							end,
							order = 1,
						},
						empty = {
							name = " \n ",
							width = "full",
							type = "description",
							order = 2,
						},
						SaveTheme = {
							name = "Save Theme",
							desc = "Save your current color selection as a new theme.",
							type = "execute",
							func = function() StaticPopup_Show("SAVE_THEME") end,
							order = 3,
						},
						DeleteTheme = {
							name = "Delete Theme",
							desc = "Delete the active theme.",
							type = "execute",
							func = function() StaticPopup_Show("DELETE_THEME") end,
							order = 4,
						},
						empty2 = {
							name = " \n",
							width = "full",
							type = "description",
							order = 5,
						},
						ImportTheme = {
							name = "Import Theme",
							desc = "Import a new Theme into LUI",
							type = "execute",
							func = function() StaticPopup_Show("IMPORT_THEME") end,
							order = 6,
						},
						ExportTheme = {
							name = "Export Theme",
							desc = "Export your current theme so you can share it with others.",
							type = "execute",
							func = function() StaticPopup_Show("EXPORT_THEME") end,
							order = 7,
						},
						empty3 = {
							name = " \n",
							width = "full",
							type = "description",
							order = 8,
						},
						ResetThemes = {
							name = "Reset Themes",
							desc = "Reset all themes back to defaults",
							type = "execute",
							func = function() StaticPopup_Show("RESET_THEMES") end,
							order = 9,
						},
					},
				},
				Frames = {
					name = "Frames",
					type = "group",
					order = 2,
					args = {
						TopInfoColors = {
							name = "Top Textur Color",
							desc = "Choose any Color for your Top Textur",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Frames", true) end,
							get = function() return unpack(db.Colors.color_top) end,
							set = function(_,r,g,b,a)
									db.Colors.color_top = {r,g,b,a}
									module:Refresh_TopInfoColors()
								end,
							order = 14,
						},
						BottomInfoColors = {
							name = "Bottom Textur Color",
							desc = "Choose any Color for your Bottom Textur",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Frames", true) end,
							get = function() return unpack(db.Colors.color_bottom) end,
							set = function(_,r,g,b,a)
									db.Colors.color_bottom = {r,g,b,a}
									module:Refresh_BottomInfoColors()
								end,
							order = 15,
						},
						Minimap = {
							name = "Minimap Color",
							desc = "Choose any Color for your Minimap",
							type = "color",
							width = "full",
							disabled = function() 
								if not LUI:GetModule("Minimap", true) then
									return true
								elseif not db.Minimap.Enable then
									return true
								else
									return false
								end
							end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.minimap) end,
							set = function(_,r,g,b,a)
									db.Colors.minimap = {r,g,b,a}
									module:Refresh_Minimap()
								end,
							order = 7,
						},
					},
				},
				Panels = {
					name = "Panels",
					type = "group",
					order = 3,
					args = {
						ChatBG = {
							name = "Chatframe Color",
							desc = "Choose any Color for your Chat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.chat) end,
							set = function(_,r,g,b,a)
									db.Colors.chat = {r,g,b,a}
									module:Refresh_Chat()
								end,
							order = 19,
						},
						ChatBorder = {
							name = "Chatframe Bordercolor",
							desc = "Choose any Bordercolor for your Chat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.chatborder) end,
							set = function(_,r,g,b,a)
									db.Colors.chatborder = {r,g,b,a}
									module:Refresh_Chat()
								end,
							order = 20,
						},
						Chat2BG = {
							name = "2nd Chatframe Color",
							desc = "Choose any Color for your 2nd Chat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.chat2) end,
							set = function(_,r,g,b,a)
									db.Colors.chat2 = {r,g,b,a}
									module:Refresh_Chat()
								end,
							order = 21,
						},
						Chat2Border = {
							name = "2nd Chatframe Bordercolor",
							desc = "Choose any Bordercolor for your 2nd Chat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.chat2border) end,
							set = function(_,r,g,b,a)
									db.Colors.chat2border = {r,g,b,a}
									module:Refresh_Chat()
								end,
							order = 22,
						},
						TpsBG = {
							name = "Tps Color",
							desc = "Choose any Color for your Threat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.tps) end,
							set = function(_,r,g,b,a)
									db.Colors.tps = {r,g,b,a}
									module:Refresh_Tps()
								end,
							order = 23,
						},
						TpsBorder = {
							name = "Tps Bordercolor",
							desc = "Choose any Bordercolor for your Threat Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.tpsborder) end,
							set = function(_,r,g,b,a)
									db.Colors.tpsborder = {r,g,b,a}
									module:Refresh_Tps()
								end,
							order = 24,
						},
						DpsBG = {
							name = "Dps Color",
							desc = "Choose any Color for your Dps Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.dps) end,
							set = function(_,r,g,b,a)
									db.Colors.dps = {r,g,b,a}
									module:Refresh_Dps()
								end,
							order = 25,
						},
						DpsBorder = {
							name = "Dps Bordercolor",
							desc = "Choose any Bordercolor for your Dps Panel",
							type = "color",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							width = "full",
							hasAlpha = true,
							get = function() return unpack(db.Colors.dpsborder) end,
							set = function(_,r,g,b,a)
									db.Colors.dpsborder = {r,g,b,a}
									module:Refresh_Dps()
								end,
							order = 26,
						},
						RaidBG = {
							name = "Raid Color",
							desc = "Choose any Color for your Raid Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.raid) end,
							set = function(_,r,g,b,a)
									db.Colors.raid = {r,g,b,a}
									module:Refresh_Raid()
								end,
							order = 27,
						},
						RaidBorder = {
							name = "Raid Panel Bordercolor",
							desc = "Choose any Bordercolor for your Raid Panel",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Panels", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.raidborder) end,
							set = function(_,r,g,b,a)
									db.Colors.raidborder = {r,g,b,a}
									module:Refresh_Raid()
								end,
							order = 28,
						},
					},
				},
				Bars = {
					name = "Bars",
					type = "group",
					order = 4,
					args = {
						BarTop = {
							name = "Top Bar Texture Color",
							desc = "Choose any Color for your Top Bar Texture",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Bars", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.bar) end,
							set = function(_,r,g,b,a)
									db.Colors.bar = {r,g,b,a}
									module:Refresh_Bars()
								end,
							order = 1,
						},
						BarBottom = {
							name = "Bottom Bar Texture Color",
							desc = "Choose any Color for your Bottom Bar Texture",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Bars", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.bar2) end,
							set = function(_,r,g,b,a)
									db.Colors.bar2 = {r,g,b,a}
									module:Refresh_Bars()
								end,
							order = 2,
						},
						Sidebar = {
							name = "Sidebar Color",
							desc = "Choose any Color for your Sidebar",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Bars", true) end,
							get = function() return unpack(db.Colors.sidebar) end,
							set = function(_,r,g,b,a)
									db.Colors.sidebar = {r,g,b,a}
									module:Refresh_Sidebars()
								end,
							order = 3,
						},
					},
				},
				Navigation = {
					name = "Navigation",
					type = "group",
					order = 5,
					args = {
						Navigation = {
							name = "Top Navigation Button Color",
							desc = "Choose any Color for Top Navigation Buttons",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Frames", true) end,
							get = function() return unpack(db.Colors.navi) end,
							set = function(_,r,g,b,a)
									db.Colors.navi = {r,g,b,a}
									module:Refresh_NavigationColors()
								end,
							order = 12,
						},
						NavigationHover = {
							name = "Top Navigation Button Hover Color",
							desc = "Choose any Color for Top Navigation Buttons Hover Effect",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Frames", true) end,
							get = function() return unpack(db.Colors.navi_hover) end,
							set = function(_,r,g,b,a)
									db.Colors.navi_hover = {r,g,b,a}
									module:Refresh_NavigationHoverColors()
								end,
							order = 13,
						},
						OrbColors = {
							name = "Orb Color",
							desc = "Choose any Color for your Orb",
							type = "color",
							width = "full",
							hasAlpha = true,
							disabled = function() return not LUI:GetModule("Orb", true) end,
							get = function() return unpack(db.Colors.orb) end,
							set = function(_,r,g,b,a)
									db.Colors.orb = {r,g,b,a}
									module:Refresh_OrbColor()
								end,
							order = 16,
						},
						OrbCycleColors = {
							name = "Orb Background Color",
							desc = "Choose any Color for your Orb Background Textur",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Frames", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.orb_cycle) end,
							set = function(_,r,g,b,a)
									db.Colors.orb_cycle = {r,g,b,a}
									module:Refresh_OrbCycleColor()
								end,
							order = 17,
						},
						OrbHoverColors = {
							name = "Orb Hover Color",
							desc = "Choose any Color for your Orb Hover Effect",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Frames", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.orb_hover) end,
							set = function(_,r,g,b,a)
									db.Colors.orb_hover = {r,g,b,a}
									module:Refresh_OrbHoverColor()
								end,
							order = 18,
						},
					},
				},
				MicroMenu = {
					name = "MicroMenu",
					type = "group",
					order = 6,
					args = {
						MicroMenu = {
							name = "MicroMenu Color",
							desc = "Choose any MicroMenu Color",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Micromenu", true) end,
							hasAlpha = false,
							get = function() return unpack(db.Colors.micromenu) end,
							set = function(_,r,g,b)
									db.Colors.micromenu = {r,g,b}
									module:Refresh_Micromenu()
									module:Refresh_RaidMenu()
								end,
							order = 1,
						},
						MicroMenuBG = {
							name = "MicroMenu BG Color",
							desc = "Choose any MicroMenu Background Color.",
							type = "color",
							disabled = function() return not LUI:GetModule("Micromenu", true) end,
							width = "full",
							hasAlpha = true,
							get = function() return unpack(db.Colors.micromenu_bg) end,
							set = function(_,r,g,b,a)
									db.Colors.micromenu_bg = {r,g,b,a}
									module:Refresh_Micromenu()
									module:Refresh_RaidMenu()
								end,
							order = 2,
						},
						MicroMenuBG2 = {
							name = "MicroMenu 2nd BG Color",
							desc = "Choose any Second MicroMenu Background Color.",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Micromenu", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.micromenu_bg2) end,
							set = function(_,r,g,b,a)
									db.Colors.micromenu_bg2 = {r,g,b,a}
									module:Refresh_Micromenu()
									module:Refresh_RaidMenu()
								end,
							order = 3,
						},
						MicroMenuButton = {
							name = "MicroMenu Button Color",
							desc = "Choose any Color for your Micromenu Buttons",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Micromenu", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.micromenu_btn) end,
							set = function(_,r,g,b,a)
									db.Colors.micromenu_btn = {r,g,b,a}
									module:Refresh_Micromenu()
									module:Refresh_RaidMenu()
								end,
							order = 4,
						},
						MicroMenuButton_Hover = {
							name = "MicroMenu Button Hover Color",
							desc = "Choose any Color for your Micromenu Button Hover Effect",
							type = "color",
							width = "full",
							disabled = function() return not LUI:GetModule("Micromenu", true) end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.micromenu_btn_hover) end,
							set = function(_,r,g,b,a)
									db.Colors.micromenu_btn_hover = {r,g,b,a}
									module:Refresh_Micromenu()
									module:Refresh_RaidMenu()
								end,
							order = 5,
						},
					},
				},
				Misc = {
					name = "Misc",
					type = "group",
					order = 7,
					args = {
						EditBoxColor = {
							name = "Chat Editbox Color",
							desc = "Choose any Chat Editbox Color.",
							type = "color",
							width = "full",
							disabled = function() 
								if not LUI:GetModule("Chat", true) then
									return true
								elseif not db.Chat.Enable then
									return true
								else
									return false
								end
							end,
							hasAlpha = true,
							get = function() return unpack(db.Colors.editbox) end,
							set = function(_,r,g,b,a)
									db.Colors.editbox = {r,g,b,a}
									module:Refresh_Editbox()
								end,
							order = 6,
						},
					},
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	self.db = LUI.db.profile
	db = self.db
	
	if LUICONFIG.Versions.theme ~= version then
		LUI_Themes = LUI_Themes or {}
		for k, v in pairs(themes) do
			LUI_Themes[k] = nil
			LUI_Themes[k] = v
		end

		LUICONFIG.Versions.theme = version
	end
	
	self:CheckTheme()
	
	self:StaticPopups()
	
	LUI:RegisterOptions(self)
end