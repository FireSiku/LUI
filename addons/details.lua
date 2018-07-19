local addonname, LUI = ...

LUI.Versions.details = 5

function LUI:InstallDetails()
   
   if (not IsAddOnLoaded("Details")) then
      return
   end
   
   local ProfileName = UnitName("player") .. " - " .. GetRealmName()
   if (LUI.db.global.luiconfig[ProfileName].Versions.details == LUI.Versions.details) then
      return
   end
   
   -- Get the window 1 object
   local Details = _G._detalhes
   local instance = Details:GetInstance(1)
   
   if (instance) then
      
      -- Set the skin to Default and then apply the New Gray.
      if (instance.skin ~= "New Gray") then
         instance:ChangeSkin("New Gray")
      end
      
      -- Turn off the gradient wallpaper
      instance:InstanceWallpaper(false)

      -- Enable shadow on title bar buttons.
      instance:ToolbarMenuSetButtonsOptions(nil, true)
      
      -- Change the text font on title bar to prototype.
      instance:AttributeMenu(true, -20, 4, "Prototype", 11, nil, nil, true)
      
      -- Change bar's settings
	  --instance:SetBarSettings (height, texture, colorByClass, fixedcolor, bgTexture, bgColorByClass, bgFixedcolor, alpha, iconfile, barStart, spacement, customtexture)
      instance:SetBarSettings(24, "Minimalist", false, {0.45, 0.45, 0.45, 0.8}, "Minimalist", false, {0.45, 0.45, 0.45, 0.2}, nil, "Interface\AddOns\Details\images\spec_icons_normal_alpha", false, 0) -- luacheck: ignore
      
	  -- Change bar's text settings
	  --instance:SetBarTextSettings (size, font, fixedcolor, leftcolorbyclass, rightcolorbyclass, leftoutline, rightoutline, customrighttextenabled, customrighttext, percentage_type, 
	  --                              showposition, customlefttextenabled, customlefttext, smalloutline_left, smalloutlinecolor_left, smalloutline_right, smalloutlinecolor_right)
	  --instance:SetBarRightTextSettings (total, persecond, percent, bracket, separator)
	  instance:SetBarTextSettings(14, "Arial Narrow", {1,1,1,1}, false, false, true, false, nil, nil, 1, true, nil, nil, true, false)
	  instance:SetBarRightTextSettings(true, true, false, "(", "NONE")

	  -- Change the position of the window
	  local posTable = instance:CreatePositionTable()
	  posTable.x, posTable.y = -449, 21
	  posTable.w, posTable.h = 200, 200
	  posTable.point = "BOTTOMRIGHT"
	  instance:RestorePositionFromPositionTable(posTable)
	  
      -- We don't need the close button, so, disable it.
      instance:ToolbarMenuSetButtons(nil, true, nil, true, true, false)
	  instance:ToolbarMenuSetButtonsOptions(0, false)
	  instance:ToolbarMenuButtonsSize(1)
	  instance:DesaturateMenu(true)
      
      -- Always show the player bar even if hi/she isn't on top players.
      instance:SetBarFollowPlayer(true)
      
      -- Remove half of Details! tooltips border alpha.
      Details:SetTooltipBackdrop("Blizzard Tooltip", 16, {1, 1, 1, 0.5})
      
      -- Enable bar animations.
      Details:SetUseAnimations(true)
      
      -- Set update speed to 0.3
      Details:SetWindowUpdateSpeed(0.3)
      
	  -- Set the LUI panel to Details
	  local panelDB = LUI.db:GetNamespace("Panels")
	  panelDB.profile.Dps.Anchor = "DetailsBaseFrame1"
	  panelDB.profile.Dps.Additional = "DetailsRowFrame1"
	  panelDB.profile.Dps.OffsetY = 0
	  
   end
   
end
