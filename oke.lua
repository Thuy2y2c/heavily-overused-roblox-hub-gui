local start = tick()
local client = game:GetService('Players').LocalPlayer;
local set_identity = (type(syn) == 'table' and syn.set_thread_identity) or setidentity or setthreadcontext
local executor = identifyexecutor and identifyexecutor() or 'Unknown'

local function fail(r) return client:Kick(r) end

-- gracefully handle errors when loading external scripts
-- added a cache to make hot reloading a bit faster
local usedCache = shared.__urlcache and next(shared.__urlcache) ~= nil

shared.__urlcache = shared.__urlcache or {}
local function urlLoad(url)
    local success, result

    if shared.__urlcache[url] then
        success, result = true, shared.__urlcache[url]
    else
        success, result = pcall(game.HttpGet, game, url)
    end

    if (not success) then
        return fail(string.format('Failed to GET url %q for reason: %q', url, tostring(result)))
    end

    local fn, err = loadstring(result)
    if (type(fn) ~= 'function') then
        return fail(string.format('Failed to loadstring url %q for reason: %q', url, tostring(err)))
    end

    local results = { pcall(fn) }
    if (not results[1]) then
        return fail(string.format('Failed to initialize url %q for reason: %q', url, tostring(results[2])))
    end

    shared.__urlcache[url] = result
    return unpack(results, 2)
end

-- attempt to block imcompatible exploits
-- rewrote because old checks literally did not work
if type(set_identity) ~= 'function' then return fail('Unsupported exploit (missing "set_thread_identity")') end
if type(getconnections) ~= 'function' then return fail('You are running an outdated version of Fluxus Android. Uninstall Fluxus And Roblox and then please reinstall from www.fluxteam.net!') end
if type(getloadedmodules) ~= 'function' then return fail('You are running an outdated version of Fluxus Android. Uninstall Fluxus And Roblox and then please reinstall from www.fluxteam.net!') end
if type(getgc) ~= 'function' then   return fail('Unsupported exploit (misssing "getgc")') end

local getinfo = debug.getinfo or getinfo;
local getupvalue = debug.getupvalue or getupvalue;
local getupvalues = debug.getupvalues or getupvalues;
local setupvalue = debug.setupvalue or setupvalue;

if type(setupvalue) ~= 'function' then return fail('Unsupported exploit (misssing "debug.setupvalue")') end
if type(getupvalue) ~= 'function' then return fail('Unsupported exploit (misssing "debug.getupvalue")') end
if type(getupvalues) ~= 'function' then return fail('Unsupported exploit (missing "debug.getupvalues")') end

-- free exploit bandaid fix
if type(getinfo) ~= 'function' then
    local debug_info = debug.info;
    if type(debug_info) ~= 'function' then
        -- if your exploit doesnt have getrenv you have no hope
        if type(getrenv) ~= 'function' then return fail('Unsupported exploit (missing "getrenv")') end
        debug_info = getrenv().debug.info
    end
    getinfo = function(f)
        assert(type(f) == 'function', string.format('Invalid argument #1 to debug.getinfo (expected %s got %s', 'function', type(f)))
        local results = { debug.info(f, 'slnfa') }
        local _, upvalues = pcall(getupvalues, f)
        if type(upvalues) ~= 'table' then
            upvalues = {}
        end
        local nups = 0
        for k in next, upvalues do
            nups = nups + 1
        end
        -- winning code
        return {
            source      = '@' .. results[1],
            short_src   = results[1],
            what        = results[1] == '[C]' and 'C' or 'Lua',
            currentline = results[2],
            name        = results[3],
            func        = results[4],
            numparams   = results[5],
            is_vararg   = results[6], -- 'a' argument returns 2 values :)
            nups        = nups,     
        }
    end
end

local UI = urlLoad("https://raw.githubusercontent.com/Thuy2y2c/heavily-overused-roblox-hub-gui/main/ui.lua")
local themeManager = urlLoad("https://raw.githubusercontent.com/Thuy2y2c/heavily-overused-roblox-hub-gui/main/themeManager.lua")

local metadata = urlLoad("https://raw.githubusercontent.com/Thuy2y2c/heavily-overused-roblox-hub-gui/main/metadata.lua") -- metadata...
local httpService = game:GetService('HttpService')

local framework, scrollHandler, network
local counter = 0
