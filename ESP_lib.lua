--[[
    ESP Library v3.0 Refactor
    适用：Roblox LocalScript / 客户端调试可视化覆盖层

    设计目标：
      1. 更完整：玩家、物体、分组、条件、过滤器、距离、血量、名称、Highlight、Tracer/射线。
      2. 更好用：统一 Configure / Enable / Disable / TrackObject / UntrackObject API。
      3. 更稳定：所有视觉实例集中管理，角色重生自动重建，销毁安全，连接可控。
      4. 射线修复：Tracer 使用 Workspace 下的透明锚点 Part + Beam + Attachment，避免挂在 CoreGui/Folder 导致不渲染。
      5. 兼容旧接口：保留 AddPlayer、RemovePlayer、AddObject、AddObjectWithCondition、SetShowRay 等常用方法。

    注意：
      - 本库只负责客户端可视化。请用于你拥有控制权的体验、测试服或调试工具。
      - Beam/Highlight/BillboardGui 的表现会受 Roblox 客户端权限、StreamingEnabled、角色结构影响。
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// Small utilities
local function noop() end

local function safeCall(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then
        return true, a, b, c, d
    end
    return false, a
end

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function isInstance(value)
    return typeof(value) == "Instance"
end

local function isAliveInstance(instance)
    return isInstance(instance) and instance.Parent ~= nil
end

local function deepCopy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = deepCopy(v)
        else
            out[k] = v
        end
    end
    return out
end

local function deepMerge(base, patch)
    if type(patch) ~= "table" then
        return base
    end
    for k, v in pairs(patch) do
        if type(v) == "table" and type(base[k]) == "table" then
            deepMerge(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end

local function trySet(obj, prop, value)
    if obj and obj.Parent then
        pcall(function()
            obj[prop] = value
        end)
    end
end

local function getRoot(modelOrPart)
    if not modelOrPart then
        return nil
    end
    if modelOrPart:IsA("BasePart") then
        return modelOrPart
    end
    if modelOrPart:IsA("Model") then
        return modelOrPart:FindFirstChild("HumanoidRootPart")
            or modelOrPart:FindFirstChild("UpperTorso")
            or modelOrPart:FindFirstChild("Torso")
            or modelOrPart:FindFirstChild("Head")
            or modelOrPart.PrimaryPart
            or modelOrPart:FindFirstChildWhichIsA("BasePart", true)
    end
    if modelOrPart:IsA("Attachment") then
        return modelOrPart.Parent
    end
    return nil
end

local function getHumanoid(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    return model:FindFirstChildOfClass("Humanoid")
end

local function healthColor(ratio)
    ratio = math.clamp(ratio or 0, 0, 1)
    if ratio >= 0.5 then
        return Color3.fromRGB(math.floor(510 * (1 - ratio)), 255, 0)
    end
    return Color3.fromRGB(255, math.floor(510 * ratio), 0)
end

local function asBool(value, fallback)
    if value == nil then
        return fallback
    end
    return value == true
end

local function getDisplayNameForPlayer(player)
    if not player then
        return "Unknown"
    end
    if player.DisplayName and player.DisplayName ~= "" then
        if player.DisplayName ~= player.Name then
            return string.format("%s (@%s)", player.DisplayName, player.Name)
        end
        return player.DisplayName
    end
    return player.Name or "Unknown"
end

--// Defaults
local DEFAULT_CONFIG = {
    Enabled = false,
    AutoPlayers = true,
    IgnoreLocalPlayer = true,
    MaxDistance = 1000,
    UpdateInterval = 0.10,
    ConditionInterval = 0.50,
    ParentToCoreGui = true,
    Debug = false,

    Team = {
        UseTeamColor = false,
        IgnoreSameTeam = false,
    },

    Text = {
        Enabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = false,
        ShowGroup = false,
        Size = 13,
        Font = Enum.Font.Gotham,
        BoldFont = Enum.Font.GothamBold,
        StrokeTransparency = 0.35,
        Offset = Vector3.new(0, 3.15, 0),
        Width = 160,
        LineHeight = 14,
    },

    Highlight = {
        Enabled = true,
        FillTransparency = 0.55,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    },

    Tracer = {
        Enabled = false,
        From = "Root", -- Root | Camera | Bottom
        Width = 0.075,
        Transparency = 0.25,
        BlockedTransparency = 0.80,
        LightEmission = 1,
        Segments = 1,
        OcclusionCheck = false,
        OriginOffset = Vector3.new(0, 0, 0),
        TargetOffset = Vector3.new(0, 0, 0),
    },

    Colors = {
        Player = Color3.fromRGB(255, 255, 255),
        Object = Color3.fromRGB(255, 215, 0),
        Text = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(205, 205, 205),
        Tracer = Color3.fromRGB(255, 255, 255),
        Occluded = Color3.fromRGB(255, 80, 80),
    },

    Filters = {
        Player = nil, -- function(player, entry) -> boolean
        Object = nil, -- function(instance, entry) -> boolean
    },

    HealthGetter = nil, -- function(player, character) -> hp, maxHp
}

--// Library
local ESP = {}
ESP.__index = ESP

function ESP.new(config)
    local self = setmetatable({}, ESP)

    self.Config = deepMerge(deepCopy(DEFAULT_CONFIG), config or {})
    self._enabled = self.Config.Enabled == true
    self._destroyed = false
    self._containersReady = false

    self._players = {} -- [Player] = entry
    self._objects = {} -- [Instance] = entry
    self._groups = {} -- [groupName] = {[Instance] = true}
    self._connections = {}
    self._renderConnections = {}

    self._lastUpdate = 0
    self._lastCondition = 0

    self:_ensureContainers()
    self:_bindCoreConnections()

    if self._enabled then
        self:Enable()
    end

    return self
end

function ESP:_log(...)
    if self.Config.Debug then
        print("[ESP]", ...)
    end
end

function ESP:_getGuiParent()
    if self.Config.ParentToCoreGui then
        local ok = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "ESP_Probe"
            probe.Parent = CoreGui
            probe:Destroy()
        end)
        if ok then
            return CoreGui
        end
    end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui", 10) or Workspace
    end
    return Workspace
end

function ESP:_ensureContainers()
    if self._containersReady then
        return
    end

    local guiParent = self:_getGuiParent()

    self._guiFolder = Instance.new("Folder")
    self._guiFolder.Name = "ESP_GUI_v3"
    self._guiFolder.Parent = guiParent

    self._worldFolder = Instance.new("Folder")
    self._worldFolder.Name = "ESP_World_v3"
    self._worldFolder.Parent = Workspace

    self._localAnchor = Instance.new("Part")
    self._localAnchor.Name = "ESP_LocalTracerAnchor"
    self._localAnchor.Anchored = true
    self._localAnchor.CanCollide = false
    self._localAnchor.CanTouch = false
    self._localAnchor.CanQuery = false
    self._localAnchor.CastShadow = false
    self._localAnchor.Transparency = 1
    self._localAnchor.Size = Vector3.new(0.15, 0.15, 0.15)
    self._localAnchor.CFrame = CFrame.new(0, -10000, 0)
    self._localAnchor.Parent = self._worldFolder

    self._localAttachment = Instance.new("Attachment")
    self._localAttachment.Name = "ESP_LocalAttachment"
    self._localAttachment.Parent = self._localAnchor

    self._containersReady = true
end

function ESP:_bindCoreConnections()
    table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
        if self.Config.AutoPlayers and self._enabled then
            self:TrackPlayer(player)
        end
    end))

    table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
        self:UntrackPlayer(player)
    end))

    table.insert(self._connections, RunService.Heartbeat:Connect(function(dt)
        self:_step(dt)
    end))
