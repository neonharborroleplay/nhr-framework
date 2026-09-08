local inside = {}

local function evictProperty(id,message)
    for occupant,propertyId in pairs(inside)do
        if propertyId==id then inside[occupant]=nil SetPlayerRoutingBucket(occupant,0) TriggerClientEvent('nhr_housing:client:evicted',occupant,id,message)end
    end
end

local function clearExpired(id)
    if MySQL.update.await("DELETE FROM nhr_properties WHERE property_id=? AND ownership_type='rental' AND rent_due<=NOW()",{id})==1 then
        MySQL.update.await('DELETE FROM nhr_property_keys WHERE property_id=?',{id});evictProperty(id,'The property lease expired.')
    end
end

local function access(source, id)
    local player = exports.nhr_core:GetPlayer(source)
    if not player then return false end
    local row = MySQL.single.await("SELECT citizenid,ownership_type,rent_due FROM nhr_properties WHERE property_id=? AND (ownership_type='owned' OR rent_due>NOW())", { id })
    if not row then return false, player end
    local allowed = row.citizenid == player.PlayerData.citizenid or MySQL.scalar.await('SELECT 1 FROM nhr_property_keys WHERE property_id=? AND citizenid=?', { id, player.PlayerData.citizenid }) ~= nil
    return allowed, player, row.citizenid, row.citizenid == player.PlayerData.citizenid, row.ownership_type, row.rent_due
end

local function furnitureRows(id)
    return MySQL.query.await('SELECT id,model,x,y,z,heading FROM nhr_property_furniture WHERE property_id=? ORDER BY id', { id }) or {}
end

local function syncFurniture(id)
    local rows=furnitureRows(id)
    for occupant,propertyId in pairs(inside)do if propertyId==id then TriggerClientEvent('nhr_housing:client:furniture',occupant,rows)end end
    return rows
end

lib.callback.register('nhr_housing:info', function(source, id)
    local property = NHRProperties[id]; if not property then return end
    local allowed, _, ownerId, owned, tenure, rentDue = access(source, id)
    return { owned = owned == true, hasAccess = allowed == true, sold = ownerId ~= nil, rental = tenure == 'rental', rentDue = rentDue, price = property.price, rent = property.rent, label = property.label }
end)

lib.callback.register('nhr_housing:buy', function(source, id)
    if not exports.nhr_security:CheckRateLimit(source, 'property_buy', 3, 30000) then return false end
    local property, player = NHRProperties[id], exports.nhr_core:GetPlayer(source)
    if not property or not player or #(GetEntityCoords(GetPlayerPed(source)) - property.entrance) > 5.0 then return false end
    clearExpired(id)
    if not player.Functions.RemoveMoney('bank', property.price, 'property-purchase') then return false end
    local inserted = MySQL.update.await("INSERT IGNORE INTO nhr_properties (property_id,citizenid,ownership_type) VALUES (?,?,'owned')", { id, player.PlayerData.citizenid })
    if inserted ~= 1 then player.Functions.AddMoney('bank', property.price, 'property-refund') return false end
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { player.PlayerData.citizenid, 'property_buy', property.price, 'Purchased ' .. property.label })
    exports.nhr_logs:CreateLog('economy', 'property_purchase', source, nil, { property = id, price = property.price })
    return true
end)

lib.callback.register('nhr_housing:rent',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'property_rent',3,30000)then return false end
    local property,player=NHRProperties[id],exports.nhr_core:GetPlayer(source)
    if not property or not player or not property.rent or #(GetEntityCoords(GetPlayerPed(source))-property.entrance)>5.0 then return false end
    clearExpired(id)
    if not player.Functions.RemoveMoney('bank',property.rent,'property-rent')then return false end
    local inserted=MySQL.update.await("INSERT IGNORE INTO nhr_properties (property_id,citizenid,ownership_type,rent_due) VALUES (?,?,'rental',DATE_ADD(NOW(),INTERVAL 7 DAY))",{id,player.PlayerData.citizenid})
    if inserted~=1 then player.Functions.AddMoney('bank',property.rent,'property-rent-refund')return false end
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'property_rent',property.rent,'Seven-day lease · '..property.label})
    exports.nhr_logs:CreateLog('economy','property_rented',source,nil,{property=id,rent=property.rent});return true
end)

