lib.callback.register('nhr_scoreboard:data',function(source)
    if not exports.nhr_security:CheckRateLimit(source,'scoreboard',4,5000)then return end
    local core=exports.nhr_core:GetCoreObject();local result={players={},counts={total=0,police=0,ambulance=0,staff=0}}
    for id,player in pairs(core.Players)do
        local info=player.PlayerData.charinfo;local job=player.PlayerData.job
        result.players[#result.players+1]={id=id,name=info.firstname..' '..info.lastname,ping=GetPlayerPing(id)}
        result.counts.total=result.counts.total+1
        if job.onDuty and job.name=='police'then result.counts.police=result.counts.police+1 end
        if job.onDuty and job.name=='ambulance'then result.counts.ambulance=result.counts.ambulance+1 end
        if IsPlayerAceAllowed(id,'nhr.admin')or IsPlayerAceAllowed(id,'nhr.mod')then result.counts.staff=result.counts.staff+1 end
    end
    table.sort(result.players,function(a,b)return a.id<b.id end);return result
end)
