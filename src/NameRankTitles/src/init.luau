--[[
    NameRankTitles - Root ModuleScript
    
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
    
    This is a ModuleScript that provides shared metadata and constants.
    It does NOT auto-execute. Execution is controlled by Script placement.
    
    Installation:
    - Place NameServer (Script) in ServerScriptService
    - Place NameClient (LocalScript) in StarterPlayerScripts
    - Place this root module in ReplicatedStorage for shared access
]]--

local NameRankTitles = {}

-- Version information
NameRankTitles.Version = "1.4.0"
NameRankTitles.Author = "Horstaufmental"
NameRankTitles.License = "MPL-2.0"

-- Shared constants
NameRankTitles.Constants = {
    DefaultMaxDistance = 15,
}

return NameRankTitles
