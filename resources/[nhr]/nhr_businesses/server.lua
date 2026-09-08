MySQL.ready(function()while not GlobalState.nhrMigrationsReady do Wait(50)end;for id,b in pairs(NHRBusinesses)do MySQL.prepare.await('INSERT INTO nhr_businesses (business_id,label,price) VALUES (?,?,?) ON DUPLICATE KEY UPDATE label=VALUES(label),price=VALUES(price)',{id,b.label,b.price})end end)
lib.callback.register('nhr_businesses:info',function(source,id)
    local business=NHRBusinesses[id];if not business then return end
    local row=MySQL.single.await('SELECT owner,price,is_open FROM nhr_businesses WHERE business_id=?',{id});local player=exports.nhr_core:GetPlayer(source)
    return row and {owner=row.owner,owned=player and row.owner==player.PlayerData.citizenid,price=row.price,label=business.label,isOpen=row.is_open==1}or nil
end)
lib.callback.register('nhr_businesses:buy',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'business_buy',3,30000)then return false end
    local business=NHRBusinesses[id];local player=exports.nhr_core:GetPlayer(source)
    if not business or not player or #(GetEntityCoords(GetPlayerPed(source))-business.coords)>5.0 or not player.Functions.RemoveMoney('bank',business.price,'business-purchase')then return false end
    local changed=MySQL.update.await('UPDATE nhr_businesses SET owner=? WHERE business_id=? AND owner IS NULL',{player.PlayerData.citizenid,id})
    if changed~=1 then player.Functions.AddMoney('bank',business.price,'business-refund')return false end
    MySQL.insert.await('INSERT IGNORE INTO nhr_societies (name) VALUES (?)',{business.job})
    player.Functions.SetPrimaryGroup('job',business.job,business.bossGrade)
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'business_buy',business.price,'Purchased '..business.label})
    exports.nhr_logs:CreateLog('economy','business_purchase',source,nil,{business=id,price=business.price});return true
end)
lib.callback.register('nhr_businesses:toggle',function(source,id,state)
    if not exports.nhr_security:CheckRateLimit(source,'business_toggle',6,30000)then return false end
    local business,player=NHRBusinesses[id],exports.nhr_core:GetPlayer(source)
    if not business or not player or #(GetEntityCoords(GetPlayerPed(source))-business.coords)>5.0 then return false end
    return MySQL.update.await('UPDATE nhr_businesses SET is_open=? WHERE business_id=? AND owner=?',{state==true and 1 or 0,id,player.PlayerData.citizenid})==1
end)
lib.callback.register('nhr_businesses:sell',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'business_sell',2,60000)then return false end
    local business,player=NHRBusinesses[id],exports.nhr_core:GetPlayer(source)
    if not business or not player or #(GetEntityCoords(GetPlayerPed(source))-business.coords)>5.0 then return false end
    local row=MySQL.single.await('SELECT price FROM nhr_businesses WHERE business_id=? AND owner=?',{id,player.PlayerData.citizenid})
    if not row then return false end
    local changed=MySQL.update.await('UPDATE nhr_businesses SET owner=NULL,is_open=0 WHERE business_id=? AND owner=?',{id,player.PlayerData.citizenid})
    if changed~=1 then return false end
    local refund=math.floor(row.price*(business.resalePercent or 0.5))
    player.Functions.AddMoney('bank',refund,'business-resale')
    player.Functions.RemoveGroup('job',business.job)
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'business_sale',refund,'Sold '..business.label})
    exports.nhr_logs:CreateLog('economy','business_resale',source,nil,{business=id,refund=refund})
    return refund
end)
