local wezterm = require "wezterm"
local util = require "util.util"

system_updates = {}

function update_json(config)
    needs_update = false
    exists, err = util.file_exists(config["data_file"])
    if exists then
        json_data = util.json_parse(config["data_file"])
        if json_data ~= nil then
            if (util.get_timestamp() - json_data["timestamp"]) > (config["freshness_threshold"] * 3600) then
                needs_update = true
            end
        end
    else
        needs_update = true
    end

    if needs_update then
        system_updates.find_updates(config["data_file"])
    end
end

function find_updates(data_file)
    local config = config_parser.get_config()
    if config["os_name"] == "darwin" then
        success, stdout, stderr = wezterm.run_child_process({"softwareupdate", "--list"})
        if success then
            updates = 0
            lines = wezterm.split_by_newlines(stdout)
            for _, line in ipairs(lines) do
                index, _ = string.find(line, "* Label", 1)
                if index ~= nil then
                    updates = updates + 1
                end
            end

            output = {
                timestamp = util.get_timestamp(),
                os = config["os_name"],
                count = updates,
            }
            file = io.open(data_file, "w")
            file:write(wezterm.json_encode(output))
            file:close()
        end
    elseif config["os_name"] == "linux" and config["os_distro"] ~= nil then
        output = {
            timestamp = util.get_timestamp(),
            os = config["os_distro"],
            count = 0,
        }
        if config["os_distro"] == "alpine" then
            success, stdout, stderr = wezterm.run_child_process({"apk", "-u", "list"})
            if success then
                lines = wezterm.split_by_newlines(stdout)
                output["count"] = #lines
            end
        elseif config["os_distro"] == "arch" then
            os.execute("pacman -Sy")
            success, stdout, stderr = wezterm.run_child_process({"pacman", "-Qu"})
            if success then
                lines = wezterm.split_by_newlines(stdout)
                output["count"] = #lines
            end
        elseif config["os_distro"] == "debian" or config["os_distro"] == "ubuntu" then
            success, stdout, stderr = wezterm.run_child_process({"apt", "list", "--upgradable"})
            if success then
                lines = {}
                for _, line in ipairs(wezterm.split_by_newlines(stdout)) do
                    if line:match("Listing...") == nil then
                        table.insert(lines, line)
                    end
                end
                output["count"] = #lines
            end
        elseif config["os_distro"] == "centos" or config["os_distro"] == "fedora" then
            success, stdout, stderr = wezterm.run_child_process({"yum", "list", "updates"})
            if success then
                lines = wezterm.split_by_newlines(stdout)
                match = lines[1]:match("^%d+")
                if match then
                    output["count"] = match
                end
            end
        end
        file = io.open(data_file, "w")
        file:write(wezterm.json_encode(output))
        file:close()
    end
end

system_updates.find_updates = find_updates
system_updates.update_json = update_json

return system_updates
