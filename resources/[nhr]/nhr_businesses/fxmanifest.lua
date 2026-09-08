fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'nhr_businesses'
version '0.1.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
dependencies { 'nhr_core', 'nhr_security', 'nhr_logs', 'ox_lib', 'oxmysql', 'ox_target' }
