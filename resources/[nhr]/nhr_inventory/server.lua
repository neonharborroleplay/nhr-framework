local inventories, usableItems, stashes, drops, opened = {}, {}, {}, {}, {}

local function decode(value)
    if not value or value == '' then return {} end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or {}
end

local function inventoryWeight(items)
    local weight = 0
    for _, slot in pairs(items) do
        local item = NHRInventory.Items[slot.name]
        if item then weight = weight + item.weight * slot.count end
    end
    return weight
end

local function loadInventory(id)
    if inventories[id] then return inventories[id] end
    local raw = MySQL.scalar.await('SELECT items FROM nhr_inventories WHERE inventory_id = ?', { id })
    inventories[id] = decode(raw)
    return inventories[id]
end

local function saveInventory(id)
    if not inventories[id] or id:sub(1, 5) == 'drop:' then return end
    MySQL.prepare.await([[
        INSERT INTO nhr_inventories (inventory_id, items) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE items = VALUES(items)
    ]], { id, json.encode(inventories[id]) })
end

local function playerInventory(source)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return end
    return 'player:' .. player.PlayerData.citizenid, player
end

local function settings(id)
    if id:sub(1, 7) == 'player:' then return NHRInventory.PlayerSlots, NHRInventory.PlayerWeight end
    if id:sub(1, 5) == 'drop:' then return NHRInventory.DropSlots, NHRInventory.DropWeight end
    if id:sub(1, 6) == 'trunk:' then return NHRInventory.TrunkSlots, NHRInventory.TrunkWeight end
    if id:sub(1, 9) == 'glovebox:' then return NHRInventory.GloveboxSlots, NHRInventory.GloveboxWeight end
    local stash = stashes[id]
    return stash and stash.slots or 40, stash and stash.maxWeight or 100000
end

local function findSlot(items, name, metadata, stack)
    if stack then
        local encoded = json.encode(metadata or {})
        for key, slot in pairs(items) do
            if slot.name == name and json.encode(slot.metadata or {}) == encoded then return tonumber(key) end
        end
    end
end

local function addItem(id, name, count, metadata, preferredSlot)
    local definition = NHRInventory.Items[name]
    count = math.floor(tonumber(count) or 0)
    if not definition or count < 1 then return false, 'invalid_item' end
    if not definition.stack and count > 1 then return false, 'not_stackable' end
    local items = loadInventory(id)
    local slots, maxWeight = settings(id)
    if inventoryWeight(items) + definition.weight * count > maxWeight then return false, 'overweight' end
    local slot = findSlot(items, name, metadata, definition.stack)
    if not slot and preferredSlot and not items[tostring(preferredSlot)] then slot = tonumber(preferredSlot) end
    if not slot then for i = 1, slots do if not items[tostring(i)] then slot = i break end end end
    if not slot then return false, 'full' end
    local key = tostring(slot)
    if items[key] then items[key].count = items[key].count + count
    else items[key] = { name = name, count = count, metadata = metadata or {}, slot = slot } end
    return true, slot
end

local function removeItem(id, name, count, slot)
    count = math.floor(tonumber(count) or 0)
    if count < 1 then return false end
    local items = loadInventory(id)
    local key = slot and tostring(slot)
    if key then
        local entry = items[key]
        if not entry or entry.name ~= name or entry.count < count then return false end
        entry.count = entry.count - count
        if entry.count == 0 then items[key] = nil end
        return true
    end
    local available = 0
    for _, entry in pairs(items) do if entry.name == name then available = available + entry.count end end
    if available < count then return false end
    local remaining = count
    for itemSlot, entry in pairs(items) do
        if entry.name == name then
            local taken = math.min(remaining, entry.count)
            entry.count = entry.count - taken
            remaining = remaining - taken
            if entry.count == 0 then items[itemSlot] = nil end
            if remaining == 0 then return true end
        end
    end
    return false
end

local function snapshot(id)
    local slots, maxWeight = settings(id)
    return { id = id, items = loadInventory(id), slots = slots, weight = inventoryWeight(loadInventory(id)), maxWeight = maxWeight }
end

lib.callback.register('nhr_inventory:getPlayer', function(source)
    local id = playerInventory(source)
    return id and snapshot(id)
end)

