-- Client-specific capabilities are queried at use time so late-loaded Blizzard
-- UI remains discoverable. Shared features keep their existing implementation.
local LUI = select(2, ...)

function LUI:InitializePlayerIdentity(previousProfileKeys)
    if not self.IsForever then return end

    local legacy = {name = self.playerName, realm = self.playerRealm, profile = self.profileName}
    -- AceDB owns Forever's regional character and ruleset keys. GetRealmName
    -- is not a reliable storage key on this client, and names include surnames.
    self.playerName = self.db.keys.char
    self.playerRealm = self.db.keys.realm
    self.playerFullName = NameUtil.GetUnmodifiedUnitFullName("player")
    self.profileName = format("%s - %s", self.playerName, self.playerRealm)

    local configs = self.db.global.luiconfig
    if not configs[self.profileName] and configs[legacy.profile] then
        configs[self.profileName] = CopyTable(configs[legacy.profile])
    end
    -- Keep an existing profile selection. Only migrate a legacy mapping if
    -- this regional character did not already have its own saved selection.
    if previousProfileKeys and not previousProfileKeys[self.db.keys.char] then
        local profile = previousProfileKeys[legacy.profile]
        if profile and self.db.sv.profiles[profile] then self.db:SetProfile(profile) end
    end
    if legacy.name ~= self.playerName or legacy.realm ~= self.playerRealm then
        self.legacyPlayerIdentity = legacy
    end
end

function LUI:HasClientFeature(feature)
    if feature == "Legacy" then
        return self.IsForever and _G.LegacyMicroButton ~= nil
    elseif feature == "SwingTimer" then
        return self.IsForever and C_CVar and type(C_CVar.GetCVar) == "function"
            and C_CVar.GetCVar("showSwingTimer") ~= nil or false
    elseif feature == "Keyring" then
        return self.IsForever and C_ActionBar and type(C_ActionBar.ShouldShowKeyring) == "function"
            and Enum and Enum.BagIndex and Enum.BagIndex.Keyring ~= nil or false
    elseif feature == "LFG" then
        return self.IsRetail or (self.IsForever and _G.LFDMicroButton ~= nil)
    elseif feature == "Housing" or feature == "EJ" then
        -- These native addons are excluded from the supported Forever build.
        return self.IsRetail
    end
    return false
end
