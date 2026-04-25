--[[
    High-Performance ESP Library v1.1 (射线修复版)
    支持玩家自动追踪、通用物体高亮、距离剔除、射线连线
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

-- 本地玩家射线附件（全局复用，角色重连时自动重新获取）
local localAttachment = nil

local function GetLocalAttachment()
    local character = LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not root then return nil end
    if not localAttachment or localAttachment.Parent ~= root then
        localAttachment = Instance.new("Attachment")
        localAttachment.Name = "ESP_LocalAttachment"
        localAttachment.Parent = root
    end
    return localAttachment
end

-- 获取有效根部件
local function GetRoot(instance)
    if instance:IsA("Player") then
        local char = instance.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("Model") then
        return instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Head") or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("BasePart") then
        return instance
    else
        return nil
    end
end

-- 创建高亮
local function CreateHighlight(target)
    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.1
    hl.Parent = espContainer
    return hl
end

-- 创建玩家信息面板
local function CreateBillboard()
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 120, 0, 40)
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

-- 创建射线（Beam）
local function CreateRay(targetRoot, color)
    local localAtt = GetLocalAttachment()
    if not localAtt or not targetRoot then return nil, nil end
    local targetAtt = Instance.new("Attachment")
    targetAtt.Parent = targetRoot
    local beam = Instance.new("Beam")
    beam.Attachment0 = localAtt
    beam.Attachment1 = targetAtt
    beam.Color = ColorSequence.new(color)
    beam.FaceCamera = true
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.LightEmission = 1
    beam.Parent = espContainer
    return beam, targetAtt
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
        
        -- 射线创建（暂时不设置 Enabled，等待全局开关）
        if root then
            local localAtt = GetLocalAttachment()
            if localAtt then
                data.beam, data.targetAtt = CreateRay(root, self.Settings.Color)
            end
        end
        self:UpdatePlayerVisuals(player)
    end
    
    local function cleanupCharacter()
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.beam then data.beam:Destroy() end
        if data.targetAtt then data.targetAtt:Destroy() end
    end
    
    data.charAdded = player.CharacterAdded:Connect(function(char)
        cleanupCharacter()
        task.wait(0.5)
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
        if data.targetAtt then data.targetAtt:Destroy() end
        self.activePlayers[player] = nil
    end
end

function ESP:UpdatePlayerVisuals(player)
    local data = self.activePlayers[player]
    if not data or not data.highlight then return end
    
    local isEnabled = self._enabled
    local root = GetRoot(player.Character)
    local localRoot = GetRoot(LocalPlayer.Character)
    local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
    local withinDistance = distance <= self.Settings.MaxDistance
    local show = isEnabled and withinDistance and root ~= nil

    -- 颜色
    local color = self.Settings.Color
    if self.Settings.UseTeamColor and player.Team then
        color = player.Team.TeamColor.Color
    end

    data.highlight.Enabled = show
    data.highlight.FillColor = color
    data.highlight.OutlineColor = color

    -- 信息面板
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

    -- 射线：仅当全局开关打开、ESP启用且在距离内
    if data.beam then
        local rayEnabled = show and self.Settings.ShowRay
        data.beam.Enabled = rayEnabled
        if rayEnabled then
            data.beam.Color = ColorSequence.new(color)
            -- 确保 Attachment0 是最新的（本地角色可能重生）
            local localAtt = GetLocalAttachment()
            if localAtt and data.beam.Attachment0 ~= localAtt then
                data.beam.Attachment0 = localAtt
            end
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
    
    local root = GetRoot(instance)
    if not root then return end
    
    local data = {
        conditionFunc = conditionFunc,
        options = options,
        text = options.text or "",
        textColor = options.textColor or Color3.new(1,1,1),
        onUpdate = options.onUpdate
    }
    
    data.highlight = CreateHighlight(instance)
    data.highlight.FillColor = data.textColor
    data.highlight.OutlineColor = data.textColor
    
    if options.text then
        local billboard, nameLabel, _ = CreateBillboard()
        billboard.StudsOffset = Vector3.new(0, options.offsetY or 1.5, 0)
        billboard.Size = UDim2.new(0, 100, 0, 25)
        billboard.Adornee = root
        nameLabel.Text = data.text
        nameLabel.TextColor3 = data.textColor
        nameLabel.Size = UDim2.new(1,0,1,0)
        data.billboard = billboard
        data.nameLabel = nameLabel
    end
    
    -- 射线
    if root then
        data.beam, data.targetAtt = CreateRay(root, data.textColor)
    end
    
    data.destroyConn = instance.AncestryChanged:Connect(function()
        if not instance.Parent then
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
        if data.targetAtt then data.targetAtt:Destroy() end
        self.activeObjects[instance] = nil
    end
end

function ESP:UpdateObjectVisuals(instance)
    local data = self.activeObjects[instance]
    if not data then return end
    
    local isEnabled = self._enabled
    local root = GetRoot(instance)
    local localRoot = GetRoot(LocalPlayer.Character)
    local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
    local withinDistance = distance <= self.Settings.MaxDistance
    local show = isEnabled and withinDistance and root ~= nil

    data.highlight.Enabled = show
    if data.billboard then
        data.billboard.Enabled = show
        if show and data.onUpdate then
            pcall(data.onUpdate, instance)
        end
    end
    if data.beam then
        data.beam.Enabled = show and self.Settings.ShowRay
        if data.beam.Enabled then
            data.beam.Color = ColorSequence.new(data.textColor)
            local localAtt = GetLocalAttachment()
            if localAtt and data.beam.Attachment0 ~= localAtt then
                data.beam.Attachment0 = localAtt
            end
        end
    end
end

-- ==========================================
-- 条件管理与主循环
-- ==========================================

function ESP:CheckCondition(instance)
    local data = self.activeObjects[instance]
    if data and data.conditionFunc then
        local ok, result = pcall(data.conditionFunc, instance)
        if not ok or not result then
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

-- 定时器
local lastUpdate = 0
local lastConditionCheck = 0

RunService.Heartbeat:Connect(function(dt)
    if not ESP._enabled then return end
    
    lastUpdate = lastUpdate + dt
    lastConditionCheck = lastConditionCheck + dt
    
    if lastUpdate >= ESP.Settings.UpdateInterval then
        lastUpdate = 0
        for player, _ in pairs(ESP.activePlayers) do
            ESP:UpdatePlayerVisuals(player)
        end
        for instance, _ in pairs(ESP.activeObjects) do
            ESP:UpdateObjectVisuals(instance)
        end
    end
    
    if lastConditionCheck >= ESP.Settings.ConditionInterval then
        lastConditionCheck = 0
        ESP:RefreshConditions()
    end
end)

-- 玩家进出监听
Players.PlayerAdded:Connect(function(player)
    ESP:AddPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player)
    ESP:RemovePlayer(player)
end)

-- 本地玩家重生时重置射线附件（已有 GetLocalAttachment 会自动处理）
LocalPlayer.CharacterAdded:Connect(function()
    localAttachment = nil
end)

-- ==========================================
-- 公开 API
-- ==========================================

function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end
    self:RefreshConditions()
end

function ESP:Disable()
    self._enabled = false
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
function ESP:SetMode(mode) end
function ESP:SetColor(color) self.Settings.Color = color; self:RefreshConditions() end
function ESP:SetTeamColor(val) self.Settings.UseTeamColor = val; self:RefreshConditions() end
function ESP:SetMaxDistance(dist) self.Settings.MaxDistance = dist; self:RefreshConditions() end
function ESP:SetUpdateInterval(sec) self.Settings.UpdateInterval = sec end
function ESP:SetConditionCheckInterval(sec) self.Settings.ConditionInterval = sec end
function ESP:SetHealthGetter(func) self.Settings.HealthGetter = func; self:RefreshConditions() end

return ESP
