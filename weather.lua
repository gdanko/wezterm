local wezterm = require "wezterm"

local weather = {}

function weather.write_weather_file(weather_file)
    url = string.format("https://api.openweathermap.org/geo/1.0/direct?q=%s&limit=1&appid=%s", location, appid)
    wezterm.log_info(url)
    success, stdout, stderr = wezterm.run_child_process({"curl", url})
    if success then
        wezterm.log_info(111)
        json_data = util.json_parse_string(stdout)
        if json_data ~= nil then
            wezterm.log_info(json_data)
            location_data = json_data[1]
            if location_data["lon"] ~= nil and location_data["lat"] ~= nil then
                url = string.format("https://api.openweathermap.org/data/2.5/weather?lon=%s&lat=%s&units=imperial&appid=%s", location_data["lon"], location_data["lat"], appid)
                success, stdout, stderr = wezterm.run_child_process({"curl", url})
                if success then
                    weather_data = util.json_parse_string(stdout)
                    if weather_data ~= nil then
                        weather_data["timstamp"] = util.get_timestamp()
                        cod = weather_data["cod"]
                        -- cod is status code
                        -- error out on this
                        file = io.open(weather_file, "w")
                        file:write(wezterm.json_encode(weather_data))
                        file:close()
                    end
                end
            end
        end
    end
    return nil
end

function weather.get_icon(icon_id)
    if icon_id == "01d" then
        return "☀️"
    elseif icon_id == "01n" then
        return "🌙"
    elseif icon_id == "02d" or icon_id == "02n" or icon_id == "03d" or icon_id == "03n" or icon_id == "04d" or icon_id == "04n" then
        return "☁️"
    elseif icon_id == "09d" or icon_id == "09n" then
        return "🌧"
    elseif icon_id == "10d" or icon_id == "10n" then
        return "☔️"
    elseif icon_id == "11d" or icon_id == "11n" then
        return "⚡️"
    elseif icon_id == "13d" or icon_id == "13n" then
        return "❄️"
    elseif icon_id == "50d" or icon_id == "50n" then
        return "🌫️"
    end
end

return weather
