-- InspectorGadgetzan.lua
--   A gadget to improve access to information about players you encounter in the World of Warcraft
--     Hiketeia-Emerald Dream April 2016

-- # Libraries to consider TODO
--  * http://wow.curseforge.com/addons/libaboutpanel/
--  * http://www.wowace.com/addons/ace3/pages/getting-started/

--------
-- Upvalues
--   To improve performance, the addon has its own copy of some globals

local _G = _G
local C_MountJournal = C_MountJournal
local C_TransmogCollection = C_TransmogCollection
local CheckInteractDistance = CheckInteractDistance
local CreateFrame = CreateFrame
local CursorUpdate = CursorUpdate
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetInventorySlotInfo = GetInventorySlotInfo
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local GameTooltip = GameTooltip
local InspectUnit = InspectUnit
local NO_TRANSMOG_SOURCE_ID = NO_TRANSMOG_SOURCE_ID
local SetItemButtonTexture = SetItemButtonTexture
local ShowUIPanel = ShowUIPanel
local strsub = strsub
local strupper = strupper
local UnitBuff = UnitBuff
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled

-- Lua APIs
local tconcat, tostring, select = table.concat, tostring, select
local type, pairs, error = type, pairs, error
local format, strfind, strsub = string.format, string.find, string.sub
local max = math.max

-- Chat colors
local CHAT_COLOR = {}
CHAT_COLOR["SYSTEM"]		= {
	["hex"] = "FFFF00",
	["rgb"] = {
		["r"] = 255, ["g"] = 255, ["b"] = 0,
	},
	["intensity"] = {
		["r"] = 1, ["g"] = 1, ["b"] = 0,
	},
}
CHAT_COLOR["PARTY"]		= {
	["hex"] = "AAAAFF",
	["rgb"] = {
		["r"] = 170, ["g"] = 170, ["b"] = 255,
	},
	["intensity"] = {
		["r"] = 0.666666667, ["g"] = 0.666666667, ["b"] = 1,
	},
}
CHAT_COLOR["RAID"]		= {
	["hex"] = "FF7F00",
	["rgb"] = {
		["r"] = 255, ["g"] = 127, ["b"] = 0,
	},
	["intensity"] = {
		["r"] = 1, ["g"] = 0.498039216, ["b"] = 0,
	},
}
CHAT_COLOR["GUILD"]		= {
	["hex"] = "40FF40",
	["rgb"] = {
		["r"] = 64, ["g"] = 255, ["b"] = 64,
	},
	["intensity"] = {
		["r"] = 0.250980392, ["g"] = 1, ["b"] = 0.250980392,
	},
}
CHAT_COLOR["WHISPER"]		= {
	["hex"] = "FF80FF",
	["rgb"] = {
		["r"] = 255, ["g"] = 128, ["b"] = 255,
	},
	["intensity"] = {
		["r"] = 1, ["g"] = 0.501960784, ["b"] = 1,
	},
}
CHAT_COLOR["INSTANCE_CHAT"] = CHAT_COLOR["PARTY"]

local BLUE =   "|cff15abff"
--local BLUE_GREEN = "|cff009e73"
--local PINK = "|cffcc79a7"
--local ORANGE = "|cffe69f00"
local RED_ORANGE = "|cffff9333"
local YELLOW = "|cfff0e442"
local GRAY =   "|cff888888"



-- make sure the addon I'm parenting to in my xml is loaded, as it is load on demand
--   some other thoughts @ http://www.wowinterface.com/forums/showthread.php?t=39775&highlight=load+demand 
--   more ideas @ http://www.wowinterface.com/forums/showthread.php?t=32654&highlight=InspectUnit
--   maybe split the wardrobe stuff out into a sub-addon and have it LoadWith the inspect stuff?
LoadAddOn("Blizzard_InspectUI")

local debugLevel = nil

local addonName = ...
local addonTitle = select(2, GetAddOnInfo(addonName))
InspectorGadgetzan = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local addon = InspectorGadgetzan

-- configuration options
local options = {
	name = addonName,
	desc = nil,
	handler = InspectorGadgetzan,
	type = 'group',
	args = {
		minimap = {
			name = 'Minimap',
			type = 'group',
			args = {
				hide = {
					type = 'toggle',
					name = 'Hide Minimap Icon',
					desc = 'Hide the Minimap Icon for ' .. addonTitle,
					set = 'optionsToggleMinimap',
					get = function(info) return InspectorGadgetzan.db.profile.minimap.hide end,
					width = 'full', -- this keeps the checkboxes on one line each
				},
			},
		},
		pickupMount = {
			type = 'toggle',
			name = 'Pickup Mount on Report',
			desc = 'If you have the mount you are inspecting, would you like the mount icon to be added automatically to your mouse cursor so you can place on a toolbar',
			set = function(info, val) InspectorGadgetzan.db.profile.pickupMount = not InspectorGadgetzan.db.profile.pickupMount end,
			get = function(info) return InspectorGadgetzan.db.profile.pickupMount or false end,
			width = 'full', -- this keeps the checkboxes on one line each
		},
	},
}
local defaults = {
	profile = {
		minimap = {
			hide = false,
			-- setting a default position - the idea is so it won't be buried under all the other icons that start in the same spot which the user never moves
			--   there is some concern this might break in non-stand UIs...
			minimapPos = 11.8886764296701,
		},
		pickupMount = false,
		chatframeName = "Inspector Gadgetzan",
	}
}
local optionsTable = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, nil)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Setup a LibDataBroker interface
--   docs @ http://www.wowace.com/addons/libdbicon-1-0/
--   LibDataBroker work originally submitted by VincentSDSH
addon.LDBstub = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = 'launcher',
	label = tostring(addonName),
	text = "",
	icon = "Interface/icons/inv_helm_misc_fireworkpartyhat",
	OnClick = function(self, button)
		InspectorGadgetzan.LDBstub = self
		if button=="LeftButton" then
			if IsAltKeyDown() then
				InspectorGadgetzan:OpenConfig()
			else
				IGInspect_Show()
			end
		elseif button=="RightButton" then
			if IsShiftKeyDown() then
				IGMount_Clone()
			else
				IGMount_Report()
			end			
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine("|cFFFFFFFFInspector Gadgetzan|r")
		tooltip:AddLine("Click to Inspect Wardrobe of target")
		tooltip:AddLine("Alt-Click to open the options")
		tooltip:AddLine("Right-Click to Inspect their Mount")
		tooltip:AddLine("Shift-Right-Click to Mount their Mount")
	end,
})
addon.icon = LibStub("LibDBIcon-1.0")

