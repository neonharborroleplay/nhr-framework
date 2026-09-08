local cooldown = {}
RegisterNetEvent('nhr_dispatch:server:alert', function(service, title, message, coords)
    local src = source
    if cooldown[src] and GetGameTimer() - cooldown[src] < 5000 then return end
    if service ~= 'police' and service ~= 'ambulance' and service ~= 'taxi' and service ~= 'tow' then return end
    local pedCoords = GetEntityCoords(GetPlayerPed(src))
    if type(coords) ~= 'table' or #(pedCoords - vec3(tonumber(coords.x) or 0, tonumber(coords.y) or 0, tonumber(coords.z) or 0)) > 50.0 then return end
    cooldown[src] = GetGameTimer()
    local core = exports.nhr_core:GetCoreObject()
    for target, player in pairs(core.Players) do
        if player.PlayerData.job.name == service and player.PlayerData.job.onDuty then
            TriggerClientEvent('nhr_dispatch:client:alert', target, tostring(title):sub(1, 48), tostring(message):sub(1, 120), coords)
        end
    end
end)
AddEventHandler('playerDropped', function() cooldown[source] = nil end)
