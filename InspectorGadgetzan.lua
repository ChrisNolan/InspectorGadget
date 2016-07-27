-- InspectorGadget.lua
--   A gadget to improve access to information about players you encounter in the World of Warcraft
--     Hiketeia-Emerald Dream April 2016

-- # Libraries to consider TODO
--  * http://wow.curseforge.com/addons/libaboutpanel/
--  * http://www.wowace.com/addons/ace3/pages/getting-started/

-- make sure the addon I'm parenting to in my xml is loaded, as it is load on demand
--   some other thoughts @ http://www.wowinterface.com/forums/showthread.php?t=39775&highlight=load+demand 
--   maybe split the wardrobe stuff out into a sub-addon and have it LoadWith the inspect stuff?
LoadAddOn("Blizzard_InspectUI")

local debugLevel = nil

InspectorGadget = CreateFrame("Frame") -- TODO if I have this here, do I need the .xml file?
local addon = InspectorGadget

local MountCache={};--  Stores our discovered mounts' spell IDs

local function buildMountCache()
	for i = 1, C_MountJournal.GetNumMounts() do --  Loop though all mounts
		local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i);--   Grab mount spell ID
		if spellID then
			MountCache[spellID] = { -- Register spell ID in our cache
				index = i,
				creatureName = creatureName,
				spellID = spellID,
				mountID = mountID
			};
		end
		-- TODO manually add class specific mounts that aren't in everyone's journal?  Like "Felsteed"
		--   Mounts that have trouble ATM: Ancient Frostsabre
	end
end

function InspectorGadget_OnLoad(self)

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
	local i = 1; --    Initialize at index 1
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
function IGMount_Report(mount)
	if mount == nil then
		mount = IGMount("playertarget")
	end
	if mount then
		DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Mount reports: \124cffffd000\124Hspell:".. mount.spellID .. "\124h[" .. mount.creatureName .. "]\124h\124r");
		C_MountJournal.Pickup(mount.index)
		IGMount_Show(mount.index)
	else
		DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Mount reports: Not mounted")
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
		C_MountJournal.SummonByID(mount.mountID)
	else
		DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Mount reports: Not mounted - Unable to clone.")
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
-- 7.0 changed a bunch.... current research:
--    InspectPaperDoll - InspectpaperDollViewButton_OnClick() calling C_TransmogCollection.GetInspectSources()
--    FrameXML/DressUpFrames.lua / DressUpFrame_Show() + DressUpSources()


function IGInspect_Show()
	if (UnitPlayerControlled("target") and CheckInteractDistance("target", 1) and not UnitIsUnit("player", "target")) then
		InspectUnit("target")
		-- TODO how do I get the INSPECT_READY event here?  do a RegisterEvent?
		IGWardrobe_OnLoad()
		InspectFrameTab_OnClick(InspectFrameTab5)
	end
end

local transmogCategories = {}
transmogCategories[1] = {name = "Head", slot = "Head"};
transmogCategories[2] = {name = "Shoulder", slot = "Shoulder"};
transmogCategories[3] = {name = "Back", slot = "Back"};
transmogCategories[4] = {name = "Chest", slot = "Chest"};
transmogCategories[5] = {name = "Shirt", slot = "Shirt"};
transmogCategories[6] = {name = "Tabard", slot = "Tabard"};
transmogCategories[7] = {name = "Wrist", slot = "Wrist"};
transmogCategories[8] = {name = "Hands", slot = "Hands"};
transmogCategories[9] = {name = "Waist", slot = "Waist"};
transmogCategories[10] = {name = "Legs", slot = "Legs"};
transmogCategories[11] = {name = "Feet", slot = "Feet"};
transmogCategories[12] = {name = "Wand", slot = "MainHand"};
transmogCategories[13] = {name = "One-Handed Axes", slot = "MainHand"};
transmogCategories[14] = {name = "One-Handed Swords", slot = "MainHand"};
transmogCategories[15] = {name = "One-Handed Maces", slot = "MainHand"};
transmogCategories[16] = {name = "Daggers", slot = "MainHand"};
transmogCategories[17] = {name = "Fist Weapons", slot = "MainHand"};
transmogCategories[18] = {name = "Shields", slot = "SecondaryHand"};
transmogCategories[19] = {name = "Held In Off-hand", slot = "SecondaryHand"};
transmogCategories[20] = {name = "Two-Handed Axes", slot = "MainHand"};
transmogCategories[21] = {name = "Two-Handed Swords", slot = "MainHand"};
transmogCategories[22] = {name = "Two-Handed Maces", slot = "MainHand"};
transmogCategories[23] = {name = "Staves", slot = "MainHand"};
transmogCategories[24] = {name = "Polearms", slot = "MainHand"};
transmogCategories[25] = {name = "Bows", slot = "MainHand"};
transmogCategories[26] = {name = "Guns", slot = "MainHand"};
transmogCategories[27] = {name = "Crossbows", slot = "MainHand"};
transmogCategories[28] = {name = "Warglaives", slot = "MainHand"};

