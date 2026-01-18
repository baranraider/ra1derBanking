local QBCore = exports['qb-core']:GetCoreObject()
local TransactionTable = {}
local PendingTransactions = {}

function Round(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

	return left..(num:reverse():gsub('(%d%d%d)','%1' ..","):reverse())..right
end

function addTransaction(src, identifier, amount, reason, type)
    local tx = {
        identifier = identifier,
        amount = amount,
        title = reason,
        type = type,
        created_at = os.date("%Y-%m-%d %H:%M:%S"),
        runtime = true
    }

    table.insert(TransactionTable, tx)
    table.insert(PendingTransactions, tx)

    local lastTransactions = getLastTransactionsByIdentifier(identifier, 5)
    TriggerClientEvent("ra1derBanking:client:updateTransactionsUI", src, lastTransactions)
end

function getLastTransactionsByIdentifier(identifier, limit)
    local result = {}
    limit = limit or 5

    for i = #TransactionTable, 1, -1 do
        local tx = TransactionTable[i]

        if tx.identifier == identifier then
            table.insert(result, {
                title = tx.title,
                time = tx.created_at,
                amount = tx.amount,
                type = tx.type
            })
        end

        if #result >= limit then break end
    end

    return result
end


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local rows = MySQL.query.await(
        "SELECT identifier, title, amount, type, created_at FROM ra1derbank_transactions ORDER BY created_at DESC LIMIT 5"
    )

    for i = #rows, 1, -1 do
        local v = rows[i]
        table.insert(TransactionTable, {
            identifier = v.identifier,
            title = v.title,
            amount = v.amount,
            type = v.type,
            created_at = v.created_at,
            runtime = false
        })
    end
end)


AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, tx in ipairs(PendingTransactions) do
        MySQL.insert.await(
            "INSERT INTO ra1derbank_transactions (identifier, title, amount, type, created_at) VALUES (?, ?, ?, ?, ?)",
            {
                tx.identifier,
                tx.title,
                tx.amount,
                tx.type,
                tx.created_at
            }
        )
    end
end)


lib.callback.register('ra1derBanking:server:getBankData', function(source)
    local src = source
    local playerData = GetPlayerData(src)
    if not playerData then return {} end

    local transactions = {}

    for i = #TransactionTable, 1, -1 do
        local tx = TransactionTable[i]

        if tx.identifier == playerData.citizenid then
            table.insert(transactions, {
                title = tx.title,
                time = tx.created_at,
                amount = tx.amount,
                type = tx.type
            })
        end

        if #transactions >= 5 then break end
    end

    local bills = MySQL.query.await(
        "SELECT id, sender, recipient_label, amount FROM vivum_invoices WHERE recipient = ? ORDER BY timestamp DESC LIMIT 5",
        { playerData.citizenid }
    )

    local billsData = {}
    for _, bill in pairs(bills or {}) do
        billsData[#billsData + 1] = {
            id = bill.id,
            title = bill.sender,
            description = bill.recipient_label,
            amount = bill.amount
        }
    end

    return {
        username = playerData.firstname .. " " .. playerData.lastname,
        accountId = playerData.citizenid,
        balance = GetPlayerMoney(src, "bank"),
        transactions = transactions,
        bills = billsData
    }
end)


lib.callback.register('ra1derBanking:server:getBills', function()
    local billsData = {}

    local src = source
    local playerData = GetPlayerData(src)

    if playerData then
        local bills = MySQL.Sync.fetchAll(
                          "SELECT * FROM vivum_invoices WHERE recipient = ? ORDER BY timestamp DESC LIMIT 5",
                          {playerData.citizenid})
        if bills ~= nil then
            for _, bill in pairs(bills) do
                table.insert(billsData, {
                    id = bill.id,
                    title = bill.sender,
                    description = bill.recipient_label,
                    amount = bill.amount
                })
            end
        end
    end

    return billsData
end)

lib.callback.register('ra1derBanking:server:updateBalance', function()
    local src = source
    return GetPlayerMoney(src, "bank")
end)

lib.callback.register('ra1derBanking:server:validateReceiver', function(_, citizenid)
    local targetData = GetPlayerByCitizenId(citizenid)
    if targetData.firstname == nil then
        local targetSql = MySQL.Sync.fetchAll("SELECT charinfo FROM players WHERE citizenid = ?", {citizenid})

        if targetSql[1].charinfo ~= nil then
            local targetCharinfo = json.decode(targetSql[1].charinfo)

            targetData = {
                firstname = targetCharinfo.firstname,
                lastname = targetCharinfo.lastname,
                gender = targetCharinfo.gender == 0 and "Male" or "Female"
            }
        else
            return nil
        end
    end

    return {
        firstname = targetData.firstname,
        lastname  = targetData.lastname,
        gender    = targetData.gender
    }
end)

