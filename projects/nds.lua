--[[
    ═══════════════════════════════════════════════════════════════
    LightScript 子项目 · 灾害 & 地图投票
    ═══════════════════════════════════════════════════════════════
    由主项目调用：
        local nds = loadstring(readfile("nds.lua"))()
        nds({ Library = Library, Window = win })

    约定：子项目不建灵动岛，所有控件并入主项目窗口。

    真实结构（Dex 实测）：
        PlayerGui.MainGui.MapVotePage                 投票页 Frame
          .Vote.Choice1/2/3                           三个选项
            .MapNameLabel                             TextLabel，地图名
          .Selected.Map                               ImageButton
        PlayerGui.UIs.mapVote                         HUD 图标
        PlayerGui.UIs.<warningFrame>.warningText      灾害名文字
    ═══════════════════════════════════════════════════════════════
]]

return function(ctx)
    local ctx = ctx or {}

    local Library = ctx.Library
    local win = ctx.Window

    -- 独立运行：自建无灵动岛窗口
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
        if win.ShowMain then win:ShowMain() end
    end

    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

    local function getGui(name)
        local pg = LP:FindFirstChild("PlayerGui")
        return pg and pg:FindFirstChild(name) or nil
    end

    ------------------------------------------------------------------
    -- 灾害预警：直接读 GUI 上的 warningText（比扫 workspace 准）
    ------------------------------------------------------------------
    local Disaster = { on = false, conns = {}, last = nil, lastAt = 0 }

    function Disaster:findWarning()
        local gui = getGui("UIs")
        if not gui then return nil end
        for _, frame in ipairs(gui:GetChildren()) do
            if frame:IsA("Frame") or frame:IsA("ImageLabel") then
                local txt = frame:FindFirstChild("warningText", true)
                if txt and txt:IsA("TextLabel") then
                    local s = tostring(txt.Text or "")
                    if s ~= "" then return s end
                end
            end
        end
        return nil
    end

    function Disaster:report(name)
        if self.last == name and (tick() - self.lastAt) < 8 then return end
        self.last = name
        self.lastAt = tick()
        win:Notify("灾害预警", name, 6, { Type = "warning" })
        pcall(function() win:SetIslandStatus("灾害：" .. name) end)
        print("[NDS] 灾害:", name)
    end

    function Disaster:start()
        if self.on then return end
        self.on = true

        -- ① GUI 文字轮询（最早、最准）
        table.insert(self.conns, task.spawn(function()
            while self.on do
                local w = self:findWarning()
                if w then self:report(w) end
                task.wait(0.4)
            end
        end))

        -- ② workspace 兜底：灾害模型生成
        local names = {
            "Tornado", "Earthquake", "Flood", "Volcano", "Meteor Shower", "Blizzard",
            "Sandstorm", "Thunderstorm", "Tsunami", "Fire", "Acid Rain", "Flash Flood",
            "Rising Lava", "Deadly Virus", "Space Rock", "Sand Storm", "Lightning",
        }
        table.insert(self.conns, workspace.DescendantAdded:Connect(function(d)
            if not self.on then return end
            local dn = tostring(d.Name):lower()
            for _, n in ipairs(names) do
                if dn:find(n:lower(), 1, true) then self:report(n); break end
            end
        end))
    end

    function Disaster:stop()
        self.on = false
        for _, c in ipairs(self.conns) do
            pcall(function() if c.Disconnect then c:Disconnect() else task.cancel(c) end end)
        end
        self.conns = {}
    end

    ------------------------------------------------------------------
    -- 地图投票：直接把 MapVotePage 显示出来
    ------------------------------------------------------------------
    local Vote = { on = false, target = "", conn = nil }

    function Vote:page()
        local main = getGui("MainGui")
        local page = main and main:FindFirstChild("MapVotePage")
        return page, main
    end

    function Vote:open()
        local page, main = self:page()
        if not page then
            win:Warning("投票", "找不到 MapVotePage", 3)
            return false
        end
        pcall(function()
            if main then main.Visible = true end
            page.Visible = true
        end)
        win:Notify("投票", "已显示投票页", 2, { Type = "success" })
        return true
    end

    -- 读取三个选项：{ name = 地图名, button = 可点击实例 }
    function Vote:choices()
        local page = self:page()
        local out = {}
        if not page then return out end
        local voteBox = page:FindFirstChild("Vote")
        if not voteBox then return out end

        for _, choice in ipairs(voteBox:GetChildren()) do
            local label = choice:FindFirstChild("MapNameLabel", true)
            local name = label and tostring(label.Text) or ""
            local clickable = choice

            -- 选项本身可能只是容器，往上找 ImageButton / TextButton
            if not (clickable:IsA("ImageButton") or clickable:IsA("TextButton")) then
                for _, sub in ipairs(choice:GetDescendants()) do
                    if sub:IsA("ImageButton") or sub:IsA("TextButton") then
                        clickable = sub
                        break
                    end
                end
            end

            if name ~= "" then
                out[#out + 1] = { name = name, button = clickable }
            end
        end
        return out
    end

    function Vote:cast(target)
        target = tostring(target or "")
        if target == "" then return false end
        for _, c in ipairs(self:choices()) do
            if c.name:lower():find(target:lower(), 1, true) then
                local done = false
                if c.button then
                    done = pcall(function() firesignal(c.button.MouseButton1Click) end)
                    if not done then
                        done = pcall(function() c.button:Activate() end)
                    end
                end
                win:Notify("投票", "已投票：" .. c.name, 2, { Type = "success" })
                return true
            end
        end
        return false
    end

    function Vote:list()
        local names = {}
        for _, c in ipairs(self:choices()) do names[#names + 1] = c.name end
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
            local w = Disaster:findWarning()
            win:Notify("灾害预警", w and ("当前：" .. w) or "已开始监听", 3, { Type = "success" })
        else
            Disaster:stop()
        end
    end)
    tab:CreateParagraph("直接读 GUI 上的 warningText，比扫场景更早更准。", 2)

    tab:CreateDivider()
    tab:CreateSection("地图投票")

    tab:CreateButton("显示投票页", function()
        Vote:open()
    end)

    tab:CreateButton("列出选项", function()
        local names = Vote:list()
        if #names == 0 then
            win:Warning("投票", "投票页里没读到选项（可能需要先「显示投票页」）", 3)
            return
        end
        win:Notify("候选地图", table.concat(names, " / "), 5, { Type = "info" })
        print("[NDS] 候选:", table.concat(names, " | "))
    end)

    tab:CreateTextbox("目标地图", "输入地图名", "", function(text)
        Vote.target = text
    end)

    tab:CreateButton("投票", function()
        if not Vote:cast(Vote.target) then
            win:Warning("投票", "没匹配到，先「列出选项」看名字", 3)
        end
    end)

    tab:CreateToggle("自动投票", false, function(on)
        if on then
            if Vote.target == "" then win:Warning("投票", "先填目标地图名", 3); return end
            Vote:start()
            win:Notify("投票", "每 2 秒尝试一次", 3, { Type = "success" })
        else
            Vote:stop()
        end
    end)

    return {
        name = "Disaster & Vote",
        Disaster = Disaster,
        Vote = Vote,
        stop = function()
            pcall(function() Disaster:stop() end)
            pcall(function() Vote:stop() end)
        end,
    }
end
