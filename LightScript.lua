--[[
    ═══════════════════════════════════════════════════════════════
    LightScript · v1.0
    开场动画 → 灵动岛 → 功能面板
    ═══════════════════════════════════════════════════════════════
    执行：
        loadstring(readfile("LightScript.lua"))()
    依赖：同目录 LS_UI.lua（LS 团队 UI 库）
    ═══════════════════════════════════════════════════════════════
]]

local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════
-- LightScript 主对象
-- ══════════════════════════════════════════════════════════
local LightScript = { closed = false }

-- ══════════════════════════════════════════════════════════
-- 0. 防重复加载
-- ══════════════════════════════════════════════════════════
if getgenv and getgenv().LightScript then
    pcall(function() getgenv().LightScript:Shutdown() end)
    getgenv().LightScript = nil
end

-- ══════════════════════════════════════════════════════════
-- 1. 载入 UI 库
-- ══════════════════════════════════════════════════════════
local function readSource()
    local ok, src = pcall(readfile, "LS_UI.lua")
    if ok and type(src) == "string" and #src > 1000 then return src, "local" end

    local url = "https://raw.githubusercontent.com/bbear8297-creator/Light_Script/main/ui_APP.Lua"
    local ok2, body = pcall(function()
        if type(request) == "function" then
            return request({ Url = url, Method = "GET" }).Body
        end
        return game:HttpGet(url)
    end)
    if ok2 and type(body) == "string" and #body > 1000 then return body, "remote" end
    return nil
end

local src, srcFrom = readSource()
if not src then
    warn("[LightScript] 找不到 LS_UI.lua，也没有网络")
    return
end

local chunk = loadstring(src, "=LS_UI")
if not chunk then
    warn("[LightScript] LS_UI.lua 编译失败")
    return
end
local okLib, Library = pcall(chunk)
if not okLib then
    warn("[LightScript] LS_UI 载入失败: " .. tostring(Library))
    return
end

local THEME  = "Nebula"
local Theme  = Library.Themes[THEME] or Library.Themes.DeepSpace
local ACCENT = Theme.Accent

