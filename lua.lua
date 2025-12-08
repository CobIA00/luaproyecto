-- PS1 MAX PET GUI - New Stats / New Other (Tu Dex 2025)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer.Name
local playerGui = player:WaitForChild("PlayerGui")

local core = workspace.__REMOTES.Core
local getOwn = core["Get Stats"]
local getOther = core["Get Other Stats"]
local newOwn = core["New Stats"]
local newOther = core["New Other Stats"]

local function getMyPets()
    local pets = {}
    pcall(function()
        local own = getOwn:InvokeServer()
        local ownPets = own["Save"]["Pets"] or {}
        for _,v in pairs(ownPets) do if v.n then table.insert(pets, {name=v.n, lvl=v.l or 0, pow=v.p or 0, data=v}) end end
    end)
    pcall(function()
        local other = getOther:InvokeServer()
        local otherPets = other[player]["Save"]["Pets"] or {}
        for _,v in pairs(otherPets) do if v.n then table.insert(pets, {name=v.n, lvl=v.l or 0, pow=v.p or 0, data=v}) end end
    end)
    return pets
end

local function tryMax(petName)
    -- Método 1: New Stats (self full)
    pcall(function()
        local stats = getOwn:InvokeServer()
        for i,v in pairs(stats["Save"]["Pets"]) do
            if v.n == petName then v.l = 999999999; v.p = 999999999 end
        end
        newOwn:FireServer(stats)
    end)
    -- Método 2: New Stats (solo Save)
    pcall(function()
        local stats = getOwn:InvokeServer()
        newOwn:FireServer(stats["Save"])
    end)
    -- Método 3: New Other (self stats)
    pcall(function()
        local other = getOther:InvokeServer()
        local my = other[player]
        for i,v in pairs(my["Save"]["Pets"]) do
            if v.n == petName then v.l = 999999999; v.p = 999999999 end
        end
        newOther:FireServer(player, my)
    end)
    -- Método 4: New Other (full table)
    pcall(function()
        local other = getOther:InvokeServer()
        local my = other[player]
        for i,v in pairs(my["Save"]["Pets"]) do
            if v.n == petName then v.l = 999999999; v.p = 999999999 end
        end
        newOther:FireServer(other)
    end)
    wait(1)
end

-- GUI (móvil OK)
local sg = Instance.new("ScreenGui", playerGui); sg.Name = "PS1Maxer"; sg.ResetOnSpawn = false
local mf = Instance.new("Frame", sg); mf.Size = UDim2.new(0.85,0,0.75,0); mf.Position = UDim2.new(0.075,0,0.125,0)
mf.BackgroundColor3 = Color3.fromRGB(20,20,30); mf.BorderSizePixel=0
local uc = Instance.new("UICorner", mf); uc.CornerRadius = UDim.new(0,15)
local title = Instance.new("TextLabel", mf); title.Size = UDim2.new(1,0,0.12,0); title.BackgroundTransparency=1
title.Text = "🐶 PS1 MAXER - New Stats (Permanente)"; title.TextColor3 = Color3.new(1,1,1); title.TextScaled=true; title.Font=Enum.Font.GothamBold
local close = Instance.new("TextButton", mf); close.Size = UDim2.new(0.1,0,0.1,0); close.Position = UDim2.new(0.88,0,0.02,0)
close.BackgroundColor3 = Color3.fromRGB(255,40,40); close.Text="X"; close.TextColor3=1; close.TextScaled=true; close.Font=Enum.Font.GothamBold
local cc = Instance.new("UICorner", close); cc.CornerRadius = UDim.new(0,8)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local sf = Instance.new("ScrollingFrame", mf); sf.Size = UDim2.new(1,-20,0.68,0); sf.Position = UDim2.new(0,10,0.14,0)
sf.BackgroundColor3 = Color3.fromRGB(35,35,45); sf.BorderSizePixel=0; sf.ScrollBarThickness=6
local sc = Instance.new("UICorner", sf); sc.CornerRadius = UDim.new(0,12)
local ul = Instance.new("UIListLayout", sf); ul.Padding = UDim.new(0,8)

local maxAll = Instance.new("TextButton", mf); maxAll.Size = UDim2.new(1,-20,0.09,0); maxAll.Position = UDim2.new(0,10,0.86,0)
maxAll.BackgroundColor3 = Color3.fromRGB(0,255,80); maxAll.Text="🚀 MAX TODAS"; maxAll.TextColor3=1; maxAll.TextScaled=true; maxAll.Font=Enum.Font.GothamBold
local ac = Instance.new("UICorner", maxAll); ac.CornerRadius = UDim.new(0,12)

local refresh = Instance.new("TextButton", mf); refresh.Size = UDim2.new(0.48,-10,0.09,0); refresh.Position = UDim2.new(0,10,0.76,0)
refresh.BackgroundColor3 = Color3.fromRGB(80,150,255); refresh.Text="🔄 REFRESH"; refresh.TextColor3=1; refresh.TextScaled=true; refresh.Font=Enum.Font.Gotham
local rc = Instance.new("UICorner", refresh); rc.CornerRadius = UDim.new(0,12)

local function load()
    for _,c in pairs(sf:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local pets = getMyPets()
    if #pets == 0 then
        local nol = Instance.new("TextLabel", sf); nol.Size=UDim2.new(1,0,0,60); nol.BackgroundTransparency=1
        nol.Text="No pets válidas (ejecuta VER primero)"; nol.TextColor3=Color3.fromRGB(255,200,100); nol.TextScaled=true
    else
        for _,pet in pairs(pets) do
            local btn = Instance.new("TextButton", sf); btn.Size=UDim2.new(1,0,0,50)
            btn.BackgroundColor3 = Color3.fromRGB(50,50,60); btn.Text = pet.name .. "\nLvl: " .. pet.lvl .. " | Pow: " .. pet.pow
            btn.TextColor3=1; btn.TextScaled=true; btn.Font=Enum.Font.Gotham
            local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,8)
            btn.MouseButton1Click:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(0,255,80)
                tryMax(pet.name)
                wait(0.3); btn.BackgroundColor3 = Color3.fromRGB(50,50,60)
                load()
            end)
        end
    end
    sf.CanvasSize = UDim2.new(0,0,0, ul.AbsoluteContentSize.Y + 20)
end

maxAll.MouseButton1Click:Connect(function()
    local pets = getMyPets()
    for _,pet in pairs(pets) do tryMax(pet.name) end
    wait(2); load()
end)
refresh.MouseButton1Click:Connect(load)
load()

-- Anim
mf.Size = UDim2.new(0,0,0,0)
TweenService:Create(mf, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size=UDim2.new(0.85,0,0.75,0)}):Play()
