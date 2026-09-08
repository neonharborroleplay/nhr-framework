local stores,sessions={},{ }
local function policeCount()local count=0;for _,p in pairs(exports.nhr_core:GetCoreObject().Players)do if p.PlayerData.job.name=='police'and p.PlayerData.job.onDuty then count=count+1 end end;return count end
local function alert(coords)
    for target,p in pairs(exports.nhr_core:GetCoreObject().Players)do if p.PlayerData.job.name=='police'and p.PlayerData.job.onDuty then TriggerClientEvent('nhr_dispatch:client:alert',target,'Store Robbery','Silent alarm triggered.',{x=coords.x,y=coords.y,z=coords.z})end end
end
lib.callback.register('nhr_robberies:begin',function(source,id)
    local coords=NHRRobberies.stores[id];local now=GetGameTimer()
    if not coords or #(GetEntityCoords(GetPlayerPed(source))-coords)>4.0 or policeCount()<NHRRobberies.minimumPolice then return end
    if stores[id]and stores[id]>now or sessions[source]or exports.nhr_inventory:GetItemCount(source,'lockpick')<1 then return end
    exports.nhr_inventory:RemoveItem(source,'lockpick',1)
    local token=('%d:%d:%d'):format(source,now,math.random(10000,99999))
    sessions[source]={id=id,token=token,ready=now+NHRRobberies.duration-100,expires=now+NHRRobberies.duration+30000}
    stores[id]=now+NHRRobberies.duration+30000;alert(coords);return token
end)
lib.callback.register('nhr_robberies:finish',function(source,token)
    local session=sessions[source];sessions[source]=nil
    if not session or session.token~=token or GetGameTimer()<session.ready or GetGameTimer()>session.expires then return false end
    local coords=NHRRobberies.stores[session.id];if #(GetEntityCoords(GetPlayerPed(source))-coords)>5.0 then return false end
    local reward=math.random(NHRRobberies.reward.min,NHRRobberies.reward.max)
    if not exports.nhr_inventory:AddItem(source,'marked_bills',reward,{source='store_robbery'})then return false end
    stores[session.id]=GetGameTimer()+NHRRobberies.cooldown;return true,reward
end)
RegisterNetEvent('nhr_robberies:server:cancel',function(token)local s=sessions[source];if s and s.token==token then stores[s.id]=nil;sessions[source]=nil end end)
AddEventHandler('playerDropped',function()local s=sessions[source];if s then stores[s.id]=nil end;sessions[source]=nil end)
