-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Chat, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Chat")
if not module or not module.registered then return end

local modStickyChannels = module:GetModule("StickyChannels")
local modEditbox = module:GetModule("EditBox")
local modButtons = module:GetModule("Buttons")

local Chat = Opt:CreateModuleOptions("Chat", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################
local function resetChatPos()
	local dbd = module.defaults.profile
	db.x = dbd.x
	db.y = dbd.y
	db.point = dbd.point
	db.width = dbd.width
	db.height = dbd.height

	positionChatFrame()
end

local anchorPoints = {
	TOP = L["Top"],
	BOTTOM = L["Bottom"],
	FREE = L["Free-floating"],
	LOCK = L["Free-floating (Locked)"],
}

local function buttonsDisabled() return not db.HideButtons end
local function scrollButtonDisabled() return not db.HideButtons and not db.ScrollReminder end
local function copyButtonDisabled() return not db.CopyChat end
local function tileDisabled() return not modEditbox.db.profile.Background.Tile end
local function StickyChannelsDisabled() return not modStickyChannels.db.profile.Enabled end

local chans = db.Channels

local function GenerateStickySettings()
	local channelList = modStickyChannels.channels
	local channelSettings = {}
	for name, t in pairs(channelList) do
		channelSettings[name] =  Opt:Toggle({name = channelList[name].desc, desc = "Enable sticky flag for " .. channelList[name].desc})
	end
	return Opt:Group({name = "StickyChannels", db = modStickyChannels.db.profile, args = {
		Enabled = Opt:Toggle({name = "Enable Sticky Channels"}),
		Channels = Opt:InlineGroup({name = "Sticky Channels", disabled = StickyChannelsDisabled, db = modStickyChannels.db.profile.Channels, args = channelSettings}),
	}})
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

Chat.args = {
    -- General
    Header = Opt:Header({name = L["Chat"]}),
	General = Opt:Group({name = L["General Settings"], db = db.General, args = {
		Font = Opt:Group({name = L["Font"], db = db.General.Font, args = {
			Font = Opt:MediaFont({name = L["Font"], desc = L["Choose a font"]}),
			Flag = Opt:Select({name = L["Flag"], desc = L["Choose a font flag"], values = LUI.FontFlags}),
			Size = Opt:Slider({name = L["Size"], desc = L["Choose a fontsize"], min = 6, max = 20, step = 1, width = "full"}),
		}}),
		ShortChannelNames = Opt:Toggle({name = L["Short channel names"], desc = L["Use abreviated channel names"]}),
		DisableFading = Opt:Toggle({name = L["Disable fading"], desc = L["Stop the chat from fading out over time"]}),
		MinimalistTabs = Opt:Toggle({name = L["Minimalist tabs"], desc = L["Use minimalist style tabs"]}),
		LinkHover = Opt:Toggle({name = L["Link hover tooltip"], desc = L["Show tooltip when mousing over links in chat"]}),
		ShiftMouseScroll = Opt:Toggle({name = L["Shift mouse scrolling"], desc = L["Holding shift while mouse scrolling will jump to top or bottom"]}),
		BackgroundColor = Opt:Color({name = L["Chat Background"], width = "full"}),
		ResetPosition = Opt:Execute({name = L["Reset position"], desc = L["Reset the main chat dock's position"], func = resetChatPos, confirm = L["Are you sure?"]}),
	}}),

	EditBox = Opt:Group({name = L["EditBox"], db = modEditbox.db.profile, args = {
		Font = Opt:InlineGroup({name = L["Font"], db = modEditbox.db.profile.Font, args = {
			Font = Opt:MediaFont({name = L["Font"], desc = L["Choose a font"]}),
			Flag = Opt:Select({name = L["Flag"], desc = L["Choose a font flag"], values = LUI.FontFlags}),
			Size = Opt:Slider({name = L["Size"], desc = L["Choose a fontsize"], min = 6, max = 20, step = 1, width = "full"}),
		}}),
		Anchor = Opt:Select({name = L["Anchor Point"], desc = L["Select where the EditBox anchors to the ChatFrame"], values = anchorPoints}),
		UseAlt = Opt:Toggle({name = L["Use Alt key"], desc = L["Requires the Alt key to be held down to move the cursor"]}),
		History = Opt:Toggle({name = L["Remember history"], desc = L["Remembers the history of the EditBox across sessions"]}),
		ColorByChannel = Opt:Toggle({name = L["Color by channel"], desc = L["Sets the EditBox color to the color of your currently active channel"]}),
		Height = Opt:Slider({name = L["Height"], desc = L["Adjust the height of the EditBox"], min = 5, max = 50, step = 1, width = "full"}),
		
		Background = Opt:InlineGroup({name = L["Background"], db = modEditbox.db.profile.Background, args = {
			Texture = Opt:MediaBackground({name = L["Texture"], desc = L["Choose a texture"]}),
			empty = Opt:Spacer({}),
			Tile = Opt:Toggle({name = L["Tile"], desc = L["Should the background texture be tiled over the area"]}),
			TileSize = Opt:Slider({name = L["Tile Size"], desc = L["Adjust the size of each tile of the background texture"], min = 1, max = 200, step = 1, disabled = tileDisabled}),
			Insets = Opt:Group({name = L["Insets"], db = modEditbox.db.profile.Background.Insets, args = {
				top = Opt:InputNumber({name = L["Top"], desc = L["Adjust the top inset of the background"], width = "half"}),
				bottom = Opt:InputNumber({name = L["Bottom"], desc = L["Adjust the bottom inset of the background"], width = "half"}),
				left = Opt:InputNumber({name = L["Left"], desc = L["Adjust the left inset of the background"], width = "half"}),
				right = Opt:InputNumber({name = L["Right"], desc = L["Adjust the right inset of the background"], width = "half"}),
			}}),
		}}),

		Border = Opt:InlineGroup({name = L["Border"], db = modEditbox.db.profile.Border, args = {
			Texture = Opt:MediaBorder({name = L["Texture"], desc = L["Choose a texture"]}),
			Thickness = Opt:Slider({name = L["Thickness"], desc = L["Adjust the thickness of the border"], min = 1, max = 20, step = 1}),
		}}),
	}}),

	Buttons = Opt:Group({name = L["Buttons"], db = modButtons.db.profile, args = {
		HideButtons = Opt:Toggle({name = L["Hide Buttons"]}),
		ScrollReminder = Opt:Toggle({name = L["Scroll to bottom button"], desc = L["Show scroll to bottom button when scrolled up"], disabled = buttonsDisabled}),
		ScrollScale = Opt:Slider({name = L["Scale"], desc = L["Scale of the scroll to bottom button"], min = 0.5, max = 2, step = 0.05, isPercent = true, disabled = scrollButtonDisabled}),
		CopyChat = Opt:Toggle({name = L["Copy chat button"], desc = L["Show copy chat button"]}),
		CopyScale = Opt:Slider({name = L["Scale"], desc = L["Scale of the copy chat button"], min = 0.5, max = 2, step = 0.05, isPercent = true, disabled = copyButtonDisabled}),
	}}),

	StickyChannels = GenerateStickySettings(),
}
