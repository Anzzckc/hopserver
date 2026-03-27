local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function ResetHopFile()
    local fileName = LocalPlayer.Name .. ".json"
    writefile(fileName, HttpService:JSONEncode({["LastTime"] = os.time(), ["Count"] = 0}))
    StarterGui:SetCore("SendNotification", {
        Title = "System",
        Text = "Hop Count Reset Successfully!",
        Duration = 5
    })
end

local function ManageHopCount()
    local currentTime = os.time()
    local fileName = LocalPlayer.Name .. ".json"
    local lastUpdate, count = 0, 0
    if isfile(fileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success then lastUpdate, count = data.LastTime or 0, data.Count or 0 end
    end
    if (currentTime - lastUpdate) > 10800 then count = 0 end
    count = count + 1
    writefile(fileName, HttpService:JSONEncode({["LastTime"] = currentTime, ["Count"] = count}))
    return count
end

local function SendVipReport(reason, detail, oldJobId, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    local totalHops = ManageHopCount()
    local timestamp = os.date("%H:%M:%S - %m/%d/2026")
    local color = isEmergency and 16711680 or 65280
    local playerCount = #Players:GetPlayers()
    local teleportScript = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'..oldJobId..'")'
    local data = {
        ["embeds"] = {{
            ["title"] = "Notification 🔔",
            ["description"] = "Action: **Hopping to New Server...**",
            ["color"] = color,
            ["fields"] = {
                {["name"] = "📈 Hop Count", ["value"] = "**" .. tostring(totalHops) .. "**", ["inline"] = true},
                {["name"] = "⏰ Timestamp", ["value"] = timestamp, ["inline"] = true},
                {["name"] = "⚠️ Reason", ["value"] = reason, ["inline"] = false},
                {["name"] = "🔍 Detail", ["value"] = detail, ["inline"] = false},
                {["name"] = "📊 Players :", ["value"] = "`" .. playerCount .. "/12`", ["inline"] = true},
                {["name"] = "🆔 Place-Id :", ["value"] = "`" .. game.PlaceId .. "`", ["inline"] = true},
                {["name"] = "🆔 Job-Id (Current) :", ["value"] = "`" .. oldJobId .. "`", ["inline"] = false},
                {["name"] = "📜 Script :", ["value"] = "`" .. teleportScript .. "`", ["inline"] = false}
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

local function ExecuteHop(reason, detail, isEmergency)
    SendVipReport(reason, detail, game.JobId, isEmergency)
    task.wait(1.5)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function Monitor(player)
    if player == LocalPlayer then return end
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            ExecuteHop("Admin Detected", "Target: " .. player.Name, true)
            return
        end
    end
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

task.spawn(function()
    local bindable = Instance.new("BindableFunction")
    function bindable.OnInvoke(button)
        if button == "Reset Now" then
            ResetHopFile()
        end
    end

    local success = false
    while not success do
        success = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Control Panel",
                Text = "(Do You Want To Reset Hop Count?)",
                Duration = 20,
                Button1 = "Reset Now",
                Button2 = "Keep It",
                Callback = bindable,
                Icon = "rbxassetid://3129596397"
            })
        end)
        task.wait(1)
    end

    if Config and Config["Automatically Hop When The Time Comes"] == true then
        local hours = Config["HopIntervalHours"] or 1
        task.wait(hours * 3600)
        if Config["Automatically Hop When The Time Comes"] == true then
            ExecuteHop("Scheduled Auto Hop", "Server refreshed after " .. tostring(hours) .. " hour(s).", false)
        end
    end
end)
