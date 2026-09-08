local function officer(source)
    local player=exports.nhr_core:GetPlayer(source)
    return player and player.PlayerData.job.name=='police' and player.PlayerData.job.onDuty and player
end
lib.callback.register('nhr_mdt:search',function(source,query)
    if not officer(source)then return end
    query=('%'..tostring(query or''):sub(1,40)..'%')
    local people=MySQL.query.await('SELECT citizenid,charinfo,job,metadata FROM nhr_characters WHERE citizenid LIKE ? OR charinfo LIKE ? LIMIT 25',{query,query})or{}
    for _,row in ipairs(people)do row.charinfo=json.decode(row.charinfo or'{}');row.job=json.decode(row.job or'{}');row.metadata=json.decode(row.metadata or'{}')end
    local vehicles=MySQL.query.await('SELECT citizenid,plate,model,state FROM nhr_vehicles WHERE plate LIKE ? OR model LIKE ? LIMIT 25',{query,query})or{}
    return {people=people,vehicles=vehicles}
end)
lib.callback.register('nhr_mdt:reports',function(source,citizenid)
    if not officer(source)then return end
    return MySQL.query.await("SELECT id,author,title,body,suspect,created_at FROM nhr_mdt_reports WHERE suspect=? OR ?='' ORDER BY id DESC LIMIT 50",{tostring(citizenid or''),tostring(citizenid or'')})or{}
end)
lib.callback.register('nhr_mdt:create',function(source,title,body,suspect)
    local player=officer(source);title=tostring(title or''):sub(1,100);body=tostring(body or''):sub(1,5000);suspect=tostring(suspect or''):sub(1,16)
    if not player or #title<3 or #body<5 then return false end
    MySQL.insert.await('INSERT INTO nhr_mdt_reports (author,title,body,suspect) VALUES (?,?,?,?)',{player.PlayerData.citizenid,title,body,suspect});return true
end)
lib.callback.register('nhr_mdt:legal',function(source,citizenid)
    if not officer(source)then return end;citizenid=tostring(citizenid or'')
    return {citations=MySQL.query.await('SELECT id,amount,reason,paid,created_at FROM nhr_citations WHERE citizenid=? ORDER BY id DESC',{citizenid})or{},warrants=MySQL.query.await('SELECT id,reason,active,created_at FROM nhr_warrants WHERE citizenid=? ORDER BY id DESC',{citizenid})or{}}
end)
lib.callback.register('nhr_mdt:payCitations',function(source)
    local player=exports.nhr_core:GetPlayer(source);if not player then return false end
    local total=MySQL.scalar.await('SELECT COALESCE(SUM(amount),0) FROM nhr_citations WHERE citizenid=? AND paid=0',{player.PlayerData.citizenid})or 0
    if total<1 or not player.Functions.RemoveMoney('bank',total,'citation-payment')then return false end
    MySQL.update.await('UPDATE nhr_citations SET paid=1 WHERE citizenid=? AND paid=0',{player.PlayerData.citizenid});return true,total
end)
