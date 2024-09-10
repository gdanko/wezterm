package.path = "../util/?.lua;" .. package.path
local wezterm = require "wezterm"
local util = require "util.util"
local cpu_usage = {}

function darwin_cpu_usage(config)
    success, stdout, stderr = wezterm.run_child_process({"top", "-l", 1})
    if success then
        user, sys, idle = stdout:match("CPU usage: (%d+.%d+)%%%s+user,%s+(%d+.%d+)%%%s+sys,%s+(%d+.%d+)%%%s+idle")
        cpu_usage = string.format("%s user %s%%, sys %s%%, idle %s%%", wezterm.nerdfonts.oct_cpu, user, sys, idle)
        return util.pad_string(2, 2, cpu_usage)
    end
    return nil
end

function linux_cpu_usage(config)
    success, stdout, stderr = wezterm.run_child_process({"mpstat"})
    if success then
        user, nice, sys, iowait, irq, soft, steal, guest, gnice, idle = stdout:match("all%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)%s+(%d+.%d+)")
        cpu_usage = string.format("%s user %s%%, sys %s%%, idle %s%%", wezterm.nerdfonts.oct_cpu, user, sys, idle)
        return util.pad_string(2, 2, cpu_usage)
    end
    return nil
end

cpu_usage.darwin_cpu_usage = darwin_cpu_usage
cpu_usage.linux_cpu_usage = linux_cpu_usage

return cpu_usage
