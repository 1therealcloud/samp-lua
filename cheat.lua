script_name('cloud-multi-cheat')
script_version('01.11.2026')
script_author('cloud')

-- require

require'lib.moonloader'
local memory = require 'memory'
local ffi = require "ffi"
local sampev = require 'samp.events'
local inicfg = require 'inicfg'

require('samp.synchronization')
local sampfuncs = require('sampfuncs')
local raknet = require('samp.raknet')

-- ini
local script_name = thisScript().filename:match("^(.*)%.%w+$")

local directIni = ''..script_name..'.ini'

local ini = inicfg.load({
    settings = {
        bone_wh = false,
        static_crosshair = false,
        no_spread = false,
        auto_reload = false,
        extra_ws = false,
        anti_mask = false,
        stream_info = false,
        nick_render = false,
        vehicle_render = false,
        object_wh = false,
    },

    commands = {
        bone_wh = 'bonewh',
        static_crosshair = 'staticcrosshair',
        no_spread = 'nospread',
        auto_reload = 'autoreload',
        extra_ws = 'extraws',
        anti_mask = 'antimask',
        stream_info = 'streaminfo',
        nick_render = 'nickrender',
        vehicle_render = 'vehrender',
        cj_run = 'cjrun',
        object_wh = 'objwh',
    },

    int_settings = {
        stream_info_y = 450,
        stream_info_x = 50,
    },

    airbrake = {
        speed_onfoot = 0.5,
        sync_onfoot = 0.5,
    },

    object_wh = {},
}, directIni)
inicfg.save(ini, directIni)

-- do not set the value to true
local airbrake_active = false
local cjrun = false

-- autoupdate

