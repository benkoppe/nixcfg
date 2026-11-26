-- Keeps a session saved and reports `nvim -S <session>` to Rex over OSC 7577.

local token = vim.env.OSC7577_TOKEN
-- Keep child processes from reporting in our place.
vim.env.OSC7577_TOKEN = nil
if not token then
	return
end

-- Trusted by resume.lua. Separate from persistence.nvim's sessions.
local dir = vim.fn.stdpath("state") .. "/rex-resume"
vim.fn.mkdir(dir, "p")

-- Drop sessions left behind for 30 days.
for name in vim.fs.dir(dir) do
	local path = dir .. "/" .. name
	local stat = vim.uv.fs_stat(path)
	if stat and os.time() - stat.mtime.sec > 30 * 24 * 60 * 60 then
		os.remove(path)
	end
end

-- "nvim" or "v".
local program = vim.fs.basename(vim.v.argv[1])
local file

local function save()
	pcall(vim.cmd.mksession, { vim.fn.fnameescape(file), bang = true })
end

local function report()
	local argv = table.concat(vim.tbl_map(vim.base64.encode, { program, "-S", file }), ",")
	-- Our parent is the TUI, which Rex resumes.
	local body = ("pid=%d:time=%d:argv=%s"):format(vim.uv.os_getppid(), os.time(), argv)
	local mac = vim.fn.sha256(body .. ":" .. token)
	vim.api.nvim_ui_send(("\27]7577;%s:mac=%s\27\\"):format(body, mac))
end

local group = vim.api.nvim_create_augroup("rex-resume", {})

vim.api.nvim_create_autocmd("UIEnter", {
	group = group,
	once = true,
	callback = function()
		-- Keep the session we were resumed from. this_session is symlink-resolved.
		local resumed = vim.v.this_session
		if resumed ~= "" and vim.fs.dirname(resumed) == vim.uv.fs_realpath(dir) then
			file = dir .. "/" .. vim.fs.basename(resumed)
		else
			file = ("%s/%d-%d.vim"):format(dir, os.time(), vim.fn.getpid())
		end
		save()
		report()

		local timer = vim.uv.new_timer()
		vim.api.nvim_create_autocmd({ "BufEnter", "WinClosed", "TabClosed", "DirChanged" }, {
			group = group,
			callback = function()
				timer:start(1000, 0, vim.schedule_wrap(save))
			end,
		})

		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = group,
			callback = function()
				-- A UI means the user quit; without one the terminal died.
				if #vim.api.nvim_list_uis() > 0 then
					timer:stop()
					os.remove(file)
				end
			end,
		})
	end,
})
