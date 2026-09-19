--[[
    ═══════════════════════════════════════════════════════════════════════════
    LS Team UI Library · v3.0 "Liquid Glass"
    · 灵动岛 (Dynamic Island)，位置由 IgnoreGuiInset 显式处理
    · 真·液态玻璃：BlurEffect 背景虚化 + 三级层次 + 顶部高光
    · 新增：Textbox / Section / Divider
    · 修复：灵动岛展开裁剪、通知队列、主题回调泄漏、色板双渐变
    ═══════════════════════════════════════════════════════════════════════════
]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")
local Lighting         = game:GetService("Lighting")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")

local Library = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- §1  目标 GUI 层
-- ═══════════════════════════════════════════════════════════════════════════
local targetGui
do
    local ok, res = pcall(function() return gethui and gethui() end)
    targetGui = (ok and res) or CoreGui
end
if not pcall(function() return targetGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §2  通用工具
-- ═══════════════════════════════════════════════════════════════════════════
local function MeasureText(text, size, font, maxW)
    return TextService:GetTextSize(text, size, font, Vector2.new(maxW or 2000, 2000))
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[LS_UI] " .. tostring(err)) end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §3  共享背景模糊（多个窗口共享一个 BlurEffect）
-- ═══════════════════════════════════════════════════════════════════════════
local BlurController = {}
do
    local state = getgenv().LS_UI_BlurState or { count = 0, blur = nil }
    getgenv().LS_UI_BlurState = state

    function BlurController.Acquire()
        if not state.blur or not state.blur.Parent then
            local b = Instance.new("BlurEffect")
            b.Name = "LS_UI_Blur"
            b.Size = 0
            b.Parent = Lighting
            state.blur = b
        end
        state.count = state.count + 1
        TweenService:Create(state.blur, TweenInfo.new(0.4), { Size = 14 }):Play()
    end

    function BlurController.Release()
        state.count = math.max(0, state.count - 1)
        if state.count == 0 and state.blur and state.blur.Parent then
            local b = state.blur
            local t = TweenService:Create(b, TweenInfo.new(0.35), { Size = 0 })
            t:Play()
            t.Completed:Connect(function()
                if state.count == 0 and b.Parent then b:Destroy() end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §4  液态玻璃系统
--     三层结构：Tint（玻璃底色）/ Edge（边缘反光）/ Highlight（顶部高光）
-- ═══════════════════════════════════════════════════════════════════════════
local Glass = {}

-- 视觉层次按"轻→重"排列：元素最轻、窗口最重
Glass.Levels = {
    Window  = { Tint = Color3.fromRGB(22, 22, 30), TintT = 0.28, EdgeT = 0.72, HiT = 0.82, Radius = 24, Stroke = 1.2 },
    Panel   = { Tint = Color3.fromRGB(36, 36, 46), TintT = 0.42, EdgeT = 0.80, HiT = 0.88, Radius = 18, Stroke = 1.0 },
    Element = { Tint = Color3.fromRGB(58, 58, 72), TintT = 0.55, EdgeT = 0.88, HiT = 0.94, Radius = 12, Stroke = 1.0 },
    Island  = { Tint = Color3.fromRGB(10, 10, 14), TintT = 0.06, EdgeT = 0.70, HiT = 0.70, Radius = 19, Stroke = 1.2 },
    Bubble  = { Tint = Color3.fromRGB(78, 78, 96), TintT = 0.50, EdgeT = 0.86, HiT = 0.92, Radius = 10, Stroke = 1.0 },
}

-- 给任意 GuiObject 套玻璃
-- opts: { Level = "Window"|"Panel"|"Element"|"Island"|"Bubble",
--         Radius, Tint, TintT, EdgeColor, EdgeT, Highlight = bool }
function Glass.Apply(parent, opts)
    opts = opts or {}
    local lv = Glass.Levels[opts.Level or "Element"]

    local tint     = opts.Tint     or lv.Tint
    local tintT    = opts.TintT    or lv.TintT
    local edgeT    = opts.EdgeT    or lv.EdgeT
    local radius   = opts.Radius   or lv.Radius
    local strokePx = opts.Stroke   or lv.Stroke
    local edgeCol  = opts.EdgeColor or Color3.fromRGB(255, 255, 255)
    local hlOn     = opts.Highlight ~= false

    parent.BackgroundColor3 = tint
    parent.BackgroundTransparency = tintT
    parent.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent

    local edge = Instance.new("UIStroke")
    edge.Color = edgeCol
    edge.Transparency = edgeT
    edge.Thickness = strokePx
    edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    edge.Parent = parent

    local hi
    if hlOn then
        hi = Instance.new("UIGradient")
        hi.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(140, 140, 160)),
        })
        -- 顶部高光比底部亮
        hi.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,    lv.HiT),
            NumberSequenceKeypoint.new(0.5,  lv.HiT + 0.08),
            NumberSequenceKeypoint.new(1,    1),
        })
        hi.Rotation = 90
        hi.Parent = parent
    end

    return { Corner = corner, Edge = edge, Highlight = hi }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §5  主题
