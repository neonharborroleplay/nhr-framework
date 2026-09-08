local function rob(id)
    local token=lib.callback.await('nhr_robberies:begin',false,id)
    if not token then return lib.notify({type='error',description='The register cannot be robbed right now.'})end
    local success=lib.skillCheck({'easy','medium','medium'},{'w','a','s','d'})
    if not success then TriggerServerEvent('nhr_robberies:server:cancel',token)return end
    if not lib.progressCircle({duration=NHRRobberies.duration,label='Emptying register',canCancel=true,disable={move=true,combat=true}})then TriggerServerEvent('nhr_robberies:server:cancel',token)return end
    local ok,reward=lib.callback.await('nhr_robberies:finish',false,token);lib.notify({type=ok and'success'or'error',description=ok and('Stole $'..reward..' in marked bills.')or'Robbery failed.'})
end
CreateThread(function()for id,coords in pairs(NHRRobberies.stores)do local storeId=id;exports.ox_target:addSphereZone({coords=coords,radius=1.0,options={{name='nhr_rob_'..storeId,label='Rob register',icon='fa-solid fa-mask-face',onSelect=function()rob(storeId)end}}})end end)