local enable_autoupdate = true
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
local updater_loaded, Updater = pcall(loadstring, [[
    return {
        check = function(url, prefix, site)
            local d = require('moonloader').download_status
            local temp_file = os.tmpname()
            local start_clock = os.clock()
            
            if doesFileExist(temp_file) then 
                os.remove(temp_file) 
            end
            
            downloadUrlToFile(url, temp_file, function(id, status, p1, p2)
                if status == d.STATUSEX_ENDDOWNLOAD then
                    if doesFileExist(temp_file) then
                        local f = io.open(temp_file, 'r')
                        if f then
                            local data = decodeJson(f:read('*a'))
                            updatelink = data.updateurl
                            updateversion = data.latest
                            f:close()
                            os.remove(temp_file)
                            
                            if updateversion ~= thisScript().version then
                                lua_thread.create(function(prefix_msg)
                                    local ds = require('moonloader').download_status
                                    local color = -1
                                    print(prefix_msg .. 'Update detected. Trying to update from ' .. thisScript().version .. ' на ' .. updateversion, color)
                                    wait(250)
                                    
                                    downloadUrlToFile(updatelink, thisScript().path, function(n, o, p, q)
                                        if o == ds.STATUS_DOWNLOADINGDATA then
                                            print(string.format('Downloaded %d of %d.', p, q))
                                        elseif o == ds.STATUS_ENDDOWNLOADDATA then
                                            print('Update download complete.')
                                            print(prefix_msg .. 'Update finished!', color)
                                            goupdatestatus = true
                                            lua_thread.create(function()
                                                wait(500)
                                                thisScript():reload()
                                            end)
                                        end
                                        
                                        if o == ds.STATUSEX_ENDDOWNLOAD then
                                            if goupdatestatus == nil then
                                                print(prefix_msg .. 'Update failed.', color)
                                                update = false
                                            end
                                        end
                                    end)
                                end, prefix)
                            else
                                update = false
                                print('v' .. thisScript().version .. ': Already up to date.')
                            end
                        end
                    else
                        print('v' .. thisScript().version .. ': Unable to update.)
                        update = false
                    end
                end
            end)
            
            while update ~= false and os.clock() - start_clock < 10 do 
                wait(100) 
            end
            
            if os.clock() - start_clock >= 10 then
            print('v' .. thisScript().version .. ': timeout, exiting update check wait.')
            end
        end
    }
]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/1therealcloud/samp-lua/refs/heads/master/version.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
        end
    end
end

-- main

function main()
    while not isSampAvailable() do wait(100) end
    
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix)
    end
    
    sampfuncsLog("{73b461}Loaded!")

    writeMemory(0x58E1DD, 2, 0x9090, true) -- fast crosshair
    writeMemory(0x058E280, 1, 0xEB, true) -- fix crosshair

    -- misc
    noExplosion()
    airbrake()

    -- main functions
    enableAllFunctions()
    registerChatCommands()
    dialogRespond()

    wait(-1)
end

function noExplosion()
    lua_thread.create(function ()
        while true do wait(0)
            if isCharInAnyCar(PLAYER_PED) then
                local carid = storeCarCharIsInNoSave(PLAYER_PED)
                local health = getCarHealth(carid)
                local speed = getCarSpeed(carid)
                if isCarUpsidedown(carid) and health <= 350 then
                    setCarHealth(carid, 350)
                end -- переворот хп
            end-- if in car
        end-- while
    end)
end

--------------------------------- register commands --------------------------------

function registerChatCommands()
    sampRegisterChatCommand('cheatunload', function() thisScript():unload() end)

    sampRegisterChatCommand('cheathelp', function() showHelpDialog() end)

    sampRegisterChatCommand(ini.commands.cj_run, function()
        cjrun = not cjrun
        sampAddChatMessage(cjrun and 'Activated!' or 'DeActivated!', -1)
        cj_run(cjrun)
    end)

    sampRegisterChatCommand(ini.commands.nick_render, function()
        ini.settings.nick_render = not ini.settings.nick_render
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.nick_render and 'Activated!' or 'DeActivated!', -1)
        nickrender(ini.settings.nick_render)
    end)

    sampRegisterChatCommand(ini.commands.vehicle_render, function()
        ini.settings.vehicle_render = not ini.settings.vehicle_render
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.vehicle_render and 'Activated!' or 'DeActivated!', -1)
        vehiclerender(ini.settings.vehicle_render)
    end)

    sampRegisterChatCommand(ini.commands.bone_wh, function()
        ini.settings.bone_wh = not ini.settings.bone_wh
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.bone_wh and 'Activated!' or 'DeActivated!', -1)
        bonewh(ini.settings.bone_wh)
    end)

    sampRegisterChatCommand(ini.commands.static_crosshair, function()
        ini.settings.static_crosshair = not ini.settings.static_crosshair
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.static_crosshair and 'Activated!' or 'DeActivated!', -1)
        staticcrosshair(ini.settings.static_crosshair)
    end)

    sampRegisterChatCommand(ini.commands.no_spread, function()
        ini.settings.no_spread = not ini.settings.no_spread
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.no_spread and 'Activated!' or 'DeActivated!', -1)
        nospread(ini.settings.no_spread)
    end)

    sampRegisterChatCommand(ini.commands.auto_reload, function()
        ini.settings.auto_reload = not ini.settings.auto_reload
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.auto_reload and 'Activated!' or 'DeActivated!', -1)
        autoreload(ini.settings.auto_reload)
    end)

    sampRegisterChatCommand(ini.commands.extra_ws, function()
        ini.settings.extra_ws = not ini.settings.extra_ws
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.extra_ws and 'Activated!' or 'DeActivated!', -1)
        extraws(ini.settings.extra_ws)
    end)

    sampRegisterChatCommand(ini.commands.anti_mask, function()
        ini.settings.anti_mask = not ini.settings.anti_mask
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.anti_mask and 'Activated!' or 'DeActivated!', -1)
    end)

    sampRegisterChatCommand(ini.commands.stream_info, function()
        ini.settings.stream_info = not ini.settings.stream_info
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.stream_info and 'Activated!' or 'DeActivated!', -1)
        streaminfo(ini.settings.stream_info)
    end)

    sampRegisterChatCommand(ini.commands.object_wh, function(id)
        if id == nil or id == "" then
            ini.settings.object_wh = not ini.settings.object_wh
            sampAddChatMessage(ini.settings.object_wh and 'Activated!' or 'DeActivated!', -1)
            object_wh(ini.settings.object_wh)
        else
            local num = tonumber(id)
            if num then
                local found = false
                for i, v in ipairs(ini.object_wh) do
                    if v == num then
                        table.remove(ini.object_wh, i)
                        sampAddChatMessage('Removed ID: ' .. num, -1)
                        found = true
                    end
                end
                if not found then
                    table.insert(ini.object_wh, num)
                    sampAddChatMessage('Added ID: ' .. num, -1)
                end
            else
                sampAddChatMessage('ID must be a number!', -1)
            end
        end

        inicfg.save(ini, directIni)
    end)


