--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: forte.lua
	Description: ForteXorcist Module
	Version....: 1.975-v1.5
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Forte")
local _, class = UnitClass("player")
local _G = _G;

local db;
local FW = _G.FW;
local UIParent = _G.UIParent;

LUI_versions.forte = "v1.975"; -- major version - DON'T change this for just every FX version, because it will prompt a 'restore'

local LR = {"LEFT","RIGHT"};
local TB = {"TOP","BOTTOM"};

local defaults = {
	Forte = {
		IndividualColor = true,
		Color = {0.24,0.24,0.24},
		
		Player = {
			Enable = true,
			Lock = true,
			PaddingX = "0",
			PaddingY = "0",
		},
		Target = {
			Enable = true,
			Lock = true,
			PaddingX = "0",
			PaddingY = "0",
		},
		Focus = {
			Enable = false,
			Lock = true,
			PaddingX = "0",
			PaddingY = "0",
		},
		Compact = {
			Location = "LEFT",
			Enable = false,
			Lock = true,
			PaddingX = "4",
			PaddingY = "-170",
		},
		Cooldown = {
			Enable = true,
			Lock = true,
			PaddingX = "0",
			PaddingY = "120",
		},
		Splash = {
			Location = "BOTTOM",
			Enable = true,
			Lock = true,
			PaddingX = "0",
			PaddingY = "250",
		},
	},
}

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
		anchor = {"oUF_LUI_target","TOPRIGHT"},
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

function module:FXLoaded()
	return IsAddOnLoaded("Forte_Core") and FW.VERSION and FW.VERSION >= LUI_versions.forte; -- don't run if FX is too old...
end

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
	return FW.Settings.Timer.Instances[self:GetTimerIndexByName(name)];
end
function module:GetCooldown() -- should be replaced by proper function once cooldown cloning is enabled
	return FW.Settings.Cooldown.Instances[1];
end
function module:GetSplash() -- should be replaced by proper function once cooldown cloning is enabled
	return FW.Settings.Splash.Instances[1];
end

function module:SetFrameProps(instance,name)
	local properties = timer_instances[name];
	local uiScale = UIParent:GetEffectiveScale();
	local x,y;
	local width = 50;
	local paddingX,paddingY = tonumber(db.Forte[name].PaddingX),tonumber(db.Forte[name].PaddingY);
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
			if frame and db.oUF[name][setting].Enable and db.oUF[name][setting].Lock then
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
		if db.Forte.Compact.Location == "RIGHT" then
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

function module:SetPosForte()
	if not LUI.isForteTimerLoaded or not db.oUF.Settings.Enable then return end

	for name, data in pairs(timer_instances) do
		if db.Forte[name].Enable and db.Forte[name].Lock then
			local instance = module:GetTimerByName(name);
			if instance then
				module:SetFrameProps(instance,name);
			end
		end
	end
	
	FW:RefreshFrames();
end

function module:SetPosForteCooldown()
	if not LUI.isForteCooldownLoaded or not db.Forte.Cooldown.Lock then return end
	
	local uiScale = UIParent:GetEffectiveScale()
	local x = (UIParent:GetWidth() * uiScale / 2) + tonumber(db.Forte.Cooldown.PaddingX)
	local y = tonumber(db.Forte.Cooldown.PaddingY) * uiScale
	
	local instance = module:GetCooldown();
	instance.x = x;
	instance.y = y;

	FW:RefreshFrames();
end

function module:SetPosForteSplash()
	if not LUI.isForteCooldownLoaded or not db.Forte.Splash.Lock then return end
	local x,y;
	local uiScale = UIParent:GetEffectiveScale()
	x = tonumber(db.Forte.Splash.PaddingX) + UIParent:GetWidth() / 2;
	if db.Forte.Splash.Location == "TOP" then
		y = UIParent:GetHeight() - tonumber(db.Forte.Splash.PaddingY);
	else
		y = tonumber(db.Forte.Splash.PaddingY);
	end
	local instance = module:GetSplash();
	instance.x = x * uiScale;
	instance.y = y * uiScale;

	FW:RefreshFrames();
