-- 通知回收专项诊断
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_notif.txt", table.concat(OUT, "\n")) end
end

local function clockCheck()
    local a = os.clock()
    task.wait(1)
    local b = os.clock()
    return string.format("os.clock dt over 1s = %.3f", b - a)
end

log("=== notif diag ===")
log(clockCheck())

local L
local ok, err = pcall(function() L = loadstring(readfile("LS_UI.lua"), "=LS_UI")() end)
log("load = " .. tostring(ok) .. " " .. tostring(err))
if not ok then return end

local win = L:CreateWindow({ Title = "N", Theme = "Nebula" })
win:ShowMain()
log("window ok")

local function countNotifs()
    local n = 0
    pcall(function()
        for _, v in ipairs(gethui():GetChildren()) do
            if v:IsA("ScreenGui") and tostring(v.Name):match("^LS_UI_") then
                for _, d in ipairs(v:GetDescendants()) do
                    if d.Name == "LS_Notif" then n = n + 1 end
                end
            end
        end
    end)
    return n
end

log("before toast: " .. countNotifs())
win:Toast("测试通知", 1)
log("after toast:  " .. countNotifs())

-- ★ 复现用户那一条：三参数 Toast（标题, 内容, 时长）
win:Toast("瞄准部位", "切换为 头部", 2)
log("after 3-arg toast: " .. countNotifs())

task.wait(1.0); log("t=1.0s  notifs=" .. countNotifs())
task.wait(1.0); log("t=2.0s  notifs=" .. countNotifs())
task.wait(2.0); log("t=4.0s  notifs=" .. countNotifs())

-- 再发三条，看批量回收
win:Success("A", "x", 1)
win:Warning("B", "y", 1)
win:Error("C", "z", 1)
log("batch after send: " .. countNotifs())
task.wait(3.0)
log("batch t=3s: " .. countNotifs())

log("=== end ===")