end

--------------------------------- enable all ---------------------------------

function enableAllFunctions()
    bonewh(ini.settings.bone_wh)
    staticcrosshair(ini.settings.static_crosshair)
    nospread(ini.settings.no_spread)
    extraws(ini.settings.extra_ws)
    autoreload(ini.settings.auto_reload)
    streaminfo(ini.settings.stream_info)
    nickrender(ini.settings.nick_render)
    vehiclerender(ini.settings.vehicle_render)
    object_wh(ini.settings.object_wh)
end

--------------------------------- disable all ---------------------------------

function disableAllFunctions()
    bonewh(false)
    staticcrosshair(false)
    nospread(false)
    extraws(false)
    autoreload(false)
    streaminfo(false)
    nickrender(false)
    vehiclerender(false)
    cj_run(false)
    object_wh(false)
end

--------------------------------- on terminate ---------------------------------

addEventHandler('onScriptTerminate', function(script)
    if script == script.this then
        disableAllFunctions()
    end
end)

--------------------------------- on window message ---------------------------------

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if msg == 0x101 then
        if isGameInputFree() and wparam == 46 then
            if isCharInAnyCar(PLAYER_PED) then
                setCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED), getCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED)))
                addOneOffSound(0.0 , 0.0, 0.0, 1054)
            else
                local x, y, z = getCharCoordinates(PLAYER_PED)
                setCharCoordinates(PLAYER_PED, x, y, z - 1)
                addOneOffSound(0.0 , 0.0, 0.0, 1055)
            end
        end
    end

    if msg == 0x100 and lparam == 3538945 and isGameInputFree() then
        airbrake_active = not airbrake_active
            local x, y, z = getCharCoordinates(PLAYER_PED)
            airBrkCoords = {x, y, z - 1}
        printStringNow(airbrake_active and '~S~Air~P~Brake ~B~Activated' or '~S~Air~P~Brake ~B~De-Activated', 2000)
    end

    if airbrake_active and isGameInputFree() and (wparam == 16 or wparam == 32) then
        consumeWindowMessage(true, false)
    end

    if msg == 0x100 and wparam == 18 and isGameInputFree() then
        if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) == PLAYER_PED and not sampIsDialogActive() then
            local Handle = storeCarCharIsInNoSave(PLAYER_PED)
            memory.setint8(getCarPointer(Handle) + 0x40 + 0x0, isKeyDown(1) and 7 or 2, true)
            setCarProofs(Handle, true, true, true, true, true)
            local x, y = convert3DCoordsToScreen(getCarCoordinates(Handle))
            renderDrawPolygon(x, y, 22, 22, 4, 0, 0xFF000000)
            renderDrawPolygon(x, y, 20, 20, 4, 0, 0xFFffffff)
            renderDrawPolygon(x, y, 12, 12, 4, 0, 0xFF000000)
            renderDrawPolygon(x, y, 10, 10, 4, 0, 0xFFfff700)

            printStringNow("+", 50)
        end
    end
end)

--------------------------------- dialog --------------------------------

function showHelpDialog()
    sampShowDialog(1231, 'Script settings', 'Function\tCommand\tStatus\nBone WH\t/'..ini.commands.bone_wh..'\t'..string.format(ini.settings.bone_wh and '{73b461}true' or '{dc4747}false')..'\nStatic crosshair\t/'..ini.commands.static_crosshair..'\t'..string.format(ini.settings.static_crosshair and '{73b461}true' or '{dc4747}false')..'\nNo spread\t/'..ini.commands.no_spread..'\t'..string.format(ini.settings.no_spread and '{73b461}true' or '{dc4747}false')..'\nAuto reload\t/'..ini.commands.auto_reload..'\t'..string.format(ini.settings.auto_reload and '{73b461}true' or '{dc4747}false')..'\nExtra WS\t/'..ini.commands.extra_ws..'\t'..string.format(ini.settings.extra_ws and '{73b461}true' or '{dc4747}false')..'\nAnti mask\t/'..ini.commands.anti_mask..'\t'..string.format(ini.settings.anti_mask and '{73b461}true' or '{dc4747}false')..'\nStream info\t/'..ini.commands.stream_info..'\t'..string.format(ini.settings.stream_info and '{73b461}true' or '{dc4747}false')..'\nNick render\t/'..ini.commands.nick_render..'\t'..string.format(ini.settings.nick_render and '{73b461}true' or '{dc4747}false')..'\nVehicle render\t/'..ini.commands.vehicle_render..'\t'..string.format(ini.settings.vehicle_render and '{73b461}true' or '{dc4747}false')..'\nObject render\t/'..ini.commands.object_wh..'\t'..string.format(ini.settings.object_wh and '{73b461}true' or '{dc4747}false')..'', 'Accept', 'Cancel', 5) -- ini.setting.object_wh
