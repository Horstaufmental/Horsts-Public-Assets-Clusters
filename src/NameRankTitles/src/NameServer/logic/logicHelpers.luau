--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local Overhead = require(script.Parent.Parent.overhead)
local config = require(script.Parent.Parent.config)

local module = {}

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

function module.getPlayerRank(player: Player, team: Team): (string, string)
	local groupIdVal
	local playerRank
	local rankIcon

	if team then
		groupIdVal = team:FindFirstChild("groupID")
		if not groupIdVal then
			warn("Missing 'groupID' IntValue for Team" .. team.Name)
			playerRank = "Guest"
		else
			for k, v in pairs(config.customRanks) do -- first level: groups
				if k == groupIdVal.Value then
					local plrRank = player:GetRankInGroupAsync(groupIdVal.Value)
					for ke, ve in pairs(v) do -- second level: ranks
						local parsed = parse_ranks(ve[1])
						if
							(parsed.type == "greater" and (plrRank >= parsed.value) == false)
							or (parsed.type == "less" and (plrRank <= parsed.value) == false)
							or (parsed.type == "range" and (plrRank <= parsed.min and plrRank >= parsed.max) == false)
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
					end
				end
			end
		end
		if playerRank == nil then
			playerRank = player:GetRoleInGroupAsync(groupIdVal.Value)
		end
	else
		playerRank = "Guest"
	end

	return playerRank, rankIcon
end

function module.parseTrelloTitle
(player: Player, playerRank: string, rankClone: TextLabel, user: TextLabel, bar: Frame, cache)
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
end

return module