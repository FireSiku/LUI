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
local buttonDB = modButtons.db.profile

local Chat = Opt:CreateModuleOptions("Chat", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################
local anchorPoints = {
	TOP = L["Top"],
	BOTTOM = L["Bottom"],
	FREE = L["Free-floating"],
	LOCK = L["Free-floating (Locked)"],
}

local function buttonsDisabled() return not buttonDB.HideButtons end
local function scrollButtonDisabled() return not buttonDB.HideButtons or not buttonDB.ScrollReminder end
local function copyButtonDisabled() return not buttonDB.CopyChat end
local function tileDisabled() return not modEditbox.db.profile.Background.Tile end
local function StickyChannelsDisabled() return not modStickyChannels.db.profile.Enabled end

local function GenerateStickySettings()
	local channelList = modStickyChannels.channels
	local channelSettings = {}
	for name, t in pairs(channelList) do
		channelSettings[name] = Opt:Toggle({name = channelList[name].desc, desc = "Keep " .. channelList[name].desc .. " selected after sending a message."})
	end
	return Opt:Group({name = "Sticky Channels", db = modStickyChannels.db.profile, args = {
		Description = Opt:Desc({name = "A sticky channel remains your active chat type after you send a message. For example, Guild stays selected instead of returning to Say."}),
		Enabled = Opt:Toggle({name = "Enable Sticky Channels", desc = "Apply the channel choices below."}),
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
			Flag = Opt:Select({name = L["Flag"], desc = "Add an outline effect. Thick Outline intentionally makes letters look much heavier; choose None for the font's normal weight.", values = LUI.FontFlags}),
			Size = Opt:Slider({name = L["Size"], desc = L["Choose a fontsize"], min = 6, max = 20, step = 1, width = "full"}),
		}}),
		ShortChannelNames = Opt:Toggle({name = L["Short channel names"], desc = "Abbreviate chat prefixes such as Guild, Party, Raid, and numbered public channels."}),
		DisableFading = Opt:Toggle({name = "Disable message fading", desc = "Keep chat messages visible instead of fading them out over time."}),
		DisableTabFading = Opt:Toggle({name = "Disable chat-tab fading", desc = "Keep chat-tab labels at their normal visible alpha when the mouse leaves the chat window."}),
		MinimalistTabs = Opt:Toggle({name = L["Minimalist tabs"], desc = L["Use minimalist style tabs"]}),
		LinkHover = Opt:Toggle({name = L["Link hover tooltip"], desc = L["Show tooltip when mousing over links in chat"]}),
		ShiftMouseScroll = Opt:Toggle({name = L["Shift mouse scrolling"], desc = L["Holding shift while mouse scrolling will jump to top or bottom"]}),
	}}),

	EditBox = Opt:Group({name = "Chat Input Box", db = modEditbox.db.profile, args = {
		Font = Opt:InlineGroup({name = L["Font"], db = modEditbox.db.profile.Font, args = {
			Font = Opt:MediaFont({name = L["Font"], desc = L["Choose a font"]}),
			Flag = Opt:Select({name = L["Flag"], desc = "Add an outline effect. Thick Outline intentionally makes letters look much heavier; choose None for the font's normal weight.", values = LUI.FontFlags}),
			Size = Opt:Slider({name = L["Size"], desc = L["Choose a fontsize"], min = 6, max = 20, step = 1, width = "full"}),
		}}),
		Anchor = Opt:Select({name = L["Anchor Point"], desc = L["Select where the EditBox anchors to the ChatFrame"], values = anchorPoints}),
		UseAlt = Opt:Toggle({name = L["Use Alt key"], desc = L["Requires the Alt key to be held down to move the cursor"]}),
		History = Opt:Toggle({name = L["Remember history"], desc = L["Remembers the history of the EditBox across sessions"]}),
		ColorByChannel = Opt:Toggle({name = L["Color by channel"], desc = "Color the input-box background and border with the active Say, Guild, Party, Raid, Whisper, or numbered-channel color. These colors come from Blizzard's chat settings; the Background color below only supplies the opacity and fallback color."}),
		Height = Opt:Slider({name = L["Height"], desc = L["Adjust the height of the EditBox"], min = 5, max = 50, step = 1, width = "full"}),
		
		Background = Opt:InlineGroup({name = L["Background"], db = modEditbox.db.profile.Background, args = {
			Color = Opt:Color({name = "Color", hasAlpha = true, db = modEditbox.db.profile.Background}),
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

	Buttons = Opt:Group({name = L["Buttons"], db = buttonDB, args = {
		HideButtons = Opt:Toggle({name = L["Hide Buttons"], desc = "Hide Blizzard's chat menu, Quick Join, voice, and per-window button frames. The LUI copy button is controlled separately below."}),
		ScrollReminder = Opt:Toggle({name = L["Scroll to bottom button"], desc = L["Show scroll to bottom button when scrolled up"], disabled = buttonsDisabled}),
		ScrollScale = Opt:Slider({name = L["Scale"], desc = L["Scale of the scroll to bottom button"], min = 0.5, max = 2, step = 0.05, isPercent = true, disabled = scrollButtonDisabled}),
		CopyChat = Opt:Toggle({name = L["Copy chat button"], desc = "Show or hide LUI's copy-chat button independently of Blizzard's chat buttons."}),
		CopyScale = Opt:Slider({name = L["Scale"], desc = L["Scale of the copy chat button"], min = 0.5, max = 2, step = 0.05, isPercent = true, disabled = copyButtonDisabled}),
	}}),

	StickyChannels = GenerateStickySettings(),
}
