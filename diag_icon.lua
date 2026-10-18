-- 图标渲染诊断：把 Tab 按钮内部的真实层级 dump 出来
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_icon.txt", table.concat(OUT, "\n")) end
end

local function P(inst, prop)
    local ok, v = pcall(function() return inst[prop] end)
    return ok and tostring(v) or "-"
end

log("=== icon diag ===")
local L
local ok, err = pcall(function() L = loadstring(readfile("LS_UI.lua"), "=LS_UI")() end)
log("load = " .. tostring(ok) .. " " .. tostring(err))
if not ok then return end

log("IconNames = " .. tostring(L.IconNames and table.concat(L.IconNames, ",") or "nil"))

local win = L:CreateWindow({ Title = "ICON", Theme = "Nebula" })
local tab = win:CreateTab("战斗", "combat")
log("tab 创建完成 = " .. tostring(tab ~= nil))

-- 找 ScreenGui → 找名叫 战斗 的 TextButton
local gui
for _, v in ipairs(gethui():GetChildren()) do
    if v:IsA("ScreenGui") and tostring(v.Name):match("^LS_UI_") then gui = v end
end
log("gui = " .. tostring(gui))

local btn
if gui then
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextButton") and d.Name == "战斗" then btn = d end
    end
end
log("tab button = " .. tostring(btn))

if btn then
    log(("button size=%s pos=%s"):format(P(btn, "Size"), P(btn, "Position")))
    local kids = btn:GetDescendants()
    log("子物体数 = " .. #kids)
    for _, d in ipairs(kids) do
        log(("  %-14s %-14s size=%-22s pos=%-26s bgc=%-18s bgT=%s vis=%s"):format(
            tostring(d.Name), d.ClassName, P(d, "Size"), P(d, "Position"),
            P(d, "BackgroundColor3"), P(d, "BackgroundTransparency"), P(d, "Visible")))
    end
end

log("=== end ===")
