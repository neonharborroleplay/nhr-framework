local buckets, blockedModels = {}, {}
for _, model in ipairs(NHRSecurity.BlacklistedModels) do blockedModels[joaat(model)] = true end

local function check(source, action, limit, window)
    source = tonumber(source)
    if not source or source <= 0 or IsPlayerAceAllowed(source, 'nhr.admin') then return true end
    action = tostring(action or 'unknown'):sub(1,64)
    limit = math.max(1, math.floor(tonumber(limit) or 5))
    window = math.max(1000, math.floor(tonumber(window) or 10000))
    local now, key = GetGameTimer(), ('%d:%s'):format(source, action)
    local bucket = buckets[key]
    if not bucket or now - bucket.started >= window then bucket = { started = now, count = 0 }; buckets[key] = bucket end
    bucket.count = bucket.count + 1
    if bucket.count <= limit then return true end
    if bucket.count == limit + 1 then exports.nhr_logs:CreateLog('security', 'rate_limit', source, nil, { action = action, limit = limit, window = window }) end
    return false
end

exports('CheckRateLimit', check)

AddEventHandler('entityCreating', function(entity)
    if not NHRSecurity.CancelBlacklistedEntities or not blockedModels[GetEntityModel(entity)] then return end
    local owner = NetworkGetEntityOwner(entity)
    if owner > 0 and not IsPlayerAceAllowed(owner, 'nhr.admin') then
        CancelEvent()
        exports.nhr_logs:CreateLog('security', 'blocked_entity', owner, nil, { model = GetEntityModel(entity) })
    end
end)

AddEventHandler('weaponDamageEvent', function(sender, data)
    local damage = tonumber(data and data.weaponDamage) or 0
    if damage > NHRSecurity.MaxWeaponDamage and not IsPlayerAceAllowed(sender, 'nhr.admin') then
        CancelEvent()
        exports.nhr_logs:CreateLog('security', 'abnormal_damage', sender, nil, { damage = damage, weapon = data.weaponType })
    end
end)

AddEventHandler('playerDropped', function()
    local prefix = tostring(source) .. ':'
    for key in pairs(buckets) do if key:sub(1, #prefix) == prefix then buckets[key] = nil end end
end)