function InspectorGadgetzan:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(addonName .. "DB", defaults, true) -- use global profile called 'Default'
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AceConfigDialog:AddToBlizOptions(addonName, addonTitle)
	self.icon:Register(addonName, addon.LDBstub, self.db.profile.minimap)
	self:RegisterComm("NewAppearance")
end

function InspectorGadgetzan:OnEnable()
    -- Called when the addon is enabled
end

function InspectorGadgetzan:OnDisable()
    -- Called when the addon is disabled
end

function InspectorGadgetzan:optionsToggleMinimap(info, val)
	InspectorGadgetzan.db.profile.minimap.hide = not InspectorGadgetzan.db.profile.minimap.hide
	if self.db.profile.minimap.hide then
		self.icon:Hide(addonName)
	else
		self.icon:Show(addonName)
	end
end

function InspectorGadgetzan:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory(addonTitle)
	-- need to call it a second time as there is a bug where the first time it won't switch - need Blizzard to fix
	--   there is a function available in !BlizzBugsSuck which lets the single call work.  I'll stick with my kludge for now
	InterfaceOptionsFrame_OpenToCategory(addonTitle)
end

function InspectorGadgetzan:ChatFrame()
	local name = self.db.profile.chatframeName
	local frame = DEFAULT_CHAT_FRAME
	for i = 1, NUM_CHAT_WINDOWS do
		n = FCF_GetChatWindowInfo(i)
		if n == name then
			frame = _G["ChatFrame"..i]
		end
	end
	return frame
end

function InspectorGadgetzan:OnCommReceived(prefix, message, distribution, sender)
    -- process the incoming message
	if prefix == "NewAppearance" then
		if sender ~= UnitName("player") then
			if message ~= self.lastCommMessage then
				-- TODO make the 'sender' in the message a player link
				self:Printcf(self:ChatFrame(), CHAT_COLOR[distribution].intensity, "[%s] %s|r", sender, message)
			end
			self.lastCommMessage = message
		end
	else
		if debugLevel then self:Print(prefix..message..distribution..sender) end
	end
end

--[[ -- I'm using just the text of the tooltip return atm because these were tricky to wrap my head around.  I like the idea of using them though so let's keep them around for the time being

function InspectorGadgetzan:IsValidAppearanceForCharacter(itemLink)
	if CanIMogIt and itemLink then
		return CanIMogIt:IsValidAppearanceForCharacter(itemLink)
	else
		return false
	end
end

function InspectorGadgetzan:PlayerKnowsTransmog(itemLink)
	if CanIMogIt then
		return CanIMogIt:PlayerKnowsTransmog(itemLink)
	end
end

function InspectorGadgetzan:CharacterCanLearnTransmog(itemLink)
	if CanIMogIt then
		CanIMogIt:CharacterCanLearnTransmog(itemLink)
	end
end

function InspectorGadgetzan:CanIMogItGetTooltipText(itemLink)
	if CanIMogIt then
		CanIMogIt:GetTooltipText(itemLink)
	end
end
]]--

local MountCache={};--  Stores our discovered mounts' spell IDs

local function buildMountCache()
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, mountID
	for i = 1, C_MountJournal.GetNumMounts() do --  Loop though all mounts
		creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i);--   Grab mount spell ID
		if spellID then
			MountCache[spellID] = { -- Register spell ID in our cache
				index = i,
				creatureName = creatureName,
				spellID = spellID,
				mountID = mountID
			};
		end
		-- TODO manually add class specific mounts that aren't in everyone's journal?  Like "Felsteed"
		--   Mounts that have trouble ATM: Ancient Frostsaber, Plagued Proto-drake, Reins of the Black Proto-Drake (these are flagged as 'Legacy' mounts in Wowhead).  This comment gives more of the 1.4 removed mounts: http://www.wowhead.com/item=12302/reins-of-the-ancient-frostsaber#comments:id=1765130.  wonder if I can search wowhead for all the 'legacy' ones rather than just stumbling upon them?  Swift Spectral Tiger
	end
end

function InspectorGadgetzan_OnLoad(self)

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
		addon:Print(InspectorGadgetzan:ChatFrame(), "Mount reports: \124cffffd000\124Hspell:".. mount.spellID .. "\124h[" .. mount.creatureName .. "]\124h\124r");
		if InspectorGadgetzan.db.profile.pickupMount then
			C_MountJournal.Pickup(mount.index)
		end
		IGMount_Show(mount.index)
	else
		addon:Print(InspectorGadgetzan:ChatFrame(), "Mount reports: Not mounted")
	end
