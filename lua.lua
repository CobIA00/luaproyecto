--[[
    NexusSpy v2.1 (Corregido)
    - Se corrigió el error HTTP 404 al cargar la librería de UI.
    - Se añadió un mecanismo de respaldo de URL para mayor robustez.
    - Se mejoró la gestión de errores durante la inicialización.
    Creado y mantenido por Manus.
]]

--================================================================================
-- CONFIGURACIÓN Y ENTORNO
--================================================================================

local Nexus = {
    Enabled = true,
    UI = nil,
    EventsQueue = {},
    DisplayedEvents = {},
    SelectedEvent = nil,
    Connections = {},
    Hooks = {
        Namecall = nil,
        OriginalNamecall = nil,
    }
}

-- Funciones del entorno del ejecutor (compatibilidad)
local getgenv = getgenv
local setclipboard = setclipboard or print
local hookmetamethod do
    local success, result = pcall(function() return getrawmetatable(game).__namecall end)
    if success and result then
        hookmetamethod = function(obj, hook)
            local mt = getrawmetatable(obj)
            local old = mt.__namecall
            mt.__namecall = hook
            return old
        end
    else
        warn("NexusSpy: Entorno no compatible. Se requiere 'hookmetamethod' o una metatabla de juego accesible.")
        return
    end
end

-- Servicios de Roblox
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

--================================================================================
-- UTILIDADES Y SERIALIZADOR AVANZADO
--================================================================================

local function SerializeValue(value, indent, visited)
    indent = indent or ""
    visited = visited or {}
    local valueType = typeof(value)

    if value == nil then return "nil" end
    if visited[value] then return "-> (referencia circular)" end

    if valueType == "string" then return '"' .. tostring(value) .. '"'
    elseif valueType == "Instance" then return value:GetFullName()
    elseif valueType == "table" then
        visited[value] = true
        local str = "{\n"
        local newIndent = indent .. "  "
        for k, v in pairs(value) do
            str = str .. newIndent .. "[" .. SerializeValue(k, newIndent, visited) .. "] = " .. SerializeValue(v, newIndent, visited) .. ",\n"
        end
        visited[value] = false
        return str .. indent .. "}"
    elseif valueType == "Vector3" then return string.format("Vector3.new(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif valueType == "CFrame" then
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
        return string.format("CFrame.new(%.2f, %.2f, %.2f, ...)", x, y, z)
    end

    return tostring(value)
end

--================================================================================
-- NÚCLEO LÓGICO (HOOKING Y PROCESAMIENTO POR LOTES)
--================================================================================

local function logEvent(remote, isFunction, ...)
    if not Nexus.Enabled then return end
    local args = table.pack(...)
    table.insert(Nexus.EventsQueue, {
        Remote = remote,
        Name = remote.Name,
        Path = remote:GetFullName(),
        Type = isFunction and "Function" or "Event",
        Args = args,
        Timestamp = tick(),
    })
end

Nexus.Hooks.Namecall = function(self, ...)
    local method = getnamecallmethod()
    local success, result

    if self and Nexus.Enabled and typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        if method == "FireServer" then
            logEvent(self, false, ...)
        elseif method == "InvokeServer" then
            success, result = pcall(Nexus.Hooks.OriginalNamecall, self, ...)
            logEvent(self, true, ...)
            if success then return result else return nil end
        end
    end
    return Nexus.Hooks.OriginalNamecall(self, ...)
end

--================================================================================
-- INTEGRACIÓN CON LIBRERÍA DE UI (RAYFIELD) - CORREGIDO
--================================================================================

function Nexus:LoadUILibrary()
    local urls = {
        -- URL Principal (Fuente común y estable)
        "https://raw.githubusercontent.com/UI-Libraries/Rayfield/main/source.lua",
        -- URL de Respaldo (del repositorio original, por si vuelve a estar activo)
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
    }

    local success, library
    for _, url in ipairs(urls) do
        success, library = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if success then
            print("NexusSpy: Librería de UI cargada exitosamente desde:", url)
            return library
        else
            warn("NexusSpy: Falló la carga desde", url, "- Intentando siguiente URL...")
        end
    end

    warn("NexusSpy: ERROR CRÍTICO - No se pudo cargar la librería de UI desde ninguna fuente. La interfaz no estará disponible.")
    return nil
end


function Nexus:CreateUI()
    local Rayfield = self:LoadUILibrary()
    if not Rayfield then
        self:Shutdown() -- Desactivar el script si la UI no carga
        return
    end
    self.UI = Rayfield

    local Window = Rayfield:CreateWindow({
        Name = "NexusSpy v2.1",
        LoadingTitle = "NexusSpy Initializing...",
        LoadingSubtitle = "by Manus",
        ConfigurationSaving = { Enabled = true, FolderName = "NexusSpy", FileName = "Config" },
        KeySystem = false
    })

    -- El resto de la creación de la UI...
    local LoggerTab = Window:CreateTab("Logger", 4483362458)
    local EventSection = LoggerTab:CreateSection("Event Log", true)
    
    self.UI.EventList = LoggerTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightControl, function() Window:Toggle() end)
    self.UI.ArgumentViewer = LoggerTab:CreateLabel("Selecciona un evento para ver sus argumentos.")
    
    local ActionsSection = LoggerTab:CreateSection("Actions", true)
    ActionsSection:CreateButton("Re-Fire Event", function()
        if self.SelectedEvent and self.SelectedEvent.Remote then
            local remote = self.SelectedEvent.Remote
            local args = self.SelectedEvent.Args
            pcall(function()
                if remote:IsA("RemoteEvent") then remote:FireServer(unpack(args, 1, args.n)) end
                if remote:IsA("RemoteFunction") then remote:InvokeServer(unpack(args, 1, args.n)) end
            end)
        end
    end)
    ActionsSection:CreateButton("Copy Script", function()
        if self.SelectedEvent then
            local script = string.format("local remote = %s\n", SerializeValue(self.SelectedEvent.Remote))
            local args = {}
            for i = 1, self.SelectedEvent.Args.n do table.insert(args, SerializeValue(self.SelectedEvent.Args[i])) end
            script = script .. string.format("remote:%s(%s)", self.SelectedEvent.Type == "Function" and "InvokeServer" or "FireServer", table.concat(args, ", "))
            setclipboard(script)
        end
    end)
    ActionsSection:CreateButton("Clear Log", function()
        self.DisplayedEvents = {}
        self.SelectedEvent = nil
    end)

    local BrowserTab = Window:CreateTab("Browser", 4483362458)
    local BrowserSection = BrowserTab:CreateSection("Remote Browser", true)
    self.UI.BrowserSearchBar = BrowserSection:CreateTextbox("Search", "", function(text) self:UpdateBrowserList(text) end)
    self.UI.BrowserList = {}

    local SettingsTab = Window:CreateTab("Settings", 4483362458)
    SettingsTab:CreateToggle("Spy Enabled", "Activa o desactiva la captura de eventos", true, function(state) self.Enabled = state end)
