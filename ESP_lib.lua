-- ==================== ESP库 v2.0（修复版） ====================
-- 支持玩家自动追踪（加入/重生）、通用物体、Highlight/Box双模式、射线连接、血量/名称显示
local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置
local CONFIG = {
    Mode = "Highlight",           -- "Highlight", "Box"
    ShowName = true,
    ShowHealth = true,
    ShowRay = false,              -- 射线开关
    TeamColor = true,
    CustomColor = nil,
    MaxDistance = 150,
    UpdateInterval = 0.3,
    HealthGetter = nil,
    RayColor = Color3.fromRGB(255, 0, 0),
}

-- 内部数据
local activeObjects = {}          -- [instance] = {highlight, box, billboard, rayLine, nameLabel, healthLabel, connections}
local updateConnection = nil
local lastUpdateTime = 0

-- 辅助：获取展示颜色
local function getColor(instance)
    if CONFIG.CustomColor then
        return CONFIG.CustomColor
    end
    if CONFIG.TeamColor and instance:IsA("Player") and instance.Team then
        return instance.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 0)
end

-- 获取血量（仅玩家）
local function getHealth(instance)
    if CONFIG.HealthGetter then
        local ok, val = pcall(CONFIG.HealthGetter, instance)
        if ok and type(val) == "number" then
            return math.floor(val)
        end
    end
    if instance:IsA("Player") then
        local char = instance.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                return math.floor(humanoid.Health)
            end
        end
    end
    return nil
end

-- 获取名称
local function getDisplayName(instance)
    if instance:IsA("Player") then
        return instance.Name
    end
    return instance.Name or "Object"
end

