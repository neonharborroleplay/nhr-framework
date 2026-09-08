local open = false
local drops = {}
local vehicleContainer = false

local function refresh()
    local inventory, secondary
    if vehicleContainer then inventory, secondary = lib.callback.await('nhr_inventory:getOpen', false)
    else inventory = lib.callback.await('nhr_inventory:getPlayer', false) end
    if inventory then SendNUIMessage({ action = 'inventory', inventory = inventory, secondary = secondary, definitions = NHRInventory.Items }) end
end

local function toggle()
    if not LocalPlayer.state.isLoggedIn then return end
    open = not open
    vehicleContainer = false
    SetNuiFocus(open, open)
    SendNUIMessage({ action = open and 'open' or 'close' })
    if open then refresh() end
    if not open then TriggerServerEvent('nhr_inventory:server:close') end
end

RegisterCommand('inventory', toggle, false)
RegisterKeyMapping('inventory', 'Open inventory', 'keyboard', 'F2')

RegisterNUICallback('close', function(_, cb)
    open = false
    vehicleContainer = false
    TriggerServerEvent('nhr_inventory:server:close')
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb(true)
end)
RegisterNUICallback('use', function(data, cb) cb(lib.callback.await('nhr_inventory:use', false, data.slot)); refresh() end)
RegisterNUICallback('drop', function(data, cb) cb(lib.callback.await('nhr_inventory:drop', false, data.slot, data.count)); refresh() end)
RegisterNUICallback('transfer', function(data, cb) cb(lib.callback.await('nhr_inventory:transfer', false, data.from, data.to, data.slot, data.count)); refresh() end)

local function openVehicleContainer(kind)
    local vehicle = kind == 'glovebox' and GetVehiclePedIsIn(PlayerPedId(), false) or lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 3.5, false)
    if not vehicle or vehicle == 0 then return lib.notify({ type = 'error', description = 'No vehicle nearby.' }) end
    local primary, secondary = lib.callback.await('nhr_inventory:openVehicle', false, NetworkGetNetworkIdFromEntity(vehicle), kind)
    if not primary then return lib.notify({ type = 'error', description = 'Container is locked or inaccessible.' }) end
    vehicleContainer, open = true, true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    SendNUIMessage({ action = 'inventory', inventory = primary, secondary = secondary, definitions = NHRInventory.Items })
end

RegisterCommand('trunk', function() openVehicleContainer('trunk') end, false)
RegisterCommand('glovebox', function() openVehicleContainer('glovebox') end, false)

RegisterNetEvent('nhr_inventory:client:openAuthorized', function()
    local primary, secondary = lib.callback.await('nhr_inventory:getOpen', false)
    if not primary then return end
    vehicleContainer, open = true, true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    SendNUIMessage({ action = 'inventory', inventory = primary, secondary = secondary, definitions = NHRInventory.Items })
end)

RegisterNetEvent('nhr_inventory:client:dropCreated', function(id, coords) drops[id] = { coords = coords } end)
RegisterNetEvent('nhr_inventory:client:dropRemoved', function(id) drops[id] = nil end)

AddEventHandler('nhr_core:client:onPlayerLoaded', function()
    drops = lib.callback.await('nhr_inventory:getDrops', false) or {}
end)

CreateThread(function()
    local textVisible = false
    while true do
        local wait = 1000
        local nearDrop = false
        local coords = GetEntityCoords(PlayerPedId())
        for id, drop in pairs(drops) do
            local location = vec3(drop.coords.x, drop.coords.y, drop.coords.z)
            local distance = #(coords - location)
            if distance < 20.0 then
                wait = 0
                DrawMarker(2, location.x, location.y, location.z + 0.15, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.22, 0.22, 0.22, 82, 211, 163, 190, false, true, 2, false)
                if distance <= NHRInventory.DropDistance then
                    nearDrop = true
                    if not textVisible then
                        lib.showTextUI('[E] Pick up items')
                        textVisible = true
                    end
                    if IsControlJustReleased(0, 38) then lib.callback.await('nhr_inventory:pickup', false, id) end
                end
            end
        end
        if not nearDrop and textVisible then
            lib.hideTextUI()
            textVisible = false
        end
        Wait(wait)
    end
end)
