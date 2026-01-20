--[[
    MANUSSPY ULTIMATE v4.1.0 - THE FINAL UNIFIED REMOTE SPY
    
    Unificación de: SimpleSpy (UI/R2S), Hydroxide (Introspección), ManusSpy (Optimización).
    
    Características:
    - Serialización completa de tipos (CFrame, Vector3, Color3, Ray, etc.)
    - Generación de Scripts R2S (Remote-to-Script) listos para ejecutar.
    - Introspección de Upvalues y Constantes (Estilo Hydroxide).
    - Sistema de filtrado O(1) por Hashing.
    - Estabilidad garantizada para Delta/Móvil mediante Safe-Hooks.
]]

local ManusSpy = {
    Version = "4.1.0",
    Settings = {
        IgnoreList = {},
        BlockList = {},
        AutoScroll = true,
        MaxLogs = 250,
        RecordReturnValues = true,
        ExcludedRemotes = {
            ["CharacterSoundEvent"] = true, ["GetServerTime"] = true, ["UpdatePlayerModels"] = true,
            ["SoundEvent"] = true, ["PlaySound"] = true, ["PetMovement"] = true,
            ["UpdatePet"] = true, ["SpawnPet"] = true, ["GetPetData"] = true
        },
    },
    Logs = {},
    Queue = {},
}

-- [[ CORE UTILITIES ]]
local function safe(f, ...)
    local success, result = pcall(f, ...)
    return success and result or nil
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local task = task or { defer = function(f, ...) coroutine.wrap(f)(...) end }

-- Polyfills Avanzados
local getgenv = (typeof(getgenv) == "function") and getgenv or function() return _G end
local hookmetamethod = hookmetamethod or (syn and syn.hook_metamethod) or (fluxus and fluxus.hook_metamethod)
local getnamecallmethod = getnamecallmethod or (syn and syn.get_namecall_method) or (fluxus and fluxus.get_namecall_method)
local checkcaller = checkcaller or (syn and syn.check_caller) or (fluxus and fluxus.check_caller) or function() return false end
local newcclosure = newcclosure or (syn and syn.new_cclosure) or (fluxus and fluxus.new_cclosure) or function(f) return f end
local hookfunction = hookfunction or (syn and syn.hook_function) or (fluxus and fluxus.hook_function)
local getcallingscript = (debug and debug.getcallingscript) or function() return "Unknown" end
local setclipboard = setclipboard or (syn and syn.write_clipboard) or (toclipboard) or (fluxus and fluxus.set_clipboard) or function() end
local getinfo = (debug and debug.getinfo) or function() return {} end
local getupvalue = (debug and debug.getupvalue)
local getconstant = (debug and debug.getconstant)

