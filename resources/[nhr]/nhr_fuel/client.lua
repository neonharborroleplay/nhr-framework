CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and GetIsVehicleEngineRunning(vehicle) then
            local rpm = GetVehicleCurrentRpm(vehicle)
            local fuel = math.max(0.0, GetVehicleFuelLevel(vehicle) - (0.02 + rpm * 0.08))
            SetVehicleFuelLevel(vehicle, fuel)
            Entity(vehicle).state:set('nhrFuel', fuel, true)
            if fuel <= 0.0 then SetVehicleEngineOn(vehicle, false, true, true) end
        end
    end
end)

AddStateBagChangeHandler('nhrFuel', nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if entity ~= 0 and value then SetVehicleFuelLevel(entity, value + 0.0) end
end)

local function refuel()
    local vehicle = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, false)
    if not vehicle then return lib.notify({ type = 'error', description = 'Move a vehicle closer to the pump.' }) end
    local current = math.floor(GetVehicleFuelLevel(vehicle))
    local liters = math.max(0, 100 - current)
    if liters == 0 then return lib.notify({ description = 'The tank is already full.' }) end
    local ok, cost = lib.callback.await('nhr_fuel:purchase', false, liters)
    if not ok then return lib.notify({ type = 'error', description = 'Unable to pay for fuel.' }) end
    lib.progressCircle({ duration = liters * 250, label = ('Refueling · $%d'):format(cost), canCancel = false, disable = { move = true, car = true } })
    SetVehicleFuelLevel(vehicle, 100.0)
    Entity(vehicle).state:set('nhrFuel', 100.0, true)
end

CreateThread(function()
    for _, station in ipairs(NHRFuel.stations) do
        exports.ox_target:addSphereZone({ coords = station, radius = 12.0, options = {
            { name = ('nhr_fuel_%d_%d'):format(math.floor(station.x), math.floor(station.y)), label = ('$%d/L · Fill tank'):format(NHRFuel.pricePerLiter), icon = 'fa-solid fa-gas-pump', onSelect = refuel }
        } })
    end
end)
