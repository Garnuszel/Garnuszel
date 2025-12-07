fx_version 'cerulean'
game 'gta5'

author 'rev-core example'
description 'Lightweight callback and utility framework'
version '1.0.0'

shared_scripts {
    'shared/core.lua'
}

client_scripts {
    'client/callbacks.lua'
}

server_scripts {
    'server/callbacks.lua',
    'server/characters.lua'
}