-- Moves the inspect sources into the buttons and text fields 
--   if debugLevel is set, it'll also dump them to the chat
local function IGInspectSourcesDump()

	appearanceSources = C_TransmogCollection.GetInspectSources()

	if appearanceSources then
		if debugLevel then DEFAULT_CHAT_FRAME:AddMessage("Inspector Gadget Appearances Dump") end
		for i = 1, #appearanceSources do
			if ( appearanceSources[i] and appearanceSources[i] ~= NO_TRANSMOG_SOURCE_ID ) then
				categoryID , appearanceID, unknownBoolean1, uiOrder, unknownBoolean2, itemLink, appearanceLink, unknownFlag = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSources[i])
				if debugLevel then
					DEFAULT_CHAT_FRAME:AddMessage(format("%s is item %s (appearance %s)", transmogCategories[categoryID].name, itemLink, appearanceLink))
					-- print (format("unknownBoolean1 %s, uiOrder %s, unknownBoolean2 %s, unknownFlag %s", tostring(unknownBoolean1), tostring(uiOrder), tostring(unknownBoolean2), tostring(unknownFlag))) -- TODO figure out those other fields
				end
				-- TODO this is really ugly... iterate it ... is _G[] what I need?
				-- local slot = WardrobeCollectionFrame_GetSlotFromCategoryID(categoryID); -- HMPF, this is nil sometimes... guess I won't use it.  hardcode my transmogCategories table for now
				if     categoryID == 1 then
					InspectorGadgetWardrobeHeadSlot.itemLink = itemLink
					InspectorGadgetWardrobeHeadText.appearanceLink = appearanceLink
				elseif categoryID == 2 then 
					InspectorGadgetWardrobeShoulderSlot.itemLink = itemLink
					InspectorGadgetWardrobeShoulderText.appearanceLink = appearanceLink
				elseif categoryID == 3 then
					InspectorGadgetWardrobeBackSlot.itemLink = itemLink
					InspectorGadgetWardrobeBackText.appearanceLink = appearanceLink
				elseif categoryID == 4 then
					InspectorGadgetWardrobeChestSlot.itemLink = itemLink
					InspectorGadgetWardrobeChestText.appearanceLink = appearanceLink
				elseif categoryID == 5 then
					InspectorGadgetWardrobeShirtSlot.itemLink = itemLink
					InspectorGadgetWardrobeShirtText.appearanceLink = appearanceLink
				elseif categoryID == 6 then
					InspectorGadgetWardrobeTabardSlot.itemLink = itemLink
					InspectorGadgetWardrobeTabardText.appearanceLink = appearanceLink
				elseif categoryID == 7 then
					InspectorGadgetWardrobeWristSlot.itemLink = itemLink
					InspectorGadgetWardrobeWristText.appearanceLink = appearanceLink
				elseif categoryID == 8 then
					InspectorGadgetWardrobeHandsSlot.itemLink = itemLink
					InspectorGadgetWardrobeHandsText.appearanceLink = appearanceLink
				elseif categoryID == 9 then
					InspectorGadgetWardrobeWaistSlot.itemLink = itemLink
					InspectorGadgetWardrobeWaistText.appearanceLink = appearanceLink
				elseif categoryID ==10 then
					InspectorGadgetWardrobeLegsSlot.itemLink = itemLink
					InspectorGadgetWardrobeLegsText.appearanceLink = appearanceLink
				elseif categoryID ==11 then
					InspectorGadgetWardrobeFeetSlot.itemLink = itemLink
					InspectorGadgetWardrobeFeetText.appearanceLink = appearanceLink
				end
				if (transmogCategories[categoryID].slot == "MainHand") then
					-- if it already has something in the mainhand, assume it is a dualwielder
					if InspectorGadgetWardrobeMainHandSlot.itemLink then
						InspectorGadgetWardrobeSecondaryHandSlot.itemLink = itemLink
						InspectorGadgetWardrobeSecondaryHandText.appearanceLink = appearanceLink
					else
						InspectorGadgetWardrobeMainHandSlot.itemLink = itemLink
						InspectorGadgetWardrobeMainHandText.appearanceLink = appearanceLink
					end
				elseif transmogCategories[categoryID].slot == "SecondaryHand" then
					InspectorGadgetWardrobeSecondaryHandSlot.itemLink = itemLink
					InspectorGadgetWardrobeSecondaryHandText.appearanceLink = appearanceLink
				end
			end
		end
	else
		print("Inspector Gadget not ready")
	end
