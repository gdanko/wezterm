local color_config = require "color-config"
local status_bar = require "status-bar"
local util = require "util"
local wezterm = require "wezterm"
local config_parser = require "parse-config"

local act = wezterm.action

config = config_parser.get_config()

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
    config["display"]["color_scheme"]["scheme_name"],
    config["display"]["color_scheme"]["randomize_color_scheme"]
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
    initial_cols = config["display"]["initial_cols"],
    initial_rows = config["display"]["initial_rows"],
    line_height  = 1.0,
    native_macos_fullscreen_mode = false,
    use_resize_increments = true,

    window_background_opacity = config["display"]["window_background_opacity"],
    window_padding = config["display"]["window_padding"]
}

local config_color_scheme = {}

if config["display"]["color_scheme"]["enable_gradient"] then
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
    adjust_window_size_when_changing_font_size = true,
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
    enabled = config_fonts_enabled,
    font_size = config["display"]["font_size"],
    font_rasterizer = "FreeType",
    font_shaper = "Harfbuzz",
    font_rules = {
        {
            italic        = true,
            intensity     = "Normal",
            underline     = "None",
            blink         = "Slow",
            reverse       = true,
            strikethrough = true,
            invisible     = false,
            font          = wezterm.font_with_fallback({"JetBrains Mono", "SF Mono Regular"})
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
            key = "k",
            mods = config["keymod"],
            action = act.Multiple {
                act.ClearScrollback "ScrollbackAndViewport",
                act.SendKey { key = "L", mods = "CTRL" },
            },
        },
        {
            key = "Enter",
            mods = config["keymod"],
            action = "ToggleFullScreen"
        },
        {
            key = "t",
            mods = config["keymod"],
            action=wezterm.action {
                SpawnCommandInNewTab = {
                    cwd = wezterm.home_dir
                }
            }
        },
        {
            key = "n",
            mods = config["keymod"],
            action = wezterm.action {
                SpawnCommandInNewWindow = {
                    cwd = wezterm.home_dir
                }
            }
        },
        {
            key = "w",
            mods = config["keymod"],
            action = wezterm.action {
                CloseCurrentTab = {
                    confirm = true
                }
            }
        },
        {
            key =  "a",
            mods = config["keymod"],
            action = act.EmitEvent "select-all-to-clipboard"
        },
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
        local cwd = ""
        local hostname = ""
        local cwd_uri = pane:get_current_working_dir()
        if cwd_uri then
            cwd = cwd_uri.file_path
            hostname = cwd_uri.host or wezterm.hostname()
        end

        -- Get system stats using wsstats
        cells = status_bar.update_status_bar(cwd)

        -- The powerline < symbol
        local LEFT_ARROW = utf8.char(0xe0b3)
        -- The filled-in variant of the < symbol
        local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
      
        -- Color palette for the backgrounds of each cell
        -- https://maketintsandshades.com/
        local colors = {
            "#410093",
            "#3b0084",
            "#340076",
            "#2e0067",
            "#270058",
            "#21004a",
            "#1a003b",
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
    status_update_interval = config["status_bar"]["update_interval"] * 1000
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local tab_padding = "    "
    if tab.is_active then
        return {
            {Background={Color="#301f7c"}},
            {Text=tab_padding .. tab.active_pane.title .. tab_padding},
        }
    else
        return {
            {Background={Color="#41337c"}},
            {Text=tab_padding .. tab.active_pane.title .. tab_padding},
        }
    end
    return tab.active_pane.title
end)

wezterm.on("select-all-to-clipboard", function(window, pane)
    local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
    window:copy_to_clipboard(selected, 'Clipboard')
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
