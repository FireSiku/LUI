--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: forte.lua
	Description: ForteXorcist Module
	Version....: 1.975-v1.6
]] 

local addonname, LUI = ...
local module = LUI:Module("Forte", "AceHook-3.0")
local Bars = LUI:Module("Bars")

local _, class = UnitClass("player")
local _G = _G

local db, dbd
local FW = _G.FW
local UIParent = _G.UIParent

LUI.Versions.forte = "v1.975"; -- major version - DON'T change this for just every FX version, because it will prompt a 'restore'

------------------------------------------------------
-- / LOCAL VARIABLES / --
------------------------------------------------------

local LR = {"LEFT","RIGHT"};
local TB = {"TOP","BOTTOM"};

local global_settings = {
	GlobalFrameNames = true,
	ShardEnable = false,
	SummonEnable = false,
	SoulstoneEnable = false,
	HealthstoneEnable = false,
}

local timer_settings = {
	lock = true,
	scale = 1,
	NormalBgColor = {0.00,0.00,0.00,0.75},
	StacksFont = {"Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",11,"OUTLINE"},
	Font = {"Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",11},
	Height = 18,
	Texture = "Interface\\AddOns\\LUI\\media\\textures\\statusbars\\Minimalist",
	LabelFont = {"Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",11},
}

local cooldown_settings = {
	lock = true,
	scale = 1,
	Loga = 0.255,
	Tags = 5,
	CustomTags = {[0]=false,"0 1 10 30 60 120 300 600"},
	BgColor = {0,0,0,0},
	Font = {"Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",11},
	IconFont = {"Interface\\AddOns\\LUI\\media\\fonts\\vibrocen.ttf",11,"OUTLINE"},
	IconTime = false,
	Texture = "Interface\\AddOns\\LUI\\media\\textures\\statusbars\\Minimalist",
	Width = 384,
	Height = 28,
	Hide = true,
}

local splash_settings = {
	lock = true,
	Enable = true,
	SecondSplashMax = 3,
	scale = 2,
}

local timer_instances = {
	Player = {
		anchor = {"oUF_LUI_player"},
		offset = {
			DEATHKNIGHT = {"Runes","Runes"},
			SHAMAN = {"Totems","TotemBar",1},
			DRUID = {"Eclipse","EclipseBar"},
			PALADIN = {"HolyPower","HolyPower"},
			WARLOCK = {"SoulShards","SoulShards"},
		},
		settings = {
			Spell = true,
			Label = false,
			Target = false,
			Focus = false,
			Other = false,
			NoTarget = true,
			UnknownTarget = false,
			You = true,
			RaidDebuffs = false,
		}
	},
	Target = {
		anchor = {"oUF_LUI_target", "TOPRIGHT"},
		settings = {
			Spell = true,
			Label = false,
			Target = true,
			Focus = false,
			Other = false,
			NoTarget = false,
			UnknownTarget = false,
			You = false,
			RaidDebuffs = true,
		}
	},
	Focus = {
		anchor = {"oUF_LUI_focus"},
		settings = {
			Spell = true,
			Label = false,
			Target = false,
			Focus = true,
			Other = false,
			NoTarget = false,
			UnknownTarget = false,
			You = false,
			RaidDebuffs = false,
		}
	},
	Compact = {
		settings = {
			Spell = true,
			Label = true,
			RaidTargets = {[0]=true,0.7},
			CastSpark = {[0]=false,0.3},
			Spark = {[0]=false,0.7},
			Name = false,
			LabelLimit = true,
			Target = true,
			Focus = true,
			Other = true,
			NoTarget = false,
			UnknownTarget = false,
			You = false,
			RaidDebuffs = false,
		}
	},
}

------------------------------------------------------
-- / LOCAL FUNCTIONS / --
------------------------------------------------------

local function AnimateTopBGBar(frame, elapsed)
	frame.dt = frame.dt + elapsed
	
	local point, parent, rpoint = frame:GetPoint()
	local x, y = Bars.db.TopTexture.X, Bars.db.TopTexture.Y
	local animheight = Bars.db.TopTexture.AnimationHeight
	local y2
	
	if frame.dt < frame.end_anim then
		y2 = animheight * (frame.dt / frame.end_anim)
		if not frame.moveout then
			y2 = animheight - y2
		end
	else
		frame:SetScript("OnUpdate", nil)
		y2 = frame.moveout and animheight or 0
	end
	
	frame:SetPoint(point, parent, rpoint, x, y + y2)
