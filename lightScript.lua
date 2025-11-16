
-- 服务声明
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- 玩家变量
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 创建主UI
local MainUI = Instance.new("ScreenGui")
MainUI.Name = "LightScriptUI"
MainUI.ResetOnSpawn = false
MainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 创建悬浮球
local FloatingBall = Instance.new("TextButton")
FloatingBall.Name = "FloatingBall"
FloatingBall.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
FloatingBall.BackgroundTransparency = 0.3
FloatingBall.Size = UDim2.new(0, 60, 0, 60)
FloatingBall.Position = UDim2.new(0.5, -30, 0.5, -30)
FloatingBall.ZIndex = 10
FloatingBall.Text = "LS"
FloatingBall.TextColor3 = Color3.fromRGB(200, 200, 255)
FloatingBall.TextSize = 20
FloatingBall.Font = Enum.Font.GothamBold
FloatingBall.Active = true
FloatingBall.Draggable = true
FloatingBall.Parent = MainUI

-- 悬浮球样式
local BallCorner = Instance.new("UICorner")
BallCorner.CornerRadius = UDim.new(1, 0)
BallCorner.Parent = FloatingBall

local BallShadow = Instance.new("UIStroke")
BallShadow.Color = Color3.fromRGB(100, 100, 150)
BallShadow.Thickness = 2
BallShadow.Transparency = 0.7
BallShadow.Parent = FloatingBall

-- 主窗口
local OuterContainer = Instance.new("Frame")
OuterContainer.Name = "OuterContainer"
OuterContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
OuterContainer.BackgroundTransparency = 0.2
OuterContainer.Size = UDim2.new(0.8, 0, 0.7, 0)
OuterContainer.Position = UDim2.new(0.1, 0, 0.15, 0)
OuterContainer.Visible = false
OuterContainer.ClipsDescendants = true
OuterContainer.Parent = MainUI

-- 主窗口样式
local OuterCorner = Instance.new("UICorner")
OuterCorner.CornerRadius = UDim.new(0, 15)
OuterCorner.Parent = OuterContainer

local OuterStroke = Instance.new("UIStroke")
OuterStroke.Color = Color3.fromRGB(80, 80, 120)
OuterStroke.Thickness = 3
OuterStroke.Transparency = 0.5
OuterStroke.Parent = OuterContainer

-- 标题
local LightScriptLabel = Instance.new("TextLabel")
LightScriptLabel.Name = "LightScriptLabel"
LightScriptLabel.Text = "Light Script"
LightScriptLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
LightScriptLabel.TextSize = 12
LightScriptLabel.Font = Enum.Font.Gotham
LightScriptLabel.BackgroundTransparency = 1
LightScriptLabel.Size = UDim2.new(0, 80, 0, 20)
LightScriptLabel.Position = UDim2.new(0, 10, 0, 5)
LightScriptLabel.TextXAlignment = Enum.TextXAlignment.Left
LightScriptLabel.ZIndex = 5
LightScriptLabel.Parent = OuterContainer

-- 主容器
local MainContainer = Instance.new("Frame")
MainContainer.Name = "MainContainer"
MainContainer.BackgroundTransparency = 1
MainContainer.Size = UDim2.new(1, 0, 1, 0)
MainContainer.Parent = OuterContainer

-- 水平布局
local HorizontalLayout = Instance.new("UIListLayout")
HorizontalLayout.Padding = UDim.new(0, 10)
HorizontalLayout.FillDirection = Enum.FillDirection.Horizontal
HorizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
HorizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Top
HorizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
HorizontalLayout.Parent = MainContainer

-- 左侧面板
local LeftPanel = Instance.new("Frame")
LeftPanel.Name = "LeftPanel"
LeftPanel.BackgroundTransparency = 1
LeftPanel.Size = UDim2.new(0.25, 0, 1, 0)
LeftPanel.LayoutOrder = 1
LeftPanel.Parent = MainContainer

-- 左侧标题
local FunctionTitle = Instance.new("TextLabel")
FunctionTitle.Name = "FunctionTitle"
FunctionTitle.Text = "功能"
FunctionTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
FunctionTitle.TextSize = 16
FunctionTitle.Font = Enum.Font.GothamBold
FunctionTitle.BackgroundTransparency = 1
FunctionTitle.Size = UDim2.new(1, 0, 0, 30)
FunctionTitle.TextXAlignment = Enum.TextXAlignment.Center
FunctionTitle.Parent = LeftPanel

-- 左侧滚动容器
local LeftScrollContainer = Instance.new("ScrollingFrame")
LeftScrollContainer.Name = "LeftScrollContainer"
LeftScrollContainer.BackgroundTransparency = 1
LeftScrollContainer.Size = UDim2.new(1, 0, 1, -30)
LeftScrollContainer.Position = UDim2.new(0, 0, 0, 30)
LeftScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftScrollContainer.ScrollBarThickness = 6
LeftScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
LeftScrollContainer.ScrollBarImageTransparency = 0.7
LeftScrollContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always
LeftScrollContainer.Parent = LeftPanel

-- 左侧内容
local LeftContent = Instance.new("Frame")
LeftContent.Name = "LeftContent"
LeftContent.BackgroundTransparency = 1
LeftContent.Size = UDim2.new(1, 0, 1, 0)
LeftContent.Parent = LeftScrollContainer

