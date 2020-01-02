local config = {}

local tablename = 'vpn-lan'
local sudo_prog = '/usr/local/bin/doas'
local sudo_args = '-n -u root --'
local ip_prog = sudo_prog .. ' ' .. sudo_args .. ' /sbin/pfctl'

config.allowed_ips = '192.168.0.128/25'
config.ip_prog_add = ip_prog .. ' -t ' .. tablename .. ' -T add %h 2>&1'
config.ip_prog_remove = ip_prog .. ' -t ' .. tablename .. ' -T delete %h 2>&1'
config.ip_prog_check = ip_prog .. ' -t ' .. tablename .. ' -T test %h 2>&1'
config.ip_prog_check_success = '1/1 addresses match'
config.html_title = 'Toggle vpn access'
config.text_disallowed_host = 'Your IP (%h) is not allowed to use this service.'
config.text_missing_host = 'Your IP (%h) is not surfing via vpn.'
config.text_added_host = 'Your IP (%h) is surfing via vpn.'

return config
