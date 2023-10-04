local AnimDictBox = 'anim@scripted@player@mission@tun_control_tower@male@'
local AnimDictCabinet = 'missheist_jewel'
local IsHacking
local IsSmashing
local ClosestCabinet = 1
local AnimName
local AnimNameSmashTop = {
    'smash_case_tray_a',
    'smash_case_d',
    'smash_case_e'
}
local AnimNameSmashFront = {
    'smash_case_tray_b',
    'smash_case_necklace_skull'
}
local insideJewelry = false
local electricalBoxEntity

local function createElectricalBox()
    electricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, false, false, false)
    while not DoesEntityExist(electricalBoxEntity) do
        Wait(0)
    end
    SetEntityHeading(electricalBoxEntity, Config.Electrical.w)
    if Config.UseTarget then
        local options = {
            {
                name = 'qb-jewelery:electricalBox',
                icon = 'fab fa-usb',
                label = Lang:t('text.electricalTarget'),
                distance = 1.6,
                items = Config.Doorlock.RequiredItem,
                onSelect = function()
                    lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end
                        TriggerEvent('qb-jewelery:client:electricalHandler')
                    end)
                end
            }
        }
        exports.ox_target:addLocalEntity(electricalBoxEntity, options)
    end
end

local function removeElectricalBox()
    if Config.UseTarget then
        exports.ox_target:removeLocalEntity(electricalBoxEntity, 'qb-jewelery:electricalBox')
    end
    if electricalBoxEntity ~= nil and DoesEntityExist(electricalBoxEntity) then
        DeleteObject(electricalBoxEntity)
    end
    electricalBoxEntity = nil
end

if not Config.UseTarget then
    CreateThread(function()
        local HasShownText
        while true do
            local PlayerCoords = GetEntityCoords(cache.ped)
            local ElectricalCoords = vector3(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z + 1.1)
            local WaitTime = 800
            local Nearby = false
            if #(PlayerCoords - ElectricalCoords) <= 1.5 and not IsHacking then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true lib.showTextUI(Lang:t('text.electrical'), 'left-center') end
                else
                    DrawText3D(Lang:t('text.electrical'), ElectricalCoords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end

                        IsHacking = true
                        TriggerEvent('qb-jewelery:client:electricalHandler')
                    end)
                end
            end
            if not Nearby and HasShownText then HasShownText = false lib.hideTextUI() end
            Wait(WaitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:electricalHandler', function()
    lib.requestAnimDict(AnimDictBox)
    local PlayerCoords = GetEntityCoords(cache.ped)
    local Box = GetClosestObjectOfType(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1.5, `tr_prop_tr_elecbox_01a`, false, false, false)
    local EnterScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, EnterScene, AnimDictBox, 'enter', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, EnterScene, AnimDictBox, 'enter_electric_box', 4.0, -8.0, 1)
    local LoopingScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, false, true, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, LoopingScene, AnimDictBox, 'loop', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, LoopingScene, AnimDictBox, 'loop_electric_box', 4.0, -8.0, 1)
    local LeavingScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, LeavingScene, AnimDictBox, 'exit', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, LeavingScene, AnimDictBox, 'exit_electric_box', 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(EnterScene)
    Wait(GetAnimDuration(AnimDictBox, 'enter') * 1000)
    NetworkStartSynchronisedScene(LoopingScene)

    TriggerEvent('ultra-voltlab', math.random(Config.Doorlock.HackTime.Min, Config.Doorlock.HackTime.Max), function(result, reason)
        Wait(2500)
        NetworkStartSynchronisedScene(LeavingScene)
        IsHacking = false
        if result == 0 then
            TriggerServerEvent('qb-jewellery:server:failedhackdoor')
        elseif result == 1 then
            TriggerServerEvent('qb-jewellery:server:succeshackdoor')
        elseif result == 2 then
            exports.qbx_core:Notify('Timed out', 'error')
        elseif result == -1 then
            print('Error occured', reason)
        end
        Wait(GetAnimDuration(AnimDictBox, 'exit') * 1000)
        NetworkStopSynchronisedScene(LeavingScene)
    end)
end)

local function StartRayFire(Coords, RayFire)
    local RayFireObject = GetRayfireMapObject(Coords.x, Coords.y, Coords.z, 1.4, RayFire)
    SetStateOfRayfireMapObject(RayFireObject, 4)
    Wait(100)
    SetStateOfRayfireMapObject(RayFireObject, 6)
end

local function LoadParticle()
    lib.requestNamedPtfxAsset('scr_jewelheist')
    UseParticleFxAsset('scr_jewelheist')
end

local function PlaySmashAudio(Coords)
    local SoundId = GetSoundId()
    PlaySoundFromCoord(SoundId, 'Glass_Smash', Coords.x, Coords.y, Coords.z, '', false, 6.0, false)
    ReleaseSoundId(SoundId)
end

