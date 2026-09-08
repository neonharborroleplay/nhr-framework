local function menu(id)
    local info=lib.callback.await('nhr_businesses:info',false,id);if not info then return end
    local options={}
    if info.owned then options={
        {title=info.isOpen and'Close business'or'Open business',description='Current status: '..(info.isOpen and'Open'or'Closed'),onSelect=function()local ok=lib.callback.await('nhr_businesses:toggle',false,id,not info.isOpen);lib.notify({type=ok and'success'or'error',description=ok and'Business status updated.'or'Unable to change status.'})end},
        {title='Management',description='Use /bossmenu for society funds, history, and employees.',disabled=true},
        {title=('Sell to city · $%d'):format(math.floor(info.price*0.5)),onSelect=function()local answer=lib.alertDialog({header='Sell business?',content='This removes your ownership and job access.',cancel=true,centered=true});if answer=='confirm'then local refund=lib.callback.await('nhr_businesses:sell',false,id);lib.notify({type=refund and'success'or'error',description=refund and('Business sold for $'..refund)or'Sale failed.'})end end}
    }
    elseif info.owner then options={{title=info.isOpen and'Open'or'Closed',description='Privately owned',disabled=true}}
    else options={{title=('Purchase · $%d'):format(info.price),onSelect=function()local ok=lib.callback.await('nhr_businesses:buy',false,id);lib.notify({type=ok and'success'or'error',description=ok and'Business purchased.'or'Purchase failed.'})end}}
    end
    lib.registerContext({id='nhr_business',title=info.label,options=options});lib.showContext('nhr_business')
end
CreateThread(function()for id,b in pairs(NHRBusinesses)do local businessId=id;exports.ox_target:addSphereZone({coords=b.coords,radius=1.5,options={{name='nhr_business_'..businessId,label=b.label,icon='fa-solid fa-store',onSelect=function()menu(businessId)end}}})end end)
