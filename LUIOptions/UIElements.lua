-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("UIElements")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################



-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.UIElements = Opt:Group("UI Elements", nil, nil, "tab", true, nil, Opt.GetSet(db))
Opt.options.args.UIElements.handler = module
local UIElements = {

}

Opt.options.args.UIElements.args = UIElements

--[[
    local function DisablePosition(info)
		local parent = info[#info-1]
		return not db[parent].ManagePosition
	end
	local options = {
		Header = module:NewHeader("UI Elements", 1),
		--Note: Displaying a tree group inside of a tree group just results in collapsable entries
		--      instead of displaying two tree lists.
		--The only way around that is to make a tab group and then have its childs be a tree list.
		Elements = module:NewGroup("UI Elements", 2, "tree", nil, {
			ObjectiveTracker = module:NewGroup("ObjectiveTracker", 1, nil, nil, {
				Desc = module:NewDesc("As of currently, these options requires a Reload UI.",1),
				HeaderColor = module:NewToggle("Color Headers by Class", nil, 2),
				ManagePosition = module:NewToggle("Manage Position", nil, 3, "Refresh"),
				Offset = module:NewPosition("ObjectiveTracker", 4, nil, "Refresh", nil, DisablePosition),
			}),
			DurabilityFrame = module:NewGroup("DurabilityFrame", 2, nil, nil, {
				Desc = module:NewDesc("This frame shows a little armored guy when equipment breaks.", 1),
				HideFrame = module:NewToggle("Hide This Frame", nil, 2, "Refresh"),
				ManagePosition = module:NewToggle("Manage Position", nil, 3, "Refresh"),
				Position = module:NewPosition("DurabilityFrame", 4, true, "Refresh", nil, DisablePosition),
			}),
			OrderHallCommandBar = module:NewGroup("OrderHallCommandBar", 2, nil, nil, {
				Desc = module:NewDesc("This frame shows a bar at the top when you are in your class halls.", 1),
				HideFrame = module:NewToggle("Hide This Frame", nil, 2),
			}),
		}),
	}
]]