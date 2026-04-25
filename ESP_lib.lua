
local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置
local CONFIG = {
    ShowName = true,           -- 玩家显示名称
    ShowHealth = true,         -- 玩家显示血量
    TeamColor = true,          -- 玩家根据队伍上色
    CustomColor = nil,         -- 全局自定义颜色
    MaxDistance = 150,         -- 文本面板最远可见距离
    UpdateInterval = 0.2,      -- 血量/文本刷新间隔
    ConditionCheckInterval = 1.0, -- 条件检查间隔（秒），避免频繁遍历
    HealthGetter = nil,        -- 自定义血量获取函数
}

-- 内部数据
local activePlayers = {}       -- [player] = {highlight, billboard, ...}
local activeObjects = {}       -- [instance] = {highlight, billboard, conditionFunc, ...}
local updateConnection = nil
local lastUpdateTime = 0
local lastConditionCheck = 0

-- ==================== 辅助函数 ====================
local function getColor(instance)
    if CONFIG.CustomColor then return CONFIG.CustomColor end
    if CONFIG.TeamColor and instance:IsA("Player") and instance.Team then
        return instance.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 50, 50)
end

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

local function getHealth(instance)
    if CONFIG.HealthGetter then
        local ok, val = pcall(CONFIG.HealthGetter, instance)
        if ok and type(val) == "number" then return math.floor(val) end
    end
    if instance:IsA("Player") then
        local char = instance.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
            end
        end
    end
    return nil, nil
end

