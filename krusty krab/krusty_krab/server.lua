local ESX = exports['es_extended']:getSharedObject()

local activeOrders = {}
local activeDeliveries = {}

local function IsKrustyJob(xPlayer)
    return xPlayer
        and xPlayer.job
        and xPlayer.job.name == Config.JobName
end

local function IsOnDuty(source)
    return activeDeliveries[source] ~= nil or true
end

local function GetItemCount(xPlayer, item)
    local inventoryItem = xPlayer.getInventoryItem(item)

    if not inventoryItem then
        return 0
    end

    return inventoryItem.count or 0
end

local function HasItems(xPlayer, items)
    for item, amount in pairs(items) do
        if GetItemCount(xPlayer, item) < amount then
            return false
        end
    end

    return true
end

local function RemoveItems(xPlayer, items)
    for item, amount in pairs(items) do
        xPlayer.removeInventoryItem(item, amount)
    end
end

local function GiveItem(xPlayer, item, amount)
    xPlayer.addInventoryItem(item, amount)
end

RegisterNetEvent('krustykrab:setDuty', function(state)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsKrustyJob(xPlayer) then
        return
    end

    if state then
        TriggerClientEvent(
            'esx:showNotification',
            source,
            'You are now on duty.'
        )
    else
        activeOrders[source] = nil
        activeDeliveries[source] = nil

        TriggerClientEvent(
            'esx:showNotification',
            source,
            'You are now off duty.'
        )
    end
end)

ESX.RegisterServerCallback(
    'krustykrab:canCook',
    function(source, cb, recipeName)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not IsKrustyJob(xPlayer) then
            cb(false)
            return
        end

        local recipe = Config.Recipes[recipeName]

        if not recipe then
            cb(false)
            return
        end

        cb(HasItems(xPlayer, recipe.required))
    end
)

RegisterNetEvent('krustykrab:finishCooking', function(recipeName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsKrustyJob(xPlayer) then
        return
    end

    local recipe = Config.Recipes[recipeName]

    if not recipe then
        return
    end

    if not HasItems(xPlayer, recipe.required) then
        TriggerClientEvent(
            'esx:showNotification',
            source,
            'You are missing ingredients.'
        )
        return
    end

    RemoveItems(xPlayer, recipe.required)

    GiveItem(
        xPlayer,
        recipe.reward.item,
        recipe.reward.amount
    )

    TriggerClientEvent(
        'esx:showNotification',
        source,
        ('You made %sx %s.'):format(
            recipe.reward.amount,
            recipe.reward.item
        )
    )
end)

RegisterNetEvent('krustykrab:restock', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsKrustyJob(xPlayer) then
        return
    end

    if xPlayer.job.grade < 1 then
        TriggerClientEvent(
            'esx:showNotification',
            source,
            'You are not authorized to restock.'
        )
        return
    end

    for item, amount in pairs(Config.StorageItems) do
        GiveItem(xPlayer, item, amount)
    end

    TriggerClientEvent(
        'esx:showNotification',
        source,
        'The restaurant has been restocked.'
    )
end)

ESX.RegisterServerCallback(
    'krustykrab:createOrder',
    function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not IsKrustyJob(xPlayer) then
            cb(false)
            return
        end

        if activeOrders[source] then
            cb(false)
            return
        end

        local order =
            Config.CustomerOrders[
                math.random(1, #Config.CustomerOrders)
            ]

        local orderId =
            ('%s_%s_%s'):format(
                source,
                os.time(),
                math.random(1000, 9999)
            )

        activeOrders[source] = {
            id = orderId,
            name = order.name,
            items = order.items,
            reward = order.reward,
            created = os.time()
        }

        cb({
            id = orderId,
            name = order.name,
            items = order.items,
            reward = order.reward
        })
    end
)

ESX.RegisterServerCallback(
    'krustykrab:completeOrder',
    function(source, cb, orderId)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not IsKrustyJob(xPlayer) then
            cb(false, 'You are not a Krusty Krab employee.')
            return
        end

        local order = activeOrders[source]

        if not order then
            cb(false, 'You have no active order.')
            return
        end

        if order.id ~= orderId then
            cb(false, 'Invalid order.')
            return
        end

        -- Prevent orders from being held indefinitely.
        if os.time() - order.created > 900 then
            activeOrders[source] = nil

            cb(false, 'That customer left because the order took too long.')
            return
        end

        if not HasItems(xPlayer, order.items) then
            cb(false, 'You do not have all of the requested food.')
            return
        end

        RemoveItems(xPlayer, order.items)

        xPlayer.addMoney(order.reward)

        activeOrders[source] = nil

        cb(true, 'Order completed.', order.reward)
    end
)

ESX.RegisterServerCallback(
    'krustykrab:startDelivery',
    function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not IsKrustyJob(xPlayer) then
            cb(false)
            return
        end

        if activeDeliveries[source] then
            cb(false)
            return
        end

        local locationIndex =
            math.random(
                1,
                #Config.Delivery.locations
            )

        activeDeliveries[source] = {
            location = locationIndex,
            started = os.time()
        }

        cb(true, locationIndex)
    end
)

ESX.RegisterServerCallback(
    'krustykrab:finishDelivery',
    function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not IsKrustyJob(xPlayer) then
            cb(false)
            return
        end

        local delivery = activeDeliveries[source]

        if not delivery then
            cb(false)
            return
        end

        -- Minimum delivery time prevents instant payout exploits.
        if os.time() - delivery.started < 15 then
            cb(false)
            return
        end

        local reward = Config.Delivery.reward

        xPlayer.addMoney(reward)

        activeDeliveries[source] = nil

        cb(true, reward)
    end
)

AddEventHandler('playerDropped', function()
    local source = source

    activeOrders[source] = nil
    activeDeliveries[source] = nil
end)