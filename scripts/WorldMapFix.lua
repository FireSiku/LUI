local addonname, LUI = ...
local script = LUI:NewScript("WorldMapFix")

WorldMapFrame:SetFrameStrata("HIGH")
local children = {WorldMapFrame:GetChildren()}
for k, v in pairs(children) do
    if v.TrackerBackground or v.Icon then
        --WorldMapBountyBoardMixin
        v:SetFrameStrata("DIALOG")
    end
end
WorldMapCompareTooltip1:SetFrameStrata("TOOLTIP")
WorldMapCompareTooltip2:SetFrameStrata("TOOLTIP")
