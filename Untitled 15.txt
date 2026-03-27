local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local request = request or http_request or syn.request

local HopCount = 0
local Today = os.date("%d/%m/%Y")

if pcall(function() return readfile("hop.txt") end) then
    local data = HttpService:JSONDecode(readfile("hop.txt"))
    if data.date == Today then
        HopCount = data.hop or 0
    else
        HopCount = 0
    end
end

local function SendReport(reason, detail)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    if not request then return end

    local data = {
        ["embeds"] = {{
            ["title"] = "📊 BÁO CÁO HOP SERVER",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "📈 Số lần nhảy", ["value"] = tostring(HopCount)},
                {["name"] = "⏰ Thời gian", ["value"] = os.date("%H:%M:%S - %d/%m/%Y")},
                {["name"] = "⚠️ Lý do", ["value"] = reason},
                {["name"] = "🔍 Chi tiết", ["value"] = detail},
                {["name"] = "🌍 Server", ["value"] = game.JobId}
            }
        }}
    }

    pcall(function()
        request({
            Url = Config.Webhook.Url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function ExecuteHop(reason, detail)
    HopCount = HopCount + 1

    writefile("hop.txt", HttpService:JSONEncode({
        hop = HopCount,
        date = os.date("%d/%m/%Y")
    }))

    SendReport(reason, detail)

    task.wait(1.5)

    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}

local function Monitor(player)
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("🚨 CẢNH BÁO KHẨN CẤP", "Admin: " .. player.Name)
            return
        end
    end
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

task.spawn(function()
    while true do
        task.wait(3600)
        if Config and Config["sau 1h có hop server không?"] == true then
            ExecuteHop("🔄 BẢO TRÌ ĐỊNH KỲ", "Auto hop sau 1 giờ")
        end
    end
end)
