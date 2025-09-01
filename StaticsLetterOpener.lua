--[[------------------------------------------------------------------------------------------------
Title:					Static's Letter Opener
Author:					Static_Recharge
Version:			  0.0.2
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
	self.addonVersion = "0.0.2"
	self.author = "|CFF0000Static_Recharge|r"
	self.varsVersion = 1
	self.Surveys = {
		[219849] = true,			-- blacksmithing
		[219850] = true,			-- clothing
		[219851] = true,			-- woodworking
		[219852] = true,			-- enchanting
		[219853] = true,			-- alchemy
		[219854] = true,			-- jewelry
	}
	self.MasterWrits = {
		[217917] = true,			-- blacksmithing
		[217918] = true,			-- clothing
		[217919] = true,			-- woodworking
		[217920] = true,			-- enchanting
		[217921] = true,			-- provisioning
		[217922] = true,			-- alchemy
		[217923] = true,			-- jewelry
	}
	self.Defaults = {
		surveys = true,
		masterWrits = false,
		chatMsg = true,
	}

	-- session variables
	self.Que = {}
	self.started = false

	-- saved variables initialization
	self.SV = ZO_SavedVars:NewAccountWide("StaticsLetterOpenerAccountWideVars", self.varsVersion, nil, self.Defaults, nil)
	
	-- Event Registrations
	EM:RegisterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnInventorySingleSlotUpdate(...) end)
	EM:AddFilterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)

	--SLASH_COMMANDS["/slotest"] = function() self:Test() end
	SLASH_COMMANDS["/slosurveys"] = function() self.SV.surveys = not self.SV.surveys d("[SLO] Survey opening toggled") end
	SLASH_COMMANDS["/slomasterwrits"] = function() self.SV.masterWrits = not self.SV.masterWrits ("[SLO] Master Writ opening toggled") end
	SLASH_COMMANDS["/slochatmsg"] = function() self.SV.chatMsg = not self.SV.chatMsg ("[SLO] Chat Messages toggled") end

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
	local itemData = {
		id = GetItemId(bagId, slotId),
		link = GetItemLink(bagId, slotId),
	}
	if (self.SV.surveys and self.Surveys[itemData.id]) or (self.SV.masterWrits and self.MasterWrits[itemData.id]) then
		table.insert(self.Que, itemData)
		--d(zo_strformat("<<1>> Qued", itemData.link))
		if not self.started then
			EM:RegisterForUpdate(self.addonName, 500, function() self:Open() end)
			self.started = true
		end
	end
end


function LO:Open()
	local bag = BAG_BACKPACK
	if #self.Que == 0 then
		EM:UnregisterForUpdate(self.addonName)
		self.started = false
		return
	end
	if GetSlotCooldownInfo(1) == 0 then
		local slotId = self:GetInventoryIndex()
		if IsProtectedFunction("UseItem") then
			CallSecureProtected("UseItem", bag, slotId)
		else
			UseItem(bag, slotId)
		end
		if self.SV.chatMsg then d(zo_strformat("<<1>> Opened", self.Que[1].link)) end
		table.remove(self.Que, 1)
	end
end


function LO:GetInventoryIndex()
	local bag = BAG_BACKPACK
	local slot = ZO_GetNextBagSlotIndex(bag)
	local item
	while slot do
		item = GetItemId(bag, slot)
		if HasItemInSlot(bag, slot)	and item == self.Que[1].id then
			--d(zo_strformat("<<1>> Found", self.Que[1].link))
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