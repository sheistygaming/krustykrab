local ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local onDuty = false
local currentOrder = nil
local deliveryActive = false
local deliveryBlip = nil

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job

    if job.name ~= Config.JobName then
        onDuty = false
    end
end)

local function IsKrustyEmployee()
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

local function DrawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z)

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)

    ClearDrawOrigin()
end

local function ShowHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function ProgressBar(label, duration)
    local startTime = GetGameTimer()

    while GetGameTimer() - startTime < duration do
        Wait(0)

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 22, true)

        local progress = (GetGameTimer() - startTime) / duration

        DrawRect(
            0.5,
            0.90,
            0.25,
            0.025,
            0,
            0,
            0,
            180
        )

        DrawRect(
            0.5 - (0.25 / 2) + (0.25 * progress / 2),
            0.90,
            0.25 * progress,
            0.025,
            255,
            193,
            7,
            220
        )

        SetTextCentre(true)
        SetTextScale(0.35, 0.35)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandDisplayText(0.5, 0.86)
    end

    return true
end

local function StartCooking(recipeName)
    if not onDuty then
        ESX.ShowNotification('You must be clocked in.')
        return
    end

    local recipe = Config.Recipes[recipeName]

    if not recipe then
        return
    end

    ESX.TriggerServerCallback(
        'krustykrab:canCook',
        function(canCook)
            if not canCook then
                ESX.ShowNotification('You do not have the required ingredients.')
                return
            end

            local duration = Config.CookingTime[recipeName] or 5000

            TaskStartScenarioInPlace(
                PlayerPedId(),
                'PROP_HUMAN_BBQ',
                0,
                true
            )

            ProgressBar('Preparing food...', duration)

            ClearPedTasks(PlayerPedId())

            TriggerServerEvent(
                'krustykrab:finishCooking',
                recipeName
            )
        end,
        recipeName
    )
end

local function ToggleDuty()
    if not IsKrustyEmployee() then
        return
    end

    onDuty = not onDuty

    if onDuty then
        TriggerServerEvent('krustykrab:setDuty', true)
        ESX.ShowNotification('You clocked ~g~in~s~.')
    else
        TriggerServerEvent('krustykrab:setDuty', false)
        ESX.ShowNotification('You clocked ~r~out~s~.')
    end
end

local function StartCustomerOrder()
    if not onDuty then
        ESX.ShowNotification('You must be clocked in.')
        return
    end

    if currentOrder then
        ESX.ShowNotification('You already have an active order.')
        return
    end

    ESX.TriggerServerCallback(
        'krustykrab:createOrder',
        function(order)
            if not order then
                ESX.ShowNotification('No customers are waiting right now.')
                return
            end

            currentOrder = order

            ESX.ShowNotification(
                ('New order: ~y~%s~s~'):format(order.name)
            )
        end
    )
end

local function CompleteCustomerOrder()
    if not currentOrder then
        ESX.ShowNotification('You do not have an active order.')
        return
    end

    ESX.TriggerServerCallback(
        'krustykrab:completeOrder',
        function(success, message, reward)
            if success then
                ESX.ShowNotification(
                    ('Order complete! You earned ~g~$%s~s~.'):format(reward)
                )

                currentOrder = nil
            else
                ESX.ShowNotification(message or 'You are missing items.')
            end
        end,
        currentOrder.id
    )
end