end

-- Mount the same mount as your target
-- TODO Future feature: register the player in question, and if they change their mount, you change yours too (if it is safe to do so etc.)
--      More for when you're waiting around for a pull, or sitting in the capital city etc and people are messing around with their collections
--      Maybe call it 'mirror' instead of 'clone'?
function IGMount_Clone()
	local mount = IGMount("playertarget")
	if mount then
		addon:Print(InspectorGadgetzan:ChatFrame(), "Mount cloning: \124cffffd000\124Hspell:".. mount.spellID .. "\124h[" .. mount.creatureName .. "]\124h\124r");
		C_MountJournal.SummonByID(mount.mountID)
	else
		addon:Print(InspectorGadgetzan:ChatFrame(), "Mount reports: Not mounted - Unable to clone.")
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
		InspectorGadgetzanWardrobeFrame:RegisterEvent("INSPECT_READY")
		InspectUnit("target")
	else
		addon:Print(InspectorGadgetzan:ChatFrame(), "Invalid target/Target not found.") -- TODO make this red for an error
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

	local appearanceSources = C_TransmogCollection.GetInspectSources()

	if appearanceSources then
		if debugLevel then addon:Print(InspectorGadgetzan:ChatFrame(), "Appearances Dump") end
		for i = 1, #appearanceSources do
			if ( appearanceSources[i] and appearanceSources[i] ~= NO_TRANSMOG_SOURCE_ID ) then
				-- TODO should I local these?
				categoryID , appearanceID, unknownBoolean1, uiOrder, unknownBoolean2, itemLink, appearanceLink, unknownFlag = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSources[i])
				if debugLevel then
					addon:Printf(InspectorGadgetzan:ChatFrame(), "%s is item %s (appearance %s)", transmogCategories[categoryID].name, itemLink, appearanceLink)
					-- print (format("unknownBoolean1 %s, uiOrder %s, unknownBoolean2 %s, unknownFlag %s", tostring(unknownBoolean1), tostring(uiOrder), tostring(unknownBoolean2), tostring(unknownFlag))) -- TODO figure out those other fields
				end
				-- TODO this is really ugly... iterate it ... is _G[] what I need?
				-- local slot = WardrobeCollectionFrame_GetSlotFromCategoryID(categoryID); -- HMPF, this is nil sometimes... guess I won't use it.  hardcode my transmogCategories table for now
				if     categoryID == 1 then
					InspectorGadgetzanWardrobeHeadSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeHeadText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeHeadText.itemLink = itemLink
					InspectorGadgetzanWardrobeHeadText.categoryID = categoryID
					InspectorGadgetzanWardrobeHeadText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeHeadText.slotID = INVSLOT_HEAD
				elseif categoryID == 2 then 
					InspectorGadgetzanWardrobeShoulderSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeShoulderText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeShoulderText.itemLink = itemLink
					InspectorGadgetzanWardrobeShoulderText.categoryID = categoryID
					InspectorGadgetzanWardrobeShoulderText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeShoulderText.slotID = INVSLOT_SHOULDER
				elseif categoryID == 3 then
					InspectorGadgetzanWardrobeBackSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeBackText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeBackText.itemLink = itemLink
					InspectorGadgetzanWardrobeBackText.categoryID = categoryID
					InspectorGadgetzanWardrobeBackText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeBackText.slotID = INVSLOT_BACK
				elseif categoryID == 4 then
					InspectorGadgetzanWardrobeChestSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeChestText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeChestText.itemLink = itemLink
					InspectorGadgetzanWardrobeChestText.categoryID = categoryID
					InspectorGadgetzanWardrobeChestText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeChestText.slotID = INVSLOT_CHEST
				elseif categoryID == 5 then
					InspectorGadgetzanWardrobeShirtSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeShirtText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeShirtText.itemLink = itemLink
					InspectorGadgetzanWardrobeShirtText.categoryID = categoryID
					InspectorGadgetzanWardrobeShirtText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeShirtText.slotID = INVSLOT_BODY
				elseif categoryID == 6 then
					InspectorGadgetzanWardrobeTabardSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeTabardText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeTabardText.itemLink = itemLink
					InspectorGadgetzanWardrobeTabardText.categoryID = categoryID
					InspectorGadgetzanWardrobeTabardText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeTabardText.slotID = INVSLOT_TABARD
				elseif categoryID == 7 then
					InspectorGadgetzanWardrobeWristSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeWristText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeWristText.itemLink = itemLink
					InspectorGadgetzanWardrobeWristText.categoryID = categoryID
					InspectorGadgetzanWardrobeWristText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeWristText.slotID = INVSLOT_WRIST
				elseif categoryID == 8 then
					InspectorGadgetzanWardrobeHandsSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeHandsText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeHandsText.itemLink = itemLink
					InspectorGadgetzanWardrobeHandsText.categoryID = categoryID
					InspectorGadgetzanWardrobeHandsText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeHandsText.slotID = INVSLOT_HAND
				elseif categoryID == 9 then
					InspectorGadgetzanWardrobeWaistSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeWaistText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeWaistText.itemLink = itemLink
					InspectorGadgetzanWardrobeWaistText.categoryID = categoryID
					InspectorGadgetzanWardrobeWaistText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeWaistText.slotID = INVSLOT_WAIST
				elseif categoryID ==10 then
					InspectorGadgetzanWardrobeLegsSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeLegsText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeLegsText.itemLink = itemLink
					InspectorGadgetzanWardrobeLegsText.categoryID = categoryID
					InspectorGadgetzanWardrobeLegsText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeLegsText.slotID = INVSLOT_LEGS
				elseif categoryID ==11 then
					InspectorGadgetzanWardrobeFeetSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeFeetText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeFeetText.itemLink = itemLink
					InspectorGadgetzanWardrobeFeetText.categoryID = categoryID
					InspectorGadgetzanWardrobeFeetText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeFeetText.slotID = INVSLOT_FEET
				end
				if (transmogCategories[categoryID].slot == "MainHand") then
					-- if it already has something in the mainhand, assume it is a dualwielder
					if InspectorGadgetzanWardrobeMainHandSlot.itemLink then
						InspectorGadgetzanWardrobeSecondaryHandSlot.itemLink = itemLink
						InspectorGadgetzanWardrobeSecondaryHandText.appearanceLink = appearanceLink
						InspectorGadgetzanWardrobeSecondaryHandText.itemLink = itemLink
						InspectorGadgetzanWardrobeSecondaryHandText.categoryID = categoryID
						InspectorGadgetzanWardrobeSecondaryHandText.sourceID = appearanceSources[i]
						InspectorGadgetzanWardrobeSecondaryHandText.slotID = INVSLOT_OFFHAND
					else
						InspectorGadgetzanWardrobeMainHandSlot.itemLink = itemLink
						InspectorGadgetzanWardrobeMainHandText.appearanceLink = appearanceLink
						InspectorGadgetzanWardrobeMainHandText.itemLink = itemLink
						InspectorGadgetzanWardrobeMainHandText.categoryID = categoryID
						InspectorGadgetzanWardrobeMainHandText.sourceID = appearanceSources[i]
						InspectorGadgetzanWardrobeMainHandText.slotID = INVSLOT_MAINHAND
					end
				elseif transmogCategories[categoryID].slot == "SecondaryHand" then
					InspectorGadgetzanWardrobeSecondaryHandSlot.itemLink = itemLink
					InspectorGadgetzanWardrobeSecondaryHandText.appearanceLink = appearanceLink
					InspectorGadgetzanWardrobeSecondaryHandText.itemLink = itemLink
					InspectorGadgetzanWardrobeSecondaryHandText.categoryID = categoryID
					InspectorGadgetzanWardrobeSecondaryHandText.sourceID = appearanceSources[i]
					InspectorGadgetzanWardrobeSecondaryHandText.slotID = INVSLOT_OFFHAND
				end
			end
		end
	else
		addon:Print(InspectorGadgetzan:ChatFrame(), "not ready")
	end
