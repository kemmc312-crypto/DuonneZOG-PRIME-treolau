--[[ 
    DUONNEZOG PRIME V14.2 - VELOCITY AUTO-EXEC OPTIMIZED (MODIFIED)
    - REMOVED: Tự động dừng khi nhặt đồ hiếm (God's Chalice, Fist, v.v.)
]]

-- Đợi game load xong 100% trước khi chạy code
if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

-- Đợi nhân vật và dữ liệu sẵn sàng
repeat task.wait() until game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("Data")

--// [TỰ ĐỘNG CHỌN PHE - Marines]
pcall(function()
    if game:GetService("Players").LocalPlayer.Team == nil then
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
    end
end)

--// [PHẦN 1: HỆ THỐNG LƯU TRỮ]
local HttpService = game:GetService("HttpService")
local fileName = "DuonneZOG_Data.json"

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
local TotalChalice = SavedData and SavedData.Chalice or 0
local TotalFist = SavedData and SavedData.Fist or 0
local StartTime = SavedData and SavedData.StartTime or tick()
local LastBeli = game.Players.LocalPlayer.Data.Beli.Value

--// [PHẦN 2: GIAO DIỆN UI]
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "DuonneZOG_Final"
sg.DisplayOrder = 9999

local BlackFrame = Instance.new("Frame", sg)
BlackFrame.Size = UDim2.new(1, 0, 1, 0)
BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackFrame.ZIndex = 1

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 450, 0, 170)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Main.BorderSizePixel = 0
Main.ZIndex = 2
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 3

local logo = Instance.new("ImageLabel", Main)
logo.Size = UDim2.new(0, 110, 0, 110)
logo.Position = UDim2.new(0, 20, 0.5, -55)
logo.BackgroundTransparency = 1
logo.Image = "rbxthumb://type=Asset&id=8582793337&w=420&h=420"
logo.ZIndex = 3

local function CreateLabel(text, pos, color, size)
    local l = Instance.new("TextLabel", Main)
    l.Size = UDim2.new(0, 280, 0, 30)
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = size or 16
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 4
    return l
end

local title = CreateLabel("DUONNEZOG PRIME", UDim2.new(0, 145, 0, 20), Color3.fromRGB(255, 0, 0), 24)
local moneyTxt = CreateLabel("Earned: +0k Beli", UDim2.new(0, 145, 0, 55), nil, 17)
local timeTxt = CreateLabel("Time: 00:00:00", UDim2.new(0, 145, 0, 80), Color3.fromRGB(180, 180, 180), 16)
local chaliceTxt = CreateLabel("Chalice Found: 0", UDim2.new(0, 145, 0, 105), Color3.fromRGB(255, 255, 0), 16)
local fistTxt = CreateLabel("Fist of Darkness: 0", UDim2.new(0, 145, 0, 130), Color3.fromRGB(255, 0, 255), 16)

--// [PHẦN 3: LOGIC CẬP NHẬT STATS]
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local currentBeli = game.Players.LocalPlayer.Data.Beli.Value
            if currentBeli > LastBeli then TotalMoneyEarned = TotalMoneyEarned + (currentBeli - LastBeli) end
            LastBeli = currentBeli
            
            local chaliceInBag, fistInBag = 0, 0
            for _, folder in pairs({game.Players.LocalPlayer.Backpack, game.Players.LocalPlayer.Character}) do
                for _, v in pairs(folder:GetChildren()) do
                    if v.Name == "God's Chalice" then chaliceInBag = chaliceInBag + 1 end
                    if v.Name:find("Fist") then fistInBag = fistInBag + 1 end
                end
            end
            if chaliceInBag > TotalChalice then TotalChalice = chaliceInBag end
            if fistInBag > TotalFist then TotalFist = fistInBag end

            moneyTxt.Text = "Earned: +" .. string.format("%.1f", TotalMoneyEarned/1000) .. "k Beli"
            timeTxt.Text = "Time: " .. os.date("!%X", tick() - StartTime)
            chaliceTxt.Text = "Chalice Found: " .. TotalChalice
            fistTxt.Text = "Fist of Darkness: " .. TotalFist

            SaveStats({Money = TotalMoneyEarned, Chalice = TotalChalice, Fist = TotalFist, StartTime = StartTime})
        end)
    end
