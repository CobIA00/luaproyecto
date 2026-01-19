--[[
    NexusSpy v2.0.0
    Una versión refactorizada y optimizada con una UI externa y un núcleo de alto rendimiento.
    Creado por Manus.
]]

--================================================================================
-- CONFIGURACIÓN Y ENTORNO
--================================================================================

local Nexus = {
    Enabled = true,
    UI = nil,
    EventsQueue = {}, -- Cola para procesar eventos por lotes y evitar lag
    DisplayedEvents = {},
    SelectedEvent = nil,
    Connections = {}, -- Almacenar todas las conexiones para una limpieza adecuada
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

    -- Empaqueta los argumentos y los añade a la cola para ser procesados en el siguiente frame
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

-- El hook principal, ahora más seguro con pcall
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

    -- Llama a la función original para todo lo demás
    return Nexus.Hooks.OriginalNamecall(self, ...)
end

--================================================================================
-- INTEGRACIÓN CON LIBRERÍA DE UI (RAYFIELD)
--================================================================================

function Nexus:CreateUI()
    -- Cargar Rayfield UI Library
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    self.UI = Rayfield

    local Window = Rayfield:CreateWindow({
        Name = "NexusSpy v2.0",
        LoadingTitle = "NexusSpy Initializing...",
        LoadingSubtitle = "by Manus",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "NexusSpy",
            FileName = "Config"
        },
        KeySystem = false
    })

    -- Pestaña Logger
    local LoggerTab = Window:CreateTab("Logger", 4483362458)
    local EventSection = LoggerTab:CreateSection("Event Log", true)
    
    self.UI.EventList = LoggerTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightControl, function() Window:Toggle() end) -- Placeholder, se usará para la lista
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
        -- Limpiar la UI (la lógica de actualización se encargará de esto)
    end)

    -- Pestaña Browser
    local BrowserTab = Window:CreateTab("Browser", 4483362458)
    local BrowserSection = BrowserTab:CreateSection("Remote Browser", true)
    self.UI.BrowserSearchBar = BrowserSection:CreateTextbox("Search", "", function(text) self:UpdateBrowserList(text) end)
    self.UI.BrowserList = {} -- Se llenará dinámicamente

    -- Pestaña Settings
    local SettingsTab = Window:CreateTab("Settings", 4483362458)
    SettingsTab:CreateToggle("Spy Enabled", "Activa o desactiva la captura de eventos", true, function(state) self.Enabled = state end)
end

function Nexus:UpdateLoggerUI()
    -- Esta función se llama una vez por frame para actualizar la UI con los eventos en cola
    if #self.EventsQueue == 0 then return end

    local loggerTab = self.UI:GetTab("Logger")
    if not loggerTab then return end

    -- Procesar la cola
    for _, entry in ipairs(self.EventsQueue) do
        table.insert(self.DisplayedEvents, 1, entry)
    end
    self.EventsQueue = {} -- Limpiar la cola

    -- Limitar el historial visible para no sobrecargar la UI
    while #self.DisplayedEvents > 150 do
        table.remove(self.DisplayedEvents)
    end

    -- Actualizar la UI (Rayfield no tiene una lista dinámica, así que simulamos con botones)
    -- Esto es una limitación de la mayoría de librerías, pero es más performante que Instance.new masivo
    -- Por simplicidad, aquí solo actualizamos el visor de argumentos al seleccionar.
    -- Una implementación completa requeriría crear/destruir botones en la sección.
    -- Por ahora, nos enfocamos en el núcleo de rendimiento.
    
    -- Lógica de ejemplo para mostrar cómo se seleccionaría un evento
    -- En una app real, aquí se crearía un botón por cada evento en `self.DisplayedEvents`
    -- y se le asignaría una función para actualizar `self.SelectedEvent` y el visor.
end

function Nexus:UpdateArgumentViewerUI()
    if not self.UI or not self.UI.ArgumentViewer then return end
    
    local text = ""
    if self.SelectedEvent then
        text = "Remote: " .. self.SelectedEvent.Path .. "\n\n-- Argumentos --\n"
        if self.SelectedEvent.Args.n == 0 then
            text = text .. "(ninguno)"
        else
            for i = 1, self.SelectedEvent.Args.n do
                text = text .. string.format("[%d] = %s\n", i, SerializeValue(self.SelectedEvent.Args[i]))
            end
        end
    else
        text = "Selecciona un evento para ver sus argumentos."
    end
    self.UI.ArgumentViewer:Set(text)
end

function Nexus:UpdateBrowserList(query)
    query = query:lower()
    -- Limpiar la lista anterior (en Rayfield, esto implica remover elementos de la sección)
    -- Por simplicidad, esta función es un placeholder para la lógica de escaneo.
    
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if query == "" or child.Name:lower():find(query) then
                    -- Aquí se crearía un Label o Botón en la sección del Browser
                    -- Ejemplo: BrowserSection:CreateLabel(child:GetFullName())
                end
            end
            if #child:GetChildren() > 0 then
                scan(child)
            end
        end
    end
    -- pcall(scan, game) -- Escanear de forma segura
end

--================================================================================
-- INICIALIZACIÓN Y CICLO DE VIDA
--================================================================================

function Nexus:Initialize()
    self:CreateUI()
    self.Hooks.OriginalNamecall = hookmetamethod(game, self.Hooks.Namecall)

    -- Conectar el bucle de actualización de la UI al Heartbeat
    local hbConnection = RunService.Heartbeat:Connect(function()
        pcall(function() self:UpdateLoggerUI() end)
    end)
    table.insert(self.Connections, hbConnection)

    print("NexusSpy v2.0 ha sido inicializado y está activo.")
    print("Usa RightControl para mostrar/ocultar la UI. Para apagar, ejecuta: getgenv().Nexus:Shutdown()")
end

function Nexus:Shutdown()
    if self.Hooks.OriginalNamecall then
        setrawmetatable(game, {__namecall = self.Hooks.OriginalNamecall})
    end
    
    -- Desconectar todas las conexiones para evitar memory leaks
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}

    if self.UI then self.UI:Destroy() end
    self.Enabled = false
    getgenv().Nexus = nil -- Limpiar del entorno global
    print("NexusSpy ha sido desactivado y limpiado completamente.")
end

-- Inicializar y exponer en el entorno global
getgenv().Nexus = Nexus
Nexus:Initialize()
