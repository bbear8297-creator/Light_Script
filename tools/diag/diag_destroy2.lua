-- LS · 销毁链路诊断 2：带 Blur、带通知、模拟关闭按钮
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_destroy2.txt", table.concat(OUT, "\n")) end
    print("[d2] " .. s)
end
local function T(label, fn)
    local ok, v = pcall(fn)
    log(("%-32s %s"):format(label, ok and ("ok -> " .. tostring(v)) or ("ERR " .. tostring(v))))
end

local Lighting = game:GetService("Lighting")
local function countGui()
    local n = 0
    pcall(function()
        for _, v in ipairs(gethui():GetChildren()) do
            if v:IsA("ScreenGui") and tostring(v.Name):match("^LS_UI_") then n = n + 1 end
        end
    end)
    return n
end
local function countBlur()
    local n = 0
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") and v.Name == "LS_UI_Blur" then n = n + 1 end
    end
    return n
end
local function countIsland()
    local n = 0
    pcall(function()
        for _, v in ipairs(gethui():GetChildren()) do
            if v:IsA("ScreenGui") and tostring(v.Name):match("^LS_UI_") then
                for _, c in ipairs(v:GetChildren()) do
                    if c.Name == "DynamicIsland" then n = n + 1 end
                end
            end
        end
    end)
    return n
end
local function state()
    return ("gui=%s blur=%s island=%s"):format(tostring(countGui()), tostring(countBlur()), tostring(countIsland()))
end

log("=== d2 start ===")
local L
local ok, err = pcall(function() L = loadstring(readfile("LS_UI.lua"), "=LS_UI")() end)
log("load = " .. tostring(ok) .. " " .. tostring(err))
if not ok then return end
log("初始 " .. state())

-- 1) 建窗 + 显示（会开 Blur）+ 弹通知
local win = L:CreateWindow({ Title = "B1", Theme = "Nebula" })
local tab = win:CreateTab("T")
tab:CreateToggle("tg", false, function() end)
tab:CreateSlider("sl", 0, 10, 5, function() end)
win:ShowMain()
win:Success("提示", "销毁测试", 10)
task.wait(0.6)
log("显示后 " .. state())

-- 2) Blur 开启状态下销毁
T("win:Destroy()（Blur 开着）", function() win:Destroy(); return "done" end)
task.wait(0.6)
log("销毁后 " .. state())

-- 3) 通知的 task.delay 到期后是否又复活
task.wait(2)
log("等 2s 后 " .. state())

-- 4) 重新建一个并显示，验证 Blur 能重新开
local w2 = L:CreateWindow({ Title = "B2" })
w2:ShowMain()
task.wait(0.6)
log("重建显示后 " .. state())

-- 5) 模拟点右上角 X（hideMain）再看
T("w2:HideMain()", function() w2:HideMain(); return "done" end)
task.wait(0.6)
log("HideMain 后 " .. state() .. "  IsMainOpen=" .. tostring(w2:IsMainOpen()))

-- 6) 再 X 一次后的 Show
T("w2:ShowMain()", function() w2:ShowMain(); return "done" end)
task.wait(0.4)
log("ShowMain 后 " .. state())

-- 7) 彻底清理
T("DestroyAll()", function() L:DestroyAll(); return "done" end)
task.wait(0.6)
log("DestroyAll 后 " .. state() .. "  windows=" .. tostring(#L:GetWindows()))

-- 8) 全量残留扫描
local leftovers = {}
pcall(function()
    for _, v in ipairs(gethui():GetChildren()) do
        if tostring(v.Name):match("LS_UI") then leftovers[#leftovers + 1] = v.Name end
    end
end)
log("gethui 残留 LS_UI*: " .. (#leftovers > 0 and table.concat(leftovers, ", ") or "无"))
local lb = {}
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") then lb[#lb + 1] = v.Name end
end
log("Lighting 里的 BlurEffect: " .. (#lb > 0 and table.concat(lb, ", ") or "无"))

log("=== d2 end ===")
