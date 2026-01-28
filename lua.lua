-- Advanced Client Vulnerability Auditor (Luau)
-- Put in StarterPlayer -> StarterPlayerScripts as a LocalScript (ONLY for auditing your games)
-- Features:
--  - Modular, configurable, performance-conscious
--  - Per-remote sliding window counters, spike detection, suspicious-arg heuristics
--  - Whitelist/blacklist patterns
--  - Batched log updates and UI recycling (reduced GC/DOM churn)
--  - Public API: _G.ClientAudit
--  - Safe: no server-side breaking, intended for testing/audits only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService") -- used for simple encoding of logs
local player = Players.LocalPlayer

-- ======= CONFIG =======
local config = {
    SUSPICIOUS_NUMBER_THRESHOLD = 1e6,
    HIGH_WALKSPEED_THRESHOLD = 30,
    HIGH_JUMP_THRESHOLD = 80,
    TELEPORT_DISTANCE_THRESHOLD = 50,
    REMOTE_CALL_RATE_WINDOW = 2,          -- seconds (sliding window)
    REMOTE_CALL_RATE_THRESHOLD = 12,      -- calls in window considered suspicious
    GLOBAL_ACTIVITY_WINDOW = 60,          -- seconds to consider elevated activity
    GLOBAL_ACTIVITY_THRESHOLD = 500,
    LOG_MAX_ENTRIES = 2000,
    GUI_UPDATE_INTERVAL = 0.5,            -- update GUI every X seconds (batched)
    SAMPLE_RATE = 1.0,                    -- fraction 0..1 of events to log (1 = log all)
    WHITELIST_PATTERNS = { "^GamePass", "^SafeRemote" }, -- patterns to ignore (lua patterns)
    BLACKLIST_PATTERNS = { "Cheat", "AdminOnly" },      -- patterns to always highlight
    SHOW_INSTANCE_PATH = true,
    LABEL_POOL_SIZE = 80,                 -- recycled labels for performance
}

-- ======= STATE (weak refs where possible) =======
local logs = {}                           -- newest first
local logCount = 0
local remoteStats = setmetatable({}, { __mode = "k" })  -- [remote] = {timestamps = {t1,t2,...}}
local originalMethods = setmetatable({}, { __mode = "k" }) -- store originals
local connections = {}                    -- for cleanup if needed
local guiRoot = nil
local pendingGuiLogs = {}                 -- buffer for GUI updates
local lastGuiUpdate = 0
local paused = false

-- ======= UTILS =======
local function now() return os.time() + (tick() - math.floor(tick())) end -- higher resolution-ish
local function shouldSample() return config.SAMPLE_RATE >= 1 or math.random() <= config.SAMPLE_RATE end

local function matchesPatternList(name, patterns)
    if not name then return false end
    for _,p in ipairs(patterns) do
        if tostring(name):match(p) then return true end
    end
    return false
end

local function shortInstancePath(inst)
    if not inst then return "<nil>" end
    if not config.SHOW_INSTANCE_PATH then return inst.Name end
    local ok, s = pcall(function() return inst:GetFullName() end)
    return ok and s or inst.Name
end

local function severityPrefix(level)
    if level == "ERROR" then return "❗ERROR" end
    if level == "WARN" then return "⚠️WARN" end
    return "INFO"
end

local function pushLog(level, message)
    if not shouldSample() then return end
    local ts = os.date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("%s | %s | %s", ts, severityPrefix(level), message)
    table.insert(logs, 1, entry)
    logCount = logCount + 1
    if logCount > config.LOG_MAX_ENTRIES then
        for i = config.LOG_MAX_ENTRIES + 1, logCount do logs[i] = nil end
        logCount = config.LOG_MAX_ENTRIES
    end
    -- buffer for GUI update
    table.insert(pendingGuiLogs, 1, entry)
end

-- safe tostring for args
local function argToString(v)
    local t = typeof(v)
    if t == "Instance" then
        return ("<Instance:%s>"):format(shortInstancePath(v))
    elseif t == "table" then
        -- small preview
        local ok, s = pcall(function() return HttpService:JSONEncode({}) end)
        return "<table>"
    else
        return tostring(v)
    end
