--[[
    精美自适应通用 UI 库 (支持 PC & Mobile)
    核心特性: 全端自适应居中, 顺滑拖拽, 悬浮球唤醒, 动态模块创建
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = {}

-- 保护UI容器，优先放置于CoreGui防重置
local targetGui = (gethui and gethui()) or CoreGui
if not targetGui:FindFirstChild("RobloxGui") and not pcall(function() return CoreGui.Name end) then
    targetGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- 全局拖拽函数 (兼容鼠标与触屏)
local function MakeDraggable(dragArea, moveObject)
    local dragging = false
    local dragInput, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = moveObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            -- 考虑到 AnchorPoint, 我们使用 Offset 进行位移
            moveObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- 快速创建 UI 元素圆角
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

-- 库初始化：创建窗口
function Library:CreateWindow(options)
    local WindowTitle = options.Title or "My Executor UI"
    local AccentColor = options.Color or Color3.fromRGB(85, 170, 255)

    -- 主屏幕GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalExecutorUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetGui

    -- 悬浮球 (可拖拽, 点击显示/隐藏主UI)
    local FloatingBall = Instance.new("TextButton")
    FloatingBall.Name = "FloatingBall"
    FloatingBall.Size = UDim2.new(0, 50, 0, 50)
    FloatingBall.Position = UDim2.new(0.1, 0, 0.1, 0)
    FloatingBall.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FloatingBall.Text = "UI"
    FloatingBall.TextColor3 = AccentColor
    FloatingBall.Font = Enum.Font.GothamBold
    FloatingBall.TextSize = 18
    FloatingBall.Parent = ScreenGui
    AddCorner(FloatingBall, 25) -- 圆形
    
    local UIStrokeBall = Instance.new("UIStroke", FloatingBall)
    UIStrokeBall.Color = AccentColor
    UIStrokeBall.Thickness = 2

    -- 主UI框架 (自适应居中)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0) -- 比例尺寸，适配手机
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 8)

    -- 尺寸限制 (防止PC屏幕过大时失真)
    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MaxSize = Vector2.new(650, 400)
    SizeConstraint.MinSize = Vector2.new(300, 250)
    SizeConstraint.Parent = MainFrame

    -- 拖拽区域与顶部标题
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowTitle
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- 侧边栏 (导航区)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, 0, 1, -10)
    TabContainer.Position = UDim2.new(0, 0, 0, 5)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.Parent = TabContainer

    -- 内容区 (模块界面展示区)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -130, 1, -40)
    ContentContainer.Position = UDim2.new(0, 130, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    -- 激活拖拽功能
    MakeDraggable(TopBar, MainFrame)
    MakeDraggable(FloatingBall, FloatingBall)

    -- 悬浮球点击事件
    FloatingBall.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    local Window = {}
    local Tabs = {}
    local FirstTab = true

    -- 创建侧边栏模块 (Tab)
    function Window:CreateTab(TabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(0.9, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        TabButton.Text = TabName
        TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 14
        TabButton.Parent = TabContainer
        AddCorner(TabButton, 6)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = TabName .. "_Page"
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = AccentColor
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage

        -- 自动更新滚动条画布大小
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        if FirstTab then
            TabButton.BackgroundColor3 = AccentColor
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            FirstTab = false
        end

        table.insert(Tabs, {Button = TabButton, Page = TabPage})

        -- 切换模块逻辑
        TabButton.MouseButton1Click:Connect(function()
            for _, tabData in pairs(Tabs) do
                if tabData.Button == TabButton then
                    tabData.Page.Visible = true
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {BackgroundColor3 = AccentColor, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                else
                    tabData.Page.Visible = false
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                end
            end
        end)

        local Elements = {}

        -- [1] 文本/标签
        function Elements:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            LabelFrame.Parent = TabPage
            AddCorner(LabelFrame, 6)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = LabelFrame
        end

        -- [2] 普通按钮
        function Elements:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Font = Enum.Font.GothamSemibold
            Button.TextSize = 14
            Button.Parent = TabPage
            AddCorner(Button, 6)

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = AccentColor}):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
            end)

            Button.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
        end

        -- [3] 开关 Toggle
        function Elements:CreateToggle(text, default, callback)
            local toggled = default or false
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            ToggleFrame.Parent = TabPage
            AddCorner(ToggleFrame, 6)

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
            ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
            ToggleBtn.BackgroundColor3 = toggled and AccentColor or Color3.fromRGB(60, 60, 60)
            ToggleBtn.Text = ""
            ToggleBtn.Parent = ToggleFrame
            AddCorner(ToggleBtn, 10)

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 16, 0, 16)
            Indicator.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Indicator.Parent = ToggleBtn
            AddCorner(Indicator, 8)

            local function FireToggle()
                toggled = not toggled
                local goalColor = toggled and AccentColor or Color3.fromRGB(60, 60, 60)
                local goalPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
                TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = goalPos}):Play()
                pcall(callback, toggled)
            end

            ToggleBtn.MouseButton1Click:Connect(FireToggle)
        end

        -- [4] 滑块 Slider (完美适配手机触摸与PC鼠标)
        function Elements:CreateSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            SliderFrame.Parent = TabPage
            AddCorner(SliderFrame, 6)

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -20, 0, 25)
            SliderLabel.Position = UDim2.new(0, 10, 0, 0)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text .. " : " .. tostring(default)
            SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextSize = 14
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame

            local BarBackground = Instance.new("Frame")
            BarBackground.Size = UDim2.new(1, -20, 0, 8)
            BarBackground.Position = UDim2.new(0, 10, 0, 30)
            BarBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            BarBackground.Parent = SliderFrame
            AddCorner(BarBackground, 4)

            local BarFill = Instance.new("Frame")
            local defaultScale = (default - min) / (max - min)
            BarFill.Size = UDim2.new(defaultScale, 0, 1, 0)
            BarFill.BackgroundColor3 = AccentColor
            BarFill.Parent = BarBackground
            AddCorner(BarFill, 4)

            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = BarBackground

            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp(input.Position.X - BarBackground.AbsolutePosition.X, 0, BarBackground.AbsoluteSize.X)
                local scale = pos / BarBackground.AbsoluteSize.X
                local value = math.floor(min + ((max - min) * scale))
                
                TweenService:Create(BarFill, TweenInfo.new(0.1), {Size = UDim2.new(scale, 0, 1, 0)}):Play()
                SliderLabel.Text = text .. " : " .. tostring(value)
                pcall(callback, value)
            end

            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
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
        end

        return Elements
    end

    return Window
end

return Library
