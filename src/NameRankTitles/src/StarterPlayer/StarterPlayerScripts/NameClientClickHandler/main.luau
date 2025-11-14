--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
]]--
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local TS = game:GetService("TweenService")
local tInfo_select = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local toggleEvent = script.ToggleEvent

local toggle = false
local cd = false
local max_dist = 15

local cache = {}
local previousPlayer = ""

local function cooldownThing()
	cd = true
	task.wait(0.35)
	cd = false
end

local function typewrite(label, text: string, speed: number)
	label.Text = ""
	for i = 1, #text do
		label.Text = string.sub(text, 1, i)
		task.wait(speed / #text)
	end
end

local Character
local tween_select
local tween_unselect

script.InitHightlight.Event:Connect(function(local_player: Player, target: Player, max_dist: number)
	local character = target.Character

	local highlight = Instance.new("Highlight")
	highlight.Parent = character
	highlight.Enabled = true

	while toggle ~= false do
		task.wait(0)

		local dist = local_player:DistanceFromCharacter(character:FindFirstChild("HumanoidRootPart").Position)
		local t = math.clamp(dist / max_dist, 0, 1)

		if dist > max_dist then
			print(script.Name..": max > max_dist, exiting")
			toggle = false
			toggleEvent:Fire()
		elseif t <= 0.5 then
			--print("green to yellow: dist: ".. dist .. " | t: " .. t / 0.5)
			highlight.FillColor = Color3.new(0, 1, 0):Lerp(Color3.new(1, 1, 0), t / 0.5)
		else
			--print("yellow to red: dist: ".. dist .. " | t: " .. t)
			highlight.FillColor = Color3.new(1, 1, 0):Lerp(Color3.new(1, 0, 0), t)
		end
	end
end)

Mouse.Button1Down:Connect(function()
	if not Mouse.Target then return end
	local Part = Mouse.Target
	if Part:FindFirstAncestorWhichIsA("Model") then Character = Part:FindFirstAncestorWhichIsA("Model") end

	if Character and game.Players:GetPlayerFromCharacter(Character) then
		if cd then return end

		toggle = not toggle

		-- scale = k * 1 / length | or simply scale = C / length
		-- example, 0.9 = C / 24, 21.6 = C
		-- meaning scale = 21.6 / length
		-- multiply it by 10^-1 to get the actual scale
		tween_select = TS:Create(Character.Head:FindFirstChild("Tag").Container.Select, tInfo_select, { Size = UDim2.new((21.6 / #Character.Head:FindFirstChild("Tag").Container.Primary.Text) * 10^-1, 0, 0.02, 0) })
		tween_unselect = TS:Create(Character.Head:FindFirstChild("Tag").Container.Select, tInfo_select, { Size = UDim2.new(0, 0, 0.02, 0) })

		local PlayerTargeted = game.Players:GetPlayerFromCharacter(Character)

		local dist = Player:DistanceFromCharacter(Character:FindFirstChild("HumanoidRootPart").Position)
		if dist > max_dist then return end

		if previousPlayer == "" then
			previousPlayer = PlayerTargeted.Name 
		elseif previousPlayer ~= "" and previousPlayer ~= PlayerTargeted.Name then
			typewrite(Character.Head:FindFirstChild("Tag").Container.Bar.BarEntry, cache[previousPlayer], 0.15)
			previousPlayer = PlayerTargeted.Name
		end

		local tag = Character.Head:FindFirstChild("Tag")
		if not tag then return end

		local bar = tag.Container:WaitForChild('Bar')

		if PlayerTargeted:FindFirstChild("barrank_value") and PlayerTargeted:FindFirstChild("barrank_value").Value ~= "" then
			if toggle == true then
				if not cache[PlayerTargeted.Name] then cache[PlayerTargeted.Name] = bar.BarEntry.Text end
				tween_select:Play()
				script.InitHightlight:Fire(Player, PlayerTargeted, max_dist)
				typewrite(bar.BarEntry, PlayerTargeted.barrank_value.Value, 0.25)
			else
				for _,v in pairs(Character:GetChildren()) do
					if v:IsA("Highlight") then v:Destroy() end
				end
				tween_unselect:Play()
				typewrite(bar.BarEntry, cache[PlayerTargeted.Name], 0.25)
			end
		end

		cooldownThing()
		print("done - toggle: "..tostring(toggle))
	end
end)

toggleEvent.Event:Connect(function()
	local PlayerTargeted = game.Players:GetPlayerFromCharacter(Character)

	local tag = Character.Head:FindFirstChild("Tag")
	local bar = tag.Container:WaitForChild('Bar')

	if toggle == false then
		for _,v in pairs(Character:GetChildren()) do
			if v:IsA("Highlight") then v:Destroy() end
		end
		tween_unselect:Play()
		typewrite(bar.BarEntry, cache[PlayerTargeted.Name], 0.25)
	end
end)