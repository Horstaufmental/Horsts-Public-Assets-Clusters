--[[
    Copyright (c) 2025 Horstaufmental
    SPDX-License-Identifier: MPL-2.0

    Originally made by K_ieraH and Nucl3arPlayz  
	Modified by Horstaufmental
]]--

local HttpService = game:GetService("HttpService")

local Trello = {}

function Trello.fetch(url, listName): ()
	local json = HttpService:GetAsync(url)
	local data = HttpService:JSONDecode(json)
	
	for _, list in ipairs(data) do
		if list.name == listName then
			return list.cards
		end
	end

    return {}
end

return Trello