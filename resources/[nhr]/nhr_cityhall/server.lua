local function atCityHall(source)
    local ped = GetPlayerPed(source)
    return ped ~= 0 and #(GetEntityCoords(ped) - NHRCityHall.coords) <= 6.0
end

local function identityMetadata(player)
    local info = player.PlayerData.charinfo
    return { citizenid = player.PlayerData.citizenid, name = info.firstname .. ' ' .. info.lastname, birthdate = info.birthdate, gender = info.gender, nationality = info.nationality }
end

lib.callback.register('nhr_cityhall:info', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or not atCityHall(source) then return end
    local licenses = MySQL.query.await('SELECT license_type,issued_at FROM nhr_licenses WHERE citizenid=? ORDER BY license_type', { player.PlayerData.citizenid }) or {}
    local jobs, core = {}, exports.nhr_core:GetCoreObject()
    for name, grade in pairs(player.PlayerData.jobs) do
        local definition, gradeData = core.Shared.Jobs[name], core.Shared.Jobs[name] and core.Shared.Jobs[name].grades[grade]
        if definition and gradeData then jobs[#jobs + 1] = { name = name, label = definition.label, grade = grade, gradeName = gradeData.name, active = player.PlayerData.job.name == name } end
    end
    return { identity = identityMetadata(player), licenses = licenses, jobs = jobs }
end)

lib.callback.register('nhr_cityhall:document', function(source, document)
    if not exports.nhr_security:CheckRateLimit(source, 'cityhall_document', 5, 30000) then return false end
    local player = exports.nhr_core:GetPlayer(source)
    if not player or not atCityHall(source) then return false end
    local item, fee, metadata = 'id_card', NHRCityHall.idFee, identityMetadata(player)
    if document == 'driver' then
        item, fee = 'driver_license', NHRCityHall.driverLicenseFee
        metadata.license = 'driver'
        if not MySQL.scalar.await("SELECT 1 FROM nhr_licenses WHERE citizenid=? AND license_type='driver'",{player.PlayerData.citizenid})then return false end
    elseif document ~= 'id' then return false end
    if exports.nhr_inventory:GetItemCount(source, item) > 0 or not player.Functions.RemoveMoney('bank', fee, 'cityhall-document') then return false end
    if not exports.nhr_inventory:AddItem(source, item, 1, metadata) then player.Functions.AddMoney('bank', fee, 'cityhall-refund') return false end
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { player.PlayerData.citizenid, 'government_fee', fee, document == 'driver' and 'Driver license replacement' or 'Replacement ID' })
    exports.nhr_logs:CreateLog('economy', 'document_issued', source, nil, { document = document, fee = fee })
    return true
end)

lib.callback.register('nhr_cityhall:switchJob', function(source, name)
    if not exports.nhr_security:CheckRateLimit(source, 'job_switch', 4, 30000) then return false end
    local player = exports.nhr_core:GetPlayer(source)
    name = tostring(name or '')
    local grade = player and player.PlayerData.jobs[name]
    if not player or not atCityHall(source) or grade == nil then return false end
    local changed = player.Functions.SetPrimaryGroup('job', name, grade)
    if changed then exports.nhr_logs:CreateLog('economy', 'job_switch', source, nil, { job = name, grade = grade }) end
    return changed
end)

lib.callback.register('nhr_cityhall:present',function(source,target,item)
    if not exports.nhr_security:CheckRateLimit(source,'document_present',6,30000)then return false end
    target=tonumber(target);if item~='id_card'and item~='driver_license'then return false end
    local holder,viewer=exports.nhr_core:GetPlayer(source),target and exports.nhr_core:GetPlayer(target)
    if not holder or not viewer or target==source or #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))>5.0 then return false end
    local entry=exports.nhr_inventory:GetItem(source,item);if not entry then return false end
    TriggerClientEvent('nhr_cityhall:client:document',target,item=='id_card'and'State Identification'or'Driver License',entry.metadata)
    return true
end)

exports.nhr_inventory:RegisterUsableItem('id_card', function(source, entry) TriggerClientEvent('nhr_cityhall:client:document', source, 'State Identification', entry.metadata) end)
exports.nhr_inventory:RegisterUsableItem('driver_license', function(source, entry) TriggerClientEvent('nhr_cityhall:client:document', source, 'Driver License', entry.metadata) end)
