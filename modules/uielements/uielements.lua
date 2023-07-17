-- This module handle various UI Elements by LUI or Blizzard.
-- It's an umbrella module to consolidate the many, many little UI changes that LUI does
--	that do not need a full module for themselves.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.UIElements
local module = LUI:GetModule("UI Elements")
local Micromenu = LUI:GetModule("Micromenu", true) --[[@as LUI.Micromenu]]
local db

local orderUI = false

local ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
local DurabilityFrame = _G.DurabilityFrame
local Minimap = _G.Minimap

local BlizzMicroButtons = {
	CharacterMicroButton = "LUIMicromenu_Player",
	SpellbookMicroButton = "LUIMicromenu_Spellbook",
	TalentMicroButton = "LUIMicromenu_Talents",
	AchievementMicroButton = "LUIMicromenu_Achievements",
	QuestLogMicroButton = "LUIMicromenu_Quests",
	GuildMicroButton = "LUIMicromenu_Guild",
	LFDMicroButton = "LUIMicromenu_LFG",
	EJMicroButton = "LUIMicromenu_EJ",
	CollectionsMicroButton = "LUIMicromenu_Collections",
	CollectionsJournalTab1 = "LUIMicromenu_Collections",
	CollectionsJournalTab2 = "LUIMicromenu_Collections",
	CollectionsJournalTab3 = "LUIMicromenu_Collections",
	CollectionsJournalTab4 = "LUIMicromenu_Collections",
	CollectionsJournalTab5 = "LUIMicromenu_Collections",
}


-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetUIElements()
	db = module.db.profile
	module:SetHiddenFrames()
	--module:SetObjectiveFrame()
	module:SetAdditionalFrames()
	module:SetPosition('VehicleSeatIndicator')
	module:SetPosition('AlwaysUpFrame')
	module:SetPosition('CaptureBar')
	module:SetPosition('TicketStatus')
	module:SetPosition('PlayerPowerBarAlt')
	module:SetPosition('ObjectiveTrackerFrame')
	module:SetPosition('DurabilityFrame')
	module:SetPosition('PlayerPowerBarAlt')
	module:SetPosition('QueueStatusButton')
	module:SetAlerts()
end

function module:SetHiddenFrames()
	-- Durability Frame
	if db.DurabilityFrame.HideFrame then
		LUI:Kill(DurabilityFrame)
	else
		LUI:Unkill(DurabilityFrame)
		if db.DurabilityFrame.ManagePosition then
			DurabilityFrame:ClearAllPoints()
			-- Not Working. Figure out why.
			DurabilityFrame:SetPoint("RIGHT", Minimap, "LEFT", db.DurabilityFrame.X, db.DurabilityFrame.Y)
		end
	end

	if db.OrderHallCommandBar.HideFrame and not orderUI then
		module:SecureHook("OrderHall_LoadUI", function()
			LUI:Kill(_G.OrderHallCommandBar)
		end)
		orderUI = true
	end
end

-- ####################################################################################################################
-- ##### UIElements: Force Positioning ################################################################################
-- ####################################################################################################################
--- @TODO: Refactor to be cleaner. this was ripped straight out of V3 miinimap module.

local UIWidgetBelowMinimapContainerFrame = _G.UIWidgetBelowMinimapContainerFrame
local UIWidgetTopCenterContainerFrame = _G.UIWidgetTopCenterContainerFrame
local VehicleSeatIndicator = _G.VehicleSeatIndicator
local TicketStatusFrame = _G.TicketStatusFrame
local PlayerPowerBarAlt = _G.PlayerPowerBarAlt
local GroupLootContainer = _G.GroupLootContainer

local shouldntSetPoint = false

function module:SetAdditionalFrames()
	self:SecureHook(DurabilityFrame, "SetPoint", "DurabilityFrame_SetPoint")
	if (LUI.IsRetail) then
		self:SecureHook(VehicleSeatIndicator, "SetPoint", "VehicleSeatIndicator_SetPoint")
		self:SecureHook(ObjectiveTrackerFrame, "SetPoint", "ObjectiveTrackerFrame_SetPoint")
		self:SecureHook(UIWidgetTopCenterContainerFrame, "SetPoint", "AlwaysUpFrame_SetPoint")
		self:SecureHook(TicketStatusFrame, "SetPoint", "TicketStatus_SetPoint")
		self:SecureHook(UIWidgetBelowMinimapContainerFrame, "SetPoint", "CaptureBar_SetPoint")
		self:SecureHook(PlayerPowerBarAlt, "SetPoint", "PlayerPowerBarAlt_SetPoint")
		self:SecureHook(GroupLootContainer, "SetPoint", "GroupLootContainer_SetPoint")
		self:SecureHook(QueueStatusButton, "SetPoint", "QueueStatusButton_SetPoint")
	end