-- 左侧布局
local LeftLayout = Instance.new("UIListLayout")
LeftLayout.Padding = UDim.new(0, 6)
LeftLayout.FillDirection = Enum.FillDirection.Vertical
LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
LeftLayout.VerticalAlignment = Enum.VerticalAlignment.Top
LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayout.Parent = LeftContent

-- 功能按钮
local function createFunctionButton(name, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    button.BackgroundTransparency = 0.3
    button.Size = UDim2.new(0.9, 0, 0, 28)
    button.LayoutOrder = layoutOrder
    button.Parent = LeftContent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    return button
end

-- 创建所有功能按钮
local HomeButton = createFunctionButton("主页", 1)
local GeneralButton = createFunctionButton("通用", 2)
local Server1Button = createFunctionButton("服务器1", 3)
local Server2Button = createFunctionButton("服务器2", 4)
local Server3Button = createFunctionButton("服务器3", 5)
local Server4Button = createFunctionButton("服务器4", 6)
local SettingsButton = createFunctionButton("设置", 7)

-- 右侧面板
local RightPanel = Instance.new("Frame")
RightPanel.Name = "RightPanel"
RightPanel.BackgroundTransparency = 1
RightPanel.Size = UDim2.new(0.7, 0, 1, 0)
RightPanel.LayoutOrder = 2
RightPanel.Parent = MainContainer

-- 右侧滚动容器
local RightScrollContainer = Instance.new("ScrollingFrame")
RightScrollContainer.Name = "RightScrollContainer"
RightScrollContainer.BackgroundTransparency = 1
RightScrollContainer.Size = UDim2.new(1, 0, 1, 0)
RightScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
RightScrollContainer.ScrollBarThickness = 6
RightScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
RightScrollContainer.ScrollBarImageTransparency = 0.7
RightScrollContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always
RightScrollContainer.Parent = RightPanel

-- 右侧内容
local RightContent = Instance.new("Frame")
RightContent.Name = "RightContent"
RightContent.BackgroundTransparency = 1
RightContent.Size = UDim2.new(1, 0, 1, 0)
RightContent.Parent = RightScrollContainer

-- 右侧布局
local RightLayout = Instance.new("UIListLayout")
RightLayout.Padding = UDim.new(0, 15)
RightLayout.FillDirection = Enum.FillDirection.Vertical
RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
RightLayout.VerticalAlignment = Enum.VerticalAlignment.Top
RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightLayout.Parent = RightContent

-- 创建界面函数
local function createInterface(name, defaultVisible)
    local interface = Instance.new("Frame")
    interface.Name = name .. "Interface"
    interface.BackgroundTransparency = 1
    interface.Size = UDim2.new(1, 0, 0, 0)
    interface.AutomaticSize = Enum.AutomaticSize.Y
    interface.Visible = defaultVisible or false
    interface.LayoutOrder = 1
    interface.Parent = RightContent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = interface
    
    return interface
end

-- 创建主页界面
local HomeInterface = createInterface("Home", true)

-- 主页内容
local HomeTitle = Instance.new("TextLabel")
HomeTitle.Name = "HomeTitle"
HomeTitle.Text = "主页信息"
HomeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HomeTitle.TextSize = 18
HomeTitle.Font = Enum.Font.GothamBold
HomeTitle.BackgroundTransparency = 1
HomeTitle.Size = UDim2.new(0.9, 0, 0, 40)
HomeTitle.LayoutOrder = 1
HomeTitle.Parent = HomeInterface

-- 服务器信息
local ServerInfoSection = Instance.new("Frame")
ServerInfoSection.Name = "ServerInfoSection"
ServerInfoSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
ServerInfoSection.BackgroundTransparency = 0.4
ServerInfoSection.Size = UDim2.new(0.95, 0, 0, 120)
ServerInfoSection.BorderSizePixel = 0
ServerInfoSection.LayoutOrder = 2
ServerInfoSection.Parent = HomeInterface

local ServerInfoCorner = Instance.new("UICorner")
ServerInfoCorner.CornerRadius = UDim.new(0, 10)
ServerInfoCorner.Parent = ServerInfoSection

local ServerInfoTitle = Instance.new("TextLabel")
ServerInfoTitle.Name = "ServerInfoTitle"
ServerInfoTitle.Text = "服务器信息"
ServerInfoTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
ServerInfoTitle.TextSize = 14
ServerInfoTitle.Font = Enum.Font.Gotham
ServerInfoTitle.BackgroundTransparency = 1
ServerInfoTitle.Size = UDim2.new(0.9, 0, 0.2, 0)
ServerInfoTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
ServerInfoTitle.Parent = ServerInfoSection

local ServerInfoContainer = Instance.new("Frame")
ServerInfoContainer.Name = "ServerInfoContainer"
ServerInfoContainer.BackgroundTransparency = 1
ServerInfoContainer.Size = UDim2.new(0.9, 0, 0.7, 0)
ServerInfoContainer.Position = UDim2.new(0.05, 0, 0.25, 0)
ServerInfoContainer.Parent = ServerInfoSection

local ServerInfoLayout = Instance.new("UIListLayout")
ServerInfoLayout.Padding = UDim.new(0, 8)
ServerInfoLayout.FillDirection = Enum.FillDirection.Vertical
ServerInfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ServerInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ServerInfoLayout.Parent = ServerInfoContainer

local ServerName = Instance.new("TextLabel")
ServerName.Name = "ServerName"
ServerName.Text = "服务器: 加载中..."
ServerName.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerName.TextSize = 14
ServerName.TextXAlignment = Enum.TextXAlignment.Left
ServerName.Font = Enum.Font.Gotham
ServerName.BackgroundTransparency = 1
ServerName.Size = UDim2.new(1, 0, 0, 22)
ServerName.LayoutOrder = 1
ServerName.Parent = ServerInfoContainer

local PlayerCount = Instance.new("TextLabel")
PlayerCount.Name = "PlayerCount"
PlayerCount.Text = "在线玩家: 加载中..."
PlayerCount.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerCount.TextSize = 14
PlayerCount.TextXAlignment = Enum.TextXAlignment.Left
PlayerCount.Font = Enum.Font.Gotham
PlayerCount.BackgroundTransparency = 1
PlayerCount.Size = UDim2.new(1, 0, 0, 22)
PlayerCount.LayoutOrder = 2
PlayerCount.Parent = ServerInfoContainer

local GameTime = Instance.new("TextLabel")
GameTime.Name = "GameTime"
GameTime.Text = "游戏时间: 加载中..."
GameTime.TextColor3 = Color3.fromRGB(255, 255, 255)
GameTime.TextSize = 14
GameTime.TextXAlignment = Enum.TextXAlignment.Left
GameTime.Font = Enum.Font.Gotham
GameTime.BackgroundTransparency = 1
GameTime.Size = UDim2.new(1, 0, 0, 22)
GameTime.LayoutOrder = 3
GameTime.Parent = ServerInfoContainer

-- 时间显示
local TimeSection = Instance.new("Frame")
TimeSection.Name = "TimeSection"
TimeSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
TimeSection.BackgroundTransparency = 0.4
TimeSection.Size = UDim2.new(0.95, 0, 0, 80)
TimeSection.BorderSizePixel = 0
TimeSection.LayoutOrder = 3
TimeSection.Parent = HomeInterface

local TimeCorner = Instance.new("UICorner")
TimeCorner.CornerRadius = UDim.new(0, 10)
TimeCorner.Parent = TimeSection

local TimeTitle = Instance.new("TextLabel")
TimeTitle.Name = "TimeTitle"
TimeTitle.Text = "北京时间"
TimeTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
TimeTitle.TextSize = 14
TimeTitle.Font = Enum.Font.Gotham
TimeTitle.BackgroundTransparency = 1
TimeTitle.Size = UDim2.new(0.9, 0, 0.3, 0)
TimeTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
TimeTitle.Parent = TimeSection

local TimeDisplay = Instance.new("TextLabel")
TimeDisplay.Name = "TimeDisplay"
TimeDisplay.Text = "加载中..."
TimeDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeDisplay.TextSize = 14
TimeDisplay.Font = Enum.Font.GothamBold
TimeDisplay.BackgroundTransparency = 1
TimeDisplay.Size = UDim2.new(0.9, 0, 0.5, 0)
TimeDisplay.Position = UDim2.new(0.05, 0, 0.35, 0)
TimeDisplay.Parent = TimeSection

-- 玩家信息
local PlayerSection = Instance.new("Frame")
PlayerSection.Name = "PlayerSection"
PlayerSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
PlayerSection.BackgroundTransparency = 0.4
PlayerSection.Size = UDim2.new(0.95, 0, 0, 150)
PlayerSection.BorderSizePixel = 0
PlayerSection.LayoutOrder = 4
PlayerSection.Parent = HomeInterface

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 10)
PlayerCorner.Parent = PlayerSection

