--[[
    ═══════════════════════════════════════════════════════════════
    LightScript · v1.1
    启动页 → 渐显开场 → 灵动岛 → 普通飞行（速度可调）
    ═══════════════════════════════════════════════════════════════
    执行：loadstring(readfile("LightScript.lua"))()
    依赖：同目录 LS_UI.lua
    ═══════════════════════════════════════════════════════════════
]]

local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

local LightScript = { closed = false }

-- 防重复加载
if getgenv and getgenv().LightScript then
    pcall(function() getgenv().LightScript:Shutdown() end)
    getgenv().LightScript = nil
end

-- ══════════════════════════════════════════════════════════
-- 载入 UI 库
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
end

local src, srcFrom = readSource()
if not src then warn("[LightScript] 找不到 LS_UI.lua"); return end
local chunk = loadstring(src, "=LS_UI")
if not chunk then warn("[LightScript] LS_UI 编译失败"); return end
local okLib, Library = pcall(chunk)
if not okLib then warn("[LightScript] LS_UI 载入失败: " .. tostring(Library)); return end

local THEME  = "Nebula"
local Theme  = Library.Themes[THEME] or Library.Themes.DeepSpace
local ACCENT = Theme.Accent

-- ══════════════════════════════════════════════════════════
-- 启动页
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
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ACCENT),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, ACCENT),
        })
        g.Parent = logo
    end

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0.5, -6)
    sub.BackgroundTransparency = 1
    sub.Text = "LS TEAM  ·  v1.1"
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
        for _, d in ipairs(bg:GetDescendants()) do
            if d:IsA("TextLabel") then
                TweenService:Create(d, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
            elseif d:IsA("ImageLabel") then
                TweenService:Create(d, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play()
            elseif d:IsA("Frame") then
                TweenService:Create(d, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
            end
        end
        TweenService:Create(bg, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
        task.delay(0.45, function() pcall(function() gui:Destroy() end) end)
    end
    return api
end

local boot = buildBoot()
do
    local STEPS = {
        { at = 6,   text = "校验执行环境…" },
        { at = 20,  text = "载入 UI 核心…" },
        { at = 38,  text = "构建界面控件…" },
        { at = 56,  text = "注入功能模块…" },
        { at = 74,  text = "同步配置…" },
        { at = 90,  text = "挂载灵动岛…" },
        { at = 100, text = "准备就绪" },
    }
    local idx = 1
    for p = 0, 100 do
        if idx > #STEPS then break end
        while idx <= #STEPS and p >= STEPS[idx].at do
            boot.Set(p, STEPS[idx].text)
            idx = idx + 1
        end
        task.wait(0.035)
    end
    boot.Set(100, "准备就绪")
end

-- ══════════════════════════════════════════════════════════
-- 主窗口
-- ══════════════════════════════════════════════════════════
local win = Library:CreateWindow({ Title = "LightScript", Theme = THEME, CloseButton = "hide" })

local tabHome    = win:CreateTab("主页", "home")
local tabMove    = win:CreateTab("移动", "move")
local tabTool    = win:CreateTab("工具", "bolt")
local tabSetting = win:CreateTab("设置", "settings")
local tabAbout   = win:CreateTab("关于", "info")

if win.SetMainPosition then
    win:SetMainPosition(UDim2.new(0.5, 0, 0.585, 0))
end

-- ══════════════════════════════════════════════════════════
-- 飞行：CFrame 位移 + 锚定去外力 + 禁用下坠状态
-- ══════════════════════════════════════════════════════════
local Fly = { enabled = false, speed = 65, conn = nil, jumpConn = nil, upTicks = 0 }

function Fly:root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

function Fly:humanoid()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

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

local FALL_STATES = {
    Enum.HumanoidStateType.Freefall,
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
}

function Fly:setFalling(on)
    local hum = self:humanoid()
    if not hum then return end
    for _, s in ipairs(FALL_STATES) do
        pcall(function() hum:SetStateEnabled(s, on) end)
    end
    if not on then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

function Fly:stop(silent)
    self.enabled = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    if self.jumpConn then self.jumpConn:Disconnect(); self.jumpConn = nil end
    self.upTicks = 0
    local root, hum = self:root(), self:humanoid()
    if root then pcall(function() root.Anchored = false end) end
    self:setFalling(true)
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
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
    root.Anchored = true
    self:setFalling(false)

    self.conn = RunService.Heartbeat:Connect(function(dt)
        if not self.enabled then return end
        local r = self:root()
        if not r then self:stop(true); return end
        if not r.Anchored then r.Anchored = true end

        local cam = workspace.CurrentCamera
        local mv = self:moveVector()
        local dir = Vector3.zero
        if cam then
            dir = cam.CFrame.LookVector * (-mv.Z) + cam.CFrame.RightVector * mv.X
        end
        if self.upTicks > 0 then
            dir = dir + Vector3.yAxis
            self.upTicks = self.upTicks - 1
        end

        local mag = dir.Magnitude
        if mag > 1 then dir = dir / mag end

        local newPos = r.Position + dir * self.speed * dt

        -- 朝向跟着视角：水平方向决定转身，相机俯仰决定身体前后倾
        local camLook = (cam and cam.CFrame.LookVector) or Vector3.new(0, 0, -1)
        local flat = Vector3.new(camLook.X, 0, camLook.Z)
        if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
        flat = flat.Unit

        local pitch = math.asin(math.clamp(camLook.Y, -1, 1))     -- 抬头为正
        pitch = math.clamp(pitch, math.rad(-60), math.rad(60))    -- 别翻过去

        local yawCF = CFrame.lookAt(newPos, newPos + flat)
        local target = yawCF * CFrame.Angles(pitch, 0, 0)         -- 抬头后仰 / 低头前倾

        local curRot = r.CFrame - r.CFrame.Position
        local alpha = math.clamp(dt * 12, 0, 1)
        r.CFrame = CFrame.new(newPos) * curRot:Lerp(target - target.Position, alpha)
    end)

    self.jumpConn = UserInput.JumpRequest:Connect(function()
        if self.enabled then self.upTicks = 9 end
    end)

    win:SetIslandStatus("飞行中")
    return true
end

function Fly:setSpeed(v)
    self.speed = v
end

LP.CharacterAdded:Connect(function()
    task.wait(1.0)
    if Fly.enabled then
        Fly.enabled = false
        Fly:start()
    end
    pcall(function() Speed:apply() end)
end)

-- ══════════════════════════════════════════════════════════
-- 速度 / 跳跃
-- ══════════════════════════════════════════════════════════
local Speed = { walk = 16, jump = 50, on = false }

function Speed:apply()
    local hum = Fly:humanoid()
    if not hum then return end
    hum.WalkSpeed = self.on and self.walk or 16
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower = self.on and self.jump or 50
    end)
end

-- ══════════════════════════════════════════════════════════
-- Noclip：逐帧把角色部件的 CanCollide 关掉
-- ══════════════════════════════════════════════════════════
local Noclip = { on = false, conn = nil }

function Noclip:start()
    if self.on then return end
    self.on = true
    self.conn = RunService.Stepped:Connect(function()
        local c = LP.Character
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then
                d.CanCollide = false
            end
        end
    end)
end

function Noclip:stop()
    self.on = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
end

-- ══════════════════════════════════════════════════════════
-- Fling（触碰式）：把自己送进目标身体里造成穿插，物理引擎会把对方弹飞
-- ══════════════════════════════════════════════════════════
local function nearestTarget(radius)
    local myRoot = Fly:root()
    if not myRoot then return nil end
    local best, bestD = nil, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local r = plr.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - myRoot.Position).Magnitude
                if d <= radius and (not bestD or d < bestD) then
                    best, bestD = r, d
                end
            end
        end
    end
    return best
end

function Fling(radius, power)
    local myRoot = Fly:root()
    local target = nearestTarget(radius)
    if not myRoot or not target then return 0 end

    task.spawn(function()
        for i = 1, 10 do
            pcall(function()
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.CFrame = target.CFrame * CFrame.new(0, 0.5, 0.4)
            end)
            task.wait(0.03)
        end
        pcall(function()
            myRoot.AssemblyLinearVelocity = Vector3.new(0, power, 0)
        end)
    end)
    return 1
end

-- ══════════════════════════════════════════════════════════
-- Parts 环绕（所有权劫持版）
--   原理同 Super Ring Parts：
--   1) sethiddenproperty(SimulationRadius, inf) 抢到附近部件的物理所有权
--   2) 吸附地图上「未锚定、不属于角色」的部件
--   3) 每个部件挂 AlignPosition，每帧把目标位置指到环形槽位
--   → 因为是服务器已知的部件，其他人也能看见
-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════
-- Parts 环绕（照抄 Super Ring Parts 的算法）
--   1) SimulationRadius = inf 抢物理所有权
--   2) parts 列表：初始扫描 + DescendantAdded / DescendantRemoving 维护
--   3) 每帧对每个部件算环形目标点，直接写 part.Velocity 朝目标推
-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════
-- Parts 环绕（照抄 Super Ring Parts V6）
--   关键三条（之前全漏了）：
--     1) 每帧给所有部件灌常量 Velocity → 抢物理所有权
--     2) 扫全图，不做距离过滤（远处部件靠常驻推力慢慢被拉过来）
--     3) 参数用原版量级：radius 50 / height 100 / attraction 1000
-- ══════════════════════════════════════════════════════════
local Ring = {
    on = false,
    radius = 50,
    height = 100,
    rotationSpeed = 10,
    attraction = 1000,
    grabVelocity = Vector3.new(14.46262424, 14.46262424, 14.46262424),
    maxParts = 200,
    scanRadius = 99999,     -- 99999 = 不过滤
    conn = nil, addedConn = nil, removedConn = nil,
    parts = {}, hits = 0,
}

