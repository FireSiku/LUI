local addonname, LUI = ...
local script = LUI:NewScript("WorldMapFix")

--WorldMapFrame:SetFrameStrata("HIGH")
local children = {WorldMapFrame:GetChildren()}
for k, v in pairs(children) do
    if v.TrackerBackground or v.Icon then
        --WorldMapBountyBoardMixin
        LUI:Print("Changing Strata for", v:GetDebugName())
        v:SetFrameStrata("DIALOG")
    end
end
