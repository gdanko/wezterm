local color_config = require "color-config"
local config_parser = require "parse-config"
local status_bar = require "status-bar"
local util = require "util.util"
local wezterm = require "wezterm"
local username = os.getenv('USER')
local hostname = wezterm.hostname()

local act = wezterm.action

local user_config = config_parser.get_config()

-- Enable/disable config blocks
config_appearance_enabled           = true
config_color_scheme_enabled         = true
config_environment_enabled          = true
config_fonts_enabled                = true
config_general_enabled              = true
config_keys_enabled                 = true
config_status_bar_enabled           = true
config_tabs_enabled                 = true
config_test_enabled                 = true

color_scheme_map = color_config.get_color_scheme(
    user_config["display"]["color_scheme"]["scheme_name"],
    user_config["display"]["color_scheme"]["randomize_color_scheme"]
)

local config_appearance = {
    enabled = config_appearance_enabled,
    bold_brightens_ansi_colors = true,
    enable_scroll_bar = true,
    enable_wayland = true,
    -- foreground_text_hsb = {
    --     hue=1.0,
    --     saturation=1.0,
    --     balance=1.5
    -- },
    front_end    = "OpenGL",
    initial_cols = user_config["display"]["initial_cols"],
    initial_rows = user_config["display"]["initial_rows"],
    line_height  = 1.0,
    native_macos_fullscreen_mode = false,
    use_resize_increments = true,

    window_background_opacity = user_config["display"]["window_background_opacity"],
    window_padding = user_config["display"]["window_padding"]
}

local config_color_scheme = {}

if user_config["display"]["color_scheme"]["enable_gradient"] then
    config_color_scheme = {
        enabled = config_color_scheme_enabled,
        window_background_gradient = {
            orientation = "Vertical",
            colors = {"#0f0c29", "#302b63", "#24243e"},
            -- colors = {"#283b3c", "#26484a", "#215e61"},
            interpolation = "Linear",
            blend = "Rgb",
        }
    }
else
    config_color_scheme = {
        enabled = config_color_scheme_enabled,
        colors = color_scheme_map,
    }
end

local config_environment = {
    enabled = config_environment_enabled,
    audible_bell = "Disabled",
    automatically_reload_config = true,
    pane_focus_follows_mouse = true, -- Doesn't seem to work??
    prefer_egl = true,
    scroll_to_bottom_on_input = true,
    scrollback_lines = 100000,
    swallow_mouse_click_on_window_focus = swallow_mouse_click_on_window_focus,
    term = "xterm-256color",
}

local config_fonts = {
    window_frame = {
        font = wezterm.font {
            family  = user_config["display"]["tab_bar_font"]["family"],
            weight  = user_config["display"]["tab_bar_font"]["weight"],
            stretch = user_config["display"]["tab_bar_font"]["stretch"],
        },
        font_size = user_config["display"]["tab_bar_font"]["size"],
    },
    adjust_window_size_when_changing_font_size = false,
    hide_tab_bar_if_only_one_tab = true,
    enabled = config_fonts_enabled,
    font_size = user_config["display"]["terminal_font"]["size"],
    font_rasterizer = "FreeType",
    font_shaper = "Harfbuzz",
    font = wezterm.font_with_fallback{
        {
            family  = user_config["display"]["terminal_font"]["family"],
            weight  = user_config["display"]["terminal_font"]["weight"],
            stretch = user_config["display"]["terminal_font"]["stretch"],
        }
    },
    -- https://wezfurlong.org/wezterm/config/lua/config/font_rules.html
    font_rules = {
        {
            italic        = true,
            intensity     = "Normal",
            underline     = "None",
            blink         = "Slow",
            reverse       = true,
            strikethrough = true,
            invisible     = false,
            font          = wezterm.font_with_fallback{
                {
                    family  = user_config["display"]["terminal_font"]["family"],
                    weight  = user_config["display"]["terminal_font"]["weight"],
                    stretch = user_config["display"]["terminal_font"]["stretch"],
                }
            }
        }
    }
}

local config_general = {
    enabled = config_general_enabled,
    check_for_updates = true,
    check_for_updates_interval_seconds = 86400,
    default_cwd = wezterm.home_dir,
    exit_behavior = "CloseOnCleanExit",
    skip_close_confirmation_for_processes_named = {
        "ash",
        "bash",
        "csh",
        "fish",
        "sh",
        "tmux",
        "zsh",
    },
    window_close_confirmation = "AlwaysPrompt",
    set_environment_variables = {
        PATH = "/opt/homebrew/bin" .. ":" .. os.getenv("PATH") -- May not be working
    }
}

