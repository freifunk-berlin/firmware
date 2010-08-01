--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id$

]]--


local uci = require "luci.model.uci".cursor()
local tools = require "luci.tools.ffwizard"
local util = require "luci.util"
local sys = require "luci.sys"
local ip = require "luci.ip"

local function mksubnet(community, meship)
	local subnet_prefix = tonumber(uci:get("freifunk", community, "splash_prefix")) or 27
	local pool_network = uci:get("freifunk", community, "splash_network") or "10.104.0.0/16"
	local pool = luci.ip.IPv4(pool_network)

	if pool then
		local hosts_per_subnet = 2^(32 - subnet_prefix)
		local number_of_subnets = (2^pool:prefix())/hosts_per_subnet

		local seed1, seed2 = meship:match("(%d+)%.(%d+)$")
		math.randomseed(seed1 * seed2)

		local subnet = pool:add(hosts_per_subnet * math.random(number_of_subnets))

		local subnet_ipaddr = subnet:network(subnet_prefix):add(1):string()
		local subnet_netmask = subnet:mask(subnet_prefix):string()

		return subnet_ipaddr, subnet_netmask
	end
end


-------------------- View --------------------
f = SimpleForm("ffwizward", "Freifunkassistent",
 "Dieser Assistent unterstüzt bei der Einrichtung des Routers für das Freifunknetz.")


main = f:field(Flag, "wifi", "Freifunkzugang über WLAN einrichten")

dev = f:field(ListValue, "device", "WLAN-Gerät")
dev:depends("wifi", "1")
uci:foreach("wireless", "wifi-device",
	function(section)
		dev:value(section[".name"])
	end)

net = f:field(Value, "net", "Freifunk Community", "Mesh WLAN Netzbereich")
net.rmempty = true
net:depends("wifi", "1")
uci:foreach("freifunk", "community", function(s)
	net:value(s[".name"], "%s (%s)" % {s.name, s.mesh_network or "?"})
end)

function net.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "net")
end
function net.write(self, section, value)
	uci:set("freifunk", "wizard", "net", value)
	uci:save("freifunk")
end

meship = f:field(Value, "meship", "Mesh WLAN IP Adresse", "Netzweit eindeutige Identifikation")
meship.rmempty = true
meship:depends("wifi", "1")
function meship.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "meship")
end
function meship.write(self, section, value)
	uci:set("freifunk", "wizard", "meship", value)
	uci:save("freifunk")
end
function meship.validate(self, value)
	local x = ip.IPv4(value)
	return ( x and x:prefix() == 32 ) and x:string() or ""
end

client = f:field(Flag, "client", "WLAN-DHCP anbieten")
client:depends("wifi", "1")
client.rmempty = false
function client.cfgvalue(self, section)
--	return uci:get("freifunk", "wizard", "dhcp_splash") or "0"
	return "0"
end
dhcpmeshsplash = f:field(Value, "dhcpmeshsplash", "Mesh WLAN-DHCP anbieten", "Netzweit eindeutiges DHCP Netz")
dhcpmeshsplash:depends("client", "1")
function dhcpmeshsplash.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "dhcp_mesh_splash")
end

olsr = f:field(Flag, "olsr", "OLSR einrichten")
olsr.rmempty = true

lat = f:field(Value, "lat", "Latitude")
lat:depends("olsr", "1")
function lat.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "latitude")
end
function lat.write(self, section, value)
	uci:set("freifunk", "wizard", "latitude", value)
	uci:save("freifunk")
end

lon = f:field(Value, "lon", "Longitude")
lon:depends("olsr", "1")
function lon.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "longitude")
end
function lon.write(self, section, value)
	uci:set("freifunk", "wizard", "longitude", value)
	uci:save("freifunk")
end

--[[
*Opens an OpenStreetMap iframe or popup
*Makes use of resources/OSMLatLon.htm and htdocs/resources/osm.js
(is that the right place for files like these?)
]]--

