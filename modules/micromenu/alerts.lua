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
	TalentMicroButton = "LUIMicromenu_Talents",
	SpellbookMicroButton = "LUIMicromenu_Talents",
	AchievementMicroButton = "LUIMicromenu_Achievements",
	LegacyMicroButton = "LUIMicromenu_Legacy",
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
local pointerTimers = setmetatable({}, {__mode = "k"})

local function CanPosition(frame)
	return frame and not (frame.IsForbidden and frame:IsForbidden())
		and not (frame.IsProtected and frame:IsProtected())
end

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
	if pointerTimers[frame] then
		pointerTimers[frame]:Cancel()
		pointerTimers[frame] = nil
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
	arrow2:Show()
	arrow2.Anim:Play()
end

-- Do not call AnchorAndRotate/RotateArrow/SetClampedTextureRotation from
-- addon execution: those helpers WRITE Lua caches on Blizzard's frames.
-- In particular, relativeRegion is read by HelpTip:OnHide on the path from
-- PlayerSpells:OnShow to MultiActionBar_ShowAllGrids. Keep all logical fields
-- and callback ownership native; override only C-backed visual properties.
local function RotateTexture(texture, degrees)
	if not texture then return end
	local coords = texture.origTexCoords
	if not coords then return end -- Native Init has normally populated these.
	local width, height = texture.origWidth, texture.origHeight
	if width and height then
		if degrees == 90 or degrees == 270 then width, height = height, width end
		texture:SetSize(width, height)
	end
	local order = degrees == 90 and {3, 7, 1, 5}
		or degrees == 180 and {7, 5, 3, 1}
		or degrees == 270 and {5, 1, 7, 3} or {1, 3, 5, 7}
	texture:SetTexCoord(coords[order[1]], coords[order[1]+1], coords[order[2]], coords[order[2]+1],
		coords[order[3]], coords[order[3]+1], coords[order[4]], coords[order[4]+1])
end

local function Transform(x, y, rotation)
	if rotation.swapOffsets then x, y = y, x end
	return x * rotation.modOffsetX, y * rotation.modOffsetY
end

local function PositionHelpTip(frame, region, point, alignment, info, arrowOnly)
	local tip = _G.HelpTip
	local pointInfo = tip.PointInfo[point]
	local rotation = pointInfo and tip.Rotations[pointInfo.arrowRotation]
	if not rotation then return end
	local anchor = rotation.anchors[alignment]
	if not arrowOnly then
		local offset = tip.DistanceOffsets[alignment]
		local x, y = Transform(offset[1], offset[2], rotation)
		local baseX, baseY = info.offsetX or 0, info.offsetY or 0
		if point ~= (info.targetPoint or tip.Point.BottomEdgeCenter) then
			if point <= tip.Point.BottomEdgeRight then baseY = -baseY else baseX = -baseX end
		end
		frame:ClearAllPoints()
		frame:SetPoint(anchor, region, pointInfo.relativeAnchor, x + baseX, y + baseY)
	end
	local arrow = frame.Arrow
	if not arrow or info.hideArrow then return end
	local offset = tip.ArrowOffsets[alignment]
	local x, y = Transform(offset[1], offset[2], rotation)
	arrow:ClearAllPoints()
	arrow:SetPoint("CENTER", frame, anchor, x, y)
	RotateTexture(arrow.Arrow, rotation.degrees)
	RotateTexture(arrow.Glow, rotation.degrees)
	if arrow.Glow and arrow.Arrow then
		x, y = Transform(tip.ArrowGlowOffsets[1], tip.ArrowGlowOffsets[2], rotation)
		arrow.Glow:SetPoint("CENTER", arrow.Arrow, "CENTER", x, y)
	end
end

local function RestoreHelpTip(frame, reset)
	local state = reanchoredHelpTips[frame]
	if state and CanPosition(frame) and (reset or frame.info == state.info) then
		PositionHelpTip(frame, state.region, state.point, state.alignment, state.info, reset)
	end
	reanchoredHelpTips[frame] = nil
end


