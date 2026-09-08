local function boss(source)
    local player = exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.job.isBoss and player or nil
end
local function log(player, kind, amount)
    MySQL.insert('INSERT INTO nhr_society_transactions (society, citizenid, kind, amount) VALUES (?, ?, ?, ?)', { player.PlayerData.job.name, player.PlayerData.citizenid, kind, amount })
end
lib.callback.register('nhr_management:account', function(source)
    local player = boss(source); if not player then return end
    MySQL.insert.await('INSERT IGNORE INTO nhr_societies (name) VALUES (?)', { player.PlayerData.job.name })
    return MySQL.scalar.await('SELECT balance FROM nhr_societies WHERE name=?', { player.PlayerData.job.name }) or 0
end)
lib.callback.register('nhr_management:statements', function(source)
    local player = boss(source); if not player then return {} end
    return MySQL.query.await('SELECT citizenid,kind,amount,created_at FROM nhr_society_transactions WHERE society=? ORDER BY id DESC LIMIT 25', { player.PlayerData.job.name }) or {}
end)
lib.callback.register('nhr_management:deposit', function(source, amount)
    if not exports.nhr_security:CheckRateLimit(source, 'society_deposit', 6, 10000) then return false end
    local player = boss(source); amount = math.floor(tonumber(amount) or 0)
    if not player or amount < 1 or not player.Functions.RemoveMoney('cash', amount, 'society-deposit') then return false end
    MySQL.prepare.await('INSERT INTO nhr_societies (name,balance) VALUES (?,?) ON DUPLICATE KEY UPDATE balance=balance+VALUES(balance)', { player.PlayerData.job.name, amount })
    log(player, 'deposit', amount); return true
end)
lib.callback.register('nhr_management:withdraw', function(source, amount)
    if not exports.nhr_security:CheckRateLimit(source, 'society_withdraw', 6, 10000) then return false end
    local player = boss(source); amount = math.floor(tonumber(amount) or 0)
    if not player or amount < 1 then return false end
    local changed = MySQL.update.await('UPDATE nhr_societies SET balance=balance-? WHERE name=? AND balance>=?', { amount, player.PlayerData.job.name, amount })
    if changed ~= 1 then return false end
    player.Functions.AddMoney('cash', amount, 'society-withdraw'); log(player, 'withdraw', amount); return true
end)
lib.callback.register('nhr_management:employee', function(source, targetId, action, grade)
    if not exports.nhr_security:CheckRateLimit(source, 'society_employee', 6, 30000) then return false end
    targetId = tonumber(targetId)
    local manager, employee = boss(source), exports.nhr_core:GetPlayer(targetId)
    if not manager or not employee or targetId == source or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetId))) > 5.0 then return false end
    local job = manager.PlayerData.job.name
    local success=false
    if action == 'hire' then success=employee.Functions.SetPrimaryGroup('job', job, 0)
    elseif employee.PlayerData.job.name ~= job then return false
    elseif action == 'fire' then success=employee.Functions.RemoveGroup('job',job)
    else grade = math.floor(tonumber(grade) or -1);if action == 'grade' and grade >= 0 and grade < manager.PlayerData.job.grade then success=employee.Functions.SetPrimaryGroup('job', job, grade)end end
    if success then exports.nhr_logs:CreateLog('economy','employee_'..action,source,targetId,{job=job,grade=grade})end
    return success
end)
