-- PET SIM 1 → GOD MODE PERMANENTE 2025 + CONSOLE COPIER
-- Combina el editor de pets con la utilidad para copiar output de consola

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- ================== CONFIGURACIÓN DE CONSOLA ==================
local consoleOutput = {}

-- Interceptar prints para capturarlos
local oldPrint = print
print = function(...)
    local args = {...}
    local str = table.concat(args, "\t")
    oldPrint(...)
    table.insert(consoleOutput, "[PRINT] " .. str)
    if #consoleOutput > 10000 then
        table.remove(consoleOutput, 1)
    end
end

local oldWarn = warn
warn = function(...)
    local args = {...}
    local str = table.concat(args, "\t")
    oldWarn(...)
    table.insert(consoleOutput, "[WARN] " .. str)
    if #consoleOutput > 10000 then
        table.remove(consoleOutput, 1)
    end
end

-- ================== GUI PRINCIPAL ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PS1GodPets"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 450)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = mainFrame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
title.Text = "🔥 PET SIM 1 - GOD MODE + CONSOLE COPIER"
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

-- ================== PESTAÑAS ==================
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 40)
tabsFrame.Position = UDim2.new(0, 10, 0, 50)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local petTab = Instance.new("TextButton")
petTab.Size = UDim2.new(0.5, -5, 1, 0)
petTab.Position = UDim2.new(0, 0, 0, 0)
petTab.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
petTab.Text = "🐉 PET EDITOR"
petTab.TextColor3 = Color3.new(1,1,1)
petTab.Font = Enum.Font.GothamBold
petTab.TextSize = 16
petTab.Parent = tabsFrame

local consoleTab = Instance.new("TextButton")
consoleTab.Size = UDim2.new(0.5, -5, 1, 0)
consoleTab.Position = UDim2.new(0.5, 5, 0, 0)
consoleTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
consoleTab.Text = "📋 CONSOLE COPIER"
consoleTab.TextColor3 = Color3.new(1,1,1)
consoleTab.Font = Enum.Font.GothamBold
consoleTab.TextSize = 16
consoleTab.Parent = tabsFrame

-- ================== CONTENIDO PET EDITOR ==================
local petContent = Instance.new("Frame")
petContent.Size = UDim2.new(1, -20, 1, -135)
petContent.Position = UDim2.new(0, 10, 0, 95)
petContent.BackgroundTransparency = 1
petContent.Visible = true
petContent.Parent = mainFrame

-- ScrollingFrame para lista de pets
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -50)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = petContent

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Botones del pet editor
local maxLevelBtn = Instance.new("TextButton")
maxLevelBtn.Size = UDim2.new(0.32, -6, 0, 40)
maxLevelBtn.Position = UDim2.new(0, 10, 1, -50)
maxLevelBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
maxLevelBtn.Text = "🚀 MAX LEVEL"
maxLevelBtn.TextColor3 = Color3.new(1,1,1)
maxLevelBtn.TextScaled = true
maxLevelBtn.Font = Enum.Font.GothamBold
maxLevelBtn.Parent = petContent

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(0.32, -6, 0, 40)
equipBtn.Position = UDim2.new(0.34, 0, 1, -50)
equipBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
equipBtn.Text = "EQUIP"
equipBtn.TextColor3 = Color3.new(1,1,1)
equipBtn.TextScaled = true
equipBtn.Parent = petContent

local deleteBtn = Instance.new("TextButton")
deleteBtn.Size = UDim2.new(0.32, -6, 0, 40)
deleteBtn.Position = UDim2.new(0.68, 0, 1, -50)
deleteBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
deleteBtn.Text = "🗑️ DELETE"
deleteBtn.TextColor3 = Color3.new(1,1,1)
deleteBtn.TextScaled = true
deleteBtn.Parent = petContent

