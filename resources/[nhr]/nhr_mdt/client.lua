local function reports(citizenid)
    local rows=lib.callback.await('nhr_mdt:reports',false,citizenid or'');if not rows then return end
    local options={{title='Create report',icon='file-circle-plus',onSelect=function()local x=lib.inputDialog('New Police Report',{{type='input',label='Title',required=true},{type='textarea',label='Report',required=true},{type='input',label='Suspect Citizen ID',default=citizenid}});if x then lib.callback.await('nhr_mdt:create',false,x[1],x[2],x[3])end end}}
    if citizenid and citizenid~=''then local legal=lib.callback.await('nhr_mdt:legal',false,citizenid)or{citations={},warrants={}};for _,row in ipairs(legal.warrants)do options[#options+1]={title=('Warrant #%d · %s'):format(row.id,row.active==1 and'ACTIVE'or'CLOSED'),description=row.reason}end;for _,row in ipairs(legal.citations)do options[#options+1]={title=('Citation #%d · $%d · %s'):format(row.id,row.amount,row.paid==1 and'PAID'or'UNPAID'),description=row.reason}end end
    for _,row in ipairs(rows)do options[#options+1]={title=('#%d · %s'):format(row.id,row.title),description=row.body}end
    lib.registerContext({id='nhr_mdt_reports',title='Police Reports',options=options});lib.showContext('nhr_mdt_reports')
end
RegisterCommand('mdt',function()
    local x=lib.inputDialog('NHR MDT',{{type='input',label='Name, Citizen ID, plate, or model',required=true}});if not x then return end
    local result=lib.callback.await('nhr_mdt:search',false,x[1]);if not result then return end
    local options={{title='All reports',onSelect=function()reports('')end}}
    for _,row in ipairs(result.people)do local person=row;options[#options+1]={title=(person.charinfo.firstname or'')..' '..(person.charinfo.lastname or''),description=person.citizenid..' · '..(person.job.label or'Unknown'),onSelect=function()reports(person.citizenid)end}end
    for _,row in ipairs(result.vehicles)do options[#options+1]={title=row.plate..' · '..row.model,description='Owner '..row.citizenid..' · '..row.state}end
    lib.registerContext({id='nhr_mdt',title='MDT Search',options=options});lib.showContext('nhr_mdt')
end,false)
RegisterCommand('paycitations',function()local ok,total=lib.callback.await('nhr_mdt:payCitations',false);lib.notify({type=ok and'success'or'error',description=ok and('$'..total..' in citations paid.')or'No payable citations or insufficient funds.'})end,false)