-- ══════════════════════════════════════════════════════════
-- 2. 开场：全屏启动页 + 进度条
-- ══════════════════════════════════════════════════════════
local function buildBoot()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "LS_Boot"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.ResetOnSpawn = false
    gui.Parent = parent

    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(7, 7, 10)
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = gui

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(0, 620, 0, 620)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0.5, -40)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://1316045217"
    glow.ImageColor3 = ACCENT
    glow.ImageTransparency = 0.82
    glow.ZIndex = 2
    glow.Parent = bg

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 46)
    logo.Position = UDim2.new(0, 0, 0.5, -56)
    logo.BackgroundTransparency = 1
    logo.Text = "LightScript"
    logo.TextColor3 = Color3.fromRGB(245, 245, 250)
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 34
    logo.ZIndex = 3
    logo.Parent = bg

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACCENT),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, ACCENT),
    })
    grad.Parent = logo

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0.5, -6)
    sub.BackgroundTransparency = 1
    sub.Text = "LS TEAM  ·  v1.0"
    sub.TextColor3 = Color3.fromRGB(120, 120, 135)
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 12
    sub.ZIndex = 3
    sub.Parent = bg

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 280, 0, 4)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.5, 34)
    track.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    track.BorderSizePixel = 0
    track.ZIndex = 3
    track.Parent = bg
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = track
    end

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.ZIndex = 4
    fill.Parent = track
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = fill
        local s = Instance.new("UIStroke")
        s.Color = ACCENT
        s.Thickness = 1
        s.Transparency = 0.35
        s.Parent = fill
    end

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 16)
    status.Position = UDim2.new(0, 0, 0.5, 50)
    status.BackgroundTransparency = 1
    status.Text = "初始化…"
    status.TextColor3 = Color3.fromRGB(130, 130, 145)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.ZIndex = 3
    status.Parent = bg

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.new(0, 60, 0, 16)
    pct.AnchorPoint = Vector2.new(1, 0.5)
    pct.Position = UDim2.new(0.5, 148, 0.5, 34)
    pct.BackgroundTransparency = 1
    pct.Text = "0%"
    pct.TextColor3 = ACCENT
    pct.Font = Enum.Font.GothamBold
    pct.TextSize = 12
    pct.ZIndex = 3
    pct.Parent = bg

    local api = {}

    function api.Set(p, text)
        p = math.clamp(p, 0, 100)
        fill.Size = UDim2.new(p / 100, 0, 1, 0)
        pct.Text = string.format("%d%%", math.floor(p))
        if text then status.Text = text end
    end

    function api.Close()
        local items = {}
        for _, d in ipairs(bg:GetDescendants()) do
            if d:IsA("TextLabel") then
                items[#items + 1] = { d, "TextTransparency" }
            elseif d:IsA("ImageLabel") then
                items[#items + 1] = { d, "ImageTransparency" }
            elseif d:IsA("Frame") then
                items[#items + 1] = { d, "BackgroundTransparency" }
            end
        end
        for _, it in ipairs(items) do
            TweenService:Create(it[1], TweenInfo.new(0.35), { [it[2]] = 1 }):Play()
        end
        TweenService:Create(bg, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
        task.delay(0.45, function()
            pcall(function() gui:Destroy() end)
        end)
    end

    return api
end

local boot = buildBoot()

-- 阶段一：慢速加载（约 4 秒）
local STEPS = {
    { at = 6,   text = "校验执行环境…" },
    { at = 18,  text = "载入 UI 核心…" },
    { at = 34,  text = "构建界面控件…" },
    { at = 52,  text = "注入功能模块…" },
    { at = 70,  text = "同步配置…" },
    { at = 88,  text = "挂载灵动岛…" },
    { at = 100, text = "准备就绪" },
}
do
    local idx = 1
    for p = 0, 100 do
        if idx > #STEPS then break end
        while idx <= #STEPS and p >= STEPS[idx].at do
            boot.Set(p, STEPS[idx].text)
            idx = idx + 1
        end
        task.wait(0.04)
    end
    boot.Set(100, "准备就绪")
end

-- ══════════════════════════════════════════════════════════
-- 3. 主窗口
-- ══════════════════════════════════════════════════════════
local win = Library:CreateWindow({
    Title = "LightScript",
    Theme = THEME,
    CloseButton = "hide",
})

local tabHome    = win:CreateTab("主页", "home")
local tabMove    = win:CreateTab("移动", "move")
local tabSetting = win:CreateTab("设置", "settings")
local tabAbout   = win:CreateTab("关于", "info")

-- 窗口下移一点，给顶部的灵动岛让出位置
if win.SetMainPosition then
    win:SetMainPosition(UDim2.new(0.5, 0, 0.585, 0))
end

-- ══════════════════════════════════════════════════════════
-- 4. 移动模块 · 飞行
-- ══════════════════════════════════════════════════════════
-- 手机端没有 WASD：用 Humanoid.MoveDirection（摇杆与键盘统一的"世界坐标输入"）
-- 相机俯仰决定垂直分量，跳跃键短按给向上冲量。
local Fly = { enabled = false, speed = 65, conn = nil, bv = nil, bg = nil, jumpConn = nil, upTicks = 0 }

function Fly:root()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Fly:humanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Fly:stop(silent)
    self.enabled = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    if self.jumpConn then self.jumpConn:Disconnect(); self.jumpConn = nil end
    if self.bv then pcall(function() self.bv:Destroy() end); self.bv = nil end
    if self.bg then pcall(function() self.bg:Destroy() end); self.bg = nil end
    self.upTicks = 0
    local hum = self:humanoid()
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    if not silent then win:SetIslandStatus("待机") end
end

function Fly:start()
    local root, hum = self:root(), self:humanoid()
    if not root or not hum then
        win:Warning("飞行", "角色还没加载好", 3)
        return false
    end
    if self.enabled then return true end

    self.enabled = true
    self.upTicks = 0

    -- 速度驱动
    local bv = Instance.new("BodyVelocity")
    bv.Name = "LS_Fly"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.P = 1250
    bv.Velocity = Vector3.new(0, 32, 0)     -- 起飞冲量
    bv.Parent = root
    self.bv = bv

    -- 姿态驱动：跟相机对齐，避免角色翻滚
    local bg = Instance.new("BodyGyro")
    bg.Name = "LS_FlyGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 3000
    bg.D = 500
    bg.CFrame = root.CFrame
    bg.Parent = root
    self.bg = bg

    self.conn = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        local r = self:root()
        if not r then self:stop(true); return end

        local h = self:humanoid()
        local md = (h and h.MoveDirection) or Vector3.zero
        local cam = workspace.CurrentCamera

        -- MoveDirection 永远是水平的世界坐标；用相机把它还原成 3D 方向，
        -- 这样"抬头 + 前推"就自然爬升，"低头 + 前推"下降。
        local dir = Vector3.zero
        if cam then
            if md.Magnitude > 0.05 then
                local rel = cam.CFrame:VectorToObjectSpace(md)
                dir = cam.CFrame.LookVector * rel.Z + cam.CFrame.RightVector * rel.X
            end
            if self.bg then self.bg.CFrame = cam.CFrame end
        else
            dir = md
        end

        local vel = dir * self.speed
        if self.upTicks > 0 then
            vel = vel + Vector3.new(0, self.speed, 0)
            self.upTicks = self.upTicks - 1
        end

        if self.bv then self.bv.Velocity = vel end
    end)

    -- 手机跳跃键 / PC 空格 → 上升脉冲
    self.jumpConn = UserInput.JumpRequest:Connect(function()
        if self.enabled then self.upTicks = 9 end
    end)

    win:SetIslandStatus("飞行中")
    return true
end

function Fly:setSpeed(v)
    self.speed = v
end

LightScript.Fly = Fly          -- 暴露给外部/调试用

LP.CharacterAdded:Connect(function()
    if Fly.enabled then
        task.wait(1.2)
        Fly:start()
    end
end)

-- ══════════════════════════════════════════════════════════
-- 5. 主页
-- ══════════════════════════════════════════════════════════
tabHome:CreateSection("运行状态")

local info = tabHome:CreateInfoPanel({
    PlayerName   = LP.Name,
    ServerInfo   = "Server: " .. tostring(game.JobId):sub(1, 8),
    ExecutorInfo = "Executor: " .. tostring(identifyexecutor and identifyexecutor() or "?"),
})

local lblStat = tabHome:CreateLabel("模块加载：等待中…")
local barMod  = tabHome:CreateProgressBar("核心模块", 0)

tabHome:CreateDivider()
tabHome:CreateSection("快速操作")

tabHome:CreateButton("重新应用主题", function()
    win:ApplyTheme(THEME)
    win:SetAccentColor(ACCENT)
    win:Notify("界面", "主题已重新应用", 2, { Type = "success" })
end)

tabHome:CreateButton("刷新玩家信息", function()
    if info then
        info:SetPlayerName(LP.Name)
        info:SetServerInfo("Server: " .. tostring(game.JobId):sub(1, 8))
    end
    win:Notify("信息", "已刷新", 2, { Type = "success" })
end)

-- 模块加载进度（开场后再跑一遍，营造加载感）
task.spawn(function()
    task.wait(1.0)
    local phases = {
        { 20,  "载入基础库…" },
        { 45,  "注册功能模块…" },
        { 70,  "同步主题…" },
        { 90,  "挂载热键…" },
        { 100, "全部就绪" },
    }
    for _, ph in ipairs(phases) do
        if LightScript.closed then return end
        barMod:Set(ph[1] / 100)
        lblStat:SetText("模块加载：" .. ph[2])
        task.wait(0.45)
    end
    if not LightScript.closed then
        lblStat:SetText("模块加载：完成 ✔")
        win:SetIslandStatus("待机")
    end
end)

-- ══════════════════════════════════════════════════════════
-- 6. 移动页
-- ══════════════════════════════════════════════════════════
tabMove:CreateSection("飞行")

local toggleFly
toggleFly = tabMove:CreateToggle("启用飞行", false, function(on)
    if on then
        if not Fly:start() then
            toggleFly:Set(false)
        else
            win:Notify("飞行", "WASD 移动 · 空格上升 · Shift 下降", 3, { Type = "success" })
        end
    else
        Fly:stop()
    end
end)

local sliderSpeed
sliderSpeed = tabMove:CreateSlider("飞行速度", 10, 300, Fly.speed, function(v)
    Fly:setSpeed(v)
end)

local bindFly
bindFly = tabMove:CreateKeybind("飞行开关", Enum.KeyCode.F, function()
    toggleFly:Set(not toggleFly:Get())
end)

tabMove:CreateParagraph(
    "手机：推摇杆飞，抬头就爬升、低头就下降，跳键短按上升。\n" ..
    "电脑：WASD 飞，空格上升。速度滑条实时生效。", 2)

-- ══════════════════════════════════════════════════════════
-- 7. 设置页
-- ══════════════════════════════════════════════════════════
tabSetting:CreateSection("外观")

tabSetting:CreateDropdown("主题预设",
    { "DeepSpace", "Nebula", "Aurora", "Ember" }, THEME, function(name)
        win:ApplyTheme(name)
        win:Notify("主题", "已切换 " .. tostring(name), 2)
    end)

tabSetting:CreateColorPicker("强调色", ACCENT, function(c)
    win:SetAccentColor(c)
end)

tabSetting:CreateDivider()
tabSetting:CreateSection("脚本")

local armed = false

tabSetting:CreateButton("关闭脚本", function()
    if not armed then
        armed = true
        win:Warning("再次确认", "3 秒内再点一次即可关闭 LightScript", 3)
        task.delay(3, function() armed = false end)
        return
    end
    armed = false
    LightScript:Shutdown()
end)

tabSetting:CreateParagraph(
    "关闭会停止所有功能、断开连接并清除界面。\n" ..
    "需要重新开始时，再执行一次脚本即可。", 2)

-- ══════════════════════════════════════════════════════════
-- 8. 关于页
-- ══════════════════════════════════════════════════════════
tabAbout:CreateSection("LightScript")

tabAbout:CreateParagraph(
    "版本：v1.0\n" ..
    "UI 库：" .. (srcFrom == "local" and "本地 LS_UI.lua" or "远程拉取") .. "\n" ..
    "执行器：" .. tostring(identifyexecutor and identifyexecutor() or "?") .. "\n" ..
    "身份等级：" .. tostring(getthreadidentity and getthreadidentity() or "?"), 4)

tabAbout:CreateDivider()
tabAbout:CreateSection("架构")

tabAbout:CreateParagraph(
    "LightScript 只做三件事：加载 UI 库、跑模块、管生命周期。\n" ..
    "控件全部来自 LS_UI，功能模块独立注册，互不耦合。", 2)

tabAbout:CreateButton("复制运行信息", function()
    local txt = table.concat({
        "LightScript v1.0",
        "executor=" .. tostring(identifyexecutor and identifyexecutor() or "?"),
        "identity=" .. tostring(getthreadidentity and getthreadidentity() or "?"),
        "place=" .. tostring(game.PlaceId),
        "theme=" .. THEME,
    }, "\n")
    if setclipboard then
        setclipboard(txt)
        win:Notify("已复制", "运行信息已写入剪贴板", 2, { Type = "success" })
    else
        print(txt)
        win:Warning("不可用", "当前执行器没有 setclipboard", 3)
    end
end)

-- ══════════════════════════════════════════════════════════
-- 9. 生命周期
-- ══════════════════════════════════════════════════════════
function LightScript:Shutdown()
    if self.closed then return end
    self.closed = true
    pcall(function() Fly:stop(true) end)
    pcall(function() Library:DestroyAll() end)
    pcall(function() boot.Close() end)
    if getgenv then getgenv().LightScript = nil end
    print("[LightScript] 已关闭")
end

if getgenv then getgenv().LightScript = LightScript end

win:SetIslandStatus("启动中")
win:SetIslandDot(Theme.Success)

-- 收启动页 → 窗口自己带旋入动画 → 灵动岛就位
task.wait(0.25)
boot.Close()
task.wait(0.15)
win:ShowMain()

task.wait(1.4)
if not LightScript.closed then
    win:Notify("LightScript", "已启动，按 F 开关飞行", 3, { Type = "success" })
end

print("[LightScript] v1.0 启动完成")
