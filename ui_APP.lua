--[[
    ═══════════════════════════════════════════════════════════════════
    LS Team UI Library · v2.0 "Liquid Glass"
    · 灵动岛 (Dynamic Island) 取代悬浮球，自适应胶囊体
    · 全局液态玻璃风格 (Window / Panel / Element / Island 四级)
    · 完全保持 v1.x API 兼容
    · 修复：主题回调泄漏、通知单条、pcall 无日志、命名冲突
    ═══════════════════════════════════════════════════════════════════
]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")

local Library = {}

-- ═══════════════════════════════════════════════════════════════════
-- 目标 GUI 层
-- ═══════════════════════════════════════════════════════════════════
local targetGui
do
    local ok, res = pcall(function() return gethui and gethui() end)
    targetGui = (ok and res) or CoreGui
end
if not pcall(function() return targetGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════════
-- 通用工具
-- ═══════════════════════════════════════════════════════════════════
local function MeasureText(text, size, font, maxW)
    return TextService:GetTextSize(text, size, font, Vector2.new(maxW or 2000, 2000))
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[LS_UI] callback error: " .. tostring(err)) end
end

-- ═══════════════════════════════════════════════════════════════════
-- 液态玻璃系统
-- ═══════════════════════════════════════════════════════════════════
local Glass = {}
Glass.Presets = {
    Window  = { Tint = Color3.fromRGB(14, 14, 20), TintT = 0.20, StrokeT = 0.80, Radius = 26 },
    Panel   = { Tint = Color3.fromRGB(28, 28, 36), TintT = 0.38, StrokeT = 0.86, Radius = 20 },
    Element = { Tint = Color3.fromRGB(48, 48, 60), TintT = 0.62, StrokeT = 0.92, Radius = 14 },
    Island  = { Tint = Color3.fromRGB(6,   6,  10), TintT = 0.02, StrokeT = 0.86, Radius = 19 },
    Bubble  = { Tint = Color3.fromRGB(60, 60, 75), TintT = 0.55, StrokeT = 0.90, Radius = 10 },
}

function Glass.Apply(parent, opts)
    opts = opts or {}
    local preset = Glass.Presets[opts.Preset or "Element"]
    local tint    = opts.Tint    or preset.Tint
    local tintT   = opts.TintT   or preset.TintT
    local strokeT = opts.StrokeT or preset.StrokeT
    local radius  = opts.Radius  or preset.Radius
    local hlOn    = opts.Highlight ~= false

    parent.BackgroundColor3 = tint
    parent.BackgroundTransparency = tintT
    parent.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = opts.StrokeColor or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = strokeT
    stroke.Thickness = opts.StrokeThickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent

    local hl
    if hlOn then
        hl = Instance.new("UIGradient")
        hl.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 155)),
        })
        hl.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.70),
            NumberSequenceKeypoint.new(0.5, 0.93),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        hl.Rotation = 90
        hl.Parent = parent
    end

    return { Corner = corner, Stroke = stroke, Highlight = hl }
end

-- ═══════════════════════════════════════════════════════════════════
-- 主题 (液态玻璃下调色板只改 Accent 与语义色)
-- ═══════════════════════════════════════════════════════════════════
Library.Themes = {
    Default = {
        Accent    = Color3.fromRGB(10, 132, 255),
        AccentHi  = Color3.fromRGB(80, 170, 255),
        Text      = Color3.fromRGB(240, 240, 245),
        SubText   = Color3.fromRGB(155, 155, 170),
        ToggleOff = Color3.fromRGB(75, 75, 90),
        Divider   = Color3.fromRGB(255, 255, 255),
        Success   = Color3.fromRGB(80, 220, 130),
        Warning   = Color3.fromRGB(255, 190, 60),
        Danger    = Color3.fromRGB(255, 90, 95),
    },
    Ocean = {
        Accent    = Color3.fromRGB(0, 190, 200),
        AccentHi  = Color3.fromRGB(0, 225, 235),
        Text      = Color3.fromRGB(235, 250, 255),
        SubText   = Color3.fromRGB(150, 195, 205),
        ToggleOff = Color3.fromRGB(60, 90, 100),
        Divider   = Color3.fromRGB(255, 255, 255),
        Success   = Color3.fromRGB(80, 220, 160),
        Warning   = Color3.fromRGB(255, 200, 80),
        Danger    = Color3.fromRGB(255, 100, 100),
    },
    Sunset = {
        Accent    = Color3.fromRGB(255, 95, 110),
        AccentHi  = Color3.fromRGB(255, 140, 150),
        Text      = Color3.fromRGB(255, 240, 240),
        SubText   = Color3.fromRGB(220, 170, 175),
        ToggleOff = Color3.fromRGB(110, 70, 80),
        Divider   = Color3.fromRGB(255, 255, 255),
        Success   = Color3.fromRGB(120, 220, 140),
        Warning   = Color3.fromRGB(255, 190, 90),
        Danger    = Color3.fromRGB(255, 90, 95),
    },
    Autumn = {
        Accent    = Color3.fromRGB(255, 140, 40),
        AccentHi  = Color3.fromRGB(255, 175, 90),
        Text      = Color3.fromRGB(255, 245, 235),
        SubText   = Color3.fromRGB(215, 185, 160),
        ToggleOff = Color3.fromRGB(100, 75, 55),
        Divider   = Color3.fromRGB(255, 255, 255),
        Success   = Color3.fromRGB(150, 220, 120),
        Warning   = Color3.fromRGB(255, 200, 80),
        Danger    = Color3.fromRGB(255, 100, 90),
    },
}

