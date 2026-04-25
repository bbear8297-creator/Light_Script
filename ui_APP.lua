--[[
    精美自适应通用 UI 库 v1.0.1 (色板弹窗可拖动)
    LS Team 开发
    修复：颜色选择器弹出窗口现在可以通过顶部标题栏自由拖拽移动
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

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
        DividerColor = Color3.fromRGB(220, 220, 220)
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
        DividerColor = Color3.fromRGB(180, 215, 225)
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
        DividerColor = Color3.fromRGB(210, 190, 170)
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
        DividerColor = Color3.fromRGB(230, 210, 210)
    }
}

-- ========== 创建窗口 ==========
function Library:CreateWindow(options)
    local WindowTitle = options.Title or "Executor UI"
    local initialTheme = options.Theme or "Default"
    local floatingBallImage = options.FloatingBallImage  -- 可选

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

    -- 悬浮球
    local FloatingBall
    if floatingBallImage then
        FloatingBall = Instance.new("ImageButton")
        FloatingBall.Image = floatingBallImage
        FloatingBall.BackgroundTransparency = 1
    else
        FloatingBall = Instance.new("TextButton")
        FloatingBall.Text = "UI"
        FloatingBall.TextColor3 = Theme.TextColor
        FloatingBall.Font = Enum.Font.GothamBold
        FloatingBall.TextSize = 18
    end
    FloatingBall.Size = UDim2.new(0, 50, 0, 50)
    FloatingBall.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingBall.Position = UDim2.new(0.1, 25, 0.1, 25)
    if not floatingBallImage then
        FloatingBall.BackgroundColor3 = Theme.ElementBackground
    end
    FloatingBall.Parent = ScreenGui
    AddCorner(FloatingBall, 25)
    local UIStrokeBall = Instance.new("UIStroke", FloatingBall)
    UIStrokeBall.Color = Theme.Accent
    UIStrokeBall.Thickness = 2
    local BallScale = Instance.new("UIScale", FloatingBall)

    table.insert(themeUpdateFunctions, function(t)
        if not floatingBallImage then
            FloatingBall.BackgroundColor3 = t.ElementBackground
            FloatingBall.TextColor3 = t.TextColor
        end
        UIStrokeBall.Color = t.Accent
    end)

    -- 主框架
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
    TopBar.BackgroundColor3 = Theme.TopBarBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    local TopBarCorner = Instance.new("UICorner", TopBar)
    TopBarCorner.CornerRadius = UDim.new(0, 16)
    local BottomHideFrame = Instance.new("Frame")
    BottomHideFrame.Size = UDim2.new(1, 0, 0.5, 0)
    BottomHideFrame.Position = UDim2.new(0, 0, 0.5, 0)
    BottomHideFrame.BackgroundColor3 = Theme.TopBarBackground
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
        TopBar.BackgroundColor3 = t.TopBarBackground
        BottomHideFrame.BackgroundColor3 = t.TopBarBackground
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

    -- 修复：侧边栏标签容器，动态 CanvasSize 避免多余滚动
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, 0, 1, -10)
    TabContainer.Position = UDim2.new(0, 0, 0, 5)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.ScrollingEnabled = true
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.Parent = TabContainer

    -- 关键修复：根据内容高度实时调整 CanvasSize，防止空白滚动
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
    end)

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

    -- 弹性展开/收回
    local isUiOpen = true
    local isAnimating = false

    FloatingBall.MouseButton1Click:Connect(function()
        if isAnimating then return end
        isAnimating = true
        local pressTween = TweenService:Create(BallScale, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 0.8})
        pressTween:Play()
        pressTween.Completed:Wait()
        TweenService:Create(BallScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

        isUiOpen = not isUiOpen

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

    local Window = {}
    local Tabs = {}
    local FirstTab = true
    local selectedTabButton = nil
    local currentDropdown = nil
    local activeKeybinds = {}

    local function closeDropdown()
        if currentDropdown then
            currentDropdown.list:Destroy()
            DropdownOverlay.Visible = false
            if currentDropdown.conn then currentDropdown.conn:Disconnect() end
            currentDropdown = nil
        end
    end

    function Window:ApplyTheme(themeName)
        closeDropdown()
        loadTheme(themeName)
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("UIGradient") then child:Destroy() end
        end
        for _, func in ipairs(themeUpdateFunctions) do
            func(Theme)
        end
    end

    -- 核心：色板联动整套主题
    function Window:SetAccentColor(color)
        local h, s, v = color:ToHSV()
        Theme.Accent = color
        Theme.MainBackground = Color3.fromHSV(h, s * 0.12, math.min(v + 0.35, 1))
        Theme.SidebarBackground = Color3.fromHSV(h, s * 0.18, math.min(v + 0.25, 1))
        Theme.ElementBackground = Color3.fromHSV(h, s * 0.08, math.min(v + 0.4, 1))
        Theme.TopBarBackground = Color3.fromHSV(h, s * 0.05, math.min(v + 0.45, 1))
        local bg = Theme.MainBackground
        local luminance = 0.299*bg.R + 0.587*bg.G + 0.114*bg.B
        local textColor = luminance > 0.55 and Color3.fromRGB(30,30,30) or Color3.fromRGB(240,240,240)
        Theme.TextColor = textColor
        Theme.TitleTextColor = textColor
        Theme.ElementTextColor = textColor
        Theme.ToggleOffColor = Color3.fromHSV(h, s * 0.05, math.min(v + 0.2, 1))
        Theme.DividerColor = Color3.fromHSV(h, s * 0.08, math.min(v + 0.3, 1))

        for _, func in ipairs(themeUpdateFunctions) do
            func(Theme)
        end
    end

    -- ========== 通知增强版：支持图片，自适应高度 ==========
    local currentNotification = nil
    function Window:Notify(title, message, duration, imageId)
        title = title or "通知"
        message = message or ""
        duration = duration or 4
        if currentNotification then
            currentNotification:Destroy()
        end

        local notifFrame = Instance.new("Frame")
        notifFrame.BackgroundColor3 = Theme.ElementBackground
        notifFrame.Size = UDim2.new(0, 240, 0, 0)
        notifFrame.Position = UDim2.new(1, 10, 0, 0)
        notifFrame.Parent = NotificationContainer
        AddCorner(notifFrame, 8)
        local stroke = Instance.new("UIStroke", notifFrame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 1

        local imgSize = 48
        local padding = 8
        local hasImage = imageId and true or false
        local textXOffset = hasImage and (imgSize + padding) or 0

        if hasImage then
            local notifImage = Instance.new("ImageLabel")
            notifImage.Size = UDim2.new(0, imgSize, 0, imgSize)
            notifImage.Position = UDim2.new(0, padding, 0.5, -imgSize/2)
            notifImage.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            notifImage.Image = imageId
            notifImage.ScaleType = Enum.ScaleType.Fit
            notifImage.Parent = notifFrame
            AddCorner(notifImage, 6)
        end

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -textXOffset - 20, 0, 20)
        titleLabel.Position = UDim2.new(0, textXOffset + 4, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Theme.TextColor
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notifFrame

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -textXOffset - 20, 0, 0)
        msgLabel.Position = UDim2.new(0, textXOffset + 4, 0, 30)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Theme.TextColor
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextSize = 13
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextWrapped = true
        msgLabel.Parent = notifFrame

        local function calculateMsgHeight()
            local textSize = TextService:GetTextSize(
                msgLabel.Text,
                msgLabel.TextSize,
                msgLabel.Font,
                Vector2.new(msgLabel.AbsoluteSize.X, math.huge)
            )
            return textSize.Y
        end

        local function adjustSize()
            local msgHeight = calculateMsgHeight()
            local minHeight = hasImage and (imgSize + 12) or 50
            local totalHeight = math.max(minHeight, 30 + msgHeight + 12)
            notifFrame.Size = UDim2.new(0, 240, 0, totalHeight)
            msgLabel.Size = UDim2.new(1, -textXOffset - 20, 0, msgHeight)
            notifFrame:TweenPosition(UDim2.new(1, -250, 0, 0), "Out", "Quad", 0.3)
        end

        task.defer(adjustSize)
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

    -- 标签页创建（图标可选背景）
    function Window:CreateTab(TabName, iconId, iconOptions)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(0.9, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TabButton.Text = ""
        TabButton.Parent = TabContainer
        AddCorner(TabButton, 8)

        local contentHolder = Instance.new("Frame")
        contentHolder.Size = UDim2.new(1, -10, 1, 0)
        contentHolder.Position = UDim2.new(0, 5, 0, 0)
        contentHolder.BackgroundTransparency = 1
        contentHolder.Parent = TabButton

        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Horizontal
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = contentHolder

        if iconId then
            if type(iconId) == "table" then
                iconOptions = iconId
                iconId = iconOptions.Image
            end
            local icon = Instance.new("ImageLabel")
            local defaultSize = UDim2.new(0, 18, 0, 18)
            if iconOptions and iconOptions.Size then
                defaultSize = iconOptions.Size
            end
            icon.Size = defaultSize
            icon.Image = iconId
            if iconOptions and iconOptions.BackgroundColor3 then
                icon.BackgroundColor3 = iconOptions.BackgroundColor3
                icon.BackgroundTransparency = iconOptions.BackgroundTransparency or 0
            else
                icon.BackgroundTransparency = 1
            end
            if iconOptions and iconOptions.ImageColor3 then
                icon.ImageColor3 = iconOptions.ImageColor3
            end
            icon.Parent = contentHolder
        end

        local tabText = Instance.new("TextLabel")
        tabText.Size = UDim2.new(1, -10, 1, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = TabName
        tabText.TextColor3 = Theme.TextColor
        tabText.Font = Enum.Font.GothamSemibold
        tabText.TextSize = 14
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.Parent = contentHolder

        table.insert(themeUpdateFunctions, function(t)
            if selectedTabButton == TabButton then return end
            tabText.TextColor3 = t.TextColor
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
            tabText.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                        BackgroundColor3 = Theme.Accent
                    }):Play()
                    local txt = tabData.Button:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel")
                    if txt then
                        TweenService:Create(txt, TweenInfo.new(0.2), {
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end
                else
                    tabData.Page.Visible = false
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    }):Play()
                    local txt = tabData.Button:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel")
                    if txt then
                        TweenService:Create(txt, TweenInfo.new(0.2), {
                            TextColor3 = Theme.TextColor
                        }):Play()
                    end
                end
            end
        end)

        local Elements = {}

        -- ========== 基础控件 ==========
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

        -- ========== 高级控件 ==========
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

        -- 色板颜色选择器（增加可拖动的标题栏）
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
                previewStroke.Color = t.Accent
            end
            table.insert(themeUpdateFunctions, apply)

            local pickerPopup = nil
            colorPreview.MouseButton1Click:Connect(function()
                if pickerPopup then pickerPopup:Destroy() end
                pickerPopup = Instance.new("Frame")
                pickerPopup.Size = UDim2.new(0, 224, 0, 218) -- 高度增加 18 给拖动条
                pickerPopup.Position = UDim2.new(0, colorPreview.AbsolutePosition.X - 160, 0, colorPreview.AbsolutePosition.Y + 32)
                pickerPopup.BackgroundColor3 = Theme.ElementBackground
                pickerPopup.BorderSizePixel = 0
                pickerPopup.ZIndex = 200
                pickerPopup.Parent = ScreenGui
                AddCorner(pickerPopup, 10)
                local popupStroke = Instance.new("UIStroke", pickerPopup)
                popupStroke.Color = Theme.Accent
                popupStroke.Thickness = 1

                -- ★ 新增拖动手柄 ★
                local DragBar = Instance.new("TextButton")
                DragBar.Size = UDim2.new(1, 0, 0, 18)
                DragBar.Position = UDim2.new(0, 0, 0, 0)
                DragBar.BackgroundColor3 = Theme.Accent
                DragBar.BackgroundTransparency = 0.7
                DragBar.Text = "⋮⋮ 拖动移动"
                DragBar.TextColor3 = Theme.TextColor
                DragBar.Font = Enum.Font.GothamBold
                DragBar.TextSize = 11
                DragBar.Parent = pickerPopup
                AddCorner(DragBar, 10)
                -- 使整个色板可拖动
                MakeDraggable(DragBar, pickerPopup)

                -- 饱和度/明度区 (向下偏移 22 像素)
                local svBox = Instance.new("ImageButton")
                svBox.Size = UDim2.new(0, 180, 0, 180)
                svBox.Position = UDim2.new(0, 8, 0, 26)
                svBox.Image = ""
                svBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                svBox.Parent = pickerPopup
                AddCorner(svBox, 4)

                local whiteGrad = Instance.new("UIGradient", svBox)
                whiteGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                })
                whiteGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })
                local blackGrad = Instance.new("UIGradient", svBox)
                blackGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                })
                blackGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })

                -- 色相条 (向下偏移 22 像素)
                local hueBar = Instance.new("ImageButton")
                hueBar.Size = UDim2.new(0, 22, 0, 180)
                hueBar.Position = UDim2.new(0, 194, 0, 26)
                hueBar.Image = ""
                hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueBar.Parent = pickerPopup
                AddCorner(hueBar, 4)
                local hueGrad = Instance.new("UIGradient", hueBar)
                hueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                hueGrad.Rotation = 90

                local svIndicator = Instance.new("Frame")
                svIndicator.Size = UDim2.new(0, 10, 0, 10)
                svIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
                svIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                svIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                svIndicator.BorderSizePixel = 1
                svIndicator.Parent = svBox
                AddCorner(svIndicator, 5)

                local hueIndicator = Instance.new("Frame")
                hueIndicator.Size = UDim2.new(1, 0, 0, 4)
                hueIndicator.AnchorPoint = Vector2.new(0, 0.5)
                hueIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                hueIndicator.BorderSizePixel = 1
                hueIndicator.Parent = hueBar

                local h, s, v = currentColor:ToHSV()
                svIndicator.Position = UDim2.new(s, 0, 1-v, 0)
                hueIndicator.Position = UDim2.new(0, 0, h, 0)

                local svDragging = false
                local hueDragging = false

                local function updateCurrentColor()
                    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    local newColor = Color3.fromHSV(h, s, v)
                    currentColor = newColor
                    colorPreview.BackgroundColor3 = currentColor
                    pcall(callback, currentColor)
                end

                local function updateSV(input)
                    local relX = math.clamp(input.Position.X - svBox.AbsolutePosition.X, 0, svBox.AbsoluteSize.X) / svBox.AbsoluteSize.X
                    local relY = math.clamp(input.Position.Y - svBox.AbsolutePosition.Y, 0, svBox.AbsoluteSize.Y) / svBox.AbsoluteSize.Y
                    s = relX
                    v = 1 - relY
                    svIndicator.Position = UDim2.new(s, 0, relY, 0)
                    updateCurrentColor()
                end

                svBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = true
                        updateSV(input)
                    end
                end)

                local function updateHue(input)
                    local relY = math.clamp(input.Position.Y - hueBar.AbsolutePosition.Y, 0, hueBar.AbsoluteSize.Y) / hueBar.AbsoluteSize.Y
                    h = relY
                    hueIndicator.Position = UDim2.new(0, 0, h, 0)
                    updateCurrentColor()
                end

                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        updateHue(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = false
                        hueDragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSV(input)
                    elseif hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateHue(input)
                    end
                end)

                -- 完成按钮 (向下偏移 26 像素)
                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(1, -16, 0, 26)
                closeBtn.Position = UDim2.new(0, 8, 0, 188)
                closeBtn.BackgroundColor3 = Theme.Accent
                closeBtn.Text = "完成"
                closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
                closeBtn.Font = Enum.Font.GothamSemibold
                closeBtn.TextSize = 14
                closeBtn.Parent = pickerPopup
                AddCorner(closeBtn, 6)
                closeBtn.MouseButton1Click:Connect(function()
                    pickerPopup:Destroy()
                    pickerPopup = nil
                end)

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
            local listenConn

            local function startListening()
                if listening then return end
                listening = true
                bindButton.Text = "..."
                listenConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindButton.Text = currentKey.Name
                        listening = false
                        if listenConn then
                            listenConn:Disconnect()
                            listenConn = nil
                        end
                        local old = activeKeybinds[text]
                        if old then old:Disconnect() end
                        activeKeybinds[text] = UserInputService.InputBegan:Connect(function(inp, gp)
                            if not gp and inp.KeyCode == currentKey then
                                pcall(callback, currentKey)
                            end
                        end)
                    end
                end)
            end

            bindButton.MouseButton1Click:Connect(startListening)

            local old = activeKeybinds[text]
            if old then old:Disconnect() end
            activeKeybinds[text] = UserInputService.InputBegan:Connect(function(inp, gp)
                if not gp and inp.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)

            return keybindFrame
        end

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
        for _, conn in pairs(activeKeybinds) do
            conn:Disconnect()
        end
        activeKeybinds = {}
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    Window:ApplyTheme(initialTheme)

    return Window
end

return Library
