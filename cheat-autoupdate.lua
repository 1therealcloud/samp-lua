
script_name('cloud-multi-cheat-autoupdate')
script_version('nil')
script_author('cloud')

-- require

require('lib.moonloader')
local requests = require('requests')

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
    while not isSampAvailable() do wait(0) end

    -- update
    local lastver = update():getLastVersion()
    if thisScript().version ~= lastver then
        update():download()
    end

    wait(-1)
end