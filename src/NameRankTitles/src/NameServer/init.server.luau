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
local Overhead = require(script.overhead)
local Divisions = require(script.divisions)

-- Get the Tag template (injected as a child of this script)
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

local function parse_ranks(str)
	-- range based
	local a, b = str:match("^(%-?%d+)%s*%-%s*(%-?%d+)$")
	if a and b then
		return { type = "range", min = tonumber(a), max = tonumber(b) }
	end

	-- greater and less than
	local n, op = str:match("^(%-?%d+)%s*([<>])$")
	if not n then
		op, n = str:match("^([<>])%s*(%-?%d+)$")
	end
	if n and op then
		if op == ">" then
			return { type = "greater", value = tonumber(n) }
		else
			return { type = "less", value = tonumber(n) }
		end
	end

	return { type = "equal", value = tonumber(str) }
end

local function onCharacter(character)
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

	local groupIdVal
	local playerRank
	local rankIcon = nil
	if team then
		groupIdVal = team:FindFirstChild("groupID")
		if not groupIdVal then
			warn("Missing 'groupID' IntValue for Team" .. team.Name)
			playerRank = team.Name
		else
			for k, v in pairs(config.customRanks) do -- first level: groups
				if k == groupIdVal.Value then
					local plrRank = player:GetRankInGroupAsync(groupIdVal.Value)
					for ke, ve in pairs(v) do -- second level: ranks
						local parsed = parse_ranks(ve[1])
						if
							(parsed.type == "greater" and (plrRank >= parsed.value) == false)
							or (parsed.type == "less" and (plrRank <= parsed.value) == false)
							or (parsed.type == "range" and (plrRank < parsed.min or plrRank > parsed.max))
							or (parsed.type == "equal" and plrRank ~= parsed.value)
						then
							continue
						end

						if ve[2] ~= nil then
							playerRank = ve[2]
						else
							playerRank = player:GetRoleInGroupAsync(groupIdVal.Value)
						end
						if ve[3] ~= nil then
							rankIcon = ve[3]
						end
					end -- end of second level
				end
			end -- end of first level
			if playerRank == nil then
				playerRank = team.Name
			end
		end
		if playerRank == nil then
			if groupIdVal ~= nil then
				playerRank = player:GetRoleInGroupAsync(groupIdVal.Value)
			else
				playerRank = team.Name
			end
		end
	else
		playerRank = "Guest"
	end

	local tag = tagTemplate:Clone()
	local user = tag.Container:WaitForChild("Primary")
	local rankClone = tag.Container:WaitForChild("Secondary")
	local bar = tag.Container:WaitForChild("Bar")

	local barrank_value = player:FindFirstChild("barrank_value")
	if not barrank_value then
		barrank_value = Instance.new("StringValue")
		barrank_value.Name = "barrank_value"
		barrank_value.Parent = player
	end
	local playerName = player.Name

	user.Text = playerName
	rankClone.Text = playerRank
	if rankIcon ~= nil then
		tag.Container.Rank.Visible = true
		tag.Container.Rank.Image = rankIcon
		tag.Container.Rank.Position = UDim2.new(0.499, 0, 0.62, 0)
		user.Position = UDim2.new(0.5, 0, -0.05, 0)
		rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)
	end
	if team then
		user.TextColor3 = team.TeamColor.Color
	else
		user.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	rankClone.TextColor3 = Color3.fromRGB(255, 255, 255)

	local highest_division = Divisions.findHighestDivision(player, config, team) or nil
	if highest_division ~= nil then
		bar.Visible = true
		user.Position = UDim2.new(0.5, 0, -0.05, 0)
		rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)
		tag.Container.Rank.Position = UDim2.new(0.735, 0, 0.62, 0)

		bar.BarEntry.Text = highest_division[2]
		barrank_value.Value = highest_division[3]
		bar.DivisionIcon.Image = highest_division[4]

		bar.BackgroundColor3 = highest_division[5]
	end

	-- Custom Titles from Trello
	local above, below, c, Bar, bar_rank, bar_c, bar_icon = Overhead.create(player, cache, config)
	if above then
		user.Text = above

		if below and below ~= "" then
			rankClone.Text = below
		else
			rankClone.Text = playerRank
		end

		if c then
			user.TextColor3 = c
		end

		if Bar and Bar ~= "" then
			bar.Visible = true
			user.Position = UDim2.new(0.5, 0, -0.05, 0)
			rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)

			bar.BarEntry.Text = Bar
		end

		if bar_rank and bar_rank ~= "" then
			local vl = player:FindFirstChild("barrank_value")
			if not vl then
				vl = Instance.new("StringValue")
				vl.Name = "barrank_value"
				vl.Parent = player
			end
			vl.Value = bar_rank
		end

		if bar_c then
			bar.BackgroundColor3 = bar_c
		end

		if bar_icon and bar_icon ~= "" then
			bar.DivisionIcon.Image = bar_icon
		end
	end

	tag.Parent = head
	tag.Container:FindFirstChild("Health").HealthHandler.Enabled = true
end

-- Auto-initialize on server startup
update()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		update()
	end
end)
