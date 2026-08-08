local Blips = {}
local Points = {}
local client = client

local function ShowBlip(blipConfig, blip)
    if blip.job and blip.job ~= client.job.name then
        return false
    elseif blip.gang and blip.gang ~= client.gang.name then
        return false
    end

    if Config.RCoreTattoosCompatibility and blip.type == "tattoo" then
        return false
    end

    return (blipConfig.Show and blip.showBlip == nil) or blip.showBlip
end

local function CreateBlip(blipConfig, coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.Sprite)
    SetBlipColour(blip, blipConfig.Color)
    SetBlipScale(blip, blipConfig.Scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.Name)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function ClearBlips()
    for i = 1, #Blips do
        if DoesBlipExist(Blips[i]) then
            RemoveBlip(Blips[i])
        end
    end
    Blips = {}
end

local function ClearPoints()
    for i = 1, #Points do
        local point = Points[i]
        if point.blip and DoesBlipExist(point.blip) then
            RemoveBlip(point.blip)
        end
        point:remove()
    end
    Points = {}
end

local function SetupAllBlips()
    for k in pairs(Config.Stores) do
        local shop = Config.Stores[k]
        local blipConfig = Config.Blips[shop.type]
        if ShowBlip(blipConfig, shop) then
            Blips[#Blips + 1] = CreateBlip(blipConfig, shop.coords)
        end
    end
end

local function SetupDistanceBlips()
    for k in pairs(Config.Stores) do
        local shop = Config.Stores[k]
        local blipConfig = Config.Blips[shop.type]
        if ShowBlip(blipConfig, shop) then
            Points[#Points + 1] = lib.points.new({
                coords = shop.coords,
                distance = Config.BlipDistance or 60,
                blipConfig = blipConfig,
                onEnter = function(point)
                    if not point.blip then
                        point.blip = CreateBlip(point.blipConfig, point.coords)
                    end
                end,
                onExit = function(point)
                    if point.blip then
                        RemoveBlip(point.blip)
                        point.blip = nil
                    end
                end,
            })
        end
    end
end

function ResetBlips()
    ClearBlips()
    ClearPoints()

    if Config.ShowBlips == 1 then
        SetupDistanceBlips()
    elseif Config.ShowBlips == 2 then
        SetupAllBlips()
    end
end
