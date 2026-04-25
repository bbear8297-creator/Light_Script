-- =====================================================
-- ESP 库 v1.2 (射线稳定版)
-- 修复: 本地玩家重生后射线自动重连
-- 支持: 玩家高亮 + 信息面板 + 通用物体 + 射线连线
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- 容器
local espContainer = Instance.new("Folder")
espContainer.Name = "ESP_Container"
local success = pcall(function() espContainer.Parent = CoreGui end)
if not success then espContainer.Parent = LocalPlayer:WaitForChild("PlayerGui") end

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
}

-- 获取本地玩家的射线连接点 (每次实时获取，避免缓存失效)
local function GetLocalAttachment()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not root then return nil end
    -- 确保附件存在
    local att = root:FindFirstChild("ESP_LocalAttachment")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "ESP_LocalAttachment"
        att.Parent = root
    end
    return att
end

-- 获取物体的根部件
local function GetRoot(instance)
    if instance:IsA("Player") then
        local char = instance.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("Model") then
        return instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Head") 
               or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("BasePart") then
        return instance
    end
    return nil
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
local function CreatePlayerBillboard()
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

-- 创建射线 (返回 beam, targetAttachment)
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

-- 重新绑定射线的起点 (本地角色重生后调用)
local function RefreshRayAttachment(beam)
    if not beam then return end
    local localAtt = GetLocalAttachment()
    if localAtt then
        beam.Attachment0 = localAtt
    end
end

-- ==================== 玩家管理 ====================
function ESP:AddPlayer(player)
    if player == LocalPlayer or self.activePlayers[player] then return end
    local data = {}
    
    local function setupCharacter(char)
        local root = GetRoot(char)
        if not root then return end
        data.highlight = CreateHighlight(char)
        data.billboard, data.nameLabel, data.healthLabel = CreatePlayerBillboard()
        data.billboard.Adornee = root
        -- 提前创建射线实例，启用/禁用由全局开关控制
        if root then
            data.beam, data.targetAtt = CreateRay(root, self.Settings.Color)
        end
        self:UpdatePlayerVis(player)
    end
    
    local function cleanupCharacter()
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        if data.beam then data.beam:Destroy() end
        if data.targetAtt then data.targetAtt:Destroy() end
    end
    
    data.charAdded = player.CharacterAdded:Connect(function(char)
        cleanupCharacter()
        task.wait(0.3)
        setupCharacter(char)
    end)
    data.charRemoved = player.CharacterRemoving:Connect(cleanupCharacter)
    
    if player.Character then setupCharacter(player.Character) end
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

function ESP:UpdatePlayerVis(player)
    local data = self.activePlayers[player]
    if not data or not data.highlight then return end
    
    local enabled = self._enabled
    local root = GetRoot(player.Character)
    local localRoot = GetRoot(LocalPlayer.Character)
    local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
    local show = enabled and (distance <= self.Settings.MaxDistance) and (root ~= nil)
    
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
    
    -- 射线
    if data.beam then
        local rayShow = show and self.Settings.ShowRay
        data.beam.Enabled = rayShow
        if rayShow then
            -- 关键修复: 每次启用时强制刷新本地 Attachment
            RefreshRayAttachment(data.beam)
            data.beam.Color = ColorSequence.new(color)
        end
    end
end

-- ==================== 通用物体管理 ====================
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
        text = options.text or "",
        textColor = options.textColor or Color3.new(1,1,1),
        onUpdate = options.onUpdate,
        options = options,
    }
    
    data.highlight = CreateHighlight(instance)
    data.highlight.FillColor = data.textColor
    data.highlight.OutlineColor = data.textColor
    
    if options.text then
        local bb, lbl, _ = CreatePlayerBillboard()
        bb.StudsOffset = Vector3.new(0, options.offsetY or 1.5, 0)
        bb.Size = UDim2.new(0, 100, 0, 25)
        bb.Adornee = root
        lbl.Text = data.text
        lbl.TextColor3 = data.textColor
        lbl.Size = UDim2.new(1,0,1,0)
        data.billboard = bb
        data.nameLabel = lbl
    end
    
    -- 物体也能添加射线
    if root then
        data.beam, data.targetAtt = CreateRay(root, data.textColor)
    end
    
    data.destroyConn = instance.AncestryChanged:Connect(function()
        if not instance.Parent then self:RemoveObject(instance) end
    end)
    
    self.activeObjects[instance] = data
    self:UpdateObjectVis(instance)
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

