--[[
    ⚡ Thunder Hub - Cameraman Tower Defense (Fluent UI ฉบับสมบูรณ์)
    ฟีเจอร์: ฟาร์ม + ยูนิต + มาโคร + กาชา + ความปลอดภัย + ประสิทธิภาพ + Discord
    ธีม: 6 ธีมของ Fluent + บันทึกอัตโนมัติ
    วิธีใช้: loadstring(game:HttpGet("ลิงก์ไฟล์นี้"))()
]]

-- ============================================================
-- 1. โหลด Fluent UI + Addons
-- ============================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ============================================================
-- 2. ค่าตั้งต้น (ครบทุกฟีเจอร์)
-- ============================================================
local Config = {
    -- Discord
    DiscordWebhook = "",
    EnableWebhook = false,
    NotifyOnRare = true,
    NotifyOnDisconnect = true,

    -- ฟาร์ม
    MapName = "Toilet City",
    Difficulty = "ง่าย",
    AutoJoin = true,
    AutoVote = true,
    AutoSkip = true,
    AutoReplay = true,
    LeaveOnWin = false,
    LeaveOnFail = true,

    -- ยูนิต
    AutoPlace = true,
    AutoUpgrade = true,
    AutoSell = false,
    MaxUnits = 15,
    Targeting = "แรงสุด",

    -- กาชา
    AutoSummon = true,
    SummonType = "x10",
    AutoClaim = true,
    AutoEquipBest = true,
    AutoRedeem = true,

    -- ความปลอดภัย
    AntiAFK = true,
    HumanDelay = true,
    StreamerMode = false,

    -- ประสิทธิภาพ
    FPSBoost = true,
    RemoveEffects = true,
    ScreenMode = "ปกติ",

    -- มาโคร
    UseMacro = false,
    MacroName = "ค่าเริ่มต้น",
}

-- ============================================================
-- 3. สร้างหน้าต่าง Fluent
-- ============================================================
local Window = Fluent:CreateWindow({
    Title = "⚡ Thunder Hub | Cameraman TD",
    SubTitle = "Full Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ============================================================
-- 4. ระบบธีม (6 ธีม + บันทึก)
-- ============================================================
local Themes = {"Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose"}
local ThemeFile = "ThunderHub/Theme.txt"

if not isfolder("ThunderHub") then makefolder("ThunderHub") end
if not isfile(ThemeFile) then writefile(ThemeFile, "Dark") end

local CurrentTheme = "Dark"
local ok, saved = pcall(readfile, ThemeFile)
if ok and saved and saved ~= "" then CurrentTheme = saved end
Fluent:SetTheme(CurrentTheme)

-- ============================================================
-- 5. ฟังก์ชันช่วยเหลือ
-- ============================================================
local function SafeCall(fn, ...)
    local success, err = pcall(fn, ...)
    if not success then
        warn("[Thunder] " .. tostring(err))
        if Config.EnableWebhook and Config.DiscordWebhook ~= "" then
            task.spawn(function()
                pcall(function()
                    HttpService:PostAsync(Config.DiscordWebhook, HttpService:JSONEncode({
                        content = "⚠️ **Error**: " .. tostring(err)
                    }))
                end)
            end)
        end
    end
    return success
end

local function RandomWait(min, max)
    if Config.HumanDelay then
        task.wait(math.random(min * 100, max * 100) / 100)
    else
        task.wait(min)
    end
end

local function FindButton(parent, name)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Name:lower():find(name:lower()) then
            return obj
        end
    end
    return nil
end

local function FindLabel(parent, name)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Name:lower():find(name:lower()) then
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

local function GetPing()
    local ok, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and ping or 50
end

-- ============================================================
-- 6. ระบบ Discord Webhook
-- ============================================================
local Discord = {}

function Discord.Send(title, desc, color)
    if not Config.EnableWebhook or Config.DiscordWebhook == "" then return end
    task.spawn(function()
        pcall(function()
            HttpService:PostAsync(Config.DiscordWebhook, HttpService:JSONEncode({
                username = "Thunder Hub",
                embeds = {{
                    title = title,
                    description = desc,
                    color = color or 3447003,
                    timestamp = DateTime.now():ToIsoDate(),
                    footer = { text = "Thunder Hub | " .. LP.Name }
                }}
            }), Enum.HttpContentType.ApplicationJson)
        end)
    end)
end

function Discord.NotifyRare(name, rarity)
    if not Config.NotifyOnRare then return end
    Discord.Send("🎉 พบยูนิตหายาก!", "**" .. name .. "** (" .. rarity .. ")", 15844367)
end

function Discord.NotifySummary(wins, losses)
    Discord.Send("📊 สรุปการฟาร์ม", "ชนะ: " .. wins .. " | แพ้: " .. losses, 5763719)
end

function Discord.NotifyDisconnect(reason)
    if not Config.NotifyOnDisconnect then return end
    Discord.Send("⚠️ หลุด/ติดขัด", tostring(reason), 15158332)
end

-- ============================================================
-- 7. ตัวแปรสถานะ
-- ============================================================
local State = {
    Running = true,
    Wins = 0,
    Losses = 0,
    Farming = false,
    ScreenGui = nil,
    StreamerGui = nil,
}

-- ============================================================
-- 8. Anti-AFK + Streamer Mode
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
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.1)
                    hum:Move(Vector3.new(0, 0, -1), true)
                    task.wait(0.3)
                    hum:Move(Vector3.zero, true)
                end
            end
        end)
    end)
    print("[Anti-AFK] เปิดแล้ว")
