RegisterCommand('invoice',function()
    local player=lib.getClosestPlayer(GetEntityCoords(PlayerPedId()),4.0,false);if not player then return end
    local x=lib.inputDialog('Issue Invoice',{{type='number',label='Amount',min=1,max=100000,required=true},{type='input',label='Reason',required=true}});if x then lib.callback.await('nhr_billing:issue',false,GetPlayerServerId(player),x[1],x[2])end
end,false)
local function history()
    local rows=lib.callback.await('nhr_billing:history',false);local options={}
    for _,row in ipairs(rows or{})do options[#options+1]={title=('$%d · %s'):format(row.amount,row.society),description=('%s · %s · %s'):format(row.status,row.reason,row.created_at),disabled=true}end
    if #options==0 then options[1]={title='No invoice history',disabled=true}end
    lib.registerContext({id='nhr_invoice_history',title='Invoice history',menu='nhr_invoices',options=options});lib.showContext('nhr_invoice_history')
end
RegisterCommand('invoices',function()
    local rows=lib.callback.await('nhr_billing:list',false);if not rows then return end;local options={}
    for _,row in ipairs(rows)do local invoice=row;options[#options+1]={title=('$%d · %s'):format(invoice.amount,invoice.society),description=invoice.reason,onSelect=function()local ok=lib.callback.await('nhr_billing:pay',false,invoice.id);lib.notify({type=ok and'success'or'error',description=ok and'Invoice paid.'or'Payment failed.'})end}end
    options[#options+1]={title='View invoice history',icon='clock-rotate-left',onSelect=history}
    lib.registerContext({id='nhr_invoices',title='Invoices',options=options});lib.showContext('nhr_invoices')
end,false)
RegisterNetEvent('nhr_billing:client:received',function(amount,reason)lib.notify({title=('New invoice · $%d'):format(amount),description=reason,duration=8000})end)
