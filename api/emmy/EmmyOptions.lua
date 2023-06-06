-- ####################################################################################################################
-- ##### Ace3 Options Table ###########################################################################################
-- ####################################################################################################################
---@meta

---@alias methodname string @ If a string is given, it must point to a valid function found within handler: `option.handler[string](info, ...)`

---@class InfoTable
---@field handler table @ Handler object for the current option
---@field type AceConfig.OptionsTable.Type @ Type of the current option
---@field options AceOption[] @ Pointer for the root of the options table
---@field option AceOption @ Pointer for the current AceOption table
---@field arg any @ Value of the current option's "arg" node if it was set.
---@field uiType string @ Parameter passed by AceConfigRegistry
---@field uiName string @ Parameter passed by AceConfigRegistry
---@field [0] string @ Name of the slash command used, or empty string ("") if not a slash

---[AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOption
---@field type AceConfig.OptionsTable.Type @ the type of the option
---@field name string|function @ display name for the option
---@field desc string|function @ description for the option (or nil for a self-describing name)
---@field descStyle string @ `"inline"` if you want the description to show below the option in a GUI (rather than as a tooltip). Currently only supported by AceGUI "Toggle"
---@field validate boolean|methodname|function @ validate the input/value before setting it. return a string (error message) to indicate error. Child options will inherit this value unless overridden.
---@field confirm boolean|function|methodname @ prompt for confirmation before changing a value. Display `"name - desc"` unless `confirmText` is set. Child options will inherit this value unless overridden.
---@field confirmText string @ confirmation text to display if `confirm` is set to true. Ignored if a function is provided instead.
---@field order number|methodname|function @ relative position of item (default = 100, 0=first, -1=last)
---@field disabled boolean|methodname|function @ option will be greyed out and disabled but still visible. Child options will inherit this value unless overridden.
---@field hidden boolean|methodname|function @ option will be hidden from sight. Child options will inherit this value unless overridden.
---@field icon string|function @ path to icon texture
---@field iconCoords table|methodname|function @ arguments to pass to SetTexCoord, e.g. {0.1,0.9,0.1,0.9}.
---@field handler table @ object on which functions are called if they are declared as strings rather than function references. Child options will inherit this value unless overridden.
---@field width AceConfig.OptionsTable.Width|number @ provide a hint for how wide this option needs to be. Full make the option the full width of the window. Number is a multiplier of the default width.
---@field arg any @ Information that will be passed down to the InfoTable
local AceOption = {}
AceOption.width = "normal"
AceOption.descStyle = "tooltip"
AceOption.order = 100
AceOption.disabled = false
AceOption.hidden = false
AceOption.guiHidden = false
AceOption.dialogHidden = false
AceOption.dropdownHidden = false
AceOption.dropdownHidden = false
AceOption.cmdHidden = false

---A execute option will simply run 'func'. In a GUI, this would be a button.If image is set, it'll display a clickable image instead of a default GUI button.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionExecute : AceOption
---@field func function|methodname @ function to execute
---@field image string|function @ path to image texture, if this is a function it can optionally return the width and height of the image as the 2nd and 3rd value, these will be used instead of imageWidth and imageHeight.
---@field imageCoords table|methodname|function @ arguments to pass to SetTexCoord, e.g. {0.1,0.9,0.1,0.9}.
---@field imageWidth number @ Width of the displayed image
---@field imageHeight number @ Height of the displayed image
local AceOptionExecute = {}

---A simple text input, with an optional validate string or function to match the text against.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionInput : AceOption
---@field get function|methodname @ getter function
---@field set function|methodname @ setter function
---@field multiline boolean|integer @ if true will be shown as a multiline editbox in dialog implementations (Integer = # of lines in editbox)
---@field pattern string @ optional validation pattern. (Use the validate field for more advanced checks!)
---@field usage string @ usage string (displayed if pattern mismatches and in console help messages)
local AceOptionInput = {}

---A simple checkbox
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionToggle : AceOption
---@field get function|methodname @ getter function
---@field set function|methodname @ setter function
---@field tristate boolean @ Make the toggle a tri-state checkbox. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
local AceOptionToggle = {}

---A option for configuring numeric values in a specific range. In a GUI, a slider.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionRange : AceOption
---@field min number @ absolute minimum value that will be allowed to be set by the option
---@field max number @ absolute maximum value that will be allowed to be set by the option
---@field softMin number @ soft minimal value, used by the UI for a convenient limit while allowing manual input of values up to min/max
---@field softMax number @ soft maximal value, used by the UI for a convenient limit while allowing manual input of values up to min/max
---@field step number @ step value: "smaller than this will break the code" (default=no stepping limit). `min` and `max` are required for `step` to function.
---@field bigStep number @ a more generally-useful step size. Support in UIs is optional.
---@field get function|methodname @ getter function
---@field set function|methodname @ setter function
---@field isPercent boolean @ range represent a percentage e.g. 1.0 will be shown as 100%, etc
local AceOptionRange = {}
AceOptionRange.isPercent = false

---Only one of the values can be selected. In a dropdown menu implementation it would likely be a radio group, in a dialog likely a dropdown combobox.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionSelect : AceOption
---@field values table|function @ [key]=value pair table to choose from, key is the value passed to "set", value is the string displayed
---@field sorting table|function @ Optional sorted array-style table with the keys of the values table as values to sort the options.
---@field get function|methodname @ getter function
---@field set function|methodname @ setter function
---@field style string|"dropdown"|"radio" @ (optional support in implementations)
local AceOptionSelect = {}

---Multiple "toggle" elements condensed into a group of checkboxes, or something else that makes sense in the interface.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionMultiselect : AceOption
---@field values table|function @ [key]=value pair table to choose from, key is the value passed to "set", value is the string displayed
---@field get function|methodname @ will be called for every key in values with the key name as last parameter
---@field set function|methodname @ will be called with keyname, state as parameters
---@field tristate boolean @ Make the checkmarks tri-state. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
local AceOptionMultiselect = {}

---Opens a color picker form, in GUI possibly a button to open that.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionColor : AceOption
---@field get function|methodname @ getter function must return four arguments (r,g,b,a)
---@field set function|methodname @ setter function using four arguments (r,g,b,a). If `hasAlpha` is false, (a) will always be set as 1.0
---@field hasAlpha boolean @ indicate if alpha is adjustable
local AceOptionColor = {}
AceOptionColor.hasAlpha = false

---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionKeybinding : AceOption
---@field get function|methodname @ getter function
---@field set function|methodname @ setter function
local AceOptionKeybinding = {}

---A heading. In commandline and dropdown UIs shows as a heading, in a dialog UI it will additionaly provide a break in the layout.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionHeader : AceOption
---@field name string @ text to display
local AceOptionHeader = {}

---A paragraph of text to appear next to other options in the config, optionally with an image in front of it.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionDesc : AceOption
---@field name string @ text to display
---@field fontSize string|"small"|"medium"|"large" @ Size of the text. Only the pre-defined values are allowed.
---@field image string|function @ path to image texture, if this is a function it can optionally return the width and height of the image as the 2nd and 3rd value, these will be used instead of imageWidth and imageHeight.
---@field imageCoords table|methodname|function @ arguments to pass to SetTexCoord, e.g. {0.1,0.9,0.1,0.9}.
---@field imageWidth number @ Width of the displayed image
---@field imageHeight number @ Height of the displayed image
local AceOptionDesc = {}
AceOptionDesc.fontSzie = "small"

---The first table in an AceOptions table is implicitly a group. You can have more levels of groups by simply adding another table with type="group" under the first args table.
---- [AceConfig Options Table Documentation](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
---@class AceOptionGroup : AceOption
---@field args table @ table with more AceOptions in it.
---@field plugins table @ table containing named tables with more args in them. This allows modules and libraries to easily add more content to an addon's options table.
---@field childGroups string|"tree"|"tab"|"select" @ decides how children groups of this group are displayed. Default to `"tree"` then `"tab"`. Only dialog-driven UIs are assumed to behave differently for all types.
---@field inline boolean @ show as a bordered box in a dialog UI, or at the parent's level with a separate heading in commandline and dropdown UIs.
---@field get function|methodname @ getter function. Child options will inherit this value unless overridden.
---@field set function|methodname @ setter function. Child options will inherit this value unless overridden.
local AceOptionGroup = {}
