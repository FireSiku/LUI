-- Instance Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Instance", "AceEvent-3.0")

local GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime = GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime
local RequestRaidInfo = RequestRaidInfo
local sort, time = sort, time

local instances = {}
-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetInstanceInfo()
	wipe(instances)
	for i = 1, GetNumSavedInstances() do
		local name, id, reset, _, locked, extended, _, _, _, difficulty = GetSavedInstanceInfo(i)

		if name and reset and reset > 0 and (locked or extended) then
			instances[#instances + 1] = {
				name = difficulty and format("%s - %s", name, difficulty) or name,
				id = id,
				expires = time() + reset,
			}
		end
	end

	sort(instances, function(a, b)
		return a.name < b.name
	end)

	element.text = format("Instance [%d]", #instances)
	element:UpdateTooltip()
end

function element:RequestInstanceInfo()
	RequestRaidInfo()
end

function element:OnClick(frame_, button_) -- Toggle RaidInfoFrame
	ToggleFriendsFrame(_G.FRIEND_TAB_RAID or 3)
end

element.RefreshSettings = element.SetInstanceInfo
-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader("Instance Info")
	if #instances == 0 then
		GameTooltip:AddLine("[No saved instances]")
	else
		GameTooltip:AddDoubleLine("Instance", "Time Remaining")
		for _, instance in ipairs(instances) do
			local remaining = instance.expires - time()
			if remaining > 0 then
				GameTooltip:AddDoubleLine(format("%s (%s)", instance.name, instance.id), SecondsToTime(remaining), 1,1,1, 1,1,1)
			end
		end
	end
	element:AddHint("Click to open Raid Info.")
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element.text = format("Instance [0]")
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "RequestInstanceInfo")
	element:RegisterEvent("UPDATE_INSTANCE_INFO", "SetInstanceInfo")
	element:AddUpdate("SetInstanceInfo", 60)
	element:RequestInstanceInfo()
	element:SetInstanceInfo()
end
