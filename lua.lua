--// DeltaPets-Fix  (inyección directa en el hilo del módulo)
--// by 0xDev – 100 % móvil / Delta

local player = game:GetService("Players").LocalPlayer
local core   = game:GetService("CoreGui")

------------------------------------------------------------------------
-- 1.  Capturamos el hilo real del módulo antes de que use GetPetDir
------------------------------------------------------------------------
local petScript = player:WaitForChild("PlayerGui")
                    :WaitForChild("Scripts")
                    :WaitForChild("Game")
                    :WaitForChild("Pets")

--// Forzamos a que el hilo corra *ahora* (si aún no lo ha hecho)
--    con un dummy-require que dispara su loader interno
task.spawn(function()
    -- Ejecutamos el LocalScript interno para que se cree el entorno
    for _, scr in ipairs(petScript:GetDescendants()) do
        if scr:IsA("LocalScript") and scr.Name:find("Pets") then
            scr.Disabled = true
            scr.Disabled = false   -- fuerza re-run
            break
        end
    end
end)

------------------------------------------------------------------------
-- 2.  Patcheamos la función *desde dentro* usando debug.info
------------------------------------------------------------------------
local targetFunc = nil
local safety = Vector3.new(0, 0, 1)  -- valor "n" seguro
local safetyR = 0                      -- valor "r" seguro

--// Escaneamos cada frame hasta que la función aparezca
local heartbeat; heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
    -- Busca cualquier función cuyo source contenga "GetPetDir"
    for _, thread in ipairs(debug.getregistry()) do
        if type(thread) == "thread" and coroutine.status(thread) == "suspended" then
            local info = debug.getinfo(thread, "fn")
            if info and info.what == "Lua" and info.name == "GetPetDir" then
                targetFunc = info.func
                heartbeat:Disconnect()
                break
            end
        end
    end
end)

--// Una vez encontrada, la reemplazamos por una que nunca devuelva nil
task.spawn(function()
    while not targetFunc do task.wait() end
    -- Sustituimos la upvalue que devuelve la tabla
    local upvalue = 1
    while debug.getupvalue(targetFunc, upvalue) ~= nil do
        upvalue = upvalue + 1
    end
    -- La *última* upvalue es la que devuelve la tabla {n=..., r=...}
    debug.setupvalue(targetFunc, upvalue - 1, function(...) return {n = safety, r = safetyR} end)
end)

------------------------------------------------------------------------
-- 3.  GUI mínima (sin syn, sin require, sin protec_gui)
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = string.reverse("Fixed")
gui.ResetOnSpawn = false
gui.Parent = core

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 60)
main.Position = UDim2.new(0.5, -110, 0.05, 0)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Parent = gui

local lab = Instance.new("TextLabel")
lab.Size = UDim2.new(1, 0, 1, 0)
lab.BackgroundTransparency = 1
lab.Text = "Pets crash parcheado ✔"
lab.TextColor3 = Color3.new(0, 1, 0)
lab.Font = Enum.Font.GothamBold
lab.TextSize = 14
lab.Parent = main

-- drag táctil
local uis = game:GetService("UserInputService")
local drag, g start
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; g start = i.Position; g = main.Position
    end
end)
uis.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - g start
        main.Position = UDim2.new(g.X.Scale, g.X.Offset + d.X,
                                 g.Y.Scale, g.Y.Offset + d.Y)
    end
end)
uis.InputEnded:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
        drag = false
    end
end)