end

function IGWardrobeViewButton_OnLoad(self)
	self:SetWidth(30 + self:GetFontString():GetStringWidth());
end

--[[
INVSLOT_HEAD = 1
INVSLOT_NECK = 2
INVSLOT_SHOULDER = 3
INVSLOT_BODY = 4 (shirt)
INVSLOT_CHEST = 5
INVSLOT_WAIST = 6
INVSLOT_LEGS = 7
INVSLOT_FEET = 8
INVSLOT_WRIST = 9
INVSLOT_HAND = 10
INVSLOT_FINGER1 = 11
INVSLOT_FINGER2 = 12
INVSLOT_TRINKET1 = 13
INVSLOT_TRINKET2 = 14
INVSLOT_BACK = 15
INVSLOT_MAINHAND = 16
INVSLOT_OFFHAND = 17
INVSLOT_RANGED = 18
INVSLOT_TABARD = 19
]]--

local inventorySlotNames = {
	"Head",
	"Shoulder",
	"Back",
	"Chest",
	"Shirt",
	"Tabard",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"MainHand",
	"SecondaryHand",
}


--[[
local KNOWN =                                       L["Learned."]												Blue & Enabled
local KNOWN_FROM_ANOTHER_ITEM =                     L["Learned from another item."]								Blue & Enabled
local KNOWN_BY_ANOTHER_CHARACTER =                  L["Learned for a different class."]							Blue & Disabled
local KNOWN_BUT_TOO_LOW_LEVEL =                     L["Learned but cannot transmog yet."]						Blue & Disabled
local KNOWN_FROM_ANOTHER_ITEM_BUT_TOO_LOW_LEVEL =   L["Learned from another item but cannot transmog yet."]		Blue & Disabled
local KNOWN_FROM_ANOTHER_ITEM_AND_CHARACTER =       L["Learned for a different class and item."]				Blue & Disabled
local UNKNOWN =                                     L["Not learned."]											Orange & Enable
local UNKNOWABLE_BY_CHARACTER =                     L["Another class can learn this item."]						Yellow & Disabl
local UNKNOWABLE_BY_CHARACTER_SOULBOUND =           L["Cannot be learned by this character."]					Yellow & Disabl
local CAN_BE_LEARNED_BY =                           L["Can be learned by:"] -- list of classes					not used
local NOT_TRANSMOGABLE =                            L["Cannot be learned."]										Gray
local CANNOT_DETERMINE =                            L["Cannot determine status on other characters."]			Yellow & Disabl
]]--


local APPEARANCE_SOURCES_ALL = 1
local APPEARANCE_SOURCES_SELECTED = 2
local APPEARANCE_SOURCES_POSSIBLE = 3

local KNOWN_YES =	1  -- Blue & Enabled
local KNOWN_NO =	2  -- Blue & Disabled
local NOTKNOWN_YES =3  -- Orange & Enabled
local NOTKNOWN_NO = 4  -- Yellow & Disabled
local CANTKNOW =	5

