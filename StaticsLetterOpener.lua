--[[------------------------------------------------------------------------------------------------
Title:					Static's Letter Opener
Author:					Static_Recharge
Version:			  0.0.1
Description:		Opens master writs and survey letters automatically
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local EM = EVENT_MANAGER


--[[------------------------------------------------------------------------------------------------
LO Class Initialization
LO    - Parent object containing all functions, tables, variables, constants and other data managers.
  |-  Defaults    - Default values for saved vars and settings menu items.
------------------------------------------------------------------------------------------------]]--
local LO = ZO_InitializingObject:Subclass()

--[[------------------------------------------------------------------------------------------------
LO:Initialize()
Inputs:				None
Outputs:			None
Description:	Initializes all of the variables, object managers, slash commands and main event
							callbacks.
------------------------------------------------------------------------------------------------]]--
function LO:Initialize()
	-- Static definitions
	self.addonName = "StaticsLetterOpener"
	self.addonVersion = "0.0.1"
	self.author = "|CFF0000Static_Recharge|r"

	-- session variables
	self.Que = {}
	self.started = false
	
	-- Event Registrations
	EM:RegisterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnInventorySingleSlotUpdate(...) end)
	EM:AddFilterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)

	SLASH_COMMANDS["/slotest"] = function() self:Test() end

	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
function function LO:OnInventorySingleSlotUpdate (eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
Inputs:				eventCode				- Internal ZOS event code, not used here.
							bagId						- Number for which bag was affected (use globals)
Outputs:			None
Description:	
------------------------------------------------------------------------------------------------]]--
function LO:OnInventorySingleSlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
	local itemType, specialItemType = GetItemType(bagId, slotId)
	if itemType == ITEMTYPE_CONTAINER_STACKABLE and specialItemType == SPECIALIZED_ITEMTYPE_CONTAINER_STACKABLE then
		local item = GetItemLink(bagId, slotId)
		--d(item)
		table.insert(self.Que, item)
		if not self.started then
			EM:RegisterForUpdate(self.addonName, 500, function() self:Open() end)
			self.started = true
		end
	end
end


function LO:Open()
	if #self.Que <= 0 then
		EM:UnregisterForUpdate(self.addonName)
		self.started = false
		return
	end
	if GetSlotCooldownInfo(1) == 0 then
		local slotId = self:GetInventoryIndex()
		--d(GetItemLink(BAG_BACKPACK, slotId))
		if IsProtectedFunction("UseItem") then
			CallSecureProtected("UseItem", BAG_BACKPACK, slotId)
		else
			UseItem(BAG_BACKPACK, slotId)
		end
		d(zo_strformat("<<1>> opened.", self.Que[1]))
		table.remove(self.Que, 1)
		if #self.Que == 0 then
			EM:UnregisterForUpdate(self.addonName)
			self.started = false
		end
	else
		--d("Calling later")
	end
end


function LO:GetInventoryIndex()
	local bag = BAG_BACKPACK
	local slot = ZO_GetNextBagSlotIndex(bag)
	local link
	while slot do
		link = GetItemLink(BAG_BACKPACK, slot)
		if HasItemInSlot(bag, slot)	and link == self.Que[1] then
			return slot
		end
		slot = ZO_GetNextBagSlotIndex(bag, slot)
	end
end


--[[------------------------------------------------------------------------------------------------
function function LO:Test()
Inputs:				None
Outputs:			None
Description:	
------------------------------------------------------------------------------------------------]]--
function LO:Test()
	d("test")
end


--[[------------------------------------------------------------------------------------------------
Main add-on event registration. Creates the global object, StaticsLetterOpener, of the LO class.
------------------------------------------------------------------------------------------------]]--
EM:RegisterForEvent("StaticsLetterOpener", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if addonName ~= "StaticsLetterOpener" then return end
	EM:UnregisterForEvent("StaticsLetterOpener", EVENT_ADD_ON_LOADED)
	StaticsLetterOpener = LO:New()
end)