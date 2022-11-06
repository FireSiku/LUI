-- ####################################################################################################################
-- ##### SharedMedia Library Functions ################################################################################
-- ####################################################################################################################
---@meta

---[Documentation](https://www.wowace.com/projects/libsharedmedia-3-0/pages/api-documentation)
---@class LibSharedMedia-3.0
local LibSharedMedia = {}

LibSharedMedia.LOCALE_BIT_koKR = 1
LibSharedMedia.LOCALE_BIT_ruRU = 2
LibSharedMedia.LOCALE_BIT_zhCN = 4
LibSharedMedia.LOCALE_BIT_zhTW = 8
LibSharedMedia.LOCALE_BIT_western = 128

LibSharedMedia.MediaType = {
	BACKGROUND = "background",
	BORDER = "border",
	FONT = "font",
	STATUSBAR = "statusbar",
	SOUND = "sound",
}

--- Registers a new handle of given type.
---@param mediatype string
---@param key string
---@param data string
---@param langmask? number @ bitmask - only for mediatype 'font'; bits should be set if the font supports that locale (see below)
---@return boolean success @ false if data for the given mediatype-key pair already exists
function LibSharedMedia:Register(mediatype, key, data, langmask) end

--- Fetches the data for the given handle and type.
---@param mediatype string
---@param key string
---@param noDefault? boolean @  if true, `nil` will be returned instead of the default handle's data
---@return string? @ the requested handle's data if it exists, otherwise the default handle's data or nil
function LibSharedMedia:Fetch(mediatype, key, noDefault) end

--- Checks if the given type (and handle) is valid.
---@param mediatype string
---@param key? string
---@return boolean
function LibSharedMedia:IsValid(mediatype, key) end

--- Gets a hash table {data -> handle} to eg. iterate over.
---@param mediatype string
---@return table<string, string>
function LibSharedMedia:HashTable(mediatype) end

--- Gets a sorted list of handles.
---@param mediatype string
---@return string[]
function LibSharedMedia:List(mediatype) end

--- Returns the prior set override handle.
---@param mediatype string
---@return string?
function LibSharedMedia:GetGlobal(mediatype) end

--- Sets or clears a handle that will be returned on fetch instead of the requested handle
---@param mediatype string
---@param key? string
function LibSharedMedia:SetGlobal(mediatype, key) end

--- Returns the default return value for nonexistant handles.
---@param mediatype string
---@return string?
function LibSharedMedia:GetDefault(mediatype) end

--- Sets a default return value for nonexistant handles. Won't replace an already set default.
---@param type string
---@param handle string
function LibSharedMedia:SetDefault(type, handle) end