end

function ESP:_syncLocalAnchor()
    if not self._localAnchor then
        return
    end

    local fromMode = self.Config.Tracer.From
    local camera = Workspace.CurrentCamera
    local originCFrame

    if fromMode == "Camera" and camera then
        originCFrame = camera.CFrame
    else
        local character = LocalPlayer and LocalPlayer.Character
        local root = getRoot(character)
        if root then
            originCFrame = root.CFrame
            if fromMode == "Bottom" then
                originCFrame = CFrame.new(root.Position - Vector3.new(0, 3, 0))
            end
        elseif camera then
            originCFrame = camera.CFrame
        end
    end

    if originCFrame then
        self._localAnchor.CFrame = originCFrame + self.Config.Tracer.OriginOffset
    else
        self._localAnchor.CFrame = CFrame.new(0, -10000, 0)
    end
end

function ESP:_step(dt)
    if self._destroyed then
        return
    end

    self:_syncLocalAnchor()

    if not self._enabled then
        return
    end

    self._lastUpdate = self._lastUpdate + dt
    self._lastCondition = self._lastCondition + dt

    if self._lastUpdate >= math.max(self.Config.UpdateInterval, 0.016) then
        self._lastUpdate = 0
        self:_updatePlayers()
        self:_updateObjects()
    end

    if self._lastCondition >= math.max(self.Config.ConditionInterval, 0.05) then
        self._lastCondition = 0
        self:_checkObjectConditions()
    end
