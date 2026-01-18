local blipsCreated = false
local Blips = {}

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    if Config.AlwaysShowBankBlips then
        createBlips()
    end
end)

function createBlips()
    if blipsCreated then return end

    for _, v in ipairs(Config.BankLocations) do
        if v.blip and v.blipSettings then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            local b = v.blipSettings

            SetBlipSprite(blip, b.sprite)
            SetBlipColour(blip, b.colour)
            SetBlipScale(blip, b.scale)
            SetBlipAsShortRange(blip, b.shortRange)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(v.label)
            EndTextCommandSetBlipName(blip)

            Blips[#Blips + 1] = blip
        end
    end

    blipsCreated = true
end



function removeBlips()
    for i = 1, #Blips do
        RemoveBlip(Blips[i])
    end
    Blips = {}
    blipsCreated = false
end


RegisterNetEvent("ra1derBanking:client:ToggleBankBlips", function()
    if blipsCreated then
        removeBlips()
        QBCore.Functions.Notify('Banka iconları kapatıldı!', 'error')
    else
        createBlips()
        QBCore.Functions.Notify('Banka iconları açıldı!', 'success')
    end
end)


function bankAnimationEnter()
    local player = PlayerPedId()
    local dict = "anim@amb@prop_human_atm@interior@male@enter"
    local anim = "enter"

    loadAnimDict(dict)
    TaskPlayAnim(player, dict, anim, 8.0, -8.0, 1500, 0, 0, false, false, false)
end

function bankAnimationIdle()
    local player = PlayerPedId()
    local dict = "anim@heists@fleeca_bank@scope_out@cashier_loop"
    local anim = "cashier_loop"

    loadAnimDict(dict)
    TaskPlayAnim(player, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

function stopAnimation(dict)
    local player = PlayerPedId() 
    ClearPedTasks(player)
end

if Config.Open.Key ~= false then
    local ekran = false  
    CreateThread(function()
        while true do
            local bekle = 2000
            local pedCo = GetEntityCoords(PlayerPedId())
            local inZone = false
    
            for k, v in pairs(Config.BankLocations) do
                local coords = v.coords
                local distance = #(pedCo - coords)
    
                if distance < 10 then
                    bekle = 0
                    inZone = true
    
                    if distance < 2 then
                        if not ekran then
                            -- exports["ra1derUI"]:TextDisplay(
                            --     "banka",
                            --     "left",
                            --     "Banka",
                            --     "DollarSign",
                            --     "Los Santos Bank",
                            --     "University",
                            --     "E"
                            -- )
                            textUI = lib.showTextUI("[E] Banka", {
                                position = "left-center",
                                icon = 'DollarSign',
                            })
                            ekran = true
                        end
    
                        if IsControlJustReleased(0, 46) then
                            openUI()
                        end
                    else
                        if ekran then
                            exports["ra1derUI"]:HideText()
                            lib.hideTextUI()
                            ekran = false
                        end
                    end
                end
            end
    
            if not inZone then
                if ekran then
                    lib.hideTextUI()
                    exports["ra1derUI"]:KeyPressed()
                    ekran = false
                end
            end
    
            Wait(bekle)
        end
    end)
else
    CreateThread(function()
        for k, v in pairs(Config.BankLocations) do
            exports['qb-target']:AddBoxZone("ra1derbank-" .. k, v.coords, 1.5, 1.5, {
                name = "ra1derbank-" .. k,
                debugPoly = false,
                heading = 0,
                minZ = v.coords - 2.0,
                maxZ = v.coords + 2.0,
                }, {
                options = {
                    {
                        icon = v.icon,
                        label = v.label,
                        action = function()
                            openUI()
                        end,
                        canInteract = function()
                            return not IsPedInAnyVehicle(PlayerPedId(), false)
                        end
                    }
                },
                distance = 3.0
            })
        end
    end)
end


CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.ATMProps , {
        options = {
            {
                icon = "fas fa-credit-card",
                label = "ATM",
                action = function()
                    openUI()
                end,
                canInteract = function()
                    return not IsPedInAnyVehicle(PlayerPedId(), false)
                end
            }
        },
        distance = 1.5    
    })
end)

RegisterNetEvent("ra1derBanking:client:Notify", function(message, type, length)
    QBCore.Functions.Notify(message, type, length)
end)

