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
local abs, collectgarbage, error, format, getmetatable, GetTime = math.abs, collectgarbage, error, format, getmetatable, GetTime
local print, setmetatable, strfind, strlower, tsort, tostring, type, wipe = print, setmetatable, string.find, string.lower, table.sort, tostring, type, wipe
local debugprofilestart, debugprofilestop = debugprofilestart, debugprofilestop

-- Local variables.
local defaultKillTime = 0.5
local weakTable = {__mode = "k"}
local traces = setmetatable({}, weakTable)
local excludes = setmetatable({}, weakTable)
local timeStack = 0

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
	Notes.....: Attempts to remove a function from the profiler. Disabling the profiler and reloading the UI should be preferred however.
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

-- timerStart()
--[[
	Notes.....: This is a wrapper for debugprofilestart and debugprofilestop. It takes their functionality and makes them work similarly to GetTime().
				We count a time stack so we know when we can refresh the debug timer. Because debugprofilerstart can be called elsewhere; this might not
				always return the correct time. But a small time error here or there doesn't outweigh the precision gained.
]]
local function timerStart()
	if timeStack == 0 then
		-- Start debug timer. We track a stack to freshen the debug profiler timer's start time.
		debugprofilestart()
	end

	-- Increase stack and return new start time.
	timeStack = timeStack + 1
	return debugprofilestop()
end

-- timerStop()
--[[
	Notes.....: This is a wrapper for debugprofilestart and debugprofilestop. It takes their functionality and makes them work similarly to GetTime().
				Collects the precision timer and reduces the time stack.
]]
local function timerStop()
	-- Get times.
	local time = debugprofilestop()

	-- Reduce time stack.
	timeStack = timeStack - 1

	-- Return time.
	return time
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
			return func
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
		newFunc = function(...) --a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15)
		-- Check if removed.
			if traces[func].removed then
				-- Error out with removal reason.
				return error(traces[func].removed, 2)
			end

			-- Check for recursion.
			if traces[func].recurse > 0 then
				-- Check this recursion loop hasn't been running excessively (n seconds or n recursions).
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
			else
				-- Log recursion.
				traces[func].start = GetTime()
				traces[func].recurse = 0
			end

			-- Increase recurse counter.
			traces[func].recurse = traces[func].recurse + 1

			-- Get start time and memory.
			local mem = collectgarbage("count")
			local time = timerStart()

			-- Run original function.
			local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 = traces[func].oldFunc(...) --a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, 15)

			-- Collect time and memory results.
			time = timerStop() - time
			mem = collectgarbage("count") - mem

			-- Check time to make sure function isn't a problem.
			if time >= traces[func].killTimeMS  and not traces[func].removed then
				-- Remove function.
				traces[func].removed = module.CreateError(traces[func].name, format("Took to long: %.4f milliseconds.", time))

				-- Print out an error.
				print("|c0090ffffLUI:|r Profiler: |cffff0000Stopping function calls of", traces[func].name, "after a", time, "millisecond execution.")
			end

			-- Decrease recurse counter.
			traces[func].recurse = traces[func].recurse - 1

			-- Update stats.
			traces[func].count = traces[func].count + 1
			traces[func].last = time
			traces[func].memL = mem
			traces[func].memT = traces[func].memT + mem
			traces[func].total = traces[func].total + time
			-- - Max/Min
			if not traces[func].max or time > traces[func].max then traces[func].max = time end
			if not traces[func].min or time < traces[func].min then traces[func].min = time end

			return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
		end,

		count = 0,
		killTime = killTime,
		killTimeMS = killTime * 1000,
		last = 0,
		max = nil,
		memL = 0,
		memT = 0,
		min = nil,
		name = scope and scope.."."..name or name,
		recurse = 0,
		removed = false,
		start = 0,
		total = 0,
	}

	-- Add new function to excludes.
	excludes[traces[func].newFunc] = traces[func]

	-- Return new function.
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

module.GUI = CreateFrame("Frame", format("LUI: Profiler (%s)", GetAddOnMetadata(addonname, "X-Curse-Packaged-Version") or "Working Copy"))
local gui = module.GUI

