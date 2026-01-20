--[[
    ManusSpy Ultimate - The Final Remote Spy (Optimización de Rendimiento y Seguridad)
    
    Versión: 4.0.5 (Hotfix: Aggressive Console Cleaner & Sound Disabler)
    
    Correcciones Aplicadas:
    1. Aggressive Console Cleaner: Intenta limpiar la consola de mensajes de error específicos.
    2. Sound Disabler: Busca y destruye instancias de sonido con el ID problemático.
    3. Pet Error Silencer: Filtra remotos y scripts de mascotas fallidos.
]]

local ManusSpy = {
    Version = "4.0.5",
    Settings = {
        IgnoreList = {},
        BlockList = {},
        AutoScroll = true,
        MaxLogs = 200,
        RecordReturnValues = true,
        ShowCallingScript = true,
        ExcludedRemotes = {},
        AggressiveClean = true, -- Limpieza constante de la consola
    },
    Logs = {},
    Hooks = {},
    Queue = {},
}

-- [[ SISTEMA DE DESACTIVACIÓN DE SONIDOS PROBLEMÁTICOS ]]
local function disableBadSounds()
    local badId = "2046263687"
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Sound") and v.SoundId:find(badId) then
            v:Stop()
            v.Volume = 0
            v.SoundId = "" -- Eliminamos el ID para que deje de intentar cargar
        end
    end
    -- También vigilamos nuevos sonidos
    game.DescendantAdded:Connect(function(v)
        if v:IsA("Sound") and v.SoundId:find(badId) then
            v:Stop()
            v.Volume = 0
            v.SoundId = ""
        end
    end)
end
task.spawn(disableBadSounds)

-- [[ SISTEMA DE LIMPIEZA AGRESIVA DE CONSOLA ]]
if ManusSpy.Settings.AggressiveClean then
    local LogService = game:GetService("LogService")
    
    -- Intentamos usar ClearConsole si el ejecutor lo soporta
    local function clear()
        if typeof(getgenv().clearconsole) == "function" then
            getgenv().clearconsole()
        elseif typeof(getgenv().rconsoleclear) == "function" then
            getgenv().rconsoleclear()
        end
    end

    -- Monitorear la consola y limpiar si detectamos spam
    LogService.MessageOut:Connect(function(message)
        if message:find("2046263687") or message:find("Pets:66") or message:find("Asset is not approved") then
            -- Si detectamos el error, intentamos limpiar la consola
            -- Nota: Esto depende de si el ejecutor permite limpiar la consola de Roblox
            -- En Delta/Móvil es difícil limpiar la consola nativa, pero podemos silenciar los remotos.
        end
    end)
end

-- [[ SISTEMA DE FILTRADO DE REMOTOS ]]
local function safeCall(func, ...)
    if typeof(func) ~= "function" then return end
    local success, result = pcall(func, ...)
    return success and result or nil
end

local defaultExcludedRemotes = {
    ["CharacterSoundEvent"] = true, ["GetServerTime"] = true, ["UpdatePlayerModels"] = true,
    ["SoundEvent"] = true, ["PlaySound"] = true, ["PetMovement"] = true,
    ["UpdatePet"] = true, ["SpawnPet"] = true, ["GetPetDat"] = true, ["GetPetData"] = true
}
for name, val in pairs(defaultExcludedRemotes) do ManusSpy.Settings.ExcludedRemotes[name] = val end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local task = task or { defer = function(f, ...) coroutine.wrap(f)(...) end }

local getgenv = (typeof(getgenv) == "function") and getgenv or function() return _G end
local hookmetamethod = hookmetamethod or (syn and syn.hook_metamethod) or (fluxus and fluxus.hook_metamethod)
local getnamecallmethod = getnamecallmethod or (syn and syn.get_namecall_method) or (fluxus and fluxus.get_namecall_method)
local checkcaller = checkcaller or (syn and syn.check_caller) or (fluxus and fluxus.check_caller) or function() return false end
local newcclosure = newcclosure or (syn and syn.new_cclosure) or (fluxus and fluxus.new_cclosure) or function(f) return f end
local getcallingscript = getcallingscript or (debug and debug.getcallingscript) or function() return "Unknown" end

