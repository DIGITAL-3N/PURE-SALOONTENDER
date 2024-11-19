Config = {}

Config.Debug = true
Config.Img = "rsg-inventory/html/images/"
Config.StorageMaxWeight = 4000000
Config.StorageMaxSlots = 48
Config.Keybind = 'J'

-- Boss Menu Settings
Config.BossMenuKeybind = 'B'
Config.MinimumWithdrawAmount = 1.0
Config.MaximumWithdrawAmount = 10000.0

Config.CraftingRecipes = {
    food = {
        ["skaridi"] = {
            label = "Shrimp",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["midi"] = {
            label = "Mussels",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["sushi"] = {
            label = "Sushi",
            ingredients = {
                { item = "raw_fish", amount = 5 },
                { item = "rice", amount = 2 }
            },
            craftTime = 10000
        },
        ["salmonasperji"] = {
            label = "Salmon Asparagus",
            ingredients = {
                { item = "raw_fish", amount = 5 },
                { item = "asparagus", amount = 2 }
            },
            craftTime = 10000
        },
        ["calmari"] = {
            label = "Calamari",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["octopussy"] = {
            label = "Octopus",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["sharkfillet"] = {
            label = "Shark Fillet",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["seasalad"] = {
            label = "Sea Salad",
            ingredients = {
                { item = "raw_fish", amount = 3 },
                { item = "vegetables", amount = 2 }
            },
            craftTime = 10000
        },
        ["tunafishfillet"] = {
            label = "Tuna Fish Fillet",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["kingcrab"] = {
            label = "King Crab",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        },
        ["omar"] = {
            label = "Lobster",
            ingredients = {
                { item = "raw_fish", amount = 5 }
            },
            craftTime = 10000
        }
    },
    drinks = {
        ["draftbeer"] = {
            label = "Draft Beer",
            ingredients = {
                { item = "water", amount = 2 },
                { item = "hops", amount = 3 }
            },
            craftTime = 10000
        },
        ["citruslemonade"] = {
            label = "Citrus Lemonade",
            ingredients = {
                { item = "water", amount = 3 },
                { item = "hops", amount = 2 }
            },
            craftTime = 10000
        },
        ["mintlemonade"] = {
            label = "Mint Lemonade",
            ingredients = {
                { item = "water", amount = 3 },
                { item = "hops", amount = 2 }
            },
            craftTime = 10000
        },
        ["orangelemonade"] = {
            label = "Orange Lemonade",
            ingredients = {
                { item = "water", amount = 3 },
                { item = "hops", amount = 2 }
            },
            craftTime = 10000
        }
    }
}

Config.Restaurants = {
    {
        id = 'blackwater_fish',
        name = 'Blackwater Fish Restaurant',
        job = 'horsetrainer',
        locations = {
            kitchen = {
                name = 'Kitchen',
                coords = vector3(-734.79, -1217.96, 43.11),
                showblip = false
            },
            menu = {
                name = 'Restaurant Menu',
                coords = vector3(-737.67, -1215.08, 43.11),
                showblip = true
            },
            storage = {
                name = 'Storage',
                coords = vector3(-735.79, -1216.96, 43.11),
                showblip = false
            },
            boss = {
                name = 'Management Office',
                coords = vector3(-735.79, -1218.96, 43.11),
                showblip = false
            }
        },
        allowedItems = {
            food = {
                "skaridi", "midi", "sushi", "salmonasperji",
                "calmari", "octopussy", "sharkfillet", "seasalad",
                "tunafishfillet", "kingcrab", "omar"
            },
            drinks = {
                "mintlemonade", "draftbeer", "citruslemonade", "orangelemonade"
            }
        },
        blip = {
            name = 'Fish Restaurant - Blackwater',
            sprite = 'blip_shop_store',
            scale = 0.2
        }
    },
    {
        id = 'magic_island_fish',
        name = 'Magic Island Fish Restaurant',
        job = 'police',
        locations = {
            kitchen = {
                name = 'Kitchen',
                coords = vector3(2581.48, -1157.65, 53.71),
                showblip = false
            },
            menu = {
                name = 'Restaurant Menu',
                coords = vector3(2582.22, -1165.75, 53.71),
                showblip = true
            },
            storage = {
                name = 'Storage',
                coords = vector3(2579.74, -1156.45, 53.72),
                showblip = false
            },
            boss = {
                name = 'Management Office',
                coords = vector3(2580.74, -1156.45, 53.72),
                showblip = false
            }
        },
        allowedItems = {
            food = {
                "skaridi", "midi", "sushi", "salmonasperji",
                "calmari", "octopussy", "sharkfillet", "seasalad",
                "tunafishfillet", "kingcrab", "omar"
            },
            drinks = {
                "mintlemonade", "draftbeer", "citruslemonade", "orangelemonade"
            }
        },
        blip = {
            name = 'Fish Restaurant - Magic Island',
            sprite = 'blip_shop_store',
            scale = 0.2
        }
    },
    {
        id = 'casino_boat',
        name = 'Casino Boat Restaurant',
        job = 'horsetrainer',
        locations = {
            kitchen = {
                name = 'Kitchen',
                coords = vector3(2856.33, -1401.23, 47.53),
                showblip = false
            },
            menu = {
                name = 'Restaurant Menu',
                coords = vector3(2655.33, -1399.12, 51.14),
                showblip = true
            },
            storage = {
                name = 'Storage',
                coords = vector3(2855.33, -1400.23, 47.53),
                showblip = false
            },
            boss = {
                name = 'Management Office',
                coords = vector3(2855.33, -1402.23, 47.53),
                showblip = false
            }
        },
        allowedItems = {
            food = {
                "skaridi", "midi", "sushi", "salmonasperji",
                "calmari", "octopussy", "sharkfillet", "seasalad",
                "tunafishfillet", "kingcrab", "omar"
            },
            drinks = {
                "mintlemonade", "draftbeer", "citruslemonade", "orangelemonade"
            }
        },
        blip = {
            name = 'Casino Boat Restaurant',
            sprite = 'blip_shop_store',
            scale = 0.2
        }
    }
}