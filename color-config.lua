local wezterm = require "wezterm"
local util = require "util.util"

color_config = {}

local wezterm = require 'wezterm'

local function detect_theme()
    -- Helper to run a command and capture stdout
    local function run_and_capture(cmd)
        local success, stdout, stderr = wezterm.run_child_process(cmd)
        if success and stdout then
            return stdout
        end
        return ""
    end

    -- 1. Try DBus portal (org.freedesktop.appearance)
    local result = run_and_capture {
        "gdbus", "call", "--session",
        "--dest", "org.freedesktop.portal.Desktop",
        "--object-path", "/org/freedesktop/portal/desktop",
        "--method", "org.freedesktop.portal.Settings.Read",
        "org.freedesktop.appearance", "color-scheme"
    }

    if result:match("uint32 1") then
        return "dark"
    elseif result:match("uint32 0") then
        return "light"
    elseif result:match("uint32 2") then
        return "light"
    end

    -- 2. Try GTK theme name
    result = run_and_capture {
        "gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"
    }

    if result:lower():match("dark") then
        return "dark"
    elseif result ~= "" then
        return "light"
    end

    -- 3. Try KDE Plasma config
    result = run_and_capture {
        "grep", "^LookAndFeelPackage=", os.getenv("HOME") .. "/.config/kdeglobals"
    }

    if result:lower():match("dark") then
        return "dark"
    elseif result ~= "" then
        return "light"
    end

    -- 4. Fallback
    return "light"
end

function select_random_scheme(all_color_schemes)
    local keys = {}
    local n = 0
    for k, _ in pairs(all_color_schemes) do
        n = n + 1
        keys[n] = k
    end
    local index = math.random(0, #(keys))
    return keys[index]
end

function scheme_is_valid(scheme)
    keys = {'background', 'cursor_bg', 'cursor_fg', 'foreground', 'selection_bg', 'selection_fg'}
    for _, key in ipairs(keys) do
        if scheme[key] == nil then
            return false
        end
    end
    return true
end

function get_color_scheme(theme_name, scheme_name, randomize_color_scheme)
    local color_scheme_map = {}
    local default_color_scheme = {
        background   = "#dfdbc3",
        cursor_bg    = "#73635a",
        cursor_fg    = "#000000",
        foreground   = "#3b2322",
        selection_bg = "#000000",
        selection_fg = "#a4a390",
        ansi = {
            "#000000",
            "#cc0000",
            "#009600",
            "#d06b00",
            "#0000cc",
            "#cc00cc",
            "#0087cc",
            "#cccccc",
        },
        brights = {
            "#7f7f7f",
            "#cc0000",
            "#009600",
            "#d06b00",
            "#0000cc",
            "#cc00cc",
            "#0086cb",
            "#ffffff"
        }
    }

    local color_schemes_filename = util.path_join({wezterm.config_dir, "color-schemes.json"})
    local all_color_schemes = util.json_parse(color_schemes_filename)
    if all_color_schemes ~= nil then
        if randomize_color_scheme then
            scheme_name = select_random_scheme(all_color_schemes)
        end

        if all_color_schemes[scheme_name] ~= nil then
            if theme_name == "dark" then
                if scheme_is_valid(all_color_schemes[scheme_name]["colors_dark"]) then
                    scheme = all_color_schemes[scheme_name]["colors_dark"]
                else
                    scheme = all_color_schemes[scheme_name]["colors"]
                end
            elseif theme_name == "light" then
                if scheme_is_valid(all_color_schemes[scheme_name]["colors_light"]) then
                    scheme = all_color_schemes[scheme_name]["colors_light"]
                else
                    scheme = all_color_schemes[scheme_name]["colors"]
                end
            else
                scheme = all_color_schemes[scheme_name]["colors"]
            end

            color_scheme_map = {
                ansi         = scheme["ansi"],
                background   = scheme["background"],
                brights      = scheme["brights"],
                cursor_bg    = scheme["cursor_bg"],
                cursor_fg    = scheme["cursor_fg"],
                foreground   = scheme["foreground"],
                selection_bg = scheme["selection_fg"],
                selection_fg = scheme["selection_bg"],
            }
        else
            color_scheme_map = default_color_scheme
        end
    else
        color_scheme_map = default_color_scheme
    end
    return color_scheme_map
end

color_config.detect_theme = detect_theme
color_config.get_color_scheme = get_color_scheme

return color_config