local class = util.class

OpenStreetMapLonLat = class(AbstractValue)

function OpenStreetMapLonLat.__init__(self, ...)
AbstractValue.__init__(self, ...)
self.template = "cbi/osmll_value"
self.latfield = nil
self.lonfield = nil
self.centerlat = "0"
self.centerlon = "0"
self.zoom = "0"
self.width = "100%" --popups will ignore the %-symbol, "100%" is interpreted as "100"
self.height = "600"
self.popup = false
self.displaytext="OpenStretMap" --text on button, that loads and displays the OSMap
self.hidetext="X" -- text on button, that hides OSMap
end

osm = f:field(OpenStreetMapLonLat, "latlon", "Geokoordinaten mit OpenStreetMap ermitteln:")
osm:depends("olsr", "1")
osm.latfield = "lat"
osm.lonfield = "lon"
osm.centerlat = uci:get("freifunk", "wizard", "latitude") or "52"
osm.centerlon = uci:get("freifunk", "wizard", "longitude") or "10"
osm.width = "100%"
osm.height = "600"
osm.popup = false
osm.zoom = "11"
osm.displaytext="OpenStreetMap anzeigen"
osm.hidetext="OpenStreetMap verbergen"

share = f:field(Flag, "sharenet", "Eigenen Internetzugang freigeben")
share.rmempty = true

wansec = f:field(Flag, "wansec", "WAN-Zugriff auf Gateway beschränken")
wansec.rmempty = false
wansec:depends("sharenet", "1")
function wansec.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "wan_security")
end
function wansec.write(self, section, value)
	uci:set("freifunk", "wizard", "wan_security", value)
	uci:save("freifunk")
end

lanmain = f:field(Flag, "lanolsr", "Freifunkzugang über LAN einrichten")
landev = f:field(ListValue, "landevice", "LAN-Gerät")
landev.rmempty = true
landev:depends("lanolsr", "1")
uci:foreach("network", "interface",
	function(section)
		if section[".name"] ~= "loopback" then
			landev:value(section[".name"])
		end
	end)

lanip = f:field(Value, "lanip", "Mesh LAN IP Adresse", "Netzweit eindeutige Identifikation")
lanip.rmempty = true
lanip:depends("lanolsr", "1")
function lanip.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "lanip")
end
function lanip.write(self, section, value)
	uci:set("freifunk", "wizard", "lanip", value)
	uci:save("freifunk")
end
function lanip.validate(self, value)
	local x = ip.IPv4(value)
	return ( x and x:prefix() == 32 ) and x:string() or ""
end
lanclient = f:field(Flag, "lanclient", "LAN-DHCP anbieten")
lanclient:depends("lanolsr", "1")
lanclient.rmempty = false
function lanclient.cfgvalue(self, section)
--	return uci:get("freifunk", "wizard", "landhcp_splash") or "0"
	return "0"
end
landhcpmeshsplash = f:field(Value, "landhcpmeshsplash", "Mesh LAN-DHCP anbieten", "Netzweit eindeutiges DHCP Netz")
landhcpmeshsplash:depends("lanclient", "1")
function landhcpmeshsplash.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "landhcp_mesh_splash")
end



-------------------- Control --------------------
function f.handle(self, state, data)
	if state == FORM_VALID then
		luci.http.redirect(luci.dispatcher.build_url("admin", "uci", "changes"))
		return false
	elseif state == FORM_INVALID then
		self.errmessage = "Ungültige Eingabe: Bitte die Formularfelder auf Fehler prüfen."
	end
	return true
end

local function _strip_internals(tbl)
	tbl = tbl or {}
	for k, v in pairs(tbl) do
		if k:sub(1, 1) == "." then
			tbl[k] = nil
		end
	end
	return tbl
end

