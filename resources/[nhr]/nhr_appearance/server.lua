local function decodeAppearance(raw)
    if not raw or raw == '' then return end
    local ok, appearance = pcall(json.decode, raw)
    if ok and type(appearance) == 'table' then return appearance end
end

local function nearStore(source)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, store in ipairs(NHRAppearance.Stores) do
        if #(coords - store) <= 12.0 then return true end
    end
    return false
end

lib.callback.register('nhr_appearance:get', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return end
    local raw = MySQL.scalar.await('SELECT appearance FROM nhr_appearances WHERE citizenid = ?', {
        player.PlayerData.citizenid
    })
    local appearance = decodeAppearance(raw)
    if (not appearance or appearance.version ~= 2) and player.PlayerData.metadata.isdead and GetResourceState('nhr_status') == 'started' then
        exports.nhr_status:Revive(source)
    end
    return appearance
end)

lib.callback.register('nhr_appearance:save', function(source, appearance)
    local player = exports.nhr_core:GetPlayer(source)
    if not player or type(appearance) ~= 'table' then return false, 'invalid_appearance' end
    if appearance.version ~= 2 then return false, 'invalid_version' end
    if appearance.model ~= 'male' and appearance.model ~= 'female' then return false, 'invalid_model' end

    local existingRaw = MySQL.scalar.await('SELECT appearance FROM nhr_appearances WHERE citizenid = ?', {
        player.PlayerData.citizenid
    })
    local existingAppearance = decodeAppearance(existingRaw)
    local existing = existingAppearance and existingAppearance.version == 2
    if existing and not nearStore(source) and not IsPlayerAceAllowed(source, 'nhr.admin') then
        return false, 'Visit a clothing store to save changes.'
    end

    local encoded = json.encode(appearance)
    if #encoded > 30000 then return false, 'appearance_too_large' end
    if existing and NHRAppearance.ShopPrice > 0 and
        not player.Functions.RemoveMoney('cash', NHRAppearance.ShopPrice, 'appearance-store') then
        return false, ('You need $%d cash.'):format(NHRAppearance.ShopPrice)
    end

    MySQL.prepare.await([[
        INSERT INTO nhr_appearances (citizenid, appearance) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE appearance = VALUES(appearance)
    ]], { player.PlayerData.citizenid, encoded })

    player.PlayerData.charinfo.gender = appearance.model
    player.Functions.Update()
    exports.nhr_logs:CreateLog('player', 'appearance_saved', source, nil, { model = appearance.model })
    return true
end)