local function vehicleAccess(source, netId, kind)
    if kind ~= 'trunk' and kind ~= 'glovebox' then return end
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(vehicle)) > 4.0 then return end
    if kind == 'glovebox' and GetVehiclePedIsIn(GetPlayerPed(source), false) ~= vehicle then return end
    if kind == 'trunk' and GetVehicleDoorLockStatus(vehicle) > 1 then return end
    local plate = exports.nhr_vehicles:CleanPlate(GetVehicleNumberPlateText(vehicle))
    if plate == '' then return end
    return kind .. ':' .. plate
end

local function searchAccess(source,access)
    local target=access and tonumber(access.target)
    if not target or not exports.nhr_core:GetPlayer(target) or not Player(target).state.nhrCuffed then return end
    if #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))>5.0 then return end
    return access.id
end

lib.callback.register('nhr_inventory:openVehicle', function(source, netId, kind)
    local containerId, playerId = vehicleAccess(source, netId, kind), playerInventory(source)
    if not containerId or not playerId then return end
    opened[source] = { id = containerId, netId = netId, kind = kind }
    return snapshot(playerId), snapshot(containerId)
end)

lib.callback.register('nhr_inventory:getOpen', function(source)
    local access, playerId = opened[source], playerInventory(source)
    local containerId = access and (access.kind == 'stash' and access.id or access.kind=='search'and searchAccess(source,access)or vehicleAccess(source, access.netId, access.kind))
    if not containerId or containerId ~= access.id or not playerId then opened[source] = nil return end
    return snapshot(playerId), snapshot(containerId)
end)

lib.callback.register('nhr_inventory:transfer', function(source, fromId, toId, slot, count)
    local access, playerId = opened[source], playerInventory(source)
    local validContainer = access and (access.kind == 'stash' and access.id or access.kind=='search'and searchAccess(source,access)or vehicleAccess(source, access.netId, access.kind))
    if not access or not playerId or validContainer ~= access.id then return false end
    local allowed = { [playerId] = true, [access.id] = true }
    if not allowed[fromId] or not allowed[toId] or fromId == toId then return false end
    local entry = loadInventory(fromId)[tostring(slot)]
    count = math.floor(tonumber(count) or 0)
    if not entry or count < 1 or count > entry.count then return false end
    if not addItem(toId, entry.name, count, entry.metadata) then return false end
    if removeItem(fromId, entry.name, count, slot) then return true end
    removeItem(toId, entry.name, count)
    return false
end)

RegisterNetEvent('nhr_inventory:server:close', function() opened[source] = nil end)

lib.callback.register('nhr_inventory:use', function(source, slot)
    local id = playerInventory(source)
    local entry = id and loadInventory(id)[tostring(slot)]
    local handler = entry and usableItems[entry.name]
    if not handler then return false end
    handler(source, entry, slot)
    return true
end)

lib.callback.register('nhr_inventory:drop', function(source, slot, count)
    local id = playerInventory(source)
    local entry = id and loadInventory(id)[tostring(slot)]
    count = math.floor(tonumber(count) or 0)
    if not entry or count < 1 or count > entry.count then return false end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local dropId = ('drop:%d:%d'):format(os.time(), math.random(1000, 9999))
    inventories[dropId] = {}
    if not addItem(dropId, entry.name, count, entry.metadata) then inventories[dropId] = nil return false end
    removeItem(id, entry.name, count, slot)
    drops[dropId] = { coords = { x = coords.x, y = coords.y, z = coords.z }, created = GetGameTimer() }
    TriggerClientEvent('nhr_inventory:client:dropCreated', -1, dropId, drops[dropId].coords)
    return true
end)

lib.callback.register('nhr_inventory:getDrops', function() return drops end)

lib.callback.register('nhr_inventory:pickup', function(source, dropId)
    local id = playerInventory(source)
    local drop = type(dropId) == 'string' and drops[dropId]
    if not id or not drop then return false end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local dx, dy, dz = coords.x - drop.coords.x, coords.y - drop.coords.y, coords.z - drop.coords.z
    if dx * dx + dy * dy + dz * dz > NHRInventory.DropDistance * NHRInventory.DropDistance then return false end
    local dropItems = inventories[dropId]
    for key, entry in pairs(dropItems) do
        if addItem(id, entry.name, entry.count, entry.metadata) then dropItems[key] = nil end
    end
    if next(dropItems) == nil then
        drops[dropId], inventories[dropId] = nil, nil
        TriggerClientEvent('nhr_inventory:client:dropRemoved', -1, dropId)
    end
    return true
end)

