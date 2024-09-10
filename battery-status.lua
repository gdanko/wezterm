local wezterm = require "wezterm"

battery_status = {}

function to_int(input)
    return math.floor(input)
end

function get_battery_status(b)
    local icon = ""
    local soc = b.state_of_charge * 100
    local state = b.state

    if state == "Charging" then
        icon_set = {
            wezterm.nerdfonts.md_battery_alert, wezterm.nerdfonts.md_battery_charging_10, wezterm.nerdfonts.md_battery_charging_20, wezterm.nerdfonts.md_battery_charging_30,
            wezterm.nerdfonts.md_battery_charging_40, wezterm.nerdfonts.md_battery_charging_50, wezterm.nerdfonts.md_battery_charging_60, wezterm.nerdfonts.md_battery_charging_70,
            wezterm.nerdfonts.md_battery_charging_80, wezterm.nerdfonts.md_battery_charging_90, wezterm.nerdfonts.md_battery_charging,
        }
    else
        icon_set = {
            wezterm.nerdfonts.md_battery_alert, wezterm.nerdfonts.md_battery_10, wezterm.nerdfonts.md_battery_20, wezterm.nerdfonts.md_battery_30, wezterm.nerdfonts.md_battery_40,
            wezterm.nerdfonts.md_battery_50, wezterm.nerdfonts.md_battery_60, wezterm.nerdfonts.md_battery_70, wezterm.nerdfonts.md_battery_80, wezterm.nerdfonts.md_battery_90,
            wezterm.nerdfonts.md_battery,
        }
    end

    if to_int(soc) == 100 then
        if state == "Charging" or state == "Full" then
            icon = wezterm.nerdfonts.md_battery_charging
        else
            icon = wezterm.nerdfonts.md_battery
        end
    else
        icon = icon_set[to_int(soc / 10) + 1]
    end
    
    return icon, string.format('%.0f%%', soc)
end

battery_status.get_battery_status = get_battery_status

return battery_status