end

local function CreateCooldowntimerAnimation()
	if LUI.isForteCooldownLoaded then
		if not FW.Settings then
			FW:RegisterVariablesEvent(CreateCooldowntimerAnimation);
			return;
		end
		
		local topbar = LUIBarsTopBG
		local FXCD = _G.FX_Cooldown1
		
		if FXCD and not module:IsHooked(FXCD, "OnShow") then
			module:HookScript(FXCD, "OnShow", function()
				if db.Cooldown.Lock and Bars.db.TopTexture.Animation then
					topbar.dt = 0
					topbar.end_anim = 0.25
					topbar.moveout = true
					topbar:SetScript("OnUpdate", AnimateTopBGBar)
				end
			end)
			module:HookScript(FXCD, "OnHide", function()
				if db.Cooldown.Lock and Bars.db.TopTexture.Animation then
					topbar.dt = 0
					topbar.end_anim = 0.5
					topbar.moveout = false
					topbar:SetScript("OnUpdate", AnimateTopBGBar)
				end
			end)
		end
		--[[
		
		-- copy of code that was located in the bars module:
		local timerout,timerin = 0,0
		local anim_time_out, anim_time_in = 0.25, 0.5
			
		local bb_SlideIn = CreateFrame("Frame", nil, UIParent)
		bb_SlideIn:Hide()
			
		bb_SlideIn:SetScript("OnUpdate", function(self,elapsed)
			timerin = timerin + elapsed
			local point, parent, rpoint = BarsBackground:GetPoint()
			local x = tonumber(Bars.db.TopTexture.X)
			local y = tonumber(Bars.db.TopTexture.Y)
			local pixelpersec = tonumber(Bars.db.TopTexture.AnimationHeight) * 2
			if timerin < anim_time_in then
				local y2 = y - timerin * pixelpersec + pixelpersec * anim_time_in
				BarsBackground:SetPoint(point, parent, rpoint, x, y2)
			else
				BarsBackground:SetPoint(point, parent, rpoint, x, bb_y)
				timerin = 0
				self:Hide()
			end
		end)

		local bb_SlideOut = CreateFrame("Frame", nil, UIParent)
		bb_SlideOut:Hide()
		
		bb_SlideOut:SetScript("OnUpdate", function(self,elapsed)
			timerout = timerout + elapsed
			local bb_x = tonumber(Bars.db.TopTexture.X)
			local bb_y = tonumber(Bars.db.TopTexture.Y)
			local bb_ppx_out = tonumber(Bars.db.TopTexture.AnimationHeight) * 3
			local bb_yout = tonumber(Bars.db.TopTexture.Y) + tonumber(Bars.db.TopTexture.AnimationHeight)
			if timerout < anim_time_out then
				local y2 = bb_y + timerout * bb_ppx_out
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, y2)
			else
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, bb_yout)
				timerout = 0
				self:Hide()
			end
		end)
		local bb_Forte = CreateFrame("Frame", nil, UIParent)
		bb_Forte:Show()
		
		local isOut = false
		bb_Forte:SetScript("OnUpdate", function(self)
			if db.Cooldown.Lock and _G.FX_Cooldown1 then
				if _G.FX_Cooldown1:IsShown() and not isOut then
					if Bars.db.TopTexture.Animation then
						bb_SlideOut:Show()
						isOut = true
					end
				elseif not _G.FX_Cooldown1:IsShown() and isOut then
					if Bars.db.TopTexture.Animation then
						bb_SlideIn:Show()
						isOut = false
					end
				end
			end
		end)]]
	end
end

local function ConfigureForte()
	LUI:InstallForte()
	ReloadUI()
end

local function SetupForte() -- only done on new major version
	LUICONFIG.Versions.forte = LUI.Versions.forte; -- don't ask again
	-- disable the new frames that are enabled by default
	if LUI.Versions.forte == "v1.975" then
		db.Player.Enable = false;
		db.Target.Enable = false;
	end
	module:SetForte();
end

------------------------------------------------------
-- / LUI INSTALL FUNCTION / --
------------------------------------------------------

