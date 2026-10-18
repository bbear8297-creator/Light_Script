--[[
    ═══════════════════════════════════════════════════════════════
    Light Script · LS UI 库 · 全元素演示 / 自检脚本
    ═══════════════════════════════════════════════════════════════
    执行器 Console 粘一行即可：

        loadstring(game:HttpGet("https://raw.githubusercontent.com/bbear8297-creator/Light_Script/main/demo_ui.lua"))()

    本地文件：

        loadstring(readfile("demo_ui.lua"))()

    跑完会在 Console 打印 API 自检报告（重点看 SetText / Set / Get）。
    窗口关掉之后，点屏幕顶部中间的「灵动岛」可以重新展开。
    ═══════════════════════════════════════════════════════════════
]]

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")

local RAW_UI = "https://raw.githubusercontent.com/bbear8297-creator/Light_Script/main/ui_APP.Lua"

-- ───────────────────────────────────────────── 加载 UI 库
local function fetch(url)
    local body
    pcall(function()
        if type(request) == "function" then
            body = request({ Url = url, Method = "GET" }).Body
        elseif syn and type(syn.request) == "function" then
            body = syn.request({ Url = url, Method = "GET" }).Body
        elseif http and type(http.request) == "function" then
            body = http.request({ Url = url, Method = "GET" }).Body
        else
            body = game:HttpGet(url)
        end
    end)
    if type(body) == "string" and #body > 1000 then return body end

    local ok2, body2 = pcall(game.HttpGet, game, url)
    if ok2 and type(body2) == "string" and #body2 > 1000 then return body2 end
    return nil
end

local src = fetch(RAW_UI)
if not src then
    warn("[demo] 拉取 ui_APP.Lua 失败。把仓库里的 ui_APP.Lua 放到执行器目录，改用：")
    warn('[demo] loadstring(readfile("ui_APP.Lua"))()')
    return
end

local chunk, cerr = loadstring(src, "=LS_UI")
if not chunk then
    warn("[demo] 编译失败: " .. tostring(cerr))
    return
end

local okLoad, Library = pcall(chunk)
if not okLoad then
    warn("[demo] 库加载失败: " .. tostring(Library))
    return
end
print("[demo] LS UI 库加载成功 →", tostring(Library))

-- ───────────────────────────────────────────── 小工具
local function hasFn(obj, key)
    if obj == nil then return false end
    local ok, v = pcall(function() return obj[key] end)
    return ok and type(v) == "function"
end

local function guard(name, fn)
    local ok, res = pcall(fn)
    if not ok then
        warn(("[demo] 创建 %s 失败: %s"):format(name, tostring(res)))
        return nil
    end
    return res
end

-- 兼容两种返回形态：table{Set=...} 与 Instance（attachMethod 挂的）
local function callMethod(obj, method, arg)
    if obj == nil then return false end
    local fn
    local ok = pcall(function() fn = obj[method] end)
    if ok and type(fn) == "function" then
        if pcall(fn, arg) then return true end          -- obj.Method(arg) / 表形态
        if pcall(fn, obj, arg) then return true end     -- obj:Method(arg)
    end
    if type(Library.Call) == "function" then
        -- 注意：Library:Call 是冒号方法，点调用时第一个参数就是 inst
        return (pcall(function() Library.Call(obj, method, arg) end))
    end
    return false
end

local function executorName()
    local ok, v = pcall(function()
        return identifyexecutor and identifyexecutor() or "unknown"
    end)
    return (ok and v) or "unknown"
end

-- ───────────────────────────────────────────── 建窗口
local win = guard("Window", function()
    return Library:CreateWindow({ Title = "Light Script · Demo", Theme = "Nebula" })
end)
if not win then
    warn("[demo] 窗口创建失败，后续跳过")
    return
end
win:ShowMain()

local tabHome    = win:CreateTab("概览",  "dashboard")
local tabCombat  = win:CreateTab("战斗",  "combat")
local tabVisual  = win:CreateTab("视觉",  "visual")
local tabSetting = win:CreateTab("设置",  "settings")
local tabAbout   = win:CreateTab("关于",  "info")

-- ───────────────────────────────────────────── Tab 1 · 概览
tabHome:CreateSection("玩家信息")

local info = guard("InfoPanel", function()
    return tabHome:CreateInfoPanel({
        PlayerName   = Players.LocalPlayer and Players.LocalPlayer.Name or "?",
        ServerInfo   = "Server: " .. tostring(game.JobId):sub(1, 8),
        ExecutorInfo = "Executor: " .. executorName(),
    })
end)

local lblClock = guard("Label", function()
    return tabHome:CreateLabel("启动时间：--:--:--")
end)

tabHome:CreateSection("心跳")