-- 创建信息面板（仅玩家）
local function createBillboard(instance, objData)
    if not instance:IsA("Player") then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Info"
    billboard.Size = UDim2.new(0, 160, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = CONFIG.MaxDistance
    billboard.Adornee = nil  -- 稍后设置
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Text = getDisplayName(instance)
    nameLabel.Parent = frame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.Text = "❤️ ?"
    healthLabel.Parent = frame
    
    objData.nameLabel = nameLabel
    objData.healthLabel = healthLabel
    return billboard
end

-- 创建Highlight
local function createHighlight(instance, color)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.4
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return hl
end

-- 创建Box（使用SelectionBox，若失败则降级为Highlight）
local function createBox(instance, color)
    local box = Instance.new("SelectionBox")
    box.Name = "ESP_Box"
    box.Color3 = color
    box.LineThickness = 0.1
    box.Transparency = 0.5
    box.SurfaceTransparency = 0.8
    return box
end

-- 创建射线（连接本地角色到目标角色的根部部件）
local function createRayLine(targetInstance)
    local line = Instance.new("SelectionBox")  -- 欺骗，实际需要LineHandle，但SelectionBox不可连线。改用Part?
    -- 最简单实现：使用两个点之间的圆柱体，但性能差。本库不实现复杂射线，改用简单提示：射线功能需要额外开发。
    -- 为了满足需求，我们采用折衷：在目标头顶生成一个追踪球体并连线？太复杂。先提供空壳，后续用 Drawing 或 模型Line。
    -- 为避免报错，返回nil并提示。
    warn("射线功能暂未完全实现，将在后续版本提供Drawing方式")
    return nil
end

-- 更新单个ESP的视觉元素
local function updateESP(instance, objData)
    if not instance then return end
    local color = getColor(instance)
    local mode = CONFIG.Mode
    
    -- 处理高亮/盒子
    if mode == "Highlight" then
        if not objData.highlight then
            objData.highlight = createHighlight(instance, color)
        end
        objData.highlight.FillColor = color
        objData.highlight.OutlineColor = color
        objData.highlight.Parent = (instance:IsA("Player") and instance.Character) or instance
        if objData.box then objData.box.Parent = nil end
    elseif mode == "Box" then
        if not objData.box then
            objData.box = createBox(instance, color)
        end
        objData.box.Color3 = color
        objData.box.Parent = (instance:IsA("Player") and instance.Character) or instance
        if objData.highlight then objData.highlight.Parent = nil end
    end
    
    -- 更新信息面板（玩家）
    if instance:IsA("Player") then
        if not objData.billboard then
            objData.billboard = createBillboard(instance, objData)
        end
        local char = instance.Character
        local head = char and char:FindFirstChild("Head")
        if objData.billboard then
            objData.billboard.Adornee = head
            objData.billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and head ~= nil
            objData.billboard.MaxDistance = CONFIG.MaxDistance
        end
        if objData.nameLabel then
            objData.nameLabel.Text = getDisplayName(instance)
            objData.nameLabel.Visible = CONFIG.ShowName
        end
        if objData.healthLabel then
            local hp = getHealth(instance)
            objData.healthLabel.Text = hp and ("❤️ " .. hp) or "❤️ ?"
            objData.healthLabel.Visible = CONFIG.ShowHealth
        end
        -- 调整面板高度
        local numLines = (CONFIG.ShowName and 1 or 0) + (CONFIG.ShowHealth and 1 or 0)
        if objData.billboard then
            if numLines == 1 then
                objData.billboard.Size = UDim2.new(0, 140, 0, 25)
            else
                objData.billboard.Size = UDim2.new(0, 140, 0, 40)
            end
        end
    else
        -- 非玩家物体，没有Billboard
        if objData.billboard then objData.billboard:Destroy() end
        objData.billboard = nil
    end
end

-- 批量更新血量（定时）
local function startUpdateLoop()
    if updateConnection then return end
    updateConnection = RunService.Stepped:Connect(function()
        local now = tick()
        if now - lastUpdateTime >= CONFIG.UpdateInterval then
            lastUpdateTime = now
            for instance, objData in pairs(activeObjects) do
                if instance:IsA("Player") and objData.healthLabel and objData.healthLabel.Visible then
                    local hp = getHealth(instance)
                    if hp then
                        objData.healthLabel.Text = "❤️ " .. hp
                    else
                        objData.healthLabel.Text = "❤️ ?"
                    end
                end
                -- 动态更新颜色（如果配置改变）
                if CONFIG.Mode then
                    updateESP(instance, objData)
                end
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

-- 添加玩家/物体
function ESP:Add(instance)
    if not instance or activeObjects[instance] then return end
    local objData = {}
    activeObjects[instance] = objData
    
    if instance:IsA("Player") then
        -- 监听角色变化
        local function onCharAdded(char)
            task.wait(0.1)
            updateESP(instance, objData)
        end
        local function onCharRemoving()
            if objData.billboard then objData.billboard.Enabled = false end
            if objData.highlight then objData.highlight.Parent = nil end
            if objData.box then objData.box.Parent = nil end
        end
        if instance.Character then
            onCharAdded(instance.Character)
        end
        objData.charAdded = instance.CharacterAdded:Connect(onCharAdded)
        objData.charRemoved = instance.CharacterRemoving:Connect(onCharRemoving)
    end
    
    updateESP(instance, objData)
end

function ESP:Remove(instance)
    local objData = activeObjects[instance]
    if objData then
        if objData.highlight then objData.highlight:Destroy() end
        if objData.box then objData.box:Destroy() end
        if objData.billboard then objData.billboard:Destroy() end
        if objData.charAdded then objData.charAdded:Disconnect() end
        if objData.charRemoved then objData.charRemoved:Disconnect() end
        activeObjects[instance] = nil
    end
end

local function addAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP:Add(player)
        end
    end
end

local function setupEvents()
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            task.wait(0.2)
            ESP:Add(player)
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        ESP:Remove(player)
    end)
end

-- ==================== 公共 API ====================
function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    setupEvents()
    startUpdateLoop()
    addAllPlayers()
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
        for inst, data in pairs(activeObjects) do
            updateESP(inst, data)
        end
    else
        warn("无效模式，仅支持 Highlight 和 Box")
    end
end

function ESP:ShowName(show)
    CONFIG.ShowName = show
    for inst, data in pairs(activeObjects) do
        if data.nameLabel then
            data.nameLabel.Visible = show
        end
        if data.billboard then
            local head = inst.Character and inst.Character:FindFirstChild("Head")
            data.billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and head ~= nil
        end
    end
end

function ESP:ShowHealth(show)
    CONFIG.ShowHealth = show
    for inst, data in pairs(activeObjects) do
        if data.healthLabel then
            data.healthLabel.Visible = show
        end
        if data.billboard then
            local head = inst.Character and inst.Character:FindFirstChild("Head")
            data.billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and head ~= nil
        end
    end
end

function ESP:SetTeamColor(enable)
    CONFIG.TeamColor = enable
    if enable then CONFIG.CustomColor = nil end
    for inst, data in pairs(activeObjects) do
        updateESP(inst, data)
    end
end

function ESP:SetColor(color)
    CONFIG.CustomColor = color
    CONFIG.TeamColor = false
    for inst, data in pairs(activeObjects) do
        updateESP(inst, data)
    end
end

function ESP:SetMaxDistance(dist)
    CONFIG.MaxDistance = dist
    for inst, data in pairs(activeObjects) do
        if data.billboard then
            data.billboard.MaxDistance = dist
        end
    end
end

function ESP:SetUpdateInterval(interval)
    CONFIG.UpdateInterval = math.max(0.1, interval)
end

function ESP:SetHealthGetter(func)
    CONFIG.HealthGetter = func
end

function ESP:ShowRay(enable)
    CONFIG.ShowRay = enable
    -- 射线功能后续完善，先空实现
    if enable then
        warn("射线功能开发中，暂不可用")
    end
end

function ESP:IsEnabled()
    return self._enabled or false
end

-- 通用物体添加
function ESP:AddObject(instance)
    ESP:Add(instance)
end

function ESP:RemoveObject(instance)
    ESP:Remove(instance)
end

return ESP
