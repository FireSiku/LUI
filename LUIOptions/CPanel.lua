-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type LUIAddon
local LUI = Opt.LUI
local L = LUI.L

local IsShiftKeyDown = _G.IsShiftKeyDown

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function GenerateModuleButtons()
    local args = {}
    for name, mod in LUI:IterateModules() do
        if mod.enableButton then
			args[name] = Opt:EnableButton({name = name, desc = L["Core_ModuleClickHint"],
				enableFunc = function() return mod:IsEnabled() end,
				func = function(info, btn)
					if IsShiftKeyDown() then
						mod.db:ResetProfile()
						mod:ModPrint(L["Core_ModuleReset"])
					else
						if mod.VToggle then mod:VToggle()
						elseif mod.Toggle then mod:Toggle()
						end
						mod:ModPrint( (mod:IsEnabled()) and L["API_BtnEnabled"] or L["API_BtnDisabled"])
						StaticPopup_Show("RELOAD_UI")
					end
				end
			})
        end
    end
    return args
end

local infotext = LUI:GetModule("Infotext", true)
local function GenerateInfotextButtons()
	local args = {}
	for name, obj in infotext.LDB:DataObjectIterator() do
		args[name] = Opt:EnableButton({name = name,
			enableFunc = function() return true end,
			func = function() infotext:ToggleInfotext(name) end
		})
	end
	return args
end

local addonMod = LUI:GetModule("Addons", true)
local function GenerateAddonSupportButtons()
	local args = {}
	args.Desc = Opt:Desc({name = L["CPanel_AddonDesc"]})
	args.Break = Opt:Spacer({width = "full"})
	for name, mod in addonMod:IterateModules() do
		args[name] = Opt:Execute({name = format(L["CPanel_AddonReset"], name),
			func = function()
				--addonMod.db.Installed[name] = nil
				addonMod:OnEnable()
			end
		})
	end
	return args
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

-- local Cooldown = Opt:CreateModuleOptions("Cooldown", LUI)
Opt.options.args.CPanel = Opt:Group("Control Panel", nil, 3, "tab")
Opt.options.args.CPanel.handler = LUI
local CPanel = {
	Modules = Opt:Group({name = L["CPanel_Modules"], args = GenerateModuleButtons()}),
	Infotext = Opt:Group({name = L["CPanel_Infotext"], disabled = function() return infotext and infotext.registered end}),
	Addons = Opt:Group({name = L["CPanel_Addons"], disabled = function() return addonMod and addonMod.registered end}),
}

if infotext and infotext.registered then CPanel.Infotext.args = GenerateInfotextButtons() end
if addonMod and addonMod.registered then CPanel.Addons.args = GenerateAddonSupportButtons() end

Opt.options.args.CPanel.args = CPanel
