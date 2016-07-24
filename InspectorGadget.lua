-- InspectorGadget.lua
--   A gadget to improve access to information about players you encounter in the World of Warcraft
--     Hiketeia-Emerald Dream April 2016

-- # Libraries to consider TODO
--  * http://wow.curseforge.com/addons/libaboutpanel/
--  * http://www.wowace.com/addons/ace3/pages/getting-started/

-- TODO wait until after PLAYER_LOGIN finishes before doing this code to be sure it is ready?
local MountCache={};--  Stores our discovered mounts' spell IDs
for i=1,C_MountJournal.GetNumMounts() do--  Loop though all mounts
	local creatureName,spellid=C_MountJournal.GetMountInfo(i);--   Grab mount spell ID
	MountCache[spellid]={index = i, creatureName = creatureName, spellID = spellid};-- Register spell ID in our cache
end


function InspectorGadget_OnLoad(self)

end

-- Put a button on the screen to query what mount the target is on
local function IGMountDebugButton()
	-- WhatMount debugging
	local b = CreateFrame("Button", "WhatMountButton", UIParent, "UIPanelButtonTemplate")
	b:SetSize(120 ,22) -- width, height
	b:SetText("What Mount?")
	b:SetPoint("CENTER")
	b:SetScript("OnClick", function()
		IGMount_Report()
	end)
end

-- show the mount journal
local function IGMount_Show(index)
	if (not CollectionsJournal) then
		CollectionsJournal_LoadUI();
	end
	if (not CollectionsJournal:IsShown()) then
		ShowUIPanel(CollectionsJournal);
	end
	CollectionsJournal_SetTab(CollectionsJournal, 1);
	MountJournal_Select(index);
end


-- return a table of info about the mount the unit is on
function IGMount(unit)
	local i=1;--    Initialize at index 1
	if not unit then
		unit = "playertarget"
	end
	-- code originally from SDPhantom @ http://www.wowinterface.com/forums/showpost.php?p=314055&postcount=2
	while true do-- Infinite loop, we'll break manually
		local _,_,_,_,_,_,_,_,_,_,spellid=UnitBuff(unit,i);--   Grab buff info
		if spellid then--   If we have a buff, we have a spell ID
			if MountCache[spellid] then return MountCache[spellid]; end--   Return SpellID if mount is found
			i=i+1;--    Increment by 1 and try again
		else break; end--   Else break loop if no more buffs
	end
end

-- What mount is that person on?  Pop mount journal, and also give you the icon if you have it to place on your bar
function IGMount_Report()
	local mount = IGMount("playertarget")
	if mount then
		DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Mount reports: \124cffffd000\124Hspell:".. mount.spellID .. "\124h[" .. mount.creatureName .. "]\124h\124r");
		C_MountJournal.Pickup(mount.index)
		IGMount_Show(mount.index)
	else
		print "Inspector Gadget Mount reports: Not mounted"
	end
end

-- Mount the same mount as your target
-- TODO Future feature: register the player in question, and if they change their mount, you change yours too (if it is safe to do so etc.)
--      More for when you're waiting around for a pull, or sitting in the capital city etc and people are messing around with their collections
--      Maybe call it 'mirror' instead of 'clone'?
function IGMount_Clone()
	local mount = IGMount("playertarget")
	if mount then
		DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Mount cloning: \124cffffd000\124Hspell:".. mount.spellID .. "\124h[" .. mount.creatureName .. "]\124h\124r");
		C_MountJournal.Summon(mount.index)
	else
		print "Inspector Gadget Mount reports: Not mounted"
	end
end

-- # Inspect
-- 
-- http://wowprogramming.com/docs/api_categories#inspect
-- http://wow.gamepedia.com/API_CheckInteractDistance
-- http://wow.gamepedia.com/API_NotifyInspect
-- http://wow.gamepedia.com/API_InspectUnit
-- Code to monitor your own item level and notify you of a change http://www.wowinterface.com/forums/showpost.php?p=308065&postcount=7
-- Code to add an item level to the player tooltip: http://www.wowinterface.com/forums/showpost.php?p=304938&postcount=2
-- Internally, this is the code used on the default inspect screen for your own character to show your ilvl https://www.townlong-yak.com/framexml/19831/PaperDollFrame.lua#1458
-- Use Addon Messages to respond with the info rather than via inspect?  i.e. for iLvl if party members are using the addon too, get it from them?  Could we do account-wide stuff too?  i.e sure this shaman is only 701, but they have two toons which are 725 so cut them some slack?
-- Interface/AddOns/Blizzard_InspectUI
-- http://wow.gamepedia.com/API_GetItemTransmogrifyInfo
-- Couple other inspect addons to review: http://mods.curse.com/addons/wow/examiner, http://mods.curse.com/addons/wow/inspect-equip

