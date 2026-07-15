local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

function serverhop()
    local servers = {}
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Failed to get server list")
        return
    end
    
    local data = HttpService:JSONDecode(result)
    
    if data and data.data then
        for _, server in pairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        warn("Server hopping to: " .. randomServer)
        TeleportService:TeleportToPlaceInstance(PlaceId, randomServer, LocalPlayer)
    else
        warn("No servers available")
    end
end

serverhop()
