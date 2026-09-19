local _, D = ...
local window, reportBox
local page = "overview"
local WIDTH, HEIGHT = 740, 590
local PATH = "World of Warcraft\\_retail_\\WTF\\Account\\<account folder>\\SavedVariables\\LUIDiagnostics.lua"
local DISCORD = "https://discord.gg/SR29pjc"

local function Label(parent, size, x, y, width)
	local label = parent:CreateFontString(nil, "OVERLAY")
	label:SetFont(STANDARD_TEXT_FONT, size, "")
	label:SetPoint("TOPLEFT", x, y)
	label:SetWidth(width)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("TOP")
	label:SetWordWrap(true)
	label:SetTextColor(0.88, 0.9, 0.94)
	return label
end

local function Button(parent, text, x, y, width, click)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 32)
	button:SetPoint("TOPLEFT", x, y)
	button:SetText(text)
	button:SetScript("OnClick", click)
	return button
end

local function ScaleWindow()
	local scale = math.min(1, (UIParent:GetWidth() - 40) / WIDTH, (UIParent:GetHeight() - 40) / HEIGHT)
	window:SetScale(math.max(0.4, scale))
end

local function SetPage(nextPage)
	page = nextPage
	D:RefreshWindow()
end

local function MakeWindow()
	window = CreateFrame("Frame", "LUIDiagnosticsWindow", UIParent, "BackdropTemplate")
	window:SetSize(WIDTH, HEIGHT)
	window:SetPoint("CENTER")
	window:SetFrameStrata("DIALOG")
	window:SetClampedToScreen(true)
	window:EnableMouse(true)
	window:SetMovable(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", function(self) self:StartMoving() end)
	window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	window:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
	window:SetBackdropColor(0.055, 0.065, 0.085, 0.99)
	window:SetBackdropBorderColor(0.25, 0.3, 0.37, 1)
	tinsert(UISpecialFrames, "LUIDiagnosticsWindow")
	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() window:Hide() end)
	window.title = Label(window, 23, 24, -23, 650)
	window.title:SetText("LUI DEBUG")
	window.status = Label(window, 15, 24, -65, 690)
	window.heading = Label(window, 19, 24, -111, 690)
	window.body = Label(window, 14, 24, -147, 690)
	window.body:SetHeight(115)
	window.detail = Label(window, 14, 24, -280, 690)
	window.detail:SetHeight(150)
	window.note = Label(window, 12, 24, -445, 690)
	window.note:SetHeight(60)
	window.note:SetTextColor(0.68, 0.73, 0.8)
	window.primary = Button(window, "", 24, -519, 222, function()
		if page == "confirmStart" then
			D:ChangeRecording(true)
		elseif page == "confirmStop" then
			D:ChangeRecording(false)
		elseif page == "report" or page == "file" then
			reportBox:SetFocus()
			reportBox:HighlightText()
		else
			SetPage(D:IsRecording() and "confirmStop" or "confirmStart")
		end
	end)
	window.secondary = Button(window, "", 259, -519, 222, function()
		if page == "confirmStart" or page == "confirmStop" or page == "report" or page == "file" then
			SetPage("overview")
		else
			SetPage("report")
		end
	end)
	window.tertiary = Button(window, "File / Discord instructions", 494, -519, 222, function() SetPage("file") end)
	window.combat = Label(window, 12, 24, -565, 690)
	window.combat:SetTextColor(1, 0.7, 0.35)
	reportBox = LibStub("AceGUI-3.0"):Create("MultiLineEditBox")
	reportBox.frame:SetParent(window)
	reportBox.frame:ClearAllPoints()
	reportBox.frame:SetPoint("TOPLEFT", 24, -148)
	reportBox:SetWidth(692)
	reportBox:SetLabel("")
	reportBox:SetNumLines(19)
	reportBox:DisableButton(true)
	reportBox:SetMaxLetters(0)
	reportBox.editBox:SetAutoFocus(false)
	-- The editable copy is disposable; edits never change the saved report.
	window:SetScript("OnHide", function()
		reportBox:ClearFocus()
		window:UnregisterAllEvents()
	end)
	window:SetScript("OnShow", function()
		window:RegisterEvent("PLAYER_REGEN_DISABLED")
		window:RegisterEvent("PLAYER_REGEN_ENABLED")
		window:RegisterEvent("DISPLAY_SIZE_CHANGED")
	end)
	window:SetScript("OnEvent", function(_, event)
		if event == "DISPLAY_SIZE_CHANGED" then ScaleWindow() end
		-- This only refreshes our own dialog; combat ending never triggers a reload.
		D:RefreshWindow()
	end)
	window:Hide()
end

