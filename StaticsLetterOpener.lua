--[[------------------------------------------------------------------------------------------------
Title:					Static's Letter Opener
Author:					Static_Recharge
Version:			  1.0.0
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
	self.addonVersion = "1.0.0"
	self.author = "|CFF0000Static_Recharge|r"
	self.varsVersion = 1

	self.chatPrefix = "|cFFFFFF[SLO]:|r "
	self.chatTextColor = "|cFFFFFF"
	self.chatSuffix = "|r"

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
		chatMsgEnabled = true,
		openAll = false,
		debugMode = false,
	}

	-- Session variables
	self.Que = {}
	self.started = false

	-- Saved variables initialization
	self.SV = ZO_SavedVars:NewAccountWide("StaticsLetterOpenerAccountWideVars", self.varsVersion, nil, self.Defaults, nil)

	-- Child initilization
	self.Settings = StaticsLetterOpenerInitSettings(self)
	
	-- Event Registrations
	EM:RegisterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnInventorySingleSlotUpdate(...) end)
	EM:AddFilterForEvent(self.addonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)

	--SLASH_COMMANDS["/slotest"] = function() self:Test() end

	self.initialized = true
end


--[[------------------------------------------------------------------------------------------------
function function LO:OnInventorySingleSlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
Inputs:				eventCode				- Internal ZOS event code, not used here.
							bagId						- Number for which bag was affected (use globals)
							slotId 					- Slot number for the item that was affected
							isNewItem 			- True if the item is new to the player
							itemSoundCategory - Sound information for the item
							inventoryUpdateReason - Global reason for inventory change
							stackCountChange - new stack count
Outputs:			None
Description: 	Adds found items to the Que and starts the opening event.
------------------------------------------------------------------------------------------------]]--
function LO:OnInventorySingleSlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
	if not self.SV.openAll and not isNewItem then return end
	local itemData = {
		id = GetItemId(bagId, slotId),
		link = GetItemLink(bagId, slotId),
	}
	if (self.SV.surveys and self.Surveys[itemData.id]) or (self.SV.masterWrits and self.MasterWrits[itemData.id]) then
		table.insert(self.Que, itemData)
		self:DebugMsg(zo_strformat("<<1>> Qued", itemData.link))
		if not self.started then
			EM:RegisterForUpdate(self.addonName, 500, function() self:Open() end)
			self.started = true
		end
	end
end


--[[------------------------------------------------------------------------------------------------
function function LO:Open()
Inputs:				None
Outputs:			None
Description:	Opens the next item in the Que.
------------------------------------------------------------------------------------------------]]--
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
		self:SendToChat(zo_strformat("<<1>> Opened", self.Que[1].link))
		table.remove(self.Que, 1)
	end
end


--[[------------------------------------------------------------------------------------------------
function function LO:GetInventoryIndex()
Inputs:				None
Outputs:			slot 						- The slot containing the next item in the Que
Description:	Searches for and returns the slot number of the next item in the Que.
------------------------------------------------------------------------------------------------]]--
function LO:GetInventoryIndex()
	local bag = BAG_BACKPACK
	local slot = ZO_GetNextBagSlotIndex(bag)
	local item
	while slot do
		item = GetItemId(bag, slot)
		if HasItemInSlot(bag, slot)	and item == self.Que[1].id then
			self:DebugMsg(zo_strformat("<<1>> Found", self.Que[1].link))
			return slot
		end
		slot = ZO_GetNextBagSlotIndex(bag, slot)
	end
end


--[[------------------------------------------------------------------------------------------------
function LO:SendToChat(inputString, ...)
Inputs:				inputString			- The input string to be formatted and sent to chat.
							...							- More inputs to be placed on new lines within the same message.
Outputs:			None
Description:	Formats text to be sent to the chat box for the user. Only the first line gets the
							add-on prefix.
------------------------------------------------------------------------------------------------]]--
function LO:SendToChat(inputString, ...)
	if not self.SV.chatMsgEnabled then return end
	if inputString == false or inputString == "" then return end
	local Args = {...}
	local Output = {}
	table.insert(Output, zo_strformat("<<1>><<2>><<3>><<4>>", self.chatPrefix, self.chatTextColor, inputString, self.chatSuffix))
	if #Args > 0 then
		for i,v in ipairs(Args) do
		  table.insert(Output, zo_strformat("\n<<1>><<2>><<3>>", self.chatTextColor, v, self.chatSuffix))
		end
	end
	CS:AddMessage(table.concat(Output))
end


--[[------------------------------------------------------------------------------------------------
function function LO:BoolConvert(bool, returnType)
Inputs:				bool 						- input bool to convert
							returnType 			- how the output should be formated (optional, 1 default)
Outputs:			string 					- string containing the converted bool, or the input if not a bool
Description:	Returns a converted bool or the input if not a bool.
returnType: 	1 	- "true/false"
							2		- "on/off"
							3		- "yes/no"
							4		- "positive/negative"
------------------------------------------------------------------------------------------------]]--
function LO:BoolConvert(bool, returnType)
	local Responses = {
		{"true", "false"},
		{"on", "off"},
		{"yes", "no"},
		{"positive", "negative"},
	}

	if type(bool) == "boolean" then
		if not returnType then returnType = 1 end
		if bool then
			return Responses[returnType][1]
		else
			return Responses[returnType][2]
		end
	end
	return bool
end


--[[------------------------------------------------------------------------------------------------
function LO:DebugMsg(inputString)
Inputs:				inputString			- The debug string to print to chat
Outputs:			None
Description:	Checks if debugging mode is on and if so, sends the input message to chat.
------------------------------------------------------------------------------------------------]]--
function LO:DebugMsg(inputString)
	if not self.SV.debugMode then return end
	if inputString == false then return end
	self:SendToChat("[DEBUG] " .. inputString)
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