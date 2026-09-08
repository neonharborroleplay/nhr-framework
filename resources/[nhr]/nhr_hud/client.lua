local initialCore = exports.nhr_core:GetCoreObject()
local playerLoaded = initialCore.PlayerLoaded == true
local playerData = initialCore.PlayerData or {}

AddEventHandler('nhr_core:client:onPlayerLoaded', function(data)
    playerData = data or {}
    playerLoaded = true
end)

AddEventHandler('nhr_core:client:playerDataChanged', function(data)
    playerData = data or playerData
end)

AddEventHandler('nhr_core:client:onPlayerUnloaded', function()
    playerLoaded = false
    playerData = {}
end)

CreateThread(function()
    while true do
        Wait(250)
        if playerLoaded then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local meta = playerData.metadata or {}
            local talking = NetworkIsPlayerTalking(PlayerId())
            local radio = tonumber(LocalPlayer.state.radioChannel) or 0
            local call = tonumber(LocalPlayer.state.callChannel) or 0
            SendNUIMessage({ action = 'update', visible = not IsPauseMenuActive(),
                health = math.max(0, GetEntityHealth(ped) - 100), armor = GetPedArmour(ped),
                hunger = meta.hunger or 100, thirst = meta.thirst or 100, stress = meta.stress or 0,
                vehicle = vehicle ~= 0, speed = vehicle ~= 0 and math.floor(GetEntitySpeed(vehicle) * 2.236936) or 0,
                fuel = vehicle ~= 0 and math.floor(GetVehicleFuelLevel(vehicle)) or 0,
                voice = talking and 100 or ((radio > 0 or call > 0) and 60 or 25), talking = talking,
                radio = radio, call = call
            })
        else SendNUIMessage({ action = 'update', visible = false }) Wait(750) end
    end
end)
