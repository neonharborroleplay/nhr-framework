local function identity(value)
    if type(value) ~= 'number' then return tostring(value or 'system'):sub(1,64) end
    local player = exports.nhr_core:GetPlayer(value)
    return player and player.PlayerData.citizenid or exports.nhr_core:GetLicense(value) or ('source:' .. value)
end

local function create(category, action, actor, target, details)
    category = tostring(category or 'general'):sub(1,24)
    action = tostring(action or 'unknown'):sub(1,48)
    actor = identity(actor)
    target = target and identity(target) or ''
    details = type(details) == 'table' and details or { message = tostring(details or '') }
    local encoded = json.encode(details):sub(1,4000)
    local auditAction = (category .. ':' .. action):sub(1,48)
    MySQL.insert('INSERT INTO nhr_audit_logs (actor,action,target,details) VALUES (?,?,?,?)', {
        actor, auditAction, target, encoded
    })
    if NHRLogs.Webhook == '' or not NHRLogs.WebhookCategories[category] then return end
    local payload = json.encode({ username = NHRLogs.Username, embeds = {{
        title = ('%s · %s'):format(category:upper(), action), color = category == 'security' and 15158332 or 3447003,
        fields = {{ name = 'Actor', value = actor, inline = true }, { name = 'Target', value = target ~= '' and target or 'none', inline = true }, { name = 'Details', value = ('```json\n%s\n```'):format(encoded:sub(1,900)) }},
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }}})
    PerformHttpRequest(NHRLogs.Webhook, function() end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

exports('CreateLog', create)
