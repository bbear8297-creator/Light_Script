--[[
    精美自适应通用 UI 库 v3.4 (动态渐变升级+高级控件扩展)
    优化：侧边栏完美自适应、主题切换修复、流畅渐变、文字主题跟随、防误触、通知栏上调
    新增：悬浮球 Q 弹点击动画、主界面丝滑弹性弹出/收起动画
    v3.4 新增：Apple 风格动态循环渐变、CreateImage、CreateColorPicker、CreateKeybind 等控件
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}

local targetGui = (gethui and gethui()) or CoreGui
if not targetGui:FindFirstChild("RobloxGui") and not pcall(function() return CoreGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function MakeDraggable(dragArea, moveObject)
    local dragging, dragInput, dragStart, startPos
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
            moveObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

-- ========== 内置主题库 ==========
Library.Themes = {
    Default = {
        Accent = Color3.fromRGB(85, 170, 255),
        MainBackground = Color3.fromRGB(248, 248, 248),
        SidebarBackground = Color3.fromRGB(240, 240, 240),
        ElementBackground = Color3.fromRGB(245, 245, 245),
        TopBarBackground = Color3.fromRGB(252, 252, 252),
        TextColor = Color3.fromRGB(40, 40, 40),
        TitleTextColor = Color3.fromRGB(30, 30, 30),
        ElementTextColor = Color3.fromRGB(30, 30, 30),
        ToggleOffColor = Color3.fromRGB(180, 180, 180),
        DividerColor = Color3.fromRGB(220, 220, 220),
        Gradient = nil
    },
    Ocean = {
        Accent = Color3.fromRGB(0, 180, 180),
        MainBackground = Color3.fromRGB(230, 245, 250),
        SidebarBackground = Color3.fromRGB(200, 235, 240),
        ElementBackground = Color3.fromRGB(235, 248, 252),
        TopBarBackground = Color3.fromRGB(220, 240, 245),
        TextColor = Color3.fromRGB(20, 60, 80),
        TitleTextColor = Color3.fromRGB(15, 45, 60),
        ElementTextColor = Color3.fromRGB(20, 70, 90),
        ToggleOffColor = Color3.fromRGB(170, 210, 220),
        DividerColor = Color3.fromRGB(180, 215, 225),
        Gradient = nil
    },
    Autumn = {
        Accent = Color3.fromRGB(255, 140, 0),
        MainBackground = Color3.fromRGB(250, 245, 235),
        SidebarBackground = Color3.fromRGB(240, 230, 210),
        ElementBackground = Color3.fromRGB(245, 235, 220),
        TopBarBackground = Color3.fromRGB(248, 240, 225),
        TextColor = Color3.fromRGB(80, 50, 30),
        TitleTextColor = Color3.fromRGB(60, 40, 20),
        ElementTextColor = Color3.fromRGB(70, 45, 25),
        ToggleOffColor = Color3.fromRGB(200, 180, 160),
        DividerColor = Color3.fromRGB(210, 190, 170),
        Gradient = nil
    },
    Sunset = {
        Accent = Color3.fromRGB(255, 80, 100),
        MainBackground = Color3.fromRGB(255, 240, 240),
        SidebarBackground = Color3.fromRGB(255, 225, 225),
        ElementBackground = Color3.fromRGB(255, 245, 245),
        TopBarBackground = Color3.fromRGB(255, 235, 235),
        TextColor = Color3.fromRGB(80, 40, 40),
        TitleTextColor = Color3.fromRGB(60, 20, 20),
        ElementTextColor = Color3.fromRGB(90, 45, 45),
        ToggleOffColor = Color3.fromRGB(220, 190, 190),
        DividerColor = Color3.fromRGB(230, 210, 210),
        Gradient = nil
    },
    WarmGradient = {
        Accent = Color3.fromRGB(255, 100, 80),
        MainBackground = Color3.fromRGB(255, 240, 230),
        SidebarBackground = Color3.fromRGB(250, 230, 220),
        ElementBackground = Color3.fromRGB(255, 245, 240),
        TopBarBackground = Color3.fromRGB(255, 235, 225),
        TextColor = Color3.fromRGB(80, 50, 40),
        TitleTextColor = Color3.fromRGB(60, 30, 20),
        ElementTextColor = Color3.fromRGB(90, 55, 45),
        ToggleOffColor = Color3.fromRGB(220, 200, 190),
        DividerColor = Color3.fromRGB(230, 210, 200),
        Gradient = Instance.new("UIGradient")
    }
}

local warmGrad = Library.Themes.WarmGradient.Gradient
warmGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 100))
})
warmGrad.Rotation = 45