end

function ESP:_getPlayerColor(player, entry)
    if entry and entry.Options and entry.Options.color then
        return entry.Options.color
    end
    if self.Config.Team.UseTeamColor and player and player.Team then
        return player.Team.TeamColor.Color
    end
    return self.Config.Colors.Player
end

function ESP:_getObjectColor(entry)
    if entry and entry.Options and entry.Options.color then
        return entry.Options.color
    end
    if entry and entry.Options and entry.Options.textColor then
        return entry.Options.textColor
    end
    return self.Config.Colors.Object
end

function ESP:_distanceToLocal(root)
    local character = LocalPlayer and LocalPlayer.Character
    local localRoot = getRoot(character)
    if not root or not localRoot then
        return math.huge
    end
    return (root.Position - localRoot.Position).Magnitude
end

function ESP:_passesCommonVisibility(root, maxDistance)
    if not self._enabled or not root then
        return false, math.huge
    end
    local distance = self:_distanceToLocal(root)
    return distance <= (maxDistance or self.Config.MaxDistance), distance
end

function ESP:_isOccluded(targetRoot)
    if not self.Config.Tracer.OcclusionCheck then
        return false
    end
    if not self._localAnchor or not targetRoot then
        return false
    end

    local origin = self._localAnchor.Position
    local target = targetRoot.Position + self.Config.Tracer.TargetOffset
    local direction = target - origin
    if direction.Magnitude <= 0.1 then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {self._worldFolder}
    if LocalPlayer and LocalPlayer.Character then
        table.insert(exclude, LocalPlayer.Character)
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    if not result then
        return false
    end
    return not result.Instance:IsDescendantOf(targetRoot.Parent)
end

--// Render creation
function ESP:_makeHighlight(adornee, color)
    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.Adornee = adornee
    h.Enabled = false
    h.DepthMode = self.Config.Highlight.DepthMode
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = self.Config.Highlight.FillTransparency
    h.OutlineTransparency = self.Config.Highlight.OutlineTransparency
    h.Parent = self._guiFolder
    return h
end

function ESP:_makeBillboard()
    local cfg = self.Config.Text

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Label"
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Enabled = false
    bb.Size = UDim2.new(0, cfg.Width, 0, 0)
    bb.StudsOffset = cfg.Offset
    bb.AutomaticSize = Enum.AutomaticSize.Y
    bb.Parent = self._guiFolder

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 1)
    layout.Parent = bb

    local function label(name, order, bold)
        local t = Instance.new("TextLabel")
        t.Name = name
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(1, 0, 0, cfg.LineHeight)
        t.Font = bold and cfg.BoldFont or cfg.Font
        t.TextSize = cfg.Size
        t.TextColor3 = self.Config.Colors.Text
        t.TextStrokeColor3 = Color3.new(0, 0, 0)
        t.TextStrokeTransparency = cfg.StrokeTransparency
        t.RichText = false
        t.Text = ""
        t.Visible = false
        t.LayoutOrder = order
        t.Parent = bb
        return t
    end

    return {
        Billboard = bb,
        Name = label("Name", 1, true),
        Health = label("Health", 2, false),
        Distance = label("Distance", 3, false),
        Group = label("Group", 4, false),
        Custom = label("Custom", 5, false),
    }
end

