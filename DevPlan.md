# Dev Plan

## CanIMogIt intergration

Use this other addons ability to know about the item and your use of it to colourize or indicate in some way on the wardrobe inspect screen your relation to the items you are looking at.  i.e. can you use that appearance, do you know that appearance etc.

## Inspect yourself

Turn Gadgetzan on you.

## New appearances announcement

The default UI only announces to yourself when you learn a new epic appearance.  We want that knowledge for all new appearances regardless of rarity of the source item.

I'd like to be able to have this 'transmog-log' available as a history too -- but instead of its own seperate window, what about using the chat log?  Though it's own window has the bonus of being able to skin it etc.  Do we save this history and or a summary? e.g. you've learned 19 new appearances this session.  Make a distinction between first time you get an appearance vs getting a secondary source of an appearance already know.

The new profession recipe learned 'toast' type popup is kinda neat too.  Consider extending to allow for that type of pop up.

Be sure to find the event for loosing an appearnce too so if you sell something back for example you will be told too.

When your group members get a new appearance report show that as well (via the AceComms - they'll need the addon to see your announcements most likly - depending on how the event works.)

### Notes

* Event that triggers is: TRANSMOG_COLLECTION_UPDATED.  Use C_TransmogCollection.GetLatestAppearance() after that
* C_TransmogCollection.GetCategoryCollectedCount -- could use at beginning of session, save the ount for each category, then throughout look at the new #s to tell you how many of each thing you've gotten.
* How does C_TransmogCollection.IsNewAppearance work? - It is used in the UI to glow and show the 'new' text. Would be heavy to search out all the 'new'... wonder if we can do that in the UI itself though rather than ourselves?

## Fashion Scoring

When looking at anothers appearance be able to rate it / share it / steal it.

Integrate Jen's requirements doc/user stories to this file.

Host a fashion show in-game as a launch party.

When you rate another, it messages them with the rating.  If they have the addon, the ratings are tracked and stored - otherwise it suggests they get the addon.

When someone in your party rates another, you also see it in the same place the transmog-log shows up.  If you're in a neutral area perhaps you can see ratings made by people not in your party as well?  Keep a server wide status of ratings somehow too as long as someone logged in as the addon.

## Transformation report

The original 3rd feature. With all the toys that let your transform into different things, it is hard to know where it came from.  Report on this like we report on the mount they are riding, and give a quick way to clone them.  Maybe even pop-up so and so just transformed into this, would you like to as well?  Don't do that in combat though.  But all those Gamons at the right time... hmmm...