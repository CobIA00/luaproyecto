--[[
    ManusSpy Ultimate - The Final Remote Spy (Optimización de Rendimiento y Seguridad)
    
    Versión: 4.0.3 (Hotfix: Nil Value Protection & Delta Stability)
    
    Correcciones Aplicadas:
    1. Safe-Call Wrapper: Protege contra errores "attempt to call a nil value".
    2. Robust Polyfills: Verificación estricta de funciones del ejecutor.
    3. Error Silencer mejorado para scripts externos.
]]

local ManusSpy = {
    Version = "4.0.3",
    Settings = {
        IgnoreList = {},
        BlockList = {},
        AutoScroll = true,
        MaxLogs = 200,
        RecordReturnValues = true,
        ShowCallingScript = true,
        ExcludedRemotes = {},
        SilenceConsoleErrors = true,
    },
    Logs = {},
    Hooks = {},
    Queue = {},
}

-- [[ SISTEMA DE PROTECCIÓN CONTRA NIL VALUES ]]
local function safeCall(func, ...)
    if typeof(func) ~= "function" then return end
    local success, result = pcall(func, ...)
    if success then return result end
    return nil
end

-- Inicializar la tabla hash de exclusión
local defaultExcludedRemotes = {
    ["CharacterSoundEvent"] = true,
    ["GetServerTime"] = true,
    ["UpdatePlayerModels"] = true,
    ["SoundEvent"] = true,
    ["PlaySound"] = true,
    ["PetMovement"] = true,
    ["UpdatePet"] = true
}
for name, val in pairs(defaultExcludedRemotes) do
    ManusSpy.Settings.ExcludedRemotes[name] = val
end

-- Services con verificación
local function getService(name)
    local success, service = pcall(game.GetService, game, name)
    return success and service or nil
end

local Players = getService("Players")
local CoreGui = getService("CoreGui")
local RunService = getService("RunService")
local UserInputService = getService("UserInputService")
local LocalPlayer = Players and Players.LocalPlayer
local task = task or { defer = function(f, ...) coroutine.wrap(f)(...) end }

-- Environment Check & Polyfills (ULTRA COMPATIBILIDAD)
local getgenv = (typeof(getgenv) == "function") and getgenv or function() return _G end
local hookmetamethod = hookmetamethod or (syn and syn.hook_metamethod) or (fluxus and fluxus.hook_metamethod)
local getnamecallmethod = getnamecallmethod or (syn and syn.get_namecall_method) or (fluxus and fluxus.get_namecall_method)
local checkcaller = checkcaller or (syn and syn.check_caller) or (fluxus and fluxus.check_caller) or function() return false end
local newcclosure = newcclosure or (syn and syn.new_cclosure) or (fluxus and fluxus.new_cclosure) or function(f) return f end
local hookfunction = hookfunction or (syn and syn.hook_function) or (fluxus and fluxus.hook_function)
local getcallingscript = getcallingscript or (debug and debug.getcallingscript) or function() return "Unknown" end
local setclipboard = setclipboard or (syn and syn.write_clipboard) or (toclipboard) or (fluxus and fluxus.set_clipboard) or function() end

-- Funciones de Introspección con protección
local getupvalue = getupvalue or (debug and debug.getupvalue)
local getconstant = getconstant or (debug and debug.getconstant)
local getinfo = (debug and debug.getinfo) or function() return {} end

-- Utility: Advanced Path Generation
local function getPath(instance)
    if not instance then return "nil" end
    local success, name = pcall(function() return instance.Name end)
    if not success then return "ProtectedInstance" end
    
    if instance == game then return "game" end
    if instance == workspace then return "workspace" end
    if instance == LocalPlayer then return "game:GetService('Players').LocalPlayer" end
    
    local parent
    pcall(function() parent = instance.Parent end)
    
    local isService, service = pcall(function() return game:GetService(instance.ClassName) end)
    if isService and service == instance then
        return 'game:GetService("' .. instance.ClassName .. '")'
    end

    if not parent then
        return 'getnilinstance("' .. name .. '")'
    end
    
    local cleanName = name:gsub('[%w_]', '')
    local head = ""
    if #cleanName > 0 or tonumber(name:sub(1,1)) then
        head = '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]'
    else
        head = "." .. name
    end
    
    return getPath(parent) .. head
end

