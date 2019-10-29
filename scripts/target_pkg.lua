local funcs = {}

function funcs.config_message(config, _, ...)
	config(...)
end

local lib = dofile('scripts/target_pkg_lib.lua')(funcs)
