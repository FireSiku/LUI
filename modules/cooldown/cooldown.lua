--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Cooldown Timer Module
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Cooldown
local module = LUI:GetModule("Cooldown")
local Media = LibStub("LibSharedMedia-3.0")

module.timers = {}

-- Database and defaults shortcuts.
local db --luacheck: ignore

-- Localized API
local floor, format, tinsert, tremove = math.floor, string.format, table.insert, table.remove
local pairs, ipairs, wipe, GetTime = pairs, ipairs, wipe, GetTime
local GetActionCooldown = _G.GetActionCooldown

local COOLDOWN_TYPE_LOSS_OF_CONTROL = _G.COOLDOWN_TYPE_LOSS_OF_CONTROL or 1
local COOLDOWN_TYPE_NORMAL = _G.COOLDOWN_TYPE_NORMAL or 2

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local activeUICooldowns = {}

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

local function actionUIButtonCD_OnShow(self)
	activeUICooldowns[self] = self:GetParent()
end

local function actionUIButtonCD_OnHide(self)
	activeUICooldowns[self] = nil
end

--------------------------------------------------
-- Cooldown Functions
--------------------------------------------------

do
	local day, hour, minute = 86400, 3600, 60
	local iconSize = 36
	local precision, threshold, minDuration, minToSec

	local cache = {}

	local colors = {}

	local timeFormats = {
		[day] = "%.0fd",
		[hour] = "%.0fh",
		[minute] = "%.0fm",
		[1] = "%.0f",
	}

	local fontScale = setmetatable({}, {
		__index = function(t, width)
			local scale = width / iconSize
			t[width] = scale > db.General.MinScale and scale * db.Text.Size

			return t[width]
		end
	})

	local alphaCurve = C_CurveUtil.CreateCurve()
	alphaCurve:SetType(Enum.LuaCurveType.Step)

	function module:UpdateVars()
		db = module.db.profile

		precision = 1 / 10^(db.General.Precision)
		threshold = db.General.Threshold
		minDuration = db.General.MinDuration
		minToSec = db.General.MinToSec

		wipe(fontScale)

		timeFormats[true] = format("%%.%df", db.General.Precision) -- threshold

		colors[day] = db.Colors.Day
		colors[hour] = db.Colors.Hour
		colors[minute] = db.Colors.Min
		colors[1] = db.Colors.Sec
		colors[true] = db.Colors.Threshold

		alphaCurve:AddPoint(3, 0)
		alphaCurve:AddPoint(minDuration + 0.01, 1)
	end


	local function round(num)
		return floor(num + 0.5)
	end

	local Timer = {}

	function Timer:Start(durationObject)
		self.durationObject = durationObject
		self.enabled = true
		self.cd:SetAlpha(durationObject:EvaluateRemainingDuration(alphaCurve) or 1)

		if not self:Scale() or not self:Update() then return end

		self:Show()
	end

	function Timer:Stop()
		self:Hide()

		self.enabled = nil
		self.cd.luitimer = nil
		self.fontScale = nil -- force update of fontsize on next use

		tinsert(cache, self)
	end

	function Timer:Update()	
		if self.durationObject:IsZero() then
			LUI:Print("Stopping cooldown timer")
			self:Stop()
			return
		end
		-- duration >= minDuration need alpha curve
		
		self:FormatTime(self.durationObject:GetRemainingDuration())
		return true
	end

	-- function Timer:ShouldUpdate(start, duration)
	-- 	if start ~= self.start or duration ~= self.duration then
	-- 		if duration < minDuration or not self:IsVisible() then
	-- 			self:Stop()
	-- 			return
	-- 		end
	-- 	end

	-- 	return true
	-- end

	function Timer:OnUpdate(elapsed)
		self.nextUpdate = self.nextUpdate - elapsed

		if self.nextUpdate > 0 then return end
		self:Update()
	end

	function Timer:FormatTime(seconds)
		local factor
		if seconds < threshold then
			factor = true

			self.nextUpdate = precision
			self.text:SetFormattedText(timeFormats[factor], seconds)
		else
			factor = seconds < minToSec and 1 or seconds < hour and minute or seconds < day and hour or day

			self.nextUpdate = seconds % factor
			self.text:SetFormattedText(timeFormats[factor], seconds / factor)
		end

		if self.color ~= colors[factor] then
			self.color = colors[factor]
			self.text:SetTextColor(self.color.r, self.color.g, self.color.b)
		end
	end

	function Timer:Scale()
		local scale = fontScale[round(self.cd:GetWidth())]

		if self.fontScale ~= scale then
			self.fontScale = scale

			if not scale then
				LUI:Print("Stopping cooldown timer via Scale", self.cd:GetName())
				self:Stop()
				return
			end

			self.text:SetFont(Media:Fetch("font", db.Text.Font), scale, db.Text.Flag)
		end

		return true
	end

	function Timer:Position()
		self:ClearAllPoints()
		self:SetAllPoints()
		self.text:SetPoint(db.Text.Align, db.Text.XOffset, db.Text.YOffset)
	end


	local function getTimer(cd)
		local timer = tremove(cache)

		if timer then
			timer:SetParent(cd)
		else
			timer = setmetatable(CreateFrame("Frame", nil, cd, "LUI_Cooldown_Template"), Timer)
			timer:SetScript("OnUpdate", timer.OnUpdate)
			tinsert(module.timers, timer)
		end

		timer.cd = cd
		cd.luitimer = timer

		return timer
	end

	function module:IsSupportedCooldownType(cd)
		local cdType = cd.cooldownType
		
		if cdType == COOLDOWN_TYPE_LOSS_OF_CONTROL then
			return true
		elseif cdType == COOLDOWN_TYPE_NORMAL then
			return true
		end

		-- Spell Charges
		local parent = cd:GetParent()
		if parent and parent.cooldown == cd then
			return true
		end
		if parent and parent.chargeCooldown == cd then
			return true
		-- Item Cooldowns
		elseif parent and parent.SetItem then
			return true
		end

		return db.General.SupportAll
	end

	function module:AssignTimer(cd, start, duration)
		if cd.IsForbidden and cd:IsForbidden() then return end
		if cd.noCooldownCount then return end
		-- Disable LUI cooldowns on WeakAura frames
		if db.General.FilterWA and cd:GetName() and strfind(cd:GetName(), "WeakAuras") then return end

		local durationObject = C_DurationUtil.CreateDuration()
		durationObject:SetTimeFromStart(start, duration)

		if cd.luitimer then
			--if cd.luitimer:ShouldUpdate(durationObject) then
				cd.luitimer.durationObject = durationObject
				cd.luitimer:Update()
			--end
		elseif module:IsSupportedCooldownType(cd) and cd:IsVisible() then
			getTimer(cd):Start(durationObject)
		end
	end

	function module.initTimer()
		if not Timer.__index then
			local timerFuncs = Timer

			Timer = {__index = CreateFrame("Frame")}

			for k, v in pairs(timerFuncs) do
				Timer.__index[k] = v
			end
		end

		module:SecureHook(getmetatable(_G.ActionButton1Cooldown).__index, "SetCooldown", "AssignTimer")
	end
end


function module:RegisterActionUIButton(frame)
	local cd = frame.cooldown
	if not module:IsHooked(cd, "OnShow") then
		module:SecureHookScript(cd, "OnShow", actionUIButtonCD_OnShow)
		module:SecureHookScript(cd, "OnHide", actionUIButtonCD_OnHide)
	end
end


--------------------------------------------------
-- Event Functions
--------------------------------------------------


function module:ACTIONBAR_UPDATE_COOLDOWN()
	for cd, button in pairs(activeUICooldowns) do
		module:AssignTimer(cd, GetActionCooldown(button.action))
	end
end
