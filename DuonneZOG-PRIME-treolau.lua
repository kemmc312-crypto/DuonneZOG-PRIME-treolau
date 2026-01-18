--[[ 
    DUONNEZOG V15 - ULTIMATE AUTO EXEC
    - ƯU TIÊN: DIAMOND > GẦN NHẤT
    - FIX LỖI NHẶT NHANH (DELAY 0.15S)
    - KHÔNG DỪNG KHI CÓ CHÉN THÁNH/FIST
    - ANTI-LAG & WHITE SCREEN
]]

if not game:IsLoaded() then game.Loaded:Wait() end
if _G.DuonneZOG_Loaded then return end
_G.DuonneZOG_Loaded = true

--// [1. KHỞI TẠO]
local lp = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local fileName = "DuonneZOG_Data.json"

--// [2. HỆ THỐNG LƯU TRỮ]
local function SaveStats(data)
    pcall(function() writefile(fileName, HttpService:JSONEncode(data)) end)
end

local function LoadStats()
    if isfile(fileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success then return result end
    end
    return nil
end

local SavedData = LoadStats()
local TotalMoneyEarned = SavedData and SavedData.Money or 0
local StartTime = SavedData and SavedData.StartTime or tick()
local LastBeli = 0
pcall(function() LastBeli = lp.Data.Beli.Value end)

--// [3. GIAO DIỆN UI HIỆN ĐẠI]
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "DuonneZOG_V15"

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 250, 0, 150)
Main.Position = UDim2.new(0, 15, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 255, 150)
stroke.Thickness = 2

local function CreateLabel(text, pos, color, size)
    local l = Instance.new("TextLabel", Main)
    l.Size = UDim2.new(1, -20, 0, 20)
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = size or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Position = pos + UDim2.new(0, 10, 0, 0)
    return l
end

local title = CreateLabel("DUONNEZOG V15", UDim2.new(0, 0, 0, 10), Color3.fromRGB(0, 255, 150), 16)
local moneyTxt = CreateLabel("Earned: +0k", UDim2.new(0, 0, 0, 40))
local timeTxt = CreateLabel("Time: 00:00:00", UDim2.new(0, 0, 0, 65))
local hopTxt = CreateLabel("Hop in: 25s", UDim2.new(0, 0, 0, 90), Color3.fromRGB(200, 200, 200))
local statusTxt = CreateLabel("Status: Initializing...", UDim2.new(0, 0, 0, 115), Color3.fromRGB(255, 255, 0), 11)

--// [4. LOGIC SERVER HOP]
getgenv().Config = {
    MaxPlayers = 8,
    HopTimeLimit = 25,
    WaitBetweenChests = 0.15,
    IsHopping = false
}

local function GeminiHop()
    if getgenv().Config.IsHopping then return end
    getgenv().Config.IsHopping = true
    statusTxt.Text = "Status: Finding Server..."
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, s in ipairs(servers) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId and s.playing <= getgenv().Config.MaxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
                task.wait(5)
            end
        end
    end)
    getgenv().Config.IsHopping = false
end

--// [5. AUTO CHEST CORE]
task.spawn(function()
    while task.wait(0.5) do
        -- Tự chọn phe Marines
        pcall(function()
            if lp.Team == nil then
                rs.Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end
            -- Cập nhật thông số Beli
            local currentBeli = lp.Data.Beli.Value
            if currentBeli > LastBeli then TotalMoneyEarned = TotalMoneyEarned + (currentBeli - LastBeli) end
            LastBeli = currentBeli
            
            moneyTxt.Text = "Earned: +" .. string.format("%.1f", TotalMoneyEarned/1000) .. "k Beli"
            timeTxt.Text = "Time: " .. os.date("!%X", tick() - StartTime)
            SaveStats({Money = TotalMoneyEarned, StartTime = StartTime})
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if not getgenv().Config.IsHopping then
            pcall(function()
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local chests = {}
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v.Name:find("Chest") and v:FindFirstChild("TouchInterest") then 
                        table.insert(chests, v) 
                    end
                end

                -- Ưu tiên Kim Cương > Gần nhất
                table.sort(chests, function(a, b)
                    local aD = a.Name:lower():find("diamond")
                    local bD = b.Name:lower():find("diamond")
                    if aD and not bD then return true elseif not aD and bD then return false end
                    return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
                end)

                for _, chest in ipairs(chests) do
                    if getgenv().Config.IsHopping or not chest.Parent then break end
                    statusTxt.Text = "Status: Collecting " .. chest.Name
                    hrp.CFrame = chest.CFrame
                    firetouchinterest(hrp, chest, 0)
                    task.wait(getgenv().Config.WaitBetweenChests)
                    firetouchinterest(hrp, chest, 1)
                end
                statusTxt.Text = "Status: Waiting for chests..."
            end)
        end
    end
end)

--// [6. TIMER & FIX LAG]
task.spawn(function()
    local timer = getgenv().Config.HopTimeLimit
    while task.wait(1) do
        if not getgenv().Config.IsHopping then
            timer = timer - 1
            hopTxt.Text = "Hop in: " .. timer .. "s"
            if timer <= 0 then GeminiHop(); timer = getgenv().Config.HopTimeLimit end
        end
    end
end)

-- Phá va chạm và Fix lag
game:GetService("RunService").Stepped:Connect(function()
    if lp.Character then
        for _, v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- Màn hình trắng (Tự động bật để giảm lag tối đa)
task.spawn(function()
    task.wait(2)
    game:GetService("RunService"):Set3dRenderingEnabled(false)
end)

-- Anti AFK
for _, v in pairs(getconnections(lp.Idled)) do v:Disable() end
