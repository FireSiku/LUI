--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: profiler.lua
	Description: Experimental profiler tools.
]]


-- External references.
local addonname, LUI = ...

-- Create profiler namespace.
LUI.Profiler = LUI.Profiler or {}
local module = LUI.Profiler

-- Localize functions.
local collectgarbage, error, GetTime, print, type = collectgarbage, error, GetTime, print, type

-- Local variables.
local KILLTIME = 2
local traces = {}
local excludes = {}

function module.Trace(func, name, scope)
	-- This should never happen, but just in case.
	if traces[func] then
		return traces[func].newFunc
	elseif excludes[func] then
		return func
	end
    
	-- Create trace.
	traces[func] = {
		oldFunc = func,
		newFunc = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15)
			local time
			local mem = collectgarbage("count")
			
			-- Check for recursion.
			if traces[func].recurse > 0 then
				-- Check this recursion loop hasn't been running excesively (n seconds).
				if GetTime() - traces[func].start > KILLTIME then
					-- Create an error to break recursion.
					error("|c0090ffffLUI:|r Profiler: Stopping recursive loop of "..traces[func].name.." after "..traces[func].recurse.." calls.")
				end

				-- Get time.
				time = GetTime()
			else
				-- Get time and log for recursion.
				time  = GetTime()
				traces[func].start = time
			end

			-- Increase recurse counter.
			traces[func].recurse = traces[func].recurse + 1
            
			-- Run and collect results.
			local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 = func(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, 15)

			-- Collect time and memory results.
			time = GetTime() - time
			mem = collectgarbage("count") - mem

			-- Check time to make sure function isn't a problem.
			if time > KILLTIME then
				-- Print error.
				traces[func].newFunc = function() error("|c0090ffffLUI:|r Profiler: This function has been disabled.", 2) end
				error("|c0090ffffLUI:|r Profiler: Stopping function call of "..traces[func].name.." after "..time.." seconds execution.")
			end

			-- Decrease recurse counter.
			traces[func].recurse = traces[func].recurse - 1
            
			-- Update stats.
			traces[func].total = traces[func].total + time
			traces[func].last = time
			traces[func].memT = traces[func].memT + mem
			traces[func].memL = mem
			traces[func].count = traces[func].count + 1
            
			return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
		end,

		start = 0,
		recurse = 0,
		count = 0,
		total = 0,
		last = 0,
		memT = 0,
		memL = 0,
		name = scope and scope.."."..name or name,
	}

	-- Add new function to excludes.
	excludes[traces[func].newFunc] = true

	-- Return new funcion.
	return traces[func].newFunc
end

-- For debug purposes.
function module.Print()
	print("Num traces:", #traces)
	for f, t in pairs(traces) do
		print(t.name, ":", count, ",", total, "s,", memT, "kb.")
	end
end

-- Prototype meta metatable.
local meta
function module.ApplyMetatable(table, name)
	-- Check excludes.
	if excludes[table] then return end

	-- Set metatable variables.
	rawset(table, "__nameP", name)
	rawset(table, "__oldP", getmetatable(table))

	-- Add old metatable to excludes.
	if table.__oldP then
		excludes[table.__oldP] = true
	end
		
	-- Set metatable.
	print("Settings metatable for", name)
	table = setmetatable(table, meta)

	-- Check metatable was set.
	if type(table) ~= "table" then return error("Metatable failed") end

	-- Scan for previously written functions and tables.
	local vType
	for k, v in pairs(table) do
		vType = type(v)
		if vType == "function" then
			-- Trace function.
			local newFunc = module.Trace(v, k, name)

			-- Pass new function to old metatable, or rawset.
			if table.__oldP and table.__oldP.__newindex then
				table.__oldP.__newindex(table, k, newFunc)
			else
				rawset(table, k, newFunc)
			end
		elseif vType == "table" then
			-- Apply metatable to child table.
			--module.ApplyMetatable(v, table.__nameP.."."..k)
		end
	end
end

-- Create metatable.
meta = {
	__index = function(self, k)
		-- Look up old metatbale if it exists.
		if self.__oldP then
			local __type = type(self.__oldP.__index)
			if __type == "function" then
				return self.__oldP.__index(self, k)
			elseif __type == "table" then
				return self.__oldP.__index[k]
			end
		end
	end,
	__newindex = function(self, k, v)
		local __type = type(v)
		-- Check if value is a function.
		if __type == "function" then
			-- Trace function.
			local newFunc = module.Trace(v, k, self.__nameP)

			-- Pass new function to old metatable, or rawset.
			if self.__oldP and self.__oldP.__newindex then
				self.__oldP.__newindex(self, k, newFunc)
			else
				rawset(self, k, newFunc)
			end
		--elseif __type == "table" then
			-- Apply metatable to child table.
			--module.ApplyMetatable(v, self.__nameP.."."..k)

		else
			-- Access old metatable, or rawset.
			if self.__oldP and self.__oldP.__newindex then
				self.__oldP.__newindex(self, k, v)
			else
				rawset(self, k, v)
			end
		end
	end,
}

function module.Slash(msg)
	local number = tonumber(msg)
	if not number then return end

	KILLTIME = tonumber(msg)
	print("|c0090ffffLUI:|r Profiler: Kill time set to", msg, "second/s.")
end

SLASH_LUIPROFILER1 = "/luiprofiler"
SlashCmdList.LUIPROFILER = module.Slash

-- Set up exludes.
-- - Add profiler functions.
excludes[module.Trace] = true
excludes[module.Print] = true
excludes[module.ApplyMetatable] = true
excludes[module.Slash] = true
 
-- - Add profiler tables.
excludes[meta] = true
excludes[module] = true

-- - Add global.
excludes[_G] = true


-- Apply metatable to the LUI namespace.
if false then
	module.ApplyMetatable(LUI, "LUI")
end