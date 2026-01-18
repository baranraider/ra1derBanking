if GetResourceState('qb-core') ~= 'started' then
	return 
end

QBCore = exports['qb-core']:GetCoreObject()
PlayerData, PlayerGroup = {}, {}

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    while QBCore.Functions.GetPlayerData() == nil do
        Wait(1)
    end
    PlayerData = QBCore.Functions.GetPlayerData()

	PlayerData.firstname = PlayerData.charinfo.firstname
	PlayerData.lastname = PlayerData.charinfo.lastname

	Wait(100)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function()
    PlayerData = QBCore.Functions.GetPlayerData()
	
	PlayerData.firstname = PlayerData.charinfo.firstname
	PlayerData.lastname = PlayerData.charinfo.lastname
end)

CreateThread(function()
    while true do
        if LocalPlayer.state['isLoggedIn'] then
            while QBCORE == nil do
                Wait(1)
                QBCORE = exports['qb-core']:GetCoreObject()
            end
            PlayerData = QBCORE.Functions.GetPlayerData()
    
            if PlayerData.charinfo ~= nil then
                PlayerData.firstname = PlayerData.charinfo.firstname
                PlayerData.lastname = PlayerData.charinfo.lastname
            end
    
            if PlayerData.identifier == nil then
                PlayerData.identifier = PlayerData.citizenid
            end
            Wait(100)
            break
        end
        Wait(1000)
    end
end)