end

-- ======= Remote monitoring (efficient sliding window) =======
local function ensureRemoteState(remote)
    if not remoteStats[remote] then
        remoteStats[remote] = { timestamps = {} }
    end
end

local function recordRemoteCall(remote)
    ensureRemoteState(remote)
    local s = remoteStats[remote]
    local t = tick()
    table.insert(s.timestamps, t)
    -- purge old timestamps older than window
    local cutoff = t - config.REMOTE_CALL_RATE_WINDOW
    local j = 1
    for i = #s.timestamps, 1, -1 do
        if s.timestamps[i] >= cutoff then
            j = i
            break
        end
    end
    -- compact to recent ones
    local new = {}
    for i = j, #s.timestamps do new[#new+1] = s.timestamps[i] end
    s.timestamps = new
    return #s.timestamps
end

local function interceptRemote(remote)
    if originalMethods[remote] then return end
    originalMethods[remote] = {}
    -- RemoteEvent
    if remote:IsA("RemoteEvent") then
        originalMethods[remote].FireServer = remote.FireServer
        remote.FireServer = function(self, ...)
            -- lightweight pre-checks
            local name = shortInstancePath(self)
            if matchesPatternList(self.Name, config.WHITELIST_PATTERNS) then
                return originalMethods[remote].FireServer(self, ...)
            end

            local callsInWindow = recordRemoteCall(remote)
            if callsInWindow >= config.REMOTE_CALL_RATE_THRESHOLD then
                pushLog("WARN", ("High call rate on %s : %d calls in last %.1fs"):format(name, callsInWindow, config.REMOTE_CALL_RATE_WINDOW))
            end

            -- check args heuristics (only check first few for performance)
            local args = {...}
            for i = 1, math.min(6, #args) do
                local v = args[i]
                if typeof(v) == "number" and math.abs(v) >= config.SUSPICIOUS_NUMBER_THRESHOLD then
                    pushLog("WARN", ("Suspicious numeric arg on %s arg#%d = %s"):format(name, i, tostring(v)))
                elseif typeof(v) == "string" and #v > 800 then
                    pushLog("WARN", ("Very long string arg on %s (len=%d)"):format(name, #v))
                elseif typeof(v) == "Instance" and not v:IsDescendantOf(game) then
                    pushLog("WARN", ("Arg Instance not in DataModel on %s arg#%d = %s"):format(name, i, argToString(v)))
                end
            end

            -- blacklist/keyword detection in name
            if matchesPatternList(self.Name, config.BLACKLIST_PATTERNS) then
                pushLog("ERROR", ("Blacklisted pattern in remote name: %s"):format(name))
            end

            -- call original (protected)
            local ok, res = pcall(originalMethods[remote].FireServer, self, ...)
            if not ok then
                pushLog("ERROR", ("Error calling original FireServer on %s: %s"):format(name, tostring(res)))
            end
            return res
        end
        pushLog("INFO", ("Monitoring RemoteEvent: %s"):format(shortInstancePath(remote)))
    end

    -- RemoteFunction
    if remote:IsA("RemoteFunction") then
        originalMethods[remote].InvokeServer = remote.InvokeServer
        remote.InvokeServer = function(self, ...)
            local name = shortInstancePath(self)
            if matchesPatternList(self.Name, config.WHITELIST_PATTERNS) then
                return originalMethods[remote].InvokeServer(self, ...)
            end

            local callsInWindow = recordRemoteCall(remote)
            if callsInWindow >= config.REMOTE_CALL_RATE_THRESHOLD then
                pushLog("WARN", ("High invoke rate on %s : %d calls in last %.1fs"):format(name, callsInWindow, config.REMOTE_CALL_RATE_WINDOW))
            end

            local args = {...}
            for i = 1, math.min(6, #args) do
                local v = args[i]
                if typeof(v) == "number" and math.abs(v) >= config.SUSPICIOUS_NUMBER_THRESHOLD then
                    pushLog("WARN", ("Suspicious numeric arg on %s arg#%d = %s"):format(name, i, tostring(v)))
                end
            end

            if matchesPatternList(self.Name, config.BLACKLIST_PATTERNS) then
                pushLog("ERROR", ("Blacklisted pattern in remote name: %s"):format(name))
            end

            local ok, res = pcall(originalMethods[remote].InvokeServer, self, ...)
            if not ok then
                pushLog("ERROR", ("Error calling original InvokeServer on %s: %s"):format(name, tostring(res)))
            end
            return res
        end
        pushLog("INFO", ("Monitoring RemoteFunction: %s"):format(shortInstancePath(remote)))
    end
end

-- scan existing remotes and hook DescendantAdded
local function scanAndHook(root)
    for _,v in ipairs(root:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            pcall(interceptRemote, v)
        end
    end
end
scanAndHook(game)
connections[#connections+1] = game.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        pcall(interceptRemote, desc)
    end
end)

-- ======= Character watcher (optimized) =======
local function watchCharacter(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    pushLog("INFO", ("Character watcher started for %s"):format(player.Name))

    -- use single listeners that do minimal work
    local wsConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        local ws = hum.WalkSpeed
        if ws > config.HIGH_WALKSPEED_THRESHOLD then
            pushLog("WARN", ("High WalkSpeed detected: %.2f"):format(ws))
        end
    end)
    table.insert(connections, wsConn)

    local jpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        local jp = hum.JumpPower
        if jp > config.HIGH_JUMP_THRESHOLD then
            pushLog("WARN", ("High JumpPower detected: %.2f"):format(jp))
        end
    end)
    table.insert(connections, jpConn)

    -- teleport detection with small debounce
    local lastPos = root.Position
    local tpDebounce = 0
    local cfConn = root:GetPropertyChangedSignal("CFrame"):Connect(function()
        local nowt = tick()
        if nowt < tpDebounce then return end
        local newPos = root.Position
        local dist = (newPos - lastPos).Magnitude
        if dist >= config.TELEPORT_DISTANCE_THRESHOLD then
            pushLog("WARN", ("Possible teleport: dist=%.1f from (%.1f,%.1f,%.1f) to (%.1f,%.1f,%.1f)"):format(
                dist, lastPos.X, lastPos.Y, lastPos.Z, newPos.X, newPos.Y, newPos.Z))
            tpDebounce = nowt + 0.5 -- avoid duplicate spam
        end
        lastPos = newPos
    end)
    table.insert(connections, cfConn)
end

if player.Character then pcall(watchCharacter, player.Character) end
connections[#connections+1] = player.CharacterAdded:Connect(function(c) pcall(watchCharacter, c) end)

-- ======= Global activity monitor (lightweight) =======
local globalActivityTimestamps = {}
local function recordGlobalActivity()
    table.insert(globalActivityTimestamps, tick())
    -- purge old
    local cutoff = tick() - config.GLOBAL_ACTIVITY_WINDOW
    local idx = 1
    for i = #globalActivityTimestamps, 1, -1 do
        if globalActivityTimestamps[i] >= cutoff then
            idx = i
            break
        end
    end
    local new = {}
    for i = idx, #globalActivityTimestamps do new[#new+1] = globalActivityTimestamps[i] end
    globalActivityTimestamps = new
    if #globalActivityTimestamps >= config.GLOBAL_ACTIVITY_THRESHOLD then
        pushLog("WARN", ("Elevated global client activity: %d events in last %ds"):format(#globalActivityTimestamps, config.GLOBAL_ACTIVITY_WINDOW))
    end
end

-- Hook recordGlobalActivity into remote interceptors by wrapping recordRemoteCall
-- We already call recordRemoteCall in interceptors, so call recordGlobalActivity there as well
-- (Add this call to interceptors)
-- For cleanliness, we will just wrap recordRemoteCall to also record global activity:
do
    local orig_recordRemoteCall = recordRemoteCall
    recordRemoteCall = function(remote)
        local count = orig_recordRemoteCall(remote)
        recordGlobalActivity()
        return count
    end
end

-- ======= GUI - optimized with batching and simple recycling =======
local labelPool = {}
local function getLabel(parent)
    if #labelPool > 0 then
        local lbl = table.remove(labelPool)
        lbl.Visible = true
        lbl.Parent = parent
        return lbl
    end
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(230,230,230)
    label.LayoutOrder = 0
    return label
end

local function recycleLabel(lbl)
    lbl.Text = ""
    lbl.Visible = false
    lbl.Parent = nil
    if #labelPool < config.LABEL_POOL_SIZE then
        table.insert(labelPool, lbl)
    else
        lbl:Destroy()
    end
end

local function makeGui()
    if guiRoot and guiRoot.Parent then return guiRoot end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ClientAuditGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Parent = screenGui
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Position = UDim2.new(0.02, 0, 0.06, 0)
    frame.Size = UDim2.new(0, 520, 0, 420)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    frame.BorderSizePixel = 0
    frame.Active = true

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, -100, 0, 28)
    title.Position = UDim2.new(0, 6, 0, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Text = "Advanced Client Auditor"
    title.TextColor3 = Color3.fromRGB(255,255,255)

    local hideBtn = Instance.new("TextButton")
    hideBtn.Parent = frame
    hideBtn.Size = UDim2.new(0, 80, 0, 26)
    hideBtn.Position = UDim2.new(1, -88, 0, 4)
    hideBtn.Text = "Hide"
    hideBtn.Font = Enum.Font.SourceSans
    hideBtn.TextSize = 14
    hideBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = not screenGui.Enabled
    end)

    -- Search box
    local search = Instance.new("TextBox")
    search.Parent = frame
    search.Size = UDim2.new(0.6, -10, 0, 28)
    search.Position = UDim2.new(0, 6, 0, 34)
    search.PlaceholderText = "Filter logs (substring)..."
    search.ClearTextOnFocus = false
    search.Font = Enum.Font.SourceSans
    search.TextSize = 14

    -- Pause toggle
    local pauseBtn = Instance.new("TextButton")
    pauseBtn.Parent = frame
    pauseBtn.Size = UDim2.new(0, 80, 0, 28)
    pauseBtn.Position = UDim2.new(0.62, 0, 0, 34)
    pauseBtn.Text = "Pause"
    pauseBtn.Font = Enum.Font.SourceSans
    pauseBtn.TextSize = 14
    pauseBtn.MouseButton1Click:Connect(function()
        paused = not paused
        pauseBtn.Text = paused and "Resume" or "Pause"
    end)

    -- Copy all
    local copyBtn = Instance.new("TextButton")
    copyBtn.Parent = frame
    copyBtn.Size = UDim2.new(0, 110, 0, 28)
    copyBtn.Position = UDim2.new(0.76, 0, 0, 34)
    copyBtn.Text = "Copy all"
    copyBtn.Font = Enum.Font.SourceSansBold
    copyBtn.TextSize = 14

    local fullBox = Instance.new("TextBox")
    fullBox.Parent = frame
    fullBox.Size = UDim2.new(1, -12, 0, 90)
    fullBox.Position = UDim2.new(0, 6, 0, 68)
    fullBox.MultiLine = true
    fullBox.ClearTextOnFocus = false
    fullBox.PlaceholderText = "Press Copy all to populate logs for copying..."
    fullBox.TextWrapped = true
    fullBox.Font = Enum.Font.SourceSans
    fullBox.TextSize = 14

    copyBtn.MouseButton1Click:Connect(function()
        fullBox.Text = table.concat(logs, "\n")
        fullBox:CaptureFocus()
        pushLog("INFO", "Logs prepared for copying in GUI.")
    end)

    -- Scrolling log area
    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = frame
    scroll.Name = "LogList"
    scroll.Position = UDim2.new(0, 6, 0, 170)
    scroll.Size = UDim2.new(1, -12, 0, 240)
    scroll.CanvasSize = UDim2.new(0, 0, 1, 0)
    scroll.BackgroundTransparency = 0.2
    scroll.BackgroundColor3 = Color3.fromRGB(8,8,8)
    scroll.BorderSizePixel = 0
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local uiLayout = Instance.new("UIListLayout")
    uiLayout.Parent = scroll
    uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiLayout.Padding = UDim.new(0, 6)

    -- make draggable
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    guiRoot = screenGui
    pushLog("INFO", "Advanced Auditor GUI created.")
    return screenGui, search, scroll
end

local gui, searchBox, logScroll -- references
pcall(function() gui, searchBox, logScroll = makeGui() end)

-- GUI updater (batched)
local function updateGui()
    if not gui or not gui.Parent or paused then return end
    local searchText = (searchBox and searchBox.Text) or ""
    -- move pendingGuiLogs into visible area (cap)
    if #pendingGuiLogs == 0 then return end
    local scroll = logScroll
    if not scroll then return end
    -- add up to N entries per update to avoid heavy work
    local maxAdd = 30
    local added = 0
    for i = #pendingGuiLogs, 1, -1 do
        local entry = pendingGuiLogs[i]
        -- apply search filter quickly
        if searchText == "" or string.find(string.lower(entry), string.lower(searchText), 1, true) then
            local lbl = getLabel(scroll)
            lbl.LayoutOrder = -logCount - i
            lbl.Text = entry
            lbl.Parent = scroll
            added = added + 1
            if added >= maxAdd then break end
        end
    end
    -- clear pending buffer (we won't re-add those we didn't process)
    pendingGuiLogs = {}
end

-- schedule GUI updates on a timer (not every frame)
local guiAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
    guiAccumulator = guiAccumulator + dt
    if guiAccumulator >= config.GUI_UPDATE_INTERVAL then
        guiAccumulator = 0
        if not paused then
            pcall(updateGui)
        end
    end
end)

-- ======= Public API =======
_G.ClientAudit = _G.ClientAudit or {}
_G.ClientAudit.GetLogs = function() return logs end
_G.ClientAudit.GetLogsText = function() return table.concat(logs, "\n") end
_G.ClientAudit.ShowGui = function()
    pcall(function() if not guiRoot then makeGui() end; if guiRoot and guiRoot.Parent then guiRoot.Enabled = true end end)
end
_G.ClientAudit.HideGui = function()
    pcall(function() if guiRoot and guiRoot.Parent then guiRoot.Enabled = false end end)
end
_G.ClientAudit.Pause = function() paused = true end
_G.ClientAudit.Resume = function() paused = false end
_G.ClientAudit.ExportJson = function()
    local ok, json = pcall(function() return HttpService:JSONEncode({ logs = logs, time = os.date() }) end)
    if ok then
        pushLog("INFO", "Logs exported to JSON string (available via return value).")
        return json
    else
        pushLog("ERROR", "Failed to export logs to JSON.")
        return nil
    end
end
_G.ClientAudit.ClearLogs = function()
    logs = {}
    logCount = 0
    pendingGuiLogs = {}
    if guiRoot and guiRoot.Parent then
        -- clear UI children in scroll
        local scroll = guiRoot.Frame:FindFirstChild("LogList")
        if scroll then
            for _,c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextLabel") then recycleLabel(c) end
            end
        end
    end
    pushLog("INFO", "Logs cleared.")
end

-- expose a simple toggle for sampling (less noise)
_G.ClientAudit.SetSampleRate = function(r)
    config.SAMPLE_RATE = math.clamp(tonumber(r) or 1, 0, 1)
    pushLog("INFO", ("Sample rate set to %.2f"):format(config.SAMPLE_RATE))
end

-- ======= Lightweight auto-scan for suspicious new Remotes naming =======
connections[#connections+1] = game.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        -- brief heuristics
        if desc.Name:lower():find("admin") or desc.Name:lower():find("cheat") then
            pushLog("WARN", ("New remote with suspicious name created: %s"):format(shortInstancePath(desc)))
        end
    end
end)

-- ======= Startup logs =======
pushLog("INFO", "Advanced Client Vulnerability Auditor initialized.")
pushLog("INFO", "Scanning game for remotes...")
scanAndHook(game)
pushLog("INFO", "Initial remote scan complete.")

-- End of script 
