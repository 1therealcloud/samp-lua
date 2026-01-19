script_name('cloud-multi-cheat')
script_version('19.01.2026')
script_author('cloud')

-- require

require('lib.moonloader')
local memory = require('memory')
local ffi = require('ffi')
local sampev = require('samp.events')
local weapons = require('game.weapons')
local inicfg = require('inicfg')

require('samp.synchronization')
local sampfuncs = require('sampfuncs')
local raknet = require('samp.raknet')
local requests = require('requests')

-- ini
local script_name = thisScript().filename:match("^(.*)%.%w+$")

local directIni = '' .. script_name .. '.ini'

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
        antidrunk = false
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
        object_wh = 'objwh',
        antidrunk = 'antidrunk'
    },

    int_settings = {
        stream_info_y = 450,
        stream_info_x = 50
    },

    object_wh = {}
}, directIni)
inicfg.save(ini, directIni)

-- do not set the value to true
local cjrun = false

-- autoupdate

function update()
    local raw = 'https://raw.githubusercontent.com/1therealcloud/samp-lua/refs/heads/master/version.json'
    local dlstatus = require('moonloader').download_status

    local f = {}
    function f:getLastVersion()
        local response = requests.get(raw)
        if response.status_code == 200 then
            return decodeJson(response.text)['latest']
        else
            return 'UNKNOWN'
        end
    end
    function f:download()
        local response = requests.get(raw)
        if response.status_code == 200 then
            downloadUrlToFile(decodeJson(response.text)['updateurl'], thisScript().path, function(id, status, p1, p2)
                print('Downloading ' .. decodeJson(response.text)['updateurl'] .. ' to ' .. thisScript().path)
                if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                    print('Script updated, restarting...')
                    flashActiveWindow()
                    thisScript():reload()
                end
            end)
        else
            print('Error, unable to apply update, code: ' .. response.status_code)
        end
    end
    return f
end

-- main

function main()
    while not isSampAvailable() do
        wait(100)
    end

    -- update():readSerials()

    -- update
    local lastver = update():getLastVersion()
    print('{73b461}Loaded, version: ' .. lastver)
    if thisScript().version ~= lastver then
        update():download()
    end

    writeMemory(0x58E1DD, 2, 0x9090, true) -- fast crosshair
    writeMemory(0x058E280, 1, 0xEB, true) -- fix crosshair

    -- misc
    noExplosion()

    -- main functions
    enableAllFunctions()
    registerChatCommands()
    dialogRespond()

    wait(-1)
end

function noExplosion()
    lua_thread.create(function()
        while true do wait(0)
            if isCharInAnyCar(PLAYER_PED) then
                local carid = storeCarCharIsInNoSave(PLAYER_PED)
                local health = getCarHealth(carid)
                local speed = getCarSpeed(carid)
                if isCarUpsidedown(carid) and health <= 350 then
                    setCarHealth(carid, 350)
                end -- переворот хп
            end -- if in car
        end -- while
    end)
end

--------------------------------- register commands --------------------------------

function registerChatCommands()
    sampRegisterChatCommand('cheatunload', function()
        error("Forced crash")
    end)

    sampRegisterChatCommand('cheathelp', function()
        showHelpDialog()
    end)

    sampRegisterChatCommand(ini.commands.nick_render, function()
        ini.settings.nick_render = not ini.settings.nick_render
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.nick_render and 'Activated!' or 'DeActivated!', -1)
    end)

    sampRegisterChatCommand(ini.commands.vehicle_render, function()
        ini.settings.vehicle_render = not ini.settings.vehicle_render
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.vehicle_render and 'Activated!' or 'DeActivated!', -1)
    end)

    sampRegisterChatCommand(ini.commands.bone_wh, function()
        ini.settings.bone_wh = not ini.settings.bone_wh
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.bone_wh and 'Activated!' or 'DeActivated!', -1)
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
    end)

    sampRegisterChatCommand(ini.commands.object_wh, function(id)
        if id == nil or id == "" then
            ini.settings.object_wh = not ini.settings.object_wh
            sampAddChatMessage(ini.settings.object_wh and 'Activated!' or 'DeActivated!', -1)
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

    sampRegisterChatCommand(ini.commands.antidrunk, function()
        ini.settings.antidrunk = not ini.settings.antidrunk
        inicfg.save(ini, directIni)
        sampAddChatMessage(ini.settings.antidrunk and 'Activated!' or 'DeActivated!', -1)
    end)

end

--------------------------------- enable all ---------------------------------

function enableAllFunctions()
    staticcrosshair(ini.settings.static_crosshair)
    nospread(ini.settings.no_spread)
    extraws(ini.settings.extra_ws)

    autoreload()
    bonewh()
    streaminfo()
    nickrender()
    vehiclerender()
    object_wh()
end

--------------------------------- disable all ---------------------------------

function disableAllFunctions()
    staticcrosshair(false)
    nospread(false)
    extraws(false)
    cj_run(false)
end

--------------------------------- on terminate ---------------------------------

addEventHandler('onScriptTerminate', function(script)
    if script == script.this then
        disableAllFunctions()
    end
end)

--------------------------------- on window message ---------------------------------

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if msg == 0x101 then -- 220
        if isGameInputFree() then

            if wparam == 220 then -- backslash
                if doesCharExist(playerPed) then
                    cjrun = not cjrun
                    cj_run(cjrun)
                    sampAddChatMessage(cjrun and 'Activated' or 'Deactivated!', -1)
                end
            end

            if wparam == 46 then -- delete
                if isCharInAnyCar(PLAYER_PED) then
                    setCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED),
                    getCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED)))
                    addOneOffSound(0.0, 0.0, 0.0, 1054)
                else
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    setCharCoordinates(PLAYER_PED, x, y, z - 1)
                    addOneOffSound(0.0, 0.0, 0.0, 1055)
                end
            end
        end -- if if isGameInputFree()
    end -- msg == 0x101
