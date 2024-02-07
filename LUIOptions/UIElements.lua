-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.UIElements, AceDB-3.0
local L, module, db = Opt:GetLUIModule("UI Elements")
if not module or not module.registered then return end

local UIElements = Opt:CreateModuleOptions("UI Elements", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function DisablePosition(info)
	local parent = info[#info-1]
	return not db[parent].ManagePosition
end

local framePositionOrder = {
	"ObjectiveTrackerFrame", "QueueStatusButton", "PlayerPowerBarAlt", "AlwaysUpFrame", "DurabilityFrame", 
	"CaptureBar", "VehicleSeatIndicator", "GroupLootContainer", "TicketStatus"
}

local framePositionList = {
	ObjectiveTrackerFrame = "Objectives Tracker",
	QueueStatusButton = "Queue Status Button",
	PlayerPowerBarAlt = "Alternate Power Bar",
	AlwaysUpFrame = "Zone Objectives Frame",
	DurabilityFrame = "Durability Frame",
	CaptureBar = "Capture Bar",
	VehicleSeatIndicator = "Vehicle Seat Indicator",
	GroupLootContainer = "Group Loot Container",
	TicketStatus = "GM Ticket Status",
}

local framePositionDescs = {
	ObjectiveTrackerFrame = "This Frame occurs when tracking Quests and Achievements.",
	QueueStatusButton = "This button appears when you queue up when searching for groups or instances",
	PlayerPowerBarAlt = "This Frame is the special bar that appears during certain fights or events. Example: Sanity bar during Visions.",
	AlwaysUpFrame = "This Frame occurs in Battlegrounds, Instances and Zone Objectives. Example: Attempts left in Icecrown.",
	DurabilityFrame = "This Frame occurs when your gear is damaged or broken.",
	CaptureBar = "This Frame occurs when trying to capture a pvp objective.",
	VehicleSeatIndicator = "This Frame occurs in some special Mounts and Vehicles. Example: Traveler's Tundra Mammoth.",
	GroupLootContainer = "This Frame is the anchor point for many Loot-based frames such as the Need/Greed and Bonus Roll frames.",
	TicketStatus = "This Frame occurs when waiting on a ticket response",
}

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local function GenerateFramePositionGroup(frame, name, order)
	local dbFrame = db[frame]
    if not dbFrame then return end    -- If that unit does not have options for that bar, nil it

    local group = Opt:Group({name = name, db = dbFrame, args = {
		Desc = Opt:Desc({name = framePositionDescs[frame]}),
        ManagePosition = Opt:Toggle({name = "Manage This Frame's Position", width = "full"}),
        X = Opt:Input({name = "X Value"}),
        Y = Opt:Input({name = "Y Value"}),
    }})

    return group
end

UIElements.args = {
	Header = Opt:Header({name = "UI Elements"}),
	Elements = Opt:Group({name = "Frame Positions", childGroups = "tree"})
}

for i, name in ipairs(framePositionOrder) do
	UIElements.args.Elements.args[name] = GenerateFramePositionGroup(name, framePositionList[name], i+5)
end

--[[
    
	local options = {
		
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
