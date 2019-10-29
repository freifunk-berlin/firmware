return function(funcs)
	local lib = dofile('scripts/target_lib.lua')
	local env = lib.env

	assert(env.BOARD)
	assert(env.SUBTARGET)

	local target = arg[1]
	local extra_packages = arg[2]

	local function site_packages(image)
		return lib.exec_capture_raw(string.format([[
	MAKEFLAGS= make print _GLUON_IMAGE_=%s --no-print-directory -s -f - <<'END_MAKE'
include $(GLUON_SITEDIR)/site.mk

print:
	echo -n '$(GLUON_$(_GLUON_IMAGE_)_SITE_PACKAGES)'
END_MAKE
		]], lib.escape(image)))
	end

	lib.include('generic')
	if env.GLUON_FWTYPE == 'gluon' then
		lib.include('generic_gluon')
	elseif env.GLUON_FWTYPE == 'ffberlin' then
		lib.include('generic_ffberlin')
	end
	for pkg in string.gmatch(extra_packages, '%S+') do
		lib.packages {pkg}
	end
	lib.include(target)


	if not lib.opkg then
		lib.packages {'-opkg'}
	end


	local default_pkgs = ''
	for _, pkg in ipairs(lib.target_packages) do
		default_pkgs = default_pkgs .. ' ' .. pkg

	end

--	local cjson = require "cjson"
	local pkg_list = {}
--	local pkg_list_json
	for _, dev in ipairs(lib.devices) do
		local profile = dev.options.profile or dev.name
		local device_pkgs = default_pkgs

		local function handle_pkg(pkg)
			device_pkgs = device_pkgs .. ' ' .. pkg
		end

		for _, pkg in ipairs(dev.options.packages or {}) do
			handle_pkg(pkg)
		end
		for pkg in string.gmatch(site_packages(dev.image), '%S+') do
			handle_pkg(pkg)
		end

		if env.GLUON_FWTYPE == 'ffberlin' then
--			io.stderr:write(string.format("additional packages for board %s: %s\n", profile, device_pkgs))
--			package_list = io.open(string.format("%s/%s.packages", env.GLUON_TMPDIR, profile), "w")
--			package_list:write(device_pkgs)
--			package_list:close()
			pkg_list[profile] = device_pkgs
--			pkg_list_json = cjson.encode(pkg_list)
			io.stdout:write(string.format("%s:%s\n", profile, device_pkgs))
		end
	end
--	io.stdout:write("pkg-json:" .. pkg_list_json .. "\n")
--	io.stdout:write("pkg-json:" .. cjson.encode(pkg_list) .. "\n")

	return lib
end
