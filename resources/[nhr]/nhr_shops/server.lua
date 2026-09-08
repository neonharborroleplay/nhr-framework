lib.callback.register('nhr_shops:buy', function(source, shopName, itemName, count, account)
    local shop = NHRShops[shopName]
    local player = exports.nhr_core:GetPlayer(source)
    count = math.floor(tonumber(count) or 0)
    if not shop or not player or count < 1 or count > 20 then return false, 'Invalid purchase.' end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local nearby = false
    for _, location in ipairs(shop.locations) do if #(coords - location) <= 5.0 then nearby = true break end end
    if not nearby then return false, 'You are not at this shop.' end
    local product
    for _, item in ipairs(shop.items) do if item.name == itemName then product = item break end end
    if not product then return false, 'Item is not sold here.' end
    account = account == 'bank' and 'bank' or 'cash'
    local total = product.price * count
    if not exports.nhr_inventory:CanCarryItem(source, itemName, count) then return false, 'Inventory is too heavy.' end
    if not player.Functions.RemoveMoney(account, total, 'shop-purchase') then return false, 'Not enough money.' end
    local added = exports.nhr_inventory:AddItem(source, itemName, count)
    if not added then
        player.Functions.AddMoney(account, total, 'shop-refund')
        return false, 'Inventory has no suitable slot.'
    end
    return true, ('Purchased %dx %s for $%d.'):format(count, product.label, total)
end)