function InspectorGadgetzan:ItemTransmogStatus(itemLink)
	if CanIMogIt then
		local status = CanIMogIt:GetTooltipText(itemLink)
		if (
			status == CanIMogIt.KNOWN or
			status == CanIMogIt.KNOWN_FROM_ANOTHER_ITEM
		) then
			return KNOWN_YES
		elseif (
			status == CanIMogIt.KNOWN_BY_ANOTHER_CHARACTER or
			status == CanIMogIt.KNOWN_BUT_TOO_LOW_LEVEL or
			status == CanIMogIt.KNOWN_FROM_ANOTHER_ITEM_BUT_TOO_LOW_LEVEL or
			status == CanIMogIt.KNOWN_FROM_ANOTHER_ITEM_AND_CHARACTER
		) then
			return KNOWN_NO
		elseif (
			status == CanIMogIt.UNKNOWN
		) then
			return NOTKNOWN_YES
		elseif (
			status == CanIMogIt.UNKNOWABLE_BY_CHARACTER or
			status == CanIMogIt.UNKNOWABLE_BY_CHARACTER_SOULBOUND or
			status == CanIMogIt.CANNOT_DETERMINE
		) then
			return NOTKNOWN_NO
		else
			return CANTKNOW
		end
	else
		return NOTKNOWN_NO
	end
end

local itemTransmogStatues = {
	[KNOWN_YES] = {
		["color"] = BLUE,
		["enabled"] = true,
	},
	[KNOWN_NO] = {
		["color"] = BLUE,
		["enabled"] = false,
	},
	[NOTKNOWN_YES] = {
		["color"] = RED_ORANGE,
		["enabled"] = true,
	},
	[NOTKNOWN_NO] = {
		["color"] = YELLOW,
		["enabled"] = false,
	},
	[CANTKNOW] = {
		["color"] = GRAY,
		["enabled"] = false,
	},
}

-- copied from DressupFrame.lua since my appearanceSources wasn't compatible...  should try to make my argument better
local function MyDressUpSources(appearanceSources, mainHandEnchant, offHandEnchant)
	if ( not appearanceSources ) then
		return true;
	end

	DressUpFrame_Show();
	--local mainHandSlotID = GetInventorySlotInfo("MAINHANDSLOT");
	--local secondaryHandSlotID = GetInventorySlotInfo("SECONDARYHANDSLOT");
	--[[
	for i = 1, #appearanceSources do
		print("Looping DressUp "..appearanceSources[i])
		--if ( i ~= mainHandSlotID and i ~= secondaryHandSlotID ) then
			if ( appearanceSources[i] and appearanceSources[i] ~= NO_TRANSMOG_SOURCE_ID ) then
				print("Trying on "..appearanceSources[i])
				DressUpModel:TryOn(appearanceSources[i])
			end
		--end
	end
	]]--
	for slotID, sourceID in pairs(appearanceSources) do
		--if ( i ~= mainHandSlotID and i ~= secondaryHandSlotID ) then
			if ( sourceID and sourceID ~= NO_TRANSMOG_SOURCE_ID ) then
				DressUpModel:TryOn(sourceID)
			end
		--end
	end

	--print("Trying on weapons now")
	--DressUpModel:TryOn(appearanceSources[mainHandSlotID], "MAINHANDSLOT", mainHandEnchant);
	--DressUpModel:TryOn(appearanceSources[secondaryHandSlotID], "SECONDARYHANDSLOT", offHandEnchant);
end

function IGWardrobeViewButton_OnClick(self)
	PlaySound("igMainMenuOptionCheckBoxOn");
	MyDressUpSources(InspectorGadgetzanAppearanceSources(UIDropDownMenu_GetSelectedValue(DropDownMenuTryOn)));
end

function InspectorGadgetzanAppearanceSourcesCheck(flag, button)
	if flag == APPEARANCE_SOURCES_ALL then return true end
	local itemTransmogStatus = InspectorGadgetzan:ItemTransmogStatus(button.itemLink)
	if flag == APPEARANCE_SOURCES_SELECTED then
		if itemTransmogStatus == KNOWN_YES or itemTransmogStatus == NOTKNOWN_YES then
			return true
		end
	elseif flag == APPEARANCE_SOURCES_POSSIBLE then
		if itemTransmogStatus == KNOWN_YES or itemTransmogStatus == KNOWN_NO then
			return true
		end
	else
		return false
	end
end

function InspectorGadgetzanAppearanceSources(flag)
	if not(flag) then flag = APPEARANCE_SOURCES_ALL end
	-- array of appearanceSources is:
	--   1 - subarray of
	--       slotIDs (vs categoryIDs) and sourceIDs
	--   2 - mainhand enchant
	--   3 - offland enchant
	local appearanceSources = {}
	for k, v in pairs(inventorySlotNames) do
		button = _G["InspectorGadgetzanWardrobe" .. v .. "Text"]
		if button.slotID and InspectorGadgetzanAppearanceSourcesCheck(flag, button) then
			appearanceSources[button.slotID] = button.sourceID
		end
	end
	return appearanceSources, 0, 0
end