local PlayerTitle = Instance.new("TextLabel")
PlayerTitle.Name = "PlayerTitle"
PlayerTitle.Text = "玩家信息"
PlayerTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
PlayerTitle.TextSize = 14
PlayerTitle.Font = Enum.Font.Gotham
PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Size = UDim2.new(0.9, 0, 0.2, 0)
PlayerTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
PlayerTitle.Parent = PlayerSection

local AvatarContainer = Instance.new("Frame")
AvatarContainer.Name = "AvatarContainer"
AvatarContainer.BackgroundTransparency = 1
AvatarContainer.Size = UDim2.new(0.3, 0, 0.7, 0)
AvatarContainer.Position = UDim2.new(0.05, 0, 0.25, 0)
AvatarContainer.Parent = PlayerSection

local PlayerAvatar = Instance.new("ImageLabel")
PlayerAvatar.Name = "PlayerAvatar"
PlayerAvatar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
PlayerAvatar.BackgroundTransparency = 0.5
PlayerAvatar.Size = UDim2.new(1, 0, 1, 0)
PlayerAvatar.BorderSizePixel = 0
PlayerAvatar.ScaleType = Enum.ScaleType.Crop
PlayerAvatar.Parent = AvatarContainer

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 8)
AvatarCorner.Parent = PlayerAvatar

local PlayerInfoContainer = Instance.new("Frame")
PlayerInfoContainer.Name = "PlayerInfoContainer"
PlayerInfoContainer.BackgroundTransparency = 1
PlayerInfoContainer.Size = UDim2.new(0.6, 0, 0.7, 0)
PlayerInfoContainer.Position = UDim2.new(0.4, 0, 0.25, 0)
PlayerInfoContainer.Parent = PlayerSection

