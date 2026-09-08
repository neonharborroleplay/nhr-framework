local allowedWeather={CLEAR=true,EXTRASUNNY=true,CLOUDS=true,OVERCAST=true,RAIN=true,THUNDER=true,FOGGY=true,SMOG=true,XMAS=true,HALLOWEEN=true}
local world={hour=NHRWorld.startHour,minute=NHRWorld.startMinute,weather=NHRWorld.weatherCycle[1],blackout=false}
local weatherIndex=1

local function sync()GlobalState.nhrWorld=world end
local function admin(source)return source==0 or IsPlayerAceAllowed(source,'nhr.admin')end
local function notify(source,message)
    if source==0 then print('[NHR WORLD] '..message)else TriggerClientEvent('ox_lib:notify',source,{description=message})end
end

RegisterCommand('time',function(source,args)
    if not admin(source)then return end
    local hour,minute=math.floor(tonumber(args[1])or-1),math.floor(tonumber(args[2])or 0)
    if hour<0 or hour>23 or minute<0 or minute>59 then return notify(source,'Usage: /time [0-23] [0-59]')end
    world.hour,world.minute=hour,minute;sync();exports.nhr_logs:CreateLog('admin','world_time',source,nil,{hour=hour,minute=minute})
end,false)

RegisterCommand('weather',function(source,args)
    if not admin(source)then return end
    local value=tostring(args[1]or''):upper()
    if not allowedWeather[value]then return notify(source,'Invalid weather type.')end
    world.weather=value;sync();exports.nhr_logs:CreateLog('admin','world_weather',source,nil,{weather=value})
end,false)

RegisterCommand('blackout',function(source)
    if not admin(source)then return end
    world.blackout=not world.blackout;sync();exports.nhr_logs:CreateLog('admin','world_blackout',source,nil,{enabled=world.blackout})
end,false)

CreateThread(function()
    sync()
    local weatherAt=GetGameTimer()+NHRWorld.weatherIntervalMs
    while true do
        Wait(NHRWorld.clockTickMs)
        local total=world.hour*60+world.minute+NHRWorld.minutesPerTick
        world.hour=math.floor(total/60)%24;world.minute=total%60
        if GetGameTimer()>=weatherAt then weatherIndex=weatherIndex%#NHRWorld.weatherCycle+1;world.weather=NHRWorld.weatherCycle[weatherIndex];weatherAt=GetGameTimer()+NHRWorld.weatherIntervalMs end
        sync()
    end
end)
