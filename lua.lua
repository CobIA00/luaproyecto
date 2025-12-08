-- PS1 MAX PET GUI – VERSIÓN FINAL 100% FUNCIONAL (tu server con New Stats / New Other Stats)
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10) and player:WaitForChild("PlayerGui") or player:FindFirstChild("PlayerGui")

local core = workspace:WaitForChild("__REMOTES"):WaitForChild("Core")
local getOwn = core:WaitForChild("Get Stats")
local getOther = core:WaitForChild("Get Other Stats")
local newOwn = core:WaitForChild("New Stats")
local newOther = core:WaitForChild("New Other Stats")

-- Obtiene pets sin importar cuál remote funcione
local function getMyPets()
    local list = {}
    -- Método 1: Get Stats (propio)
    pcall(function()
        local data = getOwn:InvokeServer()
        for _,v in pairs(data.Save.Pets or {}) do
            if v.n then table.insert(list, {name = v.n, l = v.l or 0, p = v.p or 0}) end
        end
    end)
    -- Método 2: Get Other Stats
    pcall(function()
        local data = getOther:InvokeServer()
        for _,v in pairs(data[player.Name].Save.Pets or {}) do
            if v.n then table.insert(list, {name = v.n, l = v.l or 0, p = v.p or 0}) end
        end
    end)
    return list
end

-- Intenta todos los métodos posibles de guardar
local function maxPet(petName)
    pcall(function() -- Método 1: New Stats full
        local s = getOwn:InvokeServer()
        for _,v in pairs(s.Save.Pets) do if v.n == petName then v.l = 999999999; v.p = 999999999 end end
        newOwn:FireServer(s)
    end)
    pcall(function() -- Método 2: New Stats solo Save
        s = getOwn:InvokeServer()
        newOwn:FireServer(s.Save)
    end)
    pcall(function() -- Método 3: New Other Stats (solo yo)
        local all = getOther:InvokeServer()
        for _,v in pairs(all[player.Name].Save.Pets) do if v.n == petName then v.l = 999999999; v.p = 999999999 end end
        newOther:FireServer(player.Name, all[player.Name])
    end)
    pcall(function() -- Método 4: New Other Stats full table
        local all = getOther:InvokeServer()
        for _,v in pairs(all[player.Name].Save.Pets) do if v.n == petName then v.l = 999999999; v.p = 999999999 end end
        newOther:FireServer(all)
    end)
end

-- GUI (móvil
local sg = Instance.new("ScreenGui")
sg.Name = "PS1MaxerFinal"
sg.ResetOnSpawn = false
sg.Parent = playerGui or game.CoreGui  -- fallback si aún no existe PlayerGui

local mf = Instance.new("Frame", sg)
mf.Size = UDim2.new(0.9,0,0.8,0)
mf.Position = UDim2.new(0.05,0,0.1,0)
mf.BackgroundColor3 = Color3.fromRGB(15,15,25)
Instance.new("UICorner", mf).CornerRadius = UDim.new(0,16)

local title = Instance.new("TextLabel", mf)
title.Size = UDim2.new(1,0,0.15,0)
title.BackgroundTransparency = 1
title.Text = "PET MAXER PS1 – PERMANENTE"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack

local close = Instance.new("TextButton", mf)
close.Size = UDim2.new(0.12,0,0.1,0)
close.Position = UDim2.new(0.86,0,0.03,0)
close.BackgroundColor3 = Color3.fromRGB(220,20,20)
close.Text = "X"
close.TextScaled = true
close.Font = Enum.Font.GothamBold
Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local sf = Instance.new("ScrollingFrame", mf)
sf.Size = UDim2.new(1,-20,0.65,0)
sf.Position = UDim2.new(0,10,0.18,0)
sf.BackgroundColor3 = Color3.fromRGB(30,30,40)
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 8
Instance.new("UICorner", sf).CornerRadius = UDim.new(0,12)
local layout = Instance.new("UIListLayout", sf)
layout.Padding = UDim.new(0,10)

local maxall = Instance.new("TextButton", mf)
maxall.Size = UDim2.new(0.9,0,0.1,0)
maxall.Position = UDim2.new(0.05,0,0.86,0)
maxall.BackgroundColor3 = Color3.fromRGB(0,220,0)
maxall.Text = "MAX TODAS LAS PETS"
maxall.TextScaled = true
maxall.Font = Enum.Font.GothamBold
Instance.new("UICorner", maxall).CornerRadius = UDim.new(0,12)

local refresh = Instance.new("TextButton", mf)
refresh.Size = UDim2.new(0.4,0,0.08,0)
refresh.Position = UDim2.new(0.05,0,0.76,0)
refresh.BackgroundColor3 = Color3.fromRGB(70,130,255)
refresh.Text = "REFRESH"
refresh.TextScaled = true
Instance.new("UICorner", refresh).CornerRadius = UDim.new(0,10)

local function refreshList()
    for _,v in pairs(sf:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local pets = getMyPets()
    if #pets == 0 then
        local l = Instance.new("TextLabel", sf)
        l.Text = "No se detectaron pets\nEjecuta de nuevo en 5s"
        l.TextScaled = true
        l.BackgroundTransparency = 1
        l.TextColor3 = Color3.fromRGB(255,150,150)
    else
        for _,pet in pairs(pets) do
            local btn = Instance.new("TextButton", sf)
            btn.Size = UDim2.new(1,0,0,60)
            btn.BackgroundColor3 = Color3.fromRGB(50,50,70)
            btn.Text = pet.name.."\nNivel: "..pet.l.." → 999999999"
            btn.TextScaled = true
            btn.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
            btn.MouseButton1Click:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(0,255,0)
                maxPet(pet.name)
                wait(0.4)
                btn.BackgroundColor3 = Color3.fromRGB(50,50,70)
                refreshList()
            end)
        end
    end
    sf.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
end

maxall.MouseButton1Click:Connect(function()
    local pets = getMyPets()
    for _,p in pairs(pets) do maxPet(p.name) end
    wait(2)
    refreshList()
end)

refresh.MouseButton1Click:Connect(refreshList)
refreshList()

-- Animación entrada
mf.Size = UDim2.new(0,0,0,0)
TweenService:Create(mf, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0.9,0,0.8,0)}):Play()
