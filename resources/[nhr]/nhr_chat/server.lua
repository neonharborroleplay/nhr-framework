local function characterName(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return GetPlayerName(source)or'Unknown'end
    local info=player.PlayerData.charinfo;return info.firstname..' '..info.lastname
end
local function clean(args)
    local message=table.concat(args or{},' '):gsub('[\r\n]',' '):sub(1,180)
    return message:match('^%s*(.-)%s*$')
end
local function sendNearby(source,label,message,color)
    local ped=GetPlayerPed(source);if ped==0 then return end;local coords=GetEntityCoords(ped)
    for _,id in ipairs(GetPlayers())do local target=tonumber(id);local targetPed=GetPlayerPed(target);if targetPed~=0 and #(coords-GetEntityCoords(targetPed))<=20.0 then TriggerClientEvent('chat:addMessage',target,{color=color,multiline=true,args={label,message}})end end
end
RegisterCommand('me',function(source,args)
    local message=clean(args);if source==0 or #message<1 or not exports.nhr_security:CheckRateLimit(source,'chat_me',6,10000)then return end
    sendNearby(source,'ME · '..characterName(source),message,{196,155,255})
end,false)
RegisterCommand('do',function(source,args)
    local message=clean(args);if source==0 or #message<1 or not exports.nhr_security:CheckRateLimit(source,'chat_do',6,10000)then return end
    sendNearby(source,'DO · '..characterName(source),message,{125,200,255})
end,false)
RegisterCommand('ooc',function(source,args)
    local message=clean(args);if source==0 or #message<1 or not exports.nhr_security:CheckRateLimit(source,'chat_ooc',3,30000)then return end
    TriggerClientEvent('chat:addMessage',-1,{color={170,170,170},multiline=true,args={'OOC · '..GetPlayerName(source),message}})
end,false)
AddEventHandler('chatMessage',function(source,_,message)
    if source<=0 or tostring(message):sub(1,1)=='/'then return end
    CancelEvent();message=tostring(message):gsub('[\r\n]',' '):sub(1,180)
    if #message>0 and exports.nhr_security:CheckRateLimit(source,'chat_local',8,10000)then sendNearby(source,characterName(source),message,{235,235,235})end
end)
