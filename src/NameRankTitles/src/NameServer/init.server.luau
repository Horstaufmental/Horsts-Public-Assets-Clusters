--[[
    NameRankTitles - Server Entry Point
    
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
    Modified by Horstaufmental
    
    This is a Script that auto-executes when placed in ServerScriptService.
    
    IMPORTANT: This script must be placed in ServerScriptService to run.
    Folder names do NOT trigger execution - only Script type + placement matters.
]]
--

local Players = game:GetService("Players")

-- Require modules directly from script children
-- These are ModuleScripts that must be children of this Script
local config = require(script.config)
local Trello = require(script.trello)
local Logic = require(script.logic)

-- Get the Tag template
local tagTemplate = script.Tag

local cache

local function update()
	if config.enableTrello then
		local url = "https://api.trello.com/1/boards/"
			.. config.board
			.. "/lists?cards=open&card_fields=name,desc&filter=open&fields=name&key="
			.. config.key
			.. "&token="
			.. config.token
		cache = Trello.fetch(url, config.listName)
	end
end

-- Auto-initialize on server startup
update()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		Logic.onCharacter(player.Character, cache, tagTemplate)
	end)
	if player.Character then
		Logic.onCharacter(player.Character, cache, tagTemplate)
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		update()
	end
end)
