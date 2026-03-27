-- [2026-03-27] Logic Version 2.1 - Smart Session & Hop Limit
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- 1. XỬ LÝ BỘ ĐẾM & GIỚI HẠN 3 TIẾNG
local function ManageHopCount()
    local currentTime = os.time()
    local lastUpdate = 0
    local count = 0
    
    -- Đọc dữ liệu cũ
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

    -- Cập nhật dữ liệu mới
    count = count + 1
    writefile("XuanAn_Session.json", HttpService:JSONEncode({
        ["LastTime"] = currentTime,
        ["Count"] = count
    }))
    
    return count
end

-- DANH SÁCH ADMIN & LỆNH BẪY
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

-- 2. HÀM GỬI WEBHOOK DÙNG REQUEST()
local function SendReport(reasonType, detail, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local totalHops = ManageHopCount()
    local timestamp = os.date("%H:%M:%S - Ngày %d Tháng %m Năm 2026")
    local title = isEmergency and "🚨 CẢNH BÁO KHẨN CẤP" or "📊 BÁO CÁO HỆ THỐNG AFK"
    local embedColor = isEmergency and 16711680 or 65280

    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["color"] = embedColor,
            ["fields"] = {
                {["name"] = "📈 Số lần nhảy", ["value"] = "**" .. tostring(totalHops) .. "**", ["inline"] = false},
                {["name"] = "⏰ Thời gian", ["value"] = timestamp, ["inline"] = false},
                {["name"] = "⚠️ Lý do", ["value"] = reasonType, ["inline"] = false},
                {["name"] = "🔍 Chi tiết", ["value"] = detail, ["inline"] = false},
                {["name"] = "🛡️ Hành động", ["value"] = "Đã nhảy sang server mới an toàn.", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Server JobId: " .. game.JobId}
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

-- 3. HÀM NHẢY SERVER
local function ExecuteHop(reasonType, detail, isEmergency)
    SendReport(reasonType, detail, isEmergency)
    task.wait(2)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

-- 4. GIÁM SÁT ADMIN VÀ CHAT
local function Monitor(player)
    if player == Players.LocalPlayer then return end
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Phát hiện Admin " .. player.Name .. " vừa vào server.", "Tên đối tượng: " .. player.Name, true)
            return
        end
    end
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(m, pfx .. word) then
                    ExecuteHop("Phát hiện lệnh điều khiển nguy hiểm.", "Đối tượng " .. player.Name .. " chat: " .. msg, true)
                    return
                end
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

-- 5. VÒNG LẶP TUẦN TRA 1 GIỜ
task.spawn(function()
    while task.wait(3600) do
        if Config and Config["sau 1h có hop server không?"] then
            ExecuteHop("Bảo trì định kỳ", "Tự động đổi server sau 1 giờ hoạt động.", false)
            break
        end
    end
end)
