--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: toggle.lua
	Description: Toggle Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Fader = LUI:GetModule("Fader")
local Blizzard = LUI.Blizzard
local oUF = LUI.oUF

local MAX_PLAYER_LEVEL = _G.MAX_PLAYER_LEVEL
local MAX_BOSS_FRAMES = _G.MAX_BOSS_FRAMES

local UnregisterStateDriver = _G.UnregisteredStateDriver
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local RegisterStateDriver = _G.RegisterStateDriver
local GetNumGroupMembers = _G.GetNumGroupMembers
local InCombatLockdown = _G.InCombatLockdown
local IsAddOnLoaded = _G.IsAddOnLoadOnDemand
local GetCVarBool = _G.GetCVarBool
local UnitLevel = _G.UnitLevel
local IsInRaid = _G.IsInRaid
local SetCVar = _G.SetCVar

local iconlist = {
	PvP = {"PvPIndicator"},
	Combat = {"CombatIndicator"},
	Resting = {"RestingIndicator"},
	Leader = {"LeaderIndicator", "AssistantIndicator"},
	Role = {"GroupRoleIndicator"},
	Raid = {"RaidTargetIndicator"},
	ReadyCheck = {"ReadyCheckIndicator"},
}

local function GetOpposite(dir)
	if dir == "RIGHT" then
		return "LEFT"
	elseif dir == "LEFT" then
		return "RIGHT"
	elseif dir == "BOTTOM" then
		return "TOP"
	elseif dir == "TOP" then
		return "BOTTOM"
	end
end

local ToggleMT = {
	__index = function(self)
		return self.Default
	end,
	__call = function(self, unit, override)
		oUF:SetActiveStyle("LUI")
		self[unit](override, unit)
	end,
}

-- Castbars for *target units are no longer supported as they had no event-driven updates 
function module:UnitSupportsCastbar(unit)
	return module.db.profile.Settings.Castbars and unit:match(".+target$")
end

