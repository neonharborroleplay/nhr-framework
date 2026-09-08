fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nhr_multichar'
version '0.1.1'

shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies { 'nhr_core', 'ox_lib' }
