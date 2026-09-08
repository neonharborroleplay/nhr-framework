local function cleanPlate(plate) return tostring(plate or ''):upper():gsub('%s+', ''):sub(1, 12) end

local function newPlate()
    while true do
        local plate = ('NHR%03d%02d'):format(math.random(0, 999), math.random(0, 99))
        if not MySQL.scalar.await('SELECT 1 FROM nhr_vehicles WHERE plate = ?', { plate }) then return plate end
    end
end

local function isOwner(citizenid, plate)
    return MySQL.scalar.await('SELECT 1 FROM nhr_vehicles WHERE citizenid = ? AND plate = ?', { citizenid, cleanPlate(plate) }) ~= nil
end

local function purchase(source, model, price, garage)
    local player = exports.nhr_core:GetPlayer(source)
    price = math.floor(tonumber(price) or 0)
    if not player or type(model) ~= 'string' or price < 0 then return false, 'invalid_purchase' end
    if not player.Functions.RemoveMoney('bank', price, 'vehicle-purchase') then return false, 'insufficient_funds' end
    local plate = newPlate()
    local id = MySQL.insert.await([[
        INSERT INTO nhr_vehicles (citizenid, plate, model, props, garage, state)
        VALUES (?, ?, ?, ?, ?, 'stored')
    ]], { player.PlayerData.citizenid, plate, model, json.encode({ model = joaat(model), plate = plate }), garage or 'legion' })
    if not id then player.Functions.AddMoney('bank', price, 'vehicle-purchase-refund') return false, 'database_error' end
    return true, plate
end

local function purchaseFinanced(source,model,price,garage)
    local player=exports.nhr_core:GetPlayer(source);price=math.floor(tonumber(price)or 0)
    if not player or price<1 then return false,'invalid_purchase'end
    local down=math.ceil(price*0.20);local balance=price-down;local payment=math.ceil(balance/10)
    if not player.Functions.RemoveMoney('bank',down,'vehicle-down-payment')then return false,'insufficient_funds'end
    local plate=newPlate();local id=MySQL.insert.await([[INSERT INTO nhr_vehicles (citizenid,plate,model,props,garage,state,finance_balance,finance_payment,finance_due) VALUES (?,?,?,?,?,'stored',?,?,DATE_ADD(NOW(),INTERVAL 7 DAY))]],{player.PlayerData.citizenid,plate,model,json.encode({model=joaat(model),plate=plate}),garage or'legion',balance,payment})
    if not id then player.Functions.AddMoney('bank',down,'vehicle-finance-refund')return false,'database_error'end
    return true,plate,down,payment
end

exports('CleanPlate', cleanPlate)
exports('IsOwner', isOwner)
exports('Purchase', purchase)
exports('PurchaseFinanced',purchaseFinanced)

lib.callback.register('nhr_vehicles:isOwner', function(source, plate)
    local player = exports.nhr_core:GetPlayer(source)
    return player and isOwner(player.PlayerData.citizenid, plate) or false
end)

MySQL.ready(function()
    MySQL.update("UPDATE nhr_vehicles SET state = 'stored' WHERE state = 'out'")
end)
