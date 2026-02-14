--[[
	Copyright (c) 2025 Horstaufmental
	SPDX-License-Identifier: MPL-2.0
	
	# NameRankTitles - Installation Guide

	## Understanding Roblox Script Execution

	>[!WARNING]
	>Read this before installing!

	### How Roblox Executes Scripts

	Roblox executes scripts based on **two factors only**:

	1. **Script Type** (Script, LocalScript, or ModuleScript)
	2. **Container Placement** (which service the script is placed in)

	### What Does NOT Trigger Execution

	**Folder names** - Naming a folder `server` or `client` does nothing  
	**File names** - Naming a file `init` does not make it auto-execute  
	**Folder structure** - Nested folders do not affect execution  
	**ModuleScript placement** - `ModuleScripts` never auto-execute, regardless of location

	### What DOES Trigger Execution

	**Script in ServerScriptService** - Auto-executes on server startup  
	**LocalScript in StarterPlayerScripts** - Auto-executes for each player  
	**LocalScript in StarterCharacterScripts** - Auto-executes when character spawns  
	**Script/LocalScript in workspace** - Auto-executes (but not recommended)

	### ModuleScripts

	ModuleScripts **never auto-execute**. They only run when explicitly `require()`d by another script.

	```lua
	-- This ModuleScript will NOT run automatically
	local MyModule = {}

	print("This only prints when required!")

	return MyModule
	```

	---

	## Installation Steps

	### Step 1: Download the Asset

	Download the latest release from [GitHub Releases](https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/releases)

	### Step 2: Install Server Components

	1. Open Roblox Studio
	2. Navigate to **ServerScriptService** in the Explorer
	3. Insert `NameServer` as a **Script** (not a ModuleScript!)
	4. Verify it contains these children:
	   - `logic` (ModuleScript)
	     - `logicHelpers` (ModuleScript)
	   - `config` (ModuleScript)
	   - `trello` (ModuleScript)
	   - `overhead` (ModuleScript)
	   - `divisions` (ModuleScript)
	   - `Tag` (BillboardGui with nested components)

	**Expected Structure:**
	```
	ServerScriptService
	└── NameServer [Script] <- Must be a Script, not ModuleScript
	    ├── logic [ModuleScript]
	    │   └── logicHelpers [ModuleScript]
	    ├── config [ModuleScript]
	    ├── trello [ModuleScript]
	    ├── overhead [ModuleScript]
	    ├── divisions [ModuleScript]
	    └── Tag [BillboardGui]
	        └── Container [Frame]
	            ├── Primary [TextLabel]
	            ├── Secondary [TextLabel]
	            ├── Bar [Frame]
	            ├── Rank [ImageLabel]
	            ├── Select [Frame]
	            └── Health [Frame]
	                └── HealthHandler [Script]
	```

	### Step 3: Install Client Components

	1. Navigate to **StarterPlayer → StarterPlayerScripts** in the Explorer
	2. Insert `NameClient` as a **LocalScript** (not a ModuleScript!)
	3. Verify it contains:
	   - `clickHandler` (ModuleScript)

	**Expected Structure:**
	```
	StarterPlayer
	└── StarterPlayerScripts
	    └── NameClient [LocalScript] <- Must be a LocalScript
	        ├── clickHandler [ModuleScript]
	        ├── ageEligibilityHandler [ModuleScript]
	        ├── ToggleEvent [BindableEvent]
	        └── checkEligibilityEvent [RemoteEvent]
	```

	### Step 4: Install Shared Module

	Used for shared constants:

	1. Navigate to **ReplicatedStorage** in the Explorer
	2. Insert `NameRankTitles` as a **ModuleScript**
	3. This module provides metadata only and does NOT execute

	**Expected Structure:**
	```
	ReplicatedStorage
	└── NameRankTitles [ModuleScript] <- Used for shared constants
	```

	### Step 5: Install Events

	The client script requires a BindableEvent and ToggleEvent for communication:

	Move `ToggleEvent` and `checkEligibilityEvent` from `NameClient`
	to **ReplicatedStorage**

	**Expected Structure:**
	```
	ReplicatedStorage
	├── ToggleEvent [BindableEvent]
	├── checkEligibilityEvent [RemoteEvent]
	└── NameRankTitles [ModuleScript]
	```

	### Step 6: Configure Settings

	#### Constants

	1. In ReplicatedStorage, open `NameRankTitles`
	2. Edit the configuration values:

	```lua
	-- Shared constants
	NameRankTitles.Constants = {
		DefaultMaxDistance = 15,
		EnableCanChatIcon = true,
		EnableTrello = false,
	}
	```

	#### Titles

	1. In ServerScriptService, expand `NameServer`
	2. Open the `config` ModuleScript
	3. Edit the configuration values:

	```lua
	-- Trello API credentials
	Config.board = "YOUR_BOARD_ID"
	Config.key = "YOUR_API_KEY"
	Config.token = "YOUR_API_TOKEN"
	Config.listName = "Titles"

	-- Division configuration
	Config.divisions = {
	    ["Team Name"] = {
	        ["Division Name"] = {
	            groupID,
	            divisionIcon,
	            rgb,
	            minRank,
	            maxRank,
	            priority,
	        },
	    }
	}

	-- Custom rank names
	Config.customRanks = {
	    [groupId] = {
	        {"RankId", "CustomRankName", "CustomRankIcon"},
	    }
	}
	```

	See the main [README.md](README.md) for detailed configuration instructions.

	### Step 7: Enable HTTP Requests

	1. Go to **Home -> Experience Settings**
	2. Navigate to **Security** tab
	3. Enable **"Allow HTTP Requests"**
	4. Click **Save**

	---

	## Common Installation Mistakes

	### ❌ Mistake 1: Wrong Script Type

	**Problem:** Placing `NameServer` as a ModuleScript instead of a Script

	**Symptom:** Nothing happens, no tags appear

	**Solution:** Ensure it's a **Script** (white icon), not a ModuleScript (purple icon with white jigsaw piece)

	### ❌ Mistake 2: Wrong Container

	**Problem:** Placing scripts in ReplicatedStorage or ServerStorage

	**Symptom:** Scripts don't execute

	**Solution:** 
	- Server scripts → **ServerScriptService**
	- Client scripts → **StarterPlayerScripts**

	### ❌ Mistake 3: Missing Children

	**Problem:** Script doesn't have required ModuleScript children

	**Symptom:** Error: "Key 'config' not found in class 'LuaSourceContainer'"

	**Solution:** Ensure all ModuleScripts are direct children of the main Script

	### ❌ Mistake 4: HTTP Error 429

	**Problem:** Empty Trello fields in configuration

	**Symptom:** Trello logic breaks, causing the main script to also break

	**Solution:** Fill in the fields or disable Trello usage

	### ❌ Mistake 5: Missing ToggleEvent

	**Problem:** No BindableEvent named "ToggleEvent" in ReplicatedStorage

	**Symptom:** Client script errors or click functionality doesn't work

	**Solution:** Create a BindableEvent in ReplicatedStorage named exactly "ToggleEvent"

	---

	## Verification Checklist

	Before publishing your game, verify:

	- [ ] `NameRankTitles` is a **ModuleScript** in **ReplicatedStorage**
	- [ ] `NameServer` is a **Script** in **ServerScriptService**
	- [ ] `NameClient` is a **LocalScript** in **StarterPlayerScripts**
	- [ ] `ToggleEvent` is a **BindableEvent** in **ReplicatedStorage**
	- [ ] `checkEligibilityEvent` is a **RemoteEvent** in **ReplicatedStorage**
	- [ ] All ModuleScripts are children of their respective Scripts
	- [ ] `Tag` BillboardGui is a child of `NameServer`
	- [ ] HTTP Requests are enabled in Game Settings
	- [ ] Configuration values are set in `NameRankTitles` ModuleScript
	- [ ] Configuration values are set in `config` ModuleScript
	- [ ] Teams have `groupID` IntValue children (if using group integration)

	---

	## File Structure Reference

	### Source Structure (Development)

	This is how the asset is organized in source control:

	```
	NameRankTitles/
	├── init.luau                -- Root ModuleScript (metadata only)
	├── server/
	│   ├── logic/
	│   │   ├── init.luau        -- Main server logic
	│   │   └── logicHelpers.luau -- Helper functions for logic
	│   ├── init.server.luau     -- Server entry point
	│   ├── config.luau          -- Configuration
	│   ├── divisions.luau       -- Division logic
	│   ├── overhead.luau        -- Overhead tag logic
	│   ├── trello.luau          -- Trello API integration
	│   └── Tag.rbxmx            -- BillboardGui template
	└── client/
	    ├── init.client.luau     -- Client entry point
	    ├── clickHandler.luau    -- Click interaction logic
	    ├── ageEligibilityHandler.luau -- Chat eligibility logic
	    ├── ToggleEvent.json     -- 'ToggleEvent' BindableEvent
	    └── checkEligibilityEvent.json -- 'checkEligibilityEvent' RemoteEvent
	```

	### Runtime Structure (In Roblox)

	This is how the asset must be placed in your game:

	```
	ServerScriptService
	└── NameServer [Script]
	    ├── logic [ModuleScript]
	    │   └── logicHelpers [ModuleScript]
	    ├── config [ModuleScript]
	    ├── trello [ModuleScript]
	    ├── overhead [ModuleScript]
	    ├── divisions [ModuleScript]
	    └── Tag [BillboardGui]

	StarterPlayer
	└── StarterPlayerScripts
	    └── NameClient [LocalScript]
	        ├── clickHandler [ModuleScript]
	        └── ageEligibilityHandler [ModuleScript]

	ReplicatedStorage
	├── ToggleEvent [BindableEvent]
	├── checkEligibilityEvent [RemoteEvent]
	└── NameRankTitles [ModuleScript] (optional)
	```

	---

	## Advanced: Understanding the Build Process

	If you're building from source, the build tool must:

	1. **Convert `server/init.server.luau` to a Script** (not ModuleScript)
	2. **Convert `client/init.client.luau` to a LocalScript** (not ModuleScript)
	3. **Keep all other `.luau` files as ModuleScripts**
	4. **Inject `Tag.rbxmx` as a child of the server Script**
	5. **Preserve the hierarchy of all nested Instances**

	The `init.luau` naming is a **development convention only** - it has no special meaning to Roblox.

	---

	## Need Help?

	If you encounter issues:

	1. Check the [Troubleshooting section](README.md#troubleshooting) in the main README
	2. Verify your installation against this guide
	3. Test in "Clients and Servers" mode
	4. Check the Output window for error messages
	5. Open an issue on [GitHub](https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/issues)

	---

	## License

	This asset is licensed under the **MPL-2.0** (Mozilla Public License Version 2.0).

	**Special Exception**: The `config` ModuleScript has an exception - modifications to this file do not create any obligation to publish the modified version.

	See [LICENSE](/LICENSE) for full details.
]]--