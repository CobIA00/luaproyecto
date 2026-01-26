--// DeltaSpy-Zero (anti-crash + sin protect_gui) – pegar en Delta-Mobile
------------------------------------------------------------------------
-- 1.  Neutralizamos el require del módulo Pets antes de que corra
------------------------------------------------------------------------
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ScriptContext = game:GetService("ScriptContext")
local player = game:GetService("Players").LocalPlayer

--// Esperamos a que el módulo venga del servidor (línea 1 del script)
local petModuleScript = player:WaitForChild("PlayerGui"):WaitForChild("Modules"):WaitForChild("(M) Pets")
local realReq = require
local fakeEnv = {n = Vector3.new(0,0,1), r = 0}   -- respuesta dummy segura

--// Patch en caliente del bytecode
local function patchMod()
    local original = realReq(petModuleScript)
    -- original.GetPetDir existe pero devuelve nil → lo reemplazamos
    if original and original.GetPetDir then
        original.GetPetDir = function(...) return fakeEnv end
    end
    return original
end

--// Spoofeamos require para que devuelva el módulo ya parcheado
local mt = getrawmetatable(require) or {}
setreadonly(mt, false)
mt.__namecall = function(_, mod)
    if mod == petModuleScript then return patchMod() end
    return realReq(mod)
end
setreadonly(mt, true)

------------------------------------------------------------------------
-- 2.  GUI mínima (sin syn, sin protect_gui)
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = string.reverse("Spy")
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,250,0,140)
main.Position = UDim2.new(0.5,-125,0.15,0)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

-- drag táctil
local uis = game:GetService("UserInputService")
local drag,g start,g dragging
main.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; g start = inp.Position; g = main.Position
    end
end)
uis.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inp.Position - g start
        main.Position = UDim2.new(g.X.Scale, g.X.Offset + delta.X,
                                 g.Y.Scale, g.Y.Offset + delta.Y)
    end
end)
uis.InputEnded:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1) then
        dragging = false
    end
end)

-- logger
local log = Instance.new("TextLabel")
log.Size = UDim2.new(1,-10,1,-30)
log.Position = UDim2.new(0,5,0,25)
log.BackgroundTransparency = 1
log.Text = ""
log.TextColor3 = Color3.new(1,1,1)
log.Font = Enum.Font.Gotham
log.TextSize = 11
log.TextXAlignment = Enum.TextXAlignment.Left
log.TextYAlignment = Enum.TextYAlignment.Top
log.ClipsDescendants = true
log.Parent = main

local function out(txt)
    log.Text = log.Text..txt.."\n"
end

------------------------------------------------------------------------
-- 3.  Hook remotes (simple)
------------------------------------------------------------------------
local block = {}
local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",function(self,...)
    local m = getnamecallmethod()
    if (m == "FireServer" or m == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        out(self.Name.." → "..table.concat({...}," | "))
        if block[self] then return end
    end
    return oldNamecall(self,...)
end)

------------------------------------------------------------------------
-- 4.  Botón rápido Block (tocar remote en 3s)
------------------------------------------------------------------------
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.4,0,0,20)
btn.Position = UDim2.new(0.3,0,1,-22)
btn.Text = "Block"
btn.BackgroundColor3 = Color3.fromRGB(255,90,90)
btn.Font = Enum.Font.GothamSemibold
btn.TextSize = 12
btn.Parent = main

btn.MouseButton1Click:Connect(function()
    out("Toca un Remote en 3s...")
    local con; con = uis.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local t = player:GetMouse().Target
            if t and t:IsA("RemoteEvent") then block[t]=true; out("Bloqueado: "..t.Name); con:Disconnect() end
        end
    end)
    task.wait(3); con:Disconnect()
end)

out("DeltaSpy-Zero activo – crash de Pets parcheado")
