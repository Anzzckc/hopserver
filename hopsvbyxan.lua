-- [[ MAIN LOGIC V6.1 - OBFUSCATE THIS ]]
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- Logic quản lý tệp tin Hop Count
local function ManageHopCount(isRealHop)
    local fileName = LocalPlayer.Name .. ".json"
    local lastUpdate, count = 0, 0
    if isfile(fileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success then 
            lastUpdate = data.LastTime or 0
            count = data.Count or 0 
        end
    end
    if (os.time() - lastUpdate) > 10800 then count = 0 end
    if isRealHop then
        count = count + 1
        writefile(fileName, HttpService:JSONEncode({["LastTime"] = os.time(), ["Count"] = count}))
    end
    return count
end

-- Hàm gửi Webhook Discord (Đã tối ưu Embed + Click-to-Copy)
local function SendVipReport(action, reason, detail, jobId, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local totalHops = ManageHopCount(false)
    local timestamp = os.date("%H:%M:%S - %m/%d/%Y")
    local color = isEmergency and 16711680 or 65280  -- Đỏ cho emergency, Xanh cho bình thường
    local playerCount = #Players:GetPlayers()
    
    local teleportScript = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'..jobId..'")'

    local data = {
        ["embeds"] = {{
            ["title"] = "🔔 Notification - Server Hop",
            ["description"] = "**Action:** " .. action,
            ["color"] = color,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),  -- ISO timestamp cho Discord
            ["footer"] = {
                ["text"] = "XuanAn Hop System • V6.1"
            },
            ["fields"] = {
                {
                    ["name"] = "📈 Hop Count",
                    ["value"] = "`" .. tostring(totalHops) .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Timestamp",
                    ["value"] = "`" .. timestamp .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "⚠️ Reason",
                    ["value"] = "`" .. reason .. "`",
                    ["inline"] = false
                },
                {
                    ["name"] = "🔍 Detail",
                    ["value"] = "`" .. detail .. "`",
                    ["inline"] = false
                },
                {
                    ["name"] = "📊 Players",
                    ["value"] = "`" .. playerCount .. "/12`",
                    ["inline"] = true
                },
                {
                    ["name"] = "🆔 Place ID",
                    ["value"] = "`" .. game.PlaceId .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "🆔 Job ID (Current)",
                    ["value"] = "`" .. jobId .. "`",
                    ["inline"] = false
                },
                {
                    ["name"] = "📜 Teleport Script",
                    ["value"] = "```lua\n" .. teleportScript .. "\n```",
                    ["inline"] = false
                }
            }
        }}
    }

    pcall(function()
        request({
            Url = Config.Webhook.Url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- Hàm thực hiện nhảy Server
local function ExecuteHop(reason, detail, isEmergency)
    ManageHopCount(true)
    SendVipReport("Hopping to New Server...", reason, detail, game.JobId, isEmergency)
    task.wait(1.5)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

-- Hệ thống Né Admin & Chat nhạy cảm
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function Monitor(player)
    if player == LocalPlayer then return end
    
    -- Kiểm tra Admin
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Admin Detected", "Target: " .. player.Name, true)
            return
        end
    end
    
    -- Kiểm tra Chat nguy hiểm
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(m, pfx .. word) then
                    ExecuteHop("Dangerous Command", "Player " .. player.Name .. " chat: " .. msg, true)
                    return
                end
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

-- HÀM PING 5 PHÚT (HEARTBEAT)
task.spawn(function()
    while true do
        task.wait(300)
        if Config["Enable 5-Min Ping"] then
            SendVipReport("Monitoring Server Status...", "Periodic Status Ping", "Account is still active.", game.JobId, false)
        end
    end
end)

-- AUTO RECONNECT (Dành cho rớt mạng)
GuiService.ErrorMessageChanged:Connect(function()
    local errorCode = GuiService:GetErrorCode()
    local NetworkErrors = {[277] = true, [279] = true, [280] = true}
    if NetworkErrors[errorCode] then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- AUTO HOP THEO GIỜ
task.spawn(function()
    if Config["Automatically Hop When The Time Comes"] then
        task.wait(Config.HopIntervalHours * 3600)
        ExecuteHop("Scheduled Auto Hop", "Refreshing server after " .. Config.HopIntervalHours .. "h.", false)
    end
end)
