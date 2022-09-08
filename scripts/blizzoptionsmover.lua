local addonname, LUI = ...
local script = LUI:NewScript("BlizzOptionsMover", "AceEvent-3.0")

local ChatConfigFrame = _G.ChatConfigFrame
local MacOptionsFrame = _G.MacOptionsFrame
local KeyBindingFrame = _G.KeyBindingFrame
local AudioOptionsFrame = _G.AudioOptionsFrame
local VideoOptionsFrame = _G.VideoOptionsFrame
local InterfaceOptionsFrame = _G.InterfaceOptionsFrame

function script:MakeMovable(frame)
	local mover = CreateFrame("Frame", frame:GetName() .. "Mover", frame)
	mover:EnableMouse(true)
	mover:SetPoint("TOP", frame, "TOP", 0, 10)
	mover:SetWidth(160)
	mover:SetHeight(40)
	mover:SetScript("OnMouseDown", function(self)
		self:GetParent():StartMoving()
	end)
	mover:SetScript("OnMouseUp", function(self)
		self:GetParent():StopMovingOrSizing()
	end)
	frame:SetMovable(true)
end

function script:PLAYER_ENTERING_WORLD(event)
	self:UnregisterEvent(event)
	
	self:MakeMovable(InterfaceOptionsFrame)
	self:MakeMovable(ChatConfigFrame)
	self:MakeMovable(AudioOptionsFrame)
	self:MakeMovable(VideoOptionsFrame)
	if MacOptionsFrame then
	   self:MakeMovable(MacOptionsFrame)
	end
end

function script:ADDON_LOADED(event, addon)
	if addon == "Blizzard_BindingUI" then
		self:UnregisterEvent(event)
		
		self:MakeMovable(KeyBindingFrame)
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD")
script:RegisterEvent("ADDON_LOADED")
