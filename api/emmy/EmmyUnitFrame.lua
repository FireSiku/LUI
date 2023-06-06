-- ####################################################################################################################
-- ##### oUF Library Functions ########################################################################################
-- ####################################################################################################################
---@meta

---@class oUF
---@field version number
---@field objects UnitFrame[] @ Array containing all UnitFrames created by `oUF:Spawn`
---@field headers UnitFrameHeader[] @ Array containing all UnitFrameHeader created by `oUF:SpawnHeader`
---@field colors table @ Table of colors used by oUF
---@field useHCYColorGradient boolean @ If set to true, `oUF:ColorGradient` will use HCY colors instead of RGB
local oUF = {}
oUF.useHCYColorGradient = false
oUF.objects = {}
oUF.headers = {}
oUF.colors = {}

--- Add a function to a table to be executed upon UnitFrame/header initialization.
---@param func function
function oUF:RegisterInitCallback(func) end

--- Make a (table of) function(s) available to all UnitFrames.
---@param name string
---@param func function|table
function oUF:RegisterMetaFunction(name, func) end

--- Used to register a style with oUF. This will also set the active style if it hasn't been set yet.
---@param name string
---@param func function @ function defining the style
function oUF:RegisterStyle(name, func) end

--- Set the active style.
---@param name string
function oUF:SetActiveStyle(name) end

--- Get the active style.
function oUF:GetActiveStyle() end

--- Return an iterator over all registered styles.
function oUF:IterateStyles() end

--- Create a single UnitFrame and apply the currently active style to it.  
---  
--- In addition to the standard group headers, oUF implements some of its own attributes. These can be supplied by the layout, but are optional.  
---- **oUF-enableArenaPrep** (boolean) can be set to toggle arena prep support. Defaults to true.
---@param unit UnitId
---@param overrideName string? @ unique global name to use for the UnitFrame. Defaults to an auto-generated name based on the unit. oUF implements some of its own attributes. These can be supplied by the layout, but are optional.
---@return UnitFrame
function oUF:Spawn(unit, overrideName) end

--- Register an element with oUF.
---@param name string
---@param update function? @ function used to update the element
---@param enable function? @ function used to enable the element for a given UnitFrame and unit
---@param disable function? @ function used to disable the element for a given UnitFrame
function oUF:AddElement(name, update, enable, disable) end

--- Used to convert a percent value (the quotient of `a` and `b`) into a gradient from 2 or more RGB colors. A RGB color is a sequence of 3 consecutive RGB percent values in the range [0-1].  
--- If more than 2 colors are passed, the gradient will be between the two colors which percent lies in an evenly divided range.  
--- If `a` is negative or `b` is zero then the first 3 RGB values are returned. If `a` is bigger than or equal to `b`, then the last 3 RGB values are returend.  
--- http://www.wowwiki.com/ColorGradient  
---   
--- If **oUF.useHCYColorGradient** is set to true, HCY color values will be expected instead.
---@param a number @ value used as numerator to calculate the percentage
---@param b number @ value usedas denominator to calculate the percentage
---@param ... table @ List of RGB percent values. At least 6 values should be passed [0-1]
---@vararg number
function oUF:ColorGradient(a, b, ...) end

--- Used to call a function directly if the current character is logged in and the factory is active.  
--- Else the function is queued up to be executed at a later time (upon PLAYER_LOGIN by default).
---@param func function
function oUF:Factory(func) end

--- Used to enable the factory.
function oUF:EnableFactory() end

--- Used to disable the factory.
function oUF:DisableFactory() end

--- Attempt to execute queued up functions. The current player must be logged in and the factory must be active for this to succeed.
function oUF:RunFactoryQueue() end

-- ####################################################################################################################
-- ##### oUF UnitFrames ###############################################################################################
-- ####################################################################################################################

