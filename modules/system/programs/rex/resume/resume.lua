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
