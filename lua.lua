-- Pet Maxer PS1 UNIVERSAL - Multi-Path + Nil Safe (2025)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = workspace:WaitForChild("__REMOTES")
local function findRemote(name)
    return remotes:FindFirstChild(name) or remotes.Core:FindFirstChild(name) or remotes.Game:FindFirstChild(name)
end
local getStats = findRemote("Get Other Stats")
local setStats = findRemote("Set Stats")

local function maxPet(petName, maxVal)
    if not getStats or not setStats then return end
    local Stats = getStats:InvokeServer()
    local myPets = Stats[player.Name]["Save"]["Pets"] or {}
    for i, v in pairs(myPets) do
        local name = v.n or v[1]
        if name and name == petName then
            v.l = maxVal or 999999999
            v.p = maxVal or 999999999
            break
        end
    end
    setStats:FireServer(Stats[player.Name])
    wait(1.5)
end

-- GUI Móvil
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetMaxerUni"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
mainFrame.Position = UDim2.new(0.075, 0, 0.125, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uc = Instance.new("UICorner", mainFrame); uc.CornerRadius = UDim.new(0,15)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0.12,0); title.BackgroundTransparency = 1
title.Text = "🐶 PET MAXER PS1 - UNIVERSAL REMOTES"
title.TextColor3 = Color3.new(1,1,1); title.TextScaled = true; title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.1,0,0.1,0); closeBtn.Position = UDim2.new(0.88,0,0.02,0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255,40,40); closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true; closeBtn.Font = Enum.Font.GothamBold; closeBtn.Parent = mainFrame
local closeC = Instance.new("UICorner", closeBtn); closeC.CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-20,0.68,0); scrollFrame.Position = UDim2.new(0,10,0.14,0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(35,35,45); scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame; local scC = Instance.new("UICorner", scrollFrame); scC.CornerRadius = UDim.new(0,12)

local layout = Instance.new("UIListLayout", scrollFrame); layout.Padding = UDim.new(0,8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,0,0,40); statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = Color3.new(1,1,1); statusLbl.TextScaled = true; statusLbl.Font = Enum.Font.Gotham
statusLbl.Parent = scrollFrame

local maxAllBtn = Instance.new("TextButton")
maxAllBtn.Size = UDim2.new(1,-20,0.09,0); maxAllBtn.Position = UDim2.new(0,10,0.86,0)
maxAllBtn.BackgroundColor3 = Color3.fromRGB(0,255,80); maxAllBtn.Text = "🚀 MAX TODAS (999M)"
maxAllBtn.TextColor3 = Color3.new(1,1,1); maxAllBtn.TextScaled = true; maxAllBtn.Font = Enum.Font.GothamBold
maxAllBtn.Parent = mainFrame; local allC = Instance.new("UICorner", maxAllBtn); allC.CornerRadius = UDim.new(0,12)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.48,-10,0.09,0); refreshBtn.Position = UDim2.new(0,10,0.76,0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(80,150,255); refreshBtn.Text = "🔄 REFRESH"
refreshBtn.TextColor3 = Color3.new(1,1,1); refreshBtn.TextScaled = true; refreshBtn.Font = Enum.Font.Gotham
refreshBtn.Parent = mainFrame; local refC = Instance.new("UICorner", refreshBtn); refC.CornerRadius = UDim.new(0,12)

local function loadPets()
    statusLbl:Destroy()
    for _, child in pairs(scrollFrame:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
    if not getStats or not setStats then
        local err = Instance.new("TextLabel"); err.Size = UDim2.new(1,0,0,60); err.BackgroundTransparency = 1
        err.Text = "❌ Remotes NO encontrados.\nBusca 'Get Other Stats' en Dex."; err.TextColor3 = Color3.fromRGB(255,100,100)
        err.TextScaled = true; err.Font = Enum.Font.GothamBold; err.Parent = scrollFrame
        return
    end
    local success, Stats = pcall(getStats.InvokeServer, getStats)
    if success and Stats[player.Name] then
        local myPets = Stats[player.Name]["Save"]["Pets"] or {}
        local count = 0
        for _, v in pairs(myPets) do
            local name = v.n or v[1]
            if name and name ~= "" then
                count = count + 1
                local petBtn = Instance.new("TextButton")
                petBtn.Size = UDim2.new(1,0,0,50); petBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
                petBtn.Text = name .. "\nLvl: " .. (v.l or 0) .. " | Pow: " .. (v.p or 0)
                petBtn.TextColor3 = Color3.new(1,1,1); petBtn.TextScaled = true; petBtn.Font = Enum.Font.Gotham
                petBtn.Parent = scrollFrame; local pC = Instance.new("UICorner", petBtn); pC.CornerRadius = UDim.new(0,8)
                petBtn.MouseButton1Click:Connect(function()
                    petBtn.BackgroundColor3 = Color3.fromRGB(0,255,80)
                    spawn(function() maxPet(name) end)
                    wait(0.3); petBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
                    loadPets()
                end)
            end
        end
        if count == 0 then
            local noP = Instance.new("TextLabel"); noP.Size = UDim2.new(1,0,0,60); noP.BackgroundTransparency = 1
            noP.Text = "✅ No pets válidas (inventario vacío?)"; noP.TextColor3 = Color3.fromRGB(100,255,100)
            noP.TextScaled = true; noP.Parent = scrollFrame
        end
    else
        local err = Instance.new("TextLabel"); err.Size = UDim2.new(1,0,0,60); err.BackgroundTransparency = 1
        err.Text = "❌ Error Invoke. Rejoin."; err.TextColor3 = Color3.fromRGB(255,100,100)
        err.TextScaled = true; err.Font = Enum.Font.GothamBold; err.Parent = scrollFrame
    end
    scrollFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
end

statusLbl.Text = "🔍 Buscando remotes..."; statusLbl.TextScaled = true; statusLbl.Parent = scrollFrame

maxAllBtn.MouseButton1Click:Connect(function()
    local Stats = getStats:InvokeServer()
    local myPets = Stats[player.Name]["Save"]["Pets"] or {}
    for _, v in pairs(myPets) do
        local name = v.n or v[1]
        if name and name ~= "" then maxPet(name, 999999999) end
    end
    wait(2.5); loadPets()
end)

refreshBtn.MouseButton1Click:Connect(loadPets)

wait(2); loadPets()  -- Auto load

-- Anim
mainFrame.Size = UDim2.new(0,0,0,0)
TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0.85,0,0.75,0)}):Play()
