# Player Paint

This is a standalone plugin intended to provide the +paint feature to players for visibility and to mark landmarks, with decals being fully client-sided. This is ideal for movement game-mode servers that want to provide the feature to players, but do not want it to be abused to destroy visibility and cause chaos in public servers! 

## Usage:

* Players can bind `+paint` to a key. When this key is held down, they will continously place paint on the surface they are looking at. 
* `sm_paint` (or `!paint` / `/paint`) will place down a single paint decal on the surface the player is aiming at.
* `sm_paintoptions` will open the options menu, which can be used to access options to change paint colour and size.
* `sm_paintcolour` (or `sm_paintcolor`) will directly open the paint colour settings menu.
* `sm_paintsize` will directly open the paint size settings menu.
* `sm_clearpaint` will tell you how to clear decals, since I couldn't figure out how to make the plugin force clear decals for the player. :P

This plugin uses clientprefs to store settings, so player's paint settings are remembered when they join the server. 

Players can choose from 14 colours and 3 size options! 
![](https://infra.s-ul.eu/xc7Q48Ki)

## Installation:

* Download the plugin and unzip it: https://github.com/1zc/Player-Paint/archive/main.zip
* Drop the `materials` and `addons` folders into your server's `csgo` folder.
* Drop the `materials` folder into your CSGO FastDL, if you use one.

## Compiling:

You'll need the [MultiColors](https://forums.alliedmods.net/showthread.php?t=247770) include. This plugin works on SM 1.10, haven't tested on 1.11.

## Credits:

* [The Paint plugin by SlidyBat.](https://forums.alliedmods.net/showthread.php?p=2541664)
* Zealain, for the GOKZ Timer implementation of Paint.