end

function dialogRespond()
    while true do wait(0)
        local result, button, list, input = sampHasDialogRespond(1231)
        if result then
            if button == 1 then
                if list == 0 then
                    ini.settings.bone_wh = not ini.settings.bone_wh
                    bonewh(ini.settings.bone_wh)
                    showHelpDialog()  
                end
                if list == 1 then
                    ini.settings.static_crosshair = not ini.settings.static_crosshair
                    staticcrosshair(ini.settings.static_crosshair)
                    showHelpDialog()
                end
                if list == 2 then
                    ini.settings.no_spread = not ini.settings.no_spread
                    nospread(ini.settings.no_spread)
                    showHelpDialog()
                end
                if list == 3 then
                    ini.settings.auto_reload = not ini.settings.auto_reload
                    autoreload(ini.settings.auto_reload)
                    showHelpDialog()
                end
                if list == 4 then
                    ini.settings.extra_ws = not ini.settings.extra_ws
                    extraws(ini.settings.extra_ws)
                    showHelpDialog()
                end
                if list == 5 then
                    ini.settings.anti_mask = not ini.settings.anti_mask 
                    showHelpDialog()
                end
                if list == 6 then
                    ini.settings.stream_info = not ini.settings.stream_info
                    streaminfo(ini.settings.stream_info)
                    showHelpDialog()
                end
                if list == 7 then
                    ini.settings.nick_render = not ini.settings.nick_render
                    nickrender(ini.settings.nick_render)
                    showHelpDialog()
                end
                if list == 8 then
                    ini.settings.vehicle_render = not ini.settings.vehicle_render
                    vehiclerender(ini.settings.vehicle_render)
                    showHelpDialog()
                end
                if list == 9 then
                    ini.settings.object_wh = not ini.settings.object_wh
                    object_wh(ini.settings.object_wh)
                    showHelpDialog()
                end
                inicfg.save(ini, directIni)
            end
        end
    end
end

--------------------------------- functions --------------------------------

function isPlayerPassenger()
    if not isCharInAnyCar(PLAYER_PED) then return (getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED))) end
end

function isGameInputFree()
    return (not sampIsCursorActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsScoreboardOpen() and not isPauseMenuActive())
end

function setCharCoordinatesDontResetAnim(handle, x, y, z)
    if doesCharExist(handle) then
        local ped = getCharPointer(handle)
        setEntityCoordinates(ped, x, y, z)
    end
end

function setEntityCoordinates(entityPtr, x, y, z)
    if entityPtr ~= 0 then
        local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
        if matrixPtr ~= 0 then
            local posPtr = matrixPtr + 0x30
            writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
            writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
            writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
        end
    end
end

function getFullSpeed(speed, ping, min_ping)
    local fps = memory.getfloat(0xB7CB50, true)
    local result = (speed / (fps / 60))
    if ping == 1 then
        local ping = sampGetPlayerPing(getMyId())
        if min_ping < ping then
            result = (result / (min_ping / ping))
        end
    end
    return result
end

function getMoveSpeed(heading, speed)
    moveSpeed = {
        x = math.sin(-math.rad(heading)) * (speed),
        y = math.cos(-math.rad(heading)) * (speed),
        z = 0
    }
    return moveSpeed
end

--------------------------------- airbrake --------------------------------