lib.callback.register('nhr_housing:renew',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'property_renew',3,30000)then return false end
    local property=NHRProperties[id];local allowed,player,_,owned,tenure=access(source,id)
    if not property or not allowed or not owned or tenure~='rental'or #(GetEntityCoords(GetPlayerPed(source))-property.entrance)>5.0 or not player.Functions.RemoveMoney('bank',property.rent,'property-renew')then return false end
    local changed=MySQL.update.await("UPDATE nhr_properties SET rent_due=DATE_ADD(IF(rent_due>NOW(),rent_due,NOW()),INTERVAL 7 DAY) WHERE property_id=? AND citizenid=? AND ownership_type='rental'",{id,player.PlayerData.citizenid})
    if changed~=1 then player.Functions.AddMoney('bank',property.rent,'property-renew-refund')return false end
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)',{player.PlayerData.citizenid,'property_rent',property.rent,'Lease renewal · '..property.label})
    exports.nhr_logs:CreateLog('economy','property_lease_renewed',source,nil,{property=id,rent=property.rent});return true
end)

lib.callback.register('nhr_housing:endLease',function(source,id)
    if not exports.nhr_security:CheckRateLimit(source,'property_end_lease',2,30000)then return false end
    local property=NHRProperties[id];local allowed,player,_,owned,tenure=access(source,id)
    if not property or not allowed or not owned or tenure~='rental'or #(GetEntityCoords(GetPlayerPed(source))-property.entrance)>5.0 then return false end
    if MySQL.update.await("DELETE FROM nhr_properties WHERE property_id=? AND citizenid=? AND ownership_type='rental'",{id,player.PlayerData.citizenid})~=1 then return false end
    MySQL.update.await('DELETE FROM nhr_property_keys WHERE property_id=?',{id});evictProperty(id,'The property lease ended.')
    exports.nhr_logs:CreateLog('economy','property_lease_ended',source,nil,{property=id});return true
end)

lib.callback.register('nhr_housing:enter', function(source, id)
    local property = NHRProperties[id]
    local allowed, _, ownerId, owned = access(source, id)
    if not property or not allowed or #(GetEntityCoords(GetPlayerPed(source)) - property.entrance) > 5.0 then return end
    local characterId = tonumber(MySQL.scalar.await('SELECT id FROM nhr_characters WHERE citizenid=?', { ownerId }))
    if not characterId then return end
    inside[source] = id
    SetPlayerRoutingBucket(source, 10000 + characterId)
    return { position = property.interior, furniture = furnitureRows(id), owned = owned == true }
end)

lib.callback.register('nhr_housing:furniture', function(source, id)
    local allowed = access(source, id)
    if not allowed or inside[source] ~= id then return {} end
    return furnitureRows(id)
end)

lib.callback.register('nhr_housing:placeFurniture', function(source, id, key, coords, heading)
    if not exports.nhr_security:CheckRateLimit(source, 'furniture_place', 8, 30000) then return false end
    local definition, property = NHRHousingFurniture[tostring(key or '')], NHRProperties[id]
    local allowed, player, _, owned = access(source, id)
    if not definition or not property or not allowed or not owned or inside[source] ~= id or type(coords) ~= 'table' then return false end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z or #(GetEntityCoords(GetPlayerPed(source)) - vec3(x, y, z)) > 4.0 or #(property.interior.xyz - vec3(x, y, z)) > 25.0 then return false end
    if (MySQL.scalar.await('SELECT COUNT(*) FROM nhr_property_furniture WHERE property_id=?', { id }) or 0) >= 30 then return false end
    if not player.Functions.RemoveMoney('bank', definition.price, 'property-furniture') then return false end
    local furnitureId = MySQL.insert.await('INSERT INTO nhr_property_furniture (property_id,model,x,y,z,heading,placed_by) VALUES (?,?,?,?,?,?,?)', { id, definition.model, x, y, z, tonumber(heading) or 0.0, player.PlayerData.citizenid })
    if not furnitureId then player.Functions.AddMoney('bank', definition.price, 'furniture-refund') return false end
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { player.PlayerData.citizenid, 'furniture', definition.price, definition.label })
    exports.nhr_logs:CreateLog('economy','furniture_purchase',source,nil,{property=id,model=definition.model,price=definition.price})
    return syncFurniture(id)
end)

lib.callback.register('nhr_housing:removeFurniture', function(source, id, furnitureId)
    if not exports.nhr_security:CheckRateLimit(source, 'furniture_remove', 8, 30000) then return false end
    local allowed, _, _, owned = access(source, id)
    if not allowed or not owned or inside[source] ~= id then return false end
    local row = MySQL.single.await('SELECT x,y,z FROM nhr_property_furniture WHERE id=? AND property_id=?', { tonumber(furnitureId), id })
    if not row or #(GetEntityCoords(GetPlayerPed(source)) - vec3(tonumber(row.x), tonumber(row.y), tonumber(row.z))) > 4.0 then return false end
    if MySQL.update.await('DELETE FROM nhr_property_furniture WHERE id=? AND property_id=?', { tonumber(furnitureId), id }) ~= 1 then return false end
    exports.nhr_logs:CreateLog('economy','furniture_removed',source,nil,{property=id,furniture=tonumber(furnitureId)})
    return syncFurniture(id)
end)

