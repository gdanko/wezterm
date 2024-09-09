local strings = {}

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

function split_lines(input)
    local lines = {}
	for line in string.gmatch(input, "[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

function split_words(input)
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    return parts
end

function get_plural(count, string)
    if count == 1 then
        return string
    else
        return string.format("%ss", string)
    end
end

function pad_string(pad_left, pad_right, input_string)
    if input_string ~= nil then
        return (" "):rep(pad_left) .. input_string .. (" "):rep(pad_right)
    else
        return input_string
    end
end

strings.get_plural = get_plural
strings.pad_string = pad_string
strings.split_lines = split_lines
strings.split_words = split_words
strings.string_split = string_split

return strings
