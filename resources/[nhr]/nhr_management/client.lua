local function statements()
    local rows = lib.callback.await('nhr_management:statements', false)
    local options = {}
    for _, row in ipairs(rows or {}) do
        options[#options + 1] = { title = ('%s · $%d'):format(row.kind, row.amount), description = ('%s · %s'):format(row.citizenid, row.created_at) }
    end
    if #options == 0 then options[1] = { title = 'No society transactions yet', disabled = true } end
    lib.registerContext({ id = 'nhr_society_statements', title = 'Society transactions', menu = 'nhr_boss', options = options })
    lib.showContext('nhr_society_statements')
end

RegisterCommand('bossmenu', function()
    local core = exports.nhr_core:GetCoreObject()
    if not core.PlayerData.job.isBoss then return end
    local balance = lib.callback.await('nhr_management:account', false)
    if balance == nil then return end
    lib.registerContext({ id = 'nhr_boss', title = ('%s · $%d'):format(core.PlayerData.job.label, balance), options = {
        { title = 'Deposit cash', onSelect = function() local x=lib.inputDialog('Deposit',{ {type='number',label='Amount',min=1,required=true} }); if x then lib.callback.await('nhr_management:deposit',false,x[1]) end end },
        { title = 'Withdraw cash', onSelect = function() local x=lib.inputDialog('Withdraw',{ {type='number',label='Amount',min=1,required=true} }); if x then lib.callback.await('nhr_management:withdraw',false,x[1]) end end },
        { title = 'Transaction history', icon = 'file-invoice-dollar', onSelect = statements },
        { title = 'Manage nearby employee', onSelect = function()
            local playerId = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 4.0, false)
            if not playerId then return end
            local input=lib.inputDialog('Employee action',{ {type='select',label='Action',options={{value='hire',label='Hire'},{value='fire',label='Fire'},{value='grade',label='Set grade'}}},{type='number',label='Grade',default=0,min=0} })
            if input then lib.callback.await('nhr_management:employee',false,GetPlayerServerId(playerId),input[1],input[2]) end
        end }
    } }); lib.showContext('nhr_boss')
end, false)
