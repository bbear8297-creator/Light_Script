# LightScript 项目文档

> 最后更新：本次会话结束
> 主体版本：`1818f70`　子项目：`projects/nds.lua`
> 运行环境：Android + Delta Executor（注入 Roblox）

---

## 1. 项目定位

**LightScript（LS）是主体**，负责：UI 窗口、灵动岛、通用功能模块（飞行/速度/甩飞/环绕/无敌）。
**各游戏做成子项目**，被主体远程调用后把自己的 Tab 挂进同一个窗口，**子项目不建灵动岛**。

```
LightScript.lua           主体
├─ ui_APP.Lua             UI 库（窗口/控件/灵动岛）
└─ projects/*.lua         子项目（按游戏划分）
   └─ nds.lua             自然灾害：灾害预警 + 地图投票
```

调用约定：

```lua
-- 主体加载子项目
local chunk = loadstring(readfile("nds.lua"), "=nds")
local factory = chunk()                      -- 文件 return 的是工厂函数
local project = factory({ Library = Library, Window = win, Project = "..." })
```

> ⚠️ 踩过的坑：`pcall(chunk, ctx)` 只会拿到工厂函数，**不会执行它**。
> 必须先 `chunk()` 再 `factory(ctx)`，否则子项目永不生效但日志显示"已加载"。

子项目独立运行时会自己 `CreateWindow({ Island = false })`，不带岛。

---

## 2. 文件清单

| 文件 | 大小 | 作用 |
|---|---|---|
| `LightScript.lua` | 50,090 B | 主体：UI、飞行、速度、Noclip、甩飞×3、环绕、防甩飞、无敌、子项目加载器 |
| `projects/nds.lua` | 10,793 B | 子项目：灾害预警、地图投票 |
| `ui_APP.Lua` | 119,705 B | UI 库：窗口、Tab、控件、灵动岛、通知 |
| `demo_ui.lua` | 14,695 B | 全控件演示 |
| `ESP_lib.lua` / `FX.lua` | 16 KB / 31 KB | 预留扩展（未接入主体） |
| `diag_*.lua` | 各 1–3 KB | 历史诊断脚本 |

手机上对应路径：`/sdcard/Delta/Workspace/{LightScript.lua, nds.lua, LS_UI.lua}`

---

## 3. 注入与测试流程

### 3.1 推送文件

```powershell
adb push D:\Code\Light_Script\LightScript.lua        /sdcard/Delta/Workspace/LightScript.lua
adb push D:\Code\Light_Script\projects\nds.lua       /sdcard/Delta/Workspace/nds.lua
adb push D:\Code\Light_Script\ui_APP.Lua             /sdcard/Delta/Workspace/LS_UI.lua
```

### 3.2 Autoexecute 启动脚本

`/sdcard/Delta/Autoexecute/zz_ls_boot.lua`：

```lua
task.wait(0.5)
local ok, err = pcall(function()
    return assert(loadstring(readfile("LightScript.lua"), "=LightScript"))()
end)
if not ok and writefile then writefile("ls_boot_err.txt", tostring(err)) end
```

### 3.3 重启客户端

```powershell
adb shell am force-stop com.roblox.client
adb shell am start -n com.roblox.client/com.roblox.client.startup.ActivitySplash
# 等约 40s（游戏加载完 autoexecute 才会触发）
```

### 3.4 验证与调试

```powershell
adb shell screencap -p /sdcard/x.png; adb pull /sdcard/x.png D:\Code\_tools\x.png
adb shell "cat /sdcard/Delta/Workspace/ls_boot_err.txt"
```

调试用探针脚本：临时把 `zz_ls_boot.lua` 换成探针内容（加载 LightScript → 操作模块 → `writefile` 落盘），再 `adb pull` 读结果。**所有结论都以设备实测数据为准，不靠猜。**

### 3.5 语法门禁

```powershell
D:\Code\_tools\luau\luau-analyze.exe D:\Code\Light_Script\LightScript.lua
# 必须 SyntaxError: 0 才能推送
```

---

## 4. 功能与原理

### 4.1 飞行（Fly）

- `root.Anchored = true` 悬浮，每帧按相机朝向写 CFrame
- 摇杆输入：`PlayerModule:GetControls():GetMoveVector()`
- 方向：`cam.CFrame.LookVector * (-mv.Z) + cam.CFrame.RightVector * mv.X`
- 俯仰：`math.asin(camLook.Y)`，钳制 ±60°
- 禁用 `Freefall/FallingDown/Ragdoll`，强制 `Running`，绝不进入下坠状态
- 速度滑条 10–300

**约束**：这台账号的 R15 骨架只有 `AnimationConstraint`，没有 `Motor6D`，且关节只在动画播放时存在 → **不能禁用 Animate**，否则关节消失。