if Config.UseTarget then
    for i = 1, #Config.Cabinets do
        exports.ox_target:addBoxZone({
            coords = Config.Cabinets[i].coords,
            size = vec3(1.2, 1.6, 1),
            rotation = Config.Cabinets[i].heading,
            --debug = true,
            options = {
                {
                    icon = 'fas fa-gem',
                    label = Lang:t('text.cabinet'),
                    distance = 0.6,
                    onSelect = function()
                        ClosestCabinet = i
                        lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                            if not CanSmash then return end
                            TriggerEvent('qb-jewelery:client:cabinetHandler')
                        end, ClosestCabinet)
                    end
                }
            }
        })
    end
else
    CreateThread(function()
        local HasShownText
        while true do
            local PlayerCoords = GetEntityCoords(cache.ped)
            local Nearby = false
            local WaitTime = 800
            for i = 1, #Config.Cabinets do
                if #(PlayerCoords - Config.Cabinets[i].coords) < 0.5 then
                    if not ClosestCabinet then ClosestCabinet = i
                    elseif #(PlayerCoords - Config.Cabinets[i].coords) < #(PlayerCoords - Config.Cabinets[ClosestCabinet].coords) then ClosestCabinet = i end
                    WaitTime = 0
                    Nearby = true
                end
            end
            if Nearby and not (IsSmashing or Config.Cabinets[ClosestCabinet].isOpened) then
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true lib.showTextUI(Lang:t('text.cabinet'),  'left-center') end
                else
                    DrawText3D(Lang:t('text.cabinet'), Config.Cabinets[ClosestCabinet].coords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                        if not CanSmash then return end

                        IsSmashing = true
                        if HasShownText then HasShownText = false lib.hideTextUI() end
                        TriggerEvent('qb-jewelery:client:cabinetHandler')
                    end, ClosestCabinet)
                end
            end
            if not Nearby and HasShownText then HasShownText = false lib.hideTextUI() end
            Wait(WaitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:cabinetHandler', function()
    local PlayerCoords = GetEntityCoords(cache.ped)
    if not IsWearingGloves() then
        if Config.FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
    end
    TaskAchieveHeading(cache.ped, Config.Cabinets[ClosestCabinet].heading, 1500)
    Wait(1500)
    lib.requestAnimDict(AnimDictCabinet)
    if Config.Cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
        AnimName = AnimNameSmashFront[math.random(1, #AnimNameSmashFront)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(150)
        StartRayFire(PlayerCoords, Config.Cabinets[ClosestCabinet].rayFire)
    elseif Config.Cabinets[ClosestCabinet].rayFire then
        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
        StartRayFire(PlayerCoords, Config.Cabinets[ClosestCabinet].rayFire)
    else
        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
    end
    LoadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(cache.ped), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    PlaySmashAudio(PlayerCoords)
    Wait(GetAnimDuration(AnimDictCabinet, AnimName) * 850)
    ClearPedTasks(cache.ped)
    IsSmashing = false
    TriggerServerEvent('qb-jewelery:server:endcabinet')
end)

RegisterNetEvent('qb-jewelery:client:synceffects', function(ClosestCabinet, OriginalPlayer)
    Wait(1500)
    if Config.Cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
        Wait(150)
        StartRayFire(Config.Cabinets[ClosestCabinet].coords, Config.Cabinets[ClosestCabinet].rayFire)
    elseif Config.Cabinets[ClosestCabinet].rayFire then
        Wait(300)
        StartRayFire(Config.Cabinets[ClosestCabinet].coords, Config.Cabinets[ClosestCabinet].rayFire)
    end
    LoadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(GetPlayerPed(GetPlayerFromServerId(OriginalPlayer))), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    PlaySmashAudio(Config.Cabinets[ClosestCabinet].coords)
end)

RegisterNetEvent('qb-jewelery:client:syncconfig', function(Cabinets)
    Config.Cabinets = Cabinets
end)

RegisterNetEvent('qb-jewelery:client:alarm', function()
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    Wait(100)
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
    Wait(Config.AlarmDuration)
    StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
end)

lib.zones.sphere({
    coords = vec3(Config.Cabinets[1].coords.x, Config.Cabinets[1].coords.y, Config.Cabinets[1].coords.z),
    radius = 80,
    --debug = true,
    onEnter = function()
        insideJewelry = true
        createElectricalBox()
        CreateThread(function()
            
            while insideJewelry do
                for i = 1, #Config.Cabinets do
                    if Config.Cabinets[i].isOpened then
                        local RayFire = GetRayfireMapObject(Config.Cabinets[i].coords.x, Config.Cabinets[i].coords.y, Config.Cabinets[i].coords.z, 1.4, Config.Cabinets[i].rayFire)
                        SetStateOfRayfireMapObject(RayFire, 9)
                    end
                end
                Wait(6000)
            end
        end)
    end,
    onExit = function()
        removeElectricalBox()
        insideJewelry = false
    end,
})

if GetResourceMetadata(GetCurrentResourceName(), 'shared_script', GetNumResourceMetadata(GetCurrentResourceName(), 'shared_script') - 1) == 'configs/kambi.lua' then
    --- Add more functionality later
end

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end
    removeElectricalBox()
end)