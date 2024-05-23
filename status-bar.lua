local battery_status = require "battery-status"
local config_parser = require "parse-config"
local system_updates = require "system-updates"
local github = require "github"
local util = require "util"
local weather = require "weather"
local wezterm = require "wezterm"

local wsstats_json_file = "/tmp/wsstats.json"

local arrow_down = wezterm.nerdfonts.cod_arrow_small_down
local arrow_up = wezterm.nerdfonts.cod_arrow_small_up

status_bar = {}

function url_encode(input)
    input = string.gsub(input, "([^%w _%-.%~])", function(c) return string.format("%%%02x", string.byte(c)) end)
    return input
end

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

    -- system updates
    if config["status_bar"]["system_updates"]["enabled"] then
        data_file = util.path_join({wezterm.config_dir, "data", "system-updates.json"})
        hours, minutes, seconds = util.get_hms()
        if ((minutes % config["status_bar"]["system_updates"]["interval"]) == 0 and seconds < 4) or util.file_exists(data_file) == false then
            system_updates.find_updates(data_file)
        else
            update_data = util.json_parse(data_file)
            if update_data ~= nil then
                update_status = wezterm.nerdfonts.md_floppy .. " updates: " .. update_data["count"]
                table.insert(cells, util.pad_string(2, 2, update_status))
            end
        end
    end

    -- weather
    if config["status_bar"]["weather"]["enabled"] then
        data_file = util.path_join({wezterm.config_dir, "data", "weather.json"})
        hours, minutes, seconds = util.get_hms()
        if ((minutes % config["status_bar"]["weather"]["interval"]) == 0 and seconds < 4) or util.file_exists(data_file) == false then
            if config["status_bar"]["weather"]["api_key"] == nil then
                weather_data = "missing weather api key"
                table.insert(cells, util.pad_string(1, 1, weather_data))
            elseif config["status_bar"]["weather"]["location"] == nil then
                weather_data = "missing weather location"
                table.insert(cells, util.pad_string(1, 1, weather_data))
            else
                appid = config["status_bar"]["weather"]["api_key"]
                location = string.gsub(config["status_bar"]["weather"]["location"], " ", "%%20")
                err = weather.write_weather_file(data_file, location, appid)
            end
        else
            if util.file_exists(data_file) then
                unit = "F"
                if config["status_bar"]["weather"]["unit"] ~= "F" then
                    unit = "C"
                end
                degree_symbol = "°"
                weather_data = util.json_parse(data_file)
                if weather_data ~= nil then
                    icon_id = weather_data["weather"][1]["icon"]
                    condition_id = weather_data["weather"][1]["id"]
                    current = weather_data["main"]["temp"]
                    high = weather_data["main"]["temp_max"]
                    low = weather_data["main"]["temp_min"]
                    if unit == "C" then
                        current = util.farenheit_to_celsius(current)
                        high = util.farenheit_to_celsius(high)
                        low = util.farenheit_to_celsius(low)
                    end
                    icon = weather.get_icon(icon_id, condition_id)

                    weather_status = {
                        current .. degree_symbol .. unit .. " " .. icon
                    }
                    if config["status_bar"]["weather"]["show_low"] then
                        table.insert(weather_status, arrow_down .. " " .. low .. degree_symbol .. unit)
                    end
                    if config["status_bar"]["weather"]["show_high"] then
                        table.insert(weather_status, arrow_up .. " " .. high .. degree_symbol .. unit)
                    end
                    table.insert(cells, util.pad_string(1, 1, table.concat(weather_status, " ")))
                end
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
        data_file = util.path_join({wezterm.config_dir, "data", "stock-quotes.json"})
        hours, minutes, seconds = util.get_hms()
        if ((minutes % config["status_bar"]["stock_quotes"]["interval"]) == 0 and seconds < 4) or util.file_exists(data_file) == false then
            local symbols = table.concat(config["status_bar"]["stock_quotes"]["symbols"], ",")
            local url = "https://query1.finance.yahoo.com/v7/finance/spark?symbols=" .. symbols
            success, stdout, stderr = wezterm.run_child_process({"curl", url})
            if success then
                file = io.open(data_file, "w")
                file:write(stdout)
                file:close()
            end
        else
            if util.file_exists(data_file) then
                market_data = util.json_parse(data_file)
                if market_data["spark"] ~= nil and market_data["spark"]["result"] ~= nil and #market_data["spark"]["result"] > 0 then
                    for _, block in ipairs(market_data["spark"]["result"]) do
                        symbol = block["symbol"]
                        meta = block["response"][1]["meta"]
                        if meta["previousClose"] ~= nil and meta["regularMarketPrice"] ~= nil then
                            local price = meta["regularMarketPrice"]
                            local last = meta["previousClose"]
                            if price > last then
                                updown = arrow_up
                                pct_change = string.format("%.2f", ((price - last) / last) * 100)
                            else
                                updown = arrow_down
                                pct_change = string.format("%.2f", ((last - price) / last) * 100)
                            end
                            stock_quote = wezterm.nerdfonts.cod_graph_line .. " " .. symbol .. " $" .. price .. " " .. updown .. pct_change .. "%"
                            table.insert(cells, util.pad_string(2, 2, stock_quote))
                        end
                    end
                end
            end
        end
    end

    -- system status
    if config["status_bar"]["system_status"]["enabled"] then
        data_file = "/tmp/wsstats.json"
        local values = util.json_parse(data_file)
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
