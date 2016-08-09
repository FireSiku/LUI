local addonname, LUI = ...

LUI.Versions.details = 5

function LUI:InstallDetails()
   
   if (not IsAddOnLoaded ("Details")) then
      return
   end
   
   local ProfileName = UnitName ("player") .. " - " .. GetRealmName()
   if (LUI.db.global.luiconfig[ProfileName].Versions.details == LUI.Versions.details) then
      return
   end
   
   --> Get the window 1 object
   local Details = _G._detalhes
   local instance = Details:GetInstance (1)
   
   if (instance) then
      
      --> Set the skin to Default and then apply the Serenity.
      if (instance.skin ~= "Serenity") then
         instance:ChangeSkin ("Serenity")
      end
      
      --> Turn off the gradient wallpaper
      instance:InstanceWallpaper (false)

      --> Enable shadow on title bar buttons.
      instance:ToolbarMenuSetButtonsOptions (nil, true)
      
      --> Change the text font on title bar to prototype.
      instance:AttributeMenu (true, -20, 4, "Prototype", 11, nil, nil, true)
      
      --> Change bar's height to 14, using Skyline texture and 0 pixels spacement between bars.
      instance:SetBarSettings (14, "Skyline", nil, nil, nil, nil, nil, nil, nil, nil, 0)
      
      --> We don't need the close button, so, disable it.
      instance:ToolbarMenuSetButtons (nil, nil, nil, nil, nil, false)
      
      --> Always show the player bar even if hi/she isn't on top players.
      instance:SetBarFollowPlayer (true)
      
      --> Remove half of Details! tooltips border alpha.
      Details:SetTooltipBackdrop ("Blizzard Tooltip", 16, {1, 1, 1, 0.5})
      
      --> Enable bar animations.
      Details:SetUseAnimations (true)
      
      --> Set update speed to 0.3
      Details:SetWindowUpdateSpeed (0.3)
      
   end
   
end

if (IsAddOnLoaded ("Details")) then
	local Details = _G._detalhes
	local instance = Details:GetInstance(1)
	instance.rowframe:SetParent(instance.baseframe)
end
