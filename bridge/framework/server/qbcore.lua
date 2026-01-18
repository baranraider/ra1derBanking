if GetResourceState('qb-core') ~= 'started' then
    print("^1[qb-bridge] QBCore not detected switching to ESX")
    return
end

local QBCore = exports['qb-core']:GetCoreObject()

local function buildPlayerData(Player)
    if not Player then return nil end

    local charinfo = Player.PlayerData.charinfo

    return {
        source    = Player.PlayerData.source,
        citizenid = Player.PlayerData.citizenid,
        license   = Player.PlayerData.license,
        job       = { name = Player.PlayerData.job.name },
        firstname = charinfo.firstname,
        lastname  = charinfo.lastname,
        gender    = charinfo.gender == 0 and "Male" or "Female"
    }
end

GetPlayerData = function(source)
    return buildPlayerData(QBCore.Functions.GetPlayer(source))
end

GetPlayerByCitizenId = function(citizenid)
    return buildPlayerData(QBCore.Functions.GetPlayerByCitizenId(citizenid))
end

GetPlayerMoney = function(source, account)
    local Player = QBCore.Functions.GetPlayer(source)
    return Player and Player.Functions.GetMoney(account) or 0
end

AddPlayerMoney = function(source, account, amount, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    Player.Functions.AddMoney(account, amount, reason)
    return true
end

RemovePlayerMoney = function(source, account, amount, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    if Player.Functions.GetMoney(account) < amount then
        return false
    end

    Player.Functions.RemoveMoney(account, amount, reason)
    return true
end