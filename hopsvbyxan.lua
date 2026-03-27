-- [2026-03-27] Logic Version 3.1 - VIP "Jump First, Report Later"
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- 1. QUẢN LÝ BỘ ĐẾM & GIỚI HẠN 3 TIẾNG (SESSION)
local function ManageHopCount()
    local currentTime = os.time()
    local lastUpdate, count = 0, 0
    
    if isfile("XuanAn_Session.json") then
        local success, data = pcall(function() 
            return HttpService:JSONDecode(readfile("XuanAn_Session.json")) 
        end)
        if success then 
            lastUpdate = data.LastTime or 0
            count = data.Count or 0 
        end
    end

    -- Nếu quá 3 tiếng (10800 giây) không hoạt động, reset về 0
    if (currentTime - lastUpdate) > 10800 then 
        count = 0 
    end

    count = count + 1
    writefile("XuanAn_Session.json", HttpService:JSONEncode({
        ["LastTime"] = currentTime, 
        ["Count"] = count
    }))
    return count
end

-- 2. HÀM GỬI WEBHOOK VIP (SAU KHI ĐÃ NHẢY SANG SERVER MỚI)
local function SendVipReport(reason, detail, oldJobId, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local totalHops = ManageHopCount()
    local timestamp = os.date("%H:%M:%S - %d/%m/2026")
    local color = isEmergency and 16711680 or 65280 -- Đỏ hoặc Xanh lá
    local playerCount = #Players:GetPlayers()
    
    -- Tạo lệnh Script Teleport để copy nhanh
    local teleportScript = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'..oldJobId..'")'

    local data = {
        ["embeds"] = {{
            ["title"] = "Thông Báo 🔔",
            ["color"] = color,
            ["fields"] = {
                {["name"] = "📈 Hop Server", ["value"] = "**" .. tostring(totalHops) .. "**", ["inline"] = true},
                {["name"] = "⏰ Thời gian", ["value"] = timestamp, ["inline"] = true},
                {["name"] = "⚠️ Lý do", ["value"] = reason, ["inline"] = false},
                {["name"] = "🔍 Chi tiết", ["value"] = detail, ["inline"] = false},
                {["name"] = "📊 Players :", ["value"] = "`" .. playerCount .. "/12`", ["inline"] = true},
                {["name"] = "🆔 Place-Id :", ["value"] = "`" .. game.PlaceId .. "`", ["inline"] = true},
                {["name"] = "🆔 Job-Id :", ["value"] = "`" .. oldJobId .. "`", ["inline"] = false},
                {["name"] = "📜 Script :", ["value"] = "`" .. teleportScript .. "`", ["inline"] = false},
                {["name"] = "🛡️ Hành động", ["value"] = "Hop Server Mới✅", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Current JobId: " .. game.JobId}
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

-- 3. HÀM NHẢY SERVER & LƯU TRỮ TẠM THỜI
local function ExecuteHop(reason, detail, isEmergency)
    local oldJobId = game.JobId
    
    -- Lưu thông tin báo cáo vào file tạm để server sau khi nhảy sẽ đọc và gửi
    writefile("XuanAn_PendingReport.json", HttpService:JSONEncode({
        ["Reason"] = reason,
        ["Detail"] = detail,
        ["OldJobId"] = oldJobId,
        ["IsEmergency"] = isEmergency
    }))
    
    task.wait(0.5)
    -- Thực hiện nhảy server
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

-- 4. KIỂM TRA BÁO CÁO TỒN ĐỌNG KHI VỪA VÀO SERVER
task.spawn(function()
    if isfile("XuanAn_PendingReport.json") then
        local success, reportData = pcall(function() 
            return HttpService:JSONDecode(readfile("XuanAn_PendingReport.json")) 
        end)
        if success and reportData then
            -- Gửi báo cáo từ server mới về server cũ vừa rời đi
            SendVipReport(reportData.Reason, reportData.Detail, reportData.OldJobId, reportData.IsEmergency)
            delfile("XuanAn_PendingReport.json") -- Xóa file sau khi báo cáo xong
        end
    end
end)

-- 5. HỆ THỐNG GIÁM SÁT (Admin & Chat)
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function Monitor(player)
    if player == Players.LocalPlayer then return end

    -- Phát Hiện Player Nhạy Cảm
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Phát Hiện Player Nhạy Cảm", "Đối tượng: " .. player.Name, true)
            return
        end
    end

    -- Có Lệnh Nhạy Cảm
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(m, pfx .. word) then
                    ExecuteHop("Có Lệnh Nhạy Cảm", "Đối tượng " .. player.Name .. " chat: " .. msg, true)
                    return
                end
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

-- Tự động Hop sau 1 giờ
task.spawn(function()
    while task.wait(3600) do
        if Config and Config["sau 1h có hop server không?"] then
            ExecuteHop("Đã Hop Server Sau 1h hoạt động", "Hệ thống tự động làm mới server.", false)
            break
        end
    end
end)