-- ═══════════════════════════════════════════════════════════════════════════
Library.Themes = {
    Default = {
        Accent = Color3.fromRGB(10, 132, 255), AccentHi = Color3.fromRGB(90, 175, 255),
        Text = Color3.fromRGB(240, 240, 245), SubText = Color3.fromRGB(160, 160, 175),
        ToggleOff = Color3.fromRGB(80, 80, 95), Divider = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(80, 220, 130), Warning = Color3.fromRGB(255, 190, 60),
        Danger = Color3.fromRGB(255, 90, 95),
    },
    Ocean = {
        Accent = Color3.fromRGB(0, 190, 200), AccentHi = Color3.fromRGB(60, 225, 235),
        Text = Color3.fromRGB(235, 250, 255), SubText = Color3.fromRGB(150, 195, 205),
        ToggleOff = Color3.fromRGB(60, 90, 100), Divider = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(80, 220, 160), Warning = Color3.fromRGB(255, 200, 80),
        Danger = Color3.fromRGB(255, 100, 100),
    },
    Sunset = {
        Accent = Color3.fromRGB(255, 95, 110), AccentHi = Color3.fromRGB(255, 150, 160),
        Text = Color3.fromRGB(255, 240, 240), SubText = Color3.fromRGB(220, 175, 180),
        ToggleOff = Color3.fromRGB(110, 70, 80), Divider = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(120, 220, 140), Warning = Color3.fromRGB(255, 190, 90),
        Danger = Color3.fromRGB(255, 90, 95),
    },
    Autumn = {
        Accent = Color3.fromRGB(255, 140, 40), AccentHi = Color3.fromRGB(255, 180, 95),
        Text = Color3.fromRGB(255, 245, 235), SubText = Color3.fromRGB(215, 185, 160),
        ToggleOff = Color3.fromRGB(100, 75, 55), Divider = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(150, 220, 120), Warning = Color3.fromRGB(255, 200, 80),
        Danger = Color3.fromRGB(255, 100, 90),
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- §6  灵动岛
-- ═══════════════════════════════════════════════════════════════════════════
local function CreateDynamicIsland(parent, theme, callbacks)
    callbacks = callbacks or {}

    local COMPACT_H  = 40
    local EXPANDED_H = 100
    local COMPACT_W_MIN = 132
    local EXPANDED_W_MIN = 300

    local isExpanded = false
    local isAnimating = false

    -- ─── 位置：屏幕顶部安全区居中 ───
    local function initialPosition()
        return UDim2.new(0.5, 0, 0, 12)
    end

    -- ─── 主胶囊 ───
    local Island = Instance.new("TextButton")
    Island.Name = "DynamicIsland"
    Island.AnchorPoint = Vector2.new(0.5, 0)
    Island.Position = initialPosition()
    Island.Size = UDim2.new(0, COMPACT_W_MIN, 0, COMPACT_H)
    Island.Text = ""
    Island.AutoButtonColor = false
    Island.ClipsDescendants = true
    Island.ZIndex = 220
    Island.Parent = parent

    local islandGlass = Glass.Apply(Island, {
        Level = "Island", Radius = COMPACT_H / 2,
    })

    -- ─── 收起态内容 ───
    local CompactView = Instance.new("Frame")
    CompactView.Name = "CompactView"
    CompactView.Size = UDim2.new(1, 0, 1, 0)
    CompactView.BackgroundTransparency = 1
    CompactView.Visible = true
    CompactView.ZIndex = 2
    CompactView.Parent = Island

    local compactDot = Instance.new("Frame")
    compactDot.Size = UDim2.new(0, 8, 0, 8)
    compactDot.Position = UDim2.new(0, 16, 0.5, -4)
    compactDot.BackgroundColor3 = theme.Success
    compactDot.BorderSizePixel = 0
    compactDot.ZIndex = 3
    compactDot.Parent = CompactView
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = compactDot
    end
    -- 呼吸
    task.spawn(function()
        while compactDot.Parent do
            TweenService:Create(compactDot, TweenInfo.new(1.2), { BackgroundTransparency = 0.55 }):Play()
            task.wait(1.2)
            TweenService:Create(compactDot, TweenInfo.new(1.2), { BackgroundTransparency = 0 }):Play()
            task.wait(1.2)
        end
    end)

    local compactTitle = Instance.new("TextLabel")
    compactTitle.Size = UDim2.new(1, -50, 1, 0)
    compactTitle.Position = UDim2.new(0, 34, 0, 0)
    compactTitle.BackgroundTransparency = 1
    compactTitle.Text = "LS UI"
    compactTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    compactTitle.Font = Enum.Font.GothamBold
    compactTitle.TextSize = 13
    compactTitle.TextXAlignment = Enum.TextXAlignment.Left
    compactTitle.ZIndex = 3
    compactTitle.Parent = CompactView

    -- ─── 展开态内容 ───
    local ExpandedView = Instance.new("Frame")
    ExpandedView.Name = "ExpandedView"
    ExpandedView.Size = UDim2.new(1, 0, 1, 0)
    ExpandedView.BackgroundTransparency = 1
    ExpandedView.Visible = false
    ExpandedView.ZIndex = 2
    ExpandedView.Parent = Island

    -- 头部：状态点 + 标题
    local expDot = Instance.new("Frame")
    expDot.Size = UDim2.new(0, 10, 0, 10)
    expDot.Position = UDim2.new(0, 20, 0, 22)
    expDot.BackgroundColor3 = theme.Success
    expDot.BorderSizePixel = 0
    expDot.ZIndex = 3
    expDot.Parent = ExpandedView
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = expDot
    end

    local expTitle = Instance.new("TextLabel")
    expTitle.Size = UDim2.new(1, -50, 0, 22)
    expTitle.Position = UDim2.new(0, 42, 0, 16)
    expTitle.BackgroundTransparency = 1
    expTitle.Text = "LS UI 调试器"
    expTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    expTitle.Font = Enum.Font.GothamBold
    expTitle.TextSize = 15
    expTitle.TextXAlignment = Enum.TextXAlignment.Left
    expTitle.ZIndex = 3
    expTitle.Parent = ExpandedView

    local expSub = Instance.new("TextLabel")
    expSub.Size = UDim2.new(1, -50, 0, 18)
    expSub.Position = UDim2.new(0, 42, 0, 42)
    expSub.BackgroundTransparency = 1
    expSub.Text = "运行中 · 0 个功能"
    expSub.TextColor3 = Color3.fromRGB(170, 170, 185)
    expSub.Font = Enum.Font.Gotham
    expSub.TextSize = 12
    expSub.TextXAlignment = Enum.TextXAlignment.Left
    expSub.ZIndex = 3
    expSub.Parent = ExpandedView

    -- 按钮行
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -32, 0, 22)
    btnRow.Position = UDim2.new(0, 16, 1, -30)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 3
    btnRow.Parent = ExpandedView
    do
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 6)
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Parent = btnRow
    end

    local buttonDefs = {}
    local function addButton(label, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 0, 22)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.86
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 4
        btn.Parent = btnRow
        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = btn
            local p = Instance.new("UIPadding")
            p.PaddingLeft = UDim.new(0, 12)
            p.PaddingRight = UDim.new(0, 12)
            p.Parent = btn
        end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 11
        lbl.ZIndex = 5
        lbl.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.7 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.86 }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            if callbacks.OnAction then SafeCall(callbacks.OnAction, key) end
        end)

        table.insert(buttonDefs, { Text = label, Instance = btn })
        return btn
    end

    addButton("设置", "settings")
    addButton("通知", "notify")
    addButton("收起", "collapse")

    -- ─── 自适应宽度计算 ───
    local function compactWidth()
        local tw = MeasureText(compactTitle.Text, 13, Enum.Font.GothamBold).X
        return math.max(COMPACT_W_MIN, 16 + 8 + 10 + tw + 20)
    end

    local function expandedWidth()
        local wTitle = MeasureText(expTitle.Text, 15, Enum.Font.GothamBold).X + 42 + 24
        local wSub   = MeasureText(expSub.Text, 12, Enum.Font.Gotham).X + 42 + 24
        local wBtns  = 32
        for _, b in ipairs(buttonDefs) do
            wBtns = wBtns + MeasureText(b.Text, 11, Enum.Font.GothamSemibold).X + 24 + 6
        end
        return math.max(EXPANDED_W_MIN, wTitle, wSub, wBtns)
    end

    -- ─── 展开/收起 ───
    local function setExpanded(next)
        if isAnimating or next == isExpanded then return end
        isAnimating = true
        isExpanded = next

        local targetW = next and expandedWidth() or compactWidth()
        local targetH = next and EXPANDED_H or COMPACT_H
        local targetR = next and 24 or (COMPACT_H / 2)

        local info = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        TweenService:Create(Island, info, {
            Size = UDim2.new(0, targetW, 0, targetH),
        }):Play()
        TweenService:Create(islandGlass.Corner, info, {
            CornerRadius = UDim.new(0, targetR),
        }):Play()

        if next then
            ExpandedView.Visible = true
            CompactView.Visible = false
            -- 立即显示展开视图，然后淡入
            for _, c in ipairs(ExpandedView:GetDescendants()) do
                if c:IsA("TextLabel") then c.TextTransparency = 1
                elseif c:IsA("Frame") then c.BackgroundTransparency = 1 end
            end
            ExpandedView.BackgroundTransparency = 1

            task.defer(function()
                for _, c in ipairs(ExpandedView:GetDescendants()) do
                    if c:IsA("TextLabel") then
                        TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0.12), { TextTransparency = 0 }):Play()
                    end
                end
                -- 恢复状态点颜色
                TweenService:Create(expDot, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
                -- 恢复按钮
                for _, b in ipairs(buttonDefs) do
                    TweenService:Create(b.Instance, TweenInfo.new(0.3), { BackgroundTransparency = 0.86 }):Play()
                    local lbl = b.Instance:FindFirstChildOfClass("TextLabel")
                    if lbl then TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play() end
                end
            end)
        else
            CompactView.Visible = true
            -- 淡出展开视图
            for _, c in ipairs(ExpandedView:GetDescendants()) do
                if c:IsA("TextLabel") then
                    TweenService:Create(c, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
                end
            end
            task.delay(0.2, function()
                if not isExpanded then ExpandedView.Visible = false end
            end)
        end

        task.delay(0.45, function()
            isAnimating = false
            if next then
                if callbacks.OnExpand then SafeCall(callbacks.OnExpand) end
            else
                if callbacks.OnCollapse then SafeCall(callbacks.OnCollapse) end
            end
        end)
    end

    -- ─── 拖动 + 点击 ───
    local dragging, dragStart, startPos, moved
    Island.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = Island.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            if moved then
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
            if dragging and not moved then
                setExpanded(not isExpanded)
            end
            dragging = false
            moved = false
        end
    end)

    -- ─── API ───
    local API = { Frame = Island }

    function API.SetExpanded(v) setExpanded(v) end
    function API.Toggle() setExpanded(not isExpanded) end

    function API.SetStatus(text)
        compactTitle.Text = text
        expSub.Text = text
        if not isExpanded then
            TweenService:Create(Island, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, compactWidth(), 0, COMPACT_H)
            }):Play()
        end
    end

    function API.SetTitle(text)
        expTitle.Text = text
        if isExpanded then
            TweenService:Create(Island, TweenInfo.new(0.3), {
                Size = UDim2.new(0, expandedWidth(), 0, EXPANDED_H)
            }):Play()
        end
    end

    function API.SetDotColor(color)
        compactDot.BackgroundColor3 = color
        expDot.BackgroundColor3 = color
    end

    function API.Destroy()
        if Island.Parent then Island:Destroy() end
    end

    return API
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §7  CreateWindow
-- ═══════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(options)
    options = options or {}
    local WindowTitle = options.Title or "LS UI"
    local initialTheme = options.Theme or "Default"

    -- ─── 主题 ───
    local Theme = {}
    local function loadTheme(name)
        local t = Library.Themes[name] or Library.Themes.Default
        for k, _ in pairs(Library.Themes.Default) do Theme[k] = t[k] end
    end
    loadTheme(initialTheme)

    -- ─── ScreenGui ───
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LS_UI_" .. tostring(math.random(100000, 999999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = false   -- 使用安全区
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = targetGui

    -- 主题回调管理
    local themeRegistry = {}
    local themeCounter = 0
    local function RegisterTheme(fn)
        themeCounter = themeCounter + 1
        local id = themeCounter
        themeRegistry[id] = fn
        pcall(fn, Theme)
        return id
    end
    local function UnregisterTheme(id) themeRegistry[id] = nil end
    local function RunTheme()
        for _, fn in pairs(themeRegistry) do pcall(fn, Theme) end
    end

    -- ─── 遮罩 ───
    local Overlay = Instance.new("TextButton")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.Text = ""
    Overlay.Visible = false
    Overlay.Active = true
    Overlay.ZIndex = 500
    Overlay.Parent = ScreenGui

    -- ─── 通知容器 ───
    local NotifContainer = Instance.new("Frame")
    NotifContainer.AnchorPoint = Vector2.new(1, 0)
    NotifContainer.Position = UDim2.new(1, -14, 0, 62)
    NotifContainer.Size = UDim2.new(0, 270, 1, -100)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.ClipsDescendants = false
    NotifContainer.ZIndex = 400
    NotifContainer.Parent = ScreenGui
    do
        local l = Instance.new("UIListLayout")
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, 8)
        l.Parent = NotifContainer
    end
    local notifOrder = 0

    -- ─── 主窗（前置声明，灵动岛回调要用） ───
    local MainFrame, MainScale, Island

    local function showMain()
        MainFrame.Visible = true
        TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()
        BlurController.Acquire()
    end

    local function hideMain()
        BlurController.Release()
        TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Scale = 0
        }):Play()
        task.delay(0.3, function()
            if MainScale.Scale < 0.05 then MainFrame.Visible = false end
        end)
    end

    -- ─── 灵动岛 ───
    Island = CreateDynamicIsland(ScreenGui, Theme, {
        OnExpand = function() end,
        OnCollapse = function() end,
        OnAction = function(key)
            if key == "settings" then
                showMain()
                Island.SetExpanded(false)
            elseif key == "notify" then
                -- 由 Window 对象暴露的 Notify，占位
                if options.OnIslandNotify then
                    SafeCall(options.OnIslandNotify)
                end
            elseif key == "collapse" then
                Island.SetExpanded(false)
            end
        end,
    })

    -- ─── 主窗 ───
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
    MainFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.ZIndex = 100
    MainFrame.Parent = ScreenGui

    local mainGlass = Glass.Apply(MainFrame, { Level = "Window", Radius = 24 })

    MainScale = Instance.new("UIScale")
    MainScale.Scale = 0
    MainScale.Parent = MainFrame

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(700, 460)
    sizeConstraint.MinSize = Vector2.new(340, 300)
    sizeConstraint.Parent = MainFrame

    -- ─── 顶部栏 ───
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 2
    TopBar.Parent = MainFrame

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Size = UDim2.new(1, -120, 1, 0)
    TopTitle.Position = UDim2.new(0, 22, 0, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Text = WindowTitle
    TopTitle.TextColor3 = Theme.Text
    TopTitle.Font = Enum.Font.GothamBold
    TopTitle.TextSize = 16
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.ZIndex = 3
    TopTitle.Parent = TopBar

    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -18, 0.5, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = TopBar
    local closeGlass = Glass.Apply(closeBtn, {
        Level = "Bubble", Radius = 14, Highlight = false, EdgeT = 0.95,
    })
    closeBtn.BackgroundTransparency = 0.6

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Theme.Danger,
            BackgroundTransparency = 0.2,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.6,
            TextColor3 = Theme.SubText
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(hideMain)

    -- 顶部分隔线
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -32, 0, 1)
    topDivider.Position = UDim2.new(0, 16, 1, -1)
    topDivider.BackgroundColor3 = Theme.Divider
    topDivider.BackgroundTransparency = 0.86
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = 3
    topDivider.Parent = TopBar

    RegisterTheme(function(t)
        TopTitle.TextColor3 = t.Text
        topDivider.BackgroundColor3 = t.Divider
        closeBtn.TextColor3 = t.SubText
    end)

    -- 拖动主窗
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

    -- ─── 侧边栏 ───
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0.30, 0, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ZIndex = 2
    Sidebar.Parent = MainFrame

    local sidebarGlass = Instance.new("Frame")
    sidebarGlass.Name = "SidebarGlass"
    sidebarGlass.Size = UDim2.new(1, -16, 1, -16)
    sidebarGlass.Position = UDim2.new(0, 8, 0, 8)
    sidebarGlass.ZIndex = 2
    sidebarGlass.Parent = Sidebar
    Glass.Apply(sidebarGlass, { Level = "Panel", Radius = 18 })

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 6)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.Parent = sidebarGlass
    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 10)
    sidebarPad.PaddingBottom = UDim.new(0, 10)
    sidebarPad.Parent = sidebarGlass

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.ScrollingEnabled = true
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ZIndex = 3
    TabContainer.Parent = sidebarGlass
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = TabContainer
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- ─── 内容区 ───
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(0.70, 0, 1, -48)
    ContentContainer.Position = UDim2.new(0.30, 0, 0, 48)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ZIndex = 2
    ContentContainer.Parent = MainFrame

    -- ═══════════════════════════════════════════════════════════════════
    -- 通知（队列 · 玻璃化）
    -- ═══════════════════════════════════════════════════════════════════
    local function pushNotification(title, message, duration, opts)
        title = title or "通知"
        message = message or ""
        duration = duration or 4
        opts = opts or {}
        local kind = opts.Type or "info"

        notifOrder = notifOrder + 1

        local notif = Instance.new("Frame")
        notif.Name = "Notif"
        notif.Size = UDim2.new(1, 0, 0, 70)
        notif.ZIndex = 401
        notif.LayoutOrder = notifOrder
        notif.Parent = NotifContainer
        local g = Glass.Apply(notif, { Level = "Panel", Radius = 14 })

        -- 类型色条
        local barColor = Theme.Accent
        if kind == "success" then barColor = Theme.Success
        elseif kind == "warning" then barColor = Theme.Warning
        elseif kind == "error" then barColor = Theme.Danger end

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -16)
        bar.Position = UDim2.new(0, 8, 0, 8)
        bar.BackgroundColor3 = barColor
        bar.BorderSizePixel = 0
        bar.ZIndex = 3
        bar.Parent = notif
        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = bar
        end

        -- 图片（可选）
        local imgSize = 40
        local padX = 16
        local hasImage = opts.Image and true or false
        local textX = hasImage and (padX + imgSize + 10) or (padX + 8)

        if hasImage then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, imgSize, 0, imgSize)
            img.Position = UDim2.new(0, padX, 0, 14)
            img.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
            img.BackgroundTransparency = 0.4
            img.Image = opts.Image
            img.ScaleType = Enum.ScaleType.Crop
            img.ZIndex = 3
            img.Parent = notif
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = img
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
        msgLbl.Position = UDim2.new(0, textX, 0, 36)
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
        local maxW = 270 - textX - 16
        local textH = MeasureText(message, 12, Enum.Font.Gotham, maxW).Y
        local minH = hasImage and (imgSize + 26) or 66
        local totalH = math.max(minH, 36 + textH + 18)
        msgLbl.Size = UDim2.new(1, -textX - 16, 0, textH)
        notif.Size = UDim2.new(1, 0, 0, totalH)

        -- 入场
        local sc = Instance.new("UIScale")
        sc.Scale = 0.85
        sc.Parent = notif
        notif.Position = UDim2.new(1, 40, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()

        -- 出场
        task.delay(duration, function()
            if not notif.Parent then return end
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, 0)
            }):Play()
            TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0.85 }):Play()
            task.wait(0.32)
            if notif.Parent then notif:Destroy() end
        end)

        return notif
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- Window 对象
    -- ═══════════════════════════════════════════════════════════════════
    local Window = {}
    local Tabs = {}
    local firstTab = true
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
        RunTheme()
    end

    function Window:Notify(title, message, duration, imageId)
        local opts = {}
        if type(imageId) == "string" then opts.Image = imageId end
        if type(imageId) == "table" then
            opts.Type = imageId.Type
            opts.Image = imageId.Image
        end
        return pushNotification(title, message, duration, opts)
    end

    -- 便捷方法
    function Window:Toast(message, duration)
        return pushNotification("提示", message, duration or 2.5, { Type = "info" })
    end
    function Window:Success(title, message, duration)
        return pushNotification(title, message, duration or 3, { Type = "success" })
    end
    function Window:Warning(title, message, duration)
        return pushNotification(title, message, duration or 3, { Type = "warning" })
    end
    function Window:Error(title, message, duration)
        return pushNotification(title, message, duration or 4, { Type = "error" })
    end

    -- 灵动岛接口
    function Window:SetIslandStatus(text) Island.SetStatus(text) end
    function Window:SetIslandTitle(text) Island.SetTitle(text) end
    function Window:SetIslandDot(color) Island.SetDotColor(color) end
    function Window:ShowMain() showMain() end
    function Window:HideMain() hideMain() end

    -- 让灵动岛的通知按钮真的弹通知
    options.OnIslandNotify = function()
        Window:Toast("来自灵动岛", 2.5)
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- 标签页
    -- ═══════════════════════════════════════════════════════════════════
    function Window:CreateTab(TabName, iconId, iconOptions)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(1, -16, 0, 36)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.ZIndex = 4
        TabButton.Parent = TabContainer
        local tbGlass = Glass.Apply(TabButton, {
            Level = "Bubble", Radius = 11, Highlight = false, EdgeT = 0.97,
        })
        TabButton.BackgroundTransparency = 1

        local tbScale = Instance.new("UIScale")
        tbScale.Scale = 1
        tbScale.Parent = TabButton

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -16, 1, 0)
        holder.Position = UDim2.new(0, 8, 0, 0)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 5
        holder.Parent = TabButton
        do
            local l = Instance.new("UIListLayout")
            l.FillDirection = Enum.FillDirection.Horizontal
            l.VerticalAlignment = Enum.VerticalAlignment.Center
            l.Padding = UDim.new(0, 8)
            l.Parent = holder
        end

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
            icon.Parent = holder
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
        tabText.Parent = holder

        local isSelected = false
        local themeId
        local function apply(t)
            if isSelected then
                tabText.TextColor3 = Color3.fromRGB(255, 255, 255)
                tbGlass.Edge.Color = t.AccentHi
                tbGlass.Edge.Transparency = 0.3
                TabButton.BackgroundColor3 = t.Accent
                TabButton.BackgroundTransparency = 0.15
            else
                tabText.TextColor3 = t.Text
                tbGlass.Edge.Color = Color3.fromRGB(255, 255, 255)
                tbGlass.Edge.Transparency = 0.97
                TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TabButton.BackgroundTransparency = 1
            end
        end
        themeId = RegisterTheme(apply)

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

        local function setSelected(v)
            isSelected = v
            apply(Theme)
        end

        table.insert(Tabs, { Button = TabButton, Page = TabPage, setSelected = setSelected })

        if firstTab then
            firstTab = false
            setSelected(true)
        end

        TabButton.MouseEnter:Connect(function()
            if not isSelected then
                TweenService:Create(TabButton, TweenInfo.new(0.18), { BackgroundTransparency = 0.88 }):Play()
            end
            TweenService:Create(tbScale, TweenInfo.new(0.18), { Scale = 1.02 }):Play()
        end)
        TabButton.MouseLeave:Connect(function()
            if not isSelected then
                TweenService:Create(TabButton, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
            end
            TweenService:Create(tbScale, TweenInfo.new(0.18), { Scale = 1 }):Play()
        end)
        TabButton.MouseButton1Click:Connect(function()
            for _, d in ipairs(Tabs) do
                local active = (d.Button == TabButton)
                d.Page.Visible = active
                d.setSelected(active)
            end
        end)

        -- ═══════════════════════════════════════════════════════════
        -- 控件工厂
        -- ═══════════════════════════════════════════════════════════
        local Elements = {}

        -- ▸ Label
        function Elements:CreateLabel(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 32)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, Highlight = false, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -28, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.SubText
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            RegisterTheme(function(t) lbl.TextColor3 = t.SubText end)
            return frame
        end

        -- ▸ Section（分组标题）
        function Elements:CreateSection(title)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 28)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 3
            frame.Parent = TabPage

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = string.upper(title)
            lbl.TextColor3 = Theme.SubText
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            RegisterTheme(function(t) lbl.TextColor3 = t.SubText end)
            return frame
        end

        -- ▸ Divider（分隔线）
        function Elements:CreateDivider()
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 8)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 3
            frame.Parent = TabPage

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, -32, 0, 1)
            line.Position = UDim2.new(0, 16, 0.5, 0)
            line.BackgroundColor3 = Theme.Divider
            line.BackgroundTransparency = 0.82
            line.BorderSizePixel = 0
            line.ZIndex = 4
            line.Parent = frame

            RegisterTheme(function(t)
                line.BackgroundColor3 = t.Divider
            end)
            return frame
        end

        -- ▸ Button
        function Elements:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 40)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 3
            btn.Parent = TabPage
            local g = Glass.Apply(btn, { Level = "Element", Radius = 12 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -50, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.GothamSemibold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = btn

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 24, 1, 0)
            arrow.Position = UDim2.new(1, -32, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "›"
            arrow.TextColor3 = Theme.SubText
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 20
            arrow.ZIndex = 4
            arrow.Parent = btn

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                arrow.TextColor3 = t.SubText
                btn.BackgroundColor3 = Color3.fromRGB(58, 58, 72)
            end)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.3
                }):Play()
                TweenService:Create(g.Edge, TweenInfo.new(0.18), {
                    Color = Theme.AccentHi, Transparency = 0.3
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Color3.fromRGB(58, 58, 72), BackgroundTransparency = 0.55
                }):Play()
                TweenService:Create(g.Edge, TweenInfo.new(0.18), {
                    Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Theme.Text
                }):Play()
            end)
            btn.MouseButton1Click:Connect(function() SafeCall(callback) end)
            return btn
        end

        -- ▸ Toggle
        function Elements:CreateToggle(text, default, callback)
            local toggled = default or false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -90, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(0, 46, 0, 24)
            track.AnchorPoint = Vector2.new(1, 0.5)
            track.Position = UDim2.new(1, -16, 0.5, 0)
            track.Text = ""
            track.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
            track.BackgroundTransparency = 0
            track.AutoButtonColor = false
            track.ZIndex = 4
            track.Parent = frame
            local tc = Instance.new("UICorner")
            tc.CornerRadius = UDim.new(1, 0)
            tc.Parent = track

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 5
            knob.Parent = track
            local kc = Instance.new("UICorner")
            kc.CornerRadius = UDim.new(1, 0)
            kc.Parent = knob

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                track.BackgroundColor3 = toggled and t.Accent or t.ToggleOff
            end)

            local function fire()
                toggled = not toggled
                local goal = toggled and Theme.Accent or Theme.ToggleOff
                local pos = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
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

        -- ▸ Slider
        function Elements:CreateSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 60)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -28, 0, 22)
            lbl.Position = UDim2.new(0, 16, 0, 6)
            lbl.BackgroundTransparency = 1
            lbl.Text = text .. "   " .. tostring(default)
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -32, 0, 6)
            barBg.Position = UDim2.new(0, 16, 0, 40)
            barBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            barBg.BackgroundTransparency = 0.86
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 4
            barBg.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = barBg
            end

            local defaultScale = (default - min) / (max - min)
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(defaultScale, 0, 1, 0)
            barFill.BackgroundColor3 = Theme.Accent
            barFill.BorderSizePixel = 0
            barFill.ZIndex = 5
            barFill.Parent = barBg
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = barFill
            end

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(defaultScale, 0, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 6
            knob.Parent = barBg
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = knob
                local s = Instance.new("UIStroke")
                s.Color = Theme.Accent
                s.Thickness = 2
                s.Parent = knob
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                barFill.BackgroundColor3 = t.Accent
                local s = knob:FindFirstChildOfClass("UIStroke")
                if s then s.Color = t.Accent end
            end)

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.ZIndex = 7
            hit.Parent = barBg

            local dragging = false
            local function update(input)
                local rel = math.clamp(input.Position.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
                local sc = rel / barBg.AbsoluteSize.X
                local value = math.floor(min + (max - min) * sc)
                TweenService:Create(barFill, TweenInfo.new(0.08), { Size = UDim2.new(sc, 0, 1, 0) }):Play()
                TweenService:Create(knob, TweenInfo.new(0.08), { Position = UDim2.new(sc, 0, 0.5, 0) }):Play()
                lbl.Text = text .. "   " .. tostring(value)
                SafeCall(callback, value)
            end

            hit.InputBegan:Connect(function(input)
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

        -- ▸ Dropdown
        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(0, 130, 0, 30)
            dropBtn.AnchorPoint = Vector2.new(1, 0.5)
            dropBtn.Position = UDim2.new(1, -12, 0.5, 0)
            dropBtn.Text = selected .. "  ▾"
            dropBtn.TextColor3 = Theme.Text
            dropBtn.Font = Enum.Font.GothamSemibold
            dropBtn.TextSize = 12
            dropBtn.AutoButtonColor = false
            dropBtn.ZIndex = 4
            dropBtn.Parent = frame
            Glass.Apply(dropBtn, { Level = "Bubble", Radius = 8, Highlight = false, EdgeT = 0.9 })

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                dropBtn.TextColor3 = t.Text
            end)

            dropBtn.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == dropBtn then
                    closeDropdown(); return
                end
                closeDropdown()

                local list = Instance.new("Frame")
                list.Name = "DropdownList"
                list.ZIndex = 501
                list.Parent = ScreenGui
                Glass.Apply(list, { Level = "Panel", Radius = 12 })

                local l = Instance.new("UIListLayout")
                l.Parent = list

                for _, opt in ipairs(options) do
                    local oBtn = Instance.new("TextButton")
                    oBtn.Size = UDim2.new(1, -8, 0, 32)
                    oBtn.Position = UDim2.new(0, 4, 0, 0)
                    oBtn.BackgroundTransparency = 1
                    oBtn.Text = opt
                    oBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.Text
                    oBtn.Font = Enum.Font.Gotham
                    oBtn.TextSize = 13
                    oBtn.AutoButtonColor = false
                    oBtn.ZIndex = 502
                    oBtn.Parent = list
                    do
                        local c = Instance.new("UICorner")
                        c.CornerRadius = UDim.new(0, 8)
                        c.Parent = oBtn
                    end
                    if opt == selected then
                        oBtn.BackgroundColor3 = Theme.Accent
                        oBtn.BackgroundTransparency = 0.3
                    end

                    oBtn.MouseEnter:Connect(function()
                        TweenService:Create(oBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = Theme.Accent,
                            BackgroundTransparency = 0.4,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end)
                    oBtn.MouseLeave:Connect(function()
                        TweenService:Create(oBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = (opt == selected) and Theme.Accent or Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = (opt == selected) and 0.3 or 1,
                            TextColor3 = (opt == selected) and Color3.fromRGB(255, 255, 255) or Theme.Text
                        }):Play()
                    end)
                    oBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        dropBtn.Text = selected .. "  ▾"
                        SafeCall(callback, selected)
                        closeDropdown()
                    end)
                end

                local ap = dropBtn.AbsolutePosition
                local asz = dropBtn.AbsoluteSize
                list.Position = UDim2.new(0, ap.X, 0, ap.Y + asz.Y + 4)
                list.Size = UDim2.new(0, asz.X, 0, #options * 32 + 8)

                Overlay.Visible = true
                currentDropdown = { button = dropBtn, list = list }
                local conn = Overlay.MouseButton1Click:Connect(closeDropdown)
                currentDropdown.conn = conn
            end)
            return frame
        end

        -- ▸ Textbox（新增）
        function Elements:CreateTextbox(text, placeholder, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 62)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -28, 0, 20)
            lbl.Position = UDim2.new(0, 16, 0, 6)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local input = Instance.new("TextBox")
            input.Size = UDim2.new(1, -32, 0, 26)
            input.Position = UDim2.new(0, 16, 0, 28)
            input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            input.BackgroundTransparency = 0.5
            input.BorderSizePixel = 0
            input.Text = default or ""
            input.PlaceholderText = placeholder or ""
            input.PlaceholderColor3 = Theme.SubText
            input.TextColor3 = Theme.Text
            input.Font = Enum.Font.Gotham
            input.TextSize = 13
            input.TextXAlignment = Enum.TextXAlignment.Left
            input.ClearTextOnFocus = false
            input.ZIndex = 4
            input.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 8)
                c.Parent = input
                local p = Instance.new("UIPadding")
                p.PaddingLeft = UDim.new(0, 10)
                p.PaddingRight = UDim.new(0, 10)
                p.Parent = input
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(255, 255, 255)
                s.Transparency = 0.85
                s.Parent = input
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                input.TextColor3 = t.Text
                input.PlaceholderColor3 = t.SubText
                local s = input:FindFirstChildOfClass("UIStroke")
                if s then s.Color = t.Accent end
            end)

            input.FocusLost:Connect(function(enterPressed)
                SafeCall(callback, input.Text, enterPressed)
            end)
            return frame
        end

        -- ▸ ProgressBar（新增）
        function Elements:CreateProgressBar(text, default)
            local val = math.clamp(default or 0, 0, 1)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 46)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -28, 0, 20)
            lbl.Position = UDim2.new(0, 16, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Text = text .. "   " .. math.floor(val * 100) .. "%"
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -32, 0, 6)
            barBg.Position = UDim2.new(0, 16, 0, 32)
            barBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            barBg.BackgroundTransparency = 0.86
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 4
            barBg.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = barBg
            end

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(val, 0, 1, 0)
            barFill.BackgroundColor3 = Theme.Accent
            barFill.BorderSizePixel = 0
            barFill.ZIndex = 5
            barFill.Parent = barBg
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = barFill
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                barFill.BackgroundColor3 = t.Accent
            end)

            local API = {}
            function API.Set(v)
                v = math.clamp(v, 0, 1)
                TweenService:Create(barFill, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                    Size = UDim2.new(v, 0, 1, 0)
                }):Play()
                lbl.Text = text .. "   " .. math.floor(v * 100) .. "%"
            end
            return API
        end

        -- ▸ InfoPanel
        function Elements:CreateInfoPanel(info)
            info = info or {}
            local panel = Instance.new("Frame")
            panel.Size = UDim2.new(1, 0, 0, 88)
            panel.ZIndex = 3
            panel.Parent = TabPage
            local g = Glass.Apply(panel, { Level = "Element", Radius = 14 })

            local avWrap = Instance.new("Frame")
            avWrap.Size = UDim2.new(0, 62, 0, 62)
            avWrap.Position = UDim2.new(0, 16, 0.5, -31)
            avWrap.BackgroundTransparency = 1
            avWrap.ZIndex = 4
            avWrap.Parent = panel
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = avWrap
                local s = Instance.new("UIStroke")
                s.Color = Theme.Accent
                s.Thickness = 2
                s.Transparency = 0.3
                s.Parent = avWrap
            end

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(1, -4, 1, -4)
            avatar.Position = UDim2.new(0, 2, 0, 2)
            avatar.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
            avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            avatar.ZIndex = 5
            avatar.Parent = avWrap
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = avatar
            end

            task.spawn(function()
                pcall(function()
                    local userId = Players.LocalPlayer.UserId
                    local url = Players:GetUserThumbnailAsync(userId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    avatar.Image = url
                end)
            end)

            local infoFrame = Instance.new("Frame")
            infoFrame.Size = UDim2.new(1, -96, 1, -20)
            infoFrame.Position = UDim2.new(0, 90, 0, 10)
            infoFrame.BackgroundTransparency = 1
            infoFrame.ZIndex = 4
            infoFrame.Parent = panel
            do
                local l = Instance.new("UIListLayout")
                l.Padding = UDim.new(0, 2)
                l.Parent = infoFrame
            end

            local function line(text, bold, color, size)
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, 0, 0, size or 18)
                t.BackgroundTransparency = 1
                t.Text = text
                t.TextColor3 = color
                t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
                t.TextSize = size or 13
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.ZIndex = 5
                t.Parent = infoFrame
                return t
            end

            local nL = line(info.PlayerName or Players.LocalPlayer.Name, true, Theme.Text, 16)
            local sL = line(info.ServerInfo or "Server: unknown", false, Theme.SubText, 12)
            local eL = line(info.ExecutorInfo or "Executor: unknown", false, Theme.SubText, 12)

            RegisterTheme(function(t)
                nL.TextColor3 = t.Text
                sL.TextColor3 = t.SubText
                eL.TextColor3 = t.SubText
                local s = avWrap:FindFirstChildOfClass("UIStroke")
                if s then s.Color = t.Accent end
            end)
            return panel
        end

        -- ▸ Image
        function Elements:CreateImage(imageId, sizeX, sizeY)
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, sizeX or 100, 0, sizeY or 100)
            img.Image = imageId or ""
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 3
            img.Parent = TabPage
            Glass.Apply(img, { Level = "Element", Radius = 12 })
            return img
        end

        -- ▸ ColorPicker
        function Elements:CreateColorPicker(text, defaultColor, callback)
            local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local prev = Instance.new("TextButton")
            prev.Size = UDim2.new(0, 64, 0, 30)
            prev.AnchorPoint = Vector2.new(1, 0.5)
            prev.Position = UDim2.new(1, -12, 0.5, 0)
            prev.BackgroundColor3 = currentColor
            prev.Text = ""
            prev.AutoButtonColor = false
            prev.ZIndex = 4
            prev.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 8)
                c.Parent = prev
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(255, 255, 255)
                s.Transparency = 0.5
                s.Parent = prev
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
            end)

            local popup = nil
            prev.MouseButton1Click:Connect(function()
                if popup then popup:Destroy() end

                popup = Instance.new("Frame")
                popup.Size = UDim2.new(0, 248, 0, 248)
                popup.ZIndex = 600
                popup.Parent = ScreenGui
                Glass.Apply(popup, { Level = "Panel", Radius = 16 })

                -- 打开位置：预览块下方
                local ap = prev.AbsolutePosition
                local asz = prev.AbsoluteSize
                local px = math.clamp(ap.X - 170, 10, ScreenGui.AbsoluteSize.X - 258)
                local py = math.clamp(ap.Y + asz.Y + 8, 10, ScreenGui.AbsoluteSize.Y - 258)
                popup.Position = UDim2.new(0, px, 0, py)

                -- 拖动把手
                local bar = Instance.new("TextButton")
                bar.Size = UDim2.new(1, 0, 0, 22)
                bar.BackgroundTransparency = 1
                bar.Text = "· · ·"
                bar.TextColor3 = Theme.SubText
                bar.Font = Enum.Font.GothamBold
                bar.TextSize = 14
                bar.AutoButtonColor = false
                bar.ZIndex = 601
                bar.Parent = popup
                do
                    local dragging, ds, sp
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true; ds = input.Position; sp = popup.Position
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                            local d = input.Position - ds
                            popup.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                    end)
                end

                -- SV 区
                local svBox = Instance.new("Frame")
                svBox.Size = UDim2.new(0, 190, 0, 190)
                svBox.Position = UDim2.new(0, 12, 0, 30)
                svBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                svBox.BorderSizePixel = 0
                svBox.ZIndex = 601
                svBox.Parent = popup
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 10)
                    c.Parent = svBox
                end

                -- 白色叠加（水平渐变：左不透明 右透明）
                local white = Instance.new("Frame")
                white.Size = UDim2.new(1, 0, 1, 0)
                white.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                white.BorderSizePixel = 0
                white.ZIndex = 602
                white.Parent = svBox
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 10)
                    c.Parent = white
                    local gr = Instance.new("UIGradient")
                    gr.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    gr.Parent = white
                end

                -- 黑色叠加（垂直渐变：上透明 下不透明）
                local black = Instance.new("Frame")
                black.Size = UDim2.new(1, 0, 1, 0)
                black.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                black.BorderSizePixel = 0
                black.ZIndex = 603
                black.Parent = svBox
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 10)
                    c.Parent = black
                    local gr = Instance.new("UIGradient")
                    gr.Rotation = 90
                    gr.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    })
                    gr.Parent = black
                end

                -- 色相条
                local hue = Instance.new("Frame")
                hue.Size = UDim2.new(0, 24, 0, 190)
                hue.Position = UDim2.new(0, 210, 0, 30)
                hue.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                hue.BorderSizePixel = 0
                hue.ZIndex = 601
                hue.Parent = popup
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 10)
                    c.Parent = hue
                    local gr = Instance.new("UIGradient")
                    gr.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                    })
                    gr.Rotation = 90
                    gr.Parent = hue
                end

                -- SV 指示器
                local svInd = Instance.new("Frame")
                svInd.Size = UDim2.new(0, 14, 0, 14)
                svInd.AnchorPoint = Vector2.new(0.5, 0.5)
                svInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                svInd.BorderSizePixel = 0
                svInd.ZIndex = 604
                svInd.Parent = svBox
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = svInd
                    local s = Instance.new("UIStroke")
                    s.Color = Color3.fromRGB(0, 0, 0)
                    s.Thickness = 2
                    s.Transparency = 0.3
                    s.Parent = svInd
                end

                -- Hue 指示器
                local hueInd = Instance.new("Frame")
                hueInd.Size = UDim2.new(1, 6, 0, 4)
                hueInd.AnchorPoint = Vector2.new(0.5, 0.5)
                hueInd.Position = UDim2.new(0.5, 0, 0, 0)
                hueInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueInd.BorderSizePixel = 0
                hueInd.ZIndex = 604
                hueInd.Parent = hue
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = hueInd
                    local s = Instance.new("UIStroke")
                    s.Color = Color3.fromRGB(0, 0, 0)
                    s.Thickness = 1
                    s.Parent = hueInd
                end

                local h, s, v = currentColor:ToHSV()
                svInd.Position = UDim2.new(s, 0, 1 - v, 0)
                hueInd.Position = UDim2.new(0.5, 0, h, 0)

                local svDrag, hueDrag = false, false

                local function commit()
                    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    currentColor = Color3.fromHSV(h, s, v)
                    prev.BackgroundColor3 = currentColor
                    SafeCall(callback, currentColor)
                end

                local function updSV(input)
                    local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    s = rx; v = 1 - ry
                    svInd.Position = UDim2.new(s, 0, 1 - v, 0)
                    commit()
                end
                local function updHue(input)
                    local ry = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
                    h = ry
                    hueInd.Position = UDim2.new(0.5, 0, h, 0)
                    commit()
                end

                -- 交互命中区（透明按钮，覆盖在 svBox 上）
                local svHit = Instance.new("TextButton")
                svHit.Size = UDim2.new(1, 0, 1, 0)
                svHit.BackgroundTransparency = 1
                svHit.Text = ""
                svHit.ZIndex = 605
                svHit.Parent = svBox
                svHit.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag = true; updSV(input)
                    end
                end)

                local hueHit = Instance.new("TextButton")
                hueHit.Size = UDim2.new(1, 0, 1, 0)
                hueHit.BackgroundTransparency = 1
                hueHit.Text = ""
                hueHit.ZIndex = 605
                hueHit.Parent = hue
                hueHit.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = true; updHue(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag = false; hueDrag = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if svDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updSV(input)
                    elseif hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updHue(input)
                    end
                end)

                -- 关闭
                local closeB = Instance.new("TextButton")
                closeB.Size = UDim2.new(1, -24, 0, 26)
                closeB.Position = UDim2.new(0, 12, 1, -32)
                closeB.Text = "完成"
                closeB.TextColor3 = Color3.fromRGB(255, 255, 255)
                closeB.Font = Enum.Font.GothamSemibold
                closeB.TextSize = 13
                closeB.AutoButtonColor = false
                closeB.ZIndex = 601
                closeB.Parent = popup
                closeB.BackgroundColor3 = Theme.Accent
                do
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 10)
                    c.Parent = closeB
                end
                closeB.MouseButton1Click:Connect(function()
                    popup:Destroy(); popup = nil
                end)

                local conn
                conn = Overlay.MouseButton1Click:Connect(function()
                    if popup then
                        popup:Destroy(); popup = nil
                        if conn then conn:Disconnect() end
                    end
                end)
                Overlay.Visible = true
            end)
            return frame
        end

        -- ▸ Keybind
        function Elements:CreateKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, -20, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0, 100, 0, 30)
            bindBtn.AnchorPoint = Vector2.new(1, 0.5)
            bindBtn.Position = UDim2.new(1, -12, 0.5, 0)
            bindBtn.Text = currentKey.Name
            bindBtn.TextColor3 = Theme.Text
            bindBtn.Font = Enum.Font.GothamSemibold
            bindBtn.TextSize = 12
            bindBtn.AutoButtonColor = false
            bindBtn.ZIndex = 4
            bindBtn.Parent = frame
            local bbG = Glass.Apply(bindBtn, { Level = "Bubble", Radius = 8, Highlight = false, EdgeT = 0.9 })

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                bindBtn.TextColor3 = t.Text
                bbG.Edge.Color = t.Accent
            end)

            local listening = false
            local listenerKey = "kb_" .. tostring(themeCounter)

            local function startListening()
                if listening then return end
                listening = true
                bindBtn.Text = "..."
                bbG.Edge.Color = Theme.Accent
                bbG.Edge.Transparency = 0.3

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindBtn.Text = currentKey.Name
                        listening = false
                        if conn then conn:Disconnect() end
                        bbG.Edge.Color = Color3.fromRGB(255, 255, 255)
                        bbG.Edge.Transparency = 0.9

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

            if activeKeybinds[listenerKey] then
                activeKeybinds[listenerKey]:Disconnect()
            end
            activeKeybinds[listenerKey] = UserInputService.InputBegan:Connect(function(inp, gp)
                if not gp and inp.KeyCode == currentKey then
                    SafeCall(callback, currentKey)
                end
            end)
            return frame
        end

        -- ▸ Paragraph
        function Elements:CreateParagraph(text, lines)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, (lines or 2) * 22 + 20)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, Highlight = false, EdgeT = 0.95 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 1, -20)
            lbl.Position = UDim2.new(0, 16, 0, 10)
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

            RegisterTheme(function(t) lbl.TextColor3 = t.SubText end)
            return frame
        end

        return Elements
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- 销毁
    -- ═══════════════════════════════════════════════════════════════════
    function Window:Destroy()
        for _, conn in pairs(activeKeybinds) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        activeKeybinds = {}
        themeRegistry = {}
        closeDropdown()
        BlurController.Release()
        if Island then Island.Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
    end

    -- 初始打开：稍等 0.4s 让 ScreenGui 尺寸稳定后打开灵动岛
    task.spawn(function()
        task.wait(0.3)
        showMain()
    end)

    return Window
end

return Library