---@class UnitFrame : Frame
---@field colors table @ Table of colors used by oUF
---@field Auras UnitFrame-Auras?
---@field Buffs UnitFrame-Buffs?
---@field Debuffs UnitFrame-Debuffs?
---@field Health UnitFrame-Health
---@field Power UnitFrame-Power
---@field AlternativePower UnitFrame-AlternativePower?
---@field AdditionalPower UnitFrame-AdditionalPower?
---@field HealthPrediction UnitFrame-HealthPrediction?
---@field PowerPrediction UnitFrame-PowerPrediction?
---@field ClassPower UnitFrame-ClassPower?
---@field Runes UnitFrame-Runes?
---@field Totems UnitFrame-Totems?
---@field Stagger UnitFrame-Stagger?
local UnitFrame = {}
UnitFrame.colors = {}

--- Activate an element for the given UnitFrame.
---@param name string
---@param unit UnitId @ unit to be passed to the element's Enable function. Defaults to the frame's unit 
function UnitFrame:EnableElement(name, unit) end

--- Deactivate an element for the given UnitFrame.
---@param name string
function UnitFrame:DisableElement(name) end

--- Check if an element is enabled on the given frame
---@param name string
function UnitFrame:IsElementEnabled(name) end

--- Toggle the visibility of a UnitFrame based on the existence of its unit. This is a reference to `RegisterUnitWatch`
---@param asState boolean @ if true, the frame's "state-unitexists" attribute will be set to a boolean value denoting whether the unit exists; if false, the frame will be shown if its unit exists, and hidden if it does not (boolean)
function UnitFrame:Enable(asState) end

--- UnregisterUnitWatch for the given frame and hide it
function UnitFrame:Disable() end

--- Check if a UnitFrame is registered with the unit existence monitor. This is a reference to `UnitWatchRegistered`
function UnitFrame:IsEnabled() end

--- Update all enabled elements on the given frame
---@param event string @ event name to pass to the elements' update functions 
function UnitFrame:UpdateAllElements(event) end

--- Used to convert a percent value (the quotient of `a` and `b`) into a gradient from 2 or more RGB colors. A RGB color is a sequence of 3 consecutive RGB percent values in the range [0-1].  
--- If more than 2 colors are passed, the gradient will be between the two colors which percent lies in an evenly divided range.  
--- If `a` is negative or `b` is zero then the first 3 RGB values are returned. If `a` is bigger than or equal to `b`, then the last 3 RGB values are returend.  
--- http://www.wowwiki.com/ColorGradient  
--- 
--- If **oUF.useHCYColorGradient** is set to true, HCY color values will be expected instead.
---@param a number @ value used as numerator to calculate the percentage
---@param b number @ value usedas denominator to calculate the percentage
---@param ... table @ List of RGB percent values. At least 6 values should be passed [0-1]
---@vararg number
function UnitFrame:ColorGradient(a, b, ...) end

-- ####################################################################################################################
-- ##### oUF Group Headers ############################################################################################
-- ####################################################################################################################