function airbrake()
    lua_thread.create(function()
        while true do 
            wait(0)
            while not sampIsLocalPlayerSpawned() or isCharInAnyCar(PLAYER_PED) and not isPlayerPassenger() do wait(0) airbrake_active = false clearPrints() end
            if airbrake_active and sampIsLocalPlayerSpawned() then
                setCharHeading(PLAYER_PED, getHeadingFromVector2d(select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()), select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates())))
                speed = getFullSpeed(ini.airbrake.speed_onfoot, 0, 0)
                
                if not isGameInputFree() then goto set_coords end
                
                if isKeyDown(VK_SPACE) then
                    airBrkCoords[3] = airBrkCoords[3] + speed / 2
                elseif isKeyDown(VK_LSHIFT) and airBrkCoords[3] > -95.0 then
                    airBrkCoords[3] = airBrkCoords[3] - speed / 2
                end

                if isKeyDown(VK_S) then
                    airBrkCoords[1] = airBrkCoords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED)))
                    airBrkCoords[2] = airBrkCoords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED)))
                elseif isKeyDown(VK_W) then
                    airBrkCoords[1] = airBrkCoords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED)))
                    airBrkCoords[2] = airBrkCoords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED)))
                end
                if isKeyDown(VK_D) then
                    airBrkCoords[1] = airBrkCoords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90))
                    airBrkCoords[2] = airBrkCoords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90))
                elseif isKeyDown(VK_A) then
                    airBrkCoords[1] = airBrkCoords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90))
                    airBrkCoords[2] = airBrkCoords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90))
                end

                ::set_coords::
                
                setCharCoordinatesDontResetAnim(PLAYER_PED, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3] + 0.5)
                memory.setuint8(getCharPointer(playerPed) + 0x46C, 3, true)
                setCharVelocity(PLAYER_PED, 0, 0, 0)
            end
        end
    end)
end

function sampev.onSendPlayerSync(data)
    if not airbrake_active then return end
    local speed = getMoveSpeed(getCharHeading(PLAYER_PED), ini.airbrake.sync_onfoot)
    data.moveSpeed = {speed.x, speed.y, data.moveSpeed.z}
    return data
end

--------------------------------- cj run ---------------------------------

function cj_run(bool)
    if bool then
        setAnimGroupForChar(PLAYER_PED, "PLAYER")
    else
        setAnimGroupForChar(PLAYER_PED, (cjrun and "PLAYER" or (isCharMale(PLAYER_PED) and "MAN" or "WOMAN")))
    end
end

--------------------------------- nick render ---------------------------------

local my_font = renderCreateFont('Arial Bold', 7.5, 0x4 + 0x8)

function isNameTagVisible(id)
    local res = false
    local pStSet = sampGetServerSettingsPtr()
    local NTdist = representIntAsFloat(readMemory(pStSet + 39, 4, false))
    local bool, handle = sampGetCharHandleBySampPlayerId(id)
    if bool and isCharOnScreen(handle) then
        local x, y, z = GetBodyPartCoordinates(8, handle)
        local xi, yi, zi = getActiveCameraCoordinates()
        local result = isLineOfSightClear(x, y, z, xi, yi, zi, true, false, false, true, false)
        local dist = math.sqrt( (xi - x) ^ 2 + (yi - y) ^ 2 + (zi - z) ^ 2 )
        if result and dist <= NTdist then
            res = true
        end
    end
    return res
end

function nickrender(bool)
    lua_thread.create(function()
    while true do wait(0)
    if bool and ini.settings.nick_render then
        for k, v in ipairs(getAllChars()) do
            local result, id = sampGetPlayerIdByCharHandle(v)
            if result and v ~= PLAYER_PED then
                local name = sampGetPlayerNickname(id)
                local color = string.format('%06X', bit.band(sampGetPlayerColor(id), 0xFFFFFF))
                local x, y, z = getCharCoordinates(v)
                if isCharSittingInAnyCar(v) then
                    z = z + 1
                end
                local coordresult, renderx, rendery, floatz, floatw, floath = convert3DCoordsToScreenEx(x, y, z + 1.0, true, true)
                if coordresult and not isNameTagVisible(id) then
                    local text = string.format('{%s}%s{FFFFFF}(%03d)', color, name, id)
                    renderFontDrawText(my_font, text, renderx - 75, rendery, 0xFFFFFFFF)
                end
            end
        end
    end
end
    end)
end

--------------------------------- vehicle render ---------------------------------

local my_font = renderCreateFont('Arial Bold', 8.5, 0x4 + 0x8)

function vehiclerender(bool)

    lua_thread.create(function()
    while true do wait(0)
    if bool and ini.settings.vehicle_render then
        for k, v in ipairs(getAllVehicles()) do
            local result, id = sampGetVehicleIdByCarHandle(v)
                if result then
                local health = string.format(getCarHealth(v))
                local x, y, z = getCarCoordinates(v)
                local coordresult, renderx, rendery, floatz, floatw, floath = convert3DCoordsToScreenEx(x, y, z, true, true)
                local doorStatus = getCarDoorLockStatus(v)
                if coordresult then
                    local text = '{'..(doorStatus == 0 and '73b461' or 'dc4747')..'}'..health..'hp ('..id..')'
                    renderFontDrawText(my_font, text, renderx, rendery - 15, 0xFFFFFFFF)
                end
            end
        end
    end
end
    end)
