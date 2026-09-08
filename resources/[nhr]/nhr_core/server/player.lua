NHR.Players = {}

local function copy(value)
    if type(value) ~= 'table' then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local function decode(value, fallback)
    if not value or value == '' then return copy(fallback) end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or copy(fallback)
end

local function licenseOf(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
end

local function groupData(kind, name, grade)
    local definitions = kind == 'job' and NHRJobs or NHRGangs
    local definition = definitions[name]
    grade = math.floor(tonumber(grade) or 0)
    local gradeData = definition and definition.grades[grade]
    if not definition or not gradeData then return end
    return {
        name = name, label = definition.label, grade = grade,
        gradeName = gradeData.name, payment = gradeData.payment or 0,
        isBoss = gradeData.isBoss == true, onDuty = definition.defaultDuty == true
    }
end

local function sync(player)
    TriggerClientEvent('nhr_core:client:setPlayerData', player.PlayerData.source, player.PlayerData)
end

function NHR.GetLicense(source) return licenseOf(tonumber(source)) end
function NHR.GetPlayer(source) return NHR.Players[tonumber(source)] end

function NHR.GetPlayerByCitizenId(citizenid)
    for _, player in pairs(NHR.Players) do
        if player.PlayerData.citizenid == citizenid then return player end
    end
end

function NHR.GetCharacters(source)
    local license = licenseOf(source)
    if not license then return {} end
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo, money, job, gang, last_seen
        FROM nhr_characters WHERE license = ? ORDER BY last_seen DESC
    ]], { license }) or {}
    for i = 1, #rows do
        rows[i].charinfo = decode(rows[i].charinfo, {})
        rows[i].money = decode(rows[i].money, {})
        rows[i].job = decode(rows[i].job, {})
        rows[i].gang = decode(rows[i].gang, {})
    end
    return rows
end

local function citizenId()
    while true do
        local id = ('%s%08X'):format(NHRConfig.CharacterIdPrefix, math.random(0, 0xFFFFFFFF))
        if not MySQL.scalar.await('SELECT 1 FROM nhr_characters WHERE citizenid = ?', { id }) then return id end
    end
end

