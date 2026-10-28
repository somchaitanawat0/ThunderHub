--[[
    Thunder Hub - Cameraman Tower Defense (Main Script - Part 1/2)
    ---------------------------------------------------------------
    Requires: ThunderUI.lua (loaded from GitHub)
    Features: Farm Loop, Unit Management, Anti-AFK, Discord Webhook
    ---------------------------------------------------------------
    Note: Part 1 contains 2 tabs (Farm, Units)
          Part 2 will add 4 more tabs (Gacha, Theme, Settings, Discord)
          Total 6 tabs - fits within ThunderUI TabBar width
]]

-- ============================================================
-- SECTION 1: SERVICES
-- ============================================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ============================================================
-- SECTION 2: LOAD UI (replace YOUR_NAME with your GitHub username)
-- ============================================================
local UI_URL = "https://raw.githubusercontent.com/somchaitanawat0/ThunderHub/refs/heads/main/ThunderUI.lua"

local UI_SUCCESS, UILib = pcall(function()
    return loadstring(game:HttpGet(UI_URL))()
end)

if not UI_SUCCESS or not UILib then
    warn("[Thunder] Failed to load ThunderUI.lua - check URL or connection")
    return
end

-- ============================================================
-- SECTION 3: CONFIG (default values)
-- ============================================================
local Config = {
    -- Map
    MapName = "Toilet City",
    Difficulty = "Easy",

    -- Farm
    AutoJoin = true,
    AutoVote = true,
    AutoSkip = true,
    AutoReplay = true,
    LeaveOnWin = false,
    LeaveOnFail = true,

    -- Units
    AutoPlace = true,
    AutoUpgrade = true,
    MaxUnits = 15,
    Targeting = "Strongest",

    -- Gacha
    AutoSummon = true,
    SummonType = "x10",
    AutoClaim = true,

    -- Security
    AntiAFK = true,
    HumanDelay = true,

    -- Performance
    FPSBoost = false,

    -- Discord
    DiscordWebhook = "",
    EnableWebhook = false,

    -- Theme
    CurrentTheme = "Blue",

    -- State (do not edit)
    IsFarming = false,
    Wins = 0,
    Losses = 0,
}

-- ============================================================
-- SECTION 4: HELPERS
-- ============================================================

-- Safe function wrapper
local function SafeCall(fn, ...)
    local success, err = pcall(fn, ...)
    if not success then
        warn("[Thunder Error] " .. tostring(err))
    end
    return success, err
end

-- Randomized delay (respects Human Delay setting)
local function RandomWait(min, max)
    if Config.HumanDelay then
        task.wait(math.random(min * 100, max * 100) / 100)
    else
        task.wait(min)
    end
end

-- Find a TextButton by name inside parent
local function FindButton(parent, name)
    if not parent then return nil end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Visible
           and obj.Name:lower():find(name:lower()) then
            return obj
        end
    end
    return nil
end

-- Click a button via VirtualUser
local function ClickButton(btn)
    if not btn or not btn.Visible then return false end
    return pcall(function()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(pos)
    end)
end

-- Fire a ProximityPrompt (with executor check)
local function FirePrompt(prompt)
    if not prompt then return false end
    if type(fireproximityprompt) ~= "function" then
        warn("[Thunder] executor does not support fireproximityprompt")
        return false
    end
    return pcall(fireproximityprompt, prompt)
end

-- ============================================================
-- SECTION 5: DISCORD WEBHOOK
-- ============================================================

-- Get executor request function
local function GetRequestFunction()
    if type(request) == "function" then return request end
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    return nil
end

local RequestFn = GetRequestFunction()

local function SendWebhook(title, desc, color)
    if not Config.EnableWebhook or Config.DiscordWebhook == "" then return end
    if not RequestFn then
        warn("[Thunder] executor has no request/syn.request - cannot send webhook")
        return
    end

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
-- SECTION 6: ANTI-AFK (function only - called in Part 2)
-- ============================================================
local AntiAFKStarted = false