-- Configure Freifunk checked
function main.write(self, section, value)
	if value == "0" then
		return
	end

	local device = dev:formvalue(section)
	local node_ip, external
	local netname = "wireless"
	local lannetname = "lan"
	local landevice = landev:formvalue(section)
	local lan_ip

	-- Collect IP-Address
	local community = net:formvalue(section)

	-- Invalidate fields
	if not community then
		net.tag_missing[section] = true
	else
		external = uci:get("freifunk", community, "external") or ""
		network = ip.IPv4(uci:get("freifunk", community, "mesh_network") or "104.0.0.0/8")
		node_ip = meship:formvalue(section) and ip.IPv4(meship:formvalue(section))
		lan_ip = lanip:formvalue(section) and ip.IPv4(lanip:formvalue(section))

		if not node_ip or not network or not network:contains(node_ip) then
			meship.tag_missing[section] = true
			node_ip = nil
		end
	end

	if not node_ip then return end


	-- Cleanup
	tools.wifi_delete_ifaces(device)
	tools.network_remove_interface(netname)
	tools.firewall_zone_remove_interface("freifunk", netname)
	if lan_ip then
		-- tools.network_remove_interface(lannetname)
		tools.firewall_zone_remove_interface("freifunk", lannetname) 
		uci:delete_all("firewall","zone", {name=lannetname})
		uci:delete_all("firewall","forwarding", {src=lannetname})
		uci:delete_all("firewall","forwarding", {dest=lannetname})
	end

	-- Tune community settings
	if community and uci:get("freifunk", community) then
		uci:tset("freifunk", "community", uci:get_all("freifunk", community))
	end

	-- Tune wifi device
	local devconfig = uci:get_all("freifunk", "wifi_device")
	util.update(devconfig, uci:get_all(external, "wifi_device") or {})
	uci:tset("wireless", device, devconfig)

	-- Create wifi iface
	local ifconfig = uci:get_all("freifunk", "wifi_iface")
	util.update(ifconfig, uci:get_all(external, "wifi_iface") or {})
	ifconfig.device = device
	ifconfig.network = netname
	ifconfig.ssid = uci:get("freifunk", community, "ssid")
	uci:section("wireless", "wifi-iface", nil, ifconfig)

	-- Save wifi
	uci:save("wireless")

	-- Create firewall zone and add default rules (first time)
	local newzone = tools.firewall_create_zone("freifunk", "REJECT", "ACCEPT", "REJECT", true)
	if newzone then
		uci:foreach("freifunk", "fw_forwarding", function(section)
			uci:section("firewall", "forwarding", nil, section)
		end)
		uci:foreach(external, "fw_forwarding", function(section)
			uci:section("firewall", "forwarding", nil, section)
		end)

		uci:foreach("freifunk", "fw_rule", function(section)
			uci:section("firewall", "rule", nil, section)
		end)
		uci:foreach(external, "fw_rule", function(section)
			uci:section("firewall", "rule", nil, section)
		end)
	end

	-- Enforce firewall include
	local has_include = false
	uci:foreach("firewall", "include",
		function(section)
			if section.path == "/etc/firewall.freifunk" then
				has_include = true
			end
		end)

	if not has_include then
		uci:section("firewall", "include", nil,
			{ path = "/etc/firewall.freifunk" })
	end

	-- Allow state: invalid packets
	uci:foreach("firewall", "defaults",
		function(section)
			uci:set("firewall", section[".name"], "drop_invalid", "0")
		end)

	-- Prepare advanced config
	local has_advanced = false
	uci:foreach("firewall", "advanced",
		function(section) has_advanced = true end)

	if not has_advanced then
		uci:section("firewall", "advanced", nil,
			{ tcp_ecn = "0", ip_conntrack_max = "8192", tcp_westwood = "1" })
	end

	uci:save("firewall")


	-- Create network interface
	local netconfig = uci:get_all("freifunk", "interface")
	util.update(netconfig, uci:get_all(external, "interface") or {})
	netconfig.proto = "static"
	netconfig.ipaddr = node_ip:string()
	uci:section("network", "interface", netname, netconfig)
	uci:save("network")
	tools.firewall_zone_add_interface("freifunk", netname)
	uci:save("firewall")
	if lan_ip then
		local lannetconfig = uci:get_all("freifunk", "interface")
		util.update(lannetconfig, uci:get_all(external, "interface") or {})
		lannetconfig.proto = "static"
		lannetconfig.ipaddr = lan_ip:string()
		uci:section("network", "interface", lannetname, lannetconfig)
		uci:save("network")
		tools.firewall_zone_add_interface("freifunk", lannetname)
		uci:save("firewall")
	end

	local new_hostname = node_ip:string():gsub("%.", "-")
	local old_hostname = sys.hostname()

	uci:foreach("system", "system",
		function(s)
			-- Make crond silent
			uci:set("system", s['.name'], "cronloglevel", "10")

			-- Set hostname
			if old_hostname == "OpenWrt" or old_hostname:match("^%d+-%d+-%d+-%d+$") then
				uci:set("system", s['.name'], "hostname", new_hostname)
				sys.hostname(new_hostname)
			end
		end)

	uci:save("system")
