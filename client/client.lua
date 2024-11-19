local RSGCore = exports['rsg-core']:GetCoreObject()
local currentRestaurant = nil

-- Helper Functions
local function debugAuth(playerJob, requiredJob, restaurantId)
    if Config.Debug then
        print('Player Job:', playerJob)
        print('Required Job:', requiredJob)
        print('Restaurant ID:', restaurantId)
    end
end

local function getRestaurantById(id)
    for _, restaurant in pairs(Config.Restaurants) do
        if restaurant.id == id then
            if Config.Debug then
                print('Found restaurant:', restaurant.id, 'job:', restaurant.job)
            end
            return restaurant
        end
    end
    if Config.Debug then
        print('No restaurant found for id:', id)
    end
    return nil
end

local function isItemAllowed(restaurantId, itemName)
    local restaurant = getRestaurantById(restaurantId)
    if not restaurant then return false end
    
    for categoryName, items in pairs(restaurant.allowedItems) do
        for _, item in ipairs(items) do
            if item == itemName then
                if Config.Debug then
                    print('Item', itemName, 'is allowed in category', categoryName)
                end
                return true
            end
        end
    end
    return false
end

local function isBoss(PlayerData)
    return PlayerData.job.isboss or false
end

-- Setup Prompts and Blips
Citizen.CreateThread(function()
    for _, restaurant in pairs(Config.Restaurants) do
        -- Kitchen Prompt
        exports['rsg-core']:createPrompt(
            restaurant.id..'_kitchen',
            restaurant.locations.kitchen.coords,
            RSGCore.Shared.Keybinds[Config.Keybind],
            'Access Kitchen',
            {
                type = 'client',
                event = 'restaurant:client:openKitchen',
                args = { restaurant.id }
            }
        )
        
        -- Menu Prompt
        exports['rsg-core']:createPrompt(
            restaurant.id..'_menu',
            restaurant.locations.menu.coords,
            RSGCore.Shared.Keybinds[Config.Keybind],
            'Access Menu',
            {
                type = 'client',
                event = 'restaurant:client:openMenu',
                args = { restaurant.id }
            }
        )
        
        -- Storage Prompt
        exports['rsg-core']:createPrompt(
            restaurant.id..'_storage',
            restaurant.locations.storage.coords,
            RSGCore.Shared.Keybinds[Config.Keybind],
            'Access Storage',
            {
                type = 'client',
                event = 'restaurant:client:openStorage',
                args = { restaurant.id }
            }
        )

        -- Boss Menu Prompt
        exports['rsg-core']:createPrompt(
            restaurant.id..'_boss',
            restaurant.locations.boss.coords,
            RSGCore.Shared.Keybinds[Config.Keybind],
            'Access Management',
            {
                type = 'client',
                event = 'restaurant:client:openBossMenu',
                args = { restaurant.id }
            }
        )
        
        -- Create Blips
        if restaurant.locations.menu.showblip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, restaurant.locations.menu.coords)
            SetBlipSprite(blip, joaat(restaurant.blip.sprite), true)
            SetBlipScale(restaurant.blip.scale, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, restaurant.blip.name)
        end
    end
end)

