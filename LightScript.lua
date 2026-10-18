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

-- ══════════════════════════════════════════════════════════
-- Fling：SkidFling（原作 zqyDSUWX，KILASIK 的 Multi-Fling 用的就是这套）
--   本质：把自己 CFrame 塞进目标身体里，配上天文级速度/角速度疯狂旋转，
--         物理求解器会把目标直接弹飞。
--   三个前置缺一不可：
--     1) 自己挂 BodyVelocity(0, MaxForce 9e9) → 锁住自己不被弹飞
--     2) 关掉 Seated 状态
--     3) FallenPartsDestroyHeight = NaN → 飞出去的部件不会被销毁
-- ══════════════════════════════════════════════════════════
function Fling(radius, duration)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local target = nearestTarget(radius or 30)
    if not (char and hum and root and target) then return 0 end

    local dur = tonumber(duration) or 2
    local savedPos = root.CFrame
    local savedFPDH = workspace.FallenPartsDestroyHeight

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root

    pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)

    task.spawn(function()
        local t0 = tick()
        local angle = 0
        local flip = 1

        while tick() - t0 < dur do
            if not root.Parent or not target.Parent then break end
            angle = angle + 100
            flip = -flip

            local cf = CFrame.new(target.Position)
                * CFrame.new(0, flip * 1.5, 0)
                * CFrame.Angles(math.rad(angle), 0, 0)

            pcall(function()
                root.CFrame = cf
                char:SetPrimaryPartCFrame(cf)
                root.Velocity = Vector3.new(9e7, 9e8, 9e7)
                root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end)
            task.wait()
        end

        pcall(function() bv:Destroy() end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        pcall(function() workspace.FallenPartsDestroyHeight = savedFPDH end)

        -- 复位，别把自己丢在地图外面
        pcall(function()
            root.CFrame = savedPos + Vector3.new(0, 3, 0)
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end)

    return 1
end
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
                -- 原版逻辑：每帧先灌常量速度（抢所有权）
                pcall(function() part.Velocity = self.grabVelocity end)

                local pos = part.Position
                local flat = Vector3.new(pos.X, center.Y, pos.Z) - center
                local dist = flat.Magnitude
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
                    if dir.Magnitude > 0.01 then
                        -- 原版恒定吸力，不做阻尼
                        pcall(function()
                            part.Velocity = dir.Unit * self.attraction
                        end)
                    end
                end
            end
        end
