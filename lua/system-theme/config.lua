local M = {}

local function noop() end

---@alias system_theme.XDGAppearance
---| '"0"' # No preference or unknown
---| '"1"' # Prefer dark appearance
---| '"2"' # Prefer light appearance

---@alias system_theme.VimAppearance
---| '"dark"'
---| '"light"'

---@class system_theme.Themes
---@field [system_theme.VimAppearance] string

---@class system_theme.Backgrounds
---@field [system_theme.VimAppearance] system_theme.VimAppearance

---@class system_theme.Hooks
---@field [system_theme.VimAppearance] fun()

---@class system_theme.Appearances
---@field [system_theme.XDGAppearance] system_theme.VimAppearance

---@class system_theme.Config
---@field themes system_theme.Themes
---@field backgrounds system_theme.Backgrounds
---@field hooks system_theme.Hooks
---@field appearances system_theme.Appearances

---@type system_theme.Config
M._defaults = {
	themes = { dark = "default", light = "default" },
	backgrounds = { dark = "dark", light = "light" },
	hooks = { dark = noop, light = noop },
	appearances = { ["0"] = "light", ["1"] = "dark", ["2"] = "light" },
}

---@type system_theme.Config
M._config = {} ---@diagnostic disable-line: missing-fields

---@param config? system_theme.Config
function M.setup(config)
	M._config = vim.tbl_deep_extend("force", M._defaults, M._config, config or {})
end

---@return system_theme.Config
function M.get()
	assert(not vim.tbl_isempty(M._config), "config.setup() must be called first")
	return M._config
end

return M