function IGInspect_Show()
	if (UnitPlayerControlled("target") and CheckInteractDistance("target", 1) and not UnitIsUnit("player", "target")) then
		InspectUnit("target")
	end
end

-- WIP function to try and understand how the api calls work
--  ATM this only works for myself, and not other person.  Started thread @ http://www.wowinterface.com/forums/showthread.php?p=314771#post314771 to see if I'm missing something
function IGInspectTransmogDump()
	transmogSlots = { InspectHeadSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectWristSlot, InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot, InspectMainHandSlot, InspectSecondaryHandSlot }

	unit = "player"

	for i, slot in ipairs(transmogSlots) do
	   slotId = slot:GetID()
	   local isTransmogrified, canTransmogrify, cannotTransmogrifyReason, hasPending, hasUndo, visibleItemID, textureName = GetTransmogrifySlotInfo(slotId)
	   if isTransmogrified then
		  local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(visibleItemID)
		  local itemId = GetInventoryItemID(unit, slotId)
		  -- local itemLink = GetInventoryItemLink(unit, )
		  print (format("Slot %s is transmogrified to %s. %s", slotId, link, itemId))
	   end
	   
	end
end

-- WIP function to try and understand how the api calls work
--  ATM this only works for myself, and not other person.  Started thread @ http://www.wowinterface.com/forums/showthread.php?p=314771#post314771 to see if I'm missing something
function IGInspectTransmogDumpv2()
	CreateFrame( "GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate" ); -- Tooltip name cannot be nil

	local function ScanTooltipOfUnitSlotForTransmog(unit,slot)
	   local tooltip = MyScanningTooltip
	   local isTransmogrified = false
	   local itemName = nil
	   tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" ); -- does a ClearLines() already
	   tooltip:SetInventoryItem(unit,slot)
	   for i=1,MyScanningTooltip:NumLines() do
		  local left = _G["MyScanningTooltipTextLeft"..i]:GetText()
		  if left then
			 if isTransmogrified then
				-- The line after the Transmog header has been found will be the name
				-- might have to parse Illusion: Hidden
				itemName = left
				break -- return isTransmogrified, itemName
			 end
			 
			 if left == "Transmogrified to:" then -- Deal with localization - any better patterns to match?
				isTransmogrified = true
			 end
		  end
	   end
	   return isTransmogrified, itemName
	end

	transmogSlots = { InspectHeadSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectWristSlot, InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot, InspectMainHandSlot, InspectSecondaryHandSlot }

	-- Inspect the target manually before you try unless you've targetted yourself
	unit = "playertarget"

	for i, slot in ipairs(transmogSlots) do
	   slotId = slot:GetID()
	   
	   local isTransmogrified, itemName = ScanTooltipOfUnitSlotForTransmog(unit,slotId)
	   if isTransmogrified then
		  local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemName)
		  if link then
			 -- Can't call by itemName unless I have it in my bags... ugh!
			 print (format("Slot %s is transmogrified to %s.", slotId, link))
		  else
			 print (format("Slot %s is transmogrified to %s", slotId, itemName))
		  end
	   end
	end
end

-- Configuration for the slash command dispatcher
local IGCommandTable = {
	["mount"] = {
		["clone"] = function()
			IGMount_Clone()
		end,
		["report"] = function()
			IGMount_Report()
		end,
		[""] = function()  -- default
			IGMount_Report()
		end,
		["help"] = "Inspector Gadget mount commands: clone, report",
	},
	["help"] = "Inspector Gadget commands: mount",
}

-- slash command processor from Addon book
local function DispatchCommand(message, commandTable)
	local command, parameters = string.split(" ", message, 2)
	local entry = commandTable[command:lower()]
	local which = type(entry)
	
	if which == "function" then
		entry(parameters)
	elseif which == "table" then -- nested commands
		DispatchCommand(parameters or "", entry)
	elseif which == "string" then
		print(entry)
	elseif message ~= "help" then -- if any command given that we don't have in the table, give the help message if there is one
		DispatchCommand("help", commandTable)
	end
end

-- Registering slash commands
SLASH_INSPECTORGADGET1 = "/inspectorgadget"
SLASH_INSPECTORGADGET2 = "/ig"
SlashCmdList["INSPECTORGADGET"] = function(message)
	DispatchCommand(message, IGCommandTable)
end