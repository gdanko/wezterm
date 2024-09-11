local wezterm = require "wezterm"
local util = require "util.util"

local weather = {}

function update_json(config)
    needs_update = false
    number, multiplier = util.get_number_and_multiplier(config["interval"])
    exists, err = util.file_exists(config["data_file"])
    if exists then
        weather_data = util.json_parse(config["data_file"])
        if weather_data ~= nil then
            if (util.get_timestamp() - weather_data["timestamp"]) > (number * multiplier) then
                needs_update = true
            end
        end
    else
        needs_update = true
    end

    if needs_update then
        url = string.format("http://api.weatherapi.com/v1/forecast.json?key=%s&q=%s&days=%s&aqi=yes&alerts=yes", config["api_key"], config["location"]:gsub(" ", "%%20"), "2")
        success, stdout, stderr = wezterm.run_child_process({"curl", url})
        if success then
            weather_data = util.json_parse_string(stdout)
            if weather_data ~= nil then
                weather_data["timestamp"] = util.get_timestamp()
                file = io.open(config["data_file"], "w")
                file:write(wezterm.json_encode(weather_data))
                file:close()
            end
        end

        needs_update = false
        conditions = {}
        exists, err = util.file_exists(config["conditions_file"])
        if exists then
            condition_data = util.json_parse(config["conditions_file"])
            if condition_data ~= nil then
                if (util.get_timestamp() - condition_data["timestamp"]) > (config["interval"] * 3600) then
                    needs_update = true
                end
            end
        else
            needs_update = true
        end

        url = "https://www.weatherapi.com/docs/weather_conditions.json"
        success, stdout, stderr = wezterm.run_child_process({"curl", url})
        if success then
            conditions_array = util.json_parse_string(stdout)
            if conditions_array ~= nil then
                conditions["data"] = conditions_array
                conditions["timestamp"] = util.get_timestamp()
                file = io.open(config["conditions_file"], "w")
                file:write(wezterm.json_encode(conditions))
                file:close()
            end
        end
    end
end

function get_weather(config)
    exists, err = util.file_exists(config["data_file"])
    if exists then
        weather_data = util.json_parse(config["data_file"])
        if weather_data ~= nil then
            if config["use_celsius"] then
                current_temp = weather_data["current"]["temp_c"]
                unit = "C"
            else
                current_temp = weather_data["current"]["temp_f"]
                unit = "F"
            end
            weather = string.format("%s %s°%s", config["location"], current_temp, unit)
            return util.pad_string(2, 2, weather)
        end
    end
    return nil
end

weather.get_weather = get_weather
weather.update_json = update_json

return weather