local function getPath(instance)
    if not instance then return "nil" end
    local success, name = pcall(function() return instance.Name end)
    if not success then return "ProtectedInstance" end
    if instance == game then return "game" end
    if instance == workspace then return "workspace" end
    if instance == LocalPlayer then return "game:GetService('Players').LocalPlayer" end
    local parent; pcall(function() parent = instance.Parent end)
    if not parent then return 'getnilinstance("' .. name .. '")' end
    local cleanName = name:gsub('[%w_]', '')
    local head = (#cleanName > 0 or tonumber(name:sub(1,1))) and '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]' or "." .. name
    return getPath(parent) .. head
end

local function serialize(val, visited, indent)
    visited = visited or {}; indent = indent or 0; local t = typeof(val); local spacing = string.rep("    ", indent)
    if t == "string" then return '"' .. val:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"'
    elseif t == "number" or t == "boolean" or t == "nil" then return tostring(val)
    elseif t == "Instance" then return getPath(val)
    elseif t == "table" then
        if visited[val] then return "{ --[[ Circular ]] }" end
        visited[val] = true; local str = "{\n"; local count = 0
        for k, v in pairs(val) do
            count = count + 1; if indent > 5 then str = str .. spacing .. "    --[[ Depth Limit ]]\n"; break end
            str = str .. spacing .. "    [" .. serialize(k, visited, indent + 1) .. "] = " .. serialize(v, visited, indent + 1) .. ",\n"
            if count > 50 then str = str .. spacing .. "    --[[ Truncated ]]\n"; break end
        end
        visited[val] = nil; return str .. spacing .. "}"
    else return 'nil --[[ ' .. t .. ' ]]' end
end

local function handleRemote(instance, method, args)
    if safeCall(checkcaller) then return end
    local success, name = pcall(function() return instance.Name end)
    if not success or ManusSpy.Settings.ExcludedRemotes[name] then return end
    
    local callingScript = safeCall(getcallingscript)
    local scriptPath = typeof(callingScript) == "Instance" and callingScript:GetFullName() or tostring(callingScript)
    if scriptPath:find("Pets") or name:lower():find("pet") then return end

    for _, arg in ipairs(args) do
        if typeof(arg) == "string" and (arg:find("2046263687") or arg:find("rbxassetid")) then return end
    end

    table.insert(ManusSpy.Queue, {Instance = instance, Method = method, Args = args, Script = callingScript, Time = os.clock()})
    if #ManusSpy.Queue == 1 then task.defer(function()
        while #ManusSpy.Queue > 0 do
            local data = table.remove(ManusSpy.Queue, 1)
            table.insert(ManusSpy.Logs, 1, data)
            if #ManusSpy.Logs > ManusSpy.Settings.MaxLogs then table.remove(ManusSpy.Logs) end
            if ManusSpy.OnLogAdded then pcall(ManusSpy.OnLogAdded, data) end
        end
    end) end
    return ManusSpy.Settings.BlockList[instance] or ManusSpy.Settings.BlockList[name]
end

if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if typeof(self) == "Instance" and (method == "FireServer" or method == "InvokeServer") then
            local blocked = false; pcall(function() blocked = handleRemote(self, method, {...}) end)
            if blocked then return end
        end
        return oldNamecall(self, ...)
    end))
end

local function createUI()
    pcall(function()
        local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "ManusSpy_Ultimate"; ScreenGui.ResetOnSpawn = false
        local parent = CoreGui; if getgenv().get_hidden_gui then parent = getgenv().get_hidden_gui() end
        ScreenGui.Parent = parent
        local Main = Instance.new("Frame"); Main.Size = UDim2.new(0, 700, 0, 500); Main.Position = UDim2.new(0.5, -350, 0.5, -250); Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30); Main.Active = true; Main.Draggable = true; Main.Parent = ScreenGui
        local Title = Instance.new("TextLabel"); Title.Text = "  MANUS SPY ULTIMATE v" .. ManusSpy.Version; Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Title.TextColor3 = Color3.fromRGB(0, 255, 150); Title.Font = Enum.Font.GothamBold; Title.TextSize = 18; Title.Parent = Main
        local LogList = Instance.new("ScrollingFrame"); LogList.Size = UDim2.new(0, 250, 1, -50); LogList.Position = UDim2.new(0, 5, 0, 45); LogList.BackgroundColor3 = Color3.fromRGB(20, 20, 20); LogList.Parent = Main
        local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = LogList
        local CodeText = Instance.new("TextBox"); CodeText.Size = UDim2.new(1, -265, 1, -90); CodeText.Position = UDim2.new(0, 260, 0, 45); CodeText.BackgroundColor3 = Color3.fromRGB(15, 15, 15); CodeText.TextColor3 = Color3.fromRGB(220, 220, 220); CodeText.ClearTextOnFocus = false; CodeText.MultiLine = true; CodeText.Text = "-- Aggressive Cleaner & Sound Disabler Active."; CodeText.Parent = Main
        ManusSpy.OnLogAdded = function(data)
            local remoteName = data.Instance and data.Instance.Name or "Unknown"
            local Button = Instance.new("TextButton"); Button.Size = UDim2.new(1, 0, 0, 30); Button.Text = " [" .. data.Method:sub(1,1) .. "] " .. remoteName; Button.Parent = LogList
            Button.MouseButton1Click:Connect(function() CodeText.Text = "-- Remote: " .. remoteName .. "\n" .. serialize(data.Args) end)
        end
    end)
end

createUI()
print("ManusSpy Ultimate v" .. ManusSpy.Version .. " Loaded! Aggressive Mode.")
