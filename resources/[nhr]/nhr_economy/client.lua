CreateThread(function()
    exports.ox_target:addSphereZone({coords=NHREconomy.launder,radius=1.2,options={{name='nhr_launder',label='Exchange marked bills',icon='fa-solid fa-money-bill-transfer',onSelect=function()
        local input=lib.inputDialog('Exchange Marked Bills',{{type='number',label='Amount',min=1,required=true}});if not input then return end
        local ok,payout=lib.callback.await('nhr_economy:launder',false,input[1]);lib.notify({type=ok and'success'or'error',description=ok and('$'..payout..' received.')or'Exchange failed.'})
    end}}})
end)
