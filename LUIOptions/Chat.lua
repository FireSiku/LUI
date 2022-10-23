-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Chat")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Chat = Opt:Group("Chat", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Chat.handler = module

local Chat = {
    -- General
    Header = Opt:Header(L["Chat"], 1),
	General = Opt:Group("General Settings", nil, 2, nil, nil, nil, Opt.GetSet(db.General)),
	NameText = Opt:Group("Name Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Name)),
	Colors = Opt:Group("Bar Colors", nil, 4, nil, nil, nil, Opt.GetSet(db.Colors)),
}

local GeneralTab = {
	Width = Opt:InputNumber("Width", "Choose the Width for the Chat.", 1),
	Height = Opt:InputNumber("Height", "Choose the Height for the Chat.", 2),
	empty1 = Opt:Desc(" ", 3),
	X = Opt:InputNumber("X Value", "Choose the X Value for the Chat.", 4),
	Y = Opt:InputNumber("Y Value", "Choose the Y Value for the Chat.", 5),
	empty2 = Opt:Desc(" ", 6),
	Texture = Opt:MediaStatusbar("Texture", "Choose the Chat Texture.", 7),
	TextureBG = Opt:MediaStatusbar("Background Texture", "Choose the Chat Background Texture.", 8),
	BarGap = Opt:Slider("Spacing", "Select the Spacing between mirror bars when shown.", 9, {min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 10, nil, "full"),
}

local ColorTab = {
	FatigueBar = Opt:Color("Fatigue Bar", "Fatigue Bar", 1),
	BreathBar = Opt:Color("Breath Bar", "Breath Bar", 2),
	FeignBar = Opt:Color("Feign Death Bar", "Feign Death Bar", 3),
	Bar = Opt:Color("Other Bar", "Other Chats", 4),
	ArchyBar = Opt:Color("Archaeology Progress Bar", "Archaeology Progress Bar", 5),
	Background = Opt:Color("Background", "Chat Background", 6),
}

local NameText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Name Text.", 2),
	Color = Opt:Color("Name", "Mirror Name", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Name)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Name Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7),
}

Opt.options.args.Chat.args = Chat

--- Link the groups together.
Chat.General.args = GeneralTab
Chat.Colors.args = ColorTab
Chat.NameText.args = NameText

