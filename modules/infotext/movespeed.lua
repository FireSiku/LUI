-- Movement Speed Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("MoveSpeed", "AceEvent-3.0")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################
function module:SetMoveSpeed()

	local stat = NewStat("MoveSpeed")

	if db.MoveSpeed.Enable and not stat.Created then

		local baseSpeed = BASE_MOVEMENT_SPEED
		-- Script functions
		stat.OnUpdate = function(self, deltaTime)
			self.dt = self.dt + deltaTime
			if self.dt > 0.5 then
				self.dt = 0

				local unit = "player"
				if UnitInVehicle("player") then
					unit = "vehicle"
				end
				local speed, runSpeed = GetUnitSpeed(unit)
				if speed == 0 then
					speed = runSpeed
				end

				-- Set value
				self.text:SetText(format("Speed: %d%%", speed / baseSpeed * 100))
			end
		end

		stat.Created = true
	end

end

local function formatMoveSpeed(kb)
	if kb > KB_PER_MB then
		return format("%.2fmb", kb / KB_PER_MB)
	else
		return format("%.1fkb", kb)
	end
end

function element:UpdateMoveSpeed()
	UpdateAddOnMemoryUsage()
	totalMemory = 0

	for i = 1, GetNumAddOns() do
		local _, addonTitle = GetAddOnInfo(i)
		if IsAddOnLoaded(i) then
			addonMemory[addonTitle] = GetAddOnMemoryUsage(i)
			totalMemory = totalMemory + addonMemory[addonTitle]
		else
			addonMemory[addonTitle] = nil
		end
	end

	--sort table
	LUI:SortTable(sortedAddons, addonMemory, addonSort)
	element.text = format("%.1fmb", totalMemory / KB_PER_MB)

	element:UpdateTooltip()
end

function element.OnClick(frame_, button_)
	collectgarbage("collect")
	element:UpdateMemory()
end
-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoMemory_Header"])
	for i = 1, #sortedAddons do
		local addonTitle = sortedAddons[i]
		local r, g, b = LUI:InverseGradient((addonMemory[addonTitle] / totalMemory) * GRADIENT_MULTIPLIER)
		GameTooltip:AddDoubleLine(addonTitle, formatMoveSpeed(addonMemory[addonTitle]), 1,1,1, r, g, b)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["InfoMemory_TotalMemory"], formatMoveSpeed(totalMemory), 1,1,1, .8,.8,.8)

	element:AddHint(L["InfoMemory_Hint_Any"])
end
-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:UpdateMoveSpeed()
	element:AddUpdate("UpdateMoveSpeed", MEMORY_UPDATE_TIME)
end
