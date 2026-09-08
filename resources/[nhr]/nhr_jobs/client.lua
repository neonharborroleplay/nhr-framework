local function jobCenter()
    local options = {}
    for name, definition in pairs(NHRPublicJobs) do
        local jobName = name
        local label = definition.label
        options[#options + 1] = { title = label, onSelect = function()
            local ok = lib.callback.await('nhr_jobs:select', false, jobName)
            lib.notify({ type = ok and 'success' or 'error', description = ok and ('You are now employed as ' .. label) or 'Unable to change job.' })
        end }
    end
    lib.registerContext({ id = 'nhr_jobs', title = 'City Employment', options = options })
    lib.showContext('nhr_jobs')
end

CreateThread(function()
    exports.ox_target:addSphereZone({ coords = NHRJobCenter, radius = 1.5, options = { { name = 'nhr_jobs', label = 'Browse public jobs', icon = 'fa-solid fa-briefcase', onSelect = jobCenter } } })
    for name, coords in pairs(NHRDutyPoints) do
        local jobName = name
        exports.ox_target:addSphereZone({ coords = coords, radius = 1.5, options = { { name = 'nhr_duty_' .. jobName, label = 'Toggle duty', icon = 'fa-solid fa-clock', onSelect = function()
            local ok, state = lib.callback.await('nhr_jobs:duty', false)
            if ok then lib.notify({ description = state and 'You are on duty.' or 'You are off duty.' }) end
        end } } })
    end
end)

RegisterCommand('myjobs',function()
    local core=exports.nhr_core:GetCoreObject();local options={}
    for name,grade in pairs(core.PlayerData.jobs or{})do local jobName=name;local definition=core.Shared.Jobs[name];options[#options+1]={title=definition and definition.label or name,description='Grade '..grade,onSelect=function()local ok=lib.callback.await('nhr_jobs:switch',false,jobName);if ok then lib.notify({description='Active job changed.'})end end}end
    lib.registerContext({id='nhr_myjobs',title='My Jobs',options=options});lib.showContext('nhr_myjobs')
end,false)
