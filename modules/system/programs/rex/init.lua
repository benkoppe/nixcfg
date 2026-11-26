-- Rex config shared by every machine, installed by nixcfg.
-- for local machine config.make a local.lua file

-- Check that local.lua exists on the machine before importing it.
local function exists(module)
	for pattern in package.path:gmatch("[^;]+") do
		local file = io.open((pattern:gsub("%?", module)), "r")
		if file then
			file:close()
			return true
		end
	end
	return false
end

if exists("local") then
	require("local")
end
