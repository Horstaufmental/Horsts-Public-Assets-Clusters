--[[
	Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
--]]
local event = game.ReplicatedStorage:FindFirstChild("ToggleRankTagEvent")

event.OnClientEvent:Connect(function()
	for _, v in game.Players:GetPlayers() do
		local playerChar = v.Character
		if playerChar and playerChar.Head:FindFirstChild("Tag") then
			if not v:FindFirstChild("tag_hidden") or not v.tag_hidden.Value then
				playerChar.Head.Tag.Enabled = not (playerChar.Head.Tag.Enabled)
			end
		end
	end
end)