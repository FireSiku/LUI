-- Instance Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Instance", "AceEvent-3.0")

local GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime = GetNumSavedInstances, GetSavedInstanceInfo, SecondsToTime
local sort, time = sort, time

local instances = {}
local events = {"PLAYER_ENTERING_WORLD", "UPDATE_INSTANCE_INFO", "INSTANCE_BOOT_START", "INSTANCE_BOOT_STOP"}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetInstanceInfo()
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, _, _, _, _, _, _, difficulty = GetSavedInstanceInfo(i)

        if reset and reset > 0 then
            instances[i] = {
                name = (name .. " - " .. difficulty),
                id = id,
                reset = reset,
                curTime = time(),
            }
        end
    end

    for i, v in ipairs(instances) do
        if time() >= (v.curTime + v.reset) then
            wipe(instances[i])
            instances[i] = nil
        end
    end

    sort(instances, function(a, b)
        return a.name < b.name
    end)

    -- Set value
    element.text = format("Instance [%d]", #instances)
end
function element:OnClick(frame_, button_) -- Toggle RaidInfoFrame
    if RaidInfoFrame:IsVisible() then
        RaidInfoFrame:Hide()
        if FriendsFrame:IsVisible() then
            FriendsFrame:Hide()
        end
    else
        ToggleFriendsFrame(3)
        RaidInfoFrame:Show()
    end
end
-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
    local numInstances = #instances
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Instance Info:", 0.4, 0.78, 1)
    GameTooltip:AddLine(" ")
    if numInstances == 0 then
        GameTooltip:AddLine("[No saved instances]")
    else
        GameTooltip:AddDoubleLine("Instance:", "Time Remaining:")
        GameTooltip:AddLine(" ")
    end 
    for i = 1, numInstances do
        local instance = instances[i]
        if instance and (time() <= (instance.curTime + instance.reset)) then
            GameTooltip:AddDoubleLine(instance.name .. " (" .. instance.id .. ")", SecondsToTime((instance.curTime + instance.reset) - time()), 1,1,1, 1,1,1)
        end
    end 
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Hint:\n- Any Click to open Raid Info frame.", 0, 1, 0)
    GameTooltip:Show()
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
    element.text = format("Instance [0]")
    element:RegisterEvent("PLAYER_ENTERING_WORLD", "SetInstanceInfo")
    element:RegisterEvent("UPDATE_INSTANCE_INFO", "SetInstanceInfo")
    element:RegisterEvent("INSTANCE_BOOT_START", "SetInstanceInfo")
    element:RegisterEvent("INSTANCE_BOOT_STOP", "SetInstanceInfo")
	element:SetInstanceInfo()
end
