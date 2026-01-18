if GetResourceState('es_extended') ~= 'started' then
    return
end

ESX = exports['es_extended']:getSharedObject()
PlayerData, PlayerGroup = {}, {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function()
    while ESX == nil do
		Wait(1)
		ESX = exports['es_extended']:getSharedObject()
	end

	PlayerData = ESX.GetPlayerData()

	PlayerData.firstname = PlayerData.firstName
    PlayerData.lastname  = PlayerData.lastName
    PlayerData.citizenid  = PlayerData.identifier

	Wait(100)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job

    PlayerData.firstname = PlayerData.charinfo.firstname
    PlayerData.lastname  = PlayerData.charinfo.lastname
    PlayerData.citizenid  = PlayerData.identifier

end)

CreateThread(function()
    while true do
        if LocalPlayer.state['isLoggedIn'] then
            while ESX == nil do
                Wait(1)
                ESX = exports['es_extended']:getSharedObject()
            end
            PlayerData = ESX.GetPlayerData()
    
            PlayerData.firstname = PlayerData.firstName
            PlayerData.lastname  = PlayerData.lastName
            PlayerData.citizenid  = PlayerData.identifier
            
            Wait(100)
            break
        end
        Wait(1000)
    end
end)