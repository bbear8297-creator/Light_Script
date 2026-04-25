-- ==================== ESP库（高性能版） ====================
-- 依赖：Roblox服务（Players, RunService）
-- 特性：Highlight隔墙高亮、可选信息面板（名称/血量）、动画更新优化、低配置模式
-- 作者：LS Team 适配

local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置参数（用户可调整）
local CONFIG = {
    UpdateInterval = 0.3,           -- 血量/名称更新间隔（秒），越高性能越好
    MaxDistance = 150,              -- 信息面板最大显示距离（超出则隐藏）
    UseDefaultHealth = true,        -- 是否使用默认血量获取（从Humanoid.Health读取）
    HealthGetter = nil,             -- 自定义血量获取函数 function(plr) return number end
    TeamColor = true,               -- 是否根据队伍显示高亮颜色
    CustomColor = nil,              -- 自定义高亮颜色（Color3），优先级高于队伍色
    Mode = "Highlight",             -- 当前模式："Highlight", "Box", "Chams"（后两者暂未实现降级方案）
    ShowName = true,
    ShowHealth = true,
}

-- 内部数据
local activeEsp = {}               -- [player] = {Highlight, BillboardGui}
local updateTask = nil
local currentMode = CONFIG.Mode

-- 辅助函数：获取玩家队伍颜色（如果有Team）
local function getTeamColor(player)
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)  -- 默认红色
end

-- 辅助函数：获取玩家血量
local function getPlayerHealth(player)
    if CONFIG.HealthGetter then
        local ok, val = pcall(CONFIG.HealthGetter, player)
        if ok and type(val) == "number" then
            return math.floor(val)
        end
    end
    if CONFIG.UseDefaultHealth then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            return math.floor(char.Humanoid.Health)
        end
    end
    return nil
end

-- 创建或更新单个玩家的 ESP 显示
local function updateESPForPlayer(player)
    -- 跳过本地玩家
    if player == LocalPlayer then return end
    
    local esp = activeEsp[player]
    if not esp then
        -- 首次创建
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.OutlineTransparency = 0.4
        highlight.FillTransparency = 0.6
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- 隔墙可见核心
        highlight.Adornee = player.Character
        
        -- 信息面板（BillboardGui）
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Info"
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = CONFIG.MaxDistance
        billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
        
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
        nameLabel.Text = player.Name
        nameLabel.Parent = frame
        
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = Color3.new(0.8,1,0.8)
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextSize = 12
        healthLabel.Text = "HP: ?"
        healthLabel.Parent = frame
        
        esp = {
            Highlight = highlight,
            Billboard = billboard,
            NameLabel = nameLabel,
            HealthLabel = healthLabel
        }
        activeEsp[player] = esp
        
        -- 如果角色后来才出现，需要重新设置Adornee
        local function onCharacterAdded(char)
            if not esp.Highlight or not esp.Highlight.Parent then return end
            esp.Highlight.Adornee = char
            local head = char:FindFirstChild("Head")
            if head and esp.Billboard then
                esp.Billboard.Adornee = head
            end
        end
        if player.Character then
            onCharacterAdded(player.Character)
        end
        player.CharacterAdded:Connect(onCharacterAdded)
    end
    
    -- 更新高亮颜色（根据模式）
    if currentMode == "Highlight" then
        local color = CONFIG.CustomColor
        if not color and CONFIG.TeamColor then
            color = getTeamColor(player)
        elseif not color then
            color = Color3.fromRGB(255, 255, 0)  -- 默认黄色
        end
        esp.Highlight.FillColor = color
        esp.Highlight.OutlineColor = color
        
        if not esp.Highlight.Parent then
            esp.Highlight.Parent = player.Character or player
        end
    else
        -- 其他模式（Box/Chams）暂用Highlight降级，保证可用
        if esp.Highlight then esp.Highlight.Parent = nil end
    end
    
    -- 更新信息面板可见性及内容
    if esp.Billboard then
        local show = (CONFIG.ShowName or CONFIG.ShowHealth) and player.Character and player.Character:FindFirstChild("Head")
        if show then
            esp.Billboard.Enabled = true
            if CONFIG.ShowName then
                esp.NameLabel.Text = player.Name
                esp.NameLabel.Visible = true
            else
                esp.NameLabel.Visible = false
            end
            if CONFIG.ShowHealth then
                local health = getPlayerHealth(player)
                if health then
                    esp.HealthLabel.Text = "❤️ " .. health
                else
                    esp.HealthLabel.Text = "❤️ ?"
                end
                esp.HealthLabel.Visible = true
            else
                esp.HealthLabel.Visible = false
            end
            -- 根据显示内容调整面板高度
            local numLines = (CONFIG.ShowName and 1 or 0) + (CONFIG.ShowHealth and 1 or 0)
            if numLines == 1 then
                esp.Billboard.Size = UDim2.new(0, 140, 0, 25)
            else
                esp.Billboard.Size = UDim2.new(0, 140, 0, 40)
            end
        else
            esp.Billboard.Enabled = false
        end
    end
