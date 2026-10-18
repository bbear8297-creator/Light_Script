# LS UI 库（ui_APP.Lua）审查与修复报告

审查对象：`ui_APP.Lua`（2246 行，v1.0 "修复版"）
修复产物：`ui_APP.fixed.lua`（2413 行）
校验：`luau-analyze` → **0 个语法错误**；剩余诊断全部是 Roblox 全局（`Instance`/`Enum`/`UDim2`…）在离线分析器里未知，属正常。

---

## 一、这个库的结构（先理解，再修）

```
ui_APP.Lua
├─ 常量        ICONS
├─ 工具        Measure / Safe / attachMethod ← 方法挂载（问题核心）
├─ targetGui   ScreenGui 的宿主层
├─ 玻璃层      Glass.Levels + Glass.Apply(parent, {Level, Tint, Radius, EdgeT})
│              给任意 GuiObject 贴 UICorner + UIStroke
├─ 主题        Library.Themes { DeepSpace, Nebula, Aurora, Ember }
├─ 计数器      FeatureCounter（登记开启的功能数，喂给灵动岛）
├─ 灵动岛      CreateDynamicIsland(parent, theme, callbacks)
│              头像 + 状态文字 + 状态点 + ping + fps，宽度按文本实测自增长
└─ Library:CreateWindow(options) → Window
   ├─ blurCtrl        BlurEffect 开/关（0 ↔ 8，带补间与销毁）
   ├─ ScreenGui       的命名 LS_UI_<随机>，ResetOnSpawn=false，DisplayOrder=999999
   ├─ Overlay         全屏隐形 TextButton，ZIndex 500，给下拉/取色器做"点外部关闭"
   ├─ NotifContainer  右上竖排通知（UIListLayout）
   ├─ MainFrame       0.92×0.78 + UISizeConstraint(340..720 × 300..470) + UIScale 弹入弹出
   │  ├ TopBar        标题 + 关闭钮 + 拖拽
   │  ├ Sidebar       0.30 宽，玻璃面板 + 竖向 TabContainer
   │  └ ContentContainer 0.70 宽，装每个 Tab 的 ScrollingFrame
   ├─ pushNotification(title, msg, duration, {Type})
   ├─ Window API: Notify/Toast/Success/Warning/Error、ShowMain/HideMain/ToggleMain、
   │              GetIsland/SetIsland*、RegisterFeature/SetFeatureActive、
   │              ApplyTheme/SetAccentColor、TrackConnection/AddCleanup、Destroy
   └─ CreateTab(name, iconId, iconOpts) → Elements
      CreateLabel / CreateSection / CreateDivider / CreateButton / CreateToggle /
      CreateSlider / CreateDropdown / CreateTextbox / CreateProgressBar /
      CreateInfoPanel / CreateImage / CreateColorPicker / CreateKeybind / CreateParagraph
```

三个贯穿全局的机制：

1. **themeRegistry**：`RegisterTheme(fn)` 把"这个控件怎么跟着换肤"存起来，`RunTheme()` 统一重放。
2. **globalConns**：`track(conn)` 收集所有连接，`Window:Destroy()` 一次断开。
3. **Element 方法**：属性型控件（Label/InfoPanel）需要 `:SetText` 这类方法，靠 `attachMethod` 挂到 Instance 上。

---

## 二、致命问题（会直接导致"点了没反应 / 界面不出来"）

### P0-1 `attachMethod` 从来就没成功过 —— 元素方法全是 nil

原文件 42–54 行：

```lua
local ok = pcall(function() rawset(inst, name, fn) end)   -- ①
if not ok then ok = pcall(function() inst[name] = fn end) end  -- ②
```

- ① `rawset` 只接受 table。`Instance` 是 userdata，`rawset` 直接抛 `table expected`，pcall 吃掉。
- ② Instance 的 `__newindex` 只允许写真实属性，写未知 key 抛 `X is not a valid member of Frame`，又被 pcall 吃掉。

于是 `attachMethod` 永远返回 `false`，而调用方在 1034–1039、1760–1768 行挂了
`SetText / SetValue / SetServerInfo / SetExecutorInfo / SetPlayerName` —— 这些方法一个都没挂上。
外部脚本一写 `label:SetText("...")` 就是 `attempt to call a nil value`，被外层 `Safe()` 吞掉 → **UI 看着正常，功能点了没反应**。

