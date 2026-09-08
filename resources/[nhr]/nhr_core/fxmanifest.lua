fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nhr_core'
author 'NHR Framework'
description 'Core runtime for the NHR framework'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/groups.lua',
    'shared/main.lua'
}

client_scripts { 'client/main.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/migrations.lua',
    'server/player.lua',
    'server/main.lua'
}

dependencies { 'ox_lib', 'oxmysql' }