end

-- 定时批量更新血量信息（避免每帧更新）
local function startUpdateLoop()
    if updateTask then return end
    updateTask = RunService.Stepped:Connect(function()
        -- 用步进触发但限制实际更新频率，此处简单用时间差控制
        local now = tick()
        if not ESP._lastUpdate then ESP._lastUpdate = now end
        if now - ESP._lastUpdate >= CONFIG.UpdateInterval then
            ESP._lastUpdate = now
            for player, esp in pairs(activeEsp) do
                if player and esp and esp.HealthLabel and esp.HealthLabel.Visible then
                    local health = getPlayerHealth(player)
                    if health then
                        esp.HealthLabel.Text = "❤️ " .. health
                    else
                        esp.HealthLabel.Text = "❤️ ?"
                    end
                end
            end
        end
    end)
end

-- 停止更新循环
local function stopUpdateLoop()
    if updateTask then
        updateTask:Disconnect()
        updateTask = nil
    end
end

-- 监听玩家进出
local function setupEventHandlers()
    Players.PlayerAdded:Connect(function(player)
        -- 延迟一小段时间等待角色加载
        task.wait(0.2)
        updateESPForPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        local esp = activeEsp[player]
        if esp then
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
            activeEsp[player] = nil
        end
    end)
    -- 监听角色移除（死亡重生）
    for _, player in ipairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            updateESPForPlayer(player)
        end)
        player.CharacterRemoving:Connect(function()
            local esp = activeEsp[player]
            if esp and esp.Billboard then
                esp.Billboard.Enabled = false
            end
        end)
    end
end

-- ==================== 公共 API ====================
-- 启用ESP（默认高亮模式）
function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    setupEventHandlers()
    startUpdateLoop()
    -- 为所有当前玩家创建ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end

-- 关闭ESP并清除所有创建的实例
function ESP:Disable()
    self._enabled = false
    stopUpdateLoop()
    for player, esp in pairs(activeEsp) do
        if esp.Highlight then esp.Highlight:Destroy() end
        if esp.Billboard then esp.Billboard:Destroy() end
    end
    activeEsp = {}
end

-- 设置ESP显示模式（目前仅实现Highlight，其他模式可扩展）
function ESP:SetMode(mode)
    if mode ~= "Highlight" and mode ~= "Box" and mode ~= "Chams" then
        warn("ESP模式暂不支持: " .. mode .. "，已降级为Highlight")
        mode = "Highlight"
    end
    currentMode = mode
    CONFIG.Mode = mode
    -- 刷新高亮开关
    for player, esp in pairs(activeEsp) do
        if mode == "Highlight" then
            if esp.Highlight and player.Character then
                esp.Highlight.Parent = player.Character
            end
        else
            if esp.Highlight then esp.Highlight.Parent = nil end
        end
    end
end

-- 设置是否显示名称
function ESP:ShowName(show)
    CONFIG.ShowName = show
    for _, esp in pairs(activeEsp) do
        if esp.NameLabel then
            esp.NameLabel.Visible = show
        end
    end
end

-- 设置是否显示血量
function ESP:ShowHealth(show)
    CONFIG.ShowHealth = show
    for _, esp in pairs(activeEsp) do
        if esp.HealthLabel then
            esp.HealthLabel.Visible = show
        end
    end
end

-- 自定义血量获取函数（用于Dex读取Value）
function ESP:SetHealthGetter(func)
    CONFIG.HealthGetter = func
    CONFIG.UseDefaultHealth = (func == nil)
end

-- 设置高亮颜色（优先级高于队伍颜色），传入nil则使用队伍颜色/默认
function ESP:SetColor(color3)
    CONFIG.CustomColor = color3
    for _, esp in pairs(activeEsp) do
        if esp.Highlight then
            local finalColor = color3 or (CONFIG.TeamColor and getTeamColor(esp._cachedPlayer) or Color3.fromRGB(255,255,0))
            esp.Highlight.FillColor = finalColor
            esp.Highlight.OutlineColor = finalColor
        end
    end
end

-- 设置是否依据队伍自动上色
function ESP:SetTeamColor(enable)
    CONFIG.TeamColor = enable
    if not CONFIG.CustomColor then
        for player, esp in pairs(activeEsp) do
            if esp.Highlight then
                local color = enable and getTeamColor(player) or Color3.fromRGB(255,255,0)
                esp.Highlight.FillColor = color
                esp.Highlight.OutlineColor = color
            end
        end
    end
end

-- 设置信息面板最大显示距离（优化远处玩家）
function ESP:SetMaxDistance(distance)
    CONFIG.MaxDistance = distance
    for _, esp in pairs(activeEsp) do
        if esp.Billboard then
            esp.Billboard.MaxDistance = distance
        end
    end
end

-- 设置全局更新间隔（降低CPU占用）
function ESP:SetUpdateInterval(interval)
    CONFIG.UpdateInterval = math.max(0.1, interval)
end

-- 可选：获取当前状态
function ESP:IsEnabled()
    return self._enabled or false
end

return ESP