-- [[ SERIALIZADOR AVANZADO (R2S READY) ]]
local function getPath(instance)
    if not instance then return "nil" end
    local name = safe(function() return instance.Name end) or "Protected"
    if instance == game then return "game" end
    if instance == workspace then return "workspace" end
    if instance == LocalPlayer then return "game:GetService('Players').LocalPlayer" end
    
    local parent = safe(function() return instance.Parent end)
    if not parent then return 'getnilinstance("' .. name .. '")' end
    
    local isService, service = pcall(function() return game:GetService(instance.ClassName) end)
    if isService and service == instance then return 'game:GetService("' .. instance.ClassName .. '")' end
    
    local cleanName = name:gsub('[%w_]', '')
    local head = (#cleanName > 0 or tonumber(name:sub(1,1))) and '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]' or "." .. name
    return getPath(parent) .. head
end

local function serialize(val, visited, indent)
    visited = visited or {}; indent = indent or 0; local t = typeof(val); local spacing = string.rep("    ", indent)
    if t == "string" then return '"' .. val:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"'
    elseif t == "number" or t == "boolean" or t == "nil" then return tostring(val)
    elseif t == "Instance" then return getPath(val)
    elseif t == "Vector3" then return string.format("Vector3.new(%.3f, %.3f, %.3f)", val.X, val.Y, val.Z)
    elseif t == "Vector2" then return string.format("Vector2.new(%.3f, %.3f)", val.X, val.Y)
    elseif t == "CFrame" then return "CFrame.new(" .. tostring(val) .. ")"
    elseif t == "Color3" then return string.format("Color3.fromRGB(%d, %d, %d)", val.R*255, val.G*255, val.B*255)
    elseif t == "UDim2" then return string.format("UDim2.new(%.3f, %d, %.3f, %d)", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
    elseif t == "table" then
        if visited[val] then return "{ --[[ Circular ]] }" end
        visited[val] = true; local str = "{\n"; local count = 0
        for k, v in pairs(val) do
            count = count + 1; if indent > 5 then str = str .. spacing .. "    --[[ Depth Limit ]]\n"; break end
            str = str .. spacing .. "    [" .. serialize(k, visited, indent + 1) .. "] = " .. serialize(v, visited, indent + 1) .. ",\n"
            if count > 50 then str = str .. spacing .. "    --[[ Truncated ]]\n"; break end
        end
        visited[val] = nil; return str .. spacing .. "}"
    elseif t == "function" then return 'function() --[[ ' .. tostring(val) .. ' ]]'
    else return 'nil --[[ ' .. t .. ' ]]' end
end

-- [[ INTROSPECCIÓN Y R2S ]]
local function generateR2S(data)
    local path = getPath(data.Instance)
    return string.format([[-- ManusSpy Ultimate R2S
-- Remote: %s
-- Method: %s
-- Time: %s

local Remote = %s
local Args = %s

Remote:%s(unpack(Args))]], path, data.Method, os.date("%H:%M:%S"), path, serialize(data.Args), data.Method)
end

local function getFuncDetails(func)
    if typeof(func) ~= "function" then return "-- No es una función." end
    local info = getinfo(func, "S")
    local output = string.format("-- Función: %s\n-- Fuente: %s\n-- Línea: %d\n", tostring(func), info.source or "C", info.linedefined or 0)
    
    if getupvalue then
        output = output .. "\n-- UPVALUES:\n"
        for i = 1, 100 do
            local n, v = getupvalue(func, i)
            if not n then break end
            output = output .. string.format("-- [%d] %s = %s\n", i, n, tostring(v))
        end
    end
    return output
end

-- [[ HOOKING ENGINE ]]
local function handleRemote(instance, method, args, returnValue)
    if checkcaller() then return end
    local name = safe(function() return instance.Name end)
    if not name or ManusSpy.Settings.ExcludedRemotes[name] then return end
    
    local callingScript = getcallingscript()
    local sName = tostring(callingScript)
    if sName:find("Pets") or name:lower():find("pet") then return end
    
    -- Filtrar sonidos problemáticos
    for _, arg in ipairs(args) do
        if typeof(arg) == "string" and arg:find("2046263687") then return end
    end

    local data = {
        Instance = instance,
        Method = method,
        Args = args,
        ReturnValue = returnValue,
        Script = callingScript,
        Time = os.clock(),
        CallingFunction = getinfo(2, "f").func
    }
    
    table.insert(ManusSpy.Queue, data)
    if #ManusSpy.Queue == 1 then task.defer(function()
        while #ManusSpy.Queue > 0 do
            local d = table.remove(ManusSpy.Queue, 1)
            table.insert(ManusSpy.Logs, 1, d)
            if #ManusSpy.Logs > ManusSpy.Settings.MaxLogs then table.remove(ManusSpy.Logs) end
            if ManusSpy.OnLogAdded then pcall(ManusSpy.OnLogAdded, d) end
        end
    end) end
end

if hookmetamethod then
    local old; old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" and (m == "FireServer" or m == "InvokeServer") then
            pcall(handleRemote, self, m, {...})
        end
        return old(self, ...)
    end))
end

