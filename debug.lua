--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: DEBUG.lua
	Description: Debugger for LUI
	Version....: 0.1
	Rev Date...: 14/08/11
]]

local addonname, LUI = ...

local version, revision = GetAddOnMetadata(addonname, "Version"), GetAddOnMetadata(addonname, "X-Curse-Packaged-Version")
LUI.DEBUG = version ~= revision
-- LUI.DEBUG = true -- for debugging with core releases

--------------------------------------------------
-- / Localized API / --
--------------------------------------------------

local pairs, type, tostring, tinsert, rawget, error, floor = pairs, type, tostring, tinsert, rawget, error, floor

--------------------------------------------------
-- / Local Functions / --
--------------------------------------------------

local function is_list(t)
	local n = #t
	
	for k in pairs(t) do
		if type(k) ~= "number" or k < 1 or k > n or floor(k) ~= k then
			return false
		end
	end
	return true
end

local function simple_pretty_tostring(value)
	if type(value) == "string" then
		return ("%q"):format(value)
	else
		return tostring(value)
	end
end

local function pretty_tostring(value)
	if type(value) ~= "table" then
		return simple_pretty_tostring(value)
	end
	
	local t = {}
	if is_list(value) then
		for _, v in ipairs(value) do
			tinsert(t, simple_pretty_tostring(v))
		end
	else
		for k, v in pairs(value) do
			tinsert(t, "[" .. simple_pretty_tostring(k) .. "] = " .. simple_pretty_tostring(v))
		end
	end
	return "{" .. table.concat(t, ", ") .. "}"
end

local function helper(alpha, ...)
	for i=1, select("#", ...) do
		if alpha == select(i, ...) then
			return true
		end
	end
	return false
end

--------------------------------------------------
-- / Debug Conditions / --
--------------------------------------------------

local conditions = {}
conditions["isin"] = function(alpha, bravo, depth)
	if type(bravo) == "table" then
		return bravo[alpha] ~= nil
	elseif type(bravo) == "string" then
		return helper(alpha, (";"):split(bravo))
	else
		error(("Bad argument #3 to 'argcheck'. Expected %q or %q, got %q"):format("table", "string", type(bravo)), depth or 3)
	end
end
conditions["typeof"] = function(alpha, bravo)
	local type_alpha = type(alpha)
	if type_alpha == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsObjectType) == "function" then
		type_alpha = "frame"
	end
	
	return conditions["isin"](type_alpha, bravo, 4)
end
conditions["frametype"] = function(alpha, bravo)
	if type(bravo) ~= "string" then
		error(("Bad argument #3 to 'argcheck'. Expected %q, got %q"):format("string", type(bravo)), 3)
	end
	return type(alpha) == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsOpjectType) == "function" and alpha:IsObjectType(bravo)
end
conditions['match'] = function(alpha, bravo)
	if type(alpha) ~= "string" then
		error(("Bad argument #1 to 'argcheck'. Expected %q, got %q"):format("string", type(alpha)), 3)
	end
	if type(bravo) ~= "string" then
		error(("Bad argument #3 to argcheck'. Expected %q, got %q"):format("string", type(bravo)), 3)
	end
	return alpha:match(bravo)
end
conditions['=='] = function(alpha, bravo)
	return alpha == bravo
end
conditions['~='] = function(alpha, bravo)
	return alpha ~= bravo
end
conditions['>'] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha > bravo
end
conditions['>='] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha >= bravo
end
conditions['<'] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha < bravo
end
conditions['<='] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha <= bravo
end

for cond, func in pairs(conditions) do
	conditions["not_"..cond] = function(...)
		return not func(...)
	end
end

--------------------------------------------------
-- / Debug Functions / --
--------------------------------------------------

LUI.argcheck = function(alpha, condition, bravo)
	if not LUI.DEBUG then return end
	
	if not conditions[condition] then
		error(("Unknown condition: '%s'"):format(pretty_tostring(condition)), 2)
	end
	if not conditions[condition](alpha, bravo) then
		error(("Argcheck failed: %s %s %s"):format(pretty_tostring(alpha), condition, pretty_tostring(bravo)), 2)
	end
end

function LUI:Debug()
	self.DEBUG = not self.DEBUG
	self:Print("Debugging "..(self.DEBUG and "enabled" or "disabled"))
end
