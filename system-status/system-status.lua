local wezterm = require "wezterm"
local system_status = {}

local folderOfThisFile = (...):match("(.-)[^%.]+$")

local cpu_usage = require(folderOfThisFile .. "cpu-usage")
local disk_usage = require(folderOfThisFile .. "disk-usage")
local load_averages = require(folderOfThisFile .. "load-averages")
local memory_usage = require(folderOfThisFile .. "memory-usage")
local network_throughput = require(folderOfThisFile .. "network-throughput")
local uptime = require(folderOfThisFile .. "uptime")

function get_cpu_usage(config)
    if config["os_name"] == "darwin" then
        return cpu_usage.darwin_cpu_usage(config)
    elseif config["os_name"] == "linux" then
        return cpu_usage.linux_cpu_usage(config)
    end
end

function get_disk_usage(config)
    if config["os_name"] == "darwin" then
        return disk_usage.darwin_disk_usage(config)
    elseif config["os_name"] == "linux" then
        return disk_usage.linux_disk_usage(config)
    end
end

function get_memory_usage(config)
    if config["os_name"] == "darwin" then
        return memory_usage.darwin_memory_usage(config)
    elseif config["os_name"] == "linux" then
        return memory_usage.linux_memory_usage(config)
    end
end

function get_load_averages(config)
    if config["os_name"] == "darwin" then
        return load_averages.darwin_load_averages(config)
    elseif config["os_name"] == "linux" then
        return load_averages.linux_load_averages(config)
    end
end

function get_network_throughput(config)
    if config["os_name"] == "darwin" then
        return network_throughput.darwin_network_throughput(config)
    elseif config["os_name"] == "linux" then
        return network_throughput.linux_network_throughput(config)
    end
end

function get_system_uptime(config)
    if config["os_name"] == "darwin" then
        return uptime.darwin_uptime(config)
    elseif config["os_name"] == "linux" then
        return uptime.linux_uptime(config)
    end
end

system_status.get_cpu_usage = get_cpu_usage
system_status.get_disk_usage = get_disk_usage
system_status.get_load_averages = get_load_averages
system_status.get_memory_usage = get_memory_usage
system_status.get_network_throughput = get_network_throughput
system_status.get_system_uptime = get_system_uptime

return system_status
