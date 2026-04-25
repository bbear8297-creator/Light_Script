--[[
    High-Performance ESP Library v1.0
    Supported for Universal & Dynamic games (e.g., Doors)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- 创建安全容器
local espContainer = Instance.new("Folder")
espContainer.Name = "ESP_Container"
local success = pcall(function() espContainer.Parent = CoreGui end)
if not success then 
    espContainer.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

local ESP = {
    _enabled = false,
    Settings = {
        ShowName = true,
        ShowHealth = true,
        ShowRay = false,
        Color = Color3.fromRGB(255, 255, 255),
        UseTeamColor = false,
        MaxDistance = 1000,
        UpdateInterval = 0.3,
        ConditionInterval = 1.0,
        HealthGetter = nil,
    },
    activePlayers = {},
    activeObjects = {},
    connections = {}
}

-- ==========================================
-- 内部辅助函数
-- ==========================================

-- 获取有效根部件
local function GetRoot(characterOrModel)
    if not characterOrModel then return nil end
    return characterOrModel:FindFirstChild("HumanoidRootPart") 
        or characterOrModel:FindFirstChild("Head") 
        or characterOrModel:FindFirstChildWhichIsA("BasePart")
end

-- 获取本地玩家射线起点 Attachment
local localAttachment = nil
local function GetLocalAttachment()
    local root = GetRoot(LocalPlayer.Character)
    if not root then return nil end
    if not localAttachment or not localAttachment.Parent then
        localAttachment = Instance.new("Attachment")
        localAttachment.Name = "ESP_LocalAttachment"
        localAttachment.Parent = root
    end
    return localAttachment
end

-- ==========================================
-- 核心创建函数
-- ==========================================

local function CreateHighlight(target)
    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.1
    hl.Parent = espContainer
    return hl
end

local function CreateBillboard()
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = bb
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0
    nameLbl.LayoutOrder = 1
    nameLbl.Parent = bb
    
    local healthLbl = Instance.new("TextLabel")
    healthLbl.BackgroundTransparency = 1
    healthLbl.Size = UDim2.new(1, 0, 0.5, 0)
    healthLbl.Font = Enum.Font.Gotham
    healthLbl.TextSize = 10
    healthLbl.TextStrokeTransparency = 0
    healthLbl.LayoutOrder = 2
    healthLbl.Parent = bb
    
    bb.Parent = espContainer
    return bb, nameLbl, healthLbl
end

local function CreateBeam(targetPart)
    local att1 = Instance.new("Attachment")
    att1.Parent = targetPart
    
    local beam = Instance.new("Beam")
    beam.FaceCamera = true
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Attachment0 = GetLocalAttachment()
    beam.Attachment1 = att1
    beam.Parent = espContainer
    
    return beam, att1
end

-- ==========================================
-- 玩家处理逻辑
-- ==========================================

function ESP:AddPlayer(player)
    if player == LocalPlayer or self.activePlayers[player] then return end
    
    local data = {}
    
    local function setupCharacter(char)
        local root = GetRoot(char)
        if not root then return end
        
        data.highlight = CreateHighlight(char)
        data.billboard, data.nameLabel, data.healthLabel = CreateBillboard()
        data.billboard.Adornee = root
        data.beam, data.att1 = CreateBeam(root)
        
        -- 初始状态更新
        self:UpdatePlayerVisuals(player)
    end
    
    local function cleanupCharacter()
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.beam then data.beam:Destroy() end
        if data.att1 then data.att1:Destroy() end
    end
    
    data.charAdded = player.CharacterAdded:Connect(function(char)
        cleanupCharacter()
        task.wait(0.5) -- 等待模型加载完毕
        setupCharacter(char)
    end)
    
    data.charRemoved = player.CharacterRemoving:Connect(cleanupCharacter)
    
    if player.Character then
        setupCharacter(player.Character)
    end
    
    self.activePlayers[player] = data
end

function ESP:RemovePlayer(player)
    local data = self.activePlayers[player]
    if data then
        if data.charAdded then data.charAdded:Disconnect() end
        if data.charRemoved then data.charRemoved:Disconnect() end
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.beam then data.beam:Destroy() end
        if data.att1 then data.att1:Destroy() end
        self.activePlayers[player] = nil
    end
end

function ESP:UpdatePlayerVisuals(player)
    local data = self.activePlayers[player]
    if not data or not data.highlight then return end
    
    local isEnabled = self._enabled
    local root = GetRoot(player.Character)
    local distance = root and LocalPlayer.Character and GetRoot(LocalPlayer.Character) 
        and (root.Position - GetRoot(LocalPlayer.Character).Position).Magnitude or 0
    
    local withinDistance = distance <= self.Settings.MaxDistance
    local show = isEnabled and withinDistance

    -- 颜色逻辑
    local color = self.Settings.Color
    if self.Settings.UseTeamColor and player.Team then
        color = player.Team.TeamColor.Color
    end

    data.highlight.Enabled = show
    data.highlight.FillColor = color
    data.highlight.OutlineColor = color

    data.billboard.Enabled = show and (self.Settings.ShowName or self.Settings.ShowHealth)
    
    if data.billboard.Enabled then
        data.nameLabel.Visible = self.Settings.ShowName
        data.nameLabel.Text = player.DisplayName
        data.nameLabel.TextColor3 = color
        
        data.healthLabel.Visible = self.Settings.ShowHealth
        if self.Settings.ShowHealth then
            local hp, maxHp = "?", "?"
            if self.Settings.HealthGetter then
                hp = self.Settings.HealthGetter(player) or "?"
            elseif player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                hp, maxHp = math.floor(hum.Health), math.floor(hum.MaxHealth)
            end
            data.healthLabel.Text = "❤️ " .. tostring(hp) .. " / " .. tostring(maxHp)
            data.healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    data.beam.Enabled = show and self.Settings.ShowRay
    if data.beam.Enabled then
        data.beam.Color = ColorSequence.new(color)
        -- 确保射线起点有效
        if not data.beam.Attachment0 or not data.beam.Attachment0.Parent then
            data.beam.Attachment0 = GetLocalAttachment()
        end
    end
end

-- ==========================================
-- 通用物体处理逻辑
-- ==========================================

function ESP:AddObject(instance, options)
    self:AddObjectWithCondition(instance, options, nil)
end

function ESP:AddObjectWithCondition(instance, options, conditionFunc)
    if self.activeObjects[instance] then return end
    options = options or {}
    
    local root = GetRoot(instance) or instance
    if not root:IsA("BasePart") then return end

    local data = {
        conditionFunc = conditionFunc,
        options = options,
        text = options.text or "",
        textColor = options.textColor or Color3.new(1, 1, 1),
        onUpdate = options.onUpdate
    }
    
    data.highlight = CreateHighlight(instance)
    data.highlight.FillColor = data.textColor
    data.highlight.OutlineColor = data.textColor
    
    if options.text then
        data.billboard, data.nameLabel, _ = CreateBillboard()
        data.billboard.Adornee = root
        data.billboard.StudsOffset = Vector3.new(0, options.offsetY or 1.5, 0)
        data.nameLabel.Text = data.text
        data.nameLabel.TextColor3 = data.textColor
    end
    
    data.beam, data.att1 = CreateBeam(root)
    
    data.destroyConn = instance.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:RemoveObject(instance)
        end
    end)
    
    self.activeObjects[instance] = data
    self:UpdateObjectVisuals(instance)
end

function ESP:UpdateObjectText(instance, newText)
    local data = self.activeObjects[instance]
    if data and data.nameLabel then
        data.text = newText
        data.nameLabel.Text = newText
    end
end

function ESP:RemoveObject(instance)
    local data = self.activeObjects[instance]
    if data then
        if data.destroyConn then data.destroyConn:Disconnect() end
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.beam then data.beam:Destroy() end
        if data.att1 then data.att1:Destroy() end
        self.activeObjects[instance] = nil
    end
end

function ESP:UpdateObjectVisuals(instance)
    local data = self.activeObjects[instance]
    if not data then return end
    
    local isEnabled = self._enabled
    local root = GetRoot(instance) or instance
    local distance = root and LocalPlayer.Character and GetRoot(LocalPlayer.Character) 
        and (root.Position - GetRoot(LocalPlayer.Character).Position).Magnitude or 0
    
    -- 距离检查剔除，防止超出31个Highlight上限
    local withinDistance = distance <= self.Settings.MaxDistance
    local show = isEnabled and withinDistance
    
    data.highlight.Enabled = show
    if data.billboard then
        data.billboard.Enabled = show
    end
    
    data.beam.Enabled = show and self.Settings.ShowRay
    if data.beam.Enabled then
        data.beam.Color = ColorSequence.new(data.textColor)
        if not data.beam.Attachment0 or not data.beam.Attachment0.Parent then
            data.beam.Attachment0 = GetLocalAttachment()
        end
    end
end

-- ==========================================
-- 条件管理与主循环
-- ==========================================

function ESP:CheckCondition(instance)
    local data = self.activeObjects[instance]
    if data and data.conditionFunc then
        local passed = pcall(function() return data.conditionFunc(instance) end)
        if not passed or data.conditionFunc(instance) == false then
            self:RemoveObject(instance)
            return false
        end
    end
    return true
end

function ESP:RefreshConditions()
    for instance, _ in pairs(self.activeObjects) do
        self:CheckCondition(instance)
    end
end

-- 启动定时器
local lastUpdate = 0
local lastConditionCheck = 0

RunService.Heartbeat:Connect(function(dt)
    if not ESP._enabled then return end
    
    lastUpdate += dt
    lastConditionCheck += dt
    
    -- 高频更新：血量、距离判断、动态文字
    if lastUpdate >= ESP.Settings.UpdateInterval then
        lastUpdate = 0
        for player, _ in pairs(ESP.activePlayers) do
            ESP:UpdatePlayerVisuals(player)
        end
        for instance, data in pairs(ESP.activeObjects) do
            if data.onUpdate then
                pcall(function() data.onUpdate(instance) end)
            end
            ESP:UpdateObjectVisuals(instance)
        end
    end
    
    -- 低频更新：条件管理（自动销毁不合格物体，如切换房间）
    if lastConditionCheck >= ESP.Settings.ConditionInterval then
        lastConditionCheck = 0
        ESP:RefreshConditions()
    end
end)

-- 监听本地玩家重生（修复射线断裂问题）
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    localAttachment = nil -- 强制重置起点 Attachment
    GetLocalAttachment()
end)

