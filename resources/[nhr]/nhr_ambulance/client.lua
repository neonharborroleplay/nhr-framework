local function closest() local p=lib.getClosestPlayer(GetEntityCoords(PlayerPedId()),4.0,false); return p and GetPlayerServerId(p) end
RegisterCommand('treat',function() local target=closest(); if target then lib.callback.await('nhr_ambulance:treat',false,target) end end,false)
RegisterCommand('revive',function() local target=closest(); if target then lib.callback.await('nhr_ambulance:revive',false,target) end end,false)
RegisterCommand('ems',function() exports.nhr_dispatch:SendAlert('ambulance','Medical assistance','A civilian has requested emergency medical assistance.') end,false)
RegisterNetEvent('nhr_ambulance:client:heal',function() SetEntityHealth(PlayerPedId(),math.min(GetEntityMaxHealth(PlayerPedId()),GetEntityHealth(PlayerPedId())+50)) end)
local bones={ [31086]='head',[24818]='torso',[18905]='left_arm',[57005]='right_arm',[63931]='left_leg',[36864]='right_leg' }
AddEventHandler('gameEventTriggered',function(name,args)
    if name~='CEventNetworkEntityDamage'or args[1]~=PlayerPedId()then return end
    local _,bone=GetPedLastDamageBone(PlayerPedId());local part=bones[bone]or'torso';local health=GetEntityHealth(PlayerPedId())
    TriggerServerEvent('nhr_ambulance:server:injury',part,health<130 and 3 or health<170 and 2 or 1)
end)
RegisterCommand('injuries',function()
    local target=closest();if not target then return end;local injuries=lib.callback.await('nhr_ambulance:injuries',false,target);if not injuries then return end
    local options={};for part,severity in pairs(injuries)do local bodyPart=part;options[#options+1]={title=part:gsub('_',' '),description='Severity '..severity..' · consumes one bandage',onSelect=function()lib.callback.await('nhr_ambulance:treatInjury',false,target,bodyPart)end}end
    lib.registerContext({id='nhr_injuries',title='Patient Injuries',options=options});lib.showContext('nhr_injuries')
end,false)
