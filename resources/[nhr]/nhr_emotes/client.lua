local active=false
local function cancel()if active then ClearPedTasks(PlayerPedId());active=false end end
local function play(name)
    if name=='c'or name=='cancel'then return cancel()end
    local emote=NHREmotes[name];local ped=PlayerPedId()
    if not emote then return lib.notify({type='error',description='Unknown emote. Use /emotes.'})end
    if IsEntityDead(ped)or IsPedInAnyVehicle(ped,false)or LocalPlayer.state.nhrCuffed then return lib.notify({type='error',description='You cannot use an emote now.'})end
    cancel()
    if emote.type=='scenario'then TaskStartScenarioInPlace(ped,emote.scenario,0,true)
    else lib.requestAnimDict(emote.dict);TaskPlayAnim(ped,emote.dict,emote.clip,3.0,3.0,-1,emote.flag or 49,0.0,false,false,false)end
    active=true
end
RegisterCommand('e',function(_,args)play(tostring(args[1]or''):lower())end,false)
RegisterCommand('emotes',function()
    local options={};for name,emote in pairs(NHREmotes)do local key=name;options[#options+1]={title=emote.label,description='/e '..name,onSelect=function()play(key)end}end
    table.sort(options,function(a,b)return a.title<b.title end);lib.registerContext({id='nhr_emotes',title='Emotes',options=options});lib.showContext('nhr_emotes')
end,false)
RegisterCommand('nhr_emote_cancel',cancel,false)
RegisterKeyMapping('nhr_emote_cancel','Cancel current emote','keyboard','X')
CreateThread(function()TriggerEvent('chat:addSuggestion','/e','Play an allowlisted emote',{{name='name',help='Use /emotes to browse'}})end)
AddEventHandler('nhr_core:client:onPlayerUnloaded',cancel)
AddEventHandler('onResourceStop',function(resource)if resource==GetCurrentResourceName()then cancel()end end)
