-- LS · 代理元素验证（跑在 autoexecute 里）
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_diag.txt", table.concat(OUT, "\n")) end
    print("[diag] " .. s)
end
local function T(label, fn)
    local ok, v = pcall(fn)
    log(("%-28s %s"):format(label, ok and ("ok -> " .. tostring(v)) or ("ERR " .. tostring(v))))
end

log("=== proxy test start ===")
log("executor = " .. tostring(identifyexecutor and identifyexecutor() or "?"))

local L
local ok, err = pcall(function() L = loadstring(readfile("LS_UI.lua"), "=LS_UI")() end)
log("load lib = " .. tostring(ok) .. " " .. tostring(err))
if not ok then return end

local win = L:CreateWindow({ Title = "PROXY", Theme = "Nebula" })
local tab = win:CreateTab("A")

local lbl = tab:CreateLabel("hi")
local sl  = tab:CreateSlider("s", 0, 100, 50, function() end)
local tg  = tab:CreateToggle("t", false, function() end)
local dd  = tab:CreateDropdown("d", { "x", "y" }, "x", function() end)
local kb  = tab:CreateKeybind("k", Enum.KeyCode.F, function() end)
local pb  = tab:CreateProgressBar("p", 0)
local cp  = tab:CreateColorPicker("c", Color3.new(1, 0, 0), function() end)
local ip  = tab:CreateInfoPanel({ PlayerName = "n" })

log("typeof(label)  = " .. typeof(lbl))
log("typeof(slider) = " .. typeof(sl))

T("lbl:SetText('A1')", function() lbl:SetText("A1"); return "done" end)
T("lbl.SetText('A2') dot", function() lbl.SetText("A2"); return "done" end)
T("lbl.Text read", function() return tostring(lbl.Text) end)
T("lbl.Parent get/set", function() local p = lbl.Parent; lbl.Parent = p; return "done" end)
T("lbl.Frame:IsA('Frame')", function() return tostring(lbl.Frame:IsA("Frame")) end)

T("sl:Set(7)", function() sl:Set(7); return "done" end)
T("sl:Get()", function() return tostring(sl:Get()) end)
T("tg:Set(true)", function() tg:Set(true); return "done" end)
T("tg:Get()", function() return tostring(tg:Get()) end)
T("dd:Set('y')", function() dd:Set("y"); return "done" end)
T("dd:Get()", function() return tostring(dd:Get()) end)
T("kb:Get()", function() return tostring(kb:Get()) end)
T("pb:Set(0.5)", function() pb:Set(0.5); return "done" end)
T("pb:Get()", function() return tostring(pb:Get()) end)
T("cp:Set(color)", function() cp:Set(Color3.fromRGB(1, 2, 3)); return "done" end)
T("cp:Get()", function() return tostring(cp:Get()) end)
T("ip:SetServerInfo", function() ip:SetServerInfo("Server: TEST"); return "done" end)

log("=== proxy test end ===")
