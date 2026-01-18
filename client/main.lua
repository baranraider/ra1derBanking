function getConfig()
    local resourceName = GetCurrentResourceName()
    local raw = LoadResourceFile(resourceName, "config/language.json")
    if not raw then
        error("[ra1derBanking] language.json couldnt load!")
    end

    local langData = json.decode(raw)

    local activeLang = langData.language
    local translations = langData.translations or {}

    if not translations then
        error("[ra1derBanking] language dosyası bulunamadı")
    end

    Config.Language = translations[activeLang]
    SendNUIMessage({
        action = "setLanguage",
        language = activeLang
    })
    
    SendNUIMessage({
        action = "setLangTexts",
        texts = translations
    })
end

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            getConfig()
            break
        end
        Wait(250)
    end
end)

function updateTransactions(transactions)
   SendNUIMessage({
        action = "setTransactions",
        transactions = transactions
    })
end

function removeBill(billId)
   SendNUIMessage({
        action = "removeBill",
        billId = billId
    })
end

function updateBills()
    local bills = lib.callback.await("ra1derBanking:server:getBills", false)

    SendNUIMessage({
        action = "setBills",
        bills = bills
    })
end

function updateBalance()
    local balance = lib.callback.await("ra1derBanking:server:updateBalance", false)

    SendNUIMessage({
        action = "updateBalance",
        balance = balance
    })
end

function openUI()
    CreateThread(function()
        getConfig()
        bankAnimationEnter()
    end)
    CreateThread(function()
        local bankData = lib.callback.await("ra1derBanking:server:getBankData", false)
            
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            payload = {
                username = bankData.username,
                accountId = bankData.accountId,
                balance = bankData.balance,
                transactions = bankData.transactions,
                bills = bankData.bills,
                quickNumbers = Config.quickNumbers
            }
        })
        bankAnimationIdle()
    end)
end


function closeUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close",
    })
    Wait(500)
    stopAnimation()
end

function loadAnimDict(dict)
    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do        
        Wait(1)
    end
end

RegisterNUICallback("close", function(_, cb)
    closeUI()

    cb("ok")
end)

RegisterNUICallback("deposit", function(data, cb)
    TriggerServerEvent("ra1derBanking:server:depositMoney", data.amount, data.reason)
    TriggerEvent("ra1derBanking:Notify",data.amount.. " Para Yatırma İşlemi Başarılı", "success", 15000)
    cb("ok")
end)

RegisterNUICallback("withdraw", function(data, cb)
    TriggerServerEvent("ra1derBanking:server:withdrawMoney", data.amount, data.reason)
    TriggerEvent("ra1derBanking:Notify", data.amount.. " Para Çekme İşlemi Başarılı", "success", 15000)
    cb("ok")
end)

RegisterNUICallback("payBill", function(data, cb)
    TriggerServerEvent("ra1derBanking:server:payBill", data.billId)
    TriggerEvent("ra1derBanking:Notify", 
        "LS Banking",
        data.billId.. " ID'li Fatura Ödendi",
        "universal_currency_alt",
        15000
    )
    cb("ok")
end)

RegisterNUICallback("validateReceiver", function(data, cb)
    local info = lib.callback.await("ra1derBanking:server:validateReceiver", false, data.citizenid)

    cb(info)
end)

RegisterNUICallback("transfer", function(data, cb)
    print(data.receiver)
    TriggerServerEvent("ra1derBanking:server:transferMoney", data.amount, data.reason, data.receiver)
    cb("ok")
end)

RegisterNetEvent("ra1derBanking:client:updateBankData", function(type)
    if type == "bill" then
        updateBills()
    end

    updateBalance()
end)

RegisterNetEvent("ra1derBanking:client:removeBill", function(billId)
    removeBill(billId)
end)

RegisterNetEvent("ra1derBanking:client:updateTransactionsUI", function(transactions)
    updateTransactions(transactions)
end)