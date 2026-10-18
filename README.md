# LightScript

> LS Team · Roblox Luau 脚本框架 + 自带 UI 库
> 主体 `LightScript.lua`　UI 库 `ui_APP.Lua`　子项目 `projects/*.lua`

---

## 这是什么

一个自研的 Roblox 脚本工程，分两层：

- **LightScript（主体）**：负责创建窗口、灵动岛、通用功能（飞行 / 速度 / 穿墙 / 甩飞 / 环绕 / 无敌），并从本地或远程加载子项目
- **子项目（projects/）**：按游戏划分的功能模块，被主体调用后**把自己的 Tab 挂进同一个窗口**，不另建窗口、不建灵动岛
- **UI 库（ui_APP.Lua）**：自研玻璃拟态 UI，本仓库所有界面都基于它

```
LightScript.lua      ← 主体入口
ui_APP.Lua           ← UI 库（手机上存为 LS_UI.lua）
projects/nds.lua     ← 子项目：自然灾害（灾害预警 + 地图投票）
examples/demo_ui.lua ← 全控件演示
docs/PROJECT.md      ← 项目交接文档（原理、流程、踩坑、待办）
docs/UI_REVIEW.md    ← UI 库设计评审
tools/diag/          ← 历史诊断脚本
archive/             ← 备份与旧实验，不参与运行
```

---

## 快速开始

### 1. 推送文件到设备

```bash
adb push LightScript.lua          /sdcard/Delta/Workspace/LightScript.lua
adb push ui_APP.Lua               /sdcard/Delta/Workspace/LS_UI.lua
adb push projects/nds.lua         /sdcard/Delta/Workspace/nds.lua
```

### 2. Autoexecute

`/sdcard/Delta/Autoexecute/zz_ls_boot.lua`

```lua
task.wait(0.5)
local ok, err = pcall(function()
    return assert(loadstring(readfile("LightScript.lua"), "=LightScript"))()
end)
if not ok and writefile then writefile("ls_boot_err.txt", tostring(err)) end
```

进游戏后自动加载。手动加载同理，把 `LightScript.lua` 内容丢进执行器即可。

---

## 功能一览

| 页 | 功能 | 说明 |
|---|---|---|
| 主页 | 运行状态 / 快速操作 | 玩家信息、服务器 JobId |
| 移动 | 飞行、行走速度、跳跃力度 | CFrame 飞行，摇杆控制，俯仰跟视角，绝不进入下坠 |
| 工具 | 防甩飞、无敌、Noclip | 位置锁 + 伤害拦截 |
| 工具 | 甩飞（SkidFling）、旋转甩飞、配件甩飞 | 三种实现并存 |
| 工具 | Parts 环绕 | 抢夺附近未锚定部件绕身旋转 |
| 设置 | 主题、强调色、关闭脚本 | 关闭时完整清理 |
| 自然灾害 | 灾害预警、地图投票 | 子项目，见 `projects/nds.lua` |

---

## UI 库使用文档

### 3.1 加载与建窗

```lua
local Library = loadstring(readfile("LS_UI.lua"), "=LS_UI")()
local win = Library:CreateWindow({
    Title  = "LightScript",
    Theme  = "Nebula",        -- 主题预设
    Island = true,            -- false = 不创建灵动岛（子项目用）
})
win:ShowMain()
```

| 选项 | 类型 | 说明 |
|---|---|---|
| `Title` | string | 窗口标题 |
| `Theme` | string | 主题名，见 `Library.Themes` |
| `Island` | boolean | **默认 true**；子项目传 `false`，只往传入窗口加 Tab |
| `DisplayOrder` | number | 覆盖默认 `2147483647`（顶置，防止被游戏 GUI 挡住触摸） |

### 3.2 Tab

```lua
local tab = win:CreateTab("工具", "bolt")   -- 第二个参数是内置图标名
```

内置图标：`dashboard` `combat` `visual` `settings` `info` `home` `move` `bolt`

### 3.3 控件

