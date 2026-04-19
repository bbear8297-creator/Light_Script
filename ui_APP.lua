-- AppleGlassUI - 苹果风格毛玻璃界面库
-- 适用于 Roblox 执行器脚本，提供简洁、可复用的 UI 组件

local AppleGlassUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 样式配置（可全局调整）
local Style = {
    BackgroundColor = Color3.fromRGB(255, 255, 255),    -- 基底白色
    GlassOpacity = 0.6,                                 -- 毛玻璃透明度 (0-1)
    BlurSize = 10,                                      -- 模糊程度 (通过 UIGradient 模拟)
    AccentColor = Color3.fromRGB(0, 122, 255),          -- 苹果蓝
    TextColor = Color3.fromRGB(50, 50, 50),
    SubTextColor = Color3.fromRGB(120, 120, 120),
    CornerRadius = UDim.new(0, 12),                     -- 圆角大小
    ShadowTransparency = 0.7,
    Font = Enum.Font.GothamSemibold,
    AnimationSpeed = 0.2,                               -- 缓动动画时长
}

-- 创建毛玻璃效果 Frame
function AppleGlassUI:CreateGlassFrame(parent, size, position, anchorPoint)
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(0, 300, 0, 200)
    frame.Position = position or UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Style.BackgroundColor
    frame.BackgroundTransparency = 1 - Style.GlassOpacity
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- 圆角效果
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Style.CornerRadius
    corner.Parent = frame

    -- 模拟模糊的渐变 (UIGradient 实现轻微的磨砂感)
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    gradient.Rotation = 45
    gradient.Parent = frame

    -- 柔和阴影 (通过额外的 Frame 模拟)
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 2, 0, 3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = Style.ShadowTransparency
    shadow.BorderSizePixel = 0
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = Style.CornerRadius
    shadowCorner.Parent = shadow

    -- 返回 frame 方便后续添加内容
    return frame
end

-- 创建标题文本
function AppleGlassUI:CreateTitle(parent, text, fontSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text or "Title"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextSize = fontSize or 20
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- 创建副标题/描述文本
function AppleGlassUI:CreateDescription(parent, text, fontSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = text or "Description"
    label.TextColor3 = Style.SubTextColor
    label.Font = Enum.Font.Gotham
    label.TextSize = fontSize or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- 创建分隔线
function AppleGlassUI:CreateDivider(parent, position)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = position or UDim2.new(0, 10, 0, 70)
    line.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    line.BackgroundTransparency = 0.6
    line.BorderSizePixel = 0
    line.Parent = parent
    return line
end

-- 创建苹果风格按钮
function AppleGlassUI:CreateButton(parent, text, callback, position, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(1, -20, 0, 36)
    button.Position = position or UDim2.new(0, 10, 0, 80)
    button.BackgroundColor3 = Style.AccentColor
    button.BackgroundTransparency = 0.1
    button.BorderSizePixel = 0
    button.Text = text or "Button"
    button.TextColor3 = Style.AccentColor
    button.Font = Style.Font
    button.TextSize = 16
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    -- 悬停与点击效果
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
        -- 点击动画
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundTransparency = originalTrans + 0.3
        }):Play()
        wait(0.1)
        TweenService:Create(button, TweenInfo.new(Style.AnimationSpeed), {
            BackgroundTransparency = originalTrans
        }):Play()
    end)

    return button
end

-- 创建开关 (Toggle)
function AppleGlassUI:CreateToggle(parent, text, default, callback, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = position or UDim2.new(0, 10, 0, 130)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text or "Toggle"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 48, 0, 26)
    toggleButton.Position = UDim2.new(1, -48, 0.5, -13)
    toggleButton.BackgroundColor3 = default and Style.AccentColor or Color3.fromRGB(200, 200, 200)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleButton

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = default or false

    local function updateVisual()
        local targetColor = state and Style.AccentColor or Color3.fromRGB(200, 200, 200)
        local targetPos = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
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
        GetState = function()
            return state
        end
    }
end

-- 创建滑块 (Slider)
function AppleGlassUI:CreateSlider(parent, text, min, max, default, callback, position)
    min = min or 0
    max = max or 100
    default = default or 50

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = position or UDim2.new(0, 10, 0, 180)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text or "Slider"
    label.TextColor3 = Style.TextColor
    label.Font = Style.Font
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Style.SubTextColor
    valueLabel.Font = Style.Font
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 4)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 2)
    sliderCorner.Parent = sliderBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Style.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobShadow = Instance.new("Frame")
    knobShadow.Size = UDim2.new(1, 0, 1, 0)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.6
    knobShadow.BorderSizePixel = 0
    knobShadow.ZIndex = knob.ZIndex - 1
    knobShadow.Parent = knob

    local knobShadowCorner = Instance.new("UICorner")
    knobShadowCorner.CornerRadius = UDim.new(1, 0)
    knobShadowCorner.Parent = knobShadow

    local dragging = false
    local function updateSlider(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * relativeX
        valueLabel.Text = string.format("%.1f", value)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
        if callback then callback(value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Frame = frame,
        SetValue = function(self, newValue)
            local relative = (newValue - min) / (max - min)
            valueLabel.Text = string.format("%.1f", newValue)
            fill.Size = UDim2.new(relative, 0, 1, 0)
            knob.Position = UDim2.new(relative, -8, 0.5, -8)
        end
    }
end

-- 创建下拉菜单 (简单版)
function AppleGlassUI:CreateDropdown(parent, options, defaultIndex, callback, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = position or UDim2.new(0, 10, 0, 240)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    button.BackgroundTransparency = 0.5
    button.BorderSizePixel = 0
    button.Text = options[defaultIndex or 1] or "Select"
    button.TextColor3 = Style.TextColor
    button.Font = Style.Font
    button.TextSize = 16
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -25, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://7072707677" -- 向下箭头 (可替换)
    arrow.Parent = button

    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(1, 0, 0, 0)
    dropdownList.Position = UDim2.new(0, 0, 1, 5)
    dropdownList.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    dropdownList.BackgroundTransparency = 0.2
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
    dropdownList.ScrollBarThickness = 6
    dropdownList.Parent = frame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = dropdownList

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = dropdownList

    local selected = options[defaultIndex or 1]
    local optionButtons = {}

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -4, 0, 28)
        optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.BackgroundTransparency = 0.3
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.TextColor3 = Style.TextColor
        optBtn.Font = Style.Font
        optBtn.TextSize = 14
        optBtn.Parent = dropdownList

        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 6)
        optCorner.Parent = optBtn

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
            dropdownList.Size = UDim2.new(1, 0, 0, math.min(#options * 30, 150))
            dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
        end
    end)

    -- 点击外部关闭
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not frame:IsAncestorOf(input.UserInputState) then
                dropdownList.Visible = false
            end
        end
    end)

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

-- 创建一个完整的窗口 (快捷方法)
function AppleGlassUI:CreateWindow(title, subtitle)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = (RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui")) or game.CoreGui

    local mainFrame = self:CreateGlassFrame(screenGui, UDim2.new(0, 400, 0, 500), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
    
    -- 拖动功能
    local dragging = false
    local dragStart, startPos
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

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
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    self:CreateTitle(mainFrame, title or "Apple Glass UI", 24)
    self:CreateDescription(mainFrame, subtitle or "Elegant • Minimal • Powerful", 14)
    self:CreateDivider(mainFrame, UDim2.new(0, 10, 0, 70))

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -80)
    contentFrame.Position = UDim2.new(0, 0, 0, 80)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentFrame = contentFrame,
        -- 便捷创建方法
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
end

-- 导出库
return AppleGlassUI