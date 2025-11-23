local event = game.ReplicatedStorage:FindFirstChild("ToggleRankTagEvent")

event.OnClientEvent:Connect(function()
	for _, v in game.Players:GetPlayers() do
		local playerChar = v.Character
		if playerChar and playerChar.Head:FindFirstChild("Tag") then
			playerChar.Head.Tag.Enabled = not (playerChar.Head.Tag.Enabled)
		end
	end
end)