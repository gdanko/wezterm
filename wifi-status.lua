local config_parser = require "parse-config"
local util = require "util.util"
local wezterm = require "wezterm"

local wifi_status = {}

function update_json(config)
    local output = {
        timestamp = nil,
        interfaces = {}
    }
    needs_update = false
    number, multiplier = util.get_number_and_multiplier(config["status_bar"]["wifi_status"]["interval"])
    exists, err = util.file_exists(config["status_bar"]["wifi_status"]["data_file"])
    if exists then
        json_data = util.json_parse(config["status_bar"]["wifi_status"]["data_file"])
        if json_data ~= nil then
            if (util.get_timestamp() - json_data["timestamp"]) > (number * multiplier) then
                needs_update = true
            end
        end
    else
        needs_update = true
    end

    if needs_update then
        if config["os_name"] == "darwin" then
            network_interface_list = config["status_bar"]["system_status"]["network_interface_list"]
            success, stdout, stderr = wezterm.run_child_process({"/usr/sbin/system_profiler", "SPAirPortDataType", "-json", "-detailLevel", "basic"})
            if success then
                data = util.json_parse_string(stdout)
                if data ~= nil then
                    interfaces  = data["SPAirPortDataType"][1]["spairport_airport_interfaces"]
                    for _, interface in ipairs(interfaces) do
                        ifname = interface["_name"]
                        if util.has_value(network_interface_list, ifname) then
                            spairport_signal_noise = interface["spairport_current_network_information"]["spairport_signal_noise"]
                            signal_level = spairport_signal_noise:match("(-%d+) dBm")
                            if signal_level ~= nil then
                                output["interfaces"][ifname] = tonumber(signal_level)
                            end
                        end
                    end
                end
            end
        elseif config["os_name"] == "linux" then
            network_interface_list = config["status_bar"]["system_status"]["network_interface_list"]
            if network_interface_list ~= nil then
                for _, ifname in ipairs(network_interface_list) do
                    success, stdout, stderr = wezterm.run_child_process({"iwconfig", ifname})
                    if success then
                        signal_level = stdout:match("Signal level=-(-%d+) dBm")
                        if signal_level ~= nil then
                            output["interfaces"][ifname] = tonumber(signal_level)
                        end
                    end
                end
            end
        end
        output["timestamp"] = util.get_timestamp()
        file = io.open(config["status_bar"]["wifi_status"]["data_file"], "w")
        file:write(wezterm.json_encode(output))
        file:close()
    end
end

function get_wifi_status(config)
    wifi_status = {}
    exists, err = util.file_exists(config["status_bar"]["wifi_status"]["data_file"])
    if exists then
        json_data = util.json_parse(config["status_bar"]["wifi_status"]["data_file"])
        if json_data ~= nil then
            for interface, signal in pairs(json_data["interfaces"]) do
                signal = tonumber(signal)
                interface_data = util.pad_string(2, 2, string.format("%s %s %s dBm", get_icon(signal), interface, signal))
                table.insert(wifi_status, interface_data)
            end
        end
        return wifi_status
    end
    return nil
end

function get_icon(signal)
    if signal >= -30 then
        return wezterm.nerdfonts.md_wifi_strength_4
    elseif signal >= -50 then
        return wezterm.nerdfonts.md_wifi_strength_3
    elseif signal >= -60 then
        return wezterm.nerdfonts.md_wifi_strength_2
    elseif signal >= -70 then
        return wezterm.nerdfonts.md_wifi_strength_1
    elseif signal >= -80 then
        return wezterm.nerdfonts.md_wifi_strength_outline
    elseif signal >= -90 then
        return wezterm.nerdfonts.md_wifi_strength_alert_outline
    end
end

wifi_status.get_wifi_status = get_wifi_status
wifi_status.update_json = update_json

return wifi_status
