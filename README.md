# My wezterm configuration
## I've found how flexible wezterm is and decided to try to have some fun with it. I've just scratched the surface of what wezterm can do, but it's been a lot of fun learning.

## Requirements
* wezterm on either Darwin or Linux. I don't have a Windows computer to test on.
* If you want system status in the title bar, please download and build [wsstats](https://github.com/gdanko/wsstats).

## Installation
Clone the repository at the root of ~/.config. Pro tip, I use Dropbox so I can use the same config across multiple computers.

## Features
* Generic default config that is pulled when wezterm is started.
* Ability to override defaults on a per-hostname basis. `parse-config.lua` looks for `overrides.lua` and parses the overrides. Simply copy overrides.lua.SAMPLE to overrides.lua to use it. Any time you update the overrides file, WezTerm will re-read everything.
* iTerm2 color schemes (yes I know it's there by default) with the ability to randomize the scheme on configuration reload. Please see this [repo](https://github.com/gdanko/iterm-color-to-gnome-terminal).
* Tab title can be process name (default) or cwd.
* Fancy status bar stuff.

### Status Bar Features
* Battery percentage
* Clock
* Stock quotes
* Git branch information for paths that are repositories
* System stats
  * Uptime
  * CPU Usage
  * Load Averages
  * Memory Usage
  * Disk Usage
  * Network Throughput
  * WiFi Signal Strength (Linux only)
* System update count (currently MacOS, Alpine, Arch, CentOS, Debian, Fedora, Ubuntu)
* Weather, with optional low/high (requires OpenWeatherMap API key)

## To-Do
* Alphabetize the stocks in the status bar. They're rendered out of order sometimes.
* Other stuff
