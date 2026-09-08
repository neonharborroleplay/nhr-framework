local opened=false
local function pushData()
    local data=lib.callback.await('nhr_phone:data',false);if not data then return false end
    SendNUIMessage({action='data',data=data});return true
end
local function openPhone()
    if not pushData()then return lib.notify({type='error',description='You need a phone.'})end
    opened=true;SetNuiFocus(true,true);SendNUIMessage({action='open'})
end
RegisterNetEvent('nhr_phone:client:open',openPhone)
RegisterNetEvent('nhr_phone:client:message',function(number,body)lib.notify({title='Message from '..number,description=body,duration=8000});if opened then pushData()end end)
RegisterNetEvent('nhr_phone:client:incoming',function(number)opened=true;SetNuiFocus(true,true);SendNUIMessage({action='open'});SendNUIMessage({action='incoming',number=number})end)
RegisterNetEvent('nhr_phone:client:connected',function(number)SendNUIMessage({action='connected',number=number})end)
RegisterNetEvent('nhr_phone:client:callEnded',function()SendNUIMessage({action='ended'})end)
RegisterNUICallback('close',function(_,cb)opened=false;SetNuiFocus(false,false);SendNUIMessage({action='close'});cb(true)end)
RegisterNUICallback('send',function(data,cb)local ok=lib.callback.await('nhr_phone:send',false,data.number,data.body);cb(ok);if ok then pushData()end end)
RegisterNUICallback('contact',function(data,cb)local ok=lib.callback.await('nhr_phone:addContact',false,data.name,data.number);cb(ok);if ok then pushData()end end)
RegisterNUICallback('call',function(data,cb)local ok,message=lib.callback.await('nhr_phone:dial',false,data.number);cb({ok=ok,message=message})end)
RegisterNUICallback('answer',function(_,cb)cb(lib.callback.await('nhr_phone:answer',false))end)
RegisterNUICallback('hangup',function(_,cb)cb(lib.callback.await('nhr_phone:hangup',false))end)
RegisterNUICallback('service',function(data,cb)local coords=GetEntityCoords(PlayerPedId());TriggerServerEvent('nhr_dispatch:server:alert',data.service,'Service Request','A customer is requesting service.',{x=coords.x,y=coords.y,z=coords.z});cb(true)end)
RegisterCommand('phone',openPhone,false)
RegisterKeyMapping('phone','Open phone','keyboard','F1')
