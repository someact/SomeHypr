-- Small helpers shared by every other module. Loaded first by hyprland.lua.

HOME = os.getenv("HOME")
HYPR_DIR = HOME .. "/.config/hypr"

function file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

-- require() a module only if its file exists. Used for machine-written files
-- (generated/*, monitors.lua) that may not exist on a fresh install.
function require_optional(name)
    if package.searchpath(name, package.path) then
        require(name)
        return true
    end
    return false
end

-- Absolute workspace id for slot `i` (1..10) inside the current group of
-- `workspaceGroupSize` workspaces, so SUPER+1 on workspace 13 goes to 11.
function workspace_in_group(i)
    local curr = hl.get_active_workspace().id
    return math.floor((curr - 1) / workspaceGroupSize) * workspaceGroupSize + i
end

-- Case-insensitive "does `s` match any Lua pattern in `patterns`".
function matches_any(s, patterns)
    if s == nil or s == "" then return false end
    s = string.lower(s)
    for _, p in ipairs(patterns) do
        if string.find(s, p) then return true end
    end
    return false
end
