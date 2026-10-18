-- LS · 方法挂载逐行诊断（autoexecute）
-- 每一步都落盘，哪怕中途死掉也能看到死在哪

local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_diag.txt", table.concat(OUT, "\n")) end
    print("[diag] " .. s)
end

local function T(label, fn)
    local ok, v = pcall(fn)
    log(("%-34s %s"):format(label, ok and ("ok -> " .. tostring(v)) or ("ERR " .. tostring(v))))
    return ok, v
end

log("=== start ===")
log("executor = " .. tostring(identifyexecutor and identifyexecutor() or "?"))
log("identity = " .. tostring(getthreadidentity and getthreadidentity() or "?"))

local Library
local ok, err = pcall(function()
    Library = loadstring(readfile("LS_UI.lua"), "=LS_UI")()
end)
log("load library  = " .. tostring(ok) .. "  " .. tostring(err))
if not ok then return end

local win = Library:CreateWindow({ Title = "DIAG", Theme = "Nebula" })
log("window        = " .. tostring(win ~= nil))

local tab = win:CreateTab("T")
log("tab           = " .. tostring(tab ~= nil))

local lbl = tab:CreateLabel("hello")
local sl = tab:CreateSlider("s", 0, 100, 50, function() end)
log("label/slider  = " .. tostring(lbl ~= nil) .. " / " .. tostring(sl ~= nil))

-- ===== 核心测试 =====
local mt = getrawmetatable(game)
log("mt type       = " .. type(mt))
T("isreadonly(mt)", function() return tostring(isreadonly and isreadonly(mt)) end)
log("mt.__index    = " .. type(rawget(mt, "__index")))

T("rawget(registry?)", function() return "skip" end)

T("label[SetText] lookup", function() return type(lbl["SetText"]) end)
T("label:SetText()", function() lbl:SetText("A"); return "done" end)
T("label.SetText(self,'B')", function() lbl.SetText(lbl, "B"); return "done" end)
T("Library.Call(label)", function() Library.Call(lbl, "SetText", "C"); return "done" end)

T("slider[Set] lookup", function() return type(sl["Set"]) end)
T("slider:Set(7)", function() sl:Set(7); return "done" end)
T("slider.Set(sl,8)", function() sl.Set(sl, 8); return "done" end)
T("slider[Get] lookup", function() return type(sl["Get"]) end)

-- ===== 手动复现 attachMethod 的主路径 =====
T("manual hook install", function()
    local orig = rawget(mt, "__index")
    setreadonly(mt, false)
    mt.__index = function(self, k)
        if k == "ZzTest" then return function(a, b) return "hit:" .. tostring(a == self) end end
        return orig(self, k)
    end
    setreadonly(mt, true)
    return "installed"
end)
T("frame.ZzTest()", function() return Instance.new("Frame").ZzTest() end)
T("frame:ZzTest()", function() return Instance.new("Frame"):ZzTest() end)

-- ===== 检查 metatable 是否被别的脚本顶掉 =====
T("mt.__index still ours?", function()
    local idx = rawget(mt, "__index")
    return type(idx)
end)

log("=== end ===")