module.ToggleUnit = setmetatable({
	Default = function(override, unit)
		local dbUnit = module.db.profile[unit]
		local x = dbUnit.X / dbUnit.Scale
		local y = dbUnit.Y / dbUnit.Scale

		if override == nil then override = dbUnit.Enable end

		if override then
			if _G["oUF_LUI_"..unit] then
				_G["oUF_LUI_"..unit]:Enable()
				_G["oUF_LUI_"..unit]:UpdateAllElements('refreshUnit')
				_G["oUF_LUI_"..unit]:ClearAllPoints()
				_G["oUF_LUI_"..unit]:SetScale(dbUnit.Scale)
				_G["oUF_LUI_"..unit]:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
			else
				local f = oUF:Spawn(unit, "oUF_LUI_"..unit)
				f:SetScale(dbUnit.Scale)
				f:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
			end

			if Blizzard:IsHideable(unit) then
				Blizzard:Hide(unit)
			end
		else
			if Blizzard:IsHideable(unit) then
				Blizzard:Show(unit)
			end

			if _G["oUF_LUI_"..unit] then _G["oUF_LUI_"..unit]:Disable() end
		end

		module.ApplySettings(unit)
	end,

	boss = function(override)
		local dbUnit = module.db.profile.boss
		if override == nil then override = dbUnit.Enable end

		if override then
			local x = dbUnit.X / dbUnit.Scale
			local y = dbUnit.Y / dbUnit.Scale

			local growdir = dbUnit.GrowDirection
			local opposite = GetOpposite(growdir)

			Blizzard:Hide("boss")

			if oUF_LUI_boss then
				oUF_LUI_boss:SetScale(dbUnit.Scale)
				oUF_LUI_boss:ClearAllPoints()
				oUF_LUI_boss:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				oUF_LUI_boss:SetWidth(dbUnit.Width)
				oUF_LUI_boss:SetHeight(dbUnit.Height)
				oUF_LUI_boss:SetAttribute("Height", dbUnit.Height)
				oUF_LUI_boss:SetAttribute("Padding", dbUnit.Padding)
				oUF_LUI_boss:Show()

				for i = 1, MAX_BOSS_FRAMES do
					_G["oUF_LUI_boss"..i]:Enable()
					_G["oUF_LUI_boss"..i]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_boss"..i]:ClearAllPoints()
					if i == 1 then
						local point = (growdir == "LEFT" or growdir == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
						_G["oUF_LUI_boss"..i]:SetPoint(point, oUF_LUI_boss, point, 0, 0)
					else
						if growdir == "LEFT" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, - dbUnit.Padding, 0)
						elseif growdir == "RIGHT" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, dbUnit.Padding, 0)
						elseif growdir == "TOP" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, dbUnit.Padding)
						else
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, - dbUnit.Padding)
						end
					end
				end
			else
				local bossParent = CreateFrame("Frame", "oUF_LUI_boss", UIParent)
				bossParent:SetScale(dbUnit.Scale)
				bossParent:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				bossParent:SetWidth(dbUnit.Width)
				bossParent:SetHeight(dbUnit.Height)
				bossParent:SetAttribute("Height", dbUnit.Height)
				bossParent:SetAttribute("Padding", dbUnit.Padding)
				bossParent:Show()

				local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
				handler:SetFrameRef("boss", bossParent)
				handler:SetAttribute("_onstate-resize", [[
					local parent = self:GetFrameRef("boss")
					local padding = parent:GetAttribute("Padding")
					local height = parent:GetAttribute("Height")
					parent:SetHeight(newstate * height + (newstate - 1) * padding)
				]])
				RegisterStateDriver(handler, "resize", "[@boss4,exists] 4; [@boss3,exists] 3; [@boss2,exists] 2; 1")
				bossParent.handler = handler

				local boss = {}
				for i = 1, MAX_BOSS_FRAMES do
					boss[i] = oUF:Spawn("boss"..i, "oUF_LUI_boss"..i)
					boss[i]:SetParent(bossParent)
					if i == 1 then
						local point = (growdir == "LEFT" or growdir == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
						boss[i]:SetPoint(point, bossParent, point, 0, 0)
					else
						if growdir == "LEFT" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, - dbUnit.Padding, 0)
						elseif growdir == "RIGHT" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, dbUnit.Padding, 0)
						elseif growdir == "TOP" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, dbUnit.Padding)
						else
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, - dbUnit.Padding)
						end
					end
				end
			end

			module.ToggleUnit("bosstarget")
		else
			if dbUnit.UseBlizzard then
				Blizzard:Show("boss")
			else
				Blizzard:Hide("boss")
			end

			if oUF_LUI_boss then
				oUF_LUI_boss:Hide()
				for i = 1, MAX_BOSS_FRAMES do
					if _G["oUF_LUI_boss"..i] then _G["oUF_LUI_boss"..i]:Disable() end
				end
			end

			module.ToggleUnit("bosstarget", false)
		end
	end,

	bosstarget = function(override)
		local dbUnit = module.db.profile.bosstargert
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			if _G.oUF_LUI_bosstarget1 then
				for i = 1, MAX_BOSS_FRAMES do
					if _G["oUF_LUI_bosstarget"..i] then
						_G["oUF_LUI_bosstarget"..i]:Enable()
						_G["oUF_LUI_bosstarget"..i]:ClearAllPoints()
						_G["oUF_LUI_bosstarget"..i]:SetPoint(dbUnit.Point, _G["oUF_LUI_boss"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					end
				end
			else
				for i = 1, MAX_BOSS_FRAMES do
					oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i):SetPoint(dbUnit.Point, _G["oUF_LUI_boss"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					_G["oUF_LUI_bosstarget"..i]:SetParent(_G["oUF_LUI_boss"..i])
				end
			end
		else
			for i = 1, MAX_BOSS_FRAMES do
				if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Disable() end
			end
		end
	end,

	party = function(override)
		local dbUnit = module.db.profile.party
		if override == nil then override = dbUnit.Enable end

		if override then
			local x = dbUnit.X / dbUnit.Scale
			local y = dbUnit.Y / dbUnit.Scale

			local growdir = dbUnit.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_party then
				oUF_LUI_party:SetScale(dbUnit.Scale)
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				oUF_LUI_party:SetAttribute("point", opposite)
				oUF_LUI_party:SetAttribute("xOffset", growdir == "LEFT" and - dbUnit.Padding or dbUnit.Padding)
				oUF_LUI_party:SetAttribute("yOffset", growdir == "BOTTOM" and - dbUnit.Padding or dbUnit.Padding)
				oUF_LUI_party:SetAttribute("showPlayer", dbUnit.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
						self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
						self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
					end
				]])

				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Enable()
						_G["oUF_LUI_partyUnitButton"..i]:UpdateAllElements('refreshUnit')
					end
				end
				oUF_LUI_party.handler:GetScript("OnEvent")(oUF_LUI_party.handler)
			else
				local party = oUF:SpawnHeader("oUF_LUI_party", nil, nil,
					"showParty", true,
					"showPlayer", dbUnit.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"point", opposite,
					"xOffset", growdir == "LEFT" and - dbUnit.Padding or dbUnit.Padding,
					"yOffset", growdir == "BOTTOM" and - dbUnit.Padding or dbUnit.Padding,
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
							self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
							self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
						end
					]]
				)

				party:SetScale(dbUnit.Scale)
				party:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)

				local handler = CreateFrame("Frame")
				handler:RegisterEvent("PLAYER_ENTERING_WORLD")
				handler:RegisterEvent("GROUP_ROSTER_UPDATE")
				handler:SetScript("OnEvent", function(self, event)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
						return
					end

					self:UnregisterEvent("PLAYER_REGEN_ENABLED")

					if dbUnit.Enable then
						if dbUnit.ShowInRaid then
							party:Show()
						else
							if not IsInRaid() then
								party:Show()
							else
								-- GetNumGroupMembers() - total number of players in the group (either party or raid), 0 if not in a group. 
								-- GetNumSubgroupMembers() - number of players in the player's sub-group, excluding the player. 
								local numraid = GetNumGroupMembers()
								local numparty = GetNumSubgroupMembers()
								if dbUnit.ShowInRealParty then
									if IsInRaid() then
										party:Hide()
									end
								else
									if numraid > 0 and numraid <= 5 then
										party:Show()
									else
										party:Hide()
									end
								end
							end
						end
					else
						party:Hide()
					end
				end)
				party.handler = handler
				handler:GetScript("OnEvent")(handler)
			end

			SetCVar("useCompactPartyFrames", nil)
			Blizzard:Hide("party")

			module.ToggleUnit("partytarget")
			module.ToggleUnit("partypet")
		else
			if dbUnit.UseBlizzard then
				Blizzard:Show("party")
			else
				SetCVar("useCompactPartyFrames", nil)
				Blizzard:Hide("party")
			end

			if oUF_LUI_party then
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Disable()
						_G["oUF_LUI_partyUnitButton"..i]:Hide()
					end
				end
				oUF_LUI_party:Hide()
			end

			module.ToggleUnit("partytarget", false)
			module.ToggleUnit("partypet", false)
		end
	end,

	partytarget = function(override)
		local dbUnit = module.db.profile.partytarget
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(dbUnit.Point, _G["oUF_LUI_partyUnitButton"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,

	partypet = function(override)
		local dbUnit = module.db.profile.partypet
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:SetPoint(dbUnit.Point, _G["oUF_LUI_partyUnitButton"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then _G["oUF_LUI_partyUnitButton"..i.."pet"]:Disable() end
			end
		end
	end,

	Arena = function(override)
		local dbUnit = module.db.profile.arena
		if override == nil then override = dbUnit.Enable end

		if override then
			local x = dbUnit.X / dbUnit.Scale
			local y = dbUnit.Y / dbUnit.Scale

			local growdir = dbUnit.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_arena then
				oUF_LUI_arena:SetScale(dbUnit.Scale)
				oUF_LUI_arena:ClearAllPoints()
				oUF_LUI_arena:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				oUF_LUI_arena:SetWidth(dbUnit.Width)
				oUF_LUI_arena:SetHeight(dbUnit.Height)
				oUF_LUI_arena:SetAttribute("Height", dbUnit.Height)
				oUF_LUI_arena:SetAttribute("Padding", dbUnit.Padding)
				oUF_LUI_arena:Show()

				for i = 1, 5 do
					_G["oUF_LUI_arena"..i]:Enable()
					_G["oUF_LUI_arena"..i]:ClearAllPoints()
					_G["oUF_LUI_arena"..i]:UpdateAllElements('refreshUnit')
					if i == 1 then
						local point = (growdir == "LEFT" or growdir == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
						_G["oUF_LUI_arena"..i]:SetPoint(point, oUF_LUI_arena, point, 0, 0)
					else
						if growdir == "LEFT" then
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, - dbUnit.Padding, 0)
						elseif growdir == "RIGHT" then
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, dbUnit.Padding, 0)
						elseif growdir == "TOP" then
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, 0, dbUnit.Padding)
						else
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, 0, - dbUnit.Padding)
						end
					end
				end
			else
				-- oUF kills it, we save it!
				-- Should be handled fine by the new hideblizzard tool
				-- Arena_LoadUI_ = ArenaLoadUI

				local arenaParent = CreateFrame("Frame", "oUF_LUI_arena", UIParent)
				arenaParent:SetScale(dbUnit.Scale)
				arenaParent:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				arenaParent:SetWidth(dbUnit.Width)
				arenaParent:SetHeight(dbUnit.Height)
				arenaParent:SetAttribute("Height", dbUnit.Height)
				arenaParent:SetAttribute("Padding", dbUnit.Padding)
				arenaParent:Show()

				local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
				handler:SetFrameRef("arena", arenaParent)
				handler:SetAttribute("_onstate-resize", [[
					local parent = self:GetFrameRef("arena")
					local padding = parent:GetAttribute("Padding")
					local height = parent:GetAttribute("Height")
					parent:SetHeight(newstate * height + (newstate - 1) * padding)
				]])
				RegisterStateDriver(handler, "resize", "[@arena5,exists] 5; [@arena4,exists] 4; [@arena3,exists] 3; [@arena2,exists] 2; 1")
				arenaParent.handler = handler

				local arena = {}
				for i = 1, 5 do
					arena[i] = oUF:Spawn("arena"..i, "oUF_LUI_arena"..i)
					arena[i]:SetParent(arenaParent)
					if i == 1 then
						local point = (growdir == "LEFT" or growdir == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
						arena[i]:SetPoint(point, arenaParent, point, 0, 0)
					else
						if growdir == "LEFT" then
							arena[i]:SetPoint(opposite, arena[i-1], growdir, - dbUnit.Padding, 0)
						elseif growdir == "RIGHT" then
							arena[i]:SetPoint(opposite, arena[i-1], growdir, dbUnit.Padding, 0)
						elseif growdir == "TOP" then
							arena[i]:SetPoint(opposite, arena[i-1], growdir, 0, dbUnit.Padding)
						else
							arena[i]:SetPoint(opposite, arena[i-1], growdir, 0, - dbUnit.Padding)
						end
					end
				end
			end

			Blizzard:Hide("arena")

			module.ToggleUnit("Arenatarget")
			module.ToggleUnit("Arenapet")
		else
			if dbUnit.UseBlizzard == true then
				Blizzard:Show("arena")
				if not GetCVarBool("showArenaEnemyFrames") then
					print("Notice: Blizzard's Arena frames are disabled under the Unit Frames section of your Interface options")
				end
			else
				Blizzard:Hide("arena")
			end

			if oUF_LUI_arena then
				oUF_LUI_arena:Hide()
				for i = 1, 5 do
					if _G["oUF_LUI_arena"..i] then _G["oUF_LUI_arena"..i]:Disable() end
				end
			end

			module.ToggleUnit("Arenatarget", false)
			module.ToggleUnit("Arenapet", false)
		end
	end,

	Arenatarget = function(override)
		local dbUnit = module.db.profile.arenatarget
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(dbUnit.Point, _G["oUF_LUI_arena"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(dbUnit.Point, _G["oUF_LUI_arena"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					_G["oUF_LUI_arenatarget"..i]:SetParent(_G["oUF_LUI_arena"..i])
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then _G["oUF_LUI_arenatarget"..i]:Disable() end
			end
		end
	end,

	Arenapet = function(override)
		local dbUnit = module.db.profile.arenapet
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(dbUnit.Point, _G["oUF_LUI_arena"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
				else
					oUF:Spawn("arena"..i.."pet", "oUF_LUI_arenapet"..i):SetPoint(dbUnit.Point, _G["oUF_LUI_arena"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					_G["oUF_LUI_arenapet"..i]:SetParent(_G["oUF_LUI_arena"..i])
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then _G["oUF_LUI_arenapet"..i]:Disable() end
			end
		end
	end,

	Maintank = function(override)
		local dbUnit = module.db.profile.maintank
		if override == nil then override = dbUnit.Enable end

		if override then
			local x = dbUnit.X / dbUnit.Scale
			local y = dbUnit.Y / dbUnit.Scale

			local growdir = dbUnit.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_maintank then
				oUF_LUI_maintank:SetScale(dbUnit.Scale)
				oUF_LUI_maintank:ClearAllPoints()
				oUF_LUI_maintank:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				oUF_LUI_maintank:SetAttribute("point", opposite)
				oUF_LUI_maintank:SetAttribute("xOffset", growdir == "LEFT" and - dbUnit.Padding or dbUnit.Padding)
				oUF_LUI_maintank:SetAttribute("yOffset", growdir == "BOTTOM" and - dbUnit.Padding or dbUnit.Padding)
				oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "maintanktargettarget" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
						self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
					elseif unit == "maintanktarget" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
						self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
					elseif unit == "maintank" then
						self:SetHeight(]]..dbUnit.Height..[[)
						self:SetWidth(]]..dbUnit.Width..[[)
					end
				]])
				oUF_LUI_maintank:Show()

				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then
						_G["oUF_LUI_maintankUnitButton"..i]:Enable()
						_G["oUF_LUI_maintankUnitButton"..i]:ClearAllPoints()
						_G["oUF_LUI_maintankUnitButton"..i]:UpdateAllElements('refreshUnit')
					end
				end
			else
				local tank = oUF:SpawnHeader("oUF_LUI_maintank", nil, nil,
					"showRaid", true,
					"groupFilter", "MAINTANK",
					"template", "oUF_LUI_maintank",
					"showPlayer", true,
					"unitsPerColumn", 4,
					"point", opposite,
					"xOffset", growdir == "LEFT" and - dbUnit.Padding or dbUnit.Padding,
					"yOffset", growdir == "BOTTOM" and - dbUnit.Padding or dbUnit.Padding,
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "maintanktargettarget" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
							self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
						elseif unit == "maintanktarget" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
							self:SetPoint("]]..dbUnit.Point..[[", self:GetParent(), "]]..dbUnit.RelativePoint..[[", ]]..dbUnit.X..[[, ]]..dbUnit.Y..[[)
						elseif unit == "maintank" then
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
						end
					]]
				)

				tank:SetScale(dbUnit.Scale)
				tank:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, x, y)
				tank:Show()
			end

			module.ToggleUnit("Maintanktarget")
		else
			if oUF_LUI_maintank then
				oUF_LUI_maintank:Hide()
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then _G["oUF_LUI_maintankUnitButton"..i]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
				end
			end

			module.ToggleUnit("Maintanktarget", false)
		end
	end,

	Maintanktarget = function(override)
		local dbUnit = module.db.profile.maintanktarget
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(dbUnit.Point, _G["oUF_LUI_maintankUnitButton"..i], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:UpdateAllElements('refreshUnit')
				end
			end

			module.ToggleUnit("Maintanktargettarget")
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
			end

			module.ToggleUnit("Maintanktargettarget", false)
		end
	end,

	Maintanktargettarget = function(override)
		local dbUnit = module.db.profile.maintanktargettarget
		if override == nil then override = dbUnit.Enable end

		if override and dbUnit.Enable and dbUnit.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(dbUnit.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], dbUnit.RelativePoint, dbUnit.X, dbUnit.Y)
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:UpdateAllElements('refreshUnit')
				end
			end
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
			end
		end
	end,

	raid = function(override)
		local dbUnit = module.db.profile.raid
		if override == nil then override = dbUnit.Enable end

		if override then
			if IsAddOnLoaded("Plexus") or IsAddOnLoaded("Grid2") or IsAddOnLoaded("VuhDo") or IsAddOnLoaded("Healbot") then
				return
			end
			if oUF_LUI_raid then
				for i = 1, 5 do
					if i ~= 1 then
						_G["oUF_LUI_raid_25_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_25_"..i-1], "TOPRIGHT", dbUnit.GroupPadding, 0)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("yOffset", - dbUnit.Padding)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
						]])
					end
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then
							frame:Enable()
							frame:UpdateAllElements('refreshUnit')
						end
					end
				end

				local width40 = (5 * dbUnit.Width - 3 * dbUnit.GroupPadding) / 8

				for i = 1, 8 do
					if i ~= 1 then
						_G["oUF_LUI_raid_40_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_40_"..i-1], "TOPRIGHT", dbUnit.GroupPadding, 0)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("yOffset", - dbUnit.Padding)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..width40..[[)
						]])
					end
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then
							frame:Enable()
							frame:UpdateAllElements('refreshUnit')
						end
					end
				end

				oUF_LUI_raid:ClearAllPoints()
				oUF_LUI_raid:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, dbUnit.X, dbUnit.Y)
				oUF_LUI_raid:Show()

				RegisterStateDriver(oUF_LUI_raid_25, "visibility", "[@raid26,exists] hide; show")
				RegisterStateDriver(oUF_LUI_raid_40, "visibility", "[@raid26,exists] show; hide")
			else
				local raidAnchor = CreateFrame("Frame", "oUF_LUI_raid", UIParent)
				raidAnchor:SetWidth(dbUnit.Width * 5 + dbUnit.GroupPadding * 4)
				raidAnchor:SetHeight(dbUnit.Height * 5 + dbUnit.Padding * 4)
				raidAnchor:SetPoint(dbUnit.Point, UIParent, dbUnit.Point, dbUnit.X, dbUnit.Y)

				local raid25 = CreateFrame("Frame", "oUF_LUI_raid_25", raidAnchor, "SecureHandlerStateTemplate")
				raid25:SetWidth(1)
				raid25:SetHeight(1)
				raid25:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				RegisterStateDriver(raid25, "visibility", "[@raid26,exists] hide; show")
				local raid25table = {}
				for i = 1, 5 do
					raid25table[i] = oUF:SpawnHeader("oUF_LUI_raid_25_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - dbUnit.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..dbUnit.Width..[[)
						]]
					)
					raid25table[i]:SetParent(raid25)
					raid25table[i]:Show()
					if i == 1 then
						raid25table[i]:SetPoint("TOPLEFT", raid25, "TOPLEFT", 0, 0)
					else
						raid25table[i]:SetPoint("TOPLEFT", raid25table[i-1], "TOPRIGHT", dbUnit.GroupPadding, 0)
					end
				end

				local raid40 = CreateFrame("Frame", "oUF_LUI_raid_40", raidAnchor, "SecureHandlerStateTemplate")
				raid40:SetWidth(1)
				raid40:SetHeight(1)
				raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				RegisterStateDriver(raid40, "visibility", "[@raid26,exists] show; hide")

				local width40 = (5 * dbUnit.Width - 3 * dbUnit.GroupPadding) / 8

				local raid40table = {}
				for i = 1, 8 do
					raid40table[i] = oUF:SpawnHeader("oUF_LUI_raid_40_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - dbUnit.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..dbUnit.Height..[[)
							self:SetWidth(]]..width40..[[)
						]]
					)
					raid40table[i]:SetParent(raid40)
					raid40table[i]:Show()
					if i == 1 then
						raid40table[i]:SetPoint("TOPLEFT", raid40, "TOPLEFT", 0, 0)
					else
						raid40table[i]:SetPoint("TOPLEFT", raid40table[i-1], "TOPRIGHT", dbUnit.GroupPadding, 0)
					end
				end
			end

			Blizzard:Hide("raid")
		else
			if dbUnit.UseBlizzard == true then
				Blizzard:Show("raid")
			else
				Blizzard:Hide("raid")
			end

			if oUF_LUI_raid then
				for i = 1, 5 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then frame:Disable() end
					end
				end

				for i = 1, 8 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then frame:Disable() end
					end
				end

				if oUF_LUI_raid_25 then
					UnregisterStateDriver(oUF_LUI_raid_25, "visibility")
					oUF_LUI_raid_25:Hide()
				end
				if oUF_LUI_raid_40 then
					UnregisterStateDriver(oUF_LUI_raid_40, "visibility")
					oUF_LUI_raid_40:Hide()
				end

				oUF_LUI_raid:Hide()
			end
		end
	end,
}, ToggleMT)

