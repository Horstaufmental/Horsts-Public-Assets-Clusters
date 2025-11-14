--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

	Originally made by K_ieraH and Nucl3arPlayz
	Modified by Horstaufmental
]]--

--[[ START OF CONFIGURATION ]]--

local config = require(script:WaitForChild("Config"))

local board = config.board
local key = config.key
local token = config.token
local listName = config.listName
local divisions = config.divisions

--[[ END OF CONFIGURATION ]]--

--[[ Tutorial Stuff ]]--
--[[

	Trello cards should be formatted like following:
	
	Card Name: Username
	1st Line: Top Line of Name
	2nd Line: Bottom Line of Name 
	3rd Line: R,G,B colour for the title. (input N/A if undesired)
	4th Line: Division Bar Text
	5th Line: Division Bar Rank (input N/A if undesired)
	6th Line: Division Bar Color
	7th Line: Division Bar Logo
	
--]]

--[[ Setting Important Stuff ]]--

game.StarterPlayer.NameDisplayDistance = 0
game.StarterPlayer.HealthDisplayDistance = 0

--[[ END OF IMPORTANT STUFF ]]--

-- Setting up variables & services
local url = "https://api.trello.com/1/boards/" .. board .. "/lists?cards=open&card_fields=name,desc&filter=open&fields=name&key=" .. key .. "&token=" .. token;
local rank = script:WaitForChild('Tag')
local http = game:GetService("HttpService");
local Players = game:GetService("Players")

-- Declaring cache variable for use by update and get rank object
local cache;

function replaceVars(player, input)
	local down = string.lower(input);
	local hasGroupRole, endOf = string.find(down, "#grouprole:");

	if (hasGroupRole ~= nil) then
		local cut = string.sub(down, endOf + 1);
		local groupId = string.sub(cut, 1, string.find(cut, "#") - 1);

		input = string.gsub(input, string.sub(input, endOf - 10, endOf + string.len(groupId) + 1), player:GetRoleInGroup(tonumber(groupId)));
	end

	input = string.gsub(input, "#username#", player.Name);

	return input;
end

function createOverheadObject(player)
	if (cache) then
		for i,v in ipairs(cache) do
			local isMatch = (string.lower(v.name) == string.lower(player.Name))

			-- Check for group match, e.g., "Group:12345"
			if not isMatch and string.sub(string.lower(v.name), 1, 6) == "group:" then
				local groupId = tonumber(string.sub(v.name, 7))
				if groupId and player:IsInGroup(groupId) then
					isMatch = true
				end
			end

			if isMatch then
				-- Clean the description and split into lines
				local desc = string.gsub(v.desc, "\r", "")
				local rawLines = string.split(desc, "\n")
				local lines = {} -- A new table to hold only non-empty lines

				-- Filter out empty lines caused by double newlines
				for _, line in ipairs(rawLines) do
					if line ~= "" then
						table.insert(lines, line)
					end
				end

				local above = ""
				local below = ""
				local c = nil
				local bar = ""
				local bar_rank = ""
				local bar_c = nil
				local bar_icon = ""

				-- Process the first line if it exists
				if #lines >= 1 then
					above = replaceVars(player, lines[1])
				end

				-- Process the second line if it exists
				if #lines >= 2 then
					below = replaceVars(player, lines[2])
				end

				-- Process the third line for color if it exists
				if #lines >= 3 then
					local buf = replaceVars(player, lines[3])
					if buf == "N/A" then
						c = nil
					else
						local colorParts = string.split(lines[3], "[%s,]+") -- Split by space or comma
						if #colorParts == 3 then
							local r, g, b = tonumber(colorParts[1]), tonumber(colorParts[2]), tonumber(colorParts[3])
							if r and g and b then
								c = Color3.fromRGB(r, g, b)
							end
						end
					end
				end

				if #lines >= 4 then
					bar = replaceVars(player, lines[4])
				end

				if #lines >= 5 then
					local buf = replaceVars(player, lines[5])
					if buf == "N/A" then
						buf = ""
					else
						bar_icon = buf
					end
				end

				if #lines >= 6 then
					local colorParts = string.split(lines[6], "[%s,]+") -- Split by space or comma
					if #colorParts == 3 then
						local r, g, b = tonumber(colorParts[1]), tonumber(colorParts[2]), tonumber(colorParts[3])
						if r and g and b then
							bar_c = Color3.fromRGB(r, g, b)
						end
					end
				end

				if #lines >= 7 then
					local prefix = "rbxassetid://"
					local buf = replaceVars(player, lines[7])

					bar_icon = prefix .. buf
				end

				-- Only return a custom title if the top line was successfully created
				if above ~= "" then
					return above, below, c, bar, bar_rank, bar_c, bar_icon
				end
			end
		end
	end

	return false; -- Return false if no custom title is found