所有控件都返回 **table 代理**，不是原始 Instance；需要原始对象时取 `.Frame`。

```lua
tab:CreateSection("分组标题")
tab:CreateDivider()
tab:CreateParagraph("多行说明文字\n第二行", 2)   -- 第二个参数是行数

tab:CreateButton("按钮文字", function() end)

tab:CreateToggle("开关", false, function(on) end)

tab:CreateSlider("滑条", 0, 100, 50, function(v) end)

local drop = tab:CreateDropdown("下拉", { "A", "B" }, "A", function(choice) end)
drop:Set("B")                 -- 代码设置选中项
drop:Get()                    -- 当前值
drop:GetOptions()             -- 选项列表
drop:SetOptions({ "C", "D" }) -- 运行时替换选项（本库扩展）

tab:CreateTextbox("标题", "占位符", "默认值", function(text) end)
```

### 3.4 通知与灵动岛

```lua
win:Notify("标题", "内容", 4, { Type = "success" })   -- success / warning / info / error
win:Warning("标题", "内容", 4)                        -- 等价 Notify + warning
win:Toast("标题", "内容", 4)                          -- Notify 的容错别名

win:SetIslandStatus("运行中")           -- 灵动岛状态文字
win:SetIslandDot(Theme.Success)         -- 状态点颜色
win:SetIslandAvatar(assetId)            -- 头像
win:SetIslandTitle("标题")              -- 标题

win:ToggleMain()          -- 展开/收起主窗口
win:ShowMain() / win:HideMain()
win:SetMainPosition(UDim2.new(0.5, 0, 0.585, 0))
win:GetMainFrame()        -- 原始 CanvasGroup
win:SetCloseAction(fn)    -- 关闭按钮回调
win:Destroy() / win:IsDestroyed()
```

`Island = false` 时所有 `SetIsland*` 接口自动变为空操作，不会报错——**子项目可以放心调用**。

### 3.5 清理

```lua
Library:DestroyAll()      -- 销毁所有窗口、通知、连接
```

---

## 子项目规范

1. 文件结构统一为工厂函数：

```lua
return function(ctx)
    local Library, win = ctx.Library, ctx.Window
    local tab = win:CreateTab("我的游戏", "bolt")
    tab:CreateButton("做点什么", function() end)
    return { name = "MyGame", stop = function() end }
end
```

2. **不建灵动岛**（`Island = false`），只往传入的窗口加 Tab
3. 独立运行时自己 `CreateWindow({ Island = false })`
4. 导出 `stop()`，主体 `Shutdown` 时统一清理
5. 主体加载方式：

```lua
local factory = loadstring(readfile("nds.lua"), "=nds")()
local project = factory({ Library = Library, Window = win, Project = "Natural Disaster" })
```

> ⚠️ 注意先 `chunk()` 拿工厂，再 `factory(ctx)`。`pcall(chunk, ctx)` 不会执行工厂函数。

---

## 环境要求

- 执行器：Delta / Synapse 类，identity 7+
- 需要 API：`gethui`、`getrawmetatable`、`setreadonly`、`newcclosure`、`hookmetamethod`、`hookfunction`、`firesignal`、`getconnections`、`sethiddenproperty`、`writefile` / `readfile`
- 缺失时自动降级并提示（例如无敌会退回补血模式）

---

## 设计取向

- **隐匿**：运行逻辑干净，操作有冷却控制
- **稳定**：出错自己兜住，不影响正常游玩
- **无痕**：关闭时自动清理，不残留对象和连接

功能可以很强，但底层干净才是根本。

---

## 已知问题

见 [docs/PROJECT.md](docs/PROJECT.md) 第 7 节「未完成事项」：

1. 无敌在部分游戏仍会死（服务端复制绕过客户端钩子）
2. 甩飞仅 SkidFling 对贴身目标有效
3. Parts 环绕观感弱于原版
4. 投票列表需手动刷新
5. ESP 未接入主体

---

## 许可证

仅供学习与研究使用。
