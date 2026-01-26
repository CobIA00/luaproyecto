--// DeltaSpy-Lite  (full-mobile, sin syn)
--// by 0xDev – fix incluido para Pets

------------------------------------------------------------------------
-- 0.  Parche rápido al error “attempt to index nil with 'n'”
--     (inyectamos antes de que el cliente cargue el módulo)
------------------------------------------------------------------------
local pets = player:WaitForChild("PlayerGui"):WaitForChild("Modules"):WaitForChild("(M) Pets")
local getPetDir = pets:WaitForChild("GetPetDir")
local old; old = hookfunction(getPetDir, function(...)
    local s, r = pcall(old, ...)
    if not s then
        -- Devolvemos directorio vacío para que no pete
        return {n = Vector3.new(0, 0, 1), r = 0}
    end
    return r
end)

------------------------------------------------------------------------
-- 1.  GUI flotante (sin syn.protect_gui)
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = string.reverse("Spy") -- nombre invertido, menos visible
gui.DisplayOrder = 999
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- drag & drop táctil (mismo código anterior)
local function drag(frame)
    local uis = game:GetService("UserInputService")
    local dragging, start, objPos
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; start = inp.Position; objPos = frame.Position
        end
    end)
    uis.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = inp.Position - start
            frame.Position = UDim2.new(objPos.X.Scale, objPos.X.Offset + delta.X,
                                      objPos.Y.Scale, objPos.Y.Offset + delta.Y)
        end
    end)
    uis.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
        end
    end)
end

------------------------------------------------------------------------
-- 2.  Front-end
------------------------------------------------------------------------
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 160)
main.Position = UDim2.new(0.5, -130, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Active = true
drag(main); main.Parent = gui

local top = Instance.new("TextLabel")
top.Size = UDim2.new(1, 0, 0, 24)
top.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
top.Text = "  ΔSpy"
top.TextColor3 = Color3.white
top.Font = Enum.Font.GothamBold
top.TextSize = 14
top.Parent = main

local log = Instance.new("ScrollingFrame")
log.Size = UDim2.new(1, -8, 1, -56)
log.Position = UDim2.new(0, 4, 0, 28)
log.BackgroundTransparency = 1
log.ScrollBarThickness = 4
log.CanvasSize = UDim2.new(0, 0, 0, 0)
log.Parent = main

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 2)
uiList.Parent = log

local function newL(txt)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = log
    log.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y)
end

------------------------------------------------------------------------
-- 3.  Logger (hook __namecall)
------------------------------------------------------------------------
local Block, Spoof = {}, {}
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        local args = {...}
        local brief = table.concat(args, " | ")
        newL(string.format("%s → %s", self.Name, brief))
        if Block[self] then return end
        if Spoof[self] then return table.unpack(Spoof[self]) end
    end
    return oldNamecall(self, ...)
end)

------------------------------------------------------------------------
-- 4.  Botones (misma lógica táctil)
------------------------------------------------------------------------
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -8, 0, 24)
bar.Position = UDim2.new(0, 4, 1, -28)
bar.BackgroundTransparency = 1
bar.Parent = main

local blockBtn = Instance.new("TextButton")
blockBtn.Size = UDim2.new(0.3, 0, 1, 0)
blockBtn.Text = "Block"
blockBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
blockBtn.Font = Enum.Font.GothamSemibold
blockBtn.TextSize = 12
blockBtn.Parent = bar

local spoofBtn = Instance.new("TextButton")
spoofBtn.Size = UDim2.new(0.3, 0, 1, 0)
spoofBtn.Position = UDim2.new(0.35, 0, 0, 0)
spoofBtn.Text = "Spoof"
spoofBtn.BackgroundColor3 = Color3.fromRGB(90, 200, 90)
spoofBtn.Font = Enum.Font.GothamSemibold
spoofBtn.TextSize = 12
spoofBtn.Parent = bar

local grabBtn = Instance.new("TextButton")
grabBtn.Size = UDim2.new(0.3, 0, 1, 0)
grabBtn.Position = UDim2.new(0.7, 0, 0, 0)
grabBtn.Text = "Grab"
grabBtn.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
grabBtn.Font = Enum.Font.GothamSemibold
grabBtn.TextSize = 12
grabBtn.Parent = bar

blockBtn.MouseButton1Click:Connect(function()
    newL("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local t = game:GetService("Players").LocalPlayer:GetMouse().Target
            if t and t:IsA("RemoteEvent") then Block[t] = true; newL("Bloqueado: "..t.Name); con:Disconnect() end
        end
    end)
    task.wait(3); con:Disconnect()
end)

spoofBtn.MouseButton1Click:Connect(function()
    newL("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local t = game:GetService("Players").LocalPlayer:GetMouse().Target
            if t and t:IsA("RemoteEvent") then Spoof[t] = {"spoof"}; newL("Spoofeado: "..t.Name); con:Disconnect() end
        end
    end)
    task.wait(3); con:Disconnect()
end)

grabBtn.MouseButton1Click:Connect(function()
    newL("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local t = game:GetService("Players").LocalPlayer:GetMouse().Target
            if t and t:IsA("RemoteEvent") then
                local pack
                local old = t.FireServer
                t.FireServer = function(_,...) pack = {...}; return old(t,...) end
                task.spawn(function()
                    task.wait(1)
                    old(t, table.unpack(pack))
                    newL("Reenviado: "..t.Name)
                end)
                con:Disconnect()
            end
        end
    end)
    task.wait(3); con:Disconnect()
end)

newL("DeltaSpy móvil activo – arrastra la ventana")
