math.randomseed(os.time())

AddEventHandler('playerDropped', function() NHR.Logout(source) end)

RegisterNetEvent('nhr_core:server:updatePosition', function(coords)
    local player = NHR.GetPlayer(source)
    if not player or type(coords) ~= 'table' then return end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return end
    player.PlayerData.position = { x = x, y = y, z = z, w = tonumber(coords.w) or 0.0 }
end)

CreateThread(function()
    while true do
        Wait(NHRConfig.SaveInterval)
        for _, player in pairs(NHR.Players) do player.Functions.Save() end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, player in pairs(NHR.Players) do player.Functions.Save() end
end)

RegisterCommand('nhrsaveall', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'nhr.admin') then return end
    for _, player in pairs(NHR.Players) do player.Functions.Save() end
end, false)

RegisterCommand('nhrsetjob', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'nhr.admin') then return end
    local target, name, grade = tonumber(args[1]), args[2], tonumber(args[3])
    local player = target and NHR.GetPlayer(target)
    if player and name and grade then player.Functions.SetPrimaryGroup('job', name, grade) end
end, false)
