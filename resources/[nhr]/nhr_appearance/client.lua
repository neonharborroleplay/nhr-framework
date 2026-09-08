local initialCore = exports.nhr_core:GetCoreObject()
local playerLoaded = initialCore.PlayerLoaded == true
local playerData = initialCore.PlayerData or {}
local editorOpen = false
local requiredSetup = false
local originalAppearance
local editorCamera
local currentBlend = { mother = 0, father = 0, shapeMix = 0.5, skinMix = 0.5 }
local mapBlips = {}

local cameraViews = {
    whole = { distance = 3.45, cameraZ = 0.88, targetZ = 0.88, fov = 42.0 },
    head = { distance = 1.05, cameraZ = 1.62, targetZ = 1.62, fov = 34.0 },
    chest = { distance = 1.45, cameraZ = 1.08, targetZ = 1.08, fov = 36.0 },
    legs = { distance = 1.55, cameraZ = 0.52, targetZ = 0.52, fov = 37.0 },
    shoes = { distance = 1.15, cameraZ = 0.12, targetZ = 0.12, fov = 34.0 }
}

local componentLabels = {
    [0] = 'Face', [1] = 'Masks', [3] = 'Upper body', [4] = 'Legs', [5] = 'Bags',
    [6] = 'Shoes', [7] = 'Accessories', [8] = 'Undershirt', [9] = 'Armor',
    [10] = 'Decals', [11] = 'Tops'
}
local propLabels = { [0] = 'Hats', [1] = 'Glasses', [2] = 'Ears', [6] = 'Watches', [7] = 'Bracelets' }
local overlayLabels = {
    [0] = 'Blemishes', [1] = 'Facial hair', [2] = 'Eyebrows', [3] = 'Ageing',
    [4] = 'Makeup', [5] = 'Blush', [6] = 'Complexion', [7] = 'Sun damage',
    [8] = 'Lipstick', [9] = 'Moles', [10] = 'Chest hair', [11] = 'Body blemishes',
    [12] = 'Additional body blemishes'
}
local overlayColorTypes = { [1] = 1, [2] = 1, [4] = 1, [5] = 2, [8] = 2, [10] = 1 }

local function modelName()
    return GetEntityModel(PlayerPedId()) == joaat('mp_f_freemode_01') and 'female' or 'male'
end

