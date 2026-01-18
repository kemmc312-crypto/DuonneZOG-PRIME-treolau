--[[ 
    DUONNEZOG V30 - FINAL VERSION
    - THỜI GIAN: Tích lũy (Chỉ chạy khi có script).
    - RESET: 00:00 VN (Tất cả về 0).
    - SERVER HOP: 25s liên tục, chặn server cũ 5 phút.
    - AUTO: Chest, Marines Team, Anti-Lag, Anti-AFK.
]]

repeat task.wait() until game:IsLoaded()
if _G.DuonneZOG_V30_Loaded then return end
_G.DuonneZOG_V30_Loaded = true

local lp = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StatsFile = "DuonneZOG_V30_Final.json"

--// [1. HÀM NGÀY GIỜ VN]
local function GetVNDate()
    -- Lấy ngày theo múi giờ GMT+7
    return os.date("!%d/%m/%Y", tick() + 25200)
end

--// [2. QUẢN LÝ DỮ LIỆU TÍCH LŨY]
local function SaveData(data)
    pcall(function() writefile(StatsFile, HttpService:JSONEncode(data)) end)
end

local function LoadData()
    local today = GetVNDate()
    local default = {
        LastDate = today,
        Seconds = 0, -- Thời gian tích lũy (không phải real-time)
        Money = 0,
        Cup = 0,
        Key = 0,
        Blacklist = {}
    }
    
    if isfile(StatsFile) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(StatsFile)) end)
        if success and result then
            -- Nếu đúng ngày hôm nay: Lấy dữ liệu cũ để chạy tiếp
            if result.LastDate == today then
                -- Lọc Blacklist 5 phút
                local cleanBL = {}
                for id, t in pairs(result.Blacklist or {}) do
                    if tick() - t < 300 then cleanBL[id] = t end
                end
                result.Blacklist = cleanBL
                return result
            end
        end
    end
    -- Nếu sang ngày mới hoặc chưa có file: Trả về 0 hết (Reset)
    return default
end

local Data = LoadData()
Data.Blacklist[game.JobId] = tick() -- Chặn server hiện tại
SaveData(Data)

--// [3. GIAO DIỆN UI]
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "DuonneZOG_V30_Final"

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 260, 0, 200)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 255, 150)
stroke.Thickness = 2

local function CreateLabel(txt, pos, color)
    local l = Instance.new("TextLabel", Main)
    l.Size = UDim2.new(1, -20, 0, 22)
    l.Position = pos + UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12; l.Text = txt
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local title = CreateLabel("DUONNEZOG V30 - FINAL", UDim2.new(0,0,0,10), Color3.fromRGB(0, 255, 150))
local moneyTxt = CreateLabel("Beli Earned: 0", UDim2.new(0,0,0,35))
local timeTxt = CreateLabel("Script Run Time: 00:00:00", UDim2.new(0,0,0,57))
local cupTxt = CreateLabel("Cup Nhặt Được: 0", UDim2.new(0,0,0,79), Color3.fromRGB(255, 255, 100))
local keyTxt = CreateLabel("Key Nhặt Được: 0", UDim2.new(0,0,0,101), Color3.fromRGB(255, 100, 255))
local blTxt = CreateLabel("Blacklisted (5m): 0", UDim2.new(0,0,0,123), Color3.fromRGB(255, 100, 100))
local hopTxt = CreateLabel("Hop in: 25s", UDim2.new(0,0,0,145), Color3.fromRGB(0, 200, 255))

--// [4. THEO DÕI ITEM]
local function Monitor(obj)
    if obj.Name == "God's Chalice" then 
        Data.Cup = Data.Cup + 1 
        SaveData(Data)
    elseif obj.Name == "Fist of Darkness" then 
        Data.Key = Data.Key + 1 
        SaveData(Data) 
    end
end
lp.Backpack.ChildAdded:Connect(Monitor)
if lp.Character then lp.Character.ChildAdded:Connect(Monitor) end

--// [5. INFINITE HOP]
local function Hop()
    getgenv().IsHopping = true
    while true do
        pcall(function()
            local list = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
            for _, s in ipairs(list) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId and not Data.Blacklist[s.id] and s.playing <= 8 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
                    task.wait(3)
                end
            end
        end)
        task.wait(1)
    end
end

--// [6. VÒNG LẶP CHÍNH (UPDATE STATS)]
task.spawn(function()
    local lastBeli = lp.Data.Beli.Value
    while task.wait(1) do
        pcall(function()
            -- Auto Team Marines
            if not lp.Team or lp.Team.Name == "Neutral" then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end
            
            -- Đếm thời gian tích lũy
            Data.Seconds = Data.Seconds + 1
            
            -- Đếm tiền
            local curBeli = lp.Data.Beli.Value
            if curBeli > lastBeli then 
                Data.Money = Data.Money + (curBeli - lastBeli) 
            end
            lastBeli = curBeli
            
            -- Hiển thị UI
            moneyTxt.Text = "Beli Earned: " .. math.floor(Data.Money/1000) .. "k"
            local h, m, s = math.floor(Data.Seconds/3600), math.floor((Data.Seconds%3600)/60), math.floor(Data.Seconds%60)
            timeTxt.Text = string.format("Script Run Time: %02d:%02d:%02d", h, m, s)
            
            cupTxt.Text = "Cup Nhặt Được: " .. Data.Cup
            keyTxt.Text = "Key Nhặt Được: " .. Data.Key
            local bc = 0; for _ in pairs(Data.Blacklist) do bc = bc + 1 end
            blTxt.Text = "Blacklisted (5m): " .. bc
            
            SaveData(Data) -- Lưu vào file mỗi giây
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
                    firetouchinterest(hrp, chest, 0); task.wait(0.1); firetouchinterest(hrp, chest, 1)
                end
            end)
        end
    end
end)

--// [8. TIMER 25S ĐỂ NHẢY SERVER]
task.spawn(function()
    local t = 25
    while task.wait(1) do
        if not getgenv().IsHopping then
            t = t - 1
            hopTxt.Text = "Hop in: " .. t .. "s"
            if t <= 0 then Hop() end
        end
    end
end)

-- TỐI ƯU HÓA: Tắt Render giảm CPU/RAM, Chống AFK
game:GetService("RunService"):Set3dRenderingEnabled(false)
for _, v in pairs(getconnections(lp.Idled)) do v:Disable() end
