local evidence={}
RegisterNetEvent('nhr_evidence:client:add',function(entry)evidence[entry.id]=entry end)
RegisterNetEvent('nhr_evidence:client:remove',function(id)evidence[id]=nil end)
AddEventHandler('nhr_core:client:onPlayerLoaded',function(data)if data.job.name=='police' then evidence=lib.callback.await('nhr_evidence:list',false) or {} end end)
AddEventHandler('nhr_core:client:playerDataChanged',function(data)if data.job.name=='police' and data.job.onDuty then evidence=lib.callback.await('nhr_evidence:list',false) or {} else evidence={} end end)
CreateThread(function()
    while true do
        Wait(0)
        if IsPedShooting(PlayerPedId()) then
            local coords=GetEntityCoords(PlayerPedId())
            TriggerServerEvent('nhr_evidence:server:casing',GetSelectedPedWeapon(PlayerPedId()),{x=coords.x,y=coords.y,z=coords.z})
            Wait(1000)
        end
    end
end)
CreateThread(function()
    while true do
        local wait=1000;local coords=GetEntityCoords(PlayerPedId())
        for id,entry in pairs(evidence) do
            local point=vec3(entry.coords.x,entry.coords.y,entry.coords.z);local distance=#(coords-point)
            if distance<15.0 then wait=0 DrawMarker(2,point.x,point.y,point.z+0.1,0,0,0,0,180.0,0,0.15,0.15,0.15,255,200,40,180,false,true,2,false)
                if distance<1.5 and IsControlJustReleased(0,38) then lib.callback.await('nhr_evidence:collect',false,id) end
            end
        end
        Wait(wait)
    end
end)