function ESP:_makeTracer(targetRoot, color)
    if not targetRoot or not targetRoot:IsA("BasePart") then
        return nil
    end

    local targetAttachment = Instance.new("Attachment")
    targetAttachment.Name = "ESP_TargetAttachment"
    targetAttachment.Position = self.Config.Tracer.TargetOffset
    targetAttachment.Parent = targetRoot

    local beam = Instance.new("Beam")
    beam.Name = "ESP_Tracer"
    beam.Enabled = false
    beam.FaceCamera = true
    beam.Attachment0 = self._localAttachment
    beam.Attachment1 = targetAttachment
    beam.Width0 = self.Config.Tracer.Width
    beam.Width1 = self.Config.Tracer.Width
    beam.LightEmission = self.Config.Tracer.LightEmission
    beam.LightInfluence = 0
    beam.Segments = self.Config.Tracer.Segments
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new(self.Config.Tracer.Transparency)
    beam.Parent = self._worldFolder

    return beam, targetAttachment
end

function ESP:_cleanupRender(entry)
    if not entry then
        return
    end
    safeDestroy(entry.Highlight)
    if entry.Labels then
        safeDestroy(entry.Labels.Billboard)
    end
    safeDestroy(entry.Tracer)
    safeDestroy(entry.TargetAttachment)
    entry.Highlight = nil
    entry.Labels = nil
    entry.Tracer = nil
    entry.TargetAttachment = nil
    entry.Root = nil
end

function ESP:_buildRender(entry, adornee, root, color)
    self:_cleanupRender(entry)
    if not root or not root:IsA("BasePart") then
        return false
    end

    if self.Config.Highlight.Enabled ~= false and asBool(entry.Options.highlight, true) then
        entry.Highlight = self:_makeHighlight(adornee, color)
    end

    if self.Config.Text.Enabled ~= false and asBool(entry.Options.textEnabled, true) then
        entry.Labels = self:_makeBillboard()
        entry.Labels.Billboard.Adornee = root
        if entry.Options.offset then
            entry.Labels.Billboard.StudsOffset = entry.Options.offset
        end
    end

    local wantsTracer = entry.Options.tracer
    if wantsTracer == nil then
        wantsTracer = entry.Options.showRay
    end
    if wantsTracer == nil then
        wantsTracer = self.Config.Tracer.Enabled
    end

    if wantsTracer then
        entry.Tracer, entry.TargetAttachment = self:_makeTracer(root, color)
    end

    entry.Root = root
    return true
end

--// Player tracking
function ESP:TrackPlayer(player, options)
    if not player or not player:IsA("Player") then
        return nil
    end
    if self.Config.IgnoreLocalPlayer and player == LocalPlayer then
        return nil
    end

    local existing = self._players[player]
    if existing then
        if options then
            deepMerge(existing.Options, options)
        end
        return existing
    end

    local entry = {
        Kind = "Player",
        Player = player,
        Options = options or {},
        Connections = {},
        LastCharacter = nil,
    }
    self._players[player] = entry

    local function rebuild(character)
        entry.LastCharacter = character
        if not character then
            self:_cleanupRender(entry)
            return
        end

        task.spawn(function()
            local root = character:FindFirstChild("HumanoidRootPart")
                or character:WaitForChild("HumanoidRootPart", 5)
                or getRoot(character)
            if not root or not root.Parent then
                return
            end
            self:_buildRender(entry, character, root, self:_getPlayerColor(player, entry))
            self:UpdatePlayer(player)
        end)
    end

    table.insert(entry.Connections, player.CharacterAdded:Connect(rebuild))
    table.insert(entry.Connections, player.CharacterRemoving:Connect(function()
        self:_cleanupRender(entry)
    end))

    if player.Character then
        rebuild(player.Character)
    end

    return entry
end

function ESP:UntrackPlayer(player)
    local entry = self._players[player]
    if not entry then
        return
    end
    for _, connection in ipairs(entry.Connections) do
        safeDisconnect(connection)
    end
    self:_cleanupRender(entry)
    self._players[player] = nil
end

