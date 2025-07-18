fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Il tuo nome'
description 'Job Delivery con ped e ox_target'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_target',
    'ox_lib',
    'mysql-async'
}

ui_page 'html/main.html'

files {
    'html/main.html',
    'html/main.css',
    'html/main.js',
    'html/img/tablet_bg.png'
}
