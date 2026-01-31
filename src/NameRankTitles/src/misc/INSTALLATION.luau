--[[
	Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
    
    # INSTALLATION GUIDE: NameRankTitles
    This plugin is to be used alongside RankTitlesUtils for admin controls
    
    Step 1:
    Move the scripts/models into each corresponding place (e.g. a script inside "ServerScriptService" folder would need be moved to ServerScriptService)
    For the case of "Plugins", move the scripts inside into your Adonis_Loader.Config.Plugins folder
    
    Step 2:
    Configure the "adminPerms" inside script as needed (See Configuration for more information)
    
    Done. That's all you needed.
    
    ------------------------------------------
    Commands
    ------------------------------------------

	| Prefix | Command | Arguments | Description | Admin Level |
	|--------|---------|-----------|-------------|-------------|
	| : | `hidename`, `toggletag`, `hidetag` 		| `player`							  		 | Hide player's nametag (globally					 | Admins |
	| : | `nameedit`, `newname` 					| `player`, `new name` 				 		 | Edit player's name in the 						 | Admins |
	| : | `rankedit`, `newrank`, `ranktag` 			| `player`, `new rank` 				  		 | Edit player's rank in the ranktag  				 | Admins |
	| : | `namecoloredit`, `namecolor` 				| `player`, `new name color (in RGB)` 		 | Edit player's name color in the ranktag  		 | Admins |
	| : | `hidebar`, `togglebar`, `hidedivision` 	| `player` 							  		 | Hide player's divisional bar (globally)			 | Admins |
	| : | `baredit`, `newbardiv`, `divbar` 			| `player`, `new rank` 				  		 | Edit player's divisional bar title 				 | Admins |
	| : | `barrankedit`, `newbarrank`, `rankbar` 	| `player`, `new rank` 				  		 | Edit player's divisional bar rank 				 | Admins |
	| : | `iconedit`, `newbaricon`, `iconbar` 		| `player`, `new icon (must be an asset id)` | Edit player's divisional bar icon 				 | Admins |
	| : | `barcoloredit`, `barcolor` 				| `player`, `new bar color (in RGB)` 		 | Edit player's divisional bar color in the ranktag | Admins |
	| ! | `showtag`, `showtagall`, `toggletagall`   | *(none)* 									 | Hide everyone's nametag (locally) 				 | Players|
	
	------------------------------------------
	Usage Examples
	------------------------------------------
	
	-- Hide a player's tag
	:hidename Player1

	-- Change someone's displayed name
	:nameedit Player1 [VIP] CustomName

	-- Update rank display
	:rankedit Player1 Supreme Commander

	-- Change name color to red
	:namecolor Player1 255, 0, 0

	-- Toggle divisional bar visibility
	:hidebar Player1

	-- Update division bar text
	:baredit Player1 Elite Division

	-- Change bar icon (using asset ID)
	:iconedit Player1 123456789

	-- Change bar color to blue
	:barcolor Player1 0, 0, 255

	-- Player command: toggle all tags visibility (local only)
	!showtag
	
	------------------------------------------
	Configuration
	------------------------------------------

	The default admin level for commands is set to "Admins". To change this:

	1. Open "Server: RankTitlesUtils"
	2. Modify the `adminPerms` variable at line 15:
	   "local adminPerms = "YourCustomRank""
	3. Use rank names from your Adonis Settings or custom ranks
	
	------------------------------------------
	Notes
	------------------------------------------

	- RGB Format: Colors must be specified as `R, G, B` (e.g., `255, 0, 0` for red)
	- Asset IDs: For icon commands, provide only the numeric asset ID without the `rbxassetid://` prefix
	- Player Targeting: Commands support Adonis player selectors:
	  - `me` - Target yourself
	  - `all` - Target all players
	  - `others` - Target everyone except yourself
	  - `%TEAMNAME` - Target specific team
	  > (For more information, please read the manual by running `!usage` in game with Adonis)
	- Global vs Local: 
	  - Admin commands (`:`) affect all players globally
	  - Player commands (`!`) only affect the command user locally
    
    ------------------------------------------
    
    Reporting bugs or having any questions?
    You can open a new issue in my repository:
    https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters
]]--