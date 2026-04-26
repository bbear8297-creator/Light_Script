-- Robust ESP Library v2.1
-- 修复射线、重生、性能、动态更新
-- 放置于您的仓库 ESP_lib.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- 辅助函数
local function safeDestroy(obj)
    if obj then pcall(function() obj:Destroy() end) end
end

local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
        or character:FindFirstChildWhichIsA("BasePart")
end

-- 容器
local ESP = {}
ESP._enabled = false
ESP.Settings = {
    ShowName = true,
    ShowHealth = true,
    ShowDistance = false,
    ShowRay = false,
    RayColor = Color3.fromRGB(255, 255, 255),
    RayWidth = 0.1,
    RayTransparency = 0.2,
    DefaultColor = Color3.fromRGB(255, 255, 255),
    UseTeamColor = false,
    MaxDistance = 1000,
    UpdateInterval = 0.1,
    HealthGetter = nil
}

ESP.Players = {}   -- [Player] = RenderData
ESP.Objects = {}   -- [Instance] = RenderData

-- 创建稳定容器（CoreGui 优先）
local function createContainer()
    local folder = Instance.new("Folder")
    folder.Name = "ESP_Robust_Container"
    pcall(function() folder.Parent = CoreGui end)
    if not folder.Parent then
        folder.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return folder
end
local Container = createContainer()

-- 射线原点在 Workspace 内（必须！否则 Beam 不渲染）
local function createRayOrigin()
    local part = Instance.new("Part")
    part.Name = "ESP_RayOrigin"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.CFrame = CFrame.new(0, -10000, 0)
    part.Parent = Workspace

    local attach = Instance.new("Attachment")
    attach.Name = "OriginAttachment"
    attach.Parent = part
    return part, attach
end
local RayOriginPart, RayOriginAttachment = createRayOrigin()

-- 每帧更新射线起点到本地玩家位置
local function updateRayOrigin()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    if root then
        RayOriginPart.CFrame = root.CFrame
    else
        RayOriginPart.CFrame = CFrame.new(0, -10000, 0) -- 隐藏
    end
end

-- 为实体创建视觉元素（玩家/物体通用）
local function createRender(entity, options)
    options = options or {}
    local render = {}
    local adornee = entity
    local root = nil

    if entity:IsA("Player") then
        adornee = entity.Character
        if not adornee then return nil end
        root = getRoot(adornee)
    elseif entity:IsA("Instance") then
        root = getRoot(entity) or entity
        if not root:IsA("BasePart") then return nil end
    end

    if not root then return nil end

    -- 1. Highlight
    if options.Highlight ~= false then
        local hl = Instance.new("Highlight")
        hl.Adornee = adornee
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0.1
        hl.Enabled = false
        hl.Parent = Container
        render.Highlight = hl
    end

    -- 2. Billboard
    if options.Text ~= false then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.Enabled = false
        bb.Parent = Container

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Visible = false
        nameLabel.Parent = bb

        local healthLabel = Instance.new("TextLabel")
        healthLabel.BackgroundTransparency = 1
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextSize = 12
        healthLabel.TextStrokeTransparency = 0
        healthLabel.Visible = false
        healthLabel.Parent = bb

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = 10
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.Visible = false
        distanceLabel.Parent = bb

        render.Billboard = bb
        render.NameLabel = nameLabel
        render.HealthLabel = healthLabel
        render.DistanceLabel = distanceLabel
    end

    -- 3. Beam (射线) - 挂载到目标 Root 的 Attachment
    if options.Beam ~= false then
        local targetAttach = Instance.new("Attachment")
        targetAttach.Parent = root

        local beam = Instance.new("Beam")
        beam.FaceCamera = true
        beam.Width0 = ESP.Settings.RayWidth
        beam.Width1 = ESP.Settings.RayWidth
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Transparency = NumberSequence.new(ESP.Settings.RayTransparency)
        beam.Attachment0 = RayOriginAttachment
        beam.Attachment1 = targetAttach
        beam.Enabled = false
        beam.Parent = Container  -- Container 实际在 CoreGui/PlayerGui 不影响，因为附件在 Workspace
        render.Beam = beam
        render.TargetAttachment = targetAttach
    end

    render.Root = root
    render.Options = options
    return render
end