function D:RefreshWindow()
	if not window then return end
	local active, combat = self:IsRecording(), InCombatLockdown()
	local current = self:GetLatestSession()
	local count = current and #current.errors or 0
	window.status:SetText((active and "|cffffcc66DIAGNOSTICS ACTIVE|r" or "|cff90c7a0DIAGNOSTICS OFF|r")
		.. "   |   Latest session: " .. count .. " stored error groups")
	window.combat:SetText(combat and "In combat: starting and stopping with a reload are unavailable." or "")
	window.primary:Enable()
	window.secondary:Enable()
	window.tertiary:Show()
	window.body:Show()
	window.detail:Show()
	reportBox.frame:Hide()
	window.note:SetText("The last 3 sessions are kept, with up to 40 error groups per session. Repeats are counted. No settings or chat history are collected; error text can contain names.")

	if page == "confirmStart" then
		window.heading:SetText("Start diagnostics?")
		window.body:SetText("Your interface will reload immediately when you confirm. Start only at a safe moment outside combat.\n\nAfter the reload, play normally until the problem happens. Diagnostics will stay active across reloads and logins until you stop it.")
		window.detail:SetText("The report collects Lua errors from BugGrabber, blocked actions, timestamps, combat and window state, versions and active LUI modules.\n\n!BugGrabber is needed for general Lua errors. Without it, blocked actions and Lua warnings can still be recorded.\n\nPrevious sessions are retained within the history limit.")
		window.primary:SetText("Start & reload UI")
		window.secondary:SetText("Cancel")
		window.tertiary:Hide()
		if combat then window.primary:Disable() end
	elseif page == "confirmStop" then
		window.heading:SetText("Stop diagnostics and save the log?")
		window.body:SetText("Your interface will reload immediately when you confirm. This stops recording and writes the collected data to disk.\n\nAfter the reload, this window shows you how to copy the report or find the saved file.")
		window.detail:SetText("Wait until you are safely outside combat.\n\nThe report remains available after recording stops. You can inspect it before sharing it with the LUI team.")
		window.primary:SetText("Stop, save & reload UI")
		window.secondary:SetText("Cancel")
		window.tertiary:Hide()
		if combat then window.primary:Disable() end
	elseif page == "report" or page == "file" then
		window.body:Hide()
		window.detail:Hide()
		reportBox.frame:Show()
		if page == "report" then
			window.heading:SetText("Copy the latest session report")
			reportBox:SetText(self:BuildReport())
			window.note:SetText("Click Select all, then press Ctrl+C (Mac: Cmd+C). Paste into Discord, or into a .txt file and attach it if the report is long. Check that END OF REPORT is included. Text edits here do not change the saved data.")
		else
			window.heading:SetText("Share your report with the LUI team")
			local saveHint = active and "Recording is still active. Stop, save & reload UI first so the file contains the latest data."
				or "After Stop, save & reload UI, the file is ready to attach."
			reportBox:SetText(saveHint .. "\n\nFILE LOCATION (Retail)\n" .. PATH
				.. "\n\nOpen your World of Warcraft installation folder, then _retail_, WTF, Account, your account folder and SavedVariables."
				.. "\n\nAttach LUIDiagnostics.lua. Do not send LUI.lua, the .bak file or your whole WTF folder."
				.. "\n\nDISCORD\n" .. DISCORD
				.. "\n\nPost in the LUI support / bug-report area, or the thread where the team requested your log."
				.. "\n\nDescribe what happened, what you were doing and roughly when it occurred. The file includes up to 3 sessions; the copyable report shows the latest session."
				.. "\n\nYou can also use Copy report to avoid looking through folders. Nothing is uploaded automatically.")
			window.note:SetText("<account folder> is a placeholder for your own account directory. The report and the file may contain names from error text. Review them before sharing.")
			if current and current.actionBars then
				window.note:SetText("Action-bar trace: also attach World of Warcraft/_retail_/Logs/taint.log alongside LUIDiagnostics.lua. Check timestamps for this session; older native log entries are retained.")
			end
		end
		window.primary:SetText("Select all (then Ctrl+C)")
		window.secondary:SetText("Back")
		window.tertiary:SetShown(page == "report")
	else
		window.heading:SetText(active and "Play normally until the problem happens" or "Guided troubleshooting")
		if active then
			window.body:SetText("Diagnostics is running in the background, including during combat. When the problem has happened, return here at a safe moment and stop recording.\n\n" .. self:GetCaptureStatus())
		else
			window.body:SetText("Use this when you are investigating a problem with LUI or the support team asks for a diagnostic report.\n\nThe steps below guide you through recording and sharing the information.")
		end
		window.detail:SetText("1. START\nConfirm the start and automatic interface reload.\n\n2. PLAY\nLet the problem happen while diagnostics is active.\n\n3. STOP AND SHARE\nStop, save and reload. Copy the report or attach the log in Discord.")
		window.primary:SetText(active and "Stop diagnostics..." or "Start diagnostics...")
		window.secondary:SetText("Copy report")
		if not current then window.secondary:Disable() end
		if combat then window.primary:Disable() end
	end
end

function D:OpenWindow(afterReload)
	if InCombatLockdown() then LUI:Print("LUI DEBUG: Please wait until you are out of combat.") return end
	self:Initialize()
	if not window then MakeWindow() end
	page = afterReload == "stopped" and "file" or "overview"
	ScaleWindow()
	window:Show()
	self:RefreshWindow()
end
