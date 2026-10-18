-- LS · 销毁链路诊断（autoexecute）
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_destroy.txt", table.concat(OUT, "\n")) end
    print("[destroy] " .. s)
end
local function T(label, fn)
    local ok, v = pcall(fn)
    log(("%-30s %s"):format(label, ok and ("ok -> " .. tostring(v)) or ("ERR " .. tostring(v))))
end

local function countGui()
    local n = 0
    local ok = pcall(function()
        for _, v in ipairs(gethui():GetChildren()) do
            if v:IsA("ScreenGui") and tostring(v.Name):match("^LS_UI_") then n = n + 1 end
        end
    end)
    return ok and n or "?"
end
local function countBlur()
    local n = 0
    for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
        if v:IsA("BlurEffect") and v.Name == "LS_UI_Blur" then n = n + 1 end
    end
    return n
end
local function countOverlay()
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

log("=== destroy diag start ===")
local L
local ok, err = pcall(function() L = loadstring(readfile("LS_UI.lua"), "=LS_UI")() end)
log("load lib = " .. tostring(ok) .. " " .. tostring(err))
if not ok then return end

log(("初始: gui=%s blur=%s island=%s"):format(tostring(countGui()), tostring(countBlur()), tostring(countOverlay())))

local win = L:CreateWindow({ Title = "D1", Theme = "Nebula" })
local tab = win:CreateTab("T")
local lbl = tab:CreateLabel("x")
log(("建窗后: gui=%s blur=%s island=%s"):format(tostring(countGui()), tostring(countBlur()), tostring(countOverlay())))

T("win:HideMain()", function() win:HideMain(); return "done" end)
T("win:ShowMain()", function() win:ShowMain(); return "done" end)
T("lbl:SetText 前", function() lbl:SetText("y"); return "done" end)

T("win:Destroy()", function() win:Destroy(); return "done" end)
log(("销毁后: gui=%s blur=%s island=%s"):format(tostring(countGui()), tostring(countBlur()), tostring(countOverlay())))
log(("IsDestroyed() = %s"):format(tostring(win:IsDestroyed())))
log(("GetWindows 数量 = %d"):format(#L:GetWindows()))

T("重复 Destroy()", function() win:Destroy(); return "done" end)
T("销毁后 lbl:SetText", function() lbl:SetText("z"); return "done" end)

-- 重建
local ok2, win2 = pcall(function() return L:CreateWindow({ Title = "D2" }) end)
log("重建 = " .. tostring(ok2) .. " " .. tostring(win2))
if ok2 and win2 then
    local t2 = win2:CreateTab("T2")
    local s2 = t2:CreateSlider("s", 0, 10, 5, function() end)
    T("新窗 slider:Set", function() s2:Set(3); return tostring(s2:Get()) end)
end
log(("两窗并存: gui=%s blur=%s"):format(tostring(countGui()), tostring(countBlur())))

T("Library:DestroyAll()", function() L:DestroyAll(); return "done" end)
log(("DestroyAll 后: gui=%s blur=%s island=%s"):format(tostring(countGui()), tostring(countBlur()), tostring(countOverlay())))
log(("GetWindows 数量 = %d"):format(#L:GetWindows()))

log("=== destroy diag end ===")
