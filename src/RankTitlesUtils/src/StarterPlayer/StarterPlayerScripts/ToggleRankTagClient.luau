--[[
	Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
--]]
local event = game.ReplicatedStorage:FindFirstChild("ToggleRankTagEvent")

event.OnClientEvent:Connect(function(hiddenState)
	for _, v in game.Players:GetPlayers() do
		local playerChar = v.Character
		if playerChar and playerChar.Head:FindFirstChild("Tag") then
			if hiddenState == nil or hiddenState ~= false then
				playerChar.Head.Tag.Enabled = not (playerChar.Head.Tag.Enabled)
			end
		end
	end
end)