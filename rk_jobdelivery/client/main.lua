local ped = nil
local carrelloProp = nil
local carrelloInMano = false
local carrelloNetId = nil
local veicolo = nil
local consegnaIndex = 0
local consegnaBlip = nil

local paccoInMano = false
local paccoProp = nil
local consegnaMarker = nil
local consegnaPed = nil
local consegnaPedProp = nil

local scoreboardActive = false
local returnBlip = nil

local lavoroAttivo = false
local jobId = nil

local function removeConsegnaEntities()
    if consegnaPed and DoesEntityExist(consegnaPed) then
        DeleteEntity(consegnaPed)
        consegnaPed = nil
    end
    if consegnaPedProp and DoesEntityExist(consegnaPedProp) then
        DeleteEntity(consegnaPedProp)
        consegnaPedProp = nil
    end
end

local function setNextConsegnaBlip()
    if consegnaBlip then
        RemoveBlip(consegnaBlip)
        consegnaBlip = nil
    end
    local coords = Config.Consegne[consegnaIndex]
    if coords then
        consegnaBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(consegnaBlip, 514) 
        SetBlipColour(consegnaBlip, 5)
        SetBlipScale(consegnaBlip, 1.0)
        SetBlipAsShortRange(consegnaBlip, false)
        SetBlipRoute(consegnaBlip, true)
        SetBlipRouteColour(consegnaBlip, 5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Consegna #" .. consegnaIndex)
        EndTextCommandSetBlipName(consegnaBlip)
        
        CreateThread(function()
            while consegnaBlip and consegnaIndex <= #Config.Consegne do
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local dist = #(pos - coords)
                if dist < 3.0 then
                    lib.notify({title = 'Livraison', description = 'Vous avez livré le colis #'..consegnaIndex, type = 'success'})
                    RemoveBlip(consegnaBlip)
                    consegnaBlip = nil
                    consegnaIndex = consegnaIndex + 1
                    if Config.Consegne[consegnaIndex] then
                        Wait(1000)
                        setNextConsegnaBlip()
                    else
                        lib.notify({title = 'Livraison', description = 'Vous avez terminé toutes les livraisons !', type = 'success'})
                    end
                    break
                end
                Wait(500)
            end
        end)
    end
end

local function creaPaccoInMano()
    local ped = PlayerPedId()
    local model = 'prop_cs_cardbox_01'
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    paccoProp = CreateObject(model, 0, 0, 0, true, true, false)
    SetEntityAsMissionEntity(paccoProp, true, true)
    AttachEntityToEntity(
        paccoProp, ped, GetPedBoneIndex(ped, 24816),
        0.05, 0.35, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )
    paccoInMano = true
    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
end

local function rimuoviPaccoInMano()
    if paccoProp and DoesEntityExist(paccoProp) then
        DeleteEntity(paccoProp)
        paccoProp = nil
    end
    paccoInMano = false
    ClearPedTasks(PlayerPedId())
end

local function creaBlipConsegna(coords)
    if consegnaBlip then
        RemoveBlip(consegnaBlip)
        consegnaBlip = nil
    end
    consegnaBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(consegnaBlip, 514)
    SetBlipColour(consegnaBlip, 5)
    SetBlipScale(consegnaBlip, 1.0)
    SetBlipAsShortRange(consegnaBlip, false)
    SetBlipRoute(consegnaBlip, true)
    SetBlipRouteColour(consegnaBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Consegna #" .. consegnaIndex)
    EndTextCommandSetBlipName(consegnaBlip)
end

local function creaMarkerConsegna(coords)
    CreateThread(function()
        while paccoInMano and coords do
            DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 0, 255, 0, 120, false, true, 2, false, nil, nil, false)
            Wait(0)
        end
    end)
end


local function showScoreboard(show, consegnati, totali)
    if show then
        SendNUIMessage({
            action = "showScoreboard",
            consegnati = consegnati or 0,
            totali = totali or 0
        })
        scoreboardActive = true
    else
        SendNUIMessage({ action = "hideScoreboard" })
        scoreboardActive = false
    end
end


local function updateScoreboard(consegnati, totali)
    if scoreboardActive then
        SendNUIMessage({
            action = "updateScoreboard",
            consegnati = consegnati or 0,
            totali = totali or 0
        })
    end
end


local function creaBlipRitorno(coords)
    if returnBlip then
        RemoveBlip(returnBlip)
        returnBlip = nil
    end
    returnBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(returnBlip, 1)
    SetBlipColour(returnBlip, 2)
    SetBlipScale(returnBlip, 1.0)
    SetBlipAsShortRange(returnBlip, false)
    SetBlipRoute(returnBlip, true)
    SetBlipRouteColour(returnBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Retour au stockage")
    EndTextCommandSetBlipName(returnBlip)
end

local function pagaPlayer()
    TriggerServerEvent('rk_jobdelivery:payPlayer')
end

local function terminaLavoro(daTarget, reason)

    if veicolo and DoesEntityExist(veicolo) then
        DeleteEntity(veicolo)
        veicolo = nil
    end
    if returnBlip then
        RemoveBlip(returnBlip)
        returnBlip = nil
    end
    if consegnaBlip then
        RemoveBlip(consegnaBlip)
        consegnaBlip = nil
    end
   
    if paccoProp and DoesEntityExist(paccoProp) then
        DeleteEntity(paccoProp)
        paccoProp = nil
    end
    paccoInMano = false
  
    if carrelloProp and DoesEntityExist(carrelloProp) then
        DeleteEntity(carrelloProp)
        carrelloProp = nil
    end
    carrelloInMano = false
   
    showScoreboard(false)
    lavoroAttivo = false
    jobId = nil
    
 
    if daTarget then
        TriggerServerEvent('rk_jobdelivery:endJob', 'abandonné', reason or 'Tu as arrêté de travailler.')
    end
end

local function startConsegne()
    consegnaIndex = 1
    lavoroAttivo = true
    showScoreboard(true, 0, #Config.Consegne)
  
    exports.ox_target:addLocalEntity(veicolo, {
        {
            label = 'Prendre le paquet',
            icon = 'fa-solid fa-box',
            bones = {'door_dside_r', 'door_pside_r', 'boot'},
            distance = 3.0,
            canInteract = function(entity, distance, coords, name)
                return not paccoInMano and not carrelloInMano and consegnaIndex > 0 and consegnaIndex <= #Config.Consegne
            end,
            onSelect = function()
           
                SetVehicleDoorOpen(veicolo, 2, false, false)
                SetVehicleDoorOpen(veicolo, 3, false, false)
                
                lib.notify({title = 'Emballer', description = 'Prendre le paquet...', type = 'info'})
                
               
                local model = 'prop_cs_cardbox_01'
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(10) end
                
                local offset = GetOffsetFromEntityInWorldCoords(veicolo, 0.0, -2.5, 0.1) 
                local tempPacco = CreateObject(model, offset.x, offset.y, offset.z, true, true, false)
                SetEntityAsMissionEntity(tempPacco, true, true)
                SetEntityCollision(tempPacco, false, false)
                FreezeEntityPosition(tempPacco, true)
                
              
                local ped = PlayerPedId()
                RequestAnimDict("mini@repair")
                while not HasAnimDictLoaded("mini@repair") do Wait(10) end
                TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, 2000, 49, 0, false, false, false)
                
                Wait(2000)
                
           
                DeleteEntity(tempPacco)
                creaPaccoInMano()
                
               
                SetVehicleDoorShut(veicolo, 2, false)
                SetVehicleDoorShut(veicolo, 3, false)
                
                local coords = Config.Consegne[consegnaIndex]
                creaBlipConsegna(coords)
                creaMarkerConsegna(coords)
                lib.notify({title = 'Livraison', description = 'Apportez le colis au client !', type = 'info'})
                
                exports.ox_target:addSphereZone({
                    coords = coords,
                    radius = 2.0,
                    debug = false,
                    options = {
                        {
                            name = 'suona_cliente_'..consegnaIndex,
                            label = 'Sonner au client',
                            icon = 'fa-solid fa-bell',
                            canInteract = function(entity, distance, coords, name)
                                return paccoInMano
                            end,
                            onSelect = function()
                                local ped = PlayerPedId()
                            
                                if paccoProp and DoesEntityExist(paccoProp) then
                                    AttachEntityToEntity(
                                        paccoProp, ped, GetPedBoneIndex(ped, 24816),
                                        0.05, 0.35, 0.0,
                                        0.0, 0.0, 0.0,
                                        true, true, false, true, 1, true
                                    )
                                end
                             
                                RequestAnimDict("timetable@jimmy@doorknock@")
                                while not HasAnimDictLoaded("timetable@jimmy@doorknock@") do Wait(10) end
                                TaskPlayAnim(ped, "timetable@jimmy@doorknock@", "knockdoor_idle", 8.0, -8.0, 2000, 49, 0, false, false, false)
                                lib.notify({title = 'Livraison', description = 'Vous livrez le colis...', type = 'info'})
                                Wait(2000)
                            
                                local pedModel = 'a_m_m_business_01'
                                RequestModel(pedModel)
                                while not HasModelLoaded(pedModel) do Wait(10) end
                               
                                local playerPos = GetEntityCoords(ped)
                                local coords = Config.Consegne[consegnaIndex]
                                local pedHeading = GetHeadingFromVector_2d(playerPos.x - coords.x, playerPos.y - coords.y)
                                local playerHeading = GetHeadingFromVector_2d(coords.x - playerPos.x, coords.y - playerPos.y)
                                
                                consegnaPed = CreatePed(0, pedModel, coords.x, coords.y, coords.z - 1.0, pedHeading, false, true)
                                SetEntityAsMissionEntity(consegnaPed, true, true)
                               
                                SetEntityHeading(ped, playerHeading)
                             
                                local model = 'prop_cs_cardbox_01'
                                RequestModel(model)
                                while not HasModelLoaded(model) do Wait(10) end
                                consegnaPedProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
                                SetEntityAsMissionEntity(consegnaPedProp, true, true)
                                AttachEntityToEntity(
                                    consegnaPedProp, consegnaPed, GetPedBoneIndex(consegnaPed, 24816),
                                    0.05, 0.35, 0.0,
                                    0.0, 0.0, 0.0,
                                    true, true, false, true, 1, true
                                )
                                RequestAnimDict("anim@heists@box_carry@")
                                while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
                                TaskPlayAnim(consegnaPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, 2000, 49, 0, false, false, false)
                             
                                rimuoviPaccoInMano()
                              
                                Wait(2000)
                                removeConsegnaEntities()
                                
                                if consegnaBlip then
                                    RemoveBlip(consegnaBlip)
                                    consegnaBlip = nil
                                end
                                updateScoreboard(consegnaIndex, #Config.Consegne)
                             
                                TriggerServerEvent('rk_jobdelivery:updateProgress', consegnaIndex + 1, consegnaIndex)
                                
                                consegnaIndex = consegnaIndex + 1
                                if Config.Consegne[consegnaIndex] then
                                    Wait(1000)
                                    lib.notify({title = 'Livraison', description = 'Retour au véhicule pour le prochain colis !', type = 'info'})
                                    creaBlipConsegna(Config.Consegne[consegnaIndex])
                                else
                                    
                                    showScoreboard(false)
                                    lavoroAttivo = false
                                    lib.notify({title = 'Livraison', description = 'Vous avez effectué toutes les livraisons ! Retournez au dépôt pour restituer le véhicule..', type = 'success'})
                                    creaBlipRitorno(Config.Ped.coords)
                                   
                                    exports.ox_target:addLocalEntity(veicolo, {
                                        {
                                            label = 'Livraison du véhicule et réception du paiement',
                                            icon = 'fa-solid fa-money-bill',
                                            canInteract = function(entity, distance, coords, name)
                                                local pos = GetEntityCoords(PlayerPedId())
                                                local depot = Config.Ped.coords
                                                return #(pos - vector3(depot.x, depot.y, depot.z)) < 5.0
                                            end,
                                            onSelect = function()
                                                if veicolo and DoesEntityExist(veicolo) then
                                                    DeleteEntity(veicolo)
                                                    veicolo = nil
                                                end
                                                if returnBlip then
                                                    RemoveBlip(returnBlip)
                                                    returnBlip = nil
                                                end
                                                pagaPlayer()
                                            end
                                        }
                                    })
                                end
                            end
                        }
                    }
                })
            end
        }
    })
   
    if Config.Consegne[1] then
        creaBlipConsegna(Config.Consegne[1])
    end
end



CreateThread(function()
    local pedConfig = Config.Ped

    local blip = AddBlipForCoord(pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z)
    SetBlipSprite(blip, 478)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Centre de livraison")
    EndTextCommandSetBlipName(blip)

   
    RequestModel(pedConfig.model)
    while not HasModelLoaded(pedConfig.model) do
        Wait(10)
    end
    ped = CreatePed(0, pedConfig.model, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z - 1.0, pedConfig.coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Parlez au facteur',
            icon = 'fa-solid fa-envelope',
            canInteract = function(entity, distance, coords, name)
                return not lavoroAttivo
            end,
            onSelect = function()
                TriggerEvent('rk_jobdelivery:interactPed')
            end
        },
        {
            label = 'Arrêter de travailler',
            icon = 'fa-solid fa-xmark',
            canInteract = function(entity, distance, coords, name)
                return lavoroAttivo and (consegnaIndex <= #Config.Consegne)
            end,
            onSelect = function()
                terminaLavoro(true)
            end
        }
    })
end)

RegisterNetEvent('rk_jobdelivery:interactPed', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openTablet' })
end)

RegisterNUICallback('closeTablet', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


RegisterNetEvent('rk_jobdelivery:jobStarted', function(newJobId)
    jobId = newJobId
    spawnJobEntities()
end)

RegisterNetEvent('rk_jobdelivery:restoreJob', function(jobData)
    if not jobData then return end
    
    jobId = jobData.id
    consegnaIndex = jobData.current_delivery
    lavoroAttivo = true
    
    lib.notify({title = 'Travail', description = 'restauration en cours...', type = 'info'})
    
   
    spawnJobEntities()
    
 
    showScoreboard(true, jobData.deliveries_completed, jobData.total_deliveries)
    
  
    if consegnaIndex <= #Config.Consegne then
        local coords = Config.Consegne[consegnaIndex]
        if coords then
            creaBlipConsegna(coords)
        end
    else
      
        showScoreboard(false)
        lavoroAttivo = false
        creaBlipRitorno(Config.Ped.coords)
    end
end)

function spawnJobEntities()
 
    local prop = 'prop_rub_cage01b'
    local coords = Config.Pacchi[1]
    if coords then
        RequestModel(prop)
        while not HasModelLoaded(prop) do
            Wait(10)
        end
        carrelloProp = CreateObject(prop, coords.x, coords.y, coords.z - 1.0, true, true, false)
        PlaceObjectOnGroundProperly(carrelloProp)
        SetEntityAsMissionEntity(carrelloProp, true, true)
        FreezeEntityPosition(carrelloProp, true)
        carrelloNetId = NetworkGetNetworkIdFromEntity(carrelloProp)

        exports.ox_target:addLocalEntity(carrelloProp, {
            {
                label = 'Obtenir le panier',
                icon = 'fa-solid fa-dolly',
                canInteract = function(entity, distance, coords, name)
                    return not carrelloInMano
                end,
                onSelect = function()
                    
                    local ped = PlayerPedId()
                    carrelloInMano = true
                    
                    RequestAnimDict("missfinale_c2ig_11")
                    while not HasAnimDictLoaded("missfinale_c2ig_11") do Wait(10) end
                    TaskPlayAnim(ped, "missfinale_c2ig_11", "pushcar_offcliff_m", 8.0, -8.0, -1, 49, 0, false, false, false)
                    lib.notify({title = 'Panier', description = 'Tu pousses le chariot !', type = 'success'})
                   
                    CreateThread(function()
                        while carrelloInMano and carrelloProp and DoesEntityExist(carrelloProp) do
                            local ped = PlayerPedId()
                            
                            if not IsEntityPlayingAnim(ped, "missfinale_c2ig_11", "pushcar_offcliff_m", 3) then
                                TaskPlayAnim(ped, "missfinale_c2ig_11", "pushcar_offcliff_m", 8.0, -8.0, -1, 49, 0, false, false, false)
                            end
                          
                            local forward = GetEntityForwardVector(ped)
                            local pos = GetEntityCoords(ped) + forward * 1.2
                            SetEntityCoords(carrelloProp, pos.x, pos.y, pos.z - 1.0, false, false, false, false)
                            SetEntityHeading(carrelloProp, GetEntityHeading(ped))
                            Wait(0)
                        end
                        ClearPedTasks(PlayerPedId())
                    end)
                end
            }
        })
    end


    local vehConfig = Config.Veicolo
    if vehConfig and vehConfig.model and vehConfig.coords then
        local vehHash = type(vehConfig.model) == "number" and vehConfig.model or GetHashKey(vehConfig.model)
        RequestModel(vehHash)
        while not HasModelLoaded(vehHash) do
            Wait(10)
        end
        veicolo = CreateVehicle(vehHash, vehConfig.coords.x, vehConfig.coords.y, vehConfig.coords.z, vehConfig.coords.w, true, false)
        SetEntityAsMissionEntity(veicolo, true, true)
        SetVehicleOnGroundProperly(veicolo)

       
        exports.ox_target:addLocalEntity(veicolo, {
            {
                label = 'Charger le chariot',
                icon = 'fa-solid fa-truck-loading',
                bones = {'door_dside_r', 'door_pside_r', 'boot'},
                distance = 4.0,
                canInteract = function(entity, distance, coords, name)
                    return carrelloInMano
                end,
                onSelect = function()
                    if carrelloProp and DoesEntityExist(carrelloProp) then
                   
                        SetVehicleDoorOpen(veicolo, 2, false, false)
                        SetVehicleDoorOpen(veicolo, 3, false, false)
                        
                        lib.notify({title = 'Panier', description = 'Chargement du chariot...', type = 'info'})
                        
                     
                        local offset = GetOffsetFromEntityInWorldCoords(veicolo, 0.0, -2.8, 0.8) 
                        local vehHeading = GetEntityHeading(veicolo)
                        
                        SetEntityCoords(carrelloProp, offset.x, offset.y, offset.z, false, false, false, false)
                        SetEntityHeading(carrelloProp, vehHeading)
                        SetEntityCollision(carrelloProp, false, false)
                        FreezeEntityPosition(carrelloProp, true)
                        
                        Wait(2000)
                        
                       
                        SetVehicleDoorShut(veicolo, 2, false)
                        SetVehicleDoorShut(veicolo, 3, false)
                        
                       
                        if carrelloProp and DoesEntityExist(carrelloProp) then
                            DeleteEntity(carrelloProp)
                            carrelloProp = nil
                        end
                        
                        carrelloInMano = false
                        lib.notify({title = 'Panier', description = 'Vous avez chargé votre panier !', type = 'success'})
                        
                        
                        startConsegne()
                    end
                end
            }
        })
    end
end


CreateThread(function()
    Wait(2000) 
    TriggerServerEvent('rk_jobdelivery:getJobStatus')
end)

RegisterNUICallback('startJob', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    
   
    TriggerServerEvent('rk_jobdelivery:startJob')
end)