end


function olsr.write(self, section, value)
	if value == "0" then
		return
	end


	local device = dev:formvalue(section)
	local netname = "wireless"
	local lannetname = "lan"
	local community = net:formvalue(section)
	local external  = community and uci:get("freifunk", community, "external") or ""
	local landevice = landev:formvalue(section)

	local latval = tonumber(lat:formvalue(section))
	local lonval = tonumber(lon:formvalue(section))


	-- Delete old interface
	uci:delete_all("olsrd", "Interface")
--	if landevice then uci:delete_all("olsrd", "Interface", {interface=lannetname}) end
	uci:delete_all("olsrd", "Hna4")

	-- Write new interface
	local olsrbase = uci:get_all("freifunk", "olsr_interface")
	util.update(olsrbase, uci:get_all(external, "olsr_interface") or {})
	olsrbase.interface = netname
	olsrbase.ignore    = "0"
	uci:section("olsrd", "Interface", nil, olsrbase)
	if landevice then
		local lanolsrbase = uci:get_all("freifunk", "olsr_interface")
		util.update(lanolsrbase, uci:get_all(external, "olsr_interface") or {})
		lanolsrbase.interface = lannetname
		lanolsrbase.ignore    = "0"
		uci:section("olsrd", "Interface", nil, lanolsrbase)
	else
		uci:delete_all("olsrd", "Interface", {interface=lannetname})
	end

	-- Delete old watchdog settings
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_watchdog.so.0.1"})

	-- Write new watchdog settings
	uci:section("olsrd", "LoadPlugin", nil, {
		library  = "olsrd_watchdog.so.0.1",
		file     = "/var/run/olsrd.watchdog",
		interval = "30"
	})

	-- Delete old nameservice settings
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_nameservice.so.0.3"})

	-- Write new nameservice settings
	uci:section("olsrd", "LoadPlugin", nil, {
		library     = "olsrd_nameservice.so.0.3",
		suffix      = ".olsr",
		hosts_file  = "/var/etc/hosts.olsr",
		latlon_file = "/var/run/latlon.js",
		lat         = latval and string.format("%.15f", latval) or "",
		lon         = lonval and string.format("%.15f", lonval) or ""
	})

	-- Save latlon to system too
	if latval and lonval then
		uci:foreach("system", "system", function(s)
			uci:set("system", s[".name"], "latlon",
				string.format("%.15f %.15f", latval, lonval))
		end)
	else
		uci:foreach("system", "system", function(s)
			uci:delete("system", s[".name"], "latlon")
		end)
	end
	-- Collect MESH DHCP IP NET
	local splashnet = dhcpmeshsplash:formvalue(section) and ip.IPv4(dhcpmeshsplash:formvalue(section))
	-- Write new HNA4 dhcp settings
	if splashnet then
		local splash_mask = splashnet:mask():string()
		local splash_network = splashnet:network():string()
		uci:section("olsrd", "Hna4", nil, {
		    netmask  = splash_mask,
		    netaddr  = splash_network
		})
	end
	if landevice then
		local lansplashnet = landhcpmeshsplash:formvalue(section) and ip.IPv4(landhcpmeshsplash:formvalue(section))
		-- Write new HNA4 dhcp settings
		if lansplashnet then
			local lansplash_mask = lansplashnet:mask():string()
			local lansplash_network = lansplashnet:network():string()
			uci:section("olsrd", "Hna4", nil, {
				netmask  = lansplash_mask,
				netaddr  = lansplash_network
			})
		end
	end

	-- Import hosts
	uci:foreach("dhcp", "dnsmasq", function(s)
		uci:set("dhcp", s[".name"], "addnhosts", "/var/etc/hosts.olsr")
	end)

	-- Make sure that OLSR is enabled
	sys.exec("/etc/init.d/olsrd enable")

	uci:save("olsrd")
	uci:save("dhcp")
