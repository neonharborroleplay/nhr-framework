local selection = vec4(-1035.71, -2731.87, 20.17, 328.0)
local cameraPosition = vec3(-1032.85, -2728.10, 21.05)
local selectorCamera
local selectorActive = false

local function requestPlayerModel(gender)
    local model = joaat(gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
    if GetEntityModel(PlayerPedId()) == model then return end
    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(model) then return end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
end

local function destroySelectorCamera()
    if selectorCamera and DoesCamExist(selectorCamera) then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(selectorCamera, false)
    end
    selectorCamera = nil
end

local function preparePreview(character)
    requestPlayerModel(character and character.charinfo and character.charinfo.gender or 'male')
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, selection.x, selection.y, selection.z, false, false, false)
    SetEntityHeading(ped, selection.w)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDefaultComponentVariation(ped)
    SetPlayerControl(PlayerId(), false, 0)

    destroySelectorCamera()
    selectorCamera = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', cameraPosition.x, cameraPosition.y,
        cameraPosition.z, 0.0, 0.0, 0.0, 42.0, false, 0)
    PointCamAtEntity(selectorCamera, ped, 0.0, 0.0, 0.65, true)
    SetCamActive(selectorCamera, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function leaveSelector()
    selectorActive = false
    destroySelectorCamera()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetPlayerControl(PlayerId(), true, 0)
end

local function selectCharacter(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return end
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(0) end
    lib.hideContext(false)
    leaveSelector()
    TriggerServerEvent('nhr_multichar:server:select', citizenid)
end

local function createCharacter()
    local input = lib.inputDialog('Create Character', {
        { type = 'input', label = 'First name', required = true, min = 2, max = 24 },
        { type = 'input', label = 'Last name', required = true, min = 2, max = 24 },
        { type = 'date', label = 'Date of birth', required = true, format = 'YYYY-MM-DD' },
        { type = 'select', label = 'Gender', required = true, options = {
            { value = 'male', label = 'Male' }, { value = 'female', label = 'Female' },
            { value = 'other', label = 'Other' }
        }},
        { type = 'input', label = 'Nationality', default = 'San Andreas', max = 32 }
    })
    if not input then return lib.showContext('nhr_character_select') end
    local ok, result = lib.callback.await('nhr_multichar:create', false, {
        firstname = input[1], lastname = input[2], birthdate = input[3], gender = input[4], nationality = input[5]
    })
    if not ok then
        lib.notify({ type = 'error', description = result or 'Character creation failed.' })
        return lib.showContext('nhr_character_select')
    end
    selectCharacter(result)
end

RegisterNetEvent('nhr_multichar:client:open', function()
    if selectorActive then return end
    selectorActive = true
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    local characters = lib.callback.await('nhr_multichar:getCharacters', false) or {}
    preparePreview(characters[1])

    local options = {}
    for i = 1, #characters do
        local character = characters[i]
        options[#options + 1] = {
            title = ('%s %s'):format(character.charinfo.firstname or '', character.charinfo.lastname or ''),
            description = ('%s · $%s bank'):format(character.job.label or 'Civilian', character.money.bank or 0),
            icon = 'user',
            onSelect = function() selectCharacter(character.citizenid) end
        }
    end
    options[#options + 1] = { title = 'Create Character', icon = 'plus', onSelect = createCharacter }
    lib.registerContext({ id = 'nhr_character_select', title = 'Neon Harbor Roleplay', canClose = false, options = options })
    lib.showContext('nhr_character_select')
    DoScreenFadeIn(500)
end)

RegisterNetEvent('nhr_multichar:client:error', function(reason)
    leaveSelector()
    if IsScreenFadedOut() then DoScreenFadeIn(300) end
    lib.notify({ type = 'error', description = reason or 'Unable to load character.' })
    Wait(350)
    TriggerEvent('nhr_multichar:client:open')
end)

AddEventHandler('nhr_core:client:onPlayerLoaded', function()
    leaveSelector()
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    TriggerServerEvent('nhr_multichar:server:sessionStarted')
    TriggerEvent('nhr_multichar:client:open')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then leaveSelector() end
end)

RegisterCommand('logout', function() TriggerServerEvent('nhr_multichar:server:logout') end, false)
