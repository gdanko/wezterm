package.path = "../util/?.lua;" .. package.path
local wezterm = require "wezterm"
local util = require "util.util"
local load_averages = {}

function darwin_load_averages(config)
    success, stdout, stderr = wezterm.run_child_process({"/usr/bin/uptime"})
    if success then
        load1, load5, load15 = stdout:match("load averages:%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)")
        load_averages = string.format("load: %s, %s, %s", load1, load5, load15)
        return util.pad_string(2, 2, load_averages)
    end
    return nil
end

function linux_load_averages(config)
    success, stdout, stderr = wezterm.run_child_process({"/usr/bin/uptime"})
    if success then
        load1, load5, load15 = stdout:match("load average:%s+(%d+.%d+),%s+(%d+.%d+),%s+(%d+.%d+)")
        load_averages = string.format("load: %s, %s, %s", load1, load5, load15)
        return util.pad_string(2, 2, load_averages)
    end
    return nil
end

load_averages.darwin_load_averages = darwin_load_averages
load_averages.linux_load_averages = linux_load_averages

return load_averages