end

--------------------------------- streaminfo ---------------------------------

players = {}

function streaminfo(bool)
    lua_thread.create(function()
        while true do wait(0)
            if bool and ini.settings.stream_info then
            local y = ini.int_settings.stream_info_y
            local x = ini.int_settings.stream_info_x
                for k, v in ipairs(getAllChars()) do
                    local result, id = sampGetPlayerIdByCharHandle(v)
                    if result and v ~= PLAYER_PED then
                        local color = string.format('%06X', bit.band(sampGetPlayerColor(id), 0xFFFFFF))
                        local nick = sampGetPlayerNickname(id)          
                        table.insert(players, {nick, id})
                        local player_text = '{'..color..'}'..nick..'{ffffff}['..id..']'
                        if y <= 740 and not isSampfuncsConsoleActive() then
                            renderFontDrawText(my_font, player_text, x, y, 0xFFFFFFFF)
                            y = y + 15
                        end
                    end
                end
            end
        end
    end)
end

--------------------------------- extra ws ---------------------------------

function extraws(bool)
    if bool then
        writeMemory(0x5231A6, 1, 0x90)
    else
        writeMemory(0x5231A6, 1, 0x75)
    end
end

--------------------------------- autoreload ---------------------------------

function autoreload(bool)
    lua_thread.create(function()
        while true do wait(0)
            if bool then
                if isCharShooting(PLAYER_PED) then
                    reloadGun()
                end
            end
        end
    end)
end

function reloadGun()
    local CPed = getCharPointer(playerPed)
    local currentWeapon = getCurrentCharWeapon(playerPed)
    local weaponSlot = getWeapontypeSlot(currentWeapon)
    local CWeapon = CPed + 0x5A0
    local currentCWeapon = CWeapon + weaponSlot * 0x1C
    ffi.cast('void(__thiscall*)(void* CWeapon, void* CPed)', 0x73AEB0)(ffi.cast('void*', currentCWeapon), ffi.cast('void*', CPed))
end

--------------------------------- staticcrosshair ---------------------------------

function staticcrosshair(bool)
    if bool then
        memory.copy(0x609D80, memory.strptr("\x90\x90"), 2, true)
    else
        memory.copy(0x609D80, memory.strptr("\x7A\x08"), 2, true)
    end
end

--------------------------------- nospread ---------------------------------

function nospread(bool)
    if bool then
        memory.setfloat(0x8D6110, 0.0, true) -- non shotguns
        memory.setfloat(0x8D611C, 0.0, true)
    else
        memory.setfloat(0x8D6110, 0.75, true) -- non shotguns
        memory.setfloat(0x8D611C, 0.050000001 , true)
    end
end

