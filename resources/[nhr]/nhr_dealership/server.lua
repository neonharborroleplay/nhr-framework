MySQL.ready(function()while not GlobalState.nhrMigrationsReady do Wait(50)end;for _,vehicle in ipairs(NHRDealership.vehicles)do MySQL.insert.await('INSERT IGNORE INTO nhr_dealer_stock (model,stock) VALUES (?,?)',{vehicle.model,vehicle.stock})end end)
local function reserve(model)return MySQL.update.await('UPDATE nhr_dealer_stock SET stock=stock-1 WHERE model=? AND stock>0',{model})==1 end
local function restore(model)MySQL.update('UPDATE nhr_dealer_stock SET stock=stock+1 WHERE model=?',{model})end
lib.callback.register('nhr_dealership:buy', function(source, model)
    local coords = GetEntityCoords(GetPlayerPed(source))
    if #(coords - NHRDealership.location) > 8.0 then return false, 'You are not at the dealership.' end
    local selected
    for _, vehicle in ipairs(NHRDealership.vehicles) do if vehicle.model == model then selected = vehicle break end end
    if not selected then return false, 'Vehicle is unavailable.' end
    if not reserve(selected.model)then return false,'This model is out of stock.'end
    local ok, result = exports.nhr_vehicles:Purchase(source, selected.model, selected.price, NHRDealership.garage)
    if not ok then restore(selected.model)return false, result == 'insufficient_funds' and 'Insufficient bank balance.' or 'Purchase failed.' end
    return true, ('Purchased %s. Plate: %s'):format(selected.label, result)
end)

lib.callback.register('nhr_dealership:finance',function(source,model)
    local coords=GetEntityCoords(GetPlayerPed(source));if #(coords-NHRDealership.location)>8.0 then return false,'You are not at the dealership.'end
    local selected;for _,vehicle in ipairs(NHRDealership.vehicles)do if vehicle.model==model then selected=vehicle break end end
    if not selected then return false,'Vehicle is unavailable.'end
    if not reserve(selected.model)then return false,'This model is out of stock.'end
    local ok,plate,down,payment=exports.nhr_vehicles:PurchaseFinanced(source,selected.model,selected.price,NHRDealership.garage)
    if not ok then restore(selected.model)return false,plate=='insufficient_funds'and'Insufficient bank balance.'or'Financing failed.'end
    return true,('Financed %s · Plate %s · $%d down · $%d weekly'):format(selected.label,plate,down,payment)
end)
