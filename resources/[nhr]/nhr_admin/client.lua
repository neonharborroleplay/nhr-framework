local frozen=false
RegisterNetEvent('nhr_admin:client:teleport',function(c)SetEntityCoords(PlayerPedId(),c.x,c.y,c.z,false,false,false,false)end)
RegisterNetEvent('nhr_admin:client:freeze',function()frozen=not frozen FreezeEntityPosition(PlayerPedId(),frozen)lib.notify({description=frozen and 'You were frozen.' or 'You were unfrozen.'})end)
local function playerActions(player)
    lib.registerContext({id='nhr_admin_player',title=player.name..' · '..player.source,menu='nhr_admin',options={
        {title='Go to player',onSelect=function()lib.callback.await('nhr_admin:action',false,'goto',player.source)end},
        {title='Bring player',onSelect=function()lib.callback.await('nhr_admin:action',false,'bring',player.source)end},
        {title='Freeze / unfreeze',onSelect=function()lib.callback.await('nhr_admin:action',false,'freeze',player.source)end},
        {title='Revive',onSelect=function()lib.callback.await('nhr_admin:action',false,'revive',player.source)end},
        {title='Kick',onSelect=function()local x=lib.inputDialog('Kick',{ {type='input',label='Reason',required=true} });if x then lib.callback.await('nhr_admin:action',false,'kick',player.source,x[1])end end},
        {title='Ban',onSelect=function()local x=lib.inputDialog('Ban',{ {type='number',label='Hours (0 = permanent)',min=0,required=true} });if x then lib.callback.await('nhr_admin:action',false,'ban',player.source,x[1])end end}
    }});lib.showContext('nhr_admin_player')
end
RegisterCommand('admin',function()
    local players=lib.callback.await('nhr_admin:players',false);if not players then return end
    local options={}
    for _,entry in ipairs(players)do local player=entry;options[#options+1]={title=player.name,description=player.citizenid..' · ID '..player.source,onSelect=function()playerActions(player)end}end
    options[#options+1]={title='Open reports',onSelect=function()ExecuteCommand('reports')end}
    lib.registerContext({id='nhr_admin',title='NHR Administration',options=options});lib.showContext('nhr_admin')
end,false)
RegisterCommand('reports',function()
    local reports=lib.callback.await('nhr_admin:reports',false);if not reports then return end
    local options={};for _,entry in ipairs(reports)do local report=entry;options[#options+1]={title=('#%d · %s'):format(report.id,report.status),description=report.message,onSelect=function()lib.callback.await('nhr_admin:reportAction',false,report.id,report.status=='open' and 'claimed' or 'closed')end}end
    lib.registerContext({id='nhr_reports',title='Player Reports',options=options});lib.showContext('nhr_reports')
end,false)
RegisterCommand('report',function(_,args)local message=table.concat(args,' ');if #message<5 then return lib.notify({type='error',description='Usage: /report your message'})end TriggerServerEvent('nhr_admin:server:report',message)lib.notify({description='Report submitted.'})end,false)