local config_keys = {
    enabled = config_keys_enabled,
    keys = {
        {
            key = "r",
            mods = "CMD|SHIFT",
            action = wezterm.action.ReloadConfiguration,
        },
        {
            key = "a",
            mods = "SHIFT|CTRL",
            action = wezterm.action_callback(function(window, pane)
                local dims = pane:get_dimensions()
                local txt = pane:get_text_from_region(0, dims.scrollback_top, 0, dims.scrollback_top + dims.scrollback_rows)
                window:copy_to_clipboard(txt:match("^%s*(.-)%s*$")) -- trim leading and trailing whitespace
            end)
        },
        {
            key =  "a",
            mods = user_config["keymod"],
            action = wezterm.action_callback(function(window, pane)
                local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
                window:copy_to_clipboard(selected, "Clipboard")
            end)
        },
        {
            key = "k",
            mods = user_config["keymod"],
            action = act.Multiple {
                act.ClearScrollback "ScrollbackAndViewport",
                act.SendKey { key = "L", mods = "CTRL" },
            },
        },
        {
            key = "Enter",
            mods = user_config["keymod"],
            action = "ToggleFullScreen"
        },
        {
            key = "t",
            mods = user_config["keymod"],
            action=wezterm.action {
                SpawnCommandInNewTab = {
                    cwd = wezterm.home_dir
                }
            }
        },
        {
            key = "n",
            mods = user_config["keymod"],
            action = wezterm.action {
                SpawnCommandInNewWindow = {
                    cwd = wezterm.home_dir
                }
            }
        },
        {
            key = "w",
            mods = user_config["keymod"],
            action = wezterm.action {
                CloseCurrentTab = {
                    confirm = true
                }
            }
        },
        -- {
        --     key = "l",
        --     mods = user_config["keymod"],
        --     action = wezterm.action.SplitPane {
        --         direction = "Left",
        --         size = { Percent = 50 },
        --     }
        -- },
        -- {
        --     key = "r",
        --     mods = user_config["keymod"],
        --     action = wezterm.action.SplitPane {
        --         direction = "Right",
        --         size = { Percent = 50 },
        --     }
        -- },
        -- {
        --     key = "u",
        --     mods = user_config["keymod"],
        --     action = wezterm.action.SplitPane {
        --         direction = "Up",
        --         size = { Percent = 50 },
        --     }
        -- },
        -- {
        --     key = "d",
        --     mods = user_config["keymod"],
        --     action = wezterm.action.SplitPane {
        --         direction = "Down",
        --         size = { Percent = 50 },
        --     }
        -- },
    },
    swap_backspace_and_delete = false,
}

local config_tabs = {
    enabled = config_tabs_enabled,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = true,
    tab_bar_at_bottom = false,
    tab_max_width = 8,
    use_fancy_tab_bar = true,
}

local config_status_bar = {
    wezterm.on('update-right-status', function(window, pane)
        -- Each element holds the text for a cell in a "powerline" style << fade
        local cwd = util.get_cwd(pane)

        -- Get system stats
        cells = status_bar.update_status_bar(cwd)

        -- The powerline < symbol
        local LEFT_ARROW = utf8.char(0xe0b3)
        -- The filled-in variant of the < symbol
        local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
      
        -- Color palette for the backgrounds of each cell
        -- https://maketintsandshades.com/
        -- https://mdigi.tools/color-shades/#410093
        local colors = {
            -- "#c08fff",
            -- "#b57aff",
            -- "#aa66ff",
            -- "#9e52ff",
            -- "#933dff",
            -- "#8729ff",
            -- "#7c14ff",
            -- "#7100ff",
            -- "#6800eb",
            "#5f00d6",
            "#5600c2",
            "#4d00ad",
            "#440099",
            "#3b0085",
            "#320070",
            "#29005c",
            "#200047",
            "#170033",
            "#0e001f",
        }
      
        -- Foreground color for the text across the fade
        local text_fg = "#c0c0c0"
        -- The elements to be formatted
        local elements = {}
        -- How many cells have been formatted
        local num_cells = 0
      
        -- Translate a cell into elements
        function push(text, is_last)
            local cell_no = num_cells + 1
            table.insert(elements, { Foreground = { Color = text_fg } })
            table.insert(elements, { Background = { Color = colors[cell_no] } })
            table.insert(elements, { Text = ' ' .. text .. ' ' })
          if not is_last then
            table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
            table.insert(elements, { Text = SOLID_LEFT_ARROW })
          end
          num_cells = num_cells + 1
        end
      
        while #cells > 0 do
            local cell = table.remove(cells, 1)
            push(cell, #cells == 0)
        end
      
        window:set_right_status(wezterm.format(elements))
      end)
}

local config_test = {
    enabled = config_test_enabled,
    status_update_interval = user_config["status_bar"]["update_interval"] * 1000
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    local title = util.basename(pane.foreground_process_name)
    local cwd = nil

    if user_config["tabs"]["title_is_cwd"] then
        local cwd_uri = pane.current_working_dir
        if cwd_uri then
            cwd = cwd_uri.file_path
            cwd = string.gsub(cwd, wezterm.home_dir, "~")
            if cwd ~= nil then
                title = string.format("%s@%s: %s", username, hostname, cwd)
            end
        end
    end

    local color = "#41337c"
    if tab.is_active then
        color = "#301f7c"
    elseif hover then
        color = "green"
    end

    return {
        { Background = { Color = color } },
        { Text = util.pad_string(2, 2, title)},
    }
end)

configs = {
    config_appearance,
    config_color_scheme,
    config_environment,
    config_fonts,
    config_general,
    config_keys,
    config_status_bar,
    config_tabs,
    config_test,
}

full_config = {}
for index, block in ipairs(configs) do
    if block["enabled"] ~= nil then
        if block["enabled"] == true then
            for key, value in pairs(block) do
                -- The key "enabled" is not valid so ignore it
                if key ~= "enabled" then
                    full_config[key] = value
                end
            end
        end
    end
end

return full_config
