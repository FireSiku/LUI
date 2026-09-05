-- Mail Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Mail", "AceEvent-3.0")

local GetInboxNumItems = _G.GetInboxNumItems
local HasNewMail = _G.HasNewMail

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:UpdateMail()
	local db = module.db.profile.Mail
	local numMail, totalItems = GetInboxNumItems()
	local hasNew = HasNewMail()
	numMail = tonumber(numMail) or 0
	totalItems = tonumber(totalItems) or 0

	if numMail > 0 or totalItems > 0 then
		element.text = format("Mail: %d/%d%s", numMail, totalItems, hasNew and db.NewIndic or "")
	elseif hasNew then
		element.text = "Mail: New"..(db.NewIndic or "")
	else
		element.text = "Mail: 0"
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateMail")
	element:RegisterEvent("MAIL_SHOW", "UpdateMail")
	element:RegisterEvent("MAIL_CLOSED", "UpdateMail")
	element:RegisterEvent("MAIL_INBOX_UPDATE", "UpdateMail")
	element:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	element:UpdateMail()
end

element.RefreshSettings = element.UpdateMail
