-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("RaidMenu")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local OverlapPreventionMethods = {
	AutoHide = L["AutoHide"],
	Offset = L["Offset"],
}

local function IsUsingAutoHide() return db.OverlapPrevention == "AutoHide" end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.RaidMenu = Opt:Group("Raid Menu", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.RaidMenu.handler = module

local RaidMenu = {
    -- General
    Header = Opt:Header({name = L["Raid Menu"]}),
	
	Compact = Opt:Toggle({name = L["Compact Raid Menu"], desc = L["Use compact version of the Raid Menu"]}),

	Spacing = Opt:Slider({name = L["Spacing"], desc = L["MicroOptions_Spacing_Desc"], min = 0, max = 10, step = 1}),
	Scale = Opt:Slider({name = L["Scale"], desc = L["ize of the Raid Menu"], values = Opt.ScaleValues}),
	Spacer1 = Opt:Spacer({}),
	OverlapPrevention = Opt:Select({name = L["Micromenu Overlap Prevention"], values = OverlapPreventionMethods,
		desc = L["\n\nAuto-Hide: The MicroMenu or Raid Menu should hide when the other is opened\n\nOffset: The Raid Menu should offset itself when the MicroMenu is open"]}),
	X_Offset = Opt:Slider({name = L["X Offset"], desc = L["How far to horizontally offset when the MicroMenu is open"], min = -200, max = 200, step = 1, disabled = IsUsingAutoHide}),
	Offset = Opt:Slider({name = L["Y Offset"], desc = L["How far to horizontally offset when the MicroMenu is open"], min = -200, max = 200, step = 1, disabled = IsUsingAutoHide}),
	Spacer2 = Opt:Spacer({}),
	Opacity = Opt:Slider({name = L["Opacity"], desc = L["How far to vertically offset when the MicroMenu is open"], min = 20, max = 100, step = 10, disabled = IsUsingAutoHide}),
	AutoHide = Opt:Toggle({name = L["Auto-Hide Raid Menu"], desc = L["Wether or not the Raid Menu should hide itself after clicking on a function"], width = "full"}),
	ShowTooltips = Opt:Toggle({name = L["Show Tooltips"], desc = L["Wether or not to show tooltips for the Raid Menu tools"], width = "full"}),
	ToggleRaidIcon = Opt:Toggle({name = L["Toggle Raid Icon"], desc = L["Wether of not Raid Target Icons can be removed by applying the icon the target already has"], width = "full"}),
}

Opt.options.args.RaidMenu.args = RaidMenu
