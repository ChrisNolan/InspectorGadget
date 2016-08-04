-- QQ
--
--   Bunch of snippets of code, for testing/debugging/experimenting with
--
--   Not used in the addon itself at all.  Wonder if there is a way to exclude a file from the release package but keep in the dev repo?
--

-- playing around... should probably fork this if I don't finish it tonight?
-- https://github.com/tomrus88/BlizzardInterfaceCode/blob/8d22f338783f1a9722552e662904c3c0eaf46d75/Interface/FrameXML/DressUpFrames.lua

local function MessingAround1()
	-- storing stuff I'm tossing into wowlua trying to get a handle on the un-documented features.
	local dressUpModel = CreateFrame('DressUpModel')
	DressUpSources(C_TransmogCollection.GetInspectSources())
	DressUpModel:TryOn(9610)
	print(DressUpModel:GetSlotTransmogSources(1))
	print(DressUpModel:GetSlotTransmogSources(3))
	
	print(C_TransmogCollection.GetAppearanceSourceInfo(9610))
	
	print(C_TransmogCollection.GetAppearanceSourceInfo(30469))
	
	appearanceSources = C_TransmogCollection.GetInspectSources()

	print("   ")

	for i = 1, #appearanceSources do
		if ( appearanceSources[i] and appearanceSources[i] ~= NO_TRANSMOG_SOURCE_ID ) then
			-- DressUpModel:TryOn(appearanceSources[i]);
			print(C_TransmogCollection.GetAppearanceSourceInfo(appearanceSources[i]))
		end
	end

print(" ")
print(C_TransmogCollection.GetAppearanceSourceInfo(9610))
print("Sources: ")
tprint(C_TransmogCollection.GetAppearanceSources(9610)) -- appearanceID returns a table of sourceType, name, isCollected, sourceID, quality
print("Appearance Info: ")
tprint(C_TransmogCollection.GetAppearanceInfoBySource(20754)) -- sourceID

	link = "|cffff80ff|Htransmogappearance:33287|h[Rifle Commander's Eyepatch]|h|r"
	_, sourceID = strsplit(":", link);
	print(sourceID)
	sourceID=tonumber(sourceID)
	print(sourceID)
	
link = "|cffff80ff|Htransmogappearance:33287|h[Rifle Commander's Eyepatch]|h|r"
_, sourceID = strsplit(":", link);
print(sourceID)
sourceID=tonumber(sourceID)
print(sourceID)
fixedlink = GetFixedLink(link)
printable = gsub(fixedlink, "\124", "\124\124");
print(printable)
linkString = string.match(link, "transmogappearance[%-?%d:]+")
print(linkString)

CollectionsJournal_LoadUI();
for i = 1, 11 do
   slot = WardrobeCollectionFrame_GetSlotFromCategoryID(i)
   slotg = _G[slot]
   print(format("%s %s %s.", i, slot, slotg))
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
		  DEFAULT_CHAT_FRAME:AddMessage(format("Slot %s is transmogrified to %s. %s", slotId, link, itemId))
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

local function MessingAround3()
	-- inspect someone first
	appearanceSources = C_TransmogCollection.GetInspectSources()

	if appearanceSources then
	   for i = 1, #appearanceSources do
		  if ( appearanceSources[i] and appearanceSources[i] ~= NO_TRANSMOG_SOURCE_ID ) then
			 categoryID , appearanceID, _, _, _, itemLink, appearanceLink, _ = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSources[i])
			 DEFAULT_CHAT_FRAME:AddMessage(format("%s is item %s (appearance %s)",categoryID, itemLink, appearanceLink))
		  end
	   end
	end
end

-- a table print function i took from some website to help me learn more about the results in wowlua ... 
local function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end

-- from http://us.battle.net/wow/en/forum/topic/20747675037
local function mountdump()
	local mounts = C_MountJournal.GetMountIDs()
	for i=1,#mounts do
		local creatureName, spellID, icon, active, isUsable, sourceType = C_MountJournal.GetMountInfoByID(mounts[i])
		print(creatureName,"has a mountID of ",mounts[i])
	end
end


-- notes on announcing new transmog...

	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" ) then
		if ( not CollectionsJournal ) then
			local latestAppearanceID, latestAppearanceCategoryID = C_TransmogCollection.GetLatestAppearance();
			if ( latestAppearanceID and latestAppearanceID ~= self.latestAppearanceID ) then
				self.latestAppearanceID = latestAppearanceID;
				SetCVar("petJournalTab", 5);
			end
		end

		
		elseif ( event == "TRANSMOG_COLLECTION_UPDATED") then
		WardrobeCollectionFrame_CheckLatestAppearance(true);
		if ( self:IsVisible() ) then
			WardrobeCollectionFrame_GetVisualsList();
			WardrobeCollectionFrame_FilterVisuals();
			WardrobeCollectionFrame_SortVisuals();
			WardrobeCollectionFrame_Update();