function LUI:InstallForte()
	if not module:FXLoaded() then return end
	if LUICONFIG.Versions.forte == LUI.Versions.forte and LUICONFIG.IsForteInstalled == true then return end
	if not FW.Settings then
		FW:RegisterVariablesEvent(LUI.InstallForte);
		return;
	end
	local LUIprofileOld = UnitName("Player");
	local LUIprofileNew = "LUI: "..LUIprofileOld;
	local created_new = false;
	
	local index = FW:InstanceNameToIndex(LUIprofileNew,FW.Saved.Profiles);
	if not index then
		index = FW:InstanceNameToIndex(LUIprofileOld,FW.Saved.Profiles);
		if index then
			FW:InstanceRename(index,LUIprofileNew,FW.Saved.Profiles);
		else
			index = FW:InstanceCreate(LUIprofileNew,FW.Saved.Profiles,global_settings);
			created_new = true;
		end
	end
	FW:UseProfile( index );
	
	if not created_new then
		module:Copy(FW.Default,FW.Settings); -- FX
		module:Copy(global_settings,FW.Settings); -- global
	end
				
	-- disable Spell Timer instances that LUI won't use on install
	if LUI.isForteTimerLoaded then
		for index, instance in ipairs(FW.Settings.Timer.Instances) do
			if not timer_instances[ FW:InstanceIndexToName(index,FW.Settings.Timer) ] then
				instance.Enable = false;
			end
		end
		 -- restore defaults
		for name, data in pairs(timer_instances) do
			local instance = module:GetTimerByName(name);
			if instance then
				module:Copy(FW.InstanceDefault.Timer,instance); -- FX
				module:Copy(timer_settings,instance); -- global
				module:Copy(data.settings,instance); -- instance
			end
		end
	end
	-- restore defaults
	if LUI.isForteCooldownLoaded then
		module:Copy(FW.InstanceDefault.Cooldown,module:GetCooldown() ); -- FX
		module:Copy(cooldown_settings,module:GetCooldown() ); -- global
		module:Copy(FW.InstanceDefault.Splash,module:GetSplash() ); -- FX
		module:Copy(splash_settings,module:GetSplash() ); -- global
	end
	
	LUICONFIG.Versions.forte = LUI.Versions.forte
	LUICONFIG.IsForteInstalled = true
end

------------------------------------------------------
-- / FORTE FUNCTIONS / --
------------------------------------------------------

function module:Copy(from,to) -- copies contents from table 'from' to table 'to'
	for key, val in pairs(from) do
		if type(val) == "table" then
			if type(to[key]) ~= "table" then
				to[key] = {};
			end
			self:Copy(val,to[key]);
		else
			to[key] = val;
		end
	end
end
function module:GetTimerIndexByName(name)
	return FW:InstanceNameToIndex(name,FW.Settings.Timer,1);-- set to case sensitive
end
function module:GetTimerByName(name)
	return FW.Settings.Timer.Instances[module:GetTimerIndexByName(name)];
end
function module:GetCooldown() -- should be replaced by proper function once cooldown cloning is enabled
	return FW.Settings.Cooldown.Instances[1];
end
function module:GetSplash() -- should be replaced by proper function once cooldown cloning is enabled
	return FW.Settings.Splash.Instances[1];
end

------------------------------------------------------
-- / MODULE FUNCTIONS / --
------------------------------------------------------

function module:FXLoaded()
	return IsAddOnLoaded("Forte_Core") and FW.VERSION and FW.VERSION >= LUI.Versions.forte; -- don't run if FX is too old...
end

function module:RegisterForteEvents() -- no self in this func (Forte_Core OnEvent callbacks)
	if not FW.Settings then
		FW:RegisterVariablesEvent(module.RegisterForteCallbacks);
		return;
	end
	FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForte);
	FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForteCooldown);
	FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForteSplash);
end

