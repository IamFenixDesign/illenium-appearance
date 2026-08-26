lib.callback.register("illenium-appearance:server:GetPlayerAces", function()
    local src = source
    local allowedAces = {}
    for i = 1, #Config.Aces do
        local ace = Config.Aces[i]
        if IsPlayerAceAllowed(src, ace) then
            allowedAces[#allowedAces+1] = ace
        end
    end
    return allowedAces
end)

local SETTINGS_ACE = "fenix.appearance"

local function hasSettingsAce(src)
    if not Config.SettingsAce then
        return true
    end
    return IsPlayerAceAllowed(src, SETTINGS_ACE) and true or false
end

lib.callback.register("illenium-appearance:server:HasSettingsAce", function()
    return hasSettingsAce(source)
end)

local COLOR_KEYS = {
    "accent", "accentSoft", "accentText", "surface", "field", "fieldHover",
    "border", "text", "muted", "ok", "okBg", "okBorder", "danger", "dangerBg", "dangerBorder"
}

local DEFAULT_COLORS = {
    accent = "#7c6cf0",
    accentSoft = "#2a2840",
    accentText = "#ddd6fe",
    surface = "#1c1c24",
    field = "#18181f",
    fieldHover = "#22222c",
    border = "#32323e",
    text = "#f2f2f6",
    muted = "#9494a8",
    ok = "#22c55e",
    okBg = "#15251a",
    okBorder = "#2a5a38",
    danger = "#ef4444",
    dangerBg = "#2a1818",
    dangerBorder = "#5c2828"
}

local COLORS_KVP = "fenix_appearance_colors"
local cachedColors

local function isHexColor(value)
    return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

local function sanitizeColors(input)
    local out = {}
    for i = 1, #COLOR_KEYS do
        local key = COLOR_KEYS[i]
        local value = input and input[key]
        out[key] = isHexColor(value) and value or DEFAULT_COLORS[key]
    end
    return out
end

local function getThemeColors()
    if cachedColors then
        return cachedColors
    end

    local raw = GetResourceKvpString(COLORS_KVP)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            cachedColors = sanitizeColors(decoded)
            return cachedColors
        end
    end

    cachedColors = sanitizeColors(nil)
    return cachedColors
end

local function saveThemeColors(colors)
    cachedColors = sanitizeColors(colors)
    SetResourceKvp(COLORS_KVP, json.encode(cachedColors))
    TriggerClientEvent("illenium-appearance:client:setThemeColors", -1, cachedColors)
    return cachedColors
end

lib.callback.register("illenium-appearance:server:GetThemeColors", function()
    return getThemeColors()
end)

lib.callback.register("illenium-appearance:server:SaveThemeColors", function(source, colors)
    if not hasSettingsAce(source) then
        return false
    end
    if type(colors) ~= "table" then
        return false
    end
    return saveThemeColors(colors)
end)