-- Apply frame settings.
-- Variables.
gui.dt = 0
gui.Active = 3
gui.Fields = {}
gui.StartTime = GetTime()
gui.Traces = {}
gui.Sorted = setmetatable({}, weakTable)

-- Create Children.
gui.Session = gui:CreateFontString()
gui.Slider = CreateFrame("Slider", "LUI: Profiler: Slider", gui, "UIPanelScrollBarTemplate")
gui.Title = gui:CreateFontString()
gui.Totals = gui:CreateFontString()

-- Creators.
local fields = {"Name", "Calls", "Time (us)", "Avg. Time (us)", "Min (us)", "Max (us)", "Memory (bytes)"}
gui.NewField = function(self, field, width)
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
	f:ClearAllPoints()
	if not last then
		f:SetPoint("TOPLEFT", self.Totals, "BOTTOMLEFT", 0, -5)
	else
		f:SetPoint("TOPLEFT", last, "TOPRIGHT", 5)
	end
	f:SetWidth(width)
	-- Name.
	f.Name = f:CreateFontString()
	f.Name:SetAllPoints(f)
	f.Name:SetFontObject(GameFontNormalSmall)
	f.Name:SetJustifyH("CENTER")
	f.Name:SetText(field)
	f.Name:SetTextColor(0, 1, 0)

	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetMinResize(10, 20)
	f:SetResizable(true)
	f:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			gui.SetActiveField(gui.Active == self.Field and -self.Field or self.Field)
		else
			if self:GetWidth() <= 11 then
				self:SetWidth(self.lastWidth or 80)
			else
				self.lastWidth = self:GetWidth()
				self:SetWidth(10)
			end

			self:ClearAllPoints()
			if self.Field > 1 then
				self:SetPoint("TOPLEFT", gui.Fields[self.Field - 1], "TOPRIGHT", 5)
			else
				self:SetPoint("TOPLEFT", gui.Totals, "BOTTOMLEFT", 0, -5)
			end
		end
	end)
	f:SetScript("OnDragStart", function(self)
		self:StartSizing("RIGHT")
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self:ClearAllPoints()
		if self.Field > 1 then
			self:SetPoint("TOPLEFT", gui.Fields[self.Field - 1], "TOPRIGHT", 5)
		else
			self:SetPoint("TOPLEFT", gui.Totals, "BOTTOMLEFT", 0, -5)
		end
	end)
