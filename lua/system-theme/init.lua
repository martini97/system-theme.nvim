local worker = require("system-theme.worker")

local M = {}

local kill_cmd = "SysThemeDbusKill"

---@class ThemeHooks
---@field light function
---@field dark function

---@class SystemThemeConfig
---@field light_theme string?
---@field dark_theme string?
---@field hooks ThemeHooks?

---Setup system theme
---@param opts SystemThemeConfig?
function M.setup(opts)
    ---@type SystemThemeConfig
    local config = opts or {}

    local _ = pcall(vim.api.nvim_command, kill_cmd)

    local thread, close_fd = worker.run(config)

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