local function StartAntiAFK()
    if AntiAFKStarted then return end
    AntiAFKStarted = true

    LP.Idled:Connect(function()
        -- Simulate click + movement
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
        pcall(function()
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end)

    print("[Anti-AFK] Enabled")
end

-- ============================================================
-- SECTION 7: GAME ACTIONS
-- ============================================================

-- Join target map
local function JoinMap()
    if not Config.AutoJoin then return end
    SafeCall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local actionText = obj.ActionText or ""
                if actionText:lower():find(Config.MapName:lower()) then
                    FirePrompt(obj)
                    return
                end
            end
        end
    end)
end

-- Vote for difficulty
local function VoteDifficulty()
    if not Config.AutoVote then return end
    task.wait(2)
    SafeCall(function()
        local btn = FindButton(PG, Config.Difficulty)
        if btn then ClickButton(btn) end
    end)
end

-- Skip current wave
local function SkipWave()
    if not Config.AutoSkip then return end
    SafeCall(function()
        local btn = FindButton(PG, "Skip")
        if btn then ClickButton(btn) end
    end)
end

-- Upgrade all units (capped by MaxUnits)
local function UpgradeAll()
    if not Config.AutoUpgrade then return end
    SafeCall(function()
        local count = 0
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible then
                local nameLower = obj.Name:lower()
                if nameLower:find("upgrade") and count < Config.MaxUnits then
                    ClickButton(obj)
                    RandomWait(0.15, 0.4)
                    count = count + 1
                end
            end
        end
    end)
end

-- Check if game ended (FIX: returns actual result, not pcall success)
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

    -- Return actual boolean result (not pcall success flag)
    return ok and result
end

-- ============================================================
-- SECTION 8: BUILD UI
-- ============================================================
local Hub = UILib.New({
    Title = "Thunder Hub | Cameraman TD",
    Theme = Config.CurrentTheme,
})

-- ============================================================
-- TAB 1: FARM
-- ============================================================
local FarmTab = Hub:AddTab("Farm")

Hub:AddInput(FarmTab, "Map Name", Config.MapName, function(v)
    Config.MapName = v
end)

Hub:AddDropdown(FarmTab, "Difficulty", {"Easy", "Normal", "Hard", "Insane"}, Config.Difficulty, function(v)
    Config.Difficulty = v
end)

Hub:AddToggle(FarmTab, "Auto Join Map", Config.AutoJoin, function(v)
    Config.AutoJoin = v
end)

Hub:AddToggle(FarmTab, "Auto Vote", Config.AutoVote, function(v)
    Config.AutoVote = v
end)

Hub:AddToggle(FarmTab, "Auto Skip Wave", Config.AutoSkip, function(v)
    Config.AutoSkip = v
end)

Hub:AddToggle(FarmTab, "Auto Replay", Config.AutoReplay, function(v)
    Config.AutoReplay = v
end)

Hub:AddToggle(FarmTab, "Leave On Win", Config.LeaveOnWin, function(v)
    Config.LeaveOnWin = v
end)

Hub:AddToggle(FarmTab, "Leave On Fail", Config.LeaveOnFail, function(v)
    Config.LeaveOnFail = v
end)

-- Start farm button
Hub:AddButton(FarmTab, "> Start Farm Loop", function()
    if Config.IsFarming then
        warn("[Thunder] Farm loop is already running")
        return
    end
    Config.IsFarming = true
    SendWebhook("Farm Started", "Map: " .. Config.MapName .. " | Diff: " .. Config.Difficulty, 3066993)

    task.spawn(function()
        while Config.IsFarming do
            JoinMap()
            task.wait(3)
            VoteDifficulty()
            task.wait(3)
            SkipWave()
            UpgradeAll()

            if CheckGameEnd() then
                task.wait(3)
            end
            task.wait(2)
        end
    end)
end)

-- Stop farm button
Hub:AddButton(FarmTab, "[] Stop Farm Loop", function()
    Config.IsFarming = false
    SendWebhook("Farm Stopped", "Wins: " .. Config.Wins .. " | Losses: " .. Config.Losses, 15158332)
end)

