--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    to be placed under NameServer.Tag.Container.Health
]]--
local TS = game:GetService("TweenService")
local tInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local char = script.Parent.Parent.Parent.Parent.Parent

local humanoid:Humanoid = char:WaitForChild("Humanoid")
if humanoid == nil then
	return
end

local function updateHealthBar()
	local health = humanoid.Health
	local healthpoints = math.clamp(health / 100, 0, 1)

	local healthFrame = script.Parent
	local healthBar = healthFrame.Bar

	local goal = {}
	goal.Size = UDim2.new(healthpoints, 0, 1, 0)

	local tween = TS:Create(healthBar, tInfo, goal)
	tween:Play()

	if health < humanoid.MaxHealth then healthFrame.Visible = true else healthFrame.Visible = false end

	local color
	if health < humanoid.MaxHealth / 2 then
		-- red to yellow
		color = Color3.fromRGB(255,0,0):Lerp(Color3.fromRGB(255,255,0), healthpoints / 0.5)
	else
		-- yellow to green
		color = Color3.fromRGB(255,255,0):Lerp(Color3.fromRGB(0,255,0), (healthpoints - 0.5) / 0.5)
	end

	healthFrame.BackgroundColor3 = color
	healthFrame.UIStroke.Color = color

	healthBar.BackgroundColor3 = color
	healthBar.UIStroke.Color = color
end

humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealthBar)
humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealthBar)