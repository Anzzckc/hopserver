local Config = _G.XuanAn
local HopCount = 0
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local HarmlessEmotes = {"/e dance", "/e dance2", "/e dance3", "/e wave", "/e cheer", "/e laugh", "/e point"}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local function SendReport(reason, detail)
    -- Kiểm tra cấu hình có đúng không
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" or Config.Webhook.Url == "THÊM_WEBHOOK_CỦA_MÀY_VÀO_ĐÂY" then return end
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🛡️ HỆ THỐNG PHÒNG THỦ [XuanAn]",
            ["description"] = "Phát hiện nguy hiểm, đang di tản.",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "📈 Lần nhảy", ["value"] = tostring(HopCount), ["inline"] = true},
                {["name"] = "⏰ Giờ", ["value"] = os.date("%H:%M:%S"), ["inline"] = true},
                {["name"] = "⚠️ Lý do", ["value"] = reason, ["inline"] = false},
                {["name"] = "🔍 Chi tiết", ["value"] = detail, ["inline"] = false}
            }
        }}
    }

    -- Cố gắng gửi sớ về Discord, nhưng không chặn luồng code chính
    task.spawn(function()
        pcall(function()
            HttpService:PostAsync(Config.Webhook.Url, HttpService:JSONEncode(data))
        end)
    end)
end

-- HÀM SỬA LỖI TRÌNH TỰ
local function ExecuteHop(reason, detail)
    HopCount = HopCount + 1
    
    -- Lệnh 1: Gửi Webhook ngay lập tức (Xử lý bất đồng bộ)
    SendReport(reason, detail)
    
    -- Lệnh 2: Đợi hẳn 2 giây cho Webhook chắc chắn bay đi
    task.wait(2)
    
    -- Lệnh 3: Nhảy Server
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local function Monitor(player)
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Admin gia nhập", "Đố tượng: " .. player.Name)
            return
        end
    end
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, emote in pairs(HarmlessEmotes) do if m == emote then return end end
        local cleanMsg = m
        if string.sub(m, 1, 3) == "/e " then cleanMsg = string.sub(m, 4) end
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(cleanMsg, pfx .. word) then
                    ExecuteHop("Lệnh Admin nguy hiểm", "Nội dung: " .. msg)
                    return
                end
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

task.spawn(function()
    while true do
        task.wait(3600)
        ExecuteHop("Tuần tra định kỳ", "Đổi Server bảo mật.")
    end
end)
