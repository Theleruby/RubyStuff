# RubyStuff
This repo contains addons I've written for World of Warcraft: Wrath of the Lich King (3.3.5a client version). This is mostly a work-in-progress, so expect bugs. I'm also new to writing lua as well as WoW addons, so things might be written kinda badly for now. 

Feel free to make feature requests and report bugs. I'll try to fix anything reported and improve the code quality over time.

Everything here is public domain (at least the parts I wrote) so you can also do what you want with it.

## Latest Updates
RubyStuff Social is at version 2.0.1 - 19 June 2022

## How to install or update the addon(s)

Download the repo from GitHub as a zip file. Put the addons you want into the AddOns folder.

----

## RubyStuff Social
(Prat 3.0 is currently required to use this)

This is an addon which adds a new social list window. You can toggle it by setting a custom keybind in the keybinding settings.

The social list window allows you to see the status of both friends and guildmates. It also allows you to set a custom note for them if you want to. If you don't specify any custom note, the note will be automatically fetched from the guild's public note for that player (if present). Notes are shared between all characters on your WoW account.

The addon then integrates with Prat 3.0 in order to display the note for each player next to their name in the chat window. For this part to work, you need to enable the module in Prat's settings.

Note that if you have a note set for a character, but they're not in the friend list or guild of the character you're logged in as, they will be listed in the social list with unknown status. This is a WoW client limitation. If you want to see the person's status you can add them to your friend list.
