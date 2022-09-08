-- ####################################################################################################################
-- ##### oUF Library Functions ########################################################################################
-- ####################################################################################################################
-- luacheck: ignore

---@meta

---@class oUF
---@field version number
---@field objects UnitFrame[] @ Array containing all UnitFrames created by `oUF:Spawn`
---@field headers UnitFrameHeader[] @ Array containing all UnitFrameHeader created by `oUF:SpawnHeader`
---@field colors table @ Table of colors used by oUF
---@field useHCYColorGradient boolean @ If set to true, `oUF:ColorGradient` will use HCY colors instead of RGB
local oUF = {}

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

--- Create a single UnitFrame and apply the currently active style to it.  
---  
--- In addition to the standard group headers, oUF implements some of its own attributes. These can be supplied by the layout, but are optional.  
---- **oUF-enableArenaPrep** (boolean) can be set to toggle arena prep support. Defaults to true.
---@param unit WowUnit
---@param overrideName string? @ unique global name to use for the UnitFrame. Defaults to an auto-generated name based on the unit. oUF implements some of its own attributes. These can be supplied by the layout, but are optional.
---@return UnitFrame
function oUF:Spawn(unit, overrideName) end

--- Create nameplates and apply the currently active style to them.
---@param prefix string? @ prefix for the global name of the nameplate. Defaults to an auto-generated prefix
---@param callback function? @ function to be called after a nameplate unit or the player's target has changed. The arguments passed to the callback are the updated nameplate, if any, the event that triggered the update, and the new unit (function?)
---@param variables table? @ list of console variable-value pairs to be set when the player logs in
---@return NamePlate
function oUF:SpawnNamePlates(namePrefix, nameplateCallback, nameplateCVars) end

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
---@param ... @ List of RGB percent values. At least 6 values should be passed [0-1]
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
local UnitFrame = {}

---Activate an element for the given UnitFrame.
---@param name string
---@param unit WowUnit @ unit to be passed to the element's Enable function. Defaults to the frame's unit 
function UnitFrame:EnableElement(name, unit) end

---Deactivate an element for the given UnitFrame.
---@param name string
function UnitFrame:DisableElement(name) end

---Check if an element is enabled on the given frame
---@param name string
function UnitFrame:IsElementEnabled(name) end

---Toggle the visibility of a UnitFrame based on the existence of its unit. This is a reference to `RegisterUnitWatch`
---@param asState  @ if true, the frame's "state-unitexists" attribute will be set to a boolean value denoting whether the unit exists; if false, the frame will be shown if its unit exists, and hidden if it does not (boolean)
function UnitFrame:Enable(asState) end

---UnregisterUnitWatch for the given frame and hide it
function UnitFrame:Disable() end

---Check if a UnitFrame is registered with the unit existence monitor. This is a reference to `UnitWatchRegistered`
function UnitFrame:IsEnabled() end

---Update all enabled elements on the given frame
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
---@param ... @ List of RGB percent values. At least 6 values should be passed [0-1]
---@vararg number
function UnitFrame:ColorGradient(a, b, ...) end

-- ####################################################################################################################
-- ##### oUF Group Headers ############################################################################################
-- ####################################################################################################################

---@class UnitFrameHeader : Frame

-- ####################################################################################################################
-- ##### oUF Nameplates ###############################################################################################
-- ####################################################################################################################

---@class NamePlate : Frame
