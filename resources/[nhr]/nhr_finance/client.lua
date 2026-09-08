RegisterCommand('vehiclefinance',function()
    local rows=lib.callback.await('nhr_finance:list',false);if not rows then return end
    local options={};for _,row in ipairs(rows)do local loan=row;options[#options+1]={title=loan.model..' · '..loan.plate,description=('$%d remaining · $%d payment'):format(loan.finance_balance,loan.finance_payment),onSelect=function()local ok,amount=lib.callback.await('nhr_finance:pay',false,loan.plate);lib.notify({type=ok and'success'or'error',description=ok and('$'..amount..' payment completed.')or'Payment failed.'})end}end
    lib.registerContext({id='nhr_finance',title='Vehicle Financing',options=options});lib.showContext('nhr_finance')
end,false)
