local LUI = select(2, ...)
local issecretvalue = _G.issecretvalue or function() return false end

function LUI:TooltipHasWidgets(tooltip)
	-- Hidden containers can still receive updates until their set is unregistered.
	local container = tooltip and tooltip.widgetContainer
	if issecretvalue(container) then return true end
	if not container then return false end
	local widgetSetID = container.widgetSetID
	return issecretvalue(widgetSetID) or widgetSetID ~= nil
end

function LUI:HideTooltip(tooltip, owner)
	if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
	-- Native OnHide lays out the widget container before unregistering its
	-- events. Leave that cleanup on Blizzard's own execution path.
	if self:TooltipHasWidgets(tooltip) then return end
	if owner and not tooltip:IsOwned(owner) then return end
	tooltip:Hide()
end
