--[[
    精美自适应通用 UI 库 v2.1
    新增：下拉菜单、通知系统、动态改色、按钮文本左对齐
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Library = {}

-- 保护UI容器
local targetGui = (gethui and gethui()) or CoreGui
if not targetGui:FindFirstChild("RobloxGui") and not pcall(function() return CoreGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- 全局拖拽函数
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
            moveObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- 圆角工具
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

-- 库初始化
function Library:CreateWindow(options)
    local WindowTitle = options.Title or "My Executor UI"
    local AccentColor = options.Color or Color3.fromRGB(85, 170, 255)

    -- 颜色表，用于动态更新
    local accentColorTable = { Current = AccentColor }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalExecutorUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetGui

    -- ========== 右上角通知容器 ==========
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.AnchorPoint = Vector2.new(1, 0)
    NotificationContainer.Position = UDim2.new(1, -10, 0, 50)
    NotificationContainer.Size = UDim2.new(0, 250, 1, -60)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.ClipsDescendants = false
    NotificationContainer.ZIndex = 10
    NotificationContainer.Parent = ScreenGui

    -- ========== 下拉菜单全局列表 ==========
    local DropdownList = Instance.new("Frame")
    DropdownList.Name = "DropdownList"
    DropdownList.Size = UDim2.new(0, 200, 0, 0)
    DropdownList.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.ZIndex = 10
    DropdownList.Parent = ScreenGui
    AddCorner(DropdownList, 8)

    local DropdownListLayout = Instance.new("UIListLayout")
    DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DropdownListLayout.Parent = DropdownList

    -- 悬浮球
    local FloatingBall = Instance.new("TextButton")
    FloatingBall.Name = "FloatingBall"
    FloatingBall.Size = UDim2.new(0, 50, 0, 50)
    FloatingBall.Position = UDim2.new(0.1, 0, 0.1, 0)
    FloatingBall.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    FloatingBall.Text = "UI"
    FloatingBall.TextColor3 = Color3.fromRGB(40, 40, 40)
    FloatingBall.Font = Enum.Font.GothamBold
    FloatingBall.TextSize = 18
    FloatingBall.Parent = ScreenGui
    AddCorner(FloatingBall, 25)

    local UIStrokeBall = Instance.new("UIStroke", FloatingBall)
    UIStrokeBall.Color = accentColorTable.Current
    UIStrokeBall.Thickness = 2

    -- 主UI框架
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 16)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = accentColorTable.Current
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.4

    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MaxSize = Vector2.new(650, 400)
    SizeConstraint.MinSize = Vector2.new(300, 250)
    SizeConstraint.Parent = MainFrame

    -- 顶部栏
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(252, 252, 252)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 16)
    TopBarCorner.Parent = TopBar

    local BottomHideFrame = Instance.new("Frame")
    BottomHideFrame.Size = UDim2.new(1, 0, 0.5, 0)
    BottomHideFrame.Position = UDim2.new(0, 0, 0.5, 0)
    BottomHideFrame.BackgroundColor3 = Color3.fromRGB(252, 252, 252)
    BottomHideFrame.BorderSizePixel = 0
    BottomHideFrame.Parent = TopBar

    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, 0, 0, 1)
    TopDivider.Position = UDim2.new(0, 0, 1, -1)
    TopDivider.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    TopDivider.BorderSizePixel = 0
    TopDivider.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowTitle
    TitleLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 16)
    SidebarCorner.Parent = Sidebar

    local RightHideFrame = Instance.new("Frame")
    RightHideFrame.Size = UDim2.new(0.5, 0, 1, 0)
    RightHideFrame.Position = UDim2.new(0.5, 0, 0, 0)
    RightHideFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    RightHideFrame.BorderSizePixel = 0
    RightHideFrame.Parent = Sidebar

    local SideDivider = Instance.new("Frame")
    SideDivider.Size = UDim2.new(0, 1, 1, 0)
    SideDivider.Position = UDim2.new(1, -1, 0, 0)
    SideDivider.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
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

    -- 内容区
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
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
    local dropdownCloseConn = nil

    -- 颜色更新函数列表
    local updateFunctions = {}

    -- ========== 动态改色API ==========
    function Window:SetAccentColor(newColor)
        accentColorTable.Current = newColor
        for _, func in ipairs(updateFunctions) do
            func(newColor)
        end
    end

    -- 添加更新函数
    table.insert(updateFunctions, function(c) UIStrokeBall.Color = c end)
    table.insert(updateFunctions, function(c) MainStroke.Color = c end)

    -- ========== 通知系统 ==========
    local currentNotification = nil
    function Window:Notify(title, message, duration)
        title = title or "通知"
        message = message or ""
        duration = duration or 4

        -- 如果已有通知，直接移除
        if currentNotification then
            currentNotification:Destroy()
            currentNotification = nil
        end

        local notifFrame = Instance.new("Frame")
        notifFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        notifFrame.Size = UDim2.new(0, 240, 0, 60)
        notifFrame.Position = UDim2.new(1, 10, 0, 0) -- 从右侧滑入
        notifFrame.Parent = NotificationContainer
        AddCorner(notifFrame, 8)
        local stroke = Instance.new("UIStroke", notifFrame)
        stroke.Color = Color3.fromRGB(200, 200, 200)
        stroke.Thickness = 1

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -16, 0, 20)
        titleLabel.Position = UDim2.new(0, 8, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notifFrame

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -16, 0, 20)
        msgLabel.Position = UDim2.new(0, 8, 0, 28)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextSize = 13
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextWrapped = true
        msgLabel.Parent = notifFrame

        -- 入场滑入动画
        notifFrame:TweenPosition(UDim2.new(1, -250, 0, 0), "Out", "Quad", 0.3)
        currentNotification = notifFrame

        -- 自动消失
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

    -- ========== 关闭下拉菜单的辅助函数 ==========
    local function closeDropdown()
        if DropdownList.Visible then
            DropdownList.Visible = false
            if dropdownCloseConn then
                dropdownCloseConn:Disconnect()
                dropdownCloseConn = nil
            end
            currentDropdown = nil
        end
    end

    -- ========== 标签页创建 ==========
    function Window:CreateTab(TabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(0.9, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TabButton.Text = TabName
        TabButton.TextColor3 = Color3.fromRGB(50, 50, 50)
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
        TabPage.ScrollBarImageColor3 = accentColorTable.Current
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
            TabButton.BackgroundColor3 = accentColorTable.Current
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            selectedTabButton = TabButton
            table.insert(updateFunctions, function(c)
                if selectedTabButton == TabButton then
                    selectedTabButton.BackgroundColor3 = c
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
                        BackgroundColor3 = accentColorTable.Current,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                else
                    tabData.Page.Visible = false
                    TweenService:Create(tabData.Button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                        TextColor3 = Color3.fromRGB(50, 50, 50)
                    }):Play()
                end
            end
        end)

        local Elements = {}
        local ELEMENT_BG = Color3.fromRGB(245, 245, 245)

        -- 标签
        function Elements:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundColor3 = ELEMENT_BG
            LabelFrame.Parent = TabPage
            AddCorner(LabelFrame, 8)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(40, 40, 40)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = LabelFrame
        end

        -- 按钮（文本左对齐）
        function Elements:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = ELEMENT_BG
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(30, 30, 30)
            Button.Font = Enum.Font.GothamSemibold
            Button.TextSize = 14
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.Parent = TabPage
            AddCorner(Button, 8)

            -- 文本左对齐留出边距
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10)
            padding.Parent = Button

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = accentColorTable.Current,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = ELEMENT_BG,
                    TextColor3 = Color3.fromRGB(30, 30, 30)
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
            ToggleFrame.BackgroundColor3 = ELEMENT_BG
            ToggleFrame.Parent = TabPage
            AddCorner(ToggleFrame, 8)

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
            ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
            ToggleBtn.BackgroundColor3 = toggled and accentColorTable.Current or Color3.fromRGB(180, 180, 180)
            ToggleBtn.Text = ""
            ToggleBtn.Parent = ToggleFrame
            AddCorner(ToggleBtn, 10)

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 16, 0, 16)
            Indicator.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Indicator.Parent = ToggleBtn
            AddCorner(Indicator, 8)

            -- 动态颜色更新函数
            local function updateToggleColor(newColor)
                ToggleBtn.BackgroundColor3 = toggled and newColor or Color3.fromRGB(180, 180, 180)
            end
            table.insert(updateFunctions, updateToggleColor)

            local function FireToggle()
                toggled = not toggled
                local goalColor = toggled and accentColorTable.Current or Color3.fromRGB(180, 180, 180)
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
            SliderFrame.BackgroundColor3 = ELEMENT_BG
            SliderFrame.Parent = TabPage
            AddCorner(SliderFrame, 8)

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -20, 0, 25)
            SliderLabel.Position = UDim2.new(0, 10, 0, 0)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text .. " : " .. tostring(default)
            SliderLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
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
            BarFill.BackgroundColor3 = accentColorTable.Current
            BarFill.Parent = BarBackground
            AddCorner(BarFill, 4)

            -- 颜色更新
            table.insert(updateFunctions, function(c) BarFill.BackgroundColor3 = c end)

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

        -- ★ 复合信息面板
        function Elements:CreateInfoPanel(info)
            local panel = Instance.new("Frame")
            panel.Size = UDim2.new(1, 0, 0, 80)
            panel.BackgroundColor3 = ELEMENT_BG
            panel.Parent = TabPage
            AddCorner(panel, 10)

            -- 左侧头像
            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 55, 0, 55)
            avatar.Position = UDim2.new(0, 12, 0.5, -27)
            avatar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            avatar.Parent = panel
            AddCorner(avatar, 27)

            -- 尝试加载真实头像
            spawn(function()
                pcall(function()
                    local userId = Players.LocalPlayer.UserId
                    local content = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    avatar.Image = content
                end)
            end)

            -- 右侧信息区
            local infoFrame = Instance.new("Frame")
            infoFrame.Size = UDim2.new(1, -80, 1, -10)
            infoFrame.Position = UDim2.new(0, 75, 0, 5)
            infoFrame.BackgroundTransparency = 1
            infoFrame.Parent = panel

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 2)
            layout.Parent = infoFrame

            -- 玩家名
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = info.PlayerName or Players.LocalPlayer.Name
            nameLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 15
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = infoFrame

            -- 服务器/游戏信息
            local serverLabel = Instance.new("TextLabel")
            serverLabel.Size = UDim2.new(1, 0, 0, 18)
            serverLabel.BackgroundTransparency = 1
            serverLabel.Text = info.ServerInfo or "服务器信息: 未知"
            serverLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
            serverLabel.Font = Enum.Font.Gotham
            serverLabel.TextSize = 13
            serverLabel.TextXAlignment = Enum.TextXAlignment.Left
            serverLabel.Parent = infoFrame

            -- 注入器信息
            local execLabel = Instance.new("TextLabel")
            execLabel.Size = UDim2.new(1, 0, 0, 18)
            execLabel.BackgroundTransparency = 1
            execLabel.Text = info.ExecutorInfo or "注入器: 未知"
            execLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
            execLabel.Font = Enum.Font.Gotham
            execLabel.TextSize = 13
            execLabel.TextXAlignment = Enum.TextXAlignment.Left
            execLabel.Parent = infoFrame

            return panel
        end

        -- ★ 下拉菜单
        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = ELEMENT_BG
            DropdownFrame.Parent = TabPage
            AddCorner(DropdownFrame, 8)

            -- 左侧标签
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(0.5, -10, 1, 0)
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = text
            DropdownLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextSize = 14
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame

            -- 右侧选择按钮
            local DropButton = Instance.new("TextButton")
            DropButton.Size = UDim2.new(0.45, -20, 0, 28)
            DropButton.Position = UDim2.new(1, -10, 0.5, -14)
            DropButton.AnchorPoint = Vector2.new(1, 0.5)
            DropButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            DropButton.Text = selected .. "  ▼"
            DropButton.TextColor3 = Color3.fromRGB(30, 30, 30)
            DropButton.Font = Enum.Font.GothamSemibold
            DropButton.TextSize = 13
            DropButton.Parent = DropdownFrame
            AddCorner(DropButton, 6)

            -- 点击事件
            DropButton.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == DropButton then
                    closeDropdown()
                    return
                end

                closeDropdown() -- 先关闭其他已打开的

                -- 清空旧选项
                for _, child in ipairs(DropdownList:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                -- 填充新选项
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = opt
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = (opt == selected) and accentColorTable.Current or Color3.fromRGB(245, 245, 245)
                    optBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
                    optBtn.Text = opt
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 13
                    optBtn.Parent = DropdownList
                    AddCorner(optBtn, 4)

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        DropButton.Text = selected .. "  ▼"
                        pcall(callback, selected)
                        closeDropdown()
                    end)

                    optBtn.MouseEnter:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.2), {
                            BackgroundColor3 = accentColorTable.Current,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end)
                    optBtn.MouseLeave:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.2), {
                            BackgroundColor3 = (opt == selected) and accentColorTable.Current or Color3.fromRGB(245, 245, 245),
                            TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
                        }):Play()
                    end)
                end

                -- 计算列表位置（相对于屏幕）
                local absPos = DropButton.AbsolutePosition
                local absSize = DropButton.AbsoluteSize
                DropdownList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
                DropdownList.Size = UDim2.new(0, math.max(absSize.X, 200), 0, #options * 28)
                DropdownList.Visible = true

                currentDropdown = {button = DropButton, options = options, selected = selected}

                -- 全局点击关闭
                if dropdownCloseConn then dropdownCloseConn:Disconnect() end
                dropdownCloseConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local pos = Vector2.new(input.Position.X, input.Position.Y)
                        local drpAbsPos = DropdownList.AbsolutePosition
                        local drpAbsSize = DropdownList.AbsoluteSize
                        local btnAbsPos = DropButton.AbsolutePosition
                        local btnAbsSize = DropButton.AbsoluteSize
                        if pos.X < drpAbsPos.X or pos.X > drpAbsPos.X + drpAbsSize.X or pos.Y < drpAbsPos.Y or pos.Y > drpAbsPos.Y + drpAbsSize.Y then
                            if pos.X < btnAbsPos.X or pos.X > btnAbsPos.X + btnAbsSize.X or pos.Y < btnAbsPos.Y or pos.Y > btnAbsPos.Y + btnAbsSize.Y then
                                closeDropdown()
                            end
                        end
                    end
                end)
            end)

            return DropdownFrame
        end

        return Elements
    end

    -- ★ 销毁UI方法
    function Window:Destroy()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    return Window
end

return Library
