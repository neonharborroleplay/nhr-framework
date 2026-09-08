local open,held=false,false
local function show()
    held=true
    local data=lib.callback.await('nhr_scoreboard:data',false);if not data or not held then return end
    local counts=data.counts;local options={{title=('Players %d · Police %d · EMS %d · Staff %d'):format(counts.total,counts.police,counts.ambulance,counts.staff),disabled=true}}
    for _,player in ipairs(data.players)do options[#options+1]={title=('[%d] %s'):format(player.id,player.name),description=('Ping: %d ms'):format(player.ping),disabled=true}end
    lib.registerContext({id='nhr_scoreboard',title='NHR Server',options=options});lib.showContext('nhr_scoreboard');open=true
end
RegisterCommand('+nhrscoreboard',show,false)
RegisterCommand('-nhrscoreboard',function()held=false;if open then lib.hideContext();open=false end end,false)
RegisterKeyMapping('+nhrscoreboard','Hold player scoreboard','keyboard','HOME')
