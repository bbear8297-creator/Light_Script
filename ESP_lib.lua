-- ==================== ESP库（完整版） ====================
-- 支持玩家自动追踪（加入/重生）、通用物体添加、三种渲染模式（Highlight/Box/Chams）
-- 信息面板（名称/血量）正常工作，性能可调
-- 作者：LS Team

local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置默认值
local CONFIG = {
    Mode = "Highlight",           -- "Highlight", "Box", "Chams"
    ShowName = true,
    ShowHealth = true,
    TeamColor = true,             -- 玩家专用：队伍自动色
    CustomColor = nil,            -- 全局自定义颜色（覆盖队伍色）
    MaxDistance = 150,            -- 信息面板最大可见距离
    UpdateInterval = 0.3,         -- 血量/名称更新间隔（秒）
    HealthGetter = nil,           -- 自定义血量函数(instance) -> number
}

-- 内部数据
local activeObjects = {}          -- [对象] = {highlight, box, billboard, lastHealth, lastName}
local updateConnection = nil
local lastUpdateTime = 0

-- 辅助函数：获取队伍颜色（仅对玩家有效）
local function getTeamColor(instance)
    if instance:IsA("Player") and instance.Team then
        return instance.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

-- 辅助函数：获取血量（仅对玩家有效）
local function getHealth(instance)
    if CONFIG.HealthGetter then
        local ok, val = pcall(CONFIG.HealthGetter, instance)
        if ok and type(val) == "number" then
            return math.floor(val)
        end
    end
    if instance:IsA("Player") then
        local char = instance.Character
        if char and char:FindFirstChild("Humanoid") then
            return math.floor(char.Humanoid.Health)
        end
    end
    return nil
end

-- 辅助函数：获取名称（玩家名 or 物体名）
local function getName(instance)
    if instance:IsA("Player") then
        return instance.Name
    elseif instance:IsA("BasePart") or instance:IsA("Model") then
        return instance.Name
    end
    return "ESP"
end

-- 获取当前应使用的颜色
local function getCurrentColor(instance)
    if CONFIG.CustomColor then
        return CONFIG.CustomColor
    end
    if CONFIG.TeamColor and instance:IsA("Player") then
        return getTeamColor(instance)
    end
    return Color3.fromRGB(255, 255, 0)  -- 默认黄色
end

-- 创建信息面板（BillboardGui）
local function createBillboard(instance, objData)
    if not instance or not instance:IsA("Player") then
        return nil  -- 只有玩家才显示信息面板（其他物体暂不需要，可扩展）
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Info"
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = CONFIG.MaxDistance
    -- Adornee 后续在角色变化时更新
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
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Text = getName(instance)
    nameLabel.Parent = frame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(0.8,1,0.8)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.Text = "❤️ ?"
    healthLabel.Parent = frame
    
    objData.NameLabel = nameLabel
    objData.HealthLabel = healthLabel
    return billboard
end

-- 创建高亮（Highlight）
local function createHighlight(instance)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.OutlineTransparency = 0.4
    highlight.FillTransparency = 0.6
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return highlight
end

-- 创建方框（SelectionBox）仅用于Part/Model的包围盒
local function createBox(instance)
    local box = Instance.new("SelectionBox")
    box.Name = "ESP_Box"
    box.LineThickness = 0.05
    box.Color3 = Color3.new(1,0,0)
    box.Transparency = 0.5
    box.SurfaceTransparency = 0.8
    return box
end

-- 更新单个ESP的视觉样式
local function updateVisual(instance, objData)
    local mode = CONFIG.Mode
    local color = getCurrentColor(instance)
    
    -- 处理 Highlight 模式
    if mode == "Highlight" then
        if not objData.Highlight then
            objData.Highlight = createHighlight(instance)
        end
        objData.Highlight.FillColor = color
        objData.Highlight.OutlineColor = color
        objData.Highlight.Parent = instance.Character or instance  -- 玩家需挂在Character上
        if objData.Box then objData.Box.Parent = nil end
    elseif mode == "Box" then
        if not objData.Box then
            objData.Box = createBox(instance)
        end
        objData.Box.Color3 = color
        objData.Box.Parent = instance.Character or instance
        if objData.Highlight then objData.Highlight.Parent = nil end
    elseif mode == "Chams" then
        -- Chams 暂用 Highlight 代替（性能更好），可后续实现材质替换
        if not objData.Highlight then
            objData.Highlight = createHighlight(instance)
        end
        objData.Highlight.FillColor = color
        objData.Highlight.OutlineColor = color
        objData.Highlight.Parent = instance.Character or instance
        if objData.Box then objData.Box.Parent = nil end
    end
    
    -- 处理信息面板（仅玩家）
    if instance:IsA("Player") then
        if not objData.Billboard then
            objData.Billboard = createBillboard(instance, objData)
        end
        if objData.Billboard then
            -- 更新 Adornee 为角色的头部
            local char = instance.Character
            local head = char and char:FindFirstChild("Head")
            objData.Billboard.Adornee = head
            objData.Billboard.MaxDistance = CONFIG.MaxDistance
            objData.Billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and head ~= nil
            -- 更新文字显示
            if objData.NameLabel then
                objData.NameLabel.Text = getName(instance)
                objData.NameLabel.Visible = CONFIG.ShowName
            end
            if objData.HealthLabel then
                local health = getHealth(instance)
                objData.HealthLabel.Text = health and ("❤️ " .. health) or "❤️ ?"
                objData.HealthLabel.Visible = CONFIG.ShowHealth
            end
            -- 调整面板高度
            local numLines = (CONFIG.ShowName and 1 or 0) + (CONFIG.ShowHealth and 1 or 0)
            if numLines == 1 then
                objData.Billboard.Size = UDim2.new(0, 140, 0, 25)
            else
                objData.Billboard.Size = UDim2.new(0, 140, 0, 40)
            end
        end
    else
        -- 非玩家物体，无信息面板
        if objData.Billboard then objData.Billboard:Destroy() end
        objData.Billboard = nil
    end
