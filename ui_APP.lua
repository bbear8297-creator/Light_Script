-- AppleGlassUI Enhanced
-- 修复：自适应、悬浮球、窗口拖动、下拉菜单

local AppleGlassUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 样式配置
local Style = {
    BackgroundColor = Color3.fromRGB(255, 255, 255),
    GlassOpacity = 0.65,
    AccentColor = Color3.fromRGB(0, 122, 255),
    TextColor = Color3.fromRGB(40, 40, 40),
    SubTextColor = Color3.fromRGB(100, 100, 100),
    CornerRadius = UDim.new(0, 12),
    ShadowTransparency = 0.75,
    Font = Enum.Font.GothamSemibold,
    AnimationSpeed = 0.2,
}

-- 工具函数：计算屏幕比例尺寸
local function ScaleDimension(scaleX, scaleY, offsetX, offsetY)
    return UDim2.new(scaleX or 0, offsetX or 0, scaleY or 0, offsetY or 0)
end

-- 创建毛玻璃 Frame (自适应圆角、阴影)
function AppleGlassUI:CreateGlassFrame(parent, size, position, anchorPoint)
    local frame = Instance.new("Frame")
    frame.Size = size or ScaleDimension(0.3, 0.4, 0, 0)
    frame.Position = position or ScaleDimension(0.5, 0.5, 0, 0)
    frame.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Style.BackgroundColor
    frame.BackgroundTransparency = 1 - Style.GlassOpacity
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Style.CornerRadius
    corner.Parent = frame

    -- 模拟磨砂渐变
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(1, 0.15),
    })
    gradient.Rotation = 45
    gradient.Parent = frame

    -- 阴影层
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 3, 0, 5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = Style.ShadowTransparency
    shadow.BorderSizePixel = 0
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = Style.CornerRadius
    shadowCorner.Parent = shadow

    return frame
end

-- 创建标题 (自适应字号)
function AppleGlassUI:CreateTitle(parent, text, fontSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, fontSize or 24)
    label.Position = UDim2.new(0, 15, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text or "Title"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextScaled = true
    label.TextWrapped = false
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- 创建描述文本
function AppleGlassUI:CreateDescription(parent, text, fontSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, fontSize or 16)
    label.Position = UDim2.new(0, 15, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = text or "Description"
    label.TextColor3 = Style.SubTextColor
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- 分隔线
function AppleGlassUI:CreateDivider(parent, position)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -30, 0, 1)
    line.Position = position or UDim2.new(0, 15, 0, 70)
    line.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = parent
    return line
end

-- 按钮 (带悬停点击动画)
function AppleGlassUI:CreateButton(parent, text, callback, position, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(1, -30, 0, 40)
    button.Position = position or UDim2.new(0, 15, 0, 80)
    button.BackgroundColor3 = Style.AccentColor
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Text = text or "Button"
    button.TextColor3 = Style.AccentColor
    button.Font = Style.Font
    button.TextSize = 18
    button.TextScaled = true
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local originalTrans = button.BackgroundTransparency
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(Style.AnimationSpeed), {
            BackgroundTransparency = originalTrans + 0.2
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(Style.AnimationSpeed), {
            BackgroundTransparency = originalTrans
        }):Play()
    end)
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundTransparency = originalTrans + 0.3}):Play()
        task.wait(0.1)
        TweenService:Create(button, TweenInfo.new(Style.AnimationSpeed), {BackgroundTransparency = originalTrans}):Play()
    end)
    return button
end

-- 开关 (Toggle)
function AppleGlassUI:CreateToggle(parent, text, default, callback, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 45)
    frame.Position = position or UDim2.new(0, 15, 0, 130)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or "Toggle"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextSize = 18
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 56, 0, 30)
    toggleButton.Position = UDim2.new(1, -56, 0.5, -15)
    toggleButton.BackgroundColor3 = default and Style.AccentColor or Color3.fromRGB(180, 180, 180)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = default and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 4, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleButton
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default or false
    local function updateVisual()
        local targetColor = state and Style.AccentColor or Color3.fromRGB(180, 180, 180)
        local targetPos = state and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 4, 0.5, -12)
        TweenService:Create(toggleButton, TweenInfo.new(Style.AnimationSpeed), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(knob, TweenInfo.new(Style.AnimationSpeed), {Position = targetPos}):Play()
    end

    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if callback then callback(state) end
    end)

    return {
        Frame = frame,
        SetState = function(self, newState)
            if newState ~= state then
                state = newState
                updateVisual()
            end
        end,
        GetState = function() return state end
    }
end

-- 滑块 (Slider)
function AppleGlassUI:CreateSlider(parent, text, min, max, default, callback, position)
    min, max, default = min or 0, max or 100, default or 50
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 55)
    frame.Position = position or UDim2.new(0, 15, 0, 190)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text or "Slider"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 22)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Style.SubTextColor
    valueLabel.Font = Style.Font
    valueLabel.TextSize = 16
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 32)
    sliderBg.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Style.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateSlider(input)
        local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * relX
        valueLabel.Text = string.format("%.1f", val)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -10, 0.5, -10)
        if callback then callback(val) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return {
        Frame = frame,
        SetValue = function(self, newVal)
            local rel = (newVal - min) / (max - min)
            valueLabel.Text = string.format("%.1f", newVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -10, 0.5, -10)
        end
    }
end

