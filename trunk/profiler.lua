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
local collectgarbage, error, GetTime, print, tostring, type = collectgarbage, error, GetTime, print, tostring, type
local getmetatable, setmetatable = getmetatable, setmetatable

-- Local variables.
local KILLTIME = 0.5
local traces = {}
local excludes = setmetatable({}, {__mode = "kv"})
local metatable
--[[
function module.ApplyMetatable(table, name, scope)
	-- Check excludes.
	if excludes[table] then return end

	-- Don't set metatable for database tables... You've been warned!
	if name == "db" or name == "dbd" or name == "defaults" then
		excludes[table] = true
		return
	end

	-- Add table to excludes.
	excludes[table] = true

	-- Force name to a string value.
	name = tostring(name)

	-- Set metatable variables.
	rawset(table, "__nameP", scope and scope.."."..name or name)
	rawset(table, "__oldP", getmetatable(table) or false)

	-- Add old metatable to excludes.
	if table.__oldP then
		excludes[table.__oldP] = true
	end
		
	-- Set metatable.
	print("Setting metatable for", table.__nameP)
	table = setmetatable(table, metatable)

	-- Check metatable was set.
	if type(table) ~= "table" then return error("Metatable failed") end

	-- Scan for previously written functions and tables.
	local kType, vType
	for k, v in pairs(table) do
		-- Check key type.
		kType = type(k)
		if kType == "function" then
			-- Remove old value from table.
			table[k] = nil

			-- Trace function.
			k = module.Trace(k, k, table.__nameP)

			-- Pass new function to old metatable, or rawset.
			if table.__oldP and table.__oldP.__newindex then
				table.__oldP.__newindex(table, k, v)
			else
				rawset(table, k, v)
			end
		elseif kType == "table" then
			-- Apply metatable to child table.
			module.ApplyMetatable(k, k, table.__nameP)
		end

		-- Check value type.
		vType = type(v)
		if vType == "function" then
			-- Trace function.
			v = module.Trace(v, k, table.__nameP)

			-- Pass new function to old metatable, or rawset.
			if table.__oldP and table.__oldP.__newindex then
				table.__oldP.__newindex(table, k, v)
			else
				rawset(table, k, v)
			end
		elseif vType == "table" then
			-- Apply metatable to child table.
			module.ApplyMetatable(v, k, table.__nameP)
		end
	end
end
--]]

function module.CreateDummy(name, reason)
	return function() error("Function ["..name.."] has been removed by LUI's profiler.\nReason = "..reason, 3) end
end

--[[
-- Creates a list of all tables in the given table.
local function exTable(table)
	excludes[table] = true

	local more = {}
	for k, v in pairs(table) do
		if type(k) == "table" then
			excludes[k] = true
			for kk, kv in pairs(k) do
				if type(kk) == "table" then
					more[#more + 1] = kk
				end
				if type(kv) == "table" then
					more[#more + 1] = kv
				end
			end
		end
		if type(v) == "table" then
			excludes[v] = true
			for vk, vv in pairs(v) do
				if type(vk) == "table" then
					more[#more + 1] = vk
				end
				if type(vv) == "table" then
					more[#more + 1] = vv
				end
			end
		end
	end

	return #more > 0, more
end

local f = CreateFrame("frame")
function module.ExcludeTable(table, children)
	if not children then
		excludes[table] = true
		return
	end

	local GetTime = GetTime
	f.state = true
	f.t = table

	f.throttle = 0
	f:SetScript("OnUpdate", function(self)
		if GetTime() - self.throttle < 1 then return end

		print("Processing:", #self.t)
		self.state, self.t = exTable(self.t)

		if self.state then
			print("Pausing.")
			self.throttle = GetTime()
		else
			self:SetScript("OnUpdate", nil)
			print("Collecting Garbage.")
			collectgarbage()
			print("Finished.")
		end
	end)
end
--]]

function module.GetInfo()
	return traces, excludes, KILLTIME
end

function module.Print()
	for f, t in pairs(traces) do
		print(t.name, ":", t.count, "calls,", t.total, "seconds,", t.memT, "kb.")
	end
end

function module.Trace(func, name, scope)
	-- Skip already traced functions or excluded ones.
	if traces[func] then
		return traces[func].newFunc
	elseif excludes[func] then
		return func
	end

	-- Force name to a string value.
	name = tostring(name)
    
	-- Create trace.
	traces[func] = {
		oldFunc = func,
		newFunc = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15)
			local time
			local mem = collectgarbage("count")
			
			-- Check for recursion.
			if traces[func].recurse > 0 then
				-- Check this recursion loop hasn't been running excesively (n seconds).
				if GetTime() - traces[func].start >= KILLTIME then
					-- Remove function.
					traces[func].removed = true
					traces[func].oldFunc = module.CreateDummy(traces[func].name, "Recursion: "..traces[func].recurse.." calls.")
				
					-- Print out an error. Using error will hang the client as it reads the call stack.
					print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping recursive loop of", traces[func].name, "after", traces[func].recurse, "calls with total execution time of", GetTime() - traces[func].start, "seconds.")

					-- Stop recurse
					traces[func].recurse = 0

					-- Return to break recurse.
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
			if time >= KILLTIME  and not traces[func].removed then
				-- Remove function.
				traces[func].removed = true
				traces[func].oldFunc = module.CreateDummy(traces[func].name, "Took to long: "..time.." seconds.")

				-- Print out an error.
				print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping function calls of", traces[func].name, "after a", time, "second execution.")
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
--[[
metatable = {
	__index = function(self, k)
		-- Look up old metatbale if it exists.
		if self.__oldP and self.__oldP.__index then
			local __type = type(self.__oldP.__index)
			if __type == "function" then
				return self.__oldP.__index(self, k)
			elseif __type == "table" then
				return self.__oldP.__index[k]
			end
		end
	end,
	__newindex = function(self, k, v)
		-- Check key type.
		local kType = type(k)
		if kType == "function" then
			-- Remove old value from table.
			self[k] = nil

			-- Trace function.
			k = module.Trace(k, k, table.__nameP)

			-- Pass new function to old metatable, or rawset.
			if table.__oldP and table.__oldP.__newindex then
				table.__oldP.__newindex(table, k, v)
			else
				rawset(table, k, v)
			end
		elseif vType == "table" then
			-- Apply metatable to child table.
			module.ApplyMetatable(k, k, table.__nameP)
		end

		-- Check value type.
		local vType = type(v)
		if vType == "function" then
			-- Trace function.
			v = module.Trace(v, k, self.__nameP)

			-- Pass new function to old metatable, or rawset.
			if self.__oldP and self.__oldP.__newindex then
				self.__oldP.__newindex(self, k, v)
			else
				rawset(self, k, v)
			end
		elseif vType == "table" then
			-- Apply metatable to child table.
			module.ApplyMetatable(v, k, self.__nameP)
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
--]]

-- Set up exludes.
-- - Add profiler functions.
--excludes[module.ApplyMetatable] = true
excludes[module.CreateDummy] = true
--excludes[module.ExcludeTable] = true
excludes[module.GetInfo] = true
excludes[module.Print] = true
excludes[module.Trace] = true
 
-- - Add profiler tables.
--[[
excludes[metatable] = true
excludes[module] = true

-- - Add global.
excludes[_G] = true

-- Apply metatable to the LUI namespace.
if false then
	module.ApplyMetatable(LUI, "LUI")
end
--]]