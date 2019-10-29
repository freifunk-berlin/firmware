local funcs = {}

function funcs.config_message(config, _, ...)
	config(...)
end

function funcs.config_package(config, pkg, value)
	io.stderr:write("config_package: " .. pkg .. "\n")
	config('CONFIG_PACKAGE_%s=%s', pkg, value)
end

local lib = dofile('scripts/target_config_lib.lua')(funcs)


local output = {}

for config in pairs(lib.configs) do
	io.stderr:write(config .. "\n")
	table.insert(output, config)
end

-- The sort will make =y entries override =m ones
table.sort(output)
for _, line in ipairs(output) do
	io.stdout:write(line, '\n')
end
