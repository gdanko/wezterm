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
        weather = {
            locations = {}
        }
        for _, location in ipairs(config["locations"]) do
            url = string.format("http://api.weatherapi.com/v1/forecast.json?key=%s&q=%s&days=%s&aqi=yes&alerts=yes", config["api_key"], location:gsub(" ", "%%20"), "2")
            success, stdout, stderr = wezterm.run_child_process({"curl", url})
            if success then
                weather_data = util.json_parse_string(stdout)
                if weather_data ~= nil then
                    weather["locations"][location] = weather_data
                end
            end
            weather["timestamp"] = util.get_timestamp()
            file = io.open(config["data_file"], "w")
            file:write(wezterm.json_encode(weather))
            file:close()
        end

        needs_update = false
        conditions = {}
        exists, err = util.file_exists(config["conditions_file"])
        if exists then
            condition_data = util.json_parse(config["conditions_file"])
            if condition_data ~= nil then
                if (util.get_timestamp() - condition_data["timestamp"]) > (number * multiplier) then
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
    weather_output = {}
    exists, err = util.file_exists(config["data_file"])
    if exists then
        weather_data = util.json_parse(config["data_file"])
        for location, location_data in pairs(weather_data["locations"]) do
            if location_data ~= nil then
                if location_data["error"] == nil then
                    if util.has_value(config["locations"], location) then
                        condition_code = location_data["current"]["condition"]["code"]
                        is_day = location_data["current"]["is_day"]
                        icon = get_weather_icon(condition_code, is_day)
                        if config["use_celsius"] then
                            current_temp = location_data["current"]["temp_c"]
                            unit = "C"
                        else
                            current_temp = location_data["current"]["temp_f"]
                            unit = "F"
                        end
                        weather = string.format("%s %s %s°%s", icon, location_data["location"]["name"], math.floor(current_temp), unit)
                        table.insert(weather_output, util.pad_string(2, 2, weather))
                    end
                else
                    weather = string.format("Weather: %s", location_data["error"]["message"])
                    table.insert(weather_output, util.pad_string(2, 2, weather))

                end
            end
        end
        if #weather_output > 0 then
            return weather_output
        end
    end
    return nil
end

function get_weather_icon(condition_code, is_day)
    if condition_code == 1000 then
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_sunny
        else
            return wezterm.nerdfonts.md_weather_night
        end
    elseif condition_code == 1003 then
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_partly_cloudy
        else
            return wezterm.nerdfonts.md_weather_night_partly_cloudy
        end
    elseif condition_code == 1006 then
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_cloudy
        else
            return wezterm.nerdfonts.md_weather_cloudy
        end
    elseif condition_code == 1009 then -- Overcast
        if is_day == 1 then
            return wezterm.nerdfonts.weather_day_sunny_overcast
        else
            return wezterm.nerdfonts.weather_day_sunny_overcast
        end
    elseif condition_code == 1030 then -- Mist
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_hazy
        else
            return wezterm.nerdfonts.md_weather_hazy
        end
    elseif condition_code == 1063 then -- Patchy rain possible
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_partly_rainy
        else
            return wezterm.nerdfonts.md_weather_partly_rainy
        end
    elseif condition_code == 1066 then -- Patchy snow possible
        if is_day == 1 then
            return wezterm.nerdfonts.md_weather_partly_snowy
        else
            return wezterm.nerdfonts.md_weather_partly_snowy
        end
    end
    return wezterm.nerdfonts.md_weather_sunny
end

weather.get_weather = get_weather
weather.update_json = update_json

return weather
