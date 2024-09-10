local battery_status = require "battery-status"
local config_parser = require "parse-config"
local stock_quotes = require "stock-quotes"
local system_updates = require "system-updates"
local github = require "github"
local util = require "util.util"
local weather = require "weather"
local wezterm = require "wezterm"

local arrow_down = wezterm.nerdfonts.cod_arrow_small_down
local arrow_up = wezterm.nerdfonts.cod_arrow_small_up
local config = config_parser.get_config()

local stock_quotes_config = config["status_bar"]["stock_quotes"]
local system_status_config = config["status_bar"]["system_status"]
local system_updates_config = config["status_bar"]["system_updates"]
local weather_config = config["status_bar"]["weather"]

status_bar = {}

function status_bar.update_status_bar(cwd)
    -- update the data files as needed
    stock_quotes.update_json(stock_quotes_config)
    system_updates.update_json(system_updates_config)

    local cells = {}
    -- cwd and github branch information
    if config["status_bar"]["toggles"]["show_cwd"] then
        if cwd then
            local bits = {
                wezterm.nerdfonts.cod_folder,
                cwd
            }
            -- display branch info and commits ahead/behind if cwd is a repository
            if config["status_bar"]["toggles"]["show_branch_info"] then
                local branch_name, commits_behind, commits_ahead, current_tag = github.branch_info(cwd)
                if branch_name then
                    table.insert(bits, wezterm.nerdfonts.dev_git_branch)
                    table.insert(bits, branch_name)

                    if commits_behind and commits_ahead then
                        if (commits_behind > 0) and (commits_ahead <= 0) then
                            table.insert(bits, "< " .. tostring(commits_behind))
                        elseif (commits_behind <= 0) and (commits_ahead > 0) then
                            table.insert(bits, "> " .. tostring(commits_ahead))
                        elseif (commits_behind > 0) and (commits_ahead > 0) then
                            table.insert(bits, "< " .. tostring(commits_behind))
                            table.insert(bits, ", ")
                            table.insert(bits, "> " .. tostring(commits_ahead))
                        end
                    end

                    if current_tag then
                        table.insert(bits, wezterm.nerdfonts.cod_tag .. " " .. current_tag)
                    end
                end
            end
            table.insert(cells, util.pad_string(2, 2, table.concat(bits, " ")))
        end
    end

    -- clock
    if config["status_bar"]["toggles"]["show_clock"] then
        local date = wezterm.strftime "%a %b %-d %H:%M"
        table.insert(cells, util.pad_string(2, 2, date))
    end

    -- battery
    if config["status_bar"]["toggles"]["show_battery"] then
        if #wezterm.battery_info() > 0 then
            for _, b in ipairs(wezterm.battery_info()) do
                icon, battery_percent = battery_status.get_battery_status(b)
                bat = icon .. " " .. battery_percent
                table.insert(cells, util.pad_string(1, 1, bat))
            end
        end
    end

    -- weather
    if weather_config["enabled"] then
        local unit = ""

        if weather_config["use_celsius"] then
            unit = "&m"
        end

        if weather_config["location"] ~= nil then
            url = string.format("wttr.in/%s?format=%%c%%t%s", weather_config["location"]:gsub(" ", "+"), unit)
            success, stdout, stderr = wezterm.run_child_process({"curl", url})
            if success then
                table.insert(cells, util.pad_string(1, 1, stdout))
            end
        end
    end

    -- stock quotes
    if stock_quotes_config["enabled"] then
        local indexes = {"^DJI", "^IXIC", "^GSPC"}
        local index_data = {}
        market_data = util.json_parse(stock_quotes_config["data_file"])
        if market_data ~= nil then
            for symbol, data in pairs(market_data["symbols"]) do
                if not util.has_value(indexes, symbol) then
                    if util.has_value(stock_quotes_config["symbols"], symbol) then
                        if data["price"] ~= nil and data["last"] ~= nil then
                            local price = data["price"]
                            local last = data["last"]
                            if price > last then
                                updown_arrow = arrow_up
                                updown_amount = string.format("%.2f", price - last)
                                pct_change = string.format("%.2f", ((price - last) / last) * 100)
                            else
                                updown_arrow = arrow_down
                                updown_amount = string.format("%.2f", last - price)
                                pct_change = string.format("%.2f", ((last - price) / last) * 100)
                            end
                            stock_quote = wezterm.nerdfonts.cod_graph_line .. " " .. symbol .. " $" .. price .. " " .. updown_arrow .. "$" .. updown_amount .. " (" .. pct_change .. "%)"
                            table.insert(cells, util.pad_string(2, 2, stock_quote))
                        end
                    end
                end
            end

            for symbol, data in pairs(market_data["symbols"]) do
                if util.has_value(indexes, symbol) then
                    if data["price"] ~= nil and data["last"] ~= nil then
                        local price = data["price"]
                        local last = data["last"]
                        if price > last then
                            updown_arrow = arrow_up
                            updown_amount = string.format("%.2f", price - last)
                            pct_change = string.format("%.2f", ((price - last) / last) * 100)
                        else
                            updown_arrow = arrow_down
                            updown_amount = string.format("%.2f", last - price)
                            pct_change = string.format("%.2f", ((last - price) / last) * 100)
                        end
                        if symbol == "^DJI" then
                            if stock_quotes_config["indexes"]["show_djia"] then
                                table.insert(index_data, "DOW " .. updown_arrow .. " " .. pct_change .. "%")
                            end
                        elseif symbol == "^IXIC" then
                            if stock_quotes_config["indexes"]["show_nasdaq"] then
                                table.insert(index_data, "Nasdaq " .. updown_arrow .. " " .. pct_change .. "%")
                            end
                        elseif symbol == "^GSPC" then
                            if stock_quotes_config["indexes"]["show_sp500"] then
                                table.insert(index_data, "S&P 500 " .. updown_arrow .. " " .. pct_change .. "%")
                            end
                        end
                    end
                end
            end
            if #index_data > 0 then
                table.insert(cells, wezterm.nerdfonts.cod_graph_line .. " " .. table.concat(index_data, "; "))
            end
        end
    end

    -- system updates
    if system_updates_config["enabled"] then
        update_data = util.json_parse(system_updates_config["data_file"])
        if update_data ~= nil then
            update_status = wezterm.nerdfonts.md_floppy .. " updates: " .. update_data["count"]
            table.insert(cells, util.pad_string(2, 2, update_status))
        end
    end

    -- system status
    if system_status_config["enabled"] then
        if config["os_name"] == "darwin" then
            if system_status_config["toggles"]["show_uptime"] then
                success, stdout, stderr = wezterm.run_child_process({"sysctl", "-n", "kern.boottime"})
                if success then
                    timestamp = stdout:match("{ sec = %d+, usec = %d+ } (%a+%s+%a+%s+%d+%s+%d+:%d+:%d+%s+%d+)")
                    success, stdout, stderr = wezterm.run_child_process({"/bin/date", "-j", "-f", "%a %b %d %H:%M:%S %Y", timestamp, "+%s"})
                    if success then
                        delta = util.get_timestamp() - stdout
                        years, days, hours, minutes, seconds = util.duration(delta)
                        local uptime = {"up"}
                        if years > 0 then
                            table.insert(uptime, string.format("%d %s", years, util.get_plural(years, "year")))
                        end
                        if days > 0 then
                            table.insert(uptime, string.format("%d %s", days, util.get_plural(days, "day")))
                        end
                        table.insert(uptime, string.format("%d:%02d", hours, minutes))
                        table.insert(cells, util.pad_string(2, 2, table.concat(uptime, " ")))
                    end
                end
            end

            if system_status_config["toggles"]["show_cpu_usage"] then
                success, stdout, stderr = wezterm.run_child_process({"top", "-l", 1})
                if success then
                    user, sys, idle = stdout:match("CPU usage: (%d+.%d+)%%%s+user,%s+(%d+.%d+)%%%s+sys,%s+(%d+.%d+)%%%s+idle")
                    cpu_usage = string.format("%s user %s%%, sys %s%%, idle %s%%", wezterm.nerdfonts.oct_cpu, user, sys, idle)
                    table.insert(cells, util.pad_string(2, 2, cpu_usage))
                end
            end

            if system_status_config["toggles"]["show_memory_usage"] then
                local pagesize = nil
                local total = nil
                success, stdout, stderr = wezterm.run_child_process({"sysctl", "-n", "hw.pagesize"})
                if success then
                    pagesize = stdout
                end

                success, stdout, stderr = wezterm.run_child_process({"sysctl", "-n", "hw.memsize"})
                if success then
                    total = stdout
                end

                if pagesize ~= nil and total ~= nil then
                    -- https://github.com/giampaolo/psutil/blob/master/psutil/_psosx.py#L113-L126
                    success, stdout, stderr = wezterm.run_child_process({"vm_stat"})
                    if success then
                        bytes_total       = total
                        bytes_free        = stdout:match("Pages free:%s+(%d+)") * pagesize
                        bytes_active      = stdout:match("Pages active:%s+(%d+)") * pagesize
                        bytes_inactive    = stdout:match("Pages inactive:%s+(%d+)") * pagesize
                        bytes_wired       = stdout:match("Pages wired down:%s+(%d+)") * pagesize
                        bytes_speculative = stdout:match("Pages speculative:%s+(%d+)") * pagesize
                        bytes_used        = bytes_active + bytes_wired
                        bytes_available   = bytes_inactive + bytes_free

                        memory_unit = config["status_bar"]["system_status"]["memory_unit"]
                        memory_usage = string.format("%s %s / %s", wezterm.nerdfonts.md_memory, util.byte_converter(bytes_used, memory_unit), util.byte_converter(bytes_total, memory_unit))
                        table.insert(cells, util.pad_string(2, 2, memory_usage))
                    end
                end
            end

            if system_status_config["toggles"]["show_disk_usage"] then
                disk_list = system_status_config["disk_list"]
                if disk_list ~= nil then
                    if #disk_list > 0 then
                        for _, disk_item in ipairs(disk_list) do
                            success, stdout, stderr = wezterm.run_child_process({"/bin/df", "-k", disk_item["mount_point"]})
                            if success then
                                df_data = util.split_words(util.split_lines(stdout)[2])
                                disk_total = df_data[2] * 1024
                                disk_available = df_data[4] * 1024
                                disk_used = disk_total - disk_available
                                mount_point = df_data[9]
                                disk_usage = string.format("%s %s %s / %s", wezterm.nerdfonts.md_harddisk, mount_point, util.byte_converter(disk_used, disk_item["unit"]), util.byte_converter(disk_total, disk_item["unit"]))
                                table.insert(cells, util.pad_string(2, 2, disk_usage))
                            end
                        end
                    end
                end
            end

            if system_status_config["toggles"]["show_network_throughput"] then
                network_interface_list = system_status_config["network_interface_list"]
                if network_interface_list ~= nil then
                    if #network_interface_list > 0 then
                        for _, interface in ipairs(network_interface_list) do
                            local r1, s1 = util.network_data_darwin(interface)
                            _, _, _ = wezterm.run_child_process({"sleep", "1"})
                            local r2, s2 = util.network_data_darwin(interface)
                            network_throughput = string.format("%s %s RX / %s TX", interface, util.process_bytes(r2 - r1), util.process_bytes(s2 - s1))
                            table.insert(cells, util.pad_string(2, 2, network_throughput))
                        end
                    end
                end
            end
        elseif config["os_name"] == "linux" then
            if system_status_config["toggles"]["show_uptime"] then
                success, stdout, stderr = wezterm.run_child_process({"cut", "-f1", "-d.", "/proc/uptime"})
                if success then
                    years, days, hours, minutes, seconds = util.duration(stdout)
                    local uptime = {"up"}
                    if years > 0 then
                        table.insert(uptime, string.format("%d %s", years, util.get_plural(years, "year")))
                    end
                    if days > 0 then
                        table.insert(uptime, string.format("%d %s", days, util.get_plural(days, "day")))
                    end
                    table.insert(uptime, string.format("%d:%02d", hours, minutes))
                    table.insert(cells, util.pad_string(2, 2, table.concat(uptime, " ")))
                    
                end
            end

            if system_status_config["toggles"]["show_cpu_usage"] then
                success, stdout, stderr = wezterm.run_child_process({"mpstat"})
                if success then
                    user, nice, sys, iowait, irq, soft, steal, guest, gnice, idle = stdout:match("all%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)")
                    cpu_usage = string.format("%s user %s%%, sys %s%%, idle %s%%", wezterm.nerdfonts.oct_cpu, user, sys, idle)
                    table.insert(cells, util.pad_string(2, 2, cpu_usage))
                end
            end

            if system_status_config["toggles"]["show_memory_usage"] then
                success, stdout, stderr = wezterm.run_child_process({"free", "-b", "-w"})
                if success then
                    bytes_total, bytes_used, bytes_free, bytes_shared, bytes_buffers, bytes_cache, bytes_available = stdout:match("Mem:%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
                    memory_unit = config["status_bar"]["system_status"]["memory_unit"]
                    memory_usage = string.format("%s %s / %s", wezterm.nerdfonts.md_memory, util.byte_converter(bytes_used, memory_unit), util.byte_converter(bytes_total, memory_unit))
                    table.insert(cells, util.pad_string(2, 2, memory_usage))
                end
            end

            if system_status_config["toggles"]["show_disk_usage"] then
                disk_list = system_status_config["disk_list"]
                if disk_list ~= nil then
                    if #disk_list > 0 then
                        for _, disk_item in ipairs(disk_list) do
                            success, stdout, stderr = wezterm.run_child_process({"/bin/df", "-k", disk_item["mount_point"]})
                            if success then
                                df_data = util.split_words(util.split_lines(stdout)[2])
                                disk_total = df_data[2] * 1024
                                disk_available = df_data[4] * 1024
                                disk_used = df_data[3] * 1024
                                mount_point = df_data[6]
                                disk_usage = string.format("%s %s %s / %s", wezterm.nerdfonts.md_harddisk, mount_point, util.byte_converter(disk_used, disk_item["unit"]), util.byte_converter(disk_total, disk_item["unit"]))
                                table.insert(cells, util.pad_string(2, 2, disk_usage))
                            end
                        end
                    end
                end
            end

            if system_status_config["toggles"]["show_network_throughput"] then
                network_interface_list = system_status_config["network_interface_list"]
                if network_interface_list ~= nil then
                    if #network_interface_list > 0 then
                        for _, interface in ipairs(network_interface_list) do
                            local r1, s1 = util.network_data_linux(interface)
                            if r1 ~= nil and s1 ~= nil then
                                _, _, _ = wezterm.run_child_process({"sleep", "1"})
                                local r2, s2 = util.network_data_linux(interface)
                                if r2 ~= nil and s2 ~= nil then
                                    network_throughput = string.format("%s %s RX / %s TX", interface, util.process_bytes(r2 - r1), util.process_bytes(s2 - s1))
                                    table.insert(cells, util.pad_string(2, 2, network_throughput))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return cells
end

return status_bar