-- ═══════════════════════════════════════════════════════════════════
-- 灵动岛 (Dynamic Island)
-- ═══════════════════════════════════════════════════════════════════
local function CreateDynamicIsland(parent, callbacks)
    callbacks = callbacks or {}

    local CFG = {
        CompactH  = 40,
        ExpandedH = 100,
        MinCW     = 130,
        MinEW     = 280,
        AnimT     = 0.42,
        Style     = Enum.EasingStyle.Quart,
        Dir       = Enum.EasingDirection.Out,
    }

    local isExpanded = false
    local isAnimating = false

    -- ── 主容器 ──
    local Island = Instance.new("TextButton")
    Island.Name = "DynamicIsland"
    Island.AnchorPoint = Vector2.new(0.5, 0)
    Island.Position = UDim2.new(0.5, 0, 0, 16)
    Island.Size = UDim2.new(0, CFG.MinCW, 0, CFG.CompactH)
    Island.Text = ""
    Island.AutoButtonColor = false
    Island.ClipsDescendants = true
    Island.ZIndex = 200
    Island.Parent = parent

    local islandGlass = Glass.Apply(Island, {
        Preset = "Island",
        Radius = CFG.CompactH / 2,
    })

    -- 柔和外发光（模拟浮起阴影）
    local glow = Instance.new("Frame")
    glow.Name = "IslandGlow"
    glow.AnchorPoint = Vector2.new(0.5, 0)
    glow.Position = UDim2.new(0.5, 0, 0, 20)
    glow.Size = UDim2.new(0, CFG.MinCW + 8, 0, CFG.CompactH + 8)
    glow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    glow.BackgroundTransparency = 0.55
    glow.BorderSizePixel = 0
    glow.ZIndex = 190
    glow.Parent = parent
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glow

    local function syncGlow()
        glow.Position = UDim2.new(0.5, 0, 0, Island.Position.Y.Offset + 6)
        glow.Size = UDim2.new(0, Island.Size.X.Offset + 8, 0, Island.Size.Y.Offset + 6)
    end
    Island:GetPropertyChangedSignal("Position"):Connect(syncGlow)
    Island:GetPropertyChangedSignal("Size"):Connect(syncGlow)

    -- ── 收起态 ──
    local Compact = Instance.new("CanvasGroup")
    Compact.Name = "Compact"
    Compact.Size = UDim2.new(1, 0, 0, CFG.CompactH)
    Compact.BackgroundTransparency = 1
    Compact.GroupTransparency = 0
    Compact.ZIndex = 2
    Compact.Parent = Island

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    dot.BorderSizePixel = 0
    dot.ZIndex = 3
    dot.Parent = Compact
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- 呼吸动画
    task.spawn(function()
        while dot.Parent do
            TweenService:Create(dot, TweenInfo.new(1.1), { BackgroundTransparency = 0.55 }):Play()
            task.wait(1.1)
            TweenService:Create(dot, TweenInfo.new(1.1), { BackgroundTransparency = 0 }):Play()
            task.wait(1.1)
        end
    end)

    local compactTitle = Instance.new("TextLabel")
    compactTitle.Size = UDim2.new(1, -44, 1, 0)
    compactTitle.Position = UDim2.new(0, 36, 0, 0)
    compactTitle.BackgroundTransparency = 1
    compactTitle.Text = "LS UI"
    compactTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    compactTitle.Font = Enum.Font.GothamBold
    compactTitle.TextSize = 13
    compactTitle.TextXAlignment = Enum.TextXAlignment.Left
    compactTitle.ZIndex = 3
    compactTitle.Parent = Compact

    -- ── 展开态 ──
    local Expanded = Instance.new("CanvasGroup")
    Expanded.Name = "Expanded"
    Expanded.Size = UDim2.new(1, 0, 1, 0)
    Expanded.BackgroundTransparency = 1
    Expanded.GroupTransparency = 1
    Expanded.ZIndex = 2
    Expanded.Parent = Island

    local bigDot = Instance.new("Frame")
    bigDot.Size = UDim2.new(0, 10, 0, 10)
    bigDot.Position = UDim2.new(0, 18, 0, 22)
    bigDot.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    bigDot.BorderSizePixel = 0
    bigDot.ZIndex = 3
    bigDot.Parent = Expanded
    local bigDotCorner = Instance.new("UICorner")
    bigDotCorner.CornerRadius = UDim.new(1, 0)
    bigDotCorner.Parent = bigDot

    local expTitle = Instance.new("TextLabel")
    expTitle.Size = UDim2.new(1, -40, 0, 20)
    expTitle.Position = UDim2.new(0, 38, 0, 17)
    expTitle.BackgroundTransparency = 1
    expTitle.Text = "LS UI 调试器"
    expTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    expTitle.Font = Enum.Font.GothamBold
    expTitle.TextSize = 14
    expTitle.TextXAlignment = Enum.TextXAlignment.Left
    expTitle.ZIndex = 3
    expTitle.Parent = Expanded

    local expSub = Instance.new("TextLabel")
    expSub.Size = UDim2.new(1, -40, 0, 16)
    expSub.Position = UDim2.new(0, 38, 0, 38)
    expSub.BackgroundTransparency = 1
    expSub.Text = "运行中 · 0 个功能"
    expSub.TextColor3 = Color3.fromRGB(160, 160, 175)
    expSub.Font = Enum.Font.Gotham
    expSub.TextSize = 11
    expSub.TextXAlignment = Enum.TextXAlignment.Left
    expSub.ZIndex = 3
    expSub.Parent = Expanded

    -- 操作按钮行
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -32, 0, 22)
    btnRow.Position = UDim2.new(0, 16, 1, -30)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 3
    btnRow.Parent = Expanded

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Parent = btnRow

    local buttonDefs = {}
    local function addButton(text, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 0, 22)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.88
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 4
        btn.Parent = btnRow
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = btn
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = btn
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 11
        lbl.ZIndex = 5
        lbl.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.70 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.88 }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            if callbacks.OnAction then SafeCall(callbacks.OnAction, key) end
        end)
        table.insert(buttonDefs, { Text = text, Instance = btn })
        return btn
    end

    addButton("设置", "settings")
    addButton("通知", "notify")
    addButton("收起", "collapse")

    -- ── 自适应尺寸计算 ──
    local function computeCompactWidth()
        local w = MeasureText(compactTitle.Text, 13, Enum.Font.GothamBold).X
        return math.max(CFG.MinCW, 16 + 8 + 8 + w + 20)
    end

    local function computeExpandedWidth()
        local wTitle = MeasureText(expTitle.Text, 14, Enum.Font.GothamBold).X + 38 + 24
        local wSub   = MeasureText(expSub.Text, 11, Enum.Font.Gotham).X + 38 + 24
        local wBtns  = 0
        for _, b in ipairs(buttonDefs) do
            wBtns = wBtns + MeasureText(b.Text, 11, Enum.Font.GothamSemibold).X + 24 + 6
        end
        wBtns = wBtns + 32
        return math.max(CFG.MinEW, wTitle, wSub, wBtns)
    end

    -- ── 切换展开/收起 ──
    local function setExpanded(next, instant)
        if isAnimating or next == isExpanded then return end
        isAnimating = true
        isExpanded = next

        local targetW = next and computeExpandedWidth() or computeCompactWidth()
        local targetH = next and CFG.ExpandedH or CFG.CompactH
        local targetR = targetH / 2

        local tInfo = instant and TweenInfo.new(0)
            or TweenInfo.new(CFG.AnimT, CFG.Style, CFG.Dir)

        TweenService:Create(Island, tInfo, {
            Size = UDim2.new(0, targetW, 0, targetH)
        }):Play()
        TweenService:Create(islandGlass.Corner, tInfo, {
            CornerRadius = UDim.new(0, targetR)
        }):Play()

        TweenService:Create(Compact, TweenInfo.new(0.22), {
            GroupTransparency = next and 1 or 0
        }):Play()
        TweenService:Create(Expanded, TweenInfo.new(0.30, Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out, 0.08), {
            GroupTransparency = next and 0 or 1
        }):Play()

        task.delay(instant and 0 or CFG.AnimT, function()
            isAnimating = false
            if next then
                if callbacks.OnExpand then SafeCall(callbacks.OnExpand) end
            else
                if callbacks.OnCollapse then SafeCall(callbacks.OnCollapse) end
            end
        end)
    end

    -- ── 拖动 + 点击 (互斥) ──
    local dragging, dragStart, startPos, hasMoved
    Island.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = Island.Position
            -- 拖动反馈
            TweenService:Create(islandGlass.Stroke, TweenInfo.new(0.15), {
                Transparency = 0.55
            }):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then hasMoved = true end
            if hasMoved then
                Island.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not hasMoved then
                setExpanded(not isExpanded)
            end
            dragging = false
            hasMoved = false
            TweenService:Create(islandGlass.Stroke, TweenInfo.new(0.25), {
                Transparency = 0.86
            }):Play()
        end
    end)

    -- ── 对外 API ──
    local API = {}
    API.Frame = Island

    function API.SetExpanded(v) setExpanded(v) end
    function API.Toggle() setExpanded(not isExpanded) end
    function API.IsExpanded() return isExpanded end

    function API.SetStatus(text)
        compactTitle.Text = text
        expSub.Text = text
        if not isExpanded then
            TweenService:Create(Island, TweenInfo.new(0.3, CFG.Style, CFG.Dir), {
                Size = UDim2.new(0, computeCompactWidth(), 0, CFG.CompactH)
            }):Play()
        end
    end

    function API.SetTitle(text)
        expTitle.Text = text
        if isExpanded then
            TweenService:Create(Island, TweenInfo.new(0.3, CFG.Style, CFG.Dir), {
                Size = UDim2.new(0, computeExpandedWidth(), 0, CFG.ExpandedH)
            }):Play()
        end
    end

    function API.SetDotColor(color)
        dot.BackgroundColor3 = color
        bigDot.BackgroundColor3 = color
    end

    function API.Destroy()
        glow:Destroy()
        Island:Destroy()
    end

    return API