-- 下拉菜单 (修复版)
function AppleGlassUI:CreateDropdown(parent, options, defaultIndex, callback, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 45)
    frame.Position = position or UDim2.new(0, 15, 0, 260)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    button.BackgroundTransparency = 0.4
    button.BorderSizePixel = 0
    button.Text = options[defaultIndex or 1] or "Select"
    button.TextColor3 = Style.TextColor
    button.Font = Style.Font
    button.TextSize = 18
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 24, 0, 24)
    arrow.Position = UDim2.new(1, -30, 0.5, -12)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://7072707677"
    arrow.Parent = button

    -- 下拉列表容器 (放在 ScreenGui 上层)
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(1, 0, 0, 0)
    dropdownList.Position = UDim2.new(0, 0, 1, 5)
    dropdownList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownList.BackgroundTransparency = 0.2
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 36)
    dropdownList.ScrollBarThickness = 6
    dropdownList.ZIndex = 10
    dropdownList.Parent = frame
    Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 10)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = dropdownList

    local selected = options[defaultIndex or 1]
    local optionButtons = {}

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -8, 0, 32)
        optBtn.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        optBtn.BackgroundTransparency = 0.3
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.TextColor3 = Style.TextColor
        optBtn.Font = Style.Font
        optBtn.TextSize = 16
        optBtn.ZIndex = 10
        optBtn.Parent = dropdownList
        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            button.Text = opt
            dropdownList.Visible = false
            if callback then callback(opt) end
        end)

        table.insert(optionButtons, optBtn)
    end

    button.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        if dropdownList.Visible then
            local itemCount = #options
            dropdownList.CanvasSize = UDim2.new(0, 0, 0, itemCount * 36 + (itemCount-1)*4)
            dropdownList.Size = UDim2.new(1, 0, 0, math.min(itemCount * 40, 200))
        end
    end)

    -- 点击外部关闭 (延迟绑定避免误触)
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dropdownList.Visible and not frame:IsAncestorOf(input.UserInputState) then
                dropdownList.Visible = false
            end
        end
    end
    UserInputService.InputBegan:Connect(onInputBegan)

    return {
        Frame = frame,
        GetSelected = function() return selected end,
        SetSelected = function(self, newOpt)
            for i, opt in ipairs(options) do
                if opt == newOpt then
                    selected = opt
                    button.Text = opt
                    break
                end
            end
        end
    }
end

-- 创建悬浮球 (可拖动，点击切换窗口)
function AppleGlassUI:CreateFloatingBall(parentWindow, onClick)
    local screenGui = parentWindow.ScreenGui
    local ball = Instance.new("ImageButton")
    ball.Size = UDim2.new(0, 60, 0, 60)
    ball.Position = UDim2.new(0, 20, 0.5, -30)
    ball.BackgroundColor3 = Style.AccentColor
    ball.BackgroundTransparency = 0.2
    ball.BorderSizePixel = 0
    ball.Image = "rbxassetid://7072725342" -- 可替换为你的图标
    ball.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ball.ScaleType = Enum.ScaleType.Fit
    ball.ZIndex = 5
    ball.Parent = screenGui
    Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

    -- 阴影
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 3, 0, 5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = ball.ZIndex - 1
    shadow.Parent = ball
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(1, 0)

    -- 拖动逻辑
    local dragging = false
    local dragStart, startPos

    ball.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = ball.Position
        end
    end)

    ball.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, screenGui.AbsoluteSize.X - ball.AbsoluteSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, screenGui.AbsoluteSize.Y - ball.AbsoluteSize.Y)
            ball.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- 点击事件
    ball.MouseButton1Click:Connect(function()
        if not dragging then
            parentWindow.MainFrame.Visible = not parentWindow.MainFrame.Visible
            if onClick then onClick(parentWindow.MainFrame.Visible) end
        end
    end)

    return ball
end

-- 创建完整窗口 (主入口)
function AppleGlassUI:CreateWindow(title, subtitle)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = (RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui")) or game.CoreGui
    screenGui.IgnoreGuiInset = true

    -- 根据屏幕大小计算窗口尺寸 (自适应)
    local screenSize = screenGui.AbsoluteSize
    local windowWidth = math.min(450, screenSize.X * 0.4)
    local windowHeight = math.min(600, screenSize.Y * 0.7)

    local mainFrame = self:CreateGlassFrame(
        screenGui,
        UDim2.new(0, windowWidth, 0, windowHeight),
        UDim2.new(0.5, -windowWidth/2, 0.5, -windowHeight/2),
        Vector2.new(0, 0)
    )
    mainFrame.Visible = true

    -- 标题栏 (用于拖动，并给予可见背景)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Style.BackgroundColor
    titleBar.BackgroundTransparency = 0.9  -- 半透明可见，保证能点击
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = Style.CornerRadius
    titleCorner.Parent = titleBar

    -- 拖动功能 (使用 titleBar 本身)
    local dragging = false
    local dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    self:CreateTitle(mainFrame, title or "Apple Glass UI", 26)
    self:CreateDescription(mainFrame, subtitle or "Elegant • Minimal • Powerful", 16)
    self:CreateDivider(mainFrame, UDim2.new(0, 15, 0, 75))

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -85)
    contentFrame.Position = UDim2.new(0, 0, 0, 85)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local windowObj = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentFrame = contentFrame,
        -- 便捷方法
        AddButton = function(self, text, callback)
            return AppleGlassUI:CreateButton(contentFrame, text, callback)
        end,
        AddToggle = function(self, text, default, callback)
            return AppleGlassUI:CreateToggle(contentFrame, text, default, callback)
        end,
        AddSlider = function(self, text, min, max, default, callback)
            return AppleGlassUI:CreateSlider(contentFrame, text, min, max, default, callback)
        end,
        AddDropdown = function(self, options, defaultIndex, callback)
            return AppleGlassUI:CreateDropdown(contentFrame, options, defaultIndex, callback)
        end,
    }

    -- 自动添加悬浮球
    windowObj.FloatingBall = self:CreateFloatingBall(windowObj)

    return windowObj
end

return AppleGlassUI
