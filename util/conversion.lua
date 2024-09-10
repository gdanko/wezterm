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

function duration(seconds)
    local years = 0
    local days = 0
    seconds = math.floor(seconds)
    days = math.floor(seconds / 86400)
    if days > 365 then
        years, days = divide(days, 366)
    end
    hours = math.floor(((seconds - (days * 86400)) / 3600))
    minutes = math.floor(((seconds - days * 86400 - hours * 3600) / 60))
    secs = math.floor((seconds - (days * 86400) - (hours * 3600) - (minutes * 60)))

    return years, days, hours, minutes, secs
end

function fahrenheit_to_celsius(temp)
    c = (((temp - 32) * 5) / 9)
    return string.format("%.2f", c)
end

conversion.byte_converter = byte_converter
conversion.duration = duration
conversion.fahrenheit_to_celsius = fahrenheit_to_celsius
conversion.process_bytes = process_bytes

return conversion