end
gui.NewTrace = function(self)
	local f = CreateFrame("Frame", nil, self)
	local last = self.Traces[#self.Traces]
	self.Traces[#self.Traces + 1] = f

	f:Hide()
	f.Func = nil
	f.Removed = false
	f:SetHeight(20)
	f:SetWidth(1)

	-- Create fields.
	last = last and last.Fields or self.Fields
	f.Fields = {}

	for i=1, #fields do
		local field = f:CreateFontString()
		field:SetPoint("TOPLEFT", last[i], "BOTTOMLEFT", 0, -5)
		field:SetPoint("TOPRIGHT", last[i], "BOTTOMRIGHT", 0, -5)
		field:SetFontObject(GameFontNormalSmall)
		field:SetJustifyH(i == 1 and "LEFT" or "CENTER")
		field:SetTextColor(1, 1, 1)
		f.Fields[i] = field
	end

	f.Update = self.OnTraceUpdate
end
gui.OnTraceUpdate = function(self, func)
	self:Show()
	if self.Func ~= func then
		self.Func = func
		self.Fields[1]:SetText(traces[func].name)
	end

	local total = traces[func].total * 1000
	local avg =  total / traces[func].count
	avg = avg > 0 and avg or 0
	self.Fields[2]:SetFormattedText("%d", traces[func].count)
	self.Fields[3]:SetFormattedText("%d",  total)
	self.Fields[4]:SetFormattedText("%.2f", avg)
	self.Fields[5]:SetFormattedText("%.2f", traces[func].min and traces[func].min * 1000 or 0)
	self.Fields[6]:SetFormattedText("%.2f", traces[func].max and traces[func].max * 1000 or 0)
	self.Fields[7]:SetFormattedText("%d", traces[func].memT * 1024)

	if self.Removed ~= traces[func].removed then
		self.Removed = traces[func].removed
		if self.Removed then
			self.Fields[1]:SetTextColor(1, 0, 0)
		else
			self.Fields[1]:SetTextColor(1, 1, 1)
		end
	end
end
gui.SetActiveField = function(field)
	local active = abs(gui.Active)
	local absField = abs(field)
	if active ~= absField then
		-- Reset previous field.
		gui.Fields[active].Name:SetTextColor(0, 1, 0)
	end

	gui.Active = field
	if gui.Active > 0 then
		gui.Fields[absField].Name:SetTextColor(0.4, 0.78, 1)
	else
		gui.Fields[absField].Name:SetTextColor(1, 0, 1)
	end

	-- Update.
	gui:OnUpdate(1)
end

-- Create fields.
gui:NewField(fields[1], 200)
for i = 2, #fields do
	gui:NewField(fields[i], 80)
end
gui.Fields[3].Name:SetTextColor(0.4, 0.78, 1)

-- Layout and look.
-- - Frame.
gui:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8})
gui:SetBackdropBorderColor(0, 0, 0, 0.2)
gui:SetBackdropColor(0, 0, 0, 0.5)
gui:SetHeight(400)
gui:SetPoint("CENTER", UIParent)
gui:SetWidth(725)
gui:SetScale(0.9)
-- - Title.
gui.Title:SetPoint("TOP", gui, "TOP", 0, -5)
gui.Title:SetFontObject(GameFontNormalSmall)
gui.Title:SetText(gui:GetName())
gui.Title:SetTextColor(0.4, 0.78, 1)
-- - Session.
gui.Session:SetPoint("TOPLEFT", gui, "TOPLEFT", 5, -20)
gui.Session:SetFontObject(GameFontNormalSmall)
gui.Session:SetFormattedText("|cffffff00Session:|r %d seconds.", GetTime() - gui.StartTime)
gui.Session:SetTextColor(1, 1, 1)
-- - Slider
gui.Slider:Enable()
gui.Slider:SetMinMaxValues(0, 15)
gui.Slider:SetOrientation("VERTICAL")
gui.Slider:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -5, -20)
gui.Slider:SetPoint("BOTTOMRIGHT", gui, "BOTTOMRIGHT", -5, 20)
gui.Slider:SetValueStep(1)
-- - Totals.
gui.Totals:SetPoint("TOPLEFT", gui.Session, "BOTTOMLEFT", 0, -5)
gui.Totals:SetFontObject(GameFontNormalSmall)
gui.Totals:SetFormattedText("|cffffff00Totals:|r Calls =  %d, Time = %d ms, Memory = %d kb.", 0, 0, 0)
gui.Totals:SetTextColor(1, 1, 1)

-- Interaction.
-- - Frame.
gui:EnableMouse(true)
gui:RegisterForDrag("LeftButton", "RightButton")
--gui:SetMinResize(725, 400)
gui:SetMovable(true)
gui.Sort = function(a, b)
-- Sort traces by active field.
	local active = gui.Active
	if active == 1 then
		return traces[a].name < traces[b].name	-- Name +
	elseif active == -1 then
		return traces[a].name > traces[b].name	-- Name -
	elseif active == 2 then
		return traces[a].count > traces[b].count	-- Calls -
	elseif active == -2 then
		return traces[a].count < traces[b].count	-- Calls +
	elseif active == 3 then
		return traces[a].total > traces[b].total	-- Time -
	elseif active == -3 then
		return traces[a].total < traces[b].total	-- Time +
	elseif active == 4 then
		local aAvg, bAvg = traces[a].total / traces[a].count, traces[b].total / traces[b].count	-- Avg.Time -
		aAvg = aAvg > 0 and aAvg or 0
		bAvg = bAvg > 0 and bAvg or 0
		return aAvg > bAvg
	elseif active == -4 then
		local aAvg, bAvg = traces[a].total / traces[a].count, traces[b].total / traces[b].count	-- Avg.Time +
		aAvg = aAvg > 0 and aAvg or 0
		bAvg = bAvg > 0 and bAvg or 0
		return aAvg < bAvg
	elseif active == 5 then
		local amin, bmin = traces[a].min, traces[b].min		-- Min Time -
		if amin and bmin then
			return amin > bmin
		else
			return amin
		end
	elseif active == -5 then
		local amin, bmin = traces[a].min, traces[b].min		-- Min Time +
		if amin and bmin then
			return amin < bmin
		else
			return amin
		end
	elseif active == 6 then
		local amax, bmax = traces[a].max, traces[b].max		-- Max Time -
		if amax and bmax then
			return amax > bmax
		else
			return amax
		end
	elseif active == -6 then
		local amax, bmax = traces[a].max, traces[b].max		-- Max Time +
		if amax and bmax then
			return amax < bmax
		else
			return amax
		end
	elseif active == 7 then
		return traces[a].memT > traces[b].memT	-- Memory -
	elseif active == -7 then
		return traces[a].memT < traces[b].memT	-- Memory +
	else
		return false
	end
