# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This repository houses Roblox Studio assets for public release. Each asset is independently versioned and released through GitHub tags and releases. Source code is provided, but **binaries are not manually buildable** - they must be obtained from the [releases page](https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/releases).

## Project Structure

```
src/
  └── ASSETNAME/           # Each asset has its own directory
      ├── README.md        # Asset documentation
      └── src/
          ├── Plugins/              # Adonis plugin modules (if applicable)
          ├── ServerScriptService/  # Server-side scripts
          ├── StarterPlayer/        # Client-side scripts
          └── ReplicatedStorage/    # Shared resources (RemoteEvents, etc.)
misc/                      # Repository assets (images, etc.)
```

## Current Assets

### NameRankTitles
A Roblox overhead name tag system with:
- **Trello integration**: Fetches custom titles from Trello cards
- **Team-based coloring**: Tags reflect player's team color
- **Division/rank system**: Displays player divisions with configurable icons and colors
- **Group integration**: Supports multiple Roblox group IDs with rank-based filtering
- **Health indicators**: Shows player health with color-coded bars
- **Click-to-inspect**: Client-side interaction to view player details

**Key Files:**
- `main.luau`: Core server logic, handles Trello API, tag creation, character spawning
- `Config.luau`: Trello credentials, division configurations, group mappings
- `HealthHandler.luau`: Client-side health bar updates using TweenService
- `NameClientClickHandler/main.luau`: Click detection, highlight effects, typewriter animations

### RankTitlesUtils
Adonis admin commands plugin for managing NameRankTitles in-game. Provides 10 commands for runtime tag manipulation.

**Key Features:**
- **Tag visibility controls**: Toggle tags globally or locally
- **Text editing**: Modify names, ranks, division text on the fly
- **Color customization**: Change name and bar colors with RGB values
- **Icon management**: Update division icons using asset IDs
- **Client/Server architecture**: Uses RemoteEvents for player-side commands

**Key Files:**
- `server.RankTitlesUtils.luau`: Adonis plugin with 10 admin commands
- `ToggleRankTagClient.luau`: Client handler for local tag visibility
- `ToggleRankTagEvent.rbxmx`: RemoteEvent for client-server communication

**Command Categories:**
- Visibility: `:hidename`, `:hidebar`, `!showtag`
- Content: `:nameedit`, `:rankedit`, `:baredit`, `:barrankedit`
- Styling: `:namecolor`, `:barcolor`, `:iconedit`

## Development Workflow

### Versioning & Releases
- Each asset uses semantic versioning: `AssetName-vX.Y.Z`
- Git tags format: `NameRankTitles-v1.2.1`
- Find specific asset versions at: https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/tags
- **Never commit compiled/binary files** - releases are the source of truth for binaries

### File Types
- `.luau`: Lua/Luau scripts (Roblox's typed Lua dialect)
- `.rbxmx`: Roblox XML model files (UI instances, physical objects)

### Code Patterns

**Server-Side (main.luau):**
- Uses `pcall()` for API calls and error handling
- Implements caching to minimize API requests (30-second refresh cycle)
- Race condition handling for `PlayerAdded` events
- Variable replacement system: `#username#`, `#grouprole:GROUPID#`
- Priority-based division selection (higher priority wins)

**Client-Side (NameClientClickHandler):**
- Event-driven architecture with custom BindableEvents
- TweenService for smooth animations
- Distance-based interactions (max 15 studs default)
- Typewriter effect for text reveals
- Color interpolation for health/distance indicators

**Configuration:**
- Config files have MPL-2.0 exception: modifications don't require source publication
- Divisions use nested tables: `[TeamName][DivisionName] = {groupID, icon, color, minRank, maxRank, priority}`
- Trello card format documented inline (7 lines: top text, bottom text, color, bar text, bar rank, bar color, bar icon)

**Adonis Integration (RankTitlesUtils):**
- Plugin follows Adonis command structure: `Commands`, `Prefix`, `Args`, `Description`, `AdminLevel`, `Function`
- Uses `service.GetPlayers()` for player targeting with Adonis selectors
- RGB color parsing: `args[2]:match("(%d+),%s*(%d+),%s*(%d+)")`
- Asset ID formatting: Auto-prepends `rbxassetid://` to icon IDs
- Default admin level configurable via `adminPerms` variable

## License Compliance

All code is licensed under **MPL-2.0** (Mozilla Public License 2.0):
- Modifications to MPL-licensed files must be made available if redistributed
- Your own code that uses/interacts with these assets has no obligations
- Config.luau has a special exception allowing private modifications
- Always preserve copyright headers when modifying files

## Important Notes

- **Studio Testing**: PlayerAdded events may not fire in Studio solo mode - use "Clients and Servers" or test in actual game
- **Trello API**: Requires API key and token from https://trello.com/power-ups/admin/
- **Group Integration**: Team objects need `groupID` IntValue children for rank lookups
- **Health System**: Character health must be ≤100 for proper bar scaling
- **VS Code**: Repository ignores `.vscode/` directory
