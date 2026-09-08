local dependencies = { 'oxmysql', 'ox_lib', 'ox_target', 'pma-voice', 'spawnmanager', 'chat' }

local function inspect()
    local result = { database = false, migrationsReady = GlobalState.nhrMigrationsReady == true, dependencies = {}, checkedAt = os.time() }
    local ok, value = pcall(function() return MySQL.scalar.await('SELECT 1') end)
    result.database = ok and value == 1
    for _, resource in ipairs(dependencies) do result.dependencies[resource] = GetResourceState(resource) == 'started' end
    return result
end

RegisterCommand('nhrhealth', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'nhr.admin') then return end
    local status = inspect()
    print(('[NHR HEALTH] database=%s migrations=%s dependencies=%s'):format(tostring(status.database), tostring(status.migrationsReady), json.encode(status.dependencies)))
end, false)

CreateThread(function()
    while not GlobalState.nhrMigrationsReady do Wait(100) end
    local status = inspect()
    GlobalState.nhrHealth = status
    print(('[NHR HEALTH] database=%s migrations=%s dependencies=%s'):format(tostring(status.database), tostring(status.migrationsReady), json.encode(status.dependencies)))
end)

exports('Inspect', inspect)
