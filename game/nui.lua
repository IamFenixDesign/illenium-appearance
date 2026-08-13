local client = client

RegisterNUICallback("appearance_get_locales", function(_, cb)
    local lang = GetConvar("illenium-appearance:locale", "en")
    local locale = Locales[lang] or Locales["en"]
    cb(locale and locale.UI or {})
end)

RegisterNUICallback("appearance_get_settings", function(_, cb)
    cb({ appearanceSettings = client.getAppearanceSettings() })
end)

RegisterNUICallback("appearance_get_data", function(_, cb)
    local appearanceData = client.getAppearance()
    if appearanceData.tattoos then
        client.setPedTattoos(cache.ped, appearanceData.tattoos)
    end
    cb({ config = client.getConfig(), appearanceData = appearanceData })
end)

RegisterNUICallback("appearance_set_camera", function(camera, cb)
    cb(1)
    client.setCamera(camera)
end)

RegisterNUICallback("appearance_camera_orbit", function(data, cb)
    cb(1)
    client.orbitCamera(data)
end)

RegisterNUICallback("appearance_camera_zoom", function(data, cb)
    cb(1)
    client.zoomCamera(data and data.delta or 0)
end)

RegisterNUICallback("appearance_camera_reset", function(_, cb)
    cb(1)
    client.resetCamera()
end)

RegisterNUICallback("appearance_camera_freemode", function(data, cb)
    cb(1)
    client.setFreeCamEnabled(data and data.enabled)
end)

RegisterNUICallback("appearance_turn_around", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, 180.0)
end)

RegisterNUICallback("appearance_rotate_camera", function(direction, cb)
    cb(1)
    client.rotateCamera(direction)
end)

RegisterNUICallback("appearance_change_model", function(model, cb)
    local playerPed = client.setPlayerModel(model)

    SetEntityHeading(cache.ped, client.getHeading())
    SetEntityInvincible(playerPed, true)
    FreezeEntityPosition(playerPed, true)
    TaskStandStill(playerPed, -1)
    client.resetCamera()

    cb({
        appearanceSettings = client.getAppearanceSettings(),
        appearanceData = client.getPedAppearance(playerPed)
    })
end)

RegisterNUICallback("appearance_change_component", function(component, cb)
    client.setPedComponent(cache.ped, component)
    client.focusCameraForComponent(component and component.component_id)
    cb(client.getComponentSettings(cache.ped, component.component_id))
end)

RegisterNUICallback("appearance_change_prop", function(prop, cb)
    client.setPedProp(cache.ped, prop)
    client.focusCameraForProp(prop and prop.prop_id)
    cb(client.getPropSettings(cache.ped, prop.prop_id))
end)

RegisterNUICallback("appearance_change_head_blend", function(headBlend, cb)
    cb(1)
    client.setPedHeadBlend(cache.ped, headBlend)
    client.focusCamera('head')
end)

RegisterNUICallback("appearance_change_face_feature", function(faceFeatures, cb)
    cb(1)
    client.setPedFaceFeatures(cache.ped, faceFeatures)
    client.focusCamera('head')
end)

RegisterNUICallback("appearance_change_head_overlay", function(headOverlays, cb)
    cb(1)
    client.setPedHeadOverlays(cache.ped, headOverlays)
    client.focusCamera('head')
end)

RegisterNUICallback("appearance_change_hair", function(hair, cb)
    client.setPedHair(cache.ped, hair)
    client.focusCamera('head')
    cb(client.getHairSettings(cache.ped))
end)

RegisterNUICallback("appearance_change_eye_color", function(eyeColor, cb)
    cb(1)
    client.setPedEyeColor(cache.ped, eyeColor)
    client.focusCamera('head')
end)

RegisterNUICallback("appearance_apply_tattoo", function(data, cb)
    local paid = not data.tattoo or not Config.ChargePerTattoo or lib.callback.await("illenium-appearance:server:payForTattoo", false, data.tattoo)
    if paid then
        client.addPedTattoo(cache.ped, data.updatedTattoos or data)
        local zone = data.tattoo and data.tattoo.zone
        if zone == 'ZONE_HEAD' or zone == 'ZONE_HAIR' then
            client.focusCamera('head')
        elseif zone == 'ZONE_LEFT_LEG' or zone == 'ZONE_RIGHT_LEG' then
            client.focusCamera('bottom')
        else
            client.focusCamera('body')
        end
    end
    cb(paid)
end)

RegisterNUICallback("appearance_preview_tattoo", function(previewTattoo, cb)
    cb(1)
    client.setPreviewTattoo(cache.ped, previewTattoo.data, previewTattoo.tattoo)
    local zone = previewTattoo.tattoo and previewTattoo.tattoo.zone
    if zone == 'ZONE_HEAD' or zone == 'ZONE_HAIR' then
        client.focusCamera('head')
    elseif zone == 'ZONE_LEFT_LEG' or zone == 'ZONE_RIGHT_LEG' then
        client.focusCamera('bottom')
    else
        client.focusCamera('body')
    end
end)

RegisterNUICallback("appearance_delete_tattoo", function(data, cb)
    cb(1)
    client.removePedTattoo(cache.ped, data)
end)

RegisterNUICallback("appearance_wear_clothes", function(dataWearClothes, cb)
    cb(1)
    client.wearClothes(dataWearClothes.data, dataWearClothes.key)
end)

RegisterNUICallback("appearance_remove_clothes", function(clothes, cb)
    cb(1)
    client.removeClothes(clothes)
end)

RegisterNUICallback("appearance_save", function(appearance, cb)
    -- Restore clothes removed in this menu (illenium UI). Do it before
    -- preserveUneditedAppearance so p-clothing toggles are not put back on.
    client.wearClothes(appearance, "head")
    client.wearClothes(appearance, "body")
    client.wearClothes(appearance, "bottom")
    appearance = client.preserveUneditedAppearance(appearance)
    client.exitPlayerCustomization(appearance)
    cb(1)
end)

RegisterNUICallback("appearance_exit", function(_, cb)
    cb(1)
    client.exitPlayerCustomization()
end)

RegisterNUICallback("rotate_left", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, 10.0)
end)

RegisterNUICallback("rotate_right", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, -10.0)
end)

RegisterNUICallback("get_theme_configuration", function(_, cb)
    cb(Config.Theme)
end)
