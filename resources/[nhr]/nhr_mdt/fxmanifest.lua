fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'nhr_mdt'
version '0.1.0'
shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
dependencies { 'nhr_core', 'ox_lib', 'oxmysql' }
