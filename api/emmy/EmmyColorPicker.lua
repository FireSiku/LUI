---@meta

---@class ColorPickerFrameMixin
---@field Content ColorPickerFrameContent
---@field swatchFunc function
---@field hasOpacity boolean
---@field opacityFunc function
---@field opacity number
---@field previousValues {r: number, g: number, b: number, a: number}
---@field cancelFunc function
---@field extraInfo table
local ColorPickerFrameMixin = {}

---@class ColorPickerInfoTable
---@field swatchFunc function
---@field hasOpacity boolean
---@field opacityFunc function
---@field opacity number
---@field r number
---@field g number
---@field b number
---@field cancelFunc function
---@field extraInfo table
local ColorPickerInfoTable = {}

---@class ColorPickerFrameContent
---@field ColorPicker ColorSelect
---@field ColorSwatchCurrent Texture
---@field ColorSwatchOriginal Texture
---@field HexBox ColorPickerHexBoxMixin
---@field AlphaBackground Texture
local ColorPickerFrameContent = {}

---@class ColorPickerHexBoxMixin
---@field Instructions FontString
---@field Hash FontString
ColorPickerHexBoxMixin = {}

function ColorPickerFrameMixin:OnLoad()
end

function ColorPickerFrameMixin:OnShow()
end

function ColorPickerFrameMixin:OnKeyDown(key)
end

function ColorPickerFrameMixin:SetupColorPickerAndShow(info)
end

local function T(t,m) m = m or ""; for k,v in pairs(t) do if type(v) == "table" then print(m,k,v,v.GetObjectType and v:GetObjectType()); T(v,m.."- ") else print(m,k,v) end end end; T(ColorPickerFrame.Content)

---[Documentation](https://warcraft.wiki.gg/wiki/API_ColorSelect_GetColorRGB)
---@return number r
---@return number g
---@return number b
function ColorPickerFrameMixin:GetColorRGB()
end

---@return number a
function ColorPickerFrameMixin:GetColorAlpha()
end

---@return table extraInfo
function ColorPickerFrameMixin:GetExtraInfo()
    return self.extraInfo;
end

--- Get previous RGB values
---@return number r
---@return number g
---@return number b
---@return number a
function ColorPickerFrameMixin:GetPreviousValues()
end

function ColorPickerHexBoxMixin:OnLoad()
end

function ColorPickerHexBoxMixin:OnTextChanged()
end

function ColorPickerHexBoxMixin:OnEnterPressed();
end

---@param r number
---@param g number
---@param b number
function ColorPickerHexBoxMixin:OnColorSelect(r, g, b)
end
