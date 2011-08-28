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
local geterrorhandler, seterrorhandler = geterrorhandler, seterrorhandler

-- Local variables.
local KILLTIME = 0.03
local traces = {}
local excludes = {}
local metatable
local dummy = function() error("This function has been removed by LUI's profiler.", 3) end

-- For debug purposes.
function module.GetInfo()
	return traces, excludes, KILLTIME
end

function module.Print()
	for f, t in pairs(traces) do
		print(t.name, ":", t.count, "calls,", t.total, "seconds,", t.memT, "kb.")
	end
end

function module.ApplyMetatable(table, name)
	-- Check excludes.
	if excludes[table] then return end

	-- Add table to excludes.
	excludes[table] = true

	-- Set metatable variables.
	rawset(table, "__nameP", name)
	rawset(table, "__oldP", getmetatable(table) or false)

	-- Add old metatable to excludes.
	if table.__oldP then
		excludes[table.__oldP] = true
	end
		
	-- Set metatable.
	print("Setting metatable for", name)
	table = setmetatable(table, metatable)

	-- Check metatable was set.
	if type(table) ~= "table" then return error("Metatable failed") end

	-- Scan for previously written functions and tables.
	local vType
	for k, v in pairs(table) do
		vType = type(v)
		if vType == "function" then
			-- Trace function.
			local newFunc = module.Trace(v, k, name)
			print("Tracing function:", name.."."..k)

			-- Pass new function to old metatable, or rawset.
			if table.__oldP and table.__oldP.__newindex then
				table.__oldP.__newindex(table, k, newFunc)
			else
				rawset(table, k, newFunc)
			end

			if table[k] ~= newFunc then
				print("Failed to set new function.")
			end
		elseif vType == "table" then
			-- Apply metatable to child table.
			module.ApplyMetatable(v, name.."."..k)
		end
	end
end

function module.Trace(func, name, scope)
	-- Skip already traced functions or excluded ones.
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
					-- Remove function.
					traces[func].removed = true
					traces[func].oldFunc = dummy
				
					-- Create an error to break recursion.
					print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping recursive loop of "..traces[func].name.." after "..traces[func].recurse.." calls.")

					-- Stop recurse
					traces[func].recurse = 0
					return
				end

				-- Get time.
				time = GetTime()
			else
				-- Get time and log for recursion.
				time  = GetTime()
				traces[func].start = time
				traces[func].recurse = 0
			end

			-- Increase recurse counter.
			traces[func].recurse = traces[func].recurse + 1
            
			-- Run and collect results.
			local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 = traces[func].oldFunc(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, 15)

			-- Collect time and memory results.
			time = GetTime() - time
			mem = collectgarbage("count") - mem

			-- Check time to make sure function isn't a problem.
			if time > KILLTIME  and not traces[func].removed then
				-- Remove function.
				traces[func].removed = true
				traces[func].oldFunc = dummy

				-- Print error.
				print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping function calls of "..traces[func].name.." after a "..time.." second execution.")
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
		removed = false,
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

-- Create metatable.
metatable = {
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

-- Set up exludes.
-- - Add profiler functions.
excludes[module.ApplyMetatable] = true
excludes[module.GetInfo] = true
excludes[module.Print] = true
excludes[module.Trace] = true
 
-- - Add profiler tables.
excludes[metatable] = true
excludes[module] = true

-- - Add global.
excludes[_G] = true


-- Apply metatable to the LUI namespace.
if false then
	module.ApplyMetatable(LUI, "LUI")
end