function Ring:claimOwnership()
    pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
    pcall(function() LP.ReplicationFocus = workspace end)
end

function Ring:retain(p)
    if not p:IsA("BasePart") then return false end
    if p.Anchored then return false end
    if not p:IsDescendantOf(workspace) then return false end
    local char = LP.Character
    if char and p:IsDescendantOf(char) then return false end
    pcall(function()
        p.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        p.CanCollide = false
    end)
    return true
end

function Ring:addPart(p)
    if #self.parts >= self.maxParts then return end
    if table.find(self.parts, p) then return end
    if self:retain(p) then
        self.parts[#self.parts + 1] = p
    end
end

function Ring:removePart(p)
    local i = table.find(self.parts, p)
    if i then table.remove(self.parts, i) end
end

function Ring:scan()
    self.parts = {}
    local root = Fly:root()
    local center = root and root.Position or Vector3.zero

    for _, d in ipairs(workspace:GetDescendants()) do
        if #self.parts >= self.maxParts then break end
        if self:retain(d) then
            if self.scanRadius >= 90000
                or (d.Position - center).Magnitude <= self.scanRadius then
                self.parts[#self.parts + 1] = d
            end
        end
    end
    self.hits = #self.parts
end

function Ring:start()
    if self.on then return end
    self.on = true
    self:claimOwnership()
    self:scan()

    self.addedConn = workspace.DescendantAdded:Connect(function(d)
        if self.on then self:addPart(d) end
    end)
    self.removedConn = workspace.DescendantRemoving:Connect(function(d)
        if self.on then self:removePart(d) end
    end)

    self.claimTick = 0
    self.conn = RunService.Heartbeat:Connect(function(dt)
        if not self.on then return end
        local root = Fly:root()
        if not root then return end

        self.claimTick = self.claimTick + dt
        if self.claimTick > 0.5 then
            self.claimTick = 0
            self:claimOwnership()
        end

        local center = root.Position
        local h = math.max(self.height, 0.1)

        for _, part in ipairs(self.parts) do
            if part and part.Parent and not part.Anchored then
                local pos = part.Position
                local flat = Vector3.new(pos.X, center.Y, pos.Z) - center
                local dist = flat.Magnitude

                -- ① 只在远处灌常驻速度：抢所有权 + 拉进范围，近处不干扰环
                if dist > self.radius * 2.5 then
                    pcall(function() part.Velocity = self.grabVelocity end)
                end

                -- ② 弹簧模型：距离越近速度越小，到点自动收敛，不会过冲
                if dist > 0.01 then
                    local angle = math.atan2(pos.Z - center.Z, pos.X - center.X)
                        + math.rad(self.rotationSpeed)
                    local r = math.min(self.radius, math.max(dist, 2))
                    local target = Vector3.new(
                        center.X + math.cos(angle) * r,
                        center.Y + self.height * math.abs(math.sin((pos.Y - center.Y) / h)),
                        center.Z + math.sin(angle) * r
                    )
                    local dir = target - pos
                    local gap = dir.Magnitude
                    if gap > 0.05 then
                        local speed = math.min(self.attraction, gap * 6)
                        pcall(function()
                            part.Velocity = dir.Unit * speed
                            part.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end
        end
        self.hits = #self.parts
    end)
end

function Ring:stop()
    self.on = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    if self.addedConn then self.addedConn:Disconnect(); self.addedConn = nil end
    if self.removedConn then self.removedConn:Disconnect(); self.removedConn = nil end
end
function Ring:refresh()
    if self.on then self:scan() end
end
function Ring:rebuild()
    if self.on then self:build() end
end

-- ══════════════════════════════════════════════════════════
-- 主页
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

tabHome:CreateButton("刷新玩家信息", function()
    if info then
        info:SetPlayerName(LP.Name)
        info:SetServerInfo("Server: " .. tostring(game.JobId):sub(1, 8))
    end
    win:Notify("信息", "已刷新", 2, { Type = "success" })
end)

task.spawn(function()
    task.wait(0.8)
    local phases = {
        { 25,  "载入基础库…" },
        { 55,  "注册功能模块…" },
        { 80,  "同步主题…" },
        { 100, "全部就绪" },
    }
    for _, ph in ipairs(phases) do
        if LightScript.closed then return end
        barMod:Set(ph[1] / 100)
        lblStat:SetText("模块加载：" .. ph[2])
        task.wait(0.4)
    end
    if not LightScript.closed then
        lblStat:SetText("模块加载：完成 ✔")
        win:SetIslandStatus("待机")
    end
end)

-- ══════════════════════════════════════════════════════════
-- 移动页
-- ══════════════════════════════════════════════════════════
tabMove:CreateSection("飞行")

local toggleFly
toggleFly = tabMove:CreateToggle("启用飞行", false, function(on)
    if on then
        if not Fly:start() then
            toggleFly:Set(false)
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
    "推摇杆飞，抬头爬升、低头下降，跳跃键上升。\n" ..
    "飞行中人物保持直立，不会进入下坠状态。", 2)

tabMove:CreateSection("速度与跳跃")

tabMove:CreateToggle("启用速度修改", false, function(on)
    Speed.on = on
    Speed:apply()
end)

tabMove:CreateSlider("行走速度", 16, 300, 16, function(v)
    Speed.walk = v
    Speed:apply()
end)

tabMove:CreateSlider("跳跃力度", 50, 300, 50, function(v)
    Speed.jump = v
    Speed:apply()
end)

-- ══════════════════════════════════════════════════════════
-- 工具页：Noclip / Fling / Parts Ring
-- ══════════════════════════════════════════════════════════
tabTool:CreateSection("穿墙")

tabTool:CreateToggle("启用 Noclip", false, function(on)
    if on then Noclip:start() else Noclip:stop() end
end)

tabTool:CreateDivider()
tabTool:CreateSection("甩飞附近玩家")

local flingRadius = 25
local flingPower = 3e4
local autoFlingConn

tabTool:CreateSlider("作用半径", 5, 100, 25, function(v)
    flingRadius = v
end)

tabTool:CreateSlider("力度（万）", 1, 100, 3, function(v)
    flingPower = v * 10000
end)

tabTool:CreateButton("立即甩飞", function()
    local n = Fling(flingRadius, flingPower)
    win:Notify("甩飞", ("范围内命中 %d 人"):format(n), 2, { Type = n > 0 and "success" or "warning" })
end)

tabTool:CreateToggle("自动甩飞", false, function(on)
    if autoFlingConn then autoFlingConn:Disconnect(); autoFlingConn = nil end
    if on then
        autoFlingConn = RunService.Heartbeat:Connect(function()
            Fling(flingRadius, flingPower)
        end)
        win:SetIslandStatus("自动甩飞中")
    else
        win:SetIslandStatus("待机")
    end
end)

tabTool:CreateDivider()
tabTool:CreateSection("Parts 环绕")

tabTool:CreateToggle("启用环绕", false, function(on)
    if on then
        Ring:start()
        task.delay(0.5, function()
            win:Notify("环绕", ("已接管 %d 个部件"):format(Ring.hits), 3,
                { Type = Ring.hits > 0 and "success" or "warning" })
        end)
    else
        Ring:stop()
    end
end)

tabTool:CreateSlider("环绕半径", 5, 120, 50, function(v)
    Ring.radius = v
end)

tabTool:CreateSlider("环绕高度", 0, 200, 100, function(v)
    Ring.height = v
end)

tabTool:CreateSlider("旋转速度", 0, 30, 10, function(v)
    Ring.rotationSpeed = v
end)

tabTool:CreateSlider("吸附力度", 100, 3000, 1000, function(v)
    Ring.attraction = v
end)

tabTool:CreateSlider("最大部件数", 10, 400, 200, function(v)
    Ring.maxParts = math.floor(v)
    Ring:refresh()
end)
tabTool:CreateParagraph(
    "Noclip 逐帧关闭自身碰撞，可穿过地形。\n" ..
    "甩飞依赖网络所有权，能否踢飞看对面所在服务器。", 2)

-- ══════════════════════════════════════════════════════════
-- 设置页
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
        win:Warning("再次确认", "3 秒内再点一次即可关闭", 3)
        task.delay(3, function() armed = false end)
        return
    end
    armed = false
    LightScript:Shutdown()
end)

tabSetting:CreateParagraph("关闭后停止全部功能、清除界面；再次执行即可重开。", 2)

-- ══════════════════════════════════════════════════════════
-- 关于页
-- ══════════════════════════════════════════════════════════
tabAbout:CreateSection("LightScript")
tabAbout:CreateParagraph(
    "版本：v1.1\n" ..
    "UI 库：" .. (srcFrom == "local" and "本地 LS_UI.lua" or "远程") .. "\n" ..
    "执行器：" .. tostring(identifyexecutor and identifyexecutor() or "?") .. "\n" ..
    "身份等级：" .. tostring(getthreadidentity and getthreadidentity() or "?"), 4)

tabAbout:CreateDivider()
tabAbout:CreateButton("复制运行信息", function()
    local txt = table.concat({
        "LightScript v1.1",
        "executor=" .. tostring(identifyexecutor and identifyexecutor() or "?"),
        "identity=" .. tostring(getthreadidentity and getthreadidentity() or "?"),
        "place=" .. tostring(game.PlaceId),
    }, "\n")
    if setclipboard then
        setclipboard(txt)
        win:Notify("已复制", "运行信息已写入剪贴板", 2, { Type = "success" })
    else
        print(txt)
    end
end)

-- ══════════════════════════════════════════════════════════
-- 生命周期
-- ══════════════════════════════════════════════════════════
function LightScript:Shutdown()
    if self.closed then return end
    self.closed = true
    pcall(function() Fly:stop(true) end)
    pcall(function() Noclip:stop() end)
    pcall(function() Ring:stop() end)
    if autoFlingConn then pcall(function() autoFlingConn:Disconnect() end) end
    pcall(function() Library:DestroyAll() end)
    pcall(function() boot.Close() end)
    if getgenv then getgenv().LightScript = nil end
    print("[LightScript] 已关闭")
end

if getgenv then getgenv().LightScript = LightScript end

-- 暴露模块句柄，便于调试与外部调用
LightScript.Fly = Fly
LightScript.Ring = Ring
LightScript.Noclip = Noclip
LightScript.Speed = Speed
LightScript.Fling = Fling

win:SetIslandStatus("启动中")
win:SetIslandDot(Theme.Success)

task.wait(0.25)
boot.Close()
task.wait(0.15)
win:ShowMain()

task.wait(1.2)
if not LightScript.closed then
    win:Notify("LightScript", "已启动 · 按 F 开关飞行", 3, { Type = "success" })
end
print("[LightScript] v1.1 启动完成")
