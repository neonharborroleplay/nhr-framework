local function log(player, kind, amount, description)
    MySQL.insert('INSERT INTO nhr_transactions (citizenid, kind, amount, description) VALUES (?, ?, ?, ?)', {
        player.PlayerData.citizenid, kind, amount, description
    })
end

lib.callback.register('nhr_banking:account', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return end
    return { cash = player.Functions.GetMoney('cash'), bank = player.Functions.GetMoney('bank') }
end)

lib.callback.register('nhr_banking:statements', function(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return {} end
    return MySQL.query.await('SELECT kind,amount,description,created_at FROM nhr_transactions WHERE citizenid=? ORDER BY id DESC LIMIT 25', { player.PlayerData.citizenid }) or {}
end)

lib.callback.register('nhr_banking:deposit', function(source, amount)
    if not exports.nhr_security:CheckRateLimit(source, 'bank_deposit', 8, 10000) then return false end
    local player = exports.nhr_core:GetPlayer(source)
    amount = math.floor(tonumber(amount) or 0)
    if not player or amount <= 0 or not player.Functions.RemoveMoney('cash', amount, 'deposit') then return false end
    player.Functions.AddMoney('bank', amount, 'deposit')
    log(player, 'deposit', amount, 'Cash deposit')
    return true
end)

lib.callback.register('nhr_banking:withdraw', function(source, amount)
    if not exports.nhr_security:CheckRateLimit(source, 'bank_withdraw', 8, 10000) then return false end
    local player = exports.nhr_core:GetPlayer(source)
    amount = math.floor(tonumber(amount) or 0)
    if not player or amount <= 0 or not player.Functions.RemoveMoney('bank', amount, 'withdraw') then return false end
    player.Functions.AddMoney('cash', amount, 'withdraw')
    log(player, 'withdrawal', amount, 'Cash withdrawal')
    return true
end)

lib.callback.register('nhr_banking:transfer', function(source, citizenid, amount)
    if not exports.nhr_security:CheckRateLimit(source, 'bank_transfer', 6, 30000) then return false end
    local player = exports.nhr_core:GetPlayer(source)
    local target = exports.nhr_core:GetPlayerByCitizenId(tostring(citizenid or ''))
    amount = math.floor(tonumber(amount) or 0)
    if not player or not target or player == target or amount <= 0 or amount > 2000000 then return false end
    if not player.Functions.RemoveMoney('bank', amount, 'transfer') then return false end
    target.Functions.AddMoney('bank', amount, 'transfer')
    log(player, 'transfer_out', amount, 'Transfer to ' .. target.PlayerData.citizenid)
    log(target, 'transfer_in', amount, 'Transfer from ' .. player.PlayerData.citizenid)
    if amount >= 100000 then exports.nhr_logs:CreateLog('economy', 'large_transfer', source, target.PlayerData.citizenid, { amount = amount }) end
    return true
end)
