if not Config.Enabled then return end

-- List of valid file extensions to check for collisions
local VALID_EXTENSIONS = {
    ['.ymap'] = true,
    ['.ydr']  = true,
    ['.ybn']  = true,
    ['.ytd']  = true,
    ['.ymt']  = true,
    ['.ydd']  = true,
    ['.ycd']  = true,
    ['.ynv']  = true,
    ['.ypt']  = true,
    ['.ytyp'] = true
}

local foundFiles = {} -- Store found files by name
local dirCache = {}   -- Cache directory listings to avoid repeated IO

-- Get the file extension from a filename
local function getExtension(file)
    return file:match("^.+(%..+)$")
end

-- List the contents of a directory (Windows or Unix compatible)
local function listDir(path)
    if dirCache[path] then return dirCache[path] end

    local handle = io.popen('dir "' .. path .. '" /b /a')
    if not handle then
        handle = io.popen('ls -a "' .. path .. '"')
    end
    if not handle then return {} end

    local items = {}
    for item in handle:lines() do
        if item ~= '.' and item ~= '..' then
            table.insert(items, item)
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

    -- Start scanning the 'stream' and 'maps' folders
    local queue = {
        {path = 'stream', base = basePath},
        {path = 'maps', base = basePath}
    }

    local co = coroutine.create(function()
        while #queue > 0 do
            local batchSize = 3 -- Process up to 3 items per tick
            local nextQueue = {}

            for i = 1, math.min(batchSize, #queue) do
                local current = table.remove(queue, 1)
                local fullPath = current.base .. '/' .. current.path
                local items = listDir(fullPath)
                if items then
                    for _, item in ipairs(items) do
                        local itemPath = fullPath .. '/' .. item
                        local relPath = current.path .. '/' .. item

                        local ext = getExtension(item)
                        if ext and VALID_EXTENSIONS[ext:lower()] then
                            local key = item:lower()
                            if not foundFiles[key] then
                                foundFiles[key] = {}
                            end
                            table.insert(foundFiles[key], {
                                resource = resourceName,
                                path = relPath
                            })
                        else
                            -- If the item is a directory, add it to the next queue
                            table.insert(nextQueue, {path = relPath, base = current.base})
                        end
                    end
                end
            end

            -- Add remaining items to the next queue
            for _, item in ipairs(queue) do
                table.insert(nextQueue, item)
            end
            queue = nextQueue
            coroutine.yield() -- Yield to avoid blocking the server
        end
    end)

    -- Run the coroutine until finished
    while coroutine.status(co) ~= 'dead' do
        coroutine.resume(co)
        Wait(0)
    end
end

-- Main thread to scan all resources
CreateThread(function()
    Wait(5000)
    print('^3[CollisionChecker]^7 Starting resource scan, please be patient this can take a couple of minutes...')

    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            scanResource(resourceName)
        end
    end

    print('^3[CollisionChecker]^7 Scan completed. Results:')

    local foundAny = false
    for fileName, entries in pairs(foundFiles) do
        if #entries > 1 then
            foundAny = true
            print('^1[COLLISION DETECTED]^7 File: ^3' .. fileName .. '^7')
            for _, info in ipairs(entries) do
                print('  → ^5' .. info.resource .. '^7 | ^2' .. info.path .. '^7')
            end
        end
    end

    if not foundAny then
        print('^2[CollisionChecker]^7 No duplicated MLO / prop / collision files found.')
    else
        print('^1[CollisionChecker]^7 Duplicates detected — these may cause collision or MLO issues.')
    end
end)