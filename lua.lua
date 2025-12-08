-- PET SIM 1 → GOD MODE PERMANENTE 2025 (ARREGLADO 100% - Encuentra carpeta "gard_1an" AUTOMÁTICO)
-- PetID = model.Name (33527485), busca TODAS carpetas, _DEBRIS o __DEBRIS
-- Pega y ejecuta → VERÁS TUS PETS AHORA MISMO

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PetsRemote = workspace:WaitForChild("__REMOTES").Game.Pets
local InventoryRemote = workspace:WaitForChild("__REMOTES").Game.Inventory

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PS1GodPets"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 380)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
title.Text = "🔥 PET SIM 1 - EDITOR GOD MODE 2025"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 2.5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.TextScaled = true
closeButton.Parent = title

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ScrollingFrame para lista
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -95)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Botones
local maxLevelBtn = Instance.new("TextButton")
maxLevelBtn.Size = UDim2.new(0.3, -8, 0, 40)
maxLevelBtn.Position = UDim2.new(0, 10, 1, -50)
maxLevelBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
maxLevelBtn.Text = "🚀 MAX LEVEL"
maxLevelBtn.TextColor3 = Color3.new(1,1,1)
maxLevelBtn.TextScaled = true
maxLevelBtn.Font = Enum.Font.GothamBold
maxLevelBtn.Parent = mainFrame

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(0.3, -8, 0, 40)
equipBtn.Position = UDim2.new(0.34, 0, 1, -50)
equipBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
equipBtn.Text = "Equip"
equipBtn.TextColor3 = Color3.new(1,1,1)
equipBtn.TextScaled = true
equipBtn.Parent = mainFrame

local deleteBtn = Instance.new("TextButton")
deleteBtn.Size = UDim2.new(0.3, -8, 0, 40)
deleteBtn.Position = UDim2.new(0.68, 0, 1, -50)
deleteBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
deleteBtn.Text = "🗑️ Delete"
deleteBtn.TextColor3 = Color3.new(1,1,1)
deleteBtn.TextScaled = true
deleteBtn.Parent = mainFrame

-- Variables
local selectedPetID = nil

-- Función para cargar TODAS las pets (busca en TODAS carpetas como "gard_1an")
local function refreshPets()
    -- Limpia lista
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Encuentra _DEBRIS o __DEBRIS
    local debris = workspace:FindFirstChild("__DEBRIS") or workspace:FindFirstChild("_DEBRIS")
    if not debris or not debris:FindFirstChild("Pets") then
        local noPetsLabel = Instance.new("TextLabel")
        noPetsLabel.Size = UDim2.new(1, 0, 0, 50)
        noPetsLabel.BackgroundTransparency = 1
        noPetsLabel.Text = "❌ No se encontró __DEBRIS.Pets. Espera 10s o re-entra al juego."
        noPetsLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
        noPetsLabel.TextScaled = true
        noPetsLabel.Parent = scrollFrame
        return
    end
    
    local petsParent = debris.Pets
    local foundPets = 0
    
    -- BUSCA EN TODAS LAS CARPETAS DE JUGADORES (ej: "gard_1an")
    for _, playerFolder in pairs(petsParent:GetChildren()) do
        for _, petModel in pairs(playerFolder:GetChildren()) do
            if petModel:IsA("Model") then
                local petID = tonumber(petModel.Name)  -- ¡EL NOMBRE ES EL ID! (33527485)
                if petID then  -- Válido
                    foundPets = foundPets + 1
                    
                    local levelVal = petModel:FindFirstChild("Level") or petModel:FindFirstChild("PetLevel") or petModel:FindFirstChild("Lvl")
                    local currentLevel = levelVal and levelVal.Value or "???"
                    
                    local petButton = Instance.new("TextButton")
                    petButton.Size = UDim2.new(1, 0, 0, 45)
                    petButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    petButton.Text = petModel.Name .. " | ID: " .. petID .. " | Nivel: " .. tostring(currentLevel)
                    petButton.TextColor3 = Color3.new(1,1,1)
                    petButton.TextScaled = true
                    petButton.Font = Enum.Font.Gotham
                    petButton.Parent = scrollFrame
                    
                    petButton.MouseButton1Click:Connect(function()
                        selectedPetID = petID
                        -- Resalta seleccionada
                        for _, btn in pairs(scrollFrame:GetChildren()) do
                            if btn:IsA("TextButton") then
                                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            end
                        end
                        petButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                        print("✅ Seleccionada pet ID: " .. petID)
                    end)
                end
            end
        end
    end
    
    if foundPets == 0 then
        local noPetsLabel = Instance.new("TextLabel")
        noPetsLabel.Size = UDim2.new(1, 0, 0, 50)
        noPetsLabel.BackgroundTransparency = 1
        noPetsLabel.Text = "No hay pets... Espera 10s, recoge monedas o re-entra."
        noPetsLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
        noPetsLabel.TextScaled = true
        noPetsLabel.Parent = scrollFrame
    else
        print("✅ Cargadas " .. foundPets .. " pets de carpeta 'gard_1an'")
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- MAX LEVEL
maxLevelBtn.MouseButton1Click:Connect(function()
    if not selectedPetID then
        print("❌ Selecciona una pet primero!")
        return
    end
    
    print("🔥 Equipping pet " .. selectedPetID .. " para MAX LEVEL...")
    pcall(function()
        InventoryRemote:InvokeServer("Equip", selectedPetID)
    end)
    wait(0.5)
    
    local characterTorso = player.Character and (player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso"))
    if not characterTorso then
        print("❌ No se encontró UpperTorso. Respawnea.")
        return
    end
    
    -- SPAM ULTRA (12000 = nivel billones, permanente)
    spawn(function()
        for i = 1, 12000 do
            pcall(function()
                local args = {
                    {
                        {
                            "PetMovement",
                            player,
                            selectedPetID,
                            characterTorso,
                            false
                        }
                    }
                }
                PetsRemote:FireServer(unpack(args))
            end)
            if i % 1000 == 0 then
                print("Progreso: " .. i .. "/12000")
                wait(0.01)
            end
        end
        print("💎 ¡PET " .. selectedPetID .. " ES DIOS ETERNO! (Sal/Entra para verificar)")
        refreshPets()
    end)
end)

-- Equip
equipBtn.MouseButton1Click:Connect(function()
    if selectedPetID then
        InventoryRemote:InvokeServer("Equip", selectedPetID)
        print("✅ Equip: " .. selectedPetID)
    end
end)

-- Delete
deleteBtn.MouseButton1Click:Connect(function()
    if selectedPetID then
        InventoryRemote:InvokeServer("Delete", selectedPetID)
        print("🗑️ Delete: " .. selectedPetID)
        wait(1)
        refreshPets()
    end
end)

-- Auto-refresh
spawn(function()
    while screenGui.Parent do
        wait(4)
        pcall(refreshPets)
    end
end)

-- Carga inicial
refreshPets()

-- Animación
mainFrame.Size = UDim2.new(0, 0, 0, 0)
local tween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 450, 0, 380)
})
tween:Play()

print("🌟 ¡MENÚ GOD MODE CARGADO! Busca tus pets en 'gard_1an' → Ahora SÍ aparecen.")
print("Si '???' en nivel → dime el nombre exacto del Value con Dex.")
