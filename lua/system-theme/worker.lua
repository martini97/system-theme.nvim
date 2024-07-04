local M = {}

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

---Run the dbus worker thread
---@return luv_thread_t? thread handle to the worker thread
---@return integer close_fd file descriptor used to stop the worker thread
function M.run()
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

    return vim.uv.new_thread(thread_func, package.path, package.cpath, fds.write, close_fds.read), close_fds.write
end

return M
