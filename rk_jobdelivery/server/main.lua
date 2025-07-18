
local function getPlayerIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in pairs(identifiers) do
        if string.find(id, "license:") then
            return id
        end
    end
    return nil
end


RegisterNetEvent('rk_jobdelivery:startJob', function()
    local src = source
    local identifier = getPlayerIdentifier(src)
    local playerName = GetPlayerName(src)
    
    if not identifier then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Errore', description = 'Impossibile identificare il giocatore!', type = 'error'})
        return
    end
    
    
    MySQL.Async.fetchScalar('SELECT id FROM rk_jobdelivery WHERE player_identifier = ? AND job_status = "active"', {identifier}, function(activeJob)
        if activeJob then
            TriggerClientEvent('ox_lib:notify', src, {title = 'Lavoro', description = 'Hai già un lavoro attivo!', type = 'error'})
            return
        end
        
       
        local totalDeliveries = #Config.Consegne
        local vehModel = Config.Veicolo.model
        local vehCoords = json.encode({x = Config.Veicolo.coords.x, y = Config.Veicolo.coords.y, z = Config.Veicolo.coords.z, w = Config.Veicolo.coords.w})
        
        MySQL.Async.execute('INSERT INTO rk_jobdelivery (player_identifier, player_name, total_deliveries, vehicle_model, vehicle_coords) VALUES (?, ?, ?, ?, ?)', 
        {identifier, playerName, totalDeliveries, vehModel, vehCoords}, function(insertId)
            if insertId then
                TriggerClientEvent('ox_lib:notify', src, {title = 'Lavoro', description = 'Lavoro iniziato con successo!', type = 'success'})
                TriggerClientEvent('rk_jobdelivery:jobStarted', src, insertId)
            else
                TriggerClientEvent('ox_lib:notify', src, {title = 'Errore', description = 'Errore nell\'avviare il lavoro!', type = 'error'})
            end
        end)
    end)
end)


RegisterNetEvent('rk_jobdelivery:getJobStatus', function()
    local src = source
    local identifier = getPlayerIdentifier(src)
    
    if not identifier then
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM rk_jobdelivery WHERE player_identifier = ? AND job_status = "active"', {identifier}, function(result)
        if result and #result > 0 then
            local jobData = result[1]
            TriggerClientEvent('rk_jobdelivery:restoreJob', src, jobData)
        end
    end)
end)


RegisterNetEvent('rk_jobdelivery:updateProgress', function(currentDelivery, deliveriesCompleted)
    local src = source
    local identifier = getPlayerIdentifier(src)
    
    if not identifier then
        return
    end
    
    MySQL.Async.execute('UPDATE rk_jobdelivery SET current_delivery = ?, deliveries_completed = ? WHERE player_identifier = ? AND job_status = "active"', 
    {currentDelivery, deliveriesCompleted, identifier})
end)


RegisterNetEvent('rk_jobdelivery:endJob', function(jobStatus, reason)
    local src = source
    local identifier = getPlayerIdentifier(src)
    
    if not identifier then
        return
    end
    
    jobStatus = jobStatus or 'completed'
    
    MySQL.Async.execute('UPDATE rk_jobdelivery SET job_status = ?, end_time = NOW() WHERE player_identifier = ? AND job_status = "active"', 
    {jobStatus, identifier}, function(affectedRows)
        if affectedRows > 0 then
            if jobStatus == 'completed' then
                TriggerClientEvent('ox_lib:notify', src, {title = 'Lavoro', description = 'Lavoro completato con successo!', type = 'success'})
            elseif jobStatus == 'abandoned' then
                TriggerClientEvent('ox_lib:notify', src, {title = 'Lavoro', description = reason or 'Hai abbandonato il lavoro.', type = 'info'})
            end
        end
    end)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    MySQL.ready(function()
        MySQL.Async.execute('UPDATE rk_jobdelivery SET job_status = "abandoned", end_time = NOW() WHERE job_status = "active"')
    end)
end)

RegisterNetEvent('rk_jobdelivery:payPlayer', function()
    local src = source
    local identifier = getPlayerIdentifier(src)
    local amount = (Config and Config.Paga) or 5000
    
    if not identifier then
        return
    end
    

    MySQL.Async.execute('UPDATE rk_jobdelivery SET total_earnings = ? WHERE player_identifier = ? AND job_status = "active"', 
    {amount, identifier})
    
   
    local success = exports.ox_inventory:AddItem(src, 'money', amount)
    
    if not success then
     
        local xPlayer = ESX and ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addMoney(amount) 
            TriggerClientEvent('ox_lib:notify', src, {title = 'Pagamento', description = 'Hai ricevuto $'..amount..' in contanti!', type = 'success'})
        else
          
            TriggerClientEvent('ox_lib:notify', src, {title = 'Pagamento', description = 'Pagamento di $'..amount..' elaborato!', type = 'success'})
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Pagamento', description = 'Hai ricevuto $'..amount..' in contanti!', type = 'success'})
    end
    
 
    TriggerEvent('rk_jobdelivery:endJob', 'completed')
end)
