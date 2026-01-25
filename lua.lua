--[[
    Advanced Game Analyzer GUI
    Purpose: Full control passive auditing
    Author: Defensive / Dev tool
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- =====================
-- CONFIG (GUI controlled)
-- =====================
local Config = {
    ScanRemotes = true,
    ScanCoins = true,
    ScanPets = true,
    RiskMultiplier = 1.0
}

-- =====================
-- ANALYZER CORE
-- =====================
local Analyzer = {}

local SYSTEM_KEYWORDS = {
    Coins = {"coin", "coins", "damage", "health"},
    Pets = {"pet", "pets", "egg", "golden"},
    Stats = {"stat", "stats", "save", "load", "inventory"},
}

local CRITICAL_KEYWORDS = {
    "save","set","give","grant",
    "buy","product","gamepass",
    "admin","execute","eval"
}

local function containsAny(str, list)
    str = str:lower()
    for _, k in ipairs(list) do
        if str:find(k) then return true end
    end
    return false
end

local function calculateRisk(name)
    local score = 0
    name = name:lower()

    if containsAny(name, CRITICAL_KEYWORDS) then
        score += 40
    end

    for _, keys in pairs(SYSTEM_KEYWORDS) do
        if containsAny(name, keys) then
            score += 20
        end
    end

    if name:find("game") or name:find("core") then
        score += 15
    end

    return math.clamp(math.floor(score * Config.RiskMultiplier), 0, 100)
end

local function riskLabel(score)
    if score >= 75 then return "CRITICAL"
    elseif score >= 50 then return "HIGH"
    elseif score >= 25 then return "MEDIUM"
    else return "INFO" end
end

function Analyzer.Run()
    local Report = {
        Remotes = {},
        Coins = 0,
        Pets = 0
    }

    if Config.ScanRemotes then
        for _, root in ipairs({Workspace, ReplicatedStorage}) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local risk = calculateRisk(obj.Name)
                    table.insert(Report.Remotes, {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Risk = risk,
                        Severity = riskLabel(risk)
                    })
                end
            end
        end
    end

    if Config.ScanCoins then
        local things = Workspace:FindFirstChild("__THINGS")
        if things and things:FindFirstChild("Coins") then
            for _, zone in ipairs(things.Coins:GetChildren()) do
                Report.Coins += #zone:GetChildren()
            end
        end
    end

    if Config.ScanPets then
        local debris = Workspace:FindFirstChild("__DEBRIS")
        if debris and debris:FindFirstChild("Pets") then
            for _, plr in ipairs(debris.Pets:GetChildren()) do
                Report.Pets += #plr:GetChildren()
            end
        end
    end

    return Report
end

-- =====================
-- GUI
-- =====================
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.Name = "AnalyzerGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.4, 0.45)
frame.Position = UDim2.fromScale(0.3, 0.25)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local function createButton(text, posY)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.fromScale(0.9, 0.12)
    b.Position = UDim2.fromScale(0.05, posY)
    b.BackgroundColor3 = Color3.fromRGB(45,45,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = text
    return b
end

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.fromScale(1, 0.15)
title.BackgroundTransparency = 1
title.Text = "🧠 Advanced Game Analyzer"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local btnRemotes = createButton("Scan Remotes: ON", 0.18)
local btnCoins   = createButton("Scan Coins: ON", 0.32)
local btnPets    = createButton("Scan Pets: ON", 0.46)
local btnRun     = createButton("▶ Run Analysis", 0.62)
local btnExport  = createButton("📤 Print Report", 0.76)

-- =====================
-- GUI LOGIC
-- =====================
local function toggle(btn, key)
    Config[key] = not Config[key]
    btn.Text = btn.Text:gsub("ON|OFF", Config[key] and "ON" or "OFF")
end

btnRemotes.MouseButton1Click:Connect(function()
    toggle(btnRemotes, "ScanRemotes")
end)

btnCoins.MouseButton1Click:Connect(function()
    toggle(btnCoins, "ScanCoins")
end)

btnPets.MouseButton1Click:Connect(function()
    toggle(btnPets, "ScanPets")
end)

local LastReport

btnRun.MouseButton1Click:Connect(function()
    LastReport = Analyzer.Run()
    btnRun.Text = "✔ Analysis Done"
    task.delay(1, function()
        btnRun.Text = "▶ Run Analysis"
    end)
end)

btnExport.MouseButton1Click:Connect(function()
    if not LastReport then return end
    print("=== ANALYZER REPORT ===")
    print("Remotes:", #LastReport.Remotes)
    print("Coins:", LastReport.Coins)
    print("Pets:", LastReport.Pets)
    for _, r in ipairs(LastReport.Remotes) do
        if r.Severity ~= "INFO" then
            print(r.Severity, r.Path, r.Risk)
        end
    end
end)
