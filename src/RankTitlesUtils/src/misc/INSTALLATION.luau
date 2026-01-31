--[[
	Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
    
    # INSTALLATION GUIDE: RankTitlesUtils
    
    Step 1:
    Move the scripts/models into each corresponding place (e.g. a script inside "ServerScriptService" folder would need be moved to ServerScriptService)
    
    Step 2:
    Create a new 'IntValue' inside every teams, name them "groupID" and put your groupID in the value
    (If group ranks are undesired, feel free to skip)
    
    Step 3:
    Configure "Config" inside "NameServer" as needed
    
    Done. That's all you needed.
    
----------------------------------------------
    Configuration
----------------------------------------------
    
    # Trello Setup
    Edit `Config` to add your Trello credentials:
    ------------------------------------------
    Config.board    =  "BOARD_ID"        -- Your Trello board ID (from URL: trello.com/b/HERE/)
	Config.key      =  "API_KEY"        -- Your API key from https://trello.com/power-ups/admin/
	Config.token    =  "TOKEN_32CHARS"        -- Your API token (32 characters)
	Config.listName =  "Titles"  -- Name of the list containing title cards
	------------------------------------------
	
	Getting Trello Credentials
	
	Visit https://trello.com/power-ups/admin/
	Create a new Power-Up or select an existing one
	Copy your API Key from the "API Key" section
	Click "Token" to generate a new API Token (must be 32 characters)
	Copy your board ID from the URL: `https://trello.com/b/BOARDID/board-name`
	
	# Custom Group-Wide Rank Names
	Customize rank names and icons for specific groups in `Config`. This provides a basic way to override default rank names without using Trello.
	------------------------------------------
	Config.customRanks = {
		[groupId] = {
			-- {"RankId", "CustomRankName", "CustomRankIcon"}
			-- Set second/third argument to nil if undesired
			
			-- Regular custom rank name & icon
			{"20", "Sergeant Major", "rbxassetid://12345"},
			
			-- "And above" - affects rank 100 and all higher ranks
			{"100>", "Commanders", nil},
			
			-- "And below" - affects rank 10 and all lower ranks
			{"<10", nil, "rbxassetid://54321"},
			
			-- Range-based - affects ranks 50 through 70
		},
	}
	------------------------------------------
	Example:
	------------------------------------------
	Config.customRanks = {
		[12345678] = {
			{"255", "Supreme Commander", "rbxassetid://98765"},
			{"200>", "High Command", nil},
			{"100-199", "Officers", "rbxassetid://11111"},
			{"50-99", "NCOs", nil},
			{"<49", "Enlisted", nil},
		},
	}
	------------------------------------------
	Special Keywords:
	- '>' - All ranks above (e.g., '100>' = ranks 100+)
	- '<' - All ranks below (e.g., '<10' = ranks 1-10)
	- '-' - Range of ranks (e.g., '50-70' = ranks 50 to 70)
	
	Note: For more advanced customization with custom names, colors, and divisional bars, use the Trello system instead.
	
	# Division Setup
	Configure divisions in `Config`:
	
	# Division Configuration
	Configure divisions in Config:
	------------------------------------------
	Config.divisions = {
    	["Team Name"] = {
       		["Division Name"] = {
            	groupID,          -- Roblox group ID
            	divisionIcon,     -- "rbxassetid://12345"
            	rgb,              -- Color3.fromRGB(R,G,B) or nil for team color
            	minRank,          -- Minimum rank (1-255)
            	maxRank,          -- Maximum rank (1-255)
            	priority,         -- Priority (higher = shown first)
        	},
    	}
	}
	------------------------------------------
	Example:
	------------------------------------------
	Config.divisions = {
    	["Red Team"] = {
        	["Elite Forces"] = {
            	12345678,                      -- Group ID
            	"rbxassetid://14842204514",   -- Division icon
            	Color3.fromRGB(200, 0, 0),    -- Red bar color
            	10,                            -- Min rank 10
            	255,                           -- Max rank 255
            	10,                            -- High priority
        	},
        	["Standard Infantry"] = {
            	12345678,
            	"rbxassetid://14842204514",
            	nil,                           -- Use team color
            	1,
            	9,
            	1,                             -- Low priority
        	},
    	}
	}
	------------------------------------------
	
	# Trello Card Format
	Create cards in your Trello list with the following format:

	- Card Name: Player username or Group:GROUPID for group-wide titles
	- Card Description (7 lines):
		i. Top line of name (supports #username#, #grouprole:GROUPID#)
	   ii. Bottom line of name (rank text)
	  iii. Name color in RGB format (e.g., 255, 0, 0) or N/A
	   iv. Division bar text
		v. Division bar rank text or N/A
	   vi. Division bar color in RGB format (e.g., 0, 100, 200)
	  vii. Division bar icon (asset ID number only)
	  
	Example Card:
	------------------------------------------
	Card Name: Horstaufmental
	
	Card Description:
	Horstaufmental
	Commander-in-chief
	239, 184, 56
	Lunar Defense Corps
	Field Marshal
	97, 14, 157
	131549281561184
	------------------------------------------
	Group-Wide Card Example:
	------------------------------------------
	Card Name: Group:12345678
	
	Card Description:
	#username#
	#grouprole:12345678#
	N/A
	Division Name
	N/A
	100, 100, 100
	14842204514
	------------------------------------------
	
	# Team Setup
	For proper group integration, ensure your Teams have an IntValue named groupID:
		1. Create or select a Team in game.Teams
		2. Add an IntValue child to the Team
		3. Name it groupID
		4. Set its Value to your Roblox group ID
	Example:
	------------------------------------------
	Teams
	└── MyTeam
    	└── groupID (IntValue) = 12345678
	------------------------------------------ 
	
---------------------------------------------- 
	Features in Detail
----------------------------------------------

	# Variable Replacement
	Use these variables in Trello card descriptions:
	- #username# - Replaced with the player's username
	- #grouprole:GROUPID# - Replaced with the player's role in the specified group
	
	# Priority System
	When a player is in multiple divisions:
		- The division with the highest priority is displayed
		- If priorities are equal, the highest rank within that division wins
		- Set priority as the 6th parameter in division configuration (default: 0)
		
	# Health System
	- Health bars automatically show when player health < max health
	- Colors interpolate based on health percentage:
		- 0-50%: Red → Yellow
		- 50-100%: Yellow → Green
	- Smooth transitions using TweenService
	
	# Click-to-Inspect
	Players can click on other players to:
		- Highlight them with a distance-based color indicator
		- View their division rank (typewriter animation)
		- Maximum distance: 15 studs (configurable in code)
		
    (ADDITIONAL INFO)
    You can remove the clicking functionality by deleting/setting 'Enabled' to false
    in NameClientClickHandler.
    
---------------------------------------------- 
	Important Notes
----------------------------------------------

	Studio Testing: PlayerAdded events may not fire in Studio solo mode. Use "Clients and Servers" mode or test in-game
	Trello Cache: The system updates Trello data every 30 seconds to minimize API calls
	Character Health: Health bars are designed for characters with ≤100 max health
	Name Distance: The system sets NameDisplayDistance and HealthDisplayDistance to 0 (tags replace default nameplates)
	
---------------------------------------------- 
	Troubleshooting
----------------------------------------------

	# Tags not appearing
	Check that Tag is properly placed under NameServer
	Verify character Head exists before tag creation
	Test in "Clients and Servers" mode, not solo Studio mode
	
	# Trello titles not loading
	Ensure that Allow HTTP Requests is turned on in the game settings
	Verify your API key, token, and board ID in Config.luau
	Check that your list name matches exactly (case-sensitive)
	Ensure Trello cards are formatted correctly (7 lines in description)
	Check output for HTTP errors
	
	# Division not showing
	Verify the player is in the specified group
	Check that rank is within minRank and maxRank range
	Ensure Team has a groupID IntValue child
	Verify team name matches exactly in Config.divisions
	
	# Group roles not working
	Ensure Teams have groupID IntValue children
	Verify group IDs are correct (numeric, not group name)
	Check that players are actually in the groups
	
---------------------------------------------- 
	Compatibility
----------------------------------------------

	Adonis Admin: Use RankTitlesUtils plugin for in-game tag management
	Custom Admin Systems: Commands can be adapted to other admin systems
	
---------------------------------------------- 
	License
----------------------------------------------

	This asset is licensed under the MPL-2.0 (Mozilla Public License Version 2.0).
	Special Exception: Config has an exception - modifications to this file do not create any obligation to publish the modified version.
	See the provided `LICENSE` for full details.

---------------------------------------------- 
	Credits
----------------------------------------------
	
	Originally made by K_ieraH and Nucl3arPlayz
	Modified by Horstaufmental

----------------------------------------------

    Reporting bugs or having any questions?
    You can open a new issue in my repository:
    https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters

]]--