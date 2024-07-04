# system-theme.nvim

This plugin uses system D-Bus messages to automatically switch Neovim between
light and dark modes.

## Installation

Because this plugin depends on [Luarocks](https://luarocks.org/) packages, it's
recommended to install using [lazy.nvim](https://github.com/folke/lazy.nvim)
(version 11.x or later):

```lua
{
    "cosmicboots/system-theme.nvim",
    config = {
        dark_theme = "sorbet",
        light_theme = "morning",
    },
}
```

## Configuration

The configuration passed into the setup function follows this format:
```lua
{
    light_theme = "your-light-theme", -- Light theme to use
    dark_theme = "your-dark-theme", -- Dark theme to use
    hooks = {
        light = function()
            -- This is run after the light theme is applied
        end,
        dark = function()
            -- This is run after the dark theme is applied
        end,
    },
}
```

All settings are optional. If `light_theme` or `dark_theme`
aren't set, the global vim variables `g:light_theme` and
`g:dark_theme` will be used, respectively.

## Usage

This plugin will try to stay out of your way.

If you need to terminate the thread processing system D-Bus messages, the
`:SysThemeDbusKill` command is provided. This will prevent the plugin from
listening for system theme changes until Neovim is restarted.

