--[[
	Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0
--]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	--[[
		Change this to allow the specified Admin Level and above to use the commands
		List of admin levels can be found in your Adonis's Settings
	]]--
	local adminPerms = "Admins"

	server.Commands.HideTag = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"hidename","toggletag","hidetag"};	-- Commands
		Args = {"player"};	-- Command arguments
		Description = "Hide player's nametag (globally)";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v:Player in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local tag = v.Character.Head:WaitForChild("Tag")
				tag.Enabled = not tag.Enabled
			end
		end
	}
	server.Commands.NameEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"nameedit","newname"};	-- Commands
		Args = {"player","new name"};	-- Command arguments
		Description = "Edit player's name in the ranktag";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name
				game.Workspace[playerName].Head.Tag.Container.Primary.Text = args[2]
			end
		end
	}
	server.Commands.RankEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"rankedit","newrank","ranktag"};	-- Commands
		Args = {"player","new rank"};	-- Command arguments
		Description = "Edit player's rank in the ranktag";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name
				game.Workspace[playerName].Head.Tag.Container.Secondary.Text = args[2]
			end
		end
	}
	server.Commands.NameColorEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"namecoloredit","namecolor"};	-- Commands
		Args = {"player","new name color (in RGB)"};	-- Command arguments
		Description = "Edit player's name color in the ranktag";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name

				local r, g, b = args[2]:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					game.Workspace[playerName].Head.Tag.Container.Primary.TextColor3 = color
				else 
					game.Workspace[playerName].Head.Tag.Container.Primary.TextColor3 = Color3.fromRGB(255,255,255) 
					error("Invalid RGB value, reverting to default color!")
				end
			end
		end
	}
	server.Commands.HideBar = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"hidebar","togglebar","hidedivision"};	-- Commands
		Args = {"player"};	-- Command arguments
		Description = "Hide player's divsional bar (globally)";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name
				local state = game.Workspace[playerName].Head.Tag.Container.Bar.Visible
				if state == true then
					game.Workspace[playerName].Head.Tag.Container.Bar.Visible = false
					game.Workspace[playerName].Head.Tag.Container.Primary.Position = UDim2.new(0.5, 0, 0.15, 0)
					game.Workspace[playerName].Head.Tag.Container.Secondary.Position = UDim2.new(0.5, 0, 0.46, 0)
				else
					game.Workspace[playerName].Head.Tag.Container.Bar.Visible = true
					game.Workspace[playerName].Head.Tag.Container.Primary.Position = UDim2.new(0.5, 0, -0.05, 0)
					game.Workspace[playerName].Head.Tag.Container.Secondary.Position = UDim2.new(0.5, 0, 0.26, 0)
				end
			end
		end
	}
	server.Commands.BarDivEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"baredit","newbardiv","divbar"};	-- Commands
		Args = {"player","new rank"};	-- Command arguments
		Description = "Edit player's divisional bar title";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name
				game.Workspace[playerName].Head.Tag.Container.Bar.BarEntry.Text = args[2]
			end
		end
	}
	server.Commands.BarRankEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"barrankedit","newbarrank","rankbar"};	-- Commands
		Args = {"player","new rank"};	-- Command arguments
		Description = "Edit player's divisional bar rank";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			if not plr:FindFirstChild("barrank_value") then
				local vl = Instance.new("StringValue")
				vl.Name = "barrank_value"
				vl.Parent = plr
			end
			plr.ranktag_barrank.Value = args[2]
		end
	}
	server.Commands.BarIconEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"iconedit","newbaricon","iconbar"};	-- Commands
		Args = {"player","new icon (must be an asset id)"};	-- Command arguments
		Description = "Edit player's divisional bar icon";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name
				game.Workspace[playerName].Head.Tag.Container.Bar.DivisionIcon.Image = "rbxassetid://".. args[2]
			end
		end
	}
	server.Commands.BarColorEdit = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"barcoloredit","barcolor"};	-- Commands
		Args = {"player","new bar color (in RGB)"};	-- Command arguments
		Description = "Edit player's divisional bar color in the ranktag";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = adminPerms;	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
				local playerName = v.Name

				local r, g, b = args[2]:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					game.Workspace[playerName].Head.Tag.Container.Bar.BackgroundColor3 = color
				else 
					game.Workspace[playerName].Head.Tag.Container.Bar.BackgroundColor3 = Color3.fromRGB(255,255,255) 
					error("Invalid RGB value, reverting to default color!")
				end
			end
		end
	}
	server.Commands.ToggleRankTagClient = {
		Prefix = server.Settings.PlayerPrefix;	-- Prefix to use for command
		Commands = {"showtag","showtagall","toggletagall"};	-- Commands
		Args = {};	-- Command arguments
		Description = "Hide everyone's nametag (locally)";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr: Player)
			game.ReplicatedStorage:FindFirstChild("ToggleRankTagEvent")
				:FireClient(plr, hiddenState[plr.Name])
		end
	}
end