--- Create a group header and apply the currently active style to it.  
---  
--- In addition to the standard group headers, oUF implements some of its own attributes. These can be supplied by the layout, but are optional.  
---- **oUF-initialConfigFunction** (string) can contain code that will be securely run at the end of the initial secure configuration
---- **oUF-onlyProcessChildren** (boolean) can be used to force headers to only process children
---@param overrideName string? @ unique global name to be used for the header. Defaults to an auto-generated name based on the name of the active style and other arguments passed to `:SpawnHeader` (string?)
---@param template string? @ name of a template to be used for creating the header. Defaults to `'SecureGroupHeaderTemplate'`
---@param visibility string @ macro conditional(s) which define when to display the header. Further argument pairs. Consult [Group Headers](http://wowprogramming.com/docs/secure_template/Group_Headers.html) for possible values. In addition to the standard group headers, oUF implements some of its own attributes. These can be supplied by the layout, but are optional.
---@return UnitFrameHeader
function oUF:SpawnHeader(overrideName, template, visibility, ...) end

---@class UnitFrameHeader : Frame
local UnitFrameHeader = {}


-- ####################################################################################################################
-- ##### oUF Nameplates ###############################################################################################
-- ####################################################################################################################

--- Create nameplates and apply the currently active style to them.
---@param namePrefix string? @ prefix for the global name of the nameplate. Defaults to an auto-generated prefix
---@param nameplateCallback function? @ function to be called after a nameplate unit or the player's target has changed. The arguments passed to the callback are the updated nameplate, if any, the event that triggered the update, and the new unit (function?)
---@param nameplateCVars table? @ list of console variable-value pairs to be set when the player logs in
---@return NamePlate
function oUF:SpawnNamePlates(namePrefix, nameplateCallback, nameplateCVars) end

---@class NamePlate : Frame
local NamePlate = {}

-- ####################################################################################################################
-- ##### oUF Elements #################################################################################################
-- ####################################################################################################################
-- \.(\w+)\s+- (.*)\((\w+)\)
-- ---@field $1 $3 @ $2

---@class Unitframe-ElementBG : Texture
---@field multiplier number @ Used to tint the background based on the main widgets R, G and B values. Defaults to 1 
local ElementBG = {}
ElementBG.multiplier = 1

--- Handles the updating of a status bar that displays the unit's health.
---@class UnitFrame-Health : StatusBar
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. It will inherit the color of the main StatusBar.
---@field smoothGradient table @ 9 color values to be used with the .colorSmooth option
---@field considerSelectionInCombatHostile boolean @ Indicates whether selection should be considered hostile while the unit is in combat with the player
---@field colorDisconnected boolean @ Use `self.colors.disconnected` to color the bar if the unit is offline 
---@field colorTapping boolean @ Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player 
---@field colorThreat boolean @ Use `self.colors.threat[threat]` to color the bar based on the unit's threat status. `threat` is defined by the first return of [UnitThreatSituation](https://wow.gamepedia.com/API_UnitThreatSituation) 
---@field colorClass boolean @ Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) 
---@field colorClassNPC boolean @ Use `self.colors.class[class]` to color the bar if the unit is a NPC 
---@field colorClassPet boolean @ Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player 
---@field colorSelection boolean @ Use `self.colors.selection[selection]` to color the bar based on the unit's selection color. `selection` is defined by the return value of Private.unitSelectionType, a wrapper function for [UnitSelectionType](https://wow.gamepedia.com/API_UnitSelectionType) 
---@field colorReaction boolean @ Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the unit. `reaction` is defined by the return value of [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) 
---@field colorSmooth boolean @ Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient based on the player's current health percentage 
---@field colorHealth boolean @ Use `self.colors.health` to color the bar. This flag is used to reset the bar color back to default if none of the above conditions are met 
local Health = {}

--- A Frame to hold `Button`s representing both buffs and debuffs.
---@class UnitFrame-Auras
---@field disableMouse boolean @ Disables mouse events 
---@field disableCooldown boolean @ Disables the cooldown spiral 
---@field size number @ Aura button size. Defaults to 16 
---@field width number @ Aura button width. Takes priority over `size` 
---@field height number @ Aura button height. Takes priority over `size` 
---@field onlyShowPlayer boolean @ Shows only auras created by player/vehicle 
---@field showStealableBuffs boolean @ Displays the stealable texture on buffs that can be stolen 
---@field spacing number @ Spacing between each button. Defaults to 0 
---@field spacing-x number @ Horizontal spacing between each button. Takes priority over `spacing` 
---@field spacing-y number @ Vertical spacing between each button. Takes priority over `spacing` 
---@field growth-x string @ Horizontal growth direction. Defaults to 'RIGHT' 
---@field growth-y string @ Vertical growth direction. Defaults to 'UP' 
---@field initialAnchor string @ Anchor point for the aura buttons. Defaults to 'BOTTOMLEFT' 
---@field filter string @ Custom filter list for auras to display. Defaults to 'HELPFUL' for buffs and 'HARMFUL' for debuffs 
---@field tooltipAnchor string @ Anchor point for the tooltip. Defaults to 'ANCHOR_BOTTOMRIGHT', however, if a frame has anchoring restrictions it will be set to 'ANCHOR_CURSOR' 
---@field numBuffs number @ The maximum number of buffs to display. Defaults to 32 
---@field numDebuffs number @ The maximum number of debuffs to display. Defaults to 40 
---@field numTotal number @ The maximum number of auras to display. Prioritizes buffs over debuffs. Defaults to the sum of .numBuffs and .numDebuffs 
---@field gap boolean @ Controls the creation of an invisible button between buffs and debuffs. Defaults to false 
---@field buffFilter string @ Custom filter list for buffs to display. Takes priority over `filter` 
---@field debuffFilter string @ Custom filter list for debuffs to display. Takes priority over `filter` 
local Auras = {}
Auras.numBuffs = 32
Auras.numDebuffs = 40
Auras.gap = false
Auras.size = 16
Auras.spacing = 0
Auras['growth-x'] = "RIGHT"
Auras['growth-y'] = "UP"
Auras.initialAnchor = "BOTTOMLEFT"
Auras.filter = "HELPFUL"
Auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"

--- A Frame to hold `Button`s representing buffs.
---@class UnitFrame-Buffs
---@field disableMouse boolean @ Disables mouse events 
---@field disableCooldown boolean @ Disables the cooldown spiral 
---@field size number @ Aura button size. Defaults to 16 
---@field width number @ Aura button width. Takes priority over `size` 
---@field height number @ Aura button height. Takes priority over `size` 
---@field onlyShowPlayer boolean @ Shows only auras created by player/vehicle 
---@field showStealableBuffs boolean @ Displays the stealable texture on buffs that can be stolen 
---@field spacing number @ Spacing between each button. Defaults to 0 
---@field spacing-x number @ Horizontal spacing between each button. Takes priority over `spacing` 
---@field spacing-y number @ Vertical spacing between each button. Takes priority over `spacing` 
---@field growth-x string @ Horizontal growth direction. Defaults to 'RIGHT' 
---@field growth-y string @ Vertical growth direction. Defaults to 'UP' 
---@field initialAnchor AnchorPoint @ Anchor point for the aura buttons. Defaults to 'BOTTOMLEFT' 
---@field filter string @ Custom filter list for auras to display. Defaults to 'HELPFUL' for buffs and 'HARMFUL' for debuffs 
---@field tooltipAnchor TooltipAnchor @ Anchor point for the tooltip. Defaults to 'ANCHOR_BOTTOMRIGHT', however, if a frame has anchoring restrictions it will be set to 'ANCHOR_CURSOR' 
---@field num number @ Number of buffs to display. Defaults to 32 
local Buffs = {}
Buffs.num = 32
Buffs.size = 16
Buffs.spacing = 0
Buffs['growth-x'] = "RIGHT"
Buffs['growth-y'] = "UP"
Buffs.initialAnchor = "BOTTOMLEFT"
Buffs.filter = "HELPFUL"
Buffs.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"

