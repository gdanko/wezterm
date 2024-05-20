local wezterm = require "wezterm"

battery_status = {}

function battery_status.get_battery_status(b)
    local icon = ""
    local battery_percent = ""
    soc = b.state_of_charge * 100
    state = b.state

    if soc == 100 then
        -- It's still plugged in even though it's full
        if state == "Charging" or state == "Full" then
            icon = wezterm.nerdfonts.md_battery_charging
        else
            icon = wezterm.nerdfonts.md_battery
        end
    elseif soc < 100 and soc > 89 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_90
        else
            icon = wezterm.nerdfonts.md_battery_90
        end
    elseif soc < 90 and soc > 79 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_80
        else
            icon = wezterm.nerdfonts.md_battery_80
        end
    elseif soc < 80 and soc > 69 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_70
        else
            icon = wezterm.nerdfonts.md_battery_70
        end
    elseif soc < 70 and soc > 59 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_60
        else
            icon = wezterm.nerdfonts.md_battery_60
        end
    elseif soc < 60 and soc > 49 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_50
        else
            icon = wezterm.nerdfonts.md_battery_50
        end
    elseif soc < 50 and soc > 39 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_40
        else
            icon = wezterm.nerdfonts.md_battery_40
        end
    elseif soc < 40 and soc > 29 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_30
        else
            icon = wezterm.nerdfonts.md_battery_30
        end
    elseif soc < 30 and soc > 19 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_20
        else
            icon = wezterm.nerdfonts.md_battery_20
        end
    elseif soc < 20 and soc > 9 then
        if state == "Charging" then
            icon = wezterm.nerdfonts.md_battery_charging_10
        else
            icon = wezterm.nerdfonts.md_battery_10
        end
    else
        icon = wezterm.nerdfonts.md_battery_alert
    end
    return icon, string.format('%.0f%%', soc)
end

return battery_status
