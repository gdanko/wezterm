local config_parser = require "parse-config"
local util = require "util"
local wezterm = require "wezterm"

local config = config_parser.get_config()

local wifi_status = {}

function wifi_status.update_wifi_status()
    local output = {
        timestamp = nil,
        interfaces = {}
    }
    data_file = config["status_bar"]["system_status"]["wifi_status"]["data_file"]
    if config["os_name"] == "linux" then
        network_interface_list = config["status_bar"]["system_status"]["network_interface_list"]
        if network_interface_list ~= nil then
            for _, ifname in ipairs(network_interface_list) do
                success, stdout, stderr = wezterm.run_child_process({"iwconfig", ifname})
                if success then
                    signal_level = stdout:match("Signal level=--(%d+) dBm")
                    if signal_level ~= nil then
                        output["interfaces"][ifname] = signal_level
                    end
                end
            end
        end
    elseif config["os_name"] == "darwin" then
        success, stdout, stderr = wezterm.run_child_process({"/usr/sbin/system_profiler", "SPAirPortDataType", "-json", "-detailLevel", "basic"})
        if success then
            data = util.json_parse_string(stdout)
            if data ~= nil then
                interfaces  = data["SPAirPortDataType"][1]["spairport_airport_interfaces"]
                for _, interface in ipairs(interfaces) do
                    ifname = interface["_name"]
                    if util.has_value(config["status_bar"]["system_status"]["network_interface_list"], ifname) then
                        spairport_signal_noise = interface["spairport_current_network_information"]["spairport_signal_noise"]
                        signal_level = spairport_signal_noise:match("-(%d+) dBm")
                        if signal_level ~= nil then
                            output["interfaces"][ifname] = signal_level
                        end
                    end
                end
            end
        end
    end
    output["timestamp"] = util.get_timestamp()
    file = io.open(data_file, "w")
    file:write(wezterm.json_encode(output))
    file:close()
end

return wifi_status
