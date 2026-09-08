fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'nhr_phone'
version '0.1.0'
shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
ui_page 'web/index.html'
files { 'web/index.html', 'web/style.css', 'web/app.js' }
dependencies { 'nhr_core', 'nhr_inventory', 'nhr_dispatch', 'pma-voice', 'ox_lib', 'oxmysql' }