end

--- Force the position of a given supported frame
---@param frame string The name of the frame to force position
function module:SetPosition(frame)
	shouldntSetPoint = true
	if frame == "AlwaysUpFrame" and db.AlwaysUpFrame.ManagePosition then
		UIWidgetTopCenterContainerFrame:ClearAllPoints()
		UIWidgetTopCenterContainerFrame:SetPoint("TOP", UIParent, "TOP", db.AlwaysUpFrame.X, db.AlwaysUpFrame.Y)
	elseif (LUI.IsRetail) and frame == "VehicleSeatIndicator" and db.VehicleSeatIndicator.ManagePosition then
		VehicleSeatIndicator:ClearAllPoints()
		VehicleSeatIndicator:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.VehicleSeatIndicator.X, db.VehicleSeatIndicator.Y)
	elseif frame == "DurabilityFrame" and db.DurabilityFrame.ManagePosition then
		DurabilityFrame:ClearAllPoints()
		DurabilityFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.DurabilityFrame.X, db.DurabilityFrame.Y)
	elseif frame == "TicketStatus" and db.TicketStatus.ManagePosition then
		TicketStatusFrame:ClearAllPoints()
		TicketStatusFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.TicketStatus.X, db.TicketStatus.Y)
	elseif (LUI.IsRetail) and frame == "ObjectiveTrackerFrame" and db.ObjectiveTrackerFrame.ManagePosition then
		--ObjectiveTrackerFrame:ClearAllPoints() -- Cause a lot of odd behaviors with the quest tracker.
		ObjectiveTrackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.ObjectiveTrackerFrame.X, db.ObjectiveTrackerFrame.Y)
	elseif frame == "CaptureBar" and db.CaptureBar.ManagePosition then
		UIWidgetBelowMinimapContainerFrame:ClearAllPoints()
		UIWidgetBelowMinimapContainerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.CaptureBar.X, db.CaptureBar.Y)
	elseif frame == "PlayerPowerBarAlt" and db.PlayerPowerBarAlt.ManagePosition then
		PlayerPowerBarAlt:ClearAllPoints()
		PlayerPowerBarAlt:SetPoint("BOTTOM", UIParent, "BOTTOM", db.PlayerPowerBarAlt.X, db.PlayerPowerBarAlt.Y)
	elseif frame == "GroupLootContainer" and db.GroupLootContainer.ManagePosition then
		GroupLootContainer:ClearAllPoints()
		GroupLootContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", db.GroupLootContainer.X, db.GroupLootContainer.Y)
	elseif (LUI.IsRetail) and frame == "QueueStatusButton" and db.QueueStatusButton.ManagePosition then
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.QueueStatusButton.X, db.QueueStatusButton.Y)
	end

	shouldntSetPoint = false
end

function module:DurabilityFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('DurabilityFrame')
end

function module:ObjectiveTrackerFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('ObjectiveTrackerFrame')
end

function module:VehicleSeatIndicator_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('VehicleSeatIndicator')
end

function module:AlwaysUpFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('AlwaysUpFrame')
end

function module:CaptureBar_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('CaptureBar')
end

function module:GroupLootContainer_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('GroupLootContainer')
end

function module:PlayerPowerBarAlt_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('PlayerPowerBarAlt')
end

function module:TicketStatus_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('TicketStatus')
end

function module:QueueStatusButton_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('QueueStatusButton')
end

-- ####################################################################################################################
-- ##### UIElement: ObjectiveTracker ##################################################################################
-- ####################################################################################################################

function module:ChangeHeaderColor(header, r, g, b)
	header.Background:SetDesaturated(true)
	header.Background:SetVertexColor(r, g, b)
end

function module:SetObjectiveFrame()
	-- if db.ObjectiveTracker.HeaderColor then
	-- 	module:SecureHook("ObjectiveTracker_Initialize", function()
	-- 		for i, v in pairs(ObjectiveTrackerFrame.MODULES) do
	-- 			module:ChangeHeaderColor(v.Header, module:RGB(LUI.playerClass))
	-- 		end
	-- 	end)
	-- end
	if db.ObjectiveTracker.ManagePosition then
		-- module:SecureHook("ObjectiveTracker_Update", function()
		-- 	shouldntSetPoint = true
		-- 	ObjectiveTrackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.ObjectiveTracker.OffsetX, db.ObjectiveTracker.OffsetY)
		-- 	shouldntSetPoint = false
		-- end)
	end
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function module:Refresh()
	module:SetHiddenFrames()
end
