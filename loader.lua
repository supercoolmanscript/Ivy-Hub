-- Ivy Hub V2 Remote Loader
local rawScriptURL = "https://raw.githubusercontent.com/supercoolmanscript/Ivy-Hub/main/skibidi%20script.lua"

local success, response = pcall(function()
    return game:HttpGet(rawScriptURL, true)
end)

if success and response and #response > 0 then
    local executable, err = loadstring(response)
    if executable then
        task.spawn(executable)
    else
        warn("[Ivy Hub Loader] Syntax/Execution Error: " .. tostring(err))
    end
else
    warn("[Ivy Hub Loader] Failed to fetch script from GitHub. Check if repository is public or if the default branch is 'master' instead of 'main'.")
end
