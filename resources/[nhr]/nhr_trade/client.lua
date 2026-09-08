RegisterCommand('trade',function()
    local player=lib.getClosestPlayer(GetEntityCoords(PlayerPedId()),4.0,false);if not player then return end
    local x=lib.inputDialog('Offer Trade',{{type='input',label='Item name',required=true},{type='number',label='Quantity',min=1,required=true},{type='number',label='Cash price',min=0,required=true}})
    if x then local ok=lib.callback.await('nhr_trade:offer',false,GetPlayerServerId(player),x[1],x[2],x[3]);lib.notify({type=ok and'success'or'error',description=ok and'Trade offered.'or'Invalid trade.'})end
end,false)
RegisterNetEvent('nhr_trade:client:offer',function(token,item,count,price,seller)
    local answer=lib.alertDialog({header='Trade offer from '..seller,content=('%dx %s for $%d cash'):format(count,item,price),cancel=true})
    if answer=='confirm'then local ok=lib.callback.await('nhr_trade:accept',false,token);lib.notify({type=ok and'success'or'error',description=ok and'Trade completed.'or'Trade failed.'})end
end)