-- ================== CONTENIDO CONSOLE COPIER ==================
local consoleContent = Instance.new("Frame")
consoleContent.Size = UDim2.new(1, -20, 1, -135)
consoleContent.Position = UDim2.new(0, 10, 0, 95)
consoleContent.BackgroundTransparency = 1
consoleContent.Visible = false
consoleContent.Parent = mainFrame

-- TextBox para consola
local consoleTextBox = Instance.new("TextBox")
consoleTextBox.Size = UDim2.new(1, 0, 1, -60)
consoleTextBox.Position = UDim2.new(0, 0, 0, 0)
consoleTextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
consoleTextBox.TextColor3 = Color3.fromRGB(0, 255, 100)
consoleTextBox.TextXAlignment = Enum.TextXAlignment.Left
consoleTextBox.TextYAlignment = Enum.TextYAlignment.Top
consoleTextBox.MultiLine = true
consoleTextBox.TextWrapped = true
consoleTextBox.ClearTextOnFocus = false
consoleTextBox.Font = Enum.Font.Code
consoleTextBox.TextSize = 14
consoleTextBox.Text = "Esperando salida de consola..."
consoleTextBox.Parent = consoleContent

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, 0, 0, 50)
copyBtn.Position = UDim2.new(0, 0, 1, -50)
copyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
copyBtn.Text = "📋 COPIAR TODO AL PORTAPAPELES"
copyBtn.TextColor3 = Color3.new(1,1,1)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 18
copyBtn.Parent = consoleContent

-- ================== VARIABLES Y FUNCIONES ==================
local selectedPetID = nil
local PetsRemote = workspace:WaitForChild("__REMOTES").Game.Pets
local InventoryRemote = workspace:WaitForChild("__REMOTES").Game.Inventory

-- Función para actualizar consola
local function updateConsole()
    consoleTextBox.Text = table.concat(consoleOutput, "\n")
    consoleTextBox.CursorPosition = #consoleTextBox.Text + 1
end

-- Función para refrescar pets
local function refreshPets()
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local debris = workspace:FindFirstChild("__DEBRIS") or workspace:FindFirstChild("_DEBRIS")
    if not debris or not debris:FindFirstChild("Pets") then
        local noPetsLabel = Instance.new("TextLabel")
        noPetsLabel.Size = UDim2.new(1, 0, 0, 50)
        noPetsLabel.BackgroundTransparency = 1
        noPetsLabel.Text = "❌ No se encontró __DEBRIS.Pets. Espera 10s o re-entra."
        noPetsLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
        noPetsLabel.TextScaled = true
        noPetsLabel.Parent = scrollFrame
        return
    end
    
    local petsParent = debris.Pets
    local foundPets = 0
    
    for _, playerFolder in pairs(petsParent:GetChildren()) do
        for _, petModel in pairs(playerFolder:GetChildren()) do
            if petModel:IsA("Model") then
                local petID = tonumber(petModel.Name)
                if petID then
                    foundPets = foundPets + 1
                    
                    local levelVal = petModel:FindFirstChild("Level") or petModel:FindFirstChild("PetLevel") or petModel:FindFirstChild("Lvl")
                    local currentLevel = levelVal and levelVal.Value or "???"
                    
                    local petButton = Instance.new("TextButton")
                    petButton.Size = UDim2.new(1, 0, 0, 45)
                    petButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    petButton.Text = "ID: " .. petID .. " | Nivel: " .. tostring(currentLevel)
                    petButton.TextColor3 = Color3.new(1,1,1)
                    petButton.TextScaled = true
                    petButton.Font = Enum.Font.Gotham
                    petButton.Parent = scrollFrame
                    
                    petButton.MouseButton1Click:Connect(function()
                        selectedPetID = petID
                        for _, btn in pairs(scrollFrame:GetChildren()) do
                            if btn:IsA("TextButton") then
                                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            end
                        end
                        petButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                        print("✅ Pet seleccionada: " .. petID)
                    end)
                end
            end
        end
    end
    
    if foundPets == 0 then
        local noPetsLabel = Instance.new("TextLabel")
        noPetsLabel.Size = UDim2.new(1, 0, 0, 50)
        noPetsLabel.BackgroundTransparency = 1
        noPetsLabel.Text = "No hay pets... Espera 10s o recoge monedas."
        noPetsLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
        noPetsLabel.TextScaled = true
        noPetsLabel.Parent = scrollFrame
    else
        print("✅ " .. foundPets .. " pets encontradas")
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- ================== EVENTOS DE BOTONES ==================
-- Cambiar pestañas
petTab.MouseButton1Click:Connect(function()
    petContent.Visible = true
    consoleContent.Visible = false
    petTab.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    consoleTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
end)

