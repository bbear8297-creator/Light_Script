-- ==================== ESP库 v3.0（完全修复强化版） ====================
-- 修复：Box模式Adornee绑定、血量获取逻辑、新增原生Beam连线(射线)追踪
local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置 (所有基础信息和射线默认开启)
local CONFIG = {
    Mode = "Highlight",           -- 支持 "Highlight" 或 "Box"
    ShowName = true,
    ShowHealth = true,
    ShowRay = true,               -- 默认开启射线连接
    TeamColor = true,
    CustomColor = nil,
    MaxDistance = 1000,           -- 调大了默认可视距离
    UpdateInterval = 0.2,
    HealthGetter = nil,
}

local activeObjects = {}          -- [instance] = {highlight, box, billboard, rayLine...}
local updateConnection = nil
local lastUpdateTime = 0

-- 辅助：获取展示颜色
local function getColor(instance)
    if CONFIG.CustomColor then return CONFIG.CustomColor end
    if CONFIG.TeamColor and instance:IsA("Player") and instance.Team then
        return instance.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 50, 50) -- 默认红色
end

-- 辅助：获取目标核心部件 (更稳定)
local function getRootPart(instance)
    if instance:IsA("Player") and instance.Character then
        return instance.Character:FindFirstChild("HumanoidRootPart") 
            or instance.Character.PrimaryPart 
            or instance.Character:FindFirstChild("Head")
    elseif instance:IsA("Model") then
        return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("BasePart") then
        return instance
    end
    return nil
end

-- 获取血量（更兼容的版本）
local function getHealth(instance)
    if CONFIG.HealthGetter then
        local ok, val = pcall(CONFIG.HealthGetter, instance)
        if ok and type(val) == "number" then return math.floor(val) end
    end
    if instance:IsA("Player") then
        local char = instance.Character
        if char then
            -- 使用 OfClass 更稳定，防止有些游戏改了 Humanoid 的名字
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
            end
        end
    end
    return nil, nil
end

-- 获取名称
local function getDisplayName(instance)
    if instance:IsA("Player") then
        return instance.DisplayName or instance.Name
    end
    return instance.Name or "Object"
end

