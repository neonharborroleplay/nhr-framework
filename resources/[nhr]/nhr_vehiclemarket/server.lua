local offers = {}

local function nearby(a, b)
    local aPed, bPed = GetPlayerPed(a), GetPlayerPed(b)
    return aPed ~= 0 and bPed ~= 0 and #(GetEntityCoords(aPed) - GetEntityCoords(bPed)) <= 5.0
end

lib.callback.register('nhr_vehiclemarket:list', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return {} end
    return MySQL.query.await("SELECT plate,model FROM nhr_vehicles WHERE citizenid=? AND state='stored' AND finance_balance=0 ORDER BY model", { player.PlayerData.citizenid }) or {}
end)

lib.callback.register('nhr_vehiclemarket:offer', function(source, target, plate, price)
    if not exports.nhr_security:CheckRateLimit(source, 'vehicle_offer', 4, 30000) then return false end
    target, price = tonumber(target), math.floor(tonumber(price) or 0)
    local seller, buyer = exports.nhr_core:GetPlayer(source), target and exports.nhr_core:GetPlayer(target)
    plate = exports.nhr_vehicles:CleanPlate(plate)
    if not seller or not buyer or seller == buyer or price < 1 or price > 2000000 or not nearby(source, target) then return false end
    local row = MySQL.single.await("SELECT model FROM nhr_vehicles WHERE citizenid=? AND plate=? AND state='stored' AND finance_balance=0", { seller.PlayerData.citizenid, plate })
    if not row then return false end
    local token = ('vehicle:%d:%d:%d'):format(source, target, math.random(100000, 999999))
    offers[token] = { seller = source, buyer = target, plate = plate, model = row.model, price = price, expires = GetGameTimer() + 30000 }
    TriggerClientEvent('nhr_vehiclemarket:client:offer', target, token, row.model, plate, price, GetPlayerName(source))
    return true
end)

lib.callback.register('nhr_vehiclemarket:accept', function(source, token)
    if not exports.nhr_security:CheckRateLimit(source, 'vehicle_accept', 4, 30000) then return false end
    local offer = offers[tostring(token or '')]
    offers[tostring(token or '')] = nil
    if not offer or offer.buyer ~= source or GetGameTimer() > offer.expires or not nearby(offer.seller, source) then return false end
    local seller, buyer = exports.nhr_core:GetPlayer(offer.seller), exports.nhr_core:GetPlayer(source)
    if not seller or not buyer or not buyer.Functions.RemoveMoney('bank', offer.price, 'vehicle-private-sale') then return false end
    local changed = MySQL.update.await("UPDATE nhr_vehicles SET citizenid=? WHERE citizenid=? AND plate=? AND state='stored' AND finance_balance=0", {
        buyer.PlayerData.citizenid, seller.PlayerData.citizenid, offer.plate
    })
    if changed ~= 1 then buyer.Functions.AddMoney('bank', offer.price, 'vehicle-sale-refund') return false end
    seller.Functions.AddMoney('bank', offer.price, 'vehicle-private-sale')
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { buyer.PlayerData.citizenid, 'vehicle_buy', offer.price, 'Private purchase ' .. offer.plate })
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { seller.PlayerData.citizenid, 'vehicle_sale', offer.price, 'Private sale ' .. offer.plate })
    exports.nhr_vehiclekeys:RevokePlate(offer.plate)
    exports.nhr_logs:CreateLog('economy', 'vehicle_sale', offer.seller, source, { plate = offer.plate, model = offer.model, price = offer.price })
    return true
end)

AddEventHandler('playerDropped', function()
    for token, offer in pairs(offers) do if offer.seller == source or offer.buyer == source then offers[token] = nil end end
end)
