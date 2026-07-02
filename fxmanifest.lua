fx_version 'cerulean'
game 'gta5'

name 'd87-garage'
description 'Advanced Garage System for FiveM - Multi-Framework'
version '1.0.0'
author 'Drako87/Dracatt'

lua54 'yes'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/enums.lua',
    'bridge/loader.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/nui.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/storage.lua',
    'server/spawn.lua',
    'server/main.lua',
}

files {
    'config/config.lua',
    'locales/*.json',
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
}

ui_page 'ui/index.html'