### 4.2 速度 / Noclip

- 速度：`Humanoid.WalkSpeed`、`JumpPower`（16–300 / 50–300）
- Noclip：`RunService.Stepped` 里把所有部件 `CanCollide = false`

### 4.3 甩飞（三种，效果最好的是 SkidFling）

| 模式 | 原理 | 实测 |
|---|---|---|
| **SkidFling（立即甩飞）** | 把自己 CFrame 塞进目标身体 + 写 `9e7/9e8` 速度，短促爆发 | **对方会飞**（唯一有效的） |
| 旋转甩飞（漩涡） | 给自己写 `AssemblyAngularVelocity` 高速自转撞人 | 甩飞的是自己 |
| 配件甩飞 | 生成高速部件 + `firetouchinterest` 强制触碰 | 未验证 |

SkidFling 关键前置：

```lua
workspace.FallenPartsDestroyHeight = 0/0     -- 飞出去的部件不被销毁
hum:SetStateEnabled(Seated, false)
```

已做的修正：
- **删掉 `BodyVelocity(0, 9e9)`** —— 它会把角色钉死，甩飞期间完全不能移动
- 时长默认 **0.45 秒**（0.2–1.2），短促爆发，结束立刻恢复移动
- 每帧清自己的速度但**不拉位置**，避免被钉子化
- 每帧 `God:heal()`，甩飞期间不掉血

### 4.4 防甩飞（SelfLock）

不与物理对抗，每帧校验「自己该在哪」：

```lua
if 速度 > 阈值 or 角速度 > 40 or 偏离锚点 > 阈值 then
    清 AssemblyLinearVelocity / AssemblyAngularVelocity
    root.CFrame = anchorCF        -- 拉回
else
    anchorCF = root.CFrame        -- 正常走路时锚点跟着走
end
```

参数：速度阈值 90、位移阈值 12。**正常移动不受限**，只有异常位移才触发。

### 4.5 无敌（God）

**两层**：

1. **真无敌**：`hookmetamethod(game, "__newindex", ...)` 拦截 `Humanoid.Health` 的赋值，`value <= 0` 且属于本地角色 → 直接 `return` 吞掉
2. 兜底：每帧补血、`BreakJointsOnDeath = false`、`FallenPartsDestroyHeight = -math.huge`

执行器不支持 `hookmetamethod` 时自动退回补血模式并在 UI 提示。

> ⚠️ **未解决**：实测仍然会死。可能原因：
> - `hookmetamethod` 在 Delta 上被屏蔽（需看 UI 提示是哪一条）
> - 死亡由服务端复制 `Health` 触发，绕过 Lua `__newindex`
> - 下一步：探针确认 `God.hooked` 与「Lua 写 `Health=0` 是否被吞」

### 4.6 Parts 环绕（照抄 Super Ring Parts V6）

```lua
-- 每条心跳
sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
LocalPlayer.ReplicationFocus = workspace

-- 对每个未锚定、非角色的部件
part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)   -- 质量归零
part.CanCollide = false
part.Velocity = (目标点 - 当前位置).Unit * attraction               -- 恒定吸力
```

参数（与原版一致）：半径 50、高度 100、转速 10、力度 1000、最大部件 **2000**、**不过滤距离**。

关键结论：
- 能不能推动部件取决于**该部件是否已由本客户端模拟**，与调什么 API 无关
- `SetNetworkOwner` / `GetNetworkOwner` 客户端调用直接报错（仅服务端）
- 实测：60 个部件里 36 个真的在动

**未解决**：用户反馈原版能吸更大更多，当前观感仍偏弱；可能需要继续对比原版 `ForcePart`（Torque + AlignPosition 指向共享锚点）那条未启用的分支。

### 4.7 子项目：自然灾害（projects/nds.lua）

Dex 实测结构：

```
PlayerGui.MainGui.MapVotePage                  投票页 Frame（默认不可见）
  .Vote.Choice1/2/3  (ImageButton)
    .MapNameLabel   (TextLabel，地图名)
PlayerGui.UIs.<frame>.warningText              灾害名文字
```

**灾害预警**：每 0.4 秒轮询 `warningText`（最早、最准），workspace 模型监听作兜底。
实测抓到 `Blizzard`。

**地图投票**（当前形态，按用户要求）：

```
候选地图 [下拉]   ← CreateDropdown + SetOptions 运行时换项
刷新候选          ← 读 Choice1/2/3 的 MapNameLabel
投票              ← firesignal(ImageButton.MouseButton1Click)
自动投票          ← 每 2 秒重复
```

实测读到过：`Rakish Refinery` / `Fort Indestructable` / `Arch Park`。