function DropDownMenuTryOn_OnLoad(self)
	local items = {
		{ ["text"] = "All", ["value"] = APPEARANCE_SOURCES_ALL, ["tooltipText"] = "All Items, of course"},
		{ ["text"] = "Wearable", ["value"] = APPEARANCE_SOURCES_SELECTED, ["tooltipText"] = "Wearable whatever that means"},
		{ ["text"] = "In Collection", ["value"] = APPEARANCE_SOURCES_POSSIBLE, ["tooltipText"] = "In Collection, of course"},
	}
	local function initialize(self, level)
	   local info = UIDropDownMenu_CreateInfo()
	   for k, v in pairs(items) do
		  info = UIDropDownMenu_CreateInfo()
		  info.text = v.text
		  info.value = v.value
		  info.tooltipTitle = "Tooltip title" -- not doing anything ATM.  something about a UI setting?
		  info.tooltipText = v.tooltipText
		  info.func = DropDownMenuTryOn_OnClick
		  UIDropDownMenu_AddButton(info, level)
	   end
	end
	UIDropDownMenu_Initialize(DropDownMenuTryOn, initialize)
	UIDropDownMenu_SetWidth(DropDownMenuTryOn, 80);
	UIDropDownMenu_SetButtonWidth(DropDownMenuTryOn, 104)
	UIDropDownMenu_SetSelectedID(DropDownMenuTryOn, 1)
	UIDropDownMenu_JustifyText(DropDownMenuTryOn, "LEFT")
end

function DropDownMenuTryOn_OnClick(self)
	UIDropDownMenu_SetSelectedValue(DropDownMenuTryOn, self.value)
end

-- Init the button on the screen
--   Putting icons on the empty slots
--   Taken from InspectPaperDoll.lua
function IGWardrobeItemSlotButton_OnLoad(self)
	local slotName = self:GetName()
	slotName = string.gsub(slotName, "InspectorGadgetzanWardrobe", "Inspect")
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
		local text = _G[strupper(strsub(self:GetName(), 27))]; -- 27 is hardcode of string.len("InspectorGadgetzanWardrobe")+1) why do the math after all
		GameTooltip:SetText(text);
	end
	CursorUpdate(self);
end

-- Deals with Tooltips when you mouse over an ItemText
function IGWardrobeItemTextButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local tooltipSet = false
	if self.itemLink and CanIMogIt then
		--tooltipSet = GameTooltip:SetHyperlink(self.itemLink)
		tooltipSet = GameTooltip:SetText(CanIMogIt:GetTooltipText(self.itemLink))
		-- I want to catch of hte tooltip doesn't get set, but the flag needs work
	else
		local n = strupper(strsub(self:GetName(), 27)) -- 27 is hardcode of string.len("InspectorGadgetzanWardrobe")+1) why do the math after all
		local text = _G[n:gsub("TEXT", "SLOT")]
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
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeHeadSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeShoulderSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeBackSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeChestSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeShirtSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeTabardSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeWristSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeHandsSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeWaistSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeLegsSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeFeetSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeMainHandSlot);
	IGWardrobeItemSlotButton_Update(InspectorGadgetzanWardrobeSecondaryHandSlot);
	
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeHeadText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeShoulderText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeBackText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeChestText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeShirtText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeTabardText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeWristText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeHandsText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeWaistText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeLegsText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeFeetText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeMainHandText);
	IGWardrobeItemTextButton_Update(InspectorGadgetzanWardrobeSecondaryHandText);
	
	-- Set the mount header info
	local mount = IGMount(InspectFrame.unit)
	if mount then
		local button = InspectorGadgetzanWardrobeMountMicroButton
		local prefix = "Interface\\Buttons\\UI-MicroButton-";
		local name = 'Mounts'
		button:SetNormalTexture(prefix..name.."-Up");
		button:SetPushedTexture(prefix..name.."-Down");
		button:SetDisabledTexture(prefix..name.."-Disabled");
		button:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight")
		button.tooltipText = "View " .. mount.creatureName .. " in Collections Journal"
		button.mount = mount
		button:Show()
		InspectorGadgetzanWardrobeMountText:SetText("Currently mounted on " .. mount.creatureName)
		InspectorGadgetzanWardrobeMountText:Show()
	else
		InspectorGadgetzanWardrobeMountMicroButton:Hide()
		InspectorGadgetzanWardrobeMountText:Hide()
	end
	
end

-- Opposite of UpdateButtons
local function IGWardrobeFrame_ClearButtons()
	-- don't like code like this... snazzy it up some day
	InspectorGadgetzanWardrobeHeadSlot.itemLink = nil
	InspectorGadgetzanWardrobeShoulderSlot.itemLink = nil
	InspectorGadgetzanWardrobeBackSlot.itemLink = nil
	InspectorGadgetzanWardrobeChestSlot.itemLink = nil
	InspectorGadgetzanWardrobeShirtSlot.itemLink = nil
	InspectorGadgetzanWardrobeTabardSlot.itemLink = nil
	InspectorGadgetzanWardrobeWristSlot.itemLink = nil
	InspectorGadgetzanWardrobeHandsSlot.itemLink = nil
	InspectorGadgetzanWardrobeWaistSlot.itemLink = nil
	InspectorGadgetzanWardrobeLegsSlot.itemLink = nil
	InspectorGadgetzanWardrobeFeetSlot.itemLink = nil
	InspectorGadgetzanWardrobeMainHandSlot.itemLink = nil
	InspectorGadgetzanWardrobeSecondaryHandSlot.itemLink = nil

	InspectorGadgetzanWardrobeHeadText.appearanceLink= nil
	InspectorGadgetzanWardrobeShoulderText.appearanceLink= nil
	InspectorGadgetzanWardrobeBackText.appearanceLink= nil
	InspectorGadgetzanWardrobeChestText.appearanceLink= nil
	InspectorGadgetzanWardrobeShirtText.appearanceLink= nil
	InspectorGadgetzanWardrobeTabardText.appearanceLink= nil
	InspectorGadgetzanWardrobeWristText.appearanceLink= nil
	InspectorGadgetzanWardrobeHandsText.appearanceLink= nil
	InspectorGadgetzanWardrobeWaistText.appearanceLink= nil
	InspectorGadgetzanWardrobeLegsText.appearanceLink= nil
	InspectorGadgetzanWardrobeFeetText.appearanceLink= nil
	InspectorGadgetzanWardrobeMainHandText.appearanceLink= nil
	InspectorGadgetzanWardrobeSecondaryHandText.appearanceLink= nil
