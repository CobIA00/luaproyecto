-- Pet Simulator 1 EXP & Level Up Script
-- Optimizado para Delta Executor
-- Creado por Manus

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variables de Control
local _G = getgenv and getgenv() or _G
_G.ExpFarmActive = false

-- Intentar localizar la Librería y los Remotos
local Library = nil
local Remotes = nil

local function GetLibrary()
    local success, result = pcall(function()
        return require(LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Library"))
    end)
    if success then
        Library = result
        Remotes = Library.Remotes
    end
end

GetLibrary()

-- Interfaz Gráfica (GUI)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local MinimizeBtn = Instance.new("TextButton")
local CloseBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "PetSimExpMenu"
ScreenGui.Parent = (gethui and gethui()) or (game:GetService("CoreGui"))
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "PET SIM 1 EXP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
ToggleBtn.Font = Enum.Font.SourceSans
ToggleBtn.Text = "ENCENDER"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 18

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.65, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.Text = "Estado: Apagado"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14

MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = MainFrame
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(0.75, -25, 0, 0)
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20

CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18

-- Lógica de Minimizar
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 180, 0, 25), "Out", "Quad", 0.3, true)
        ToggleBtn.Visible = false
        StatusLabel.Visible = false
        MinimizeBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 180, 0, 130), "Out", "Quad", 0.3, true)
        ToggleBtn.Visible = true
        StatusLabel.Visible = true
        MinimizeBtn.Text = "-"
    end
end)

-- Lógica de Cerrar
CloseBtn.MouseButton1Click:Connect(function()
    _G.ExpFarmActive = false
    ScreenGui:Destroy()
end)

-- Lógica de Farm de EXP
local function StartExpFarm()
    task.spawn(function()
        while _G.ExpFarmActive do
            if not Remotes then GetLibrary() end
            
            if Remotes and Remotes.Coins then
                -- Buscamos monedas cercanas para "minar" y ganar EXP
                local coinsFolder = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Coins")
                if coinsFolder then
                    local coins = coinsFolder:GetChildren()
                    if #coins > 0 then
                        -- Seleccionamos una moneda al azar o la más cercana
                        local targetCoin = coins[math.random(1, #coins)]
                        
                        -- Obtenemos tus mascotas equipadas
                        local myPets = {}
                        -- En PS1 las mascotas suelen estar en una carpeta del jugador o en el workspace
                        -- Intentamos encontrarlas por el nombre del jugador
                        for _, v in pairs(workspace.__DEBRIS.Pets:GetChildren()) do
                            if v.Name == LocalPlayer.Name or v:FindFirstChild(LocalPlayer.Name) then
                                table.insert(myPets, v.Name)
                            end
                        end
                        
                        -- Si no encontramos mascotas en el workspace, intentamos vía Library
                        if #myPets == 0 and Library and Library.GetEquippedPets then
                            myPets = Library.GetEquippedPets()
                        end

                        -- Spameamos el evento de minado para ganar EXP
                        for _, petId in pairs(myPets) do
                            if not _G.ExpFarmActive then break end
                            -- El evento "Mine" es el que otorga EXP al procesar el daño
                            Remotes.Coins:FireServer("Mine", targetCoin.Name, petId)
                        end
                    end
                end
            end
            task.wait(0.1) -- Pequeña espera para evitar lag excesivo
        end
    end)
end

-- Lógica del Botón Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    _G.ExpFarmActive = not _G.ExpFarmActive
    if _G.ExpFarmActive then
        ToggleBtn.Text = "APAGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        StatusLabel.Text = "Estado: FARMEANDO EXP..."
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        StartExpFarm()
    else
        ToggleBtn.Text = "ENCENDER"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        StatusLabel.Text = "Estado: Apagado"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

print("Manus Pet Sim 1 Script Cargado con Éxito")