--- A Frame to hold `Button`s representing debuffs.
---@class UnitFrame-Debuffs
---@field disableMouse boolean @ Disables mouse events 
---@field disableCooldown boolean @ Disables the cooldown spiral 
---@field size number @ Aura button size. Defaults to 16 
---@field width number @ Aura button width. Takes priority over `size` 
---@field height number @ Aura button height. Takes priority over `size` 
---@field onlyShowPlayer boolean @ Shows only auras created by player/vehicle 
---@field showStealableBuffs boolean @ Displays the stealable texture on buffs that can be stolen 
---@field spacing number @ Spacing between each button. Defaults to 0 
---@field spacing-x number @ Horizontal spacing between each button. Takes priority over `spacing` 
---@field spacing-y number @ Vertical spacing between each button. Takes priority over `spacing` 
---@field growth-x string @ Horizontal growth direction. Defaults to 'RIGHT' 
---@field growth-y string @ Vertical growth direction. Defaults to 'UP' 
---@field initialAnchor string @ Anchor point for the aura buttons. Defaults to 'BOTTOMLEFT' 
---@field filter string @ Custom filter list for auras to display. Defaults to 'HELPFUL' for buffs and 'HARMFUL' for debuffs 
---@field tooltipAnchor string @ Anchor point for the tooltip. Defaults to 'ANCHOR_BOTTOMRIGHT', however, if a frame has anchoring restrictions it will be set to 'ANCHOR_CURSOR' 
---@field num number @ Number of debuffs to display. Defaults to 40 
local Debuffs = {}
Debuffs.num = 40
Debuffs.size = 16
Debuffs.spacing = 0
Debuffs['growth-x'] = "RIGHT"
Debuffs['growth-y'] = "UP"
Debuffs.initialAnchor = "BOTTOMLEFT"
Debuffs.filter = "HELPFUL"
Debuffs.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"


---@class UnitFrame-Portrait3D : PlayerModel
---@field showClass boolean @ Displays the unit's class in the portrait
local Portrait3D = {}

---@class UnitFrame-Portrait2D : Texture
---@field showClass boolean @ Displays the unit's class in the portrait
local Portrait2D = {}


---@class UnitFrame-Power : StatusBar
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. It will inherit the color of the main StatusBar.
---@field frequentUpdates boolean @ Indicates whether to use UNIT_POWER_FREQUENT instead UNIT_POWER_UPDATE to update the bar 
---@field displayAltPower boolean @ Use this to let the widget display alternative power, if the unit has one. By default, it does so only for raid and party units. If none, the display will fall back to the primary power 
---@field smoothGradient table @ 9 color values to be used with the .colorSmooth option 
---@field considerSelectionInCombatHostile boolean @ Indicates whether selection should be considered hostile while the unit is in combat with the player 
---@field colorDisconnected boolean @ Use `self.colors.disconnected` to color the bar if the unit is offline 
---@field colorTapping boolean @ Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player 
---@field colorThreat boolean @ Use `self.colors.threat[threat]` to color the bar based on the unit's threat status. `threat` is defined by the first return of [UnitThreatSituation](https://wow.gamepedia.com/API_UnitThreatSituation) 
---@field colorPower boolean @ Use `self.colors.power[token]` to color the bar based on the unit's power type. This method will fall-back to `:GetAlternativeColor()` if it can't find a color matching the token. If this function isn't defined, then it will attempt to color based upon the alternative power colors returned by [UnitPowerType](http://wowprogramming.com/docs/api/UnitPowerType.html). If these aren't defined, then it will attempt to color the bar based upon `self.colors.power[type]`. In case of failure it'll default to `self.colors.power.MANA` 
---@field colorClass boolean @ Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) 
---@field colorClassNPC boolean @ Use `self.colors.class[class]` to color the bar if the unit is a NPC 
---@field colorClassPet boolean @ Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player 
---@field colorSelection boolean @ Use `self.colors.selection[selection]` to color the bar based on the unit's selection color. `selection` is defined by the return value of Private.unitSelectionType, a wrapper function for [UnitSelectionType](https://wow.gamepedia.com/API_UnitSelectionType) 
---@field colorReaction boolean @ Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the unit. `reaction` is defined by the return value of [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) 
---@field colorSmooth boolean @ Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient based on the player's current power percentage 
local Power = {}