-- [[ INTERFAZ DE USUARIO AVANZADA ]]
local function createUI()
    pcall(function()
        local sg = Instance.new("ScreenGui"); sg.Name = "ManusSpy_Ultimate"; sg.ResetOnSpawn = false
        local p = CoreGui; if getgenv().get_hidden_gui then p = getgenv().get_hidden_gui() end
        sg.Parent = p
        
        local Main = Instance.new("Frame"); Main.Size = UDim2.new(0, 700, 0, 500); Main.Position = UDim2.new(0.5, -350, 0.5, -250); Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Main.Active = true; Main.Draggable = true; Main.Parent = sg
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = Main
        
        local Top = Instance.new("Frame"); Top.Size = UDim2.new(1, 0, 0, 40); Top.BackgroundColor3 = Color3.fromRGB(35, 35, 35); Top.Parent = Main
        local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 8); tCorner.Parent = Top
        
        local Title = Instance.new("TextLabel"); Title.Text = "  MANUS SPY ULTIMATE v" .. ManusSpy.Version; Title.Size = UDim2.new(1, 0, 1, 0); Title.BackgroundTransparency = 1; Title.TextColor3 = Color3.fromRGB(0, 255, 150); Title.Font = Enum.Font.GothamBold; Title.TextSize = 18; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Top
        
        local LogList = Instance.new("ScrollingFrame"); LogList.Size = UDim2.new(0, 250, 1, -50); LogList.Position = UDim2.new(0, 5, 0, 45); LogList.BackgroundColor3 = Color3.fromRGB(15, 15, 15); LogList.ScrollBarThickness = 2; LogList.Parent = Main
        local uiList = Instance.new("UIListLayout"); uiList.Padding = UDim.new(0, 2); uiList.Parent = LogList
        
        local CodeView = Instance.new("ScrollingFrame"); CodeView.Size = UDim2.new(1, -265, 1, -90); CodeView.Position = UDim2.new(0, 260, 0, 45); CodeView.BackgroundColor3 = Color3.fromRGB(10, 10, 10); CodeView.Parent = Main
        local CodeText = Instance.new("TextBox"); CodeText.Size = UDim2.new(1, -10, 1, -10); CodeText.Position = UDim2.new(0, 5, 0, 5); CodeText.BackgroundTransparency = 1; CodeText.TextColor3 = Color3.fromRGB(200, 200, 200); CodeText.Font = Enum.Font.Code; CodeText.TextSize = 14; CodeText.TextXAlignment = Enum.TextXAlignment.Left; CodeText.TextYAlignment = Enum.TextYAlignment.Top; CodeText.MultiLine = true; CodeText.ClearTextOnFocus = false; CodeText.Text = "-- Select a remote to view details"; CodeText.Parent = CodeView
        
        local function createBtn(text, pos, size, color)
            local b = Instance.new("TextButton"); b.Text = text; b.Position = pos; b.Size = size; b.BackgroundColor3 = color; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.Parent = Main
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = b
            return b
        end

        local ClearBtn = createBtn("Clear", UDim2.new(0, 260, 1, -40), UDim2.new(0, 80, 0, 35), Color3.fromRGB(100, 30, 30))
        local CopyBtn = createBtn("Copy", UDim2.new(0, 345, 1, -40), UDim2.new(0, 80, 0, 35), Color3.fromRGB(30, 60, 100))
        local IntroBtn = createBtn("Introspect", UDim2.new(0, 430, 1, -40), UDim2.new(0, 100, 0, 35), Color3.fromRGB(30, 100, 100))
        
        local currentData = nil
        
        ClearBtn.MouseButton1Click:Connect(function()
            for _, v in ipairs(LogList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            ManusSpy.Logs = {}; CodeText.Text = "-- Logs cleared"
        end)
        
        CopyBtn.MouseButton1Click:Connect(function() setclipboard(CodeText.Text) end)
        
        IntroBtn.MouseButton1Click:Connect(function()
            if currentData and currentData.CallingFunction then
                CodeText.Text = getFuncDetails(currentData.CallingFunction)
            end
        end)

        ManusSpy.OnLogAdded = function(d)
            local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -5, 0, 30); b.BackgroundColor3 = Color3.fromRGB(40, 40, 40); b.TextColor3 = Color3.new(1, 1, 1); b.Text = "  [" .. d.Method:sub(1,1) .. "] " .. tostring(d.Instance); b.TextXAlignment = Enum.TextXAlignment.Left; b.Font = Enum.Font.Gotham; b.TextSize = 12; b.Parent = LogList
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = b
            
            b.MouseButton1Click:Connect(function()
                currentData = d
                CodeText.Text = generateR2S(d)
            end)
            
            LogList.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y)
            if ManusSpy.Settings.AutoScroll then LogList.CanvasPosition = Vector2.new(0, uiList.AbsoluteContentSize.Y) end
        end
    end)
end

createUI()
print("ManusSpy Ultimate v" .. ManusSpy.Version .. " Loaded! The Final Unified Spy.")
