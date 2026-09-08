RegisterCommand('vehiclelock', function()
    local coords = GetEntityCoords(PlayerPedId())
    local vehicle = lib.getClosestVehicle(coords, 7.0, false)
    if not vehicle then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not lib.callback.await('nhr_vehiclekeys:has', false, plate) then return lib.notify({ type = 'error', description = 'You do not have the keys.' }) end
    local locked = GetVehicleDoorLockStatus(vehicle) > 1
    SetVehicleDoorsLocked(vehicle, locked and 1 or 2)
    SetVehicleLights(vehicle, 2) Wait(150) SetVehicleLights(vehicle, 0)
    lib.notify({ description = locked and 'Vehicle unlocked.' or 'Vehicle locked.' })
end, false)
RegisterKeyMapping('vehiclelock', 'Lock or unlock vehicle', 'keyboard', 'L')

CreateThread(function()
    while true do
        Wait(500)
        local vehicle = GetVehiclePedIsTryingToEnter(PlayerPedId())
        if vehicle ~= 0 and GetSeatPedIsTryingToEnter(PlayerPedId()) == -1 then
            local hasKeys = lib.callback.await('nhr_vehiclekeys:has', false, GetVehicleNumberPlateText(vehicle))
            if not hasKeys and GetVehicleDoorLockStatus(vehicle) <= 1 then SetVehicleDoorsLocked(vehicle, 2) end
        end
    end
end)
