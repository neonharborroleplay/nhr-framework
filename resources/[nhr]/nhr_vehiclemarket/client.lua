RegisterNetEvent('nhr_vehiclemarket:client:offer', function(token, model, plate, price, seller)
    local result = lib.alertDialog({ header = 'Private vehicle sale', content = ('%s is offering **%s** (%s) for **$%d**.'):format(seller, model, plate, price), centered = true, cancel = true })
    if result ~= 'confirm' then return end
    local ok = lib.callback.await('nhr_vehiclemarket:accept', false, token)
    lib.notify({ type = ok and 'success' or 'error', description = ok and 'Vehicle purchased and stored in your garage.' or 'The sale could not be completed.' })
end)

RegisterCommand('sellvehicle', function()
    local playerId = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 5.0, false)
    if not playerId then return lib.notify({ type = 'error', description = 'No buyer nearby.' }) end
    local rows = lib.callback.await('nhr_vehiclemarket:list', false)
    local choices = {}
    for _, row in ipairs(rows or {}) do choices[#choices + 1] = { value = row.plate, label = ('%s · %s'):format(row.model, row.plate) } end
    if #choices == 0 then return lib.notify({ type = 'error', description = 'You have no stored, fully paid vehicles to sell.' }) end
    local input = lib.inputDialog('Sell vehicle', {
        { type = 'select', label = 'Vehicle', options = choices, required = true },
        { type = 'number', label = 'Price', min = 1, max = 2000000, required = true }
    })
    if not input then return end
    local ok = lib.callback.await('nhr_vehiclemarket:offer', false, GetPlayerServerId(playerId), input[1], input[2])
    lib.notify({ type = ok and 'success' or 'error', description = ok and 'Sale offer sent.' or 'Unable to offer that vehicle.' })
end, false)
