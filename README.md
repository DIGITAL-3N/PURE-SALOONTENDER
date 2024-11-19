# RedM Restaurant Management System

A comprehensive restaurant management system for RedM servers using RSGCore framework. This script allows players to manage restaurants, craft items, handle inventory, and process sales with a complete financial tracking system.

## Features

### Restaurant Management
- Multiple restaurant locations with unique inventories
- Job-based access control for each location
- Customizable recipes and ingredients
- Separate storage system for each restaurant
- Individual restaurant bank accounts

### Crafting System
- Category-based crafting (Food & Drinks)
- Ingredient requirement system
- Visual crafting progress
- Inventory checks for ingredients
- Customizable crafting times

### Menu Management
- Add items directly from inventory
- Custom pricing for menu items
- Stock management system
- Category organization (Food & Drinks)
- Real-time stock updates

### Financial System
- Complete transaction logging
- Boss menu for money management
- Detailed transaction history
- Secure withdrawal system
- Sales tracking

### Customer Interface
- Easy-to-use ordering system
- Category-based menu display
- Stock availability checks
- Automatic inventory updates
- Purchase confirmations

## Dependencies
- RSGCore
- ox_lib
- oxmysql

## Installation

1. Ensure you have all dependencies installed
2. Import the SQL files into your database:
```sql
restaurant.sql
```

3. Add to your `server.cfg`:
```cfg
ensure rsg-core
ensure ox_lib
ensure oxmysql
ensure restaurant-system
```

4. Configure the locations in `config.lua` to your liking

5. Add items to your shared items (`RSGCore.Shared.Items`):
```lua
-- Crafting Ingredients
["water"]           = {["name"] = "water",           ["label"] = "Water",         ["weight"] = 1.0, ["type"] = "item", ["image"] = "water.png",           ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Water"},
["hops"]            = {["name"] = "hops",            ["label"] = "Hops",          ["weight"] = 0.1, ["type"] = "item", ["image"] = "hops.png",            ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Hops for brewing"},
["mint"]            = {["name"] = "mint",            ["label"] = "Mint",          ["weight"] = 0.1, ["type"] = "item", ["image"] = "mint.png",            ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Fresh mint leaves"},
["lemon"]           = {["name"] = "lemon",           ["label"] = "Lemon",         ["weight"] = 0.1, ["type"] = "item", ["image"] = "lemon.png",           ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Fresh lemon"},
["orange"]          = {["name"] = "orange",          ["label"] = "Orange",        ["weight"] = 0.1, ["type"] = "item", ["image"] = "orange.png",          ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Fresh orange"},

-- Craftable Items
["draftbeer"]       = {["name"] = "draftbeer",       ["label"] = "Draft Beer",    ["weight"] = 1.0, ["type"] = "item", ["image"] = "draftbeer.png",       ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "A cold draft beer"},
["mintlemonade"]    = {["name"] = "mintlemonade",    ["label"] = "Mint Lemonade", ["weight"] = 1.0, ["type"] = "item", ["image"] = "mintlemonade.png",    ["unique"] = false, ["useable"] = true,  ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Refreshing mint lemonade"}
```

## Configuration

The script can be configured through the `config.lua` file:

### Adding New Restaurants
```lua
Config.Restaurants = {
    {
        id = 'restaurant_id',
        name = 'Restaurant Name',
        job = 'job_name',
        locations = {
            kitchen = {
                name = 'Kitchen',
                coords = vector3(x, y, z),
                showblip = false
            },
            -- Add other locations
        },
        allowedItems = {
            food = {
                "item1", "item2"
            },
            drinks = {
                "drink1", "drink2"
            }
        }
    }
}
```

### Adding New Recipes
```lua
Config.CraftingRecipes = {
    drinks = {
        ["drinkname"] = {
            label = "Drink Label",
            ingredients = {
                { item = "ingredient1", amount = 2 },
                { item = "ingredient2", amount = 3 }
            },
            craftTime = 10000
        }
    }
}
```

## Usage

### For Restaurant Staff
1. Access the kitchen menu at designated locations
2. Craft items using available ingredients
3. Add crafted items to the restaurant menu
4. Set prices for menu items
5. Monitor stock levels

### For Restaurant Managers
1. Access the boss menu
2. View transaction history
3. Withdraw restaurant earnings
4. Monitor sales and performance

### For Customers
1. Visit any restaurant location
2. Browse the menu by category
3. Purchase available items
4. Items automatically added to inventory

## Commands
No commands are required. All functionality is accessed through interaction points in the world.

## Support
For support, please raise an issue on the GitHub repository.

## License
[MIT License](https://choosealicense.com/licenses/mit/)

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Credits
Created by DIGITALEN - Based on the original RSG-SaloonTender
Based on RSGCore framework
