--[[
    Thunder UI - Custom Fluent-Style Library
    Features: Left Sidebar, Draggable Window, Minimize to Draggable Bar
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Themes = {
    ["Blue"]     = Color3.fromRGB(52, 152, 219),
    ["Cerulean"] = Color3.fromRGB(0, 123, 167),
    ["Green"]    = Color3.fromRGB(46, 204, 113),
    ["Red"]      = Color3.fromRGB(231, 76, 60),
    ["Purple"]   = Color3.fromRGB(155, 89, 182),
    ["Yellow"]   = Color3.fromRGB(241, 196, 15),
    ["Orange"]   = Color3.fromRGB(230, 126, 34),
    ["Pink"]     = Color3.fromRGB(255, 105, 180),
    ["Teal"]     = Color3.fromRGB(26, 188, 156),
    ["Gray"]     = Color3.fromRGB(149, 165, 166),
}

local UI = {}
UI.__index = UI

function UI.new(options)
    local self = setmetatable({}, UI)
    self.Theme = options.Theme or "Blue"
    self.Title = options.Title or "Thunder Hub"
    self.Tabs = {}
    self.TabButtons = {}
    self:Build()
    return self
end

function UI:GetColor()
    return Themes[self.Theme] or Themes["Blue"]
end

function UI:Build()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ThunderHubUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.IgnoreGuiInset = true
    self.ScreenGui.DisplayOrder = 9999
    self.ScreenGui.Parent = PG

    -- Main Window Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.fromOffset(600, 400)
    self.MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.MainFrame

    self.MainStroke = Instance.new("UIStroke")
    self.MainStroke.Color = self:GetColor()
    self.MainStroke.Thickness = 2
    self.MainStroke.Parent = self.MainFrame

    -- Top Bar (Draggable Handle)
    self.TopBar = Instance.new("Frame")
    self.TopBar.Size = UDim2.new(1, 0, 0, 36)
    self.TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.TopBar.BorderSizePixel = 0
    self.TopBar.Parent = self.MainFrame

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = self.TopBar

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.fromOffset(15, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = self.TopBar

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(24, 24)
    minBtn.Position = UDim2.new(1, -60, 0.5, -12)
    minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.new(1, 1, 1)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.BorderSizePixel = 0
    minBtn.Parent = self.TopBar

    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 6)
    mc.Parent = minBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(24, 24)
    closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = self.TopBar

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = closeBtn

    -- Left Sidebar
    self.Sidebar = Instance.new("ScrollingFrame")
    self.Sidebar.Size = UDim2.new(0, 150, 1, -36)
    self.Sidebar.Position = UDim2.fromOffset(0, 36)
    self.Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.ScrollBarThickness = 2
    self.Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.Sidebar.Parent = self.MainFrame

    local sideLayout = Instance.new("UIListLayout")
    sideLayout.Padding = UDim.new(0, 4)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Parent = self.Sidebar

    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingTop = UDim.new(0, 8)
    sidePad.PaddingLeft = UDim.new(0, 8)
    sidePad.PaddingRight = UDim.new(0, 8)
    sidePad.Parent = self.Sidebar

    -- Content Area (Right Side)
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -150, 1, -36)
    self.ContentArea.Position = UDim2.fromOffset(150, 36)
    self.ContentArea.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.Parent = self.MainFrame

    local cc2 = Instance.new("UICorner")
    cc2.CornerRadius = UDim.new(0, 8)
    cc2.Parent = self.ContentArea

    -- Build MiniBar
    self:BuildMiniBar()

    -- Enable Dragging
    self:MakeDraggable(self.MainFrame, self.TopBar)
    self:MakeDraggable(self.MiniBar, self.MiniBar)

    -- Button Connections
    minBtn.MouseButton1Click:Connect(function() self:Minimize() end)
    closeBtn.MouseButton1Click:Connect(function() self.ScreenGui:Destroy() end)
end

function UI:BuildMiniBar()
    self.MiniBar = Instance.new("Frame")
    self.MiniBar.Size = UDim2.fromOffset(250, 36)
    self.MiniBar.Position = self.MainFrame.Position
    self.MiniBar.BackgroundColor3 = self:GetColor()
    self.MiniBar.BorderSizePixel = 0
    self.MiniBar.Visible = false
    self.MiniBar.Parent = self.ScreenGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = self.MiniBar

    self.ExpandBtn = Instance.new("TextButton")
    self.ExpandBtn.Size = UDim2.fromOffset(80, 26)
    self.ExpandBtn.Position = UDim2.fromOffset(5, 5)
    self.ExpandBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.ExpandBtn.Text = "Open"
    self.ExpandBtn.TextColor3 = self:GetColor()
    self.ExpandBtn.Font = Enum.Font.GothamBold
    self.ExpandBtn.TextSize = 12
    self.ExpandBtn.BorderSizePixel = 0
    self.ExpandBtn.Parent = self.MiniBar

    local ec = Instance.new("UICorner")
    ec.CornerRadius = UDim.new(0, 6)
    ec.Parent = self.ExpandBtn

    self.ExpandBtn.MouseButton1Click:Connect(function() self:Expand() end)
end

function UI:Minimize()
    self.MiniBar.Position = self.MainFrame.Position
    self.MainFrame.Visible = false
    self.MiniBar.Visible = true
end

function UI:Expand()
    self.MainFrame.Position = self.MiniBar.Position
    self.MainFrame.Visible = true
    self.MiniBar.Visible = false
end

function UI:MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function UI:AddTab(name)
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -10)
    content.Position = UDim2.fromOffset(5, 5)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 4
    content.Visible = (#self.Tabs == 0)
    content.Parent = self.ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = (#self.Tabs == 0) and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(35, 35, 35)
    btn.Text = "  " .. name
    btn.TextColor3 = (#self.Tabs == 0) and self:GetColor() or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.BorderSizePixel = 0
    btn.Parent = self.Sidebar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    self.Tabs[name] = content
    table.insert(self.TabButtons, {Name = name, Button = btn})

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)

    return content
end

function UI:SwitchTab(name)
    for n, frame in pairs(self.Tabs) do
        frame.Visible = (n == name)
    end
    for _, t in ipairs(self.TabButtons) do
        if t.Name == name then
            t.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            t.Button.TextColor3 = self:GetColor()
        else
            t.Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            t.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

function UI:AddButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = self:GetColor()
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then warn("[UI] " .. tostring(err)) end
    end)
    return btn
end

function UI:AddToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.fromOffset(44, 24)
    toggleBtn.Position = UDim2.new(1, -54, 0.5, -12)
    toggleBtn.BackgroundColor3 = default and self:GetColor() or Color3.fromRGB(80, 80, 80)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = container

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 12)
    tc.Parent = toggleBtn

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and self:GetColor() or Color3.fromRGB(80, 80, 80)
        toggleBtn.Text = state and "ON" or "OFF"
        local ok, err = pcall(callback, state)
        if not ok then warn("[UI] " .. tostring(err)) end
    end)
    return container
