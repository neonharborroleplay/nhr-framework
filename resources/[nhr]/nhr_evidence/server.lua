local active, cooldown = {}, {}
local function police(source)
    local player=exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.job.name=='police' and player.PlayerData.job.onDuty and player
end
RegisterNetEvent('nhr_evidence:server:casing',function(weapon,coords)
    local src=source
    if cooldown[src] and GetGameTimer()-cooldown[src]<1000 then return end
    local actual=GetEntityCoords(GetPlayerPed(src))
    local location=type(coords)=='table' and vec3(tonumber(coords.x) or 0,tonumber(coords.y) or 0,tonumber(coords.z) or 0)
    if not location or #(actual-location)>5.0 then return end
    cooldown[src]=GetGameTimer()
    local data={weapon=tonumber(weapon) or 0,source=src}
    local position={x=location.x,y=location.y,z=location.z}
    local id=MySQL.insert.await('INSERT INTO nhr_evidence (evidence_type,data,coords) VALUES (?,?,?)',{'casing',json.encode(data),json.encode(position)})
    if not id then return end
    active[id]={id=id,evidence_type='casing',data=data,coords=position}
    local core=exports.nhr_core:GetCoreObject()
    for target,player in pairs(core.Players) do if player.PlayerData.job.name=='police' and player.PlayerData.job.onDuty then TriggerClientEvent('nhr_evidence:client:add',target,active[id]) end end
end)
lib.callback.register('nhr_evidence:list',function(source)
    if not police(source) then return {} end
    if next(active)==nil then
        local rows=MySQL.query.await('SELECT id,evidence_type,data,coords FROM nhr_evidence WHERE collected_by IS NULL AND created_at > DATE_SUB(NOW(), INTERVAL 2 HOUR)') or {}
        for _,row in ipairs(rows) do row.data=json.decode(row.data);row.coords=json.decode(row.coords);active[row.id]=row end
    end
    return active
end)
lib.callback.register('nhr_evidence:collect',function(source,id)
    local officer=police(source); local evidence=active[tonumber(id)]
    if not officer or not evidence then return false end
    local coords=GetEntityCoords(GetPlayerPed(source));local point=vec3(evidence.coords.x,evidence.coords.y,evidence.coords.z)
    if #(coords-point)>3.0 then return false end
    if not exports.nhr_inventory:CanCarryItem(source,'evidence_bag',1) then return false end
    local changed=MySQL.update.await('UPDATE nhr_evidence SET collected_by=? WHERE id=? AND collected_by IS NULL',{officer.PlayerData.citizenid,evidence.id})
    if changed~=1 then active[evidence.id]=nil return false end
    local added=exports.nhr_inventory:AddItem(source,'evidence_bag',1,{evidenceId=evidence.id,type=evidence.evidence_type,data=evidence.data})
    if not added then
        MySQL.update.await('UPDATE nhr_evidence SET collected_by=NULL WHERE id=? AND collected_by=?',{evidence.id,officer.PlayerData.citizenid})
        return false
    end
    active[evidence.id]=nil
    TriggerClientEvent('nhr_evidence:client:remove',-1,evidence.id)
    return true
end)
AddEventHandler('playerDropped',function() cooldown[source]=nil end)
