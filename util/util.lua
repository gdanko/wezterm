local folderOfThisFile = (...):match("(.-)[^%.]+$")
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

function has_value(array, value)
    for _, element in ipairs(array) do
        if element == value then
            return true
        end
    end
    return false
end

function determine_action(config)
    if file_exists(config["data_file"]) then
        local data = util.json_parse(config["data_file"])
        if data == nil then
            return "update", nil
        else
            if (get_timestamp() - data["timestamp"]) > (config["freshness_threshold"] * 60) then
                return "update", nil
            else
                local hours, minutes, seconds = get_hms()
                if ((minutes % config["interval"]) == 0 and seconds < 4) then
                    return "update", nil
                else
                    return "display", data
                end
            end
        end
    else
        return "update", nil
    end
end

util.determine_action = determine_action
util.execute_command = execute_command
util.has_value = has_value

local conversion = require(folderOfThisFile .. "conversion")
util.byte_converter = conversion.byte_converter
util.duration = conversion.duration
util.fahrenheit_to_celsius = conversion.fahrenheit_to_celsius
util.process_bytes = conversion.process_bytes

local filesystem = require(folderOfThisFile .. "filesystem")
util.basename = filesystem.basename
util.dirname = filesystem.dirname
util.path_join = filesystem.path_join
util.get_cwd = filesystem.get_cwd
util.file_exists = filesystem.file_exists
util.exists = filesystem.exists
util.is_dir = filesystem.is_dir

local json = require(folderOfThisFile .. "json")
util.json_parse = json.json_parse
util.json_parse_string = json.json_parse_string

local math = require(folderOfThisFile .. "math")
util.divide = math.divide

local network = require(folderOfThisFile .. "network")
util.network_data_darwin = network.network_data_darwin
util.network_data_linux = network.network_data_linux

local strings = require(folderOfThisFile .. "strings")
util.get_plural = strings.get_plural
util.pad_string = strings.pad_string
util.split_lines = strings.split_lines
util.split_words = strings.split_words
util.string_split = strings.string_split

local time = require(folderOfThisFile .. "time")
util.get_hms = time.get_hms
util.get_timestamp = time.get_timestamp

return util