module.ApplySettings = function(unit)
	local dbUnit = module.db.profile[unit]
	if dbUnit.Enable == false then return end

	for _, framename in pairs(module.framelist[unit]) do
		local frame = _G[framename]
		--print(string.format("Updating: _ = %s, framename = %s, frame = %s", tostring(_), tostring(framename), tostring(frame)))

		if frame then
			if framename:find("oUF_LUI_raid_40") then
				frame:SetWidth((dbUnit.Width * 5 - dbUnit.GroupPadding * 3) / 8)
			else
				frame:SetWidth(dbUnit.Width)
			end
			frame:SetHeight(dbUnit.Height)

			-- bars
			module.funcs.Health(frame, frame.__unit, dbUnit)
			module.funcs.Power(frame, frame.__unit, dbUnit)
			module.funcs.FrameBackdrop(frame, frame.__unit, dbUnit)

			-- texts
			if unit == "raid" then
				module.funcs.RaidInfo(frame, frame.__unit, dbUnit)
			else
				module.funcs.Info(frame, frame.__unit, dbUnit)
			end

			module.funcs.HealthValue(frame, frame.__unit, dbUnit)
			module.funcs.HealthPercent(frame, frame.__unit, dbUnit)
			module.funcs.HealthMissing(frame, frame.__unit, dbUnit)

			module.funcs.PowerValue(frame, frame.__unit, dbUnit)
			module.funcs.PowerPercent(frame, frame.__unit, dbUnit)
			module.funcs.PowerMissing(frame, frame.__unit, dbUnit)

			-- icons
			if dbUnit.Indicators then
				for key, icons in pairs(iconlist) do
					if dbUnit.Indicators[key] then
						if dbUnit.Indicators[key].Enable then
							module.funcs[icons[1]](frame, frame.__unit, dbUnit)
							frame:EnableElement(icons[1])
							if icons[2] then frame:EnableElement(icons[2]) end
						else
							if frame[icons[1]] then
								for _, icon in pairs(icons) do
									frame:DisableElement(icon)
								end
							end
						end
					end
				end
			end

			-- player specific
			if unit == "player" then

				-- runes
				if LUI.DEATHKNIGHT then
					module.funcs.Runes(frame, frame.__unit, module.db.profile.player)
					if dbUnit.RunesBar.Enable then
						frame:EnableElement("Runes")
					else
						frame:DisableElement("Runes")
						frame.Runes:Hide()
					end
				end

				-- ClassPower
				if LUI.PALADIN or LUI.WARLOCK or LUI.MONK or LUI.ROGUE then
					module.funcs.ClassPower(frame, frame.__unit, module.db.profile.player)
					if dbUnit.ClassPowerBar.Enable then
						frame:EnableElement("ClassPower")
					else
						frame:DisableElement("ClassPower")
						frame.ClassPower:Hide()
					end
				end

				-- Additional Power
				if LUI.DRUID or LUI.PRIEST or LUI.SHAMAN then
					module.funcs.AdditionalPower(frame, frame.__unit, module.db.profile.player)
					if dbUnit.AdditionalPowerBar.Enable then
						frame:EnableElement("AdditionalPower")
					else
						frame:DisableElement("AdditionalPower")
						frame.AdditionalPower.SetPosition()
					end
				end
			end

			-- portrait
			if dbUnit.Portrait and dbUnit.Portrait.Enable then
				module.funcs.Portrait(frame, frame.__unit, dbUnit)
				frame:EnableElement("Portrait")
				frame.Portrait:Show()
			else
				if frame.Portrait then
					frame:DisableElement("Portrait")
					frame.Portrait:Hide()
				end
			end

			-- alt power
			if unit == "player" or unit == "pet" then
				if module.db.profile.player.AlternativePowerBar.Enable then
					module.funcs.AlternativePower(frame, frame.__unit, dbUnit)
					frame:EnableElement("AlternativePower")
					frame.AlternativePower.SetPosition()
				else
					if frame.AlternativePower then
						frame:DisableElement("AlternativePower")
						frame.AlternativePower.SetPosition()
					end
				end
			end

			-- auras
			if dbUnit.Aura then
				if dbUnit.Aura.Buffs.Enable then
					module.funcs.Buffs(frame, frame.__unit, dbUnit)
				else
					if frame.Buffs then frame.Buffs:Hide() end
				end

				if dbUnit.Aura.Debuffs.Enable then
					module.funcs.Debuffs(frame, frame.__unit, dbUnit)
				else
					if frame.Debuffs then frame.Debuffs:Hide() end
				end

				if dbUnit.Aura.Buffs.Enable or dbUnit.Aura.Debuffs.Enable then
					frame:EnableElement("Auras")
				else
					frame:DisableElement("Auras")
				end
			end

			-- combat feedback text
			if dbUnit.CombatFeedback then module.funcs.CombatFeedbackText(frame, frame.__unit, dbUnit) end

			-- castbar
			if dbUnit.Castbar and module:UnitSupportsCastbar(unit) then
				if dbUnit.Castbar.General.Enable then
					module.funcs.Castbar(frame, frame.__unit, dbUnit)
					frame:EnableElement("Castbar")
				else
					frame:DisableElement("Castbar")
				end
			end

			-- aggro glow
			if dbUnit.Border.Aggro then
				module.funcs.AggroGlow(frame, frame.__unit, dbUnit)
				frame:EnableElement("Threat")
			else
				frame:DisableElement("Threat")
			end

			-- heal prediction
			if dbUnit.HealthPrediction then
				if dbUnit.HealthPrediction.Enable then
					module.funcs.HealthPrediction(frame, frame.__unit, dbUnit)
					frame:EnableElement("HealthPrediction")
				else
					frame:DisableElement("HealthPrediction")
				end
			end

			if unit == "targettarget" or unit == "targettargettarget" or unit == "focustarget" or unit == "focus" then
				if not frame.V2Tex then
					if unit == "targettarget" then
						module.funcs.V2Textures(frame, oUF_LUI_target)
					elseif unit == "targettargettarget" then
						module.funcs.V2Textures(frame, oUF_LUI_targettarget)
					elseif unit == "focustarget" then
						module.funcs.V2Textures(frame, oUF_LUI_focus)
					elseif unit == "focus" then
						module.funcs.V2Textures(frame, oUF_LUI_player)
					end
				end
				frame.V2Tex:Reposition()
				if module.db.profile.Settings.ShowV2Textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "partytarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_partyUnitButton"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.profile.Settings.ShowV2PartyTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "Arenatarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_arena"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.profile.Settings.ShowV2ArenaTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "bosstarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_boss"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.profile.Settings.ShowV2BossTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			end

			-- -- fader
			if dbUnit.Fader then
				if dbUnit.Fader.Enable then
					Fader:RegisterFrame(frame, dbUnit.Fader)
				else
					Fader:UnregisterFrame(frame)
				end
			end

			LUI.Profiler.TraceScope(frame, unit, "Unitframes", 2)
			frame:UpdateAllElements('refreshUnit')
		end
	end
end
