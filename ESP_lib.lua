-- Robust ESP Library v2.0
-- 基于 Roblox 官方 API 与最佳实践重构
-- 内置玩家信息/物体ESP/动态数值更新/性能优化
-- 依赖: 无 (仅使用 Roblox 内置服务)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- 辅助函数: 安全销毁实例
local function safeDestroy(obj)
    if obj then
        pcall(function() obj:Destroy() end)
    end
end

-- 辅助函数: 安全断开连接
local function safeDisconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

-- 辅助函数: 获取角色根部件
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("Torso")
        or character:FindFirstChildWhichIsA("BasePart")
end

-- ESP 主类
local ESP = {}
ESP._enabled = false
ESP.Settings = {
    ShowName = true,
    ShowHealth = true,
    ShowDistance = false,
    ShowRay = false,
    Color = Color3.fromRGB(255, 255, 255),
    UseTeamColor = false,
    MaxDistance = 1000,
    UpdateInterval = 0.1,
    HealthGetter = nil
}
ESP.Active = {}     -- [player] = renderData
ESP.Objects = {}    -- [instance] = renderData

-- 创建容器
local function createContainer()
    local container = Instance.new("Folder")
    container.Name = "ESP_Container_Robust"
    pcall(function()
        container.Parent = CoreGui
    end)
    if not container.Parent then
        container.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) or Workspace
    end
    return container
end

local ESP_Container = createContainer()

-- 创建激光起点 Part (放在 Workspace 下解决不渲染问题)
local function createLaserOriginPart()
    local part = Instance.new("Part")
    part.Name = "ESP_LaserOrigin"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.CFrame = CFrame.new(0, -1000, 0) -- 隐藏在地下
    part.Parent = Workspace
    return part
end

local LaserOriginPart = createLaserOriginPart()
local LaserOriginAttachment = Instance.new("Attachment")
LaserOriginAttachment.Name = "OriginAttachment"
LaserOriginAttachment.Parent = LaserOriginPart

-- 更新激光起点位置
local function updateLaserOrigin()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    if root then
        LaserOriginPart.CFrame = root.CFrame
    else
        LaserOriginPart.CFrame = CFrame.new(0, -1000, 0)
    end
end

-- 为单个目标创建视觉渲染
local function createRender(playerOrInstance, options)
    options = options or {}
    local render = {}

    -- 获取实际要依附的对象
    local adornee = playerOrInstance
    if playerOrInstance:IsA("Player") then
        adornee = playerOrInstance.Character
    end

    if not adornee then return nil end

    local root = getRoot(adornee)
    if not root then return nil end

    -- 1. Highlight (官方 Highlight API)
    if options.Highlight ~= false then
        local hl = Instance.new("Highlight")
        hl.Adornee = adornee
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0.1
        hl.Enabled = false
        hl.Parent = ESP_Container
        render.Highlight = hl
    end

    -- 2. BillboardGui (官方 BillboardGui API)
    if options.Text ~= false then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.Enabled = false
        bb.Parent = ESP_Container

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

    -- 3. Beam (射线)
    if options.Beam ~= false then
        local targetAttachment = Instance.new("Attachment")
        targetAttachment.Parent = root

        local beam = Instance.new("Beam")
        beam.FaceCamera = true
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Attachment0 = LaserOriginAttachment
        beam.Attachment1 = targetAttachment
        beam.Enabled = false
        beam.Parent = ESP_Container

        render.Beam = beam
        render.TargetAttachment = targetAttachment
    end

    render.Root = root
    render.Options = options
    return render
end

-- 更新单个渲染对象
-- 这个函数现在支持外部传入的动态数值 (用于显示金币等)
local function updateRender(render, entity, playerData)
    if not render or not render.Root then return end

    local isPlayerEntity = entity:IsA("Player")
    local character = isPlayerEntity and entity.Character or entity
    local root = getRoot(character)
    if root and root ~= render.Root then
        -- 根部件换了，重建渲染
        safeDestroy(render.Highlight)
        safeDestroy(render.Billboard)
        safeDestroy(render.Beam)
        safeDestroy(render.TargetAttachment)
        render = createRender(entity, render.Options)
        if not render then return end
    end

    local dist = math.huge
    local localRoot = getRoot(LocalPlayer.Character)
    if root and localRoot then
        dist = (root.Position - localRoot.Position).Magnitude
    end

    local show = ESP._enabled and (dist <= ESP.Settings.MaxDistance)
    local color = ESP.Settings.Color
    if ESP.Settings.UseTeamColor and isPlayerEntity and entity.Team then
        color = entity.Team.TeamColor.Color
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
            render.NameLabel.Text = isPlayerEntity and entity.DisplayName or (playerData and playerData.Name or entity.Name)
            render.NameLabel.TextColor3 = color
        end
    end
    if render.HealthLabel then
        render.HealthLabel.Visible = show and ESP.Settings.ShowHealth
        if render.HealthLabel.Visible then
            local hp = "?"
            if isPlayerEntity and entity.Character then
                local humanoid = entity.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    hp = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
                end
            elseif playerData and playerData.Health then
                hp = playerData.Health
            elseif ESP.Settings.HealthGetter then
                hp = ESP.Settings.HealthGetter(entity)
            end
            render.HealthLabel.Text = "HP: " .. hp
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

    -- Beam
    if render.Beam then
        render.Beam.Enabled = show and ESP.Settings.ShowRay
        if render.Beam.Enabled then
            render.Beam.Color = ColorSequence.new(color)
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
        updateLaserOrigin()

        -- 更新所有玩家
        for player, render in pairs(ESP.Active) do
            updateRender(render, player)
        end

        -- 更新所有物体 (支持动态数据刷新)
        for instance, data in pairs(ESP.Objects) do
            local extraData = data.ExtraData
            local render = data.Render
            if extraData and extraData.Update then
                -- 调用外部更新函数获取最新数据
                extraData.Value = extraData.Update(instance)
            end
            updateRender(render, instance, extraData)
        end
    end
