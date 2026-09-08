lib.callback.register('nhr_jobs:select', function(source, jobName)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or not NHRPublicJobs[jobName] or #(GetEntityCoords(GetPlayerPed(source)) - NHRJobCenter) > 6.0 then return false end
    return player.Functions.SetPrimaryGroup('job', jobName, 0)
end)

lib.callback.register('nhr_jobs:duty', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    local point = player and NHRDutyPoints[player.PlayerData.job.name]
    if not point or #(GetEntityCoords(GetPlayerPed(source)) - point) > 6.0 then return false end
    player.Functions.SetDuty(not player.PlayerData.job.onDuty)
    return true, player.PlayerData.job.onDuty
end)

lib.callback.register('nhr_jobs:switch',function(source,jobName)
    local player=exports.nhr_core:GetPlayer(source)
    local grade=player and player.PlayerData.jobs[jobName]
    if grade==nil then return false end
    return player.Functions.SetPrimaryGroup('job',jobName,grade)
end)

CreateThread(function()
    while true do
        Wait(15 * 60 * 1000)
        local core = exports.nhr_core:GetCoreObject()
        for _, player in pairs(core.Players) do
            local job = player.PlayerData.job
            if job.onDuty and job.payment > 0 then player.Functions.AddMoney('bank', job.payment, 'paycheck') end
        end
    end
end)
