local RSGCore = exports['rsg-core']:GetCoreObject()

-- get shop items
RegisterServerEvent('pure-saloontendershop:server:GetShopItems')
AddEventHandler('pure-saloontendershop:server:GetShopItems', function(data)
    local src = source
    MySQL.query('SELECT * FROM saloontendershop_stock WHERE shopid = ?', {data.id}, function(data2)
        MySQL.query('SELECT * FROM saloontender_shop WHERE shopid = ?', {data.id}, function(data3)
            TriggerClientEvent('pure-saloontendershop:client:ReturnStoreItems', src, data2, data3)
        end)
    end)
end)

-- shop stock
RSGCore.Functions.CreateCallback('pure-saloontendershop:server:shopS', function(source, cb, currentsaloonshop)
    MySQL.query('SELECT * FROM saloontender_shop WHERE shopid = ?', {currentsaloonshop}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

-- get saloontender stock items
RSGCore.Functions.CreateCallback('pure-saloontendershop:server:Stock', function(source, cb, playerjob)
    MySQL.query('SELECT * FROM saloontender_stock WHERE saloontender = ?', { playerjob }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

-- refill stock
RegisterServerEvent('pure-saloontendershop:server:InvReFill')
AddEventHandler('pure-saloontendershop:server:InvReFill', function(location, item, qt, price, job)
    local src = source
    MySQL.query('SELECT * FROM saloontendershop_stock WHERE shopid = ? AND items = ?',{location, item} , function(result)
        if result[1] ~= nil then
            local stockadd = result[1].stock + tonumber(qt)
            MySQL.update('UPDATE saloontendershop_stock SET stock = ?, price = ? WHERE shopid = ? AND items = ?',{stockadd, price, location, item})
        else
            MySQL.insert('INSERT INTO saloontendershop_stock (`shopid`, `items`, `stock`, `price`) VALUES (?, ?, ?, ?);',{location, item, qt, price})
        end
    end)
    MySQL.query('SELECT * FROM saloontender_stock WHERE saloontender = ? AND item = ?',{job, item} , function(result)
        if result[1] ~= nil then
            local stockremove = result[1].stock - tonumber(qt)
            MySQL.update('UPDATE saloontender_stock SET stock = ? WHERE saloontender = ? AND item = ?',{stockremove, job, item})
        else
            MySQL.insert('INSERT INTO saloontender_stock (`saloontender`, `item`, `stock`) VALUES (?, ?, ?);', {job, item, qt})
        end
    end)
    TriggerClientEvent('ox_lib:notify', src, {title = 'Success', description = Lang:t('lang_s26'), type = 'success', duration = 5000 })
end)

-- purchase item
RegisterServerEvent('pure-saloontendershop:server:PurchaseItem')
AddEventHandler('pure-saloontendershop:server:PurchaseItem', function(location, item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM saloontendershop_stock WHERE shopid = ? AND items = ?',{location, item} , function(data)
        local stock = data[1].stock - amount
        local price = data[1].price * amount   
        local currentMoney = Player.Functions.GetMoney('cash')
        if price <= currentMoney then
            MySQL.update("UPDATE saloontendershop_stock SET stock=@stock WHERE shopid=@location AND items=@item", {['@stock'] = stock, ['@location'] = location, ['@item'] = item}, function(count)
                if count > 0 then
                    Player.Functions.RemoveMoney("cash", price, "market")
                    Player.Functions.AddItem(item, amount)
                    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "add")
                    MySQL.query("SELECT * FROM saloontender_shop WHERE shopid=@location", { ['@location'] = location }, function(data2)
                        local moneymarket = data2[1].money + price
                        MySQL.update('UPDATE saloontender_shop SET money = ? WHERE shopid = ?',{moneymarket, location})
                    end)
                    TriggerClientEvent('ox_lib:notify', src, {title = Lang:t('lang_s27'), description = amount.."x "..RSGCore.Shared.Items[item].label, type = 'success', duration = 5000 })
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = Lang:t('lang_s28'), type = 'error', duration = 5000 })
        end
    end)
end)

-- get money
RSGCore.Functions.CreateCallback('pure-saloontendershop:server:GetMoney', function(source, cb, currentsaloonshop)
    MySQL.query('SELECT * FROM saloontender_shop WHERE shopid = ?', {currentsaloonshop}, function(checkmoney)
        if checkmoney[1] then
            cb(checkmoney[1])
        else
            cb(nil)
        end
    end)
end)

-- withdraw money
RegisterServerEvent('pure-saloontendershop:server:Withdraw')
AddEventHandler('pure-saloontendershop:server:Withdraw', function(location, smoney)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM saloontender_shop WHERE shopid = ?',{location} , function(result)
        if result[1] ~= nil then
            if result[1].money >= tonumber(smoney) then
                local nmoney = result[1].money - smoney
                MySQL.update('UPDATE saloontender_shop SET money = ? WHERE shopid = ?',{nmoney, location})
                Player.Functions.AddMoney('cash', smoney)
            else
                --Notif
            end
        end
    end)
end)