end)

-- 玩家生命监测
local function monitorCharacter(player)
    local function onCharacterAdded(character)
        local render = ESP.Active[player]
        if render then
            render.Root = getRoot(character)
        else
            ESP:AddPlayer(player)
        end
    end

    local function onCharacterRemoving()
        local render = ESP.Active[player]
        if render then
            safeDestroy(render.Highlight)
            safeDestroy(render.Billboard)
            safeDestroy(render.Beam)
            safeDestroy(render.TargetAttachment)
            render.Highlight = nil
            render.Billboard = nil
            render.Beam = nil
            render.TargetAttachment = nil
        end
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(onCharacterRemoving)

    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- 公开 API
function ESP:AddPlayer(player)
    if player == LocalPlayer or self.Active[player] then return end

    local render = createRender(player, {
        Highlight = true,
        Text = true,
        Beam = true
    })
    if render then
        self.Active[player] = render
        monitorCharacter(player)
        self:UpdatePlayer(player)
    end
end

function ESP:RemovePlayer(player)
    local render = self.Active[player]
    if render then
        safeDestroy(render.Highlight)
        safeDestroy(render.Billboard)
        safeDestroy(render.Beam)
        safeDestroy(render.TargetAttachment)
        self.Active[player] = nil
    end
end

function ESP:UpdatePlayer(player)
    local render = self.Active[player]
    if render then
        updateRender(render, player)
    end
end

-- 物体 API
function ESP:AddObject(instance, options)
    if not instance or self.Objects[instance] then return end

    local render = createRender(instance, {
        Highlight = options.Highlight ~= false,
        Text = options.Text ~= false,
        Beam = options.Beam ~= false
    })
    if render then
        self.Objects[instance] = {
            Render = render,
            ExtraData = options.ExtraData or {}
        }
        self:UpdateObject(instance)
    end
end

function ESP:RemoveObject(instance)
    local data = self.Objects[instance]
    if data then
        safeDestroy(data.Render.Highlight)
        safeDestroy(data.Render.Billboard)
        safeDestroy(data.Render.Beam)
        safeDestroy(data.Render.TargetAttachment)
        self.Objects[instance] = nil
    end
end

function ESP:UpdateObject(instance)
    local data = self.Objects[instance]
    if data then
        updateRender(data.Render, instance, data.ExtraData)
    end
end

-- 全局更新所有物体 (强制刷新)
function ESP:RefreshAll()
    for instance, data in pairs(self.Objects) do
        if data.ExtraData and data.ExtraData.Update then
            data.ExtraData.Value = data.ExtraData.Update(instance)
        end
        self:UpdateObject(instance)
    end
end

-- 启用/禁用
function ESP:Enable()
    self._enabled = true
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end
end

function ESP:Disable()
    self._enabled = false
    for player, render in pairs(self.Active) do
        if render.Highlight then render.Highlight.Enabled = false end
        if render.Billboard then render.Billboard.Enabled = false end
        if render.Beam then render.Beam.Enabled = false end
    end
    for _, data in pairs(self.Objects) do
        if data.Render.Highlight then data.Render.Highlight.Enabled = false end
        if data.Render.Billboard then data.Render.Billboard.Enabled = false end
        if data.Render.Beam then data.Render.Beam.Enabled = false end
    end
end

-- 设置方法
function ESP:SetShowName(val) self.Settings.ShowName = val end
function ESP:SetShowHealth(val) self.Settings.ShowHealth = val end
function ESP:SetShowDistance(val) self.Settings.ShowDistance = val end
function ESP:SetShowRay(val) self.Settings.ShowRay = val end
function ESP:SetColor(color) self.Settings.Color = color end
function ESP:SetTeamColor(val) self.Settings.UseTeamColor = val end
function ESP:SetMaxDistance(dist) self.Settings.MaxDistance = dist end
function ESP:SetUpdateInterval(sec) self.Settings.UpdateInterval = sec end
function ESP:SetHealthGetter(fn) self.Settings.HealthGetter = fn end

-- 兼容旧接口
function ESP:ShowName(val) self:SetShowName(val) end
function ESP:ShowHealth(val) self:SetShowHealth(val) end
function ESP:ShowRay(val) self:SetShowRay(val) end
function ESP:AddObjectWithCondition(instance, options, conditionFunc)
    self:AddObject(instance, options)
end
function ESP:UpdateObjectText(instance, text)
    local data = self.Objects[instance]
    if data and data.Render.NameLabel then
        data.Render.NameLabel.Text = text
    end
end

-- 初始化连接
Players.PlayerAdded:Connect(function(player)
    if ESP._enabled then
        ESP:AddPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:RemovePlayer(player)
end)

LocalPlayer.CharacterAdded:Connect(function()
    updateLaserOrigin()
end)

return ESP
