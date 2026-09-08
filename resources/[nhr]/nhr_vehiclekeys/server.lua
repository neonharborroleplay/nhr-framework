local sessionKeys = {}
local function revokePlate(plate)
    plate = exports.nhr_vehicles:CleanPlate(plate)
    for _, keys in pairs(sessionKeys) do keys[plate] = nil end
end
RegisterNetEvent('nhr_vehiclekeys:server:grantSession', function(plate)
    local player = exports.nhr_core:GetPlayer(source)
    plate = exports.nhr_vehicles:CleanPlate(plate)
    if player and exports.nhr_vehicles:IsOwner(player.PlayerData.citizenid, plate) then
        sessionKeys[source] = sessionKeys[source] or {}
        sessionKeys[source][plate] = true
    end
end)
lib.callback.register('nhr_vehiclekeys:has', function(source, plate)
    local player = exports.nhr_core:GetPlayer(source)
    plate = exports.nhr_vehicles:CleanPlate(plate)
    return player and (exports.nhr_vehicles:IsOwner(player.PlayerData.citizenid, plate) or sessionKeys[source] and sessionKeys[source][plate]) or false
end)
exports('RevokePlate', revokePlate)
AddEventHandler('playerDropped', function() sessionKeys[source] = nil end)
