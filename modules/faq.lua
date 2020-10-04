--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: faq.lua
	Description: FAQ Options
	Version....: 1.0
	Rev Date...: 08/07/2010
	Author.....: Louí [EU - Das Syndikat] <In Fidem>
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("FAQ")

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
				question1 = {
					order = 2,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r How do I disable modules?",
				},
				answer1 = {
					order = 3,
					width = "full",
					type = "description",
					name = "|cff3399ffA:|r Click the \"Modules:\" section on the left to find an enable/disable button for each module.",
				},
				emptyq1 = {
					name = "   ",
					width = "full",
					type = "description",
					order = 4,
				},
				question6 = {
					order = 17,
					width = "full",
					type = "description",
					name = "|cffFF0000Q:|r Several Blizzard Frames and Fonts are too small and everything looks too tiny. What should i do?",
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
					name = "|cff3399ffA:|r Use Keybindings! You can also put your Stances from the Spellbook into on of your Bartender Bars.\n Or type /bt and enable/position the original BT StanceBar.",
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
					name = "For all other Questions, Problems or Wishes regarding LUI v3\nplease visit |cff8080ffhttp://www.wowlui.com|r\n\nThanks!",
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