end


function share.write(self, section, value)
	uci:delete_all("firewall", "forwarding", {src="freifunk", dest="wan"})
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw_plain.so.0.4"})
	uci:foreach("firewall", "zone",
		function(s)		
			if s.name == "wan" then
				uci:delete("firewall", s['.name'], "local_restrict")
				return false
			end
		end)

	if value == "1" then
		uci:section("firewall", "forwarding", nil, {src="freifunk", dest="wan"})
		uci:section("olsrd", "LoadPlugin", nil, {library="olsrd_dyn_gw_plain.so.0.4"})

		if wansec:formvalue(section) == "1" then
			uci:foreach("firewall", "zone",
				function(s)		
					if s.name == "wan" then
						uci:set("firewall", s['.name'], "local_restrict", "1")
						return false
					end
				end)
		end
	end

	uci:save("firewall")
	uci:save("olsrd")
	uci:save("system")
end


function client.write(self, section, value)
	if value == "0" then
		uci:delete("freifunk", "wizard", "dhcp_splash")
		uci:save("freifunk")
		return
	end
	local device = dev:formvalue(section)
	local netname = "wireless"
	local lannetname = "lan"

	-- Collect IP-Address
	local node_ip = meship:formvalue(section)
	local lan_ip = lanip:formvalue(section)
	local landevice = landev:formvalue(section)

	if not node_ip then return end

	-- Collect MESH DHCP IP NET
	local splashnet = dhcpmeshsplash:formvalue(section) and ip.IPv4(dhcpmeshsplash:formvalue(section))
	--if landevice then local 
	lansplashnet = landhcpmeshsplash:formvalue(section) and ip.IPv4(landhcpmeshsplash:formvalue(section))
	--end

	local community = net:formvalue(section)
	local external  = community and uci:get("freifunk", community, "external") or ""
	local splash_ip, splash_mask = mksubnet(community, node_ip)
	if splashnet then
		splash_ip = splashnet:minhost():string()
		splash_mask = splashnet:mask():string()
		uci:set("freifunk", "wizard", "dhcp_mesh_splash", splashnet:string())
		uci:save("freifunk")
	else
		splash_ip, splash_mask = mksubnet(community, node_ip)
		uci:delete("freifunk", "wizard", "dhcp_mesh_splash")
		uci:save("freifunk")
	end
	if lansplashnet then
		lansplash_ip = lansplashnet:minhost():string()
		lansplash_mask = lansplashnet:mask():string()
		uci:set("freifunk", "wizard", "landhcp_mesh_splash", lansplashnet:string())
		uci:save("freifunk")
	else
		lansplash_ip, lansplash_mask = mksubnet(community, lan_ip)
		uci:delete("freifunk", "wizard", "landhcp_mesh_splash")
		uci:save("freifunk")
	end

	-- Delete old alias
	uci:delete("network", netname .. "dhcp")
	if lansplashnet then uci:delete("network", lannetname .. "dhcp") end

	-- Create alias
	local aliasbase = uci:get_all("freifunk", "alias")
	util.update(aliasbase, uci:get_all(external, "alias") or {})
	aliasbase.interface = netname
	aliasbase.ipaddr = splash_ip
	aliasbase.netmask = splash_mask
	aliasbase.proto = "static"
	uci:section("network", "alias", netname .. "dhcp", aliasbase)
	uci:save("network")
	if lansplashnet then
		local lanaliasbase = uci:get_all("freifunk", "alias")
		util.update(lanaliasbase, uci:get_all(external, "alias") or {})
		lanaliasbase.interface = lannetname
		lanaliasbase.ipaddr = lansplash_ip
		lanaliasbase.netmask = lansplash_mask
		lanaliasbase.proto = "static"
		uci:section("network", "alias", lannetname .. "dhcp", lanaliasbase)
		uci:save("network")
	end

	-- Create dhcp
	local dhcpbase = uci:get_all("freifunk", "dhcp")
	util.update(dhcpbase, uci:get_all(external, "dhcp") or {})
	dhcpbase.interface = netname .. "dhcp"
