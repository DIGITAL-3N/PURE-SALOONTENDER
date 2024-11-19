local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- Version Checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'
    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/pure-saloontender/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------------------
local function LogTransaction(restaurantId, transactionType, amount, description, employeeName)
    MySQL.insert('INSERT INTO restaurant_transactions (restaurant_id, type, amount, description, employee_name) VALUES (?, ?, ?, ?, ?)',
        {restaurantId, transactionType, amount, description, employeeName})
    
    if Config.Debug then
        print('Logged transaction:')
        print('Restaurant:', restaurantId)
        print('Type:', transactionType)
        print('Amount:', amount)
        print('Description:', description)
        print('Employee:', employeeName)
    end
end

local function UpdateRestaurantMoney(restaurantId, amount)
    MySQL.update('UPDATE restaurant_accounts SET money = money + ? WHERE restaurant_id = ?',
        {amount, restaurantId})
    
    if Config.Debug then
        print('Updated restaurant money:')
        print('Restaurant:', restaurantId)
        print('Amount change:', amount)
    end
end

-----------------------------------------------------------------------
-- Restaurant Management
-----------------------------------------------------------------------

-- Initialize Restaurant Accounts
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    if Config.Debug then
        print('Initializing restaurant accounts')
    end
    
    for _, restaurant in pairs(Config.Restaurants) do
        MySQL.query('SELECT * FROM restaurant_accounts WHERE restaurant_id = ?', {restaurant.id},
            function(result)
                if not result[1] then
                    MySQL.insert('INSERT INTO restaurant_accounts (restaurant_id, money) VALUES (?, ?)',
                        {restaurant.id, 0})
                    if Config.Debug then
                        print('Created account for restaurant:', restaurant.id)
                    end
                end
            end
        )
    end
end)

-----------------------------------------------------------------------
-- Boss Menu Functions
-----------------------------------------------------------------------

