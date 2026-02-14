--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local Players = game:GetService("Players")

local Divisions = require(script.Parent.divisions)
local Helpers = require(script.logicHelpers)
local config = require(script.Parent.config)

local module = {}

function module.onCharacter(character, cache, tagTemplate)
	local player: Player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if character.Head:FindFirstChild("Tag") then
		character.Head.Tag:Destroy()
	end

	-- When a character spawns or respawns
	local head = character:WaitForChild("Head")
	local team = player.Team

	local playerRank, rankIcon = Helpers.getPlayerRank(player, team) or "Guest", nil

	local tag = tagTemplate:Clone()
	local user = tag.Container:WaitForChild("Primary")
	local rankClone = tag.Container:WaitForChild("Secondary")
	local bar = tag.Container:WaitForChild("Bar")

	local barrank_value
	if not player:FindFirstChild("barrank_value") then
		barrank_value = Instance.new("StringValue")
		barrank_value.Name = "barrank_value"
		barrank_value.Parent = player
	end
	local playerName = player.Name

	user.Text = playerName
	rankClone.Text = playerRank
	if rankIcon ~= nil then
		tag.Container.Rank.Image = rankIcon
				tag.Container.Rank.Visible = true
	end
	if team then
		user.TextColor3 = team.TeamColor.Color
	else
		user.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	rankClone.TextColor3 = Color3.fromRGB(255, 255, 255)

	local highest_division = Divisions.findHighestDivision(player, config, team) or nil
	if highest_division ~= nil then
		user.Position = UDim2.new(0.5, 0, -0.05, 0)
		rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)
		tag.Container.Rank.Position = UDim2.new(0.735, 0, 0.62, 0)

		bar.BarEntry.Text = highest_division[2]
		barrank_value.Value = highest_division[3]
		bar.DivisionIcon.Image = highest_division[4]

		bar.BackgroundColor3 = highest_division[5]
		bar.Visible = true
	end

	-- Custom Titles from Trello
	Helpers.parseTrelloTitle(player, playerRank, rankClone, user, bar, cache)

	tag.Parent = head
	tag.Container:FindFirstChild("Health").HealthHandler.Enabled = true
end

return module