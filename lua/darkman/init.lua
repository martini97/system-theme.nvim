local M = {}

---Main worker for dbus events
---@param new_pkg_path string
---@param cpath string
---@param pipe_fd integer fd for write side of pipe for theme changes
---@param close_pipe integer fd for pipe to signal worker shutdown
local function worker(new_pkg_path, cpath, pipe_fd, close_pipe)
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

function M.setup()
    ---@type luv_thread_t?
    local thread

    local _ = pcall(vim.api.nvim_command, "DarkmanKill")

    local fds = vim.uv.pipe()
    assert(fds ~= nil)

    local close_fds = vim.uv.pipe()
    assert(close_fds ~= nil)

    local pipe = vim.uv.new_pipe()
    pipe:open(fds.read)
    pipe:read_start(function(err, data)
        assert(not err, err)
        vim.schedule(function()
            if data == "1" then
                vim.cmd("colorscheme sunburn")
            elseif data == "2" then
                vim.cmd("colorscheme base16-unikitty-light")
            end
        end)
    end)

    thread = vim.uv.new_thread(worker, package.path, package.cpath, fds.write, close_fds.read)

    vim.api.nvim_create_user_command("DarkmanKill", function()
        if thread ~= nil then
            local stop = vim.uv.new_pipe()
            stop:open(close_fds.write)

            stop:write("stop")
            thread:join()
            print("Dbus thread terminated.")
            vim.api.nvim_del_user_command("DarkmanKill")
        else
            print("no thread to shutdown")
        end
    end, {})
end

return M
