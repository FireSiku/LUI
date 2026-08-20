---@class LUIAddon
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")

module.defaults.profile.Settings = {
			ShowV2Textures = true,
			ShowV2PartyTextures = true,
			ShowV2ArenaTextures = true,
			ShowV2BossTextures = true,
			Castbars = true,
			HideBlizzRaid = false,
			AuratimerFont = "Prototype",
			AuratimerSize = 12,
			AuratimerFlag = "OUTLINE",
		}
