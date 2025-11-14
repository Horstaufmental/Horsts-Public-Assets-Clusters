--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    This file is licensed under the MPL 2.0 with the following exception:
    Changes to this configuration file do not create any obilgation to
    publish the modified version.
]]--

local Config = {}
--[[
	To get your trello app key visit the below URL, create a new key if haven't, go to "API key" then copy the first line:
	https://trello.com/power-ups/admin/

	To get your trello API token visit the following URL, create a new key if haven't, go to "API key" then generate a Token on the right side of the API key section (it should be 32 characters):
	https://trello.com/power-ups/admin/

	The board should be set as the URL board link:
	https://trello.com/b/HERE/
]]

Config.board = ""
Config.key = ""
Config.token = ""
Config.listName = "Titles"

--[[
["Team Name"] = {
	["Division Name"] = {groupID, divisionIcon, RGB},
}
]]--
Config.divisions = {
	["Misty Lake Fairy Order"] = {
		["21st Armored Grenadier"] = {0, "rbxassetid://14842204514", nil},
		["7th Littoral Marine Regiment"] = {0, "rbxassetid://14842204514", Color3.fromRGB(200, 0, 0)},
		["The Knightly Order"] = {0, "rbxassetid://14842204514", Color3.fromRGB(0,0,0)}
	}
}

return Config
