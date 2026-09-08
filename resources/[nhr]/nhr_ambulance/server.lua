local function medic(source)
    local player=exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.job.name=='ambulance' and player.PlayerData.job.onDuty
end
local function near(source,target) return target and GetPlayerPed(target)~=0 and #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))<=5.0 end
lib.callback.register('nhr_ambulance:treat',function(source,target)
    target=tonumber(target); if not medic(source) or not near(source,target) then return false end
    TriggerClientEvent('nhr_ambulance:client:heal',target); return true
end)
lib.callback.register('nhr_ambulance:revive',function(source,target)
    target=tonumber(target); if not medic(source) or not near(source,target) then return false end
    return exports.nhr_status:Revive(target)
end)
local validParts={head=true,torso=true,left_arm=true,right_arm=true,left_leg=true,right_leg=true}
RegisterNetEvent('nhr_ambulance:server:injury',function(part,severity)
    local player=exports.nhr_core:GetPlayer(source);severity=math.max(1,math.min(3,math.floor(tonumber(severity)or 1)))
    if not player or not validParts[part]then return end
    local injuries=player.PlayerData.metadata.injuries or{}
    injuries[part]=math.max(injuries[part]or 0,severity);player.Functions.SetMetadata('injuries',injuries)
end)
lib.callback.register('nhr_ambulance:injuries',function(source,target)
    target=tonumber(target);if not medic(source)or not near(source,target)then return end
    local patient=exports.nhr_core:GetPlayer(target);return patient and patient.PlayerData.metadata.injuries or{}
end)
lib.callback.register('nhr_ambulance:treatInjury',function(source,target,part)
    target=tonumber(target);local patient=exports.nhr_core:GetPlayer(target)
    if not medic(source)or not patient or not near(source,target)or not validParts[part]or not exports.nhr_inventory:RemoveItem(source,'bandage',1)then return false end
    local injuries=patient.PlayerData.metadata.injuries or{};injuries[part]=nil;patient.Functions.SetMetadata('injuries',injuries)
    TriggerClientEvent('nhr_ambulance:client:heal',target);return true
end)