end

local function ToggleStreamerMode(state)
    if State.StreamerGui then
        State.StreamerGui:Destroy()
        State.StreamerGui = nil
    end
    if not state then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "StreamerOverlay"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999998
    gui.Parent = PG

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundTransparency = 1
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.3, 0.05)
    label.Position = UDim2.fromScale(0.01, 0.01)
    label.BackgroundColor3 = Color3.new(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = "🎭 โหมดสตรีมเมอร์"
    label.TextScaled = true
    label.Parent = frame

    State.StreamerGui = gui
end

-- ============================================================
-- 9. ระบบประสิทธิภาพ
-- ============================================================
local function ApplyFPSBoost()
    if not Config.FPSBoost then return end
    SafeCall(function()
        if Config.RemoveEffects then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = false
                end
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function SetScreenMode(mode)
    if State.ScreenGui then State.ScreenGui:Destroy() State.ScreenGui = nil end
    if mode == "ปกติ" then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ThunderOverlay"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = PG

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = (mode == "จอขาว") and Color3.new(1,1,1) or Color3.new(0,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    State.ScreenGui = gui
end-- ============================================================
-- 10. ระบบฟาร์ม
-- ============================================================
local Farm = {}

function Farm.JoinMap()
    if not Config.AutoJoin then return end
    SafeCall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText:lower():find(Config.MapName:lower()) then
                fireproximityprompt(obj)
                return
            end
            if obj:IsA("BasePart") and obj.Name:lower():find(Config.MapName:lower()) then
                local char = LP.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end)
end

function Farm.VoteDifficulty()
    if not Config.AutoVote then return end
    task.wait(2)
    SafeCall(function()
        local btn = FindButton(PG, Config.Difficulty)
        if btn then ClickButton(btn) end
    end)
end

function Farm.SkipWave()
    if not Config.AutoSkip then return end
    SafeCall(function()
        local btn = FindButton(PG, "Skip")
        if btn and btn.Visible then ClickButton(btn) end
    end)
end

function Farm.CheckEnd()
    local win = FindLabel(PG, "Victory") or FindLabel(PG, "Win")
    local lose = FindLabel(PG, "Defeat") or FindLabel(PG, "Lose")

    if win and win.Visible then
        State.Wins = State.Wins + 1
        Discord.NotifySummary(State.Wins, State.Losses)
        if Config.LeaveOnWin then
            LP:Kick("ออกอัตโนมัติเมื่อชนะ")
        else
            local btn = FindButton(PG, "Play Again") or FindButton(PG, "Replay")
            if btn and Config.AutoReplay then ClickButton(btn) end
        end
        return true
    elseif lose and lose.Visible then
        State.Losses = State.Losses + 1
        if Config.LeaveOnFail then
            LP:Kick("ออกอัตโนมัติเมื่อแพ้")
        end
        return true
    end
    return false
end

function Farm.StartLoop()
    if State.Farming then return end
    State.Farming = true

    task.spawn(function()
        while State.Farming and State.Running do
            Farm.JoinMap()
            task.wait(3)
            Farm.VoteDifficulty()
            task.wait(3)
            Farm.SkipWave()
            Unit.UpgradeAll()
            if Farm.CheckEnd() then task.wait(3) end
            task.wait(2)
        end
    end)
end

function Farm.StopLoop()
    State.Farming = false
end

-- ============================================================
-- 11. ระบบยูนิต
-- ============================================================
local Unit = {}

function Unit.FindBestSpot()
    local waypoints = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and
           (obj.Name:lower():find("path") or obj.Name:lower():find("waypoint")) then
            table.insert(waypoints, obj)
        end
    end
    if #waypoints == 0 then return nil end
    return waypoints[1].CFrame + Vector3.new(0, 2, 0)
end

function Unit.Place(unitName)
    if not Config.AutoPlace then return end
    SafeCall(function()
        local hotbar = PG:FindFirstChild("Hotbar") or PG:FindFirstChild("UnitBar")
        if not hotbar then return end

        local slot = FindButton(hotbar, unitName)
        if slot then
            ClickButton(slot)
            RandomWait(0.2, 0.5)
            local spot = Unit.FindBestSpot()
            if spot then
                local mouse = LP:GetMouse()
                pcall(function()
                    mouse.Hit = spot
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(500, 500))
                end)
            end
        end
    end)
end

function Unit.UpgradeAll()
    if not Config.AutoUpgrade then return end
    SafeCall(function()
        local upgradeBtns = {}
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible then
                if obj.Name == "Upgrade" or (obj.Text and obj.Text:find("Upgrade")) then
                    table.insert(upgradeBtns, obj)
                end
            end
        end
        for _, btn in ipairs(upgradeBtns) do
            ClickButton(btn)
            RandomWait(0.15, 0.4)
        end
    end)
end

function Unit.SellWeak()
    if not Config.AutoSell then return end
    SafeCall(function()
        local sellBtns = {}
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible and obj.Name:lower():find("sell") then
                table.insert(sellBtns, obj)
            end
        end
        for _, btn in ipairs(sellBtns) do
            ClickButton(btn)
            RandomWait(0.3, 0.8)
        end
    end)
end

function Unit.SetTargeting(mode)
    SafeCall(function()
        local btn = FindButton(PG, mode) or FindButton(PG, "Target")
        if btn then ClickButton(btn) end
    end)
end

-- ============================================================
-- 12. ระบบกาชา
-- ============================================================
local Gacha = {}

function Gacha.Summon()
    if not Config.AutoSummon then return end
    SafeCall(function()
        local btn = FindButton(PG, "Summon")
        if btn and btn.Visible then
            ClickButton(btn)
            RandomWait(1, 2)
            local result = PG:FindFirstChild("SummonResult")
            if result then
                for _, obj in ipairs(result:GetDescendants()) do
                    if obj:IsA("TextLabel") then
                        local txt = obj.Text:lower()
                        if txt:find("godly") or txt:find("mythic") or txt:find("legendary") then
                            Discord.NotifyRare(obj.Text, "Rare")
                        end
                    end
                end
            end
        end
    end)
end

function Gacha.Claim()
    if not Config.AutoClaim then return end
    SafeCall(function()
        for _, obj in ipairs(PG:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible then
                if obj.Name:lower():find("claim") or (obj.Text and obj.Text:find("Claim")) then
                    ClickButton(obj)
                    RandomWait(0.5, 1)
                end
            end
        end
    end)
end

function Gacha.Redeem(code)
    SafeCall(function()
        local btn = FindButton(PG, "Code") or FindButton(PG, "Redeem")
        if btn then
            ClickButton(btn)
            task.wait(0.5)
            for _, obj in ipairs(PG:GetDescendants()) do
                if obj:IsA("TextBox") and obj.Visible then
                    obj.Text = code
                    task.wait(0.3)
                    local confirm = FindButton(PG, "Redeem") or FindButton(PG, "Confirm")
                    if confirm then ClickButton(confirm) end
                    break
                end
            end
        end
    end)
end

function Gacha.EquipBest()
    if not Config.AutoEquipBest then return end
    SafeCall(function()
        local btn = FindButton(PG, "Equip Best") or FindButton(PG, "Best")
        if btn then ClickButton(btn) end
    end)
  end-- ============================================================
-- 13. ระบบมาโคร
-- ============================================================
local Macro = {
    Recording = {},
    IsRecording = false,
    Presets = {
        ["ค่าเริ่มต้น"] = {},
        ["ToiletCity_ง่าย"] = {
            {time = 0, action = "place", name = "Speakerman"},
            {time = 2, action = "upgrade"},
            {time = 5, action = "place", name = "Cameraman"},
        },
        ["Hard_ToiletCity"] = {
            {time = 0, action = "place", name = "Speakerman"},
            {time = 1.5, action = "place", name = "Cameraman"},
            {time = 3, action = "upgrade"},
            {time = 6, action = "upgrade"},
            {time = 10, action = "sell"},
        }
    }
}

function Macro.StartRecording()
    Macro.Recording = {}
    Macro.IsRecording = true
    print("[Macro] เริ่มบันทึก")
end

function Macro.StopRecording()
    Macro.IsRecording = false
    print("[Macro] หยุดบันทึก จำนวน: " .. #Macro.Recording)
end

function Macro.Play(name)
    local preset = Macro.Presets[name]
    if not preset or #preset == 0 then return end
    task.spawn(function()
        for _, step in ipairs(preset) do
            task.wait(step.time or 0)
            if step.action == "place" then
                Unit.Place(step.name)
            elseif step.action == "upgrade" then
                Unit.UpgradeAll()
            elseif step.action == "sell" then
                Unit.SellWeak()
            end
        end
    end)
end

-- ============================================================
-- 14. แท็บฟาร์ม
-- ============================================================
local FarmTab = Window:AddTab({ Title = "ฟาร์ม", Icon = "gamepad-2" })
local FarmGroup = FarmTab:AddLeftGroupbox("ตั้งค่าแมตช์")

FarmGroup:AddInput("MapName", {
    Title = "ชื่อแผนที่",
    Default = Config.MapName,
    Placeholder = "Toilet City",
    Callback = function(v) Config.MapName = v end
})

FarmGroup:AddDropdown("Difficulty", {
    Title = "ระดับความยาก",
    Values = {"ง่าย", "ปกติ", "ยาก", "โหด"},
    Default = 1,
    Multi = false,
    Callback = function(v) Config.Difficulty = v end
})

FarmGroup:AddToggle("AutoJoin", {
    Title = "เข้าแผนที่อัตโนมัติ",
    Default = Config.AutoJoin,
    Callback = function(v) Config.AutoJoin = v end
})

FarmGroup:AddToggle("AutoVote", {
    Title = "โหวตความยากอัตโนมัติ",
    Default = Config.AutoVote,
    Callback = function(v) Config.AutoVote = v end
})

FarmGroup:AddToggle("AutoSkip", {
    Title = "ข้ามเวฟอัตโนมัติ",
    Default = Config.AutoSkip,
    Callback = function(v) Config.AutoSkip = v end
})

FarmGroup:AddToggle("AutoReplay", {
    Title = "เล่นซ้ำอัตโนมัติ",
    Default = Config.AutoReplay,
    Callback = function(v) Config.AutoReplay = v end
})

FarmGroup:AddToggle("LeaveOnWin", {
    Title = "ออกเมื่อชนะ",
    Default = Config.LeaveOnWin,
    Callback = function(v) Config.LeaveOnWin = v end
})

FarmGroup:AddToggle("LeaveOnFail", {
    Title = "ออกเมื่อแพ้",
    Default = Config.LeaveOnFail,
    Callback = function(v) Config.LeaveOnFail = v end
})

FarmGroup:AddButton({
    Title = "🚀 เริ่มฟาร์มทันที",
    Callback = function()
        Farm.StartLoop()
        Fluent:Notify({ Title = "เริ่มฟาร์ม", Content = "ระบบกำลังทำงาน", Duration = 3 })
    end
})

FarmGroup:AddButton({
    Title = "⏹️ หยุดฟาร์ม",
    Callback = function()
        Farm.StopLoop()
        Fluent:Notify({ Title = "หยุดฟาร์ม", Content = "ระบบหยุดแล้ว", Duration = 3 })
    end
})

-- ============================================================
-- 15. แท็บยูนิต
-- ============================================================
local UnitTab = Window:AddTab({ Title = "ยูนิต", Icon = "swords" })
local UnitGroup = UnitTab:AddLeftGroupbox("ตั้งค่ายูนิต")

UnitGroup:AddToggle("AutoPlace", {
    Title = "วางยูนิตอัตโนมัติ",
    Default = Config.AutoPlace,
    Callback = function(v) Config.AutoPlace = v end
})

UnitGroup:AddToggle("AutoUpgrade", {
    Title = "อัปเกรดอัตโนมัติ",
    Default = Config.AutoUpgrade,
    Callback = function(v) Config.AutoUpgrade = v end
})

UnitGroup:AddToggle("AutoSell", {
    Title = "ขายยูนิตอ่อน",
    Default = Config.AutoSell,
    Callback = function(v) Config.AutoSell = v end
})

UnitGroup:AddSlider("MaxUnits", {
    Title = "จำนวนยูนิตสูงสุด",
    Default = Config.MaxUnits,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(v) Config.MaxUnits = v end
})

UnitGroup:AddDropdown("Targeting", {
    Title = "โหมดเป้าหมาย",
    Values = {"แรงสุด", "ใกล้สุด", "บอส"},
    Default = 1,
    Multi = false,
    Callback = function(v)
        Config.Targeting = v
        Unit.SetTargeting(v)
    end
})

UnitGroup:AddButton({
    Title = "อัปเกรดทั้งหมด",
    Callback = function() Unit.UpgradeAll() end
})

UnitGroup:AddButton({
    Title = "ขายยูนิตอ่อน",
    Callback = function() Unit.SellWeak() end
})

-- ============================================================
-- 16. แท็บกาชา
-- ============================================================
local GachaTab = Window:AddTab({ Title = "กาชา", Icon = "gift" })
local GachaGroup = GachaTab:AddLeftGroupbox("ตั้งค่ากาชา")

GachaGroup:AddToggle("AutoSummon", {
    Title = "สุ่มยูนิตอัตโนมัติ",
    Default = Config.AutoSummon,
    Callback = function(v) Config.AutoSummon = v end
})

GachaGroup:AddDropdown("SummonType", {
    Title = "ประเภทสุ่ม",
    Values = {"x1", "x10"},
    Default = 2,
    Multi = false,
    Callback = function(v) Config.SummonType = v end
})

GachaGroup:AddToggle("AutoClaim", {
    Title = "รับเควสอัตโนมัติ",
    Default = Config.AutoClaim,
    Callback = function(v) Config.AutoClaim = v end
})

GachaGroup:AddToggle("AutoEquipBest", {
    Title = "ใส่ยูนิตดีที่สุด",
    Default = Config.AutoEquipBest,
    Callback = function(v) Config.AutoEquipBest = v end
})

GachaGroup:AddButton({
    Title = "🎁 สุ่มเลย",
    Callback = function() Gacha.Summon() end
})

GachaGroup:AddButton({
    Title = "📜 รับเควสทั้งหมด",
    Callback = function() Gacha.Claim() end
})

GachaGroup:AddButton({
    Title = "✨ ใส่ยูนิตดีที่สุด",
    Callback = function() Gacha.EquipBest() end
})

GachaGroup:AddInput("RedeemCode", {
    Title = "ใส่โค้ด",
    Default = "",
    Placeholder = "CODE123",
    Callback = function(v)
        if v ~= "" then Gacha.Redeem(v) end
    end
})

-- ============================================================
-- 17. แท็บมาโคร
-- ============================================================
local MacroTab = Window:AddTab({ Title = "มาโคร", Icon = "video" })
local MacroGroup = MacroTab:AddLeftGroupbox("ระบบมาโคร")

MacroGroup:AddToggle("UseMacro", {
    Title = "ใช้มาโคร",
    Default = Config.UseMacro,
    Callback = function(v) Config.UseMacro = v end
})

MacroGroup:AddDropdown("MacroName", {
    Title = "เลือกชุดมาโคร",
    Values = {"ค่าเริ่มต้น", "ToiletCity_ง่าย", "Hard_ToiletCity"},
    Default = 1,
    Multi = false,
    Callback = function(v) Config.MacroName = v end
})

MacroGroup:AddButton({
    Title = "▶️ เล่นมาโคร",
    Callback = function() Macro.Play(Config.MacroName) end
})

MacroGroup:AddButton({
    Title = "⏺️ เริ่มบันทึก",
    Callback = function() Macro.StartRecording() end
})

MacroGroup:AddButton({
    Title = "⏹️ หยุดบันทึก",
    Callback = function() Macro.StopRecording() end
})

-- ============================================================
-- 18. แท็บธีมสี
-- ============================================================
local ThemeTab = Window:AddTab({ Title = "🎨 ธีมสี", Icon = "palette" })
local ThemeGroup = ThemeTab:AddLeftGroupbox("เปลี่ยนสีพื้นหลัง UI (6 ธีม)")

ThemeGroup:AddDropdown("ThemeSelector", {
    Title = "เลือกธีม",
    Values = Themes,
    Default = CurrentTheme,
    Multi = false,
    Callback = function(value)
        Fluent:SetTheme(value)
        pcall(function() writefile(ThemeFile, value) end)
        Fluent:Notify({ Title = "เปลี่ยนธีม", Content = "ธีม: " .. value, Duration = 3 })
    end
})

ThemeGroup:AddLabel("ธีมปัจจุบัน: " .. CurrentTheme)-- ============================================================
-- 19. แท็บความปลอดภัย
-- ============================================================
local SecurityTab = Window:AddTab({ Title = "ความปลอดภัย", Icon = "shield" })
local SecurityGroup = SecurityTab:AddLeftGroupbox("ตั้งค่าความปลอดภัย")

SecurityGroup:AddToggle("AntiAFK", {
    Title = "กันการเตะ (Anti-AFK)",
    Default = Config.AntiAFK,
    Callback = function(v)
        Config.AntiAFK = v
        if v then StartAntiAFK() end
    end
})

SecurityGroup:AddToggle("HumanDelay", {
    Title = "หน่วงแบบมนุษย์",
    Default = Config.HumanDelay,
    Callback = function(v) Config.HumanDelay = v end
})

SecurityGroup:AddToggle("StreamerMode", {
    Title = "โหมดสตรีมเมอร์ (ซ่อนชื่อ)",
    Default = Config.StreamerMode,
    Callback = function(v)
        Config.StreamerMode = v
        ToggleStreamerMode(v)
    end
})

-- ============================================================
-- 20. แท็บประสิทธิภาพ
-- ============================================================
local PerfTab = Window:AddTab({ Title = "ประสิทธิภาพ", Icon = "zap" })
local PerfGroup = PerfTab:AddLeftGroupbox("ตั้งค่าประสิทธิภาพ")

PerfGroup:AddToggle("FPSBoost", {
    Title = "เพิ่ม FPS",
    Default = Config.FPSBoost,
    Callback = function(v)
        Config.FPSBoost = v
        if v then ApplyFPSBoost() end
    end
})

PerfGroup:AddToggle("RemoveEffects", {
    Title = "ลบเอฟเฟกต์",
    Default = Config.RemoveEffects,
    Callback = function(v) Config.RemoveEffects = v end
})

PerfGroup:AddDropdown("ScreenMode", {
    Title = "โหมดหน้าจอ",
    Values = {"ปกติ", "จอดำ", "จอขาว"},
    Default = 1,
    Multi = false,
    Callback = function(v)
        Config.ScreenMode = v
        SetScreenMode(v)
    end
})

-- ============================================================
-- 21. แท็บ Discord
-- ============================================================
local DiscordTab = Window:AddTab({ Title = "Discord", Icon = "message-circle" })
local DiscordGroup = DiscordTab:AddLeftGroupbox("แจ้งเตือน Discord")

DiscordGroup:AddInput("Webhook", {
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v) Config.DiscordWebhook = v end
})

DiscordGroup:AddToggle("EnableWebhook", {
    Title = "เปิดแจ้งเตือน",
    Default = Config.EnableWebhook,
    Callback = function(v) Config.EnableWebhook = v end
})

DiscordGroup:AddToggle("NotifyOnRare", {
    Title = "แจ้งเมื่อได้ยูนิตหายาก",
    Default = Config.NotifyOnRare,
    Callback = function(v) Config.NotifyOnRare = v end
})

DiscordGroup:AddToggle("NotifyOnDisconnect", {
    Title = "แจ้งเมื่อหลุด/ติดขัด",
    Default = Config.NotifyOnDisconnect,
    Callback = function(v) Config.NotifyOnDisconnect = v end
})

DiscordGroup:AddButton({
    Title = "🔔 ทดสอบส่งข้อความ",
    Callback = function()
        if Config.DiscordWebhook == "" then
            Fluent:Notify({ Title = "ผิดพลาด", Content = "กรุณาใส่ Webhook URL", Duration = 3 })
            return
        end
        pcall(function()
            HttpService:PostAsync(Config.DiscordWebhook, HttpService:JSONEncode({
                content = "✅ **Thunder Hub** ทดสอบสำเร็จ!"
            }), Enum.HttpContentType.ApplicationJson)
            Fluent:Notify({ Title = "สำเร็จ", Content = "ส่งข้อความแล้ว", Duration = 3 })
        end)
    end
})

DiscordGroup:AddButton({
    Title = "📊 ส่งสรุปการฟาร์ม",
    Callback = function()
        Discord.NotifySummary(State.Wins, State.Losses)
        Fluent:Notify({ Title = "ส่งแล้ว", Content = "สรุปการฟาร์มถูกส่ง", Duration = 3 })
    end
})

-- ============================================================
-- 22. เริ่มระบบทั้งหมด
-- ============================================================
if Config.AntiAFK then StartAntiAFK() end
if Config.FPSBoost then ApplyFPSBoost() end
if Config.StreamerMode then ToggleStreamerMode(true) end

-- แจ้ง Discord เริ่มทำงาน
Discord.Send("🚀 Thunder Hub เริ่มทำงาน", "เข้าเกม: " .. game.PlaceId, 3066993)

-- ตรวจสอบการหลุด
LP.OnTeleport:Connect(function()
    Discord.NotifyDisconnect("ผู้เล่นถูกวาร์ป/หลุด")
end)

-- แจ้งผู้ใช้
Fluent:Notify({
    Title = "⚡ Thunder Hub พร้อมใช้งาน",
    Content = "เลือกฟีเจอร์ได้ที่แท็บด้านซ้าย",
    Duration = 5
})

-- ============================================================
-- 23. โหลด SaveManager (บันทึกค่าอัตโนมัติ)
-- ============================================================
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("ThunderHub")
SaveManager:BuildConfigSection(ThemeTab)
SaveManager:LoadAutoloadConfig()

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("ThunderHub")
InterfaceManager:BuildInterfaceSection(ThemeTab)
