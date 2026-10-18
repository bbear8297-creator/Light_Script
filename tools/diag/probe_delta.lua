--[[  LS · Delta 探针（autoexecute 版）
      放到 /sdcard/Delta/Autoexecute/ 下，重启 Delta 客户端就会自动执行
      结果写到 /sdcard/Delta/Workspace/ls_probe.txt
]]

local OUT = {}

local function flush(tag)
    if not writefile then return end
    pcall(writefile, "ls_probe.txt",
        (tag and ("[" .. tag .. "]\n") or "") .. table.concat(OUT, "\n"))
end

-- 第一件事：先落一个 start，证明脚本确实跑起来了
if writefile then pcall(writefile, "ls_probe.txt", "start\n") end

local ok, err = pcall(function()
    local function probe(name)
        local o, v = pcall(function() return _G[name] end)
        if o and v ~= nil then return type(v) end
        local o2, v2 = pcall(function() return getgenv()[name] end)
        if o2 and v2 ~= nil then return type(v2) .. " (genv)" end
        return "nil"
    end

    local function safe(fn)
        local o, v = pcall(fn)
        if o then return tostring(v) end
        return "ERR: " .. tostring(v)
    end

    OUT[#OUT + 1] = "========== LS · Delta 探针 =========="
    OUT[#OUT + 1] = "executor   = " .. safe(function() return identifyexecutor() end)
    OUT[#OUT + 1] = "identity   = " .. safe(function() return getthreadidentity() end)
    OUT[#OUT + 1] = "gethui()   = " .. safe(function() return typeof(gethui()) end)
    OUT[#OUT + 1] = "place      = " .. tostring(game.PlaceId) .. " / " .. tostring(game.GameId)
    OUT[#OUT + 1] = ""

    local LIST = {
        "getgenv","getrenv","getreg","getgc","getinstances","getnilinstances",
        "getscripts","getloadedmodules","getsenv","gettenv","getcallingscript",
        "hookfunction","hookmetamethod","newcclosure","checkcaller","clonefunction",
        "getrawmetatable","setreadonly","isreadonly","islclosure","iscclosure","isexecutorclosure",
        "getconnections","firesignal","fireclickdetector","firetouchinterest","fireproximityprompt",
        "writefile","readfile","appendfile","isfile","isfolder","makefolder","delfile","listfiles",
        "request","http_request","syn","http","getcustomasset","setclipboard","getclipboard",
        "identifyexecutor","getthreadidentity","setthreadidentity","queue_on_teleport",
        "setfpscap","protectgui","gethui","sethiddenproperty","gethiddenproperty","setscriptable",
        "saveinstance","decompile","getscripthash","loadstring","require",
        "Drawing","isnetworkowner","getnamecallmethod","setnamecallmethod",
        "getupvalue","setupvalue","getupvalues","setupvalues","getconstants","getstack","getinfo",
    }

    local have, miss = {}, {}
    for _, n in ipairs(LIST) do
        local t = probe(n)
        if t == "nil" then miss[#miss + 1] = n else have[#have + 1] = string.format("%-26s %s", n, t) end
    end
    OUT[#OUT + 1] = ("---- 有 (%d) ----"):format(#have)
    for _, l in ipairs(have) do OUT[#OUT + 1] = l end
    OUT[#OUT + 1] = ""
    OUT[#OUT + 1] = ("---- 没有 (%d) ----"):format(#miss)
    OUT[#OUT + 1] = table.concat(miss, "  ")
    OUT[#OUT + 1] = ""

    OUT[#OUT + 1] = "---- 关键实测 ----"
    OUT[#OUT + 1] = "getrawmetatable(game) = " .. safe(function() return typeof(getrawmetatable(game)) end)
    OUT[#OUT + 1] = "setreadonly           = " .. safe(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false); setreadonly(mt, true)
        return "ok"
    end)
    OUT[#OUT + 1] = "newcclosure           = " .. safe(function()
        local f = newcclosure(function() return 1 end)
        return typeof(f) .. " -> " .. tostring(f())
    end)
    OUT[#OUT + 1] = "rawset(Instance)      = " .. safe(function()
        local f = Instance.new("Frame")
        rawset(f, "Test", function() return true end)
        return "ok"
    end)
    OUT[#OUT + 1] = "writefile             = " .. safe(function()
        writefile("ls_write_test.txt", "ok")
        return isfile and (isfile("ls_write_test.txt") and "ok" or "isfile=false") or "no isfile"
    end)
    OUT[#OUT + 1] = "gethui 可写           = " .. safe(function()
        local g = Instance.new("ScreenGui")
        g.Parent = gethui()
        local r = g.Parent ~= nil
        g:Destroy()
        return r and "ok" or "fail"
    end)
    OUT[#OUT + 1] = "CoreGui 可写          = " .. safe(function()
        local g = Instance.new("ScreenGui")
        g.Parent = game:GetService("CoreGui")
        local r = g.Parent ~= nil
        g:Destroy()
        return r and "ok" or "fail"
    end)
end)

if ok then
    flush("done")
    print(table.concat(OUT, "\n"))
else
    OUT[#OUT + 1] = "!! 运行中断: " .. tostring(err)
    flush("error")
    warn("[LS probe] " .. tostring(err))
end
