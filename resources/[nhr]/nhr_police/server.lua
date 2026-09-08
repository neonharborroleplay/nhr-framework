local function officer(source)
    local player = exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onDuty and player
end
local function nearby(source, target)
    return target and GetPlayerPed(target) ~= 0 and #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target))) <= 5.0
end
lib.callback.register('nhr_police:cuff', function(source, target)
    target = tonumber(target)
    if not officer(source) or not nearby(source, target) then return false end
    local state = not Player(target).state.nhrCuffed
    Player(target).state:set('nhrCuffed', state, true)
    if not state and Player(target).state.nhrEscorter then Player(target).state:set('nhrEscorter',false,true)TriggerClientEvent('nhr_police:client:escort',target,false)end
    TriggerClientEvent('nhr_police:client:cuffed', target, state)
    return true
end)
AddEventHandler('playerDropped',function()
    for _,id in ipairs(GetPlayers())do local target=tonumber(id);if Player(target).state.nhrEscorter==source then Player(target).state:set('nhrEscorter',false,true)TriggerClientEvent('nhr_police:client:escort',target,false)end end
end)
lib.callback.register('nhr_police:jail', function(source, target, minutes)
    target, minutes = tonumber(target), math.floor(tonumber(minutes) or 0)
    if not officer(source) or not nearby(source, target) or minutes < 1 or minutes > 120 then return false end
    local player = exports.nhr_core:GetPlayer(target)
    if not player then return false end
    player.Functions.SetMetadata('jail', minutes)
    Player(target).state:set('nhrCuffed', false, true)
    TriggerClientEvent('nhr_police:client:jailed', target)
    return true
end)
lib.callback.register('nhr_police:search',function(source,target)
    target=tonumber(target);if not officer(source)or not nearby(source,target)or not Player(target).state.nhrCuffed then return false end
    return exports.nhr_inventory:AuthorizePlayerSearch(source,target)
end)
lib.callback.register('nhr_police:escort',function(source,target)
    target=tonumber(target);if not officer(source)or not nearby(source,target)or not Player(target).state.nhrCuffed then return false end
    local escorter=Player(target).state.nhrEscorter
    Player(target).state:set('nhrEscorter',escorter and false or source,true)
    TriggerClientEvent('nhr_police:client:escort',target,escorter and false or source);return true
end)
lib.callback.register('nhr_police:citation',function(source,target,amount,reason)
    if not exports.nhr_security:CheckRateLimit(source,'citation_issue',6,30000)then return false end
    local cop=officer(source);target=tonumber(target);amount=math.floor(tonumber(amount)or 0);reason=tostring(reason or''):sub(1,255)
    local suspect=target and exports.nhr_core:GetPlayer(target)
    if not cop or not suspect or not nearby(source,target)or amount<1 or amount>100000 or #reason<3 then return false end
    MySQL.insert.await('INSERT INTO nhr_citations (citizenid,officer,amount,reason) VALUES (?,?,?,?)',{suspect.PlayerData.citizenid,cop.PlayerData.citizenid,amount,reason})
    TriggerClientEvent('nhr_police:client:citationReceived',target,amount,reason);return true
end)
lib.callback.register('nhr_police:warrant',function(source,citizenid,reason)
    if not exports.nhr_security:CheckRateLimit(source,'warrant_issue',6,30000)then return false end
    local cop=officer(source);citizenid=tostring(citizenid or''):sub(1,16);reason=tostring(reason or''):sub(1,500)
    if not cop or #reason<5 or not MySQL.scalar.await('SELECT 1 FROM nhr_characters WHERE citizenid=?',{citizenid})then return false end
    MySQL.insert.await('INSERT INTO nhr_warrants (citizenid,officer,reason) VALUES (?,?,?)',{citizenid,cop.PlayerData.citizenid,reason});return true
end)
lib.callback.register('nhr_police:citations',function(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return{}end
    return MySQL.query.await('SELECT id,amount,reason,paid,created_at FROM nhr_citations WHERE citizenid=? ORDER BY id DESC LIMIT 25',{player.PlayerData.citizenid})or{}
end)
lib.callback.register('nhr_police:payCitation',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'citation_pay',5,30000)then return false end
    local player=exports.nhr_core:GetPlayer(source);if not player then return false end
    local row=MySQL.single.await('SELECT id,amount FROM nhr_citations WHERE id=? AND citizenid=? AND paid=0',{tonumber(id),player.PlayerData.citizenid})
    if not row or not player.Functions.RemoveMoney('bank',row.amount,'citation-payment')then return false end
    local changed=MySQL.update.await('UPDATE nhr_citations SET paid=1 WHERE id=? AND paid=0',{row.id})
    if changed~=1 then player.Functions.AddMoney('bank',row.amount,'citation-refund')return false end
    MySQL.prepare.await("INSERT INTO nhr_societies (name,balance) VALUES ('police',?) ON DUPLICATE KEY UPDATE balance=balance+VALUES(balance)",{row.amount})
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'citation',row.amount,'Citation payment #'..row.id})
    MySQL.insert('INSERT INTO nhr_society_transactions (society,citizenid,kind,amount) VALUES (?,?,?,?)',{'police',player.PlayerData.citizenid,'citation',row.amount})
    exports.nhr_logs:CreateLog('economy','citation_paid',source,nil,{citation=row.id,amount=row.amount});return true
end)
CreateThread(function()
    while true do
        Wait(60000)
        local core = exports.nhr_core:GetCoreObject()
        for source, player in pairs(core.Players) do
            local time = tonumber(player.PlayerData.metadata.jail) or 0
            if time > 0 then
                player.Functions.SetMetadata('jail', time - 1)
                if time == 1 then TriggerClientEvent('nhr_police:client:released', source) end
            end
        end
    end
end)
