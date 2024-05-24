local wezterm = require "wezterm"
local util = require "util"

system_updates = {}

function system_updates.find_updates(data_file)
    local config = config_parser.get_config()
    if config["os_name"] == "darwin" then
        success, stdout, stderr = wezterm.run_child_process({"softwareupdate", "--list"})
        wezterm.log_info(data_file)
        wezterm.log_info(success)
        wezterm.log_info(stdout)
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
    elseif config["os_name"] == "linux" then
        local distro = ""
        success, stdout, stderr = wezterm.run_child_process({"lsb_release", "-a"})
        if success then
            index_ubuntu = string.find(stdout, "Ubuntu")
            index_fedora = string.find(stdout, "Fedora")
            if index_ubuntu then
                success, stdout, stderr = wezterm.run_child_process({"/usr/lib/update-notifier/apt-check", "--human-readable"})
                if success then
                    lines = wezterm.split_by_newlines(stdout)
                    match = lines[1]:match("^%d+")
                    if match then
                        output = {
                            timestamp = util.get_timestamp(),
                            os = "ubuntu",
                            count = match,
                        }
                        file = io.open(data_file, "w")
                        file:write(wezterm.json_encode(output))
                        file:close()
                    end
                end
            elseif index_fedora then
                success, stdout, stderr = wezterm.run_child_process({"yum", "list", "updates"})
                if success then
                    lines = wezterm.split_by_newlines(stdout)
                    output = {
                        timestamp = util.get_timestamp(),
                        os = "fedora",
                        count = #lines,
                    }
                    file = io.open(data_file, "w")
                    file:write(wezterm.json_encode(output))
                    file:close()
                end
            end
        end
    end
end

return system_updates
