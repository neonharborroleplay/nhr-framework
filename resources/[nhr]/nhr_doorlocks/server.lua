local states={}
MySQL.ready(function()
    for id,door in pairs(NHRDoors)do
        MySQL.insert.await('INSERT IGNORE INTO nhr_doors (door_id,locked) VALUES (?,?)',{id,door.locked and 1 or 0})
        states[id]=(MySQL.scalar.await('SELECT locked FROM nhr_doors WHERE door_id=?',{id}) or 0)==1
    end
    TriggerClientEvent('nhr_doorlocks:client:sync',-1,states)
end)
lib.callback.register('nhr_doorlocks:states',function()return states end)
lib.callback.register('nhr_doorlocks:toggle',function(source,id)
    local door,player=NHRDoors[id],exports.nhr_core:GetPlayer(source)
    if not door or not player or #(GetEntityCoords(GetPlayerPed(source))-door.coords)>4.0 then return false end
    local minGrade=door.groups[player.PlayerData.job.name]
    if minGrade==nil or player.PlayerData.job.grade<minGrade or not player.PlayerData.job.onDuty then return false end
    states[id]=not states[id]
    MySQL.update.await('UPDATE nhr_doors SET locked=? WHERE door_id=?',{states[id] and 1 or 0,id})
    TriggerClientEvent('nhr_doorlocks:client:set',-1,id,states[id])
    return true
end)
