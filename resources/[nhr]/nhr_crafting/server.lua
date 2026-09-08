local sessions={}
lib.callback.register('nhr_crafting:begin',function(source,benchName,index)
    local bench=NHRCrafting[benchName];local recipe=bench and bench.recipes[tonumber(index)]
    if not recipe or #(GetEntityCoords(GetPlayerPed(source))-bench.coords)>5.0 then return false end
    local player=exports.nhr_core:GetPlayer(source);if not player then return false end
    local xp=MySQL.scalar.await("SELECT xp FROM nhr_crafting_progress WHERE citizenid=? AND discipline='general'",{player.PlayerData.citizenid})or 0
    if xp<(recipe.minXp or 0)then return false end
    for item,count in pairs(recipe.ingredients)do if exports.nhr_inventory:GetItemCount(source,item)<count then return false end end
    sessions[source]={bench=benchName,index=tonumber(index),ready=GetGameTimer()+recipe.time-100}
    return true
end)
lib.callback.register('nhr_crafting:finish',function(source)
    local session=sessions[source];sessions[source]=nil
    local bench=session and NHRCrafting[session.bench];local recipe=bench and bench.recipes[session.index]
    if not recipe or GetGameTimer()<session.ready or #(GetEntityCoords(GetPlayerPed(source))-bench.coords)>5.0 then return false end
    for item,count in pairs(recipe.ingredients)do if exports.nhr_inventory:GetItemCount(source,item)<count then return false end end
    local removed={}
    for item,count in pairs(recipe.ingredients)do
        if not exports.nhr_inventory:RemoveItem(source,item,count)then for old,amount in pairs(removed)do exports.nhr_inventory:AddItem(source,old,amount)end return false end
        removed[item]=count
    end
    if exports.nhr_inventory:AddItem(source,recipe.output,recipe.count)then
        local player=exports.nhr_core:GetPlayer(source);if player then MySQL.prepare.await("INSERT INTO nhr_crafting_progress (citizenid,discipline,xp) VALUES (?,'general',?) ON DUPLICATE KEY UPDATE xp=xp+VALUES(xp)",{player.PlayerData.citizenid,recipe.xp or 1})end
        return true
    end
    for item,count in pairs(recipe.ingredients)do exports.nhr_inventory:AddItem(source,item,count)end
    return false
end)
AddEventHandler('playerDropped',function()sessions[source]=nil end)
