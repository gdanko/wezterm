local wezterm = require "wezterm"
local util = require "util"

config_parser = {}

function config_parser.get_config()
    -- default config
    local config = {
        display = {
            font_size = 14,
            initial_cols = 80,
            initial_rows = 25,
            color_scheme = {
                enable_gradient = false,
                randomize_color_scheme = false,
                scheme_name = "Novel"
            },
            window_background_opacity = 1,
            window_padding = {
                left   = 10,
                right  = 20,
                top    = 0,
                bottom = 0
            }
        },
        tabs = {
            title_is_cwd = false
        },
        status_bar = {
            update_interval = 3,
            system_status = {
                disk_list = {{mount_point = "/", unit = "Gi"}},
                enabled = true,
                network_interface_list = {},
                toggles = {
                    show_cpu_usage = true,
                    show_disk_usage = true,
                    show_load_averages = false,
                    show_memory_usage = true,
                    show_network_throughput = true,
                    show_uptime = false
                }
            },
            stock_quotes = {
                enabled = true,
                interval = 15, -- decreasing too aggressively might get you rate-limited
                symbols = {
                    "GOOG",
                    "AAPL"
                }
            },
            toggles = {
                show_battery = false,
                show_branch_info = true,
                show_cwd = false,
                show_clock = false,
                show_hostname = false,
            },
            weather = {
                api_key = nil, -- https://openweathermap.org/
                enabled = false,
                interval = 15, -- decreasing too aggressively might get you rate-limited
                location = "San Diego, CA, US",
                show_high = false,
                show_low = false,
                unit = "F", -- Either "F" or "C"
            }
        }
    }

    -- set some OS-specific defaults
    if (wezterm.target_triple == "x86_64-apple-darwin") or (wezterm.target_triple == "aarch64-apple-darwin") then
        config["keymod"] = "SUPER"
        config["os_name"] = "darwin"
    elseif (wezterm.target_triple == "x86_64-unknown-linux-gnu") or (wezterm.target_triple == "aarch64-unknown-linux-gnu") then
        config["keymod"] = "CTRL"
        config["os_name"] = "linux"
    end

    if util.file_exists( util.path_join({wezterm.config_dir, "overrides.lua"})) then
        overrides = require "overrides"
        config = overrides.override_config(config)
    end

    return config
end

return config_parser
