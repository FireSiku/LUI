-- Micromenu: Blizzard help-tip and tutorial-pointer redirection.
-- This file is specifically for handling Blizzard UI Alerts. Including but not limited to:
-- * HelpTips, such as viewing your mount collection.
-- * Alerts such as Unspent Talent Points.
-- * Tutorials

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Micromenu
local module = LUI:GetModule("Micromenu")

local BlizzMicroButtons = {
	CharacterMicroButton = "LUIMicromenu_Player",
	ProfessionMicroButton = "LUIMicromenu_Spellbook",
	PlayerSpellsMicroButton = "LUIMicromenu_Talents",
	AchievementMicroButton = "LUIMicromenu_Achievements",
	QuestLogMicroButton = "LUIMicromenu_Quests",
	GuildMicroButton = "LUIMicromenu_Guild",
	LFDMicroButton = "LUIMicromenu_LFG",
	EJMicroButton = "LUIMicromenu_EJ",
	MicroButtonAndBagsBar = "LUIMicromenu_Bags",
	CollectionsMicroButton = "LUIMicromenu_Collections",
	CollectionsJournalTab1 = "LUIMicromenu_Collections",
	CollectionsJournalTab2 = "LUIMicromenu_Collections",
	CollectionsJournalTab3 = "LUIMicromenu_Collections",
	CollectionsJournalTab4 = "LUIMicromenu_Collections",
	CollectionsJournalTab5 = "LUIMicromenu_Collections",
	MainMenuBarBackpackButton = "LUIMicromenu_Bags",
}

local reanchoredHelpTips = setmetatable({}, {__mode = "k"})
local reanchoredPointers = setmetatable({}, {__mode = "k"})