-- 销毁单个实体的所有视觉
local function destroyRender(render)
    if not render then return end
    safeDestroy(render.Highlight)
    safeDestroy(render.Billboard)
    safeDestroy(render.Beam)
    safeDestroy(render.TargetAttachment)
end

-- 更新单个实体渲染
local function updateRender(render, entity, extraData)
    if not render or not render.Root then return end

    local isPlayer = entity:IsA("Player")
    local character = isPlayer and entity.Character or entity
    local root = getRoot(character) or (entity:IsA("BasePart") and entity)

    -- 如果根部件换掉（重生/换模型）→ 重建整个 render
    if root and root ~= render.Root then
        local opts = render.Options
        destroyRender(render)
        local newRender = createRender(entity, opts)
        -- 替换旧引用
        if isPlayer then
            ESP.Players[entity] = newRender
        else
            if ESP.Objects[entity] then
                ESP.Objects[entity].Render = newRender
            end
        end
        render = newRender
        if not render then return end
    end

    if not root then
        -- 实体无效，隐藏所有
        if render.Highlight then render.Highlight.Enabled = false end
        if render.Billboard then render.Billboard.Enabled = false end
        if render.Beam then render.Beam.Enabled = false end
        return
    end

    -- 距离判定
    local localRoot = getRoot(LocalPlayer.Character)
    local dist = math.huge
    if localRoot and root then
        dist = (root.Position - localRoot.Position).Magnitude
    end
    local show = ESP._enabled and (dist <= ESP.Settings.MaxDistance)

    -- 颜色
    local color = ESP.Settings.DefaultColor
    if ESP.Settings.UseTeamColor and isPlayer and entity.Team then
        color = entity.Team.TeamColor.Color
    end
    if extraData and extraData.Color then
        color = extraData.Color
    end

    -- Highlight
    if render.Highlight then
        render.Highlight.Enabled = show
        render.Highlight.FillColor = color
        render.Highlight.OutlineColor = color
    end

    -- Billboard
    if render.Billboard then
        render.Billboard.Enabled = show and (ESP.Settings.ShowName or ESP.Settings.ShowHealth or ESP.Settings.ShowDistance)
    end
    if render.NameLabel then
        render.NameLabel.Visible = show and ESP.Settings.ShowName
        if render.NameLabel.Visible then
            local name = (extraData and extraData.Name) or (isPlayer and entity.DisplayName or (entity.Name or "???"))
            render.NameLabel.Text = name
            render.NameLabel.TextColor3 = color
        end
    end
    if render.HealthLabel then
        render.HealthLabel.Visible = show and ESP.Settings.ShowHealth
        if render.HealthLabel.Visible then
            local healthText = "?"
            if isPlayer and entity.Character then
                local humanoid = entity.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    healthText = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
                end
            elseif extraData and extraData.Health then
                healthText = extraData.Health
            elseif ESP.Settings.HealthGetter then
                healthText = ESP.Settings.HealthGetter(entity)
            end
            render.HealthLabel.Text = healthText
            render.HealthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    if render.DistanceLabel then
        render.DistanceLabel.Visible = show and ESP.Settings.ShowDistance
        if render.DistanceLabel.Visible then
            render.DistanceLabel.Text = string.format("%.0f studs", dist)
            render.DistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end

    -- 射线：独立于 ESP 总开关，只要 show 且 ShowRay 就显示
    if render.Beam then
        render.Beam.Enabled = show and ESP.Settings.ShowRay
        if render.Beam.Enabled then
            render.Beam.Color = ColorSequence.new(ESP.Settings.RayColor)
            render.Beam.Width0 = ESP.Settings.RayWidth
            render.Beam.Width1 = ESP.Settings.RayWidth
            render.Beam.Transparency = NumberSequence.new(ESP.Settings.RayTransparency)
        end
    end
end

-- 主循环
local lastUpdate = 0
RunService.Heartbeat:Connect(function(dt)
    if not ESP._enabled then return end

    lastUpdate = lastUpdate + dt
    if lastUpdate >= ESP.Settings.UpdateInterval then
        lastUpdate = 0
        updateRayOrigin()

        -- 更新玩家
        for player, render in pairs(ESP.Players) do
            updateRender(render, player)
        end

        -- 更新物体（支持动态数据）
        for instance, data in pairs(ESP.Objects) do
            local extra = data.ExtraData
            if extra and extra.Update then
                -- 调用更新函数获取最新数据
                local ok, result = pcall(extra.Update, instance)
                if ok and result then
                    -- result 应包含 {Name=..., Health=..., Color=...} 等
                    for k, v in pairs(result) do
                        extra[k] = v
                    end
                end
            end
            updateRender(data.Render, instance, extra)
        end
    end
end)