-- ========== 创建窗口 ==========
function Library:CreateWindow(options)
    local WindowTitle = options.Title or "My Executor UI"
    local initialTheme = options.Theme or "Default"

    local Theme = {}
    local function loadTheme(name)
        local t = Library.Themes[name] or Library.Themes.Default
        for k, _ in pairs(Library.Themes.Default) do
            Theme[k] = t[k]
        end
    end
    loadTheme(initialTheme)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalExecutorUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetGui

    local themeUpdateFunctions = {}

    -- 遮罩 
    local DropdownOverlay = Instance.new("TextButton")
    DropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
    DropdownOverlay.BackgroundTransparency = 1
    DropdownOverlay.Text = ""
    DropdownOverlay.Visible = false
    DropdownOverlay.Active = true 
    DropdownOverlay.ZIndex = 99
    DropdownOverlay.Parent = ScreenGui

    -- 通知容器
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.AnchorPoint = Vector2.new(1, 0)
    NotificationContainer.Position = UDim2.new(1, -10, 0, 5)
    NotificationContainer.Size = UDim2.new(0, 250, 1, -60)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.ClipsDescendants = false
    NotificationContainer.ZIndex = 10
    NotificationContainer.Parent = ScreenGui

    -- 悬浮球 (新增了居中锚点和 UIScale 缩放器)
    local FloatingBall = Instance.new("TextButton")
    FloatingBall.Size = UDim2.new(0, 50, 0, 50)
    FloatingBall.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingBall.Position = UDim2.new(0.1, 25, 0.1, 25) 
    FloatingBall.BackgroundColor3 = Theme.ElementBackground
    FloatingBall.Text = "UI"
    FloatingBall.TextColor3 = Theme.TextColor
    FloatingBall.Font = Enum.Font.GothamBold
    FloatingBall.TextSize = 18
    FloatingBall.Parent = ScreenGui
    AddCorner(FloatingBall, 25)
    local UIStrokeBall = Instance.new("UIStroke", FloatingBall)
    UIStrokeBall.Color = Theme.Accent
    UIStrokeBall.Thickness = 2
    local BallScale = Instance.new("UIScale", FloatingBall)

    table.insert(themeUpdateFunctions, function(t)
        FloatingBall.BackgroundColor3 = t.ElementBackground
        FloatingBall.TextColor3 = t.TextColor
        UIStrokeBall.Color = t.Accent
    end)

    -- 主框架 (新增 UIScale 缩放器)
    local MainFrame = Instance.new("Frame")
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    MainFrame.BackgroundColor3 = Theme.MainBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    local MainScale = Instance.new("UIScale", MainFrame)
    
    AddCorner(MainFrame, 16)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.4
    if Theme.Gradient then
        local grad = Theme.Gradient:Clone()
        grad.Parent = MainFrame
    end
    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MaxSize = Vector2.new(650, 400)
    SizeConstraint.MinSize = Vector2.new(300, 250)
    SizeConstraint.Parent = MainFrame
    table.insert(themeUpdateFunctions, function(t)
        MainFrame.BackgroundColor3 = t.MainBackground
        MainStroke.Color = t.Accent
    end)

    -- 顶部栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Theme.TopBarBackground or Theme.MainBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    local TopBarCorner = Instance.new("UICorner", TopBar)
    TopBarCorner.CornerRadius = UDim.new(0, 16)
    local BottomHideFrame = Instance.new("Frame")
    BottomHideFrame.Size = UDim2.new(1, 0, 0.5, 0)
    BottomHideFrame.Position = UDim2.new(0, 0, 0.5, 0)
    BottomHideFrame.BackgroundColor3 = Theme.TopBarBackground or Theme.MainBackground
    BottomHideFrame.BorderSizePixel = 0
    BottomHideFrame.Parent = TopBar
    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, 0, 0, 1)
    TopDivider.Position = UDim2.new(0, 0, 1, -1)
    TopDivider.BackgroundColor3 = Theme.DividerColor
    TopDivider.BorderSizePixel = 0
    TopDivider.Parent = TopBar
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowTitle
    TitleLabel.TextColor3 = Theme.TitleTextColor
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar
    table.insert(themeUpdateFunctions, function(t)
        TopBar.BackgroundColor3 = t.TopBarBackground or t.MainBackground
        BottomHideFrame.BackgroundColor3 = t.TopBarBackground or t.MainBackground
        TopDivider.BackgroundColor3 = t.DividerColor
        TitleLabel.TextColor3 = t.TitleTextColor
    end)

    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0.28, 0, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Theme.SidebarBackground
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    local SidebarCorner = Instance.new("UICorner", Sidebar)
    SidebarCorner.CornerRadius = UDim.new(0, 16)
    local RightHideFrame = Instance.new("Frame")
    RightHideFrame.Size = UDim2.new(0.5, 0, 1, 0)
    RightHideFrame.Position = UDim2.new(0.5, 0, 0, 0)
    RightHideFrame.BackgroundColor3 = Theme.SidebarBackground
    RightHideFrame.BorderSizePixel = 0
    RightHideFrame.Parent = Sidebar

    local SideDivider = Instance.new("Frame")
    SideDivider.Size = UDim2.new(0, 1, 1, 0)
    SideDivider.Position = UDim2.new(1, -1, 0, 0)
    SideDivider.BackgroundColor3 = Theme.DividerColor
    SideDivider.BorderSizePixel = 0
    SideDivider.Parent = Sidebar

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

    table.insert(themeUpdateFunctions, function(t)
        Sidebar.BackgroundColor3 = t.SidebarBackground
        RightHideFrame.BackgroundColor3 = t.SidebarBackground
        SideDivider.BackgroundColor3 = t.DividerColor
    end)

    -- 内容区
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(0.72, 0, 1, -40)
    ContentContainer.Position = UDim2.new(0.28, 0, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    MakeDraggable(TopBar, MainFrame)
    MakeDraggable(FloatingBall, FloatingBall)

    -- >>> 弹性展开/收回的核心逻辑 <<<
    local isUiOpen = true
    local isAnimating = false

    FloatingBall.MouseButton1Click:Connect(function()
        if isAnimating then return end
        isAnimating = true

        -- 1. 悬浮球 Q 弹按压效果
        local pressTween = TweenService:Create(BallScale, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 0.8})
        pressTween:Play()
        pressTween.Completed:Wait()
        TweenService:Create(BallScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

        isUiOpen = not isUiOpen

        -- 2. 主界面弹性开关动画
        if isUiOpen then
            MainFrame.Visible = true
            MainScale.Scale = 0
            local openTween = TweenService:Create(MainScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
            openTween:Play()
            openTween.Completed:Connect(function()
                isAnimating = false
            end)
        else
            local closeTween = TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            closeTween:Play()
            closeTween.Completed:Connect(function()
                if not isUiOpen then
                    MainFrame.Visible = false
                end
                isAnimating = false
            end)
        end
    end)
    -- >>> 弹性动画逻辑结束 <<<

    local Window = {}
    local Tabs = {}
    local FirstTab = true
    local selectedTabButton = nil
    local currentDropdown = nil

    local function closeDropdown()
        if currentDropdown then
            currentDropdown.list:Destroy()
            DropdownOverlay.Visible = false
            if currentDropdown.conn then currentDropdown.conn:Disconnect() end
            currentDropdown = nil
        end
    end

    -- 渐变动画相关变量
    local gradientAnimConn
    local colorCycleConn

    local function stopGradientAnimation()
        if gradientAnimConn then
            gradientAnimConn:Disconnect()
            gradientAnimConn = nil
        end
        if colorCycleConn then
            colorCycleConn:Disconnect()
            colorCycleConn = nil
        end
    end
    
    local function startGradientAnimation(grad, themeName)
        stopGradientAnimation()
        if not grad then return end
        
        -- 旋转动画
        gradientAnimConn = RunService.RenderStepped:Connect(function(dt)
            if not grad.Parent then stopGradientAnimation() return end
            grad.Rotation = (grad.Rotation + dt * 30) % 360
        end)
        
        -- Apple 风格动态色彩循环（仅 WarmGradient 主题启用）
        if themeName == "WarmGradient" then
            local startTime = os.clock()
            colorCycleConn = RunService.RenderStepped:Connect(function()
                if not grad.Parent then stopGradientAnimation() return end
                local elapsed = os.clock() - startTime
                -- 使用正弦波生成平滑流动的色相
                local hue1 = (elapsed * 0.08) % 1
                local hue2 = (hue1 + 0.15) % 1
                local hue3 = (hue1 + 0.3) % 1
                
                local color1 = Color3.fromHSV(hue1, 0.7, 0.95)
                local color2 = Color3.fromHSV(hue2, 0.8, 0.9)
                local color3 = Color3.fromHSV(hue3, 0.9, 0.85)
                
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, color1),
                    ColorSequenceKeypoint.new(0.5, color2),
                    ColorSequenceKeypoint.new(1, color3)
                })
            end)
        end
    end

    function Window:ApplyTheme(themeName)
        closeDropdown() 
        loadTheme(themeName)
        
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("UIGradient") then child:Destroy() end
        end
        
        if Theme.Gradient then
            local newGrad = Theme.Gradient:Clone()
            newGrad.Parent = MainFrame
            startGradientAnimation(newGrad, themeName) -- 传入主题名称以启用色彩循环
        else
            stopGradientAnimation()
        end
        
        for _, func in ipairs(themeUpdateFunctions) do
            func(Theme)
        end
    end

    function Window:SetAccentColor(color)
        Theme.Accent = color
        for _, func in ipairs(themeUpdateFunctions) do
            func(Theme)
        end
    end

    local currentNotification = nil
    function Window:Notify(title, message, duration)
        title = title or "通知"
        message = message or ""
        duration = duration or 4
        if currentNotification then
            currentNotification:Destroy()
        end
        local notifFrame = Instance.new("Frame")
        notifFrame.BackgroundColor3 = Theme.ElementBackground
        notifFrame.Size = UDim2.new(0, 240, 0, 60)
        notifFrame.Position = UDim2.new(1, 10, 0, 0)
        notifFrame.Parent = NotificationContainer
        AddCorner(notifFrame, 8)
        local stroke = Instance.new("UIStroke", notifFrame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 1
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -16, 0, 20)
        titleLabel.Position = UDim2.new(0, 8, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Theme.TextColor
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notifFrame
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -16, 0, 20)
        msgLabel.Position = UDim2.new(0, 8, 0, 28)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Theme.TextColor
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextSize = 13
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextWrapped = true
        msgLabel.Parent = notifFrame
        notifFrame:TweenPosition(UDim2.new(1, -250, 0, 0), "Out", "Quad", 0.3)
        currentNotification = notifFrame
        delay(duration, function()
            if notifFrame and notifFrame.Parent then
                notifFrame:TweenPosition(UDim2.new(1, 10, 0, 0), "In", "Quad", 0.3)
                wait(0.3)
                if currentNotification == notifFrame then
                    currentNotification = nil
                end
                notifFrame:Destroy()
            end
        end)
    end

    function Window:CreateTab(TabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(0.9, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TabButton.Text = TabName
        TabButton.TextColor3 = Theme.TextColor
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 14
        TabButton.Parent = TabContainer
        AddCorner(TabButton, 8)
        table.insert(themeUpdateFunctions, function(t)
            if selectedTabButton == TabButton then return end
            TabButton.TextColor3 = t.TextColor
            TabButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        end)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = TabName .. "_Page"
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        if FirstTab then
            TabButton.BackgroundColor3 = Theme.Accent
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            selectedTabButton = TabButton
            table.insert(themeUpdateFunctions, function(t)
                if selectedTabButton == TabButton then
                    TabButton.BackgroundColor3 = t.Accent
                end
            end)
            FirstTab = false
        end
        table.insert(Tabs, {Button = TabButton, Page = TabPage})

        TabButton.MouseButton1Click:Connect(function()
            for _, tabData in pairs(Tabs) do
                if tabData.Button == TabButton then
                    tabData.Page.Visible = true
                    selectedTabButton = TabButton
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Theme.Accent,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                else
                    tabData.Page.Visible = false
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                        TextColor3 = Theme.TextColor
                    }):Play()
                end
            end
        end)

        local Elements = {}

        function Elements:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundColor3 = Theme.ElementBackground
            LabelFrame.Parent = TabPage
            AddCorner(LabelFrame, 8)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextColor
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = LabelFrame
            table.insert(themeUpdateFunctions, function(t)
                LabelFrame.BackgroundColor3 = t.ElementBackground
                Label.TextColor3 = t.TextColor
            end)
        end

        function Elements:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = Theme.ElementBackground
            Button.Text = text
            Button.TextColor3 = Theme.ElementTextColor
            Button.Font = Enum.Font.GothamSemibold
            Button.TextSize = 14
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.Parent = TabPage
            AddCorner(Button, 8)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10)
            padding.Parent = Button
            local function apply(t)
                Button.BackgroundColor3 = t.ElementBackground
                Button.TextColor3 = t.ElementTextColor
            end
            table.insert(themeUpdateFunctions, apply)
            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Theme.Accent,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Theme.ElementBackground,
                    TextColor3 = Theme.ElementTextColor
                }):Play()
            end)
            Button.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
        end

        function Elements:CreateToggle(text, default, callback)
            local toggled = default or false
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.BackgroundColor3 = Theme.ElementBackground
            ToggleFrame.Parent = TabPage
            AddCorner(ToggleFrame, 8)
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Theme.TextColor
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
            ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
            ToggleBtn.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOffColor
            ToggleBtn.Text = ""
            ToggleBtn.Parent = ToggleFrame
            AddCorner(ToggleBtn, 10)
            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 16, 0, 16)
            Indicator.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Indicator.Parent = ToggleBtn
            AddCorner(Indicator, 8)
            local function apply(t)
                ToggleFrame.BackgroundColor3 = t.ElementBackground
                ToggleLabel.TextColor3 = t.TextColor
                ToggleBtn.BackgroundColor3 = toggled and t.Accent or t.ToggleOffColor
            end
            table.insert(themeUpdateFunctions, apply)
            local function FireToggle()
                toggled = not toggled
                local goalColor = toggled and Theme.Accent or Theme.ToggleOffColor
                local goalPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
                TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = goalPos}):Play()
                pcall(callback, toggled)
            end
            ToggleBtn.MouseButton1Click:Connect(FireToggle)
        end

        function Elements:CreateSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Theme.ElementBackground
            SliderFrame.Parent = TabPage
            AddCorner(SliderFrame, 8)
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -20, 0, 25)
            SliderLabel.Position = UDim2.new(0, 10, 0, 0)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text .. " : " .. tostring(default)
            SliderLabel.TextColor3 = Theme.TextColor
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextSize = 14
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame
            local BarBackground = Instance.new("Frame")
            BarBackground.Size = UDim2.new(1, -20, 0, 8)
            BarBackground.Position = UDim2.new(0, 10, 0, 30)
            BarBackground.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
            BarBackground.Parent = SliderFrame
            AddCorner(BarBackground, 4)
            local BarFill = Instance.new("Frame")
            local defaultScale = (default - min) / (max - min)
            BarFill.Size = UDim2.new(defaultScale, 0, 1, 0)
            BarFill.BackgroundColor3 = Theme.Accent
            BarFill.Parent = BarBackground
            AddCorner(BarFill, 4)
            table.insert(themeUpdateFunctions, function(t) 
                BarFill.BackgroundColor3 = t.Accent
                SliderFrame.BackgroundColor3 = t.ElementBackground
                SliderLabel.TextColor3 = t.TextColor 
            end)
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

        function Elements:CreateInfoPanel(info)
            local panel = Instance.new("Frame")
            panel.Size = UDim2.new(1, 0, 0, 80)
            panel.BackgroundColor3 = Theme.ElementBackground
            panel.Parent = TabPage
            AddCorner(panel, 10)
            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 55, 0, 55)
            avatar.Position = UDim2.new(0, 12, 0.5, -27)
            avatar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            avatar.Parent = panel
            AddCorner(avatar, 27)
            spawn(function()
                pcall(function()
                    local userId = Players.LocalPlayer.UserId
                    local content = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    avatar.Image = content
                end)
            end)
            local infoFrame = Instance.new("Frame")
            infoFrame.Size = UDim2.new(1, -80, 1, -10)
            infoFrame.Position = UDim2.new(0, 75, 0, 5)
            infoFrame.BackgroundTransparency = 1
            infoFrame.Parent = panel
            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 2)
            layout.Parent = infoFrame
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = info.PlayerName or Players.LocalPlayer.Name
            nameLabel.TextColor3 = Theme.TextColor
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 15
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = infoFrame
            local serverLabel = Instance.new("TextLabel")
            serverLabel.Size = UDim2.new(1, 0, 0, 18)
            serverLabel.BackgroundTransparency = 1
            serverLabel.Text = info.ServerInfo or "Server: unknown"
            serverLabel.TextColor3 = Theme.TextColor
            serverLabel.Font = Enum.Font.Gotham
            serverLabel.TextSize = 13
            serverLabel.TextXAlignment = Enum.TextXAlignment.Left
            serverLabel.Parent = infoFrame
            local execLabel = Instance.new("TextLabel")
            execLabel.Size = UDim2.new(1, 0, 0, 18)
            execLabel.BackgroundTransparency = 1
            execLabel.Text = info.ExecutorInfo or "Executor: unknown"
            execLabel.TextColor3 = Theme.TextColor
            execLabel.Font = Enum.Font.Gotham
            execLabel.TextSize = 13
            execLabel.TextXAlignment = Enum.TextXAlignment.Left
            execLabel.Parent = infoFrame
            table.insert(themeUpdateFunctions, function(t)
                panel.BackgroundColor3 = t.ElementBackground
                nameLabel.TextColor3 = t.TextColor
                serverLabel.TextColor3 = t.TextColor
                execLabel.TextColor3 = t.TextColor
            end)
            return panel
        end

        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = Theme.ElementBackground
            DropdownFrame.Parent = TabPage
            AddCorner(DropdownFrame, 8)
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(0.5, -20, 1, 0)
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = text
            DropdownLabel.TextColor3 = Theme.TextColor
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextSize = 14
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame
            local DropButton = Instance.new("TextButton")
            DropButton.Size = UDim2.new(0, 130, 0, 28)
            DropButton.AnchorPoint = Vector2.new(1, 0.5)
            DropButton.Position = UDim2.new(1, -10, 0.5, 0)
            DropButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            DropButton.Text = selected .. "  ▼"
            DropButton.TextColor3 = Theme.ElementTextColor
            DropButton.Font = Enum.Font.GothamSemibold
            DropButton.TextSize = 13
            DropButton.Parent = DropdownFrame
            AddCorner(DropButton, 6)
            local function apply(t)
                DropdownFrame.BackgroundColor3 = t.ElementBackground
                DropdownLabel.TextColor3 = t.TextColor
                DropButton.TextColor3 = t.ElementTextColor
            end
            table.insert(themeUpdateFunctions, apply)
            DropButton.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == DropButton then
                    closeDropdown()
                    return
                end
                closeDropdown()
                local list = Instance.new("Frame")
                list.Name = "DropdownList"
                list.BackgroundColor3 = Theme.ElementBackground
                list.BorderSizePixel = 0
                list.ZIndex = 100 
                list.Parent = ScreenGui
                AddCorner(list, 8)
                local layout = Instance.new("UIListLayout")
                layout.Parent = list
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = (opt == selected) and Theme.Accent or Theme.ElementBackground
                    optBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.TextColor
                    optBtn.Text = opt
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 13
                    optBtn.ZIndex = 101 
                    optBtn.Parent = list
                    AddCorner(optBtn, 4)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        DropButton.Text = selected .. "  ▼"
                        pcall(callback, selected)
                        closeDropdown()
                    end)
                    optBtn.MouseEnter:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.2), {
                            BackgroundColor3 = Theme.Accent,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end)
                    optBtn.MouseLeave:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.2), {
                            BackgroundColor3 = (opt == selected) and Theme.Accent or Theme.ElementBackground,
                            TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.TextColor
                        }):Play()
                    end)
                end
                local absPos = DropButton.AbsolutePosition
                local absSize = DropButton.AbsoluteSize
                list.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
                list.Size = UDim2.new(0, absSize.X, 0, #options * 28)
                DropdownOverlay.Visible = true
                currentDropdown = {button = DropButton, list = list}
                local conn
                conn = DropdownOverlay.MouseButton1Click:Connect(function()
                    closeDropdown()
                end)
                currentDropdown.conn = conn
            end)
            return DropdownFrame
        end

        -- ******************** 新增高级控件 ********************

        -- 图片显示控件（内嵌图片）
        function Elements:CreateImage(imageId, sizeX, sizeY)
            local img = Instance.new("ImageLabel")
            img.Name = "ImageElement"
            img.Size = UDim2.new(0, sizeX or 100, 0, sizeY or 100)
            img.BackgroundColor3 = Theme.ElementBackground
            img.Image = imageId or ""
            img.ScaleType = Enum.ScaleType.Fit
            img.Parent = TabPage
            AddCorner(img, 8)
            table.insert(themeUpdateFunctions, function(t)
                img.BackgroundColor3 = t.ElementBackground
            end)
            return img
        end

        -- 颜色选择器 (带 RGB 滑块)
        function Elements:CreateColorPicker(text, defaultColor, callback)
            local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local pickerFrame = Instance.new("Frame")
            pickerFrame.Size = UDim2.new(1, 0, 0, 40)
            pickerFrame.BackgroundColor3 = Theme.ElementBackground
            pickerFrame.Parent = TabPage
            AddCorner(pickerFrame, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.TextColor
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = pickerFrame

            local colorPreview = Instance.new("TextButton")
            colorPreview.Size = UDim2.new(0, 60, 0, 28)
            colorPreview.AnchorPoint = Vector2.new(1, 0.5)
            colorPreview.Position = UDim2.new(1, -10, 0.5, 0)
            colorPreview.BackgroundColor3 = currentColor
            colorPreview.Text = ""
            colorPreview.Parent = pickerFrame
            AddCorner(colorPreview, 6)
            local previewStroke = Instance.new("UIStroke", colorPreview)
            previewStroke.Color = Theme.Accent
            previewStroke.Thickness = 1

            local function apply(t)
                pickerFrame.BackgroundColor3 = t.ElementBackground
                label.TextColor3 = t.TextColor
                colorPreview.BackgroundColor3 = currentColor
                previewStroke.Color = t.Accent
            end
            table.insert(themeUpdateFunctions, apply)

            local pickerPopup = nil
            colorPreview.MouseButton1Click:Connect(function()
                if pickerPopup then pickerPopup:Destroy() end
                -- 弹出颜色选择面板
                pickerPopup = Instance.new("Frame")
                pickerPopup.Size = UDim2.new(0, 220, 0, 180)
                pickerPopup.Position = UDim2.new(0, colorPreview.AbsolutePosition.X - 160, 0, colorPreview.AbsolutePosition.Y + 32)
                pickerPopup.BackgroundColor3 = Theme.ElementBackground
                pickerPopup.BorderSizePixel = 0
                pickerPopup.ZIndex = 200
                pickerPopup.Parent = ScreenGui
                AddCorner(pickerPopup, 10)
                local popupStroke = Instance.new("UIStroke", pickerPopup)
                popupStroke.Color = Theme.Accent
                popupStroke.Thickness = 1

                -- R, G, B 滑块
                local function createChannelSlider(name, channelValue, yPos)
                    local channelLabel = Instance.new("TextLabel")
                    channelLabel.Size = UDim2.new(0, 20, 0, 16)
                    channelLabel.Position = UDim2.new(0, 10, 0, yPos)
                    channelLabel.BackgroundTransparency = 1
                    channelLabel.Text = name
                    channelLabel.TextColor3 = Theme.TextColor
                    channelLabel.Font = Enum.Font.GothamBold
                    channelLabel.TextSize = 13
                    channelLabel.TextXAlignment = Enum.TextXAlignment.Left
                    channelLabel.Parent = pickerPopup

                    local bar = Instance.new("Frame")
                    bar.Size = UDim2.new(1, -60, 0, 16)
                    bar.Position = UDim2.new(0, 35, 0, yPos)
                    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
                    bar.Parent = pickerPopup
                    AddCorner(bar, 8)

                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new(channelValue/255, 0, 1, 0)
                    fill.BackgroundColor3 = (name == "R" and Color3.fromRGB(255,0,0)) or
                                           (name == "G" and Color3.fromRGB(0,255,0)) or
                                           Color3.fromRGB(0,0,255)
                    fill.Parent = bar
                    AddCorner(fill, 8)

                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 1, 0)
                    btn.BackgroundTransparency = 1
                    btn.Text = ""
                    btn.Parent = bar

                    local dragging = false
                    local function update(input)
                        local pos = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
                        local val = math.floor(pos / bar.AbsoluteSize.X * 255)
                        fill.Size = UDim2.new(val/255, 0, 1, 0)
                        if name == "R" then currentColor = Color3.fromRGB(val, currentColor.G*255, currentColor.B*255)
                        elseif name == "G" then currentColor = Color3.fromRGB(currentColor.R*255, val, currentColor.B*255)
                        else currentColor = Color3.fromRGB(currentColor.R*255, currentColor.G*255, val) end
                        colorPreview.BackgroundColor3 = currentColor
                        pcall(callback, currentColor)
                    end
                    btn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            update(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            update(input)
                        end
                    end)
                    return bar, fill
                end

                createChannelSlider("R", currentColor.R*255, 10)
                createChannelSlider("G", currentColor.G*255, 40)
                createChannelSlider("B", currentColor.B*255, 70)

                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(1, -20, 0, 30)
                closeBtn.Position = UDim2.new(0, 10, 0, 105)
                closeBtn.BackgroundColor3 = Theme.Accent
                closeBtn.Text = "确认"
                closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
                closeBtn.Font = Enum.Font.GothamSemibold
                closeBtn.TextSize = 14
                closeBtn.Parent = pickerPopup
                AddCorner(closeBtn, 8)
                closeBtn.MouseButton1Click:Connect(function()
                    pickerPopup:Destroy()
                    pickerPopup = nil
                end)
                -- 点击遮罩关闭
                local closeConn
                closeConn = DropdownOverlay.MouseButton1Click:Connect(function()
                    if pickerPopup then
                        pickerPopup:Destroy()
                        pickerPopup = nil
                        if closeConn then closeConn:Disconnect() end
                    end
                end)
            end)
            return pickerFrame
        end

        -- 按键绑定控件
        function Elements:CreateKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local keybindFrame = Instance.new("Frame")
            keybindFrame.Size = UDim2.new(1, 0, 0, 35)
            keybindFrame.BackgroundColor3 = Theme.ElementBackground
            keybindFrame.Parent = TabPage
            AddCorner(keybindFrame, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.TextColor
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = keybindFrame

            local bindButton = Instance.new("TextButton")
            bindButton.Size = UDim2.new(0, 100, 0, 28)
            bindButton.AnchorPoint = Vector2.new(1, 0.5)
            bindButton.Position = UDim2.new(1, -10, 0.5, 0)
            bindButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            bindButton.Text = currentKey.Name
            bindButton.TextColor3 = Theme.ElementTextColor
            bindButton.Font = Enum.Font.GothamSemibold
            bindButton.TextSize = 13
            bindButton.Parent = keybindFrame
            AddCorner(bindButton, 6)

            local function apply(t)
                keybindFrame.BackgroundColor3 = t.ElementBackground
                label.TextColor3 = t.TextColor
                bindButton.TextColor3 = t.ElementTextColor
            end
            table.insert(themeUpdateFunctions, apply)

            local listening = false
            bindButton.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                bindButton.Text = "..." 
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindButton.Text = currentKey.Name
                        listening = false
                        conn:Disconnect()
                        pcall(callback, currentKey)
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)
            return keybindFrame
        end

        -- 段落/多行文本控件
        function Elements:CreateParagraph(text, lines)
            local paragraphFrame = Instance.new("Frame")
            paragraphFrame.Size = UDim2.new(1, 0, 0, (lines or 2) * 24 + 12)
            paragraphFrame.BackgroundColor3 = Theme.ElementBackground
            paragraphFrame.Parent = TabPage
            AddCorner(paragraphFrame, 8)
            local paraLabel = Instance.new("TextLabel")
            paraLabel.Size = UDim2.new(1, -20, 1, -12)
            paraLabel.Position = UDim2.new(0, 10, 0, 6)
            paraLabel.BackgroundTransparency = 1
            paraLabel.Text = text
            paraLabel.TextColor3 = Theme.TextColor
            paraLabel.Font = Enum.Font.Gotham
            paraLabel.TextSize = 14
            paraLabel.TextXAlignment = Enum.TextXAlignment.Left
            paraLabel.TextWrapped = true
            paraLabel.Parent = paragraphFrame
            table.insert(themeUpdateFunctions, function(t)
                paragraphFrame.BackgroundColor3 = t.ElementBackground
                paraLabel.TextColor3 = t.TextColor
            end)
            return paragraphFrame
        end

        return Elements
    end

    function Window:Destroy()
        stopGradientAnimation()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    Window:ApplyTheme(initialTheme)

    return Window
end

return Library
