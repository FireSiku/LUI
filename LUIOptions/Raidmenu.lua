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
	["Auto-Hide"] = L["Auto-Hide"],
	["Offset"] = L["Offset"],
}

local function IsUsingAutoHide() return db.OverlapPrevention == "AutoHide" end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.RaidMenu = Opt:Group("Raid Menu", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.RaidMenu.handler = module

local RaidMenu = {
    -- General
    Header = Opt:Header(L["Raid Menu"], 1),
	
	Compact = Opt:Toggle(L["Compact Raid Menu"], L["Use compact version of the Raid Menu"], 2),

	Spacing = Opt:Slider(L["Spacing"], L["MicroOptions_Spacing_Desc"], 3, { min = 0, max = 10, step = 1}),
	Scale = Opt:Slider(L["Scale"], L["ize of the Raid Menu"], 4, Opt.ScaleValues),
	Spacer1 = Opt:Spacer(5),
	OverlapPrevention = Opt:Select(L["Micromenu Overlap Prevention"], L["\n\nAuto-Hide: The MicroMenu or Raid Menu should hide when the other is opened\n\nOffset: The Raid Menu should offset itself when the MicroMenu is open"],
								   11, OverlapPreventionMethods),
	X_Offset = Opt:Slider(L["X Offset"], L["How far to horizontally offset when the MicroMenu is open"], 12, { min = -200, max = 200, step = 1}, nil, IsUsingAutoHide),
	Offset = Opt:Slider(L["Y Offset"], L["How far to horizontally offset when the MicroMenu is open"], 13, { min = -200, max = 200, step = 1}, nil, IsUsingAutoHide),
	Spacer2 = Opt:Spacer(15),
	Opacity = Opt:Slider(L["Opacity"], L["How far to vertically offset when the MicroMenu is open"], 21, { min = 20, max = 100, step = 10}, nil, IsUsingAutoHide),
	AutoHide = Opt:Toggle(L["Auto-Hide Raid Menu"], L["Wether or not the Raid Menu should hide itself after clicking on a function"], 22, nil, "full"),
	ShowTooltips = Opt:Toggle(L["Show Tooltips"], L["Wether or not to show tooltips for the Raid Menu tools"], 23, nil, "full"),
	ToggleRaidIcon = Opt:Toggle(L["Toggle Raid Icon"], L["Wether of not Raid Target Icons can be removed by applying the icon the target already has"], 24, nil, "full"),
}

Opt.options.args.RaidMenu.args = RaidMenu