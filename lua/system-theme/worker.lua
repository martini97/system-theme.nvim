local M = {}

local cfg = require("system-theme.config")
local utils = require("system-theme.utils")

---Main worker for dbus events
---@param new_pkg_path string
---@param cpath string
---@param pipe_fd integer fd for write side of pipe for theme changes
---@param close_pipe integer fd for pipe to signal worker shutdown
local function thread_func(new_pkg_path, cpath, pipe_fd, close_pipe)
	package.path = new_pkg_path
	package.cpath = cpath
	local p = require("dbus_proxy")
	local GLib = require("lgi").GLib

	local pipe = vim.uv.new_pipe()
	pipe:open(pipe_fd)

	local proxy = p.Proxy:new({
		bus = p.Bus.SESSION,
		name = "org.freedesktop.portal.Desktop",
		path = "/org/freedesktop/portal/desktop",
		interface = "org.freedesktop.portal.Settings",
	})

	proxy:connect_signal(function(pxy, ns, k, v)
		assert(pxy == proxy)
		if ns == "org.freedesktop.appearance" and k == "color-scheme" then
			pipe:write(v)
		end
	end, "SettingChanged")

	do
		-- Get initial theme
		local ok, _ = proxy:ReadOne("org.freedesktop.appearance", "color-scheme")
		if ok then
			pipe:write(ok)
		end
	end

	local main_loop = GLib.MainLoop()

	-- Wait for event on the close_pipe
	local io_chan = GLib.IOChannel.unix_new(close_pipe)
	GLib.io_add_watch(io_chan, GLib.PRIORITY_DEFAULT, "IN", function()
		main_loop:quit()
	end)

	main_loop:run()
end

---@param err? string
---@param data? system_theme.XDGAppearance
local function on_appearance_change(err, data)
	assert(err == nil or err == "", err)
	assert(data and data ~= "", "no appearance detected")

	if vim.in_fast_event() then
		vim.schedule(function()
			on_appearance_change(err, data)
		end)
		return
	end

	local config = utils.get_appearance_config(data, cfg.get())

	if config.theme then
		vim.cmd.colorscheme(config.theme)
	end

	if config.background then
		vim.opt.background = config.background
	end

	if config.hook and type(config.hook) == "function" then
		local ok, hook_err = pcall(config.hook)
		if not ok then
			vim.notify(
				string.format("[system-theme] failed to execute hook for '%s' with error: %s", data, hook_err),
				vim.log.levels.ERROR
			)
		end
	end
end

---Run the dbus worker thread
---@return luv_thread_t? thread handle to the worker thread
---@return integer close_fd file descriptor used to stop the worker thread
function M.run()
	local fds = utils.mk_pipe()
	local close_fds = utils.mk_pipe()
	local pipe = vim.uv.new_pipe()

	pipe:open(fds.read)
	pipe:read_start(on_appearance_change)

	return vim.uv.new_thread(thread_func, package.path, package.cpath, fds.write, close_fds.read), close_fds.write
end

return M
