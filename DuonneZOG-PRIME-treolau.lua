--[[ 
    DUONNEZOG V21 - FAST BLACKLIST EDITION (5 MINS)
    - UPDATED: Blacklist server giảm xuống còn 5 phút (300 giây).
    - FEATURE: Infinite Hop + GMT+7 Daily Stats.
    - AUTO EXEC: Bỏ vào thư mục autoexec của Velocity.
]]

repeat task.wait() until game:IsLoaded()
if _G.DuonneZOG_V21_Loaded then return end
_G.DuonneZOG_V21_Loaded = true

--// [1. KHỞI TẠO BIẾN]
local lp = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StatsFile = "DuonneZOG_DailyStats.json"
local BlacklistFile = "DuonneZOG_Blacklist.json"

--// [2. QUẢN LÝ BLACKLIST (5 PHÚT)]
local function LoadBlacklist()
    if isfile(BlacklistFile) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(BlacklistFile)) end)
        if success then 
            local current = {}
            local now = tick()
            -- Lọc bỏ những server đã quá 5 phút (300 giây)
            for id, t in pairs(result) do
                if now - t < 300 then current[id] = t end
            end
            return current
        end
    end
    return {}
end

local function SaveBlacklist(list)
    pcall(function() writefile(BlacklistFile, HttpService:JSONEncode(list)) end)
end

local Blacklist = LoadBlacklist()
Blacklist[game.JobId] = tick()
SaveBlacklist(Blacklist)

--// [3. QUẢN LÝ DỮ LIỆU GMT+7]
local function GetVNFirstDay() return os.date("!%d/%m/%Y", tick() + 25200) end
local function SaveData(data) pcall(function() writefile(StatsFile, HttpService:JSONEncode(data)) end) end
local function LoadData()
    local default = {LastDate = GetVNFirstDay(), TotalMoney = 0, TotalSeconds = 0, LastCheckTime = tick()}
    if isfile(StatsFile) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(StatsFile)) end)
        if success and result.LastDate == GetVNFirstDay() then return result end
    end
    return default
end
local CurrentStats = LoadData()
local LastBeli = 0
pcall(function() LastBeli = lp.Data.Beli.Value end)

--// [4. GIAO DIỆN UI]
local sg = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 260, 0, 160)
Main.Position = UDim2.new(0, 15, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 255, 150)

local function CreateLabel(text, pos, color)
    local l = Instance.new("TextLabel", Main)
    l.Size = UDim2.new(1, -20, 0, 25)
    l.Position = pos + UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.TextSize = 12
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local title = CreateLabel("DUONNEZOG V21 (5m BLACKLIST)", UDim2.new(0,0,0,10), Color3.fromRGB(0, 255, 150))
local moneyTxt = CreateLabel("Daily Earned: 0 Beli", UDim2.new(0,0,0,35))
local timeTxt = CreateLabel("Daily Time: 00:00:00", UDim2.new(0,0,0,60))
local blacklistTxt = CreateLabel("Blacklisted (5m): 0", UDim2.new(0,0,0,85), Color3.fromRGB(255, 100, 100))
local hopTxt = CreateLabel("Hop in: 25s", UDim2.new(0,0,0,110), Color3.fromRGB(255, 200, 0))
local statusTxt = CreateLabel("Status: Running...", UDim2.new(0,0,0,135), Color3.new(1, 1, 0))

--// [5. HÀM INFINITE HOP]
local function GeminiHop()
    getgenv().IsHopping = true
    local function GetServers(cursor)
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end
        local s, r = pcall(function() return game:HttpGet(url) end)
        if s then return HttpService:JSONDecode(r) end
    end

    while true do
        local cursor = nil
        repeat
            local list = GetServers(cursor)
            if list and list.data then
                for _, s in ipairs(list.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId and not Blacklist[s.id] and s.playing <= 8 then
                        statusTxt.Text = "Status: Hopping to new server..."
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
                        task.wait(4)
                    end
                end
                cursor = list.nextPageCursor
            end
            task.wait(0.2)
        until not cursor
        statusTxt.Text = "Status: No new servers, retrying..."
        task.wait(1)
    end
end

--// [6. VÒNG LẶP CẬP NHẬT]
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if lp.Team == nil or lp.Team.Name == "Neutral" then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end
            local currentBeli = lp.Data.Beli.Value
            if currentBeli > LastBeli and LastBeli ~= 0 then CurrentStats.TotalMoney = CurrentStats.TotalMoney + (currentBeli - LastBeli) end
            LastBeli = currentBeli
            local now = tick()
            CurrentStats.TotalSeconds = CurrentStats.TotalSeconds + (now - CurrentStats.LastCheckTime)
            CurrentStats.LastCheckTime = now
            
            local bCount = 0
            for _ in pairs(Blacklist) do bCount = bCount + 1 end
            
            moneyTxt.Text = "Daily Earned: " .. math.floor(CurrentStats.TotalMoney/1000) .. "k Beli"
            blacklistTxt.Text = "Blacklisted (5m): " .. bCount
            local h, m, s = math.floor(CurrentStats.TotalSeconds/3600), math.floor((CurrentStats.TotalSeconds%3600)/60), math.floor(CurrentStats.TotalSeconds%60)
            timeTxt.Text = string.format("Daily Time: %02d:%02d:%02d", h, m, s)
            SaveData(CurrentStats)
        end)
    end
end)

--// [7. AUTO CHEST]
task.spawn(function()
    while task.wait(0.1) do
        if not getgenv().IsHopping then
            pcall(function()
                local hrp = lp.Character.HumanoidRootPart
                local chests = {}
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v.Name:find("Chest") and v:FindFirstChild("TouchInterest") then table.insert(chests, v) end
                end
                table.sort(chests, function(a, b)
                    local aD, bD = a.Name:lower():find("diamond"), b.Name:lower():find("diamond")
                    if aD and not bD then return true elseif not aD and bD then return false end
                    return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
                end)
                for _, chest in ipairs(chests) do
                    if getgenv().IsHopping then break end
                    hrp.CFrame = chest.CFrame
                    firetouchinterest(hrp, chest, 0)
                    task.wait(0.15)
                    firetouchinterest(hrp, chest, 1)
                end
            end)
        end
    end
end)

--// [8. ĐẾM NGƯỢC]
task.spawn(function()
    local timer = 25
    while task.wait(1) do
        if not getgenv().IsHopping then
            timer = timer - 1
            hopTxt.Text = "Hop in: " .. timer .. "s"
            if timer <= 0 then GeminiHop() end
        end
    end
end)

game:GetService("RunService"):Set3dRenderingEnabled(false)
for _, v in pairs(getconnections(lp.Idled)) do v:Disable() end
