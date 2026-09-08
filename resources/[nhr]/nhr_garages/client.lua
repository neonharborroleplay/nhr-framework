local function spawnVehicle(garage, data)
    local location = NHRGarages[garage].spawn
    local model = joaat(data.model)
    lib.requestModel(model)
    local vehicle = CreateVehicle(model, location.x, location.y, location.z, location.w, true, true)
    if vehicle == 0 then
        TriggerServerEvent('nhr_garages:server:spawnFailed', data.plate)
        return lib.notify({ type = 'error', description = 'Vehicle could not be created.' })
    end
    lib.setVehicleProperties(vehicle, data.props or {})
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleFuelLevel(vehicle, data.fuel + 0.0)
    SetVehicleEngineHealth(vehicle, data.engine + 0.0)
    SetVehicleBodyHealth(vehicle, data.body + 0.0)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    TriggerServerEvent('nhr_vehiclekeys:server:grantSession', data.plate)
end

local function openGarage(name)
    local rows = lib.callback.await('nhr_garages:list', false, name)
    local options = {}
    for _, row in ipairs(rows) do
        local vehicle = row
        options[#options + 1] = { title = vehicle.model, description = ('%s · %s · Fuel %d%%'):format(vehicle.plate, vehicle.state, vehicle.fuel), disabled = vehicle.state ~= 'stored', onSelect = function()
            local spawn = NHRGarages[name].spawn
            if IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 3.0) then return lib.notify({ type = 'error', description = 'Spawn point is blocked.' }) end
            local data = lib.callback.await('nhr_garages:takeOut', false, name, vehicle.plate)
            if data then spawnVehicle(name, data) end
        end }
    end
    lib.registerContext({ id = 'nhr_garage_' .. name, title = NHRGarages[name].label, options = options })
    lib.showContext('nhr_garage_' .. name)
end

local function openImpound()
    local rows = lib.callback.await('nhr_garages:impounded', false)
    local options = {}
    for _, row in ipairs(rows) do
        local vehicle = row
        options[#options + 1] = { title = vehicle.model, description = ('%s · $%d release fee'):format(vehicle.plate, NHRGarages.impound.fee), onSelect = function()
            local spawn = NHRGarages.impound.spawn
            if IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 3.0) then return lib.notify({ type = 'error', description = 'Release area is blocked.' }) end
            local data = lib.callback.await('nhr_garages:release', false, vehicle.plate)
            if data then spawnVehicle('impound', data) else lib.notify({ type = 'error', description = 'Unable to release vehicle.' }) end
        end }
    end
    lib.registerContext({ id = 'nhr_impound', title = 'City Impound', options = options })
    lib.showContext('nhr_impound')
end

local function storeVehicle(name)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then return lib.notify({ type = 'error', description = 'Drive your vehicle into the garage.' }) end
    local ok = lib.callback.await('nhr_garages:store', false, name, NetworkGetNetworkIdFromEntity(vehicle), lib.getVehicleProperties(vehicle), GetVehicleFuelLevel(vehicle), GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle))
    lib.notify({ type = ok and 'success' or 'error', description = ok and 'Vehicle stored.' or 'This vehicle cannot be stored here.' })
end

CreateThread(function()
    for name, garage in pairs(NHRGarages) do
        if garage.special then
            exports.ox_target:addSphereZone({ coords = garage.menu, radius = 2.5, options = {
                { name = 'nhr_impound', label = 'View impounded vehicles', icon = 'fa-solid fa-car-burst', onSelect = openImpound }
            } })
        else
        exports.ox_target:addSphereZone({ coords = garage.menu, radius = 2.5, options = {
            { name = 'nhr_open_' .. name, label = 'Open ' .. garage.label, icon = 'fa-solid fa-warehouse', onSelect = function() openGarage(name) end },
            { name = 'nhr_store_' .. name, label = 'Store vehicle', icon = 'fa-solid fa-square-parking', onSelect = function() storeVehicle(name) end }
        } })
        end
    end
end)

RegisterCommand('impound', function()
    local core = exports.nhr_core:GetCoreObject()
    if core.PlayerData.job.name ~= 'police' or not core.PlayerData.job.onDuty then return end
    local vehicle = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, false)
    if not vehicle then return lib.notify({ type = 'error', description = 'No vehicle nearby.' }) end
    local ok = lib.callback.await('nhr_garages:impound', false, NetworkGetNetworkIdFromEntity(vehicle))
    lib.notify({ type = ok and 'success' or 'error', description = ok and 'Vehicle impounded.' or 'Unable to impound vehicle.' })
end, false)
