Config = {}

Config.Open = {
    Distance = 3.0, -- [E] mesafesi
    Key = true, -- True ise [E] kullanılır, false ise qb-target kullanır.
}

Config.AlwaysShowBankBlips = true

Config.BankBlip = {
    sprite = 106,      
    colour = 2,       
    scale = 0.6,
    shortRange = true
}


Config.BankLocations = {
    {
        label = "Banka",
        coords = vector3(149.73, -1041.26, 29.54),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    },
    {
        label = "Banka",
        coords = vector3(-1212.51, -331.05, 38.00),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    },
    {
        label = "Banka",
        coords = vector3(-2961.79, 482.94, 15.83),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    },
    {
        label = "Banka",
        coords = vector3(314.01, -279.73, 54.40),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    },
    {
        label = "Banka",
        coords = vector3(-351.03, -50.33, 49.29),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    },
    {
        label = "Banka",
        coords = vector3(1175.07, 2707.2, 38.32),
        blip = true,
        blipSettings = {
            sprite = 106,
            colour = 2,
            scale = 0.6,
            shortRange = true
        }
    }
}


Config.ATMProps = {
    "prop_atm_01",
    "prop_atm_02",
    "prop_atm_03",
    "prop_fleeca_atm",
}

Config.Translations = {}

Config.quickNumbers = {
    500,
    1000,
    2500
}