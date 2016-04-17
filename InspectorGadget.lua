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


-- original test function - can be removed TODO
function WhatMount1(unit)
	print "Buffs: "
	for i = 0, 40 do
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff(unit, i) -- , "PLAYER")
		if name then
			-- Call GetSpellDescription and parse that for the word 'mount' - would that be enough?
			-- 'mount' isn't enough - Acherus Deathcharger doesn't say mount - is that just class mounts?  "Summons and dismisses" 
			-- 179245 "Hire a Chauffeur to drive you around" - spell case again :-(
			-- 93326 "Transforms you into" Sandstone drake but does say it is a mount at the end
			-- 61425 Calls Forth the Traveler's Tundra Mammoth -- ugh, another exception :-(  so much for parsing the spell desc
			local desc = GetSpellDescription(spellID)
			print(i .. ": " .. name .. " " .. spellID .. " " .. desc)
		end
		-- SpellID 32292 "Swift Purple Gryphon"
		-- ItemRefTooltip
		-- SpellID 59650 "Black Drake"
		-- Garn Nighthowl has weird colouring in its tooltip.
	end
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


function IGInspect_Show()
	if (UnitPlayerControlled("target") and CheckInteractDistance("target", 1) and not UnitIsUnit("player", "target")) then
		InspectUnit("target")
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