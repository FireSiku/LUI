--- Modules api contains all the generic embeddable api that modules can use to easily acess or do stuff.
-- @classmod ModuleMixin

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
-- Addon building reference.

---@type string, LUIAddon
local _, LUI = ...
local Media = LibStub("LibSharedMedia-3.0")

--local copies
local pairs = pairs

---@class LUIModule : AceEvent-3.0
local ModuleMixin = {}

--- Embed the ModuleMixin into target object.  
--- Note: This is done automatically for modules created with :NewModule()
function LUI:EmbedModule(target)
	for k, v in pairs(ModuleMixin) do
		target[k] = v
	end
end

-- ####################################################################################################################
-- ##### Module Mixin #################################################################################################
-- ####################################################################################################################

--- Fetch a color and return the r, g, b value
---@param colorName string @ check module db first, then color module.
---@return number R, number G, number B
function ModuleMixin:RGB(colorName)
	--  TODO: Fix the issue with RGB colors as RGBA colors in the options
	local db = self:GetDB("Colors")
	if db and db[colorName] then
		-- TODO: Check for all planned types (.t)
		if db[colorName].t and db[colorName].t == "Class" then
			return LUI:GetClassColor(LUI.playerClass)
		else
			local color = db[colorName]
			return color.r, color.g, color.b
		end
	end
	return LUI:GetFallbackRGB(colorName)
end

--- Fetch a color and return the r, g, b, a values.
---@param colorName string @ check module db first, then color module.
---@return number R, number G, number B
function ModuleMixin:RGBA(colorName)
	local db = self:GetDB("Colors")

	if db and db[colorName] then
		-- TODO: Check for all planned types (.t)
		if db[colorName].t and db[colorName].t == "Class" then
			local r, g, b = LUI:GetClassColor(LUI.playerClass)
			return r, g, b, db[colorName].a or 1
		else
			local color = db[colorName]
			return color.r, color.g, color.b, color.a or 1
		end
	end

	local r, g, b = LUI:GetFallbackRGB(colorName)
	if r and g and b then
		return r, g, b, 1
	end
end

--- Fetch a color and creates a Blizzard Color with it.
---@param colorName string @ check module db first, then color module.
---@return ColorMixin
function ModuleMixin:Color(colorName)
	local r, g, b, a = self:RGBA(colorName)
	if r and g and b then
		return CreateColor(r, g, b, a)
	end
end

--- Fetch a color and wrap text with its color code.
---@param text string
---@param colorName string @ check module db first, then color module.
---@return string coloredText
function ModuleMixin:ColorText(text, colorName)
	local color = self:Color(colorName)
	if color then
		return color:WrapTextInColorCode(text)
	end
	return text
end

--- Wrapper around SharedMedia's `:Fetch("statusbar")`
---@param name string
function ModuleMixin:FetchStatusBar(name)
	local db = self:GetDB("StatusBars")
	if db and db[name] then
		return Media:Fetch("statusbar", db[name])
	elseif self.db.profile[name] then
		return Media:Fetch("statusbar", self.db.profile[name])
	end
end

--- Wrapper around SharedMedia's `:Fetch("border")`
---@param name string
function ModuleMixin:FetchBorder(name)
	local db = self:GetDB("Borders")
	if db and db[name] then
		return Media:Fetch("border", db[name])
	elseif self.db.profile[name] then
		return Media:Fetch("border", self.db.profile[name])
	end
end

--- Wrapper around SharedMedia's `:Fetch("background")`
---@param name string
function ModuleMixin:FetchBackground(name)
	local db = self:GetDB("Backgrounds")
	if db and db[name] then
		return Media:Fetch("background", db[name])
	elseif self.db.profile[name] then
		return Media:Fetch("background", self.db.profile[name])
	end
end