end

-- 为一个实例添加ESP
function ESP:Add(instance)
    if not instance then return end
    if activeObjects[instance] then return end  -- 已存在
    
    local objData = {}
    activeObjects[instance] = objData
    
    -- 如果是玩家，需要监听角色变化
    if instance:IsA("Player") then
        local function onCharacterAdded(char)
            task.wait(0.1)
            updateVisual(instance, objData)
        end
        local function onCharacterRemoving()
            if objData.Billboard then objData.Billboard.Enabled = false end
            -- 清理附着在旧角色上的实例
            if objData.Highlight then objData.Highlight.Parent = nil end
            if objData.Box then objData.Box.Parent = nil end
        end
        if instance.Character then
            onCharacterAdded(instance.Character)
        end
        instance.CharacterAdded:Connect(onCharacterAdded)
        instance.CharacterRemoving:Connect(onCharacterRemoving)
        objData._charAddedConn = instance.CharacterAdded:Connect(onCharacterAdded)
        objData._charRemovedConn = instance.CharacterRemoving:Connect(onCharacterRemoving)
    end
    
    updateVisual(instance, objData)
end

-- 移除一个实例的ESP
function ESP:Remove(instance)
    local objData = activeObjects[instance]
    if objData then
        if objData.Highlight then objData.Highlight:Destroy() end
        if objData.Box then objData.Box:Destroy() end
        if objData.Billboard then objData.Billboard:Destroy() end
        if objData._charAddedConn then objData._charAddedConn:Disconnect() end
        if objData._charRemovedConn then objData._charRemovedConn:Disconnect() end
        activeObjects[instance] = nil
    end
end

-- 批量添加玩家
local function addAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP:Add(player)
        end
    end
end

-- 定时更新所有玩家血量/名称（批量刷新）
local function startUpdateLoop()
    if updateConnection then return end
    updateConnection = RunService.Stepped:Connect(function()
        local now = tick()
        if now - lastUpdateTime >= CONFIG.UpdateInterval then
            lastUpdateTime = now
            for instance, objData in pairs(activeObjects) do
                if instance:IsA("Player") and objData.Billboard and objData.HealthLabel and objData.HealthLabel.Visible then
                    local health = getHealth(instance)
                    if health then
                        objData.HealthLabel.Text = "❤️ " .. health
                    else
                        objData.HealthLabel.Text = "❤️ ?"
                    end
                    if objData.NameLabel and CONFIG.ShowName then
                        objData.NameLabel.Text = getName(instance)
                    end
                end
                -- 刷新颜色和模式（如果动态改变了配置）
                if instance:IsA("Player") or instance:IsA("BasePart") or instance:IsA("Model") then
                    updateVisual(instance, objData)
                end
            end
        end
    end)
end

-- 停止更新循环
local function stopUpdateLoop()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- 事件监听：新玩家加入
local function setupEventHandlers()
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

-- ==================== 公共API ====================
function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    setupEventHandlers()
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
    if mode == "Highlight" or mode == "Box" or mode == "Chams" then
        CONFIG.Mode = mode
        -- 立即刷新所有视觉样式
        for instance, objData in pairs(activeObjects) do
            updateVisual(instance, objData)
        end
    else
        warn("未知模式: " .. mode)
    end
end

function ESP:ShowName(show)
    CONFIG.ShowName = show
    for instance, objData in pairs(activeObjects) do
        if objData.NameLabel then
            objData.NameLabel.Visible = show
        end
        if objData.Billboard then
            local hasHead = instance.Character and instance.Character:FindFirstChild("Head")
            objData.Billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and hasHead ~= nil
        end
    end
end

function ESP:ShowHealth(show)
    CONFIG.ShowHealth = show
    for instance, objData in pairs(activeObjects) do
        if objData.HealthLabel then
            objData.HealthLabel.Visible = show
        end
        if objData.Billboard then
            local hasHead = instance.Character and instance.Character:FindFirstChild("Head")
            objData.Billboard.Enabled = (CONFIG.ShowName or CONFIG.ShowHealth) and hasHead ~= nil
        end
    end
end

function ESP:SetHealthGetter(func)
    CONFIG.HealthGetter = func
end

function ESP:SetColor(color3)
    CONFIG.CustomColor = color3
    for instance, objData in pairs(activeObjects) do
        updateVisual(instance, objData)
    end
end

function ESP:SetTeamColor(enable)
    CONFIG.TeamColor = enable
    if enable then
        CONFIG.CustomColor = nil
    end
    for instance, objData in pairs(activeObjects) do
        updateVisual(instance, objData)
    end
end

function ESP:SetMaxDistance(distance)
    CONFIG.MaxDistance = distance
    for instance, objData in pairs(activeObjects) do
        if objData.Billboard then
            objData.Billboard.MaxDistance = distance
        end
    end
end

function ESP:SetUpdateInterval(interval)
    CONFIG.UpdateInterval = math.max(0.1, interval)
end

function ESP:IsEnabled()
    return self._enabled or false
end

-- 通用物体添加/移除接口（供后续扩展）
function ESP:AddObject(instance)
    if not instance then return end
    ESP:Add(instance)
end

function ESP:RemoveObject(instance)
    ESP:Remove(instance)
end

return ESP
