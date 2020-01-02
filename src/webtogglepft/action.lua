local io = require 'io'
local config = require 'webtogglepft.config'

local M = {}

function M.preprocess_cmd(cmd, ip, allow_bool)
    if type(cmd) == 'string' then
	return string.gsub(cmd, '%%h', ip)
    elseif type(cmd) == 'function' then
	cmd = cmd(ip)
	if type(cmd) == 'string' then
	    return cmd
	end
	if allow_bool and type(cmd) == 'boolean' then
	    return cmd
	end
    end
    return nil
end

function M.check_ip(ip)
    local cmd = M.preprocess_cmd(config.ip_prog_check, ip, true)
    if cmd == nil then
	error('Server could not determine how to execute program to check your IP address.')
    end
    if cmd == true or cmd == false then
	return cmd
    end
    local check_success = M.preprocess_cmd(config.ip_prog_check_success, ip)
    if check_success == nil then
	error('Server could not determine how to evaluate output from program that checks your IP address.')
    end

    local handle = io.popen(cmd, 'r')
    if not handle then
	error('Server could not run program to check your IP address.')
    end
    local output = handle:read('*all')
    handle:close()

    if string.match(output, check_success) then
	return true
    else
	return false
    end
end

function M.add_host(ip)
    local cmd = M.preprocess_cmd(config.ip_prog_add, ip, false)
    if cmd == nil then
	error('Server could not determine how to execute program to remove your IP address.')
    end

    local handle = io.popen(cmd, 'r')
    if not handle then
	error('Server could not run program to check your IP address.')
    end
    local output = handle:read('*all')
    handle:close()

    print(output)
end

function M.remove_host(ip)
    local cmd = M.preprocess_cmd(config.ip_prog_remove, ip, false)
    if cmd == nil then
	error('Server could not determine how to execute program to add your IP address.')
    end

    local handle = io.popen(cmd, 'r')
    if not handle then
	error('Server could not run program to check your IP address.')
    end
    local output = handle:read('*all')
    handle:close()

    print(output)
end

local function check_netmask(ipcomponent, compare, bitlen)
    if type(ipcomponent) == 'number' and type(compare) == 'number' and type(bitlen) == 'number' then
        local lower = 2 ^ (32-bitlen)
	local excess = compare % lower
	local min = compare - excess
	local max = min + lower - 1
	return ipcomponent >= min and ipcomponent <= max
    end
    return false
end

local function check_ip(myip, otherip, netmask)
    netmask = netmask and (netmask+0) or 32
    if netmask >= 32 then
	return myip == otherip
    end
    return check_netmask(myip, otherip, netmask)
end

local function ip2num(ip1, ip2, ip3, ip4)
    ip1, ip2, ip3, ip4 = ip1+0, ip2+0, ip3+0, ip4+0
    if ip1 < 255 and ip2 < 255 and ip3 < 255 and ip4 < 255 then
	return (ip1 * 2^24) + (ip2 * 2^16) + (ip3 * 2^8) + ip4
    end
end

function M.check_allowed_ip(ip)
    local checktype = type(config.allowed_ips)
    if checktype == 'string' then
	local myip = ip2num(string.match(ip, '(%d+)%.(%d+)%.(%d+)%.(%d+)'))
	for ip1, ip2, ip3, ip4, divisor, netmask in string.gmatch(config.allowed_ips, '%f[%d](%d+)%.(%d+)%.(%d+)%.(%d+)(/?)(%d*)') do
	    local otherip = ip2num(ip1, ip2, ip3, ip4)
	    if divisor ~= '/' or netmask == '' then
		netmask = nil
	    end
	    if check_ip(myip, otherip, netmask) then
		return true
	    end
	end
	return false
    elseif checktype == 'function' then
	return config.allowed_ips(ip)
    end
    return true
end

function M.render_get(req, res)
    local skt = res.socket
    local ip = skt:getpeername()
    if type(ip) ~= "string" then
	error("Could not find IP of connecting host")
    end
    if not M.check_allowed_ip(ip) then
	return M.render_disallowed_host(req, res, ip)
    end

    if M.check_ip(ip) then
	return M.render_added_host(req, res, ip)
    else
	return M.render_missing_host(req, res, ip)
    end
end

function M.handle_post_data(req, res, post)
    local skt = res.socket
    local ip = skt:getpeername()
    if type(ip) ~= "string" then
	error("Could not find IP of connecting host")
    end
    if string.find(post, 'add=0', 1, true) then
	M.remove_host(ip)
    elseif string.find(post, 'add=1', 1, true) then
	M.add_host(ip)
    end

    return M.render_get(req, res)
end

function M.render_disallowed_host(req, res, ip)
    return {
	'<!DOCTYPE html>',
	'<html>',
	'<head>',
	'<title>',
	config.html_title,
	'</title>',
	'</head>',
	'<body>',
	'<p>',
	M.preprocess_cmd(config.text_disallowed_host, ip),
	'</p>',
	'</body>',
	'</html>'
    }
end

function M.render_added_host(req, res, ip)
    return {
	'<!DOCTYPE html>',
	'<html>',
	'<head>',
	'<title>',
	config.html_title,
	'</title>',
	'</head>',
	'<body>',
	'<p>',
	M.preprocess_cmd(config.text_added_host, ip),
	'</p>',
	'<p>',
	'<form method="post">',
	'<input type="submit" value="Remove me" />',
	'<input type="hidden" name="add" value="0" />',
	'</form>',
	'</p>',
	'</body>',
	'</html>'
    }
end

function M.render_missing_host(req, res, ip)
    return {
	'<!DOCTYPE html>',
	'<html>',
	'<head>',
	'<title>',
	config.html_title,
	'</title>',
	'</head>',
	'<body>',
	'<p>',
	M.preprocess_cmd(config.text_missing_host, ip),
	'</p>',
	'<p>',
	'<form method="post">',
	'<input type="submit" value="Add me" />',
	'<input type="hidden" name="add" value="1" />',
	'</form>',
	'</p>',
	'</body>',
	'</html>'
    }
end

return M