end

function module:SetColors()
	if not LUI.isForteTimerLoaded then return end
	
	module:Copy(db.Forte.Color,FW.Settings.TimerColorOverride);
	FW.Settings.TimerColorOverride[0] = db.Forte.IndividualColor;
	
	FW:RefreshOptions(); -- at most update FX options frame, no need to refresh all frames atm
end

function module:SetForte()
	if not FW.Settings then
		FW:RegisterVariablesEvent(module.SetForte);
		return;
	end
	local created_new = false;
	if LUI.isForteTimerLoaded then
		for name, data in pairs(timer_instances) do
			local instance, enable = module:GetTimerByName(name), db.Forte[name].Enable;
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
		instance.Enable = db.Forte["Cooldown"].Enable;
		module:SetPosForteCooldown();

		instance = module:GetSplash();
		instance.Enable = db.Forte["Splash"].Enable;
		module:SetPosForteSplash();
	end
	-- live update FX options panel if it's open
	if created_new then
		FW:BuildOptions();
	end
	module:SetColors(); -- includes a FW:RefreshOptions();
end
function LUI:InstallForte()
	if not module:FXLoaded() then return end
	if LUICONFIG.Versions.forte == LUI_versions.forte and LUICONFIG.IsForteInstalled == true then return end
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
	
	LUICONFIG.Versions.forte = LUI_versions.forte
	LUICONFIG.IsForteInstalled = true
end

local function ConfigureForte()
	LUI:InstallForte()
	ReloadUI()
end

local function SetForte() -- only done on new major version
	LUICONFIG.Versions.forte = LUI_versions.forte; -- don't ask again
	-- disable the new frames that are enabled by default
	if LUI_versions.forte == "v1.975" then
		db.Forte.Player.Enable = false;
		db.Forte.Target.Enable = false;
	end
	module:SetForte();
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	StaticPopupDialogs["INSTALL_FORTE"] = {
	  text = "%s",
	  button1 = YES,
	  button2 = NO,
	  OnAccept = ConfigureForte,
	  timeout = 0,
	  whileDead = 1,
	  hideOnEscape = 1
	}
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterAddon(self, "Forte_Core")
end

local function CreateCooldowntimerAnimation()
	if LUI.isForteCooldownLoaded then
		if not FW.Settings then
			FW:RegisterVariablesEvent(CreateCooldowntimerAnimation);
			return;
		end
		-- copy of code that was located in the bars module:
		local bb_timerout,bb_timerin = 0,0
		local bb_animation_time = 0.5
		local bb_at_out = 0.25
			
		local bb_SlideIn = CreateFrame("Frame", nil, UIParent)
		bb_SlideIn:Hide()
			
		bb_SlideIn:SetScript("OnUpdate", function(self,elapsed)
			bb_timerin = bb_timerin + elapsed
			local bb_x = tonumber(db.Bars.TopTexture.X)
			local bb_y = tonumber(db.Bars.TopTexture.Y)
			local bb_pixelpersecond = tonumber(db.Bars.TopTexture.AnimationHeight) * 2
			if bb_timerin < bb_animation_time then
				local y2 = bb_y - bb_timerin * bb_pixelpersecond + bb_pixelpersecond * bb_animation_time
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, y2)
			else
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, bb_y)
				bb_timerin = 0
				self:Hide()
			end
		end)

		local bb_SlideOut = CreateFrame("Frame", nil, UIParent)
		bb_SlideOut:Hide()
		
		bb_SlideOut:SetScript("OnUpdate", function(self,elapsed)
			bb_timerout = bb_timerout + elapsed
			local bb_x = tonumber(db.Bars.TopTexture.X)
			local bb_y = tonumber(db.Bars.TopTexture.Y)
			local bb_ppx_out = tonumber(db.Bars.TopTexture.AnimationHeight) * 3
			local bb_yout = tonumber(db.Bars.TopTexture.Y) + tonumber(db.Bars.TopTexture.AnimationHeight)
			if bb_timerout < bb_at_out then
				local y2 = bb_y + bb_timerout * bb_ppx_out
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, y2)
			else
				BarsBackground:ClearAllPoints()
				BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", bb_x, bb_yout)
				bb_timerout = 0
				self:Hide()
			end
		end)
		local bb_Forte = CreateFrame("Frame", nil, UIParent)
		bb_Forte:Show()
		
		local isOut = false
		bb_Forte:SetScript("OnUpdate", function(self)
			if db.Forte.Cooldown.Lock and _G.FX_Cooldown1 then
				if _G.FX_Cooldown1:IsShown() and not isOut then
					if db.Bars.TopTexture.Animation then
						bb_SlideOut:Show()
						isOut = true
					end
				elseif not _G.FX_Cooldown1:IsShown() and isOut then
					if db.Bars.TopTexture.Animation then
						bb_SlideIn:Show()
						isOut = false
					end
				end
			end
		end)
	end