function ESP:_shouldShowPlayer(player, entry, root)
    if self.Config.Team.IgnoreSameTeam and LocalPlayer and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
        return false, math.huge
    end

    local show, distance = self:_passesCommonVisibility(root, entry.Options.maxDistance or self.Config.MaxDistance)
    if not show then
        return false, distance
    end

    local filter = entry.Options.filter or self.Config.Filters.Player
    if filter then
        local ok, result = safeCall(filter, player, entry)
        if not ok or result == false then
            return false, distance
        end
    end

    return true, distance
end

function ESP:_getPlayerHealth(player)
    local character = player.Character
    if self.Config.HealthGetter then
        local ok, hp, maxHp = safeCall(self.Config.HealthGetter, player, character)
        if ok then
            return tonumber(hp) or 0, tonumber(maxHp) or 100
        end
    end

    local humanoid = getHumanoid(character)
    if humanoid then
        return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
    end
    return 0, 100
end

function ESP:UpdatePlayer(player)
    local entry = self._players[player]
    if not entry then
        return
    end

    local character = player.Character
    local root = getRoot(character)
    if not root then
        self:_setEntryVisible(entry, false)
        return
    end

    if entry.Root ~= root then
        self:_buildRender(entry, character, root, self:_getPlayerColor(player, entry))
    end

    local color = self:_getPlayerColor(player, entry)
    local show, distance = self:_shouldShowPlayer(player, entry, root)
    self:_updateEntryVisual(entry, show, color, distance)

    local labels = entry.Labels
    if labels and labels.Billboard then
        local cfg = self.Config.Text
        local showName = asBool(entry.Options.showName, cfg.ShowName)
        local showHealth = asBool(entry.Options.showHealth, cfg.ShowHealth)
        local showDistance = asBool(entry.Options.showDistance, cfg.ShowDistance)
        local showGroup = asBool(entry.Options.showGroup, cfg.ShowGroup)

        labels.Name.Visible = show and showName
        labels.Name.Text = entry.Options.name or getDisplayNameForPlayer(player)
        labels.Name.TextColor3 = color

        labels.Health.Visible = show and showHealth
        if showHealth then
            local hp, maxHp = self:_getPlayerHealth(player)
            labels.Health.Text = string.format("HP %d / %d", hp, maxHp)
            labels.Health.TextColor3 = healthColor(maxHp > 0 and hp / maxHp or 0)
        end

        labels.Distance.Visible = show and showDistance
        if showDistance then
            labels.Distance.Text = string.format("%.0f studs", distance)
            labels.Distance.TextColor3 = self.Config.Colors.Distance
        end

        labels.Group.Visible = show and showGroup and entry.Options.group ~= nil
        labels.Group.Text = entry.Options.group and tostring(entry.Options.group) or ""
        labels.Group.TextColor3 = color

        labels.Custom.Visible = show and entry.Options.text ~= nil
        labels.Custom.Text = entry.Options.text and tostring(entry.Options.text) or ""
        labels.Custom.TextColor3 = entry.Options.textColor or color
    end
end

function ESP:_updatePlayers()
    if self.Config.AutoPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if not self._players[player] and not (self.Config.IgnoreLocalPlayer and player == LocalPlayer) then
                self:TrackPlayer(player)
            end
        end
    end

    for player in pairs(self._players) do
        self:UpdatePlayer(player)
    end
end

--// Object tracking
function ESP:TrackObject(instance, options, conditionFunc)
    if not isInstance(instance) then
        return nil
    end

    local existing = self._objects[instance]
    if existing then
        if options then
            deepMerge(existing.Options, options)
        end
        if conditionFunc then
            existing.Condition = conditionFunc
        end
        self:UpdateObject(instance)
        return existing
    end

    options = options or {}
    local root = getRoot(instance) or instance
    if not root or not root:IsA("BasePart") then
        warn("[ESP] TrackObject skipped: no BasePart root for", instance:GetFullName())
        return nil
    end

    local entry = {
        Kind = "Object",
        Instance = instance,
        Options = options,
        Condition = conditionFunc or options.condition,
        Connections = {},
        Root = nil,
    }
    self._objects[instance] = entry

    if options.group then
        self._groups[options.group] = self._groups[options.group] or {}
        self._groups[options.group][instance] = true
    end

    table.insert(entry.Connections, instance.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            self:UntrackObject(instance)
        end
    end))

    self:_buildRender(entry, instance, root, self:_getObjectColor(entry))
    self:UpdateObject(instance)
    return entry
