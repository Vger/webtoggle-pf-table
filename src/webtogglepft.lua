local httpd = require 'xavante.httpd'
local io = require 'io'
local action = require 'webtogglepft.action'

local function default_headers(req, res)
    local version = req.cmd_version
    if not version then
	-- Might be a HTTP/0.9 connection, so do not
	-- send any headers.
	res.sent_headers = true
    else
	res.headers['Content-Type'] = 'text/html; charset=utf-8'
	res.headers['Expires'] = '0'
	res.headers['Accept-Ranges'] = 'none'

	if version == 'HTTP/1.0' then
	    res.headers['Connection'] = 'close'
	else
	    res.headers['Cache-Control'] = 'no-cache'
	end
    end
end

local function handle_error(req, res, status, err)
    err = tostring(err)
    io.stderr:write(status .. ':' .. err)
    res.statusline = 'HTTP/1.1 ' .. status
    default_headers(req, res)
    res.content = string.format([[ 
<!DOCTYPE html>
<html>
<head><title>%s</title></head>
<body>
<h1>%s</h1>
<p>
%s
</p>
</body>
</html>
	]], status, status, string.gsub(err, "\n", "<br/>\n"))
end

local function handle_get(req, res)
    local success, page = pcall(action.render_get, req, res)
    if not success then
	handle_error(req, res, '500 Internal Server Error', page)
    else
	default_headers(req, res)
	if page ~= nil then
	    res.content = page
	end
    end
end

local function handle_post(req, res)
    local received = {}

    local function handle_post_chunk(length)
	if not length or length <= 0 then
	    return
	end
	local body = req.socket:receive(length)
	received[#received + 1] = body
    end

    if req.headers['expect'] == '100-continue' then
	res.socket:send('HTTP/1.1 100 Continue\r\n\r\n')
    end
    local te = req.headers['transfer-encoding']
    if te and te ~= 'identity' then
	while true do
	    -- Assume chunked
	    local line = req.socket:receive()
	    if not line then
		handle_error(req, res, '400 Bad Request', 'No size of chunk specified')
		return
	    end
	    local size = tonumber(line:gsub(';.*', ''), 16)
	    if not size then
		handle_error(req, res, '400 Bad Request', 'Size specified is not hexadecimal')
		return
	    end
	    if size > 0 then
		-- this is not the last chunk, get it and skip CRLF
		handle_post_chunk(size)
		req.socket:receive()
	    else
		-- last chunk, read trailers
		httpd.read_headers(req)
		break
	    end
	end
    else
	local length = req.headers['content-length']
	if length then
	    handle_post_chunk(tonumber(length))
	end
    end
    received = table.concat(received)

    local success, page = pcall(action.handle_post_data, req, res, received)
    if not success then
	handle_error(req, res, '500 Internal Server Error', page)
    else
	default_headers(req, res)
	if page ~= nil then
	    res.content = page
	end
    end
end

local function handler(req, res)
    if req.cmd_mth == 'GET' then
	handle_get(req, res)
    elseif req.cmd_mth == 'POST' then
	handle_post(req, res)
    else
	res.headers['Allow'] = 'GET, POST';
	httpd.err_405(req, res)
    end
end

return handler
