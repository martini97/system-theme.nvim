local M = {}

---@param data system_theme.XDGAppearance
---@param config system_theme.Config
---@return { theme?: string, background?: system_theme.VimAppearance, hook?: fun() }
function M.get_appearance_config(data, config)
	---@type system_theme.VimAppearance
	local appearance = config.appearances[data]
	assert(appearance, "failed to determine background appearance for xdg color-scheme " .. data)

	return {
		theme = config.themes[appearance],
		background = config.backgrounds[appearance],
		hook = config.hooks[appearance],
	}
end

---Creates a libuv pipe
function M.mk_pipe()
	return assert(vim.uv.pipe(), "failed to create pipe")
end

return M