-- Boss Menu
RegisterNetEvent('restaurant:client:openBossMenu')
AddEventHandler('restaurant:client:openBossMenu', function(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local restaurant = getRestaurantById(restaurantId)
    
    if Config.Debug then
        print('Opening boss menu for restaurant:', restaurantId)
        print('Player Job:', PlayerData.job.name)
        print('Is Boss:', isBoss(PlayerData))
    end

    if not restaurant then
        lib.notify({ title = 'Error', description = 'Invalid restaurant configuration', type = 'error' })
        return
    end

    if PlayerData.job.name ~= restaurant.job or not isBoss(PlayerData) then
        lib.notify({ title = 'Error', description = 'You don\'t have access to management', type = 'error' })
        return
    end

    -- Get current balance
    TriggerServerEvent('restaurant:server:getBossMenu', restaurantId)
end)

RegisterNetEvent('restaurant:client:showBossMenu')
AddEventHandler('restaurant:client:showBossMenu', function(data)
    local restaurantId = data.restaurantId
    local balance = tonumber(data.balance) -- Convert to number explicitly
    local transactions = data.transactions
    local restaurant = getRestaurantById(restaurantId)

    local options = {
        {
            title = 'Current Balance: $' .. string.format("%.2f", balance),
            description = 'Restaurant account balance',
            icon = 'fas fa-dollar-sign',
            disabled = true
        },
        {
            title = 'Withdraw Money',
            description = 'Withdraw money from restaurant account',
            icon = 'fas fa-money-bill-transfer',
            onSelect = function()
                local input = lib.inputDialog('Withdraw Money', {
                    { 
                        type = 'number',
                        label = 'Amount',
                        description = 'Enter amount to withdraw',
                        required = true,
                        min = tonumber(Config.MinimumWithdrawAmount),
                        max = tonumber(balance)
                    }
                })
                
                if input then
                    local amount = tonumber(input[1])
                    if amount and amount > 0 and amount <= balance then
                        TriggerServerEvent('restaurant:server:withdrawMoney', restaurantId, amount)
                    else
                        lib.notify({ title = 'Error', description = 'Invalid amount', type = 'error' })
                    end
                end
            end,
            arrow = true
        },
        {
            title = 'Transaction History',
            description = 'View recent transactions',
            icon = 'fas fa-history',
            onSelect = function()
                local transactionOptions = {}
                for _, transaction in ipairs(transactions) do
                    table.insert(transactionOptions, {
                        title = string.format("%s: $%.2f", transaction.type, tonumber(transaction.amount)),
                        description = string.format("By %s on %s\n%s", 
                            transaction.employee_name,
                            transaction.timestamp,
                            transaction.description
                        ),
                        icon = transaction.type == 'WITHDRAWAL' and 'fas fa-minus' or 'fas fa-plus'
                    })
                end
                
                lib.registerContext({
                    id = 'transaction_history',
                    title = restaurant.name .. ' - Transactions',
                    menu = 'restaurant_boss_menu',
                    options = transactionOptions
                })
                lib.showContext('transaction_history')
            end,
            arrow = true
        }
    }

    lib.registerContext({
        id = 'restaurant_boss_menu',
        title = restaurant.name .. ' - Management',
        options = options
    })
    lib.showContext('restaurant_boss_menu')
end)

-- Kitchen Menu
RegisterNetEvent('restaurant:client:openKitchen')
AddEventHandler('restaurant:client:openKitchen', function(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local restaurant = getRestaurantById(restaurantId)
    
    if Config.Debug then
        print('Opening kitchen for restaurant:', restaurantId)
        print('Player Job:', PlayerData.job.name)
        if restaurant then
            print('Required Job:', restaurant.job)
        else
            print('Restaurant not found!')
        end
    end

    if not restaurant then
        lib.notify({ title = 'Error', description = 'Invalid restaurant configuration', type = 'error' })
        return
    end

    if PlayerData.job.name ~= restaurant.job then
        if Config.Debug then
            print('Authorization failed')
            print('Player Job:', PlayerData.job.name)
            print('Required Job:', restaurant.job)
        end
        lib.notify({ title = 'Error', description = 'You don\'t have access to this kitchen', type = 'error' })
        return
    end
    
    currentRestaurant = restaurantId
    
    lib.registerContext({
        id = 'restaurant_kitchen_menu',
        title = restaurant.name .. ' - Kitchen',
        options = {
            {
                title = 'Crafting Menu',
                description = 'Craft new items for the restaurant',
                icon = 'fa-solid fa-utensils',
                onSelect = function()
                    TriggerEvent('restaurant:client:openCrafting', restaurantId)
                end,
                arrow = true
            },
            {
                title = 'Add Inventory Items',
                description = 'Add items from your inventory to the menu',
                icon = 'fa-solid fa-plus',
                onSelect = function()
                    TriggerEvent('restaurant:client:addItemToMenu', restaurantId)
                end,
                arrow = true
            }
        }
    })
    lib.showContext('restaurant_kitchen_menu')
end)

-- Crafting Menu
RegisterNetEvent('restaurant:client:openCrafting')
AddEventHandler('restaurant:client:openCrafting', function(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local restaurant = getRestaurantById(restaurantId)
    
    if Config.Debug then
        print('Opening crafting menu for restaurant:', restaurantId)
        print('Restaurant found:', restaurant ~= nil)
        if restaurant then
            print('Restaurant job:', restaurant.job)
            print('Player job:', PlayerData.job.name)
        end
    end

    if not restaurant then 
        lib.notify({ title = 'Error', description = 'Restaurant not found', type = 'error' })
        return 
    end
    
    if PlayerData.job.name ~= restaurant.job then 
        lib.notify({ title = 'Error', description = 'Not authorized', type = 'error' })
        return 
    end

    local categories = {}
    
    -- Check if food category has items
    if restaurant.allowedItems.food and next(restaurant.allowedItems.food) then
        table.insert(categories, {
            title = 'Food Items',
            description = 'Craft food items for the restaurant',
            icon = 'fa-solid fa-burger',
            onSelect = function()
                TriggerEvent('restaurant:client:openCraftingCategory', {
                    restaurantId = restaurantId,
                    category = 'food'
                })
            end,
            arrow = true
        })
    end

    -- Check if drinks category has items
    if restaurant.allowedItems.drinks and next(restaurant.allowedItems.drinks) then
        table.insert(categories, {
            title = 'Drink Items',
            description = 'Craft drinks for the restaurant',
            icon = 'fa-solid fa-glass-water',
            onSelect = function()
                TriggerEvent('restaurant:client:openCraftingCategory', {
                    restaurantId = restaurantId,
                    category = 'drinks'
                })
            end,
            arrow = true
        })
    end

    if Config.Debug then
        print('Number of available categories:', #categories)
    end

    if #categories == 0 then
        lib.notify({ title = 'Error', description = 'No crafting categories available', type = 'error' })
        return
    end

    lib.registerContext({
        id = 'restaurant_crafting_menu',
        title = restaurant.name .. ' - Crafting',
        menu = 'restaurant_kitchen_menu',
        options = categories
    })
    lib.showContext('restaurant_crafting_menu')
end)

RegisterNetEvent('restaurant:client:openCraftingCategory')
AddEventHandler('restaurant:client:openCraftingCategory', function(data)
    local restaurantId = data.restaurantId
    local category = data.category
    local restaurant = getRestaurantById(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    
    if Config.Debug then
        print('------- DEBUG: CRAFTING CATEGORY START -------')
        print('Restaurant ID:', restaurantId)
        print('Category:', category)
        print('Restaurant found:', restaurant ~= nil)
        
        if restaurant then
            print('\nAllowed Items for ' .. category .. ':')
            if restaurant.allowedItems[category] then
                for _, item in pairs(restaurant.allowedItems[category]) do
                    print('- ' .. item)
                end
            end

            print('\nAvailable Recipes for ' .. category .. ':')
            if Config.CraftingRecipes[category] then
                for recipeName, recipeData in pairs(Config.CraftingRecipes[category]) do
                    print('- ' .. recipeName .. ' (' .. recipeData.label .. ')')
                end
            end
        end
    end

    if not restaurant then 
        lib.notify({ title = 'Error', description = 'Restaurant not found', type = 'error' })
        return 
    end
    
    if PlayerData.job.name ~= restaurant.job then 
        lib.notify({ title = 'Error', description = 'Not authorized', type = 'error' })
        return 
    end

    local craftingOptions = {}
    local allowedItems = restaurant.allowedItems[category]
    
    if allowedItems then
        for _, itemName in ipairs(allowedItems) do
            local itemData = RSGCore.Shared.Items[itemName]
            local recipe = Config.CraftingRecipes[category] and Config.CraftingRecipes[category][itemName]
            
            if Config.Debug then
                print('\n------- Checking Item:', itemName, '-------')
                print('Item exists in shared items:', itemData ~= nil)
                print('Recipe exists:', recipe ~= nil)
                if itemData then
                    print('Item Label:', itemData.label)
                end
                if recipe then
                    print('Recipe Label:', recipe.label)
                    print('Recipe Ingredients:')
                    for _, ing in pairs(recipe.ingredients) do
                        local ingData = RSGCore.Shared.Items[ing.item]
                        print('  -', ing.item, ':', ing.amount, 'x', ingData and ingData.label or 'NOT FOUND')
                    end
                end
            end
            
            if itemData and recipe then
                local ingredientText = "Required ingredients:\n"
                local validRecipe = true
                local missingIngredients = {}
                
                -- Check player's current inventory
                local playerInventory = {}
                for _, item in pairs(PlayerData.items or {}) do
                    if item then
                        playerInventory[item.name] = item.amount
                    end
                end
                
                -- Check ingredients and build description
                for _, ingredient in pairs(recipe.ingredients) do
                    local ingredientItem = RSGCore.Shared.Items[ingredient.item]
                    if ingredientItem then
                        local playerHas = playerInventory[ingredient.item] or 0
                        ingredientText = ingredientText .. ingredient.amount .. "x " .. ingredientItem.label
                        ingredientText = ingredientText .. " (Have: " .. playerHas .. ")\n"
                    else
                        validRecipe = false
                        table.insert(missingIngredients, ingredient.item)
                        if Config.Debug then
                            print('Missing ingredient:', ingredient.item)
                        end
                    end
                end

                if validRecipe then
                    table.insert(craftingOptions, {
                        title = itemData.label,
                        description = ingredientText,
                        icon = "nui://"..Config.Img..itemData.image,
                        onSelect = function()
                            if Config.Debug then
                                print('Selected item to craft:', itemData.label)
                                print('Triggering crafting start event')
                            end
                            TriggerEvent('restaurant:client:startCrafting', {
                                restaurantId = restaurantId,
                                item = itemName,
                                category = category,
                                recipe = recipe
                            })
                        end,
                        arrow = true
                    })
                    
                    if Config.Debug then
                        print('Successfully added to crafting menu:', itemData.label)
                    end
                else
                    if Config.Debug then
                        print('Recipe invalid. Missing ingredients:', table.concat(missingIngredients, ', '))
                    end
                end
            end
        end
    end

    if #craftingOptions == 0 then
        if Config.Debug then
            print('\nNo valid crafting options found for category:', category)
        end
        lib.notify({ title = 'Error', description = 'No valid recipes available', type = 'error' })
        return
    end

    -- Sort options alphabetically
    table.sort(craftingOptions, function(a, b)
        return a.title < b.title
    end)

    if Config.Debug then
        print('\n------- Final Crafting Options -------')
        print('Number of available items:', #craftingOptions)
        for i, option in ipairs(craftingOptions) do
            print(i .. '.', option.title)
        end
        print('-------------------------------------')
    end

    lib.registerContext({
        id = 'restaurant_crafting_category',
        title = restaurant.name .. ' - ' .. category:gsub("^%l", string.upper),
        menu = 'restaurant_crafting_menu',
        options = craftingOptions
    })
    lib.showContext('restaurant_crafting_category')
end)

RegisterNetEvent('restaurant:client:startCrafting')
AddEventHandler('restaurant:client:startCrafting', function(data)
    if Config.Debug then
        print('Starting crafting process')
        print('Data received:', json.encode(data))
    end

    local input = lib.inputDialog('Craft ' .. data.recipe.label, {
        { 
            type = 'number',
            label = 'Amount to craft',
            description = 'Enter the amount you want to craft',
            required = true,
            min = 1
        }
    })
    
    if not input then 
        if Config.Debug then
            print('Crafting cancelled - No input received')
        end
        return 
    end

    local amount = tonumber(input[1])
    if amount <= 0 then 
        if Config.Debug then
            print('Crafting cancelled - Invalid amount:', amount)
        end
        return 
    end

    -- Check ingredients server-side and start crafting
    if Config.Debug then
        print('Sending craft request to server')
        print('Item:', data.item)
        print('Amount:', amount)
    end

    TriggerServerEvent('restaurant:server:checkCraftingIngredients', {
        restaurantId = data.restaurantId,
        item = data.item,
        recipe = data.recipe,
        amount = amount
    })
end)

RegisterNetEvent('restaurant:client:doCrafting')
AddEventHandler('restaurant:client:doCrafting', function(data)
    if Config.Debug then
        print('Starting crafting progress bar')
        print('Data received:', json.encode(data))
    end

    RSGCore.Functions.Progressbar('crafting_item', 'Crafting ' .. data.recipe.label, data.recipe.craftTime, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        if Config.Debug then
            print('Crafting progress complete, sending to server for final processing')
        end
        
        TriggerServerEvent('restaurant:server:finishCrafting', {
            restaurantId = data.restaurantId,
            item = data.item,
            recipe = data.recipe,
            amount = data.amount
        })
    end)
end)

RegisterNetEvent('restaurant:client:craftingFailed')
AddEventHandler('restaurant:client:craftingFailed', function(reason)
    lib.notify({
        title = 'Crafting Failed',
        description = reason,
        type = 'error'
    })
end)

-- Update the recipe menu selection event to use this
local function setupCraftingOption(itemName, itemData, recipe, restaurantId)
    return {
        title = itemData.label,
        description = buildIngredientText(recipe.ingredients),
        icon = "nui://"..Config.Img..itemData.image,
        onSelect = function()
            TriggerEvent('restaurant:client:startCrafting', {
                restaurantId = restaurantId,
                item = itemName,
                category = category,
                recipe = recipe
            })
        end,
        arrow = true
    }
end

-- Helper function to build ingredient text
local function buildIngredientText(ingredients)
    local text = "Required ingredients:\n"
    for _, ingredient in pairs(ingredients) do
        local ingredientItem = RSGCore.Shared.Items[ingredient.item]
        if ingredientItem then
            text = text .. ingredient.amount .. "x " .. ingredientItem.label .. "\n"
        end
    end
    return text
end


-- Set Price for Crafted Item
RegisterNetEvent('restaurant:client:getItemPrice')
AddEventHandler('restaurant:client:getItemPrice', function(data)
    local input = lib.inputDialog('Set Item Price', {
        { 
            type = 'number',
            label = 'Price per item',
            description = 'Enter the selling price for each item',
            required = true,
            min = 0.01,
            step = 0.01
        }
    })
    
    if not input then return end
    local price = tonumber(input[1])
    
    if price <= 0 then
        lib.notify({ 
            title = 'Error', 
            description = 'Price must be greater than 0', 
            type = 'error' 
        })
        return
    end

    if Config.Debug then
        print('Setting price for crafted item')
        print('Price:', price)
    end

    TriggerServerEvent('restaurant:server:setItemPrice', {
        restaurantId = data.restaurantId,
        item = data.item,
        amount = data.amount,
        price = price
    })
end)

-- Add Item to Menu from Inventory
RegisterNetEvent('restaurant:client:addItemToMenu')
AddEventHandler('restaurant:client:addItemToMenu', function(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local restaurant = getRestaurantById(restaurantId)
    
    if Config.Debug then
        print('Adding items to menu')
        print('Restaurant:', restaurantId)
        print('Player Job:', PlayerData.job.name)
    end
    
    if not restaurant or PlayerData.job.name ~= restaurant.job then
        lib.notify({ title = 'Error', description = 'Not authorized', type = 'error' })
        return
    end
    
    local inventory = PlayerData.items
    local menuItems = {}
    
    if inventory then
        for _, item in pairs(inventory) do
            if item and isItemAllowed(restaurantId, item.name) then
                if Config.Debug then
                    print('Found valid inventory item:', item.name)
                    print('Amount:', item.amount)
                end
                
                table.insert(menuItems, {
                    title = RSGCore.Shared.Items[item.name].label,
                    description = 'Amount: ' .. item.amount,
                    icon = "nui://"..Config.Img..RSGCore.Shared.Items[item.name].image,
                    onSelect = function()
                        TriggerEvent('restaurant:client:confirmAddToMenu', {
                            restaurantId = restaurantId,
                            item = item.name,
                            amount = item.amount
                        })
                    end,
                    arrow = true
                })
            end
        end
    end
    
    if #menuItems == 0 then
        lib.notify({ title = 'Error', description = 'No valid items in inventory', type = 'error' })
        return
    end
    
    lib.registerContext({
        id = 'add_to_menu',
        title = restaurant.name .. ' - Add Items',
        menu = 'restaurant_kitchen_menu',
        options = menuItems
    })
    lib.showContext('add_to_menu')
end)

-- Confirm Adding Item to Menu
RegisterNetEvent('restaurant:client:confirmAddToMenu')
AddEventHandler('restaurant:client:confirmAddToMenu', function(data)
    local input = lib.inputDialog('Add to Menu', {
        { type = 'number', label = 'Amount', description = 'Max: '..data.amount, required = true },
        { type = 'number', label = 'Price', description = 'Price per item', required = true, min = 0.01, step = 0.01 }
    })
    
    if not input then return end
    
    local amount = tonumber(input[1])
    local price = tonumber(input[2])
    
    if amount > data.amount then
        lib.notify({ title = 'Error', description = 'Not enough items', type = 'error' })
        return
    end
    
    if price <= 0 then
        lib.notify({ title = 'Error', description = 'Invalid price', type = 'error' })
        return
    end

    if Config.Debug then
        print('Confirming add to menu')
        print('Amount:', amount)
        print('Price:', price)
    end
    
    TriggerServerEvent('restaurant:server:addToMenu', data.restaurantId, data.item, amount, price)
end)

-- Storage Management
RegisterNetEvent('restaurant:client:openStorage')
AddEventHandler('restaurant:client:openStorage', function(restaurantId)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local restaurant = getRestaurantById(restaurantId)
    
    if Config.Debug then
        print('Opening storage for restaurant:', restaurantId)
        print('Player Job:', PlayerData.job.name)
    end

    if not restaurant or PlayerData.job.name ~= restaurant.job then
        lib.notify({ title = 'Error', description = 'Not authorized', type = 'error' })
        return
    end
    
    TriggerServerEvent("inventory:server:OpenInventory", "stash", restaurantId, {
        maxweight = Config.StorageMaxWeight,
        slots = Config.StorageMaxSlots,
    })
    TriggerEvent("inventory:client:SetCurrentStash", restaurantId)
end)

-- Customer Menu System
RegisterNetEvent('restaurant:client:openMenu')
AddEventHandler('restaurant:client:openMenu', function(restaurantId)
    if Config.Debug then
        print('Opening customer menu for restaurant:', restaurantId)
    end
    TriggerServerEvent('restaurant:server:getMenuItems', restaurantId)
end)

RegisterNetEvent('restaurant:client:showMenu')
AddEventHandler('restaurant:client:showMenu', function(restaurantId, items)
    local menuItems = {}
    local restaurant = getRestaurantById(restaurantId)
    
    if not restaurant then 
        if Config.Debug then
            print('Restaurant not found:', restaurantId)
        end
        return 
    end

    if Config.Debug then
        print('Building menu with', #items, 'items')
    end
    
    -- Sort items by category
    local categorizedItems = {
        food = {},
        drinks = {}
    }

    for _, item in pairs(items) do
        if item.stock > 0 then
            -- Determine category
            local itemCategory = nil
            for category, itemList in pairs(restaurant.allowedItems) do
                for _, allowedItem in ipairs(itemList) do
                    if allowedItem == item.item then
                        itemCategory = category
                        break
                    end
                end
                if itemCategory then break end
            end

            if itemCategory then
                table.insert(categorizedItems[itemCategory], {
                    title = RSGCore.Shared.Items[item.item].label,
                    description = string.format('Price: $%.2f | Stock: %d', item.price, item.stock),
                    icon = "nui://"..Config.Img..RSGCore.Shared.Items[item.item].image,
                    item = item.item,
                    price = item.price,
                    stock = item.stock
                })
            end
        end
    end

    -- Create category submenus
    for category, categoryItems in pairs(categorizedItems) do
        if #categoryItems > 0 then
            table.insert(menuItems, {
                title = category:gsub("^%l", string.upper),
                description = 'View available ' .. category,
                icon = category == 'food' and 'fa-solid fa-burger' or 'fa-solid fa-glass-water',
                onSelect = function()
                    local categoryOptions = {}
                    for _, itemData in ipairs(categoryItems) do
                        table.insert(categoryOptions, {
                            title = itemData.title,
                            description = itemData.description,
                            icon = itemData.icon,
                            onSelect = function()
                                TriggerEvent('restaurant:client:buyItem', {
                                    restaurantId = restaurantId,
                                    item = itemData.item,
                                    price = itemData.price,
                                    stock = itemData.stock
                                })
                            end,
                            arrow = true
                        })
                    end

                    lib.registerContext({
                        id = 'restaurant_menu_' .. category,
                        title = restaurant.name .. ' - ' .. category:gsub("^%l", string.upper),
                        menu = 'restaurant_menu',
                        options = categoryOptions
                    })
                    lib.showContext('restaurant_menu_' .. category)
                end,
                arrow = true
            })
        end
    end
    
    if #menuItems == 0 then
        lib.notify({ title = 'Information', description = 'No items available', type = 'info' })
        return
    end
    
    lib.registerContext({
        id = 'restaurant_menu',
        title = restaurant.name .. ' - Menu',
        options = menuItems
    })
    lib.showContext('restaurant_menu')
end)

-- Purchase System
RegisterNetEvent('restaurant:client:buyItem')
AddEventHandler('restaurant:client:buyItem', function(data)
    if Config.Debug then
        print('Opening purchase dialog for item:', data.item)
        print('Price:', data.price)
        print('Available stock:', data.stock)
    end

    local input = lib.inputDialog('Purchase ' .. RSGCore.Shared.Items[data.item].label, {
        { 
            type = 'number', 
            label = 'Amount', 
            description = 'Max: '..data.stock, 
            required = true,
            min = 1,
            max = data.stock
        }
    })
    
    if not input then return end
    
    local amount = tonumber(input[1])
    if amount <= 0 or amount > data.stock then
        lib.notify({ title = 'Error', description = 'Invalid amount', type = 'error' })
        return
    end

    local totalPrice = amount * data.price
    local confirmPurchase = lib.alertDialog({
        header = 'Confirm Purchase',
        content = string.format('Purchase %d x %s for $%.2f?', 
            amount, 
            RSGCore.Shared.Items[data.item].label,
            totalPrice
        ),
        centered = true,
        cancel = true
    })

    if confirmPurchase == 'confirm' then
        if Config.Debug then
            print('Confirming purchase')
            print('Amount:', amount)
            print('Total price:', totalPrice)
        end
        
        TriggerServerEvent('restaurant:server:purchaseItem', data.restaurantId, data.item, amount, data.price)
    end
end)

-- Notification Handler
RegisterNetEvent('restaurant:client:notify')
AddEventHandler('restaurant:client:notify', function(data)
    lib.notify({
        title = data.title,
        description = data.description,
        type = data.type,
        duration = data.duration or 5000
    })
end)