-- 监听全局玩家进出
Players.PlayerAdded:Connect(function(player)
    ESP:AddPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player)
    ESP:RemovePlayer(player)
end)

-- ==========================================
-- 公开 API 接口
-- ==========================================

function ESP:Enable()
    self._enabled = true
    for _, player in pairs(Players:GetPlayers()) do
        self:AddPlayer(player)
    end
    self:RefreshConditions() -- 强制更新一次显示状态
end

function ESP:Disable()
    self._enabled = false
    -- 将所有 enabled 设为 false，保留对象
    for player, _ in pairs(self.activePlayers) do
        self:UpdatePlayerVisuals(player)
    end
    for instance, _ in pairs(self.activeObjects) do
        self:UpdateObjectVisuals(instance)
    end
end

function ESP:IsEnabled() return self._enabled end

function ESP:ShowName(val) self.Settings.ShowName = val; self:RefreshConditions() end
function ESP:ShowHealth(val) self.Settings.ShowHealth = val; self:RefreshConditions() end
function ESP:ShowRay(val) self.Settings.ShowRay = val; self:RefreshConditions() end
function ESP:SetMode(mode) end -- 预留占位符，仅使用 Highlight
function ESP:SetColor(color) self.Settings.Color = color; self:RefreshConditions() end
function ESP:SetTeamColor(val) self.Settings.UseTeamColor = val; self:RefreshConditions() end
function ESP:SetMaxDistance(dist) self.Settings.MaxDistance = dist; self:RefreshConditions() end
function ESP:SetUpdateInterval(sec) self.Settings.UpdateInterval = sec end
function ESP:SetConditionCheckInterval(sec) self.Settings.ConditionInterval = sec end
function ESP:SetHealthGetter(func) self.Settings.HealthGetter = func; self:RefreshConditions() end

return ESP
