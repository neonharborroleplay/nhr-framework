NHR.PlayerData = {}
NHR.PlayerLoaded = false

function NHR.GetPlayerData() return NHR.PlayerData end

RegisterNetEvent('nhr_core:client:setPlayerData', function(data)
    NHR.PlayerData = data
    LocalPlayer.state:set('job', data.job, true)
    TriggerEvent('nhr_core:client:playerDataChanged', data)
end)

RegisterNetEvent('nhr_core:client:playerLoaded', function(data)
    NHR.PlayerData = data
    NHR.PlayerLoaded = true
    LocalPlayer.state:set('isLoggedIn', true, true)
    LocalPlayer.state:set('job', data.job, true)
    TriggerEvent('nhr_core:client:onPlayerLoaded', data)
end)

RegisterNetEvent('nhr_core:client:playerUnloaded', function()
    NHR.PlayerData = {}
    NHR.PlayerLoaded = false
    LocalPlayer.state:set('isLoggedIn', false, true)
    TriggerEvent('nhr_core:client:onPlayerUnloaded')
end)

CreateThread(function()
    while true do
        Wait(15000)
        if NHR.PlayerLoaded then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('nhr_core:server:updatePosition', {
                x = coords.x, y = coords.y, z = coords.z, w = GetEntityHeading(ped)
            })
        end
    end
end)