-- ============================================================
-- TAB 2: UNITS
-- ============================================================
local UnitTab = Hub:AddTab("Units")

Hub:AddToggle(UnitTab, "Auto Place", Config.AutoPlace, function(v)
    Config.AutoPlace = v
end)

Hub:AddToggle(UnitTab, "Auto Upgrade", Config.AutoUpgrade, function(v)
    Config.AutoUpgrade = v
end)

Hub:AddSlider(UnitTab, "Max Units", Config.MaxUnits, 1, 30, function(v)
    Config.MaxUnits = v
end)

Hub:AddDropdown(UnitTab, "Targeting", {"Strongest", "Closest", "Boss"}, Config.Targeting, function(v)
    Config.Targeting = v
end)

Hub:AddButton(UnitTab, "^ Upgrade All Now", function()
    UpgradeAll()
end)

-- ============================================================
-- END OF PART 1
-- ------------------------------------------------------------
-- Part 2 will add:
--   * Gacha tab (Summon, Claim, Equip Best, Redeem)
--   * Theme tab (Dropdown with 10 colors)
--   * Settings tab (Anti-AFK + Human Delay + FPS Boost)
--   * Discord tab (Webhook input + Test button)
--   * Startup (call StartAntiAFK + Discord notify + user notify)
-- ------------------------------------------------------------
-- Part 1 + Part 2 = 6 tabs total (fits TabBar width)
-- ============================================================-- ============================================================
-- SECTION 9: GACHA FUNCTIONS
-- ============================================================

-- Summon a unit (x1 or x10)
local function SummonUnit()
    if not Config.AutoSummon then return end
    SafeCall(function()
        local btn = FindButton(PG, "Summon")
        if btn then
            ClickButton(btn)
            RandomWait(1, 2)
        end
    end)
end

-- Claim all available quest/achievement rewards
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

-- Equip the best available units
local function EquipBest()
    SafeCall(function()
        local btn = FindButton(PG, "Equip Best") or FindButton(PG, "Best")
        if btn then ClickButton(btn) end
    end)
end

-- Redeem a promo code
local function RedeemCode(code)
    if not code or code == "" then return end
    SafeCall(function()
        -- Open codes UI
        local openBtn = FindButton(PG, "Code") or FindButton(PG, "Redeem")
        if not openBtn then
            warn("[Thunder] Codes button not found")
            return
        end
        ClickButton(openBtn)
        task.wait(0.5)

        -- Type code into first visible TextBox
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextBox") and obj.Visible then
                obj.Text = code
                task.wait(0.3)
                local confirm = FindButton(PG, "Redeem") or FindButton(PG, "Confirm") or FindButton(PG, "Submit")
                if confirm then ClickButton(confirm) end
                break
            end
        end
    end)
end

-- ============================================================
-- SECTION 10: TAB 3 - GACHA
-- ============================================================
local GachaTab = Hub:AddTab("Gacha")

Hub:AddToggle(GachaTab, "Auto Summon", Config.AutoSummon, function(v)
    Config.AutoSummon = v
end)

Hub:AddDropdown(GachaTab, "Summon Type", {"x1", "x10"}, Config.SummonType, function(v)
    Config.SummonType = v
end)

Hub:AddToggle(GachaTab, "Auto Claim Rewards", Config.AutoClaim, function(v)
    Config.AutoClaim = v
end)

Hub:AddButton(GachaTab, "* Summon Now", function()
    local wasAuto = Config.AutoSummon
    Config.AutoSummon = true
    SummonUnit()
    Config.AutoSummon = wasAuto
end)

Hub:AddButton(GachaTab, "* Claim All Now", function()
    local wasAuto = Config.AutoClaim
    Config.AutoClaim = true
    ClaimQuests()
    Config.AutoClaim = wasAuto
end)

Hub:AddButton(GachaTab, "* Equip Best", function()
    EquipBest()
end)

Hub:AddInput(GachaTab, "Redeem Code", "", function(v)
    if v ~= "" then
        RedeemCode(v)
    end
end)