local PlayerInfoLayout = Instance.new("UIListLayout")
PlayerInfoLayout.Padding = UDim.new(0, 8)
PlayerInfoLayout.FillDirection = Enum.FillDirection.Vertical
PlayerInfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
PlayerInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Top
PlayerInfoLayout.Parent = PlayerInfoContainer

local PlayerName = Instance.new("TextLabel")
PlayerName.Name = "PlayerName"
PlayerName.Text = "名称: 加载中..."
PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerName.TextSize = 14
PlayerName.TextXAlignment = Enum.TextXAlignment.Left
PlayerName.Font = Enum.Font.Gotham
PlayerName.BackgroundTransparency = 1
PlayerName.Size = UDim2.new(1, 0, 0, 22)
PlayerName.LayoutOrder = 1
PlayerName.Parent = PlayerInfoContainer

local PlayerId = Instance.new("TextLabel")
PlayerId.Name = "PlayerId"
PlayerId.Text = "ID: 加载中..."
PlayerId.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerId.TextSize = 14
PlayerId.TextXAlignment = Enum.TextXAlignment.Left
PlayerId.Font = Enum.Font.Gotham
PlayerId.BackgroundTransparency = 1
PlayerId.Size = UDim2.new(1, 0, 0, 22)
PlayerId.LayoutOrder = 2
PlayerId.Parent = PlayerInfoContainer

local PlayerAccountAge = Instance.new("TextLabel")
PlayerAccountAge.Name = "PlayerAccountAge"
PlayerAccountAge.Text = "账号天数: 加载中..."
PlayerAccountAge.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerAccountAge.TextSize = 14
PlayerAccountAge.TextXAlignment = Enum.TextXAlignment.Left
PlayerAccountAge.Font = Enum.Font.Gotham
PlayerAccountAge.BackgroundTransparency = 1
PlayerAccountAge.Size = UDim2.new(1, 0, 0, 22)
PlayerAccountAge.LayoutOrder = 3
PlayerAccountAge.Parent = PlayerInfoContainer

-- 创建通用界面
local GeneralInterface = createInterface("General", false)

local GeneralTitle = Instance.new("TextLabel")
GeneralTitle.Name = "GeneralTitle"
GeneralTitle.Text = "通用功能"
GeneralTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
GeneralTitle.TextSize = 18
GeneralTitle.Font = Enum.Font.GothamBold
GeneralTitle.BackgroundTransparency = 1
GeneralTitle.Size = UDim2.new(0.9, 0, 0, 40)
GeneralTitle.LayoutOrder = 1
GeneralTitle.Parent = GeneralInterface

-- FL飞行功能板块
local FLFlyFunctionSection = Instance.new("Frame")
FLFlyFunctionSection.Name = "FLFlyFunctionSection"
FLFlyFunctionSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
FLFlyFunctionSection.BackgroundTransparency = 0.4
FLFlyFunctionSection.Size = UDim2.new(0.95, 0, 0, 180)
FLFlyFunctionSection.BorderSizePixel = 0
FLFlyFunctionSection.LayoutOrder = 2
FLFlyFunctionSection.Parent = GeneralInterface

local FLFlyFunctionCorner = Instance.new("UICorner")
FLFlyFunctionCorner.CornerRadius = UDim.new(0, 10)
FLFlyFunctionCorner.Parent = FLFlyFunctionSection

local FLFlyFunctionTitle = Instance.new("TextLabel")
FLFlyFunctionTitle.Name = "FLFlyFunctionTitle"
FLFlyFunctionTitle.Text = "FL飞行"
FLFlyFunctionTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
FLFlyFunctionTitle.TextSize = 16
FLFlyFunctionTitle.Font = Enum.Font.GothamBold
FLFlyFunctionTitle.BackgroundTransparency = 1
FLFlyFunctionTitle.Size = UDim2.new(0.9, 0, 0.15, 0)
FLFlyFunctionTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
FLFlyFunctionTitle.Parent = FLFlyFunctionSection

-- FL飞行开关
local FLFlyToggle = Instance.new("TextButton")
FLFlyToggle.Name = "FLFlyToggle"
FLFlyToggle.Text = "开启FL飞行"
FLFlyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FLFlyToggle.TextSize = 14
FLFlyToggle.Font = Enum.Font.Gotham
FLFlyToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
FLFlyToggle.BackgroundTransparency = 0.3
FLFlyToggle.Size = UDim2.new(0.4, 0, 0, 30)
FLFlyToggle.Position = UDim2.new(0.05, 0, 0.25, 0)
FLFlyToggle.Parent = FLFlyFunctionSection

local FLFlyToggleCorner = Instance.new("UICorner")
FLFlyToggleCorner.CornerRadius = UDim.new(0, 6)
FLFlyToggleCorner.Parent = FLFlyToggle

-- 上下控制按钮
local UpButton = Instance.new("TextButton")
UpButton.Name = "UpButton"
UpButton.Text = "上"
UpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpButton.TextSize = 14
UpButton.Font = Enum.Font.Gotham
UpButton.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
UpButton.BackgroundTransparency = 0.3
UpButton.Size = UDim2.new(0.2, 0, 0, 25)
UpButton.Position = UDim2.new(0.05, 0, 0.5, 0)
UpButton.Parent = FLFlyFunctionSection

