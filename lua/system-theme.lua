local worker = require("system-theme.worker")
local config = require("system-theme.config")

local M = {}

local kill_cmd = "SystemThemeDbusKill"

---Setup system theme
---@param opts system_theme.Config?
function M.setup(opts)
	config.setup(opts)

	pcall(vim.api.nvim_command, kill_cmd)

	local thread, close_fd = worker.run()

	vim.api.nvim_create_user_command(kill_cmd, function()
		if thread ~= nil then
			local stop = vim.uv.new_pipe()
			stop:open(close_fd)

			stop:write("stop")
			thread:join()
			print("Dbus thread terminated.")
			vim.api.nvim_del_user_command(kill_cmd)
		else
			print("no thread to shutdown")
		end
	end, {})
end

return M