-- 玩家生命周期管理
local function onPlayerAdded(player)
    if player == LocalPlayer or ESP.Players[player] then return end

    local function setup()
        local render = createRender(player, {Highlight = true, Text = true, Beam = true})
        if render then
            ESP.Players[player] = render
        end
    end

    local function cleanup()
        local render = ESP.Players[player]
        if render then
            destroyRender(render)
            ESP.Players[player] = nil
        end
    end

    local charAddedConn
    charAddedConn = player.CharacterAdded:Connect(function(char)
        cleanup()
        task.wait(0.1) -- 等待角色加载
        setup()
    end)
    player.CharacterRemoving:Connect(cleanup)

    if player.Character then
        setup()
    end

    -- 当玩家离开时清理
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanup()
        end
    end)
end

-- 初始化所有现存玩家
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local render = ESP.Players[player]
    if render then
        destroyRender(render)
        ESP.Players[player] = nil
    end
end)

-- 本地玩家重生后更新射线起点
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    updateRayOrigin()
end)

-- 公开 API
function ESP:AddPlayer(player)
    onPlayerAdded(player)
end

function ESP:RemovePlayer(player)
    local render = ESP.Players[player]
    if render then
        destroyRender(render)
        ESP.Players[player] = nil
    end
end

function ESP:AddObject(instance, options)
    if not instance or ESP.Objects[instance] then return end
    local render = createRender(instance, {
        Highlight = (options and options.Highlight ~= false),
        Text = (options and options.Text ~= false),
        Beam = (options and options.Beam ~= false)
    })
    if render then
        ESP.Objects[instance] = {Render = render, ExtraData = options and options.ExtraData or {}}
    end
end

function ESP:RemoveObject(instance)
    local data = ESP.Objects[instance]
    if data then
        destroyRender(data.Render)
        ESP.Objects[instance] = nil
    end
end

function ESP:Enable()
    ESP._enabled = true
end

function ESP:Disable()
    ESP._enabled = false
    for _, render in pairs(ESP.Players) do
        if render.Highlight then render.Highlight.Enabled = false end
        if render.Billboard then render.Billboard.Enabled = false end
        if render.Beam then render.Beam.Enabled = false end
    end
    for _, data in pairs(ESP.Objects) do
        if data.Render then
            if data.Render.Highlight then data.Render.Highlight.Enabled = false end
            if data.Render.Billboard then data.Render.Billboard.Enabled = false end
            if data.Render.Beam then data.Render.Beam.Enabled = false end
        end
    end
end

function ESP:SetShowName(val) ESP.Settings.ShowName = val end
function ESP:SetShowHealth(val) ESP.Settings.ShowHealth = val end
function ESP:SetShowDistance(val) ESP.Settings.ShowDistance = val end
function ESP:SetShowRay(val) ESP.Settings.ShowRay = val end
function ESP:SetRayColor(color) ESP.Settings.RayColor = color end
function ESP:SetRayWidth(width) ESP.Settings.RayWidth = width end
function ESP:SetRayTransparency(trans) ESP.Settings.RayTransparency = trans end
function ESP:SetColor(color) ESP.Settings.DefaultColor = color end
function ESP:SetTeamColor(val) ESP.Settings.UseTeamColor = val end
function ESP:SetMaxDistance(dist) ESP.Settings.MaxDistance = dist end
function ESP:SetUpdateInterval(sec) ESP.Settings.UpdateInterval = sec end
function ESP:SetHealthGetter(fn) ESP.Settings.HealthGetter = fn end

-- 兼容旧接口
function ESP:ShowName(val) self:SetShowName(val) end
function ESP:ShowHealth(val) self:SetShowHealth(val) end
function ESP:ShowRay(val) self:SetShowRay(val) end
function ESP:AddObjectWithCondition(instance, options, cond)
    self:AddObject(instance, options)
end

function ESP:UpdateObjectText(instance, text)
    local data = ESP.Objects[instance]
    if data and data.Render and data.Render.NameLabel then
        data.Render.NameLabel.Text = text
    end
end

return ESP
