local function permitted(source,channel)
    local player=exports.nhr_core:GetPlayer(source);if not player or exports.nhr_inventory:GetItemCount(source,'radio')<1 then return false end
    if channel<=10 then return (player.PlayerData.job.name=='police'or player.PlayerData.job.name=='ambulance')and player.PlayerData.job.onDuty end
    return channel>=11 and channel<=999
end
for channel=1,999 do local id=channel;exports['pma-voice']:addChannelCheck(id,function(source)return permitted(source,id)end)end
lib.callback.register('nhr_radio:join',function(source,channel)channel=math.floor(tonumber(channel)or 0);return permitted(source,channel)end)
exports.nhr_inventory:RegisterUsableItem('radio',function(source)TriggerClientEvent('nhr_radio:client:open',source)end)
