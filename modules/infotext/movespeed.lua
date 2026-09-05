-- Movement Speed Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("MoveSpeed")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetMoveSpeed()
	local baseSpeed = BASE_MOVEMENT_SPEED
	local speed, runSpeed = GetUnitSpeed("player")
	local text = "Speed: [Secret]"
	
	if not issecretvalue(speed) then
		if speed == 0 and not issecretvalue(runSpeed) then speed = runSpeed end
		if not issecretvalue(speed) then
			text = format("Speed: %d%%", speed / baseSpeed * 100)
		end
	end

	element.text = text
	element:UpdateTooltip()
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:SetMoveSpeed()
	element:AddUpdate("SetMoveSpeed", 1)
end

element.RefreshSettings = element.SetMoveSpeed
