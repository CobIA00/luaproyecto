--// DeltaSpy-Mobile  (GUI flotante + logger + replayer)
--// by 0xDev  |  para Delta Executor (mobile)
if not identifyexecutor or identifyexecutor():find("Delta") == nil then
    return -- silencioso si no es Delta
end

local gui = Instance.new("ScreenGui")
gui.Name = "DSpy"
gui.DisplayOrder = 999
gui.ResetOnSpawn = false
syn.protect_gui(gui) -- oculto de ScreenGui spy del juego
gui.Parent = game:GetService("CoreGui")

local drag,drop do
    local input,dragging,dragInput,dragStart,startPos
    function drag(frame)
        frame.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = inp.Position; startPos = frame.Position
                inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        frame.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = inp
            end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(inp)
            if inp == dragInput and dragging then
                local delta = inp.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                           startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
end

--// UI skeleton
local main = Instance.new("Frame")
main.Size = UDim2.new(0,260,0,160)
main.Position = UDim2.new(0.5,-130,0.2,0)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BorderSizePixel = 0
main.Active = true
main.Selectable = true
drag(main)

local top = Instance.new("TextLabel")
top.Size = UDim2.new(1,0,0,24)
top.BackgroundColor3 = Color3.fromRGB(60,60,60)
top.Text = "  DeltaSpy"
top.TextColor3 = Color3.white
top.Font = Enum.Font.GothamBold
top.TextSize = 14
top.Parent = main

local log = Instance.new("ScrollingFrame")
log.Size = UDim2.new(1,-8,1,-56)
log.Position = UDim2.new(0,4,0,28)
log.BackgroundTransparency = 1
log.ScrollBarThickness = 4
log.CanvasSize = UDim2.new(0,0,0,0)
log.Parent = main

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0,2)
uiList.Parent = log

local function newLine(txt)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,18)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = log
    log.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y)
end

--// Logger core
local reps = game:GetService("ReplicatedStorage")
local Block, Spoof, Record = {}, {}, {}
local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",function(self,...)
    local method = getnamecallmethod()
    if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        local args = {...}
        local compact = table.concat(args," | ")
        newLine(string.format("%s → %s", self.Name, compact))
        if Block[self] then return end
        if Spoof[self] then return table.unpack(Spoof[self]) end
    end
    return oldNamecall(self,...)
end)

--// Grab & replay
local function grab(remote)
    local snap = {}
    local old = remote.FireServer
    remote.FireServer = function(_,...)
        snap = {...}
        newLine("Grabbed "..remote.Name)
        return old(remote,...)
    end
    return function() remote.FireServer = old; return snap end
end

--// Botones
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1,-8,0,24)
bar.Position = UDim2.new(0,4,1,-28)
bar.BackgroundTransparency = 1
bar.Parent = main

local blockBtn = Instance.new("TextButton")
blockBtn.Size = UDim2.new(0.3,0,1,0)
blockBtn.Text = "Block"
blockBtn.BackgroundColor3 = Color3.fromRGB(255,90,90)
blockBtn.Font = Enum.Font.GothamSemibold
blockBtn.TextSize = 12
blockBtn.Parent = bar

local spoofBtn = Instance.new("TextButton")
spoofBtn.Size = UDim2.new(0.3,0,1,0)
spoofBtn.Position = UDim2.new(0.35,0,0,0)
spoofBtn.Text = "Spoof"
spoofBtn.BackgroundColor3 = Color3.fromRGB(90,200,90)
spoofBtn.Font = Enum.Font.GothamSemibold
spoofBtn.TextSize = 12
spoofBtn.Parent = bar

local recBtn = Instance.new("TextButton")
recBtn.Size = UDim2.new(0.3,0,1,0)
recBtn.Position = UDim2.new(0.7,0,0,0)
recBtn.Text = "Grab"
recBtn.BackgroundColor3 = Color3.fromRGB(90,150,255)
recBtn.Font = Enum.Font.GothamSemibold
recBtn.TextSize = 12
recBtn.Parent = bar

--// Logic táctil
blockBtn.MouseButton1Click:Connect(function()
    newLine("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local target = game:GetService("Players").LocalPlayer:GetMouse().Target
            if target and target:IsA("RemoteEvent") then
                Block[target] = true
                newLine("Bloqueado: "..target.Name)
                con:Disconnect()
            end
        end
    end)
    task.wait(3); con:Disconnect()
end)

spoofBtn.MouseButton1Click:Connect(function()
    newLine("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local target = game:GetService("Players").LocalPlayer:GetMouse().Target
            if target and target:IsA("RemoteEvent") then
                Spoof[target] = {"spoofed"} -- cambia a tu gusto
                newLine("Spoofeado: "..target.Name)
                con:Disconnect()
            end
        end
    end)
    task.wait(3); con:Disconnect()
end)

recBtn.MouseButton1Click:Connect(function()
    newLine("Toca un Remote en 3s...")
    local con; con = game:GetService("UserInputService").InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            local target = game:GetService("Players").LocalPlayer:GetMouse().Target
            if target and target:IsA("RemoteEvent") then
                local replay = grab(target)
                task.spawn(function()
                    task.wait(1)
                    local pack = replay()
                    newLine("Replaying "..target.Name)
                    target:FireServer(table.unpack(pack))
                end)
                con:Disconnect()
            end
        end
    end)
    task.wait(3); con:Disconnect()
end)

newLine("DeltaSpy activo – arrastra la ventana")