local function loadModel(gender)
    local hash = joaat(gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
    if GetEntityModel(PlayerPedId()) == hash then return true end
    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return false end
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    currentBlend = { mother = 0, father = 0, shapeMix = 0.5, skinMix = 0.5 }
    return true
end

local function captureAppearance()
    local ped = PlayerPedId()
    local appearance = {
        version = 2, model = modelName(), components = {}, props = {}, faceFeatures = {}, overlays = {},
        hair = {
            style = GetPedDrawableVariation(ped, 2), texture = GetPedTextureVariation(ped, 2),
            color = GetPedHairColor(ped), highlight = GetPedHairHighlightColor(ped)
        },
        eyeColor = GetPedEyeColor(ped),
        headBlend = {
            mother = currentBlend.mother, father = currentBlend.father,
            shapeMix = currentBlend.shapeMix, skinMix = currentBlend.skinMix
        }
    }
    for id in pairs(componentLabels) do
        appearance.components[tostring(id)] = {
            drawable = GetPedDrawableVariation(ped, id), texture = GetPedTextureVariation(ped, id)
        }
    end
    for id in pairs(propLabels) do
        appearance.props[tostring(id)] = {
            drawable = GetPedPropIndex(ped, id), texture = GetPedPropTextureIndex(ped, id)
        }
    end
    for index = 0, 19 do appearance.faceFeatures[index + 1] = GetPedFaceFeature(ped, index) end
    for id in pairs(overlayLabels) do
        local _, value, colorType, color, secondColor, opacity = GetPedHeadOverlayData(ped, id)
        colorType = tonumber(colorType) or 0
        if colorType <= 0 then colorType = overlayColorTypes[id] or 0 end
        appearance.overlays[tostring(id)] = {
            value = value == 255 and -1 or value, opacity = opacity or 1.0,
            colorType = colorType,
            color = color or 0, secondColor = secondColor or 0
        }
    end
    return appearance
end

local function applyAppearance(appearance)
    if type(appearance) ~= 'table' or appearance.version ~= 2 then return end
    loadModel(appearance.model)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    local blend = appearance.headBlend or {}
    currentBlend = {
        mother = tonumber(blend.mother) or 0, father = tonumber(blend.father) or 0,
        shapeMix = tonumber(blend.shapeMix) or 0.5, skinMix = tonumber(blend.skinMix) or 0.5
    }
    SetPedHeadBlendData(ped, currentBlend.mother, currentBlend.father, 0,
        currentBlend.mother, currentBlend.father, 0,
        currentBlend.shapeMix, currentBlend.skinMix, 0.0, false)
    for key, value in pairs(appearance.faceFeatures or {}) do
        SetPedFaceFeature(ped, tonumber(key) - 1, tonumber(value) or 0.0)
    end
    for key, value in pairs(appearance.components or {}) do
        local id = tonumber(key)
        if id then SetPedComponentVariation(ped, id, tonumber(value.drawable) or 0, tonumber(value.texture) or 0, 2) end
    end
    for key, value in pairs(appearance.props or {}) do
        local id, drawable = tonumber(key), tonumber(value.drawable) or -1
        if id then
            if drawable < 0 then ClearPedProp(ped, id)
            else SetPedPropIndex(ped, id, drawable, tonumber(value.texture) or 0, true) end
        end
    end
    local hair = appearance.hair or {}
    SetPedComponentVariation(ped, 2, tonumber(hair.style) or 0, tonumber(hair.texture) or 0, 2)
    SetPedHairColor(ped, tonumber(hair.color) or 0, tonumber(hair.highlight) or 0)
    SetPedEyeColor(ped, tonumber(appearance.eyeColor) or 0)
    for key, value in pairs(appearance.overlays or {}) do
        local id, overlay = tonumber(key), tonumber(value.value) or -1
        if id then
            SetPedHeadOverlay(ped, id, overlay < 0 and 255 or overlay, tonumber(value.opacity) or 1.0)
            local colorType = tonumber(value.colorType) or 0
            if colorType <= 0 then colorType = overlayColorTypes[id] or 0 end
            if overlay >= 0 and colorType > 0 then
                SetPedHeadOverlayColor(ped, id, colorType, tonumber(value.color) or 0, tonumber(value.secondColor) or 0)
            end
        end
    end
end

local function limits()
    local ped, data = PlayerPedId(), { components = {}, props = {}, overlays = {} }
    for id, label in pairs(componentLabels) do
        local drawable = GetPedDrawableVariation(ped, id)
        data.components[#data.components + 1] = {
            id = id, label = label, drawableMax = math.max(0, GetNumberOfPedDrawableVariations(ped, id) - 1),
            textureMax = math.max(0, GetNumberOfPedTextureVariations(ped, id, drawable) - 1)
        }
    end
    table.sort(data.components, function(a, b) return a.id < b.id end)
    for id, label in pairs(propLabels) do
        local drawable = GetPedPropIndex(ped, id)
        data.props[#data.props + 1] = {
            id = id, label = label, drawableMax = math.max(-1, GetNumberOfPedPropDrawableVariations(ped, id) - 1),
            textureMax = drawable < 0 and 0 or math.max(0, GetNumberOfPedPropTextureVariations(ped, id, drawable) - 1)
        }
    end
    table.sort(data.props, function(a, b) return a.id < b.id end)
    for id, label in pairs(overlayLabels) do
        local colorType = overlayColorTypes[id] or 0
        local colorMax = -1
        if colorType == 1 then colorMax = math.max(0, GetNumHairColors() - 1)
        elseif colorType == 2 then colorMax = math.max(0, GetNumMakeupColors() - 1) end
        data.overlays[#data.overlays + 1] = {
            id = id, label = label, max = math.max(0, GetPedHeadOverlayNum(id) - 1),
            colorType = colorType, colorMax = colorMax
        }
    end
    table.sort(data.overlays, function(a, b) return a.id < b.id end)
    data.hairMax = math.max(0, GetNumberOfPedDrawableVariations(ped, 2) - 1)
    data.hairColors = math.max(1, GetNumHairColors()) - 1
    return data
end

local function refreshEditor()
    SendNUIMessage({ action = 'hydrate', appearance = captureAppearance(), limits = limits() })
end

local function destroyCamera()
    if editorCamera and DoesCamExist(editorCamera) then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(editorCamera, false)
    end
    editorCamera = nil
end

local function setCameraView(name, instant)
    local view = cameraViews[name]
    if not editorOpen or not view then return end
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, view.distance, view.cameraZ)
    local nextCamera = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, view.fov, false, 0)
    PointCamAtEntity(nextCamera, ped, 0.0, 0.0, view.targetZ, true)
    SetCamActive(nextCamera, true)

    local previousCamera = editorCamera
    editorCamera = nextCamera
    if previousCamera and DoesCamExist(previousCamera) and not instant then
        SetCamActiveWithInterp(nextCamera, previousCamera, 450, 1, 1)
        CreateThread(function()
            Wait(500)
            if DoesCamExist(previousCamera) then DestroyCam(previousCamera, false) end
        end)
    else
        if previousCamera and DoesCamExist(previousCamera) then DestroyCam(previousCamera, false) end
        RenderScriptCams(true, false, 0, true, true)
    end