end

-- Change the ItemSlot to match the links attached to it
function IGWardrobeItemSlotButton_Update(button)
	local unit = InspectFrame.unit;
	local textureName, itemID, itemName, itemLink, itemRarity, itemTexture;
	if button.itemLink then
		itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(button.itemLink)
		-- if the above call is throttled it could be empty... --TODO better way to handle? check out LibInspect for a solution
		if itemLink then itemID = GetItemInfoInstant(itemLink) end
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
	if button.appearanceLink then
		local itemTransmogStatus = InspectorGadgetzan:ItemTransmogStatus(button.itemLink)
		local color = itemTransmogStatues[itemTransmogStatus].color
		local enabled = itemTransmogStatues[itemTransmogStatus].enabled
		button:SetText(color .. button.appearanceLink:match("%[.*%]"):gsub("%[", ""):gsub("%]",""))
		button:Show()
		if enabled then
			button:Enable()
		else
			button:Disable()
		end
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

function InspectorGadgetzanWardrobeFrame_OnEvent(self, event, ...)
	if event == "INSPECT_READY" then
		-- wait half a second before switching tabs to let the inspect catch up with the item cache
		-- really cludgy, but I need to do something like the LibInspect library which makes sure with a couple of passes that all the items I need are ready.
		--  Low priority since who but me will use the quick look anyway?
		--  With the LDB/Minimap now... more people will be going in this way so not as low as it was
		C_Timer.After(0.5, function()
				IGWardrobe_OnLoad()
				InspectFrameTab_OnClick(InspectFrameTab5)
				InspectorGadgetzanWardrobeFrame:UnregisterEvent("INSPECT_READY")
		end);
	end
end

-- Add an extra 'tab' to the bottom of the InspectFrame
--   very problematic to other addons that also add tabs?
--   how do I go about skinning it correctly for other UIs - thinking ElvUI specifically
local function createInspectFrameTab()
	-- TODO the LoadAddon stuff messed up the highlighting of this this button... come back to check this before commit
	if not InspectFrameTab5 then
		INSPECTFRAME_SUBFRAMES[5] = "InspectorGadgetzanWardrobeFrame";
		PanelTemplates_SetNumTabs(InspectFrame, 5);
		InspectFrameTab5 = CreateFrame("Button", "InspectFrameTab5", InspectFrame, "CharacterFrameTabButtonTemplate")
		InspectFrameTab5:SetID(5)
		InspectFrameTab5:SetPoint("LEFT", InspectFrameTab4, "RIGHT", -16, 0)
		InspectFrameTab5:SetText("IG")
		InspectFrameTab5:SetScript("OnClick", function(self) IGWardrobe_OnLoad(); InspectFrameTab_OnClick(self); end)
		InspectFrameTab5:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT");GameTooltip:SetText("Wardrobe - Inspector Gadgetzan", 1.0,1.0,1.0 );end)
		InspectFrameTab5:SetScript("OnLeave", GameTooltip_Hide)
	end
end



--------------------------------------------------------------------------------
-- Event Handler
--
local events = { "INSPECT_READY", "PLAYER_LOGIN", "TRANSMOG_COLLECTION_UPDATED" }

function InspectorGadgetzan:INSPECT_READY(...)
	createInspectFrameTab()
end

function InspectorGadgetzan:PLAYER_LOGIN(...)
	buildMountCache()
end

