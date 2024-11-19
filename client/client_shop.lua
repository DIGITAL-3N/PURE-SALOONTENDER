local RSGCore = exports['rsg-core']:GetCoreObject()
local currentsaloonshop = nil
local currentjob = nil
local isboss = nil

-------------------------------------------------------------------------------------------
-- prompts and blips
-------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.SaloonShops) do
        exports['rsg-core']:createPrompt(v.shopid, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], Lang:t('lang_s1'), {
            type = 'client',
            event = 'pure-saloontendershop:client:saloonshopMenu',
            args = { v.jobaccess, v.shopid },
        })
        if v.showblip == true then
            local SaloonShopBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
            SetBlipSprite(SaloonShopBlip,  joaat(Config.ShopBlip.blipSprite), true)
            SetBlipScale(Config.ShopBlip.blipScale, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, SaloonShopBlip, Config.ShopBlip.blipName)
        end
    end
end)

-------------------------------------------------------------------------------------------
-- menu
-------------------------------------------------------------------------------------------

RegisterNetEvent('pure-saloontendershop:client:saloonshopMenu', function(jobaccess, shopid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    currentsaloonshop = shopid
    currentjob = PlayerData.job.name
    isboss = PlayerData.job.isboss
    if currentjob == jobaccess and isboss == true then
        lib.registerContext({
            id = 'saloon_owner_shop_menu',
            title = Lang:t('lang_s2'),
            options = {
                {
                    title = Lang:t('lang_s3'),
                    description = Lang:t('lang_s4'),
                    icon = 'fa-solid fa-store',
                    serverEvent = 'pure-saloontendershop:server:GetShopItems',
                    args = { id = shopid },
                    arrow = true
                },
                {
                    title = Lang:t('lang_s5'),
                    description = Lang:t('lang_s6'),
                    icon = 'fa-solid fa-boxes-packing',
                    event = 'pure-saloontendershop:client:InvReFull',
                    args = { },
                    arrow = true
                },
                {
                    title = Lang:t('lang_s7'),
                    description = Lang:t('lang_s8'),
                    icon = 'fa-solid fa-sack-dollar',
                    event = 'pure-saloontendershop:client:CheckMoney',
                    args = { },
                    arrow = true
                },
            }
        })
        lib.showContext("saloon_owner_shop_menu")
    else
        lib.registerContext({
            id = 'saloon_customer_shop_menu',
            title = Lang:t('lang_s9'),
            options = {
                {
                    title = Lang:t('lang_s10'),
                    description = Lang:t('lang_s11'),
                    icon = 'fa-solid fa-store',
                    serverEvent = 'pure-saloontendershop:server:GetShopItems',
                    args = { id = shopid  },
                    arrow = true
                },
            }
        })
        lib.showContext("saloon_customer_shop_menu")
    end
end)

-------------------------------------------------------------------------------------------
-- get shop items
-------------------------------------------------------------------------------------------
RegisterNetEvent('pure-saloontendershop:client:ReturnStoreItems')
AddEventHandler('pure-saloontendershop:client:ReturnStoreItems', function(data2, data3)
    store_inventory = data2
    Wait(100)
    TriggerEvent('pure-saloontendershop:client:Inv', store_inventory, data3)
end)

-- saloon inventory
RegisterNetEvent("pure-saloontendershop:client:Inv", function(store_inventory, data)
    RSGCore.Functions.TriggerCallback('pure-saloontendershop:server:shopS', function(result)
        local options = {}
        for k, v in ipairs(store_inventory) do
            if store_inventory[k].stock > 0 then
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[store_inventory[k].items].label,
                    description = 'Stock: '..store_inventory[k].stock..' | '..Lang:t('lang_s12')..string.format("%.2f", store_inventory[k].price),
                    icon = "nui://"..Config.Img..RSGCore.Shared.Items[store_inventory[k].items].image,
                    event = 'pure-saloontendershop:client:InvInput',
                    args = store_inventory[k],
                    arrow = true,
                }
            end
        end
        lib.registerContext({
            id = 'saloon_shopinv_menu',
            title = Lang:t('lang_s13'),
            position = 'top-right',
            options = options
        })
        lib.showContext('saloon_shopinv_menu')
    end, currentsaloonshop)
end)