end)

--------------------------------- dialog --------------------------------

function showHelpDialog()
    sampShowDialog(1231, 'Script settings', 'Function\tCommand\tStatus\nBone WH\t/' .. ini.commands.bone_wh .. '\t' ..
        string.format(ini.settings.bone_wh and '{73b461}true' or '{dc4747}false') .. '\nStatic crosshair\t/' ..
        ini.commands.static_crosshair .. '\t' ..
        string.format(ini.settings.static_crosshair and '{73b461}true' or '{dc4747}false') .. '\nNo spread\t/' ..
        ini.commands.no_spread .. '\t' .. string.format(ini.settings.no_spread and '{73b461}true' or '{dc4747}false') ..
        '\nAuto reload\t/' .. ini.commands.auto_reload .. '\t' ..
        string.format(ini.settings.auto_reload and '{73b461}true' or '{dc4747}false') .. '\nExtra WS\t/' ..
        ini.commands.extra_ws .. '\t' .. string.format(ini.settings.extra_ws and '{73b461}true' or '{dc4747}false') ..
        '\nAnti mask\t/' .. ini.commands.anti_mask .. '\t' ..
        string.format(ini.settings.anti_mask and '{73b461}true' or '{dc4747}false') .. '\nStream info\t/' ..
        ini.commands.stream_info .. '\t' ..
        string.format(ini.settings.stream_info and '{73b461}true' or '{dc4747}false') .. '\nNick render\t/' ..
        ini.commands.nick_render .. '\t' ..
        string.format(ini.settings.nick_render and '{73b461}true' or '{dc4747}false') .. '\nVehicle render\t/' ..
        ini.commands.vehicle_render .. '\t' ..
        string.format(ini.settings.vehicle_render and '{73b461}true' or '{dc4747}false') .. '\nObject render\t/' ..
        ini.commands.object_wh .. '\t' .. string.format(ini.settings.object_wh and '{73b461}true' or '{dc4747}false') ..
        '', 'Accept', 'Cancel', 5) -- ini.setting.object_wh
end

function dialogRespond()
    while true do wait(0)
        local result, button, list, input = sampHasDialogRespond(1231)
        if result then
            if button == 1 then
                if list == 0 then
                    ini.settings.bone_wh = not ini.settings.bone_wh
                    
                end
                if list == 1 then
                    ini.settings.static_crosshair = not ini.settings.static_crosshair
                    staticcrosshair(ini.settings.static_crosshair)
                end
                if list == 2 then
                    ini.settings.no_spread = not ini.settings.no_spread
                    nospread(ini.settings.no_spread)
                end
                if list == 3 then
                    ini.settings.auto_reload = not ini.settings.auto_reload
                end
                if list == 4 then
                    ini.settings.extra_ws = not ini.settings.extra_ws
                    extraws(ini.settings.extra_ws)
                end
                if list == 5 then
                    ini.settings.anti_mask = not ini.settings.anti_mask
                end
                if list == 6 then
                    ini.settings.stream_info = not ini.settings.stream_info
                end
                if list == 7 then
                    ini.settings.nick_render = not ini.settings.nick_render
                end
                if list == 8 then
                    ini.settings.vehicle_render = not ini.settings.vehicle_render
                end
                if list == 9 then
                    ini.settings.object_wh = not ini.settings.object_wh
                end
                showHelpDialog()
                inicfg.save(ini, directIni)
            end
        end
    end
end

--------------------------------- functions --------------------------------

function isPlayerPassenger()
    if not isCharInAnyCar(PLAYER_PED) then
        return (getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)))
    end
end

function isGameInputFree()
    return (not sampIsCursorActive() and not sampIsChatInputActive() and not sampIsDialogActive() and
               not isSampfuncsConsoleActive() and not sampIsScoreboardOpen() and not isPauseMenuActive())
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

-- flashActiveWindow

ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;

    HWND GetActiveWindow(void);
    BOOL FlashWindow(HWND hWnd, BOOL bInvert);
]]

