-- Native keyring access for clients that expose it (Forever beta).
local LUI = select(2, ...)
local module = LUI:GetModule("Bags")

function module:CreateKeyringButton(parent)
    if not LUI:HasClientFeature("Keyring") then return end

    local button = module:CreateSlot("LUIBags_Keyring", parent, "")
    button.icon:SetAtlas("UI-HUD-ActionBar-Keyring-Small")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function()
        if CursorHasItem() then
            if PutKeyInKeyRing then PutKeyInKeyRing() end
        else
            -- Preserve Blizzard's item slots, tooltips, search and keyring CVar.
            ToggleBag(Enum.BagIndex.Keyring)
        end
    end)
    button:SetScript("OnReceiveDrag", function()
        if CursorHasItem() and PutKeyInKeyRing then PutKeyInKeyRing() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(_G.KEYRING or "Keyring", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    -- Keep the button discoverable even if Blizzard hides it at login.
    -- The toolbar re-evaluates both the current LUI profile and native CVar.
    button.UpdateClientVisibility = function(self)
        self.hidden = not module.db.profile.Bags.ShowKeyringButton
            or not C_ActionBar.ShouldShowKeyring()
    end
    button:RegisterEvent("CVAR_UPDATE")
    button:SetScript("OnEvent", function(_, _, cvar)
        if type(cvar) == "string" and cvar:lower() == "showkeyring" then
            parent:SetAnchors()
        end
    end)
    button:UpdateClientVisibility()
    parent:AddNewButton(button)
    return button
end