function module:SetFrameProps(instance,name)
	local properties = timer_instances[name];
	local uiScale = UIParent:GetEffectiveScale();
	local x,y;
	local width = 50;
	local paddingX,paddingY = tonumber(db[name].PaddingX),tonumber(db[name].PaddingY);
	if properties.anchor then
		local f = _G[ properties.anchor[1] ];
		if not f then
			return; -- don't update anything if anchor frame is missing...
		end
		width = f:GetWidth()*f:GetScale();
		if properties.anchor[2] == "TOPRIGHT" then -- add target timer to the right of the frame
			x = f:GetRight() + width/2 + 4;
		else
			x = f:GetLeft() + width/2;
		end
		y = f:GetBottom() + f:GetHeight()*f:GetScale() + instance.Height/2*instance.scale + 4;
		
		if properties.offset and properties.offset[class] then
			local setting,frame,index = unpack(properties.offset[class]);
			frame = f[frame]; -- frame = index and f[frame][index] or f[frame];
			if frame and LUI.db.profile.oUF[name][setting].Enable and LUI.db.profile.oUF[name][setting].Lock then
				if index then 
					frame = frame[index];
				end
				if frame:IsShown() then
					y = y + frame:GetHeight()*frame:GetScale();
				end
			end
		end
		
		x = x + paddingX;
		y = y + paddingY;
	else -- anchor compact frame to right side
		paddingX = math.abs(paddingX); -- ignore negative values here
		if db.Compact.Location == "RIGHT" then
			x = UIParent:GetWidth() - width/2 -paddingX;
		else
			x = width/2 + paddingX;
		end
		y = UIParent:GetHeight()/ 2 + paddingY;
	end
	instance.Width = width/instance.scale;
	instance.x = x*uiScale;
	instance.y = y*uiScale;
end

function module:SetPosForte() -- no self in this func (Forte_Core OnEvent callbacks)
	if not LUI.isForteTimerLoaded or not LUI.db.profile.oUF.Settings.Enable then return end

	for name, data in pairs(timer_instances) do
		if db[name].Enable and db[name].Lock then
			local instance = module:GetTimerByName(name);
			if instance then
				module:SetFrameProps(instance,name);
			end
		end
	end
	
	FW:RefreshFrames();
end

function module:SetPosForteCooldown() -- no self in this func (Forte_Core OnEvent callbacks)
	if not LUI.isForteCooldownLoaded or not db.Cooldown.Lock then return end
	
	local uiScale = UIParent:GetEffectiveScale()
	local x = (UIParent:GetWidth() * uiScale / 2) + tonumber(db.Cooldown.PaddingX)
	local y = tonumber(db.Cooldown.PaddingY) * uiScale
	
	local instance = module:GetCooldown();
	instance.x = x;
	instance.y = y;

	FW:RefreshFrames();
end

function module:SetPosForteSplash() -- no self in this func (Forte_Core OnEvent callbacks)
	if not LUI.isForteCooldownLoaded or not db.Splash.Lock then return end
	local x,y;
	local uiScale = UIParent:GetEffectiveScale()
	x = tonumber(db.Splash.PaddingX) + UIParent:GetWidth() / 2;
	if db.Splash.Location == "TOP" then
		y = UIParent:GetHeight() - tonumber(db.Splash.PaddingY);
	else
		y = tonumber(db.Splash.PaddingY);
	end
	local instance = module:GetSplash();
	instance.x = x * uiScale;
	instance.y = y * uiScale;

	FW:RefreshFrames();
end

function module:SetColors()
	if not LUI.isForteTimerLoaded then return end
	
	module:Copy(db.Color,FW.Settings.TimerColorOverride);
	FW.Settings.TimerColorOverride[0] = db.IndividualColor;
	
	FW:RefreshOptions(); -- at most update FX options frame, no need to refresh all frames atm
end

