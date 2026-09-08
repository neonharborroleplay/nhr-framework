lib.callback.register('nhr_multichar:getCharacters', function(source)
    return exports.nhr_core:GetCharacters(source)
end)

lib.callback.register('nhr_multichar:create', function(source, data)
    return exports.nhr_core:CreateCharacter(source, data)
end)

RegisterNetEvent('nhr_multichar:server:select', function(citizenid)
    if type(citizenid) ~= 'string' then return end
    local playerSource = tonumber(source)
    if not playerSource then return end
    local ok, reason = exports.nhr_core:Login(playerSource, citizenid)
    if ok then SetPlayerRoutingBucket(playerSource, 0)
    else TriggerClientEvent('nhr_multichar:client:error', playerSource, reason) end
end)

RegisterNetEvent('nhr_multichar:server:sessionStarted', function()
    local playerSource = tonumber(source)
    if not playerSource then return end
    SetPlayerRoutingBucket(playerSource, playerSource + 1000)
end)

RegisterNetEvent('nhr_multichar:server:logout', function()
    local playerSource = tonumber(source)
    if not playerSource then return end
    exports.nhr_core:Logout(playerSource)
    SetPlayerRoutingBucket(playerSource, playerSource + 1000)
    TriggerClientEvent('nhr_multichar:client:open', playerSource)
end)
