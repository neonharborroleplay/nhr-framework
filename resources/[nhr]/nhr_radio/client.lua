local currentChannel=0

local function leaveRadio(message)
    exports['pma-voice']:setRadioChannel(0)
    currentChannel=0
    if message then lib.notify({type='error',description=message})end
end

local function openRadio()
    local input=lib.inputDialog('NHR Radio',{{type='number',label='Channel (0 to leave)',min=0,max=999,required=true}});if not input then return end
    local channel=math.floor(input[1]);if channel==0 then leaveRadio()return end
    if lib.callback.await('nhr_radio:join',false,channel)then exports['pma-voice']:setRadioChannel(channel)currentChannel=channel lib.notify({description='Joined radio '..channel})else lib.notify({type='error',description='Channel access denied.'})end
end
RegisterNetEvent('nhr_radio:client:open',openRadio)
RegisterCommand('radio',openRadio,false)

CreateThread(function()
    while true do
        Wait(5000)
        if currentChannel>0 and not lib.callback.await('nhr_radio:join',false,currentChannel)then leaveRadio('Radio access was lost.')end
    end
end)
