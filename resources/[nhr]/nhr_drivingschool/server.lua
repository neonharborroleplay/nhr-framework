local sessions={}

local function close(source)
    local session=sessions[source]
    if session and session.vehicle then local vehicle=NetworkGetEntityFromNetworkId(session.vehicle);if vehicle~=0 and DoesEntityExist(vehicle)then DeleteEntity(vehicle)end end
    sessions[source]=nil
end

lib.callback.register('nhr_drivingschool:start',function(source)
    if not exports.nhr_security:CheckRateLimit(source,'driving_exam_start',2,60000)then return false end
    if sessions[source]and GetGameTimer()>sessions[source].expires then close(source)end
    local player=exports.nhr_core:GetPlayer(source)
    if not player or sessions[source]or #(GetEntityCoords(GetPlayerPed(source))-NHRDrivingSchool.start)>6.0 then return false end
    if MySQL.scalar.await("SELECT 1 FROM nhr_licenses WHERE citizenid=? AND license_type='driver'",{player.PlayerData.citizenid})then return false end
    if not player.Functions.RemoveMoney('bank',NHRDrivingSchool.fee,'driving-exam')then return false end
    local token=('dmv:%d:%d'):format(source,math.random(100000,999999))
    sessions[source]={token=token,index=1,vehicle=nil,started=GetGameTimer(),expires=GetGameTimer()+15*60*1000}
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'government_fee',NHRDrivingSchool.fee,'Driving examination'})
    return token
end)

lib.callback.register('nhr_drivingschool:bind',function(source,token,netId)
    local session=sessions[source];if not session or session.token~=token or session.vehicle then return false end
    local vehicle=NetworkGetEntityFromNetworkId(tonumber(netId)or 0)
    if vehicle==0 or not DoesEntityExist(vehicle)or GetEntityModel(vehicle)~=joaat(NHRDrivingSchool.vehicle)or GetPedInVehicleSeat(vehicle,-1)~=GetPlayerPed(source)or #(GetEntityCoords(vehicle)-NHRDrivingSchool.spawn.xyz)>12.0 then return false end
    session.vehicle=tonumber(netId);return true
end)

lib.callback.register('nhr_drivingschool:step',function(source,token,index)
    local session=sessions[source];index=math.floor(tonumber(index)or 0)
    if not session or session.token~=token or session.index~=index or GetGameTimer()>session.expires then close(source)return false end
    local vehicle=NetworkGetEntityFromNetworkId(session.vehicle or 0);local ped=GetPlayerPed(source);local point=NHRDrivingSchool.route[index]
    if vehicle==0 or not DoesEntityExist(vehicle)or GetPedInVehicleSeat(vehicle,-1)~=ped or GetEntityModel(vehicle)~=joaat(NHRDrivingSchool.vehicle)or GetEntityHealth(vehicle)<700 or #(GetEntityCoords(ped)-point)>NHRDrivingSchool.checkpointRadius then close(source)return false end
    if index<#NHRDrivingSchool.route then session.index=index+1;return'continue'end
    local player=exports.nhr_core:GetPlayer(source);if not player then close(source)return false end
    MySQL.prepare.await("INSERT INTO nhr_licenses (citizenid,license_type,issued_by) VALUES (?,'driver',?) ON DUPLICATE KEY UPDATE issued_at=NOW()",{player.PlayerData.citizenid,player.PlayerData.citizenid})
    local info=player.PlayerData.charinfo
    exports.nhr_inventory:AddItem(source,'driver_license',1,{citizenid=player.PlayerData.citizenid,name=info.firstname..' '..info.lastname,birthdate=info.birthdate,gender=info.gender,nationality=info.nationality,license='driver'})
    exports.nhr_logs:CreateLog('economy','driving_exam_passed',source,nil,{vehicle=NHRDrivingSchool.vehicle})
    close(source);return'passed'
end)

lib.callback.register('nhr_drivingschool:cancel',function(source,token,spawnFailed)
    local session=sessions[source];if not session or session.token~=token then return false end
    if spawnFailed==true and not session.vehicle and GetGameTimer()-session.started<30000 then
        local player=exports.nhr_core:GetPlayer(source);if player then player.Functions.AddMoney('bank',NHRDrivingSchool.fee,'driving-exam-refund');MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'exam_refund',NHRDrivingSchool.fee,'Driving examination refund'})end
    end
    close(source);return true
end)

AddEventHandler('playerDropped',function()close(source)end)