> 已废弃：强制显示原版投票页（`RenderStepped` 每帧置 `Visible`）。
> 问题：会盖住我们的窗口导致「关不掉、点不了」。用户明确说不要原版界面。
> 如要恢复：需要同时把 `ScreenGui.DisplayOrder` 提到最高（已改为 `2147483647`）。

---

## 5. 环境与硬约束

| 项 | 值 |
|---|---|
| 执行器 | Delta，`identifyexecutor()` → `"Delta"`，identity 8 |
| 设备 | OnePlus PLR110 / Android 16 / arm64-v8a |
| 注入目标 | `com.roblox.client` v2.741.1062 |
| 可用 API | `gethui, getrawmetatable, setreadonly, newcclosure, request, writefile/readfile, setclipboard, hookfunction, identifyexecutor, setfpscap, Drawing, firesignal, getconnections, sethiddenproperty` |
| 缺失 API | `gettenv, syn, getclipboard, protectgui, saveinstance, setupvalues` |
| 骨架 | R15，只有 `AnimationConstraint`，**没有 Motor6D** |

---

## 6. 踩坑记录（重要）

1. **Luau `GETMETHOD`**：`obj:Method()` 对 userdata 绕过 `__index` → 元素必须返回 table 代理，`.Frame` 拿原始 Instance
2. **`attachMethod` 无效**：`rawset(userdata)` 报 "table expected" → 改用元表 `__index` 注入
3. **UI 不可见**：需 `gethui()`，退化到 CoreGui → PlayerGui 探测
4. **通知卡死**：`os.clock()` 是 CPU 时间会暂停 → 改 `DateTime` 墙钟 + 心跳泵 + 孤儿清扫
5. **Tab 塞不下**：第 6 个 Tab 被裁到侧栏外 → Tab 高度 38 → 30
6. **子项目"加载成功"但无 Tab**：工厂函数没被调用（见第 1 节）
7. **PowerShell 拼接截断文件**：`$e` 匹配到多行导致 slice 失败 → 大改动用 `edit` 工具或先备份 `git show <commit>:file`
8. **PS 单引号里的 `` `n ``** 是字面量，会写进 Lua 文件造成语法错误
9. **中文替换用 PowerShell 会乱码** → 改文件一律用 write/edit 工具

---

## 7. 未完成事项（下次开工清单）

按优先级：

1. **无敌为什么还会死**
   - 探针确认 `God.hooked` 真假
   - 若 hook 成功但还死 → 死亡来自服务端复制，需换方案（`SetStateEnabled(Dead,false)` + `Died` 事件抢救 + `ChangeState(Physics)`）
2. **甩飞只对单人生效**
   - 现仅 SkidFling 有效果，且需要目标贴身
   - 可尝试：短时 `SetNetworkOwner` 声明失败后，改用「目标为锚点」的多段触碰
3. **Parts 环绕观感弱于原版**
   - 对比原版未启用的 `ForcePart`（`Torque` + `AlignPosition` 指向共享锚点部件）
   - 或提高 `maxParts` 到全量、`attraction` 到 1500+
4. **投票下拉的刷新时机**
   - 目前靠手动「刷新候选」；可加「回合切换自动刷新」（监听 `MapVotePage:GetPropertyChangedSignal("Visible")`）
5. **ESP 未接入**
   - `ESP_lib.lua` 已在仓库，可做成第二个子项目 `projects/esp.lua`

---

## 8. 常用接口（调试用）

```lua
local LS = getgenv().LightScript
LS.Fly          -- 飞行
LS.Ring         -- 环绕
LS.Noclip       -- 穿墙
LS.Speed        -- 速度
LS.Fling        -- SkidFling
LS.TouchFling   -- 配件甩飞
LS.Spin         -- 旋转甩飞
LS.SelfLock     -- 防甩飞
LS.God          -- 无敌
LS.Projects.loaded["Natural Disaster"].Vote      -- 子项目投票
LS.Projects.loaded["Natural Disaster"].Disaster  -- 子项目灾害
```

---

## 9. 提交历史（近期）

```
1818f70  feat(god): 真无敌 —— hookmetamethod 拦截致命伤害
21e6c9f  fix(fling): 甩飞不再锁住自己 —— 改短促爆发，甩完立刻能走
a360d5e  feat: 无敌（防摔死）—— 解决甩飞时自己被杀
15f2003  feat: 防甩飞（位置锁）+ 甩飞不再甩自己
c97d532  feat(nds): 按 Dex 实测结构重写 —— 投票页直接显示，选项直读
d6e6a54  refactor: LS 拆成主体 + 子项目架构
c22863b  feat: 地图投票助手（NDS）
d02f265  feat: 灾害预警（Natural Disaster Survival）
dde5d34  fix(ring): 对齐原版——不按距离过滤、上限 2000
```

仓库：`https://github.com/bbear8297-creator/Light_Script`（branch `main`）