lib.callback.register('nhr_housing:sell', function(source, id)
    if not exports.nhr_security:CheckRateLimit(source, 'property_sell', 2, 60000) then return false end
    local property = NHRProperties[id]
    local allowed, player, _, owned, tenure = access(source, id)
    if not property or not allowed or not owned or tenure~='owned'or #(GetEntityCoords(GetPlayerPed(source)) - property.entrance) > 5.0 then return false end
    local changed = MySQL.update.await("DELETE FROM nhr_properties WHERE property_id=? AND citizenid=? AND ownership_type='owned'", { id, player.PlayerData.citizenid })
    if changed ~= 1 then return false end
    MySQL.update.await('DELETE FROM nhr_property_keys WHERE property_id=?', { id })
    local refund = math.floor(property.price * (property.resalePercent or 0.6))
    player.Functions.AddMoney('bank', refund, 'property-resale')
    MySQL.insert('INSERT INTO nhr_transactions (citizenid,kind,amount,description) VALUES (?,?,?,?)', { player.PlayerData.citizenid, 'property_sale', refund, 'Sold ' .. property.label })
    evictProperty(id,'The property was sold.')
    exports.nhr_logs:CreateLog('economy', 'property_resale', source, nil, { property = id, refund = refund })
    return refund
end)

lib.callback.register('nhr_housing:key', function(source, id, target, action)
    if not exports.nhr_security:CheckRateLimit(source, 'property_key', 6, 30000) then return false end
    target = tonumber(target)
    local allowed, ownerPlayer, _, owned = access(source, id)
    local recipient = target and exports.nhr_core:GetPlayer(target)
    if not allowed or not owned or not recipient or target == source or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target))) > 5.0 then return false end
    local changed
    if action == 'grant' then
        changed = MySQL.update.await('INSERT IGNORE INTO nhr_property_keys (property_id,citizenid,granted_by) VALUES (?,?,?)', { id, recipient.PlayerData.citizenid, ownerPlayer.PlayerData.citizenid })
    elseif action == 'revoke' then
        changed = MySQL.update.await('DELETE FROM nhr_property_keys WHERE property_id=? AND citizenid=?', { id, recipient.PlayerData.citizenid })
    else return false end
    if changed and changed > 0 then exports.nhr_logs:CreateLog('economy', 'property_key_' .. action, source, target, { property = id }); return true end
    return false
end)

RegisterNetEvent('nhr_housing:server:exit', function(id)
    if inside[source] == id then inside[source] = nil SetPlayerRoutingBucket(source, 0) end
end)

RegisterNetEvent('nhr_housing:server:stash', function(id)
    local allowed, _, ownerId = access(source, id)
    if not allowed or inside[source] ~= id or GetPlayerRoutingBucket(source) == 0 or #(GetEntityCoords(GetPlayerPed(source)) - NHRHousingInterior.stash) > 3.0 then return end
    exports.nhr_inventory:AuthorizeStash(source, 'property:' .. id .. ':' .. ownerId, 'Property Storage', 60, 200000)
end)

AddEventHandler('playerDropped', function() inside[source] = nil end)

CreateThread(function()
    while not GlobalState.nhrMigrationsReady do Wait(100)end
    while true do
        local expired=MySQL.query.await("SELECT property_id,citizenid FROM nhr_properties WHERE ownership_type='rental' AND rent_due<=NOW()")or{}
        for _,row in ipairs(expired)do
            if MySQL.update.await("DELETE FROM nhr_properties WHERE property_id=? AND citizenid=? AND ownership_type='rental' AND rent_due<=NOW()",{row.property_id,row.citizenid})==1 then
                MySQL.update.await('DELETE FROM nhr_property_keys WHERE property_id=?',{row.property_id});evictProperty(row.property_id,'The property lease expired.')
                local renter=exports.nhr_core:GetPlayerByCitizenId(row.citizenid);if renter then TriggerClientEvent('nhr_housing:client:leaseExpired',renter.PlayerData.source,NHRProperties[row.property_id]and NHRProperties[row.property_id].label or row.property_id)end
            end
        end
        Wait(60000)
    end
end)