end

function ESP:UntrackObject(instance)
    local entry = self._objects[instance]
    if not entry then
        return
    end

    for _, connection in ipairs(entry.Connections) do
        safeDisconnect(connection)
    end

    if entry.Options and entry.Options.group and self._groups[entry.Options.group] then
        self._groups[entry.Options.group][instance] = nil
    end

    self:_cleanupRender(entry)
    self._objects[instance] = nil
end

function ESP:ClearObjects(group)
    if group == nil then
        for instance in pairs(self._objects) do
            self:UntrackObject(instance)
        end
        return
    end

    local bucket = self._groups[group]
    if not bucket then
        return
    end
    for instance in pairs(bucket) do
        self:UntrackObject(instance)
    end
    self._groups[group] = nil
end

function ESP:_shouldShowObject(instance, entry, root)
    if not isAliveInstance(instance) then
        return false, math.huge
    end

    local show, distance = self:_passesCommonVisibility(root, entry.Options.maxDistance or self.Config.MaxDistance)
    if not show then
        return false, distance
    end

    local filter = entry.Options.filter or self.Config.Filters.Object
    if filter then
        local ok, result = safeCall(filter, instance, entry)
        if not ok or result == false then
            return false, distance
        end
    end

    return true, distance
end

function ESP:UpdateObject(instance)
    local entry = self._objects[instance]
    if not entry then
        return
    end

    local root = getRoot(instance) or instance
    if not root or not root:IsA("BasePart") then
        self:_setEntryVisible(entry, false)
        return
    end

    if entry.Root ~= root then
        self:_buildRender(entry, instance, root, self:_getObjectColor(entry))
    end

    if entry.Options.onUpdate then
        safeCall(entry.Options.onUpdate, instance, entry)
    end

    local color = self:_getObjectColor(entry)
    local show, distance = self:_shouldShowObject(instance, entry, root)
    self:_updateEntryVisual(entry, show, color, distance)

    local labels = entry.Labels
    if labels and labels.Billboard then
        local text = entry.Options.text or entry.Options.name or instance.Name
        local showDistance = asBool(entry.Options.showDistance, self.Config.Text.ShowDistance)
        local showGroup = asBool(entry.Options.showGroup, self.Config.Text.ShowGroup)

        labels.Name.Visible = show and text ~= nil
        labels.Name.Text = tostring(text)
        labels.Name.TextColor3 = entry.Options.textColor or color

        labels.Health.Visible = false

        labels.Distance.Visible = show and showDistance
        if showDistance then
            labels.Distance.Text = string.format("%.0f studs", distance)
            labels.Distance.TextColor3 = self.Config.Colors.Distance
        end

        labels.Group.Visible = show and showGroup and entry.Options.group ~= nil
        labels.Group.Text = entry.Options.group and tostring(entry.Options.group) or ""
        labels.Group.TextColor3 = color

        labels.Custom.Visible = false
    end
end

function ESP:_updateObjects()
    for instance in pairs(self._objects) do
        self:UpdateObject(instance)
    end
end

function ESP:_checkObjectConditions()
    for instance, entry in pairs(self._objects) do
        if entry.Condition then
            local ok, keep = safeCall(entry.Condition, instance, entry)
            if not ok or keep == false then
                self:UntrackObject(instance)
            end
        end
    end
end

--// Shared visual update
function ESP:_setEntryVisible(entry, visible)
    if entry.Highlight then
        trySet(entry.Highlight, "Enabled", visible and self.Config.Highlight.Enabled ~= false)
    end
    if entry.Labels and entry.Labels.Billboard then
        trySet(entry.Labels.Billboard, "Enabled", visible and self.Config.Text.Enabled ~= false)
    end
    if entry.Tracer then
        trySet(entry.Tracer, "Enabled", visible)
    end
end

