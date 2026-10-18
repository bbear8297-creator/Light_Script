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
local Ring = {
    on = false, count = 12, radius = 6, spin = 2, scanRadius = 120,
    conn = nil, t = 0, items = {},
}

function Ring:claimOwnership()
    pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
    pcall(function() LP.ReplicationFocus = workspace end)
end

function Ring:collect()
    local myRoot = Fly:root()
    if not myRoot then return {} end
    local out = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if #out >= self.count then break end
        if d:IsA("BasePart") and not d.Anchored and d ~= myRoot then
            local model = d:FindFirstAncestorOfClass("Model")
            local isCharacter = model and model:FindFirstChildOfClass("Humanoid") ~= nil
            if not isCharacter
                and (d.Position - myRoot.Position).Magnitude <= self.scanRadius then
                out[#out + 1] = d
            end
        end
    end
    return out
end

function Ring:attach(p)
    pcall(function()
        p.CanCollide = false
        p.Massless = true
    end)

    local att = Instance.new("Attachment")
    att.Name = "LS_RingAtt"
    att.Parent = p

    local ap = Instance.new("AlignPosition")
    ap.Name = "LS_RingAlign"
    ap.Mode = Enum.PositionAlignmentMode.OneAttachment
    ap.Attachment0 = att
    ap.MaxForce = 1e9
    ap.MaxVelocity = math.huge
    ap.Responsiveness = 200
    ap.Position = p.Position
    ap.Parent = p

    local ao = Instance.new("AlignOrientation")
    ao.Name = "LS_RingAlignO"
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.Attachment0 = att
    ao.MaxTorque = 1e9
    ao.Responsiveness = 200
    ao.Parent = p

    return { part = p, ap = ap, ao = ao, att = att }
end

function Ring:build()
    self:clear()
    self:claimOwnership()

    for _, p in ipairs(self:collect()) do
        local item = self:attach(p)
        if item then self.items[#self.items + 1] = item end
    end

    -- 地图上没东西可吸时，退化成自己的方块（只有自己能看见）
    if #self.items == 0 then
        local myRoot = Fly:root()
        local folder = Instance.new("Folder")
        folder.Name = "LS_Ring"
        folder.Parent = workspace
        self.localFolder = folder

        for i = 1, self.count do
            local p = Instance.new("Part")
            p.Size = Vector3.new(0.9, 0.9, 0.9)
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromHSV((i - 1) / self.count, 0.65, 1)
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.Parent = folder
            self.items[#self.items + 1] = { part = p, localPart = true }
        end
    end
end

function Ring:clear()
    for _, it in ipairs(self.items) do
        pcall(function()
            if it.ap then it.ap:Destroy() end
            if it.ao then it.ao:Destroy() end
            if it.att then it.att:Destroy() end
        end)
    end
    self.items = {}
    if self.localFolder then
        pcall(function() self.localFolder:Destroy() end)
        self.localFolder = nil
    end
end

function Ring:start()
    if self.on then return end
    self.on = true
    self:build()

    self.claimTick = 0
    self.conn = RunService.Heartbeat:Connect(function(dt)
        if not self.on then return end
        local myRoot = Fly:root()
        if not myRoot then return end

        -- 所有权需要反复续，否则会被服务器收回
        self.claimTick = self.claimTick + dt
        if self.claimTick > 1 then
            self.claimTick = 0
            self:claimOwnership()
        end

        self.t = self.t + dt * self.spin
        local n = #self.items
        for i, it in ipairs(self.items) do
            local p = it.part
            if p and p.Parent then
                local a = self.t + (i - 1) * (math.pi * 2 / n)
                local slot = myRoot.CFrame
                    * CFrame.Angles(0, a, 0)
                    * CFrame.new(0, math.sin(self.t * 2 + i) * 0.3, -self.radius)

                if it.localPart then
                    p.CFrame = slot
                elseif it.ap then
                    it.ap.Position = slot.Position
                end
            end
        end
    end)
end

function Ring:stop()
    self.on = false
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    self:clear()
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
    if on then Ring:start() else Ring:stop() end
end)

tabTool:CreateSlider("方块数量", 4, 32, 12, function(v)
    Ring.count = math.floor(v)
    Ring:rebuild()
end)

tabTool:CreateSlider("环绕半径", 2, 15, 5, function(v)
    Ring.radius = v
end)

tabTool:CreateSlider("旋转速度", 0, 8, 2, function(v)
    Ring.spin = v
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
