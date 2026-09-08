lib.callback.register('nhr_customs:purchase',function(source,netId,kind,value)
    local player=exports.nhr_core:GetPlayer(source);local vehicle=NetworkGetEntityFromNetworkId(tonumber(netId)or 0)
    if not player or vehicle==0 or not DoesEntityExist(vehicle)or #(GetEntityCoords(GetPlayerPed(source))-NHRCustoms.location)>8.0 or #(GetEntityCoords(vehicle)-NHRCustoms.location)>8.0 then return false end
    local plate=exports.nhr_vehicles:CleanPlate(GetVehicleNumberPlateText(vehicle));if not exports.nhr_vehicles:IsOwner(player.PlayerData.citizenid,plate)then return false end
    local price
    if kind=='repair'then price=NHRCustoms.prices.repair
    elseif kind=='paint'then value=math.max(0,math.min(160,math.floor(tonumber(value)or 0)));price=NHRCustoms.prices.paint
    elseif kind=='engine'then value=math.max(1,math.min(#NHRCustoms.prices.engine,math.floor(tonumber(value)or 1)));price=NHRCustoms.prices.engine[value]
    else return false end
    if not player.Functions.RemoveMoney('bank',price,'vehicle-customization')then return false end
    return true,value
end)
