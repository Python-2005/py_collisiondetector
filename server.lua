if not Config.Enabled then return end

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

local foundFiles = {}

local function getExtension(file)
    return file:match("^.+(%..+)$")
end

local function listDir(path)
    local handle = io.popen('dir "' .. path .. '" /b /a')
    if not handle then
        handle = io.popen('ls -a "' .. path .. '"')
    end
    if not handle then return nil end

    local items = {}
    for item in handle:lines() do
        if item ~= '.' and item ~= '..' then
            table.insert(items, item)
        end
    end

    handle:close()
    return items
end

local function scanRecursive(resourceName, basePath, relativePath)
    local fullPath = basePath .. '/' .. relativePath
    local items = listDir(fullPath)
    if not items then return end

    for _, item in ipairs(items) do
        local itemPath = fullPath .. '/' .. item
        local relPath = relativePath .. '/' .. item

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
            local subItems = listDir(itemPath)
            if subItems then
                scanRecursive(resourceName, basePath, relPath)
            end
        end
    end
end

local function scanResource(resourceName)
    local basePath = GetResourcePath(resourceName)
    if not basePath then return end

    scanRecursive(resourceName, basePath, 'stream')
    scanRecursive(resourceName, basePath, 'maps')
end

CreateThread(function()
    Wait(5000)

    print('^3[CollisionChecker]^7 Starting resource scan...')

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

