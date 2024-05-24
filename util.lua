local wezterm = require "wezterm"

local util = {}

function execute_command(cwd, command)
    local command = "cd " .. cwd .. " &&  " .. command
    local handle = io.popen(command)
    local output = handle:read('*all')
    local exit = {handle:close()}
    local return_code = exit[3]
    local command_out = output:gsub("\n", "")
    return return_code, command_out
end

-- Better popen using posix
-- https://stackoverflow.com/questions/1242572/how-do-you-construct-a-read-write-pipe-with-lua/16515126#16515126

function string_split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function get_cwd(pane)
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
        cwd = cwd_uri.file_path
        cwd = string.gsub(cwd, wezterm.home_dir, "~")
        return cwd
    end
    return nil
end

function basename(path)
    return string.gsub(path, "(.*/)(.*)", "%2")
end

function dirname(path)
    return string.gsub(path, "(.*/)(.*)", "%1")
end

function path_join(path_bits)
    return table.concat(path_bits, "/")
end

function has_value(array, value)
    for _, element in ipairs(array) do
        if element == value then
            return true
        end
    end
    return false
end

function process_bytes(num)
    suffix = "B"
    for _, unit in ipairs({"", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"}) do
        if math.abs(num) < 1024.0 then
            return string.format("%.2f %s%s/s", num, unit, suffix)
        end
        num = num / 1024
    end
    return string.format("%.1f %s%s", num, "Yi", suffix)
end

function pad_string(pad_left, pad_right, input_string)
    -- return (" "):rep(pad_left) .. input_string .. (" "):rep(pad_right)
    if input_string ~= nil then
        return (" "):rep(pad_left) .. input_string .. (" "):rep(pad_right)
    else
        return input_string
    end
end

function file_exists(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13  or code == 1 then
          -- Permission denied, but it exists
          return true, nil
       end
    end
    return ok, err
 end

function is_dir(path)
    ok, err = exists(path.."/")
    if ok == true and err == nil then
        return true
    else
        return false
    end
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

function json_parse_string(input)
    local json_data = wezterm.json_parse(input)
    return json_data
end

function get_timestamp()
    return os.time()
end

-- Simple byte converter
-- Usage: foo = util.byte_converter(67108864, "Gi")
--        foo = util.byte_converter(67108864, "M")
function byte_converter(bytes, unit)
    suffix = "B"
    prefix = unit:sub(1, 1)
    if unit:find("i" .. "$") then
        divisor = 1024
    else
        divisor = 1000
    end

    if prefix == "K" then
        multiple = 1
    elseif prefix == "M" then
        multiple = 2
    elseif prefix == "G" then
        multiple = 3
    elseif prefix == "T" then
        multiple = 4
    elseif prefix == "P" then
        multiple = 5
    elseif prefix == "E" then
        multiple = 6
    else
        return string.format("%.2f%s", bytes, suffix)
    end

    return string.format("%.2f%s%s", bytes / math.pow(divisor, multiple), unit, suffix)
end

function duration(seconds)
    seconds = math.floor(seconds)
    days = math.floor(seconds / 86400)
    hours = math.floor(((seconds - (days * 86400)) / 3600))
    minutes = math.floor(((seconds - days * 86400 - hours * 3600) / 60))
    secs = math.floor((seconds - (days * 86400) - (hours * 3600) - (minutes * 60)))

    return days, hours, minutes, secs
end

function get_hms()
    time = os.date("*t")

    return time.hour, time.min, time.sec
end

function farenheit_to_celsius(temp)
    c = (((temp - 32) * 5) / 9)
    return string.format("%.2f", c)
end

util.basename = basename
util.byte_converter = byte_converter
util.dirname = dirname
util.duration = duration
util.execute_command = execute_command
util.exists = exists
util.farenheit_to_celsius = farenheit_to_celsius
util.file_exists = file_exists
util.get_cwd = get_cwd
util.get_hms = get_hms
util.get_timestamp = get_timestamp
util.has_value = has_value
util.is_dir = is_dir
util.json_parse = json_parse
util.json_parse_string = json_parse_string
util.pad_string = pad_string
util.path_join = path_join
util.process_bytes = process_bytes
util.split_to_lines = split_to_lines
util.string_split = string_split

return util
