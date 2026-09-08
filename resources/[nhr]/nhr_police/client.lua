local cuffed = false
local function closest()
    local player = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 4.0, false)
    return player and GetPlayerServerId(player)
end
RegisterCommand('cuff', function() local target=closest(); if target then lib.callback.await('nhr_police:cuff',false,target) end end, false)
RegisterCommand('jail', function()
    local target=closest(); if not target then return end
    local input=lib.inputDialog('Jail sentence',{ {type='number',label='Minutes',min=1,max=120,required=true} })
    if input then lib.callback.await('nhr_police:jail',false,target,input[1]) end
end, false)
RegisterCommand('search',function()local target=closest();if target then lib.callback.await('nhr_police:search',false,target)end end,false)
RegisterCommand('escort',function()local target=closest();if target then lib.callback.await('nhr_police:escort',false,target)end end,false)
RegisterCommand('citation',function()local target=closest();if not target then return end;local x=lib.inputDialog('Issue Citation',{{type='number',label='Amount',min=1,max=100000,required=true},{type='input',label='Reason',required=true}});if x then lib.callback.await('nhr_police:citation',false,target,x[1],x[2])end end,false)
RegisterCommand('citations',function()
    local rows=lib.callback.await('nhr_police:citations',false);local options={}
    for _,row in ipairs(rows or{})do local citation=row;options[#options+1]={title=('$%d · %s'):format(citation.amount,citation.paid==1 and'Paid'or'Unpaid'),description=('%s · %s'):format(citation.reason,citation.created_at),disabled=citation.paid==1,onSelect=function()local ok=lib.callback.await('nhr_police:payCitation',false,citation.id);lib.notify({type=ok and'success'or'error',description=ok and'Citation paid.'or'Payment failed.'})end}end
    if #options==0 then options[1]={title='No citations',disabled=true}end
    lib.registerContext({id='nhr_citations',title='My citations',options=options});lib.showContext('nhr_citations')
end,false)
RegisterCommand('warrant',function()local x=lib.inputDialog('Issue Warrant',{{type='input',label='Citizen ID',required=true},{type='textarea',label='Reason',required=true}});if x then lib.callback.await('nhr_police:warrant',false,x[1],x[2])end end,false)
RegisterCommand('panic', function()
    local job=exports.nhr_core:GetCoreObject().PlayerData.job
    if job and job.name=='police' and job.onDuty then exports.nhr_dispatch:SendAlert('police','Officer panic button','An officer requires immediate assistance.') end
end, false)
RegisterNetEvent('nhr_police:client:cuffed', function(value) cuffed=value if value then TaskHandsUp(PlayerPedId(),-1,-1,-1,true) else ClearPedTasks(PlayerPedId()) end end)
RegisterNetEvent('nhr_police:client:jailed', function() cuffed=false SetEntityCoords(PlayerPedId(),1641.6,2571.0,45.6,false,false,false,false) end)
RegisterNetEvent('nhr_police:client:escort',function(officerId)
    if not officerId then return DetachEntity(PlayerPedId(),true,false)end
    local player=GetPlayerFromServerId(officerId);if player~=-1 then AttachEntityToEntity(PlayerPedId(),GetPlayerPed(player),11816,0.35,0.45,0.0,0.0,0.0,0.0,false,false,false,true,2,true)end
end)
RegisterNetEvent('nhr_police:client:released', function() SetEntityCoords(PlayerPedId(),1847.7,2586.1,45.7,false,false,false,false) lib.notify({description='Your sentence is complete.'}) end)
RegisterNetEvent('nhr_police:client:citationReceived',function(amount,reason)lib.notify({title=('New citation · $%d'):format(amount),description=reason,duration=8000})end)
AddEventHandler('nhr_core:client:onPlayerLoaded', function(data) if (data.metadata.jail or 0)>0 then TriggerEvent('nhr_police:client:jailed') end end)
CreateThread(function() while true do if cuffed then Wait(0) DisableControlAction(0,24,true) DisableControlAction(0,25,true) DisableControlAction(0,75,true) else Wait(500) end end end)
