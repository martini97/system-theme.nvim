# system-theme.nvim

This plugin uses system D-Bus messages to automatically switch Neovim between
light and dark modes.

## Installation

Because this plugin depends on [Luarocks](https://luarocks.org/) packages, it's
recommended to install using [lazy.nvim](https://github.com/folke/lazy.nvim)
(version 11.x or later):

```lua
{
  "martini97/system-theme.nvim",
  dev = true,
  opts = {
    themes = { dark = "default", light = "peachpuff" },
    backgrounds = { dark = "light", light = "dark" },
    hooks = {
      dark = function() vim.print("its dark") end,
      light = function() vim.print("its light") end,
    },
  },
},
```

## Configuration

The configuration passed into the setup function follows this format:

```lua
{
  themes = {
    dark = "your-dark-theme",   -- which dark theme to use (default: "default")
    light = "your-light-theme", -- which light theme to use (default: "default")
  },
  backgrounds = {
    dark = "dark",   -- which 'background' to set for dark theme (:h 'background') (default: "dark")
    light = "light", -- which 'background' to set for light theme (:h 'background') (default: "light")
  },
  hooks = {
    dark = function()  -- function to be execute when switching to dark theme, takes no argument (default: noop)
      vim.print("its dark")
    end,
    light = function() -- function to be execute when switching to light theme, takes no argument (default: noop)
      vim.print("its light")
    end,
  },
  appearances = {
    ["0"] = "light", -- which appearance to use for xdg color-scheme="0" (default: "light")
    ["1"] = "dark",  -- which appearance to use for xdg color-scheme="1" (default: "dark")
    ["2"] = "light", -- which appearance to use for xdg color-scheme="2" (default: "light")
  },
}
```

## Usage

This plugin will try to stay out of your way.

If you need to terminate the thread processing system D-Bus messages, the
`:SystemThemeDbusKill` command is provided. This will prevent the plugin from
listening for system theme changes until Neovim is restarted.