local barLoad = guard("ProgressBar", function()
    return tabHome:CreateProgressBar("循环进度", 0)
end)

tabHome:CreateDivider()

guard("Button", function()
    return tabHome:CreateButton("刷新玩家信息", function()
        callMethod(info, "SetServerInfo", "Server: " .. tostring(game.JobId):sub(1, 8))
        callMethod(info, "SetPlayerName", Players.LocalPlayer and Players.LocalPlayer.Name or "?")
        callMethod(info, "SetExecutorInfo", "Executor: " .. executorName())
        win:Success("已刷新", "玩家信息与服务器 ID 已同步")
    end)
end)

tabHome:CreateParagraph(
    "这一页演示 Label:SetText、InfoPanel:SetServerInfo、ProgressBar:Set。\n" ..
    "下面的时间和进度条会动，就说明 attachMethod 修复生效了。", 2)

-- ───────────────────────────────────────────── Tab 2 · 战斗
tabCombat:CreateSection("基础开关")

local toggleAim = guard("Toggle", function()
    return tabCombat:CreateToggle("瞄准辅助", false, function(on)
        win:SetIslandStatus(on and "战斗 · 瞄准开启" or "待机")
        win:Notify("瞄准辅助", on and "已开启" or "已关闭", 2)
    end)
end)

local toggleEsp = guard("Toggle", function()
    return tabCombat:CreateToggle("ESP 透视", true, function(on)
        win:Notify("ESP", on and "已挂载绘制循环" or "已卸载绘制循环", 3,
            { Type = on and "success" or "warning" })
    end)
end)

tabCombat:CreateSection("数值")

local sliderFov = guard("Slider", function()
    return tabCombat:CreateSlider("视野角度 FOV", 10, 360, 90, function(v) end)
end)

local sliderSmooth = guard("Slider", function()
    return tabCombat:CreateSlider("平滑系数", 0, 100, 35, function(v) end)
end)

tabCombat:CreateSection("下拉与按键")

local dropMode = guard("Dropdown", function()
    return tabCombat:CreateDropdown("瞄准部位", { "头部", "躯干", "最近部位", "随机" }, "头部",
        function(opt) win:Notify("瞄准部位", "切换为 " .. tostring(opt), 2) end)
end)

local bindToggle = guard("Keybind", function()
    return tabCombat:CreateKeybind("开关面板", Enum.KeyCode.RightShift, function()
        win:ToggleMain()
    end)
end)

-- ───────────────────────────────────────────── Tab 3 · 视觉
tabVisual:CreateSection("主题色")

guard("ColorPicker", function()
    return tabVisual:CreateColorPicker("强调色", Color3.fromRGB(160, 108, 255), function(c)
        win:SetAccentColor(c)      -- 实时重绘所有注册过主题的控件
    end)
end)

tabVisual:CreateSection("绘制")

guard("Toggle", function()
    return tabVisual:CreateToggle("显示边框", true, function(on) end, { RegisterFeature = false })
end)

local lblPreview = guard("Label", function()
    return tabVisual:CreateLabel("预览：绘制颜色会跟随强调色")
end)

guard("Image", function()
    return tabVisual:CreateImage("rbxassetid://10709752508", 96, 96)
end)

guard("Textbox", function()
    return tabVisual:CreateTextbox("自定义标签", "输入点什么…", "Light Script", function(text)
        callMethod(lblPreview, "SetText", "预览：" .. tostring(text))
        win:Notify("文本框", text, 2)
    end)
end)

-- ───────────────────────────────────────────── Tab 4 · 设置
tabSetting:CreateSection("外观")

guard("Dropdown", function()
    return tabSetting:CreateDropdown("主题预设",
        { "DeepSpace", "Nebula", "Aurora", "Ember" }, "Nebula", function(name)
            win:ApplyTheme(name)
            win:Notify("主题", "已切换 " .. tostring(name), 2)
        end)
end)

tabSetting:CreateSection("生命周期")

guard("Button", function()
    return tabSetting:CreateButton("弹出四种通知", function()
        win:Notify("提示", "这是一条普通 Toast")
        task.delay(0.4, function() win:Success("成功", "操作已完成") end)
        task.delay(0.8, function() win:Warning("警告", "检测到异常数值") end)
        task.delay(1.2, function() win:Error("错误", "模拟一次失败回调") end)
    end)
end)

guard("Button", function()
    return tabSetting:CreateButton("切换 X 按钮行为（隐藏 ↔ 销毁）", function()
        local nextMode = (win:GetCloseAction() == "destroy") and "hide" or "destroy"
        win:SetCloseAction(nextMode)
        win:Notify("X 按钮", nextMode == "destroy" and "现在点 X 会直接销毁窗口"
            or "现在点 X 只隐藏，点灵动岛可展开", 3)
    end)
end)