local function CapturePoints(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = {frame:GetPoint(i)}
	end
	return points
end

local function RestorePoints(frame, points)
	frame:ClearAllPoints()
	for _, point in ipairs(points or {}) do
		frame:SetPoint(unpack(point))
	end
end

local arrowDirections = {"UP", "LEFT", "RIGHT", "DOWN"}

local function CapturePointerArrow(frame)
	for _, direction in ipairs(arrowDirections) do
		local arrow1 = frame["Arrow_"..direction..1]
		local arrow2 = frame["Arrow_"..direction..2]
		if arrow1 and (arrow1:IsShown() or (arrow2 and arrow2:IsShown())) then
			return {
				direction = direction,
				arrow1Points = CapturePoints(arrow1),
				arrow2Points = arrow2 and CapturePoints(arrow2),
			}
		end
	end
end

local function RestorePointerArrow(frame, state)
	if frame.AnimDelayTimer then
		frame.AnimDelayTimer:Cancel()
		frame.AnimDelayTimer = nil
	end
	for _, direction in ipairs(arrowDirections) do
		for index = 1, 2 do
			local arrow = frame["Arrow_"..direction..index]
			if arrow then
				arrow:Hide()
				arrow.Anim:Stop()
			end
		end
	end

	if not state or not state.direction then return end
	local arrow1 = frame["Arrow_"..state.direction..1]
	local arrow2 = frame["Arrow_"..state.direction..2]
	if not arrow1 or not arrow2 then return end
	RestorePoints(arrow1, state.arrow1Points)
	RestorePoints(arrow2, state.arrow2Points)
	arrow1:Show()
	arrow1.Anim:Play()
	frame.AnimDelayTimer = C_Timer.NewTimer(0.5, function()
		if frame.currentTarget then
			arrow2:Show()
			arrow2.Anim:Play()
		end
	end)
end

local function RememberHelpTip(frame)
	if not reanchoredHelpTips[frame] then
		reanchoredHelpTips[frame] = {
			relativeRegion = frame.relativeRegion,
			targetPoint = frame.info and frame.info.targetPoint,
		}
	end
end


-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetAlerts()
	if _G.HelpTipTemplateMixin and not module:IsHooked(_G.HelpTipTemplateMixin, "Init") then
		module:SecureHook(_G.HelpTipTemplateMixin, "Init", "AlertHandler")
	end
	if _G.HelpTip and _G.HelpTip.framePool then
		for alert in _G.HelpTip.framePool:EnumerateActive() do
			module:AlertHandler(alert, alert:GetParent(), alert.info, alert.relativeRegion)
		end
	end
	if _G.TutorialPointerFrame and not module:IsHooked(_G.TutorialPointerFrame, "Show") then
		module:SecureHook(_G.TutorialPointerFrame, "Show", function(table, content, direction, anchorFrame)
			local newPointer = anchorFrame and anchorFrame.currentNPEPointer
			if newPointer then module:ShouldReAnchorPointer(newPointer) end
		end)
	end
end

function module:AlertHandler(frame, parent, info, relativeRegion)
	if not frame or not info or not relativeRegion then return end
	if relativeRegion == _G.QueueStatusButton then
		RememberHelpTip(frame)
		frame:AnchorAndRotate(_G.HelpTip.Point.LeftEdgeCenter)
	end
	for blizzardFrame, microFrame in pairs(BlizzMicroButtons) do
		if relativeRegion == _G[blizzardFrame] and _G[microFrame] then
			RememberHelpTip(frame)
			frame.relativeRegion = _G[microFrame]
			frame.info.targetPoint = _G.HelpTip.Point.BottomEdgeCenter
			frame:AnchorAndRotate(_G.HelpTip.Point.BottomEdgeCenter)
		end
	end
end

function module:DebugAlert()
	-- It is possible for it to execute before we hooked it, run AlertHandler for active ones as well.
	LUI:Print("Listing all current alerts")
	for alert in _G.HelpTip.framePool:EnumerateActive() do
		LUI:Print(alert.relativeRegion.GetName and alert.relativeRegion:GetName() or alert.relativeRegion:GetDebugName())
	end
end

function module:ShowPointerArrow(frame, direction)
	--Look for previous arrow and Hide
	for i = 1, #arrowDirections do
		local arrow1 = frame["Arrow_"..arrowDirections[i]..1]
		local arrow2 = frame["Arrow_"..arrowDirections[i]..2]
		if arrow1 then
			arrow1:Hide()
			arrow1.Anim:Stop()
			arrow2:Hide()
			arrow2.Anim:Stop()
			if frame.AnimDelayTimer then frame.AnimDelayTimer:Cancel() end
		end
	end
	-- Show the desired arrow.
	local arrow1 = frame["Arrow_"..direction..1]
	local arrow2 = frame["Arrow_"..direction..2]
	local point = (direction == "UP") and "TOP" or (direction == "DOWN") and "BOTTOM" or direction
	arrow1:ClearAllPoints()
	arrow2:ClearAllPoints()
	local offsetX = (direction == "UP" or direction == "DOWN") and 0 or NegateIf(LUI:Scale(15), direction == "RIGHT")
	local offsetY = (direction == "LEFT" or direction == "RIGHT") and 0 or NegateIf(LUI:Scale(15), direction == "DOWN")
	arrow1:SetPoint(LUI.Opposites[point], frame, point, offsetX, offsetY)
	arrow2:SetPoint(LUI.Opposites[point], frame, point, offsetX, offsetY)
	arrow1:Show();
	arrow1.Anim:Play();
	-- Second arrow starts halfway through the first arrow's animation.
	frame.AnimDelayTimer = C_Timer.NewTimer(0.5, function()
		arrow2:Show();
		arrow2.Anim:Play()
	end)
end

function module:ShouldReAnchorPointer(frame)
	if not frame or not frame.currentTarget or not frame.Content or not frame.Content.Text then return end
	local anchor = frame.currentTarget
	local text = frame.Content.Text:GetText()
	if not frame:IsShown() and text then frame:Show() end
	local anchorFound = false

	-- Check if the pointer is pojnting to blizzard microbuttons
	for blizzardFrame, microFrame in pairs(BlizzMicroButtons) do
		if anchor == _G[blizzardFrame] then
			anchor = microFrame
			anchorFound = true
		end
	end

	-- Text-matching fallback for current tutorials that do not expose their target button reliably.
	if not anchorFound then
		-- Unspent Talent Points
		if text == _G.NPEV2_SPEC_TUTORIAL_GOSSIP_CLOSED then
			anchor = BlizzMicroButtons.PlayerSpellsMicroButton
		
		-- NPE: Found gear, open your bags
		elseif _G.NPEV2_SHOW_BAGS and _G.TutorialHelper and text == format(_G.NPEV2_SHOW_BAGS, _G.TutorialHelper:GetBagBinding()) then
			anchor = BlizzMicroButtons.MicroButtonAndBagsBar
		
		-- NPE: Open Dungeon Finder to join Darkmaul Citadel
		elseif text == _G.NPEV2_LFD_INTRO then
			anchor = BlizzMicroButtons.LFDMicroButton
			-- Make sure warning is only visible while you're on Exile Reach
			if C_Map.GetBestMapForUnit("player") ~= 1409 then
				frame:Hide()
				return
			end
		-- New mount added to your collection
		elseif text == _G.NPEV2_MOUNT_TUTORIAL_P2_NEW_MOUNT_ADDED then
			anchor = BlizzMicroButtons.CollectionsMicroButton
		else
			return
		end
	end
	
	local target = _G[anchor]
	if not target then return end
	local oldTarget = frame.currentTarget
	if not reanchoredPointers[frame] then
		reanchoredPointers[frame] = {
			currentTarget = oldTarget,
			points = CapturePoints(frame),
			arrow = CapturePointerArrow(frame),
		}
	end
	if oldTarget and oldTarget.currentNPEPointer == frame then
		oldTarget.currentNPEPointer = nil
	end
	if not target.hasHookedScriptsForNPE then
		target:HookScript("OnShow", function(self)
			if self.currentNPEPointer then self.currentNPEPointer:Show() end
		end)
		target:HookScript("OnHide", function(self)
			if self.currentNPEPointer then self.currentNPEPointer:Hide() end
		end)
		target.hasHookedScriptsForNPE = true
	end
	target.currentNPEPointer = frame
	frame.currentTarget = target
	frame:ClearAllPoints()
	frame:SetPoint("TOP", target, "BOTTOM", 0, -100)
	module:ShowPointerArrow(frame, "UP")
end

function module:RestoreAlerts()
	for frame, state in pairs(reanchoredHelpTips) do
		if frame and frame.info then
			frame.relativeRegion = state.relativeRegion
			frame.info.targetPoint = state.targetPoint
			frame.appliedTargetPoint = nil
			frame.appliedAlignment = nil
			frame:AnchorAndRotate()
		end
		reanchoredHelpTips[frame] = nil
	end

	for frame, state in pairs(reanchoredPointers) do
		-- A retired tutorial pointer has already been detached and returned to
		-- Blizzard's pool. Never reconnect one of those pooled frames.
		if frame and frame.currentTarget then
			local currentTarget = frame.currentTarget
			if currentTarget and currentTarget.currentNPEPointer == frame then
				currentTarget.currentNPEPointer = nil
			end
			frame.currentTarget = state.currentTarget
			if state.currentTarget then
				state.currentTarget.currentNPEPointer = frame
			end
			RestorePoints(frame, state.points)
			RestorePointerArrow(frame, state.arrow)
		end
		reanchoredPointers[frame] = nil
	end
end