function ESP:_updateEntryVisual(entry, visible, color, distance)
    local hasTracer = entry.Tracer ~= nil
    local tracerEnabled = entry.Options.tracer
    if tracerEnabled == nil then
        tracerEnabled = entry.Options.showRay
    end
    if tracerEnabled == nil then
        tracerEnabled = self.Config.Tracer.Enabled
    end

    if entry.Highlight then
        trySet(entry.Highlight, "Enabled", visible and self.Config.Highlight.Enabled ~= false and asBool(entry.Options.highlight, true))
        trySet(entry.Highlight, "FillColor", color)
        trySet(entry.Highlight, "OutlineColor", color)
        trySet(entry.Highlight, "FillTransparency", entry.Options.fillTransparency or self.Config.Highlight.FillTransparency)
        trySet(entry.Highlight, "OutlineTransparency", entry.Options.outlineTransparency or self.Config.Highlight.OutlineTransparency)
    end

    if entry.Labels and entry.Labels.Billboard then
        trySet(entry.Labels.Billboard, "Enabled", visible and self.Config.Text.Enabled ~= false and asBool(entry.Options.textEnabled, true))
    end

    if hasTracer then
        local showTracer = visible and tracerEnabled == true
        trySet(entry.Tracer, "Enabled", showTracer)
        if showTracer then
            local occluded = self:_isOccluded(entry.Root)
            local tracerColor = occluded and self.Config.Colors.Occluded or (entry.Options.tracerColor or color or self.Config.Colors.Tracer)
            local transparency = occluded and self.Config.Tracer.BlockedTransparency or (entry.Options.tracerTransparency or self.Config.Tracer.Transparency)
            trySet(entry.Tracer, "Color", ColorSequence.new(tracerColor))
            trySet(entry.Tracer, "Transparency", NumberSequence.new(transparency))
            trySet(entry.Tracer, "Width0", entry.Options.tracerWidth or self.Config.Tracer.Width)
            trySet(entry.Tracer, "Width1", entry.Options.tracerWidth or self.Config.Tracer.Width)
            trySet(entry.Tracer, "Segments", self.Config.Tracer.Segments)
        end
    elseif tracerEnabled == true and entry.Root then
        entry.Tracer, entry.TargetAttachment = self:_makeTracer(entry.Root, color)
    end
end

--// Public state API
function ESP:Configure(patch)
    deepMerge(self.Config, patch or {})

    if patch and patch.Tracer and patch.Tracer.TargetOffset then
        for _, entry in pairs(self._players) do
            if entry.TargetAttachment then
                trySet(entry.TargetAttachment, "Position", self.Config.Tracer.TargetOffset)
            end
        end
        for _, entry in pairs(self._objects) do
            if entry.TargetAttachment then
                trySet(entry.TargetAttachment, "Position", self.Config.Tracer.TargetOffset)
            end
        end
    end

    self:Refresh()
    return self
end

function ESP:GetConfig()
    return deepCopy(self.Config)
end

function ESP:Enable()
    if self._destroyed then
        return self
    end
    self._enabled = true
    self.Config.Enabled = true
    self:_ensureContainers()

    if self.Config.AutoPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            self:TrackPlayer(player)
        end
    end

    self:Refresh()
    return self
end

function ESP:Disable()
    self._enabled = false
    self.Config.Enabled = false

    for _, entry in pairs(self._players) do
        self:_setEntryVisible(entry, false)
    end
    for _, entry in pairs(self._objects) do
        self:_setEntryVisible(entry, false)
    end

    return self
end

function ESP:Toggle(force)
    if force ~= nil then
        if force then
            return self:Enable()
        end
        return self:Disable()
    end
    if self._enabled then
        return self:Disable()
    end
    return self:Enable()
end

function ESP:IsEnabled()
    return self._enabled
end

function ESP:Refresh()
    if self._destroyed then
        return self
    end
    for player in pairs(self._players) do
        self:UpdatePlayer(player)
    end
    for instance in pairs(self._objects) do
        self:UpdateObject(instance)
    end
    return self
end

