exports.spawnmanager:setAutoSpawn(false)

AddEventHandler('nhr_core:client:onPlayerLoaded', function(data)
    local position = data.position or exports.nhr_core:GetCoreObject().Config.DefaultSpawn
    local model = joaat(data.charinfo.gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
    exports.spawnmanager:spawnPlayer({
        x = position.x, y = position.y, z = position.z,
        heading = position.w or 0.0,
        model = model,
        skipFade = false
    }, function()
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetEntityCollision(ped, true, true)
        SetPlayerControl(PlayerId(), true, 0)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        DoScreenFadeIn(750)
        TriggerEvent('nhr_spawn:client:complete', data)
    end)
end)