-- 创建通用文本面板
local function createTextPanel(instance, text, textColor, offsetY)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_TextPanel"
    billboard.Size = UDim2.new(0, 140, 0, 30)
    billboard.StudsOffset = Vector3.new(0, offsetY or 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = CONFIG.MaxDistance
    billboard.Adornee = instance
    billboard.Parent = instance

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.Text = text or ""
    label.Parent = billboard

    return billboard, label
end

-- 更新单个物体的ESP（高亮 + 文本）
local function updateObjectESP(instance, objData)
    if not instance then return end
    local color = getColor(instance)
    local targetNode = getRootPart(instance) or instance
    if not targetNode then return end

    -- 高亮
    if not objData.highlight then
        objData.highlight = Instance.new("Highlight")
        objData.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        objData.highlight.FillTransparency = 0.6
        objData.highlight.OutlineTransparency = 0.2
    end
    objData.highlight.FillColor = color
    objData.highlight.OutlineColor = color
    objData.highlight.Parent = targetNode
    objData.highlight.Enabled = true

    -- 文本面板
    if objData.text and objData.text ~= "" then
        if not objData.billboard then
            local billboard, label = createTextPanel(targetNode, objData.text, objData.textColor, objData.offsetY)
            objData.billboard = billboard
            objData.textLabel = label
        else
            objData.textLabel.Text = objData.text
            objData.billboard.Adornee = targetNode
            objData.billboard.MaxDistance = CONFIG.MaxDistance
        end
        objData.billboard.Enabled = true
    elseif objData.billboard then
        objData.billboard.Enabled = false
    end
end

-- 更新玩家ESP（名称+血量）
local function updatePlayerESP(player, objData)
    if not player or player == LocalPlayer then return end
    local color = getColor(player)
    local targetNode = getRootPart(player) or (player.Character and player.Character)
    if not targetNode then return end

    -- 高亮
    if not objData.highlight then
        objData.highlight = Instance.new("Highlight")
        objData.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        objData.highlight.FillTransparency = 0.6
        objData.highlight.OutlineTransparency = 0.2
    end
    objData.highlight.FillColor = color
    objData.highlight.OutlineColor = color
    objData.highlight.Parent = targetNode
    objData.highlight.Enabled = true

    -- 信息面板
    if not objData.billboard then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PlayerInfo"
        billboard.Size = UDim2.new(0, 160, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = CONFIG.MaxDistance
        billboard.Adornee = targetNode
        billboard.Parent = targetNode

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = billboard

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent = frame

        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextSize = 13
        healthLabel.Parent = frame

        objData.billboard = billboard
        objData.nameLabel = nameLabel
        objData.healthLabel = healthLabel
    end

    objData.billboard.Adornee = targetNode
    objData.billboard.MaxDistance = CONFIG.MaxDistance
    objData.billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and targetNode ~= nil

    if objData.nameLabel then
        objData.nameLabel.Text = player.DisplayName or player.Name
        objData.nameLabel.Visible = CONFIG.ShowName
    end
    if objData.healthLabel then
        local hp, maxHp = getHealth(player)
        if hp and maxHp then
            objData.healthLabel.Text = string.format("❤️ %d / %d", hp, maxHp)
        elseif hp then
            objData.healthLabel.Text = "❤️ " .. hp
        else
            objData.healthLabel.Text = "❤️ ???"
        end
        objData.healthLabel.Visible = CONFIG.ShowHealth
    end

    local numLines = (CONFIG.ShowName and 1 or 0) + (CONFIG.ShowHealth and 1 or 0)
    if objData.billboard then
        objData.billboard.Size = (numLines == 1) and UDim2.new(0, 140, 0, 25) or UDim2.new(0, 140, 0, 40)
    end
end

-- 条件检查：遍历所有带条件的物体，移除不满足条件的
local function checkConditions()
    local toRemove = {}
    for instance, data in pairs(activeObjects) do
        if data.conditionFunc and not data.conditionFunc(instance) then
            table.insert(toRemove, instance)
        end
    end
    for _, instance in ipairs(toRemove) do
        ESP:RemoveObject(instance)
    end
end

-- 主更新循环（血量刷新 + 条件检查）
local function startUpdateLoop()
    if updateConnection then return end
    updateConnection = RunService.Stepped:Connect(function()
        local now = tick()
        -- 刷新玩家血量
        if now - lastUpdateTime >= CONFIG.UpdateInterval then
            lastUpdateTime = now
            for player, data in pairs(activePlayers) do
                if player and player.Character then
                    updatePlayerESP(player, data)
                end
            end
            -- 刷新物体文本（如果有动态文本，用户可以手动调用UpdateObjectText，这里不做自动）
        end
        -- 条件检查（独立间隔）
        if now - lastConditionCheck >= CONFIG.ConditionCheckInterval then
            lastConditionCheck = now
            checkConditions()
        end
    end)
end

local function stopUpdateLoop()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- ==================== 公共 API ====================

-- 启用ESP（自动追踪所有玩家）
function ESP:Enable()
    if self._enabled then return end
    self._enabled = true

    Players.PlayerAdded:Connect(function(player)
        task.wait(0.2)
        if player ~= LocalPlayer then
            ESP:AddPlayer(player)
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        ESP:RemovePlayer(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP:AddPlayer(player)
        end
    end
    startUpdateLoop()
end

-- 禁用ESP（清理所有）
function ESP:Disable()
    self._enabled = false
    stopUpdateLoop()
    for player, _ in pairs(activePlayers) do
        ESP:RemovePlayer(player)
    end
    for obj, _ in pairs(activeObjects) do
        ESP:RemoveObject(obj)
    end
end

-- 添加玩家（内部）
function ESP:AddPlayer(player)
    if activePlayers[player] then return end
    local data = {}
    activePlayers[player] = data

    local function onCharAdded(char)
        task.wait(0.1)
        updatePlayerESP(player, data)
    end
    local function onCharRemoving()
        if data.highlight then data.highlight.Enabled = false end
        if data.billboard then data.billboard.Enabled = false end
    end

    if player.Character then onCharAdded(player.Character) end
    data.charAdded = player.CharacterAdded:Connect(onCharAdded)
    data.charRemoved = player.CharacterRemoving:Connect(onCharRemoving)
    updatePlayerESP(player, data)
end

-- 移除玩家
function ESP:RemovePlayer(player)
    local data = activePlayers[player]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.charAdded then data.charAdded:Disconnect() end
        if data.charRemoved then data.charRemoved:Disconnect() end
        activePlayers[player] = nil
    end
end

-- ==================== 通用物体接口（带条件） ====================
-- 为任意物体添加带条件管理的ESP
-- @param instance: BasePart/Model 要高亮的物体
-- @param options: 表，可选：
--   text: 显示的文本（字符串）
--   textColor: Color3，默认白色
--   offsetY: 文本高度偏移，默认1.5
--   onUpdate: 可选，动态更新文本的回调函数(instance) 每次条件检查时或手动刷新时调用，应返回新文本
-- @param conditionFunc: 返回boolean的函数，接收instance为参数。当返回false时，ESP会被自动移除。若为nil，则永久存在。
function ESP:AddObjectWithCondition(instance, options, conditionFunc)
    if not instance or activeObjects[instance] then return end
    options = options or {}
    local data = {
        highlight = nil,
        billboard = nil,
        textLabel = nil,
        text = options.text or "",
        textColor = options.textColor or Color3.fromRGB(255, 255, 255),
        offsetY = options.offsetY or 1.5,
        conditionFunc = conditionFunc,   -- 条件函数
        onUpdate = options.onUpdate,
    }
    activeObjects[instance] = data

    -- 监听对象销毁
    local destroyConn
    destroyConn = instance.AncestryChanged:Connect(function()
        if not instance.Parent then
            ESP:RemoveObject(instance)
            destroyConn:Disconnect()
        end
    end)
    data.destroyConn = destroyConn

    -- 立即创建ESP
    updateObjectESP(instance, data)

    -- 如果有动态更新回调，建立定时或事件处理（简单起见，在条件检查循环中自动调用）
    if data.onUpdate then
        data.refreshText = function()
            local newText = data.onUpdate(instance)
            if newText and newText ~= data.text then
                data.text = newText
                if data.textLabel then
                    data.textLabel.Text = newText
                else
                    updateObjectESP(instance, data)
                end
            end
        end
    end
end

-- 兼容旧接口：不带条件的添加（永久存在，直到手动移除）
function ESP:AddObject(instance, options)
    ESP:AddObjectWithCondition(instance, options, nil)
end

-- 更新物体文本
function ESP:UpdateObjectText(instance, newText)
    local data = activeObjects[instance]
    if data then
        data.text = newText
        if data.textLabel then
            data.textLabel.Text = newText
        else
            updateObjectESP(instance, data)
        end
    end
end

-- 手动刷新某一物体的条件（可用于立即检查）
function ESP:CheckCondition(instance)
    local data = activeObjects[instance]
    if data and data.conditionFunc and not data.conditionFunc(instance) then
        ESP:RemoveObject(instance)
        return false
    end
    return true
end

-- 手动刷新所有物体的条件（例如房间切换时立即清理）
function ESP:RefreshConditions()
    checkConditions()
end

-- 移除物体
function ESP:RemoveObject(instance)
    local data = activeObjects[instance]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.destroyConn then data.destroyConn:Disconnect() end
        activeObjects[instance] = nil
    end
end

-- ==================== 配置 API ====================
function ESP:ShowName(show) CONFIG.ShowName = show end
function ESP:ShowHealth(show) CONFIG.ShowHealth = show end
function ESP:SetTeamColor(enable) CONFIG.TeamColor = enable; if enable then CONFIG.CustomColor = nil end end
function ESP:SetColor(color) CONFIG.CustomColor = color; CONFIG.TeamColor = false end
function ESP:SetMaxDistance(dist) CONFIG.MaxDistance = dist end
function ESP:SetUpdateInterval(interval) CONFIG.UpdateInterval = math.max(0.1, interval) end
function ESP:SetConditionCheckInterval(interval) CONFIG.ConditionCheckInterval = math.max(0.5, interval) end
function ESP:SetHealthGetter(func) CONFIG.HealthGetter = func end
function ESP:IsEnabled() return self._enabled or false end

return ESP