function ESP:Destroy()
    if self._destroyed then
        return
    end
    self:Disable()
    self._destroyed = true

    for player in pairs(self._players) do
        self:UntrackPlayer(player)
    end
    for instance in pairs(self._objects) do
        self:UntrackObject(instance)
    end

    for _, connection in ipairs(self._connections) do
        safeDisconnect(connection)
    end
    for _, connection in ipairs(self._renderConnections) do
        safeDisconnect(connection)
    end

    self._connections = {}
    self._renderConnections = {}

    safeDestroy(self._guiFolder)
    safeDestroy(self._worldFolder)

    self._guiFolder = nil
    self._worldFolder = nil
    self._localAnchor = nil
    self._localAttachment = nil
end

--// Compatibility API
function ESP:AddPlayer(player, options)
    return self:TrackPlayer(player, options)
end

function ESP:RemovePlayer(player)
    return self:UntrackPlayer(player)
end

function ESP:AddObject(instance, options, conditionFunc)
    return self:TrackObject(instance, options, conditionFunc)
end

function ESP:AddObjectWithCondition(instance, options, conditionFunc)
    return self:TrackObject(instance, options, conditionFunc)
end

function ESP:RemoveObject(instance)
    return self:UntrackObject(instance)
end

function ESP:UpdateObjectText(instance, newText)
    local entry = self._objects[instance]
    if entry then
        entry.Options.text = newText
        if entry.Labels and entry.Labels.Name then
            entry.Labels.Name.Text = tostring(newText)
        end
    end
end

function ESP:SetShowName(value)
    return self:Configure({Text = {ShowName = value}})
end

function ESP:SetShowHealth(value)
    return self:Configure({Text = {ShowHealth = value}})
end

function ESP:SetShowDistance(value)
    return self:Configure({Text = {ShowDistance = value}})
end

function ESP:SetShowRay(value)
    return self:Configure({Tracer = {Enabled = value}})
end

function ESP:SetColor(color)
    return self:Configure({Colors = {Player = color, Tracer = color, Text = color}})
end

function ESP:SetTeamColor(value)
    return self:Configure({Team = {UseTeamColor = value}})
end

function ESP:SetIgnoreSameTeam(value)
    return self:Configure({Team = {IgnoreSameTeam = value}})
end

function ESP:SetMaxDistance(distance)
    return self:Configure({MaxDistance = distance})
end

function ESP:SetUpdateInterval(seconds)
    return self:Configure({UpdateInterval = seconds})
end

function ESP:SetBeamWidth(width)
    return self:Configure({Tracer = {Width = width}})
end

function ESP:SetHealthGetter(fn)
    return self:Configure({HealthGetter = fn})
end

function ESP:ShowName(value)
    return self:SetShowName(value)
end

function ESP:ShowHealth(value)
    return self:SetShowHealth(value)
end

function ESP:ShowRay(value)
    return self:SetShowRay(value)
end

--// Singleton export for old require/loadstring style
local singleton = ESP.new()
singleton.Class = ESP

return singleton

--[[
============================================================
快速用法
============================================================

local ESP = require(path.to.ESP_lib_v3_refactor)
-- 或 loadstring(game:HttpGet("..."))()

ESP:Configure({
    MaxDistance = 600,
    Text = {
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
    },
    Tracer = {
        Enabled = true,
        From = "Root", -- Root | Camera | Bottom
        Width = 0.08,
        OcclusionCheck = false,
    },
    Team = {
        UseTeamColor = true,
        IgnoreSameTeam = false,
    },
})

ESP:Enable()

-- 标记物体
local chest = workspace:FindFirstChild("Chest")
if chest then
    ESP:TrackObject(chest, {
        text = "Chest",
        color = Color3.fromRGB(255, 215, 0),
        tracer = true,
        showDistance = true,
        group = "Loot",
        offset = Vector3.new(0, 2.5, 0),
    }, function(inst)
        return inst.Parent ~= nil
    end)
end

-- 修改文本
-- ESP:UpdateObjectText(chest, "Opened Chest")

-- 清理分组
-- ESP:ClearObjects("Loot")

-- 退出时
-- ESP:Destroy()

============================================================
创建独立实例
============================================================

local CustomESP = ESP.Class.new({
    AutoPlayers = false,
    Tracer = {Enabled = true, From = "Camera"},
})
CustomESP:TrackObject(workspace.Part, {text = "Debug Part", tracer = true})
CustomESP:Enable()
]]