end

function module:OnEnable()
	if module:FXLoaded() then
		LUI.isForteTimerLoaded = IsAddOnLoaded("Forte_Timer") ~= nil;
		LUI.isForteCooldownLoaded = IsAddOnLoaded("Forte_Cooldown") ~= nil;
		
		if LUICONFIG.IsConfigured then
			local extra = "\n\nDo you want to apply all LUI Styles to ForteXorcist Spelltimer/Cooldowntimer?\n\nThis will create a new FX profile for LUI (if it hasn't already) and apply LUI's defaults to it, including new timer frames!\n\nYou can also set the LUI defaults later by going to 'General > Addons > Restore ForteXorcist' in the LUI config.";
			if LUICONFIG.IsForteInstalled then
				if LUICONFIG.Versions.forte ~= LUI_versions.forte then
					StaticPopupDialogs["INSTALL_FORTE"].OnCancel = SetForte; -- run SetForte on cancel to create new instances anyway
					StaticPopup_Show("INSTALL_FORTE","New major version of ForteXorcist found!"..extra);
				else
					module:SetForte();
				end
				CreateCooldowntimerAnimation(); -- if forte is installed properly
				FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForte);
				FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForteCooldown);
				FW:RegisterToEvent("UI_SCALE_CHANGED",module.SetPosForteSplash);
			else
				StaticPopup_Show("INSTALL_FORTE","ForteXorcist Addon found!"..extra);
			end
		end
	end
end

