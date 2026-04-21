--[[
    Crystal UI Library v1.0
    - 自适应屏幕 (PC/移动端)
    - 可拖动悬浮球 & 主窗口
    - 左侧导航栏 + 模块化页面
    - 内置控件: 按钮、开关、滑块、下拉菜单、标签
    - 远程调用友好，直接返回创建函数
    使用方法: local CrystalUI = loadstring(game:HttpGet("https://your-host.com/crystal_ui.lua"))()
              local gui = CrystalUI:CreateWindow("你的标题")
]]

local Library = {}
Library.__index = Library

-- 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 玩家与屏幕
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local ScreenSize = workspace.CurrentCamera.ViewportSize

-- 工具函数：使对象可拖动
local function MakeDraggable(guiObject, dragHandle)
    dragHandle = dragHandle or guiObject
    local dragging = false
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            -- 边界限制 (保留部分可见)
            local absX = newPos.X.Offset + newPos.X.Scale * ScreenSize.X
            local absY = newPos.Y.Offset + newPos.Y.Scale * ScreenSize.Y
            local width = guiObject.AbsoluteSize.X
            local height = guiObject.AbsoluteSize.Y

            absX = math.clamp(absX, -width + 40, ScreenSize.X - 40)
            absY = math.clamp(absY, 0, ScreenSize.Y - 40)

            guiObject.Position = UDim2.new(0, absX, 0, absY)
        end
    end)
end

-- 主窗口创建函数
function Library:CreateWindow(title)
    local self = setmetatable({}, Library)
    self.Title = title or "Crystal UI"
    self.Tabs = {}
    self.CurrentTab = nil
    self.Active = true

    -- 创建悬浮球
    self.FloatingBall = Instance.new("ImageButton")
    self.FloatingBall.Name = "Crystal_FloatingBall"
    self.FloatingBall.Image = "rbxassetid://8992230677" -- 可替换为自定义图片
    self.FloatingBall.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    self.FloatingBall.BackgroundTransparency = 0.2
    self.FloatingBall.BorderSizePixel = 0
    self.FloatingBall.Size = UDim2.new(0, 55, 0, 55)
    self.FloatingBall.Position = UDim2.new(0, ScreenSize.X - 70, 0, ScreenSize.Y - 150)
    self.FloatingBall.AnchorPoint = Vector2.new(0.5, 0.5)
    self.FloatingBall.ZIndex = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = self.FloatingBall

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 2
    stroke.Parent = self.FloatingBall

    self.FloatingBall.Parent = CoreGui

    MakeDraggable(self.FloatingBall)

    -- 创建主窗口 (初始隐藏)
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "Crystal_Main"
    self.MainFrame.Size = UDim2.new(0, 580, 0, 380)
    self.MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    self.MainFrame.BackgroundTransparency = 0.1
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Visible = false
    self.MainFrame.ZIndex = 5
    self.MainFrame.Parent = CoreGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = self.MainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(80, 80, 120)
    mainStroke.Thickness = 1.5
    mainStroke.Parent = self.MainFrame

    -- 标题栏 (拖动把手)
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 35)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = self.TitleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.Parent = self.TitleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
        self.Active = false
    end)

    -- 主窗口拖动
    MakeDraggable(self.MainFrame, self.TitleBar)

    -- 左侧导航栏
    self.NavBar = Instance.new("Frame")
    self.NavBar.Size = UDim2.new(0, 140, 1, -35)
    self.NavBar.Position = UDim2.new(0, 0, 0, 35)
    self.NavBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    self.NavBar.BackgroundTransparency = 0.3
    self.NavBar.BorderSizePixel = 0
    self.NavBar.Parent = self.MainFrame

    local navCorner = Instance.new("UICorner")
    navCorner.CornerRadius = UDim.new(0, 12)
    navCorner.Parent = self.NavBar

    -- 内容容器
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -150, 1, -35)
    self.ContentContainer.Position = UDim2.new(0, 145, 0, 35)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.Parent = self.MainFrame

    -- 页面容器
    self.Pages = Instance.new("Folder")
    self.Pages.Name = "Pages"
    self.Pages.Parent = self.ContentContainer

    -- 悬浮球点击切换显示/隐藏
    self.FloatingBall.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = not self.MainFrame.Visible
        self.Active = self.MainFrame.Visible
        if self.MainFrame.Visible then
            self.MainFrame.ZIndex = 10
        end
    end)

    -- 自适应屏幕 (监听分辨率变化)
    local function UpdateScreenSize()
        ScreenSize = workspace.CurrentCamera.ViewportSize
        -- 调整悬浮球位置防止出屏
        local ballPos = self.FloatingBall.Position
        local absX = ballPos.X.Offset + ballPos.X.Scale * ScreenSize.X
        local absY = ballPos.Y.Offset + ballPos.Y.Scale * ScreenSize.Y
        absX = math.clamp(absX, 30, ScreenSize.X - 30)
        absY = math.clamp(absY, 30, ScreenSize.Y - 30)
        self.FloatingBall.Position = UDim2.new(0, absX, 0, absY)

        -- 调整主窗口位置 (居中且不超出)
        local frameSize = self.MainFrame.AbsoluteSize
        local newX = (ScreenSize.X - frameSize.X) / 2
        local newY = (ScreenSize.Y - frameSize.Y) / 2
        self.MainFrame.Position = UDim2.new(0, newX, 0, newY)
    end

    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScreenSize)
    UpdateScreenSize()

    -- 移动端触控优化
    if UserInputService.TouchEnabled then
        self.FloatingBall.Size = UDim2.new(0, 65, 0, 65)
    end

    return self
