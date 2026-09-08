local deathStages={}

AddEventHandler('nhr_core:server:playerLoaded',function(player)
    local meta=player.PlayerData.metadata or{}
    if meta.isdead then deathStages[player.PlayerData.source]={stage=meta.laststand and'laststand'or'dead',started=GetGameTimer()}end
end)

RegisterNetEvent('nhr_status:server:tick', function()
    if not exports.nhr_security:CheckRateLimit(source, 'status_tick', 2, 55000) then return end
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return end
    local meta = player.PlayerData.metadata
    player.Functions.SetMetadata('hunger', math.max(0, (tonumber(meta.hunger) or 100) - 1))
    player.Functions.SetMetadata('thirst', math.max(0, (tonumber(meta.thirst) or 100) - 2))
end)

RegisterNetEvent('nhr_status:server:setDeath', function(stage)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or (stage ~= 'laststand' and stage ~= 'dead') then return end
    local current=deathStages[source]
    if stage=='laststand'then
        if current then return end
        deathStages[source]={stage='laststand',started=GetGameTimer()}
    else
        if not current or current.stage~='laststand'or GetGameTimer()-current.started<(NHRStatus.lastStandSeconds-2)*1000 then return end
        deathStages[source]={stage='dead',started=GetGameTimer()}
    end
    player.Functions.SetMetadata('isdead', true)
    player.Functions.SetMetadata('laststand', stage == 'laststand')
end)

lib.callback.register('nhr_status:respawn', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not exports.nhr_security:CheckRateLimit(source, 'hospital_respawn', 2, 30000) then return false end
    local current=deathStages[source]
    if not player or not current or current.stage~='dead'or GetGameTimer()-current.started<(NHRStatus.bleedoutSeconds-2)*1000 or not player.PlayerData.metadata.isdead or player.PlayerData.metadata.laststand then return false end
    local paid=0
    if player.Functions.GetMoney('bank') >= NHRStatus.hospitalFee and player.Functions.RemoveMoney('bank', NHRStatus.hospitalFee, 'hospital-respawn')then paid=NHRStatus.hospitalFee end
    player.Functions.SetMetadata('isdead', false)
    player.Functions.SetMetadata('laststand', false)
    deathStages[source]=nil
    if paid>0 then MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'hospital',paid,'Emergency hospital respawn'})end
    exports.nhr_logs:CreateLog('economy','hospital_respawn',source,nil,{fee=paid})
    return true
end)

exports('Revive', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return false end
    player.Functions.SetMetadata('isdead', false)
    player.Functions.SetMetadata('laststand', false)
    deathStages[tonumber(source)]=nil
    TriggerClientEvent('nhr_status:client:revive', source)
    return true
end)
AddEventHandler('playerDropped',function()deathStages[source]=nil end)
