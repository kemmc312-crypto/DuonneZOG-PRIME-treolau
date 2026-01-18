--[[ 
    DUONNEZOG V18 - GMT+7 AUTO RESET & PERSISTENT STATS
    - Tự động lưu tiền/thời gian vào file, không reset khi đổi server.
    - Tự động reset stats khi sang ngày mới (00:00 sáng theo giờ VN).
    - Ưu tiên Diamond Chest > Nearby.
    - Auto chọn phe Marines.
]]

repeat task.wait() until game:IsLoaded()
if _G.DuonneZOG_V18_Loaded then return end
_G.DuonneZOG_V18_Loaded = true

--// [1. KHỞI TẠO BIẾN CƠ SỞ]
local lp = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local StatsFile = "DuonneZOG_DailyStats.json"

-- Hàm lấy ngày hiện tại theo múi giờ Việt Nam (UTC+7)
local function GetVNFirstDay()
    -- UTC+7 = 25200 giây
    return os.date("!%d/%m/%Y", tick() + 25200)
end

--// [2. QUẢN LÝ DỮ LIỆU LƯU TRỮ]
local function SaveData(data)
    pcall(function() writefile(StatsFile, HttpService:JSONEncode(data)) end)
end

local function LoadData()
    local default = {
        LastDate = GetVNFirstDay(),
        TotalMoney = 0,
        TotalSeconds = 0,
        LastCheckTime = tick()
    }
    
    if isfile(StatsFile) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(StatsFile)) end)
        if success then
            -- Kiểm tra nếu qua ngày mới thì reset
            if result.LastDate ~= GetVNFirstDay() then
                return default
            end
            return result
        end
    end
    return default
end

local CurrentStats = LoadData()
local LastBeli = 0
pcall(function() LastBeli = lp.Data.Beli.Value end)

--// [3. GIAO DIỆN UI]
local sg = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 260, 0, 150)
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
    l.TextSize = 13
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local title = CreateLabel("DUONNEZOG V18 (GMT+7)", UDim2.new(0,0,0,10), Color3.fromRGB(0, 255, 150))
local moneyTxt = CreateLabel("Daily Earned: 0 Beli", UDim2.new(0,0,0,40))
local timeTxt = CreateLabel("Daily Time: 00:00:00", UDim2.new(0,0,0,65))
local dateTxt = CreateLabel("Date: " .. CurrentStats.LastDate, UDim2.new(0,0,0,90), Color3.fromRGB(150, 150, 150))
local statusTxt = CreateLabel("Status: Running...", UDim2.new(0,0,0,115), Color3.new(1, 1, 0))

--// [4. VÒNG LẶP CẬP NHẬT STATS & AUTO CHỌN PHE]
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            -- Auto Team Marines
            if lp.Team == nil or lp.Team.Name == "Neutral" then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end

            -- Tính tiền
            local currentBeli = lp.Data.Beli.Value
            if currentBeli > LastBeli and LastBeli ~= 0 then
                CurrentStats.TotalMoney = CurrentStats.TotalMoney + (currentBeli - LastBeli)
            end
            LastBeli = currentBeli

            -- Tính thời gian (cộng dồn)
            local now = tick()
            CurrentStats.TotalSeconds = CurrentStats.TotalSeconds + (now - CurrentStats.LastCheckTime)
            CurrentStats.LastCheckTime = now

            -- Hiển thị UI
            moneyTxt.Text = "Daily Earned: " .. math.floor(CurrentStats.TotalMoney/1000) .. "k Beli"
            local hours = math.floor(CurrentStats.TotalSeconds / 3600)
            local mins = math.floor((CurrentStats.TotalSeconds % 3600) / 60)
            local secs = math.floor(CurrentStats.TotalSeconds % 60)
            timeTxt.Text = string.format("Daily Time: %02d:%02d:%02d", hours, mins, secs)

            -- Lưu dữ liệu vào file
            SaveData(CurrentStats)
        end)
    end
end)

--// [5. LOGIC NHẶT RƯƠNG]
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local hrp = lp.Character.HumanoidRootPart
            local chests = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name:find("Chest") and v:FindFirstChild("TouchInterest") then 
                    table.insert(chests, v) 
                end
            end

            table.sort(chests, function(a, b)
                local aD = a.Name:lower():find("diamond")
                local bD = b.Name:lower():find("diamond")
                if aD and not bD then return true elseif not aD and bD then return false end
                return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
            end)

            for _, chest in ipairs(chests) do
                hrp.CFrame = chest.CFrame
                firetouchinterest(hrp, chest, 0)
                task.wait(0.15)
                firetouchinterest(hrp, chest, 1)
            end
        end)
    end
end)

--// [6. SERVER HOP & FIX LAG]
task.spawn(function()
    task.wait(25) -- Sau 25 giây nhặt sạch rương thì nhảy server
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in ipairs(servers) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId and s.playing <= 8 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, lp)
            break
        end
    end
end)

-- Anti-Lag: Tắt render 3D (Nếu muốn xem game thì đổi thành true)
game:GetService("RunService"):Set3dRenderingEnabled(false)
for _, v in pairs(getconnections(lp.Idled)) do v:Disable() end