function InspectorGadgetzan:TRANSMOG_COLLECTION_UPDATED(...)
	-- flattens a simple table to a string with a delimiter
	--   gotta be a standard wayw to do this in lua, no? "tconcat" maybe?
	local function tbl2str(t)
		local s = ""
		local delimiter = " / "
		for k,v in pairs(t) do
			s = s .. v .. delimiter
		end
		return string.gsub(s, delimiter .. "$", "")
	end

	-- ERR_LEARN_TRANSMOG_S = "%s has been added to your appearance collection.";
	local SHARE_LEARN_TRANSMOG_S = "added %s%s to their appearance collection."
	-- ERR_REVOKE_TRANSMOG_S = "%s has been removed from your appearance collection.";
	local latestAppearanceID, latestAppearanceCategoryID = C_TransmogCollection.GetLatestAppearance();
	if ( latestAppearanceID and latestAppearanceID ~= self.latestAppearanceID ) then
		self.latestAppearanceID = latestAppearanceID;
		-- is a sourceID and appearanceID the same...? nope.  seems wrong to just pick one of the sources of the new appearance in order to get a link - should I give all possible ones?  Hmmm... could be neat to show the ones you know, and the sources you don't know yet?  Or is that overkill?
		local sources = C_TransmogCollection.GetAppearanceSources(self.latestAppearanceID)
		local sourceID
		local bonus_msg, bonus_share_msg, share_msg = "", "", ""
		local collectedNames = {}
		local unCollectedNames = {}
		if #sources > 1 then
			for k, source in pairs(sources) do
				-- source.{sourceType, name, isCollected, sourceID, quality}
				if source.isCollected then
					if not sourceID then sourceID = source.sourceID end
					tinsert(collectedNames, source.name)
				else
					tinsert(unCollectedNames, source.name)
				end
			end
		else
			sourceID = sources[1].sourceID
		end
		local appearanceLink = select(7, C_TransmogCollection.GetAppearanceSourceInfo(sourceID))
		-- substitute the text between the [] brackets with all the names for that appearance we know
		if #collectedNames > 1 and #unCollectedNames > 0 then
			appearanceLink = appearanceLink:gsub("%[.*%]", "["..tbl2str(collectedNames).."]")
		end
		-- if it is a unique appearance, or you have unlocked all the appearances, say so
		if #sources == 1 then
			bonus_msg = "Unique Appearance Unlocked - "
			bonus_share_msg = " the unique "
			-- TODO play a sound
		elseif #unCollectedNames == 0 then
			bonus_msg = "All sources of this appearance collected. "
		end
		self:Printcf(self:ChatFrame(), CHAT_COLOR["SYSTEM"].intensity, bonus_msg .. ERR_LEARN_TRANSMOG_S, appearanceLink)
		share_msg = format(SHARE_LEARN_TRANSMOG_S, bonus_share_msg, appearanceLink)
		if (IsInGuild()) then
			self:SendCommMessage("NewAppearance", share_msg, "GUILD")
		end
		local groupFallthrough = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY" or false
		if groupFallthrough then
			self:SendCommMessage("NewAppearance", share_msg, groupFallthrough)
		end
		if #unCollectedNames > 0 then
			self:Printcf(self:ChatFrame(), CHAT_COLOR["SYSTEM"].intensity, "%s sources of that appearance still available: %s", tostring(#unCollectedNames), tbl2str(unCollectedNames))
		end
		self.latestAppearanceLink = appearanceLink
	elseif latestAppearanceID == nil then
		self.latestAppearanceLink = latestAppearanceID
		if self.firstTRANSMOG_COLLECTION_UPDATED then
			self:Printcf(self:ChatFrame(), CHAT_COLOR["SYSTEM"].intensity, "An appearance has been removed from your appearance collection")
		else
			-- kludge to not give the message the first time through.  the event first when first loading
			self.firstTRANSMOG_COLLECTION_UPDATED = true
		end
	end
end

for k, v in pairs(events) do
	addon:RegisterEvent(v)
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
		["help"] = "Inspector Gadgetzan mount commands: clone, report",
	},
	["options"] = function()
		InspectorGadgetzan:OpenConfig()
	end,
	["help"] = "Inspector Gadgetzan commands: inspect, mount, options",
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
SLASH_INSPECTORGADGETZAN1 = "/inspectorgadgetzan"
SLASH_INSPECTORGADGETZAN2 = "/ig"
SlashCmdList["INSPECTORGADGETZAN"] = function(message)
	DispatchCommand(message, IGCommandTable)
end


-------------------
-- Taken from AceConsole-3.0
--   All I wanted to change was the Print function itself, but I dont have enough knowledage atm to do that so I have all 3 here.
local tmp={}
local function Print(self,frame,rgb,...)
	local n=0
	if self ~= AceConsole and InspectorGadgetzan:ChatFrame() == DEFAULT_CHAT_FRAME then
		n=n+1
		tmp[n] = "|cff33ff99"..tostring( self ).."|r:"
	end
	for i=1, select("#", ...) do
		n=n+1
		tmp[n] = tostring(select(i, ...))
	end
	if rgb then
		frame:AddMessage( tconcat(tmp," ",1,n), rgb.r, rgb.g, rgb.b )
	else
		frame:AddMessage( tconcat(tmp," ",1,n) )
	end
end

--- Print to DEFAULT_CHAT_FRAME or given ChatFrame (anything with an .AddMessage function)
-- @paramsig [chatframe ,] ...
-- @param chatframe Custom ChatFrame to print to (or any frame with an .AddMessage function)
-- @param ... List of any values to be printed
function InspectorGadgetzan:Print(...)
	local frame = ...
	if type(frame) == "table" and frame.AddMessage then	-- Is first argument something with an .AddMessage member?
		return Print(self, frame, nil, select(2,...))
	else
		return Print(self, DEFAULT_CHAT_FRAME, nil, ...)
	end
end


--- Formatted (using format()) print to DEFAULT_CHAT_FRAME or given ChatFrame (anything with an .AddMessage function)
-- @paramsig [chatframe ,] "format"[, ...]
-- @param chatframe Custom ChatFrame to print to (or any frame with an .AddMessage function)
-- @param format Format string - same syntax as standard Lua format()
-- @param ... Arguments to the format string
function InspectorGadgetzan:Printf(...)
	local frame = ...
	if type(frame) == "table" and frame.AddMessage then	-- Is first argument something with an .AddMessage member?
		return Print(self, frame, nil, format(select(2,...)))
	else
		return Print(self, DEFAULT_CHAT_FRAME, nil, format(...))
	end
end

function InspectorGadgetzan:Printcf(...)
	local frame = ...
	if type(frame) == "table" and frame.AddMessage then	-- Is first argument something with an .AddMessage member?
		return Print(self, frame, select(2,...), format(select(3,...)))
	else
		return Print(self, DEFAULT_CHAT_FRAME, select(1,...), format(select(2,...)))
	end
end
