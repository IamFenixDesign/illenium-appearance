-- Compatibility with p-clothing / dpclothing clothing toggles.
-- Temporary unequips must not be persisted as the player's saved outfit.

local function clothingTogglesEnabled()
    return Config.ClothingToggleCompatibility ~= false
end

--- Tattoo shop: the player often undresses on purpose to see skin.
local function isTattooOnlyConfig(conf)
    return conf
        and conf.tattoos
        and not conf.components
        and not conf.props
        and not conf.headOverlays
        and not conf.headBlend
        and not conf.ped
end

function client.shouldEquipClothingToggles(conf)
    return clothingTogglesEnabled() and not isTattooOnlyConfig(conf)
end

function client.equipClothingToggles()
    if not clothingTogglesEnabled() then return end
    TriggerEvent("dpc:EquipLast")
    TriggerEvent("p-clothing:client:equipLast")
    TriggerEvent("dpc:Menu", false)
    TriggerEvent("p-clothing:client:setMenu", false)
end

function client.resetClothingToggles()
    if not clothingTogglesEnabled() then return end
    TriggerEvent("dpc:ResetClothing")
    TriggerEvent("p-clothing:client:resetClothing")
end
