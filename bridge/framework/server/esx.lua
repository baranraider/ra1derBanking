if GetResourceState('es_extended') ~= 'started' then
    print("^1[esx-bridge] ESX not detected switching to QB")
    return
end

local ESX = exports['es_extended']:getSharedObject()

local function buildPlayerData(xPlayer)
    if not xPlayer then return nil end

    return {
        source    = xPlayer.source,
        citizenid = xPlayer.identifier,
        license   = xPlayer.license,
        job       = { name = xPlayer.job.name },
        firstname = xPlayer.firstName,
        lastname  = xPlayer.lastName,
        gender    = xPlayer.sex == 0 and "Male" or "Female"
    }
end

GetPlayerData = function(source)
    return buildPlayerData(ESX.GetPlayerFromId(source))
end

GetPlayerByCitizenId = function(identifier)
    return buildPlayerData(ESX.GetPlayerFromIdentifier(identifier))
end

local function resolveAccount(type)
    return type == "cash" and "money" or "bank"
end

GetPlayerMoney = function(source, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end

    local account = resolveAccount(type)
    local accData = xPlayer.getAccount(account)

    return accData and accData.money or 0
end

AddPlayerMoney = function(source, type, amount, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    xPlayer.addAccountMoney(resolveAccount(type), amount, reason)
    return true
end

RemovePlayerMoney = function(source, type, amount, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local account = resolveAccount(type)
    local accData = xPlayer.getAccount(account)

    if not accData or accData.money < amount then
        return false
    end

    xPlayer.removeAccountMoney(account, amount, reason)
    return true
end