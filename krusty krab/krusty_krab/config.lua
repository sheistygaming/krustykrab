Config = {}

Config.JobName = 'krustykrab'

Config.Marker = {
    type = 2,
    scale = vector3(0.25, 0.25, 0.25),
    color = { r = 255, g = 193, b = 7, a = 180 }
}

Config.Blip = {
    enabled = true,
    sprite = 267,
    color = 47,
    scale = 0.8,
    name = 'Krusty Krab'
}

Config.Locations = {
    ClockIn = vector3(-1194.42, -892.25, 13.98),

    Kitchen = vector3(-1196.11, -897.38, 13.98),

    Fryer = vector3(-1198.31, -896.52, 13.98),

    Drinks = vector3(-1193.97, -898.71, 13.98),

    Storage = vector3(-1201.26, -899.02, 13.98),

    Counter = vector3(-1190.75, -894.35, 13.98),

    Boss = vector3(-1191.52, -901.54, 13.98)
}

Config.InteractionDistance = 2.0

Config.CookingTime = {
    patty = 7000,
    fries = 5000,
    cola = 3000
}

Config.Delivery = {
    enabled = true,
    reward = 250,

    locations = {
        vector3(-1037.61, -2737.84, 20.17),
        vector3(-707.41, -914.75, 19.21),
        vector3(255.83, -375.11, 44.14),
        vector3(1130.11, -989.23, 45.97),
        vector3(-154.25, 642.22, 113.54),
        vector3(-42.11, -1750.22, 29.42)
    }
}

Config.Pay = {
    patty = 35,
    fries = 20,
    cola = 15
}

Config.Recipes = {
    patty = {
        required = {
            meat = 1,
            lettuce = 1,
            cheese = 1,
            bun = 1
        },
        reward = {
            item = 'krabby_patty',
            amount = 1
        }
    },

    fries = {
        required = {
            potato = 2
        },
        reward = {
            item = 'krabby_fries',
            amount = 1
        }
    },

    cola = {
        required = {
            water = 1,
            cola_syrup = 1
        },
        reward = {
            item = 'krabby_cola',
            amount = 1
        }
    }
}

Config.StorageItems = {
    meat = 50,
    lettuce = 50,
    cheese = 50,
    bun = 50,
    potato = 50,
    water = 50,
    cola_syrup = 50
}

Config.CustomerOrders = {
    {
        name = 'Krabby Meal',
        items = {
            krabby_patty = 1,
            krabby_fries = 1,
            krabby_cola = 1
        },
        reward = 150
    },

    {
        name = 'Krabby Patty',
        items = {
            krabby_patty = 1
        },
        reward = 75
    },

    {
        name = 'Patty + Fries',
        items = {
            krabby_patty = 1,
            krabby_fries = 1
        },
        reward = 110
    },

    {
        name = 'Fries + Cola',
        items = {
            krabby_fries = 1,
            krabby_cola = 1
        },
        reward = 70
    }
}