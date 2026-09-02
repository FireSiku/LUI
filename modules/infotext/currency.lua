-- Currency Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Currency", "AceEvent-3.0")

-- local copies
local format = format
local C_CurrencyInfo = C_CurrencyInfo

local CURRENCY = _G.CURRENCY

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function GetWatchedCurrencyCount()
	local count = 0
	while C_CurrencyInfo.GetBackpackCurrencyInfo(count + 1) do
		count = count + 1
	end
	return count
end

function element:UpdateCurrency()
	element.text = format("Currencies: %d", GetWatchedCurrencyCount())
	element:UpdateTooltip()
end

-- Click: Open Currency Frame
function element.OnClick(frame_, button_)
	_G.ToggleCharacter("TokenFrame")
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(CURRENCY)
	local displayed = 0
	local displayLimit = module.db.profile.Currency.DisplayLimit
	for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
		local info = C_CurrencyInfo.GetCurrencyListInfo(i)
		if info and info.isHeader then
			if i > 1 then GameTooltip:AddLine(" ") end
			GameTooltip:AddLine(info.name)
		elseif info and info.discovered and info.name then
			local r, g, b = 1, 1, 1
			if info.isShowInBackpack then r, g, b = 0.5, 1, 0.5 end
			if info.quantity and info.quantity ~= 0 then
				GameTooltip:AddDoubleLine(info.name, info.quantity, r,g,b, r,g,b)
			else
				GameTooltip:AddDoubleLine(info.name, "--", r,g,b, r,g,b)
			end
			displayed = displayed + 1
			if displayed >= displayLimit then
				GameTooltip:AddLine("…", 0.7, 0.7, 0.7)
				break
			end
		end
	end
	element:AddHint(L["InfoCurrency_Hint_Any"])
end

element.RefreshSettings = element.UpdateCurrency

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "UpdateCurrency")
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateCurrency")
	element:UpdateCurrency()
end
