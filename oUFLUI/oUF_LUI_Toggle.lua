local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local db = LUI.db.profile

------------------------------------------------------------------------
--	ToggleFuncs for the single Frames
--	needed for LUI options without ui reload
------------------------------------------------------------------------

-- needed for spawning without ui reload
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

local toggleFuncs = {
	Default = function(unit) 
		if db.oUF[unit].Enable == nil or db.oUF[unit].Enable then -- == nil needed for player/target
			if _G["oUF_LUI_"..ufUnits[unit]] then
				_G["oUF_LUI_"..ufUnits[unit]]:Enable()
				_G["oUF_LUI_"..ufUnits[unit]]:UpdateAllElements()
				_G["oUF_LUI_"..ufUnits[unit]]:ClearAllPoints()
				_G["oUF_LUI_"..ufUnits[unit]]:SetPoint("CENTER", UIParent, "CENTER", tonumber(db.oUF[unit].X), tonumber(db.oUF[unit].Y))
			else
				oUF:SetActiveStyle("LUI")
				oUF:Spawn(ufUnits[unit], "oUF_LUI_"..ufUnits[unit]):SetPoint("CENTER", UIParent, "CENTER", tonumber(db.oUF[unit].X), tonumber(db.oUF[unit].Y))
			end
		else
			if _G["oUF_LUI_"..ufUnits[unit]] then _G["oUF_LUI_"..ufUnits[unit]]:Disable() end
		end
	end,
	
	Boss = function()
		if db.oUF.Boss.Enable then
			if oUF_LUI_boss1 then
				for i = 1, MAX_BOSS_FRAMES do
					_G["oUF_LUI_boss"..i]:Enable()
					_G["oUF_LUI_boss"..i]:UpdateAllElements()
					_G["oUF_LUI_boss"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_boss"..i]:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Boss.X), tonumber(db.oUF.Boss.Y))
					else
						_G["oUF_LUI_boss"..i]:SetPoint('TOP', _G["oUF_LUI_boss"..i-1], 'BOTTOM', 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
			else		
				oUF:SetActiveStyle("LUI")

				local boss = {}
				for i = 1, MAX_BOSS_FRAMES do
					boss[i] = oUF:Spawn("boss"..i, "oUF_LUI_boss"..i)
					if i == 1 then
						boss[i]:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Boss.X), tonumber(db.oUF.Boss.Y))
					else
						boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
			end
		else
			for i = 1, MAX_BOSS_FRAMES do
				if _G["oUF_LUI_boss"..i] then _G["oUF_LUI_boss"..i]:Disable() end
			end
		end
	end,
	
	Party = function()
		if db.oUF.Party.Enable then
			if oUF_LUI_party then
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint("LEFT", UIParent, "LEFT", tonumber(db.oUF.Party.X), tonumber(db.oUF.Party.Y))
				oUF_LUI_party:SetAttribute("yOffset", - tonumber(db.oUF.Party.Padding))
				oUF_LUI_party:SetAttribute("showPlayer", db.oUF.Party.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..db.oUF.Party.Height..[[)
						self:SetWidth(]]..db.oUF.Party.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
						self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
						self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
						self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
						self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
					end
				]])
				
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Enable()
						_G["oUF_LUI_partyUnitButton"..i]:UpdateAllElements()
					end
				end
				
				if not InCombatLockdown() then
					if not db.oUF.Party.ShowInRaid then
						local numraid = GetNumRaidMembers()
						if numraid > 0 and (numraid > 5 or numraid ~= GetNumPartyMembers() + 1) then
							oUF_LUI_party:Hide()
						else
							oUF_LUI_party:Show()
						end
					else
						oUF_LUI_party:Show()
					end
				end
			else
				oUF:SetActiveStyle("LUI")	
				
				local party = oUF:SpawnHeader("oUF_LUI_party", nil, nil,
					"showParty", true,
					"showPlayer", db.oUF.Party.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"yOffset", - tonumber(db.oUF.Party.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..db.oUF.Party.Height..[[)
							self:SetWidth(]]..db.oUF.Party.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
							self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
							self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
							self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
							self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
						end
					]]
				)
				
				party:SetPoint("LEFT", UIParent, "LEFT", tonumber(db.oUF.Party.X), tonumber(db.oUF.Party.Y))
				
				local partyToggle = CreateFrame("Frame")
				partyToggle:RegisterEvent("PLAYER_LOGIN")
				partyToggle:RegisterEvent("RAID_ROSTER_UPDATE")
				partyToggle:RegisterEvent("PARTY_LEADER_CHANGED")
				partyToggle:RegisterEvent("PARTY_MEMBERS_CHANGED")
				partyToggle:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")

						if not db.oUF.Party.ShowInRaid then
							local numraid = GetNumRaidMembers()
							if numraid > 0 and (numraid > 5 or numraid ~= GetNumPartyMembers() + 1) then
								party:Hide()
							else
								party:Show()
							end
						else
							party:Show()
						end
					end
				end)
			end
		else
			if oUF_LUI_party then
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then _G["oUF_LUI_partyUnitButton"..i]:Disable() end
				end
				oUF_LUI_party:Hide()
			end
		end
	end,
	
	PartyTarget = function()
		if db.oUF.Party.Enable and db.oUF.PartyTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(db.oUF.PartyTarget.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyTarget.RelativePoint, tonumber(db.oUF.PartyTarget.X), tonumber(db.oUF.PartyTarget.Y))
				end
			end
			
			oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "party" then
					self:SetHeight(]]..db.oUF.Party.Height..[[)
					self:SetWidth(]]..db.oUF.Party.Width..[[)
				elseif unit == "partytarget" then
					self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
					self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
					self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
				elseif unit == "partypet" then
					self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
					self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
					self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
				end
			]])
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,
	
	PartyPet = function()
		if db.oUF.Party.Enable and db.oUF.PartyPet.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(db.oUF.PartyPet.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyPet.RelativePoint, tonumber(db.oUF.PartyPet.X), tonumber(db.oUF.PartyPet.Y))
				end
			end
			
			oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "party" then
					self:SetHeight(]]..db.oUF.Party.Height..[[)
					self:SetWidth(]]..db.oUF.Party.Width..[[)
				elseif unit == "partytarget" then
					self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
					self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
					self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
				elseif unit == "partypet" then
					self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
					self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
					self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
				end
			]])
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then _G["oUF_LUI_partyUnitButton"..i.."pet"]:Disable() end
			end
		end
	end,
	
	Arena = function()
		if db.oUF.Arena.Enable then
			SetCVar("showArenaEnemyFrames", 0)
			
			if oUF_LUI_arena then
				for i = 1, 5 do
					_G["oUF_LUI_arena"..i]:Enable()
					_G["oUF_LUI_arena"..i]:UpdateAllElements()
					_G["oUF_LUI_arena"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_arena"..i]:SetPoint("TOPRIGHT", oUF_LUI_arena, "TOPRIGHT", 0, 0)
					else
						_G["oUF_LUI_arena"..i]:SetPoint("TOP", _G["oUF_LUI_arena"..i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end
				oUF_LUI_arena:Show()
			else
				oUF:SetActiveStyle("LUI")
				
				local arenaParent = CreateFrame("Frame", "oUF_LUI_arena", UIParent)
				arenaParent:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.oUF.Arena.X), tonumber(db.oUF.Arena.Y))
				arenaParent:SetWidth(tonumber(db.oUF.Arena.Width))
				arenaParent:SetHeight(tonumber(db.oUF.Arena.Height))

				local arena = {}

				for i = 1, 5 do
					arena[i] = oUF:Spawn("arena"..i, "oUF_LUI_arena"..i)
					if i == 1 then
						arena[i]:SetPoint("TOPRIGHT", arenaParent, "TOPRIGHT", 0, 0)
					else
						arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end

				if db.oUF.ArenaTarget.Enable == true then
					local arenatarget = {}
					for i = 1, 5 do
						arenatarget[i] = oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i)
						arenatarget[i]:SetPoint(db.oUF.ArenaTarget.Point, arena[i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
					end
				end

				if db.oUF.ArenaPet.Enable == true then
					local arenapet = {}
					for i = 1, 5 do
						arenapet[i] = oUF:Spawn("arena"..i.."pet", "oUF_LUI_arenapet"..i)
						arenapet[i]:SetPoint(db.oUF.ArenaPet.Point, arena[i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaTarget.Y))
					end
				end

				arenaParent:RegisterEvent("PLAYER_LOGIN")
				arenaParent:RegisterEvent("PLAYER_ENTERING_WORLD")
				arenaParent:RegisterEvent("ARENA_OPPONENT_UPDATE")
				arenaParent:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")
						
						local c = 0
						for i = 1, 5 do
							if arena[i]:IsShown() then c = i end
						end

						if c > 0 then
							self:SetHeight(tonumber(db.oUF.Arena.Height) * c + tonumber(db.oUF.Arena.Padding) * (c-1))
						end
					end
				end)
			end
		else
			if db.oUF.Arena.UseBlizzard == true then
				SetCVar("showArenaEnemyFrames", 1)
			else
				SetCVar("showArenaEnemyFrames", 0)
			end
			
			for i = 1, 5 do
				if _G["oUF_LUI_arena"..i] then _G["oUF_LUI_arena"..i]:Disable() end
			end
			oUF_LUI_arena:Hide()
		end
	end,
	
	ArenaTarget = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements()
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				else
					oUF:SetActiveStyle("LUI")
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then _G["oUF_LUI_arenatarget"..i]:Disable() end
			end
		end
	end,
	
	ArenaPet = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaPet.Enable == true then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements()
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				else
					oUF:SetActiveStyle("LUI")
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then _G["oUF_LUI_arenapet"..i]:Disable() end
			end
		end
	end,
	
	Maintank = function()
		if db.oUF.Maintank.Enable then
			if oUF_LUI_maintank then
				oUF_LUI_maintank:ClearAllPoints()
				oUF_LUI_maintank:SetPoint("TOPRIGHT", UIParent, "RIGHT", tonumber(db.oUF.Maintank.X), tonumber(db.oUF.Maintank.Y))
				oUF_LUI_maintank:SetAttribute("yOffset", - tonumber(db.oUF.Maintank.Padding))
				oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "raidtargettarget" then
						self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
					elseif unit == "raidtarget" then
						self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
					elseif unit == "raid" then
						self:SetHeight(]]..db.oUF.Maintank.Height..[[)
						self:SetWidth(]]..db.oUF.Maintank.Width..[[)
					end
				]])
				oUF_LUI_maintank:Show()
				
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then
						_G["oUF_LUI_maintankUnitButton"..i]:Enable()
						_G["oUF_LUI_maintankUnitButton"..i]:UpdateAllElements()
					end
				end
			else		
				oUF:SetActiveStyle("LUI")

				local tank = oUF:SpawnHeader("oUF_LUI_maintank", nil, nil,
					"showRaid", true,
					"groupFilter", "MAINTANK",
					"template", "oUF_LUI_maintank",
					"showPlayer", true,
					"wrapAfter", 4,
					"yOffset", - tonumber(db.oUF.Maintank.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "raidtargettarget" then
							self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
						elseif unit == "raidtarget" then
							self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
						elseif unit == "raid" then
							self:SetHeight(]]..db.oUF.Maintank.Height..[[)
							self:SetWidth(]]..db.oUF.Maintank.Width..[[)
						end
					]]
				)
				
				tank:SetPoint("TOPRIGHT", UIParent, "RIGHT", tonumber(db.oUF.Maintank.X), tonumber(db.oUF.Maintank.Y))
				tank:Show()
			end
		else
			if oUF_LUI_maintank then
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then _G["oUF_LUI_maintankUnitButton"..i]:Disable() end
				end
				oUF_LUI_maintank:Hide()
			end
		end
	end,
	
	MaintankTarget = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:Enable()
					--_G["oUF_LUI_maintankUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(db.oUF.MaintankTarget.Point, _G["oUF_LUI_maintankUnitButton"..i], db.oUF.MaintankTarget.RelativePoint, tonumber(db.oUF.MaintankTarget.X), tonumber(db.oUF.MaintankTarget.Y))
				end
			end
			
			oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "raidtargettarget" then
					self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
				elseif unit == "raidtarget" then
					self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
				elseif unit == "raid" then
					self:SetHeight(]]..db.oUF.Maintank.Height..[[)
					self:SetWidth(]]..db.oUF.Maintank.Width..[[)
				end
			]])
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
			end
		end
	end,
	
	MaintankToT = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable and db.oUF.MaintankToT.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:UpdateAllElements()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(db.oUF.MaintankToT.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], db.oUF.MaintankToT.RelativePoint, tonumber(db.oUF.MaintankToT.X), tonumber(db.oUF.MaintankToT.Y))
				end
			end
			
			oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "raidtargettarget" then
					self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
				elseif unit == "raidtarget" then
					self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
				elseif unit == "raid" then
					self:SetHeight(]]..db.oUF.Maintank.Height..[[)
					self:SetWidth(]]..db.oUF.Maintank.Width..[[)
				end
			]])
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
			end
		end
	end,
}

oUF_LUI.toggle = function(unit)
	if toggleFuncs[unit] then
		toggleFuncs[unit]()
	else
		toggleFuncs["Default"](unit)
	end
end
