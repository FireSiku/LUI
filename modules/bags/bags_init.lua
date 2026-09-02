--[[
	Module.....: Bags
	Description: Replace the default bags.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags : LUIModule, AceHook-3.0
local module = LUI:NewModule("Bags", "AceHook-3.0")

module.enableButton = true

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Bags = {
			Lock = false,
			RowSize = 16,
			Padding = 8,
			Spacing = 4,
			Scale = 1,
			BagBar = true,
			ItemQuality = true,
			ItemLevel = true,
			BagNewline = false,
			ShowNew = false,
			ShowQuest = true,
			ShowOverlay = true,
			X = 0,
			Y = 0,
		},
		Textures = {
			BackgroundTex = "Blizzard Tooltip",
			BorderTex = "Stripped_medium",
			BorderSize = 5,
		},
		-- Fonts and Colors
		Fonts = {
			Bags = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
			Stack = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
		},
		Colors = {
			Search =         { r = 0.6,  g = 0.6,  b = 1,    a = 1,   t = "Class",      },
			Border =         { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Individual", },
			Background =     { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Class",      },
			ItemBackground = { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Individual", },
			Professions = { r = 0.1, g = 0.5, b = 0.2, a = 1, t = "Individual", },
			Bags =        { r = 1,   g = 1,   b = 1,   a = 1, t = "Individual", },
			Stack =       { r = 1,   g = 1,   b = 1,   a = 1, t = "Individual", },
		},
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	module:SetBags()

	local origToggleBag = ToggleBag
	local origOpenBag = OpenBag
	module:RawHook("ToggleBag", function(id)
		if module:IsCharacterBag(id) then
			module.ToggleBags()
		else
			origToggleBag(id)
		end 
	end, true)
	module:RawHook("OpenBag", function(id, force)
		if module:IsCharacterBag(id) then
			module.OpenBags()
		else
			origOpenBag(id, force)
		end
	end, true)
	module:RawHook("ToggleBackpack", module.ToggleBags, true)
	module:RawHook("OpenAllBags",    module.OpenBags,   true)
	module:RawHook("ToggleAllBags",  module.ToggleBags, true)
	module:RawHook("OpenBackpack",   module.OpenBags,   true)
	module:SecureHook("CloseBackpack",  module.CloseBags,  true)
	module:SecureHook("CloseAllBags",   module.CloseBags,  true)

	if not tContains(UISpecialFrames, "LUIBags") then
		tinsert(UISpecialFrames, "LUIBags")
	end
	_G.CloseAllBags()
end

function module:OnDisable()
	_G.CloseAllBags()
	self:UnhookAll()
	module:RestoreBlizzardBagState()
end
