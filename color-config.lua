local wezterm = require "wezterm"
local util = require "util"

color_config = {}

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

function color_config.get_color_scheme(scheme_name, randomize_color_scheme)
    local color_scheme_map = {}
    local default_color_scheme = {
        background   = "#dfdbc3",
        cursor_bg    = "#73635a",
        cursor_fg    = "#000000",
        foreground   = "#3b2322",
        selection_bg = "#000000",
        selection_fg = "#a4a390"
    }

    local color_schemes_filename = util.path_join({wezterm.config_dir, "color-schemes.json"})
    local all_color_schemes = util.json_parse(color_schemes_filename)
    if all_color_schemes ~= nil then
        if randomize_color_scheme then
            scheme_name = select_random_scheme(all_color_schemes)
        end

        if all_color_schemes[scheme_name] ~= nil then
            color_scheme_map = {
                background = all_color_schemes[scheme_name]["background"],
                cursor_bg = all_color_schemes[scheme_name]["cursor_bg"],
                cursor_fg = all_color_schemes[scheme_name]["cursor_fg"],
                foreground = all_color_schemes[scheme_name]["foreground"],
                selection_fg = all_color_schemes[scheme_name]["selection_bg"],
                selection_bg = all_color_schemes[scheme_name]["selection_fg"],           
            }
        else
            color_scheme_map = default_color_scheme
        end
    else
        color_scheme_map = default_color_scheme
    end
    return color_scheme_map
end

return color_config
