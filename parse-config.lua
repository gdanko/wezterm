local wezterm = require "wezterm"
local util = require "util.util"

config_parser = {}

local datadir = util.path_join({wezterm.config_dir, "data"})
if not util.is_dir(datadir) then
    os.execute("mkdir -p " .. datadir)
end

--[=====[
    Some things like weather and stock quotes will have an "interval" filed. This
    allows you to check things on a periodic basis and avoid getting rate-limited
    when using APIs.

    The format of the interval filed is <number><unit>, e.g., 15m for 15 minutes.
    Valid units are (s)econd, (m)inute, (h)our, and (d)ay. An invalid entry will
    result in the default of 15m. In other words, if you change an interval to
    "10z", the function to determine the number and multiplier will not be able to
    recognize the input and will default to 15 minutes.
--]=====]

function get_config()
    local config = {
        display = {
            tab_bar_font = {
                family  = "Roboto",
                size    = 12,
                stretch = "Normal",
                weight  = "Bold",
            },
            terminal_font = {
                family  = "JetBrains Mono",
                size    = 14,
                stretch = "Normal",
                weight  = "Regular",
            },
            initial_cols = 80,
            initial_rows = 25,
            color_scheme = {
                theme = "auto",
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
        status_bar = {
            update_interval = 2,
            system_status = {
                disk_list = {{mount_point = "/", unit = "Gi"}},
                enabled = true,
                memory_unit = "Gi",
                network_interface_list = {},
                toggles = {
                    show_cpu_usage = true,
                    show_disk_usage = true,
                    show_load_averages = false,
                    show_memory_usage = true,
                    show_network_throughput = true,
                    show_uptime = true,
                },
            },
            stock_quotes = {
                data_file = util.path_join({datadir, "stock-quotes.json"}),
                enabled = true,
                indexes = {
                    show_djia = false,
                    show_nasdaq = false,
                    show_sp500 = false,
                    show_gold = false,
                    show_crude = false,
                },
                interval = "15m", -- decreasing too aggressively might get you rate-limited
                symbols = {
                    "GOOG",
                    "AAPL"
                }
            },
            toggles = {
                show_battery = false,
                show_branch_info = true,
                show_clock = false,
                show_hostname = false,
            },
            weather = {
                api_key = nil, -- https://weatherapi.com/
                conditions_file = util.path_join({datadir, "weather_conditions.json"}),
                data_file = util.path_join({datadir, "weather.json"}),
                enabled = false,
                interval = "15m", -- decreasing too aggressively might get you rate-limited
                locations = {"San Diego, CA, US"},
                use_celsius = true,
            },
            wifi_status = {
                data_file = util.path_join({datadir, "wifi-status.json"}),
                enabled = true,
                interval = "10s",
            }
        },
        tabs = {
            title_is_cwd = true,
        },
    }

    -- set some OS-specific defaults
    if (wezterm.target_triple == "x86_64-apple-darwin") or (wezterm.target_triple == "aarch64-apple-darwin") then
        config["keymod"] = "SUPER"
        config["os_name"] = "darwin"
    elseif (wezterm.target_triple == "x86_64-unknown-linux-gnu") or (wezterm.target_triple == "aarch64-unknown-linux-gnu") then
        config["keymod"] = "SHIFT|CTRL"
        config["os_name"] = "linux"
    end

    -- find the Linux distro
    if config["os_name"] == "linux" then
        if util.file_exists("/etc/os-release") then
            local file = io.open("/etc/os-release", "r")
            if file then
                for line in file:lines() do
                    if string.match(line, "^ID=") then
                        os_distro = line:match('ID="(.-)"$') or line:match('ID=(.-)$')
                        if os_distro then
                            config["os_distro"] = os_distro
                        end
                    elseif string.match(line, "^VERSION_ID=") then
                        os_version = line:match('VERSION_ID="(.-)"$') or line:match('VERSION_ID=(.-)$')
                        if os_version then
                            config["os_version"] = os_version
                        end
                    end
                end
            end
        end
    end

    if util.file_exists( util.path_join({wezterm.config_dir, "overrides.lua"})) then
        overrides = require "overrides"
        config = overrides.override_config(config)
    end

    return config
end

config_parser.get_config = get_config

return config_parser
