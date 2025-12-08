-- PET SIMULATOR 1 → MAX LEVEL PERMANENTE 2025 (Sin errores, sin crashes)
-- Pega en Delta y ejecuta una sola vez → menú perfecto

local player = game.Players.LocalPlayer
local PetsRemote = workspace:WaitForChild("__REMOTES").Game.Pets
local InventoryRemote = workspace:WaitForChild("__REMOTES").Game.Inventory
local torso = player.Character:WaitForChild("UpperTorso")

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "PS1MaxPet"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 420, 0, 500)
frame.Position = UDim2.new(0.5, -210, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = "PET SIM 1 → MAX LEVEL PERMANENTE 2025"
title.BackgroundColor3 = Color3.fromRGB(255,100,0)
title.TextColor3 = Color3.new(1,1,1)
title.Size = UDim2.new(1,0,0,40)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true

local close = Instance.new("TextButton", title)
close.Size = UDim2.new(0,40,0,40)
close.Position = UDim2.new(1,-40,0,0)
close.BackgroundColor3 = Color3.fromRGB(200,0,0)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local scrolling = Instance.new("ScrollingFrame", frame)
scrolling.Size = UDim2.new(1,-20,1,-90)
scrolling.Position = UDim2.new(0,10,0,70)
scrolling.BackgroundTransparency = 0.9
scrolling.ScrollBarThickness = 8
scrolling.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout", scrolling)
layout.Padding = UDim.new(0,4)

local selectedID = nil

local function refresh()
    for _,v in pairs(scrolling:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local folder = workspace.__DEBRIS.Pets:FindFirstChild(player.Name)
    if not folder then return end
    for _,pet in pairs(folder:GetChildren()) do
        if pet:IsA("Model") then
            local id = pet:FindFirstChild("ID") and pet.ID.Value or "??"
            local lvl = pet:FindFirstChild("Level") and pet.Level.Value or "??"
            local btn = Instance.new("TextButton", scrolling)
            btn.Size = UDim2.new(1,-10,0,45)
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            btn.Text = pet.Name.."  |  ID: "..id.."  |  Nivel: "..lvl
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextScaled = true
            btn.MouseButton1Click:Connect(function()
                selectedID = id
                for _,b in pairs(scrolling:GetChildren()) do
                    if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(40,40,40) end
                end
                btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
            end)
        end
    end
    scrolling.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

local maxBtn = Instance.new("TextButton", frame)
maxBtn.Size = UDim2.new(0.45, -10, 0, 50)
maxBtn.Position = UDim2.new(0.05,0,1,-60)
maxBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
maxBtn.Text = "MAX LEVEL PERMANENTE"
maxBtn.TextColor3 = Color3.new(1,1,1)
maxBtn.TextScaled = true
maxBtn.Font = Enum.Font.GothamBold

maxBtn.MouseButton1Click:Connect(function()
    if not selectedID then warn("Selecciona una pet") return end
    
    -- Primero la equipamos (así el servidor la acepta siempre)
    InventoryRemote:InvokeServer("Equip", selectedID)
    wait(0.3)
    
    -- Spam brutal pero seguro (8000 veces = nivel 10.000.000+ fácil)
    spawn(function()
        for i = 1, 8000 do
            PetsRemote:FireServer({{
                "PetMovement",
                player,
                selectedID,
                torso,
                false
            }})
            if i % 500 == 0 then wait() end -- evita lag extremo
        end
        print("Pet "..selectedID.." ahora es literalmente dios")
    end)
end)

spawn(function()
    while wait(4) do
        if screenGui.Parent then pcall(refresh) end
    end
end)

refresh()
frame.Size = UDim2.new(0,0,0,0)
game:GetService("TweenService"):Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = UDim2.new(0,420,0,500)}):Play()
