local wezterm = require "wezterm"
local json = {}

function json_parse_string(input)
    local json_data = wezterm.json_parse(input)
    return json_data
end

function json_parse(filename)
    if file_exists(filename) then
        local filehandle = io.open(filename, "r")
        local json_string = filehandle:read("*a")
        filehandle:close()
        local json_data = wezterm.json_parse(json_string)
        return json_data
    else
        return nil
    end
end

json.json_parse = json_parse
json.json_parse_string = json_parse_string

return json
