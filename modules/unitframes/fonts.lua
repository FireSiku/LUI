-- Apply a font to all unit-frame text settings in the active profile.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")

local function ApplyFont(settings, defaults, font)
    for key, value in pairs(defaults) do
        if key == "Font" and type(value) == "string" then
            settings[key] = font
        elseif type(value) == "table" and type(settings[key]) == "table" then
            ApplyFont(settings[key], value, font)
        end
    end
end

local RefreshFonts = LUI.OutOfCombatWrapper(function()
    if module:IsEnabled() then module:Refresh() end
end)

function module:ApplySharedFont(font)
    if type(font) ~= "string" or not Media:IsValid("font", font) then return end
    local profile = module.db.profile
    for _, unit in ipairs(module.units) do
        ApplyFont(profile[unit], module.defaults.profile[unit], font)
    end
    profile.Settings.AuratimerFont = font
    profile.Settings.AuraCountFont = font
    profile.Settings.LastAppliedFont = font
    RefreshFonts()
end
