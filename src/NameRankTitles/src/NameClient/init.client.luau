--[[
    NameRankTitles - Client Entry Point
    
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
    
    This is a LocalScript that auto-executes when placed in StarterPlayerScripts.
    
    IMPORTANT: This script must be placed in StarterPlayerScripts to run.
    Folder names do NOT trigger execution - only LocalScript type + placement matters.
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the shared constants module
local Constants = require(ReplicatedStorage:FindFirstChild("NameRankTitles")) or nil

-- Require the clickHandler module (must be a child of this LocalScript)
local clickHandler = require(script.clickHandler)

-- Wait for the ToggleEvent to be created
local toggleEvent = ReplicatedStorage:WaitForChild("ToggleEvent")

-- Get the local player
local player = Players.LocalPlayer

-- Maximum distance for interaction
local maxDistance = if Constants then Constants.Constants.DefaultMaxDistance else 15

-- Auto-initialize on client startup
clickHandler.init({
	player = player,
	toggleEvent = toggleEvent,
	maxDistance = maxDistance
})
