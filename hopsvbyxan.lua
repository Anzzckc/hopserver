-- [[ MAIN LOGIC V6.0 - OBFUSCATE THIS ]]
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 1. Logic quản lý tệp tin Hop Count (Lưu trữ số lần nhảy server)
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
    -- Reset đếm sau 3 tiếng (10800 giây)
    if (os.time() - lastUpdate) > 10800 then count = 0 end
    if isRealHop then
        count = count + 1
        writefile(fileName, HttpService:JSONEncode({["LastTime"] = os.time(), ["Count"] = count}))
    end
    return count
end

-- 2. Hàm gửi Webhook với cấu trúc Click-to-copy (Sử dụng backtick `)
local function SendVipReport(action, reason, detail, jobId, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local totalHops = ManageHopCount(false)
    local timestamp = os.date("%H:%M:%S - %d/%m/%Y")
    local color = isEmergency and 16711680 or 65280 -- Đỏ nếu khẩn cấp, Xanh lá nếu bình thường
    local playerCount = #Players:GetPlayers()
    
    -- Lệnh script để người dùng copy và dán vào executor
    local teleportScript = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'..jobId..'")'
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🔔 Notification System",
            ["description"] = "Action: **" .. action .. "**",
            ["color"] = color,
            ["fields"] = {
                {["name"] = "📈 Hop Count", ["value"] = "`" .. tostring(totalHops) .. "`", ["inline"] = true},
                {["name"] = "⏰ Timestamp", ["value"] = "`" .. timestamp .. "`", ["inline"] = true},
                {["name"] = "⚠️ Reason", ["value"] = "`" .. reason .. "`", ["inline"] = false},
                {["name"] = "🔍 Detail", ["value"] = "```" .. detail .. "```", ["inline"] = false},
                {["name"] = "📊 Players", ["value"] = "`" .. playerCount .. "/12`", ["inline"] = true},
                {["name"] = "🆔 Place-Id", ["value"] = "`" .. game.PlaceId .. "`", ["inline"] = true},
                {["name"] = "🆔 Job-Id (Current)", ["value"] = "`" .. jobId .. "`", ["inline"] = false},
                {["name"] = "📜 Teleport Script (Click to Copy)", ["value"] = "```lua\n" .. teleportScript .. "\n```", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Spidey Bot Monitoring"}
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

-- 3. Hàm thực hiện nhảy Server
local function ExecuteHop(reason, detail, isEmergency)
    ManageHopCount(true)
    SendVipReport("Hopping to New Server...", reason, detail, game.JobId, isEmergency)
    task.wait(1.5)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

-- 4. Hệ thống Né Admin & Chat nhạy cảm
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function Monitor(player)
    if player == LocalPlayer then return end
    -- Kiểm tra Admin vào server
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Admin Detected", "Target: " .. player.Name, true)
            return
        end
    end
    -- Kiểm tra tin nhắn nhạy cảm
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

-- 5. Heartbeat Ping (Mỗi 5 phút)
task.spawn(function()
    while true do
        task.wait(300)
        if Config["Enable 5-Min Ping"] then
            SendVipReport("Monitoring Status", "Periodic Status Ping", "Account is still active.", game.JobId, false)
        end
    end
end)

-- 6. Auto Reconnect (Tự động kết nối lại khi mất mạng)
GuiService.ErrorMessageChanged:Connect(function()
    local errorCode = GuiService:GetErrorCode()
    local NetworkErrors = {[277] = true, [279] = true, [280] = true}
    if NetworkErrors[errorCode] then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- 7. Auto Hop theo giờ cấu chỉnh
task.spawn(function()
    if Config["Automatically Hop When The Time Comes"] then
        task.wait(Config.HopIntervalHours * 3600)
        ExecuteHop("Scheduled Auto Hop", "Refreshing server after " .. Config.HopIntervalHours .. "h.", false)
    end
end)