-- 创建信息面板
local function createBillboard(instance, objData)
    if not instance:IsA("Player") then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Info"
    billboard.Size = UDim2.new(0, 160, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- 稍微抬高防止穿模
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = CONFIG.MaxDistance
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = frame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    healthLabel.TextStrokeTransparency = 0.2
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 13
    healthLabel.Parent = frame
    
    objData.nameLabel = nameLabel
    objData.healthLabel = healthLabel
    return billboard
end

-- 处理射线（连线）逻辑
local function updateRay(instance, objData, color)
    if not CONFIG.ShowRay then
        if objData.beam then objData.beam.Enabled = false end
        return
    end

    local targetRoot = getRootPart(instance)
    local localRoot = getRootPart(LocalPlayer)

    if not targetRoot or not localRoot then
        if objData.beam then objData.beam.Enabled = false end
        return
    end

    -- 初始化连线组件
    if not objData.beam then
        objData.attachment0 = Instance.new("Attachment")
        objData.attachment1 = Instance.new("Attachment")
        
        local beam = Instance.new("Beam")
        beam.Name = "ESP_Tracer"
        beam.FaceCamera = true
        beam.Width0 = 0.05
        beam.Width1 = 0.05
        beam.Transparency = NumberSequence.new(0.3)
        objData.beam = beam
    end

    -- 确保附件绑定在正确的角色上
    if objData.attachment0.Parent ~= localRoot then objData.attachment0.Parent = localRoot end
    if objData.attachment1.Parent ~= targetRoot then objData.attachment1.Parent = targetRoot end

    -- 更新射线属性
    objData.beam.Attachment0 = objData.attachment0
    objData.beam.Attachment1 = objData.attachment1
    objData.beam.Color = ColorSequence.new(color)
    objData.beam.Parent = targetRoot -- 挂载在目标身上，目标死了自动销毁
    objData.beam.Enabled = true
end

-- 更新单个ESP的视觉元素
local function updateESP(instance, objData)
    if not instance then return end
    local color = getColor(instance)
    local targetNode = getRootPart(instance) or instance
    
    -- 1. 处理 Highlight / Box
    if CONFIG.Mode == "Highlight" then
        if not objData.highlight then
            objData.highlight = Instance.new("Highlight")
            objData.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            objData.highlight.FillTransparency = 0.6
            objData.highlight.OutlineTransparency = 0.2
        end
        objData.highlight.FillColor = color
        objData.highlight.OutlineColor = color
        objData.highlight.Parent = instance:IsA("Player") and instance.Character or instance
        if objData.box then objData.box.Enabled = false end
        objData.highlight.Enabled = true
        
    elseif CONFIG.Mode == "Box" then
        if not objData.box then
            objData.box = Instance.new("SelectionBox")
            objData.box.LineThickness = 0.05
            objData.box.Transparency = 0.3
            objData.box.SurfaceTransparency = 1 -- 隐藏实体表面，只留边框
        end
        objData.box.Color3 = color
        -- 【关键修复】SelectionBox 必须有 Adornee 才能显示
        objData.box.Adornee = instance:IsA("Player") and instance.Character or instance 
        objData.box.Parent = instance:IsA("Player") and instance.Character or instance
        if objData.highlight then objData.highlight.Enabled = false end
        objData.box.Enabled = true
    end
    
    -- 2. 处理信息面板 (血量/名字)
    if instance:IsA("Player") then
        if not objData.billboard then
            objData.billboard = createBillboard(instance, objData)
        end
        
        if objData.billboard then
            objData.billboard.Adornee = targetNode -- 【修复】改绑到RootPart防止没Head
            objData.billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and targetNode ~= nil
            objData.billboard.Parent = targetNode
            
            if objData.nameLabel then
                objData.nameLabel.Text = getDisplayName(instance)
                objData.nameLabel.Visible = CONFIG.ShowName
            end
            if objData.healthLabel then
                local hp, maxHp = getHealth(instance)
                if hp and maxHp then
                    objData.healthLabel.Text = string.format("❤️ %d / %d", hp, maxHp)
                elseif hp then
                    objData.healthLabel.Text = "❤️ " .. hp
                else
                    objData.healthLabel.Text = "❤️ ???"
                end
                objData.healthLabel.Visible = CONFIG.ShowHealth
            end
        end
    end
    
    -- 3. 处理连线 (射线)
    updateRay(instance, objData, color)
end

-- 定时批量更新 (主要用于刷新血量和实时状态)
local function startUpdateLoop()
    if updateConnection then return end
    updateConnection = RunService.Stepped:Connect(function()
        local now = tick()
        if now - lastUpdateTime >= CONFIG.UpdateInterval then
            lastUpdateTime = now
            for instance, objData in pairs(activeObjects) do
                updateESP(instance, objData)
            end
        end
    end)
end

local function stopUpdateLoop()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- 注册目标
function ESP:Add(instance)
    if not instance or instance == LocalPlayer or activeObjects[instance] then return end
    local objData = {}
    activeObjects[instance] = objData
    
    if instance:IsA("Player") then
        local function onCharAdded(char)
            task.wait(0.2)
            updateESP(instance, objData)
        end
        local function onCharRemoving()
            if objData.billboard then objData.billboard.Enabled = false end
            if objData.highlight then objData.highlight.Enabled = false end
            if objData.box then objData.box.Enabled = false end
            if objData.beam then objData.beam.Enabled = false end
        end
        
        if instance.Character then onCharAdded(instance.Character) end
        objData.charAdded = instance.CharacterAdded:Connect(onCharAdded)
        objData.charRemoved = instance.CharacterRemoving:Connect(onCharRemoving)
    end
    
    updateESP(instance, objData)
end

-- 移除目标
function ESP:Remove(instance)
    local objData = activeObjects[instance]
    if objData then
        if objData.highlight then objData.highlight:Destroy() end
        if objData.box then objData.box:Destroy() end
        if objData.billboard then objData.billboard:Destroy() end
        if objData.beam then objData.beam:Destroy() end
        if objData.attachment0 then objData.attachment0:Destroy() end
        if objData.attachment1 then objData.attachment1:Destroy() end
        if objData.charAdded then objData.charAdded:Disconnect() end
        if objData.charRemoved then objData.charRemoved:Disconnect() end
        activeObjects[instance] = nil
    end
end

-- ==================== 公共 API ====================

function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    
    Players.PlayerAdded:Connect(function(player)
        task.wait(0.5)
        ESP:Add(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        ESP:Remove(player)
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        ESP:Add(player)
    end
    startUpdateLoop()
end

function ESP:Disable()
    self._enabled = false
    stopUpdateLoop()
    for instance, _ in pairs(activeObjects) do
        ESP:Remove(instance)
    end
end

function ESP:SetMode(mode)
    if mode == "Highlight" or mode == "Box" then
        CONFIG.Mode = mode
        for inst, data in pairs(activeObjects) do updateESP(inst, data) end
    end
end

function ESP:ShowRay(enable)
    CONFIG.ShowRay = enable
    for inst, data in pairs(activeObjects) do updateESP(inst, data) end
end

function ESP:ShowName(show)
    CONFIG.ShowName = show
    for inst, data in pairs(activeObjects) do
        if data.nameLabel then data.nameLabel.Visible = show end
    end
end

function ESP:ShowHealth(show)
    CONFIG.ShowHealth = show
    for inst, data in pairs(activeObjects) do
        if data.healthLabel then data.healthLabel.Visible = show end
    end
end

function ESP:SetTeamColor(enable)
    CONFIG.TeamColor = enable
    if enable then CONFIG.CustomColor = nil end
    for inst, data in pairs(activeObjects) do updateESP(inst, data) end
end

function ESP:SetColor(color)
    CONFIG.CustomColor = color
    CONFIG.TeamColor = false
    for inst, data in pairs(activeObjects) do updateESP(inst, data) end
end

function ESP:SetMaxDistance(dist)
    CONFIG.MaxDistance = dist
    for inst, data in pairs(activeObjects) do
        if data.billboard then data.billboard.MaxDistance = dist end
    end
end

function ESP:SetUpdateInterval(interval)
    CONFIG.UpdateInterval = math.max(0.1, interval)
end

function ESP:SetHealthGetter(func)
    CONFIG.HealthGetter = func
end

function ESP:IsEnabled()
    return self._enabled or false
end

return ESP