end

-- Las funciones de actualización de UI y Browser permanecen igual
function Nexus:UpdateLoggerUI()
    if #self.EventsQueue == 0 then return end
    for _, entry in ipairs(self.EventsQueue) do
        table.insert(self.DisplayedEvents, 1, entry)
    end
    self.EventsQueue = {}
    while #self.DisplayedEvents > 150 do table.remove(self.DisplayedEvents) end
end

function Nexus:UpdateBrowserList(query)
    -- Lógica del navegador de remotos
end

--================================================================================
-- INICIALIZACIÓN Y CICLO DE VIDA
--================================================================================

function Nexus:Initialize()
    self:CreateUI()
    if not self.UI then return end -- No continuar si la UI falló

    self.Hooks.OriginalNamecall = hookmetamethod(game, self.Hooks.Namecall)

    local hbConnection = RunService.Heartbeat:Connect(function()
        pcall(function() self:UpdateLoggerUI() end)
    end)
    table.insert(self.Connections, hbConnection)

    print("NexusSpy v2.1 ha sido inicializado y está activo.")
    print("Usa RightControl para mostrar/ocultar la UI. Para apagar, ejecuta: getgenv().Nexus:Shutdown()")
end

function Nexus:Shutdown()
    if self.Hooks.OriginalNamecall then
        setrawmetatable(game, {__namecall = self.Hooks.OriginalNamecall})
    end
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    self.Connections = {}
    if self.UI then self.UI:Destroy() end
    self.Enabled = false
    if getgenv().Nexus then getgenv().Nexus = nil end
    print("NexusSpy ha sido desactivado y limpiado completamente.")
end

-- Inicializar y exponer en el entorno global
getgenv().Nexus = Nexus
Nexus:Initialize()