RegisterNetEvent("ra1derBanking:server:transferMoney", function(amount, reason, citizenid)
    local src = source
    local sender = GetPlayerData(src)
    if not sender then return end

    if sender.citizenid == citizenid then
        TriggerClientEvent("ra1derBanking:client:Notify", src, "Kendine para gönderemezsin!", "error")
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if not reason or reason == "" then return end

    local target = GetPlayerByCitizenId(citizenid)
    if target and target.source then
        local senderReason =
            target.firstname .. " " .. target.lastname .. " - " .. reason

        if not RemovePlayerMoney(src, "bank", amount, senderReason) then
            TriggerClientEvent("ra1derBanking:client:Notify", src, "Bankada yeterli para yok!", "error")
            return
        end

        local receiverReason =
            sender.firstname .. " " .. sender.lastname .. " - " .. reason

        AddPlayerMoney(target.source, "bank", amount, receiverReason)

        addTransaction(sender.source, sender.citizenid, amount, senderReason, "expense")
        addTransaction(target.source, target.citizenid, amount, receiverReason, "income")

        -- UI Updates
        TriggerClientEvent("ra1derBanking:client:updateBankData", src, "transaction")
        TriggerClientEvent("ra1derBanking:client:updateBankData", target.source, "transaction")

        TriggerClientEvent("ra1derBanking:client:Notify", src, target.firstname .. " " .. target.lastname.. " Kişisine " ..amount.. "$ Gönderildi!", "success")
        TriggerClientEvent("ra1derBanking:client:Notify", target.source,
            sender.firstname .. " " .. sender.lastname .. " sana " ..amount.. "$ para gönderdi", "success"
        )

        if GetResourceState("lb-phone") ~= "missing" then
            local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(target.source)
            exports["lb-phone"]:AddTransaction(phoneNumber, amount, sender.firstname .. " " .. sender.lastname, nil)
        end

        return
    end

    local rows = MySQL.Sync.fetchAll(
        "SELECT money, charinfo FROM players WHERE citizenid = ?",
        { citizenid }
    )

    if not rows or not rows[1] then
        TriggerClientEvent("ra1derBanking:client:Notify", src, "Alıcı bulunamadı!", "error")
        return
    end

    local charinfo = json.decode(rows[1].charinfo)
    local senderReason =
        charinfo.firstname .. " " .. charinfo.lastname .. " - " .. reason

    if not RemovePlayerMoney(src, "bank", amount, senderReason) then
        TriggerClientEvent("ra1derBanking:client:Notify", src, "Bankada yeterli para yok!", "error")
        return
    end

    local money = json.decode(rows[1].money)
    money.bank = (money.bank or 0) + amount

    MySQL.Async.execute(
        "UPDATE players SET money = ? WHERE citizenid = ?",
        { json.encode(money), citizenid }
    )

    local receiverReason =
        sender.firstname .. " " .. sender.lastname .. " - " .. reason

    addTransaction(sender.source, sender.citizenid, amount, senderReason, "expense")
    addTransaction(src, citizenid, amount, receiverReason, "income")

    TriggerClientEvent("ra1derBanking:client:updateBankData", src, "transaction")
    TriggerClientEvent("ra1derBanking:client:Notify", src, "Para gönderildi!", "success")
end)


RegisterNetEvent("ra1derBanking:server:depositMoney", function(amount, reason)
    local src = source
    local player = GetPlayerData(src)
    if not player then return end

    if RemovePlayerMoney(src, "cash", amount, reason) then
        if AddPlayerMoney(src, "bank", amount, reason) then
            addTransaction(player.source, player.citizenid, amount, reason, "income")

            TriggerClientEvent("ra1derBanking:client:Notify", src, "Banka hesabınıza " ..Round(amount).. "$ yatırıldı!", "success")
            TriggerClientEvent("ra1derBanking:client:updateBankData", src, "transaction")
        else
            TriggerClientEvent("ra1derBanking:client:Notify", src, "Para yatırılamadı!", "error")
        end
    else
        TriggerClientEvent("ra1derBanking:client:Notify", src, "Üzerinde yeterli para yok!", "error")
    end
end)


RegisterNetEvent("ra1derBanking:server:withdrawMoney", function(amount, reason)
    local src = source
    local player = GetPlayerData(src)
    if not player then return end

    if RemovePlayerMoney(src, "bank", amount, reason) then
        if AddPlayerMoney(src, "cash", amount, reason) then
            addTransaction(player.source, player.citizenid, amount, reason, "expense")

            TriggerClientEvent("ra1derBanking:client:Notify", src, "Banka hesabınızdan " ..Round(amount).. "$ para çekildi!", "success")
            TriggerClientEvent("ra1derBanking:client:updateBankData", src, "transaction")
        else
            TriggerClientEvent("ra1derBanking:client:Notify", src, "Para çekilemedi!", "error")
        end
    else
        TriggerClientEvent("ra1derBanking:client:Notify", src, "Bankada yeterli para yok!", "error")
    end
end)


RegisterNetEvent("ra1derBanking:server:payBill", function(billId)
    local src = source
    local bill = MySQL.Sync.fetchAll("SELECT recipient_label, amount FROM vivum_invoices WHERE id = ?", {billId})
    bill = bill[1]
    local deposit = RemovePlayerMoney(src, "bank", bill.amount, bill.recipient_label)
    if deposit then
        MySQL.Sync.execute("DELETE FROM vivum_invoices WHERE id = ?", {billId})
        TriggerClientEvent("ra1derBanking:client:Notify", src, bill.recipient_label.. " isimli " ..Round(bill.amount).. "$ tutarındaki fatura ödendi!", "success")
        TriggerClientEvent("ra1derBanking:client:updateBankData", src, "bill")
        return
    end

    TriggerClientEvent("ra1derBanking:client:Notify", src, "Bankada yeterli para yok!", "error")
end)

QBCore.Commands.Add('faturas', 'Help Text', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent("ra1derBase:client:CreateBilling", source, {
        citizenid = Player.PlayerData.citizenid,
        amount = 1000,
        sender_label = "St. Fiacre Hastanesi",
        reason = "Tedavi Ücreti"
    })
end, 'god')