consoleTab.MouseButton1Click:Connect(function()
    petContent.Visible = false
    consoleContent.Visible = true
    petTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    consoleTab.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    updateConsole()
end)

-- Botón MAX LEVEL
maxLevelBtn.MouseButton1Click:Connect(function()
    if not selectedPetID then
        print("❌ Selecciona una pet primero!")
        return
    end
    
    print("🔥 Aplicando MAX LEVEL a pet " .. selectedPetID .. "...")
    pcall(function()
        InventoryRemote:InvokeServer("Equip", selectedPetID)
    end)
    wait(0.5)
    
    local characterTorso = player.Character and (player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso"))
    if not characterTorso then
        print("❌ No se encontró UpperTorso. Respawnea.")
        return
    end
    
    spawn(function()
        for i = 1, 12000 do
            pcall(function()
                local args = {{
                    {
                        "PetMovement",
                        player,
                        selectedPetID,
                        characterTorso,
                        false
                    }
                }}
                PetsRemote:FireServer(unpack(args))
            end)
            if i % 1000 == 0 then
                print("Progreso: " .. i .. "/12000")
                wait(0.01)
            end
        end
        print("💎 ¡PET " .. selectedPetID .. " ES DIOS ETERNO!")
        refreshPets()
    end)
end)

-- Botón EQUIP
equipBtn.MouseButton1Click:Connect(function()
    if selectedPetID then
        InventoryRemote:InvokeServer("Equip", selectedPetID)
        print("✅ Pet equipada: " .. selectedPetID)
    end
end)

-- Botón DELETE
deleteBtn.MouseButton1Click:Connect(function()
    if selectedPetID then
        InventoryRemote:InvokeServer("Delete", selectedPetID)
        print("🗑️ Pet eliminada: " .. selectedPetID)
        wait(1)
        refreshPets()
    end
end)

-- Botón COPIAR CONSOLA
copyBtn.MouseButton1Click:Connect(function()
    local fullText = table.concat(consoleOutput, "\n")
    if setclipboard then
        setclipboard(fullText)
        copyBtn.Text = "✅ COPIADO ("..#consoleOutput.." líneas)"
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 0)
        print("✅ Consola copiada al portapapeles ("..#consoleOutput.." líneas)")
        wait(1.5)
        copyBtn.Text = "📋 COPIAR TODO AL PORTAPAPELES"
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    else
        print("❌ Función setclipboard no disponible")
    end
end)

-- ================== INICIALIZACIÓN ==================
-- Auto-refresh de pets
spawn(function()
    while screenGui.Parent do
        wait(4)
        pcall(refreshPets)
        if consoleContent.Visible then
            updateConsole()
        end
    end
end)

-- Carga inicial
refreshPets()

-- Animación de entrada
mainFrame.Size = UDim2.new(0, 0, 0, 0)
local tween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 500, 0, 450)
})
tween:Play()

print("🌟 PET SIM 1 - GOD MODE + CONSOLE COPIER CARGADO!")
print("💡 Usa las pestañas para cambiar entre editor de pets y visor de consola")
print("📋 Todo lo que se imprima en consola se capturará automáticamente")