guard("Button", function()
    return tabSetting:CreateButton("销毁全部窗口（测 DestroyAll）", function()
        win:Notify("即将销毁", "3 秒后执行 Library:DestroyAll()", 2)
        task.delay(3, function()
            Library:DestroyAll()
            print("[demo] DestroyAll 已执行，剩余窗口:", #Library:GetWindows())
        end)
    end)
end)

-- ───────────────────────────────────────────── 实时刷新
local running = true
win:AddCleanup(function() running = false end)

local frames = 0
win:TrackConnection(RunService.RenderStepped:Connect(function()
    frames = frames + 1
end))

local startedAt = os.clock()
task.spawn(function()
    local p = 0
    local lastT, lastF = os.clock(), 0
    while running do
        p = p + 0.015
        if p > 1 then p = 0 end
        callMethod(barLoad, "Set", p)

        local now = os.clock()
        if now - lastT >= 0.5 then
            local fps = math.floor((frames - lastF) / (now - lastT))
            callMethod(lblClock, "SetText",
                ("运行 %.1fs ｜ %d fps ｜ %d 个功能开启")
                    :format(now - startedAt, fps, win:GetActiveFeatureCount()))
            lastT, lastF = now, frames
        end
        task.wait(0.05)
    end
end)

-- ───────────────────────────────────────────── 灵动岛 & 通知
win:SetIslandStatus("演示运行中")
win:SetIslandDot(Library.Themes.Nebula.Success)

task.delay(0.6, function() win:Success("Demo", "UI 已加载，点灵动岛可收起") end)
task.delay(1.8, function() win:Notify("提示", "拖动顶栏可以移动窗口", 3) end)

-- ───────────────────────────────────────────── 自检报告
local checks = {
    { "Label:SetText",             hasFn(lblClock, "SetText") },
    { "Label:SetValue",            hasFn(lblClock, "SetValue") },
    { "InfoPanel:SetServerInfo",   hasFn(info, "SetServerInfo") },
    { "InfoPanel:SetExecutorInfo", hasFn(info, "SetExecutorInfo") },
    { "InfoPanel:SetPlayerName",   hasFn(info, "SetPlayerName") },
    { "Slider:Set / Get",          hasFn(sliderFov, "Set") and hasFn(sliderFov, "Get") },
    { "Dropdown:Set / Get",        hasFn(dropMode, "Set") and hasFn(dropMode, "Get") },
    { "Keybind:Set / Get",         hasFn(bindToggle, "Set") and hasFn(bindToggle, "Get") },
    { "Toggle:Set / Get",          hasFn(toggleAim and toggleAim.Frame, "Set") },
    { "ProgressBar:Set / Get",     hasFn(barLoad and barLoad.Frame, "Get") },
    { "Library:Call 兜底",         type(Library.Call) == "function" },
    { "Library:GetWindows",        type(Library.GetWindows) == "function" },
}

local pass, total = 0, #checks
local lines = {}
for _, c in ipairs(checks) do
    if c[2] then pass = pass + 1 end
    table.insert(lines, (c[2] and "✔  " or "✘  ") .. c[1])
end

print("══════════ LS UI 自检 ══════════")
for _, l in ipairs(lines) do print("  " .. l) end
print(("  通过 %d / %d"):format(pass, total))
print("════════════════════════════════")

tabAbout:CreateSection("自检结果")
tabAbout:CreateParagraph(
    ("通过 %d / %d 项\n\n"):format(pass, total) .. table.concat(lines, "\n"),
    total + 2)

tabAbout:CreateDivider()
tabAbout:CreateSection("用法")

tabAbout:CreateParagraph(
    'local tab = win:CreateTab("名字")\n' ..
    'local s = tab:CreateSlider("速度", 16, 200, 50, cb)\n' ..
    "s:Set(120); print(s:Get())", 3)

guard("Button", function()
    return tabAbout:CreateButton("复制自检结果到剪贴板", function()
        if setclipboard then
            setclipboard(table.concat(lines, "\n"))
            win:Success("已复制", "自检结果已写入剪贴板")
        else
            win:Warning("不可用", "当前执行器没有 setclipboard")
        end
    end)
end)

-- ───────────────────────────────────────────── 触发一次初始回调
-- 一律走 callMethod，避免 :Method 的 self 差异
callMethod(sliderFov, "Set", 90)
callMethod(sliderSmooth, "Set", 35)
callMethod(bindToggle, "Set", Enum.KeyCode.RightShift)
callMethod(dropMode, "Set", "头部")
callMethod(toggleEsp and toggleEsp.Frame, "Set", true)

print(("[demo] 完成：%d 个 Tab，窗口标题 Light Script · Demo"):format(5))
