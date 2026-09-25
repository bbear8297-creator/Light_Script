--[[
    ═══════════════════════════════════════════════════════════════════════════
    LS Team UI Library · v4.0 "Deep Space"
    · 深空夜配色 + 高质感层次
    · FeatureCounter：功能数实时统计，灵动岛同步
    · 精细动效：按压、悬停、开关小圆点、发光
    ═══════════════════════════════════════════════════════════════════════════
]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")

local Library = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- §1  目标 GUI
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
-- §2  工具
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
-- §3  背景模糊
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
        TweenService:Create(state.blur, TweenInfo.new(0.4), { Size = 18 }):Play()
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
-- §4  深空夜玻璃系统
--     层次：Window(最深) → Panel(中) → Element(最浅) → Bubble(按钮)
-- ═══════════════════════════════════════════════════════════════════════════
local Glass = {}
Glass.Levels = {
    Window  = { Tint = Color3.fromRGB( 18,  18,  22), TintT = 0.04, EdgeT = 0.80, Radius = 26, Stroke = 1.0 },
    Panel   = { Tint = Color3.fromRGB( 26,  26,  32), TintT = 0.14, EdgeT = 0.86, Radius = 20, Stroke = 1.0 },
    Element = { Tint = Color3.fromRGB( 34,  34,  42), TintT = 0.22, EdgeT = 0.90, Radius = 14, Stroke = 1.0 },
    Bubble  = { Tint = Color3.fromRGB( 46,  46,  56), TintT = 0.30, EdgeT = 0.88, Radius = 12, Stroke = 1.0 },
    Hover   = { Tint = Color3.fromRGB( 58,  58,  70), TintT = 0.20, EdgeT = 0.80, Radius = 14, Stroke = 1.0 },
}

function Glass.Apply(parent, opts)
    opts = opts or {}
    local lv = Glass.Levels[opts.Level or "Element"]
    local tint     = opts.Tint     or lv.Tint
    local tintT    = opts.TintT    or lv.TintT
    local edgeT    = opts.EdgeT    or lv.EdgeT
    local radius   = opts.Radius   or lv.Radius
    local strokePx = opts.Stroke   or lv.Stroke
    local edgeCol  = opts.EdgeColor or Color3.fromRGB(255, 255, 255)

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

    return { Corner = corner, Edge = edge }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §5  主题（深空夜为默认）
-- ═══════════════════════════════════════════════════════════════════════════
Library.Themes = {
    -- 深空夜（默认）
    DeepSpace = {
        Accent     = Color3.fromRGB( 10, 132, 255),
        AccentHi   = Color3.fromRGB( 90, 180, 255),
        AccentDim  = Color3.fromRGB( 20,  80, 160),
        Text       = Color3.fromRGB(245, 245, 250),
        SubText    = Color3.fromRGB(140, 140, 155),
        HintText   = Color3.fromRGB( 90,  90, 105),
        ToggleOff  = Color3.fromRGB( 60,  60,  72),
        Divider    = Color3.fromRGB(255, 255, 255),
        Success    = Color3.fromRGB( 48, 209,  88),
        Warning    = Color3.fromRGB(255, 214,  10),
        Danger     = Color3.fromRGB(255,  69,  58),
    },
    -- 深空紫
    Nebula = {
        Accent     = Color3.fromRGB(160, 108, 255),
        AccentHi   = Color3.fromRGB(200, 165, 255),
        AccentDim  = Color3.fromRGB( 80,  50, 140),
        Text       = Color3.fromRGB(245, 240, 255),
        SubText    = Color3.fromRGB(155, 145, 175),
        HintText   = Color3.fromRGB(100,  90, 120),
        ToggleOff  = Color3.fromRGB( 65,  60,  80),
        Divider    = Color3.fromRGB(255, 255, 255),
        Success    = Color3.fromRGB( 80, 220, 160),
        Warning    = Color3.fromRGB(255, 200,  80),
        Danger     = Color3.fromRGB(255, 100, 110),
    },
    -- 深空青
    Aurora = {
        Accent     = Color3.fromRGB( 48, 220, 200),
        AccentHi   = Color3.fromRGB(120, 240, 225),
        AccentDim  = Color3.fromRGB( 20, 100,  95),
        Text       = Color3.fromRGB(235, 250, 250),
        SubText    = Color3.fromRGB(140, 180, 180),
        HintText   = Color3.fromRGB( 80, 120, 120),
        ToggleOff  = Color3.fromRGB( 55,  75,  75),
        Divider    = Color3.fromRGB(255, 255, 255),
        Success    = Color3.fromRGB( 80, 230, 160),
        Warning    = Color3.fromRGB(255, 200,  80),
        Danger     = Color3.fromRGB(255, 110, 100),
    },
    -- 深空橙
    Ember = {
        Accent     = Color3.fromRGB(255, 140,  60),
        AccentHi   = Color3.fromRGB(255, 180, 110),
        AccentDim  = Color3.fromRGB(140,  70,  20),
        Text       = Color3.fromRGB(255, 245, 235),
        SubText    = Color3.fromRGB(200, 170, 145),
        HintText   = Color3.fromRGB(130, 100,  80),
        ToggleOff  = Color3.fromRGB( 80,  65,  55),
        Divider    = Color3.fromRGB(255, 255, 255),
        Success    = Color3.fromRGB(150, 220, 120),
        Warning    = Color3.fromRGB(255, 210, 100),
        Danger     = Color3.fromRGB(255, 100,  90),
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- §6  FeatureCounter（功能计数器）
-- ═══════════════════════════════════════════════════════════════════════════
local FeatureCounter = {}
do
    local features = {}    -- { [id] = { name, active } }
    local listeners = {}
    local counter = 0

    function FeatureCounter.Register(name)
        counter = counter + 1
        local id = "feat_" .. counter
        features[id] = { name = name or ("功能 " .. counter), active = false }
        return id
    end

    function FeatureCounter.SetActive(id, active)
        if not features[id] then return end
        if features[id].active == active then return end
        features[id].active = active
        FeatureCounter.Notify()
    end

    function FeatureCounter.Remove(id)
        if features[id] then
            features[id] = nil
            FeatureCounter.Notify()
        end
    end

    function FeatureCounter.Count()
        local n = 0
        for _, f in pairs(features) do
            if f.active then n = n + 1 end
        end
        return n
    end

    function FeatureCounter.List()
        local list = {}
        for id, f in pairs(features) do
            if f.active then table.insert(list, { id = id, name = f.name }) end
        end
        return list
    end

    function FeatureCounter.Notify()
        local count = FeatureCounter.Count()
        local list = FeatureCounter.List()
        for _, fn in ipairs(listeners) do
            pcall(fn, count, list)
        end
    end

    -- 订阅返回 unsubscribe 函数
    function FeatureCounter.Subscribe(fn)
        table.insert(listeners, fn)
        pcall(fn, FeatureCounter.Count(), FeatureCounter.List())
        return function()
            for i, f in ipairs(listeners) do
                if f == fn then
                    table.remove(listeners, i)
                    return
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §7  灵动岛（信息胶囊）
-- ═══════════════════════════════════════════════════════════════════════════
local function CreateDynamicIsland(parent, theme, callbacks)
    callbacks = callbacks or {}

    local H           = 40
    local RADIUS      = H / 2
    local PAD         = 10
    local AVATAR_SIZE = 28
    local MIN_WIDTH   = 180

    local Island = Instance.new("TextButton")
    Island.Name = "DynamicIsland"
    Island.AnchorPoint = Vector2.new(0.5, 0)
    Island.Position = UDim2.new(0.5, 0, 0, 12)
    Island.Size = UDim2.new(0, MIN_WIDTH, 0, H)
    Island.Text = ""
    Island.AutoButtonColor = false
    Island.ClipsDescendants = true
    Island.ZIndex = 220
    Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Island.BackgroundTransparency = 0
    Island.BorderSizePixel = 0
    Island.Parent = parent

    local islandCorner = Instance.new("UICorner")
    islandCorner.CornerRadius = UDim.new(0, RADIUS)
    islandCorner.Parent = Island

    local islandStroke = Instance.new("UIStroke")
    islandStroke.Color = Color3.fromRGB(255, 255, 255)
    islandStroke.Transparency = 0.88
    islandStroke.Thickness = 1
    islandStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    islandStroke.Parent = Island

    -- 左区：头像
    local LeftZone = Instance.new("Frame")
    LeftZone.Name = "LeftZone"
    LeftZone.BackgroundTransparency = 1
    LeftZone.Size = UDim2.new(0, AVATAR_SIZE, 1, 0)
    LeftZone.Position = UDim2.new(0, PAD, 0, 0)
    LeftZone.ZIndex = 3
    LeftZone.Parent = Island

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE)
    avatar.Position = UDim2.new(0, 0, 0.5, -AVATAR_SIZE / 2)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    avatar.ZIndex = 4
    avatar.Parent = LeftZone
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = avatar
        local s = Instance.new("UIStroke")
        s.Color = theme.Success
        s.Thickness = 1.5
        s.Transparency = 0.35
        s.Parent = avatar
    end

    task.spawn(function()
        pcall(function()
            local userId = Players.LocalPlayer.UserId
            local url = Players:GetUserThumbnailAsync(userId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            avatar.Image = url
        end)
    end)

    -- 中区：状态
    local CenterZone = Instance.new("Frame")
    CenterZone.Name = "CenterZone"
    CenterZone.BackgroundTransparency = 1
    CenterZone.Position = UDim2.new(0, PAD + AVATAR_SIZE + PAD, 0, 0)
    CenterZone.Size = UDim2.new(0, 0, 1, 0)
    CenterZone.ZIndex = 3
    CenterZone.Parent = Island

    local centerLabel = Instance.new("TextLabel")
    centerLabel.Name = "StatusText"
    centerLabel.Size = UDim2.new(1, 0, 1, 0)
    centerLabel.BackgroundTransparency = 1
    centerLabel.Text = "待机"
    centerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    centerLabel.Font = Enum.Font.GothamSemibold
    centerLabel.TextSize = 13
    centerLabel.TextXAlignment = Enum.TextXAlignment.Left
    centerLabel.ZIndex = 4
    centerLabel.Parent = CenterZone

    -- 右区：延迟 + 帧数 + 自定义 widget
    local RightZone = Instance.new("Frame")
    RightZone.Name = "RightZone"
    RightZone.BackgroundTransparency = 1
    RightZone.AnchorPoint = Vector2.new(1, 0)
    RightZone.Position = UDim2.new(1, -PAD, 0, 0)
    RightZone.Size = UDim2.new(0, 0, 1, 0)
    RightZone.ZIndex = 3
    RightZone.Parent = Island

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Horizontal
    rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rightLayout.Padding = UDim.new(0, 8)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Parent = RightZone

    -- 状态点（在 ping 左侧）
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 7, 0, 7)
    statusDot.BackgroundColor3 = theme.Success
    statusDot.BorderSizePixel = 0
    statusDot.LayoutOrder = 0
    statusDot.ZIndex = 4
    statusDot.Parent = RightZone
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = statusDot
    end

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "Ping"
    pingLabel.AutomaticSize = Enum.AutomaticSize.X
    pingLabel.Size = UDim2.new(0, 0, 1, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "0ms"
    pingLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    pingLabel.Font = Enum.Font.GothamMedium
    pingLabel.TextSize = 12
    pingLabel.LayoutOrder = 1
    pingLabel.ZIndex = 4
    pingLabel.Parent = RightZone

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "Fps"
    fpsLabel.AutomaticSize = Enum.AutomaticSize.X
    fpsLabel.Size = UDim2.new(0, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "0fps"
    fpsLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    fpsLabel.Font = Enum.Font.GothamMedium
    fpsLabel.TextSize = 12
    fpsLabel.LayoutOrder = 2
    fpsLabel.ZIndex = 4
    fpsLabel.Parent = RightZone

    -- 宽度自适应
    local function updateWidth(animate)
        local centerW = MeasureText(centerLabel.Text, 13, Enum.Font.GothamSemibold).X
        local pingW   = MeasureText(pingLabel.Text, 12, Enum.Font.GothamMedium).X
        local fpsW    = MeasureText(fpsLabel.Text, 12, Enum.Font.GothamMedium).X
        local rightW  = 7 + 8 + pingW + 8 + fpsW  -- dot + padding + ping + padding + fps

        -- 遍历额外 widget
        for _, child in ipairs(RightZone:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout")
            and child ~= statusDot and child ~= pingLabel and child ~= fpsLabel
            and child.Visible then
                if child.AutomaticSize == Enum.AutomaticSize.X and (child:IsA("TextLabel") or child:IsA("TextButton")) then
                    rightW = rightW + MeasureText(child.Text, child.TextSize, child.Font).X + 8
                else
                    rightW = rightW + child.AbsoluteSize.X + 8
                end
            end
        end

        CenterZone.Size = UDim2.new(0, centerW, 1, 0)
        RightZone.Size  = UDim2.new(0, rightW, 1, 0)

        local totalW = PAD + AVATAR_SIZE + PAD + centerW + PAD + rightW + PAD
        totalW = math.max(totalW, MIN_WIDTH)

        if animate then
            TweenService:Create(Island,
                TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, totalW, 0, H) }):Play()
        else
            Island.Size = UDim2.new(0, totalW, 0, H)
        end
    end

    -- 实时刷新 ping / fps
    task.spawn(function()
        local frameCount = 0
        local lastTime = tick()

        local renderConn = RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
        end)

        while Island.Parent do
            task.wait(1)
            local now = tick()
            local elapsed = math.max(now - lastTime, 0.001)
            local fps = math.floor(frameCount / elapsed)
            frameCount = 0
            lastTime = now
            fpsLabel.Text = fps .. "fps"

            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            pingLabel.Text = ping .. "ms"

            updateWidth(true)
        end

        if renderConn then renderConn:Disconnect() end
    end)

    -- 点击 = 打开主窗
    local pressScale = Instance.new("UIScale")
    pressScale.Scale = 1
    pressScale.Parent = Island

    Island.MouseButton1Click:Connect(function()
        TweenService:Create(pressScale,
            TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            TweenService:Create(pressScale,
                TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Scale = 1 }):Play()
        end)
        if callbacks.OnClick then SafeCall(callbacks.OnClick) end
    end)

    -- ─── API ───
    local API = { Frame = Island }

    function API.SetStatus(text)
        centerLabel.Text = text
        updateWidth(true)
    end
    API.SetTitle = API.SetStatus

    function API.SetAvatar(imageOrUserId)
        if type(imageOrUserId) == "number" then
            task.spawn(function()
                pcall(function()
                    local url = Players:GetUserThumbnailAsync(imageOrUserId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    avatar.Image = url
                end)
            end)
        else
            avatar.Image = tostring(imageOrUserId)
        end
    end

    function API.SetAccent(color)
        local s = avatar:FindFirstChildOfClass("UIStroke")
        if s then s.Color = color end
    end
    API.SetDotColor = API.SetAccent

    -- 状态点颜色
    function API.SetStatusDot(color)
        statusDot.BackgroundColor3 = color
    end

    -- 自定义 widget
    function API.AddWidget(side, guiObject)
        if not guiObject then return end
        if side == "left" then
            guiObject.Parent = LeftZone
        elseif side == "center" then
            guiObject.Parent = CenterZone
        elseif side == "right" then
            guiObject.Parent = RightZone
        end
        updateWidth(true)
        return guiObject
    end

    function API.RemoveWidget(guiObject)
        if guiObject then guiObject:Destroy() end
        updateWidth(true)
    end

    function API.GetZones()
        return { Left = LeftZone, Center = CenterZone, Right = RightZone }
    end

    function API.Destroy()
        if Island.Parent then Island:Destroy() end
    end

    updateWidth(false)
    return API
end

-- ═══════════════════════════════════════════════════════════════════════════
-- §8  CreateWindow
-- ═══════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(options)
    options = options or {}
    local WindowTitle = options.Title or "LS UI"
    local initialTheme = options.Theme or "DeepSpace"

    local Theme = {}
    local function loadTheme(name)
        local t = Library.Themes[name] or Library.Themes.DeepSpace
        for k, _ in pairs(Library.Themes.DeepSpace) do Theme[k] = t[k] end
    end
    loadTheme(initialTheme)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LS_UI_" .. tostring(math.random(100000, 999999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = false
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = targetGui

    local globalConns = {}
    local function trackConn(conn)
        table.insert(globalConns, conn)
        return conn
    end
    local function disconnectAll()
        for _, c in ipairs(globalConns) do
            if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        end
        globalConns = {}
    end

    local themeRegistry = {}
    local themeCounter = 0
    local function RegisterTheme(fn)
        themeCounter = themeCounter + 1
        themeRegistry[themeCounter] = fn
        pcall(fn, Theme)
        return themeCounter
    end
    local function RunTheme()
        for _, fn in pairs(themeRegistry) do pcall(fn, Theme) end
    end

    -- 遮罩
    local Overlay = Instance.new("TextButton")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.Text = ""
    Overlay.Visible = false
    Overlay.Active = false
    Overlay.ZIndex = 500
    Overlay.Parent = ScreenGui

    local overlayRefs = {}
    local overlayCounter = 0
    local function pushOverlay()
        overlayCounter = overlayCounter + 1
        local id = overlayCounter
        overlayRefs[id] = true
        Overlay.Visible = true
        Overlay.Active = true
        return id
    end
    local function popOverlay(id)
        if id then overlayRefs[id] = nil end
        if next(overlayRefs) == nil then
            Overlay.Visible = false
            Overlay.Active = false
        end
    end
    local function clearAllOverlays()
        overlayRefs = {}
        Overlay.Visible = false
        Overlay.Active = false
    end

    -- 通知容器
    local NotifContainer = Instance.new("Frame")
    NotifContainer.AnchorPoint = Vector2.new(1, 0)
    NotifContainer.Position = UDim2.new(1, -14, 0, 62)
    NotifContainer.Size = UDim2.new(0, 280, 1, -100)
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

    local MainFrame, MainScale, Island

    local function showMain()
        MainFrame.Visible = true
        MainScale.Scale = 0
        TweenService:Create(MainScale,
            TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()
        BlurController.Acquire()
    end
    local function hideMain()
        BlurController.Release()
        TweenService:Create(MainScale,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Scale = 0 }):Play()
        task.delay(0.3, function()
            if MainScale.Scale < 0.05 then MainFrame.Visible = false end
        end)
    end

    Island = CreateDynamicIsland(ScreenGui, Theme, {
        OnClick = function() showMain() end,
    })

    -- ★ 订阅 FeatureCounter，实时更新灵动岛 ★
    local islandUnsub = FeatureCounter.Subscribe(function(count, list)
        if count == 0 then
            Island.SetStatus("待机")
            Island.SetStatusDot(Theme.HintText)
        else
            Island.SetStatus("运行中 · " .. count .. " 个功能")
            Island.SetStatusDot(Theme.Success)
        end
    end)

    -- 主窗
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
    MainFrame.Size = UDim2.new(0.92, 0, 0.78, 0)
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.ZIndex = 100
    MainFrame.Parent = ScreenGui
    Glass.Apply(MainFrame, { Level = "Window", Radius = 26 })

    MainScale = Instance.new("UIScale")
    MainScale.Scale = 0
    MainScale.Parent = MainFrame

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(720, 470)
    sizeConstraint.MinSize = Vector2.new(340, 300)
    sizeConstraint.Parent = MainFrame

    -- 顶部栏
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 52)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 2
    TopBar.Parent = MainFrame

    -- 左侧：圆形 Logo 占位 + 标题
    local TitleHolder = Instance.new("Frame")
    TitleHolder.Size = UDim2.new(1, -140, 1, 0)
    TitleHolder.Position = UDim2.new(0, 20, 0, 0)
    TitleHolder.BackgroundTransparency = 1
    TitleHolder.ZIndex = 3
    TitleHolder.Parent = TopBar

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Size = UDim2.new(1, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Text = WindowTitle
    TopTitle.TextColor3 = Theme.Text
    TopTitle.Font = Enum.Font.GothamBold
    TopTitle.TextSize = 16
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.ZIndex = 3
    TopTitle.Parent = TitleHolder

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -18, 0.5, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 15
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = TopBar
    local closeGlass = Glass.Apply(closeBtn, { Level = "Bubble", Radius = 15, EdgeT = 0.92 })
    closeBtn.BackgroundTransparency = 0.5

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.15,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(closeGlass.Edge, TweenInfo.new(0.18), {
            Color = Theme.Danger, Transparency = 0.4
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Color3.fromRGB(46, 46, 56), BackgroundTransparency = 0.5,
            TextColor3 = Theme.SubText
        }):Play()
        TweenService:Create(closeGlass.Edge, TweenInfo.new(0.18), {
            Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(hideMain)

    -- 顶部分隔线（更细腻）
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -32, 0, 1)
    topDivider.Position = UDim2.new(0, 16, 1, 0)
    topDivider.BackgroundColor3 = Theme.Divider
    topDivider.BackgroundTransparency = 0.92
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = 3
    topDivider.Parent = TopBar

    RegisterTheme(function(t)
        TopTitle.TextColor3 = t.Text
        topDivider.BackgroundColor3 = t.Divider
        closeBtn.TextColor3 = t.SubText
    end)

    -- 主窗拖动
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
        trackConn(UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end))
        trackConn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0.30, 0, 1, -52)
    Sidebar.Position = UDim2.new(0, 0, 0, 52)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ZIndex = 2
    Sidebar.Parent = MainFrame

    local sidebarGlass = Instance.new("Frame")
    sidebarGlass.Name = "SidebarGlass"
    sidebarGlass.Size = UDim2.new(1, -16, 1, -16)
    sidebarGlass.Position = UDim2.new(0, 8, 0, 8)
    sidebarGlass.ZIndex = 2
    sidebarGlass.Parent = Sidebar
    Glass.Apply(sidebarGlass, { Level = "Panel", Radius = 20 })

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
    do
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, 8)
        p.PaddingBottom = UDim.new(0, 8)
        p.Parent = sidebarGlass
    end
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = TabContainer
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- 内容区
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(0.70, 0, 1, -52)
    ContentContainer.Position = UDim2.new(0.30, 0, 0, 52)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ZIndex = 2
    ContentContainer.Parent = MainFrame

    -- ═══════════════════════════════════════════════════════════════════
    -- 通知
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
        Glass.Apply(notif, { Level = "Panel", Radius = 16 })

        local barColor = Theme.Accent
        if kind == "success" then barColor = Theme.Success
        elseif kind == "warning" then barColor = Theme.Warning
        elseif kind == "error" then barColor = Theme.Danger end

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -20)
        bar.Position = UDim2.new(0, 10, 0, 10)
        bar.BackgroundColor3 = barColor
        bar.BorderSizePixel = 0
        bar.ZIndex = 3
        bar.Parent = notif
        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = bar
        end

        local imgSize = 40
        local padX = 18
        local hasImage = opts.Image and true or false
        local textX = hasImage and (padX + imgSize + 12) or (padX + 10)

        if hasImage then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, imgSize, 0, imgSize)
            img.Position = UDim2.new(0, padX, 0, 14)
            img.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            img.BackgroundTransparency = 0.3
            img.Image = opts.Image
            img.ScaleType = Enum.ScaleType.Crop
            img.ZIndex = 3
            img.Parent = notif
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 10)
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

        local maxW = 280 - textX - 16
        local textH = MeasureText(message, 12, Enum.Font.Gotham, maxW).Y
        local minH = hasImage and (imgSize + 26) or 66
        local totalH = math.max(minH, 36 + textH + 18)
        msgLbl.Size = UDim2.new(1, -textX - 16, 0, textH)
        notif.Size = UDim2.new(1, 0, 0, totalH)

        local sc = Instance.new("UIScale")
        sc.Scale = 0.85
        sc.Parent = notif
        notif.Position = UDim2.new(1, 40, 0, 0)
        TweenService:Create(notif,
            TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = UDim2.new(0, 0, 0, 0) }):Play()
        TweenService:Create(sc,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()

        task.delay(duration, function()
            if not notif.Parent then return end
            TweenService:Create(notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                { Position = UDim2.new(1, 40, 0, 0) }):Play()
            TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0.85 }):Play()
            task.wait(0.32)
            if notif.Parent then notif:Destroy() end
        end)
        return notif
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- Window
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
            popOverlay(currentDropdown.overlayId)
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
        Theme.AccentDim = Color3.fromHSV(h, s, math.max(v * 0.5, 0.1))
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

    function Window:ShowMain() showMain() end
    function Window:HideMain() hideMain() end

    function Window:GetIsland() return Island end
    function Window:SetIslandStatus(text) Island.SetStatus(text) end
    function Window:SetIslandTitle(text)  Island.SetStatus(text) end
    function Window:SetIslandDot(color)   Island.SetStatusDot(color) end
    function Window:SetIslandAvatar(imgOrId) Island.SetAvatar(imgOrId) end

    -- ★ 手动注册功能（用于非 Toggle 的功能）★
    function Window:RegisterFeature(name)
        local id = FeatureCounter.Register(name)
        return id
    end
    function Window:SetFeatureActive(id, active)
        FeatureCounter.SetActive(id, active)
    end
    function Window:GetActiveFeatureCount()
        return FeatureCounter.Count()
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- CreateTab
    -- ═══════════════════════════════════════════════════════════════════
    function Window:CreateTab(TabName, iconId, iconOptions)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(1, -16, 0, 38)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.ZIndex = 4
        TabButton.Parent = TabContainer
        local tbGlass = Glass.Apply(TabButton, {
            Level = "Bubble", Radius = 12, EdgeT = 0.97, TintT = 1,
        })

        local tbScale = Instance.new("UIScale")
        tbScale.Scale = 1
        tbScale.Parent = TabButton

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -20, 1, 0)
        holder.Position = UDim2.new(0, 12, 0, 0)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 5
        holder.Parent = TabButton
        do
            local l = Instance.new("UIListLayout")
            l.FillDirection = Enum.FillDirection.Horizontal
            l.VerticalAlignment = Enum.VerticalAlignment.Center
            l.Padding = UDim.new(0, 10)
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
        tabText.TextColor3 = Theme.SubText
        tabText.Font = Enum.Font.GothamSemibold
        tabText.TextSize = 13
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.ZIndex = 6
        tabText.Parent = holder

        local isSelected = false
        local function apply(t)
            if isSelected then
                tabText.TextColor3 = t.Text
                tbGlass.Edge.Color = t.Accent
                tbGlass.Edge.Transparency = 0.5
                tbGlass.Tint = t.Accent
                tbGlass.TintT = 0.78
            else
                tabText.TextColor3 = t.SubText
                tbGlass.Edge.Color = Color3.fromRGB(255, 255, 255)
                tbGlass.Edge.Transparency = 0.97
                tbGlass.Tint = Color3.fromRGB(46, 46, 56)
                tbGlass.TintT = 1
            end
        end
        RegisterTheme(apply)

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

        RegisterTheme(function(t)
            TabPage.ScrollBarImageColor3 = t.Accent
        end)

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
                tbGlass.TintT = 0.88
            end
            TweenService:Create(tbScale, TweenInfo.new(0.18), { Scale = 1.02 }):Play()
        end)
        TabButton.MouseLeave:Connect(function()
            if not isSelected then
                tbGlass.TintT = 1
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
        -- Elements
        -- ═══════════════════════════════════════════════════════════
        local Elements = {}

        function Elements:CreateLabel(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 1, 0)
            lbl.Position = UDim2.new(0, 16, 0, 0)
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
                frame.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            end)
            return frame
        end

        function Elements:CreateSection(title)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 30)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 3
            frame.Parent = TabPage

            local accent = Instance.new("Frame")
            accent.Size = UDim2.new(0, 3, 0, 12)
            accent.Position = UDim2.new(0, 8, 0.5, -6)
            accent.BackgroundColor3 = Theme.Accent
            accent.BorderSizePixel = 0
            accent.ZIndex = 4
            accent.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = accent
            end

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -24, 1, 0)
            lbl.Position = UDim2.new(0, 20, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = title
            lbl.TextColor3 = Theme.SubText
            lbl.Font = Enum.Font.GothamSemibold
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            RegisterTheme(function(t)
                lbl.TextColor3 = t.SubText
                accent.BackgroundColor3 = t.Accent
            end)
            return frame
        end

        function Elements:CreateDivider()
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 12)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 3
            frame.Parent = TabPage

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, -32, 0, 1)
            line.Position = UDim2.new(0, 16, 0.5, 0)
            line.BackgroundColor3 = Theme.Divider
            line.BackgroundTransparency = 0.92
            line.BorderSizePixel = 0
            line.ZIndex = 4
            line.Parent = frame
            RegisterTheme(function(t) line.BackgroundColor3 = t.Divider end)
            return frame
        end

        function Elements:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 3
            btn.Parent = TabPage
            local g = Glass.Apply(btn, { Level = "Element", Radius = 12, EdgeT = 0.92 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -56, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
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
            arrow.TextColor3 = Theme.HintText
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 22
            arrow.ZIndex = 4
            arrow.Parent = btn

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                arrow.TextColor3 = t.HintText
                btn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            end)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 62), BackgroundTransparency = 0.05
                }):Play()
                TweenService:Create(g.Edge, TweenInfo.new(0.18), {
                    Color = Theme.Accent, Transparency = 0.5
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Theme.AccentHi
                }):Play()
                TweenService:Create(arrow, TweenInfo.new(0.18), {
                    TextColor3 = Theme.Accent
                }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18), {
                    BackgroundColor3 = Color3.fromRGB(34, 34, 42), BackgroundTransparency = 0.22
                }):Play()
                TweenService:Create(g.Edge, TweenInfo.new(0.18), {
                    Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92
                }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18), {
                    TextColor3 = Theme.Text
                }):Play()
                TweenService:Create(arrow, TweenInfo.new(0.18), {
                    TextColor3 = Theme.HintText
                }):Play()
            end)
            btn.MouseButton1Click:Connect(function() SafeCall(callback) end)
            return btn
        end

        -- ★ Toggle 自动注册到 FeatureCounter ★
        function Elements:CreateToggle(text, default, callback, opts)
            opts = opts or {}
            local toggled = default or false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            -- 左侧状态点
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.Position = UDim2.new(0, 16, 0.5, -3)
            dot.BackgroundColor3 = toggled and Theme.Success or Theme.ToggleOff
            dot.BorderSizePixel = 0
            dot.ZIndex = 5
            dot.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = dot
            end

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -110, 1, 0)
            lbl.Position = UDim2.new(0, 32, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(0, 44, 0, 24)
            track.AnchorPoint = Vector2.new(1, 0.5)
            track.Position = UDim2.new(1, -18, 0.5, 0)
            track.Text = ""
            track.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
            track.AutoButtonColor = false
            track.ZIndex = 4
            track.Parent = frame
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = track
            end

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 5
            knob.Parent = track
            do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = knob
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(0, 0, 0)
                s.Transparency = 0.8
                s.Thickness = 1
                s.Parent = knob
            end

            -- ★ FeatureCounter 注册 ★
            local featureName = opts.FeatureName or text
            local registerFeature = opts.RegisterFeature ~= false
            local featureId = registerFeature and FeatureCounter.Register(featureName) or nil
            if featureId and toggled then
                FeatureCounter.SetActive(featureId, true)
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                track.BackgroundColor3 = toggled and t.Accent or t.ToggleOff
                dot.BackgroundColor3 = toggled and t.Success or t.ToggleOff
            end)

            local function fire()
                toggled = not toggled
                local goal = toggled and Theme.Accent or Theme.ToggleOff
                local pos = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                local dotColor = toggled and Theme.Success or Theme.ToggleOff

                TweenService:Create(track, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                    BackgroundColor3 = goal
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                    Position = pos
                }):Play()
                TweenService:Create(dot, TweenInfo.new(0.22), {
                    BackgroundColor3 = dotColor
                }):Play()

                -- ★ 更新 FeatureCounter ★
                if featureId then
                    FeatureCounter.SetActive(featureId, toggled)
                end

                SafeCall(callback, toggled)
            end
            track.MouseButton1Click:Connect(fire)

            local API = { Frame = frame }
            function API.Set(v)
                if toggled ~= v then fire() end
            end
            function API.Get() return toggled end
            function API.GetFeatureId() return featureId end
            return API
        end

        function Elements:CreateSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 64)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 0, 22)
            lbl.Position = UDim2.new(0, 18, 0, 8)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local valueLbl = Instance.new("TextLabel")
            valueLbl.Size = UDim2.new(0, 60, 0, 22)
            valueLbl.AnchorPoint = Vector2.new(1, 0)
            valueLbl.Position = UDim2.new(1, -18, 0, 8)
            valueLbl.BackgroundTransparency = 1
            valueLbl.Text = tostring(default)
            valueLbl.TextColor3 = Theme.Accent
            valueLbl.Font = Enum.Font.GothamBold
            valueLbl.TextSize = 13
            valueLbl.TextXAlignment = Enum.TextXAlignment.Right
            valueLbl.ZIndex = 4
            valueLbl.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -36, 0, 6)
            barBg.Position = UDim2.new(0, 18, 0, 42)
            barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
            barBg.BackgroundTransparency = 0.5
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
                valueLbl.TextColor3 = t.Accent
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
                valueLbl.Text = tostring(value)
                SafeCall(callback, value)
            end

            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            trackConn(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))
            trackConn(UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end))
            return frame
        end

        function Elements:CreateDropdown(text, options, default, callback)
            if type(options) ~= "table" or #options == 0 then return end
            local selected = default or options[1]
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
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
            dropBtn.Position = UDim2.new(1, -14, 0.5, 0)
            dropBtn.Text = selected .. "  ▾"
            dropBtn.TextColor3 = Theme.Text
            dropBtn.Font = Enum.Font.GothamSemibold
            dropBtn.TextSize = 12
            dropBtn.AutoButtonColor = false
            dropBtn.ZIndex = 4
            dropBtn.Parent = frame
            local dbg = Glass.Apply(dropBtn, { Level = "Bubble", Radius = 8, EdgeT = 0.88 })

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                dropBtn.TextColor3 = t.Text
            end)

            dropBtn.MouseEnter:Connect(function()
                TweenService:Create(dbg.Edge, TweenInfo.new(0.18), {
                    Color = Theme.Accent, Transparency = 0.5
                }):Play()
            end)
            dropBtn.MouseLeave:Connect(function()
                TweenService:Create(dbg.Edge, TweenInfo.new(0.18), {
                    Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88
                }):Play()
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
                Glass.Apply(list, { Level = "Panel", Radius = 14 })

                local l = Instance.new("UIListLayout")
                l.Padding = UDim.new(0, 2)
                l.Parent = list
                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 4)
                pad.PaddingBottom = UDim.new(0, 4)
                pad.Parent = list

                for _, opt in ipairs(options) do
                    local oBtn = Instance.new("TextButton")
                    oBtn.Size = UDim2.new(1, -8, 0, 30)
                    oBtn.Position = UDim2.new(0, 4, 0, 0)
                    oBtn.BackgroundTransparency = 1
                    oBtn.Text = opt
                    oBtn.TextColor3 = (opt == selected) and Theme.AccentHi or Theme.Text
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
                        oBtn.BackgroundTransparency = 0.75
                    end

                    oBtn.MouseEnter:Connect(function()
                        TweenService:Create(oBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = Theme.Accent,
                            BackgroundTransparency = 0.7,
                            TextColor3 = Theme.AccentHi
                        }):Play()
                    end)
                    oBtn.MouseLeave:Connect(function()
                        TweenService:Create(oBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = (opt == selected) and Theme.Accent or Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = (opt == selected) and 0.75 or 1,
                            TextColor3 = (opt == selected) and Theme.AccentHi or Theme.Text
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
                list.Size = UDim2.new(0, asz.X, 0, #options * 30 + 8)

                local ovId = pushOverlay()
                currentDropdown = { button = dropBtn, list = list, overlayId = ovId }
                local conn = Overlay.MouseButton1Click:Connect(closeDropdown)
                currentDropdown.conn = conn
            end)
            return frame
        end

        function Elements:CreateTextbox(text, placeholder, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 64)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 0, 20)
            lbl.Position = UDim2.new(0, 18, 0, 8)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local input = Instance.new("TextBox")
            input.Size = UDim2.new(1, -36, 0, 26)
            input.Position = UDim2.new(0, 18, 0, 30)
            input.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
            input.BackgroundTransparency = 0.3
            input.BorderSizePixel = 0
            input.Text = default or ""
            input.PlaceholderText = placeholder or ""
            input.PlaceholderColor3 = Theme.HintText
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
                s.Color = Color3.fromRGB(80, 80, 95)
                s.Transparency = 0.7
                s.Thickness = 1
                s.Parent = input
            end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                input.TextColor3 = t.Text
                input.PlaceholderColor3 = t.HintText
            end)

            input.Focused:Connect(function()
                local s = input:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.18), {
                        Color = Theme.Accent, Transparency = 0.3
                    }):Play()
                end
            end)
            input.FocusLost:Connect(function(enterPressed)
                local s = input:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(80, 80, 95), Transparency = 0.7
                    }):Play()
                end
                SafeCall(callback, input.Text, enterPressed)
            end)
            return frame
        end

        function Elements:CreateProgressBar(text, default)
            local val = math.clamp(default or 0, 0, 1)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 48)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -90, 0, 20)
            lbl.Position = UDim2.new(0, 18, 0, 6)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Theme.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 4
            lbl.Parent = frame

            local pct = Instance.new("TextLabel")
            pct.Size = UDim2.new(0, 60, 0, 20)
            pct.AnchorPoint = Vector2.new(1, 0)
            pct.Position = UDim2.new(1, -18, 0, 6)
            pct.BackgroundTransparency = 1
            pct.Text = math.floor(val * 100) .. "%"
            pct.TextColor3 = Theme.Accent
            pct.Font = Enum.Font.GothamBold
            pct.TextSize = 13
            pct.TextXAlignment = Enum.TextXAlignment.Right
            pct.ZIndex = 4
            pct.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -36, 0, 6)
            barBg.Position = UDim2.new(0, 18, 0, 34)
            barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
            barBg.BackgroundTransparency = 0.5
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
                pct.TextColor3 = t.Accent
                barFill.BackgroundColor3 = t.Accent
            end)

            local API = {}
            function API.Set(v)
                v = math.clamp(v, 0, 1)
                TweenService:Create(barFill,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Size = UDim2.new(v, 0, 1, 0) }):Play()
                pct.Text = math.floor(v * 100) .. "%"
            end
            return API
        end

        function Elements:CreateInfoPanel(info)
            info = info or {}
            local panel = Instance.new("Frame")
            panel.Size = UDim2.new(1, 0, 0, 92)
            panel.ZIndex = 3
            panel.Parent = TabPage
            Glass.Apply(panel, { Level = "Element", Radius = 14 })

            local avWrap = Instance.new("Frame")
            avWrap.Size = UDim2.new(0, 64, 0, 64)
            avWrap.Position = UDim2.new(0, 18, 0.5, -32)
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
                s.Transparency = 0.4
                s.Parent = avWrap
            end

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(1, -4, 1, -4)
            avatar.Position = UDim2.new(0, 2, 0, 2)
            avatar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
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
            infoFrame.Size = UDim2.new(1, -100, 1, -22)
            infoFrame.Position = UDim2.new(0, 94, 0, 12)
            infoFrame.BackgroundTransparency = 1
            infoFrame.ZIndex = 4
            infoFrame.Parent = panel
            do
                local l = Instance.new("UIListLayout")
                l.Padding = UDim.new(0, 3)
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

        function Elements:CreateColorPicker(text, defaultColor, callback)
            local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 46)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -20, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
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
            prev.Position = UDim2.new(1, -14, 0.5, 0)
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
                s.Transparency = 0.75
                s.Parent = prev
            end

            RegisterTheme(function(t) lbl.TextColor3 = t.Text end)

            local popup = nil
            local popupOverlayId = nil
            local popupOverlayConn = nil
            local popupConns = {}

            local function trackPopupConn(conn)
                table.insert(popupConns, conn)
            end

            local function closePopup()
                if popup then popup:Destroy(); popup = nil end
                for _, c in ipairs(popupConns) do
                    if c and c.Connected then pcall(function() c:Disconnect() end) end
                end
                popupConns = {}
                if popupOverlayConn then
                    popupOverlayConn:Disconnect(); popupOverlayConn = nil
                end
                if popupOverlayId then
                    popOverlay(popupOverlayId); popupOverlayId = nil
                end
            end

            prev.MouseButton1Click:Connect(function()
                if popup then closePopup() end

                popup = Instance.new("Frame")
                popup.Size = UDim2.new(0, 248, 0, 248)
                popup.ZIndex = 600
                popup.Parent = ScreenGui
                Glass.Apply(popup, { Level = "Panel", Radius = 16 })

                local ap = prev.AbsolutePosition
                local asz = prev.AbsoluteSize
                local px = math.clamp(ap.X - 170, 10, ScreenGui.AbsoluteSize.X - 258)
                local py = math.clamp(ap.Y + asz.Y + 8, 10, ScreenGui.AbsoluteSize.Y - 258)
                popup.Position = UDim2.new(0, px, 0, py)

                local bar = Instance.new("TextButton")
                bar.Size = UDim2.new(1, 0, 0, 22)
                bar.BackgroundTransparency = 1
                bar.Text = "· · ·"
                bar.TextColor3 = Theme.HintText
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
                    trackPopupConn(UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                            local d = input.Position - ds
                            popup.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
                        end
                    end))
                    trackPopupConn(UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                    end))
                end

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

                trackPopupConn(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag = false; hueDrag = false
                    end
                end))
                trackPopupConn(UserInputService.InputChanged:Connect(function(input)
                    if svDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updSV(input)
                    elseif hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updHue(input)
                    end
                end))

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
                closeB.MouseButton1Click:Connect(closePopup)

                popupOverlayId = pushOverlay()
                popupOverlayConn = Overlay.MouseButton1Click:Connect(closePopup)
            end)

            trackConn({ Disconnect = function() closePopup() end, Connected = true })
            return frame
        end

        function Elements:CreateKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, -20, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
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
            bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
            bindBtn.Text = currentKey.Name
            bindBtn.TextColor3 = Theme.Text
            bindBtn.Font = Enum.Font.GothamSemibold
            bindBtn.TextSize = 12
            bindBtn.AutoButtonColor = false
            bindBtn.ZIndex = 4
            bindBtn.Parent = frame
            local bbG = Glass.Apply(bindBtn, { Level = "Bubble", Radius = 8, EdgeT = 0.88 })

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                bindBtn.TextColor3 = t.Text
            end)

            local listening = false
            local listenConn = nil
            local triggerConn = nil

            local function bindKey(key)
                currentKey = key
                bindBtn.Text = key.Name
                if triggerConn then triggerConn:Disconnect() end
                triggerConn = trackConn(UserInputService.InputBegan:Connect(function(inp, gp)
                    if not gp and inp.KeyCode == currentKey then
                        SafeCall(callback, currentKey)
                    end
                end))
            end

            local function startListening()
                if listening then return end
                listening = true
                bindBtn.Text = "..."
                TweenService:Create(bbG.Edge, TweenInfo.new(0.18), {
                    Color = Theme.Accent, Transparency = 0.3
                }):Play()

                if listenConn then listenConn:Disconnect(); listenConn = nil end

                listenConn = trackConn(UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        if listenConn then listenConn:Disconnect(); listenConn = nil end
                        TweenService:Create(bbG.Edge, TweenInfo.new(0.18), {
                            Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88
                        }):Play()
                        bindKey(input.KeyCode)
                    end
                end))
            end

            bindBtn.MouseButton1Click:Connect(startListening)
            bindKey(currentKey)
            return frame
        end

        function Elements:CreateParagraph(text, lines)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, (lines or 2) * 22 + 22)
            frame.ZIndex = 3
            frame.Parent = TabPage
            local g = Glass.Apply(frame, { Level = "Element", Radius = 12, EdgeT = 0.94 })
            g.TintT = 0.35

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -36, 1, -22)
            lbl.Position = UDim2.new(0, 18, 0, 11)
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
    -- Destroy
    -- ═══════════════════════════════════════════════════════════════════
    function Window:Destroy()
        closeDropdown()
        disconnectAll()
        clearAllOverlays()
        themeRegistry = {}
        activeKeybinds = {}
        if islandUnsub then islandUnsub() end
        BlurController.Release()
        if Island then Island.Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
    end

    return Window
end

return Library
