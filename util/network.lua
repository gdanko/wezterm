local wezterm = require "wezterm"
local network = {}

function network_data_darwin(interface)
    local bytes_recv = nil
    local bytes_recv = nil
    success, stdout, stderr = wezterm.run_child_process({"netstat", "-bi", "-I", interface})
    if success then
        bits = split_words(split_lines(stdout)[2])
        bytes_recv = bits[7]
        bytes_sent = bits[10]
        return bytes_recv, bytes_sent
    end
    return nil, nil
end

function network_data_linux(interface)
    local bytes_recv = nil
    local bytes_recv = nil
    success, stdout, stderr = wezterm.run_child_process({"cat", "/proc/net/dev"})
    if success then
        for _, line in ipairs(split_lines(stdout)) do
            if line:match(string.format("%s:", interface)) then
                bits = split_words(line)
                return bits[2], bits[10]
            end
        end
    end
    return nil, nil
end

network.network_data_darwin = network_data_darwin
network.network_data_linux = network_data_linux

return network
