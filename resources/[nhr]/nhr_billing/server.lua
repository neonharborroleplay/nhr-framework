lib.callback.register('nhr_billing:issue',function(source,target,amount,reason)
    if not exports.nhr_security:CheckRateLimit(source,'invoice_issue',5,30000)then return false end
    target=tonumber(target);local issuer,recipient=exports.nhr_core:GetPlayer(source),exports.nhr_core:GetPlayer(target);amount=math.floor(tonumber(amount)or 0);reason=tostring(reason or''):sub(1,255)
    if not issuer or not recipient or issuer.PlayerData.job.name=='unemployed'or not issuer.PlayerData.job.onDuty or #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))>5.0 or amount<1 or amount>100000 or #reason<3 then return false end
    MySQL.insert.await('INSERT INTO nhr_invoices (issuer,recipient,society,amount,reason) VALUES (?,?,?,?,?)',{issuer.PlayerData.citizenid,recipient.PlayerData.citizenid,issuer.PlayerData.job.name,amount,reason})
    TriggerClientEvent('nhr_billing:client:received',target,amount,reason);return true
end)
lib.callback.register('nhr_billing:list',function(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return end
    return MySQL.query.await("SELECT id,society,amount,reason,created_at FROM nhr_invoices WHERE recipient=? AND status='unpaid' ORDER BY id",{player.PlayerData.citizenid})or{}
end)
lib.callback.register('nhr_billing:history',function(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return{}end
    return MySQL.query.await('SELECT id,society,amount,reason,status,created_at FROM nhr_invoices WHERE recipient=? ORDER BY id DESC LIMIT 25',{player.PlayerData.citizenid})or{}
end)
lib.callback.register('nhr_billing:pay',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'invoice_pay',5,30000)then return false end
    local player=exports.nhr_core:GetPlayer(source);if not player then return false end
    local row=MySQL.single.await("SELECT id,issuer,society,amount FROM nhr_invoices WHERE id=? AND recipient=? AND status='unpaid'",{tonumber(id),player.PlayerData.citizenid})
    if not row or not player.Functions.RemoveMoney('bank',row.amount,'invoice-payment')then return false end
    local changed=MySQL.update.await("UPDATE nhr_invoices SET status='paid' WHERE id=? AND status='unpaid'",{row.id})
    if changed~=1 then player.Functions.AddMoney('bank',row.amount,'invoice-refund')return false end
    MySQL.prepare.await('INSERT INTO nhr_societies (name,balance) VALUES (?,?) ON DUPLICATE KEY UPDATE balance=balance+VALUES(balance)',{row.society,row.amount})
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'invoice',row.amount,'Invoice paid to '..row.society})
    MySQL.insert('INSERT INTO nhr_society_transactions (society,citizenid,kind,amount) VALUES (?,?,?,?)',{row.society,row.issuer,'invoice',row.amount})
    exports.nhr_logs:CreateLog('economy','invoice_paid',source,row.issuer,{invoice=row.id,society=row.society,amount=row.amount});return true
end)
