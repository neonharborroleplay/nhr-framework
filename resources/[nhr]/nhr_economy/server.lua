lib.callback.register('nhr_economy:launder',function(source,amount)
    local player=exports.nhr_core:GetPlayer(source);amount=math.floor(tonumber(amount)or 0)
    if not player or amount<1 or #(GetEntityCoords(GetPlayerPed(source))-NHREconomy.launder)>5.0 or exports.nhr_inventory:GetItemCount(source,'marked_bills')<amount then return false end
    if not exports.nhr_inventory:RemoveItem(source,'marked_bills',amount)then return false end
    local payout=math.floor(amount*NHREconomy.launderRate)
    player.Functions.AddMoney('cash',payout,'marked-bills-laundering')
    return true,payout
end)
CreateThread(function()
    while true do
        Wait(NHREconomy.taxInterval)
        for _,player in pairs(exports.nhr_core:GetCoreObject().Players)do
            local bank=player.Functions.GetMoney('bank')
            if bank>NHREconomy.bankTaxThreshold then
                player.Functions.RemoveMoney('bank',math.floor((bank-NHREconomy.bankTaxThreshold)*NHREconomy.bankTaxRate),'wealth-tax')
            end
        end
    end
end)
