local battery_status = require "battery-status"
local config_parser = require "parse-config"
local github = require "github"
local util = require "util"
local wezterm = require "wezterm"

local wsstats_json_file = "/tmp/wsstats.json"

status_bar = {}

function status_bar.update_status_bar(cwd)
    local config = config_parser.get_config()
    local cells = {}

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

    -- stock quotes
    if config["status_bar"]["stock_quotes"]["enabled"] then
        local symbols = table.concat(config["status_bar"]["stock_quotes"]["symbols"], ",")
        local url = "https://query1.finance.yahoo.com/v7/finance/spark?symbols=" .. symbols
        success, stdout, stderr = wezterm.run_child_process({"curl", url})
        if success then
            local json_data = util.json_parse_string(stdout)
            if json_data["spark"] ~= nil and json_data["spark"]["result"] ~= nil and #json_data["spark"]["result"] > 0 then
                for _, block in ipairs(json_data["spark"]["result"]) do
                    symbol = block["symbol"]
                    meta = block["response"][1]["meta"]
                    if meta["previousClose"] ~= nil and meta["regularMarketPrice"] ~= nil then
                        local price = meta["regularMarketPrice"]
                        local last = meta["previousClose"]
                        if price > last then
                            updown = " 󰜷" -- \udb81\udf37
                            pct_change = string.format("%.2f", ((price - last) / last) * 100)
                        else
                            updown = " 󰜮" -- \udb81\udf2e
                            pct_change = string.format("%.2f", ((last - price) / last) * 100)
                        end
                        stockQuote = wezterm.nerdfonts.cod_graph_line .. " " .. symbol .. " $" .. price .. " " .. updown .. pct_change .. "%"
                        table.insert(cells, util.pad_string(2, 2, stockQuote))
                    end
                end
            end
        end
    end

    -- system status
    if config["status_bar"]["system_status"]["enabled"] then
        local values = util.json_parse(wsstats_json_file)
        if values ~= nil then
            -- check for freshness
            if (util.get_timestamp() - values["timestamp"]) > 5 then
                table.insert(cells, util.pad_string(2, 2, wezterm.nerdfonts.cod_bug .. " wsstats data is stale, please verify it's still running"))
            else
                if config["status_bar"]["system_status"]["toggles"]["show_uptime"] then
                    if values["host"] ~= nil and values["host"]["information"] ~= nil then
                        uptime = {"up"}
                        seconds = values["host"]["information"]["uptime"]
                        if seconds == 0 then
                            seconds = 1
                        end
                        days, hours, minutes, secs = util.duration(seconds)
                        if days > 1 then
                            d = "days"
                        else
                            d = "day"
                        end

                        if days > 0 then
                            table.insert(uptime, days .. " " .. d)
                        end
                        table.insert(uptime, string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) .. ":" .. string.format("%02d", secs))
                        table.insert(cells, util.pad_string(2, 2, table.concat(uptime, " ")))
                    end
                end

                if config["status_bar"]["system_status"]["toggles"]["show_cpu_usage"] then
                    if values["cpu"] ~= nil then
                        cpu_usage = wezterm.nerdfonts.oct_cpu .. " " .. "user " .. values["cpu"][1]["user"] .. "%, sys " .. values["cpu"][1]["system"] .. "%, idle " .. values["cpu"][1]["idle"] .. "%"
                    else
                        cpu_usage = wezterm.nerdfonts.cod_bug .. " Failed to get CPU usage"
                    end
                    table.insert(cells, util.pad_string(2, 2, cpu_usage))
                end

                if config["status_bar"]["system_status"]["toggles"]["show_load_averages"] then
                    if values["load"] ~= nil then
                        load1 = string.format("%.2f", values["load"]["load1"])
                        load5 = string.format("%.2f", values["load"]["load5"])
                        load15 = string.format("%.2f", values["load"]["load15"])
                        load_averages = "Load: " .. load1 .. ", " .. load5 .. ", " .. load15
                    else
                        load_averages = wezterm.nerdfonts.cod_bug .. " Failed to get load averages"
                    end
                    table.insert(cells, util.pad_string(2, 2, load_averages))
                end

                if config["status_bar"]["system_status"]["toggles"]["show_memory_usage"] then
                    if values["memory"] ~= nil then
                        memory_usage = wezterm.nerdfonts.md_memory .. " " .. util.byte_converter(values["memory"]["used"], "Gi") .. " / " .. util.byte_converter(values["memory"]["total"], "Gi")
                    else
                        memory_usage = wezterm.nerdfonts.cod_bug .. " Failed to get memory usage"
                    end
                    table.insert(cells, util.pad_string(2, 2, memory_usage))
                end

                if config["status_bar"]["system_status"]["toggles"]["show_disk_usage"] then
                    disk_list = config["status_bar"]["system_status"]["disk_list"]
                    if disk_list ~= nil then
                        if #disk_list > 0 then
                            if values["disk"] ~= nil then
                                for _, block in ipairs(values["disk"]) do
                                    for _, disk_item in ipairs(disk_list) do
                                        if block["mount_point"] == disk_item["mount_point"] then
                                            disk_usage = wezterm.nerdfonts.md_harddisk .. " " .. block["mount_point"] .. " " .. util.byte_converter(block["used"], disk_item["unit"]) .. " / " .. util.byte_converter(block["total"], disk_item["unit"])
                                            table.insert(cells, util.pad_string(2, 2, disk_usage))
                                        end
                                    end
                                end
                            end
                        else
                            disk_usage = wezterm.nerdfonts.cod_bug .. " No disks found"
                        end
                    else
                        disk_usage = wezterm.nerdfonts.cod_bug .. " Failed to get disk list"
                    end
                end

                if config["status_bar"]["system_status"]["toggles"]["show_network_throughput"] then
                    network_interface_list = config["status_bar"]["system_status"]["network_interface_list"]
                    if network_interface_list ~= nil then
                        if #network_interface_list > 0 then
                            if values["network"] ~= nil then
                                for _, block in ipairs(values["network"]) do
                                    if util.has_value(network_interface_list, block["interface"]) then
                                        recv = util.process_bytes(block["bytes_recv"])
                                        sent = util.process_bytes(block["bytes_sent"])
                                        network_throughput = wezterm.nerdfonts.md_ip_network .. " " .. block["interface"] .. " " .. recv .. " RX" .. " / " .. sent .. " TX"
                                        table.insert(cells, util.pad_string(2, 2, network_throughput))
                                    end
                                end
                            else
                                network_throughput = wezterm.nerdfonts.cod_bug .. " No interfaces found"
                            end
                        else
                            network_throughput = wezterm.nerdfonts.cod_bug .. " No interfaces found"
                        end
                    else
                        network_throughput = wezterm.nerdfonts.cod_bug .. " Failed to get interface list"
                    end
                end
            end
        else
            table.insert(cells, util.pad_string(2, 2, wezterm.nerdfonts.cod_bug .. " wsstats not running, please see https://github.com/gdanko/wsstats."))
        end
    end

    -- do stuff like clock here
        
    return cells
end

return status_bar