end

-- Init the button on the screen
--   Putting icons on the empty slots
--   Taken from InspectPaperDoll.lua
function IGWardrobeItemSlotButton_OnLoad(self)
	local slotName = self:GetName()
	slotName = string.gsub(slotName, "InspectorGadgetWardrobe", "Inspect")
	local id
	id, textureName, _ = GetInventorySlotInfo(strsub(slotName,8))
	self:SetID(id)
	SetItemButtonTexture(self, textureName)
	self.backgroundTextureName = textureName
end

-- Deals with Tooltips when you mouse over an ItemSlot
function IGWardrobeItemSlotButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local tooltipSet = false
	if self.itemLink then
		tooltipSet = GameTooltip:SetHyperlink(self.itemLink)
		-- I want to catch of hte tooltip doesn't get set, but the flag needs work
	else
		local text = _G[strupper(strsub(self:GetName(), 24))]; -- 24 is hardcoded... the length of the object name to strip off the front
		GameTooltip:SetText(text);
	end
	CursorUpdate(self);
end

-- Click handler to launch the wardrobe collection window
function IGWardrobeItemTextButton_OnClick(self)
	-- code from FrameXML/ItemRef.lua's "transmogappearance" handler
	if ( not CollectionsJournal ) then
		CollectionsJournal_LoadUI();
	end
	if ( CollectionsJournal ) then
		if self.appearanceLink then
			-- what is the 'standard' way of extracting the 'hyperlink' from the full link?
			local linkString = string.match(self.appearanceLink, "transmogappearance[%-?%d:]+")
			-- debug the whole jumpToVisualID stuff from https://github.com/tomrus88/BlizzardInterfaceCode/blob/49f059f549c48d5811b13771a52c8a4cfff3b227/Interface/AddOns/Blizzard_Collections/Blizzard_Wardrobe.lua
			WardrobeCollectionFrame_OpenTransmogLink(linkString);
		end
	end
end

local function IGWardrobeFrame_UpdateButtons()
	-- don't like code like this... snazzy it up some day
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeHeadSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeShoulderSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeBackSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeChestSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeShirtSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeTabardSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeWristSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeHandsSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeWaistSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeLegsSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeFeetSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeMainHandSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetWardrobeSecondaryHandSlot);
	
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeHeadText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeShoulderText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeBackText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeChestText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeShirtText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeTabardText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeWristText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeHandsText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeWaistText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeLegsText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeFeetText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeMainHandText);
	IGWardrobeItemTextButton_Update(InspectorGadgetWardrobeSecondaryHandText);
	
	-- Set the mount header info
	local mount = IGMount(InspectFrame.unit)
	if mount then
		local button = InspectorGadgetWardrobeMountMicroButton
		local prefix = "Interface\\Buttons\\UI-MicroButton-";
		local name = 'Mounts'
		button:SetNormalTexture(prefix..name.."-Up");
		button:SetPushedTexture(prefix..name.."-Down");
		button:SetDisabledTexture(prefix..name.."-Disabled");
		button:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight")
		button.tooltipText = "View " .. mount.creatureName .. " in Collections Journal"
		button.mount = mount
		button:Show()
		InspectorGadgetWardrobeMountText:SetText("Currently mounted on " .. mount.creatureName)
		InspectorGadgetWardrobeMountText:Show()
	else
		InspectorGadgetWardrobeMountMicroButton:Hide()
		InspectorGadgetWardrobeMountText:Hide()
	end
	
end

