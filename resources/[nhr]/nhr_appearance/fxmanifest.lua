fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'nhr_appearance'
version '0.3.2'
ui_page 'web/index.html'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
dependencies { 'nhr_core', 'ox_lib', 'oxmysql', 'ox_target' }

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}
