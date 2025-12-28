if not Config.Enabled then return end

-- Use Config.Extensions for valid file types
local VALID_EXTENSIONS = {}
for i = 1, #Config.Extensions do
    VALID_EXTENSIONS[Config.Extensions[i]:lower()] = true
end

local foundFiles = {} -- Store found files by name
local dirCache = {}   -- Cache directory listings to avoid repeated IO

-- Get the file extension from a filename
local function getExtension(file)
    return file:match("^.+(%..+)$")
end

-- List the contents of a directory (Windows or Unix compatible)
local function listDir(path)
    if dirCache[path] then return dirCache[path] end

    local handle = io.popen('dir "' .. path .. '" /b /a 2>nul')
    if not handle then
        handle = io.popen('ls -a "' .. path .. '" 2>/dev/null')
    end
    if not handle then return {} end

    local items = {}
    local idx = 0
    for item in handle:lines() do
        if item ~= '.' and item ~= '..' and item ~= '' then
            idx = idx + 1
            items[idx] = item
        end
    end

    handle:close()
    dirCache[path] = items
    return items
end

-- Scan a single resource for collision files
local function scanResource(resourceName)
    local basePath = GetResourcePath(resourceName)
    if not basePath then return end

    local queue = {
        {path = 'stream', base = basePath},
        {path = 'maps', base = basePath}
    }

    local co = coroutine.create(function()
        while #queue > 0 do
            local batchSize = 3
            local nextQueue = {}

            for i = 1, math.min(batchSize, #queue) do
                local current = table.remove(queue, 1)
                local fullPath = current.base .. '/' .. current.path
                local items = listDir(fullPath)
                if items then
                    for j = 1, #items do
                        local item = items[j]
                        local itemPath = fullPath .. '/' .. item
                        local relPath = current.path .. '/' .. item

                        local ext = getExtension(item)
                        if ext and VALID_EXTENSIONS[ext:lower()] then
                            local key = item:lower()
                            if not foundFiles[key] then
                                foundFiles[key] = {}
                            end
                            local fLen = #foundFiles[key]
                            foundFiles[key][fLen + 1] = {
                                resource = resourceName,
                                path = relPath
                            }
                        else
                            -- If the item is a directory, add it to the next queue
                            local nLen = #nextQueue
                            nextQueue[nLen + 1] = {path = relPath, base = current.base}
                        end
                    end
                end
            end

            for k = 1, #queue do
                local nLen = #nextQueue
                nextQueue[nLen + 1] = queue[k]
            end
            queue = nextQueue
            coroutine.yield()
        end
    end)

    while coroutine.status(co) ~= 'dead' do
        coroutine.resume(co)
        Wait(0)
    end
end

-- Collect keys numerically
local function getAllKeys(tbl)
    local keys = {}
    local idx = 0
    for k, _ in next, tbl do
        idx = idx + 1
        keys[idx] = k
    end
    return keys
end

-- Main thread to scan all resources
CreateThread(function()
    Wait(5000)
    print('^3[CollisionChecker]^7 Starting resource scan, please be patient...')

    local totalResources = GetNumResources()
    for i = 0, totalResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            scanResource(resourceName)
        end
    end

    print('^3[CollisionChecker]^7 Scan completed. Results:')

    local keys = getAllKeys(foundFiles)
    local foundAny = false
    for i = 1, #keys do
        local fileName = keys[i]
        local entries = foundFiles[fileName]
        if #entries > 1 then
            foundAny = true
            print('^1[COLLISION]^7 File: ^3' .. fileName .. '^7 (' .. #entries .. ' copies)')
            for j = 1, #entries do
                local info = entries[j]
                print('  [^5' .. j .. '^7] ' .. info.resource .. ' → ^2' .. info.path .. '^7')
            end
            print('')
        end
    end

    if not foundAny then
        print('^2[CollisionChecker]^7 No duplicated MLO / prop / collision files found.')
    else
        print('^1[CollisionChecker]^7 Duplicates detected — these may cause collision or MLO issues.')
    end

    print('^3[CollisionChecker]^7 Total files scanned: ' .. #keys)
end)