--[[
    精美自适应通用 UI 库 v2.3
    修复：下拉定位、穿透；新增主题系统、完整示例
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}

-- 安全容器
local targetGui = (gethui and gethui()) or CoreGui
if not targetGui:FindFirstChild("RobloxGui") and not pcall(function() return CoreGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- 工具函数
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

-- ========== 默认主题 ==========
local DefaultTheme = {
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
    Gradient = nil -- 可设置 UIGradient
}

function Library:CreateWindow(options)
    local WindowTitle = options.Title or "My Executor UI"
    local initialTheme = options.Theme or {}
    -- 合并主题
    local Theme = {}
    for k, v in pairs(DefaultTheme) do
        Theme[k] = initialTheme[k] or v
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalExecutorUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetGui

    -- ========== 主题更新函数列表 ==========
    local themeUpdateFunctions = {}

    -- ========== 全屏遮罩（防穿透） ==========
    local DropdownOverlay = Instance.new("TextButton")
    DropdownOverlay.Name = "DropdownOverlay"
    DropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
    DropdownOverlay.BackgroundTransparency = 1
    DropdownOverlay.Text = ""
    DropdownOverlay.Visible = false
    DropdownOverlay.ZIndex = 5
    DropdownOverlay.Parent = ScreenGui

    -- ========== 通知容器 ==========
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.AnchorPoint = Vector2.new(1, 0)
    NotificationContainer.Position = UDim2.new(1, -10, 0, 50)
    NotificationContainer.Size = UDim2.new(0, 250, 1, -60)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.ClipsDescendants = false
    NotificationContainer.ZIndex = 10
    NotificationContainer.Parent = ScreenGui

    -- ========== 悬浮球 ==========
    local FloatingBall = Instance.new("TextButton")
    FloatingBall.Name = "FloatingBall"
    FloatingBall.Size = UDim2.new(0, 50, 0, 50)
    FloatingBall.Position = UDim2.new(0.1, 0, 0.1, 0)
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

    table.insert(themeUpdateFunctions, function(t)
        FloatingBall.BackgroundColor3 = t.ElementBackground
        FloatingBall.TextColor3 = t.TextColor
        UIStrokeBall.Color = t.Accent
    end)

    -- ========== 主框架 ==========
    local MainFrame = Instance.new("Frame")
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    MainFrame.BackgroundColor3 = Theme.MainBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 16)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.4

    -- 渐变（若有）
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
    Sidebar.Size = UDim2.new(0, 130, 1, -40)
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
    ContentContainer.Size = UDim2.new(1, -130, 1, -40)
    ContentContainer.Position = UDim2.new(0, 130, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    MakeDraggable(TopBar, MainFrame)
    MakeDraggable(FloatingBall, FloatingBall)

    FloatingBall.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    local Window = {}
    local Tabs = {}
    local FirstTab = true
    local selectedTabButton = nil
    local currentDropdown = nil

    -- 关闭下拉
    local function closeDropdown()
        if currentDropdown then
            currentDropdown.list:Destroy()
            DropdownOverlay.Visible = false
            currentDropdown = nil
        end
    end

    -- ========== 主题API ==========
    function Window:SetTheme(newTheme)
        for k, v in pairs(newTheme) do
            if Theme[k] ~= nil then
                Theme[k] = v
            end
        end
        -- 更新渐变
        if Theme.Gradient then
            -- 移除旧渐变
            for _, child in ipairs(MainFrame:GetChildren()) do
                if child:IsA("UIGradient") then child:Destroy() end
            end
            Theme.Gradient:Clone().Parent = MainFrame
        end
        -- 执行所有主题更新函数
        for _, func in ipairs(themeUpdateFunctions) do
            func(Theme)
        end
    end

    function Window:SetAccentColor(color)
        self:SetTheme({ Accent = color })
    end

    -- 通知系统
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

    -- 标签页
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
                    selectedTabButton.BackgroundColor3 = t.Accent
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
        local ELEMENT_BG_DEFAULT = Theme.ElementBackground
        local ELEMENT_TEXT_DEFAULT = Theme.ElementTextColor

        -- 标签
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

        -- 按钮（左对齐）
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

            local function applyTheme(t)
                Button.BackgroundColor3 = t.ElementBackground
                Button.TextColor3 = t.ElementTextColor
            end
            table.insert(themeUpdateFunctions, applyTheme)

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

        -- 开关
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

            local function applyTheme(t)
                ToggleFrame.BackgroundColor3 = t.ElementBackground
                ToggleLabel.TextColor3 = t.TextColor
                ToggleBtn.BackgroundColor3 = toggled and t.Accent or t.ToggleOffColor
            end
            table.insert(themeUpdateFunctions, applyTheme)

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

        -- 滑块
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

            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = BarBackground

            local function applyTheme(t)
                SliderFrame.BackgroundColor3 = t.ElementBackground
                SliderLabel.TextColor3 = t.TextColor
                BarFill.BackgroundColor3 = t.Accent
            end
            table.insert(themeUpdateFunctions, applyTheme)

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

        -- 信息面板
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
            serverLabel.Text = info.ServerInfo or "服务器信息: 未知"
            serverLabel.TextColor3 = Theme.TextColor
            serverLabel.Font = Enum.Font.Gotham
            serverLabel.TextSize = 13
            serverLabel.TextXAlignment = Enum.TextXAlignment.Left
            serverLabel.Parent = infoFrame

            local execLabel = Instance.new("TextLabel")
            execLabel.Size = UDim2.new(1, 0, 0, 18)
            execLabel.BackgroundTransparency = 1
            execLabel.Text = info.ExecutorInfo or "注入器: 未知"
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

        -- 下拉菜单（修复定位）
        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = Theme.ElementBackground
            DropdownFrame.Parent = TabPage
            AddCorner(DropdownFrame, 8)

            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(0.5, -10, 1, 0)
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = text
            DropdownLabel.TextColor3 = Theme.TextColor
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextSize = 14
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame

            local DropButton = Instance.new("TextButton")
            DropButton.Size = UDim2.new(0.45, -20, 0, 28)
            DropButton.Position = UDim2.new(1, -10, 0.5, -14)
            DropButton.AnchorPoint = Vector2.new(1, 0.5)
            DropButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            DropButton.Text = selected .. "  ▼"
            DropButton.TextColor3 = Theme.ElementTextColor
            DropButton.Font = Enum.Font.GothamSemibold
            DropButton.TextSize = 13
            DropButton.Parent = DropdownFrame
            AddCorner(DropButton, 6)

            local function applyTheme(t)
                DropdownFrame.BackgroundColor3 = t.ElementBackground
                DropdownLabel.TextColor3 = t.TextColor
                DropButton.TextColor3 = t.ElementTextColor
            end
            table.insert(themeUpdateFunctions, applyTheme)

            DropButton.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == DropButton then
                    closeDropdown()
                    return
                end

                closeDropdown()

                -- 创建下拉列表
                local list = Instance.new("Frame")
                list.Name = "DropdownList"
                list.BackgroundColor3 = Theme.ElementBackground
                list.BorderSizePixel = 0
                list.ZIndex = 10
                list.Parent = ScreenGui
                AddCorner(list, 8)

                local layout = Instance.new("UIListLayout")
                layout.Parent = list

                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = opt
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = (opt == selected) and Theme.Accent or Theme.ElementBackground
                    optBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.TextColor
                    optBtn.Text = opt
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 13
                    optBtn.ZIndex = 10
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

                -- 正确计算位置（左对齐按钮）
                local absPos = DropButton.AbsolutePosition
                local absSize = DropButton.AbsoluteSize
                list.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
                list.Size = UDim2.new(0, math.max(absSize.X, 200), 0, #options * 28)

                DropdownOverlay.Visible = true
                currentDropdown = {button = DropButton, list = list}

                -- 点击遮罩关闭
                DropdownOverlay.MouseButton1Click:Once(function()
                    closeDropdown()
                end)
            end)

            return DropdownFrame
        end

        return Elements
    end

    function Window:Destroy()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    -- 初始应用主题
    Window:SetTheme({}) -- 触发首次更新

    return Window
end

return Library
