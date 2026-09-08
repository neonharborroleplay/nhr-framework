local inside,insideOwner
local furnitureObjects={}
local function clearFurniture()
    for _,object in pairs(furnitureObjects)do if DoesEntityExist(object)then DeleteEntity(object)end end
    furnitureObjects={}
end
local function renderFurniture(rows)
    clearFurniture()
    for _,row in ipairs(rows or{})do
        local hash=joaat(row.model);lib.requestModel(hash)
        local object=CreateObject(hash,tonumber(row.x),tonumber(row.y),tonumber(row.z),false,false,false)
        SetEntityHeading(object,tonumber(row.heading)or 0.0);FreezeEntityPosition(object,true);furnitureObjects[tonumber(row.id)]=object
        SetModelAsNoLongerNeeded(hash)
    end
end
RegisterNetEvent('nhr_housing:client:furniture',renderFurniture)
local function enterProperty(id)
    local data=lib.callback.await('nhr_housing:enter',false,id)
    if data then local pos=data.position;inside=id;insideOwner=data.owned==true;SetEntityCoords(PlayerPedId(),pos.x,pos.y,pos.z,false,false,false,false);SetEntityHeading(PlayerPedId(),pos.w);renderFurniture(data.furniture)end
end
local function manageKey(id)
    local target=lib.getClosestPlayer(GetEntityCoords(PlayerPedId()),5.0,false)
    if not target then return lib.notify({type='error',description='No player nearby.'})end
    local input=lib.inputDialog('Property access',{{type='select',label='Action',required=true,options={{value='grant',label='Grant key'},{value='revoke',label='Revoke key'}}}})
    if not input then return end
    local ok=lib.callback.await('nhr_housing:key',false,id,GetPlayerServerId(target),input[1])
    lib.notify({type=ok and'success'or'error',description=ok and'Property access updated.'or'Unable to update access.'})
