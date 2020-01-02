local xavante = require "xavante"
local toggle = require "webtogglepft"

local host = "*"
local port = 8888

local simplerules = {
    {
	match = ".",
	with = toggle,
    },
}

local conf = {
    server = { host = host, port = port },
    defaultHost = { rules = simplerules },
}

xavante.HTTP(conf)
xavante.start()
