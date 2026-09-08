local currentWeather
CreateThread(function()
    while true do
        Wait(1000)
        local world=GlobalState.nhrWorld
        if world then
            NetworkOverrideClockTime(world.hour or 12,world.minute or 0,0)
            if world.weather and world.weather~=currentWeather then currentWeather=world.weather;ClearOverrideWeather();ClearWeatherTypePersist();SetWeatherTypeNowPersist(currentWeather)end
            SetArtificialLightsState(world.blackout==true)
        end
    end
end)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName()then return end
    NetworkClearClockTimeOverride();ClearOverrideWeather();ClearWeatherTypePersist();SetArtificialLightsState(false)
end)
CreateThread(function()
    while true do
        Wait(0)
        SetVehicleDensityMultiplierThisFrame(NHRWorld.trafficDensity)
        SetRandomVehicleDensityMultiplierThisFrame(NHRWorld.trafficDensity)
        SetParkedVehicleDensityMultiplierThisFrame(NHRWorld.trafficDensity)
        SetPedDensityMultiplierThisFrame(NHRWorld.pedestrianDensity)
        SetScenarioPedDensityMultiplierThisFrame(NHRWorld.pedestrianDensity,NHRWorld.pedestrianDensity)
    end
end)
