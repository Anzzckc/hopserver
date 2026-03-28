-- [[ MAIN LOGIC V6.1 - IMPROVED ]]
local Config = _G.XuanAn
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ================================
-- QUẢN LÝ HOP COUNT & RESET
-- ================================
local function ResetHopFile()
    local fileName = LocalPlayer.Name .. ".json"
    writefile(fileName, HttpService:JSONEncode({["LastTime"] = os.time(), ["Count"] = 0}))
    StarterGui:SetCore("SendNotification", {
        Title = "System",
        Text = "Hop Count Reset Successfully!",
        Duration = 5
    })
end

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

-- ================================
-- WEBHOOK BÁO CÁO (có MaxPlayers động)
-- ================================
local function SendVipReport(action, reason, detail, jobId, isEmergency)
    if not Config or not Config.Webhook.Enable or Config.Webhook.Url == "" then return end
    local totalHops = ManageHopCount(false)
    local timestamp = os.date("%H:%M:%S - %m/%d/%Y")
    local color = isEmergency and 16711680 or 65280
    local playerCount = #Players:GetPlayers()
    local maxPlayers = game.Players.MaxPlayers  -- Lấy giới hạn thực tế của server
    local teleportScript = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'..jobId..'")'

    local data = {
        ["embeds"] = {{
            ["title"] = "Notification 🔔",
            ["description"] = "Action: **" .. action .. "**",
            ["color"] = color,
            ["fields"] = {
                {["name"] = "📈 Hop Count",    ["value"] = "`" .. tostring(totalHops) .. "`",    ["inline"] = false},
                {["name"] = "⏰ Timestamp",    ["value"] = "`" .. timestamp .. "`",             ["inline"] = false},
                {["name"] = "⚠️ Reason",       ["value"] = "`" .. reason .. "`",                ["inline"] = false},
                {["name"] = "🔍 Detail",       ["value"] = "`" .. detail .. "`",                ["inline"] = false},
                {["name"] = "📊 Players :",    ["value"] = "`" .. playerCount .. "/" .. maxPlayers .. "`", ["inline"] = false},
                {["name"] = "🆔 Place-Id :",   ["value"] = "`" .. game.PlaceId .. "`",          ["inline"] = false},
                {["name"] = "🆔 Job-Id (Current) :", ["value"] = "`" .. jobId .. "`",           ["inline"] = false},
                {["name"] = "📜 Script :",     ["value"] = "`" .. teleportScript .. "`",        ["inline"] = false}
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

-- ================================
-- HOP VỚI CỜ CHỐNG TRÙNG + DEBOUNCE
-- ================================
local isHopping = false          -- Ngăn hop chồng
local hopDebounce = false        -- Trạng thái debounce
local pendingHop = nil           -- Lưu thông tin hop cuối cùng trong debounce

local function ExecuteHop(reason, detail, isEmergency)
    if isHopping then return end
    isHopping = true
    
    ManageHopCount(true)
    SendVipReport("Hopping to New Server...", reason, detail, game.JobId, isEmergency)
    task.wait(1.5)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Anzzckc/get-hopsv/refs/heads/main/runhopsv.lua"))()
    end)
end

local function DebouncedHop(reason, detail, isEmergency)
    if hopDebounce then
        -- Đang trong thời gian debounce, cập nhật thông tin hop mới nhất
        pendingHop = {reason = reason, detail = detail, isEmergency = isEmergency}
        return
    end
    
    hopDebounce = true
    task.wait(3)   -- Gom tất cả sự kiện trong 3 giây
    
    if pendingHop then
        ExecuteHop(pendingHop.reason, pendingHop.detail, pendingHop.isEmergency)
        pendingHop = nil
    else
        ExecuteHop(reason, detail, isEmergency)
    end
    
    hopDebounce = false
end

-- ================================
-- GIÁM SÁT ADMIN & CHAT NHẠY CẢM (cải tiến bắt lệnh)
-- ================================
local AdminList = {"rip_indra", "mygame43", "Uzoth", "Zioles", "ShafiDev", "Suizei", "starcode_kitt"}
local DangerWords = {"kick", "ban", "kill", "tp", "bring", "freeze", "jail", "profile", "conf"}
local Prefixes = {":", ";", "/", ".", "?", "!", "-"}

local function Monitor(player)
    if player == LocalPlayer then return end
    
    -- Kiểm tra admin
    for _, adminName in pairs(AdminList) do
        if player.Name == adminName then
            DebouncedHop("Admin Detected", "Target: " .. player.Name, true)
            return
        end
    end
    
    -- Kiểm tra chat nguy hiểm (chỉ bắt lệnh ở đầu dòng)
    player.Chatted:Connect(function(msg)
        local m = string.lower(msg)
        for _, pfx in pairs(Prefixes) do
            for _, word in pairs(DangerWords) do
                if string.find(m, "^" .. pfx .. word) then   -- Thêm ^ để bắt đầu dòng
                    DebouncedHop("Dangerous Command", "Player " .. player.Name .. " chat: " .. msg, true)
                    return
                end
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do Monitor(p) end
Players.PlayerAdded:Connect(Monitor)

-- ================================
-- PING 5 PHÚT (HEARTBEAT)
-- ================================
task.spawn(function()
    while true do
        task.wait(300)
        if Config["Enable 5-Min Ping"] then
            SendVipReport("Monitoring Server Status...", "Periodic Status Ping", "Account is still active.", game.JobId, false)
        end
    end
end)

-- ================================
-- AUTO RECONNECT (RỚT MẠNG)
-- ================================
GuiService.ErrorMessageChanged:Connect(function()
    local errorCode = GuiService:GetErrorCode()
    local NetworkErrors = {[277] = true, [279] = true, [280] = true}
    if NetworkErrors[errorCode] then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- ================================
-- CONTROL PANEL (RESET HOP COUNT)
-- ================================
task.spawn(function()
    local bindable = Instance.new("BindableFunction")
    bindable.OnInvoke = function(button)
        if button == "Reset Now" then
            ResetHopFile()
        end
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Control Panel",
            Text = "Do You Want To Reset Hop Count?",
            Duration = 20,
            Button1 = "Reset Now",
            Button2 = "Keep It",
            Callback = bindable,
            Icon = "rbxassetid://3129596397"
        })
    end)
end)

-- ================================
-- AUTO HOP THEO GIỜ
-- ================================
task.spawn(function()
    if Config["Automatically Hop When The Time Comes"] then
        task.wait(Config.HopIntervalHours * 3600)
        DebouncedHop("Scheduled Auto Hop", "Refreshing server after " .. Config.HopIntervalHours .. "h.", false)
    end
end)