end
gui.OnUpdate = function(self, elapsed)
	self.dt = self.dt + elapsed
	if self.dt < 1 then return end
	self.dt = 0

	-- Set session time.
	self.Session:SetFormattedText("|cffffff00Session:|r %d seconds.", GetTime() - self.StartTime)

	-- Gather totals.
	local tCalls, tMem, tTime = 0, 0, 0
	for i, func in ipairs(self.Sorted) do
		tCalls = tCalls + traces[func].count
		tMem = tMem + traces[func].memT
		tTime = tTime + traces[func].total
	end
	gui.Totals:SetFormattedText("|cffffff00Totals:|r Functions = %d, Calls =  %d, Time = %d ms, Memory = %d kb.", #self.Sorted, tCalls, tTime, tMem)

	-- Sort traces.
	tsort(self.Sorted, self.Sort)

	-- Update displays.
	local t, s = #self.Traces, #self.Sorted
	local slider = self.Slider:GetValue()
	local total = t > s and t or s
	total = total > 20 and 20 or total
	for i = 1, total do
		if self.Sorted[i + slider] then
			-- Create new trace line.
			if not self.Traces[i] then
				self:NewTrace()
			end

			-- Update trace line.
			self.Traces[i]:Update(self.Sorted[i + slider])
		else
			if self.Traces[i] then
				-- Hide trace line.
				self.Traces[i]:Hide()
			end
		end
	end
end

-- Scripts.
-- - Frame.
gui:SetScript("OnDragStart", function(self, button)
	if button == "LeftButton" then
		-- Left mouse drag = move frame.
		self:StartMoving()
	else
		-- Right mouse drag = resize frame.
		--self:StartSizing("BOTTOMRIGHT")
	end
end)
gui:SetScript("OnDragStop", gui.StopMovingOrSizing)
gui:SetScript("OnUpdate", gui.OnUpdate)
-- - Slider.
gui.Slider:SetScript("OnValueChanged", function(self)
	gui:OnUpdate(1)
end)

-- Add gui to special frames, for "Esc" closure.
tinsert(UISpecialFrames, gui:GetName())

-- Profiler.GUI.Watch(filter)
--[[
	Notes.....: Loads GUI to watch all traced functions, or functions with filter in their name.
]]
gui.Watch = function(filter)
-- Clear watched traces.
	wipe(gui.Sorted)

	-- Check filter.
	if filter and filter == "" then
		filter = nil
	end

	-- Collect traces.
	for func, info in pairs(traces) do
		-- Check against filter.
		if not filter or strfind(strlower(info.name), strlower(filter)) then
			gui.Sorted[#gui.Sorted + 1] = func
		end
	end

	-- Sort slider.
	if #gui.Sorted > 20 then
		gui.Slider:SetMinMaxValues(0, #gui.Sorted - 20)
		gui.Slider:SetValue(0)
		gui.Slider:Show()
	else
		gui.Slider:SetValue(0)
		gui.Slider:Hide()
	end

	-- Show frame.
	gui.dt = 1
	gui:Show()
end

-- Create slash command to open Profiler GUI.
SLASH_LUIPROFILER1 = "/luiprofiler"
SlashCmdList.LUIPROFILER = gui.Watch





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
