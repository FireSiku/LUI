-- UIElements: Alerts
-- This file is specifically for handling Blizzard UI Alerts. Including but not limited to:
-- * HelpTips, such as viewing your mount collection.
-- * Alerts such as Unspent Talent Points.
-- * Tutorials

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.UIElements
local module = LUI:GetModule("UI Elements")
local Micromenu = LUI:GetModule("Micromenu", true) --[[@as LUI.Micromenu]]
local db

local BlizzMicroButtons = {
	CharacterMicroButton = "LUIMicromenu_Player",
	ProfessionMicroButton = "LUIMicromenu_Spellbook",
	SpellbookMicroButton = "LUIMicromenu_Talents",
	PlayerSpellsMicroButton = "LUIMicromenu_Talents",
	TalentMicroButton = "LUIMicromenu_Talents",
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


-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetAlerts()
	db = module.db.profile
	module:SecureHook(_G.HelpTipTemplateMixin, "Init", "AlertHandler")
	-- It is possible for it to execute before we hooked it, run AlertHandler for active ones as well.
	for alert in _G.HelpTip.framePool:EnumerateActive() do
		module:AlertHandler(alert, alert:GetParent(), alert.info, alert.relativeRegion)
	end
	-- With 10.1.5, Blizzard started to use the TutorialHelper for some of those. 
	module:SecureHook(_G.TutorialPointerFrame, "Show", function(table, content, direction, anchorFrame, x, y, opposite)
		if Micromenu and Micromenu:IsEnabled() then
			local newPointer = anchorFrame.currentNPEPointer
			module:ShouldReAnchorPointer(newPointer)
		end
	end)
	--- Hack-ish way of catching any other alerts that might be missed after a reload
	C_Timer.After(1, function()
		for alert in _G.HelpTip.framePool:EnumerateActive() do module:AlertHandler(alert, alert:GetParent(), alert.info, alert.relativeRegion) end
	end)
	--module:DebugAlert()
end

--- @TODO: Develop this more into its own API that allows all modules to register or reorganize frames. 
function module:AlertHandler(frame, parent, info, relativeRegion)
	if relativeRegion == _G.QueueStatusButton then
		frame:AnchorAndRotate(_G.HelpTip.Point.LeftEdgeCenter)
	end
	if Micromenu and Micromenu:IsEnabled() then
		local micro_db = Micromenu.db.profile
		for blizzardFrame, microFrame in pairs(BlizzMicroButtons) do
			if relativeRegion == _G[blizzardFrame] then
				frame.relativeRegion = _G[microFrame]
				frame.info.targetPoint = _G.HelpTip.Point.BottomEdgeCenter
				--frame:AnchorAndRotate(_G.HelpTip.Point.BottomEdgeCenter) -- Does not appear to work for MicroButtons? 
			end
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

local arrowDirections = {"UP", "LEFT", "RIGHT", "DOWN"}
function module:ShowPointerArrow(frame, direction)
	--Look for previous arrow and Hide
	for i = 1, #arrowDirections do
		local arrow1 = frame["Arrow_"..arrowDirections[i]..1]
		local arrow2 = frame["Arrow_"..arrowDirections[i]..2]
		if arrow1 then
			arrow1:Hide()
			--arrow1.Anim:Stop()
			arrow2:Hide()
			--arrow2.Anim:Stop()
			if frame.AnimDelayTimer then frame.AnimDelayTimer:Cancel() end
		end
	end
	-- -- Show the desired arrow
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
	-- --Second arrow starts half way through the first arrow's animation (1 second)
	frame.AnimDelayTimer = C_Timer.NewTimer(0.5, function()
		arrow2:Show();
		arrow2.Anim:Play()
	end)
end

function module:ShouldReAnchorPointer(frame)
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

	-- Text-matching fallback in case. Mostly for the Exile Reach's guided approach
	--- @TODO: Verify if this is still needed.
	if not anchorFound then
		-- Unspent Talent Points
		if text == _G.NPEV2_SPEC_TUTORIAL_GOSSIP_CLOSED then
			anchor = BlizzMicroButtons.TalentMicroButton
		
		-- NPE: Found gear, open your bags
		elseif text == format(_G.NPEV2_SHOW_BAGS, _G.TutorialHelper:GetBagBinding()) then
			anchor = BlizzMicroButtons.MicroButtonAndBagsBar
		
		-- NPE: Open Dungeon Finder to join Darkmaul Citadel
		elseif text == _G.NPEV2_LFD_INTRO then
			anchor = BlizzMicroButtons.LFDMicroButton
			-- Make sure warning is only visible while you're on Exile Reach
			if WorldMapFrame:GetMapID() ~= 1409 then
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
	
	frame.currentTarget = _G[anchor]
	frame:ClearAllPoints()
	frame:SetPoint("TOP", anchor, "BOTTOM", 0, -100)
	module:ShowPointerArrow(frame, "UP")
end
