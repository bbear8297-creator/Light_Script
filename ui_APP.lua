-- ==================== AppleFrostUI - 苹果毛玻璃UI库 ====================
-- 作者：Grok 为你定制 | 风格：苹果高雅 + 真实毛玻璃
-- 使用 getgenv() 实现全局复用，后续脚本无需重复加载

local AppleFrostUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 毛玻璃Frame生成器（核心样式）
local function createGlassFrame(parent, size, position)
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(0, 650, 0, 480)
    frame.Position = position or UDim2.new(0.5, -325, 0.5, -240)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)      -- 深色毛玻璃底
    frame.BackgroundTransparency = 0.32
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame

    -- 毛玻璃描边
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.82
    stroke.Thickness = 2
    stroke.Parent = frame

    -- 高光渐变（模拟真实玻璃反光）
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,180))
    }
    gradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.65),
        NumberSequenceKeypoint.new(1, 0.88)
    }
    gradient.Rotation = 40
    gradient.Parent = frame

    return frame
end

-- 创建窗口
function AppleFrostUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "AppleFrostUI"
    local size = config.Size or UDim2.new(0, 680, 0, 520)

    -- 创建ScreenGui（执行器友好）
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AppleFrostUI_Main"
    screenGui.ResetOnSpawn = false

    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    else
        screenGui.Parent = player:WaitForChild("PlayerGui")
    end

    -- 主窗口
    local window = createGlassFrame(screenGui, size)

    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 56)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = window

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 24, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- 关闭按钮（苹果风格红点）
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -48, 0, 12)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    closeBtn.TextSize = 22
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 40, 40)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 90, 90)}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
        task.wait(0.25)
        screenGui:Destroy()
    end)

    -- 窗口拖拽
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- 内容区域（自动滚动）
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -48, 1, -80)
    content.Position = UDim2.new(0, 24, 0, 70)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = window

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 16)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = content

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
    end)

    -- 窗口对象（返回给用户调用）
    local windowObj = {
        Frame = window,
        Content = content,
        ScreenGui = screenGui
    }

    -- ==================== 组件方法 ====================

    function windowObj:CreateLabel(text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 42)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.TextSize = 17
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = self.Content
        return label
    end

    function windowObj:CreateButton(config)
        config = config or {}
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 52)
        btn.BackgroundColor3 = Color3.fromRGB(0, 122, 255) -- 经典苹果蓝
        btn.Text = config.Text or "Button"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 17
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = self.Content

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = btn

        -- 悬停动画
        local originalColor = btn.BackgroundColor3
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(0, 140, 255)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = originalColor}):Play()
        end)

        -- 点击反馈
        btn.MouseButton1Click:Connect(function()
            if config.Callback then config.Callback() end
            local click = TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.4})
            click:Play()
            click.Completed:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
            end)
        end)

        return btn
    end

    function windowObj:CreateToggle(config)
        config = config or {}
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 52)
        toggleFrame.BackgroundTransparency = 1
        toggleFrame.Parent = self.Content

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.75, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = config.Text or "Toggle"
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.TextSize = 17
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 54, 0, 32)
        switch.Position = UDim2.new(1, -70, 0.5, -16)
        switch.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        switch.Text = ""
        switch.Parent = toggleFrame

        local switchCorner = Instance.new("UICorner")
        switchCorner.CornerRadius = UDim.new(1, 0)
        switchCorner.Parent = switch

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 28, 0, 28)
        knob.Position = UDim2.new(0, 2, 0.5, -14)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = switch
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local state = config.Default or false
        local function update()
            if state then
                TweenService:Create(switch, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(0, 122, 255)}):Play()
                TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -30, 0.5, -14)}):Play()
            else
                TweenService:Create(switch, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(55, 55, 60)}):Play()
                TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 2, 0.5, -14)}):Play()
            end
        end
        update()

        switch.MouseButton1Click:Connect(function()
            state = not state
            update()
            if config.Callback then config.Callback(state) end
        end)

        return {Set = function(val) state = val; update() end}
    end

    function windowObj:CreateSlider(config)
        config = config or {}
        local min, max = config.Min or 0, config.Max or 100
        local default = math.clamp(config.Default or min, min, max)

        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, 0, 0, 72)
        sliderFrame.BackgroundTransparency = 1
        sliderFrame.Parent = self.Content

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 24)
        label.BackgroundTransparency = 1
        label.Text = config.Text or "Slider"
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.TextSize = 17
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderFrame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 60, 0, 24)
        valueLabel.Position = UDim2.new(1, -60, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
        valueLabel.TextSize = 15
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.Parent = sliderFrame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 10)
        bar.Position = UDim2.new(0, 0, 0, 38)
        bar.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        bar.Parent = sliderFrame
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 5)
        barCorner.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 5)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 22, 0, 22)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = bar
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local value = default
        local function updateSlider(percent)
            value = min + (max - min) * percent
            valueLabel.Text = math.floor(value + 0.5)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            knob.Position = UDim2.new(percent, -11, 0.5, -11)
        end
        updateSlider((default - min) / (max - min))

        local dragging = false
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local mousePos = UserInputService:GetMouseLocation().X
                local barPos = bar.AbsolutePosition.X
                local barWidth = bar.AbsoluteSize.X
                local percent = math.clamp((mousePos - barPos) / barWidth, 0, 1)
                updateSlider(percent)
                if config.Callback then config.Callback(value) end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation().X
                local barPos = bar.AbsolutePosition.X
                local barWidth = bar.AbsoluteSize.X
                local percent = math.clamp((mousePos - barPos) / barWidth, 0, 1)
                updateSlider(percent)
                if config.Callback then config.Callback(value) end
            end
        end)

        return {Set = function(v) value = math.clamp(v, min, max); updateSlider((value - min) / (max - min)) end}
    end

    return windowObj
end

-- 全局注册，方便后续脚本直接调用
getgenv().AppleFrostUI = AppleFrostUI

print("✅ AppleFrostUI 苹果毛玻璃UI库 已成功加载！")
print("   使用示例：local ui = getgenv().AppleFrostUI")
