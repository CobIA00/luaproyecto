-- Remote Logger "Delta-Friendly" - sin hookmetamethod, hookfunction opcional
-- Prioriza dummy replace + fallback simple

local cloneref = cloneref or function(x) return x end
local Players = cloneref(game:GetService("Players"))
local lp = Players.LocalPlayer
local rs = cloneref(game:GetService("ReplicatedStorage"))

-- Config básica
getgenv().LoggerEnabled = true
getgenv().IgnoreDuplicates = true
getgenv().MaxLogs = 120

-- Tabla para evitar spam
local logged = {}

-- UI simple (ScreenGui funciona bien en Delta)
local sg = Instance.new("ScreenGui")
sg.Name = "DeltaLogger"
sg.ResetOnSpawn = false
sg.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 260)
frame.Position = UDim2.new(0.5, -190, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundColor3 = Color3.fromRGB(35,35,45)
title.Text = " Delta Remote Logger - 2026"
title.TextColor3 = Color3.fromRGB(180,180,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 17
title.Parent = frame

local logsFrame = Instance.new("ScrollingFrame")
logsFrame.Size = UDim2.new(1,-10,1,-70)
logsFrame.Position = UDim2.new(0,5,0,35)
logsFrame.BackgroundTransparency = 1
logsFrame.ScrollBarThickness = 5
logsFrame.CanvasSize = UDim2.new(0,0,0,0)
logsFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = logsFrame

-- Botón clear
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.4,0,0,25)
clearBtn.Position = UDim2.new(0.3,0,1,-30)
clearBtn.BackgroundColor3 = Color3.fromRGB(120,50,50)
clearBtn.Text = "Clear"
clearBtn.TextColor3 = Color3.new(1,1,1)
clearBtn.Parent = frame

clearBtn.MouseButton1Click:Connect(function()
    for _,v in logsFrame:GetChildren() do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logged = {}
end)

local function addLog(msg, col)
    if not LoggerEnabled then return end
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = msg
    lbl.TextColor3 = col or Color3.fromRGB(220,220,220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.RichText = true
    lbl.Parent = logsFrame
    
    logsFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    logsFrame.CanvasPosition = Vector2.new(0, 9999)
end

-- Formato args simple
local function fmt(v)
    local t = typeof(v)
    if t == "string" then return '"'..v..'"' end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "Instance" then return v.ClassName..":"..(v.Name or "?") end
    return "<"..t..">"
end

-- ====================== MÉTODO PRINCIPAL (mejor chance en Delta) ======================

-- 1. Intentamos hookfunction (si crashea o no funciona → ignora y usa fallback)
local hooked = false

local success, err = pcall(function()
    local dummy = Instance.new("RemoteEvent")
    local oldFire = hookfunction(dummy.FireServer, function(self, ...)
        if not LoggerEnabled then return oldFire(self, ...) end
        if checkcaller and checkcaller() then return oldFire(self, ...) end
        
        local args = {...}
        local str = ""
        for i,v in args do str = str .. (i>1 and ", " or "") .. fmt(v) end
        
        local key = self:GetFullName() .. str
        if IgnoreDuplicates and logged[key] then return oldFire(self, ...) end
        logged[key] = true
        
        addLog(
            '<font color="rgb(100,255,180)">[Fire]</font> ' .. (self.Name or "?") .. '(' .. str .. ')',
            Color3.fromRGB(100,255,180)
        )
        
        return oldFire(self, ...)
    end)
    
    local dummyRF = Instance.new("RemoteFunction")
    local oldInvoke = hookfunction(dummyRF.InvokeServer, function(self, ...)
        if not LoggerEnabled then return oldInvoke(self, ...) end
        if checkcaller and checkcaller() then return oldInvoke(self, ...) end
        
        local args = {...}
        local str = ""
        for i,v in args do str = str .. (i>1 and ", " or "") .. fmt(v) end
        
        local key = self:GetFullName() .. str
        if IgnoreDuplicates and logged[key] then return oldInvoke(self, ...) end
        logged[key] = true
        
        addLog(
            '<font color="rgb(255,180,100)">[Invoke]</font> ' .. (self.Name or "?") .. '(' .. str .. ')',
            Color3.fromRGB(255,180,100)
        )
        
        return oldInvoke(self, ...)
    end)
    
    hooked = true
    addLog("<font color='rgb(150,255,150)'>hookfunction OK → Logger activo</font>")
end)

if not success or not hooked then
    addLog("<font color='rgb(255,100,100)'>hookfunction falló en Delta → usando fallback dummy</font>")
    
    -- Fallback: creamos dummies y tratamos de "sobrescribir" referencias (funciona solo si el juego no cachea fuerte)
    -- Esto es limitado, pero mejor que nada en Delta
    local dummies = {}
    
    for _, v in rs:GetDescendants() do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local dummy = v:IsA("RemoteEvent") and Instance.new("RemoteEvent") or Instance.new("RemoteFunction")
            dummy.Name = v.Name
            dummies[v] = dummy
            
            -- Intentamos hook simple (no ideal, pero Delta a veces lo permite)
            if v:IsA("RemoteEvent") then
                v.FireServer = function(self, ...)
                    addLog("<font color='rgb(255,150,100)'>[Fallback Fire] " .. v.Name .. "</font>")
                    return dummy:FireServer(...)
                end
            else
                v.InvokeServer = function(self, ...)
                    addLog("<font color='rgb(200,100,255)'>[Fallback Invoke] " .. v.Name .. "</font>")
                    return dummy:InvokeServer(...)
                end
            end
        end
    end
    
    addLog("Fallback activado (limitado) → solo detecta nuevos calls")
end

addLog("Logger iniciado en Delta Executor • Prueba Fire/Invoke", Color3.fromRGB(180,180,255))

-- Toggle simple (puedes bindear a tecla si Delta lo permite)
-- game:GetService("UserInputService").InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.F6 then LoggerEnabled = not LoggerEnabled end end)
