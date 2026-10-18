--[[
    ═══════════════════════════════════════════════════════════════
    LightScript 子项目 · Natural Disaster Survival
    ═══════════════════════════════════════════════════════════════
    被主项目调用时：
        local nds = loadstring(readfile("nds.lua"))()
        nds({ Library = Library, Window = win })

    独立运行时（自己建窗，不带灵动岛）：
        loadstring(readfile("nds.lua"))()

    约定：子项目不创建灵动岛，所有控件并入主项目窗口。
    ═══════════════════════════════════════════════════════════════
]]

return function(ctx)
    local ctx = ctx or {}

    ------------------------------------------------------------------
    -- 独立模式：自己加载 UI 库、自建窗口（Island = false）
    ------------------------------------------------------------------
    local Library = ctx.Library
    local win = ctx.Window

    if not Library or not win then
        local ok, src = pcall(readfile, "LS_UI.lua")
        if not ok or type(src) ~= "string" then
            warn("[NDS] 找不到 LS_UI.lua")
            return
        end
        local chunk = loadstring(src, "=LS_UI")
        if not chunk then warn("[NDS] LS_UI 编译失败"); return end
        Library = chunk()
        win = Library:CreateWindow({ Title = "LightScript · NDS", Theme = "Nebula", Island = false })
        win:ShowMain()
    end

    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

    ------------------------------------------------------------------
    -- 灾害预警
    ------------------------------------------------------------------
    local Disaster = { on = false, conns = {}, last = nil, lastAt = 0, pollConn = nil }

    Disaster.Names = {
        "Tornado", "Earthquake", "Flood", "Volcano", "Meteor Shower",
        "Blizzard", "Sandstorm", "Thunderstorm", "Tsunami", "Fire",
        "Acid Rain", "Flash Flood", "Rising Lava", "Deadly Virus",
        "Space Rock", "Sand Storm", "Lightning", "Lava",
    }

    local function matchDisaster(name)
        if type(name) ~= "string" or name == "" then return nil end
        local lower = name:lower()
        for _, d in ipairs(Disaster.Names) do
            if lower:find(d:lower(), 1, true) then return d end
        end
        return nil
    end

    function Disaster:report(name)
        if self.last == name and (tick() - self.lastAt) < 8 then return end
        self.last = name
        self.lastAt = tick()
        win:Notify("灾害预警", name, 6, { Type = "warning" })
        pcall(function() win:SetIslandStatus("灾害：" .. name) end)
        print("[NDS] 灾害预警:", name)
    end

    function Disaster:start()
        if self.on then return end
        self.on = true

        table.insert(self.conns, workspace.DescendantAdded:Connect(function(d)
            if not self.on then return end
            local hit = matchDisaster(d.Name)
            if hit then self:report(hit) end
        end))

        self.pollConn = task.spawn(function()
            while self.on do
                pcall(function()
                    for _, root in ipairs({ workspace, game:GetService("ReplicatedStorage") }) do
                        for _, v in ipairs(root:GetDescendants()) do
                            if v:IsA("StringValue") or v:IsA("ObjectValue") then
                                local hit = matchDisaster(tostring(v.Value))
                                if hit then self:report(hit) end
                            end
                        end
                    end
                end)
                task.wait(1.5)
            end
        end)
    end

    function Disaster:stop()
        self.on = false
        for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
        self.conns = {}
        if self.pollConn then pcall(function() task.cancel(self.pollConn) end); self.pollConn = nil end
    end

    ------------------------------------------------------------------
    -- 地图投票
    ------------------------------------------------------------------
    local Vote = { on = false, target = "", conn = nil }

    function Vote:collect()
        local out = {}
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return out end
        for _, d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                out[#out + 1] = d
            end
        end
        return out
    end

    function Vote:labelOf(btn)
        local txt = btn.Text
        if (not txt or txt == "") and btn:FindFirstChildOfClass("TextLabel") then
            txt = btn:FindFirstChildOfClass("TextLabel").Text
        end
        return tostring(txt or btn.Name)
    end

    -- 直接唤起投票界面：先找 HUD 按钮，再找 RemoteEvent
    function Vote:open()
        for _, d in ipairs(self:collect()) do
            local label = (self:labelOf(d) .. " " .. d.Name):lower()
            if label:find("vote") or label:find("map")
                or label:find("投票") or label:find("选图") then
                if pcall(function() firesignal(d.MouseButton1Click) end) then
                    win:Notify("投票", "已唤起：" .. d.Name, 2, { Type = "success" })
                    return true
                end
            end
        end

        local rs = game:GetService("ReplicatedStorage")
        for _, d in ipairs(rs:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                local n = d.Name:lower()
                if n:find("vote") or n:find("map") then
                    if pcall(function() d:FireServer() end) then
                        win:Notify("投票", "已触发 Remote：" .. d.Name, 2, { Type = "success" })
                        return true
                    end
                end
            end
        end

        win:Warning("投票", "没找到投票入口", 3)
        return false
    end

    function Vote:cast(target)
        target = tostring(target or "")
        if target == "" then return false end
        for _, btn in ipairs(self:collect()) do
            local label = self:labelOf(btn)
            if label:lower():find(target:lower(), 1, true) then
                if pcall(function() firesignal(btn.MouseButton1Click) end) then
                    win:Notify("投票", "已投：" .. label, 2, { Type = "success" })
                    return true
                end
            end
        end
        return false
    end

    function Vote:list()
        local names = {}
        for _, btn in ipairs(self:collect()) do
            local l = self:labelOf(btn)
            if #l > 0 and #l < 30 then names[#names + 1] = l end
        end
        return names
    end

    function Vote:start()
        if self.on then return end
        self.on = true
        self.conn = task.spawn(function()
            while self.on do
                if self.target ~= "" then pcall(function() self:cast(self.target) end) end
                task.wait(2)
            end
        end)
    end

    function Vote:stop()
        self.on = false
        if self.conn then pcall(function() task.cancel(self.conn) end); self.conn = nil end
    end

    ------------------------------------------------------------------
    -- UI
    ------------------------------------------------------------------
    local tab = win:CreateTab("自然灾害", "bolt")

    tab:CreateSection("灾害预警")

    tab:CreateToggle("启用灾害预警", false, function(on)
        if on then
            Disaster:start()
            win:Notify("灾害预警", "已开始监听", 3, { Type = "success" })
        else
            Disaster:stop()
        end
    end)

    tab:CreateParagraph(
        "监听 workspace 生成 + 预选值轮询，抢在警报前报出灾害名。\n" ..
        "服务器随机挑选，客户端只能提前感知。", 2)

    tab:CreateDivider()
    tab:CreateSection("地图投票")

    tab:CreateTextbox("目标地图", "如 Rooftop", "", function(text)
        Vote.target = text
    end)

    tab:CreateButton("唤起投票界面", function()
        Vote:open()
    end)

    tab:CreateButton("唤起并投票", function()
        if Vote:open() then
            task.wait(0.6)
            Vote:cast(Vote.target)
        end
    end)

    tab:CreateButton("列出可投项", function()
        local names = Vote:list()
        if #names == 0 then
            win:Warning("投票", "PlayerGui 里没有可见按钮", 3)
            return
        end
        local shown = {}
        for i = 1, math.min(6, #names) do shown[i] = names[i] end
        win:Notify("可投项", table.concat(shown, " / "), 5, { Type = "info" })
        print("[NDS] 可投按钮:", table.concat(names, " | "))
    end)

    tab:CreateToggle("每轮自动投票", false, function(on)
        if on then
            if Vote.target == "" then
                win:Warning("投票", "先填目标地图名", 3)
                return
            end
            Vote:start()
            win:Notify("投票", "已开启，每 2 秒尝试一次", 3, { Type = "success" })
        else
            Vote:stop()
        end
    end)

    return {
        name = "Natural Disaster",
        Disaster = Disaster,
        Vote = Vote,
        stop = function()
            pcall(function() Disaster:stop() end)
            pcall(function() Vote:stop() end)
        end,
    }
end