-- ####################################################################################################################
-- ##### Old Options ###############################################################################################
-- ####################################################################################################################
--[[ 
	
function module:LoadOptions()
	local function refresh()
		self:Refresh()
	end
	local function resetChatPos()
		db.x = dbd.x
		db.y = dbd.y
		db.point = dbd.point
		db.width = dbd.width
		db.height = dbd.height

		positionChatFrame()
	end

	local options = {
		General = self:NewGroup(L["General Settings"], 1, {
			Font = self:NewGroup(L["Font"], 1, true, {
				Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
				Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
				Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 6, 20, 1, true, false, "full")
			}),
			ShortChannelNames = self:NewToggle(L["Short channel names"], L["Use abreviated channel names"], 2, true),
			DisableFading = self:NewToggle(L["Disable fading"], L["Stop the chat from fading out over time"], 3, true),
			MinimalistTabs = self:NewToggle(L["Minimalist tabs"], L["Use minimalist style tabs"], 4, true),
			LinkHover = self:NewToggle(L["Link hover tooltip"], L["Show tooltip when mousing over links in chat"], 5, true),
			ShiftMouseScroll = self:NewToggle(L["Shift mouse scrolling"], L["Holding shift while mouse scrolling will jump to top or bottom"], 6, refresh),
			BackgroundColor = self:NewColor(L["Chat Background"], nil, 7, refresh, "full"),
			ResetPosition = self:NewExecute(L["Reset position"], L["Reset the main chat dock's position"], 8, resetChatPos, L["Are you sure?"]),
		}),
		StickyChannels = module:GetModule("StickyChannels"):LoadOptions(),
		EditBox = module:GetModule("EditBox"):LoadOptions(),
		Buttons = module:GetModule("Buttons"):LoadOptions(),
	}

	return options
end

BUTTONS

function module:LoadOptions()
	local function buttonsDisabled()
		return not db.HideButtons
	end
	local function scrollButtonDisabled()
		return not db.HideButtons and not db.ScrollReminder
	end
	local function copyButtonDisabled()
		return not db.CopyChat
	end

	local options = self:NewGroup(L["Buttons"], 3, "generic", "Refresh", {
		HideButtons = self:NewToggle(L["Hide Buttons"], nil, 1, true),
		ScrollReminder = self:NewToggle(L["Scroll to bottom button"], L["Show scroll to bottom button when scrolled up"], 2, true, "normal", buttonsDisabled),
		ScrollScale = self:NewSlider(L["Scale"], L["Scale of the scroll to bottom button"], 3, 0.5, 2, 0.05, true, true, nil, scrollButtonDisabled),
		CopyChat = self:NewToggle(L["Copy chat button"], L["Show copy chat button"], 4, true, "normal"),
		CopyScale = self:NewSlider(L["Scale"], L["Scale of the copy chat button"], 5, 0.5, 2, 0.05, true, true, nil, copyButtonDisabled),
	})

	return options
end

EDITBOX

function module:LoadOptions()
	local anchorPoints = {
		TOP = L["Top"],
		BOTTOM = L["Bottom"],
		FREE = L["Free-floating"],
		LOCK = L["Free-floating (Locked)"],
	}

	local refresh = function()
		self:Refresh()
	end

	local tileDisabled = function()
		return not db.Background.Tile
	end

	local options = self:NewGroup(L["EditBox"], 2, "generic", "Refresh", {
		Font = self:NewGroup(L["Font"], 1, true, {
			Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
			Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
			Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 6, 20, 1, true, false, "full")
		}),
		Anchor = self:NewSelect(L["Anchor Point"], L["Select where the EditBox anchors to the ChatFrame"], 2, anchorPoints, false, refresh),
		UseAlt = self:NewToggle(L["Use Alt key"], L["Requires the Alt key to be held down to move the cursor"], 3, true, "normal"),
		History = self:NewToggle(L["Remember history"], L["Remembers the history of the EditBox across sessions"], 4, true, "normal"),
		ColorByChannel = self:NewToggle(L["Color by channel"], L["Sets the EditBox color to the color of your currently active channel"], 5, true, "normal"),
		Height = self:NewSlider(L["Height"], L["Adjust the height of the EditBox"], 6, 5, 50, 1, true, false, "full"),
		Background = self:NewGroup(L["Background"], 7, true, {
			Texture = self:NewSelect(L["Texture"], L["Choose a texture"], 1, true, "LSM30_Background", refresh),
			empty = self:NewDesc("", 1.5, "normal"),
			Tile = self:NewToggle(L["Tile"], L["Should the background texture be tiled over the area"], 2, true, "normal"),
			TileSize = self:NewSlider(L["Tile Size"], L["Adjust the size of each tile of the background texture"], 3, 1, 200, 1, true, false, nil, tileDisabled),
			Insets = self:NewGroup(L["Insets"], 4, true, {
				top = self:NewInputNumber(L["Top"], L["Adjust the top inset of the background"], 1, refresh, "half"),
				bottom = self:NewInputNumber(L["Bottom"], L["Adjust the bottom inset of the background"], 2, refresh, "half"),
				left = self:NewInputNumber(L["Left"], L["Adjust the left inset of the background"], 3, refresh, "half"),
				right = self:NewInputNumber(L["Right"], L["Adjust the right inset of the background"], 4, refresh, "half"),
			}),
		}),
		Border = self:NewGroup(L["Border"], 8, true, {
			Texture = self:NewSelect(L["Texture"], L["Choose a texture"], 1, true, "LSM30_Border", refresh),
			Thickness = self:NewSlider(L["Thickness"], L["Adjust the thickness of the border"], 2, 1, 20, 1, refresh),
		}),
	})

	return options
end

STICKY

function module:LoadOptions()
	local chans = db.Channels
	local funcs = {
		Enabled = function() return not db.Enabled end
	}
	local nextOrder = 1
	local options = self:NewGroup("StickyChannels", 4, "generic", "Refresh", {
		Enabled = self:NewToggle("Enable Sticky Channels", nil, 1, true),
		Channels = self:NewGroup("Sticky Channels", 2, true, funcs.Enabled, {}),
	})
	for k, v in pairs(chans) do
		options.args.Channels.args[k] = self:NewToggle(channels[k].desc, "Enable sticky flag for " .. channels[k].desc, nextOrder, true, "normal")
		nextOrder = nextOrder + 1
	end

	return options
end
]]