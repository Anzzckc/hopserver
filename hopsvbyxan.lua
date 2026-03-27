-- Main Logic Script (Optimized for Mobile Executor)
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function SendReport(reason, detail)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🛡️ HỆ THỐNG PHÒNG THỦ [XuanAn]",
            ["description"] = "Đã thực hiện nhảy Server để bảo vệ tài khoản.",
            ["color"] = 16711680, -- Màu đỏ
            ["fields"] = {
                {["name"] = "⏰ Thời gian", ["value"] = os.date("%H:%M:%S"), ["inline"] = true},
                {["name"] = "🆔 Server JobId", ["value"] = "```" .. game.JobId .. "```", ["inline"] = false},
                {["name"] = "⚠️ Lý do", ["value"] = "**" .. reason .. "**", ["inline"] = true},
                {["name"] = "🔍 Chi tiết", ["value"] = detail, ["inline"] = false}
            },
            ["footer"] = {["text"] = "Delta Mobile Executor • " .. os.date("%d/%m/%Y")}
        }}
    }

    -- Sử dụng hàm request() thay thế cho HttpService:PostAsync()
    local success, res = pcall(function()
        return request({
            Url = Config.Webhook.Url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if not success then
        warn("Lỗi gửi Webhook: " .. tostring(res))
    end
end

local function ExecuteHop(reason, detail)
    SendReport(reason, detail)
    task.wait(1.5) -- Chờ gửi webhook xong
    pcall(function()
        -- Gọi script nhảy server của bạn
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local function Monitor(player)
    -- 1. Check Admin gia nhập
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Phát hiện Admin gia nhập", "Tên đối tượng: " .. player.Name)
            return
        end
    end

    -- 2. Check Chat (Danger Words)
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(m, pfx .. word) then
                    ExecuteHop("Phát hiện lệnh nguy hiểm", "Admin " .. player.Name .. " chat: " .. msg)
                    return
                end
            end
        end
    end)
end

-- Khởi chạy vòng lặp kiểm tra
for _, p in pairs(Players:GetPlayers()) do
    if p ~= Players.LocalPlayer then Monitor(p) end
end
Players.PlayerAdded:Connect(Monitor)

-- Tự động Hop sau 1 giờ (3600 giây)
task.spawn(function()
    while task.wait(3600) do
        if Config and Config["sau 1h có hop server không?"] then
            ExecuteHop("Tuần tra định kỳ", "Tự động đổi Server sau 1 giờ hoạt động.")
            break
        end
    end
end)