end)

--// [PHẦN 4: HIỆU ỨNG THU NHỎ UI]
task.spawn(function()
    task.wait(6)
    local ts = game:GetService("TweenService")
    local info = TweenInfo.new(1.2, Enum.EasingStyle.Quart)
    ts:Create(BlackFrame, info, {BackgroundTransparency = 1}):Play()
    ts:Create(Main, info, {Position = UDim2.new(0, 15, 0, 15), AnchorPoint = Vector2.new(0, 0), Size = UDim2.new(0, 250, 0, 120)}):Play()
    ts:Create(logo, info, {Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 10, 0.5, -30)}):Play()
    title.TextSize = 14; title.Position = UDim2.new(0, 80, 0, 10)
    moneyTxt.TextSize = 11; moneyTxt.Position = UDim2.new(0, 80, 0, 30)
    timeTxt.TextSize = 10; timeTxt.Position = UDim2.new(0, 80, 0, 45)
    chaliceTxt.TextSize = 10; chaliceTxt.Position = UDim2.new(0, 80, 0, 60)
    fistTxt.TextSize = 10; fistTxt.Position = UDim2.new(0, 80, 0, 75)
    task.wait(1.5)
    if BlackFrame then BlackFrame:Destroy() end
end)

--// [PHẦN 5: AUTO CHEST ĐÃ CHỈNH SỬA]
getgenv().Config = {
    AutoChest = true,
    MaxPlayers = 8,
    HopTimeLimit = 25,
    CollectTime = 5,    
    PauseTime = 2,
    WaitBetweenChests = 0.15,
    IsHopping = false
}

local RunService = game:GetService("RunService")
RunService.Stepped:Connect(function()
    if getgenv().Config.AutoChest then
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().Config.AutoChest and not getgenv().Config.IsHopping then
            local lp = game.Players.LocalPlayer
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local chests = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name:find("Chest") and v:FindFirstChild("TouchInterest") then table.insert(chests, v) end
            end

            table.sort(chests, function(a, b)
                local pA = a.Name:lower():find("diamond") and 3 or a.Name:lower():find("gold") and 2 or 1
                local pB = b.Name:lower():find("diamond") and 3 or b.Name:lower():find("gold") and 2 or 1
                return pA > pB
            end)

            local start = tick()
            for _, chest in ipairs(chests) do
                if tick() - start >= getgenv().Config.CollectTime or getgenv().Config.IsHopping then break end
                if chest.Parent then
                    hrp.CFrame = chest.CFrame
                    task.wait(getgenv().Config.WaitBetweenChests)
                    firetouchinterest(hrp, chest, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, chest, 1)
                end
            end
            task.wait(getgenv().Config.PauseTime)
        end
    end
end)

local function GeminiHop()
    getgenv().Config.IsHopping = true
    pcall(function()
        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, s in ipairs(servers) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId and s.playing <= getgenv().Config.MaxPlayers then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, game.Players.LocalPlayer)
                task.wait(5)
            end
        end
    end)
    getgenv().Config.IsHopping = false
end

task.spawn(function()
    local timer = getgenv().Config.HopTimeLimit
    while task.wait(1) do
        pcall(function()
            if game.Players.LocalPlayer.Team == nil then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end
        end)
        if getgenv().Config.AutoChest and not getgenv().Config.IsHopping then
            timer = timer - 1
            if timer <= 0 then GeminiHop(); timer = getgenv().Config.HopTimeLimit end
        end
    end
end)

for _, v in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do v:Disable() end