**修复**：所有 Instance 共享同一个 metatable，把方法查表插到 `__index` 前面。

```lua
local MethodRegistry = setmetatable({}, { __mode = "k" })  -- Instance -> {name = fn}

local function hookInstanceIndex()
    if instanceIndexHooked then return true end
    if type(getrawmetatable) ~= "function" or type(setreadonly) ~= "function" then return false end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local original = mt.__index
        setreadonly(mt, false)
        local hook = function(self, key)
            local store = MethodRegistry[self]
            if store then local fn = store[key]; if fn ~= nil then return fn end end
            if type(original) == "function" then return original(self, key) end
            if type(original) == "table" then return original[key] end
        end
        if type(newcclosure) == "function" then hook = newcclosure(hook) end
        mt.__index = hook
        setreadonly(mt, true)
        instanceIndexHooked = true
    end)
    return ok and instanceIndexHooked
end
```

`attachMethod` 变成三段式：`rawset`（少数执行器支持）→ metatable 注入（主路径）→ 登记到
`MethodRegistry`，用新增的 `Library:Call(inst, "SetText", txt)` 兜底（纯 Studio 无执行器时）。

### P0-2 没有 `gethui` 时 UI 一个像素都不会画

原文件 57–64 行：

```lua
targetGui = (ok and res) or CoreGui
if not pcall(function() return targetGui.Name end) then
    targetGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end
```

只验证了 `CoreGui.Name` **能不能读**。读得到 ≠ 能写。Studio / 部分执行器里
`ScreenGui.Parent = CoreGui` 会抛 *"The current identity cannot modify CoreGui"*，
而这一句在 `CreateWindow` 里没有被 pcall 包，整个函数直接中断 → 后续什么都建不出来。

**修复**：`resolveGuiParent()` 改成真探测 —— `gethui()` → 试着往 CoreGui 塞一个探针
ScreenGui 再删掉 → 都不行退回 `PlayerGui`（并带 LocalPlayer 等待）。

### P0-3 `AllWindows` 是弱值表 + 用 `#` 取下标，`DestroyAll()` 会漏窗口

原文件 2222–2243 行：

```lua
local AllWindows = setmetatable({}, { __mode = "v" })
...
AllWindows[#AllWindows + 1] = win
```

- `__mode = "v"`：Window 表只被这张弱表引用，随时可能被 GC 掉（ScreenGui 实例活着不算引用）。
- `#AllWindows`：表出现空洞后长度不可靠，新窗口会**覆盖**已有下标。

结果：`DestroyAll()` 只能关掉一部分窗口，剩下的 `ScreenGui` 永久留在 CoreGui/PlayerGui 上，
只能重启客户端清掉。而且它定义在文件末尾，`Window:Destroy` 若引用它会读到 `nil` 全局。

**修复**：`local AllWindows = {}` 提到文件顶部（CreateWindow 之前）前向声明，改成
`table.insert` 顺序追加；`Window:Destroy()` 里 `forgetWindow(self)` 主动摘除；
新增 `Library:GetWindows()`。

### P0-4 `FeatureCounter` 是模块级单例，多窗口互相污染

原文件 179–217 行：`features / listeners / counter` 都是模块级 local。
两个窗口各自 CreateToggle → 计数混在一起；窗口 A 销毁后 B 的灵动岛还在显示 A 的功能数。

**修复**：抽成 `createFeatureCounter()` 工厂，`CreateWindow` 内 `local FeatureCounter = createFeatureCounter()`；
`Window:Destroy()` 调 `FeatureCounter.Clear()`；`Library.Features` 留一个全局实例给外部兼容。

---

## 三、严重问题（功能可用但表现错）

### P1-1 通知的滑入动画永远不播

原文件 806–819 行：`notif` 挂在 `NotifContainer` 的 `UIListLayout` 下，又去补间
`notif.Position` —— UIListLayout 每帧重算子物体 Position，补间被立刻覆盖，卡片是"瞬移"进来的。

**修复**：`notif` 加 `ClipsDescendants = true`，内部加一层 `body`（1,0,1,0，透明），
bar / title / msg 全部挂到 `body`，滑动补间作用在 `body.Position` 上；`UIScale` 弹入保持。

### P1-2 Slider 的点击热区只有 6px

