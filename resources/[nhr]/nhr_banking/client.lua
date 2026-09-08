local function amount(title)
    local result = lib.inputDialog(title, { { type = 'number', label = 'Amount', min = 1, required = true } })
    return result and result[1]
end

local function statements()
    local rows = lib.callback.await('nhr_banking:statements', false)
    local options = {}
    for _, row in ipairs(rows or {}) do
        options[#options + 1] = { title = ('%s · $%d'):format(row.kind, row.amount), description = ('%s · %s'):format(row.description, row.created_at) }
    end
    if #options == 0 then options[1] = { title = 'No transactions yet', disabled = true } end
    lib.registerContext({ id = 'nhr_bank_statements', title = 'Recent transactions', menu = 'nhr_bank', options = options })
    lib.showContext('nhr_bank_statements')
end

local function bank()
    local account = lib.callback.await('nhr_banking:account', false)
    if not account then return end
    lib.registerContext({ id = 'nhr_bank', title = ('Bank $%d · Cash $%d'):format(account.bank, account.cash), options = {
        { title = 'Deposit', icon = 'arrow-down', onSelect = function()
            local value = amount('Deposit')
            if value and lib.callback.await('nhr_banking:deposit', false, value) then lib.notify({ type = 'success', description = 'Deposit complete.' }) end
        end },
        { title = 'Withdraw', icon = 'arrow-up', onSelect = function()
            local value = amount('Withdraw')
            if value and lib.callback.await('nhr_banking:withdraw', false, value) then lib.notify({ type = 'success', description = 'Withdrawal complete.' }) end
        end },
        { title = 'Transfer', icon = 'money-bill-transfer', onSelect = function()
            local input = lib.inputDialog('Transfer', {
                { type = 'input', label = 'Citizen ID', required = true },
                { type = 'number', label = 'Amount', min = 1, required = true }
            })
            if input and lib.callback.await('nhr_banking:transfer', false, input[1], input[2]) then lib.notify({ type = 'success', description = 'Transfer complete.' }) end
        end },
        { title = 'Statements', icon = 'file-invoice-dollar', onSelect = statements }
    } })
    lib.showContext('nhr_bank')
end

RegisterCommand('bank', bank, false)
CreateThread(function()
    for _, model in ipairs({ `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm` }) do
        exports.ox_target:addModel(model, { { name = 'nhr_atm', label = 'Use ATM', icon = 'fa-solid fa-building-columns', onSelect = bank } })
    end
end)
