lib.callback.register('nhr_garages:list', function(source, garage)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or not NHRGarages[garage] then return {} end
    return MySQL.query.await('SELECT plate, model, state, fuel, engine, body FROM nhr_vehicles WHERE citizenid = ? AND garage = ? ORDER BY model', { player.PlayerData.citizenid, garage }) or {}
end)

lib.callback.register('nhr_garages:takeOut', function(source, garage, plate)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or not NHRGarages[garage] then return end
    plate = exports.nhr_vehicles:CleanPlate(plate)
    local changed = MySQL.update.await("UPDATE nhr_vehicles SET state='out' WHERE citizenid=? AND plate=? AND garage=? AND state='stored'", { player.PlayerData.citizenid, plate, garage })
    if changed ~= 1 then return end
    local row = MySQL.single.await('SELECT * FROM nhr_vehicles WHERE plate = ?', { plate })
    row.props = json.decode(row.props or '{}')
    return row
end)

lib.callback.register('nhr_garages:store', function(source, garage, netId, props, fuel, engine, body)
    local player = exports.nhr_core:GetPlayer(source)
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not player or not NHRGarages[garage] or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local pedCoords, vehicleCoords = GetEntityCoords(GetPlayerPed(source)), GetEntityCoords(vehicle)
    if #(pedCoords - vehicleCoords) > 8.0 then return false end
    local plate = exports.nhr_vehicles:CleanPlate(GetVehicleNumberPlateText(vehicle))
    if not exports.nhr_vehicles:IsOwner(player.PlayerData.citizenid, plate) then return false end
    MySQL.update.await("UPDATE nhr_vehicles SET props=?, garage=?, state='stored', fuel=?, engine=?, body=? WHERE citizenid=? AND plate=?", {
        json.encode(props or {}), garage, math.max(0, math.min(100, tonumber(fuel) or 100)), math.max(0, tonumber(engine) or 1000), math.max(0, tonumber(body) or 1000), player.PlayerData.citizenid, plate
    })
    DeleteEntity(vehicle)
    return true
end)

RegisterNetEvent('nhr_garages:server:spawnFailed', function(plate)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return end
    MySQL.update("UPDATE nhr_vehicles SET state='stored' WHERE citizenid=? AND plate=? AND state='out'", {
        player.PlayerData.citizenid, exports.nhr_vehicles:CleanPlate(plate)
    })
end)

lib.callback.register('nhr_garages:impounded', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return {} end
    return MySQL.query.await("SELECT plate, model, fuel, engine, body FROM nhr_vehicles WHERE citizenid=? AND state='impounded'", { player.PlayerData.citizenid }) or {}
end)

lib.callback.register('nhr_garages:release', function(source, plate)
    local player = exports.nhr_core:GetPlayer(source)
    local config = NHRGarages.impound
    if not player or #(GetEntityCoords(GetPlayerPed(source)) - config.menu) > 8.0 then return end
    plate = exports.nhr_vehicles:CleanPlate(plate)
    local row = MySQL.single.await("SELECT * FROM nhr_vehicles WHERE citizenid=? AND plate=? AND state='impounded'", { player.PlayerData.citizenid, plate })
    if not row or not player.Functions.RemoveMoney('bank', config.fee, 'impound-release') then return end
    MySQL.update.await("UPDATE nhr_vehicles SET state='out' WHERE plate=?", { plate })
    row.props = json.decode(row.props or '{}')
    return row
end)

lib.callback.register('nhr_garages:impound', function(source, netId)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'police' or not player.PlayerData.job.onDuty then return false end
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(vehicle)) > 8.0 then return false end
    local plate = exports.nhr_vehicles:CleanPlate(GetVehicleNumberPlateText(vehicle))
    local changed = MySQL.update.await("UPDATE nhr_vehicles SET state='impounded' WHERE plate=?", { plate })
    if changed ~= 1 then return false end
    DeleteEntity(vehicle)
    return true
end)
