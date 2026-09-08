local function atShop(source)return #(GetEntityCoords(GetPlayerPed(source))-NHRWeaponShop.coords)<=5.0 end
lib.callback.register('nhr_weapons:buy',function(source,item)
    local player=exports.nhr_core:GetPlayer(source);if not player or not atShop(source)then return false end
    local price=item=='weapon_pistol'and NHRWeaponShop.pistolPrice or item=='pistol_ammo'and NHRWeaponShop.ammoPrice
    if not price then return false end
    if item=='weapon_pistol'and not MySQL.scalar.await("SELECT 1 FROM nhr_licenses WHERE citizenid=? AND license_type='weapon'",{player.PlayerData.citizenid})then return false end
    if not player.Functions.RemoveMoney('bank',price,'weapon-shop')then return false end
    local metadata=item=='weapon_pistol'and{serial=('NHR-%s-%05d'):format(player.PlayerData.citizenid:sub(-4),math.random(0,99999)),owner=player.PlayerData.citizenid}or{}
    if not exports.nhr_inventory:AddItem(source,item,1,metadata)then player.Functions.AddMoney('bank',price,'weapon-refund')return false end
    return true
end)
lib.callback.register('nhr_weapons:license',function(source,target,action)
    local officer=exports.nhr_core:GetPlayer(source);target=tonumber(target);local citizen=target and exports.nhr_core:GetPlayer(target)
    if not officer or officer.PlayerData.job.name~='police'or not officer.PlayerData.job.onDuty or not citizen or #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))>5.0 then return false end
    if action=='grant'then MySQL.prepare.await("INSERT INTO nhr_licenses (citizenid,license_type,issued_by) VALUES (?,'weapon',?) ON DUPLICATE KEY UPDATE issued_by=VALUES(issued_by),issued_at=NOW()",{citizen.PlayerData.citizenid,officer.PlayerData.citizenid});return true end
    if action=='revoke'then return MySQL.update.await("DELETE FROM nhr_licenses WHERE citizenid=? AND license_type='weapon'",{citizen.PlayerData.citizenid})==1 end
    return false
end)
exports.nhr_inventory:RegisterUsableItem('weapon_pistol',function(source,item)TriggerClientEvent('nhr_weapons:client:equip',source,item.metadata and item.metadata.serial)end)
exports.nhr_inventory:RegisterUsableItem('pistol_ammo',function(source,item,slot)if exports.nhr_inventory:RemoveItem(source,item.name,1,slot)then TriggerClientEvent('nhr_weapons:client:ammo',source,12)end end)
lib.callback.register('nhr_weapons:hasPistol',function(source)return exports.nhr_inventory:GetItemCount(source,'weapon_pistol')>0 end)
