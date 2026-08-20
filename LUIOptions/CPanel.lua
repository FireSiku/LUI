-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@class LUIAddon
local LUI = Opt.LUI
local L = LUI.L

local IsShiftKeyDown = _G.IsShiftKeyDown

local CPanel = Opt:CreateModuleOptions("Control Panel", LUI)
CPanel.order = 3

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function CreateModuleButton(name, mod, order)
	if mod.enableButton then
		return Opt:EnableButton({name = name, desc = L["Core_ModuleClickHint"],
			order = order,
			enableFunc = function() return mod:IsEnabled() end,
			func = function(info, btn)
				if IsShiftKeyDown() then
					mod.db:ResetProfile()
					mod:ModPrint(L["Core_ModuleReset"])
				else
					if mod.VToggle then mod:VToggle()
					elseif mod.Toggle then mod:Toggle()
					end
					mod:ModPrint((mod:IsEnabled()) and L["API_BtnEnabled"] or L["API_BtnDisabled"])
					StaticPopup_Show("RELOAD_UI")
				end
			end
		})
	end

	return Opt:Execute({
		name = function() return format("%s: |cff00ff00Always Enabled|r", name) end,
		desc = "This core component is always enabled and has no module toggle.",
		order = order,
		func = function() end,
	})
end

local function GenerateModuleButtons()
    local args = {}
	local modules = {}
	for name, mod in LUI:IterateModules() do
		-- LUI modules are registered before the load-on-demand options addon is
		-- loaded. Build a concrete AceConfig args table here; this embedded
		-- AceConfig version does not accept a function for a group's args field.
		if mod.registered then
			table.insert(modules, {name = name, mod = mod})
		end
	end
	table.sort(modules, function(a, b) return a.name < b.name end)

	for order, entry in ipairs(modules) do
		local name, mod = entry.name, entry.mod
		args[name] = CreateModuleButton(name, mod, order)
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

CPanel.args = {
	Modules = Opt:Group({name = L["CPanel_Modules"], args = GenerateModuleButtons()}),
	Infotext = Opt:Group({name = L["CPanel_Infotext"], disabled = function() return not (infotext and infotext.registered) end}),
	Addons = Opt:Group({name = L["CPanel_Addons"], disabled = function() return not (addonMod and addonMod.registered) end}),
}

if infotext and infotext.registered then CPanel.args.Infotext.args = GenerateInfotextButtons() end
if addonMod and addonMod.registered then CPanel.args.Addons.args = GenerateAddonSupportButtons() end