-- Opposite of UpdateButtons
local function IGWardrobeFrame_ClearButtons()
	-- don't like code like this... snazzy it up some day
	InspectorGadgetWardrobeHeadSlot.itemLink = nil
	InspectorGadgetWardrobeShoulderSlot.itemLink = nil
	InspectorGadgetWardrobeBackSlot.itemLink = nil
	InspectorGadgetWardrobeChestSlot.itemLink = nil
	InspectorGadgetWardrobeShirtSlot.itemLink = nil
	InspectorGadgetWardrobeTabardSlot.itemLink = nil
	InspectorGadgetWardrobeWristSlot.itemLink = nil
	InspectorGadgetWardrobeHandsSlot.itemLink = nil
	InspectorGadgetWardrobeWaistSlot.itemLink = nil
	InspectorGadgetWardrobeLegsSlot.itemLink = nil
	InspectorGadgetWardrobeFeetSlot.itemLink = nil
	InspectorGadgetWardrobeMainHandSlot.itemLink = nil
	InspectorGadgetWardrobeSecondaryHandSlot.itemLink = nil

	InspectorGadgetWardrobeHeadText.appearanceLink= nil
	InspectorGadgetWardrobeShoulderText.appearanceLink= nil
	InspectorGadgetWardrobeBackText.appearanceLink= nil
	InspectorGadgetWardrobeChestText.appearanceLink= nil
	InspectorGadgetWardrobeShirtText.appearanceLink= nil
	InspectorGadgetWardrobeTabardText.appearanceLink= nil
	InspectorGadgetWardrobeWristText.appearanceLink= nil
	InspectorGadgetWardrobeHandsText.appearanceLink= nil
	InspectorGadgetWardrobeWaistText.appearanceLink= nil
	InspectorGadgetWardrobeLegsText.appearanceLink= nil
	InspectorGadgetWardrobeFeetText.appearanceLink= nil
	InspectorGadgetWardrobeMainHandText.appearanceLink= nil
	InspectorGadgetWardrobeSecondaryHandText.appearanceLink= nil
end

-- Change the ItemSlot to match the links attached to it
function IGWardrobeItemSlotButton_Update(button)
	local unit = InspectFrame.unit;
	local textureName;
	if button.itemLink then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(button.itemLink)
		local itemID = GetItemInfoInstant(itemLink)
		textureName = itemTexture
	end
	if ( textureName ) then
		SetItemButtonTexture(button, textureName);
		button.hasItem = 1;
		SetItemButtonQuality(button, itemRarity, itemID);
	else
		textureName = button.backgroundTextureName;
		SetItemButtonTexture(button, textureName);
		SetItemButtonCount(button, 0);
		button.IconBorder:Hide();
		button.hasItem = nil;
	end
	if ( GameTooltip:IsOwned(button) ) then
		GameTooltip:Hide();
	end
end

-- Change the ItemText to match the links attached to it
function IGWardrobeItemTextButton_Update(button)
	local textureName;
	if button.appearanceLink then
		button:SetText(button.appearanceLink)
		button:Show()
	else
		button:Hide()
	end
	if ( GameTooltip:IsOwned(button) ) then
		GameTooltip:Hide();
	end
end

-- OnLoad of the Inspect tab
function IGWardrobe_OnLoad()
	if ( not CollectionsJournal ) then
		CollectionsJournal_LoadUI();
	end
	IGWardrobeFrame_ClearButtons()
	IGInspectSourcesDump()
	IGWardrobeFrame_UpdateButtons()
end

-- Add an extra 'tab' to the bottom of the InspectFrame
--   very problematic to other addons that also add tabs?
local function createInspectFrameTab()
	-- TODO the LoadAddon stuff messed up the highlighting of this this button... come back to check this before commit
	if not InspectFrameTab5 then
		INSPECTFRAME_SUBFRAMES[5] = "InspectorGadgetWardrobeFrame";
		PanelTemplates_SetNumTabs(InspectFrame, 5);
		InspectFrameTab5 = CreateFrame("Button", "InspectFrameTab5", InspectFrame, "CharacterFrameTabButtonTemplate")
		InspectFrameTab5:SetID(5)
		InspectFrameTab5:SetPoint("LEFT", InspectFrameTab4, "RIGHT", -16, 0)
		InspectFrameTab5:SetText("IG")
		InspectFrameTab5:SetScript("OnClick", function(self) IGWardrobe_OnLoad(); InspectFrameTab_OnClick(self); end)
		InspectFrameTab5:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT");GameTooltip:SetText("Wardrobe - Inspector Gadget", 1.0,1.0,1.0 );end)
		InspectFrameTab5:SetScript("OnLeave", GameTooltip_Hide)
	end
end



--------------------------------------------------------------------------------
-- Event Handler
--
local events = {}

function events:INSPECT_READY(...)
	createInspectFrameTab()
end

function events:PLAYER_LOGIN(...)
	buildMountCache()
end

addon:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...)
end)

for k,_ in pairs(events) do
	addon:RegisterEvent(k)
end


-- Configuration for the slash command dispatcher
local IGCommandTable = {
	["inspect"] = function()
		IGInspect_Show()
	end,
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
	["help"] = "Inspector Gadget commands: inspect, mount",
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