原文件 1340–1345 行：`hit`（透明 TextButton）父级是 `barBg`，而 `barBg` 高度是 6px。
用户几乎不可能点中滑条，只能碰运气点那颗 16px 的圆钮。

**修复**：`hit.Parent = frame`、`Size = (1,0,1,0)` 覆盖整行；`update()` 里除零保护、
返回值 clamp 到 `[min, max]`、`min == max` 时 `span` 兜底为 1。

### P1-3 元素拿不到句柄 → 存读配置做不了

Slider / Dropdown / Keybind 原来 `return frame`，没有任何 Set/Get；
ProgressBar 返回的表里没有 Frame。存档系统只能靠闭包，重启即失。

**修复**（全部**向后兼容**，返回类型不变）：
- Slider / Dropdown / Keybind：`return frame`，并 `attachMethod(frame, "Set"/"Get", ...)`
- Toggle：仍返回表 `{Frame, Set, Get, GetFeatureId}`，同时在 `frame` 上挂同样的方法
- ProgressBar：返回表里补 `Frame` 和 `Get`

### P1-4 小视口下取色器位置计算会直接报错

原文件 1850–1853 行：`math.clamp(x, 10, ScreenGui.AbsoluteSize.X - 258)`。
当屏幕宽度 < 268px（手机小窗、部分模拟器）时 `min > max`，
`math.clamp` 抛 *"invalid argument #2 (min must be less than or equal to max)"*。

**修复**：新增 `clampSafe(x, lo, hi)`，`hi < lo` 时返回 `lo`，取色器两处替换。

---

## 四、低优先级 / 代码味道

| # | 位置 | 问题 | 处理 |
|---|---|---|---|
| P2-1 | 881 / 2192 | `Window:AddCleanup` 定义了两次（实现完全相同） | 删掉后者（原 2192–2196） |
| P2-2 | 1192 | `local track = Instance.new("TextButton")` 遮蔽了外层的连接收集函数 `track(conn)`；本函数内暂无 `track()` 调用所以不炸，但是个定时炸弹 | 未改名，注释标注 |
| P2-3 | 944 | `activeKeybinds` 从未使用（`LocalUnused`） | 保留，Destroy 里清空 |
| P2-4 | 1524 | Dropdown 关闭时不回收 `list` 的 `UICorner` 引用；仅 `Destroy` 实例，无泄漏 | 无需处理 |
| P2-5 | 1675 | `CreateInfoPanel` 只支持 `SetServerInfo` 等，没有 `SetAvatar` | 可后续加 |

---

## 五、验证方式

```lua
-- 执行器里
local LS = loadstring(readfile("ui_APP.fixed.lua"))()   -- 或 game:HttpGet(...)
local win = LS:CreateWindow({ Title = "Light Script", Theme = "Nebula" })
win:ShowMain()

local tab = win:CreateTab("主要", "rbxassetid://10723407389")
tab:CreateSection("测试")

local lbl = tab:CreateLabel("标签 · 初始")
lbl:SetText("标签 · 已更新")          -- P0-1：这里以前必报 nil

local s = tab:CreateSlider("速度", 16, 200, 50, function(v) print("speed", v) end)
s:Set(120); print(s:Get())            -- P1-3

local k = tab:CreateKeybind("开关", Enum.KeyCode.RightShift, function() print("key") end)
print(k:Get())

win:Success("完成", "P0 修复验证通过")
win:Notify("通知", "滑入动画应该能看见了")   -- P1-1

-- 5 秒后
task.delay(5, function()
    LS:DestroyAll()                    -- P0-3：现在能全清干净
    print("windows:", #LS:GetWindows())
end)
```

## 六、如何在你的工作流里用

```powershell
# 差异对照
git diff --no-index -- ui_APP.Lua ui_APP.fixed.lua

# 确认无误后替换
Move-Item ui_APP.Lua ui_APP.v1.0.bak.lua
Move-Item ui_APP.fixed.lua ui_APP.Lua
```

> 说明：`Light_Script_Locked.lua` 是混淆产物，无法反推它具体调用了哪些元素方法。
> 因此本次修复**没有改动任何已有函数的签名和返回类型**，只做了：
> ① 让 `attachMethod` 真正生效；② 修掉会中断流程的宿主层/生命周期问题；
> ③ 在原有返回对象上**追加** Set/Get 方法。理论上对现有调用方零破坏。
