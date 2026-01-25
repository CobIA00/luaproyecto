--[[
    Advanced Security Auditor
    Unified GUI + Core
    Passive | Defensive | Dev Tool
]]

-- =====================
-- SERVICES
-- =====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- =====================
-- CONFIG (GUI-driven)
-- =====================
local Config = {
    IgnoreDefaultRoblox = true,
    MinRiskToDisplay = 40,
    RiskMultiplier = 1,
}

-- =====================
-- AUDITOR LOGIC
-- =====================
local SYSTEM_MAP = {
    Monetization = {"gamepass","product","purchase","bought","receipt"},
    SaveData     = {"save","load","data","profile","stat","inventory"},
    Gameplay     = {"coin","coins","pet","pets","damage","health"},
    Social       = {"chat","friend","block"},
}

local DEFAULT_IGNORE = {
    "DefaultChatSystemChatEvents",
    "PlayerModule",
}

local CRITICAL = {
    "give","set","grant","admin","execute","eval"
}

local function contains(str, list)
    str = str:lower()
    for _, k in ipairs(list) do
        if str:find(k) then return true end
    end
    return false
end

local function classifySystem(name)
    for system, keys in pairs(SYSTEM_MAP) do
        if contains(name, keys) then
            return system
        end
    end
    return "Unknown"
end

local function calculateRisk(name, system, location)
    local score = 0
    name = name:lower()

    if contains(name, CRITICAL) then score += 40 end
    if system == "Monetization" or system == "SaveData" then score += 20 end
    if location == "Workspace" then score += 15 end
    if name:find("fail") or name:find("new") then score += 10 end

    return math.clamp(math.floor(score * Config.RiskMultiplier), 0, 100)
end

local function runAudit()
    local Report = {}

    local roots = {
        Workspace = Workspace,
        ReplicatedStorage = ReplicatedStorage
    }

    for location, root in pairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then

                if Config.IgnoreDefaultRoblox then
                    if contains(obj:GetFullName(), DEFAULT_IGNORE) then
                        continue
                    end
                end

                local system = classifySystem(obj.Name)
                local risk = calculateRisk(obj.Name, system, location)

                if risk >= Config.MinRiskToDisplay then
                    table.insert(Report, {
                        System = system,
                        Location = location,
                        Risk = risk,
                        Path = obj:GetFullName()
                    })
                end
            end
        end
    end

    table.sort(Report, function(a, b)
        return a.Risk > b.Risk
    end)

    return Report
end

-- =====================
-- GUI
-- =====================
local Gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
Gui.Name = "SecurityAuditor"
Gui.ResetOnSpawn = false

local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.fromScale(0.6, 0.65)
Frame.Position = UDim2.fromScale(0.2, 0.18)
Frame.BackgroundColor3 = Color3.fromRGB(18,18,24)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.fromScale(1, 0.08)
Title.BackgroundTransparency = 1
Title.Text = "🧠 Security Auditor – Unified"
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(0,200,255)

local Output = Instance.new("TextLabel", Frame)
Output.Position = UDim2.fromScale(0.02, 0.1)
Output.Size = UDim2.fromScale(0.96, 0.72)
Output.BackgroundTransparency = 1
Output.TextXAlignment = Left
Output.TextYAlignment = Top
Output.TextWrapped = true
Output.Font = Enum.Font.Code
Output.TextSize = 14
Output.TextColor3 = Color3.fromRGB(220,220,220)
Output.Text = "Press 'Run Audit' to analyze."

local function createButton(text, x, y)
    local b = Instance.new("TextButton", Frame)
    b.Size = UDim2.fromScale(0.3, 0.08)
    b.Position = UDim2.fromScale(x, y)
    b.BackgroundColor3 = Color3.fromRGB(40,40,55)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = text
    return b
end

local RunBtn = createButton("▶ Run Audit", 0.02, 0.85)
local ToggleIgnoreBtn = createButton("Ignore Roblox: ON", 0.35, 0.85)
local ClearBtn = createButton("Clear", 0.68, 0.85)

-- =====================
-- GUI LOGIC
-- =====================
local function render(report)
    local lines = {}
    table.insert(lines, "=== AUDIT REPORT ===\n")

    for _, r in ipairs(report) do
        table.insert(lines,
            string.format("[%s | %s] RISK %d\n%s\n",
                r.System,
                r.Location,
                r.Risk,
                r.Path
            )
        )
    end

    Output.Text = table.concat(lines, "\n")
end

RunBtn.MouseButton1Click:Connect(function()
    local report = runAudit()
    render(report)
end)

ToggleIgnoreBtn.MouseButton1Click:Connect(function()
    Config.IgnoreDefaultRoblox = not Config.IgnoreDefaultRoblox
    ToggleIgnoreBtn.Text = "Ignore Roblox: " .. (Config.IgnoreDefaultRoblox and "ON" or "OFF")
end)

ClearBtn.MouseButton1Click:Connect(function()
    Output.Text = ""
end)
