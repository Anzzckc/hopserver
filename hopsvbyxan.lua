-- Thiết lập cấu hình
local Config = _G.XuanAn or {
    Webhook = {
        Enable = true,
        Url = "YOUR_WEBHOOK_HERE" -- Thay URL Webhook của bạn vào đây
    },
    ["sau 1h có hop server không?"] = true
}

local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- Hàm gửi Webhook sử dụng request() thay vì PostAsync
local function SendReport(reason, adminName)
    if not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🛡️ HỆ THỐNG PHÒNG THỦ [XuanAn]",
            ["description"] = "Đã thực hiện nhảy server để bảo vệ tài khoản.",
            ["color"] = 16711680, -- Màu đỏ
            ["fields"] = {
                {["name"] = "⚠️ Lý do", ["value"] = reason, ["inline"] = false},
                {["name"] = "🔍 Tên Admin", ["value"] = adminName or "N/A", ["inline"] = true},
                {["name"] = "⏰ Thời gian", ["value"] = os.date("%H:%M:%S"), ["inline"] = true},
                {["name"] = "🆔 JobId", ["value"] = "```" .. game.JobId .. "```", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Delta Mobile Executor"}
        }}
    }

    -- Sử dụng request() theo yêu cầu
    local success, res = pcall(function()
        return request({
            Url = Config.Webhook.Url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    return success
end

-- Hàm thực hiện Hop Server
local function ExecuteHop(reason, adminName)
    print("🚀 Đang thực hiện Hop Server: " .. reason)
    SendReport(reason, adminName)
    
    task.wait(1.5) -- Chờ một chút để Webhook kịp gửi đi
    
    -- Ưu tiên chạy script hop của bạn, nếu lỗi sẽ dùng Teleport mặc định
    local hopSuccess = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
    
    if not hopSuccess then
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end
end

-- Kiểm tra Admin
local function CheckAdmin(player)
    for _, admin in pairs(AdminList) do
        if player.Name == admin then
            ExecuteHop("Phát hiện Admin gia nhập", player.Name)
            return true
        end
    end
    return false
end

-- Theo dõi người chơi mới
Players.PlayerAdded:Connect(function(player)
    CheckAdmin(player)
end)

-- Kiểm tra những người đã có sẵn trong server
for _, p in pairs(Players:GetPlayers()) do
    if CheckAdmin(p) then break end
end

-- Tự động Hop sau 1 giờ (Tuần tra định kỳ)
task.spawn(function()
    while true do
        task.wait(3600)
        if Config["sau 1h có hop server không?"] then
            ExecuteHop("Tuần tra định kỳ (1 giờ)", "N/A")
        end
    end
end)

print("✅ [XuanAn] Hệ thống bảo vệ đã kích hoạt!")