--- Function that creates a backdrop table for use with SetBackdrop and keeps a copy around based on name.
---- When function is called on an existing backdrop, update it and return it.
---- If Tile or Insets options aren't found in the DB, they can be optionally be set through parameters.
---- Requires a DB.Backdrop entry based on name.
---@param name string
---@param tile boolean @ True = Tile, False = Stretch
---@param tileSize number @ Size of each tiled copy of bgFile
---@param l number @ How far from the edge bg is drawn. (Higher = Thicker)
---@param r number @ How far from the edge bg is drawn. (Higher = Thicker)
---@param t number @ How far from the edge bg is drawn. (Higher = Thicker)
---@param b number @ How far from the edge bg is drawn. (Higher = Thicker)
---@return BackdropTable
function ModuleMixin:FetchBackdrop(name, tile, tileSize, l, r, t, b)
	local db = self:GetDB("Backdrop")
	if db and db[name] then
		local backdrop
		-- Check if backdrop exists, if not create it.
		if not self.__backdrops[name] then
			backdrop = {}
			backdrop.insets = {}
			self.__backdrops[name] = backdrop
		else
			backdrop = self.__backdrops[name]
		end
		--Make sure the values are up to date.
		backdrop.bgFile = Media:Fetch("background", db[name].Background)
		backdrop.edgeFile = Media:Fetch("border", db[name].Border)
		backdrop.edgeSize = db[name].Size
		if db[name].Tile or tile then backdrop.tile = db[name].Tile or tile end
		if db[name].TileSize or tileSize then backdrop.tileSize = db[name].TileSize or tileSize end
		if db[name].Left or l then
			backdrop.insets.left = db[name].Left or l
			backdrop.insets.right = db[name].Right or r
			backdrop.insets.top = db[name].Top or t
			backdrop.insets.bottom = db[name].Bottom or b
		end

		return backdrop
	end
end

--- Function that fetch and set Backdrop, along with setting color and border color.
---@param name string @ Name of the backdrop to fetch
---@param frame Frame
function ModuleMixin:UpdateFrameBackdrop(name, frame, ...)
	self:FetchBackdrop()
	local backdrop = self:FetchBackdrop(name, ...)

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(self:RGB(name.."BG"))
	frame:SetBackDropBorderColor(self:RGB(name.."Border"))
end

--- Quickly Setup a FontString widget
---@param frame Frame
---@param name string
---@param mFont FontName
---@param layer FrameLayer|nil @ Layer font should be drawn in. Defaults to ARTWORK
---@param hJustify boolean|nil
---@param vJustify boolean|nil
---@return FontString
function ModuleMixin:SetFontString(frame, name, mFont, layer, hJustify, vJustify)
	local fs = frame:CreateFontString(name, layer)
	local db = self:GetDB("Fonts")
	local font = db[mFont]
	fs:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
	if hJustify then fs:SetJustifyH(hJustify) end
	if vJustify then fs:SetJustifyV(vJustify) end
	return fs
end

--- Reapply the font settings of a FontString based on the given font name.
---@param fs FontString
---@param mFont string @ Name of the entry to search in `module.db.Fonts`
function ModuleMixin:RefreshFontString(fs, mFont)
	local db = self:GetDB("Fonts")
	local font = db[mFont]
	fs:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
	fs:SetTextColor(self:RGB(mFont))
end

--- Returns the profile database table.
---@param subTable string? @ Return the requested subtable if found. Otherwise return the module's db.
---@return AceDB-3.0
function ModuleMixin:GetDB(subTable)
	local db
	if self.db then
		db = self.db.profile
	end
	if db and subTable and type(db[subTable] == "table") then
		return db[subTable]
	end
	return db
end

--- Returns a database scope table. Defaults to profile.
---@param scope? DBScope
---@return AceDB-3.0
function ModuleMixin:GetDBScope(scope)
	scope = scope or "profile"
	if self.db then
		return self.db[scope]
	end
end

--- Print exclusively for Module Messages.
--- Those prints will not appear if ModuleMessages is disabled
function ModuleMixin:ModPrint(...)
	if LUI.db.profile.General.ModuleMessages then
		LUI:Print(self:GetName()..":", ...)
	end
end

--- Toggle a module's enabled state.
function ModuleMixin:VToggle()
	local name = self:GetName()
	local state = not self:IsEnabled()
	if state then
		LUI:EnableModule(name)
	else
		LUI:DisableModule(name)
	end
	LUI.db.profile.Modules[name] = state
end

--- Merge given table into module.defaults if it exists. Support all AceDB types
---@param source table
---@param name string
function ModuleMixin:MergeDefaults(source, name)
	if not self.defaults then self.defaults = {} end
	for i, scope in ipairs(LUI.DB_TYPES) do
		if source[scope] then
			if not self.defaults[scope] then self.defaults[scope] = {} end
			if name then
				self.defaults[scope][name] = LUI:CopyTable(source[scope], self.defaults[scope][name])
			else
				self.defaults[scope] = LUI:CopyTable(source[scope], self.defaults[scope])
			end
		end
	end
end

--- Since we arent doing any closure shenanigans using OnModuleCreated anymore, this accomplish the same in a much better way.
LUI:SetDefaultModulePrototype(ModuleMixin)
