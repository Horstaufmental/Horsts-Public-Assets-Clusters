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
local TextChatService = game:GetService("TextChatService")

-- Require the shared constants module
local Constants = require(ReplicatedStorage:FindFirstChild("NameRankTitles"))

-- Require the clickHandler module (must be a child of this LocalScript)
local clickHandler = require(script.clickHandler)

-- Require the ageEligibilityHandler module (must be a child of this LocalScript)
local ageEligibilityHandler = require(script.ageEligibilityHandler)

-- Wait for the events to be created
local toggleEvent = ReplicatedStorage:WaitForChild("ToggleEvent")
local checkEvent = ReplicatedStorage:WaitForChild("checkEligibilityEvent")

-- Get the local player
local player = Players.LocalPlayer

-- Maximum distance for interaction
local maxDistance = Constants.Constants.DefaultMaxDistance

-- Auto-initialize on client startup
clickHandler.init({
	player = player,
	toggleEvent = toggleEvent,
	maxDistance = maxDistance
})

checkEvent.OnClientEvent:Connect(function()
	if Constants.Constants.EnableCanChatIcon then
		-- Check if we can even talk in the first place
		if not TextChatService:CanUserChatAsync(player.UserId) then
			for _,v in pairs(game.Players:GetChildren()) do
				if v:IsA("Player") then
					ageEligibilityHandler.applyStatus(v, false)
				end
			end
		end
		
		-- Otherwise we check the other players
		for _, v in pairs(game.Players:GetChildren()) do
			if v:IsA("Player") then
				-- Check if target can chat in the first place
				local canChat = TextChatService:CanUserChatAsync(v.UserId)
				if not canChat then
					ageEligibilityHandler.applyStatus(v, false)
					continue
				end
				
				-- Check if target can chat to us
				local success, canChat_toPlayer = pcall(TextChatService:CanUsersChatAsync(player.UserId, v.UserId))
				
				-- If the target left the game during check, an error will occur
				-- in that case, we can just skip over
				if not success then
					continue
				end
				-- Otherwise we check as normal
				if not canChat_toPlayer then
					ageEligibilityHandler.applyStatus(v, false)
					continue
				end
				
				-- They can chat to us, let's move onto next person
			end
		end
	end
end)