-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetAlerts()
	local function PositionActiveHelpTips()
		if not module:IsEnabled() or not _G.HelpTip or not _G.HelpTip.framePool then return end
		for frame in _G.HelpTip.framePool:EnumerateActive() do
			-- Hook actual pooled instances, including tips created before LUI.
			-- A mixin-only hook misses methods already copied to existing frames.
			if CanPosition(frame) and not module:IsHooked(frame, "AnchorAndRotate") then
				module:SecureHook(frame, "AnchorAndRotate", function(self)
					module:AlertHandler(self, nil, self.info, self.relativeRegion)
				end)
				module:SecureHook(frame, "Reset", function(self) RestoreHelpTip(self, true) end)
			end
			module:AlertHandler(frame, nil, frame.info, frame.relativeRegion)
		end
	end
	if _G.HelpTip and not module:IsHooked(_G.HelpTip, "Show") then
		module:SecureHook(_G.HelpTip, "Show", PositionActiveHelpTips)
	end
	PositionActiveHelpTips()
	if _G.TutorialPointerFrame and not module:IsHooked(_G.TutorialPointerFrame, "Show") then
		module:SecureHook(_G.TutorialPointerFrame, "Show", function(table, content, direction, anchorFrame)
			local newPointer = anchorFrame and anchorFrame.currentNPEPointer
			if newPointer then module:ShouldReAnchorPointer(newPointer) end
		end)
		module:SecureHook(_G.TutorialPointerFrame, "_RetireFrame", function(_, frame)
			if pointerTimers[frame] then pointerTimers[frame]:Cancel(); pointerTimers[frame] = nil end
			reanchoredPointers[frame] = nil
		end)
	end
end

function module:AlertHandler(frame, parent, info, relativeRegion)
	if not module:IsEnabled() or not CanPosition(frame) or not info or not relativeRegion then return end
	local target, point
	if relativeRegion == _G.QueueStatusButton then
		target, point = relativeRegion, _G.HelpTip.Point.LeftEdgeCenter
	end
	for blizzardFrame, microFrame in pairs(BlizzMicroButtons) do
		if relativeRegion == _G[blizzardFrame] and _G[microFrame] then
			target, point = _G[microFrame], _G.HelpTip.Point.BottomEdgeCenter
			break
		end
	end
	if not target then return end
	reanchoredHelpTips[frame] = {
		info = info, region = relativeRegion,
		point = frame.appliedTargetPoint or info.targetPoint or _G.HelpTip.Point.BottomEdgeCenter,
		alignment = frame.appliedAlignment or info.alignment or _G.HelpTip.Alignment.Center,
	}
	PositionHelpTip(frame, target, point, _G.HelpTip.Alignment.Center, info)
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
		end
	end
	if frame.AnimDelayTimer then frame.AnimDelayTimer:Cancel() end
	if pointerTimers[frame] then pointerTimers[frame]:Cancel() end
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
	local state = reanchoredPointers[frame]
	pointerTimers[frame] = C_Timer.NewTimer(0.5, function()
		if module:IsEnabled() and reanchoredPointers[frame] == state
			and state and frame.currentTarget == state.currentTarget then
			arrow2:Show()
			arrow2.Anim:Play()
		end
	end)
end

function module:ShouldReAnchorPointer(frame)
	if not module:IsEnabled() or not CanPosition(frame) or not frame.currentTarget or not frame.Content or not frame.Content.Text then return end
	local anchor = frame.currentTarget
	local text = frame.Content.Text:GetText()
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
	local state = reanchoredPointers[frame]
	if not state or state.currentTarget ~= oldTarget then
		reanchoredPointers[frame] = {
			currentTarget = oldTarget,
			points = CapturePoints(frame),
			contentPoints = CapturePoints(frame.Content),
			arrow = CapturePointerArrow(frame),
		}
	end
	-- Native currentTarget/currentNPEPointer and timer ownership must stay
	-- intact: Blizzard reads them when showing, hiding and retiring a pointer.
	frame:ClearAllPoints()
	frame:SetPoint("TOP", target, "BOTTOM", 0, -100)
	frame.Content:ClearAllPoints()
	frame.Content:SetPoint("TOP", frame, "BOTTOM", 0, 5)
	module:ShowPointerArrow(frame, "UP")
end

function module:RestoreAlerts()
	for frame in pairs(reanchoredHelpTips) do
		RestoreHelpTip(frame)
	end

	for frame, state in pairs(reanchoredPointers) do
		-- A retired tutorial pointer has already been detached and returned to
		-- Blizzard's pool. Never reconnect one of those pooled frames.
		if CanPosition(frame) and frame.currentTarget == state.currentTarget then
			RestorePoints(frame, state.points)
			RestorePoints(frame.Content, state.contentPoints)
			RestorePointerArrow(frame, state.arrow)
		end
		if pointerTimers[frame] then pointerTimers[frame]:Cancel(); pointerTimers[frame] = nil end
		reanchoredPointers[frame] = nil
	end
end