function flashActiveWindow()
    local window = ffi.C.GetActiveWindow()
    ffi.C.FlashWindow(window, true)
end

-- ShowSystemMessage

function ShowSystemMessage(text, title, style)
    ffi.cdef [[
        int MessageBoxA(
            void* hWnd,
            const char* lpText,
            const char* lpCaption,
            unsigned int uType
        );
    ]]
    local hwnd = ffi.cast('void*', readMemory(0x00C8CF88, 4, false))
    ffi.C.MessageBoxA(hwnd, text, title, style and (style + 0x50000) or 0x50000)
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
        local dist = math.sqrt((xi - x) ^ 2 + (yi - y) ^ 2 + (zi - z) ^ 2)
        if result and dist <= NTdist then
            res = true
        end
    end
    return res
end

function nickrender()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.nick_render then
                for k, v in ipairs(getAllChars()) do
                    local result, id = sampGetPlayerIdByCharHandle(v)
                    if result and v ~= PLAYER_PED then
                        local name = sampGetPlayerNickname(id)
                        local color = string.format('%06X', bit.band(sampGetPlayerColor(id), 0xFFFFFF))
                        local x, y, z = getCharCoordinates(v)
                        if isCharSittingInAnyCar(v) then
                            z = z + 1
                        end
                        local coordresult, renderx, rendery, floatz, floatw, floath =
                            convert3DCoordsToScreenEx(x, y, z + 1.0, true, true)
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

function vehiclerender()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.vehicle_render then
                for k, v in ipairs(getAllVehicles()) do
                    local result, id = sampGetVehicleIdByCarHandle(v)
                    if result then
                        local health = string.format(getCarHealth(v))
                        local x, y, z = getCarCoordinates(v)
                        local coordresult, renderx, rendery, floatz, floatw, floath =
                            convert3DCoordsToScreenEx(x, y, z, true, true)
                        local doorStatus = getCarDoorLockStatus(v)
                        if coordresult then
                            local text = '{' .. (doorStatus == 0 and '73b461' or 'dc4747') .. '}' .. health .. 'hp (' ..
                                             id .. ')'
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

function streaminfo()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.stream_info then
                local y = ini.int_settings.stream_info_y
                local x = ini.int_settings.stream_info_x
                for k, v in ipairs(getAllChars()) do
                    local result, id = sampGetPlayerIdByCharHandle(v)
                    if result and v ~= PLAYER_PED then
                        local color = string.format('%06X', bit.band(sampGetPlayerColor(id), 0xFFFFFF))
                        local nick = sampGetPlayerNickname(id)
                        table.insert(players, {nick, id})
                        local player_text = '{' .. color .. '}' .. nick .. '{ffffff}[' .. id .. ']'
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
    if bool and ini.settings.extra_ws then
        writeMemory(0x5231A6, 1, 0x90)
    else
        writeMemory(0x5231A6, 1, 0x75)
    end
end

--------------------------------- autoreload ---------------------------------

function autoreload()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.auto_reload then
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
    if bool and ini.settings.static_crosshair then
        memory.copy(0x609D80, memory.strptr("\x90\x90"), 2, true)
    else
        memory.copy(0x609D80, memory.strptr("\x7A\x08"), 2, true)
    end
end

--------------------------------- nospread ---------------------------------

function nospread(bool)
    if bool and ini.settings.no_spread then
        memory.setfloat(0x8D6110, 0.0, true) -- non shotguns
        memory.setfloat(0x8D611C, 0.0, true)
    else
        memory.setfloat(0x8D6110, 0.75, true) -- non shotguns
        memory.setfloat(0x8D611C, 0.050000001, true)
    end
end

--------------------------------- bonewh ---------------------------------

function bonewh()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.bone_wh then
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
    local argb = b -- b
    argb = bit.bor(argb, bit.lshift(g, 8)) -- g
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
    local rgba = a -- b
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

function object_wh()
    lua_thread.create(function()
        while true do wait(0)
            if ini.settings.object_wh then
                for k, v in pairs(getAllObjects()) do
                    local model_id = getObjectModel(v)
                    for k2, v2 in ipairs(ini.object_wh) do
                        if model_id == v2 then
                            local px, py, pz = getCharCoordinates(PLAYER_PED)
                            local result, ox, oy, oz = getObjectCoordinates(v)
                            if result then
                                last[v] = {
                                    x = ox,
                                    y = oy,
                                    z = oz
                                }
                            end
                            local pos = last[v]
                            if not pos then
                                break
                            end
                            local coordresult, rx, ry = convert3DCoordsToScreenEx(pos.x, pos.y, pos.z, true, true)
                            if not coordresult then
                                break
                            end
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

--------------------------------- anti drunk ---------------------------------

function sampev.onSetPlayerDrunk(drunkLevel)
    if ini.settings.antidrunk then
        return false
    end
end

---------------------------------  ---------------------------------
