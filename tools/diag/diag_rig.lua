-- 骨架诊断：RigType / 关节清单 / C0 写入是否被覆盖
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_rig.txt", table.concat(OUT, "\n")) end
end

local LP = game:GetService("Players").LocalPlayer
local char = LP.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")

log("=== rig diag ===")
log("char   = " .. tostring(char))
log("rig    = " .. tostring(hum and hum.RigType))
log("animate= " .. tostring(char and char:FindFirstChildOfClass("Animate")))

log("--- Motor6D 清单 ---")
local found = {}
if char then
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Motor6D") then
            found[#found + 1] = d
            log(string.format("  %-18s parent=%-14s C0=%s", d.Name, d.Parent and d.Parent.Name or "?", tostring(d.C0)))
        end
    end
end
log("关节总数 = " .. #found)

-- 写入测试：右肩/右上臂旋转 45°，0.6s 后看是否还在
local target
for _, d in ipairs(found) do
    if d.Name == "RightUpperArm" or d.Name == "Right Shoulder" then target = d break end
end
log("测试关节 = " .. tostring(target))

if target then
    local before = target.C0
    local ok = pcall(function()
        target.C0 = before * CFrame.Angles(math.rad(-45), 0, 0)
    end)
    log("写入 = " .. tostring(ok))

    task.wait(0.6)
    local after = target.C0
    local changed = (after ~= before)
    log("0.6s 后仍保持写入 = " .. tostring(changed))
    log("  before=" .. tostring(before))
    log("  after =" .. tostring(after))

    -- 还原
    pcall(function() target.C0 = before end)
end

log("=== end ===")
