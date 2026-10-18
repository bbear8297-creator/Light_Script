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
-- 纯位移飞行：锚定 RootPart 去掉全部外力，每帧按摇杆 + 相机俯仰改 CFrame
local Fly = {
    enabled = false,
    speed = 65,
    leanDeg = 35,
    conn = nil,
    jumpConn = nil,
    upTicks = 0,
}

function Fly:root()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Fly:humanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- 摇杆向量：PlayerModule 的 GetMoveVector 不受锚定/物理影响
function Fly:moveVector()
    local ok, mv = pcall(function()
        local ps = LP:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if not pm then return nil end
        return require(pm):GetControls():GetMoveVector()
    end)
    if ok and typeof(mv) == "Vector3" then return mv end
    local h = self:humanoid()
    return (h and h.MoveDirection) or Vector3.zero
end

function Fly:stop(silent)
    self.enabled = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    if self.jumpConn then self.jumpConn:Disconnect(); self.jumpConn = nil end
    self.upTicks = 0
    local root, hum = self:root(), self:humanoid()
    pcall(function() self:restorePose() end)
    pcall(function() self:restoreArms() end)

    if root then pcall(function() root.Anchored = false end) end
    if hum then
        hum.PlatformStand = false
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
    self.t = 0
    self.idleTime = 999
    self.poseOn = false
    hum.PlatformStand = false    -- 保留人形动画，人物不会僵住
    root.Anchored = true         -- 去掉重力、碰撞、所有外力

    -- 注意：新版 AnimationConstraint 骨架在动画停止后会移除关节，
    -- 冻结动画 = 人物变成无法摆姿势的静态模型，所以这里不冻结。

    self.conn = RunService.Heartbeat:Connect(function(dt)
        if not self.enabled then return end
        local r = self:root()
        if not r then self:stop(true); return end
        -- 角色重生/换模型后 Anchored 会丢，每帧兜底，避免重力把人往下拽
        if not r.Anchored then r.Anchored = true end

        local cam = workspace.CurrentCamera
        local mv = self:moveVector()
        local dir = Vector3.zero

        if cam then
            -- mv: X = 左右, Z = 前后（相机空间，前推为负）
            dir = cam.CFrame.LookVector * (-mv.Z) + cam.CFrame.RightVector * mv.X
        end

        if self.upTicks > 0 then
            dir = dir + Vector3.yAxis
            self.upTicks = self.upTicks - 1
        end

        local mag = dir.Magnitude
        if mag > 1 then dir = dir / mag end

        -- 空中上下浮动：速度做正弦，位移自然起浮
        self.t = (self.t or 0) + dt
        local bobVel = math.cos(self.t * 2.0) * 1.1

        local newPos = r.Position + (dir * self.speed + Vector3.new(0, bobVel, 0)) * dt

        -- 姿态判定：在动 = 超人俯冲，不动 = 直立悬浮
        local traveling = dir.Magnitude > 0.05
        self.idleTime = traveling and 0 or ((self.idleTime or 0) + dt)
        local wantSuper = self.idleTime < 0.20       -- 0.2s 迟滞，避免抖动

        if wantSuper ~= self.poseOn then
            self.poseOn = wantSuper
        end

        local camLook = (cam and cam.CFrame.LookVector) or Vector3.new(0, 0, -1)

        -- 待机时只取水平朝向：镜头仰俯不该把人带歪，人要立着
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
        if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
        flatLook = flatLook.Unit

        local faceDir = traveling and dir.Unit or flatLook

        -- 手臂姿态：飞 = 单臂前伸，悬浮 = 抱胸
        self:setArms(traveling and "fly" or "cross")

        -- 前倾角：默认 35°，滑条可调；只旋转，不动机骨
        local wantLean = traveling and math.rad(self.leanDeg or 35) or 0
        self.lean = (self.lean or 0) + (wantLean - (self.lean or 0)) * math.clamp(dt * 7, 0, 1)

        local bankTarget = (-mv.X) * math.rad(12)
        self.bank = (self.bank or 0) + (bankTarget - (self.bank or 0)) * math.clamp(dt * 6, 0, 1)

        local upright = CFrame.lookAt(newPos, newPos + faceDir)
        local target = upright * CFrame.Angles(-self.lean, 0, 0) * CFrame.Angles(0, 0, self.bank)

        local currentRot = r.CFrame - r.CFrame.Position
        local alpha = math.clamp(dt * 8, 0, 1)
        r.CFrame = CFrame.new(newPos) * currentRot:Lerp(target - target.Position, alpha)


    end)

    self.jumpConn = UserInput.JumpRequest:Connect(function()
        if self.enabled then self.upTicks = 9 end
    end)

    win:SetIslandStatus("飞行中")
    return true
end

