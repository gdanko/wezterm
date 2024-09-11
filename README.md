# My wezterm configuration
## I've found how flexible wezterm is and decided to try to have some fun with it. I've just scratched the surface of what wezterm can do, but it's been a lot of fun learning.

## Requirements
* wezterm on either Darwin or Linux. I don't have a Windows computer to test on.

## Installation
Clone the repository at the root of ~/.config.

## Features
* Generic default config that is pulled when wezterm is started.
* Ability to override defaults via an overrides file. `parse-config.lua` looks for `overrides.lua` and parses the overrides. Simply copy overrides.lua.SAMPLE to overrides.lua to use it. Any time you update the overrides file, WezTerm will reload everything.
* iTerm2 color schemes (yes I know it's there by default) with the ability to randomize the scheme on configuration reload. Please see this [repo](https://github.com/gdanko/iterm-color-to-gnome-terminal).
* Tab title can be process name (default) or cwd.
* Fancy status bar stuff.

### Status Bar Features
* Battery percentage
* Clock
* Stock quotes
* System stats
  * Uptime
  * CPU Usage
  * Load Averages
  * Memory Usage
  * Disk Usage
  * Network Throughput
  * WiFi Signal Strength
* Weather (this requires a free weatherapi.com API key)

## To-Do
* Other stuff
