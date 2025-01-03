--
-- 菜单栏网速监控
--
require("module.base")
c = require("hs.canvas")

function data_diff()
    local in_seq = hs.execute(instr)
    local out_seq = hs.execute(outstr)
    local in_diff = in_seq - inseq
    local out_diff = out_seq - outseq
    if in_diff / 1024 > 1024 then
        kbin = string.format("%6.2f", in_diff / 1024 / 1024):gsub(" ", "") .. " MB/s"
    else
        kbin = string.format("%6.2f", in_diff / 1024):gsub(" ", "") .. " kB/s"
    end
    -- kbin = addNo(kbin)
    if out_diff / 1024 > 1024 then
        kbout = string.format("%6.2f", out_diff / 1024 / 1024):gsub(" ", "") .. " MB/s"
    else
        kbout = string.format("%6.2f", out_diff / 1024):gsub(" ", "") .. " kB/s"
    end
    -- kbout = addNo(kbout)
    local disp_str = "⥄" .. kbout .. "\n⥂" .. kbin
    local disp_str_no = kbout .. "\n" .. kbin
    -- 适配黑暗模式选择
    if darkMode then
        disp_str = hs.styledtext.new(disp_str_no, { font = { size = 9.0 }, color = { hex = "#FFFFFF" } })
    else
        disp_str = hs.styledtext.new(disp_str, { font = { size = 9.0 }, color = { hex = "#000000" } })
    end
    -- NetBar:setTitle(disp_str)
    -- NetBar:delete(barIcon)
    barIcon = c.new({ x = 10, y = 10, h = 24, w = 57 })
    barIcon[1] = {
        frame = { x = 0, y = -0.3, h = 24, w = 57 },
        text = hs.styledtext.new(
            kbout .. "\n" .. kbin,
            { font = { size = 9.0 }, color = { hex = "#FFFFFF" }, paragraphStyle = { alignment = "right" } }
        ),
        type = "text",
    }
    local menuIcon = barIcon:imageFromCanvas()
    NetBar:setIcon(menuIcon)
    delete(barIcon)
    inseq = in_seq
    outseq = out_seq
end

-- 添加空格增加长度
function addNo(var)
    stringLen = string.len(var)
    b = var
    if stringLen < 11 then
        a = stringLen
        repeat
            b = " " .. b
            a = a + 0.5
        until a == 11
    end
    return b
end

-- 点击时的行为
function clickCallback()
    local runningApp = app.runningApplications()
    for i, app in pairs(runningApp) do
        if string.find(app:name(), "Surge") then
            as.applescript([[
                tell application "System Events"
                    tell process "Surge"
                        tell menu bar item 1 of menu bar 2
                            perform action "AXShowMenu"
                            keystroke "d" using command down
                        end tell
                    end tell
                end tell
            ]])
            break
        end
    end
end

-- 刷新函数
function rescan()
    interface = hs.network.primaryInterfaces()
    local menuitems_table = {}
    if interface then
        -- 检查激活的网络接口并创建菜单项目
        local interface_detail = hs.network.interfaceDetails(interface)
        -- 当前SSID
        if interface_detail.AirPort then
            local ssid = interface_detail.AirPort.SSID
            table.insert(menuitems_table, {
                title = "SSID: " .. ssid,
                tooltip = "SSIDをクリップボードにコピー",
                fn = function()
                    hs.pasteboard.setContents(ssid)
                end,
            })
        end
        -- 当前IPv4地址
        if interface_detail.IPv4 then
            local ipv4 = interface_detail.IPv4.Addresses[1]
            table.insert(menuitems_table, {
                title = "IPv4アドレス: " .. ipv4,
                tooltip = "IPv4アドレスをクリップボードにコピー",
                fn = function()
                    hs.pasteboard.setContents(ipv4)
                end,
            })
        end
        -- 当前IPv6地址
        if interface_detail.IPv6 then
            local ipv6 = interface_detail.IPv6.Addresses[1]
            table.insert(menuitems_table, {
                title = "IPv6アドレス: " .. ipv6,
                tooltip = "IPv6アドレスをクリップボードにコピー",
                fn = function()
                    hs.pasteboard.setContents(ipv6)
                end,
            })
        end
        -- 当前MAC地址
        local macaddr = hs.execute("ifconfig " .. interface .. " | grep ether | awk '{print $2}'")
        table.insert(menuitems_table, {
            title = "MACアドレス: " .. macaddr,
            tooltip = "MACアドレスをクリップボードにコピー",
            fn = function()
                hs.pasteboard.setContents(macaddr)
            end,
        })
        -- 监视网速Start watching the netspeed delta
        instr = "netstat -ibn | grep -e " .. interface .. " -m 1 | awk '{print $7}'"
        outstr = "netstat -ibn | grep -e " .. interface .. " -m 1 | awk '{print $10}'"
        inseq = hs.execute(instr)
        outseq = hs.execute(outstr)
        if timer then
            timer:stop()
            timer = nil
        end
        timer = hs.timer.doEvery(1, data_diff, true)
    end
    table.insert(menuitems_table, {
        title = "インターフェイスをスキャン",
        fn = function()
            rescan()
        end,
    })
    --NetBar:setTitle("⚠︎")
    --NetBar:setMenu(menuitems_table)
    NetBar:setClickCallback(clickCallback)
end

NetBar = hs.menubar.new(true):autosaveName("Net")
rescan()
