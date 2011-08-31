--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: profiler.lua
	Description: Experimental profiler tools.
]]


-- External references.
local addonname, LUI = ...

-- Profiler state.
local Enabled = false

-- Create profiler namespace.
LUI.Profiler = {}
local module = LUI.Profiler


-- Localize functions.
local collectgarbage, error, format, getmetatable, GetTime = collectgarbage, error, format, getmetatable, GetTime
local print, setmetatable, tostring, type = print, setmetatable, tostring, type

-- Local variables.
local defaultKillTime = 0.5
local weakTable = {__mode = "k"}
local traces = setmetatable({}, weakTable)
local excludes = setmetatable({}, weakTable)


-- Profiler.CreateError(name, reason)
--[[
	Notes.....: Creates an error string to explain why the profiler has disabled a function.
	Parameters:
	(string) name: Name of the function error string is for.
	(string) reason: The reason why the profiler has disabled the function.	
]]
function module.CreateError(name, reason)
	return "Function ["..name.."] has been removed by LUI's profiler.\nReason = "..reason
end

-- Profiler.Exclude(func)
--[[
	Notes.....: Adds a function to the profilers exclusion list.
	Parameters:
	(function) func: The function to add to the exclusion list.
]]
function module.Exclude(func)
	-- Check profiler is enabled.
	if not Enabled then return end

	-- Add function to excludes without overwriting potential tracer links.
	excludes[func] = excludes[func] or true
end

-- Profiler.RemoveTrace(func)
--[[
	Notes.....: Attempts to remove a function from the profiler. Disabling the profiler and reloading the UI should be prefered however.
	Parameters:
	(function) func: The function to be removed from the profiler. Can be the original function or the new function that was returned by the profiler.
]]
function module.RemoveTrace(func)
	-- Check profiler is enabled.
	if not Enabled then return func end

	-- Find original function.
	if traces[func] then
		-- Remove trace.
		excludes[traces[func].newFunc] = nil
		traces[func] = nil

		-- Return original function.
		return func
	elseif type(excludes[func]) == "table" then
		-- Get old function and remove trace.
		local oldFunc = excludes[func].oldFunc
		excludes[func] = nil
		traces[oldFunc] = nil

		-- Return original function.
		return oldFunc	
	else
		-- Not traced, return the passed function.
		return func
	end
end

-- Profiler.Trace(func, name[, scope[, killTime]])
--[[
	Notes.....: Adds a function for profiling. If a table is passed, it will be sent to Profiler.TraceScope.
	Parameters:
	(function) func: The function to add to the profiler.
	(string) name: Name of the function; e.i. "Trace".
	(string) scope: Name of the scope; e.i. "Profiler".
	(number) killTime: Custom kill time to be used with the function in seconds.
]]
function module.Trace(func, name, scope, killTime)
	-- Check profiler is enabled.
	if not Enabled then return func end

	-- Only trace functions.
	if type(func) ~= "function" then
		if type(func) == "table" then
			module.TraceScope(func, name, scope, killTime)
		else
			return
		end
	end

	-- Skip already traced functions or excluded ones.
	if traces[func] then
		return traces[func].newFunc
	elseif excludes[func] then
		return func
	end

	-- Default killTime.
	killTime = killTime or defaultKillTime

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
				-- Check this recursion loop hasn't been running excesively (n seconds or n recurses).
				if GetTime() - traces[func].start >= traces[func].killTime --[[or traces[func].recurse > 1000]] then
					-- Remove function.
					traces[func].removed = module.CreateError(traces[func].name, format("Recursion: %d calls.", traces[func].recurse))
				
					-- Print out an error. Using error will hang the client as it reads the call stack.
					print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping recursive loop of", traces[func].name, "after", traces[func].recurse, "calls with total execution time of", GetTime() - traces[func].start, "seconds.")

					-- Stop recurse
					traces[func].recurse = 0

					-- Return to break recursion.
					return
				end

				-- Get time.
				time = GetTime()
			else
				-- Get time and log for recursion.
				time = GetTime()
				traces[func].start = time
				traces[func].recurse = 0
			end

			-- Increase recurse counter.
			traces[func].recurse = traces[func].recurse + 1
            
			-- Run and collect results.
			if traces[func].removed then
				-- Error out with removal reason.
				return error(traces[func].removed, 2)
			else
				-- Run original function.
				local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 = traces[func].oldFunc(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, 15)
			end
			
			-- Collect time and memory results.
			time = GetTime() - time
			mem = collectgarbage("count") - mem

			-- Check time to make sure function isn't a problem.
			if time >= traces[func].killTime  and not traces[func].removed then
				-- Remove function.
				traces[func].removed = module.CreateError(traces[func].name, format("Took to long: %.4f seconds.", time))

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

		count = 0,
		killTime = killTime,
		last = 0,
		memL = 0,
		memT = 0,
		name = scope and scope.."."..name or name,
		recurse = 0,
		removed = false,
		start = 0,
		total = 0,
	}

	-- Add new function to excludes.
	excludes[traces[func].newFunc] = traces[func]

	-- Return new funcion.
	return traces[func].newFunc
end