-- ══════════════════════════════════════════════════════════
-- 手臂姿态：飞行 = 右臂前伸，悬浮 = 双臂抱胸
--   直接改肩关节 C0，配合冻结动画使用
-- ══════════════════════════════════════════════════════════
Fly.baseC0 = {}
Fly.armMode = "none"
Fly.armRight = -88     -- 飞行：右臂前伸角度
Fly.armLeft  = 148     -- 飞行：左臂贴身角度

local function buildPose()
    local fly = {
        right = CFrame.Angles(math.rad(Fly.armRight), 0, 0),
        left  = CFrame.Angles(math.rad(Fly.armLeft), 0, 0),
    }
    local cross = {
        right = CFrame.Angles(math.rad(-62), 0, math.rad(-40)),
        left  = CFrame.Angles(math.rad(-62), 0, math.rad(40)),
    }
    local none = { right = CFrame.Angles(0, 0, 0), left = CFrame.Angles(0, 0, 0) }
    return { fly = fly, cross = cross, none = none }
end

function Fly:refreshArms()
    local mode = self.armMode
    self.armMode = "?"
    self:setArms(mode)
end

function Fly:setArms(mode)
    if self.armMode == mode then return end
    self.armMode = mode
    local char = LP.Character
    if not char then return end

    local pose = buildPose()[mode] or buildPose().none
    for _, d in ipairs(char:GetDescendants()) do
        local isMotor = d:IsA("Motor6D")
        local isAnim = d:IsA("AnimationConstraint")      -- 新版骨骼
        if (isMotor or isAnim) and (d.Name:find("Shoulder") or d.Name:find("UpperArm")) then
            local offset = d.Name:find("Right") and pose.right or pose.left
            if isMotor then
                if not self.baseC0[d] then self.baseC0[d] = d.C0 end
                pcall(function() d.C0 = self.baseC0[d] * offset end)
            else
                if not self.baseC0[d] then self.baseC0[d] = d.Transform end
                pcall(function() d.Transform = self.baseC0[d] * offset end)
            end
        end
    end
end

function Fly:restoreArms()
    for obj, base in pairs(self.baseC0) do
        pcall(function()
            if obj:IsA("Motor6D") then
                obj.C0 = base
            else
                obj.Transform = base
            end
        end)
    end
    self.baseC0 = {}
    self.armMode = "none"
end

-- 飞行时冻结默认动画（举手乱挥就是 Freefall / Idle 动画在播）
function Fly:freezeAnim(on)
    local char = LP.Character
    if not char then return end
    local anim = char:FindFirstChild("Animate")   -- 是 LocalScript，不能按类名找
    if anim then anim.Disabled = on end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        pcall(function()
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end)
    end
end

function Fly:setSpeed(v)
    self.speed = v
end

-- ══════════════════════════════════════════════════════════
-- 超人姿态：身体躺平（头朝飞行方向、肚皮朝下），手臂前伸
--   R6 用 "Right Shoulder"/"Left Shoulder"，R15 用 "*UpperArm"
-- ══════════════════════════════════════════════════════════
Fly.savedJoints = {}

function Fly:setPose(on)
    local char = LP.Character
    if not char then return end
    for _, name in ipairs({ "Right Shoulder", "Left Shoulder", "RightUpperArm", "LeftUpperArm" }) do
        local m = char:FindFirstChild(name, true)
        if m and m:IsA("Motor6D") then
            if on then
                if not self.savedJoints[m] then self.savedJoints[m] = m.C0 end
                m.C0 = self.savedJoints[m] * CFrame.Angles(math.pi, 0, 0)
            elseif self.savedJoints[m] then
                m.C0 = self.savedJoints[m]
                self.savedJoints[m] = nil
            end
        end
    end
end

function Fly:restorePose()
    for m, c0 in pairs(self.savedJoints) do
        pcall(function() m.C0 = c0 end)
    end
    self.savedJoints = {}
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
            win:Notify("飞行", "推摇杆飞 · 抬头爬升 · 低头下降 · 跳键上升", 3, { Type = "success" })
        end
    else
        Fly:stop()
    end
end)

local sliderSpeed
sliderSpeed = tabMove:CreateSlider("飞行速度", 10, 300, Fly.speed, function(v)
    Fly:setSpeed(v)
end)

local sliderLean
sliderLean = tabMove:CreateSlider("前倾角度", 0, 90, 35, function(v)
    Fly.leanDeg = v
end)

tabMove:CreateSection("飞行姿态")

local sliderArmR
sliderArmR = tabMove:CreateSlider("右臂前伸", -140, 0, -88, function(v)
    Fly.armRight = v
    Fly:refreshArms()
end)

local sliderArmL
sliderArmL = tabMove:CreateSlider("左臂贴身", 90, 180, 148, function(v)
    Fly.armLeft = v
    Fly:refreshArms()
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