AddEventHandler('nhr_core:server:playerLoaded', function(player)
    local id = 'player:' .. player.PlayerData.citizenid
    loadInventory(id)
    if not player.PlayerData.metadata.nhrInventoryInitialized then
        addItem(id, 'water', 2)
        addItem(id, 'sandwich', 2)
        addItem(id, 'phone', 1, { owner = player.PlayerData.citizenid })
        addItem(id, 'id_card', 1, {
            citizenid = player.PlayerData.citizenid,
            name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            birthdate = player.PlayerData.charinfo.birthdate,
            gender = player.PlayerData.charinfo.gender,
            nationality = player.PlayerData.charinfo.nationality
        })
        player.Functions.SetMetadata('nhrInventoryInitialized', true)
    end
end)

AddEventHandler('nhr_core:server:playerUnloaded', function(_, citizenid) saveInventory('player:' .. citizenid) end)
AddEventHandler('playerDropped', function() opened[source] = nil end)

exports('AddItem', function(source, name, count, metadata, slot) local id = playerInventory(source) return id and addItem(id, name, count, metadata, slot) end)
exports('RemoveItem', function(source, name, count, slot) local id = playerInventory(source) return id and removeItem(id, name, count, slot) end)
exports('GetInventory', function(id) return snapshot(id) end)
exports('GetItemCount', function(source, name)
    local id = playerInventory(source)
    local count = 0
    if id then for _, entry in pairs(loadInventory(id)) do if entry.name == name then count = count + entry.count end end end
    return count
end)
exports('GetItem',function(source,name)
    local id=playerInventory(source);if not id then return end
    for _,entry in pairs(loadInventory(id))do if entry.name==name then return entry end end
end)
exports('CanCarryItem', function(source, name, count)
    local id = playerInventory(source)
    local definition = NHRInventory.Items[name]
    if not id or not definition then return false end
    local items = loadInventory(id)
    local _, maxWeight = settings(id)
    return inventoryWeight(items) + definition.weight * math.max(0, tonumber(count) or 0) <= maxWeight
end)
exports('RegisterUsableItem', function(name, callback) usableItems[name] = callback end)
exports('RegisterStash', function(id, label, slots, maxWeight) stashes[id] = { label = label, slots = slots, maxWeight = maxWeight } end)
exports('AuthorizeStash', function(source, id, label, slots, maxWeight)
    if not exports.nhr_core:GetPlayer(source) or type(id) ~= 'string' then return false end
    stashes[id] = { label = label or id, slots = tonumber(slots) or 40, maxWeight = tonumber(maxWeight) or 100000 }
    opened[source] = { id = id, kind = 'stash' }
    TriggerClientEvent('nhr_inventory:client:openAuthorized', source)
    return true
end)
exports('AuthorizePlayerSearch',function(source,target)
    local player,targetPlayer=exports.nhr_core:GetPlayer(source),exports.nhr_core:GetPlayer(target)
    if not player or not targetPlayer or not Player(target).state.nhrCuffed then return false end
    local id='player:'..targetPlayer.PlayerData.citizenid
    opened[source]={id=id,kind='search',target=target}
    TriggerClientEvent('nhr_inventory:client:openAuthorized',source)
    return true
end)

CreateThread(function()
    while true do
        Wait(120000)
        for id in pairs(inventories) do saveInventory(id) end
        local now = GetGameTimer()
        for id, drop in pairs(drops) do
            if now - drop.created > NHRInventory.DropLifetime then
                drops[id], inventories[id] = nil, nil
                TriggerClientEvent('nhr_inventory:client:dropRemoved', -1, id)
            end
        end
    end
end)

usableItems.water = function(source, entry, slot)
    if removeItem(playerInventory(source), entry.name, 1, slot) then
        local player = exports.nhr_core:GetPlayer(source)
        player.Functions.SetMetadata('thirst', math.min(100, (player.PlayerData.metadata.thirst or 0) + 25))
    end
end

usableItems.sandwich = function(source, entry, slot)
    if removeItem(playerInventory(source), entry.name, 1, slot) then
        local player = exports.nhr_core:GetPlayer(source)
        player.Functions.SetMetadata('hunger', math.min(100, (player.PlayerData.metadata.hunger or 0) + 25))
    end
end
