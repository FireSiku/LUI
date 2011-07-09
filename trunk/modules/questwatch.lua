--[[
       Project....: LUI NextGenWoWUserInterface
       File.......: questwatch.lua
       Description: Makes the Questwatch Frame movable
       Version....: 1.02
       Rev Date...: 09/07/2011 [dd/mm/yyyy]
       Author.....: Yunai
    ]]

    local version = 1.0
    local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
    local module = LUI:NewModule("Questwatch", "AceHook-3.0")
	
    local _G = _G
    local pos
    local watchframeheight = 450

    local function QWFM_Tooltip(self)
       GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Click to move...", 1, 1, 0.5, 1, 1, 1)
        GameTooltip:Show()
    end
     
    local function init()

 	if not LUIDB.QuestWatch then LUIDB.QuestWatch = {a1 = "TOPRIGHT", af = "UIParent",a2 = "TOPRIGHT", x = -100, y = -150} end
	pos = LUIDB.QuestWatch
	
        local wf = _G['WatchFrame']
        wf:SetClampedToScreen(false)
        wf:SetMovable(1)
        wf:SetUserPlaced(true)
        wf:ClearAllPoints()   
        wf.ClearAllPoints = function() end
        wf:SetPoint(pos.a1,pos.af,pos.a2,pos.x,pos.y)
        wf.SetPoint = function() end
        wf:SetHeight(watchframeheight) 
           
        local wfh = _G['WatchFrameHeader']
        wfh:EnableMouse(true)
        wfh:RegisterForDrag("LeftButton")
        wfh:SetHitRectInsets(-15, -15, -5, -5)
        wfh:SetScript("OnDragStart", function(s)
          local f = s:GetParent()
          f:StartMoving()
        end)
        wfh:SetScript("OnDragStop", function(s)
          local f = s:GetParent()
          f:StopMovingOrSizing()
		  local _
		  pos.a1, _, pos.a2, pos.x, pos.y = f:GetPoint()
        end)
        wfh:SetScript("OnEnter", function(s)
          QWFM_Tooltip(s)
        end)
        wfh:SetScript("OnLeave", function(s)
          GameTooltip:Hide()
        end)
		return
    end
	
	function module:OnInitialize()
		init()
		LUI:RegisterOptions(self)
    end
	
	  local a = CreateFrame("Frame")

  a:SetScript("OnEvent", function(self, event)
    if(event=="PLAYER_LOGIN") then
      init()
    end
  end)
  
  a:RegisterEvent("PLAYER_LOGIN")