--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: faq.lua
	Description: FAQ Options
	Version....: 1.0
	Rev Date...: 08/07/2010
	Author.....: Louí [EU - Das Syndikat] <In Fidem>
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("FAQ")

function module:LoadOptions()
	local options = {
		FAQ = {
			name = "FAQ",
			type = "group",
			order = 5,
			args = {
				header10 = {
					name = "FAQ",
					type = "header",
					order = 1,
				},
				emptyq1 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 4,
				},
				question2 = {
					order = 5,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r The Spelltimer above my PlayerFrame and the CooldownLine above my Mainbars... what Addon is that?",
				},
				answer2 = {
					order = 6,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r This Addon is called ForteXorcist. Type /fx to open the OptionPanel.",
				},
				emptyq2 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 7,
				},
				question3 = {
					order = 8,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r There are too may Spells on my Spelltimer and CooldownLine... any suggestion?",
				},
				answer3 = {
					order = 9,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r Type /fx and choose the spelltimer/cooldowntimer tab at the bottom. Now go to Coloring/Filtering and type in the Spellname. Set it on Ignore or do other stuff.",
				},
				emptyq3 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 10,
				},
				question6 = {
					order = 17,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r Several Blizzard Frames and Fonts are too smale and everything looks too tiny. What should i do?",
				},
				answer6 = {
					order = 18,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r Press ESC, go to Video Options and choose a different UIScale. Type /rl after you choose on.",
				},
				emptyq6 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 19,
				},
				question7 = {
					order = 20,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r Where are the Stances? I don't see/find them!",
				},
				answer7 = {
					order = 21,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r Use Keybindings! You can also put your Stances from the Spellbook into on of your Bartender Bars.\ Or type /bt and enable/position the original BT StanceBar.",
				},
				emptyq7 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 22,
				},
				question8 = {
					order = 23,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r Do i have to use all your Addons? I don't like some of them!",
				},
				answer8 = {
					order = 24,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r You can replace EVERY Addon. Its your choice! Make sure you update your Frame Anchors and Sidebar Anchors after changing your Addons.",
				},
				emptyq30 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 40,
				},
				emptyq31 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 41,
				},
				faqfooter = {
					order = 42,
					width = "full",
					type = "description",
					name = "For all other Questions, Problems or Wishes regarding LUI v3\nplease visit |cff8080ffhttp://www.wow-lui.com|r\n\nThanks!",
				}
			}
		}
	}

	return options
end

function module:OnInitialize()
	LUI:RegisterOptions(self)
end

function module:OnEnable()
end

function module:OnDisable()
end
