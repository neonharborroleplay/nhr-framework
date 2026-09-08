local activeTestDrive
local function openDealer()
    local options = {}
    for _, definition in ipairs(NHRDealership.vehicles) do
        local vehicle = definition
        options[#options + 1] = { title = vehicle.label, description = ('$%s · bank payment'):format(vehicle.price), icon = 'car', onSelect = function()
            local confirm = lib.alertDialog({ header = vehicle.label, content = ('Purchase for $%d? It will be sent to Legion Garage.'):format(vehicle.price), cancel = true })
            if confirm ~= 'confirm' then return end
            local ok, message = lib.callback.await('nhr_dealership:buy', false, vehicle.model)
            lib.notify({ type = ok and 'success' or 'error', description = message })
        end }
        options[#options + 1] = { title = vehicle.label .. ' · Finance', description = ('20%% down on $%s'):format(vehicle.price), icon = 'file-invoice-dollar', onSelect = function()
            local ok,message=lib.callback.await('nhr_dealership:finance',false,vehicle.model);lib.notify({type=ok and'success'or'error',description=message})
        end }
        options[#options + 1] = { title = vehicle.label .. ' · Test drive', description = '60 second local test drive', icon = 'stopwatch', onSelect = function()
            if activeTestDrive and DoesEntityExist(activeTestDrive)then return lib.notify({type='error',description='You already have a test drive active.'})end
            local model=joaat(vehicle.model);lib.requestModel(model);local s=NHRDealership.spawn
            if IsAnyVehicleNearPoint(s.x,s.y,s.z,3.0)then return lib.notify({type='error',description='Test-drive area is blocked.'})end
            local test=CreateVehicle(model,s.x,s.y,s.z,s.w,false,false);activeTestDrive=test;SetPedIntoVehicle(PlayerPedId(),test,-1);lib.notify({description='Test drive ends in 60 seconds.'})
            CreateThread(function()Wait(60000);if DoesEntityExist(test)then DeleteEntity(test)end;activeTestDrive=nil;SetEntityCoords(PlayerPedId(),NHRDealership.location.x,NHRDealership.location.y,NHRDealership.location.z,false,false,false,false)end)
        end }
    end
    lib.registerContext({ id = 'nhr_dealer', title = 'Premium Deluxe Motorsport', options = options })
    lib.showContext('nhr_dealer')
end

CreateThread(function()
    exports.ox_target:addSphereZone({ coords = NHRDealership.location, radius = 2.0, options = {
        { name = 'nhr_dealer', label = 'Browse vehicles', icon = 'fa-solid fa-car', onSelect = openDealer }
    } })
end)
