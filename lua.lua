-- PET MAXER PS1 – VERSIÓN INDESTRUCTIBLE (Delta móvil 2025)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui") or task.wait(10)

local player = game.Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 30)

repeat task.wait() until workspace:FindFirstChild("__REMOTES")
repeat task.wait() until workspace.__REMOTES:FindFirstChild("Core")

local core = workspace.__REMOTES.Core
local getOwn = core["Get Stats"]
local getOther = core["Get Other Stats"]
local newOwn = core["New Stats"]
local newOther = core["New Other Stats"]

local function getMyPets()
    local list = {}
    pcall(function()
        local data = getOwn:InvokeServer()
        for _,v in pairs(data.Save and data.Save.Pets or {}) do
            if v.n then table.insert(list, {name=v.n, l=v.l or 0, p=v.p or 0}) end
        end
    end)
    pcall(function()
        local data = getOther:InvokeServer()
        for _,v in pairs(data[player.Name] and data[player.Name].Save and data[player.Name].Save.Pets or {}) do
            if v.n then table.insert(list, {name=v.n, l=v.l or 0, p=v.p or 0}) end
        end
    end)
    return list
end

local function maxPet(name)
    pcall(function() local d = getOwn:InvokeServer(); for _,v in pairs(d.Save.Pets or {}) do if v.n==name then v.l=999999999 v.p=999999999 end end newOwn:FireServer(d) end)
    pcall(function() local d = getOwn:InvokeServer(); newOwn:FireServer(d.Save) end)
    pcall(function() local d = getOther:InvokeServer(); for _,v in pairs(d[player.Name].Save.Pets or {}) do if v.n==name then v.l=999999999 v.p=999999999 end end newOther:FireServer(player.Name, d[player.Name]) end)
    pcall(function() local d = getOther:InvokeServer(); for _,v in pairs(d[player.Name].Save.Pets or {}) do if v.n==name then v.l=999999999 v.p=999999999 end end newOther:FireServer(d) end)
end

-- GUI ULTRA SIMPLE Y SEGURA
local sg = Instance.new("ScreenGui")
sg.Name = "MAXER_PS1"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0.9,0,0.8,0)
frame.Position = UDim2.new(0.05,0,0.1,0)
frame.BackgroundColor3 = Color3.fromRGB(10,10,20)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0.15,0)
title.BackgroundTransparency = 1
title.Text = "PET MAXER PS1"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0.15,0,0.1,0)
close.Position = UDim2.new(0.82,0,0.02,0)
close.BackgroundColor3 = Color3.fromRGB(220,20,20)
close.Text = "X"
close.TextScaled = true
Instance.new("UICorner", close)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local list = Instance.new("ScrollingFrame", frame)
list.Size = UDim2.new(1,-20,0.65,0)
list.Position = UDim2.new(0,10,0.18,0)
list.BackgroundColor3 = Color3.fromRGB(25,25,35)
list.ScrollBarThickness = 8
Instance.new("UICorner", list)
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,10)

local maxall = Instance.new("TextButton", frame)
maxall.Size = UDim2.new(0.8,0,0.1,0)
maxall.Position = UDim2.new(0.1,0,0.86,0)
maxall.BackgroundColor3 = Color3.fromRGB(0,200,0)
maxall.Text = "MAX TODAS"
maxall.TextScaled = true
Instance.new("UICorner", maxall)

local function refresh()
    for _,v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local pets = getMyPets()
    if #pets == 0 then
        local lbl = Instance.new("TextLabel", list)
        lbl.Text = "No pets detectadas\nEspera 5s y pulsa REFRESH"
        lbl.TextScaled = true
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255,100,100)
    else
        for _,p in pairs(pets) do
            local btn = Instance.new("TextButton", list)
            btn.Size = UDim2.new(1,0,0,60)
            btn.BackgroundColor3 = Color3.fromRGB(40,40,60)
            btn.Text = p.name.."\n"..p.l.." → 999999999"
            btn.TextScaled = true
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                maxPet(p.name)
                task.wait(0.5)
                refresh()
            end)
        end
    end
    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
end

maxall.MouseButton1Click:Connect(function()
    for _,p in pairs(getMyPets()) do maxPet(p.name) end
    task.wait(2)
    refresh()
end)

refresh()