end
local function propertyMenu(id)
    local info=lib.callback.await('nhr_housing:info',false,id);if not info then return end
    local options={}
    if info.hasAccess then options[#options+1]={title='Enter property',description=info.owned and'Owner access'or'Keyholder access',onSelect=function()enterProperty(id)end}end
    if info.owned then
        options[#options+1]={title='Manage nearby keyholder',onSelect=function()manageKey(id)end}
        if info.rental then
            options[#options+1]={title=('Renew seven days · $%d'):format(info.rent),description='Current due date: '..tostring(info.rentDue),onSelect=function()local ok=lib.callback.await('nhr_housing:renew',false,id);lib.notify({type=ok and'success'or'error',description=ok and'Lease renewed.'or'Renewal failed.'})end}
            options[#options+1]={title='End lease',onSelect=function()local answer=lib.alertDialog({header='End lease?',content='This immediately removes all access without a refund.',cancel=true,centered=true});if answer=='confirm'then local ok=lib.callback.await('nhr_housing:endLease',false,id);lib.notify({type=ok and'success'or'error',description=ok and'Lease ended.'or'Unable to end lease.'})end end}
        else options[#options+1]={title=('Sell to city · $%d'):format(math.floor(info.price*0.6)),onSelect=function()local answer=lib.alertDialog({header='Sell property?',content='All keyholders will be removed. Placed furniture remains with the property.',cancel=true,centered=true});if answer=='confirm'then local refund=lib.callback.await('nhr_housing:sell',false,id);lib.notify({type=refund and'success'or'error',description=refund and('Property sold for $'..refund)or'Sale failed.'})end end}end
    elseif not info.sold then
        options[#options+1]={title=('Purchase · $%d'):format(info.price),onSelect=function()local ok=lib.callback.await('nhr_housing:buy',false,id);lib.notify({type=ok and 'success'or'error',description=ok and'Property purchased.'or'Purchase failed.'})end}
        options[#options+1]={title=('Rent seven days · $%d'):format(info.rent),onSelect=function()local ok=lib.callback.await('nhr_housing:rent',false,id);lib.notify({type=ok and'success'or'error',description=ok and'Lease started.'or'Rental failed.'})end}
    elseif not info.hasAccess then options[#options+1]={title='Property is privately owned',disabled=true}end
    lib.registerContext({id='nhr_property',title=info.label,options=options});lib.showContext('nhr_property')
end
RegisterCommand('furnish',function()
    if not inside or not insideOwner then return lib.notify({type='error',description='You must be inside a property you own.'})end
    local choices={};for key,item in pairs(NHRHousingFurniture)do choices[#choices+1]={value=key,label=('%s · $%d'):format(item.label,item.price)}end
    local input=lib.inputDialog('Property furniture',{{type='select',label='Action',required=true,options={{value='place',label='Place furniture'},{value='remove',label='Remove nearest'}}},{type='select',label='Furniture',options=choices}})
    if not input then return end
    local rows
    if input[1]=='place'then
        if not input[2]then return end
        local coords=GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,1.2,0.0)
        rows=lib.callback.await('nhr_housing:placeFurniture',false,inside,input[2],{x=coords.x,y=coords.y,z=coords.z},GetEntityHeading(PlayerPedId()))
    else
        local closestId,distance
        for id,object in pairs(furnitureObjects)do local value=#(GetEntityCoords(PlayerPedId())-GetEntityCoords(object));if not distance or value<distance then closestId,distance=id,value end end
        if not closestId or distance>3.5 then return lib.notify({type='error',description='No furniture nearby.'})end
        rows=lib.callback.await('nhr_housing:removeFurniture',false,inside,closestId)
    end
    if rows then renderFurniture(rows)lib.notify({type='success',description='Furniture updated.'})else lib.notify({type='error',description='Unable to update furniture.'})end
end,false)
RegisterNetEvent('nhr_housing:client:evicted',function(id,message)
    if inside~=id then return end
    local entrance=NHRProperties[id].entrance;inside=nil;insideOwner=nil;clearFurniture();SetEntityCoords(PlayerPedId(),entrance.x,entrance.y,entrance.z,false,false,false,false)
    lib.notify({type='error',description=message or'Property access ended.'})
end)
RegisterNetEvent('nhr_housing:client:leaseExpired',function(label)lib.notify({type='error',title='Lease expired',description=tostring(label)})end)
CreateThread(function()for id,property in pairs(NHRProperties)do local propertyId=id;exports.ox_target:addSphereZone({coords=property.entrance,radius=1.5,options={{name='nhr_property_'..propertyId,label=property.label,icon='fa-solid fa-house',onSelect=function()propertyMenu(propertyId)end}}})end end)
CreateThread(function()
    while true do
        if inside then
            Wait(0);local coords=GetEntityCoords(PlayerPedId())
            if #(coords-NHRHousingInterior.exit)<1.5 then lib.showTextUI('[E] Exit property');if IsControlJustReleased(0,38)then lib.hideTextUI()TriggerServerEvent('nhr_housing:server:exit',inside)local entrance=NHRProperties[inside].entrance;inside=nil;insideOwner=nil;clearFurniture();SetEntityCoords(PlayerPedId(),entrance.x,entrance.y,entrance.z,false,false,false,false)end
            elseif #(coords-NHRHousingInterior.stash)<1.5 then lib.showTextUI('[E] Property storage');if IsControlJustReleased(0,38)then lib.hideTextUI()TriggerServerEvent('nhr_housing:server:stash',inside)Wait(500)end
            else lib.hideTextUI()end
        else Wait(500)end
    end
end)
AddEventHandler('onResourceStop',function(resource)if resource==GetCurrentResourceName()then clearFurniture()end end)
AddEventHandler('nhr_core:client:onPlayerUnloaded',function()inside=nil;insideOwner=nil;clearFurniture()end)
