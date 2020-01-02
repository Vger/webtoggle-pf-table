package = "webtogglepft"
version = "scm-0"
source = {
   url = "git://github.com/Vger/webtoggle-pf-table.git",
}
description = {
   summary = "Adding or removing IP address of connecting web client to a pf table.",
   homepage = "https://github.com/Vger/webtoggle-pf-table",
   license = "MIT/X11",
}
dependencies = {
   "lua >= 5.1",
   "xavante",
}

build = {
  type = "none",
  install = {
    bin = {
      ["webtogglepft.lua"] = "src/main.lua",
    },
    lua = {
      ["webtogglepft"] = "src/webtogglepft.lua",
      ["webtogglepft.config"] = "src/webtogglepft/config.lua",
      ["webtogglepft.action"] = "src/webtogglepft/action.lua",
    },
  },
}
