lib.callback.register('nhr_finance:list',function(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return end
    return MySQL.query.await('SELECT plate,model,finance_balance,finance_payment,finance_due FROM nhr_vehicles WHERE citizenid=? AND finance_balance>0',{player.PlayerData.citizenid})or{}
end)
lib.callback.register('nhr_finance:pay',function(source,plate)
    local player=exports.nhr_core:GetPlayer(source);if not player then return false end
    local row=MySQL.single.await('SELECT finance_balance,finance_payment FROM nhr_vehicles WHERE citizenid=? AND plate=? AND finance_balance>0',{player.PlayerData.citizenid,tostring(plate)})
    if not row then return false end
    local amount=math.min(row.finance_balance,row.finance_payment)
    if not player.Functions.RemoveMoney('bank',amount,'vehicle-finance')then return false end
    MySQL.update.await('UPDATE nhr_vehicles SET finance_balance=GREATEST(0,finance_balance-?),finance_due=IF(finance_balance<=?,NULL,DATE_ADD(NOW(),INTERVAL 7 DAY)) WHERE citizenid=? AND plate=?',{amount,amount,player.PlayerData.citizenid,plate})
    return true,amount
end)
CreateThread(function()
    while true do
        Wait(30*60*1000)
        local overdue=MySQL.query.await("SELECT plate FROM nhr_vehicles WHERE finance_balance>0 AND finance_due<NOW()")or{}
        local plates={}
        for _,row in ipairs(overdue)do plates[exports.nhr_vehicles:CleanPlate(row.plate)]=true;MySQL.update.await("UPDATE nhr_vehicles SET state='impounded' WHERE plate=?",{row.plate})end
        if next(plates)then for _,vehicle in ipairs(GetAllVehicles())do if plates[exports.nhr_vehicles:CleanPlate(GetVehicleNumberPlateText(vehicle))]then DeleteEntity(vehicle)end end end
    end
end)