local UpButtonCorner = Instance.new("UICorner")
UpButtonCorner.CornerRadius = UDim.new(0, 4)
UpButtonCorner.Parent = UpButton

local DownButton = Instance.new("TextButton")
DownButton.Name = "DownButton"
DownButton.Text = "下"
DownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DownButton.TextSize = 14
DownButton.Font = Enum.Font.Gotham
DownButton.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
DownButton.BackgroundTransparency = 0.3
DownButton.Size = UDim2.new(0.2, 0, 0, 25)
DownButton.Position = UDim2.new(0.3, 0, 0.5, 0)
DownButton.Parent = FLFlyFunctionSection

local DownButtonCorner = Instance.new("UICorner")
DownButtonCorner.CornerRadius = UDim.new(0, 4)
DownButtonCorner.Parent = DownButton

-- 速度控制
local PlusButton = Instance.new("TextButton")
PlusButton.Name = "PlusButton"
PlusButton.Text = "+"
PlusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusButton.TextSize = 14
PlusButton.Font = Enum.Font.Gotham
PlusButton.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
PlusButton.BackgroundTransparency = 0.3
PlusButton.Size = UDim2.new(0.15, 0, 0, 25)
PlusButton.Position = UDim2.new(0.55, 0, 0.5, 0)
PlusButton.Parent = FLFlyFunctionSection

local PlusButtonCorner = Instance.new("UICorner")
PlusButtonCorner.CornerRadius = UDim.new(0, 4)
PlusButtonCorner.Parent = PlusButton

local MinusButton = Instance.new("TextButton")
MinusButton.Name = "MinusButton"
MinusButton.Text = "-"
MinusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusButton.TextSize = 14
MinusButton.Font = Enum.Font.Gotham
MinusButton.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
MinusButton.BackgroundTransparency = 0.3
MinusButton.Size = UDim2.new(0.15, 0, 0, 25)
MinusButton.Position = UDim2.new(0.75, 0, 0.5, 0)
MinusButton.Parent = FLFlyFunctionSection

local MinusButtonCorner = Instance.new("UICorner")
MinusButtonCorner.CornerRadius = UDim.new(0, 4)
MinusButtonCorner.Parent = MinusButton

-- 速度显示
local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Name = "SpeedDisplay"
SpeedDisplay.Text = "速度: 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(200, 200, 255)
SpeedDisplay.TextSize = 14
SpeedDisplay.Font = Enum.Font.Gotham
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Size = UDim2.new(0.4, 0, 0, 25)
SpeedDisplay.Position = UDim2.new(0.55, 0, 0.25, 0)
SpeedDisplay.TextXAlignment = Enum.TextXAlignment.Left
SpeedDisplay.Parent = FLFlyFunctionSection

-- 玩家信息显示功能
local PlayerInfoFunctionSection = Instance.new("Frame")
PlayerInfoFunctionSection.Name = "PlayerInfoFunctionSection"
PlayerInfoFunctionSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
PlayerInfoFunctionSection.BackgroundTransparency = 0.4
PlayerInfoFunctionSection.Size = UDim2.new(0.95, 0, 0, 100)
PlayerInfoFunctionSection.BorderSizePixel = 0
PlayerInfoFunctionSection.LayoutOrder = 3
PlayerInfoFunctionSection.Parent = GeneralInterface

local PlayerInfoFunctionCorner = Instance.new("UICorner")
PlayerInfoFunctionCorner.CornerRadius = UDim.new(0, 10)
PlayerInfoFunctionCorner.Parent = PlayerInfoFunctionSection

local PlayerInfoFunctionTitle = Instance.new("TextLabel")
PlayerInfoFunctionTitle.Name = "PlayerInfoFunctionTitle"
PlayerInfoFunctionTitle.Text = "玩家信息显示"
PlayerInfoFunctionTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
PlayerInfoFunctionTitle.TextSize = 16
PlayerInfoFunctionTitle.Font = Enum.Font.GothamBold
PlayerInfoFunctionTitle.BackgroundTransparency = 1
PlayerInfoFunctionTitle.Size = UDim2.new(0.9, 0, 0.2, 0)
PlayerInfoFunctionTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
PlayerInfoFunctionTitle.Parent = PlayerInfoFunctionSection

local PlayerInfoToggle = Instance.new("TextButton")
PlayerInfoToggle.Name = "PlayerInfoToggle"
PlayerInfoToggle.Text = "显示玩家信息"
PlayerInfoToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerInfoToggle.TextSize = 14
PlayerInfoToggle.Font = Enum.Font.Gotham
PlayerInfoToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
PlayerInfoToggle.BackgroundTransparency = 0.3
PlayerInfoToggle.Size = UDim2.new(0.4, 0, 0, 35)
PlayerInfoToggle.Position = UDim2.new(0.05, 0, 0.3, 0)
PlayerInfoToggle.Parent = PlayerInfoFunctionSection

local PlayerInfoToggleCorner = Instance.new("UICorner")
PlayerInfoToggleCorner.CornerRadius = UDim.new(0, 6)
PlayerInfoToggleCorner.Parent = PlayerInfoToggle

