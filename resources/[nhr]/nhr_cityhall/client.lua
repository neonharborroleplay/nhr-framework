RegisterNetEvent('nhr_cityhall:client:document', function(title, data)
    data = data or {}
    lib.alertDialog({ header = title, content = ('**%s**\n\nCitizen ID: `%s`\n\nBirthdate: %s\n\nNationality: %s'):format(data.name or 'Unknown', data.citizenid or 'Unknown', data.birthdate or 'Unknown', data.nationality or 'Unknown'), centered = true })
end)

local function present(item)
    local player=lib.getClosestPlayer(GetEntityCoords(PlayerPedId()),5.0,false)
    if not player then return lib.notify({type='error',description='No player nearby.'})end
    local ok=lib.callback.await('nhr_cityhall:present',false,GetPlayerServerId(player),item)
    lib.notify({type=ok and'success'or'error',description=ok and'Document shown.'or'Unable to show that document.'})
end
RegisterCommand('showid',function()present('id_card')end,false)
RegisterCommand('showlicense',function()present('driver_license')end,false)

local function jobMenu(info)
    local options = {}
    for _, job in ipairs(info.jobs or {}) do
        local row = job
        options[#options + 1] = { title = row.label, description = ('%s · Grade %d'):format(row.gradeName, row.grade), disabled = row.active, onSelect = function()
            local ok = lib.callback.await('nhr_cityhall:switchJob', false, row.name)
            lib.notify({ type = ok and 'success' or 'error', description = ok and ('Active job: ' .. row.label) or 'Unable to switch jobs.' })
        end }
    end
    lib.registerContext({ id = 'nhr_cityhall_jobs', title = 'Employment records', menu = 'nhr_cityhall', options = options })
    lib.showContext('nhr_cityhall_jobs')
end

local function openCityHall()
    local info = lib.callback.await('nhr_cityhall:info', false)
    if not info then return end
    local licenseNames = {}
    for _, license in ipairs(info.licenses or {}) do licenseNames[#licenseNames + 1] = license.license_type end
    local options = {
        { title = 'Replacement ID · $' .. NHRCityHall.idFee, onSelect = function() local ok=lib.callback.await('nhr_cityhall:document',false,'id');lib.notify({type=ok and'success'or'error',description=ok and'ID issued.'or'You already have an ID or cannot pay.'})end },
        { title = 'Replace driver license · $' .. NHRCityHall.driverLicenseFee, description = #licenseNames > 0 and ('Recorded licenses: ' .. table.concat(licenseNames, ', ')) or 'Pass the driving exam before requesting a license.', onSelect = function() local ok=lib.callback.await('nhr_cityhall:document',false,'driver');lib.notify({type=ok and'success'or'error',description=ok and'License replacement issued.'or'No license record, document already carried, or payment failed.'})end },
        { title = 'Employment records', description = 'Switch between jobs you already hold.', onSelect = function() jobMenu(info) end }
    }
    lib.registerContext({ id = 'nhr_cityhall', title = 'Los Santos City Hall', options = options })
    lib.showContext('nhr_cityhall')
end

CreateThread(function()
    exports.ox_target:addSphereZone({ coords = NHRCityHall.coords, radius = 2.0, options = {{ name = 'nhr_cityhall', label = 'City Hall services', icon = 'fa-solid fa-landmark', onSelect = openCityHall }} })
end)