--- Handles the visibility and updating of a status bar that displays the player's additional power, such as Mana for Balance druids.
---@class UnitFrame-AdditionalPower : StatusBar
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. Inherits the widget's color.
---@field frequentUpdates boolean @ Indicates whether to use UNIT_POWER_FREQUENT instead UNIT_POWER_UPDATE to update the bar 
---@field displayPairs table @ Use to override display pairs. 
---@field smoothGradient table @ 9 color values to be used with the .colorSmooth option 
---@field colorPower boolean @ Use `self.colors.power[token]` to color the bar based on the player's additional power type 
---@field colorClass boolean @ Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) 
---@field colorSmooth boolean @ Use `self.colors.smooth` to color the bar with a smooth gradient based on the player's current additional power percentage 
local AdditionalPower = {}

--- Handles the visibility and updating of a status bar that displays the player's additional power, such as Mana for Balance druids.
---@class UnitFrame-AlternativePower : StatusBar
---@field smoothGradient table @ 9 color values to be used with the .colorSmooth option 
---@field considerSelectionInCombatHostile boolean @ Indicates whether selection should be considered hostile while the unit is in combat with the player 
---@field colorThreat boolean @ Use `self.colors.threat[threat]` to color the bar based on the unit's threat status. `threat` is defined by the first return of [UnitThreatSituation](https://wow.gamepedia.com/API_UnitThreatSituation) 
---@field colorPower boolean @ Use `self.colors.power[token]` to color the bar based on the unit's alternative power type 
---@field colorClass boolean @ Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) 
---@field colorClassNPC boolean @ Use `self.colors.class[class]` to color the bar if the unit is a NPC 
---@field colorSelection boolean @ Use `self.colors.selection[selection]` to color the bar based on the unit's selection color. `selection` is defined by the return value of Private.unitSelectionType, a wrapper function for [UnitSelectionType](https://wow.gamepedia.com/API_UnitSelectionType) 
---@field colorReaction boolean @ Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the unit. `reaction` is defined by the return value of [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) 
---@field colorSmooth boolean @ Use `self.colors.smooth` to color the bar with a smooth gradient based on the unit's current alternative power percentage 
local AlternativePower = {}

---@class UnitFrame-HealthPrediction
---@field myBar StatusBar @ used to represent incoming heals from the player.
---@field otherBar StatusBar @ used to represent incoming heals from others.
---@field absorbBar StatusBar @ used to represent damage absorbs.
---@field healAbsorbBar StatusBar @ used to represent heal absorbs.
---@field overAbsorb Texture @ used to signify that the amount of damage absorb is greater than the unit's missing health.
---@field overHealAbsorb Texture @ used to signify that the amount of heal absorb is greater than the unit's current health.
local HealthPrediction = {}

---@class UnitFrame-PowerPrediction
---@field mainBar StatusBar @ used to represent power cost of spells on top of the Power element.
---@field altBar StatusBar @ used to represent power cost of spells on top of the AdditionalPower element.
local PowerPrediction = {}

---@class UnitFrame-ClassPower
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. Inherits the widget's color.
local ClassPower = {}

---@class UnitFrame-Runes 
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. Inherits the widget's color.
---@field colorSpec boolean @ Use `self.colors.runes[specID]` to color the bar based on player's spec. `specID` is defined by the return value of [GetSpecialization](http://wowprogramming.com/docs/api/GetSpecialization.html) 
---@field sortOrder string|"asc"|"desc"? @ Sorting order. Sorts by the remaining cooldown time, 'asc' - from the least cooldown time remaining (fully charged) to the most (fully depleted), 'desc' - the opposite  ['asc', 'desc']
local Runes = {}

---@class UnitFrame-Totems
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. Inherits the widget's color.
---@field Icon Texture @ representing the totem icon.
---@field Cooldown Cooldown @ representing the duration of the totem.
local Totems = {}

---@class UnitFrame-Stagger : StatusBar
---@field bg Unitframe-ElementBG @ A `Texture` used as a background. Inherits the widget's color.
local Stagger = {}