-- 全局高亮功能
local HighlightFunctionSection = Instance.new("Frame")
HighlightFunctionSection.Name = "HighlightFunctionSection"
HighlightFunctionSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
HighlightFunctionSection.BackgroundTransparency = 0.4
HighlightFunctionSection.Size = UDim2.new(0.95, 0, 0, 100)
HighlightFunctionSection.BorderSizePixel = 0
HighlightFunctionSection.LayoutOrder = 4
HighlightFunctionSection.Parent = GeneralInterface

local HighlightFunctionCorner = Instance.new("UICorner")
HighlightFunctionCorner.CornerRadius = UDim.new(0, 10)
HighlightFunctionCorner.Parent = HighlightFunctionSection

local HighlightFunctionTitle = Instance.new("TextLabel")
HighlightFunctionTitle.Name = "HighlightFunctionTitle"
HighlightFunctionTitle.Text = "全局高亮"
HighlightFunctionTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
HighlightFunctionTitle.TextSize = 16
HighlightFunctionTitle.Font = Enum.Font.GothamBold
HighlightFunctionTitle.BackgroundTransparency = 1
HighlightFunctionTitle.Size = UDim2.new(0.9, 0, 0.2, 0)
HighlightFunctionTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
HighlightFunctionTitle.Parent = HighlightFunctionSection

local HighlightToggle = Instance.new("TextButton")
HighlightToggle.Name = "HighlightToggle"
HighlightToggle.Text = "开启高亮"
HighlightToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
HighlightToggle.TextSize = 14
HighlightToggle.Font = Enum.Font.Gotham
HighlightToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
HighlightToggle.BackgroundTransparency = 0.3
HighlightToggle.Size = UDim2.new(0.4, 0, 0, 35)
HighlightToggle.Position = UDim2.new(0.05, 0, 0.3, 0)
HighlightToggle.Parent = HighlightFunctionSection

local HighlightToggleCorner = Instance.new("UICorner")
HighlightToggleCorner.CornerRadius = UDim.new(0, 6)
HighlightToggleCorner.Parent = HighlightToggle

-- 创建其他界面
local Server1Interface = createInterface("Server1", false)
local Server2Interface = createInterface("Server2", false)
local Server3Interface = createInterface("Server3", false)
local Server4Interface = createInterface("Server4", false)
local SettingsInterface = createInterface("Settings", false)

-- 添加界面标题
local function addTitleToInterface(interface, titleText)
    local title = Instance.new("TextLabel")
    title.Name = interface.Name .. "Title"
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(0.9, 0, 0, 40)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Parent = interface
end

addTitleToInterface(Server1Interface, "服务器1")
addTitleToInterface(Server2Interface, "服务器2")
addTitleToInterface(Server3Interface, "服务器3")
addTitleToInterface(Server4Interface, "服务器4")
addTitleToInterface(SettingsInterface, "设置")

-- 将UI添加到玩家界面
MainUI.Parent = playerGui

-- ========== 功能实现 ==========

-- 拖拽功能
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    OuterContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

LightScriptLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = OuterContainer.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

LightScriptLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- 悬浮球点击切换UI显示/隐藏
local uiVisible = false

FloatingBall.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    
    if uiVisible then
        OuterContainer.Visible = true
        OuterContainer.Size = UDim2.new(0, 0, 0, 0)
        OuterContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        OuterContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(OuterContainer, tweenInfo, {
            Size = UDim2.new(0.8, 0, 0.7, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
    else
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(OuterContainer, tweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        
        tween.Completed:Connect(function()
            OuterContainer.Visible = false
        end)
    end
end)

-- 界面切换功能
local function switchInterface(interfaceName)
    HomeInterface.Visible = false
    GeneralInterface.Visible = false
    Server1Interface.Visible = false
    Server2Interface.Visible = false
    Server3Interface.Visible = false
    Server4Interface.Visible = false
    SettingsInterface.Visible = false
    
    if interfaceName == "Home" then
        HomeInterface.Visible = true
    elseif interfaceName == "General" then
        GeneralInterface.Visible = true
    elseif interfaceName == "Server1" then
        Server1Interface.Visible = true
    elseif interfaceName == "Server2" then
        Server2Interface.Visible = true
    elseif interfaceName == "Server3" then
        Server3Interface.Visible = true
    elseif interfaceName == "Server4" then
        Server4Interface.Visible = true
    elseif interfaceName == "Settings" then
        SettingsInterface.Visible = true
    end
end

-- 功能按钮点击效果和界面切换
local function setupButton(button, interfaceName)
    local originalSize = button.Size
    local hoverSize = UDim2.new(
        originalSize.X.Scale * 1.05, originalSize.X.Offset,
        originalSize.Y.Scale * 1.05, originalSize.Y.Offset
    )
    
    button.MouseEnter:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            Size = hoverSize,
            BackgroundTransparency = 0.2
        })
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            Size = originalSize,
            BackgroundTransparency = 0.3
        })
        tween:Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(70, 70, 100)
        })
        tween:Play()
        
        tween.Completed:Connect(function()
            local restoreTween = TweenService:Create(button, tweenInfo, {
                BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            })
            restoreTween:Play()
        end)
        
        switchInterface(interfaceName)
    end)
end