function module:SetForte() -- no self in this func (Forte_Core OnEvent callbacks)
	if not FW.Settings then
		FW:RegisterVariablesEvent(module.SetForte);
		return;
	end
	local created_new = false;
	if LUI.isForteTimerLoaded then
		for name, data in pairs(timer_instances) do
			local instance, enable = module:GetTimerByName(name), db[name].Enable;
			if not instance and enable then
				local index = FW:InstanceCreate(name, FW.Settings.Timer, data.settings);
				FW.Modules.Timer:NewTimerInstance(index); -- create the new frame and its options
				instance = FW.Settings.Timer.Instances[index];
				module:Copy(timer_settings,instance);
				created_new = true;
			end
			if instance then
				instance.Enable = enable;
			end
		end
		module:SetPosForte();
	end
	
	if LUI.isForteCooldownLoaded then
		local instance = module:GetCooldown();
		instance.Enable = db["Cooldown"].Enable;
		module:SetPosForteCooldown();

		instance = module:GetSplash();
		instance.Enable = db["Splash"].Enable;
		module:SetPosForteSplash();
	end
	-- live update FX options panel if it's open
	if created_new then
		FW:BuildOptions();
	end
	module:SetColors(); -- includes a FW:RefreshOptions();
	
	-- hook into the FX options panel to disable positioning
	if not module:IsHooked(FW, "BuildOptions") then
		local function printNotification(frame, ...)
			local parent = frame.parent.parent
			local instance = parent.instance
			if instance then
				if instance.s.lock == false then return module.hooks[frame].OnClick(frame) end -- lock it
				
				local dbcheck = instance.instanceof
				if dbcheck == "Timer" then
					dbcheck = FW:InstanceIndexToName(instance.index, FW.Settings.Timer)
				end
				
				if type(db[dbcheck]) == "table" and db[dbcheck].Lock then
					LUI:Print("Use the options in LUI to move the ForteXorcist " .. (instance.instanceof == "Timer" and dbcheck.." " or "") .. FW.Options[parent.index][1])
					if frame == frame.parent.coordinates then
						frame:ClearFocus()
					end
					return
				end
			end
			
			if frame == frame.parent.coordinates then
				return module.hooks[frame].OnEnterPressed(frame, ...)
			else
				return module.hooks[frame].OnClick(frame, ...)
			end
		end
		
		module:RawHook(FW, "BuildOptions", function()
			module.hooks[FW]:BuildOptions() -- Post Hook
			
			for i = 1, #FW.Options do
				if FW.Options[i][6] == "Timer" or db[FW.Options[i][6]] then
					if FW.Options[i].option and FW.Options[i].option.frameheader then
						local lockOption = FW.Options[i].option.frameheader.lock
						if lockOption and not module:IsHooked(lockOption, "OnClick") then
							module:RawHookScript(lockOption, "OnClick", printNotification)
						end
						
						local coordOption = FW.Options[i].option.frameheader.coordinates
						if coordOption and not module:IsHooked(coordOption, "OnEnterPressed") then
							module:RawHookScript(coordOption, "OnEnterPressed", printNotification)
						end
						
						local posOption = FW.Options[i].option.frameheader.position
						if posOption and not module:IsHooked(posOption, "OnClick") then
							module:RawHookScript(posOption, "OnClick", printNotification)
						end
					end
				end
			end
		end)
	end
end

------------------------------------------------------
-- / MODULE FUNCTIONS / --
------------------------------------------------------

module.optionsName = "ForteXorcist"
module.order = 70
module.addon = "Forte_Core"
module.defaults = {
	profile = {
		Enable = module:FXLoaded(),
		IndividualColor = true,
		Color = {0.24,0.24,0.24},
		
		Player = {
			Enable = true,
			Lock = true,
			PaddingX = 0,
			PaddingY = 0,
		},
		Target = {
			Enable = true,
			Lock = true,
			PaddingX = 0,
			PaddingY = 0,
		},
		Focus = {
			Enable = false,
			Lock = true,
			PaddingX = 0,
			PaddingY = 0,
		},
		Compact = {
			Location = "LEFT",
			Enable = false,
			Lock = true,
			PaddingX = 4,
			PaddingY = -170,
		},
		Cooldown = {
			Enable = true,
			Lock = true,
			PaddingX = 0,
			PaddingY = 120,
		},
		Splash = {
			Location = "BOTTOM",
			Enable = true,
			Lock = true,
			PaddingX = 0,
			PaddingY = 250,
		},
	},
}


