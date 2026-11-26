-- Older Rex servers have no resume rules.
if not rex.match then
	return
end

-- Reported by opencode-plugin/. Replaces the built-in rule to keep --auto.
rex.set("resume.trust.opencode", {
	command = { "opencode", "--session", rex.match.id },
	flags = {
		["--auto"] = "keep",
		["--session"] = { "drop", values = 1 },
		["-s"] = { "drop", values = 1 },
		["--continue"] = "drop",
		["-c"] = "drop",
		["--prompt"] = { "drop", values = 1 },
	},
})

-- Reported by nvim-plugin/, for sessions it saves.
for _, program in ipairs({ "nvim", "v" }) do
	rex.set("resume.trust." .. program, {
		command = { program, "-S", rex.match.under("~/.local/state/nvim/rex-resume") },
	})
end