function ESP:UpdateObjectVis(instance)
    local data = self.activeObjects[instance]
    if not data then return end
    
    local enabled = self._enabled
    local root = GetRoot(instance)
    local localRoot = GetRoot(LocalPlayer.Character)
    local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
    local show = enabled and (distance <= self.Settings.MaxDistance) and (root ~= nil)
    
    data.highlight.Enabled = show
    if data.billboard then
        data.billboard.Enabled = show
        if show and data.onUpdate then pcall(data.onUpdate, instance) end
    end
    if data.beam then
        local rayShow = show and self.Settings.ShowRay
        data.beam.Enabled = rayShow
        if rayShow then
            RefreshRayAttachment(data.beam)
            data.beam.Color = ColorSequence.new(data.textColor)
        end
    end
end

-- ==================== 条件检查 ====================
function ESP:RefreshConditions()
    for instance, data in pairs(self.activeObjects) do
        if data.conditionFunc then
            local ok, res = pcall(data.conditionFunc, instance)
            if not ok or not res then
                self:RemoveObject(instance)
            end
        end
    end
end

-- ==================== 主循环 ====================
local lastUpdate = 0
local lastCondition = 0
RunService.Heartbeat:Connect(function(dt)
    if not ESP._enabled then return end
    lastUpdate = lastUpdate + dt
    lastCondition = lastCondition + dt
    
    if lastUpdate >= ESP.Settings.UpdateInterval then
        lastUpdate = 0
        for player in pairs(ESP.activePlayers) do
            ESP:UpdatePlayerVis(player)
        end
        for obj in pairs(ESP.activeObjects) do
            ESP:UpdateObjectVis(obj)
        end
    end
    
    if lastCondition >= ESP.Settings.ConditionInterval then
        lastCondition = 0
        ESP:RefreshConditions()
    end
end)

-- 监听本地角色重生，届时所有射线的 Attachment0 会在下次 RefreshRayAttachment 中修复
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    for _, data in pairs(ESP.activePlayers) do
        if data.beam then RefreshRayAttachment(data.beam) end
    end
    for _, data in pairs(ESP.activeObjects) do
        if data.beam then RefreshRayAttachment(data.beam) end
    end
end)

-- 玩家进出监听
Players.PlayerAdded:Connect(ESP.AddPlayer)
Players.PlayerRemoving:Connect(ESP.RemovePlayer)

-- ==================== 公开 API ====================
function ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then self:AddPlayer(player) end
    end
    self:RefreshConditions()
end

function ESP:Disable()
    self._enabled = false
    for player, _ in pairs(self.activePlayers) do self:UpdatePlayerVis(player) end
    for obj, _ in pairs(self.activeObjects) do self:UpdateObjectVis(obj) end
end

function ESP:IsEnabled() return self._enabled end

function ESP:ShowRay(val) self.Settings.ShowRay = val; self:RefreshConditions() end
function ESP:ShowName(val) self.Settings.ShowName = val; self:RefreshConditions() end
function ESP:ShowHealth(val) self.Settings.ShowHealth = val; self:RefreshConditions() end
function ESP:SetColor(color) self.Settings.Color = color; self:RefreshConditions() end
function ESP:SetTeamColor(val) self.Settings.UseTeamColor = val; self:RefreshConditions() end
function ESP:SetMaxDistance(dist) self.Settings.MaxDistance = dist; self:RefreshConditions() end
function ESP:SetUpdateInterval(sec) self.Settings.UpdateInterval = sec end
function ESP:SetConditionCheckInterval(sec) self.Settings.ConditionInterval = sec end
function ESP:SetHealthGetter(func) self.Settings.HealthGetter = func; self:RefreshConditions() end
function ESP:SetMode(mode) end

return ESP