end

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	if character.Head:FindFirstChild("Tag") then
		character.Head.Tag:Destroy()
	end

	-- When a character spawns or respawns
	local head = character:WaitForChild('Head')
	local team = player.Team

	local groupIdVal = team:FindFirstChild("groupID")
	if not groupIdVal then warn("Missing 'groupID' IntValue for Team"..team.Name) end
	local playerRank = player:GetRoleInGroup(groupIdVal.Value)

	local tag = rank:Clone()
	local user = tag.Container:WaitForChild('Primary')
	local rankClone = tag.Container:WaitForChild('Secondary')
	local bar = tag.Container:WaitForChild('Bar')
	if not player:FindFirstChild("ranktag_barrank") then
		local barrank_value = Instance.new("StringValue")
		barrank_value.Name = "barrank_value"
		barrank_value.Parent = player
	end
	local playerName = player.Name

	user.Text = playerName
	rankClone.Text = playerRank
	user.TextColor3 = team.TeamColor.Color
	rankClone.TextColor3 = Color3.fromRGB(255, 255, 255)

	for k,v in pairs(divisions) do -- 1st level, factions
		if team.Name ~= k then
			continue
		end

		for ke,va in pairs(v) do -- 2nd level, divisions
			if player:IsInGroup(va[1]) then
				bar.Visible = true
				user.Position = UDim2.new(0.5, 0, -0.05, 0)
				rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)

				bar.BarEntry.Text = ke
				bar.DivisionIcon.Image = va[2]

				if va[3] == nil then
					bar.BackgroundColor3 = team.TeamColor.Color
				else
					bar.BackgroundColor3 = va[3]
				end
			end
		end
	end

	-- Custom Titles from Trello
	local above, below, c, Bar, bar_rank, bar_c, bar_icon = createOverheadObject(player);
	if (above) then
		user.Text = above

		if below and below ~= "" then
			rankClone.Text = below
		else
			rankClone.Text = playerRank
		end

		if (c) then
			user.TextColor3 = c
		end

		if Bar and Bar ~= "" then
			bar.Visible = true
			user.Position = UDim2.new(0.5, 0, -0.05, 0)
			rankClone.Position = UDim2.new(0.5, 0, 0.26, 0)
			
			bar.BarEntry.Text = Bar
		end

		if bar_rank and bar_rank ~= "" then
			local vl:StringValue = player:FindFirstChild("ranktag_barrank")
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

function updateTrelloCache()
	pcall(function()
		local jsonResponse = http:GetAsync(url);
		local returnedResponses = http:JSONDecode(jsonResponse);

		for i,v in ipairs(returnedResponses) do
			if (v.name == listName) then
				cache = v.cards;
				break -- Exit loop once we found our list
			end
		end
	end)
end

updateTrelloCache();

Players.PlayerAdded:Connect(function(player)
	-- Connect the event for future character spawns
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Check if the character already exists (to fix the race condition)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)

--[[
-- Optional: If you want to update player tags on demand from external sources
-- Just create a RemoteEvent named "UpdateTag" in ReplicatedStorage

game.ReplicatedStorage.UpdateTag.OnServerEvent:Connect(function(player)
	local character = player.Character
	if character then
		onCharacterAdded(character)
	end
end)
]]--

while (true) do
	wait(30);
	updateTrelloCache();
end