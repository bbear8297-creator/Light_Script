--[[
    ═══════════════════════════════════════════════════════════
    LS Team UI Library · v1.0 正式版
    深空夜 · 灵动岛 · 功能计数器
    ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
-- 常量
-- ═══════════════════════════════════════════════════════════
local ICONS = {
    Close  = "rbxassetid://10709752508",
    ChevD  = "rbxassetid://10709753272",
    ChevR  = "rbxassetid://10709752405",
}

-- ═══════════════════════════════════════════════════════════
-- 工具
-- ═══════════════════════════════════════════════════════════
local function Measure(text, size, font)
    return TextService:GetTextSize(text, size, font, Vector2.new(2000, 2000))
end

local function Safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[LS_UI] " .. tostring(err)) end
end

-- 目标 GUI 层
local targetGui
do
    local ok, res = pcall(function() return gethui and gethui() end)
    targetGui = (ok and res) or CoreGui
end
if not pcall(function() return targetGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════
-- Blur 控制器
-- ═══════════════════════════════════════════════════════════
local function createBlurController()
    local state = { isOn = false, blur = nil }

    local function ensure()
        if not state.blur or not state.blur.Parent then
            local b = Instance.new("BlurEffect")
            b.Name = "LS_UI_Blur"
            b.Size = 0
            b.Parent = Lighting
            state.blur = b
        end
        return state.blur
    end

    local api = {}
    function api.SetOn(on)
        on = not not on
        if on == state.isOn then return end
        state.isOn = on
        local b = ensure()
        if on then
            TweenService:Create(b, TweenInfo.new(0.4), { Size = 8 }):Play()
        else
            local t = TweenService:Create(b, TweenInfo.new(0.35), { Size = 0 })
            t:Play()
            t.Completed:Connect(function()
                if not state.isOn and b.Parent then
                    b:Destroy()
                    if state.blur == b then state.blur = nil end
                end
            end)
        end
    end
    function api.Destroy()
        state.isOn = false
        if state.blur and state.blur.Parent then state.blur:Destroy() end
        state.blur = nil
    end
    return api
end

-- ═══════════════════════════════════════════════════════════
-- 玻璃层次
-- ═══════════════════════════════════════════════════════════
local Glass = {}
Glass.Levels = {
    Window  = { Tint = Color3.fromRGB(13, 13, 17), Radius = 26, EdgeT = 0.94 },
    Panel   = { Tint = Color3.fromRGB(20, 20, 26), Radius = 20, EdgeT = 0.96 },
    Element = { Tint = Color3.fromRGB(28, 28, 36), Radius = 14, EdgeT = 0.96 },
    Bubble  = { Tint = Color3.fromRGB(38, 38, 48), Radius = 12, EdgeT = 0.94 },
}

function Glass.Apply(parent, opts)
    opts = opts or {}
    local lv = Glass.Levels[opts.Level or "Element"]
    parent.BackgroundColor3 = opts.Tint or lv.Tint
    parent.BackgroundTransparency = 0
    parent.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, opts.Radius or lv.Radius)
    corner.Parent = parent

    local edge = Instance.new("UIStroke")
    edge.Color = Color3.fromRGB(255, 255, 255)
    edge.Transparency = opts.EdgeT or lv.EdgeT
    edge.Thickness = 1
    edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    edge.Parent = parent

    return { Corner = corner, Edge = edge }
end

-- ═══════════════════════════════════════════════════════════
-- 主题
-- ═══════════════════════════════════════════════════════════
Library.Themes = {
    DeepSpace = {
        Accent = Color3.fromRGB(10, 132, 255), AccentHi = Color3.fromRGB(120, 190, 255),
        Text = Color3.fromRGB(240, 240, 245), SubText = Color3.fromRGB(140, 140, 155),
        HintText = Color3.fromRGB(85, 85, 100), ToggleOff = Color3.fromRGB(55, 55, 68),
        Success = Color3.fromRGB(48, 209, 88), Warning = Color3.fromRGB(255, 214, 10),
        Danger = Color3.fromRGB(255, 69, 58),
    },
    Nebula = {
        Accent = Color3.fromRGB(160, 108, 255), AccentHi = Color3.fromRGB(210, 175, 255),
        Text = Color3.fromRGB(245, 240, 255), SubText = Color3.fromRGB(155, 145, 175),
        HintText = Color3.fromRGB(95, 85, 115), ToggleOff = Color3.fromRGB(60, 55, 75),
        Success = Color3.fromRGB(80, 220, 160), Warning = Color3.fromRGB(255, 200, 80),
        Danger = Color3.fromRGB(255, 100, 110),
    },
    Aurora = {
        Accent = Color3.fromRGB(48, 220, 200), AccentHi = Color3.fromRGB(130, 245, 230),
        Text = Color3.fromRGB(235, 250, 250), SubText = Color3.fromRGB(140, 180, 180),
        HintText = Color3.fromRGB(75, 115, 115), ToggleOff = Color3.fromRGB(50, 70, 70),
        Success = Color3.fromRGB(80, 230, 160), Warning = Color3.fromRGB(255, 200, 80),
        Danger = Color3.fromRGB(255, 110, 100),
    },
    Ember = {
        Accent = Color3.fromRGB(255, 140, 60), AccentHi = Color3.fromRGB(255, 190, 130),
        Text = Color3.fromRGB(255, 245, 235), SubText = Color3.fromRGB(200, 170, 145),
        HintText = Color3.fromRGB(125, 95, 75), ToggleOff = Color3.fromRGB(75, 60, 50),
        Success = Color3.fromRGB(150, 220, 120), Warning = Color3.fromRGB(255, 210, 100),
        Danger = Color3.fromRGB(255, 100, 90),
    },
}

-- ═══════════════════════════════════════════════════════════
-- 功能计数器
-- ═══════════════════════════════════════════════════════════
local FeatureCounter = {}
do
    local features, listeners, counter = {}, {}, 0

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

    function FeatureCounter.Count()
        local n = 0
        for _, f in pairs(features) do if f.active then n = n + 1 end end
        return n
    end

    function FeatureCounter.Notify()
        local count = FeatureCounter.Count()
        for _, fn in ipairs(listeners) do pcall(fn, count) end
    end

    function FeatureCounter.Subscribe(fn)
        table.insert(listeners, fn)
        pcall(fn, FeatureCounter.Count())
        return function()
            for i, f in ipairs(listeners) do
                if f == fn then table.remove(listeners, i); return end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- 灵动岛
-- ═══════════════════════════════════════════════════════════
local function CreateDynamicIsland(parent, theme, callbacks)
    callbacks = callbacks or {}
    local H, RADIUS, PAD, AVATAR = 40, 20, 10, 28

    local Island = Instance.new("TextButton")
    Island.Name = "DynamicIsland"
    Island.AnchorPoint = Vector2.new(0.5, 0)
    Island.Position = UDim2.new(0.5, 0, 0, 12)
    Island.Size = UDim2.new(0, 200, 0, H)
    Island.Text = ""
    Island.AutoButtonColor = false
    Island.ClipsDescendants = true
    Island.ZIndex = 220
    Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Island.BorderSizePixel = 0
    Island.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, RADIUS)
    corner.Parent = Island

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.9
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Island

    -- 头像
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, AVATAR, 0, AVATAR)
    avatar.Position = UDim2.new(0, PAD, 0.5, -AVATAR / 2)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    avatar.ZIndex = 4
    avatar.Parent = Island
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = avatar
        local s = Instance.new("UIStroke")
        s.Color = theme.Success
        s.Thickness = 1.5
        s.Transparency = 0.3
        s.Parent = avatar
    end

    task.spawn(function()
        pcall(function()
            local url = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            avatar.Image = url
        end)
    end)

    -- 中间状态文字
    local centerLabel = Instance.new("TextLabel")
    centerLabel.Position = UDim2.new(0, PAD + AVATAR + 10, 0, 0)
    centerLabel.Size = UDim2.new(0, 100, 1, 0)
    centerLabel.BackgroundTransparency = 1
    centerLabel.Text = "待机"
    centerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    centerLabel.Font = Enum.Font.GothamSemibold
    centerLabel.TextSize = 13
    centerLabel.TextXAlignment = Enum.TextXAlignment.Left
    centerLabel.ZIndex = 4
    centerLabel.Parent = Island

    -- 右侧容器（横向：dot + ping + fps）
    local rightHolder = Instance.new("Frame")
    rightHolder.AnchorPoint = Vector2.new(1, 0)
    rightHolder.Position = UDim2.new(1, -PAD, 0, 0)
    rightHolder.Size = UDim2.new(0, 120, 1, 0)
    rightHolder.BackgroundTransparency = 1
    rightHolder.ZIndex = 3
    rightHolder.Parent = Island

    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.Padding = UDim.new(0, 6)
    rl.SortOrder = Enum.SortOrder.LayoutOrder
    rl.Parent = rightHolder

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 7, 0, 7)
    statusDot.BackgroundColor3 = theme.Success
    statusDot.BorderSizePixel = 0
    statusDot.LayoutOrder = 0
    statusDot.ZIndex = 4
    statusDot.Parent = rightHolder
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = statusDot
    end

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0, 42, 1, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "0ms"
    pingLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    pingLabel.Font = Enum.Font.GothamMedium
    pingLabel.TextSize = 12
    pingLabel.LayoutOrder = 1
    pingLabel.ZIndex = 4
    pingLabel.Parent = rightHolder

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 44, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "0fps"
    fpsLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    fpsLabel.Font = Enum.Font.GothamMedium
    fpsLabel.TextSize = 12
    fpsLabel.LayoutOrder = 2
    fpsLabel.ZIndex = 4
    fpsLabel.Parent = rightHolder

    -- 宽度自适应
    local function updateWidth(animate)
        local centerW = Measure(centerLabel.Text, 13, Enum.Font.GothamSemibold).X * 1.15 + 8
        local pingW = Measure(pingLabel.Text, 12, Enum.Font.GothamMedium).X + 6
        local fpsW  = Measure(fpsLabel.Text, 12, Enum.Font.GothamMedium).X + 6

        local extraW = 0
        for _, child in ipairs(rightHolder:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout")
            and child ~= statusDot and child ~= pingLabel and child ~= fpsLabel
            and child.Visible then
                extraW = extraW + child.Size.X.Offset + 6
            end
        end

        local rightW = 7 + 6 + pingW + 6 + fpsW + extraW
        centerLabel.Size = UDim2.new(0, centerW, 1, 0)
        rightHolder.Size = UDim2.new(0, rightW, 1, 0)

        local totalW = PAD + AVATAR + 10 + centerW + 12 + rightW + PAD
        if animate then
            TweenService:Create(Island,
                TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, totalW, 0, H) }):Play()
        else
            Island.Size = UDim2.new(0, totalW, 0, H)
        end
    end

    -- ping/fps 刷新
    task.spawn(function()
        local frameCount, lastTime = 0, tick()
        local conn = RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)
        while Island.Parent do
            task.wait(1)
            local now = tick()
            local elapsed = math.max(now - lastTime, 0.001)
            fpsLabel.Text = math.floor(frameCount / elapsed) .. "fps"
            frameCount, lastTime = 0, now

            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            pingLabel.Text = ping .. "ms"
            updateWidth(true)
        end
        if conn then conn:Disconnect() end
    end)

    -- 点击
    local pressScale = Instance.new("UIScale")
    pressScale.Scale = 1
    pressScale.Parent = Island

    Island.MouseButton1Click:Connect(function()
        TweenService:Create(pressScale,
            TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            if not pressScale.Parent then return end
            TweenService:Create(pressScale,
                TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Scale = 1 }):Play()
        end)
        if callbacks.OnClick then Safe(callbacks.OnClick) end
    end)

    local API = { Frame = Island }
    function API.SetStatus(text) centerLabel.Text = text; updateWidth(true) end
    API.SetTitle = API.SetStatus

    function API.SetAvatar(id)
        if type(id) == "number" then
            task.spawn(function()
                pcall(function()
                    avatar.Image = Players:GetUserThumbnailAsync(id,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
            end)
        else
            avatar.Image = tostring(id)
        end
    end

    function API.SetStatusDot(color) statusDot.BackgroundColor3 = color end
    function API.SetAccent(color)
        local s = avatar:FindFirstChildOfClass("UIStroke")
        if s then s.Color = color end
    end
    API.SetDotColor = API.SetAccent

    function API.AddWidget(side, obj)
        if not obj then return end
        if side == "right" then obj.Parent = rightHolder end
        updateWidth(true)
        return obj
    end

    function API.GetZones() return { Right = rightHolder } end
    function API.Destroy() if Island.Parent then Island:Destroy() end end

    updateWidth(false)
    return API
end

-- ═══════════════════════════════════════════════════════════
-- CreateWindow
-- ═══════════════════════════════════════════════════════════
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

    local blurCtrl = createBlurController()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LS_UI_" .. tostring(math.random(100000, 999999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = false
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = targetGui

    local globalConns = {}
    local function track(conn) table.insert(globalConns, conn); return conn end
    local function disconnectAll()
        for _, c in ipairs(globalConns) do
            if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        end
        globalConns = {}
    end

    local themeRegistry, themeCounter = {}, 0
    local function RegisterTheme(fn)
        themeCounter = themeCounter + 1
        themeRegistry[themeCounter] = fn
        pcall(fn, Theme)
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

    local overlayRefs, overlayCounter = {}, 0
    local function pushOverlay()
        overlayCounter = overlayCounter + 1
        overlayRefs[overlayCounter] = true
        Overlay.Visible = true
        Overlay.Active = true
        return overlayCounter
    end
    local function popOverlay(id)
        if id then overlayRefs[id] = nil end
        if next(overlayRefs) == nil then
            Overlay.Visible = false
            Overlay.Active = false
        end
    end
    local function clearOverlays()
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
    NotifContainer.ZIndex = 400
    NotifContainer.Parent = ScreenGui
    do
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Vertical   -- ★ 关键
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, 8)
        l.Parent = NotifContainer
    end
    local notifOrder = 0

    local MainFrame, MainScale, Island
    local isMainOpen, isMainAnimating = false, false

    local function showMain()
        if isMainOpen or isMainAnimating then return end
        isMainOpen, isMainAnimating = true, true
        MainFrame.Visible = true
        MainScale.Scale = 0
        local t = TweenService:Create(MainScale,
            TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 })
        t:Play()
        blurCtrl.SetOn(true)
        t.Completed:Connect(function() isMainAnimating = false end)
    end

    local function hideMain()
        if not isMainOpen or isMainAnimating then return end
        isMainOpen, isMainAnimating = false, true
        blurCtrl.SetOn(false)
        local t = TweenService:Create(MainScale,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Scale = 0 })
        t:Play()
        t.Completed:Connect(function()
            if not isMainOpen then MainFrame.Visible = false end
            isMainAnimating = false
        end)
    end

    local function toggleMain()
        if isMainOpen then hideMain() else showMain() end
    end

    -- 灵动岛
    Island = CreateDynamicIsland(ScreenGui, Theme, {
        OnClick = function() toggleMain() end,
    })

    local islandUnsub = FeatureCounter.Subscribe(function(count)
        if count == 0 then
            Island.SetStatus("待机")
            Island.SetStatusDot(Theme.HintText)
        else
            Island.SetStatus("运行中 · " .. count)
            Island.SetStatusDot(Theme.Success)
        end
    end)

    -- 主窗
    MainFrame = Instance.new("Frame")
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
    MainFrame.Size = UDim2.new(0.92, 0, 0.78, 0)
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.ZIndex = 100
    MainFrame.Parent = ScreenGui
    Glass.Apply(MainFrame, { Level = "Window" })

    MainScale = Instance.new("UIScale")
    MainScale.Scale = 0
    MainScale.Parent = MainFrame

    local sizeC = Instance.new("UISizeConstraint")
    sizeC.MaxSize = Vector2.new(720, 470)
    sizeC.MinSize = Vector2.new(340, 300)
    sizeC.Parent = MainFrame

    -- 顶部栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 52)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 2
    TopBar.Parent = MainFrame

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Size = UDim2.new(1, -120, 1, 0)
    TopTitle.Position = UDim2.new(0, 24, 0, 0)
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
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -18, 0.5, 0)
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = TopBar
    Glass.Apply(closeBtn, { Level = "Bubble", Radius = 15 })

    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Size = UDim2.new(0, 14, 0, 14)
    closeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = ICONS.Close
    closeIcon.ImageColor3 = Theme.SubText
    closeIcon.ZIndex = 4
    closeIcon.Parent = closeBtn

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Theme.Danger
        }):Play()
        TweenService:Create(closeIcon, TweenInfo.new(0.18), {
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        }):Play()
        TweenService:Create(closeIcon, TweenInfo.new(0.18), {
            ImageColor3 = Theme.SubText
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(hideMain)

    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -32, 0, 1)
    topDivider.Position = UDim2.new(0, 16, 1, 0)
    topDivider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = 3
    topDivider.Parent = TopBar

    RegisterTheme(function(t)
        TopTitle.TextColor3 = t.Text
        closeIcon.ImageColor3 = t.SubText
    end)

    -- 拖动
    do
        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, MainFrame.Position
            end
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0.30, 0, 1, -52)
    Sidebar.Position = UDim2.new(0, 0, 0, 52)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ZIndex = 2
    Sidebar.Parent = MainFrame

    local sidebarGlass = Instance.new("Frame")
    sidebarGlass.Size = UDim2.new(1, -16, 1, -16)
    sidebarGlass.Position = UDim2.new(0, 8, 0, 8)
    sidebarGlass.ZIndex = 2
    sidebarGlass.Parent = Sidebar
    Glass.Apply(sidebarGlass, { Level = "Panel" })

    local TabContainer = Instance.new("ScrollingFrame")
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
    tabLayout.FillDirection = Enum.FillDirection.Vertical   -- ★ 关键
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = TabContainer
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- 内容区
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(0.70, 0, 1, -52)
    ContentContainer.Position = UDim2.new(0.30, 0, 0, 52)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ZIndex = 2
    ContentContainer.Parent = MainFrame

    -- ═══════════════════════════════════════════════════════
    -- 通知
    -- ═══════════════════════════════════════════════════════
    local function pushNotification(title, message, duration, opts)
        title, message, duration = title or "通知", message or "", duration or 4
        opts = opts or {}
        local kind = opts.Type or "info"

        notifOrder = notifOrder + 1
        local notif = Instance.new("Frame")
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

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -28, 0, 20)
        titleLbl.Position = UDim2.new(0, 20, 0, 12)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = Theme.Text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 3
        titleLbl.Parent = notif

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -28, 0, 0)
        msgLbl.Position = UDim2.new(0, 20, 0, 36)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text = message
        msgLbl.TextColor3 = Theme.SubText
        msgLbl.Font = Enum.Font.Gotham
        msgLbl.TextSize = 12
        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
        msgLbl.TextWrapped = true
        msgLbl.ZIndex = 3
        msgLbl.Parent = notif

        local textH = TextService:GetTextSize(message, 12, Enum.Font.Gotham,
            Vector2.new(252, 2000)).Y
        local totalH = math.max(66, 36 + textH + 18)
        msgLbl.Size = UDim2.new(1, -28, 0, textH)
        notif.Size = UDim2.new(1, 0, 0, totalH)

        local sc = Instance.new("UIScale")
        sc.Scale = 0.85
        sc.Parent = notif
        notif.Position = UDim2.new(1, 40, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = UDim2.new(0, 0, 0, 0) }):Play()
        TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()

        task.delay(duration, function()
            if not notif.Parent then return end
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                { Position = UDim2.new(1, 40, 0, 0) }):Play()
            TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0.85 }):Play()
            task.wait(0.32)
            if notif.Parent then notif:Destroy() end
        end)
        return notif
    end

    -- ═══════════════════════════════════════════════════════
    -- Window 对象
    -- ═══════════════════════════════════════════════════════
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
        closeDropdown(); loadTheme(name); RunTheme()
    end

    function Window:SetAccentColor(color)
        local h, s, v = color:ToHSV()
        Theme.Accent = color
        Theme.AccentHi = Color3.fromHSV(h, math.max(s - 0.15, 0), math.min(v + 0.2, 1))
        RunTheme()
    end

    function Window:Notify(title, message, duration, imageId)
        local opts = {}
        if type(imageId) == "string" then opts.Image = imageId end
        if type(imageId) == "table" then
            opts.Type = imageId.Type; opts.Image = imageId.Image
        end
        return pushNotification(title, message, duration, opts)
    end
    function Window:Toast(m, d) return pushNotification("提示", m, d or 2.5, { Type = "info" }) end
    function Window:Success(t, m, d) return pushNotification(t, m, d or 3, { Type = "success" }) end
    function Window:Warning(t, m, d) return pushNotification(t, m, d or 3, { Type = "warning" }) end
    function Window:Error(t, m, d) return pushNotification(t, m, d or 4, { Type = "error" }) end

    function Window:ShowMain() showMain() end
    function Window:HideMain() hideMain() end
    function Window:ToggleMain() toggleMain() end
    function Window:IsMainOpen() return isMainOpen end

    function Window:GetIsland() return Island end
    function Window:SetIslandStatus(t) Island.SetStatus(t) end
    function Window:SetIslandTitle(t) Island.SetStatus(t) end
    function Window:SetIslandDot(c) Island.SetStatusDot(c) end
    function Window:SetIslandAvatar(i) Island.SetAvatar(i) end

    function Window:RegisterFeature(n) return FeatureCounter.Register(n) end
    function Window:SetFeatureActive(id, a) FeatureCounter.SetActive(id, a) end
    function Window:GetActiveFeatureCount() return FeatureCounter.Count() end

    -- ═══════════════════════════════════════════════════════
    -- CreateTab
    -- ═══════════════════════════════════════════════════════
    function Window:CreateTab(TabName, iconId, iconOptions)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName
        TabButton.Size = UDim2.new(1, -16, 0, 38)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.ZIndex = 4
        TabButton.Parent = TabContainer
        Glass.Apply(TabButton, { Level = "Bubble", EdgeT = 1 })

        local tbScale = Instance.new("UIScale")
        tbScale.Scale = 1
        tbScale.Parent = TabButton

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -24, 1, 0)
        holder.Position = UDim2.new(0, 14, 0, 0)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 5
        holder.Parent = TabButton
        do
            local l = Instance.new("UIListLayout")
            l.FillDirection = Enum.FillDirection.Horizontal   -- ★ icon + text 横排
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
            local sz = UDim2.new(0, 16, 0, 16)
            if iconOptions and iconOptions.Size then sz = iconOptions.Size end
            icon.Size = sz
            icon.Image = iconId
            icon.BackgroundTransparency = 1
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
                tabText.TextColor3 = t.AccentHi
                TabButton.BackgroundColor3 = t.Accent
                TabButton.BackgroundTransparency = 0.82
            else
                tabText.TextColor3 = t.SubText
                TabButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
                TabButton.BackgroundTransparency = 1
            end
        end
        RegisterTheme(apply)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, -24, 1, -24)
        TabPage.Position = UDim2.new(0, 12, 0, 12)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.Visible = firstTab
        TabPage.ZIndex = 2
        TabPage.Parent = ContentContainer

        RegisterTheme(function(t) TabPage.ScrollBarImageColor3 = t.Accent end)

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.FillDirection = Enum.FillDirection.Vertical   -- ★ 关键
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = TabPage
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 12)
        end)

        local function setSelected(v) isSelected = v; apply(Theme) end
        table.insert(Tabs, { Button = TabButton, Page = TabPage, setSelected = setSelected })

        if firstTab then
            firstTab = false
            setSelected(true)
        end

        TabButton.MouseEnter:Connect(function()
            if not isSelected then
                TweenService:Create(TabButton, TweenInfo.new(0.18), {
                    BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0.3
                }):Play()
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

        -- ═══════════════════════════════════════════════════
        -- Elements
        -- ═══════════════════════════════════════════════════
        local Elements = {}

        function Elements:CreateLabel(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

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
            RegisterTheme(function(t) lbl.TextColor3 = t.SubText end)
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
            line.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            line.BorderSizePixel = 0
            line.ZIndex = 4
            line.Parent = frame
            return frame
        end

        function Elements:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 3
            btn.Parent = TabPage
            Glass.Apply(btn, { Level = "Element" })

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
            arrow.Text = ">"
            arrow.TextColor3 = Theme.HintText
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 18
            arrow.ZIndex = 4
            arrow.Parent = btn

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                arrow.TextColor3 = t.HintText
                btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
            end)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18),
                    { BackgroundColor3 = Color3.fromRGB(42, 42, 54) }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18),
                    { TextColor3 = Theme.AccentHi }):Play()
                TweenService:Create(arrow, TweenInfo.new(0.18),
                    { TextColor3 = Theme.Accent }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18),
                    { BackgroundColor3 = Color3.fromRGB(28, 28, 36) }):Play()
                TweenService:Create(lbl, TweenInfo.new(0.18),
                    { TextColor3 = Theme.Text }):Play()
                TweenService:Create(arrow, TweenInfo.new(0.18),
                    { TextColor3 = Theme.HintText }):Play()
            end)
            btn.MouseButton1Click:Connect(function() Safe(callback) end)
            return btn
        end

        function Elements:CreateToggle(text, default, callback, opts)
            opts = opts or {}
            local toggled = default or false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

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
                s.Transparency = 0.85
                s.Thickness = 1
                s.Parent = knob
            end

            local featureId = opts.RegisterFeature ~= false
                and FeatureCounter.Register(opts.FeatureName or text) or nil
            if featureId and toggled then FeatureCounter.SetActive(featureId, true) end

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                track.BackgroundColor3 = toggled and t.Accent or t.ToggleOff
                dot.BackgroundColor3 = toggled and t.Success or t.ToggleOff
            end)

            local function fire()
                toggled = not toggled
                TweenService:Create(track, TweenInfo.new(0.22, Enum.EasingStyle.Quart),
                    { BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff }):Play()
                TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart),
                    { Position = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }):Play()
                TweenService:Create(dot, TweenInfo.new(0.22),
                    { BackgroundColor3 = toggled and Theme.Success or Theme.ToggleOff }):Play()
                if featureId then FeatureCounter.SetActive(featureId, toggled) end
                Safe(callback, toggled)
            end
            track.MouseButton1Click:Connect(fire)

            return {
                Frame = frame,
                Set = function(v) if toggled ~= v then fire() end end,
                Get = function() return toggled end,
                GetFeatureId = function() return featureId end,
            }
        end

        function Elements:CreateSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 64)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -100, 0, 22)
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
            barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
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
                Safe(callback, value)
            end

            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; update(input)
                end
            end)
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))
            track(UserInputService.InputChanged:Connect(function(input)
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
            Glass.Apply(frame, { Level = "Element" })

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
            dropBtn.Text = selected
            dropBtn.TextColor3 = Theme.Text
            dropBtn.Font = Enum.Font.GothamSemibold
            dropBtn.TextSize = 12
            dropBtn.AutoButtonColor = false
            dropBtn.ZIndex = 4
            dropBtn.Parent = frame
            Glass.Apply(dropBtn, { Level = "Bubble" })

            local chevron = Instance.new("Frame")
            chevron.Size = UDim2.new(0, 8, 0, 5)
            chevron.AnchorPoint = Vector2.new(1, 0.5)
            chevron.Position = UDim2.new(1, -8, 0.5, 0)
            chevron.BackgroundTransparency = 1
            chevron.ZIndex = 5
            chevron.Parent = dropBtn

            local ch1 = Instance.new("Frame")
            ch1.Size = UDim2.new(0, 5, 0, 1.5)
            ch1.Position = UDim2.new(0, 0.5, 0, 0)
            ch1.BackgroundColor3 = Theme.HintText
            ch1.BorderSizePixel = 0
            ch1.Rotation = 40
            ch1.ZIndex = 6
            ch1.Parent = chevron

            local ch2 = Instance.new("Frame")
            ch2.Size = UDim2.new(0, 5, 0, 1.5)
            ch2.Position = UDim2.new(0, 3.5, 0, 0)
            ch2.BackgroundColor3 = Theme.HintText
            ch2.BorderSizePixel = 0
            ch2.Rotation = -40
            ch2.ZIndex = 6
            ch2.Parent = chevron

            local pad = Instance.new("UIPadding")
            pad.PaddingRight = UDim.new(0, 18)
            pad.Parent = dropBtn

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                dropBtn.TextColor3 = t.Text
                ch1.BackgroundColor3 = t.HintText
                ch2.BackgroundColor3 = t.HintText
            end)

            dropBtn.MouseButton1Click:Connect(function()
                if currentDropdown and currentDropdown.button == dropBtn then
                    closeDropdown(); return
                end
                closeDropdown()

                local list = Instance.new("Frame")
                list.ZIndex = 501
                list.Parent = ScreenGui
                Glass.Apply(list, { Level = "Panel", Radius = 14 })

                local l = Instance.new("UIListLayout")
                l.FillDirection = Enum.FillDirection.Vertical   -- ★ 关键
                l.Padding = UDim.new(0, 2)
                l.Parent = list
                local p = Instance.new("UIPadding")
                p.PaddingTop = UDim.new(0, 4)
                p.PaddingBottom = UDim.new(0, 4)
                p.Parent = list

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
                        dropBtn.Text = selected
                        Safe(callback, selected)
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
            Glass.Apply(frame, { Level = "Element" })

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
            input.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
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
                s.Color = Color3.fromRGB(60, 60, 75)
                s.Transparency = 0.4
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
                    TweenService:Create(s, TweenInfo.new(0.18),
                        { Color = Theme.Accent, Transparency = 0.2 }):Play()
                end
            end)
            input.FocusLost:Connect(function(enterPressed)
                local s = input:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.18),
                        { Color = Color3.fromRGB(60, 60, 75), Transparency = 0.4 }):Play()
                end
                Safe(callback, input.Text, enterPressed)
            end)
            return frame
        end

        function Elements:CreateProgressBar(text, default)
            local val = math.clamp(default or 0, 0, 1)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 48)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

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
            barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
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

            return {
                Set = function(v)
                    v = math.clamp(v, 0, 1)
                    TweenService:Create(barFill,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                        { Size = UDim2.new(v, 0, 1, 0) }):Play()
                    pct.Text = math.floor(v * 100) .. "%"
                end,
            }
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
            avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
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
                    avatar.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
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
                l.FillDirection = Enum.FillDirection.Vertical   -- ★ 关键
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

            panel.SetServerInfo = function(text) sL.Text = text end
            panel.SetExecutorInfo = function(text) eL.Text = text end
            panel.SetPlayerName = function(text) nL.Text = text end

            return panel
        end

        function Elements:CreateImage(imageId, sizeX, sizeY)
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, sizeX or 100, 0, sizeY or 100)
            img.Image = imageId or ""
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 3
            img.Parent = TabPage
            Glass.Apply(img, { Level = "Element" })
            return img
        end

        function Elements:CreateColorPicker(text, defaultColor, callback)
            local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 46)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

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
                s.Transparency = 0.8
                s.Parent = prev
            end

            RegisterTheme(function(t) lbl.TextColor3 = t.Text end)

            local popup, popupOverlayId, popupOverlayConn
            local popupConns = {}
            local function trackP(conn) table.insert(popupConns, conn) end

            local function closePopup()
                if popup then popup:Destroy(); popup = nil end
                for _, c in ipairs(popupConns) do
                    if c and c.Connected then pcall(function() c:Disconnect() end) end
                end
                popupConns = {}
                if popupOverlayConn then popupOverlayConn:Disconnect(); popupOverlayConn = nil end
                if popupOverlayId then popOverlay(popupOverlayId); popupOverlayId = nil end
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
                popup.Position = UDim2.new(0,
                    math.clamp(ap.X - 170, 10, ScreenGui.AbsoluteSize.X - 258),
                    0,
                    math.clamp(ap.Y + asz.Y + 8, 10, ScreenGui.AbsoluteSize.Y - 258))

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
                            dragging, ds, sp = true, input.Position, popup.Position
                        end
                    end)
                    trackP(UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                            local d = input.Position - ds
                            popup.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                sp.Y.Scale, sp.Y.Offset + d.Y)
                        end
                    end))
                    trackP(UserInputService.InputEnded:Connect(function(input)
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
                        NumberSequenceKeypoint.new(1, 1)
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
                        NumberSequenceKeypoint.new(1, 0)
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
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
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
                    Safe(callback, currentColor)
                end
                local function updSV(input)
                    local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    s, v = rx, 1 - ry
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

                trackP(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        svDrag, hueDrag = false, false
                    end
                end))
                trackP(UserInputService.InputChanged:Connect(function(input)
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

            track({ Disconnect = function() closePopup() end, Connected = true })
            return frame
        end

        function Elements:CreateKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.ZIndex = 3
            frame.Parent = TabPage
            Glass.Apply(frame, { Level = "Element" })

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
            Glass.Apply(bindBtn, { Level = "Bubble" })

            RegisterTheme(function(t)
                lbl.TextColor3 = t.Text
                bindBtn.TextColor3 = t.Text
            end)

            local listening = false
            local listenConn, triggerConn

            local function bindKey(key)
                currentKey = key
                bindBtn.Text = key.Name
                if triggerConn then triggerConn:Disconnect() end
                triggerConn = track(UserInputService.InputBegan:Connect(function(inp, gp)
                    if not gp and inp.KeyCode == currentKey then
                        Safe(callback, currentKey)
                    end
                end))
            end

            local function startListening()
                if listening then return end
                listening = true
                bindBtn.Text = "..."
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                listenConn = track(UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        if listenConn then listenConn:Disconnect(); listenConn = nil end
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
            Glass.Apply(frame, { Level = "Element" })

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

    -- ═══════════════════════════════════════════════════════
    -- Destroy
    -- ═══════════════════════════════════════════════════════
    function Window:Destroy()
        isMainOpen, isMainAnimating = false, false
        closeDropdown()
        disconnectAll()
        clearOverlays()
        themeRegistry = {}
        activeKeybinds = {}
        if islandUnsub then islandUnsub() end
        blurCtrl.Destroy()
        if Island then Island.Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
    end

    return Window
end

return Library