local function StartDelivery()
    if not Config.Delivery.enabled then
        return
    end

    if not onDuty then
        ESX.ShowNotification('You must be clocked in.')
        return
    end

    if deliveryActive then
        ESX.ShowNotification('You already have a delivery.')
        return
    end

    ESX.TriggerServerCallback(
        'krustykrab:startDelivery',
        function(success, locationIndex)
            if not success then
                ESX.ShowNotification('You cannot start another delivery yet.')
                return
            end

            local location = Config.Delivery.locations[locationIndex]

            deliveryActive = true

            deliveryBlip = AddBlipForCoord(
                location.x,
                location.y,
                location.z
            )

            SetBlipSprite(deliveryBlip, 1)
            SetBlipColour(deliveryBlip, 47)
            SetBlipScale(deliveryBlip, 0.85)
            SetBlipRoute(deliveryBlip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Krusty Krab Delivery')
            EndTextCommandSetBlipName(deliveryBlip)

            ESX.ShowNotification('Delivery started. Follow the GPS.')
        end
    )
end

local function FinishDelivery()
    if not deliveryActive then
        return
    end

    ESX.TriggerServerCallback(
        'krustykrab:finishDelivery',
        function(success, reward)
            if not success then
                return
            end

            deliveryActive = false

            if deliveryBlip then
                RemoveBlip(deliveryBlip)
                deliveryBlip = nil
            end

            ESX.ShowNotification(
                ('Delivery complete! You earned ~g~$%s~s~.'):format(reward)
            )
        end
    )
end

local function OpenBossMenu()
    if not IsKrustyEmployee() then
        return
    end

    if PlayerData.job.grade_name ~= 'boss' then
        ESX.ShowNotification('You are not the manager.')
        return
    end

    TriggerEvent(
        'esx_society:openBossMenu',
        Config.JobName,
        function(data, menu)
            menu.close()
        end,
        {
            wash = false
        }
    )
end

CreateThread(function()
    while true do
        local sleep = 1000

        if IsKrustyEmployee() then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local locations = {
                {
                    coords = Config.Locations.ClockIn,
                    action = 'clock'
                },
                {
                    coords = Config.Locations.Kitchen,
                    action = 'patty'
                },
                {
                    coords = Config.Locations.Fryer,
                    action = 'fries'
                },
                {
                    coords = Config.Locations.Drinks,
                    action = 'cola'
                },
                {
                    coords = Config.Locations.Counter,
                    action = 'order'
                },
                {
                    coords = Config.Locations.Storage,
                    action = 'storage'
                },
                {
                    coords = Config.Locations.Boss,
                    action = 'boss'
                }
            }

            for _, location in pairs(locations) do
                local distance = #(coords - location.coords)

                if distance < 15.0 then
                    sleep = 0

                    DrawMarker(
                        Config.Marker.type,
                        location.coords.x,
                        location.coords.y,
                        location.coords.z,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        Config.Marker.scale.x,
                        Config.Marker.scale.y,
                        Config.Marker.scale.z,
                        Config.Marker.color.r,
                        Config.Marker.color.g,
                        Config.Marker.color.b,
                        Config.Marker.color.a,
                        false,
                        true,
                        2,
                        false,
                        nil,
                        nil,
                        false
                    )

                    if distance < Config.InteractionDistance then
                        if location.action == 'clock' then
                            ShowHelp(
                                onDuty
                                and '~E~ Clock out'
                                or '~E~ Clock in'
                            )

                            if IsControlJustReleased(0, 38) then
                                ToggleDuty()
                            end

                        elseif location.action == 'patty' then
                            ShowHelp('~E~ Cook Krabby Patty')

                            if IsControlJustReleased(0, 38) then
                                StartCooking('patty')
                            end

                        elseif location.action == 'fries' then
                            ShowHelp('~E~ Cook Krabby Fries')

                            if IsControlJustReleased(0, 38) then
                                StartCooking('fries')
                            end

                        elseif location.action == 'cola' then
                            ShowHelp('~E~ Make Krabby Cola')

                            if IsControlJustReleased(0, 38) then
                                StartCooking('cola')
                            end

                        elseif location.action == 'order' then
                            if currentOrder then
                                ShowHelp(
                                    '~E~ Serve order: ' ..
                                    currentOrder.name
                                )

                                if IsControlJustReleased(0, 38) then
                                    CompleteCustomerOrder()
                                end
                            else
                                ShowHelp('~E~ Take customer order')

                                if IsControlJustReleased(0, 38) then
                                    StartCustomerOrder()
                                end
                            end

                        elseif location.action == 'storage' then
                            ShowHelp('~E~ Restock ingredients')

                            if IsControlJustReleased(0, 38) then
                                TriggerServerEvent(
                                    'krustykrab:restock'
                                )
                            end

                        elseif location.action == 'boss' then
                            if PlayerData.job.grade_name == 'boss' then
                                ShowHelp('~E~ Boss Menu')

                                if IsControlJustReleased(0, 38) then
                                    OpenBossMenu()
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    if not Config.Blip.enabled then
        return
    end

    local blip = AddBlipForCoord(
        Config.Locations.ClockIn.x,
        Config.Locations.ClockIn.y,
        Config.Locations.ClockIn.z
    )

    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    while true do
        Wait(0)

        if deliveryActive then
            local playerCoords = GetEntityCoords(PlayerPedId())

            local nearest = nil
            local nearestDistance = 9999.0

            for _, location in ipairs(Config.Delivery.locations) do
                local distance = #(playerCoords - location)

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = location
                end
            end

            if nearest and nearestDistance < 20.0 then
                DrawMarker(
                    1,
                    nearest.x,
                    nearest.y,
                    nearest.z - 1.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    2.0,
                    2.0,
                    1.0,
                    255,
                    193,
                    7,
                    150,
                    false,
                    false,
                    2,
                    false,
                    nil,
                    nil,
                    false
                )

                if nearestDistance < 3.0 then
                    ShowHelp('~E~ Complete delivery')

                    if IsControlJustReleased(0, 38) then
                        FinishDelivery()
                    end
                end
            end
        end
    end
end)

RegisterCommand('kkdelivery', function()
    StartDelivery()
end, false)

RegisterCommand('kkorder', function()
    StartCustomerOrder()
end, false)