end

function UI:AddSlider(parent, text, default, min, max, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.fromOffset(10, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 1, -18)
    bar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 3)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = self:GetColor()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 3)
    fc.Parent = fill

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = input.Position.X
            local rel = math.clamp((mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + rel * (max - min) + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = text .. ": " .. value
            local ok, err = pcall(callback, value)
            if not ok then warn("[UI] " .. tostring(err)) end
        end
    end)
    return container
end

function UI:AddInput(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    container.BorderSizePixel = 0
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -145, 0, 24)
    box.Position = UDim2.new(1, -135, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    box.Text = default
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextTruncate = Enum.TextTruncate.AtEnd
    box.BorderSizePixel = 0
    box.Parent = container

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = box

    box.FocusLost:Connect(function()
        local ok, err = pcall(callback, box.Text)
        if not ok then warn("[UI] " .. tostring(err)) end
    end)
    return container
end

function UI:AddDropdown(parent, text, options, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -145, 0, 24)
    btn.Position = UDim2.new(1, -135, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = default
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.BorderSizePixel = 0
    btn.Parent = container

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -145, 0, #options * 26)
    listFrame.Position = UDim2.new(0, 135, 1, 2)
    listFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 20
    listFrame.Parent = container

    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 6)
    lc.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listFrame

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 26)
        ob.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        ob.Text = opt
        ob.TextColor3 = Color3.new(1, 1, 1)
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 12
        ob.TextTruncate = Enum.TextTruncate.AtEnd
        ob.BorderSizePixel = 0
        ob.ZIndex = 21
        ob.Parent = listFrame

        ob.MouseButton1Click:Connect(function()
            btn.Text = opt
            listFrame.Visible = false
            local ok, err = pcall(callback, opt)
            if not ok then warn("[UI] " .. tostring(err)) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)
    return container
end

function UI:AddLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.BorderSizePixel = 0
    label.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = label
    return label
end

function UI:GetThemeNames()
    local names = {}
    for name, _ in pairs(Themes) do table.insert(names, name) end
    table.sort(names)
    return names
end

function UI:SetTheme(name)
    if not Themes[name] then return end
    self.Theme = name
    local color = self:GetColor()

    self.MainStroke.Color = color
    self.MiniBar.BackgroundColor3 = color
    self.ExpandBtn.TextColor3 = color

    for _, t in ipairs(self.TabButtons) do
        if t.Button.BackgroundColor3 == Color3.fromRGB(45, 45, 45) then
            t.Button.TextColor3 = color
        end
    end
end

function UI:GetThemeColor()
    return self:GetColor()
end

return {
    Themes = Themes,
    New = function(opts) return UI.new(opts) end,
}