-- Profiler.TraceScope(scope, name[, parent[, killTime[, depth]]])
--[[
	Notes.....: Adds all functions under the given table for profiling.
	Parameters:
	(table) scope: The table which holds the functions.
	(string) name: Name of the scope; e.i. "Profiler".
	(string) parent: Name of the parent scope; e.i. "LUI".
	(number) killTime: Custom kill time to be used with the functions in seconds.
	(number) depth: How many child tables should also be processed.
]]
function module.TraceScope(scope, name, parent, killTime, depth)
	-- Check profiler is enabled.
	if not Enabled then return end

	-- Only process tables.
	if type(scope) ~= "table" then return end

	-- Check depth.
	depth = depth or 0
	if depth < 0 then return end

	-- Set next depth.
	depth = depth - 1

	-- Get new scope name.
	name = tostring(name)
	name = parent and parent.."."..name or name

	-- Trace all functions under this scope.
	local kType, vType
	for k, v in pairs(scope) do
		-- Check key type.
		kType = type(k)
		if kType == "function" then
			-- Remove old value from table.
			scope[k] = nil

			-- Trace function.
			k = module.Trace(k, k, name, killTime)

			-- Add traced function with value to table.
			scope[k] = v
		elseif kType == "table" then
			-- Trace functions in child table.
			module.TraceScope(k, k, name, killTime, depth)
		end

		-- Check value type.
		vType = type(v)
		if vType == "function" then
			-- Trace function.
			v = module.Trace(v, k, name, killTime)

			-- Add traced function to table in place of the old.
			scope[k] = v
		elseif vType == "table" then
			-- Trace functions in child table.
			module.TraceScope(v, k, name, killTime, depth)
		end
	end
end


-- Set up excludes.
-- - Add profiler functions.
excludes[module.CreateError] = true
excludes[module.Exclude] = true
excludes[module.RemoveTrace] = true
excludes[module.Trace] = true
excludes[module.TraceScope] = true


-- Create Profilers GUI.
if not Enabled then return end
if true then return end -- Still working on GUI.

module.Frame = CreateFrame("Frame", "LUI: Profiler")
local f = module.Frame

-- Apply frame settings.
-- Variables.
f.Active = 1
f.Fields = {}
f.Traces = {}

-- Create Children.
f.Title = f:CreateFontString()

-- Creators.
local fields = {"Name", "Calls", "Time (ms)", "Memory (bytes)", "Kill Time"}
f.NewField = function(self, field, width)
	local f = CreateFrame("Frame", self:GetName()..": Field <"..field..">", self)
	local last = self.Fields[#self.Fields]
	self.Fields[#self.Fields + 1] = f
	f.Field = #self.Fields

	-- Frame.
	f:Show()
	f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8})
	f:SetBackdropBorderColor(0, 1, 0, 1)
	f:SetBackdropColor(0, 0, 0, 0)
	f:SetHeight(20)
	if not last then
		f:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -30)
	else
		f:SetPoint("LEFT", last, "LEFT", 5)
	end
	f:SetWidth(width)
	-- Name.
	f.Name = CreateFontString()
	f.Name:SetPoint("CENTER", f)
	f.Name:SetFontObject(GameFontNormalSmall)
	f.Name:SetJustifyH("CENTER")
	f.Name:SetText(field)
	f.Name:SetTextColor(0, 1, 0)

	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetMinResize(20, 20)
	f:SetResizable(true)
	f:SetScript("OnMouseUp", function(f)
		if math.abs(self.Active) == f.Field then
			self.Active = -self.Active
		else
			self.Active = f.Field
		end
	end)
	f:SetScript("OnDragStart", function(self)
		self:StartSizing("RIGHT")
	end)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
end
f.NewTrace = function(self)
	local f = CreateFrame("Frame", nil, self)
	local last = self.Traces[#self.Traces] or self
	self.Traces[#self.Traces + 1] = f

	f:Show()
	f:SetHeight(20)
	f:SetWidth(1)
end

-- Layout and look.
-- - Frame.
f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8})
f:SetBackdropBorderColor(0, 0, 0, 0.2)
f:SetBackdropColor(0, 0, 0, 0.5)
f:SetHeight(300)
f:SetPoint("CENTER", UIParent)
f:SetWidth(550)
-- - Title.
f.Title:SetPoint("TOP", f, "TOP", 0, -5)
f.Title:SetFontObject(GameFontNormalSmall)
f.Title:SetText(f:GetName())
f.Title:SetTextColor(0.4, 0.78, 1)

-- Interaction.
-- - Frame.
f:EnableMouse(true)
f:RegisterForDrag("LeftButton", "RightButton")
f:SetMinResize(200, 100)
f:SetMovable(true)
f:SetResizable(true)

-- Scripts.
-- - Frame.
f:SetScript("OnDragStart", function(self, button)
	if button == "LeftButton" then
		-- Left mouse drag = move frame.
		self:StartMoving()
	else
		-- Right mouse drag = resize frame.
		self:StartSizing("TOPRIGHT")
	end
end)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- Add pad to special frames, for "Esc" closure.
tinsert(UISpecialFrames, f:GetName())

-- Create slash command to open Profiler GUI.
SLASH_LUIPROFILER1 = "/luiprofiler"
SlashCmdList.LUIPROFILER = function() module.Frame:Show() end






-- Old functions for safekeeping. Some of their features have nice functionality we may find interesting.
 
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

-- Create metatable.
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