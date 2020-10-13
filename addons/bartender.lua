--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bartender.lua
	Description: Bartender 4 Install Script
	Version....: 1.0
]]

local addonname, LUI = ...

LUI.Versions.bartender = 3300

function LUI:InstallBartender()
	if not IsAddOnLoaded("Bartender4") then return end

	local CharName = UnitName("player")
	local ServerName = GetRealmName()
	local ProfileName = CharName.." - "..ServerName

	if LUI.db.global.luiconfig[ProfileName] and LUI.db.global.luiconfig[ProfileName].Versions.bartender == LUI.Versions.bartender then return end

	local BagBarDefaults = {
		[CharName] = {
			["skin"] = {
				["Colors"] = {
					["Normal"] = {0.203, 0.203, 0.203, 1},
					["Pushed"] = {1, 1, 1, 0.319},
					["Highlight"] = {1, 1, 1, 1},
					["Gloss"] = {0.980, 0.980, 0.980, 1},
					["Backdrop"] = {0.980, 1, 0.968, 1},
					["Border"] = {0.082, 1, 0.043, 1},
					["Checked"] = {0.988, 1, 0.984, 1},
				},
				["ID"] = "Caith",
				["Backdrop"] = false,
			},
			["enabled"] = false,
			["show"] = "alwayshide",
			["version"] = 3,
			["position"] = {
				["y"] = 6.869293713785169,
				["x"] = 62.96281414890549,
				["point"] = "LEFT",
			},
		},
	}

	for k,v in pairs(BagBarDefaults) do
		Bartender4DB.namespaces.BagBar.profiles[k] = v
	end

	local ActionBarsDefaults = {
		[CharName] = {
			["actionbars"] = {
				{ -- [1]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {1, 1, 1, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Flash"] = {1, 0, 0, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["version"] = 3,
					["alpha"] = 1,
					["position"] = {
						["y"] = 60,
						["x"] = -197,
						["point"] = "BOTTOM",
						["scale"] = 0.85,
					},
					["hidehotkey"] = true,
					["hidemacrotext"] = true,
					["visibility"] = {
						["always"] = false,
					},
					["states"] = {
						["actionbar"] = false,
					},
				}, -- [1]
				{ -- [2]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {1, 1, 1, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Flash"] = {1, 0, 0, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["hidehotkey"] = true,
					["alpha"] = 1,
					["version"] = 3,
					["position"] = {
						["y"] = 94,
						["x"] = -197,
						["point"] = "BOTTOM",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
					},
				}, -- [2]
				{ -- [3]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Disabled"] = {0.988, 1, 0.949, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {0.980, 0.980, 0.980, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["hidehotkey"] = true,
					["alpha"] = 1,
					["version"] = 3,
					["position"] = {
						["y"] = 173.326953106798,
						["x"] = 344.0160633672025,
						["point"] = "LEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [3]
				{ -- [4]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {1, 1, 1, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Flash"] = {1, 0, 0, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["hidehotkey"] = true,
					["alpha"] = 1,
					["version"] = 3,
					["position"] = {
						["y"] = -266.7948988830055,
						["x"] = 344.0160633672025,
						["point"] = "TOPLEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [4]
				{ -- [5]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {1, 1, 1, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Flash"] = {1, 0, 0, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["alpha"] = 1,
					["hidehotkey"] = true,
					["version"] = 3,
					["position"] = {
						["y"] = 209.326940513326,
						["x"] = 344.0160633672025,
						["point"] = "LEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,

						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [5]
				{ -- [6]
					["buttons"] = 12,
					["rows"] = 1,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {1, 1, 1, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Flash"] = {1, 0, 0, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["alpha"] = 1,
					["hidehotkey"] = true,
					["version"] = 3,
					["position"] = {
						["y"] = 245.3267011968378,
						["x"] = 344.0160633672025,
						["point"] = "LEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [6]
				{ -- [7]
					["buttons"] = 12,
					["rows"] = 6,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Disabled"] = {0.988, 1, 0.949, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {0.980, 0.980, 0.980, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["alpha"] = 1,
					["hidehotkey"] = true,
					["version"] = 3,
					["position"] = {
						["y"] = -210,
						["x"] = 20,
						["point"] = "TOPLEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [7]
				{ -- [8]
					["buttons"] = 12,
					["rows"] = 6,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Disabled"] = {0.988, 1, 0.949, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Gloss"] = {0.980, 0.980, 0.980, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["alpha"] = 1,
					["hidehotkey"] = true,
					["version"] = 3,
					["position"] = {
						["y"] = -210,
						["x"] = -90,
						["point"] = "TOPRIGHT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [8]
				{ -- [9]
					["buttons"] = 12,
					["rows"] = 6,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Gloss"] = {1, 1, 1, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
							["Flash"] = {1, 0, 0, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Disabled"] = {0.988, 1, 0.949, 1},
						},
						["ID"] = "Darion",
						["Gloss"] = 0.3,
					},
					["enabled"] = false,
					["alpha"] = 1,
					["version"] = 3,
					["hidehotkey"] = true,
					["position"] = {
						["y"] = 95,
						["x"] = 20,
						["point"] = "LEFT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["possess"] = false,
						["always"] = false,
						["vehicleui"] = false,
					},
				}, -- [9]
				{ -- [10]
					["buttons"] = 12,
					["rows"] = 6,
					["skin"] = {
						["Colors"] = {
							["Normal"] = {0.133, 0.133, 0.133, 0.950},
							["Pushed"] = {0.321, 0.321, 0.321, 1},
							["Checked"] = {0.011, 0.011, 0.011, 0},
							["Highlight"] = {0.403, 0.403, 0.403, 1},
							["Backdrop"] = {0.109, 0.109, 0.109, 1},
							["Border"] = {0.407, 0.403, 0.411, 1},
						},
						["Gloss"] = 0.3,
						["ID"] = "Darion",
					},
					["enabled"] = false,
					["alpha"] = 1,
					["version"] = 3,
					["hidehotkey"] = true,
					["position"] = {
						["y"] = 95,
						["x"] = -90,
						["point"] = "RIGHT",
						["scale"] = 0.85,
					},
					["hidemacrotext"] = true,
					["visibility"] = {
						["always"] = false,
						["possess"] = false,
						["vehicleui"] = false,
					},
				}, -- [10]
			},
		},
	}

	do
		--ActionBarsDefaults[CharName].actionbars[10]
		local bardb = LUI:Module("Bars").db.profile
		if bardb.SidebarRight1.Enable and strsub(bardb.SidebarRight1.Anchor, 1, 3) == "BT4" then
			local _, num = strsplit("r", bardb.SidebarRight1.Anchor)
			local barOpt = ActionBarsDefaults[CharName].actionbars[tonumber(num)]
			barOpt.enabled = true
		end
		if bardb.SidebarRight2.Enable and strsub(bardb.SidebarRight2.Anchor, 1, 3) == "BT4" then
			local _, num = strsplit("r", bardb.SidebarRight2.Anchor)
			local barOpt = ActionBarsDefaults[CharName].actionbars[tonumber(num)]
			barOpt.enabled = true
		end
		if bardb.SidebarLeft1.Enable and strsub(bardb.SidebarLeft1.Anchor, 1, 3) == "BT4" then
			local _, num = strsplit("r", bardb.SidebarLeft1.Anchor)
			local barOpt = ActionBarsDefaults[CharName].actionbars[tonumber(num)]
			barOpt.enabled = true
		end
		if bardb.SidebarLeft2.Enable and strsub(bardb.SidebarLeft2.Anchor, 1, 3) == "BT4" then
			local _, num = strsplit("r", bardb.SidebarLeft2.Anchor)
			local barOpt = ActionBarsDefaults[CharName].actionbars[tonumber(num)]
			barOpt.enabled = true
		end
	end

	for k,v in pairs(ActionBarsDefaults) do
		Bartender4DB.namespaces.ActionBars.profiles[k] = v
	end

	local VehicleDefaults = {
		[CharName] = {
			["version"] = 3,
			["fadeoutalpha"] = 1,
			["skin"] = {
				["Colors"] = {
					["Normal"] = {0.133, 0.133, 0.133, 0.950},
					["Pushed"] = {0.321, 0.321, 0.321, 1},
					["Highlight"] = {0.403, 0.403, 0.403, 1},
					["Checked"] = {0.011, 0.011, 0.011, 0},
					["Gloss"] = {1, 1, 1, 1},
					["Border"] = {0.407, 0.403, 0.411, 1},
					["Backdrop"] = {0.109, 0.109, 0.109, 1},
					["Flash"] = {1, 0, 0, 1},
				},
				["Gloss"] = 0.3,
				["ID"] = "Darion",
			},
			["fadeoutdelay"] = 1,
			["padding"] = 0,
			["visibility"] = {
				["nopet"] = false,
				["always"] = false,
				["possess"] = false,
			},
			["position"] = {
				["y"] = -184.1292338095927,
				["x"] = 432.4822981234832,
				["point"] = "LEFT",
				["scale"] = 0.9,
			},
		},
	}

	for k,v in pairs(VehicleDefaults) do
		Bartender4DB.namespaces.Vehicle.profiles[k] = v
	end

	local StanceBarDefaults = {
		[CharName] = {
			["position"] = {
				["y"] = -16.50000411188517,
				["x"] = -82.49990584837293,
				["point"] = "CENTER",
				["scale"] = 1,
			},
			["skin"] = {
				["Colors"] = {
					["Normal"] = {0.133, 0.133, 0.133, 0.950},
					["Pushed"] = {0.321, 0.321, 0.321, 1},
					["Highlight"] = {0.403, 0.403, 0.403, 1},
					["Gloss"] = {1, 1, 1, 1},
					["Backdrop"] = {0.109, 0.109, 0.109, 1},
					["Flash"] = {1, 0, 0, 1},
					["Border"] = {0.407, 0.403, 0.411, 1},
					["Checked"] = {0.011, 0.011, 0.011, 0},
					["Disabled"] = {0.988, 1, 0.949, 1},
				},
				["Gloss"] = 0.3,
				["ID"] = "Darion",
			},
			["enabled"] = false,
			["padding"] = 1,
			["visibility"] = {
				["possess"] = false,
				["always"] = false,
				["stance"] = {
					false, -- [1]
				},
			},
			["version"] = 3,
		},
	}

	for k,v in pairs(StanceBarDefaults) do
		Bartender4DB.namespaces.StanceBar.profiles[k] = v
	end

	local PetBarDefaults = {
		[CharName] = {
			["rows"] = 2,
			["hidemacrotext"] = true,
			["position"] = {
				["y"] = 295,
				["x"] = -195,
				["point"] = "BOTTOMRIGHT",
				["scale"] = 0.8999999761581421,
			},
			["version"] = 3,
			["visibility"] = {
				["always"] = false,
			},
			["skin"] = {
				["Colors"] = {
					["Normal"] = {0.133, 0.133, 0.133, 0.950},
					["Pushed"] = {0.321, 0.321, 0.321, 1},
					["Highlight"] = {0.450, 0.450, 0.450, 1},
					["Gloss"] = {1, 1, 1, 1},
					["Backdrop"] = {0.109, 0.109, 0.109, 1},
					["Flash"] = {1, 0, 0, 1},
					["Border"] = {0.407, 0.403, 0.411, 1},
					["Checked"] = {
						0.6, -- [1]
						0.6, -- [2]
						0.6, -- [3]
						1, -- [4]
					},
					["Disabled"] = {0.988, 1, 0.949, 1},
				},
				["ID"] = "Darion",
				["Gloss"] = 0.3,
			},
		},
	}

	for k,v in pairs(PetBarDefaults) do
		Bartender4DB.namespaces.PetBar.profiles[k] = v
	end

	local MicroMenuDefaults = {
		[CharName] = {
			["enabled"] = false,
			["version"] = 3,
			["show"] = "alwayshide",
			["skin"] = {
				["Colors"] = {
					["Normal"] = {0.133, 0.133, 0.133, 1},
					["Border"] = {0.392, 0.388, 0.396, 1},
				},
				["ID"] = "Caith",
				["Backdrop"] = false,
			},
			["position"] = {
				["y"] = -257.398563614586,
				["x"] = 21.58512786494109,
				["point"] = "LEFT",
				["scale"] = 0.800000011920929,
			},
		},
	}

	for k,v in pairs(MicroMenuDefaults) do
		Bartender4DB.namespaces.MicroMenu.profiles[k] = v
	end

	local BTProfilesDefaults = {
		[CharName] = {
			["minimapIcon"] = {
				["minimapPos"] = 268,
				["radius"] = 80,
				["hide"] = true,
			},
			["buttonlock"] = true,
		},
	}

	for k,v in pairs(BTProfilesDefaults) do
		Bartender4DB.profiles[k] = v
	end

	if Bartender4DB.profileKeys[ProfileName] == nil then
		tinsert(Bartender4DB.profileKeys,ProfileName)
		Bartender4DB.profileKeys[ProfileName] = CharName
	elseif Bartender4DB.profileKeys[ProfileName] ~= CharName then
		Bartender4DB.profileKeys[ProfileName] = CharName
	end
	Bartender4:UpdateModuleConfigs()

	if LUI.db.global.luiconfig[ProfileName].Versions then LUI.db.global.luiconfig[ProfileName].Versions.bartender = LUI.Versions.bartender end
end