end

local function closeEditor(restore)
    if not editorOpen then return end
    if restore and originalAppearance then applyAppearance(originalAppearance) end
    editorOpen = false
    requiredSetup = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    destroyCamera()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)
    DisplayRadar(true)
end

local function openEditor(firstSetup)
    if editorOpen or not playerLoaded then return end
    if not firstSetup and ((playerData.metadata or {}).isdead or IsPedCuffed(PlayerPedId())) then
        return lib.notify({ type = 'error', description = 'You cannot change appearance right now.' })
    end
    editorOpen, requiredSetup = true, firstSetup == true
    originalAppearance = captureAppearance()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TaskStandStill(ped, -1)
    DisplayRadar(false)
    setCameraView('whole', true)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', required = requiredSetup })
    refreshEditor()
end

AddEventHandler('nhr_core:client:onPlayerLoaded', function(data)
    playerData = data or {}
    playerLoaded = true
end)

AddEventHandler('nhr_core:client:playerDataChanged', function(data)
    playerData = data or playerData
end)

AddEventHandler('nhr_core:client:onPlayerUnloaded', function()
    playerLoaded = false
    playerData = {}
    if editorOpen then closeEditor(true) end
end)

RegisterNUICallback('model', function(data, cb)
    if editorOpen and (data.model == 'male' or data.model == 'female') then
        loadModel(data.model)
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        TaskStandStill(ped, -1)
        if editorCamera then PointCamAtEntity(editorCamera, ped, 0.0, 0.0, 0.65, true) end
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('component', function(data, cb)
    local ped, id = PlayerPedId(), tonumber(data.id)
    if editorOpen and id and componentLabels[id] then
        local maxDrawable = math.max(0, GetNumberOfPedDrawableVariations(ped, id) - 1)
        local drawable = math.max(0, math.min(maxDrawable, math.floor(tonumber(data.drawable) or 0)))
        local maxTexture = math.max(0, GetNumberOfPedTextureVariations(ped, id, drawable) - 1)
        SetPedComponentVariation(ped, id, drawable, math.max(0, math.min(maxTexture, math.floor(tonumber(data.texture) or 0))), 2)
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('prop', function(data, cb)
    local ped, id = PlayerPedId(), tonumber(data.id)
    if editorOpen and id and propLabels[id] then
        local drawable = math.floor(tonumber(data.drawable) or -1)
        local maxDrawable = math.max(-1, GetNumberOfPedPropDrawableVariations(ped, id) - 1)
        drawable = math.max(-1, math.min(maxDrawable, drawable))
        if drawable < 0 then ClearPedProp(ped, id)
        else
            local maxTexture = math.max(0, GetNumberOfPedPropTextureVariations(ped, id, drawable) - 1)
            SetPedPropIndex(ped, id, drawable, math.max(0, math.min(maxTexture, math.floor(tonumber(data.texture) or 0))), true)
        end
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('hair', function(data, cb)
    local ped = PlayerPedId()
    if editorOpen then
        local style = math.max(0, math.min(GetNumberOfPedDrawableVariations(ped, 2) - 1, math.floor(tonumber(data.style) or 0)))
        SetPedComponentVariation(ped, 2, style, 0, 2)
        SetPedHairColor(ped, math.floor(tonumber(data.color) or 0), math.floor(tonumber(data.highlight) or 0))
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('face', function(data, cb)
    local index = math.floor(tonumber(data.index) or -1)
    if editorOpen and index >= 0 and index <= 19 then SetPedFaceFeature(PlayerPedId(), index, math.max(-1.0, math.min(1.0, tonumber(data.value) or 0.0))) end
    cb(true)
end)

RegisterNUICallback('blend', function(data, cb)
    if editorOpen then
        local mother, father = math.floor(tonumber(data.mother) or 0), math.floor(tonumber(data.father) or 0)
        currentBlend = {
            mother = mother, father = father,
            shapeMix = math.max(0.0, math.min(1.0, tonumber(data.shapeMix) or 0.5)),
            skinMix = math.max(0.0, math.min(1.0, tonumber(data.skinMix) or 0.5))
        }
        SetPedHeadBlendData(PlayerPedId(), mother, father, 0, mother, father, 0,
            currentBlend.shapeMix, currentBlend.skinMix, 0.0, false)
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('overlay', function(data, cb)
    local id = math.floor(tonumber(data.id) or -1)
    if editorOpen and overlayLabels[id] then
        local value = math.floor(tonumber(data.value) or -1)
        local opacity = math.max(0.0, math.min(1.0, tonumber(data.opacity) or 1.0))
        if data.activate == true and value >= 0 and opacity <= 0.0 then opacity = 1.0 end
        SetPedHeadOverlay(PlayerPedId(), id, value < 0 and 255 or value, opacity)
        local colorType = overlayColorTypes[id] or 0
        if value >= 0 and colorType > 0 then
            SetPedHeadOverlayColor(PlayerPedId(), id, colorType, math.floor(tonumber(data.color) or 0), 0)
        end
        refreshEditor()
    end
    cb(true)
end)

RegisterNUICallback('eye', function(data, cb)
    if editorOpen then SetPedEyeColor(PlayerPedId(), math.max(0, math.min(31, math.floor(tonumber(data.color) or 0)))) refreshEditor() end
    cb(true)
end)

RegisterNUICallback('rotate', function(data, cb)
    if editorOpen then SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) + (tonumber(data.amount) or 0.0)) end
    cb(true)
end)

RegisterNUICallback('camera', function(data, cb)
    if editorOpen and type(data.view) == 'string' and cameraViews[data.view] then
        setCameraView(data.view, false)
    end
    cb(true)
end)

RegisterNUICallback('save', function(_, cb)
    if not editorOpen then return cb(false) end
    local ok, reason = lib.callback.await('nhr_appearance:save', false, captureAppearance())
    if ok then closeEditor(false) lib.notify({ description = 'Appearance saved.' })
    else lib.notify({ type = 'error', description = reason or 'Could not save appearance.' }) end
    cb(ok == true)
end)

RegisterNUICallback('cancel', function(_, cb)
    if editorOpen and not requiredSetup then closeEditor(true) end
    cb(not requiredSetup)
end)

AddEventHandler('nhr_spawn:client:complete', function()
    CreateThread(function()
        Wait(500)
        local appearance = lib.callback.await('nhr_appearance:get', false)
        if appearance and appearance.version == 2 then applyAppearance(appearance)
        else
            local gender = (playerData.charinfo or {}).gender
            loadModel(appearance and appearance.model or (gender == 'female' and 'female' or 'male'))
            if appearance then
                local ped = PlayerPedId()
                SetPedComponentVariation(ped, 2, tonumber(appearance.hair) or 0, 0, 2)
                SetPedComponentVariation(ped, 11, tonumber(appearance.top) or 0, 0, 2)
                SetPedComponentVariation(ped, 8, tonumber(appearance.undershirt) or 0, 0, 2)
                SetPedComponentVariation(ped, 4, tonumber(appearance.legs) or 0, 0, 2)
                SetPedComponentVariation(ped, 6, tonumber(appearance.shoes) or 0, 0, 2)
            end
            Wait(250)
            openEditor(true)
        end
    end)
end)

RegisterCommand(NHRAppearance.Command, function() openEditor(false) end, false)

local function createShopBlip(coords, settings)
    if not settings or settings.Enabled ~= true then return end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, settings.Sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, settings.Scale)
    SetBlipColour(blip, settings.Color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(settings.Label)
    EndTextCommandSetBlipName(blip)
    mapBlips[#mapBlips + 1] = blip
end

CreateThread(function()
    for index, coords in ipairs(NHRAppearance.Stores) do
        createShopBlip(coords, NHRAppearance.Blips.Clothing)
        exports.ox_target:addSphereZone({
            coords = coords, radius = 2.5,
            options = {{
                name = ('nhr_appearance_store_%d'):format(index), label = ('Clothing store · $%d'):format(NHRAppearance.ShopPrice),
                icon = 'fa-solid fa-shirt', onSelect = function() openEditor(false) end
            }}
        })
    end
    for _, coords in ipairs(NHRAppearance.TattooStores) do
        createShopBlip(coords, NHRAppearance.Blips.Tattoo)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if editorOpen then closeEditor(true) end
    for index = 1, #mapBlips do
        if DoesBlipExist(mapBlips[index]) then RemoveBlip(mapBlips[index]) end
    end
end)
