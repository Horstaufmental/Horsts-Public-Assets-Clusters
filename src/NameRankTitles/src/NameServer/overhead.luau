--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local function replaceVars(player, input)
	local down = string.lower(input)
	local hasGroupRole, endOf = string.find(down, "#grouprole:")

	if hasGroupRole ~= nil then
		local cut = string.sub(down, endOf + 1)
		local groupId = string.sub(cut, 1, string.find(cut, "#") - 1)

		input = string.gsub(
			input,
			string.sub(input, endOf - 10, endOf + string.len(groupId) + 1),
			player:GetRoleInGroup(tonumber(groupId))
		)
	end

	input = string.gsub(input, "#username#", player.Name)

	return input
end

local Overhead = {}

function Overhead.create(player, cache, config)
	if cache then
		for i, v in ipairs(cache) do
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

	return false -- Return false if no custom title is found
end

return Overhead