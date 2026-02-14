--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local module = {}

function module.applyStatus(player: Player, canTalk: boolean)
	local character = player.Character
	if not character then
		return
	end
	
	local tag = character:WaitForChild("Head"):WaitForChild("Tag")
	local icon = tag:FindFirstChild("Container"):FindFirstChild("canChat")
	
	if not canTalk then
		icon.Visible = true
	end
end

return module