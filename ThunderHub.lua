--[[
    Thunder Hub - Cameraman Tower Defense (Main Script - Part 1/2)
    Organized Tabs with Emojis & Categories
]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ============================================================
-- 1. LOAD UI
-- ============================================================
local UI_URL = "https://raw.githubusercontent.com/somchaitanawat0/ThunderHub/refs/heads/main/ThunderUI.lua"
local UILib = loadstring(game:HttpGet(UI_URL))()
local Window, Rayfield = UILib.CreateWindow()

-- ============================================================
-- 2. CONFIG
-- ============================================================
local Config = {
    MapName = "Toilet City",
    Difficulty = "Easy",
    AutoJoin = true,
    AutoVote = true,
    AutoSkip = true,
    AutoReplay = true,
    LeaveOnWin = false,
    LeaveOnFail = true,
    
    AutoPlace = true,
    AutoUpgrade = true,
    MaxUnits = 15,
    Targeting = "Strongest",
    
    AutoSummon = true,
    SummonType = "x10",
    AutoClaim = true,
    
    AntiAFK = true,
    HumanDelay = true,
    FPSBoost = false,
    
    DiscordWebhook = "",
    EnableWebhook = false,
    
    IsFarming = false,
    Wins = 0,
    Losses = 0,
    
    UseMacro = false,
    MacroRecording = false,
    MacroData = {}
}

-- ============================================================
-- 3. HELPERS
-- ============================================================
local function SafeCall(fn, ...)
    local success, err = pcall(fn, ...)
    if not success then warn("[Thunder Error] " .. tostring(err)) end
    return success, err
end

local function RandomWait(min, max)
    if Config.HumanDelay then
        task.wait(math.random(min * 100, max * 100) / 100)
    else
        task.wait(min)
    end
end

local function FindButton(parent, name)
    if not parent then return nil end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Visible and obj.Name:lower():find(name:lower()) then
            return obj
        end
    end
    return nil
end

local function ClickButton(btn)
    if not btn or not btn.Visible then return false end
    return pcall(function()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(pos)
    end)
end

-- ============================================================
-- 4. DISCORD WEBHOOK
-- ============================================================
local function GetRequestFunction()
    if type(request) == "function" then return request end
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    return nil
end

local RequestFn = GetRequestFunction()

local function SendWebhook(title, desc, color)
    if not Config.EnableWebhook or Config.DiscordWebhook == "" or not RequestFn then return end
    task.spawn(function()
        pcall(function()
            local payload = {
                username = "Thunder Hub",
                embeds = {{
                    title = title,
                    description = desc,
                    color = color or 3447003,
                    timestamp = DateTime.now():ToIsoDate(),
                    footer = { text = "Thunder Hub | " .. LP.Name }
                }}
            }
            RequestFn({
                Url = Config.DiscordWebhook,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- ============================================================
-- 5. GAME ACTIONS
-- ============================================================
local function StartAntiAFK()
    LP.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
        pcall(function()
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end)
end

local function JoinMap()
    if not Config.AutoJoin then return end
    SafeCall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText:lower():find(Config.MapName:lower()) then
                fireproximityprompt(obj)
                return
            end
        end
    end)
end

local function VoteDifficulty()
    if not Config.AutoVote then return end
    task.wait(2)
    SafeCall(function()
        local btn = FindButton(PG, Config.Difficulty)
        if btn then ClickButton(btn) end
    end)
end

local function SkipWave()
    if not Config.AutoSkip then return end
    SafeCall(function()
        local btn = FindButton(PG, "Skip")
        if btn then ClickButton(btn) end
    end)
end

local function UpgradeAll()
    if not Config.AutoUpgrade then return end
    SafeCall(function()
        local count = 0
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible and obj.Name:lower():find("upgrade") and count < Config.MaxUnits then
                ClickButton(obj)
                RandomWait(0.15, 0.4)
                count = count + 1
            end
        end
    end)
end

local function ClaimQuests()
    if not Config.AutoClaim then return end
    SafeCall(function()
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible then
                local nameLower = obj.Name:lower()
                local textLower = (obj.Text or ""):lower()
                if nameLower:find("claim") or textLower:find("claim") then
                    ClickButton(obj)
                    RandomWait(0.5, 1)
                end
            end
        end
    end)
end

local function CheckGameEnd()
    local ok, result = SafeCall(function()
        local winLabel, loseLabel
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                local t = obj.Text:lower()
                if t:find("victory") or t:find("win") then winLabel = obj end
                if t:find("defeat") or t:find("lose") then loseLabel = obj end
            end
        end

        if winLabel then
            Config.Wins = Config.Wins + 1
            SendWebhook("Win!", "Wins: " .. Config.Wins .. " | Losses: " .. Config.Losses, 5763719)
            if Config.LeaveOnWin then
                pcall(function() LP:Kick("Auto leave on win") end)
            else
                local replay = FindButton(PG, "Replay") or FindButton(PG, "Play Again")
                if replay and Config.AutoReplay then ClickButton(replay) end
            end
            return true
        elseif loseLabel then
            Config.Losses = Config.Losses + 1
            if Config.LeaveOnFail then
                pcall(function() LP:Kick("Auto leave on fail") end)
            end
            return true
        end
        return false
    end)
    return ok and result
end

-- ============================================================
-- 6. UI TABS & WIDGETS (Part 1)
-- ============================================================

-- [TAB 1: 🎯 FARM]
local FarmTab = Window:CreateTab("🎯 Farm", 4483345998)
FarmTab:CreateSection("⚙️ Match Configuration")

FarmTab:CreateInput({
    Name = "🗺️ Map Name",
    CurrentValue = Config.MapName,
    PlaceholderText = "Toilet City",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) Config.MapName = Text end
})

FarmTab:CreateDropdown({
    Name = "🔥 Difficulty Level",
    Options = {"Easy", "Normal", "Hard", "Insane"},
    CurrentOption = {"Easy"},
    MultipleOptions = false,
    Callback = function(Option) Config.Difficulty = Option[1] end
})

FarmTab:CreateSection("🤖 Automation Settings")

FarmTab:CreateToggle({
    Name = "🚪 Auto Join Map",
    CurrentValue = Config.AutoJoin,
    Flag = "AutoJoin",
    Callback = function(Value) Config.AutoJoin = Value end
})

FarmTab:CreateToggle({
    Name = "🗳️ Auto Vote",
    CurrentValue = Config.AutoVote,
    Flag = "AutoVote",
    Callback = function(Value) Config.AutoVote = Value end
})

FarmTab:CreateToggle({
    Name = "⏭️ Auto Skip Wave",
    CurrentValue = Config.AutoSkip,
    Flag = "AutoSkip",
    Callback = function(Value) Config.AutoSkip = Value end
})

FarmTab:CreateToggle({
    Name = "🔄 Auto Replay",
    CurrentValue = Config.AutoReplay,
    Flag = "AutoReplay",
    Callback = function(Value) Config.AutoReplay = Value end
})

FarmTab:CreateToggle({
    Name = "🏆 Leave On Win",
    CurrentValue = Config.LeaveOnWin,
    Flag = "LeaveOnWin",
    Callback = function(Value) Config.LeaveOnWin = Value end
})

FarmTab:CreateToggle({
    Name = "💀 Leave On Fail",
    CurrentValue = Config.LeaveOnFail,
    Flag = "LeaveOnFail",
    Callback = function(Value) Config.LeaveOnFail = Value end
})

FarmTab:CreateSection("🚀 Farm Controls")

FarmTab:CreateButton({
    Name = "▶️ Start Farm Loop",
    Callback = function()
        if Config.IsFarming then return end
        Config.IsFarming = true
        SendWebhook("Farm Started", "Map: " .. Config.MapName, 3066993)
        
        task.spawn(function()
            while Config.IsFarming do
                JoinMap()
                task.wait(3)
                VoteDifficulty()
                task.wait(3)
                SkipWave()
                UpgradeAll()
                ClaimQuests()
                if CheckGameEnd() then task.wait(3) end
                task.wait(2)
            end
        end)
        Rayfield:Notify({ Title = "Farm Started", Content = "Loop is now running.", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "⏹️ Stop Farm Loop",
    Callback = function()
        Config.IsFarming = false
        SendWebhook("Farm Stopped", "Wins: " .. Config.Wins .. " | Losses: " .. Config.Losses, 15158332)
        Rayfield:Notify({ Title = "Farm Stopped", Content = "Loop has been halted.", Duration = 3 })
    end
})

-- [TAB 2: ⚔️ UNITS]
local UnitTab = Window:CreateTab("⚔️ Units", 4483345998)
UnitTab:CreateSection("🛡️ Unit Automation")

UnitTab:CreateToggle({
    Name = "📍 Auto Place",
    CurrentValue = Config.AutoPlace,
    Flag = "AutoPlace",
    Callback = function(Value) Config.AutoPlace = Value end
})

UnitTab:CreateToggle({
    Name = "⬆️ Auto Upgrade",
    CurrentValue = Config.AutoUpgrade,
    Flag = "AutoUpgrade",
    Callback = function(Value) Config.AutoUpgrade = Value end
})

UnitTab:CreateSection("🎯 Target & Limits")

UnitTab:CreateSlider({
    Name = "🔢 Max Units",
    Range = {1, 30},
    Increment = 1,
    Suffix = "Units",
    CurrentValue = Config.MaxUnits,
    Flag = "MaxUnits",
    Callback = function(Value) Config.MaxUnits = Value end
})

UnitTab:CreateDropdown({
    Name = "🎯 Targeting Mode",
    Options = {"Strongest", "Closest", "Boss"},
    CurrentOption = {"Strongest"},
    MultipleOptions = false,
    Callback = function(Option) Config.Targeting = Option[1] end
})

UnitTab:CreateButton({
    Name = "⚡ Upgrade All Now",
    Callback = function() UpgradeAll() end
})

-- [TAB 3: 🎁 GACHA]
local GachaTab = Window:CreateTab("🎁 Gacha", 4483345998)
GachaTab:CreateSection("🎰 Summon Settings")

GachaTab:CreateToggle({
    Name = "✨ Auto Summon",
    CurrentValue = Config.AutoSummon,
    Flag = "AutoSummon",
    Callback = function(Value) Config.AutoSummon = Value end
})

GachaTab:CreateDropdown({
    Name = "🔮 Summon Type",
    Options = {"x1", "x10"},
    CurrentOption = {"x10"},
    MultipleOptions = false,
    Callback = function(Option) Config.SummonType = Option[1] end
})

GachaTab:CreateSection("📜 Quest Settings")

GachaTab:CreateToggle({
    Name = "✅ Auto Claim Quests",
    CurrentValue = Config.AutoClaim,
    Flag = "AutoClaim",
    Callback = function(Value) Config.AutoClaim = Value end
})

GachaTab:CreateButton({
    Name = "🌟 Summon Now",
    Callback = function()
        local btn = FindButton(PG, "Summon")
        if btn then ClickButton(btn) end
    end
})

GachaTab:CreateButton({
    Name = "📦 Claim All Now",
    Callback = function() ClaimQuests() end
})-- [TAB 4: 📜 MACRO]
local MacroTab = Window:CreateTab("📜 Macro", 4483345998)
MacroTab:CreateSection("⏺️ Recording Controls")

MacroTab:CreateToggle({
    Name = "▶️ Use Macro",
    CurrentValue = Config.UseMacro,
    Flag = "UseMacro",
    Callback = function(Value) Config.UseMacro = Value end
})

MacroTab:CreateButton({
    Name = "⏺️ Start Recording",
    Callback = function()
        Config.MacroRecording = true
        Config.MacroData = {}
        Rayfield:Notify({ Title = "Macro", Content = "Started recording actions.", Duration = 3 })
    end
})

MacroTab:CreateButton({
    Name = "⏹️ Stop Recording",
    Callback = function()
        Config.MacroRecording = false
        Rayfield:Notify({ Title = "Macro", Content = "Stopped recording. Saved " .. #Config.MacroData .. " actions.", Duration = 3 })
    end
})

MacroTab:CreateSection("🎬 Playback")

MacroTab:CreateButton({
    Name = "▶️ Play Recording",
    Callback = function()
        if #Config.MacroData == 0 then
            Rayfield:Notify({ Title = "Macro", Content = "No macro data to play.", Duration = 3 })
            return
        end
        task.spawn(function()
            for _, action in ipairs(Config.MacroData) do
                task.wait(action.time)
                if action.type == "click" then
                    ClickButton(FindButton(PG, action.name))
                elseif action.type == "upgrade" then
                    UpgradeAll()
                end
            end
            Rayfield:Notify({ Title = "Macro", Content = "Playback finished.", Duration = 3 })
        end)
    end
})

-- [TAB 5: 🎨 THEME]
local ThemeTab = Window:CreateTab("🎨 Theme", 4483345998)
ThemeTab:CreateSection("🖌️ Appearance Customization")

ThemeTab:CreateDropdown({
    Name = "🎨 Select UI Theme",
    Options = {"Default", "Amethyst", "Dark", "Darker", "Light", "Aqua", "Rose"},
    CurrentOption = {"Default"},
    MultipleOptions = false,
    Callback = function(Option)
        local ThemeName = Option[1]
        pcall(function() Rayfield:ChangeTheme(ThemeName) end)
        Rayfield:Notify({ Title = "Theme Changed", Content = "Applied theme: " .. ThemeName, Duration = 3 })
    end
})

-- [TAB 6: 🛡️ SETTINGS]
local SettingsTab = Window:CreateTab("🛡️ Settings", 4483345998)
SettingsTab:CreateSection("🔒 Security & Safety")

SettingsTab:CreateToggle({
    Name = "🤖 Anti-AFK",
    CurrentValue = Config.AntiAFK,
    Flag = "AntiAFK",
    Callback = function(Value)
        Config.AntiAFK = Value
        if Value then StartAntiAFK() end
    end
})

SettingsTab:CreateToggle({
    Name = "⏱️ Human-like Delay",
    CurrentValue = Config.HumanDelay,
    Flag = "HumanDelay",
    Callback = function(Value) Config.HumanDelay = Value end
})

SettingsTab:CreateSection("⚡ Performance & Optimization")

SettingsTab:CreateToggle({
    Name = "🚀 FPS Boost",
    CurrentValue = Config.FPSBoost,
    Flag = "FPSBoost",
    Callback = function(Value)
        Config.FPSBoost = Value
        if Value then
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            Rayfield:Notify({ Title = "Performance", Content = "FPS Boost Enabled", Duration = 3 })
        else
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)
            Rayfield:Notify({ Title = "Performance", Content = "FPS Boost Disabled", Duration = 3 })
        end
    end
})

-- [TAB 7: 💬 DISCORD]
local DiscordTab = Window:CreateTab("💬 Discord", 4483345998)
DiscordTab:CreateSection("🔗 Webhook Integration")

DiscordTab:CreateInput({
    Name = "🌐 Webhook URL",
    CurrentValue = "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) Config.DiscordWebhook = Text end
})

DiscordTab:CreateToggle({
    Name = "📡 Enable Webhook",
    CurrentValue = Config.EnableWebhook,
    Flag = "EnableWebhook",
    Callback = function(Value) Config.EnableWebhook = Value end
})

DiscordTab:CreateSection("🧪 Testing")

DiscordTab:CreateButton({
    Name = "🔔 Test Webhook",
    Callback = function()
        if Config.DiscordWebhook == "" then
            Rayfield:Notify({ Title = "Error", Content = "Please enter a Webhook URL first.", Duration = 3 })
            return
        end
        local wasEnabled = Config.EnableWebhook
        Config.EnableWebhook = true
        SendWebhook("Test Message", "Thunder Hub webhook test successful!", 3066993)
        Config.EnableWebhook = wasEnabled
        Rayfield:Notify({ Title = "Success", Content = "Test message sent.", Duration = 3 })
    end
})

-- ============================================================
-- 7. STARTUP & INITIALIZATION
-- ============================================================
if Config.AntiAFK then StartAntiAFK() end
if Config.FPSBoost then
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
end

SendWebhook("Thunder Hub Started", "Player: " .. LP.Name .. "\nGame ID: " .. tostring(game.PlaceId), 3066993)

Rayfield:Notify({
    Title = "⚡ Thunder Hub Ready",
    Content = "Script loaded successfully. 7 Tabs Available.",
    Duration = 5,
    Image = 4483362458
})