-- Get Boss Menu Data
RegisterServerEvent('restaurant:server:getBossMenu')
AddEventHandler('restaurant:server:getBossMenu', function(restaurantId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if Config.Debug then
        print('Getting boss menu for restaurant:', restaurantId)
        print('Player:', src)
    end

    MySQL.query('SELECT money FROM restaurant_accounts WHERE restaurant_id = ?', {restaurantId},
        function(accountResult)
            if not accountResult[1] then
                TriggerClientEvent('restaurant:client:notify', src, {
                    title = 'Error',
                    description = 'Restaurant account not found',
                    type = 'error'
                })
                return
            end

            -- Get recent transactions
            MySQL.query('SELECT * FROM restaurant_transactions WHERE restaurant_id = ? ORDER BY timestamp DESC LIMIT 10',
                {restaurantId},
                function(transactionResult)
                    TriggerClientEvent('restaurant:client:showBossMenu', src, {
                        restaurantId = restaurantId,
                        balance = accountResult[1].money,
                        transactions = transactionResult
                    })
                end
            )
        end
    )
end)

-- Withdraw Money
RegisterServerEvent('restaurant:server:withdrawMoney')
AddEventHandler('restaurant:server:withdrawMoney', function(restaurantId, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Convert amount to number explicitly
    amount = tonumber(amount)
    
    if Config.Debug then
        print('Withdrawal request:')
        print('Restaurant:', restaurantId)
        print('Amount:', amount)
        print('Player:', src)
    end

    if not amount or amount <= 0 then
        TriggerClientEvent('restaurant:client:notify', src, {
            title = 'Error',
            description = 'Invalid amount',
            type = 'error'
        })
        return
    end

    -- Check if player is boss
    if not Player.PlayerData.job.isboss then
        TriggerClientEvent('restaurant:client:notify', src, {
            title = 'Error',
            description = 'Not authorized to withdraw money',
            type = 'error'
        })
        return
    end

    -- Verify restaurant and amount
    MySQL.query('SELECT money FROM restaurant_accounts WHERE restaurant_id = ?', {restaurantId},
        function(result)
            if not result[1] then
                TriggerClientEvent('restaurant:client:notify', src, {
                    title = 'Error',
                    description = 'Restaurant account not found',
                    type = 'error'
                })
                return
            end

            local currentBalance = tonumber(result[1].money)
            if not currentBalance or currentBalance < amount then
                TriggerClientEvent('restaurant:client:notify', src, {
                    title = 'Error',
                    description = 'Insufficient funds in restaurant account',
                    type = 'error'
                })
                return
            end

            -- Process withdrawal
            UpdateRestaurantMoney(restaurantId, -amount)
            Player.Functions.AddMoney('cash', amount, 'restaurant-withdrawal')
            
            -- Log transaction
            LogTransaction(
                restaurantId,
                'WITHDRAWAL',
                amount,
                'Money withdrawn by management',
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            )

            TriggerClientEvent('restaurant:client:notify', src, {
                title = 'Success',
                description = 'Withdrew $' .. string.format("%.2f", amount) .. ' from restaurant account',
                type = 'success'
            })

            -- Refresh boss menu
            TriggerEvent('restaurant:server:getBossMenu', restaurantId)
        end
    )
end)
-----------------------------------------------------------------------
-- Crafting System
-----------------------------------------------------------------------

-- Check Crafting Ingredients
RegisterServerEvent('restaurant:server:checkCraftingIngredients')
AddEventHandler('restaurant:server:checkCraftingIngredients', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local recipe = data.recipe
    local amount = data.amount
    local hasIngredients = true
    
    if Config.Debug then
        print('Checking ingredients for crafting:')
        print('Player:', src)
        print('Recipe:', json.encode(recipe))
        print('Amount:', amount)
    end

    -- Check if player has all required ingredients
    for _, ingredient in pairs(recipe.ingredients) do
        local playerItem = Player.Functions.GetItemByName(ingredient.item)
        local requiredAmount = ingredient.amount * amount
        
        if Config.Debug then
            print('Checking ingredient:', ingredient.item)
            print('Required amount:', requiredAmount)
            print('Player has:', playerItem and playerItem.amount or 0)
        end
        
        if not playerItem or playerItem.amount < requiredAmount then
            hasIngredients = false
            break
        end
    end

    if hasIngredients then
        -- Remove ingredients
        for _, ingredient in pairs(recipe.ingredients) do
            local removeAmount = ingredient.amount * amount
            Player.Functions.RemoveItem(ingredient.item, removeAmount)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[ingredient.item], "remove")
            
            if Config.Debug then
                print('Removed', removeAmount, 'x', ingredient.item)
            end
        end
        
        -- Start crafting process
        TriggerClientEvent('restaurant:client:doCrafting', src, data)
    else
        TriggerClientEvent('restaurant:client:notify', src, {
            title = 'Error',
            description = 'Missing required ingredients',
            type = 'error'
        })
    end
end)

-- Finish Crafting
RegisterServerEvent('restaurant:server:finishCrafting')
AddEventHandler('restaurant:server:finishCrafting', function(data)
    local src = source
    local restaurantId = data.restaurantId
    local item = data.item
    local amount = data.amount
    
    if Config.Debug then
        print('Finishing crafting:')
        print('Restaurant:', restaurantId)
        print('Item:', item)
        print('Amount:', amount)
    end
    
    -- Trigger client to get price input
    TriggerClientEvent('restaurant:client:getItemPrice', src, {
        restaurantId = restaurantId,
        item = item,
        amount = amount
    })
end)

-- Set Item Price and Add to Menu
RegisterServerEvent('restaurant:server:setItemPrice')
AddEventHandler('restaurant:server:setItemPrice', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local restaurantId = data.restaurantId
    local item = data.item
    local amount = data.amount
    local price = data.price

    if Config.Debug then
        print('Setting price for crafted item:')
        print('Restaurant:', restaurantId)
        print('Item:', item)
        print('Amount:', amount)
        print('Price:', price)
    end

    MySQL.query('SELECT * FROM restaurant_items WHERE restaurant_id = ? AND item = ?', 
        {restaurantId, item}, 
        function(result)
            if result[1] then
                -- Update existing stock and price
                MySQL.update('UPDATE restaurant_items SET stock = stock + ?, price = ? WHERE restaurant_id = ? AND item = ?',
                    {amount, price, restaurantId, item})
            else
                -- Add new item to stock
                MySQL.insert('INSERT INTO restaurant_items (restaurant_id, item, stock, price) VALUES (?, ?, ?, ?)',
                    {restaurantId, item, amount, price})
            end
            
            -- Log the crafting
            LogTransaction(
                restaurantId,
                'CRAFT',
                0, -- No money transaction for crafting
                string.format('Crafted %dx %s at $%.2f each', 
                    amount, 
                    RSGCore.Shared.Items[item].label,
                    price
                ),
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            )
            
            TriggerClientEvent('restaurant:client:notify', src, {
                title = 'Success',
                description = string.format('Crafted %dx %s at $%.2f each', 
                    amount, 
                    RSGCore.Shared.Items[item].label,
                    price
                ),
                type = 'success'
            })
        end
    )
end)

-----------------------------------------------------------------------
-- Menu Management
-----------------------------------------------------------------------

-- Add Item to Menu
RegisterServerEvent('restaurant:server:addToMenu')
AddEventHandler('restaurant:server:addToMenu', function(restaurantId, item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if Config.Debug then
        print('Adding item to menu:')
        print('Restaurant:', restaurantId)
        print('Item:', item)
        print('Amount:', amount)
        print('Price:', price)
    end
    
    -- Check if player has the items
    local playerItem = Player.Functions.GetItemByName(item)
    if not playerItem or playerItem.amount < amount then
        TriggerClientEvent('restaurant:client:notify', src, {
            title = 'Error',
            description = 'Not enough items',
            type = 'error'
        })
        return
    end
    
    -- Remove items from player
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
    
    -- Add to restaurant menu
    MySQL.query('SELECT * FROM restaurant_items WHERE restaurant_id = ? AND item = ?', 
        {restaurantId, item}, 
        function(result)
            if result[1] then
                -- Update existing stock
                MySQL.update('UPDATE restaurant_items SET stock = stock + ?, price = ? WHERE restaurant_id = ? AND item = ?',
                    {amount, price, restaurantId, item})
            else
                -- Insert new item
                MySQL.insert('INSERT INTO restaurant_items (restaurant_id, item, stock, price) VALUES (?, ?, ?, ?)',
                    {restaurantId, item, amount, price})
            end
            
            -- Log the addition
            LogTransaction(
                restaurantId,
                'STOCK_ADD',
                0, -- No money transaction for adding stock
                string.format('Added %dx %s to menu at $%.2f each', 
                    amount, 
                    RSGCore.Shared.Items[item].label,
                    price
                ),
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            )
            
            TriggerClientEvent('restaurant:client:notify', src, {
                title = 'Success',
                description = string.format('Added %dx %s to menu', 
                    amount, 
                    RSGCore.Shared.Items[item].label
                ),
                type = 'success'
            })
    end)
end)
-----------------------------------------------------------------------
-- Menu Display and Purchase System
-----------------------------------------------------------------------

-- Get Menu Items
RegisterServerEvent('restaurant:server:getMenuItems')
AddEventHandler('restaurant:server:getMenuItems', function(restaurantId)
    local src = source
    
    if Config.Debug then
        print('Getting menu items for restaurant:', restaurantId)
    end
    
    MySQL.query('SELECT * FROM restaurant_items WHERE restaurant_id = ?', {restaurantId},
        function(result)
            if result and #result > 0 then
                if Config.Debug then
                    print('Found', #result, 'menu items')
                end
                TriggerClientEvent('restaurant:client:showMenu', src, restaurantId, result)
            else
                TriggerClientEvent('restaurant:client:notify', src, {
                    title = 'Information',
                    description = 'No items available',
                    type = 'info'
                })
            end
        end
    )
end)

-- Purchase Item
RegisterServerEvent('restaurant:server:purchaseItem')
AddEventHandler('restaurant:server:purchaseItem', function(restaurantId, item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local totalPrice = price * amount
    
    if Config.Debug then
        print('Processing purchase:')
        print('Restaurant:', restaurantId)
        print('Item:', item)
        print('Amount:', amount)
        print('Total Price:', totalPrice)
    end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('cash') < totalPrice then
        TriggerClientEvent('restaurant:client:notify', src, {
            title = 'Error',
            description = 'Not enough money',
            type = 'error'
        })
        return
    end
    
    -- Check stock
    MySQL.query('SELECT stock FROM restaurant_items WHERE restaurant_id = ? AND item = ?', 
        {restaurantId, item},
        function(result)
            if not result[1] or result[1].stock < amount then
                TriggerClientEvent('restaurant:client:notify', src, {
                    title = 'Error',
                    description = 'Not enough stock',
                    type = 'error'
                })
                return
            end
            
            -- Update stock
            MySQL.update('UPDATE restaurant_items SET stock = stock - ? WHERE restaurant_id = ? AND item = ?',
                {amount, restaurantId, item})
            
            -- Update restaurant money
            UpdateRestaurantMoney(restaurantId, totalPrice)
            
            -- Remove money from player
            Player.Functions.RemoveMoney('cash', totalPrice, "restaurant-purchase")
            
            -- Give item to player
            Player.Functions.AddItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "add")
            
            -- Log the transaction
            LogTransaction(
                restaurantId,
                'SALE',
                totalPrice,
                string.format('Sold %dx %s at $%.2f each', 
                    amount, 
                    RSGCore.Shared.Items[item].label,
                    price
                ),
                'Customer Purchase'
            )
            
            if Config.Debug then
                print('Purchase completed successfully')
            end
            
            TriggerClientEvent('restaurant:client:notify', src, {
                title = 'Success',
                description = string.format('Purchased %dx %s for $%.2f', 
                    amount, 
                    RSGCore.Shared.Items[item].label,
                    totalPrice
                ),
                type = 'success'
            })
    end)
end)

-----------------------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------------------

-- Get Restaurant Balance
RSGCore.Functions.CreateCallback('restaurant:server:getBalance', function(source, cb, restaurantId)
    MySQL.query('SELECT money FROM restaurant_accounts WHERE restaurant_id = ?', {restaurantId},
        function(result)
            if result[1] then
                cb(result[1].money)
            else
                cb(0)
            end
        end
    )
end)

-- Get Restaurant Transactions
RSGCore.Functions.CreateCallback('restaurant:server:getTransactions', function(source, cb, restaurantId)
    MySQL.query('SELECT * FROM restaurant_transactions WHERE restaurant_id = ? ORDER BY timestamp DESC LIMIT 50', 
        {restaurantId},
        function(result)
            cb(result)
        end
    )
end)

-- Check Restaurant Authorization
RSGCore.Functions.CreateCallback('restaurant:server:isAuthorized', function(source, cb, restaurantId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return
    end

    for _, restaurant in pairs(Config.Restaurants) do
        if restaurant.id == restaurantId and Player.PlayerData.job.name == restaurant.job then
            cb(true)
            return
        end
    end
    
    cb(false)
end)

-- Event handler for resource start
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then 
        return 
    end
    
    if Config.Debug then
        print('Resource started:', resourceName)
        print('Checking version...')
    end
    
    CheckVersion()
    
    -- Initialize database tables if needed
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS restaurant_accounts (
            restaurant_id VARCHAR(50) PRIMARY KEY,
            money DECIMAL(10,2) NOT NULL DEFAULT 0.00
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS restaurant_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            restaurant_id VARCHAR(50) NOT NULL,
            type VARCHAR(20) NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            description TEXT NOT NULL,
            employee_name VARCHAR(100) NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    if Config.Debug then
        print('Database tables verified')
    end
end)

-- Export functions for other resources
exports('getRestaurantBalance', function(restaurantId)
    local promise = promise.new()
    
    MySQL.query('SELECT money FROM restaurant_accounts WHERE restaurant_id = ?', 
        {restaurantId},
        function(result)
            if result[1] then
                promise:resolve(result[1].money)
            else
                promise:resolve(0)
            end
        end
    )
    
    return Citizen.Await(promise)
end)

-- Check Version on Resource Start
CheckVersion()