function module:LoadOptions()
	local options = {
		Forte = {
			name = "ForteXorcist",
			type = "group",
			order = 70,
			childGroups = "tab",
			disabled = function() return not module:FXLoaded(); end,
			args = {
				Spelltimer = {
					name = "Spell Timer",
					type = "group",
					childGroups = "tab",
					disabled = function() return not LUI.isForteTimerLoaded; end,
					order = 2,
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
											get = function() return db.Forte.IndividualColor end,
											set = function(self,val)
													db.Forte.IndividualColor = val;
													module:SetColors();
												end,
											order = 2,
										},
										Color = {
											name = "Bar Color",
											desc = "Choose a global Bar Color.",
											type = "color",
											width = "full",
											disabled = function() return not db.Forte.IndividualColor end,
											hasAlpha = false,
											get = function() return unpack(db.Forte.Color) end,
											set = function(_,r,g,b)
													db.Forte.Color[1],db.Forte.Color[2],db.Forte.Color[3] = r,g,b;
													module:SetColors();
												end,
											order = 4,
										},
									},
								},
							},
						},
						Player = {
							name = "Player",
							desc = "This frame can be attached to the Player frame and show important buffs/debuffs on yourself, spells without a target and some important cooldowns.",
							type = "group",
							order = 2,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable this buff/debuff frame.",
									type = "toggle",
									get = function() return db.Forte.Player.Enable end,
									set = function(self,val)
											db.Forte.Player.Enable = val
											module:SetForte()
										end,
									order = 1,
								},
								FXOptions = {
									desc = "Go to all ForteXorcist options for this frame",
									name = "Toggle FX Options",
									type = "execute",
									func = function()
										FW:ScrollTo(FW.L.SPELL_TIMER,nil,module:GetTimerIndexByName("Player"));
									end,
									order = 2,
								},
								Position = {
									name = "Position",
									type = "group",
									order = 3,
									guiInline = true,
									args = {
										ForteLock = {
											name = "Lock position",
											desc = "Whether the frame should stick to the location assigned by LUI or not.",
											type = "toggle",
											width = "full",
											get = function() return db.Forte.Player.Lock end,
											set = function(self,val)
													db.Forte.Player.Lock = val
													if val then
														module:SetPosForte()
													end
												end,
											order = 1,
										},
										PaddingX = {
											name = "Padding X",
											desc = "Choose the X Padding for this frame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Player.PaddingX,
											type = "input",
											get = function() return db.Forte.Player.PaddingX end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Player.PaddingX = val
													module:SetPosForte()
												end,
											order = 2,
										},
										PaddingY = {
											name = "Padding Y",
											desc = "Choose the Y Padding for this frame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Player.PaddingY,
											type = "input",
											get = function() return db.Forte.Player.PaddingY end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Player.PaddingY = val
													module:SetPosForte()
												end,
											order = 3,
										},
									},
								},
							},
						},
						Target = {
							name = "Target",
							desc = "This frame can be attached to the target frame and show important buffs/debuffs on your target.",
							type = "group",
							order = 3,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable this buff/debuff frame.",
									type = "toggle",
									get = function() return db.Forte.Target.Enable end,
									set = function(self,val)
											db.Forte.Target.Enable = val
											module:SetForte()
										end,
									order = 1,
								},
								FXOptions = {
									desc = "Go to all ForteXorcist options for this frame",
									name = "Toggle FX Options",
									type = "execute",
									func = function()
										FW:ScrollTo(FW.L.SPELL_TIMER,nil,module:GetTimerIndexByName("Target"));
									end,
									order = 2,
								},
								Position = {
									name = "Position",
									type = "group",
									order = 3,
									guiInline = true,
									args = {
										ForteLock = {
											name = "Lock position",
											desc = "Whether the frame should stick to the location assigned by LUI or not.",
											type = "toggle",
											width = "full",
											get = function() return db.Forte.Target.Lock end,
											set = function(self,val)
													db.Forte.Target.Lock = val
													if val then
														module:SetPosForte()
													end
												end,
											order = 1,
										},
										PaddingX = {
											name = "Padding X",
											desc = "Choose the X Padding for this frame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Target.PaddingX,
											type = "input",
											get = function() return db.Forte.Target.PaddingX end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Target.PaddingX = val
													module:SetPosForte()
												end,
											order = 2,
										},
										PaddingY = {
											name = "Padding Y",
											desc = "Choose the Y Padding for this frame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Target.PaddingY,
											type = "input",
											get = function() return db.Forte.Target.PaddingY end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Target.PaddingY = val
													module:SetPosForte()
												end,
											order = 3,
										},
									},
								},
							},
						},
						Focus = {
							name = "Focus",
							desc = "This frame can be attached to the focus frame and show important buffs/debuffs on your focus.",
							type = "group",
							order = 4,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable this buff/debuff frame.",
									type = "toggle",
									get = function() return db.Forte.Focus.Enable end,
									set = function(self,val)
											db.Forte.Focus.Enable = val
											module:SetForte()
										end,
									order = 1,
								},
								FXOptions = {
									desc = "Go to all ForteXorcist options for this frame",
									name = "Toggle FX Options",
									type = "execute",
									func = function()
										FW:ScrollTo(FW.L.SPELL_TIMER,nil,module:GetTimerIndexByName("Focus"));
									end,
									order = 2,
								},
								Position = {
									name = "Position",
									type = "group",
									order = 3,
									guiInline = true,
									args = {
										ForteLock = {
											name = "Lock position",
											desc = "Whether the frame should stick to the location assigned by LUI or not.",
											type = "toggle",
											width = "full",
											get = function() return db.Forte.Focus.Lock end,
											set = function(self,val)
													db.Forte.Focus.Lock = val
													if val then
														module:SetPosForte()
													end
												end,
											order = 1,
										},
										PaddingX = {
											name = "Padding X",
											desc = "Choose the X Padding for this frame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Focus.PaddingX,
											type = "input",
											get = function() return db.Forte.Focus.PaddingX end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Focus.PaddingX = val
													module:SetPosForte()
												end,
											order = 2,
										},
										PaddingY = {
											name = "Padding Y",
											desc = "Choose the Y Padding for this frame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Focus.PaddingY,
											type = "input",
											get = function() return db.Forte.Focus.PaddingY end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Focus.PaddingY = val
													module:SetPosForte()
												end,
											order = 3,
										},
									},
								},
							},
						},
						Compact = {
							name = "Compact",
							desc = "Will show a compact timer frame with important spells on multiple units.",
							type = "group",
							order = 5,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable this buff/debuff frame.",
									type = "toggle",
									get = function() return db.Forte.Compact.Enable end,
									set = function(self,val)
											db.Forte.Compact.Enable = val
											module:SetForte()
										end,
									order = 1,
								},
								FXOptions = {
									desc = "Go to all ForteXorcist options for this frame",
									name = "Toggle FX Options",
									type = "execute",
									func = function()
										FW:ScrollTo(FW.L.SPELL_TIMER,nil,module:GetTimerIndexByName("Compact"));
									end,
									order = 2,
								},
								Position = {
									name = "Position",
									type = "group",
									order = 3,
									guiInline = true,
									args = {
										ForteLock = {
											name = "Lock position",
											desc = "Whether the frame should stick to the location assigned by LUI or not.",
											type = "toggle",
											width = "full",
											get = function() return db.Forte.Compact.Lock end,
											set = function(self,val)
													db.Forte.Compact.Lock = val
													if val then
														module:SetPosForte()
													end
												end,
											order = 1,
										},
										PaddingX = {
											name = "Padding X",
											desc = "Choose the X Padding for this frame.\n\nDefault: "..LUI.defaults.profile.Forte.Compact.PaddingX,
											type = "input",
											get = function() return db.Forte.Compact.PaddingX end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Compact.PaddingX = val
													module:SetPosForte()
												end,
											order = 2,
										},
										PaddingY = {
											name = "Padding Y",
											desc = "Choose the Y Padding for this frame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Compact.PaddingY,
											type = "input",
											get = function() return db.Forte.Compact.PaddingY end,
											set = function(self,val)
													if val == nil or val == "" then
														val = "0"
													end
													db.Forte.Compact.PaddingY = val
													module:SetPosForte()
												end,
											order = 3,
										},
										Location = {
											name = "Anchor Location",
											desc = "Choose the anchor location for the Compact frame. Should it be on the left or on the right of your screen?",
											type = "select",
											values = LR,
											get = function()
													for k, v in ipairs(LR) do
														if db.Forte.Compact.Location == v then
															return k;
														end
													end
												end,
											set = function(self, val)
													db.Forte.Compact.Location = LR[val];
													module:SetPosForte();
												end,
											order = 4,
										},
									},
								},
							},
						},
						
					},
				},
				Cooldowntimer = {
					name = "Cooldown Timer",
					type = "group",
					disabled = function() return not LUI.isForteCooldownLoaded; end,
					order = 3,
					args = {
						Enable = {
							name = "Enable",
							desc = "Enable the Cooldown Timer.",
							type = "toggle",
							get = function() return db.Forte.Cooldown.Enable end,
							set = function(self,val)
									db.Forte.Cooldown.Enable = val
									module:SetForte()
								end,
							order = 1,
						},
						FXOptions = {
							desc = "Go to all ForteXorcist options for this frame",
							name = "Toggle FX Options",
							type = "execute",
							func = function()
								FW:ScrollTo(FW.L.COOLDOWN_TIMER);
							end,
							order = 2,
						},
						Position = {
							name = "Position",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								Lock = {
									name = "Lock Cooldown Timer",
									desc = "Whether the Cooldown Timer should stick to your Bar or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.Cooldown.Lock end,
									set = function(self,val)
											db.Forte.Cooldown.Lock = val
											if val then
												module:SetPosForteCooldown()
											end
										end,
									order = 1,
								},
								PaddingX = {
									name = "Padding X",
									desc = "Choose the X Padding for your Forte Cooldowntimer.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Cooldown.PaddingX,
									type = "input",
									get = function() return db.Forte.Cooldown.PaddingX end,
									set = function(self,val)
											if val == nil or val == "" then
												val = "0"
											end
											db.Forte.Cooldown.PaddingX = val
											module:SetPosForteCooldown();
										end,
									order = 2,
								},
								PaddingY = {
									name = "Padding Y",
									desc = "Choose the Y Padding for your Forte Cooldowntimer.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Forte.Cooldown.PaddingY,
									type = "input",
									get = function() return db.Forte.Cooldown.PaddingY end,
									set = function(self,val)
											if val == nil or val == "" then
												val = "0"
											end
											db.Forte.Cooldown.PaddingY = val
											module:SetPosForteCooldown()
										end,
									order = 3,
								},
							},
						},
					},
				},
				Splash = {
					name = "Cooldown Splash",
					type = "group",
					disabled = function() return not LUI.isForteCooldownLoaded; end,
					order = 3,
					args = {
						Enable = {
							name = "Enable",
							desc = "Enable the Cooldown Splash.",
							type = "toggle",
							get = function() return db.Forte.Splash.Enable end,
							set = function(self,val)
									db.Forte.Splash.Enable = val
									module:SetForte()
								end,
							order = 1,
						},
						FXOptions = {
							desc = "Go to all ForteXorcist options for this frame",
							name = "Toggle FX Options",
							type = "execute",
							func = function()
								FW:ScrollTo(FW.L.SECONDARY_SPLASH);
							end,
							order = 2,
						},
						Position = {
							name = "Position",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								Lock = {
									name = "Lock Cooldown Splash",
									desc = "Whether the frame should stick to the location assigned by LUI or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Forte.Splash.Lock end,
									set = function(self,val)
											db.Forte.Splash.Lock = val;
											if val then
												module:SetPosForteSplash();
											end
										end,
									order = 1,
								},
								PaddingX = {
									name = "Padding X",
									desc = "Choose the X Padding for your Cooldown Splash.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Forte.Splash.PaddingX,
									type = "input",
									get = function() return db.Forte.Splash.PaddingX end,
									set = function(self,val)
											if val == nil or val == "" then
												val = "0"
											end
											db.Forte.Splash.PaddingX = val
											module:SetPosForteSplash();
										end,
									order = 2,
								},
								PaddingY = {
									name = "Padding Y",
									desc = "Choose the Y Padding for your Cooldown Splash.\n\nDefault: "..LUI.defaults.profile.Forte.Splash.PaddingY,
									type = "input",
									get = function() return db.Forte.Splash.PaddingY end,
									set = function(self,val)
											if val == nil or val == "" then
												val = "0";
											end
											db.Forte.Splash.PaddingY = val;
											module:SetPosForteSplash();
										end,
									order = 3,
								},
								Location = {
									name = "Anchor Location",
									desc = "Choose the anchor location for the Splash frame. Should it be on the top or on the bottom of your screen?",
									type = "select",
									values = TB,
									get = function()
											for k, v in ipairs(TB) do
												if db.Forte.Splash.Location == v then
													return k;
												end
											end
										end,
									set = function(self, val)
											db.Forte.Splash.Location = TB[val];
											module:SetPosForteSplash();
										end,
									order = 4,
								},
							},
						},
					},
				},
			},
		},
	}
	return options;
end

LUI:GetModule("Bars").CreateCooldowntimerAnimation = function(self) return end --kill the old function in the bars module