--	dhcpbase.start = dhcpbeg
--	dhcpbase.limit = limit
	dhcpbase.force = 1
	uci:section("dhcp", "dhcp", netname .. "dhcp", dhcpbase)
	uci:save("dhcp")
	if lansplashnet then
		local landhcpbase = uci:get_all("freifunk", "dhcp")
		util.update(landhcpbase, uci:get_all(external, "dhcp") or {})
		landhcpbase.interface = lannetname .. "dhcp"
--		landhcpbase.start = dhcpbeg
--		landhcpbase.limit = limit
		landhcpbase.force = 1
		uci:section("dhcp", "dhcp", lannetname .. "dhcp", landhcpbase)
		uci:save("dhcp")
	end


	uci:delete_all("firewall", "rule", {
		src="freifunk",
		proto="udp",
		dest_port="53"
	})
	uci:section("firewall", "rule", nil, {
		src="freifunk",
		proto="udp",
		dest_port="53",
		target="ACCEPT"
	})
	uci:delete_all("firewall", "rule", {
		src="freifunk",
		proto="udp",
		src_port="68",
		dest_port="67"
	})
	uci:section("firewall", "rule", nil, {
		src="freifunk",
		proto="udp",
		src_port="68",
		dest_port="67",
		target="ACCEPT"
	})
	uci:delete_all("firewall", "rule", {
		src="freifunk",
		proto="tcp",
		dest_port="8082",
	})
	uci:section("firewall", "rule", nil, {
		src="freifunk",
		proto="tcp",
		dest_port="8082",
		target="ACCEPT"
	})

	uci:save("firewall")

	-- Delete old splash
	uci:delete_all("luci_splash", "iface", {network=netname.."dhcp", zone="freifunk"})
	if lansplashnet then uci:delete_all("luci_splash", "iface", {network=lannetname.."dhcp", zone="freifunk"}) end

	-- Register splash
	uci:section("luci_splash", "iface", nil, {network=netname.."dhcp", zone="freifunk"})
	uci:save("luci_splash")
	if lansplashnet then
		uci:section("luci_splash", "iface", nil, {network=lannetname.."dhcp", zone="freifunk"})
		uci:save("luci_splash")
	end
	-- Make sure that luci_splash is enabled
	sys.exec("/etc/init.d/luci_splash enable")

	-- Remember state
	uci:set("freifunk", "wizard", "dhcp_splash", "1")
	uci:save("freifunk")
end

return f
