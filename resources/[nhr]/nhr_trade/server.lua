local offers={}
lib.callback.register('nhr_trade:offer',function(source,target,item,count,price)
    if not exports.nhr_security:CheckRateLimit(source,'trade_offer',6,30000)then return false end
    target=tonumber(target);count=math.floor(tonumber(count)or 0);price=math.floor(tonumber(price)or 0);item=tostring(item or'')
    local entry=exports.nhr_inventory:GetItem(source,item)
    if not exports.nhr_core:GetPlayer(source)or not exports.nhr_core:GetPlayer(target)or #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target)))>5.0 or count<1 or price<0 or not entry or entry.count<count then return false end
    local token=('%d:%d:%d'):format(source,target,math.random(10000,99999));offers[token]={seller=source,buyer=target,item=item,count=count,price=price,slot=entry.slot,metadata=entry.metadata,expires=GetGameTimer()+30000}
    TriggerClientEvent('nhr_trade:client:offer',target,token,item,count,price,GetPlayerName(source));return true
end)
lib.callback.register('nhr_trade:accept',function(source,token)
    if not exports.nhr_security:CheckRateLimit(source,'trade_accept',6,30000)then return false end
    local offer=offers[token];offers[token]=nil;if not offer or offer.buyer~=source or GetGameTimer()>offer.expires then return false end
    local seller,buyer=exports.nhr_core:GetPlayer(offer.seller),exports.nhr_core:GetPlayer(source)
    if not seller or not buyer or #(GetEntityCoords(GetPlayerPed(offer.seller))-GetEntityCoords(GetPlayerPed(source)))>5.0 or exports.nhr_inventory:GetItemCount(offer.seller,offer.item)<offer.count or not exports.nhr_inventory:CanCarryItem(source,offer.item,offer.count) then return false end
    if not buyer.Functions.RemoveMoney('cash',offer.price,'player-trade')then return false end
    if not exports.nhr_inventory:RemoveItem(offer.seller,offer.item,offer.count,offer.slot)then buyer.Functions.AddMoney('cash',offer.price,'trade-refund')return false end
    if not exports.nhr_inventory:AddItem(source,offer.item,offer.count,offer.metadata)then exports.nhr_inventory:AddItem(offer.seller,offer.item,offer.count,offer.metadata,offer.slot);buyer.Functions.AddMoney('cash',offer.price,'trade-refund');return false end
    seller.Functions.AddMoney('cash',offer.price,'player-trade')
    exports.nhr_logs:CreateLog('economy','player_trade',offer.seller,source,{item=offer.item,count=offer.count,price=offer.price});return true
end)
AddEventHandler('playerDropped',function()for token,o in pairs(offers)do if o.seller==source or o.buyer==source then offers[token]=nil end end end)
