local function customize()
    local vehicle=GetVehiclePedIsIn(PlayerPedId(),false);if vehicle==0 or GetPedInVehicleSeat(vehicle,-1)~=PlayerPedId()then return lib.notify({type='error',description='Enter your vehicle as driver.'})end
    local netId=NetworkGetNetworkIdFromEntity(vehicle)
    lib.registerContext({id='nhr_customs',title='NHR Customs',options={
        {title='Full repair',description='$'..NHRCustoms.prices.repair,onSelect=function()if lib.callback.await('nhr_customs:purchase',false,netId,'repair')then SetVehicleFixed(vehicle)SetVehicleDeformationFixed(vehicle)end end},
        {title='Primary paint',description='$'..NHRCustoms.prices.paint,onSelect=function()local x=lib.inputDialog('Paint',{{type='number',label='GTA color index',min=0,max=160,required=true}});if x then local ok,color=lib.callback.await('nhr_customs:purchase',false,netId,'paint',x[1]);if ok then local _,secondary=GetVehicleColours(vehicle);SetVehicleColours(vehicle,color,secondary)end end end},
        {title='Engine upgrade',description='Levels 1–4',onSelect=function()local x=lib.inputDialog('Engine Upgrade',{{type='number',label='Level',min=1,max=4,required=true}});if x then local ok,level=lib.callback.await('nhr_customs:purchase',false,netId,'engine',x[1]);if ok then SetVehicleModKit(vehicle,0)SetVehicleMod(vehicle,11,level-1,false)end end end}
    }});lib.showContext('nhr_customs')
end
CreateThread(function()exports.ox_target:addSphereZone({coords=NHRCustoms.location,radius=3.5,options={{name='nhr_customs',label='Customize vehicle',icon='fa-solid fa-screwdriver-wrench',onSelect=customize}}})end)
