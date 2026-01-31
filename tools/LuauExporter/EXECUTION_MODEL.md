# Roblox Execution Model - Implementation Guide

## Overview

This document describes the correct Roblox execution model implemented in the LuauExporter build system.

## Core Principles

### 1. Script Types and Auto-Execution

- **Script**: Auto-runs on the server when placed in ServerScriptService
- **LocalScript**: Auto-runs on the client when placed in StarterPlayerScripts
- **ModuleScript**: Never auto-runs; must be required by other scripts

### 2. Folder-to-Script Conversion

When a directory contains an `init.luau` file:
- The directory becomes a **script instance** (not a folder)
- The script type is determined by:
  - Directory name containing "Server" → **Script**
  - Directory name containing "Client" → **LocalScript**
  - All other directories → **ModuleScript**
- Child files become children of the script instance

## Implementation

### Root Structure

```
NameRankTitles-v1.4.0 [Model]
├── NameRankTitles [ModuleScript]     ← Root init, named after tool
│   ├── NameServer [Script]           ← Auto-runs on server
│   │   ├── config [ModuleScript]
│   │   ├── divisions [ModuleScript]
│   │   ├── overhead [ModuleScript]
│   │   ├── trello [ModuleScript]
│   │   └── Tag [BillboardGui]
│   │
│   └── NameClient [LocalScript]      ← Auto-runs on client
│       └── clickHandler [ModuleScript]
│           └── ToggleEvent [BindableEvent]
│
├── INSTALLATION [ModuleScript]
└── LICENSE [ModuleScript]
```

### Source File Structure

```
src/
├── init.luau                         → ModuleScript (named after tool)
├── NameServer/
│   ├── init.server.luau              → Script (auto-runs)
│   ├── config.luau                   → ModuleScript
│   ├── divisions.luau                → ModuleScript
│   ├── overhead.luau                 → ModuleScript
│   ├── trello.luau                   → ModuleScript
│   └── Tag.rbxmx                     → BillboardGui
│
├── NameClient/
│   ├── init.client.luau              → LocalScript (auto-runs)
│   └── clickHandler/
│       ├── init.luau                 → ModuleScript
│       └── ToggleEvent.rbxmx         → BindableEvent
│
└── misc/
    ├── INSTALLATION.luau             → ModuleScript
    └── LICENSE.luau                  → ModuleScript
```

## Code Patterns

### Root ModuleScript (init.luau)

```lua
--[[
    Shared API Module
    This is a ModuleScript that provides shared configuration and utilities.
    It does not auto-execute. Server and client scripts require this module.
]]--

local ToolName = {}

-- Shared configuration or utilities
ToolName.Version = "1.3.1"

return ToolName
```

### Server Script (NameServer/init.server.luau)

```lua
--[[
    This is a Script that auto-runs on the server.
    
    IMPORTANT: This script must be placed in ServerScriptService to run.
    It requires modules directly from its children.
]]--

local Players = game:GetService("Players")

-- Require modules directly from script children
local config = require(script.config)
local Trello = require(script.trello)
local Overhead = require(script.overhead)
local Divisions = require(script.divisions)

-- Get injected assets
local tagTemplate = script.Tag

-- Auto-initialize on server
local function init()
    -- Server initialization code
end

init()

-- Event connections
Players.PlayerAdded:Connect(function(player)
    -- Handle player added
end)
```

### Client LocalScript (NameClient/init.client.luau)

```lua
--[[
    This is a LocalScript that auto-runs on the client.
    
    IMPORTANT: This script must be placed in StarterPlayerScripts to run.
    It requires modules directly from its children.
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the clickHandler module (child of this LocalScript)
local clickHandler = require(script.clickHandler)

-- Wait for required assets
local toggleEvent = ReplicatedStorage:WaitForChild("ToggleEvent")

-- Auto-initialize on client
clickHandler.init({
    player = Players.LocalPlayer,
    toggleEvent = toggleEvent,
    maxDistance = 15
})
```

## Build System Implementation

### Key Changes

1. **Root Init Naming**: Changed from `"init"` to `meta.Name` (tool name without version)
2. **Script Type Detection**: `DetectInitFile()` determines script type based on directory name (contains "Server" or "Client")
3. **Folder Conversion**: Directories with `init.luau` become script instances, not folders
4. **Auto-Execution**: Server and client scripts run automatically; no manual initialization needed

### Builder Logic

```csharp
// Root init becomes ModuleScript named after the tool
initScript = new ModuleScript { 
    Name = meta.Name,  // "NameRankTitles", not "init"
    Source = protectedSource, 
    Parent = root 
};

// Directory detection - name contains "Server" or "Client"
if (dirName:find("Server")) then
    container = new Script { Name = dirName, Source = source, Parent = targetParent };
elseif (dirName:find("Client")) then
    container = new LocalScript { Name = dirName, Source = source, Parent = targetParent };
else
    container = new ModuleScript { Name = dirName, Source = source, Parent = targetParent };
```

## Benefits

1. **Correct Execution**: Scripts auto-run in the proper context
2. **Clear Structure**: Script types match their execution semantics
3. **No Manual Init**: No need for RunService:IsServer() checks
4. **Proper Nesting**: Child modules are correctly parented under scripts
5. **Human-Readable**: Structure matches how Roblox developers organize code

## Migration Notes

### Old Model (Incorrect)

```lua
-- Root init.luau (was trying to be executable)
local Server = require(script.server)
local Client = require(script.client)

if game:GetService("RunService"):IsServer() then
    Server.init({ config = require(script.server.config) })
else
    Client.init()
end
```

### New Model (Correct)

```lua
-- Root init.luau (ModuleScript, not executable, optional)
local NameRankTitles = {}
NameRankTitles.Version = "1.4.0"
NameRankTitles.Author = "Horstaufmental"
return NameRankTitles

-- NameServer/init.server.luau (Script, auto-runs in ServerScriptService)
local config = require(script.config)
local Trello = require(script.trello)
local Overhead = require(script.overhead)
local Divisions = require(script.divisions)
local tagTemplate = script.Tag
-- Auto-initialize here

-- NameClient/init.client.luau (LocalScript, auto-runs in StarterPlayerScripts)
local clickHandler = require(script.clickHandler)
local toggleEvent = game:GetService("ReplicatedStorage"):WaitForChild("ToggleEvent")
-- Auto-initialize here
```

## Validation

Build output should show:

```
[Model] NameRankTitles-v1.4.0
  [ModuleScript] NameRankTitles ✓
    [Script] NameServer ✓
      [ModuleScript] config
      ...
    [LocalScript] NameClient ✓
      [ModuleScript] clickHandler
      ...
```

**Key Indicators:**
- Root init is `ModuleScript` named after tool
- `NameServer` is `Script` (not ModuleScript)
- `NameClient` is `LocalScript` (not ModuleScript)
- No folders pretending to be scripts
