fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nhr_inventory'
author 'NHR Framework'
description 'First-party slot inventory for NHR'
version '0.1.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }

ui_page 'web/index.html'
files { 'web/index.html', 'web/app.js', 'web/style.css' }

dependencies { 'nhr_core', 'nhr_vehicles', 'ox_lib', 'oxmysql' }
