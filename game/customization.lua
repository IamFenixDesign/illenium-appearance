local reverseCamera
local freeCamEnabled = false
-- Tras orbitar/zoom en modo libre, conservar esa pose al editar valores
-- (aunque se salga de "mover cámara"). Se limpia con botones de zona o reset.
local freeCamUserAdjusted = false
local playerCoords
local playerHeading

-- yaw 0 = delante del ped (mira la cara). Usar offsets locales vía GetOffsetFromEntityInWorldCoords.
local freeCam = {
    yaw = 0.0,
    pitch = 0.0,
    radius = 2.2,
    height = 0.2,
    lookAtZ = -0.05,
}

local freeCamPresets = {
    -- Alineado a constants.CAMERAS de illenium (Y+ = frente del ped)
    default = { yaw = 0.0, pitch = 0.0, radius = 2.2, height = 0.2, lookAtZ = -0.05 },
    head = { yaw = 0.0, pitch = 5.0, radius = 0.9, height = 0.65, lookAtZ = 0.6 },
    body = { yaw = 0.0, pitch = 0.0, radius = 1.2, height = 0.2, lookAtZ = 0.2 },
    -- Pantalones: un poco más atrás y mirando a muslo/pantorrilla (no a los tobillos)
    bottom = { yaw = 0.0, pitch = -4.0, radius = 1.32, height = -0.38, lookAtZ = -0.52 },
    -- Zapatos: órbita relativa a los pies (height/lookAtZ se usan sobre el ancla de huesos)
    feet = { yaw = 0.0, pitch = -28.0, radius = 1.0, height = 0.68, lookAtZ = 0.05 },
}

-- component_id → preset de cámara
local COMPONENT_CAMERA = {
    [0] = 'head',   -- cara (no freemode)
    [1] = 'head',   -- máscara
    [3] = 'body',   -- torso / brazos
    [4] = 'bottom', -- pantalones
    [5] = 'body',   -- bolsos
    [6] = 'feet',   -- zapatos
    [7] = 'body',   -- bufanda / cadenas
    [8] = 'body',   -- camiseta
    [9] = 'body',   -- chaleco
    [10] = 'body',  -- calcomanías
    [11] = 'body',  -- chaqueta
}

-- prop_id → preset
local PROP_CAMERA = {
    [0] = 'head', -- sombrero
    [1] = 'head', -- gafas
    [2] = 'head', -- oreja
    [6] = 'body', -- reloj
    [7] = 'body', -- pulsera
}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function applyFreeCamPreset(key)
    local preset = freeCamPresets[key] or freeCamPresets.default
    freeCam.yaw = preset.yaw
    freeCam.pitch = preset.pitch
    freeCam.radius = preset.radius
    freeCam.height = preset.height
    freeCam.lookAtZ = preset.lookAtZ
end

local function getRgbColors()
    local colors = {
        hair = {},
        makeUp = {}
    }

    for i = 0, GetNumHairColors() - 1 do
        colors.hair[i+1] = {GetPedHairRgbColor(i)}
    end

    for i = 0, GetNumMakeupColors() - 1 do
        colors.makeUp[i+1] = {GetPedMakeupRgbColor(i)}
    end

    return colors
end

local playerAppearance

local function getAppearance()
    if not playerAppearance then
        playerAppearance = client.getPedAppearance(cache.ped)
    end

    return playerAppearance
end
client.getAppearance = getAppearance

