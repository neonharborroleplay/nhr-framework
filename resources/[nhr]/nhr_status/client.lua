local stage, stageAt = 'alive', 0
local spawnReady, pendingMetadata = false, nil

local function reviveAt(position)
    NetworkResurrectLocalPlayer(position.x, position.y, position.z, position.w, true, false)
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    stage, stageAt = 'alive', 0
end

local function beginStage(nextStage)
    local ped, coords = PlayerPedId(), GetEntityCoords(PlayerPedId())
    if IsEntityDead(ped) then NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false) ped = PlayerPedId() end
    stage, stageAt = nextStage, GetGameTimer()
    SetEntityHealth(ped, 110)
    SetEntityInvincible(ped, true)
    TriggerServerEvent('nhr_status:server:setDeath', nextStage)
end

local function maintainAnimation()
    local ped = PlayerPedId()
    if not IsEntityPlayingAnim(ped, 'combat@damage@writhe', 'writhe_loop', 3) then
        lib.requestAnimDict('combat@damage@writhe')
        TaskPlayAnim(ped, 'combat@damage@writhe', 'writhe_loop', 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end
end

RegisterNetEvent('nhr_status:client:revive', function()
    local coords = GetEntityCoords(PlayerPedId())
    reviveAt(vec4(coords.x, coords.y, coords.z, GetEntityHeading(PlayerPedId())))
end)

AddEventHandler('nhr_core:client:onPlayerLoaded', function(data)
    spawnReady = false
    pendingMetadata = data.metadata or {}
end)
AddEventHandler('nhr_spawn:client:complete', function()
    spawnReady = true
    local meta = pendingMetadata or {}
    pendingMetadata = nil
    if meta.isdead then
        beginStage(meta.laststand and 'laststand' or 'dead')
    else
        local ped, coords = PlayerPedId(), GetEntityCoords(PlayerPedId())
        reviveAt(vec4(coords.x, coords.y, coords.z, GetEntityHeading(ped)))
    end
end)
AddEventHandler('nhr_core:client:onPlayerUnloaded',function()
    spawnReady=false;pendingMetadata=nil;SetEntityInvincible(PlayerPedId(),false);ClearPedTasksImmediately(PlayerPedId());stage,stageAt='alive',0
end)

CreateThread(function()
    while true do
        Wait(60000)
        if LocalPlayer.state.isLoggedIn then TriggerServerEvent('nhr_status:server:tick') end
    end
end)

CreateThread(function()
    while true do
        Wait(250)
        if LocalPlayer.state.isLoggedIn and spawnReady and stage == 'alive' then
            local ped = PlayerPedId()
            if IsEntityDead(ped) then beginStage('laststand')
            else
                local meta = exports.nhr_core:GetCoreObject().PlayerData.metadata or {}
                if (meta.hunger or 1) <= 0 or (meta.thirst or 1) <= 0 then ApplyDamageToPed(ped, 5, false) end
            end
        end
    end
end)

CreateThread(function()
    while true do
        if stage ~= 'alive' then
            Wait(0)
            DisableAllControlActions(0)
            maintainAnimation()
            local duration = stage == 'laststand' and NHRStatus.lastStandSeconds or NHRStatus.bleedoutSeconds
            local remaining = math.max(0, duration - math.floor((GetGameTimer() - stageAt) / 1000))
            if stage == 'laststand' and remaining == 0 then beginStage('dead')
            else
                if stage == 'dead' and remaining == 0 then EnableControlAction(0, 38, true) end
                SetTextFont(4) SetTextScale(0.45, 0.45) SetTextCentre(true) SetTextColour(255, 255, 255, 220)
                BeginTextCommandDisplayText('STRING')
                local message
                if stage == 'laststand' then message = ('Incapacitated · %ds until unconscious'):format(remaining)
                elseif remaining > 0 then message = ('Unconscious · %ds until hospital respawn'):format(remaining)
                else message = ('Hold E to respawn at hospital · up to $%d'):format(NHRStatus.hospitalFee) end
                AddTextComponentSubstringPlayerName(message)
                EndTextCommandDisplayText(0.5, 0.86)
                if stage == 'dead' and remaining == 0 and IsControlPressed(0, 38) then
                    local started = GetGameTimer()
                    while IsControlPressed(0, 38) and GetGameTimer() - started < 2000 do Wait(0) end
                    if GetGameTimer() - started >= 2000 and lib.callback.await('nhr_status:respawn', false) then reviveAt(NHRStatus.hospitalSpawn) end
                end
            end
        else Wait(500) end
    end
end)
