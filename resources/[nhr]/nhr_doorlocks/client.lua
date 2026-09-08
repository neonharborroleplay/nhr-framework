local states={}
local function apply(id,locked)
    local door=NHRDoors[id];if not door then return end
    local systemId=joaat('nhr_door_'..id)
    if not IsDoorRegisteredWithSystem(systemId)then AddDoorToSystem(systemId,door.model,door.coords.x,door.coords.y,door.coords.z,false,false,false)end
    DoorSystemSetDoorState(systemId,locked and 1 or 0,false,false)
end
RegisterNetEvent('nhr_doorlocks:client:set',function(id,locked)states[id]=locked apply(id,locked)end)
RegisterNetEvent('nhr_doorlocks:client:sync',function(serverStates)states=serverStates for id,locked in pairs(states)do apply(id,locked)end end)
CreateThread(function()
    states=lib.callback.await('nhr_doorlocks:states',false)or{}
    for id,door in pairs(NHRDoors)do
        apply(id,states[id]~=false)
        local doorId=id
        exports.ox_target:addSphereZone({coords=door.coords,radius=1.3,options={{name='nhr_door_'..doorId,label='Toggle door lock',icon='fa-solid fa-lock',onSelect=function()lib.callback.await('nhr_doorlocks:toggle',false,doorId)end}}})
    end
end)