-------------------------------------------------------------------------------------------
-- refill
-------------------------------------------------------------------------------------------
RegisterNetEvent("pure-saloontendershop:client:InvReFull", function()
    RSGCore.Functions.TriggerCallback('pure-saloontendershop:server:Stock', function(result)
        if result == nil then
            lib.registerContext({
                id = 'saloon_no_inventory',
                title = Lang:t('lang_s14'),
                menu = 'saloon_owner_shop_menu',
                onBack = function() end,
                options = {
                    {
                        title = Lang:t('lang_s29'),
                        description = Lang:t('lang_s30'),
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext("saloon_no_inventory")
        else
            local options = {}
            for k, v in ipairs(result) do
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[result[k].item].label,
                    description = 'inventory amount : '..result[k].stock,
                    icon = 'fa-solid fa-box',
                    event = 'pure-saloontendershop:client:InvReFillInput',
                    args = {
                        item = result[k].item,
                        label = RSGCore.Shared.Items[result[k].item].label,
                        stock = result[k].stock
                    },
                    arrow = true,
                }
            end
            lib.registerContext({
                id = 'saloon_inv_menu',
                title = Lang:t('lang_s14'),
                menu = 'saloon_owner_shop_menu',
                onBack = function() end,
                position = 'top-right',
                options = options
            })
            lib.showContext('saloon_inv_menu')
        end
    end, currentjob)
end)

-------------------------------------------------------------------------------------------
-- add items from inventory
-------------------------------------------------------------------------------------------
RegisterNetEvent('pure-saloontendershop:client:InvReFillInput', function(data)
    local item = data.item
    local label = data.label
    local stock = data.stock
    local input = lib.inputDialog(Lang:t('lang_s31').." : "..label, {
        { 
            label = Lang:t('lang_s15'),
            description = Lang:t('lang_s16'),
            type = 'number',
            required = true,
            icon = 'hashtag'
        },
        { 
            label = Lang:t('lang_s17'),
            description = Lang:t('lang_s18'),
            default = '0.10',
            type = 'input',
            required = true,
            icon = 'fa-solid fa-dollar-sign'
        },
    })
    
    if not input then
        return
    end
    
    if stock >= tonumber(input[1]) and tonumber(input[2]) ~= nil then
        TriggerServerEvent('pure-saloontendershop:server:InvReFill', currentsaloonshop, item, input[1], tonumber(input[2]), currentjob)
    else
        lib.notify({ title = 'Error', description = Lang:t('lang_s19'), type = 'error', duration = 5000 })
    end
end)

-------------------------------------------------------------------------------------------
-- buy items
-------------------------------------------------------------------------------------------
RegisterNetEvent('pure-saloontendershop:client:InvInput', function(data)
    local name = data.items
    local price = data.price
    local stock = data.stock
    local input = lib.inputDialog(RSGCore.Shared.Items[name].label.." | $"..string.format("%.2f", price).." | Stock: "..stock, {
        { 
            label = Lang:t('lang_s15'),
            type = 'number',
            required = true,
            icon = 'hashtag'
        },
    })
    
    if not input then
        return
    end
    
    if stock >= tonumber(input[1]) then
        TriggerServerEvent('pure-saloontendershop:server:PurchaseItem', currentsaloonshop, name, input[1])
    else
        lib.notify({ title = 'Error', description = Lang:t('lang_s20'), type = 'error', duration = 5000 })
    end
end)

-------------------------------------------------------------------------------------------
-- money
-------------------------------------------------------------------------------------------
RegisterNetEvent("pure-saloontendershop:client:CheckMoney", function()
    RSGCore.Functions.TriggerCallback('pure-saloontendershop:server:GetMoney', function(checkmoney)
        RSGCore.Functions.TriggerCallback('pure-saloontendershop:server:shopS', function(result)
            lib.registerContext({
                id = 'money_menu',
                title = Lang:t('lang_s21') ..string.format("%.2f", checkmoney.money),
                menu = 'saloon_owner_shop_menu',
                onBack = function() end,
                options = {
                    {
                        title = Lang:t('lang_s22'),
                        description = Lang:t('lang_s23'),
                        icon = 'fa-solid fa-money-bill-transfer',
                        event = 'pure-saloontendershop:client:Withdraw',
                        args = checkmoney,
                        arrow = true
                    },
                }
            })
            lib.showContext("money_menu")
        end, currentsaloonshop)
    end, currentsaloonshop)
end)

-------------------------------------------------------------------------------------------
-- withdraw money
-------------------------------------------------------------------------------------------
RegisterNetEvent('pure-saloontendershop:client:Withdraw', function(checkmoney)
    local money = checkmoney.money
    local input = lib.inputDialog(Lang:t('lang_s24')..string.format("%.2f", money), {
        { 
            label = Lang:t('lang_s25'),
            type = 'input',
            required = true,
            icon = 'fa-solid fa-dollar-sign'
        },
    })
    
    if not input then
        return
    end
    
    if tonumber(input[1]) == nil then
        return
    end

    if money >= tonumber(input[1]) then
        TriggerServerEvent('pure-saloontendershop:server:Withdraw', currentsaloonshop, tonumber(input[1]))
    else
        lib.notify({ title = 'Error', description = Lang:t('lang_s20'), type = 'error', duration = 5000 })
    end
end)