-- 设置所有功能按钮
setupButton(HomeButton, "Home")
setupButton(GeneralButton, "General")
setupButton(Server1Button, "Server1")
setupButton(Server2Button, "Server2")
setupButton(Server3Button, "Server3")
setupButton(Server4Button, "Server4")
setupButton(SettingsButton, "Settings")

-- 更新时间函数
local function updateBeijingTime()
    local serverTime = os.time()
    local beijingTime = serverTime + 8 * 60 * 60
    local timeTable = os.date("!*t", beijingTime)
    local timeString = string.format("%04d年%02d月%02d日 %02d:%02d:%02d", 
        timeTable.year, timeTable.month, timeTable.day, 
        timeTable.hour, timeTable.min, timeTable.sec)
    
    TimeDisplay.Text = timeString
end

-- 获取玩家头像函数
local function updatePlayerAvatar()
    local userId = player.UserId
    local thumbnailType = Enum.ThumbnailType.HeadShot
    local thumbnailSize = Enum.ThumbnailSize.Size420x420
    
    local success, result = pcall(function()
        return Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)
    end)
    
    if success then
        PlayerAvatar.Image = result
    end
end

-- 更新玩家信息函数
local function updatePlayerInfo()
    PlayerName.Text = "名称: " .. player.Name
    PlayerId.Text = "ID: " .. player.UserId
    PlayerAccountAge.Text = "账号天数: " .. player.AccountAge
end

-- 更新服务器信息函数
local function updateServerInfo()
    ServerName.Text = "服务器: " .. game.PlaceId
    PlayerCount.Text = "在线玩家: " .. #Players:GetPlayers() .. "/" .. game.Players.MaxPlayers
    
    local gameTime = math.floor(workspace.DistributedGameTime)
    local minutes = math.floor(gameTime / 60)
    local seconds = gameTime % 60
    GameTime.Text = string.format("游戏时间: %02d:%02d", minutes, seconds)
end

-- ========== FL飞行功能v3 (完整保留原逻辑) ==========
local FLFlyEnabled = false
local FLFlySpeeds = 1
local FLFlyNowe = false
local FLFlyTpwalking = false
local FLFlyTis, FLFlyDis

