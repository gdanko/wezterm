local battery_status = require "battery-status"
local config_parser = require "parse-config"
local stock_quotes = require "stock-quotes"
local system_updates = require "system-updates"
local github = require "github"
local util = require "util.util"
local weather = require "weather"
local wezterm = require "wezterm"


local config = config_parser.get_config()

local stock_quotes_config = config["status_bar"]["stock_quotes"]
local system_status_config = config["status_bar"]["system_status"]
local system_updates_config = config["status_bar"]["system_updates"]
local weather_config = config["status_bar"]["weather"]

local system_status = require "system-status.system-status"

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
        stock_quote_data = stock_quotes.get_stock_quotes(config)
        if stock_quote_data ~= nil then
            for _, stock_quote in ipairs(stock_quote_data) do
                table.insert(cells, stock_quote)
            end
        end

        stock_index_data = stock_quotes.get_stock_indexes(config)
        if stock_index_data ~= nil then
            table.insert(cells, stock_index_data)
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
        if system_status_config["toggles"]["show_uptime"] then
            system_uptime = system_status.get_system_uptime(config)
            if system_uptime ~= nil then
                table.insert(cells, system_uptime)
            end
        end

        if system_status_config["toggles"]["show_cpu_usage"] then
            cpu_usage = system_status.get_cpu_usage(config)
            if cpu_usage ~= nil then
                table.insert(cells, cpu_usage)
            end
        end

        if system_status_config["toggles"]["show_memory_usage"] then
            memory_usage = system_status.get_memory_usage(config)
            if memory_usage ~= nil then
                table.insert(cells, memory_usage)
            end
        end

        if system_status_config["toggles"]["show_disk_usage"] then
            disk_usage = system_status.get_disk_usage(config)
            if disk_usage ~= nil then
                table.insert(cells, disk_usage)
            end
        end

        if system_status_config["toggles"]["show_network_throughput"] then
            network_throughput = system_status.get_network_throughput(config)
            if network_throughput ~= nil then
                table.insert(cells, network_throughput)
            end
        end
    end
    return cells
end

return status_bar