--------------------------------- bonewh ---------------------------------

   function bonewh(bool)
    lua_thread.create(function ()
        while true do wait(0)
            if bool and ini.settings.bone_wh then
            for i = 0, sampGetMaxPlayerId() do
                if sampIsPlayerConnected(i) then
                    local result, cped = sampGetCharHandleBySampPlayerId(i)
                    local color = sampGetPlayerColor(i)
                    local aa, rr, gg, bb = explode_argb(color)
                    local color = join_argb(255, rr, gg, bb)
                    if result then
                        if doesCharExist(cped) and isCharOnScreen(cped) then
                            local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
                            for v = 1, #t do
                                pos1X, pos1Y, pos1Z = GetBodyPartCoordinates(t[v], cped)
                                pos2X, pos2Y, pos2Z = GetBodyPartCoordinates(t[v] + 1, cped)
                                pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                                pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                                renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
                            end
                            for v = 4, 5 do
                                pos2X, pos2Y, pos2Z = GetBodyPartCoordinates(v * 10 + 1, cped)
                                pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                                renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
                            end
                            local t = {53, 43, 24, 34, 6}
                            for v = 1, #t do
                                posX, posY, posZ = GetBodyPartCoordinates(t[v], cped)
                                pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local getbonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

function GetBodyPartCoordinates(id, handle)
    if doesCharExist(handle) then
        local pedptr = getCharPointer(handle)
        local vec = ffi.new("float[3]")
        getbonePosition(ffi.cast("void*", pedptr), vec, id, true)
        return vec[0], vec[1], vec[2]
    end
end
  
  function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end
  
  function explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end

--------------------------------- anti mask ---------------------------------

function sampev.onPlayerStreamIn(id, team, model, position, rotation, color, fight)
      if ini.settings.anti_mask then
          local r, g, b, a = explode_rgba(color)
          if a >= 0 and a <= 4 then
              return {id, team, model, position, rotation, join_rgba(r, g, b, 0xAA), fight}
          end
      end
  end

function sampev.onSetPlayerColor(id, color)
      if ini.settings.anti_mask then
          local r, g, b, a = explode_rgba(color)
          if a >= 0 and a <= 4 then
              setPlayerColor(id, join_rgba(r, g, b, 0xAA))
              return false
          end
      end
  end

  function setPlayerColor(id, color)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetBitStreamWriteInt32(bs, color)
    raknetEmulRpcReceiveBitStream(72, bs)
    raknetDeleteBitStream(bs)
end

function explode_rgba(rgba)
    local r = bit.band(bit.rshift(rgba, 24), 0xFF)
    local g = bit.band(bit.rshift(rgba, 16), 0xFF)
    local b = bit.band(bit.rshift(rgba, 8), 0xFF)
    local a = bit.band(rgba, 0xFF)
    return r, g, b, a
end

function join_rgba(r, g, b, a)
    local rgba = a  -- b
    rgba = bit.bor(rgba, bit.lshift(b, 8))
    rgba = bit.bor(rgba, bit.lshift(g, 16))
    rgba = bit.bor(rgba, bit.lshift(r, 24))
    return rgba
  end

--------------------------------- object wallhack ---------------------------------

--[[

адекватно реалізувати не вийшло, прийшлось юзати костиль через

local last = {}

функція без костиля нижче, закоментована
вона працює, але текст мигає
проблема у перевірках result та coordresult

]]

local last = {}

function object_wh(bool)
    lua_thread.create(function()
        while true do wait(0)
            if bool and ini.settings.object_wh then
                for k, v in pairs(getAllObjects()) do
                    local model_id = getObjectModel(v)
                    for k2, v2 in ipairs(ini.object_wh) do
                        if model_id == v2 then
                            local px, py, pz = getCharCoordinates(PLAYER_PED)
                            local result, ox, oy, oz = getObjectCoordinates(v)
                            if result then
                                last[v] = { x = ox, y = oy, z = oz }
                            end
                            local pos = last[v]
                            if not pos then break end
                            local coordresult, rx, ry = convert3DCoordsToScreenEx(pos.x, pos.y, pos.z, true, true)
                            if not coordresult then break end
                            local dist = math.floor(getDistanceBetweenCoords3d(px, py, pz, pos.x, pos.y, pos.z))
                            local text = 'ID: ' .. model_id .. '\nDist: ' .. dist .. 'm'
                            renderFontDrawText(my_font, text, rx, ry, 0xFFFFFFFF)
                            break
                        end
                    end
                end
            end
        end
    end)
end

--[[
function object_wh()
    lua_thread.create(function()
        while true do wait(0)
            for k, v in pairs(getAllObjects()) do
                local model_id = getObjectModel(v)
                local color = 0xFFFFFFFF -- white

                for k2, v2 in ipairs(ini.object_wh) do
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    local result, ox, oy, oz = getObjectCoordinates(v)
                    local dist = math.floor(getDistanceBetweenCoords3d(x, y, z, ox, oy, oz))
                    local coordresult, renderx, rendery, floatz, floatw, floath =
                        convert3DCoordsToScreenEx(ox, oy, oz, true, true)

                    local text = 'ID: ' .. model_id .. '\nDist: ' .. dist .. 'm'

                    if not result or not coordresult then
                        break
                    end

                    if model_id == v2 then
                        renderFontDrawText(my_font, text, renderx, rendery, color)
                    end
                end
            end
        end
    end)
end
]]

---------------------------------  ---------------------------------

--[[
function sampev.onSendGiveDamage(playerId, damage, weapon, bodypart)
    sampSendGiveDamage(playerId, damage, weapon, bodypart)
    printStringNow(string.format("Sended %.1f damage to ID %d", damage, playerId), 1000)
end
]]