function NHR.CreateCharacter(source, charinfo)
    local license = licenseOf(source)
    if not license then return false, 'missing_license' end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM nhr_characters WHERE license = ?', { license }) or 0
    if count >= NHRConfig.MaxCharacters then return false, 'character_limit' end

    local first = tostring(charinfo.firstname or ''):match('^%s*(.-)%s*$'):sub(1, 24)
    local last = tostring(charinfo.lastname or ''):match('^%s*(.-)%s*$'):sub(1, 24)
    if #first < 2 or #last < 2 then return false, 'invalid_name' end

    local id = citizenId()
    local info = {
        firstname = first, lastname = last,
        birthdate = tostring(charinfo.birthdate or ''):sub(1, 10),
        gender = tostring(charinfo.gender or 'unknown'):sub(1, 16),
        nationality = tostring(charinfo.nationality or 'San Andreas'):sub(1, 32)
    }
    local job = groupData('job', NHRConfig.DefaultJob, 0)
    local gang = groupData('gang', NHRConfig.DefaultGang, 0)
    MySQL.insert.await([[
        INSERT INTO nhr_characters (citizenid, license, name, charinfo, money, job, gang, jobs, gangs, metadata, position)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        id, license, GetPlayerName(source), json.encode(info), json.encode(NHRConfig.StartingMoney),
        json.encode(job), json.encode(gang), json.encode({ [job.name] = 0 }),
        json.encode({ [gang.name] = 0 }), json.encode(NHRConfig.DefaultMetadata),
        json.encode({ x = NHRConfig.DefaultSpawn.x, y = NHRConfig.DefaultSpawn.y, z = NHRConfig.DefaultSpawn.z, w = NHRConfig.DefaultSpawn.w })
    })
    return true, id
end

function NHR.Login(source, citizenid)
    source = tonumber(source)
    if not source then return false, 'invalid_source' end
    if NHR.Players[source] then return false, 'already_logged_in' end
    local license = licenseOf(source)
    if not license then return false, 'missing_license' end
    local row = MySQL.single.await('SELECT * FROM nhr_characters WHERE citizenid = ? AND license = ?', { citizenid, license })
    if not row then return false, 'character_not_found' end

    local player = { Functions = {} }
    player.PlayerData = {
        source = source, citizenid = row.citizenid, license = row.license,
        name = GetPlayerName(source), charinfo = decode(row.charinfo, {}),
        money = decode(row.money, NHRConfig.StartingMoney),
        job = decode(row.job, groupData('job', NHRConfig.DefaultJob, 0)),
        gang = decode(row.gang, groupData('gang', NHRConfig.DefaultGang, 0)),
        jobs = decode(row.jobs, { [NHRConfig.DefaultJob] = 0 }),
        gangs = decode(row.gangs, { [NHRConfig.DefaultGang] = 0 }),
        metadata = decode(row.metadata, NHRConfig.DefaultMetadata),
        position = decode(row.position, { x = NHRConfig.DefaultSpawn.x, y = NHRConfig.DefaultSpawn.y, z = NHRConfig.DefaultSpawn.z, w = NHRConfig.DefaultSpawn.w })
    }

    function player.Functions.Update() sync(player) end
    function player.Functions.GetMoney(account) return player.PlayerData.money[account] or 0 end
    function player.Functions.AddMoney(account, amount, reason)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 or player.PlayerData.money[account] == nil then return false end
        player.PlayerData.money[account] = player.PlayerData.money[account] + amount
        sync(player)
        TriggerEvent('nhr_core:server:moneyChanged', source, account, amount, 'add', reason or 'unknown')
        return true
    end
    function player.Functions.RemoveMoney(account, amount, reason)
        amount = math.floor(tonumber(amount) or 0)
        local balance = player.PlayerData.money[account]
        if amount <= 0 or not balance or balance < amount then return false end
        player.PlayerData.money[account] = balance - amount
        sync(player)
        TriggerEvent('nhr_core:server:moneyChanged', source, account, amount, 'remove', reason or 'unknown')
        return true
    end
    function player.Functions.SetMoney(account, amount, reason)
        amount = math.floor(tonumber(amount) or -1)
        if amount < 0 or player.PlayerData.money[account] == nil then return false end
        player.PlayerData.money[account] = amount
        sync(player)
        TriggerEvent('nhr_core:server:moneyChanged', source, account, amount, 'set', reason or 'unknown')
        return true
    end
    function player.Functions.SetMetadata(key, value)
        if type(key) ~= 'string' then return false end
        player.PlayerData.metadata[key] = value
        sync(player)
        return true
    end
    function player.Functions.SetPrimaryGroup(kind, name, grade)
        if kind ~= 'job' and kind ~= 'gang' then return false end
        local data = groupData(kind, name, grade)
        if not data then return false end
        local memberships = kind == 'job' and player.PlayerData.jobs or player.PlayerData.gangs
        memberships[name] = data.grade
        player.PlayerData[kind] = data
        sync(player)
        TriggerEvent('nhr_core:server:groupChanged', source, kind, data)
        return true
    end
    function player.Functions.RemoveGroup(kind, name)
        if kind ~= 'job' and kind ~= 'gang' then return false end
        local memberships = kind == 'job' and player.PlayerData.jobs or player.PlayerData.gangs
        if memberships[name] == nil then return false end
        local fallback = kind == 'job' and NHRConfig.DefaultJob or NHRConfig.DefaultGang
        if player.PlayerData[kind].name == name then
            local data = groupData(kind, fallback, 0)
            memberships[fallback] = 0
            player.PlayerData[kind] = data
            TriggerEvent('nhr_core:server:groupChanged', source, kind, data)
        end
        memberships[name] = nil
        sync(player)
        return true
    end
    function player.Functions.SetDuty(state)
        player.PlayerData.job.onDuty = state == true
        sync(player)
    end
    function player.Functions.Save()
        local d = player.PlayerData
        MySQL.update.await([[
            UPDATE nhr_characters SET name=?, charinfo=?, money=?, job=?, gang=?, jobs=?, gangs=?, metadata=?, position=?
            WHERE citizenid=?
        ]], { d.name, json.encode(d.charinfo), json.encode(d.money), json.encode(d.job), json.encode(d.gang),
            json.encode(d.jobs), json.encode(d.gangs), json.encode(d.metadata), json.encode(d.position), d.citizenid })
    end

    NHR.Players[source] = player
    TriggerClientEvent('nhr_core:client:playerLoaded', source, player.PlayerData)
    TriggerEvent('nhr_core:server:playerLoaded', player)
    return true, player
end

function NHR.Logout(source)
    local player = NHR.GetPlayer(source)
    if not player then return end
    player.Functions.Save()
    NHR.Players[tonumber(source)] = nil
    TriggerClientEvent('nhr_core:client:playerUnloaded', source)
    TriggerEvent('nhr_core:server:playerUnloaded', source, player.PlayerData.citizenid)
end

exports('GetPlayer', NHR.GetPlayer)
exports('GetLicense', NHR.GetLicense)
exports('GetPlayerByCitizenId', NHR.GetPlayerByCitizenId)
exports('GetCharacters', NHR.GetCharacters)
exports('CreateCharacter', NHR.CreateCharacter)
exports('Login', NHR.Login)
exports('Logout', NHR.Logout)