-- FL飞行开关功能
local function toggleFLFlying()
    if FLFlyNowe == true then
        FLFlyNowe = false

        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        
        FLFlyToggle.Text = "开启FL飞行"
        FLFlyToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
    else 
        FLFlyNowe = true

        for i = 1, FLFlySpeeds do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat	
                FLFlyTpwalking = true
                local chr = player.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while FLFlyTpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
        
        player.Character.Animate.Disabled = true
        local Char = player.Character
        local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
        for i,v in next, Hum:GetPlayingAnimationTracks() do
            v:AdjustSpeed(0)
        end
        
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        
        FLFlyToggle.Text = "关闭FL飞行"
        FLFlyToggle.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
    end

    if player.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
        local plr = player
        local torso = plr.Character.Torso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0

        local bg = Instance.new("BodyGyro", torso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        local bv = Instance.new("BodyVelocity", torso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if FLFlyNowe == true then
            plr.Character.Humanoid.PlatformStand = true
        end
        
        while FLFlyNowe == true or player.Character.Humanoid.Health == 0 do
            game:GetService("RunService").RenderStepped:Wait()

            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed+.5+(speed/maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed-1
                if speed < 0 then
                    speed = 0
                end
            end
            
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
            else
                bv.velocity = Vector3.new(0,0,0)
            end
            
            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        player.Character.Animate.Disabled = false
        FLFlyTpwalking = false
    else
        local plr = player
        local UpperTorso = plr.Character.UpperTorso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0

        local bg = Instance.new("BodyGyro", UpperTorso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = UpperTorso.CFrame
        local bv = Instance.new("BodyVelocity", UpperTorso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if FLFlyNowe == true then
            plr.Character.Humanoid.PlatformStand = true
        end
        
        while FLFlyNowe == true or player.Character.Humanoid.Health == 0 do
            wait()

            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed+.5+(speed/maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed-1
                if speed < 0 then
                    speed = 0
                end
            end
            
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
            else
                bv.velocity = Vector3.new(0,0,0)
            end

            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        player.Character.Animate.Disabled = false
        FLFlyTpwalking = false
    end
end

-- 上下控制功能
UpButton.MouseButton1Down:connect(function()
    FLFlyTis = UpButton.MouseEnter:connect(function()
        while FLFlyTis do
            wait()
            player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0,1,0)
        end
    end)
end)

UpButton.MouseLeave:connect(function()
    if FLFlyTis then
        FLFlyTis:Disconnect()
        FLFlyTis = nil
    end
end)

DownButton.MouseButton1Down:connect(function()
    FLFlyDis = DownButton.MouseEnter:connect(function()
        while FLFlyDis do
            wait()
            player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0,-1,0)
        end
    end)
end)

DownButton.MouseLeave:connect(function()
    if FLFlyDis then
        FLFlyDis:Disconnect()
        FLFlyDis = nil
    end
end)

-- 速度控制功能
PlusButton.MouseButton1Down:connect(function()
    FLFlySpeeds = FLFlySpeeds + 1
    SpeedDisplay.Text = "速度: " .. FLFlySpeeds
    if FLFlyNowe == true then
        FLFlyTpwalking = false
        for i = 1, FLFlySpeeds do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat	
                FLFlyTpwalking = true
                local chr = player.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while FLFlyTpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
    end
end)

MinusButton.MouseButton1Down:connect(function()
    if FLFlySpeeds == 1 then
        SpeedDisplay.Text = '速度: 1 (最低)'
        wait(1)
        SpeedDisplay.Text = "速度: " .. FLFlySpeeds
    else
        FLFlySpeeds = FLFlySpeeds - 1
        SpeedDisplay.Text = "速度: " .. FLFlySpeeds
        if FLFlyNowe == true then
            FLFlyTpwalking = false
            for i = 1, FLFlySpeeds do
                spawn(function()
                    local hb = game:GetService("RunService").Heartbeat	
                    FLFlyTpwalking = true
                    local chr = player.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while FLFlyTpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
        end
    end
end)

-- 角色重生事件
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.7)
    player.Character.Humanoid.PlatformStand = false
    player.Character.Animate.Disabled = false
    FLFlyNowe = false
    FLFlyTpwalking = false
    FLFlyToggle.Text = "开启FL飞行"
    FLFlyToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
end)

-- ========== 玩家信息显示功能 ==========
local playerInfoEnabled = false
local playerBillboards = {}

local function createPlayerBillboard(targetPlayer)
    local character = targetPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not humanoid or not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = targetPlayer.Name .. "Info"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 180, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    -- 背景框
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.4
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, 4)
    backgroundCorner.Parent = background
    
    -- 名字标签
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = false
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Parent = billboard
    
    -- 血量标签
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Text = "血量: 100%"
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.TextScaled = false
    healthLabel.TextSize = 9
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.BackgroundTransparency = 1
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.Parent = billboard
    
    playerBillboards[targetPlayer] = billboard
    
    local function updateHealth()
        if billboard and billboard.Parent then
            local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            healthLabel.Text = "血量: " .. healthPercent .. "%"
            
            if healthPercent > 70 then
                healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif healthPercent > 30 then
                healthLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
            else
                healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end
    end
    
    humanoid.HealthChanged:Connect(updateHealth)
    updateHealth()
    
    targetPlayer.CharacterAdded:Connect(function(newCharacter)
        wait(1)
        if playerInfoEnabled and playerBillboards[targetPlayer] then
            playerBillboards[targetPlayer]:Destroy()
            createPlayerBillboard(targetPlayer)
        end
    end)
end

local function togglePlayerInfo()
    if playerInfoEnabled then
        for _, billboard in pairs(playerBillboards) do
            if billboard then
                billboard:Destroy()
            end
        end
        playerBillboards = {}
        PlayerInfoToggle.Text = "显示玩家信息"
        PlayerInfoToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
        playerInfoEnabled = false
    else
        PlayerInfoToggle.Text = "隐藏玩家信息"
        PlayerInfoToggle.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
        playerInfoEnabled = true
        
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                createPlayerBillboard(otherPlayer)
            end
        end
        
        Players.PlayerAdded:Connect(function(newPlayer)
            if playerInfoEnabled then
                wait(1)
                createPlayerBillboard(newPlayer)
            end
        end)
        
        Players.PlayerRemoving:Connect(function(leavingPlayer)
            if playerBillboards[leavingPlayer] then
                playerBillboards[leavingPlayer]:Destroy()
                playerBillboards[leavingPlayer] = nil
            end
        end)
    end
end

-- ========== 全局高亮功能 ==========
local highlightEnabled = false
local originalBrightness

local function toggleHighlight()
    if highlightEnabled then
        Lighting.Brightness = originalBrightness or 1
        HighlightToggle.Text = "开启高亮"
        HighlightToggle.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
        highlightEnabled = false
    else
        originalBrightness = Lighting.Brightness
        Lighting.Brightness = 3
        HighlightToggle.Text = "关闭高亮"
        HighlightToggle.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
        highlightEnabled = true
    end
end

-- 功能绑定
FLFlyToggle.MouseButton1Click:Connect(toggleFLFlying)
PlayerInfoToggle.MouseButton1Click:Connect(togglePlayerInfo)
HighlightToggle.MouseButton1Click:Connect(toggleHighlight)

-- 自动调整滚动区域
LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentHeight = LeftLayout.AbsoluteContentSize.Y
    LeftScrollContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
end)

RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentHeight = RightLayout.AbsoluteContentSize.Y
    RightScrollContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
end)

-- 初始化UI
updateBeijingTime()
updatePlayerAvatar()
updatePlayerInfo()
updateServerInfo()

-- 每秒更新时间
RunService.Heartbeat:Connect(function()
    updateBeijingTime()
    
    if math.floor(workspace.DistributedGameTime) % 5 == 0 then
        updateServerInfo()
    end
end)

-- 响应式布局
local function updateUISize()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if viewportSize.X < 800 then
        OuterContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
        OuterContainer.Position = UDim2.new(0.05, 0, 0.1, 0)
    else
        OuterContainer.Size = UDim2.new(0.8, 0, 0.7, 0)
        OuterContainer.Position = UDim2.new(0.1, 0, 0.15, 0)
    end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUISize)
updateUISize()

-- 发送欢迎通知
game.StarterGui:SetCore("SendNotification", {
    Title = "Light Script",
    Text = "欢迎使用Light Script！",
    Duration = 5
})

print("Light Script UI 加载完成!")