-- ============================================================
-- SECTION 11: TAB 4 - THEME
-- ============================================================
local ThemeTab = Hub:AddTab("Theme")

-- Get all theme names from UI library
local themeNames = Hub:GetThemeNames()

Hub:AddDropdown(ThemeTab, "Select Theme", themeNames, Config.CurrentTheme, function(v)
    Config.CurrentTheme = v
    Hub:SetTheme(v)
    print("[Thunder] Theme changed to: " .. v)
end)

Hub:AddLabel(ThemeTab, "Theme: " .. Config.CurrentTheme)

Hub:AddLabel(ThemeTab, "Themes apply instantly to header, tabs, and buttons")

-- ============================================================
-- SECTION 12: TAB 5 - SETTINGS (Security + Performance)
-- ============================================================
local SettingsTab = Hub:AddTab("Settings")

Hub:AddToggle(SettingsTab, "Anti-AFK", Config.AntiAFK, function(v)
    Config.AntiAFK = v
    if v then StartAntiAFK() end
end)

Hub:AddToggle(SettingsTab, "Human-Like Delay", Config.HumanDelay, function(v)
    Config.HumanDelay = v
end)

Hub:AddToggle(SettingsTab, "FPS Boost", Config.FPSBoost, function(v)
    Config.FPSBoost = v
    if v then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        print("[Thunder] FPS Boost enabled")
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
        end)
        print("[Thunder] FPS Boost disabled")
    end
end)

Hub:AddButton(SettingsTab, "! Reset Win/Loss Counter", function()
    Config.Wins = 0
    Config.Losses = 0
    print("[Thunder] Counter reset - Wins: 0 | Losses: 0")
end)

-- ============================================================
-- SECTION 13: TAB 6 - DISCORD
-- ============================================================
local DiscordTab = Hub:AddTab("Discord")

Hub:AddInput(DiscordTab, "Webhook URL", Config.DiscordWebhook, function(v)
    Config.DiscordWebhook = v
end)

Hub:AddToggle(DiscordTab, "Enable Webhook", Config.EnableWebhook, function(v)
    Config.EnableWebhook = v
end)

Hub:AddButton(DiscordTab, "@ Test Webhook", function()
    if Config.DiscordWebhook == "" then
        warn("[Thunder] Webhook URL is empty - paste your Discord webhook first")
        return
    end
    -- Temporarily force enable for test
    local wasEnabled = Config.EnableWebhook
    Config.EnableWebhook = true
    SendWebhook("Test Message", "Thunder Hub webhook test successful!", 3066993)
    Config.EnableWebhook = wasEnabled
    print("[Thunder] Test webhook sent")
end)

Hub:AddButton(DiscordTab, "@ Send Farm Summary", function()
    if Config.DiscordWebhook == "" then
        warn("[Thunder] Webhook URL is empty")
        return
    end
    local wasEnabled = Config.EnableWebhook
    Config.EnableWebhook = true
    SendWebhook(
        "Farm Summary",
        "Wins: " .. Config.Wins .. " | Losses: " .. Config.Losses
        .. " | Map: " .. Config.MapName
        .. " | Diff: " .. Config.Difficulty,
        5763719
    )
    Config.EnableWebhook = wasEnabled
end)

-- ============================================================
-- SECTION 14: STARTUP
-- ============================================================

-- Start Anti-AFK if enabled
if Config.AntiAFK then
    StartAntiAFK()
end

-- Apply FPS Boost if enabled
if Config.FPSBoost then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

-- Notify Discord that hub started
SendWebhook(
    "Thunder Hub Started",
    "Player: " .. LP.Name .. "\nGame ID: " .. tostring(game.PlaceId),
    3066993
)

-- Console ready message
print("========================================")
print("[Thunder Hub] Ready!")
print("  Player: " .. LP.Name)
print("  Theme : " .. Config.CurrentTheme)
print("  Tabs  : 6 (Farm, Units, Gacha, Theme, Settings, Discord)")
print("  Tip   : Press '—' to minimize, drag MiniBar to move")
print("========================================")

-- ============================================================
-- END OF SCRIPT
-- ============================================================
