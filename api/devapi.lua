--[[
	Name........: DevAPI
	Description.: Compatibility helpers for legacy LUI modules
]]

local MAJOR, MINOR = "LUIDevAPI", 3
local devapi = LibStub:NewLibrary(MAJOR, MINOR)

if not devapi then return end

devapi.embeds = devapi.embeds or {}

local type, pairs, unpack = type, pairs, unpack

function devapi:Toggle(state)
	if state == nil then
		state = not self:IsEnabled()
	end

	local success = self[state and "Enable" or "Disable"](self)

	if self.db.parent then
		self.db.parent.profile.modules[self:GetName()] = self:IsEnabled()
	end

	return success
end

function devapi:GetDBVar(info)
	local value = self.db.profile
	local start = self.isNestedModule and 3 or 2

	for i = start, #info - 1 do
		value = value[info[i]]
		if type(value) ~= "table" then
			error("Error accessing db\nCould not access " .. strjoin(".", info[start - 1], "db.profile", unpack(info, start, value == nil and i or i + 1)) .. "\ndb layout must be the same as info", 2)
		end
	end

	return value[info[#info]]
end

function devapi:SetDBVar(info, value)
	local db = self.db.profile
	local start = self.isNestedModule and 3 or 2

	for i = start, #info - 1 do
		db = db[info[i]]
		if type(db) ~= "table" then
			error("Error accessing db\nCould not access " .. strjoin(".", info[start - 1], "db.profile", unpack(info, start, db == nil and i or i + 1)) .. "\ndb layout must be the same as info", 2)
		end
	end

	db[info[#info]] = value
end

local mixins = {
	"Toggle",
	"GetDBVar",
	"SetDBVar",
}

function devapi:Embed(target)
	for _, method in pairs(mixins) do
		target[method] = self[method]
	end

	self.embeds[target] = true
	return target
end

for target in pairs(devapi.embeds) do
	devapi:Embed(target)
end