local function addToBlacklist(item, drawable, drawableId, blacklistSettings)
    if drawable == drawableId and item.textures then
        for i = 1, #item.textures do
            blacklistSettings.textures[#blacklistSettings.textures + 1] = item.textures[i]
        end
    end
    if not item.textures or #item.textures == 0 then
        blacklistSettings.drawables[#blacklistSettings.drawables + 1] = drawable
    end
end

local function listContains(items, item)
    for i = 1, #items do
        if items[i] == item then
            return true
        end
    end
    return false
end

local function listContainsAny(items, containedItems)
    for i = 1, #items do
        if listContains(containedItems, items[i]) then
            return true
        end
    end
    return false
end

local cachedPlayerAces
local function getPlayerAces()
    if cachedPlayerAces == nil then
        cachedPlayerAces = lib.callback.await("illenium-appearance:server:GetPlayerAces", false) or {}
    end
    return cachedPlayerAces
end

local function allowedForPlayer(item, allowedAces)
    return (item.jobs and listContains(item.jobs, client.job.name)) or (item.gangs and listContains(item.gangs, client.gang.name)) or (item.aces and listContainsAny(item.aces, allowedAces) or (item.citizenids and listContains(item.citizenids, client.citizenid)))
end

local function filterPedModelsForPlayer(pedConfigs)
    local playerPeds = {}
    local allowedAces = getPlayerAces()

    for i = 1, #pedConfigs do
        local config = pedConfigs[i]
        if (not config.jobs and not config.gangs and not config.aces and not config.citizenids) or allowedForPlayer(config, allowedAces) then
            for j = 1, #config.peds do
                playerPeds[#playerPeds + 1] = config.peds[j]
            end
        end
    end
    return playerPeds
end

local function filterTattoosByGender(tattoos)
    local filtered = {}
    local gender = client.getPedDecorationType()
    for k, v in pairs(tattoos) do
        filtered[k] = {}
        for i = 1, #v do
            local tattoo = v[i]
            if tattoo["hash" .. gender:gsub("^%l", string.upper)] ~= "" then
                filtered[k][#filtered[k] + 1] = tattoo
            end
        end
    end
    return filtered
end

local function filterBlacklistSettings(items, drawableId)
    local blacklistSettings = {
        drawables = {},
        textures = {}
    }

    -- Blacklist vacío: no pedir ACEs al servidor
    if not items or #items == 0 then
        return blacklistSettings
    end

    local allowedAces = getPlayerAces()

    for i = 1, #items do
        local item = items[i]
        if not allowedForPlayer(item, allowedAces) and item.drawables then
            for j = 0, #item.drawables do
                addToBlacklist(item, item.drawables[j], drawableId, blacklistSettings)
            end
        end
    end

    return blacklistSettings
end

local function componentBlacklistMap(gender, componentId)
    local genderSettings = Config.Blacklist[gender].components
    if componentId == 1 then
        return genderSettings.masks
    elseif componentId == 3 then
        return genderSettings.upperBody
    elseif componentId == 4 then
        return genderSettings.lowerBody
    elseif componentId == 5 then
        return genderSettings.bags
    elseif componentId == 6 then
        return genderSettings.shoes
    elseif componentId == 7 then
        return genderSettings.scarfAndChains
    elseif componentId == 8 then
        return genderSettings.shirts
    elseif componentId == 9 then
        return genderSettings.bodyArmor
    elseif componentId == 10 then
        return genderSettings.decals
    elseif componentId == 11 then
        return genderSettings.jackets
    end

    return {}
end

local function propBlacklistMap(gender, propId)
    local genderSettings = Config.Blacklist[gender].props

    if propId == 0 then
        return genderSettings.hats
    elseif propId == 1 then
        return genderSettings.glasses
    elseif propId == 2 then
        return genderSettings.ear
    elseif propId == 6 then
        return genderSettings.watches
    elseif propId == 7 then
        return genderSettings.bracelets
    end

    return {}
end

local function getComponentSettings(ped, componentId)
    local drawableId = GetPedDrawableVariation(ped, componentId)
    local gender = client.getPedDecorationType()

    local blacklistSettings = {
        drawables = {},
        textures = {}
    }

    if client.isPedFreemodeModel(ped) then
        blacklistSettings = filterBlacklistSettings(componentBlacklistMap(gender, componentId), drawableId)
    end

    return {
        component_id = componentId,
        drawable = {
            min = 0,
            max = GetNumberOfPedDrawableVariations(ped, componentId) - 1
        },
        texture = {
            min = 0,
            max = GetNumberOfPedTextureVariations(ped, componentId, drawableId) - 1
        },
        blacklist = blacklistSettings
    }
end
client.getComponentSettings = getComponentSettings

local function getPropSettings(ped, propId)
    local drawableId = GetPedPropIndex(ped, propId)
    local gender = client.getPedDecorationType()

    local blacklistSettings = {
        drawables = {},
        textures = {}
    }

    if client.isPedFreemodeModel(ped) then
        blacklistSettings = filterBlacklistSettings(propBlacklistMap(gender, propId), drawableId)
    end

    local settings = {
        prop_id = propId,
        drawable = {
            min = -1,
            max = GetNumberOfPedPropDrawableVariations(ped, propId) - 1
        },
        texture = {
            min = -1,
            max = GetNumberOfPedPropTextureVariations(ped, propId, drawableId) - 1
        },
        blacklist = blacklistSettings
    }
    return settings
end
client.getPropSettings = getPropSettings

local function getHairSettings(ped)
    local colors = getRgbColors()
    local gender = client.getPedDecorationType()
    local blacklistSettings = {
        drawables = {},
        textures = {}
    }

    if client.isPedFreemodeModel(ped) then
        blacklistSettings = filterBlacklistSettings(Config.Blacklist[gender].hair, GetPedDrawableVariation(ped, 2))
    end

    local settings = {
        style = {
            min = 0,
            max = GetNumberOfPedDrawableVariations(ped, 2) - 1
        },
        color = {
            items = colors.hair
        },
        highlight = {
            items = colors.hair
        },
        texture = {
            min = 0,
            max = GetNumberOfPedTextureVariations(ped, 2, GetPedDrawableVariation(ped, 2)) - 1
        },
        blacklist = blacklistSettings
    }

    return settings
end
client.getHairSettings = getHairSettings

local function getAppearanceSettings()
    local conf = config or {}

    local ped = {
        model = {
            items = conf.ped and filterPedModelsForPlayer(Config.Peds.pedConfig) or {}
        }
    }

    -- Tattoo catalog is loaded by NUI from web/dist/assets/tattoos-*.json
    -- (NUI callbacks can't reliably return the ~140KB payload).
    local tattoos = {
        items = {},
        opacity = {
            min = 0.1,
            max = 1,
            factor = 0.1,
        }
    }

    local components = {}
    for i = 1, #constants.PED_COMPONENTS_IDS do
        components[i] = getComponentSettings(cache.ped, constants.PED_COMPONENTS_IDS[i])
    end

    local props = {}
    for i = 1, #constants.PED_PROPS_IDS do
        props[i] = getPropSettings(cache.ped, constants.PED_PROPS_IDS[i])
    end

    local headBlend = {
        shapeFirst = {
            min = 0,
            max = 45
        },
        shapeSecond = {
            min = 0,
            max = 45
        },
        shapeThird = {
            min = 0,
            max = 45
        },
        skinFirst = {
            min = 0,
            max = 45
        },
        skinSecond = {
            min = 0,
            max = 45
        },
        skinThird = {
            min = 0,
            max = 45
        },
        shapeMix = {
            min = 0,
            max = 1,
            factor = 0.1,
        },
        skinMix = {
            min = 0,
            max = 1,
            factor = 0.1,
        },
        thirdMix = {
            min = 0,
            max = 1,
            factor = 0.1,
        }
    }

    local size = #constants.FACE_FEATURES
    local faceFeatures = table.create(0, size)
    for i = 1, size do
        local feature = constants.FACE_FEATURES[i]
        faceFeatures[feature] = { min = -1, max = 1, factor = 0.1}
    end

    local colors = getRgbColors()

    local colorMap = {
        beard = colors.hair,
        eyebrows = colors.hair,
        chestHair = colors.hair,
        makeUp = colors.makeUp,
        blush = colors.makeUp,
        lipstick = colors.makeUp,
    }

    size = #constants.HEAD_OVERLAYS
    local headOverlays = table.create(0, size)

    for i = 1, size do
        local overlay = constants.HEAD_OVERLAYS[i]
        local settings = {
            style = {
                min = 0,
                max = GetPedHeadOverlayNum(i - 1) - 1
            },
            opacity = {
                min = 0,
                max = 1,
                factor = 0.1,
            }
        }

        if colorMap[overlay] then
            settings.color = {
                items = colorMap[overlay]
            }
        end

        headOverlays[overlay] = settings
    end

    local eyeColor = {
        min = 0,
        max = 30
    }

    return {
        ped = ped,
        components = components,
        props = props,
        headBlend = headBlend,
        faceFeatures = faceFeatures,
        headOverlays = headOverlays,
        hair = getHairSettings(cache.ped),
        eyeColor = eyeColor,
        tattoos = tattoos
    }
end
client.getAppearanceSettings = getAppearanceSettings

local config
function client.getConfig() return config end

local isCameraInterpolating
local currentCamera
local cameraHandle

local function updateFreeCamera()
    if not cameraHandle or not DoesCamExist(cameraHandle) then return end

    local ped = cache.ped
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    -- Ángulo relativo al ped: 0° = frente (cara), 90° = derecha, 180° = espalda
    local yawRad = math.rad(freeCam.yaw)
    local pitchRad = math.rad(freeCam.pitch)
    local cosPitch = math.cos(pitchRad)

    local localX = freeCam.radius * cosPitch * math.sin(yawRad)
    local localY = freeCam.radius * cosPitch * math.cos(yawRad)
    local localZ = freeCam.height + (freeCam.radius * math.sin(pitchRad))

    local camCoords
    local lookAt
    local pedCoords = GetEntityCoords(ped, true)

    -- Zapatos: anclar a los huesos de los pies para enfocar el calzado de verdad
    if currentCamera == "feet" then
        local footL = GetPedBoneCoords(ped, 14201, 0.0, 0.0, 0.0) -- SKEL_L_Foot
        local footR = GetPedBoneCoords(ped, 52301, 0.0, 0.0, 0.0) -- SKEL_R_Foot
        local feetPos = vector3(
            (footL.x + footR.x) * 0.5,
            (footL.y + footR.y) * 0.5,
            (footL.z + footR.z) * 0.5
        )

        lookAt = vector3(feetPos.x, feetPos.y, feetPos.z + freeCam.lookAtZ)

        -- Offset local del ped, centrado en los pies (no en el origen del entity)
        local offsetWorld = GetOffsetFromEntityInWorldCoords(ped, localX, localY, localZ) - pedCoords
        camCoords = vector3(
            feetPos.x + offsetWorld.x,
            feetPos.y + offsetWorld.y,
            feetPos.z + offsetWorld.z
        )
    else
        camCoords = GetOffsetFromEntityInWorldCoords(ped, localX, localY, localZ)
        lookAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, freeCam.lookAtZ)
    end

    -- No dejar la cámara por debajo del suelo del ped
    local minCamZ = pedCoords.z + 0.08
    if camCoords.z < minCamZ then
        camCoords = vector3(camCoords.x, camCoords.y, minCamZ)
    end

    SetCamCoord(cameraHandle, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cameraHandle, lookAt.x, lookAt.y, lookAt.z)
end

local function facePedFront()
    local ped = cache.ped
    if not ped or ped == 0 then return end

    ClearPedTasksImmediately(ped)
    if playerCoords then
        SetEntityCoordsNoOffset(ped, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    end
    if playerHeading then
        SetEntityHeading(ped, playerHeading)
    end
    reverseCamera = false
    FreezeEntityPosition(ped, true)
    TaskStandStill(ped, -1)
end

local function setCamera(key)
    if key and key ~= "current" then
        currentCamera = key
        applyFreeCamPreset(key)
        -- Botón de zona / preset explícito: volver al auto-focus al editar
        freeCamUserAdjusted = false
    end

    if not cameraHandle or not DoesCamExist(cameraHandle) then
        local pedCoords = GetEntityCoords(cache.ped, true)
        cameraHandle = CreateCameraWithParams(
            "DEFAULT_SCRIPTED_CAMERA",
            pedCoords.x, pedCoords.y, pedCoords.z + 0.5,
            0.0, 0.0, 0.0, 49.0, false, 0
        )
        SetCamActive(cameraHandle, true)
    end

    updateFreeCamera()
end
client.setCamera = setCamera

--- Enfoca una zona al editar. No pisa el ángulo si está en "mover cámara"
--- o si el jugador ya colocó la cámara a mano en modo libre.
function client.focusCamera(preset)
    if freeCamEnabled or freeCamUserAdjusted then return end
    if not preset or preset == '' then return end
    setCamera(preset)
end

function client.focusCameraForComponent(componentId)
    client.focusCamera(COMPONENT_CAMERA[tonumber(componentId)] or 'body')
end

function client.focusCameraForProp(propId)
    client.focusCamera(PROP_CAMERA[tonumber(propId)] or 'head')
end

function client.setFreeCamEnabled(enabled)
    -- Solo habilita/deshabilita órbita; no toca la posición actual
    freeCamEnabled = enabled and true or false
end

function client.orbitCamera(data)
    if not cameraHandle or not freeCamEnabled then return end

    local dx = tonumber(data and data.dx) or 0.0
    local dy = tonumber(data and data.dy) or 0.0
    local alt = data and data.alt

    if alt then
        freeCam.height = clamp(freeCam.height - (dy * 0.004), -0.35, 1.4)
        freeCam.lookAtZ = clamp(freeCam.lookAtZ - (dy * 0.0025), -0.35, 1.1)
    else
        freeCam.yaw = freeCam.yaw - (dx * 0.28)
        freeCam.pitch = clamp(freeCam.pitch + (dy * 0.18), -35.0, 55.0)
    end

    freeCamUserAdjusted = true
    updateFreeCamera()
end

function client.zoomCamera(delta)
    if not cameraHandle or not freeCamEnabled then return end

    local zoomDelta = (tonumber(delta) or 0.0) * 0.0022
    freeCam.radius = clamp(freeCam.radius + zoomDelta, 0.55, 4.0)
    freeCamUserAdjusted = true
    updateFreeCamera()
end

function client.resetCamera()
    freeCamUserAdjusted = false
    applyFreeCamPreset("default")
    currentCamera = "default"
    freeCam.yaw = 0.0
    freeCam.pitch = 0.0
    facePedFront()
    updateFreeCamera()
end

function client.rotateCamera(direction)
    if not cameraHandle or not freeCamEnabled then return end

    local sideFactor = direction == "left" and 1.0 or -1.0
    freeCam.yaw = freeCam.yaw + (28.0 * sideFactor)
    freeCamUserAdjusted = true
    updateFreeCamera()
end

local function pedTurn(ped, angle)
    reverseCamera = not reverseCamera
    local sequenceTaskId = OpenSequenceTask()
    if sequenceTaskId then
        TaskGoStraightToCoord(0, playerCoords.x, playerCoords.y, playerCoords.z, 8.0, -1, GetEntityHeading(ped) - angle, 0.1)
        TaskStandStill(0, -1)
        CloseSequenceTask(sequenceTaskId)
        ClearPedTasks(ped)
        TaskPerformSequence(ped, sequenceTaskId)
        ClearSequenceTask(sequenceTaskId)
    end

    -- Keep the freecam locked while the ped rotates into place.
    CreateThread(function()
        local timeout = GetGameTimer() + 1800
        while GetGameTimer() < timeout do
            updateFreeCamera()
            Wait(0)
        end
        updateFreeCamera()
    end)
end
client.pedTurn = pedTurn

local function wearClothes(data, typeClothes)
    local dataClothes = constants.DATA_CLOTHES[typeClothes]
    local animationsOn = dataClothes.animations.on
    local components = dataClothes.components[client.getPedDecorationType()]
    local appliedComponents = data.components
    local props = dataClothes.props[client.getPedDecorationType()]
    local appliedProps = data.props

    RequestAnimDict(animationsOn.dict)
    while not HasAnimDictLoaded(animationsOn.dict) do
        Wait(0)
    end

    for i = 1, #components do
        local componentId = components[i][1]
        for j = 1, #appliedComponents do
            local applied = appliedComponents[j]
            if applied.component_id == componentId then
                SetPedComponentVariation(cache.ped, componentId, applied.drawable, applied.texture, 2)
            end
        end
    end

    for i = 1, #props do
        local propId = props[i][1]
        for j = 1, #appliedProps do
            local applied = appliedProps[j]
            if applied.prop_id == propId then
                SetPedPropIndex(cache.ped, propId, applied.drawable, applied.texture, true)
            end
        end
    end

    TaskPlayAnim(cache.ped, animationsOn.dict, animationsOn.anim, 3.0, 3.0, animationsOn.duration, animationsOn.move, 0, false, false, false)
end
client.wearClothes = wearClothes

local function removeClothes(typeClothes)
    local dataClothes = constants.DATA_CLOTHES[typeClothes]
    local animationsOff = dataClothes.animations.off
    local components = dataClothes.components[client.getPedDecorationType()]
    local props = dataClothes.props[client.getPedDecorationType()]

    RequestAnimDict(animationsOff.dict)
    while not HasAnimDictLoaded(animationsOff.dict) do
        Wait(0)
    end

    for i = 1, #components do
        local component = components[i]
        SetPedComponentVariation(cache.ped, component[1], component[2], 0, 2)
    end

    for i = 1, #props do
        ClearPedProp(cache.ped, props[i][1])
    end

    TaskPlayAnim(cache.ped, animationsOff.dict, animationsOff.anim, 3.0, 3.0, animationsOff.duration, animationsOff.move, 0, false, false, false)
end
client.removeClothes = removeClothes

function client.getHeading() return playerHeading end

-- Shops that don't edit clothing (tattoo/barber/surgeon) must not persist
-- p-clothing / dpclothing temporary unequips as the saved outfit.
function client.preserveUneditedAppearance(appearance)
    if not appearance or not config then return appearance end
    if config.components and config.props then return appearance end

    local saved = lib.callback.await("illenium-appearance:server:getAppearance", false)
    if not saved then return appearance end

    if not config.components then
        appearance.components = saved.components
    end
    if not config.props then
        appearance.props = saved.props
    end
    if not config.headOverlays then
        appearance.hair = saved.hair
        appearance.headOverlays = saved.headOverlays
    end
    if not config.headBlend then
        appearance.headBlend = saved.headBlend
        appearance.faceFeatures = saved.faceFeatures
        appearance.eyeColor = saved.eyeColor
    end
    if not config.tattoos then
        appearance.tattoos = saved.tattoos
    end
    if not config.ped then
        appearance.model = saved.model
    end

    return appearance
end

local callback
function client.startPlayerCustomization(cb, conf)
    callback = cb
    config = conf
    cachedPlayerAces = nil
    reverseCamera = false
    freeCamEnabled = false
    freeCamUserAdjusted = false
    isCameraInterpolating = false

    -- Clothing/barber/surgeon: put toggled pieces back on before we snapshot.
    -- Tattoo shop skips this so the player can stay undressed to see skin.
    if client.shouldEquipClothingToggles(conf) then
        client.equipClothingToggles()
    end

    playerCoords = GetEntityCoords(cache.ped, true)
    playerHeading = GetEntityHeading(cache.ped)
    BackupPlayerStats()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SetEntityInvincible(cache.ped, Config.InvincibleDuringCustomization)
    FreezeEntityPosition(cache.ped, true)
    TaskStandStill(cache.ped, -1)
    if Config.HideRadar then DisplayRadar(false) end

    -- Abrir NUI al instante; cámara y appearance en paralelo
    SendNuiMessage(json.encode({
        type = "appearance_display",
        payload = {
            asynchronous = Config.AsynchronousLoading,
            menuPosition = Config.MenuPosition or "middle"
        }
    }))

    CreateThread(function()
        playerAppearance = client.getPedAppearance(cache.ped)
        facePedFront()
        applyFreeCamPreset("default")
        freeCam.yaw = 0.0
        freeCam.pitch = 0.0
        setCamera("default")
        RenderScriptCams(true, false, 0, true, true)
        updateFreeCamera()
    end)
end

function client.exitPlayerCustomization(appearance)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cameraHandle, false)
    SetNuiFocus(false, false)

    if Config.HideRadar then DisplayRadar(true) end

    ClearPedTasksImmediately(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)

    SendNuiMessage(json.encode({
        type = "appearance_hide",
        payload = {}
    }))

    if not appearance then
        client.setPlayerAppearance(getAppearance())
    else
        client.setPedTattoos(cache.ped, appearance.tattoos)
    end

    RestorePlayerStats()

    if callback then
        callback(appearance)
    end

    callback = nil
    config = nil
    cachedPlayerAces = nil
    playerAppearance = nil
    playerCoords = nil
    cameraHandle = nil
    currentCamera = nil
    reverseCamera = nil
    freeCamEnabled = false
    freeCamUserAdjusted = false
    isCameraInterpolating = nil

end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

exports("startPlayerCustomization", client.startPlayerCustomization)
