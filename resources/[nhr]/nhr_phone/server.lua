local cooldown={}
local calls,pending,nextChannel={},{},2000
local function numberFor(player)
    local number=MySQL.scalar.await('SELECT phone_number FROM nhr_phone_numbers WHERE citizenid=?',{player.PlayerData.citizenid})
    while not number do
        local candidate=('555%07d'):format(math.random(0,9999999))
        local inserted=MySQL.insert.await('INSERT IGNORE INTO nhr_phone_numbers (citizenid,phone_number) VALUES (?,?)',{player.PlayerData.citizenid,candidate})
        if inserted and inserted>0 then number=candidate else number=MySQL.scalar.await('SELECT phone_number FROM nhr_phone_numbers WHERE citizenid=?',{player.PlayerData.citizenid}) end
    end
    if player.PlayerData.metadata.phone~=number then player.Functions.SetMetadata('phone',number) end
    return number
end
local function owner(source)
    local player=exports.nhr_core:GetPlayer(source)
    if not player or exports.nhr_inventory:GetItemCount(source,'phone')<1 then return end
    return player,numberFor(player)
end
lib.callback.register('nhr_phone:data',function(source)
    local player,number=owner(source);if not player then return end
    return {number=number,contacts=MySQL.query.await('SELECT id,name,phone_number FROM nhr_phone_contacts WHERE citizenid=? ORDER BY name',{player.PlayerData.citizenid})or{},messages=MySQL.query.await('SELECT id,sender,recipient,body,is_read,created_at FROM nhr_phone_messages WHERE sender=? OR recipient=? ORDER BY id DESC LIMIT 50',{number,number})or{}}
end)
lib.callback.register('nhr_phone:addContact',function(source,name,number)
    local player=owner(source);name=tostring(name or''):sub(1,48);number=tostring(number or''):gsub('%D',''):sub(1,12)
    if not player or #name<1 or #number<7 then return false end
    MySQL.insert.await('INSERT INTO nhr_phone_contacts (citizenid,name,phone_number) VALUES (?,?,?)',{player.PlayerData.citizenid,name,number});return true
end)
lib.callback.register('nhr_phone:deleteContact',function(source,id)
    local player=owner(source);if not player then return false end
    return MySQL.update.await('DELETE FROM nhr_phone_contacts WHERE id=? AND citizenid=?',{tonumber(id),player.PlayerData.citizenid})==1
end)
lib.callback.register('nhr_phone:send',function(source,recipient,body)
    local _,number=owner(source);recipient=tostring(recipient or''):gsub('%D',''):sub(1,12);body=tostring(body or''):sub(1,500)
    if not number or #body<1 or not MySQL.scalar.await('SELECT 1 FROM nhr_phone_numbers WHERE phone_number=?',{recipient}) then return false end
    if cooldown[source]and GetGameTimer()-cooldown[source]<2000 then return false end
    cooldown[source]=GetGameTimer();MySQL.insert.await('INSERT INTO nhr_phone_messages (sender,recipient,body) VALUES (?,?,?)',{number,recipient,body})
    local core=exports.nhr_core:GetCoreObject()
    for target,player in pairs(core.Players)do if player.PlayerData.metadata.phone==recipient then TriggerClientEvent('nhr_phone:client:message',target,number,body)break end end
    return true
end)
local function endCall(source)
    local call=calls[source]or pending[source];if not call then return false end
    local other=call.other
    calls[source],pending[source]=nil,nil
    if other then calls[other],pending[other]=nil,nil;exports['pma-voice']:setPlayerCall(other,0);TriggerClientEvent('nhr_phone:client:callEnded',other)end
    exports['pma-voice']:setPlayerCall(source,0);TriggerClientEvent('nhr_phone:client:callEnded',source);return true
end
lib.callback.register('nhr_phone:dial',function(source,recipient)
    local _,number=owner(source);recipient=tostring(recipient or''):gsub('%D',''):sub(1,12)
    if not number or calls[source]or pending[source]then return false,'Line unavailable.'end
    local citizenid=MySQL.scalar.await('SELECT citizenid FROM nhr_phone_numbers WHERE phone_number=?',{recipient});local target=citizenid and exports.nhr_core:GetPlayerByCitizenId(citizenid)
    target=target and target.PlayerData.source
    if not target or target==source or calls[target]or pending[target]or exports.nhr_inventory:GetItemCount(target,'phone')<1 then return false,'The recipient is unavailable.'end
    nextChannel=nextChannel+1;if nextChannel>60000 then nextChannel=2001 end
    local call={other=target,channel=nextChannel,from=number,to=recipient,status='ringing',created=GetGameTimer()}
    calls[source]=call;pending[target]={other=source,channel=nextChannel,from=number,to=recipient,status='ringing',created=call.created}
    TriggerClientEvent('nhr_phone:client:incoming',target,number);return true,'Calling...'
end)
lib.callback.register('nhr_phone:answer',function(source)
    local call=pending[source];if not call or not calls[call.other]then return false end
    pending[source]=nil;calls[source]=call;calls[call.other].status='active';call.status='active'
    exports['pma-voice']:setPlayerCall(source,call.channel);exports['pma-voice']:setPlayerCall(call.other,call.channel)
    TriggerClientEvent('nhr_phone:client:connected',source,call.from);TriggerClientEvent('nhr_phone:client:connected',call.other,call.to);return true
end)
lib.callback.register('nhr_phone:hangup',function(source)return endCall(source)end)
exports.nhr_inventory:RegisterUsableItem('phone',function(source)TriggerClientEvent('nhr_phone:client:open',source)end)
AddEventHandler('playerDropped',function()cooldown[source]=nil endCall(source)end)
CreateThread(function()while true do Wait(5000)local now=GetGameTimer();for source,call in pairs(calls)do if call.status=='ringing'and now-call.created>30000 then endCall(source)end end end end)
