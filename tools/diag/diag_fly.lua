-- 朝向 + 位移实测：dot(角色Look, 相机Look) 应接近 1 表示背部朝镜头
local OUT = {}
local function log(s)
    OUT[#OUT + 1] = s
    if writefile then pcall(writefile, "ls_fly3.txt", table.concat(OUT, "\n")) end
end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local function hrp()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

log("=== fly rot test ===")
local LS = getgenv and getgenv().LightScript
if not LS or not LS.Fly then log("!! 没有 Fly"); return end
local ok, err = pcall(function() return LS.Fly:start() end)
log("start = " .. tostring(ok) .. " " .. tostring(err))
task.wait(0.4)

for i = 1, 16 do
    local r = hrp()
    local cam = workspace.CurrentCamera
    local dot = "?"
    if r and cam then
        dot = string.format("%.2f", r.CFrame.LookVector:Dot(cam.CFrame.LookVector))
    end
    local mv = LS.Fly:moveVector()
    log(string.format("t=%.1f pos=(%.1f,%.1f,%.1f) mv=(%.2f,%.2f) dot=%s",
        i * 0.5,
        r and r.Position.X or 0, r and r.Position.Y or 0, r and r.Position.Z or 0,
        mv.X, mv.Z, dot))
    task.wait(0.5)
end

LS.Fly:stop(true)
log("=== end ===")
