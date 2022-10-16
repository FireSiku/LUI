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

module.ToggleUnit = setmetatable({
	Default = function(override, unit)
		local x = module.db[unit].X / module.db[unit].Scale
		local y = module.db[unit].Y / module.db[unit].Scale

		if override == nil then override = module.db[unit].Enable end

		if override then
			if _G["oUF_LUI_"..unit] then
				_G["oUF_LUI_"..unit]:Enable()
				_G["oUF_LUI_"..unit]:UpdateAllElements('refreshUnit')
				_G["oUF_LUI_"..unit]:ClearAllPoints()
				_G["oUF_LUI_"..unit]:SetScale(module.db[unit].Scale)
				_G["oUF_LUI_"..unit]:SetPoint(module.db[unit].Point, UIParent, module.db[unit].Point, x, y)
			else
				local f = oUF:Spawn(unit, "oUF_LUI_"..unit)
				f:SetScale(module.db[unit].Scale)
				f:SetPoint(module.db[unit].Point, UIParent, module.db[unit].Point, x, y)
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
		if override == nil then override = module.db.boss.Enable end

		if override then
			local x = module.db.boss.X / module.db.boss.Scale
			local y = module.db.boss.Y / module.db.boss.Scale

			local growdir = module.db.boss.GrowDirection
			local opposite = GetOpposite(growdir)

			Blizzard:Hide("boss")

			if oUF_LUI_boss then
				oUF_LUI_boss:SetScale(module.db.boss.Scale)
				oUF_LUI_boss:ClearAllPoints()
				oUF_LUI_boss:SetPoint(module.db.boss.Point, UIParent, module.db.boss.Point, x, y)
				oUF_LUI_boss:SetWidth(module.db.boss.Width)
				oUF_LUI_boss:SetHeight(module.db.boss.Height)
				oUF_LUI_boss:SetAttribute("Height", module.db.boss.Height)
				oUF_LUI_boss:SetAttribute("Padding", module.db.boss.Padding)
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
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, - module.db.boss.Padding, 0)
						elseif growdir == "RIGHT" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, module.db.boss.Padding, 0)
						elseif growdir == "TOP" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, module.db.boss.Padding)
						else
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, - module.db.boss.Padding)
						end
					end
				end
			else
				local bossParent = CreateFrame("Frame", "oUF_LUI_boss", UIParent)
				bossParent:SetScale(module.db.boss.Scale)
				bossParent:SetPoint(module.db.boss.Point, UIParent, module.db.boss.Point, x, y)
				bossParent:SetWidth(module.db.boss.Width)
				bossParent:SetHeight(module.db.boss.Height)
				bossParent:SetAttribute("Height", module.db.boss.Height)
				bossParent:SetAttribute("Padding", module.db.boss.Padding)
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
							boss[i]:SetPoint(opposite, boss[i-1], growdir, - module.db.boss.Padding, 0)
						elseif growdir == "RIGHT" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, module.db.boss.Padding, 0)
						elseif growdir == "TOP" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, module.db.boss.Padding)
						else
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, - module.db.boss.Padding)
						end
					end
				end
			end

			module.ToggleUnit("bosstarget")
		else
			if module.db.boss.UseBlizzard then
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
		if override == nil then override = module.db.bosstarget.Enable end

		if override and module.db.boss.Enable then
			if _G.oUF_LUI_bosstarget1 then
				for i = 1, MAX_BOSS_FRAMES do
					if _G["oUF_LUI_bosstarget"..i] then
						_G["oUF_LUI_bosstarget"..i]:Enable()
						_G["oUF_LUI_bosstarget"..i]:ClearAllPoints()
						_G["oUF_LUI_bosstarget"..i]:SetPoint(module.db.bosstarget.Point, _G["oUF_LUI_boss"..i], module.db.bosstarget.RelativePoint, module.db.bosstarget.X, module.db.bosstarget.Y)
					end
				end
			else
				for i = 1, MAX_BOSS_FRAMES do
					oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i):SetPoint(module.db.bosstarget.Point, _G["oUF_LUI_boss"..i], module.db.bosstarget.RelativePoint, module.db.bosstarget.X, module.db.bosstarget.Y)
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
		if override == nil then override = module.db.party.Enable end

		if override then
			local x = module.db.party.X / module.db.party.Scale
			local y = module.db.party.Y / module.db.party.Scale

			local growdir = module.db.party.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_party then
				oUF_LUI_party:SetScale(module.db.party.Scale)
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint(module.db.party.Point, UIParent, module.db.party.Point, x, y)
				oUF_LUI_party:SetAttribute("point", opposite)
				oUF_LUI_party:SetAttribute("xOffset", growdir == "LEFT" and - module.db.party.Padding or module.db.party.Padding)
				oUF_LUI_party:SetAttribute("yOffset", growdir == "BOTTOM" and - module.db.party.Padding or module.db.party.Padding)
				oUF_LUI_party:SetAttribute("showPlayer", module.db.party.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..module.db.party.Height..[[)
						self:SetWidth(]]..module.db.party.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..module.db.partytarget.Height..[[)
						self:SetWidth(]]..module.db.partytarget.Width..[[)
						self:SetPoint("]]..module.db.partytarget.Point..[[", self:GetParent(), "]]..module.db.partytarget.RelativePoint..[[", ]]..module.db.partytarget.X..[[, ]]..module.db.partytarget.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..module.db.partypet.Height..[[)
						self:SetWidth(]]..module.db.partypet.Width..[[)
						self:SetPoint("]]..module.db.partypet.Point..[[", self:GetParent(), "]]..module.db.partypet.RelativePoint..[[", ]]..module.db.partypet.X..[[, ]]..module.db.partypet.Y..[[)
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
					"showPlayer", module.db.party.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"point", opposite,
					"xOffset", growdir == "LEFT" and - module.db.party.Padding or module.db.party.Padding,
					"yOffset", growdir == "BOTTOM" and - module.db.party.Padding or module.db.party.Padding,
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..module.db.party.Height..[[)
							self:SetWidth(]]..module.db.party.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..module.db.partytarget.Height..[[)
							self:SetWidth(]]..module.db.partytarget.Width..[[)
							self:SetPoint("]]..module.db.partytarget.Point..[[", self:GetParent(), "]]..module.db.partytarget.RelativePoint..[[", ]]..module.db.partytarget.X..[[, ]]..module.db.partytarget.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..module.db.partypet.Height..[[)
							self:SetWidth(]]..module.db.partypet.Width..[[)
							self:SetPoint("]]..module.db.partypet.Point..[[", self:GetParent(), "]]..module.db.partypet.RelativePoint..[[", ]]..module.db.partypet.X..[[, ]]..module.db.partypet.Y..[[)
						end
					]]
				)

				party:SetScale(module.db.party.Scale)
				party:SetPoint(module.db.party.Point, UIParent, module.db.party.Point, x, y)

				local handler = CreateFrame("Frame")
				handler:RegisterEvent("PLAYER_ENTERING_WORLD")
				handler:RegisterEvent("GROUP_ROSTER_UPDATE")
				handler:SetScript("OnEvent", function(self, event)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
						return
					end

					self:UnregisterEvent("PLAYER_REGEN_ENABLED")

					if module.db.party.Enable then
						if module.db.party.ShowInRaid then
							party:Show()
						else
							if not IsInRaid() then
								party:Show()
							else
								-- GetNumGroupMembers() - total number of players in the group (either party or raid), 0 if not in a group. 
								-- GetNumSubgroupMembers() - number of players in the player's sub-group, excluding the player. 
								local numraid = GetNumGroupMembers()
								local numparty = GetNumSubgroupMembers()
								if module.db.party.ShowInRealParty then
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
			if module.db.party.UseBlizzard then
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
		if override == nil then override = module.db.partytarget.Enable end

		if override and module.db.party.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(module.db.partytarget.Point, _G["oUF_LUI_partyUnitButton"..i], module.db.partytarget.RelativePoint, module.db.partytarget.X, module.db.partytarget.Y)
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,

	partypet = function(override)
		if override == nil then override = module.db.partypet.Enable end

		if override and module.db.party.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:SetPoint(module.db.partypet.Point, _G["oUF_LUI_partyUnitButton"..i], module.db.partypet.RelativePoint, module.db.partypet.X, module.db.partypet.Y)
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then _G["oUF_LUI_partyUnitButton"..i.."pet"]:Disable() end
			end
		end
	end,

	Arena = function(override)
		if override == nil then override = module.db.Arena.Enable end

		if override then
			local x = module.db.Arena.X / module.db.Arena.Scale
			local y = module.db.Arena.Y / module.db.Arena.Scale

			local growdir = module.db.Arena.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_arena then
				oUF_LUI_arena:SetScale(module.db.Arena.Scale)
				oUF_LUI_arena:ClearAllPoints()
				oUF_LUI_arena:SetPoint(module.db.Arena.Point, UIParent, module.db.Arena.Point, x, y)
				oUF_LUI_arena:SetWidth(module.db.Arena.Width)
				oUF_LUI_arena:SetHeight(module.db.Arena.Height)
				oUF_LUI_arena:SetAttribute("Height", module.db.Arena.Height)
				oUF_LUI_arena:SetAttribute("Padding", module.db.Arena.Padding)
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
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, - module.db.Arena.Padding, 0)
						elseif growdir == "RIGHT" then
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, module.db.Arena.Padding, 0)
						elseif growdir == "TOP" then
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, 0, module.db.Arena.Padding)
						else
							_G["oUF_LUI_arena"..i]:SetPoint(opposite, _G["oUF_LUI_arena"..i-1], growdir, 0, - module.db.Arena.Padding)
						end
					end
				end
			else
				-- oUF kills it, we save it!
				-- Should be handled fine by the new hideblizzard tool
				-- Arena_LoadUI_ = ArenaLoadUI

				local arenaParent = CreateFrame("Frame", "oUF_LUI_arena", UIParent)
				arenaParent:SetScale(module.db.Arena.Scale)
				arenaParent:SetPoint(module.db.Arena.Point, UIParent, module.db.Arena.Point, x, y)
				arenaParent:SetWidth(module.db.Arena.Width)
				arenaParent:SetHeight(module.db.Arena.Height)
				arenaParent:SetAttribute("Height", module.db.Arena.Height)
				arenaParent:SetAttribute("Padding", module.db.Arena.Padding)
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
							arena[i]:SetPoint(opposite, arena[i-1], growdir, - module.db.Arena.Padding, 0)
						elseif growdir == "RIGHT" then
							arena[i]:SetPoint(opposite, arena[i-1], growdir, module.db.Arena.Padding, 0)
						elseif growdir == "TOP" then
							arena[i]:SetPoint(opposite, arena[i-1], growdir, 0, module.db.Arena.Padding)
						else
							arena[i]:SetPoint(opposite, arena[i-1], growdir, 0, - module.db.Arena.Padding)
						end
					end
				end
			end

			Blizzard:Hide("arena")

			module.ToggleUnit("Arenatarget")
			module.ToggleUnit("Arenapet")
		else
			if module.db.Arena.UseBlizzard == true then
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
		if override == nil then override = module.db.Arenatarget.Enable end

		if override and module.db.Arena.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(module.db.Arenatarget.Point, _G["oUF_LUI_arena"..i], module.db.Arenatarget.RelativePoint, module.db.Arenatarget.X, module.db.Arenatarget.Y)
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(module.db.Arenatarget.Point, _G["oUF_LUI_arena"..i], module.db.Arenatarget.RelativePoint, module.db.Arenatarget.X, module.db.Arenatarget.Y)
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
		if override == nil then override = module.db.Arenapet.Enable end

		if override and module.db.Arena.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements('refreshUnit')
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(module.db.Arenapet.Point, _G["oUF_LUI_arena"..i], module.db.Arenapet.RelativePoint, module.db.Arenapet.X, module.db.Arenapet.Y)
				else
					oUF:Spawn("arena"..i.."pet", "oUF_LUI_arenapet"..i):SetPoint(module.db.Arenapet.Point, _G["oUF_LUI_arena"..i], module.db.Arenapet.RelativePoint, module.db.Arenapet.X, module.db.Arenapet.Y)
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
		if override == nil then override = module.db.Maintank.Enable end

		if override then
			local x = module.db.Maintank.X / module.db.Maintank.Scale
			local y = module.db.Maintank.Y / module.db.Maintank.Scale

			local growdir = module.db.Maintank.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_maintank then
				oUF_LUI_maintank:SetScale(module.db.Maintank.Scale)
				oUF_LUI_maintank:ClearAllPoints()
				oUF_LUI_maintank:SetPoint(module.db.Maintank.Point, UIParent, module.db.Maintank.Point, x, y)
				oUF_LUI_maintank:SetAttribute("point", opposite)
				oUF_LUI_maintank:SetAttribute("xOffset", growdir == "LEFT" and - module.db.Maintank.Padding or module.db.Maintank.Padding)
				oUF_LUI_maintank:SetAttribute("yOffset", growdir == "BOTTOM" and - module.db.Maintank.Padding or module.db.Maintank.Padding)
				oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "maintanktargettarget" then
						self:SetHeight(]]..module.db.Maintanktargettarget.Height..[[)
						self:SetWidth(]]..module.db.Maintanktargettarget.Width..[[)
						self:SetPoint("]]..module.db.Maintanktargettarget.Point..[[", self:GetParent(), "]]..module.db.Maintanktargettarget.RelativePoint..[[", ]]..module.db.Maintanktargettarget.X..[[, ]]..module.db.Maintanktargettarget.Y..[[)
					elseif unit == "maintanktarget" then
						self:SetHeight(]]..module.db.Maintanktarget.Height..[[)
						self:SetWidth(]]..module.db.Maintanktarget.Width..[[)
						self:SetPoint("]]..module.db.Maintanktarget.Point..[[", self:GetParent(), "]]..module.db.Maintanktarget.RelativePoint..[[", ]]..module.db.Maintanktarget.X..[[, ]]..module.db.Maintanktarget.Y..[[)
					elseif unit == "maintank" then
						self:SetHeight(]]..module.db.Maintank.Height..[[)
						self:SetWidth(]]..module.db.Maintank.Width..[[)
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
					"xOffset", growdir == "LEFT" and - module.db.Maintank.Padding or module.db.Maintank.Padding,
					"yOffset", growdir == "BOTTOM" and - module.db.Maintank.Padding or module.db.Maintank.Padding,
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "maintanktargettarget" then
							self:SetHeight(]]..module.db.Maintanktargettarget.Height..[[)
							self:SetWidth(]]..module.db.Maintanktargettarget.Width..[[)
							self:SetPoint("]]..module.db.Maintanktargettarget.Point..[[", self:GetParent(), "]]..module.db.Maintanktargettarget.RelativePoint..[[", ]]..module.db.Maintanktargettarget.X..[[, ]]..module.db.Maintanktargettarget.Y..[[)
						elseif unit == "maintanktarget" then
							self:SetHeight(]]..module.db.Maintanktarget.Height..[[)
							self:SetWidth(]]..module.db.Maintanktarget.Width..[[)
							self:SetPoint("]]..module.db.Maintanktarget.Point..[[", self:GetParent(), "]]..module.db.Maintanktarget.RelativePoint..[[", ]]..module.db.Maintanktarget.X..[[, ]]..module.db.Maintanktarget.Y..[[)
						elseif unit == "maintank" then
							self:SetHeight(]]..module.db.Maintank.Height..[[)
							self:SetWidth(]]..module.db.Maintank.Width..[[)
						end
					]]
				)

				tank:SetScale(module.db.Maintank.Scale)
				tank:SetPoint(module.db.Maintank.Point, UIParent, module.db.Maintank.Point, x, y)
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
		if override == nil then override = module.db.Maintanktarget.Enable end

		if override and module.db.Maintank.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(module.db.Maintanktarget.Point, _G["oUF_LUI_maintankUnitButton"..i], module.db.Maintanktarget.RelativePoint, module.db.Maintanktarget.X, module.db.Maintanktarget.Y)
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
		if override == nil then override = module.db.Maintanktargettarget.Enable end

		if override and module.db.Maintanktarget.Enable and module.db.Maintank.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(module.db.Maintanktargettarget.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], module.db.Maintanktargettarget.RelativePoint, module.db.Maintanktargettarget.X, module.db.Maintanktargettarget.Y)
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
		if override == nil then override = module.db.raid.Enable end

		if override then
			if IsAddOnLoaded("Plexus") or IsAddOnLoaded("Grid2") or IsAddOnLoaded("VuhDo") or IsAddOnLoaded("Healbot") then
				return
			end
			if oUF_LUI_raid then
				for i = 1, 5 do
					if i ~= 1 then
						_G["oUF_LUI_raid_25_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_25_"..i-1], "TOPRIGHT", module.db.raid.GroupPadding, 0)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("yOffset", - module.db.raid.Padding)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.raid.Height..[[)
							self:SetWidth(]]..module.db.raid.Width..[[)
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

				local width40 = (5 * module.db.raid.Width - 3 * module.db.raid.GroupPadding) / 8

				for i = 1, 8 do
					if i ~= 1 then
						_G["oUF_LUI_raid_40_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_40_"..i-1], "TOPRIGHT", module.db.raid.GroupPadding, 0)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("yOffset", - module.db.raid.Padding)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.raid.Height..[[)
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
				oUF_LUI_raid:SetPoint(module.db.raid.Point, UIParent, module.db.raid.Point, module.db.raid.X, module.db.raid.Y)
				oUF_LUI_raid:Show()

				RegisterStateDriver(oUF_LUI_raid_25, "visibility", "[@raid26,exists] hide; show")
				RegisterStateDriver(oUF_LUI_raid_40, "visibility", "[@raid26,exists] show; hide")
			else
				local raidAnchor = CreateFrame("Frame", "oUF_LUI_raid", UIParent)
				raidAnchor:SetWidth(module.db.raid.Width * 5 + module.db.raid.GroupPadding * 4)
				raidAnchor:SetHeight(module.db.raid.Height * 5 + module.db.raid.Padding * 4)
				raidAnchor:SetPoint(module.db.raid.Point, UIParent, module.db.raid.Point, module.db.raid.X, module.db.raid.Y)

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
						"yOffset", - module.db.raid.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.raid.Height..[[)
							self:SetWidth(]]..module.db.raid.Width..[[)
						]]
					)
					raid25table[i]:SetParent(raid25)
					raid25table[i]:Show()
					if i == 1 then
						raid25table[i]:SetPoint("TOPLEFT", raid25, "TOPLEFT", 0, 0)
					else
						raid25table[i]:SetPoint("TOPLEFT", raid25table[i-1], "TOPRIGHT", module.db.raid.GroupPadding, 0)
					end
				end

				local raid40 = CreateFrame("Frame", "oUF_LUI_raid_40", raidAnchor, "SecureHandlerStateTemplate")
				raid40:SetWidth(1)
				raid40:SetHeight(1)
				raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				RegisterStateDriver(raid40, "visibility", "[@raid26,exists] show; hide")

				local width40 = (5 * module.db.raid.Width - 3 * module.db.raid.GroupPadding) / 8

				local raid40table = {}
				for i = 1, 8 do
					raid40table[i] = oUF:SpawnHeader("oUF_LUI_raid_40_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - module.db.raid.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.raid.Height..[[)
							self:SetWidth(]]..width40..[[)
						]]
					)
					raid40table[i]:SetParent(raid40)
					raid40table[i]:Show()
					if i == 1 then
						raid40table[i]:SetPoint("TOPLEFT", raid40, "TOPLEFT", 0, 0)
					else
						raid40table[i]:SetPoint("TOPLEFT", raid40table[i-1], "TOPRIGHT", module.db.raid.GroupPadding, 0)
					end
				end
			end

			Blizzard:Hide("raid")
		else
			if module.db.raid.UseBlizzard == true then
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
	if module.db[unit].Enable == false then return end

	for _, framename in pairs(module.framelist[unit]) do
		local frame = _G[framename]
		--print(string.format("Updating: _ = %s, framename = %s, frame = %s", tostring(_), tostring(framename), tostring(frame)))

		if frame then
			if framename:find("oUF_LUI_raid_40") then
				frame:SetWidth((module.db[unit].Width * 5 - module.db[unit].GroupPadding * 3) / 8)
			else
				frame:SetWidth(module.db[unit].Width)
			end
			frame:SetHeight(module.db[unit].Height)

			-- bars
			module.funcs.Health(frame, frame.__unit, module.db[unit])
			module.funcs.Power(frame, frame.__unit, module.db[unit])
			module.funcs.FrameBackdrop(frame, frame.__unit, module.db[unit])

			-- texts
			if unit == "raid" then
				module.funcs.RaidInfo(frame, frame.__unit, module.db[unit])
			else
				module.funcs.Info(frame, frame.__unit, module.db[unit])
			end

			module.funcs.HealthValue(frame, frame.__unit, module.db[unit])
			module.funcs.HealthPercent(frame, frame.__unit, module.db[unit])
			module.funcs.HealthMissing(frame, frame.__unit, module.db[unit])

			module.funcs.PowerValue(frame, frame.__unit, module.db[unit])
			module.funcs.PowerPercent(frame, frame.__unit, module.db[unit])
			module.funcs.PowerMissing(frame, frame.__unit, module.db[unit])

			-- icons
			if module.db[unit].Indicators then
				for key, icons in pairs(iconlist) do
					if module.db[unit].Indicators[key] then
						if module.db[unit].Indicators[key].Enable then
							module.funcs[icons[1]](frame, frame.__unit, module.db[unit])
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
					module.funcs.Runes(frame, frame.__unit, module.db.player)
					if module.db[unit].Bars.Runes.Enable then
						frame:EnableElement("Runes")
					else
						frame:DisableElement("Runes")
						frame.Runes:Hide()
					end
				end

				-- ClassPower
				if LUI.PALADIN or LUI.WARLOCK or LUI.MONK or LUI.ROGUE then
					module.funcs.ClassPower(frame, frame.__unit, module.db.player)
					if module.db[unit].Bars.ClassPower.Enable then
						frame:EnableElement("ClassPower")
					else
						frame:DisableElement("ClassPower")
						frame.ClassPower:Hide()
					end
				end

				-- Additional Power
				if LUI.DRUID or LUI.PRIEST or LUI.SHAMAN then
					module.funcs.AdditionalPower(frame, frame.__unit, module.db.player)
					if module.db[unit].Bars.AdditionalPower.Enable then
						frame:EnableElement("AdditionalPower")
					else
						frame:DisableElement("AdditionalPower")
						frame.AdditionalPower.SetPosition()
					end
				end
			end

			-- portrait
			if module.db[unit].Portrait and module.db[unit].Portrait.Enable then
				module.funcs.Portrait(frame, frame.__unit, module.db[unit])
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
				if module.db.player.Bars.AlternativePower.Enable then
					module.funcs.AlternativePower(frame, frame.__unit, module.db[unit])
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
			if module.db[unit].Aura then
				if module.db[unit].Aura.Buffs.Enable then
					module.funcs.Buffs(frame, frame.__unit, module.db[unit])
				else
					if frame.Buffs then frame.Buffs:Hide() end
				end

				if module.db[unit].Aura.Debuffs.Enable then
					module.funcs.Debuffs(frame, frame.__unit, module.db[unit])
				else
					if frame.Debuffs then frame.Debuffs:Hide() end
				end

				if module.db[unit].Aura.Buffs.Enable or module.db[unit].Aura.Debuffs.Enable then
					frame:EnableElement("Auras")
				else
					frame:DisableElement("Auras")
				end
			end

			-- combat feedback text
			if module.db[unit].Texts.Combat then module.funcs.CombatFeedbackText(frame, frame.__unit, module.db[unit]) end

			-- castbar
			if module.db.Settings.Castbars and module.db[unit].Castbar then
				if module.db[unit].Castbar.General.Enable then
					module.funcs.Castbar(frame, frame.__unit, module.db[unit])
					frame:EnableElement("Castbar")
				else
					frame:DisableElement("Castbar")
				end
			end

			-- aggro glow
			if module.db[unit].Border.Aggro then
				module.funcs.AggroGlow(frame, frame.__unit, module.db[unit])
				frame:EnableElement("Threat")
			else
				frame:DisableElement("Threat")
			end

			-- heal prediction
			if module.db[unit].HealthPrediction then
				if module.db[unit].HealthPrediction.Enable then
					module.funcs.HealthPrediction(frame, frame.__unit, module.db[unit])
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
				if module.db.Settings.ShowV2Textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "partytarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_partyUnitButton"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2PartyTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "Arenatarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_arena"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2ArenaTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "bosstarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_boss"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2BossTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			end

			-- -- fader
			if module.db[unit].Fader then
				if module.db[unit].Fader.Enable then
					Fader:RegisterFrame(frame, module.db[unit].Fader)
				else
					Fader:UnregisterFrame(frame)
				end
			end

			LUI.Profiler.TraceScope(frame, unit, "Unitframes", 2)
			frame:UpdateAllElements('refreshUnit')
		end
	end
end
