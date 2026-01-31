--[[
    RankTitlesUtils - Root ModuleScript
    
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
    
    This is a ModuleScript that provides shared metadata and constants.
    It does NOT auto-execute. Execution is controlled by Script placement.
    
    Installation:
    - Place Plugins/Server-RankTitlesUtils (Script) in Adonis_Loader/Config/Plugins
    - Place ReplicatedStorage/ToggleRankTagEvent (RemoteEvent) in ReplicatedStorage
    - Place StarterPlayerScripts/ToggleRankTagClient (LocalScript) in StarterPlayerScripts
    - (Optional) Place this root module in ReplicatedStorage for shared access
]]--

local RankTitlesUtils = {}

-- Version information
RankTitlesUtils.Version = "1.1.0"
RankTitlesUtils.Author = "Horstaufmental"
RankTitlesUtils.License = "MPL-2.0"

return RankTitlesUtils