function module:LoadOptions()
	local moduleName = module:GetName()
	
	local function fxModuleDisabled(info)
		for i, v in ipairs(info) do
			if v == moduleName then
				local isSpellTimer = info[i+1] == "SpellTimer"
				return not db[info[i+(isSpellTimer and 2 or 1)]].Enable
			end
		end
	end
	local function lockDisabled(info)
		return not db[info[#info-2]].Lock
	end
	local function forteTimerDisabled()
		return not LUI.isForteTimerLoaded
	end
	local function forteCooldownDisabled()
		return not LUI.isForteCooldownLoaded
	end
	
	local function isNumber(info, value)
		if value == nil or value:trim() == "" or not tonumber(value) then
			return "Please input a number."
		end
		return true
	end
	
	local function getName(info)
		return info[#info]
	end
	local function getDefault(info)
		for i, v in ipairs(info) do
			if v == moduleName then
				local isSpellTimer = info[i+1] == "SpellTimer"
				return dbd[info[i+(isSpellTimer and 2 or 1)]][info[#info]]
			end
		end
	end
	local function getValue(info)
		for i, v in ipairs(info) do
			if v == moduleName then
				local isSpellTimer = info[i+1] == "SpellTimer"
				return db[info[i+(isSpellTimer and 2 or 1)]][info[#info]]
			end
		end
	end
	local function getNumValue(info)
		return tostring(getValue(info))
	end
	local function setValue(info, value)
		for i, v in ipairs(info) do
			if v == moduleName then
				local isSpellTimer = info[i+1] == "SpellTimer"
				db[info[i+(isSpellTimer and 2 or 1)]][info[#info]] = value
				break
			end
		end
	end
	
	local function setForte(info, value)
		setValue(info, value)
		module:SetForte()
	end
	local function setPosForte(info, value)
		value = tonumber(value) or value
		setValue(info, value)
		if value then
			for i, v in ipairs(info) do
				if v == moduleName then
					if info[i+1] == "SpellTimer" then
						module:SetPosForte()
					else
						module["SetPosForte"..info[i+1]]()
					end
					break
				end
			end
		end
	end
	
	local scrollTable = {
		SpellTimer = "SPELL_TIMER",
		Cooldown = "COOLDOWN_TIMER",
		Splash = "SECONDARY_SPLASH",
	}
	local function fxOptionsFunc(info)
		local goto, unit = info[#info-1]
		if info[#info-2] == "SpellTimer" then
			unit = module:GetTimerIndexByName(goto)
			goto = info[#info-2]
		end
		FW:ScrollTo(FW.L[scrollTable[goto]], nil, unit)
	end
	local function newFXOptionsButton(order)
		order = order or 2
			
		local option = {
			name = "Toggle FX Options",
			desc = "Open ForteXorcist options for this frame",
			type = "execute",
			disabled = fxModuleDisabled,
			func = fxOptionsFunc,
			order = order,
		}
		
		return option
	end
	
	local function newPosOptions(order,location)
		order = order or 3
		
		local option = {
			name = "Position",
			type = "group",
			order = order,
			guiInline = true,
			disabled = fxModuleDisabled,
			args = {
				Lock = {
					name = "Use LUI position",
					desc = "Whether the frame should stick to the location assigned by LUI or not.",
					type = "toggle",
					width = "full",
					get = getValue,
					set = setPosForte,
					order = 1,
				},
				PaddingX = {
					name = "Padding X",
					desc = function(info) return "Choose the X Padding for this frame.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: " .. getDefault(info) end,
					type = "input",
					disabled = lockDisabled,
					validate = isNumber,
					get = getNumValue,
					set = setPosForte,
					order = 2,
				},
				PaddingY = {
					name = "Padding Y",
					desc = function(info) return "Choose the Y Padding for this frame.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: " .. getDefault(info) end,
					type = "input",
					disabled = lockDisabled,
					validate = isNumber,
					get = getNumValue,
					set = setPosForte,
					order = 3,
				},
				Location = location and {
					name = "Anchor Location",
					desc = "Choose the anchor location for this frame.",
					type = "select",
					disabled = lockDisabled,
					values = location,
					get = function(self)
						local val = getValue(self);
						for k, v in ipairs(location) do
							if val == v then
								return k;
							end
						end
					end,
					set = function(self, val)
						setPosForte(self, location[val] );
					end,
					order = 4,
				},
			},
		}
		
		return option
	end
	
	local function newSpellTimerOption(order, desc, location)
		local option = {
			name = getName,
			desc = desc,
			type = "group",
			order = order,
			args = {
				Enable = {
					name = "Enable",
					desc = "Enable this buff/debuff frame.",
					type = "toggle",
					get = getValue,
					set = setForte,
					order = 1,
				},
				FXOptions = newFXOptionsButton(),
				Position = newPosOptions(nil,location),
			},
		}
		
		return option
	end
	
	local options = {
		SpellTimer = {
			name = "Spell Timer",
			type = "group",
			childGroups = "tab",
			disabled = forteTimerDisabled,
			order = 1,
			args = {
				Global = {
					name = "All frames",
					type = "group",
					order = 1,
					--guiInline = true,
					args = {
						Colors = {
							name = "Bar Colors",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								--[[header1 = {
									name = "Bar Color",
									type = "header",
									order = 1,
								},]]
								IndividualColor = {
									name = "Global Color",
									desc = "Whether you want to use a global Color for all your tracked Buffs/Debuffs or not.\n\nNote: If you want different colors for each of your spells please disable this and type /fx to enter ForteXorcist Options and go to Spelltimer -> Coloring/Filtering",
									type = "toggle",
									width = "full",
									get = function() return db.IndividualColor end,
									set = function(info, value)
											db.IndividualColor = value
											module:SetColors()
										end,
									order = 2,
								},
								Color = {
									name = "Bar Color",
									desc = function(info)
											local color = dbd.Color
											return "Choose a global Bar Color.\n\nDefault:\nr = " .. color[1] .. "\ng = " .. color[2] .. "\nb = " .. color[3]
										end,
									type = "color",
									width = "full",
									disabled = function() return not db.IndividualColor end,
									hasAlpha = false,
									get = function() return unpack(db.Color) end,
									set = function(info, r, g, b)
											db.Color = {r, g, b}
											module:SetColors()
										end,
									order = 4,
								},
							},
						},
					},
				},
				Player = newSpellTimerOption(2, "This frame can be attached to the Player frame and show important buffs/debuffs on yourself, spells without a target and some important cooldowns."),
				Target = newSpellTimerOption(3, "This frame can be attached to the target frame and show important buffs/debuffs on your target."),
				Focus = newSpellTimerOption(4, "This frame can be attached to the focus frame and show important buffs/debuffs on your focus."),
				Compact = newSpellTimerOption(5, "Will show a compact timer frame with important spells on multiple units.",LR),
			},
		},
		Cooldown = {
			name = "Cooldown Timer",
			type = "group",
			disabled = forteCooldownDisabled,
			order = 2,
			args = {
				Enable = {
					name = "Enable",
					desc = "Enable the Cooldown Timer.",
					type = "toggle",
					get = getValue,
					set = setForte,
					order = 1,
				},
				FXOptions = newFXOptionsButton(),
				Position = newPosOptions(),
			},
		},
		Splash = {
			name = "Cooldown Splash",
			type = "group",
			disabled = forteCooldownDisabled,
			order = 3,
			args = {
				Enable = {
					name = "Enable",
					desc = "Enable the Cooldown Splash.",
					type = "toggle",
					get = getValue,
					set = setForte,
					order = 1,
				},
				FXOptions = newFXOptionsButton(),
				Position = newPosOptions(nil,TB),
			},
		},
	}
	
	return options;
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)
	
	StaticPopupDialogs["INSTALL_FORTE"] = {
		text = "%s",
		button1 = YES,
		button2 = NO,
		OnAccept = ConfigureForte,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}
end

function module:OnEnable()
	LUI.isForteTimerLoaded = IsAddOnLoaded("Forte_Timer") ~= nil;
	LUI.isForteCooldownLoaded = IsAddOnLoaded("Forte_Cooldown") ~= nil;
	
	local extra = "\n\nDo you want to apply all LUI Styles to ForteXorcist Spelltimer/Cooldowntimer?\n\nThis will create a new FX profile for LUI (if it hasn't already) and apply LUI's defaults to it, including new timer frames!\n\nYou can also set the LUI defaults later by going to 'General > Addons > Restore ForteXorcist' in the LUI config.";
	if LUICONFIG.IsForteInstalled then
		if LUICONFIG.Versions.forte ~= LUI.Versions.forte then
			StaticPopupDialogs["INSTALL_FORTE"].OnCancel = SetupForte; -- run SetForte on cancel to create new instances anyway
			StaticPopup_Show("INSTALL_FORTE","New major version of ForteXorcist found!"..extra);
		else
			module:SetForte();
		end
		CreateCooldowntimerAnimation(); -- if forte is installed properly
		module:RegisterForteEvents();
	else
		StaticPopup_Show("INSTALL_FORTE","ForteXorcist Addon found!"..extra);
	end
end

function module:OnDisable()
end
