-- Delta Console Logger
-- Script compatible con Delta Executor para Roblox

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Crear ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaConsoleLogger"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proteger el GUI (compatible con Delta)
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
elseif gethui then
    screenGui.Parent = gethui()
else
    screenGui.Parent = CoreGui
end

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = screenGui

-- Sombra
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = 0
shadow.Image = "rbxasset://textures/ui/Shadow.png"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = mainFrame

-- Corner para el frame principal
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

-- Fix para que solo la parte superior tenga esquinas redondeadas
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -200, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "🎮 Delta Console Logger"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Contador de logs
local logCounter = Instance.new("TextLabel")
logCounter.Name = "LogCounter"
logCounter.Size = UDim2.new(0, 80, 1, 0)
logCounter.Position = UDim2.new(1, -190, 0, 0)
logCounter.BackgroundTransparency = 1
logCounter.Font = Enum.Font.GothamBold
logCounter.Text = "(0 logs)"
logCounter.TextColor3 = Color3.fromRGB(200, 200, 200)
logCounter.TextSize = 12
logCounter.Parent = header

-- Contenedor de botones
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0, 150, 1, 0)
buttonContainer.Position = UDim2.new(1, -160, 0, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = header

-- Función para crear botones del header
local function createHeaderButton(name, text, position, color, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = position
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 60)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Parent = buttonContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 80)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color or Color3.fromRGB(50, 50, 60)}):Play()
    end)
    
    return btn
end

-- Variables de estado
local logs = {}
local isMinimized = false
local originalSize = mainFrame.Size

-- Contenedor de logs
local logContainer = Instance.new("ScrollingFrame")
logContainer.Name = "LogContainer"
logContainer.Size = UDim2.new(1, -20, 1, -90)
logContainer.Position = UDim2.new(0, 10, 0, 50)
logContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
logContainer.BorderSizePixel = 0
logContainer.ScrollBarThickness = 6
logContainer.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
logContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
logContainer.Parent = mainFrame

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logContainer

-- Layout para los logs
local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 5)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logContainer

-- Botón Clear (Limpiar)
local clearBtn = createHeaderButton("ClearBtn", "🗑️", UDim2.new(0, 0, 0.5, -15), Color3.fromRGB(220, 53, 69), function()
    for _, child in ipairs(logContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    logs = {}
    logCounter.Text = "(0 logs)"
end)

-- Botón Copy All
local copyBtn = createHeaderButton("CopyBtn", "📋", UDim2.new(0, 35, 0.5, -15), Color3.fromRGB(40, 167, 69), function()
    local allText = ""
    for i, log in ipairs(logs) do
        allText = allText .. log .. "\n"
    end
    
    if setclipboard then
        setclipboard(allText)
        copyBtn.Text = "✓"
        wait(1)
        copyBtn.Text = "📋"
    else
        warn("setclipboard no está disponible en este executor")
    end
end)

-- Botón Minimize/Maximize
local minimizeBtn = createHeaderButton("MinimizeBtn", "−", UDim2.new(0, 70, 0.5, -15), Color3.fromRGB(255, 193, 7), function()
    isMinimized = not isMinimized
    
    if isMinimized then
        originalSize = mainFrame.Size
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 400, 0, 40)}):Play()
        logContainer.Visible = false
        minimizeBtn.Text = "□"
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = originalSize}):Play()
        wait(0.3)
        logContainer.Visible = true
        minimizeBtn.Text = "−"
    end
end)

-- Botón Close
local closeBtn = createHeaderButton("CloseBtn", "✕", UDim2.new(0, 105, 0.5, -15), Color3.fromRGB(220, 53, 69), function()
    screenGui:Destroy()
end)

-- Hacer el frame draggable
local dragging = false
local dragInput, mousePos, framePos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale, 
            framePos.X.Offset + delta.X,
            framePos.Y.Scale, 
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Función para añadir un log
local function addLog(logType, message)
    local timestamp = os.date("%H:%M:%S")
    local logText = string.format("[%s] [%s] %s", timestamp, logType:upper(), tostring(message))
    table.insert(logs, logText)
    
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, -10, 0, 0)
    logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    logFrame.BorderSizePixel = 0
    logFrame.AutomaticSize = Enum.AutomaticSize.Y
    logFrame.Parent = logContainer
    
    local logFrameCorner = Instance.new("UICorner")
    logFrameCorner.CornerRadius = UDim.new(0, 6)
    logFrameCorner.Parent = logFrame
    
    -- Barra de color según el tipo
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BorderSizePixel = 0
    colorBar.Parent = logFrame
    
    if logType == "error" then
        colorBar.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    elseif logType == "warn" then
        colorBar.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    elseif logType == "info" then
        colorBar.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
    else
        colorBar.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
    end
    
    local logLabel = Instance.new("TextLabel")
    logLabel.Size = UDim2.new(1, -15, 1, 0)
    logLabel.Position = UDim2.new(0, 10, 0, 0)
    logLabel.BackgroundTransparency = 1
    logLabel.Font = Enum.Font.Code
    logLabel.Text = logText
    logLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    logLabel.TextSize = 12
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Top
    logLabel.TextWrapped = true
    logLabel.AutomaticSize = Enum.AutomaticSize.Y
    logLabel.Parent = logFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = logFrame
    
    -- Actualizar canvas size
    logContainer.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10)
    logContainer.CanvasPosition = Vector2.new(0, logLayout.AbsoluteContentSize.Y)
    
    -- Actualizar contador
    logCounter.Text = string.format("(%d logs)", #logs)
end

-- Interceptar console.log, warn, error
local oldPrint = print
local oldWarn = warn
local oldError = error

print = function(...)
    local args = {...}
    local message = table.concat(args, " ")
    addLog("log", message)
    return oldPrint(...)
end

warn = function(...)
    local args = {...}
    local message = table.concat(args, " ")
    addLog("warn", message)
    return oldWarn(...)
end

error = function(...)
    local args = {...}
    local message = table.concat(args, " ")
    addLog("error", message)
    return oldError(...)
end

-- Log inicial
print("🎮 Delta Console Logger inicializado correctamente")
print("📝 Todos los logs de print(), warn() y error() serán capturados")
print("✨ Compatible con Delta Executor")

-- Mensaje de bienvenida
addLog("info", "Sistema de logs iniciado - Delta Compatible")
addLog("info", "Usa los botones del header para controlar la ventana")
