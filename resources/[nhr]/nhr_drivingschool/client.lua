local examVehicle
local function cleanup()
    if examVehicle and DoesEntityExist(examVehicle)then DeleteEntity(examVehicle)end
    examVehicle=nil;lib.hideTextUI()
end

local function startExam()
    if examVehicle then return end
    local token=lib.callback.await('nhr_drivingschool:start',false)
    if not token then return lib.notify({type='error',description='Exam unavailable, already licensed, or payment failed.'})end
    local spawn=NHRDrivingSchool.spawn
    if IsAnyVehicleNearPoint(spawn.x,spawn.y,spawn.z,3.0)then lib.callback.await('nhr_drivingschool:cancel',false,token,true)return lib.notify({type='error',description='Exam spawn is blocked. Fee refunded.'})end
    local model=joaat(NHRDrivingSchool.vehicle);lib.requestModel(model)
    examVehicle=CreateVehicle(model,spawn.x,spawn.y,spawn.z,spawn.w,true,true);SetModelAsNoLongerNeeded(model)
    if examVehicle==0 then lib.callback.await('nhr_drivingschool:cancel',false,token,true)cleanup()return end
    SetPedIntoVehicle(PlayerPedId(),examVehicle,-1)
    if not lib.callback.await('nhr_drivingschool:bind',false,token,NetworkGetNetworkIdFromEntity(examVehicle))then lib.callback.await('nhr_drivingschool:cancel',false,token,true)cleanup()return end
    local first=NHRDrivingSchool.route[1];local blip=AddBlipForCoord(first.x,first.y,first.z);SetBlipRoute(blip,true)
    for index,point in ipairs(NHRDrivingSchool.route)do
        SetBlipCoords(blip,point.x,point.y,point.z)
        local reached=false
        while examVehicle and DoesEntityExist(examVehicle)and not reached do
            Wait(0);DrawMarker(1,point.x,point.y,point.z-1.0,0,0,0,0,0,0,4.0,4.0,1.0,82,211,163,160,false,false,2,false)
            if #(GetEntityCoords(PlayerPedId())-point)<8.0 then reached=true end
            if GetEntityHealth(examVehicle)<700 then reached=true end
            if GetPedInVehicleSeat(examVehicle,-1)~=PlayerPedId()then reached=true end
        end
        if not examVehicle or not DoesEntityExist(examVehicle)then RemoveBlip(blip)lib.callback.await('nhr_drivingschool:cancel',false,token,false)cleanup()return end
        local result=lib.callback.await('nhr_drivingschool:step',false,token,index)
        if not result then RemoveBlip(blip)cleanup()return lib.notify({type='error',description='Driving exam failed.'})end
        if result=='passed'then RemoveBlip(blip)cleanup()return lib.notify({type='success',description='Driving exam passed. License issued.'})end
    end
end

CreateThread(function()exports.ox_target:addSphereZone({coords=NHRDrivingSchool.start,radius=2.0,options={{name='nhr_driving_exam',label=('Driving exam · $%d'):format(NHRDrivingSchool.fee),icon='fa-solid fa-car',onSelect=startExam}}})end)
AddEventHandler('onResourceStop',function(resource)if resource==GetCurrentResourceName()then cleanup()end end)