end

-- ═══════════════════════════════════════════════════════════════════
-- 创建窗口
-- ═══════════════════════════════════════════════════════════════════
function Library:CreateWindow(options)
    options = options or {}
    local WindowTitle = options.Title or "LS UI"
    local initialTheme = options.Theme or "Default"

    local Theme = {}
    local function loadTheme(name)
        local t = Library.Themes[name] or Library.Themes.Default
        for k, _ in pairs(Library.Themes.Default) do
            Theme[k] = t[k]
        end
    end
    loadTheme(initialTheme)

    -- ── ScreenGui ──
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalExecutorUI_" .. tostring(math.random(1, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Parent = targetGui

    -- 主题回调管理（带 id，方便销毁时清理）
    local themeRegistry = {}
    local themeIdCounter = 0
    local function RegisterTheme(fn)
        themeIdCounter = themeIdCounter + 1
        local id = themeIdCounter
        themeRegistry[id] = fn
        return id
    end
    local function UnregisterTheme(id)
        themeRegistry[id] = nil
    end
    local function RunTheme()
        for _, fn in pairs(themeRegistry) do
            pcall(fn, Theme)
        end
    end

    -- ── 遮罩 ──
    local Overlay = Instance.new("TextButton")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.Text = ""
    Overlay.Visible = false
    Overlay.Active = true
    Overlay.ZIndex = 500
    Overlay.Parent = ScreenGui

    -- ── 通知容器（右上角，通知队列） ──
    local NotifContainer = Instance.new("Frame")
    NotifContainer.AnchorPoint = Vector2.new(1, 0)
    NotifContainer.Position = UDim2.new(1, -14, 0, 70)
    NotifContainer.Size = UDim2.new(0, 260, 1, -100)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.ClipsDescendants = false
    NotifContainer.ZIndex = 400
    NotifContainer.Parent = ScreenGui
    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = NotifContainer
    local notifOrder = 0

    -- ── 灵动岛 ──
    local MainFrame -- 前置声明
    local MainScale
    local Island

    local function showMain()
        if MainFrame.Visible and MainScale.Scale > 0.5 then
            -- 已显示，脉冲一下
            TweenService:Create(MainScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 0.96
            }):Play()
            task.delay(0.15, function()
                TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Scale = 1
                }):Play()
            end)
            return
        end
        MainFrame.Visible = true
        TweenService:Create(MainScale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()
    end

    local function hideMain()
        TweenService:Create(MainScale, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0
        }):Play()
        task.delay(0.28, function()
            MainFrame.Visible = false
        end)
    end

    Island = CreateDynamicIsland(ScreenGui, {
        OnExpand = function() end,
        OnCollapse = function() end,
        OnAction = function(key)
            if key == "settings" then
                showMain()
                Island.SetExpanded(false)
            elseif key == "notify" then
                -- 由外层绑定
                if options.OnIslandNotify then
                    SafeCall(options.OnIslandNotify)
                else
                    Library:_IslandNotify()
                end
            elseif key == "collapse" then
                Island.SetExpanded(false)
            end
        end,
    })

    -- ── 主窗 ──
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = true
    MainFrame.ZIndex = 100
    MainFrame.Parent = ScreenGui

    local mainGlass = Glass.Apply(MainFrame, { Preset = "Window", Radius = 26 })

    MainScale = Instance.new("UIScale")
    MainScale.Scale = 1
    MainScale.Parent = MainFrame

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(680, 440)
    sizeConstraint.MinSize = Vector2.new(340, 280)
    sizeConstraint.Parent = MainFrame

    -- 主窗外发光
    local mainGlow = Instance.new("Frame")
    mainGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    mainGlow.Position = UDim2.new(0.5, 0, 0.55, 0)
    mainGlow.Size = UDim2.new(0.9, 12, 0.85, 12)
    mainGlow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainGlow.BackgroundTransparency = 0.6
    mainGlow.BorderSizePixel = 0
    mainGlow.ZIndex = 99
    mainGlow.Parent = ScreenGui
    local mainGlowCorner = Instance.new("UICorner")
    mainGlowCorner.CornerRadius = UDim.new(0, 30)
    mainGlowCorner.Parent = mainGlow
    local mainGlowScale = Instance.new("UIScale")
    mainGlowScale.Scale = 1
    mainGlowScale.Parent = mainGlow

    -- 保持发光跟随主窗
    MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        mainGlow.Position = MainFrame.Position
    end)
    MainFrame:GetPropertyChangedSignal("Size"):Connect(function()
        mainGlow.Size = UDim2.new(
            MainFrame.Size.X.Scale, MainFrame.Size.X.Offset + 12,
            MainFrame.Size.Y.Scale, MainFrame.Size.Y.Offset + 12
        )
    end)
    MainScale:GetPropertyChangedSignal("Scale"):Connect(function()
        mainGlowScale.Scale = MainScale.Scale
        mainGlow.Visible = MainScale.Scale > 0.05
    end)

    -- ── 顶部栏 ──
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 46)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 2
    TopBar.Parent = MainFrame

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Size = UDim2.new(1, -110, 1, 0)
    TopTitle.Position = UDim2.new(0, 20, 0, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Text = WindowTitle
    TopTitle.TextColor3 = Theme.Text
    TopTitle.Font = Enum.Font.GothamBold
    TopTitle.TextSize = 15
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.ZIndex = 3
    TopTitle.Parent = TopBar

    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = TopBar
    local closeGlass = Glass.Apply(closeBtn, { Preset = "Bubble", Radius = 13, Highlight = false })
    closeGlass.Stroke.Transparency = 0.9

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.35,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.55,
            TextColor3 = Theme.SubText
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(hideMain)

    -- 顶部分隔线
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -24, 0, 1)
    topDivider.Position = UDim2.new(0, 12, 1, -1)
    topDivider.BackgroundColor3 = Theme.Divider
    topDivider.BackgroundTransparency = 0.88
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = 3
    topDivider.Parent = TopBar

    -- 主窗可拖动
    do
        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- ── 侧边栏 ──
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0.28, 0, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ZIndex = 2
    Sidebar.Parent = MainFrame

    -- 侧边玻璃内胆
    local sidebarInner = Instance.new("Frame")
    sidebarInner.Name = "SidebarInner"
    sidebarInner.Size = UDim2.new(1, -16, 1, -16)
    sidebarInner.Position = UDim2.new(0, 8, 0, 8)
    sidebarInner.ZIndex = 2
    sidebarInner.Parent = Sidebar
    local sidebarGlass = Glass.Apply(sidebarInner, { Preset = "Panel", Radius = 18 })

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.Parent = sidebarInner
    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 8)
    sidebarPad.PaddingBottom = UDim.new(0, 8)
    sidebarPad.Parent = sidebarInner

    -- 滚动容器
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.ScrollingEnabled = true
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ZIndex = 3
    TabContainer.Parent = sidebarInner
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 4)
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabListLayout.Parent = TabContainer
    tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y + 8)
    end)

    -- ── 内容区 ──
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(0.72, 0, 1, -46)
    ContentContainer.Position = UDim2.new(0.28, 0, 0, 46)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ZIndex = 2
    ContentContainer.Parent = MainFrame

    -- ═══════════════════════════════════════════════════════════
    -- 通知系统（队列，玻璃化）
    -- ═══════════════════════════════════════════════════════════
    local function makeNotification(title, message, duration, imageId)
        title = title or "通知"
        message = message or ""
        duration = duration or 4

        notifOrder = notifOrder + 1
        local order = notifOrder

        local notif = Instance.new("Frame")
        notif.Name = "Notif"
        notif.Size = UDim2.new(1, 0, 0, 0)
        notif.ZIndex = 401
        notif.LayoutOrder = order
        notif.Parent = NotifContainer

        local nGlass = Glass.Apply(notif, { Preset = "Panel", Radius = 14 })

        -- 左侧 Accent 色条
        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 1, -16)
        accentBar.Position = UDim2.new(0, 8, 0.5, -((notif.AbsoluteSize.Y - 16) / 2))
        accentBar.BackgroundColor3 = Theme.Accent
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 3
        accentBar.Parent = notif
        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(1, 0)
        abCorner.Parent = accentBar

        -- 图片
        local imgSize = 40
        local padX = 14
        local hasImage = imageId and true or false
        local textX = hasImage and (padX + imgSize + 10) or (padX + 6)

        if hasImage then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, imgSize, 0, imgSize)
            img.Position = UDim2.new(0, padX + 6, 0, 12)
            img.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
            img.BackgroundTransparency = 0.5
            img.Image = imageId
            img.ScaleType = Enum.ScaleType.Crop
            img.ZIndex = 3
            img.Parent = notif
            local ic = Instance.new("UICorner")
            ic.CornerRadius = UDim.new(0, 8)
            ic.Parent = img
        end

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -textX - 16, 0, 20)
        titleLbl.Position = UDim2.new(0, textX, 0, 12)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = Theme.Text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 3
        titleLbl.Parent = notif

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -textX - 16, 0, 0)
        msgLbl.Position = UDim2.new(0, textX, 0, 34)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text = message
        msgLbl.TextColor3 = Theme.SubText
        msgLbl.Font = Enum.Font.Gotham
        msgLbl.TextSize = 12
        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
        msgLbl.TextWrapped = true
        msgLbl.ZIndex = 3
        msgLbl.Parent = notif

        -- 动态高度
        local maxWidth = 260 - textX - 16
        local textH = MeasureText(message, 12, Enum.Font.Gotham, maxWidth).Y
        local minH = hasImage and (imgSize + 24) or 64
        local totalH = math.max(minH, 34 + textH + 16)
        msgLbl.Size = UDim2.new(1, -textX - 16, 0, textH)
        notif.Size = UDim2.new(1, 0, 0, totalH)

        -- 入场动画
        local nScale = Instance.new("UIScale")
        nScale.Scale = 0.85
        nScale.Parent = notif
        notif.Position = UDim2.new(1, 40, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        TweenService:Create(nScale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()

        -- 呼吸 Accent
        accentBar.BackgroundTransparency = 0.3
        TweenService:Create(accentBar, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()

        -- 出场
        task.delay(duration, function()
            if not notif.Parent then return end
            TweenService:Create(notif, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, 0)
            }):Play()
            TweenService:Create(nScale, TweenInfo.new(0.32), { Scale = 0.85 }):Play()
            task.wait(0.32)
            if notif.Parent then notif:Destroy() end
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- Window 对象
    -- ═══════════════════════════════════════════════════════════
    local Window = {}
    local Tabs = {}
    local firstTab = true
    local selectedTabButton = nil
    local selectedTabText = nil
    local currentDropdown = nil
    local activeKeybinds = {}

    local function closeDropdown()
        if currentDropdown then
            if currentDropdown.list then currentDropdown.list:Destroy() end
            if currentDropdown.conn then currentDropdown.conn:Disconnect() end
            Overlay.Visible = false
            currentDropdown = nil
        end
    end

    function Window:ApplyTheme(name)
        closeDropdown()
        loadTheme(name)
        RunTheme()
    end

    function Window:SetAccentColor(color)
        local h, s, v = color:ToHSV()
        Theme.Accent = color
        Theme.AccentHi = Color3.fromHSV(h, math.max(s - 0.15, 0), math.min(v + 0.15, 1))
        -- 语义色不变
        RunTheme()
    end

    function Window:Notify(title, message, duration, imageId)
        makeNotification(title, message, duration, imageId)
    end

    -- 灵动岛"通知"按钮用：一个演示通知
    function Library:_IslandNotify()
        makeNotification("灵动岛", "点击了通知按钮", 2)
    end

    function Window:SetIslandStatus(text) Island.SetStatus(text) end
    function Window:SetIslandTitle(text)  Island.SetTitle(text)  end
    function Window:SetIslandDot(color)   Island.SetDotColor(color) end
    function Window:ShowMain() showMain() end
    function Window:HideMain() hideMain() end

    -- ═══════════════════════════════════════════════════════════
    -- 标签页
    -- ═══════════════════════════════════════════════════════════
    function Window:CreateTab(TabName, iconId, iconOptions)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(1, -12, 0, 34)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.ZIndex = 4
        TabButton.Parent = TabContainer
        local tbGlass = Glass.Apply(TabButton, { Preset = "Bubble", Radius = 10, Highlight = false })
        tbGlass.Stroke.Transparency = 0.95

        local tbScale = Instance.new("UIScale")
        tbScale.Scale = 1
        tbScale.Parent = TabButton

        local contentHolder = Instance.new("Frame")
        contentHolder.Size = UDim2.new(1, -16, 1, 0)
        contentHolder.Position = UDim2.new(0, 8, 0, 0)
        contentHolder.BackgroundTransparency = 1
        contentHolder.ZIndex = 5
        contentHolder.Parent = TabButton
        local chLayout = Instance.new("UIListLayout")
        chLayout.FillDirection = Enum.FillDirection.Horizontal
        chLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        chLayout.Padding = UDim.new(0, 8)
        chLayout.Parent = contentHolder

        if iconId then
            if type(iconId) == "table" then
                iconOptions = iconId
                iconId = iconOptions.Image
            end
            local icon = Instance.new("ImageLabel")
            local defaultSize = UDim2.new(0, 16, 0, 16)
            if iconOptions and iconOptions.Size then defaultSize = iconOptions.Size end
            icon.Size = defaultSize
            icon.Image = iconId
            icon.BackgroundTransparency = 1
            if iconOptions and iconOptions.BackgroundColor3 then
                icon.BackgroundColor3 = iconOptions.BackgroundColor3
                icon.BackgroundTransparency = iconOptions.BackgroundTransparency or 0
            end
            if iconOptions and iconOptions.ImageColor3 then
                icon.ImageColor3 = iconOptions.ImageColor3
            end
            icon.ZIndex = 6
            icon.Parent = contentHolder
        end

        local tabText = Instance.new("TextLabel")
        tabText.Size = UDim2.new(1, -10, 1, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = TabName
        tabText.TextColor3 = Theme.Text
        tabText.Font = Enum.Font.GothamSemibold
        tabText.TextSize = 13
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.ZIndex = 6
        tabText.Parent = contentHolder

        local isSelected = false
        local function applyTheme(t)
            if isSelected then
                tabText.TextColor3 = Color3.fromRGB(255, 255, 255)
                tbGlass.Stroke.Color = t.Accent
                tbGlass.Stroke.Transparency = 0.4
                TabButton.BackgroundColor3 = t.Accent
                TabButton.BackgroundTransparency = 0.15
            else
                tabText.TextColor3 = t.Text
                tbGlass.Stroke.Color = Color3.fromRGB(255, 255, 255)
                tbGlass.Stroke.Transparency = 0.95
                TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TabButton.BackgroundTransparency = 1
            end
        end
        local themeId = RegisterTheme(applyTheme)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = TabName .. "_Page"
        TabPage.Size = UDim2.new(1, -24, 1, -24)
        TabPage.Position = UDim2.new(0, 12, 0, 12)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.Visible = firstTab
        TabPage.ZIndex = 2
        TabPage.Parent = ContentContainer

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = TabPage
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 12)
        end)

        local function selectThis()
            for _, data in ipairs(Tabs) do
                if data.Button == TabButton then
                    data.Page.Visible = true
                    data.setSelected(true)
                else
                    data.Page.Visible = false
                    data.setSelected(false)
                end
            end
            selectedTabButton = TabButton
        end

        local function setSelected(v)
            isSelected = v
            applyTheme(Theme)
        end

        table.insert(Tabs, { Button = TabButton, Page = TabPage, setSelected = setSelected })

        if firstTab then
            firstTab = false
            setSelected(true)
            selectedTabButton = TabButton
        end

        TabButton.MouseEnter:Connect(function()
            if not isSelected then
                TweenService:Create(TabButton, TweenInfo.new(0.18), {
                    BackgroundTransparency = 0.88
                }):Play()
            end
            TweenService:Create(tbScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1.02
            }):Play()
        end)
        TabButton.MouseLeave:Connect(function()
            if not isSelected then
                TweenService:Create(TabButton, TweenInfo.new(0.18), {
                    BackgroundTransparency = 1
                }):Play()
            end
            TweenService:Create(tbScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1
            }):Play()
        end)
        TabButton.MouseButton1Click:Connect(selectThis)

        -- ═════════════════════════════════════════════════════════
        -- 控件工厂
        -- ═════════════════════════════════════════════════════════
        local Elements = {}

        -- ── Label ──
        function Elements:CreateLabel(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 30)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12, Highlight = false })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -24, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.SubText
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            RegisterTheme(function(t)
                lbl.TextColor3 = t.SubText
                frame.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
            end)
            return frame
        end

        -- ── Button ──
        function Elements:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 38)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 3
            btn.Parent = TabPage
            local g = Glass.Apply(btn, { Preset = "Element", Radius = 12 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -24, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.GothamSemibold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = btn

            -- 右侧箭头
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -28, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "›"
            arrow.TextColor3 = Theme.SubText
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 18
            arrow.ZIndex = 4
            arrow.Parent = btn

            local function apply(t)
                lbl.TextColor3 = t.Text
                arrow.TextColor3 = t.SubText
                btn.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
                btn.BackgroundTransparency = 0.62
            end
            RegisterTheme(apply)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.45
                }):Play()
                TweenService:Create(g.Stroke, TweenInfo.new(0.18), {
                    Color = Theme.AccentHi,
                    Transparency = 0.4
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Color3.fromRGB(48, 48, 60),
                    BackgroundTransparency = 0.62
                }):Play()
                TweenService:Create(g.Stroke, TweenInfo.new(0.18), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Transparency = 0.92
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Theme.Text
                }):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                SafeCall(callback)
            end)
            return btn
        end

        -- ── Toggle ──
        function Elements:CreateToggle(text, default, callback)
            local toggled = default or false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 38)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12 })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -80, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(0, 42, 0, 22)
            track.AnchorPoint = Vector2.new(1, 0.5)
            track.Position = UDim2.new(1, -14, 0.5, 0)
            track.Text = ""
            track.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
            track.AutoButtonColor = false
            track.ZIndex = 4
            track.Parent = frame
            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(1, 0)
            tCorner.Parent = track

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 5
            knob.Parent = track
            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = UDim.new(1, 0)
            kCorner.Parent = knob
            local kShadow = Instance.new("UIStroke")
            kShadow.Color = Color3.fromRGB(0, 0, 0)
            kShadow.Transparency = 0.85
            kShadow.Parent = knob

            local function apply(t)
                lbl.TextColor3 = t.Text
                track.BackgroundColor3 = toggled and t.Accent or t.ToggleOff
            end
            RegisterTheme(apply)

            local function fire()
                toggled = not toggled
                local goal = toggled and Theme.Accent or Theme.ToggleOff
                local pos = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                TweenService:Create(track, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                    BackgroundColor3 = goal
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                    Position = pos
                }):Play()
                SafeCall(callback, toggled)
            end
            track.MouseButton1Click:Connect(fire)
            return frame
        end

        -- ── Slider ──
        function Elements:CreateSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 56)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12 })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -24, 0, 24)
            lbl.Position = UDim2.new(0, 14, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Text = text .. "  ·  " .. tostring(default)
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -28, 0, 6)
            barBg.Position = UDim2.new(0, 14, 0, 36)
            barBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            barBg.BackgroundTransparency = 0.88
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 4
            barBg.Parent = frame
            local bbCorner = Instance.new("UICorner")
            bbCorner.CornerRadius = UDim.new(1, 0)
            bbCorner.Parent = barBg

            local defaultScale = (default - min) / (max - min)
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(defaultScale, 0, 1, 0)
            barFill.BackgroundColor3 = Theme.Accent
            barFill.BorderSizePixel = 0
            barFill.ZIndex = 5
            barFill.Parent = barBg
            local bfCorner = Instance.new("UICorner")
            bfCorner.CornerRadius = UDim.new(1, 0)
            bfCorner.Parent = barFill

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(defaultScale, 0, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 6
            knob.Parent = barBg
            local knCorner = Instance.new("UICorner")
            knCorner.CornerRadius = UDim.new(1, 0)
            knCorner.Parent = knob
            local knStroke = Instance.new("UIStroke")
            knStroke.Color = Theme.Accent
            knStroke.Thickness = 1.5
            knStroke.Parent = knob

            local function apply(t)
                lbl.TextColor3 = t.Text
                barFill.BackgroundColor3 = t.Accent
                knStroke.Color = t.Accent
            end
            RegisterTheme(apply)

            local hitArea = Instance.new("TextButton")
            hitArea.Size = UDim2.new(1, 0, 1, 0)
            hitArea.BackgroundTransparency = 1
            hitArea.Text = ""
            hitArea.ZIndex = 7
            hitArea.Parent = barBg

            local dragging = false
            local function update(input)
                local rel = math.clamp(input.Position.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
                local scale = rel / barBg.AbsoluteSize.X
                local value = math.floor(min + (max - min) * scale)
                TweenService:Create(barFill, TweenInfo.new(0.08), { Size = UDim2.new(scale, 0, 1, 0) }):Play()
                TweenService:Create(knob, TweenInfo.new(0.08), { Position = UDim2.new(scale, 0, 0.5, 0) }):Play()
                lbl.Text = text .. "  ·  " .. tostring(value)
                SafeCall(callback, value)
            end

            hitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            return frame
        end

        -- ── Dropdown ──
        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 38)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12 })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(0, 130, 0, 28)
            dropBtn.AnchorPoint = Vector2.new(1, 0.5)
            dropBtn.Position = UDim2.new(1, -10, 0.5, 0)
            dropBtn.Text = selected .. "  ▾"
            dropBtn.TextColor3 = Theme.Text
            dropBtn.Font = Enum.Font.GothamSemibold
            dropBtn.TextSize = 12
            dropBtn.AutoButtonColor = false
            dropBtn.ZIndex = 4
            dropBtn.Parent = frame
            local dbGlass = Glass.Apply(dropBtn, { Preset = "Bubble", Radius = 8, Highlight = false })
            dbGlass.Stroke.Transparency = 0.9

            local function apply(t)
                lbl.TextColor3 = t.Text
                dropBtn.TextColor3 = t.Text
            end
            RegisterTheme(apply)

            dropBtn.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == dropBtn then
                    closeDropdown()
                    return
                end
                closeDropdown()

                local list = Instance.new("Frame")
                list.Name = "DropdownList"
                list.ZIndex = 501
                list.Parent = ScreenGui
                Glass.Apply(list, { Preset = "Panel", Radius = 12 })

                local layout = Instance.new("UIListLayout")
                layout.Parent = list

                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -8, 0, 30)
                    optBtn.Position = UDim2.new(0, 4, 0, 0)
                    optBtn.BackgroundTransparency = 1
                    optBtn.Text = opt
                    optBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.Text
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 13
                    optBtn.AutoButtonColor = false
                    optBtn.ZIndex = 502
                    optBtn.Parent = list
                    local oc = Instance.new("UICorner")
                    oc.CornerRadius = UDim.new(0, 8)
                    oc.Parent = optBtn
                    if opt == selected then
                        optBtn.BackgroundColor3 = Theme.Accent
                        optBtn.BackgroundTransparency = 0.3
                    end

                    optBtn.MouseEnter:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = Theme.Accent,
                            BackgroundTransparency = 0.4,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end)
                    optBtn.MouseLeave:Connect(function()
                        TweenService:Create(optBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = (opt == selected) and Theme.Accent or Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = (opt == selected) and 0.3 or 1,
                            TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.Text
                        }):Play()
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        dropBtn.Text = selected .. "  ▾"
                        SafeCall(callback, selected)
                        closeDropdown()
                    end)
                end

                local absPos = dropBtn.AbsolutePosition
                local absSize = dropBtn.AbsoluteSize
                list.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                list.Size = UDim2.new(0, absSize.X, 0, #options * 30 + 8)

                Overlay.Visible = true
                currentDropdown = { button = dropBtn, list = list }
                local conn
                conn = Overlay.MouseButton1Click:Connect(closeDropdown)
                currentDropdown.conn = conn
            end)
            return frame
        end

        -- ── InfoPanel ──
        function Elements:CreateInfoPanel(info)
            info = info or {}
            local panel = Instance.new("Frame")
            panel.Size = UDim2.new(1, 0, 0, 84)
            panel.ZIndex = 3
            panel.Parent = TabPage
            local g = Glass.Apply(panel, { Preset = "Element", Radius = 14 })

            local avatarWrap = Instance.new("Frame")
            avatarWrap.Size = UDim2.new(0, 60, 0, 60)
            avatarWrap.Position = UDim2.new(0, 14, 0.5, -30)
            avatarWrap.BackgroundTransparency = 1
            avatarWrap.ZIndex = 4
            avatarWrap.Parent = panel
            local avCorner = Instance.new("UICorner")
            avCorner.CornerRadius = UDim.new(1, 0)
            avCorner.Parent = avatarWrap
            local avStroke = Instance.new("UIStroke")
            avStroke.Color = Theme.Accent
            avStroke.Thickness = 1.5
            avStroke.Transparency = 0.3
            avStroke.Parent = avatarWrap

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(1, -4, 1, -4)
            avatar.Position = UDim2.new(0, 2, 0, 2)
            avatar.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
            avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            avatar.ZIndex = 5
            avatar.Parent = avatarWrap
            local avc2 = Instance.new("UICorner")
            avc2.CornerRadius = UDim.new(1, 0)
            avc2.Parent = avatar

            task.spawn(function()
                pcall(function()
                    local userId = Players.LocalPlayer.UserId
                    local url = Players:GetUserThumbnailAsync(userId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    avatar.Image = url
                end)
            end)

            local infoFrame = Instance.new("Frame")
            infoFrame.Size = UDim2.new(1, -90, 1, -16)
            infoFrame.Position = UDim2.new(0, 82, 0, 8)
            infoFrame.BackgroundTransparency = 1
            infoFrame.ZIndex = 4
            infoFrame.Parent = panel
            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 3)
            layout.Parent = infoFrame

            local function makeLine(text, bold, color, size)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 0, size or 18)
                l.BackgroundTransparency = 1
                l.Text = text
                l.TextColor3 = color
                l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
                l.TextSize = size or 13
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.ZIndex = 5
                l.Parent = infoFrame
                return l
            end

            local nameLbl = makeLine(info.PlayerName or Players.LocalPlayer.Name, true, Theme.Text, 16)
            local serverLbl = makeLine(info.ServerInfo or "Server: unknown", false, Theme.SubText, 12)
            local execLbl = makeLine(info.ExecutorInfo or "Executor: unknown", false, Theme.SubText, 12)

            RegisterTheme(function(t)
                panel.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
                nameLbl.TextColor3 = t.Text
                serverLbl.TextColor3 = t.SubText
                execLbl.TextColor3 = t.SubText
                avStroke.Color = t.Accent
            end)
            return panel
        end

        -- ── Image ──
        function Elements:CreateImage(imageId, sizeX, sizeY)
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, sizeX or 100, 0, sizeY or 100)
            img.Image = imageId or ""
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 3
            img.Parent = TabPage
            Glass.Apply(img, { Preset = "Element", Radius = 12 })
            return img
        end

        -- ── ColorPicker ──
        function Elements:CreateColorPicker(text, defaultColor, callback)
            local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 40)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12 })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 60, 0, 28)
            preview.AnchorPoint = Vector2.new(1, 0.5)
            preview.Position = UDim2.new(1, -10, 0.5, 0)
            preview.BackgroundColor3 = currentColor
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.ZIndex = 4
            preview.Parent = frame
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 8)
            pCorner.Parent = preview
            local pStroke = Instance.new("UIStroke")
            pStroke.Color = Color3.fromRGB(255, 255, 255)
            pStroke.Transparency = 0.5
            pStroke.Parent = preview

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                pStroke.Color = t.Accent
            end)

            local pickerPopup = nil
            preview.MouseButton1Click:Connect(function()
                if pickerPopup then pickerPopup:Destroy() end
                pickerPopup = Instance.new("Frame")
                pickerPopup.Size = UDim2.new(0, 236, 0, 232)
                pickerPopup.Position = UDim2.new(0, preview.AbsolutePosition.X - 170,
                    0, preview.AbsolutePosition.Y + 34)
                pickerPopup.ZIndex = 600
                pickerPopup.Parent = ScreenGui
                Glass.Apply(pickerPopup, { Preset = "Panel", Radius = 14 })

                -- 拖动条
                local dragBar = Instance.new("TextButton")
                dragBar.Size = UDim2.new(1, 0, 0, 20)
                dragBar.BackgroundTransparency = 1
                dragBar.Text = "· · ·"
                dragBar.TextColor3 = Theme.SubText
                dragBar.Font = Enum.Font.GothamBold
                dragBar.TextSize = 12
                dragBar.AutoButtonColor = false
                dragBar.ZIndex = 601
                dragBar.Parent = pickerPopup

                -- 拖动
                do
                    local dragging, dragStart, startPos
                    dragBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            dragStart = input.Position
                            startPos = pickerPopup.Position
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                            local delta = input.Position - dragStart
                            pickerPopup.Position = UDim2.new(
                                startPos.X.Scale, startPos.X.Offset + delta.X,
                                startPos.Y.Scale, startPos.Y.Offset + delta.Y
                            )
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                end

                -- SV 区
                local svBox = Instance.new("ImageButton")
                svBox.Size = UDim2.new(0, 180, 0, 180)
                svBox.Position = UDim2.new(0, 8, 0, 28)
                svBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                svBox.Image = ""
                svBox.AutoButtonColor = false
                svBox.ZIndex = 601
                svBox.Parent = pickerPopup
                local svCorner = Instance.new("UICorner")
                svCorner.CornerRadius = UDim.new(0, 8)
                svCorner.Parent = svBox

                -- 白色渐变（水平）
                local gradWhite = Instance.new("UIGradient", svBox)
                gradWhite.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
                gradWhite.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                })
                -- 黑色渐变（垂直，放在子 Frame 上）
                local blackOverlay = Instance.new("Frame")
                blackOverlay.Size = UDim2.new(1, 0, 1, 0)
                blackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                blackOverlay.BorderSizePixel = 0
                blackOverlay.ZIndex = 602
                blackOverlay.Parent = svBox
                local boCorner = Instance.new("UICorner")
                boCorner.CornerRadius = UDim.new(0, 8)
                boCorner.Parent = blackOverlay
                local gradBlack = Instance.new("UIGradient", blackOverlay)
                gradBlack.Rotation = 90
                gradBlack.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })

                -- 色相条
                local hueBar = Instance.new("ImageButton")
                hueBar.Size = UDim2.new(0, 22, 0, 180)
                hueBar.Position = UDim2.new(0, 194, 0, 28)
                hueBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                hueBar.Image = ""
                hueBar.AutoButtonColor = false
                hueBar.ZIndex = 601
                hueBar.Parent = pickerPopup
                local hCorner = Instance.new("UICorner")
                hCorner.CornerRadius = UDim.new(0, 8)
                hCorner.Parent = hueBar
                local hueGrad = Instance.new("UIGradient", hueBar)
                hueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                })
                hueGrad.Rotation = 90

                -- 指示器
                local svInd = Instance.new("Frame")
                svInd.Size = UDim2.new(0, 12, 0, 12)
                svInd.AnchorPoint = Vector2.new(0.5, 0.5)
                svInd.BackgroundTransparency = 1
                svInd.ZIndex = 603
                svInd.Parent = svBox
                local svIndDot = Instance.new("Frame")
                svIndDot.Size = UDim2.new(1, 0, 1, 0)
                svIndDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                svIndDot.BorderSizePixel = 0
                svIndDot.ZIndex = 604
                svIndDot.Parent = svInd
                local sidCorner = Instance.new("UICorner")
                sidCorner.CornerRadius = UDim.new(1, 0)
                sidCorner.Parent = svIndDot
                local sidStroke = Instance.new("UIStroke")
                sidStroke.Color = Color3.fromRGB(0, 0, 0)
                sidStroke.Thickness = 2
                sidStroke.Parent = svIndDot

                local hueInd = Instance.new("Frame")
                hueInd.Size = UDim2.new(1, 4, 0, 5)
                hueInd.AnchorPoint = Vector2.new(0.5, 0.5)
                hueInd.Position = UDim2.new(0.5, 0, 0, 0)
                hueInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueInd.BorderSizePixel = 0
                hueInd.ZIndex = 603
                hueInd.Parent = hueBar
                local hiCorner = Instance.new("UICorner")
                hiCorner.CornerRadius = UDim.new(1, 0)
                hiCorner.Parent = hueInd
                local hiStroke = Instance.new("UIStroke")
                hiStroke.Color = Color3.fromRGB(0, 0, 0)
                hiStroke.Thickness = 1
                hiStroke.Parent = hueInd

                local h, s, v = currentColor:ToHSV()
                svInd.Position = UDim2.new(s, 0, 1 - v, 0)
                hueInd.Position = UDim2.new(0.5, 0, h, 0)

                local svDrag, hueDrag = false, false

                local function commit()
                    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    currentColor = Color3.fromHSV(h, s, v)
                    preview.BackgroundColor3 = currentColor
                    SafeCall(callback, currentColor)
                end

                local function updateSV(input)
                    local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    s = rx
                    v = 1 - ry
                    svInd.Position = UDim2.new(s, 0, 1 - v, 0)
                    commit()
                end
                local function updateHue(input)
                    local ry = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    h = ry
                    hueInd.Position = UDim2.new(0.5, 0, h, 0)
                    commit()
                end

                svBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag = true
                        updateSV(input)
                    end
                end)
                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = true
                        updateHue(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag = false
                        hueDrag = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if svDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSV(input)
                    elseif hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updateHue(input)
                    end
                end)

                -- 完成按钮
                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(1, -16, 0, 24)
                closeBtn.Position = UDim2.new(0, 8, 1, -32)
                closeBtn.Text = "完成"
                closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                closeBtn.Font = Enum.Font.GothamSemibold
                closeBtn.TextSize = 13
                closeBtn.AutoButtonColor = false
                closeBtn.ZIndex = 601
                closeBtn.Parent = pickerPopup
                local cbCorner = Instance.new("UICorner")
                cbCorner.CornerRadius = UDim.new(0, 8)
                cbCorner.Parent = closeBtn
                closeBtn.BackgroundColor3 = Theme.Accent
                closeBtn.MouseButton1Click:Connect(function()
                    pickerPopup:Destroy()
                    pickerPopup = nil
                end)

                local closeConn
                closeConn = Overlay.MouseButton1Click:Connect(function()
                    if pickerPopup then
                        pickerPopup:Destroy()
                        pickerPopup = nil
                        if closeConn then closeConn:Disconnect() end
                    end
                end)
                Overlay.Visible = true
            end)
            return frame
        end

        -- ── Keybind ──
        function Elements:CreateKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 38)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12 })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, -20, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0, 100, 0, 28)
            bindBtn.AnchorPoint = Vector2.new(1, 0.5)
            bindBtn.Position = UDim2.new(1, -10, 0.5, 0)
            bindBtn.Text = currentKey.Name
            bindBtn.TextColor3 = Theme.Text
            bindBtn.Font = Enum.Font.GothamSemibold
            bindBtn.TextSize = 12
            bindBtn.AutoButtonColor = false
            bindBtn.ZIndex = 4
            bindBtn.Parent = frame
            local bbGlass = Glass.Apply(bindBtn, { Preset = "Bubble", Radius = 8, Highlight = false })
            bbGlass.Stroke.Transparency = 0.9

            local themeId = RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                bindBtn.TextColor3 = t.Text
                bbGlass.Stroke.Color = t.Accent
            end)

            local listening = false
            local listenConn
            local listenerKey = "kb_" .. tostring(themeIdCounter)

            local function startListening()
                if listening then return end
                listening = true
                bindBtn.Text = "..."
                bbGlass.Stroke.Color = Theme.Accent
                bbGlass.Stroke.Transparency = 0.3

                listenConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindBtn.Text = currentKey.Name
                        listening = false
                        if listenConn then
                            listenConn:Disconnect()
                            listenConn = nil
                        end
                        bbGlass.Stroke.Color = Color3.fromRGB(255, 255, 255)
                        bbGlass.Stroke.Transparency = 0.9

                        if activeKeybinds[listenerKey] then
                            activeKeybinds[listenerKey]:Disconnect()
                        end
                        activeKeybinds[listenerKey] = UserInputService.InputBegan:Connect(function(inp, gp)
                            if not gp and inp.KeyCode == currentKey then
                                SafeCall(callback, currentKey)
                            end
                        end)
                    end
                end)
            end

            bindBtn.MouseButton1Click:Connect(startListening)

            activeKeybinds[listenerKey] = UserInputService.InputBegan:Connect(function(inp, gp)
                if not gp and inp.KeyCode == currentKey then
                    SafeCall(callback, currentKey)
                end
            end)
            return frame
        end

        -- ── Paragraph ──
        function Elements:CreateParagraph(text, lines)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, (lines or 2) * 22 + 16)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Preset = "Element", Radius = 12, Highlight = false })
            g.Stroke.Transparency = 0.94

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -28, 1, -16)
            lbl.Position = UDim2.new(0, 14, 0, 8)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.SubText
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextYAlignment = Enum.TextYAlignment.Top
            lbl.TextWrapped = true
            lbl.ZIndex = 4
            lbl.Parent = frame

            RegisterTheme(function(t)
                lbl.TextColor3 = t.SubText
            end)
            return frame
        end

        return Elements
    end

    -- ═══════════════════════════════════════════════════════════
    -- 销毁
    -- ═══════════════════════════════════════════════════════════
    function Window:Destroy()
        for _, conn in pairs(activeKeybinds) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        activeKeybinds = {}
        themeRegistry = {}
        closeDropdown()
        if Island then Island.Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
    end

    -- 初始化主题
    RunTheme()

    return Window
end

return Library
