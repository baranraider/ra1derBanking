fx_version "cerulean"
games { "gta5" }
lua54 "yes"

author "ra1der & guneyct"
description "Basic NUI Bank"
version "1.0.0"

shared_scripts {
  "config/config.lua",
  "@ox_lib/init.lua"
}

client_scripts {
  "config/config.lua",
  "bridge/framework/client/*.lua",
  "client/*.lua",
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "config/config.lua",
  "bridge/framework/server/*.lua",
  "server/*.lua"
}

ui_page "html/index.html"
files {
  "config/language.json",
	"html/**/*",
}

dependencies {
  "ox_lib"
}