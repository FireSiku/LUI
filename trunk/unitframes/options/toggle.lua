--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: toggle.lua
	Description: Toggle Functions
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local Fader = LUI:Module("Fader")

local oUF = LUI.oUF
local Blizzard = LUI.Blizzard
local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES

local _, class = UnitClass("player")

local ufUnits = {
	Player = "player",
	Target = "target",
	ToT = "targettarget",
	ToToT = "targettargettarget",
	Focus = "focus",
	FocusTarget = "focustarget",
	Pet = "pet",
	PetTarget = "pettarget",
}

local iconlist = {
	PvP = {"PvP"},
	Combat = {"Combat"},
	Resting = {"Resting"},
	Lootmaster = {"MasterLooter"},
	Leader = {"Leader", "Assistant"},
	Role = {"LFDRole"},
	Raid = {"RaidIcon"},
	ReadyCheck = {"ReadyCheck"},
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
			if _G["oUF_LUI_"..ufUnits[unit]] then
				_G["oUF_LUI_"..ufUnits[unit]]:Enable()
				_G["oUF_LUI_"..ufUnits[unit]]:UpdateAllElements()
				_G["oUF_LUI_"..ufUnits[unit]]:ClearAllPoints()
				_G["oUF_LUI_"..ufUnits[unit]]:SetScale(module.db[unit].Scale)
				_G["oUF_LUI_"..ufUnits[unit]]:SetPoint(module.db[unit].Point, UIParent, module.db[unit].Point, x, y)
			else
				local f = oUF:Spawn(ufUnits[unit], "oUF_LUI_"..ufUnits[unit])
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

			if _G["oUF_LUI_"..ufUnits[unit]] then _G["oUF_LUI_"..ufUnits[unit]]:Disable() end
		end

		module.ApplySettings(unit)
	end,

	Boss = function(override)
		if override == nil then override = module.db.Boss.Enable end

		if override then
			local x = module.db.Boss.X / module.db.Boss.Scale
			local y = module.db.Boss.Y / module.db.Boss.Scale

			local growdir = module.db.Boss.GrowDirection
			local opposite = GetOpposite(growdir)

			Blizzard:Hide("boss")

			if oUF_LUI_boss then
				oUF_LUI_boss:SetScale(module.db.Boss.Scale)
				oUF_LUI_boss:ClearAllPoints()
				oUF_LUI_boss:SetPoint(module.db.Boss.Point, UIParent, module.db.Boss.Point, x, y)
				oUF_LUI_boss:SetWidth(module.db.Boss.Width)
				oUF_LUI_boss:SetHeight(module.db.Boss.Height)
				oUF_LUI_boss:SetAttribute("Height", module.db.Boss.Height)
				oUF_LUI_boss:SetAttribute("Padding", module.db.Boss.Padding)
				oUF_LUI_boss:Show()

				for i = 1, MAX_BOSS_FRAMES do
					_G["oUF_LUI_boss"..i]:Enable()
					_G["oUF_LUI_boss"..i]:UpdateAllElements()
					_G["oUF_LUI_boss"..i]:ClearAllPoints()
					if i == 1 then
						local point = (growdir == "LEFT" or growdir == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
						_G["oUF_LUI_boss"..i]:SetPoint(point, oUF_LUI_boss, point, 0, 0)
					else
						if growdir == "LEFT" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, - module.db.Boss.Padding, 0)
						elseif growdir == "RIGHT" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, module.db.Boss.Padding, 0)
						elseif growdir == "TOP" then
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, module.db.Boss.Padding)
						else
							_G["oUF_LUI_boss"..i]:SetPoint(opposite, _G["oUF_LUI_boss"..i-1], growdir, 0, - module.db.Boss.Padding)
						end
					end
				end
			else
				local bossParent = CreateFrame("Frame", "oUF_LUI_boss", UIParent)
				bossParent:SetScale(module.db.Boss.Scale)
				bossParent:SetPoint(module.db.Boss.Point, UIParent, module.db.Boss.Point, x, y)
				bossParent:SetWidth(module.db.Boss.Width)
				bossParent:SetHeight(module.db.Boss.Height)
				bossParent:SetAttribute("Height", module.db.Boss.Height)
				bossParent:SetAttribute("Padding", module.db.Boss.Padding)
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
							boss[i]:SetPoint(opposite, boss[i-1], growdir, - module.db.Boss.Padding, 0)
						elseif growdir == "RIGHT" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, module.db.Boss.Padding, 0)
						elseif growdir == "TOP" then
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, module.db.Boss.Padding)
						else
							boss[i]:SetPoint(opposite, boss[i-1], growdir, 0, - module.db.Boss.Padding)
						end
					end
				end
			end

			module.ToggleUnit("BossTarget")
		else
			if module.db.Boss.UseBlizzard then
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

			module.ToggleUnit("BossTarget", false)
		end
	end,

	BossTarget = function(override)
		if override == nil then override = module.db.BossTarget.Enable end

		if override and module.db.Boss.Enable then
			if oUF_LUI_bosstarget1 then
				for i = 1, MAX_BOSS_FRAMES do
					if _G["oUF_LUI_bosstarget"..i] then
						_G["oUF_LUI_bosstarget"..i]:Enable()
						_G["oUF_LUI_bosstarget"..i]:ClearAllPoints()
						_G["oUF_LUI_bosstarget"..i]:SetPoint(module.db.BossTarget.Point, _G["oUF_LUI_boss"..i], module.db.BossTarget.RelativePoint, module.db.BossTarget.X, module.db.BossTarget.Y)
					end
				end
			else
				for i = 1, MAX_BOSS_FRAMES do
					oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i):SetPoint(module.db.BossTarget.Point, _G["oUF_LUI_boss"..i], module.db.BossTarget.RelativePoint, module.db.BossTarget.X, module.db.BossTarget.Y)
					_G["oUF_LUI_bosstarget"..i]:SetParent(_G["oUF_LUI_boss"..i])
				end
			end
		else
			for i = 1, MAX_BOSS_FRAMES do
				if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Disable() end
			end
		end
	end,

	Party = function(override)
		if override == nil then override = module.db.Party.Enable end

		if override then
			local x = module.db.Party.X / module.db.Party.Scale
			local y = module.db.Party.Y / module.db.Party.Scale

			local growdir = module.db.Party.GrowDirection
			local opposite = GetOpposite(growdir)

			if oUF_LUI_party then
				oUF_LUI_party:SetScale(module.db.Party.Scale)
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint(module.db.Party.Point, UIParent, module.db.Party.Point, x, y)
				oUF_LUI_party:SetAttribute("point", opposite)
				oUF_LUI_party:SetAttribute("xOffset", growdir == "LEFT" and - module.db.Party.Padding or module.db.Party.Padding)
				oUF_LUI_party:SetAttribute("yOffset", growdir == "BOTTOM" and - module.db.Party.Padding or module.db.Party.Padding)
				oUF_LUI_party:SetAttribute("showPlayer", module.db.Party.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..module.db.Party.Height..[[)
						self:SetWidth(]]..module.db.Party.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..module.db.PartyTarget.Height..[[)
						self:SetWidth(]]..module.db.PartyTarget.Width..[[)
						self:SetPoint("]]..module.db.PartyTarget.Point..[[", self:GetParent(), "]]..module.db.PartyTarget.RelativePoint..[[", ]]..module.db.PartyTarget.X..[[, ]]..module.db.PartyTarget.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..module.db.PartyPet.Height..[[)
						self:SetWidth(]]..module.db.PartyPet.Width..[[)
						self:SetPoint("]]..module.db.PartyPet.Point..[[", self:GetParent(), "]]..module.db.PartyPet.RelativePoint..[[", ]]..module.db.PartyPet.X..[[, ]]..module.db.PartyPet.Y..[[)
					end
				]])

				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Enable()
						_G["oUF_LUI_partyUnitButton"..i]:UpdateAllElements()
					end
				end
				oUF_LUI_party.handler:GetScript("OnEvent")(oUF_LUI_party.handler)
			else
				local party = oUF:SpawnHeader("oUF_LUI_party", nil, nil,
					"showParty", true,
					"showPlayer", module.db.Party.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"point", opposite,
					"xOffset", growdir == "LEFT" and - module.db.Party.Padding or module.db.Party.Padding,
					"yOffset", growdir == "BOTTOM" and - module.db.Party.Padding or module.db.Party.Padding,
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..module.db.Party.Height..[[)
							self:SetWidth(]]..module.db.Party.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..module.db.PartyTarget.Height..[[)
							self:SetWidth(]]..module.db.PartyTarget.Width..[[)
							self:SetPoint("]]..module.db.PartyTarget.Point..[[", self:GetParent(), "]]..module.db.PartyTarget.RelativePoint..[[", ]]..module.db.PartyTarget.X..[[, ]]..module.db.PartyTarget.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..module.db.PartyPet.Height..[[)
							self:SetWidth(]]..module.db.PartyPet.Width..[[)
							self:SetPoint("]]..module.db.PartyPet.Point..[[", self:GetParent(), "]]..module.db.PartyPet.RelativePoint..[[", ]]..module.db.PartyPet.X..[[, ]]..module.db.PartyPet.Y..[[)
						end
					]]
				)

				party:SetScale(module.db.Party.Scale)
				party:SetPoint(module.db.Party.Point, UIParent, module.db.Party.Point, x, y)

				local handler = CreateFrame("Frame")
				handler:RegisterEvent("PLAYER_ENTERING_WORLD")
				handler:RegisterEvent("GROUP_ROSTER_UPDATE")
				handler:SetScript("OnEvent", function(self, event)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
						return
					end

					self:UnregisterEvent("PLAYER_REGEN_ENABLED")

					if module.db.Party.Enable then
						if module.db.Party.ShowInRaid then
							party:Show()
						else
							if not IsInRaid() then
								party:Show()
							else
								-- GetNumGroupMembers() - total number of players in the group (either party or raid), 0 if not in a group. 
								-- GetNumSubgroupMembers() - number of players in the player's sub-group, excluding the player. 
								local numraid = GetNumGroupMembers()
								local numparty = GetNumSubgroupMembers()
								if module.db.Party.ShowInRealParty then
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

			module.ToggleUnit("PartyTarget")
			module.ToggleUnit("PartyPet")
		else
			if module.db.Party.UseBlizzard then
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

			module.ToggleUnit("PartyTarget", false)
			module.ToggleUnit("PartyPet", false)
		end
	end,

	PartyTarget = function(override)
		if override == nil then override = module.db.PartyTarget.Enable end

		if override and module.db.Party.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(module.db.PartyTarget.Point, _G["oUF_LUI_partyUnitButton"..i], module.db.PartyTarget.RelativePoint, module.db.PartyTarget.X, module.db.PartyTarget.Y)
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,

	PartyPet = function(override)
		if override == nil then override = module.db.PartyPet.Enable end

		if override and module.db.Party.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:SetPoint(module.db.PartyPet.Point, _G["oUF_LUI_partyUnitButton"..i], module.db.PartyPet.RelativePoint, module.db.PartyPet.X, module.db.PartyPet.Y)
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
					_G["oUF_LUI_arena"..i]:UpdateAllElements()
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

			module.ToggleUnit("ArenaTarget")
			module.ToggleUnit("ArenaPet")
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

			module.ToggleUnit("ArenaTarget", false)
			module.ToggleUnit("ArenaPet", false)
		end
	end,

	ArenaTarget = function(override)
		if override == nil then override = module.db.ArenaTarget.Enable end

		if override and module.db.Arena.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements()
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(module.db.ArenaTarget.Point, _G["oUF_LUI_arena"..i], module.db.ArenaTarget.RelativePoint, module.db.ArenaTarget.X, module.db.ArenaTarget.Y)
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(module.db.ArenaTarget.Point, _G["oUF_LUI_arena"..i], module.db.ArenaTarget.RelativePoint, module.db.ArenaTarget.X, module.db.ArenaTarget.Y)
					_G["oUF_LUI_arenatarget"..i]:SetParent(_G["oUF_LUI_arena"..i])
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then _G["oUF_LUI_arenatarget"..i]:Disable() end
			end
		end
	end,

	ArenaPet = function(override)
		if override == nil then override = module.db.ArenaPet.Enable end

		if override and module.db.Arena.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements()
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(module.db.ArenaPet.Point, _G["oUF_LUI_arena"..i], module.db.ArenaPet.RelativePoint, module.db.ArenaPet.X, module.db.ArenaPet.Y)
				else
					oUF:Spawn("arena"..i.."pet", "oUF_LUI_arenapet"..i):SetPoint(module.db.ArenaPet.Point, _G["oUF_LUI_arena"..i], module.db.ArenaPet.RelativePoint, module.db.ArenaPet.X, module.db.ArenaPet.Y)
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
						self:SetHeight(]]..module.db.MaintankToT.Height..[[)
						self:SetWidth(]]..module.db.MaintankToT.Width..[[)
						self:SetPoint("]]..module.db.MaintankToT.Point..[[", self:GetParent(), "]]..module.db.MaintankToT.RelativePoint..[[", ]]..module.db.MaintankToT.X..[[, ]]..module.db.MaintankToT.Y..[[)
					elseif unit == "maintanktarget" then
						self:SetHeight(]]..module.db.MaintankTarget.Height..[[)
						self:SetWidth(]]..module.db.MaintankTarget.Width..[[)
						self:SetPoint("]]..module.db.MaintankTarget.Point..[[", self:GetParent(), "]]..module.db.MaintankTarget.RelativePoint..[[", ]]..module.db.MaintankTarget.X..[[, ]]..module.db.MaintankTarget.Y..[[)
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
						_G["oUF_LUI_maintankUnitButton"..i]:UpdateAllElements()
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
							self:SetHeight(]]..module.db.MaintankToT.Height..[[)
							self:SetWidth(]]..module.db.MaintankToT.Width..[[)
							self:SetPoint("]]..module.db.MaintankToT.Point..[[", self:GetParent(), "]]..module.db.MaintankToT.RelativePoint..[[", ]]..module.db.MaintankToT.X..[[, ]]..module.db.MaintankToT.Y..[[)
						elseif unit == "maintanktarget" then
							self:SetHeight(]]..module.db.MaintankTarget.Height..[[)
							self:SetWidth(]]..module.db.MaintankTarget.Width..[[)
							self:SetPoint("]]..module.db.MaintankTarget.Point..[[", self:GetParent(), "]]..module.db.MaintankTarget.RelativePoint..[[", ]]..module.db.MaintankTarget.X..[[, ]]..module.db.MaintankTarget.Y..[[)
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

			module.ToggleUnit("MaintankTarget")
		else
			if oUF_LUI_maintank then
				oUF_LUI_maintank:Hide()
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then _G["oUF_LUI_maintankUnitButton"..i]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
				end
			end

			module.ToggleUnit("MaintankTarget", false)
		end
	end,

	MaintankTarget = function(override)
		if override == nil then override = module.db.MaintankTarget.Enable end

		if override and module.db.Maintank.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(module.db.MaintankTarget.Point, _G["oUF_LUI_maintankUnitButton"..i], module.db.MaintankTarget.RelativePoint, module.db.MaintankTarget.X, module.db.MaintankTarget.Y)
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:UpdateAllElements()
				end
			end

			module.ToggleUnit("MaintankToT")
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
			end

			module.ToggleUnit("MaintankToT", false)
		end
	end,

	MaintankToT = function(override)
		if override == nil then override = module.db.MaintankToT.Enable end

		if override and module.db.MaintankTarget.Enable and module.db.Maintank.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(module.db.MaintankToT.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], module.db.MaintankToT.RelativePoint, module.db.MaintankToT.X, module.db.MaintankToT.Y)
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:UpdateAllElements()
				end
			end
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
			end
		end
	end,

	Raid = function(override)
		if override == nil then override = module.db.Raid.Enable end

		if override then
			if IsAddOnLoaded("Grid") or IsAddOnLoaded("Grid2") or IsAddOnLoaded("VuhDo") or IsAddOnLoaded("Healbot") then
				return
			end
			if oUF_LUI_raid then
				for i = 1, 5 do
					if i ~= 1 then
						_G["oUF_LUI_raid_25_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_25_"..i-1], "TOPRIGHT", module.db.Raid.GroupPadding, 0)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("yOffset", - module.db.Raid.Padding)
						_G["oUF_LUI_raid_25_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.Raid.Height..[[)
							self:SetWidth(]]..module.db.Raid.Width..[[)
						]])
					end
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then
							frame:Enable()
							frame:UpdateAllElements()
						end
					end
				end

				local width40 = (5 * module.db.Raid.Width - 3 * module.db.Raid.GroupPadding) / 8

				for i = 1, 8 do
					if i ~= 1 then
						_G["oUF_LUI_raid_40_"..i]:SetPoint("TOPLEFT", _G["oUF_LUI_raid_40_"..i-1], "TOPRIGHT", module.db.Raid.GroupPadding, 0)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("yOffset", - module.db.Raid.Padding)
						_G["oUF_LUI_raid_40_"..i]:SetAttribute("oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.Raid.Height..[[)
							self:SetWidth(]]..width40..[[)
						]])
					end
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then
							frame:Enable()
							frame:UpdateAllElements()
						end
					end
				end

				oUF_LUI_raid:ClearAllPoints()
				oUF_LUI_raid:SetPoint(module.db.Raid.Point, UIParent, module.db.Raid.Point, module.db.Raid.X, module.db.Raid.Y)
				oUF_LUI_raid:Show()

				RegisterStateDriver(oUF_LUI_raid_25, "visibility", "[@raid26,exists] hide; show")
				RegisterStateDriver(oUF_LUI_raid_40, "visibility", "[@raid26,exists] show; hide")
			else
				local raidAnchor = CreateFrame("Frame", "oUF_LUI_raid", UIParent)
				raidAnchor:SetWidth(module.db.Raid.Width * 5 + module.db.Raid.GroupPadding * 4)
				raidAnchor:SetHeight(module.db.Raid.Height * 5 + module.db.Raid.Padding * 4)
				raidAnchor:SetPoint(module.db.Raid.Point, UIParent, module.db.Raid.Point, module.db.Raid.X, module.db.Raid.Y)

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
						"yOffset", - module.db.Raid.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.Raid.Height..[[)
							self:SetWidth(]]..module.db.Raid.Width..[[)
						]]
					)
					raid25table[i]:SetParent(raid25)
					raid25table[i]:Show()
					if i == 1 then
						raid25table[i]:SetPoint("TOPLEFT", raid25, "TOPLEFT", 0, 0)
					else
						raid25table[i]:SetPoint("TOPLEFT", raid25table[i-1], "TOPRIGHT", module.db.Raid.GroupPadding, 0)
					end
				end

				local raid40 = CreateFrame("Frame", "oUF_LUI_raid_40", raidAnchor, "SecureHandlerStateTemplate")
				raid40:SetWidth(1)
				raid40:SetHeight(1)
				raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				RegisterStateDriver(raid40, "visibility", "[@raid26,exists] show; hide")

				local width40 = (5 * module.db.Raid.Width - 3 * module.db.Raid.GroupPadding) / 8

				local raid40table = {}
				for i = 1, 8 do
					raid40table[i] = oUF:SpawnHeader("oUF_LUI_raid_40_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - module.db.Raid.Padding,
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..module.db.Raid.Height..[[)
							self:SetWidth(]]..width40..[[)
						]]
					)
					raid40table[i]:SetParent(raid40)
					raid40table[i]:Show()
					if i == 1 then
						raid40table[i]:SetPoint("TOPLEFT", raid40, "TOPLEFT", 0, 0)
					else
						raid40table[i]:SetPoint("TOPLEFT", raid40table[i-1], "TOPRIGHT", module.db.Raid.GroupPadding, 0)
					end
				end
			end

			Blizzard:Hide("raid")
		else
			if module.db.Raid.UseBlizzard == true then
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
			module.funcs.Full(frame, frame.__unit, module.db[unit])
			module.funcs.FrameBackdrop(frame, frame.__unit, module.db[unit])

			-- texts
			if unit == "Raid" then
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
			if module.db[unit].Icons then
				for key, icons in pairs(iconlist) do
					if module.db[unit].Icons[key] then
						if module.db[unit].Icons[key].Enable then
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
			if unit == "Player" then
				-- exp/rep
				module.funcs.Experience(frame, frame.__unit, module.db.XP_Rep)
				module.funcs.Reputation(frame, frame.__unit, module.db.XP_Rep)

				if module.db.XP_Rep.Experience.Enable and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
					frame.Experience:ForceUpdate()
					frame.XP:Show()
					frame.Rep:Hide()
				else
					frame.XP:Hide()
					if module.db.XP_Rep.Reputation.Enable then
						frame.Reputation:ForceUpdate()
						frame.Rep:Show()
					else
						frame.Rep:Hide()
					end
				end

				-- runes
				if class == "DEATHKNIGHT" or class == "DEATH KNIGHT" then
					module.funcs.Runes(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.Runes.Enable then
						frame:EnableElement("Runes")
					else
						frame:DisableElement("Runes")
						frame.Runes:Hide()
					end
				end

				-- holy power
				if class == "PALADIN" then
					module.funcs.ClassIcons(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.HolyPower.Enable then
						frame:EnableElement("ClassIcons")
					else
						frame:DisableElement("ClassIcons")
						frame.ClassIcons:Hide()
					end
				end
				
				-- arcane changes
				if class == "MAGE" then
					module.funcs.ClassIcons(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.ArcaneCharges.Enable then
						frame:EnableElement("ClassIcons")
					else
						frame:DisableElement("ClassIcons")
						frame.ClassIcons:Hide()
					end
				end

				-- warlock stuff
				if class == "WARLOCK" then
					module.funcs.ClassIcons(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.WarlockBar.Enable then
						frame:EnableElement("ClassIcons")
					else
						frame:DisableElement("ClassIcons")
						frame.ClassIcons:Hide()
					end
				end

				-- chi
				if class == "MONK" then
					module.funcs.ClassIcons(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.Chi.Enable then
						frame:EnableElement("ClassIcons")
					else
						frame:DisableElement("ClassIcons")
						frame.ClassIcons:Hide()
					end
				end

				-- druid mana bar
				if class == "DRUID" or class == "PRIEST" or class == "SHAMAN" then
					module.funcs.DruidMana(frame, frame.__unit, module.db.Player)
					if module.db[unit].Bars.DruidMana.Enable then
						frame:EnableElement("DruidMana")
					else
						frame:DisableElement("DruidMana")
						frame.DruidMana.SetPosition()
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
			if unit == "Player" or unit == "Pet" then
				if module.db.Player.Bars.AltPower.Enable then
					module.funcs.AltPowerBar(frame, frame.__unit, module.db[unit])
					frame:EnableElement("AltPowerBar")
					frame.AltPowerBar.SetPosition()
				else
					if frame.AltPowerBar then
						frame:DisableElement("AltPowerBar")
						frame.AltPowerBar.SetPosition()
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
			if module.db[unit].HealPrediction then
				if module.db[unit].HealPrediction.Enable then
					module.funcs.HealPrediction(frame, frame.__unit, module.db[unit])
					frame:EnableElement("HealPrediction")
				else
					frame:DisableElement("HealPrediction")
				end
			end

			if unit == "ToT" or unit == "ToToT" or unit == "FocusTarget" or unit == "Focus" then
				if not frame.V2Tex then
					if unit == "ToT" then
						module.funcs.V2Textures(frame, oUF_LUI_target)
					elseif unit == "ToToT" then
						module.funcs.V2Textures(frame, oUF_LUI_targettarget)
					elseif unit == "FocusTarget" then
						module.funcs.V2Textures(frame, oUF_LUI_focus)
					elseif unit == "Focus" then
						module.funcs.V2Textures(frame, oUF_LUI_player)
					end
				end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2Textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "PartyTarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_partyUnitButton"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2PartyTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "ArenaTarget" then
				if not frame.V2Tex then module.funcs.V2Textures(frame, _G["oUF_LUI_arena"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if module.db.Settings.ShowV2ArenaTextures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "BossTarget" then
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

			frame:UpdateAllElements()
		end
	end
end