-- Utility: Advanced Value Serialization
local function serialize(val, visited, indent)
    visited = visited or {}
    indent = indent or 0
    local t = typeof(val)
    local spacing = string.rep("    ", indent)
    
    if t == "string" then
        return '"' .. val:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"'
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(val)
    elseif t == "Instance" then
        return getPath(val)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.3f, %.3f, %.3f)", val.X, val.Y, val.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.3f, %.3f)", val.X, val.Y)
    elseif t == "CFrame" then
        local components = {pcall(function() return val:components() end)}
        if components[1] then
            table.remove(components, 1)
            return "CFrame.new(" .. table.concat(components, ", ") .. ")"
        end
        return "CFrame.new()"
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(val.R*255), math.floor(val.G*255), math.floor(val.B*255))
    elseif t == "UDim2" then
        return string.format("UDim2.new(%.3f, %d, %.3f, %d)", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
    elseif t == "table" then
        if visited[val] then return "{ --[[ Circular ]] }" end
        visited[val] = true
        local str = "{\n"
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if indent > 5 then
                str = str .. spacing .. "    --[[ Depth Limit ]]\n"
                break
            end
            str = str .. spacing .. "    [" .. serialize(k, visited, indent + 1) .. "] = " .. serialize(v, visited, indent + 1) .. ",\n"
            if count > 50 then str = str .. spacing .. "    --[[ Truncated ]]\n" break end
        end
        visited[val] = nil
        return str .. spacing .. "}"
    elseif t == "function" then
        return 'function() --[[ ' .. tostring(val) .. ' ]]'
    else
        return 'nil --[[ ' .. t .. ' ]]'
    end
end

-- Generador de Scripts R2S
local function generateR2S(data)
    local remotePath = getPath(data.Instance)
    local method = data.Method
    local argsCode = serialize(data.Args)
    
    return string.format(
        [[-- Generated by ManusSpy Ultimate v%s
local Remote = %s
local Args = %s
Remote:%s(unpack(Args))]],
        ManusSpy.Version, remotePath, argsCode, method
    )
end

-- Introspección de Funciones
local function getFunctionInfo(func)
    if typeof(func) ~= "function" then return "-- No es una función válida." end
    local info = getinfo(func, "S")
    local output = string.format("-- Función: %s\n-- Fuente: %s\n-- Línea: %d\n", tostring(func), info.source or "C", info.linedefined or 0)
    return output
end

-- Performance: Task Scheduler
local function processQueue()
    if #ManusSpy.Queue > 0 then
        local data = table.remove(ManusSpy.Queue, 1)
        table.insert(ManusSpy.Logs, 1, data)
        if #ManusSpy.Logs > ManusSpy.Settings.MaxLogs then table.remove(ManusSpy.Logs) end
        if ManusSpy.OnLogAdded then pcall(ManusSpy.OnLogAdded, data) end
        task.defer(processQueue)
    end
end

local function scheduleUpdate(data)
    table.insert(ManusSpy.Queue, data)
    if #ManusSpy.Queue == 1 then task.defer(processQueue) end
end

-- Hooking Engine
local function handleRemote(instance, method, args, returnValue)
    if safeCall(checkcaller) then return end
    
    local success, name = pcall(function() return instance.Name end)
    if not success then return end
    
    if ManusSpy.Settings.ExcludedRemotes[name] then return end
    
    local callingScript = safeCall(getcallingscript)
    local scriptPath = typeof(callingScript) == "Instance" and callingScript:GetFullName() or tostring(callingScript)
    
    if scriptPath:find("Pets") or name:lower():find("pet") then return end

    local callingFunc
    pcall(function() callingFunc = getinfo(2, "f").func end)

    local callData = {
        Instance = instance,
        Method = method,
        Args = args,
        ReturnValue = returnValue,
        Script = callingScript,
        CallingFunction = callingFunc,
        Time = os.clock(),
    }
    
    scheduleUpdate(callData)
    return ManusSpy.Settings.BlockList[instance] or ManusSpy.Settings.BlockList[name]
end

-- Namecall Hook con protección extrema
if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if typeof(self) == "Instance" and (method == "FireServer" or method == "InvokeServer") then
            local blocked = false
            pcall(function()
                blocked = handleRemote(self, method, args)
            end)
            if blocked then return end
        end
        
        return oldNamecall(self, ...)
    end))
end

-- Method Hooks
local function hookRemoteMethod(class, methodName)
    if not hookfunction then return end
    local success, proto = pcall(function() return Instance.new(class)[methodName] end)
    if not success then return end
    
    local original
    original = hookfunction(proto, newcclosure(function(self, ...)
        local args = {...}
        local blocked = false
        pcall(function()
            blocked = handleRemote(self, methodName, args)
        end)
        if blocked then return end
        return original(self, ...)
    end))
end

hookRemoteMethod("RemoteEvent", "FireServer")
hookRemoteMethod("RemoteFunction", "InvokeServer")

-- UI Implementation (Simplificada para estabilidad)
local function createUI()
    local success, err = pcall(function()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ManusSpy_Ultimate"
        ScreenGui.ResetOnSpawn = false
        
        local parent = CoreGui
        if getgenv().get_hidden_gui then parent = getgenv().get_hidden_gui()
        elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
        ScreenGui.Parent = parent
        
        local Main = Instance.new("Frame")
        Main.Name = "Main"
        Main.Size = UDim2.new(0, 700, 0, 500)
        Main.Position = UDim2.new(0.5, -350, 0.5, -250)
        Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Main.Active = true
        Main.Draggable = true
        Main.Parent = ScreenGui
        
        local Title = Instance.new("TextLabel")
        Title.Text = "  MANUS SPY ULTIMATE v" .. ManusSpy.Version
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Title.TextColor3 = Color3.fromRGB(0, 255, 150)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 18
        Title.Parent = Main
        
        local LogList = Instance.new("ScrollingFrame")
        LogList.Size = UDim2.new(0, 250, 1, -50)
        LogList.Position = UDim2.new(0, 5, 0, 45)
        LogList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        LogList.Parent = Main
        
        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = LogList
        
        local CodeText = Instance.new("TextBox")
        CodeText.Size = UDim2.new(1, -265, 1, -90)
        CodeText.Position = UDim2.new(0, 260, 0, 45)
        CodeText.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        CodeText.TextColor3 = Color3.fromRGB(220, 220, 220)
        CodeText.ClearTextOnFocus = false
        CodeText.MultiLine = true
        CodeText.Text = "-- Ready. Stability Patches Applied."
        CodeText.Parent = Main

        ManusSpy.OnLogAdded = function(data)
            local remoteName = data.Instance and data.Instance.Name or "Unknown"
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 30)
            Button.Text = " [" .. data.Method:sub(1,1) .. "] " .. remoteName
            Button.Parent = LogList
            Button.MouseButton1Click:Connect(function()
                CodeText.Text = generateR2S(data)
            end)
        end
    end)
    if not success then warn("ManusSpy UI Error: " .. tostring(err)) end
end

createUI()
print("ManusSpy Ultimate v" .. ManusSpy.Version .. " Loaded! Stability Patches Applied.")
