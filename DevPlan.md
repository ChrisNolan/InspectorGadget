# Dev Plan

## CanIMogIt intergration

~~Use this other addons ability to know about the item and your use of it to colourize or indicate in some way on the wardrobe inspect screen your relation to the items you are looking at.  i.e. can you use that appearance, do you know that appearance etc.~~

### Notes

* CanIMogIt:IsValidAppearanceForCharacter(itemLink) -- this doesn't take into account class restrictions?  e.g. monk looking at druid only gear
* CanIMogIt:PlayerKnowsTransmog(itemLink)
* CanIMogIt:CharacterCanLearnTransmog(itemLink)
* for my own tooltips I can use CanIMogIt:GetTooltipText(itemLink)

## Inspect yourself

Turn Gadgetzan on you.

## New appearances announcement

~~The default UI only announces to yourself when you learn a new epic appearance.  We want that knowledge for all new appearances regardless of rarity of the source item.~~

~~I'd like to be able to have this 'transmog-log' available as a history too -- but instead of its own seperate window, what about using the chat log?  Though it's own window has the bonus of being able to skin it etc.  Do we save this history and or a summary? e.g. you've learned 19 new appearances this session.  Make a distinction between first time you get an appearance vs getting a secondary source of an appearance already know.~~  Still a chat window for now, in the future look at ScrollingMessageFrame and also saving the entries between sessions.

The new profession recipe learned 'toast' type popup is kinda neat too.  Consider extending to allow for that type of pop up.

~~Be sure to find the event for loosing an appearance too so if you sell something back for example you will be told too.~~ The detail doesn't seem to be available :-(

~~When your group members get a new appearance report show that as well (via the AceComms - they'll need the addon to see your announcements most likly - depending on how the event works.)~~

### Notes

* Event that triggers is: TRANSMOG_COLLECTION_UPDATED.  Use C_TransmogCollection.GetLatestAppearance() after that
* C_TransmogCollection.GetCategoryCollectedCount -- could use at beginning of session, save the ount for each category, then throughout look at the new #s to tell you how many of each thing you've gotten.
* How does C_TransmogCollection.IsNewAppearance work? - It is used in the UI to glow and show the 'new' text. Would be heavy to search out all the 'new'... wonder if we can do that in the UI itself though rather than ourselves?

## Fashion Scoring

When looking at anothers appearance be able to rate it / share it / steal it.

### Mewren's 'User Stories for Fashion Rating features'

As a user, I can rate another user that I am inspecting with the following levels:

* Jenkins Inspired
* Someone call the Fashion Police
* Well Pulled Together
* Fashion Diva
* Fashion Expert
* Fashion God


As a user, I can share the fashion level with people through various channels (/party, /intance, /raid, /say, /tell)  "Ruaha has rated Naxder's appearance as "Fashion Expert" using InspectorGadgetzan"

As a user, I can see my accumulated score  (5x Fashion God,  3x Fashion Diva, ....)

As a user, I can share my accumulated score through various channels (otherwise my score is private)

As a user, I can view the leaderboard of top 10 rated players for this week

Host a fashion show in-game as a launch party.

When you rate another, it messages them with the rating.  If they have the addon, the ratings are tracked and stored - otherwise it suggests they get the addon.

When someone in your party rates another, you also see it in the same place the transmog-log shows up.  If you're in a neutral area perhaps you can see ratings made by people not in your party as well?  Keep a server wide status of ratings somehow too as long as someone logged in as the addon.

## Transformation report

The original 3rd feature (whoops now that I found my paper work, this wasn't on the list at all). With all the toys that let your transform into different things, it is hard to know where it came from.  Report on this like we report on the mount they are riding, and give a quick way to clone them.  Maybe even pop-up so and so just transformed into this, would you like to as well?  Don't do that in combat though.  But all those Gamons at the right time... hmmm...

# "Inspector Gadget" - New WoW Addon - April 12 2016

Name subject to change - but applies because it is enhaucning the "Inspect", it is a gadget, and people know the character named that.

Goal: Improve access to information about players you encounter.

Possibily split into modules.

## Module 1: Mounts

Story: I regularly see mount sin the world that I'm curious about.  I target the player, hover over their buffs, find the one that seems to be the mount buff, and then look it up elsewhere - either online, or in the mount journal.  -> provide a button, or slash command, or popup to do this

## Module 2: iLvls

Story: When grouping with people, especially in pugs etc, iLvl is a common baseline to know about them.  EvUI has the avility to shift hover, and the player tooltip gets it included.  I will often do this for a bunch of the people when the instance starts.  I'll also check their specs too.  When leveling - heirloom bonuses etc.

-> give me a summary of everyone in the group.  While at i tmaybe show 'dungeon experience' e.g. # of boss kills, or achieves for that boss, etc

## Module 3: Wardrobe

Story: I like to know about the gear people have transmogged.  I have to inspect them, hover over each equipment slot, read the name of the transmog, then go look it up online.

-> extra frame in inspect which shows the details.  Improve for Legion to show collectability, ina set, etc. 