end

function WardrobeCollectionFrame_CheckLatestAppearance(changeTab)
	local latestAppearanceID, latestAppearanceCategoryID = C_TransmogCollection.GetLatestAppearance();
	if ( WardrobeCollectionFrame.latestAppearanceID ~= latestAppearanceID ) then
		WardrobeCollectionFrame.latestAppearanceID = latestAppearanceID;
		WardrobeCollectionFrame.jumpToLatestAppearanceID = latestAppearanceID;
		WardrobeCollectionFrame.jumpToLatestCategoryID = latestAppearanceCategoryID;

		if ( changeTab and not CollectionsJournal:IsShown() ) then
			CollectionsJournal_SetTab(CollectionsJournal, 5);
		end
	end
end

function appearanceLinkTest()
	-- appearances for Yuz to test 13602/
	local sources = C_TransmogCollection.GetAppearanceSources(13602)
	-- print(string.gsub("asfsdf[blue]jweoiur","%[.*%]","[orange]"))
	local collectedNames = {}
	local collectedNamesStr = ""
	local unCollectedNames = {}
	local unCollectedNamesStr = ""
	local sourceID
	for k, source in pairs(sources) do
		-- source.{sourceType, name, isCollected, sourceID, quality}
		if source.isCollected then
			if not sourceID then sourceID = source.sourceID end
			tinsert(collectedNames, source.name)
			print("Collected " .. source.name)
		else
			tinsert(unCollectedNames, source.name)
			print("Uncollected " .. source.name)
		end
	end
	print("Collected ".. tbl2str(collectedNames))
	print("Uncollected ".. tbl2str(unCollectedNames))
	local appearanceLink = select(7, C_TransmogCollection.GetAppearanceSourceInfo(sourceID))
	print("The escaped link is: ", appearanceLink:gsub("|", "||"))
	-- print(string.gsub("asfsdf[blue]jweoiur","%[.*%]","[orange]"))
	appearanceLink = string.gsub(appearanceLink, "%[.*%]", "["..self.tbl2str(collectedNames).."]")
	print("The escaped link is: ", appearanceLink:gsub("|", "||"))

end

function tbl2str(t)
	local s = ""
	local delimiter = " / "
	for k,v in pairs(t) do
		s = s .. v .. delimiter
	end
	return string.gsub(s, delimiter .. "$", "")
end

-- print("|cffff80ffThis is pink |cff80ff80and this is green|r but now it should be pink again|r") -- it isn't

function TestPrintcf()
	distribution = "PARTY"
	sender = "Yuz"
	message = "This should work?"
	print(CHAT_COLOR[distribution].rgb)

	InspectorGadgetzan:Printcf(InspectorGadgetzan:ChatFrame(), CHAT_COLOR[distribution].intensity, "[%s] %s", sender, message)

	InspectorGadgetzan:Printf(InspectorGadgetzan:ChatFrame(), "[%s] %s", sender, "No color given")
end

-- IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY" or "SAY"

groupFallthrough = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY" or false
if groupFallthrough then self:SendCommMessage("NewAppearance", share_msg, groupFallthrough) end
InspectorGadgetzan:SendCommMessage("TestMessage", "Anybody Home?", "PARTY")
InspectorGadgetzan:SendCommMessage("NewAppearance", "Anybody Home?", "PARTY")

function testTableAdd(count)
   local t = {}
   for i = 1, count do
      print("Adding "..i)
      t[i] = "Yes please ".. i
      print(#t)
   end
   print("We counted "..#t.." times")
   return t
end
print(testTableAdd(5))
function testTableAddOutOfOrder()
   local t = {}
   t[3] = "three"
   t[5] = "five"
   t[15] = "wow"
   print("We counted "..#t.." times")
   return t
end
print(testTableAddOutOfOrder())

IGNewAppearanceLearnedAlertSystem:AddAlert("Appearance Link", nil, 9610)

-- good sounds..

PlaySound("UI_OrderHall_Talent_Ready_Toast")
PlaySound("UI_Garrison_Toast_FollowerGained")
PlaySound("UI_Garrison_Toast_MissionComplete");
PlaySound("UI_igStore_PurchaseDelivered_Toast_01");
PlaySound("UI_DigsiteCompletion_Toast");
PlaySoundKitID(31578);	--UI_EpicLoot_Toast
PlaySoundKitID(51402);	--UI_Raid_Loot_Toast_Lesser_Item_Won
PlaySoundKitID(51561);	-- UI_Warforged_Item_Loot_Toast
PlaySound("LFG_Rewards")
PlaySound("UI_LegendaryLoot_Toast");
PlaySound("UI_Professions_NewRecipeLearned_Toast");