local wezterm = require "wezterm"
local conversion = {}

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
        return string.format("%.2f %s", bytes, suffix)
    end

    return string.format("%.2f %s%s", bytes / math.pow(divisor, multiple), unit, suffix)
end

function duration(delta)
    local years = 0
    local days = 0
    delta = math.floor(delta)
    days = math.floor(delta / 86400)
    if days > 365 then
        years, days = divide(days, 366)
    end
    hours = math.floor(((delta - (days * 86400)) / 3600))
    minutes = math.floor(((delta - days * 86400 - hours * 3600) / 60))
    seconds = math.floor((delta - (days * 86400) - (hours * 3600) - (minutes * 60)))

    return years, days, hours, minutes, seconds
end

function fahrenheit_to_celsius(temp)
    c = (((temp - 32) * 5) / 9)
    return string.format("%.2f", c)
end

function get_number_and_multiplier(interval)
    multiplier_map = {
        ["s"] = 1,
        ["m"] = 60,
        ["h"] = 3600,
        ["d"] = 86400,
    }
    number, multiplier = interval:match("^(%d+)(%a)")
    if number ~= nil and multiplier ~= nil then
        if multiplier_map[multiplier] ~= nil then
            return number, multiplier_map[multiplier]
        end
    end
    return 15, multiplier_map["m"]
end

conversion.byte_converter = byte_converter
conversion.duration = duration
conversion.fahrenheit_to_celsius = fahrenheit_to_celsius
conversion.get_number_and_multiplier = get_number_and_multiplier
conversion.process_bytes = process_bytes

return conversion
