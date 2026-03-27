local Config = _G.XuanAn
local HopCount = 0
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local HarmlessEmotes = {"/e dance", "/e dance2", "/e dance3", "/e wave", "/e cheer", "/e laugh", "/e point"}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local function SendReport(reason, detail)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    local data = {
        ["embeds"] = {{
            ["title"] = "🛡️ HỆ THỐNG PHÒNG THỦ [XuanAn]",
            ["description"] = "Phát hiện nguy hiểm hoặc đến giờ tuần tra.",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "📈 Lần nhảy thứ", ["value"] = tostring(HopCount), ["inline"] = true},
                {["name"] = "⏰ Thời gian", ["value"] = os.date("%H:%M:%S"), ["inline"] = true},
                {["name"] = "⚠️ Lý do", ["value"] = reason, ["inline"] = false},
                {["name"] = "🔍 Chi tiết", ["value"] = detail, ["inline"] = false}
            }
        }}
    }
    pcall(function()
        HttpService:PostAsync(Config.Webhook.Url, HttpService:JSONEncode(data))
    end)
end

local function ExecuteHop(reason, detail)
    HopCount = HopCount + 1
    SendReport(reason, detail)
    task.wait(1)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local function Monitor(player)
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Phát hiện Admin gia nhập", "Tên đối tượng: " .. player.Name)
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
                    ExecuteHop("Phát hiện lệnh điều khiển Admin", "Nội dung chat: " .. msg)
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
        if Config and Config["sau 1h có hop server không?"] == true then
            ExecuteHop("Tuần tra định kỳ", "Tự động đổi Server sau 1 giờ hoạt động.")
        end
    end
end)
