local function allowed(source) return source == 0 or IsPlayerAceAllowed(source, 'nhr.admin') end
local function actor(source)
    local player=exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.citizenid or exports.nhr_core:GetLicense(source) or ('source:'..source)
end
local function audit(source,action,target,details)
    exports.nhr_logs:CreateLog('admin',action,source,target,details or{})
end
local function reviveCommand(source,args)
    if not allowed(source) then return end
    local target=tonumber(args[1])or(source>0 and source or nil)
    if not target or not exports.nhr_core:GetPlayer(target) then
        if source>0 then TriggerClientEvent('ox_lib:notify',source,{type='error',description='Player not found.'})end
        return
    end
    if exports.nhr_status:Revive(target)then
        audit(source,'command_revive',target,{})
        if source>0 then TriggerClientEvent('ox_lib:notify',source,{description=('Revived player %d.'):format(target)})end
    end
end
RegisterCommand('heal',reviveCommand,false)
RegisterCommand('nhrrevive',reviveCommand,false)
lib.callback.register('nhr_admin:players',function(source)
    if not allowed(source) then return end
    local result={};local core=exports.nhr_core:GetCoreObject()
    for id,player in pairs(core.Players) do result[#result+1]={source=id,citizenid=player.PlayerData.citizenid,name=player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname} end
    return result
end)
lib.callback.register('nhr_admin:action',function(source,action,target,extra)
    if not allowed(source) then return false end
    target=tonumber(target);local player=target and exports.nhr_core:GetPlayer(target)
    if not player then return false end
    if action=='goto' then local c=GetEntityCoords(GetPlayerPed(target));TriggerClientEvent('nhr_admin:client:teleport',source,{x=c.x,y=c.y,z=c.z})
    elseif action=='bring' then local c=GetEntityCoords(GetPlayerPed(source));TriggerClientEvent('nhr_admin:client:teleport',target,{x=c.x,y=c.y,z=c.z})
    elseif action=='freeze' then TriggerClientEvent('nhr_admin:client:freeze',target)
    elseif action=='revive' then exports.nhr_status:Revive(target)
    elseif action=='kick' then audit(source,action,player.PlayerData.citizenid,{reason=extra});DropPlayer(target,tostring(extra or 'Removed by staff.'));return true
    elseif action=='ban' then
        local hours=math.max(0,math.floor(tonumber(extra) or 0))
        if hours>0 then MySQL.insert.await('INSERT INTO nhr_bans (license,reason,expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))',{player.PlayerData.license,'Administrative ban',hours})
        else MySQL.insert.await('INSERT INTO nhr_bans (license,reason) VALUES (?,?)',{player.PlayerData.license,'Administrative ban'})end
        audit(source,action,player.PlayerData.citizenid,{hours=hours});DropPlayer(target,'You have been banned.');return true
    else return false end
    audit(source,action,player.PlayerData.citizenid,{extra=extra});return true
end)
lib.callback.register('nhr_admin:reports',function(source)
    if not allowed(source) then return end
    return MySQL.query.await("SELECT * FROM nhr_reports WHERE status!='closed' ORDER BY id") or {}
end)
lib.callback.register('nhr_admin:reportAction',function(source,id,status)
    if not allowed(source) or (status~='claimed' and status~='closed') then return false end
    local changed=MySQL.update.await("UPDATE nhr_reports SET status=?,staff=? WHERE id=? AND status!='closed'",{status,actor(source),tonumber(id)})
    if changed==1 then audit(source,'report_'..status,id);return true end
    return false
end)
local reportCooldown={}
RegisterNetEvent('nhr_admin:server:report',function(message)
    local player=exports.nhr_core:GetPlayer(source);message=tostring(message or ''):sub(1,500)
    if not player or #message<5 or reportCooldown[source]and GetGameTimer()-reportCooldown[source]<60000 then return end
    reportCooldown[source]=GetGameTimer()
    MySQL.insert('INSERT INTO nhr_reports (citizenid,message) VALUES (?,?)',{player.PlayerData.citizenid,message})
end)
AddEventHandler('playerDropped',function()reportCooldown[source]=nil end)
AddEventHandler('playerConnecting',function(_,_,deferrals)
    local src=source;deferrals.defer();Wait(0)
    local license=exports.nhr_core:GetLicense(src)
    local ban=license and MySQL.single.await('SELECT reason,expires_at FROM nhr_bans WHERE license=? AND (expires_at IS NULL OR expires_at>NOW()) ORDER BY id DESC LIMIT 1',{license})
    if ban then deferrals.done('NHR: '..ban.reason) else deferrals.done() end
end)