end

-- 添加导航标签
function Library:AddTab(tabName)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName
    tabButton.Size = UDim2.new(1, -16, 0, 35)
    tabButton.Position = UDim2.new(0, 8, 0, 8 + (#self.Tabs * 45))
    tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    tabButton.BackgroundTransparency = 0.5
    tabButton.BorderSizePixel = 0
    tabButton.Text = tabName
    tabButton.TextColor3 = Color3.fromRGB(220, 220, 255)
    tabButton.Font = Enum.Font.GothamSemibold
    tabButton.TextSize = 16
    tabButton.Parent = self.NavBar

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabButton

    -- 创建对应页面
    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 200)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingEnabled = true
    page.Parent = self.Pages

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local tabData = {
        Button = tabButton,
        Page = page,
        Layout = pageLayout,
        Elements = {}
    }

    tabButton.MouseButton1Click:Connect(function()
        for _, tab in ipairs(self.Tabs) do
            tab.Page.Visible = false
            tab.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end
        tabData.Page.Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 140)
        self.CurrentTab = tabData
    end)

    table.insert(self.Tabs, tabData)

    -- 默认激活第一个标签
    if #self.Tabs == 1 then
        tabData.Page.Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 140)
        self.CurrentTab = tabData
    else
        tabData.Page.Visible = false
    end

    return {
        AddButton = function(buttonText, callback)
            self:AddButton(tabData, buttonText, callback)
        end,
        AddToggle = function(toggleText, default, callback)
            self:AddToggle(tabData, toggleText, default, callback)
        end,
        AddSlider = function(sliderText, min, max, default, callback)
            self:AddSlider(tabData, sliderText, min, max, default, callback)
        end,
        AddDropdown = function(dropdownText, options, callback)
            self:AddDropdown(tabData, dropdownText, options, callback)
        end,
        AddLabel = function(labelText)
            self:AddLabel(tabData, labelText)
        end
    }
end

-- 内部方法：创建UI元素
function Library:AddButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 40)
    button.Position = UDim2.new(0, 10, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 16
    button.Parent = tab.Page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)
    table.insert(tab.Elements, button)
    return button
end

function Library:AddToggle(tab, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 240, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 50, 0, 24)
    toggleFrame.Position = UDim2.new(1, -55, 0.5, -12)
    toggleFrame.BackgroundColor3 = default and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(80, 80, 80)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleFrame

    local toggleKnob = Instance.new("Frame")
    toggleKnob.Size = UDim2.new(0, 20, 0, 20)
    toggleKnob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleFrame

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob

    local state = default or false
    local function updateVisual()
        local goalPos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        TweenService:Create(toggleKnob, TweenInfo.new(0.2), {Position = goalPos}):Play()
        toggleFrame.BackgroundColor3 = state and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(80, 80, 80)
    end

    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            updateVisual()
            callback(state)
        end
    end)

    table.insert(tab.Elements, container)
    return container
end

function Library:AddSlider(tab, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(240, 240, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 24)
    sliderFrame.Position = UDim2.new(0, 0, 0, 25)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.Parent = sliderFrame

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false
    local function updateSlider(input)
        local relativePos = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * relativePos
        fill.Size = UDim2.new(relativePos, 0, 1, 0)
        knob.Position = UDim2.new(relativePos, -7, 0.5, -7)
        label.Text = text .. ": " .. string.format("%.2f", value)
        callback(value)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
            dragging = true
        end
    end)

    table.insert(tab.Elements, container)
    return container
end

function Library:AddDropdown(tab, text, options, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 240, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.55, 0, 0, 35)
    dropdownBtn.Position = UDim2.new(0.45, 0, 0.5, -17)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Text = options[1] or "Select..."
    dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 14
    dropdownBtn.Parent = container

    local ddCorner = Instance.new("UICorner")
    ddCorner.CornerRadius = UDim.new(0, 6)
    ddCorner.Parent = dropdownBtn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0.55, 0, 0, 0)
    listFrame.Position = UDim2.new(0.45, 0, 0.5, 18)
    listFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 15
    listFrame.Parent = container

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listFrame

    local opened = false
    dropdownBtn.MouseButton1Click:Connect(function()
        opened = not opened
        listFrame.Visible = opened
        if opened then
            local count = #options
            listFrame.Size = UDim2.new(0.55, 0, 0, math.min(count * 30, 150))
        end
    end)

    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        optBtn.BorderSizePixel = 0
        optBtn.Text = option
        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 14
        optBtn.ZIndex = 16
        optBtn.Parent = listFrame

        optBtn.MouseButton1Click:Connect(function()
            dropdownBtn.Text = option
            listFrame.Visible = false
            opened = false
            callback(option)
        end)
    end

    table.insert(tab.Elements, container)
    return container
end

function Library:AddLabel(tab, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab.Page

    table.insert(tab.Elements, label)
    return label
end

-- 公开：直接切换可见性
function Library:SetVisible(bool)
    self.MainFrame.Visible = bool
    self.Active = bool
end

return Library
