lib.callback.register('nhr_fuel:purchase', function(source, liters)
    local player = exports.nhr_core:GetPlayer(source)
    liters = math.floor(tonumber(liters) or 0)
    if not player or liters < 1 or liters > 100 then return false end
    local coords, nearby = GetEntityCoords(GetPlayerPed(source)), false
    for _, station in ipairs(NHRFuel.stations) do if #(coords - station) <= 25.0 then nearby = true break end end
    if not nearby then return false end
    local cost = liters * NHRFuel.pricePerLiter
    if not player.Functions.RemoveMoney('bank', cost, 'vehicle-fuel') then return false end
    return true, cost
end)
