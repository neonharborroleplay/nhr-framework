local function openShop(name)
    local shop = NHRShops[name]
    local options = {}
    for _, product in ipairs(shop.items) do
        local item = product
        options[#options + 1] = { title = item.label, description = ('$%d each'):format(item.price), onSelect = function()
            local input = lib.inputDialog(item.label, {
                { type = 'number', label = 'Quantity', default = 1, min = 1, max = 20, required = true },
                { type = 'select', label = 'Pay with', default = 'cash', options = {
                    { value = 'cash', label = 'Cash' }, { value = 'bank', label = 'Bank' }
                }}
            })
            if not input then return end
            local ok, message = lib.callback.await('nhr_shops:buy', false, name, item.name, input[1], input[2])
            lib.notify({ type = ok and 'success' or 'error', description = message })
        end }
    end
    lib.registerContext({ id = 'nhr_shop_' .. name, title = shop.label, options = options })
    lib.showContext('nhr_shop_' .. name)
end

CreateThread(function()
    for name, shop in pairs(NHRShops) do
        for index, coords in ipairs(shop.locations) do
            exports.ox_target:addSphereZone({ coords = coords, radius = 1.2, options = {
                { name = ('nhr_shop_%s_%d'):format(name, index), label = shop.label, icon = 'fa-solid fa-basket-shopping', onSelect = function() openShop(name) end }
            } })
        end
    end
end)
