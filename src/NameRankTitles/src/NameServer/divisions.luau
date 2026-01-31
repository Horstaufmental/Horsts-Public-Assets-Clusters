--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local Divisions = {}

function Divisions.findHighestDivision(player, config, team)
	local highest_division = nil
	
	for k, v in pairs(config.divisions) do -- 1st level, factions
		if team and team.Name ~= k then
			continue
		end

		local oldPriority = 0
		for ke, va in pairs(v) do -- 2nd level, divisions
			-- backward compatibility
			local minRank = va[4] or 1
			local maxRank = va[5] or 255
			local curPriority = va[6] or 0
			local curRank = player:GetRankInGroupAsync(va[1])

			if player:IsInGroupAsync(va[1]) and (minRank <= curRank and curRank <= maxRank) then
				-- sort by highest ranking
				-- keep breaking differently in every sessions i tested
				if highest_division == nil or curPriority >= oldPriority then
					if curPriority == oldPriority and highest_division ~= nil and curRank < highest_division[1] then
						continue
					end
					local bgclr
					if va[3] ~= nil then
						bgclr = va[3]
					else
						bgclr = team.TeamColor.Color
					end
					oldPriority = curPriority

					-- {rankId, BarText, BarRank, DivIcon, BackgroundColor}
					highest_division = {
						player:GetRankInGroupAsync(va[1]),
						ke,
						player:GetRoleInGroupAsync(va[1]),
						va[2],
						bgclr,
					}
				end
			end
		end
	end
	
	return highest_division
end

return Divisions