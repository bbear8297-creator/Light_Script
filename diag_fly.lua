-- 飞行实测：开启飞行后记录 MoveDirection 与角色坐标
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_fly.txt", table.concat(OUT, "\n")) end
end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local function hrp()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

log("=== fly test ===")
local LS = getgenv and getgenv().LightScript
log("LightScript = " .. tostring(LS))
if not LS or not LS.Fly then
    log("!! 没有暴露 Fly")
    return
end

local ok, err = pcall(function() return LS.Fly:start() end)
log("start fly = " .. tostring(ok) .. " " .. tostring(err))
log("enabled = " .. tostring(LS.Fly.enabled))

task.wait(0.8)
local p0 = hrp() and hrp().Position
log("基线位置 = " .. tostring(p0))

for i = 1, 14 do
    local r, h = hrp(), hum()
    local md = h and h.MoveDirection or Vector3.zero
    log(string.format("t=%.1fs  pos=(%.1f, %.1f, %.1f)  md=(%.2f, %.2f, %.2f)  bv=%s",
        i * 0.5,
        r and r.Position.X or 0, r and r.Position.Y or 0, r and r.Position.Z or 0,
        md.X, md.Y, md.Z,
        tostring(LS.Fly.bv and LS.Fly.bv.Velocity)))
    task.wait(0.5)
end

log("=== end ===")
