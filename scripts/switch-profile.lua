local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
paths.setup()

local profiles = require("profiles")

local M = {}

local function state_dir()
  return (os.getenv("HOME") or "~") .. "/.local/state/hypr-adaptive"
end

local function state_file()
  return state_dir() .. "/mode"
end

local function current()
  local f = io.open(state_file(), "r")
  if not f then return nil end
  local m = f:read("*l")
  f:close()
  if m == "handheld" or m == "desktop" then return m end
  return nil
end

local function pid()
  local f = io.open("/proc/self/stat", "r")
  if not f then return "" end
  local stat = f:read("*l")
  f:close()
  return (stat and stat:match("^(%d+)")) or ""
end

local function alive(proc)
  if proc == "" then return false end
  local f = io.open("/proc/" .. proc, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function lock_age(dir)
  local p = io.popen("stat -c %Y " .. dir .. " 2>/dev/null")
  if not p then return 0 end
  local t = tonumber(p:read("*l") or "0")
  p:close()
  if not t or t == 0 then return 0 end
  return os.time() - t
end

local function acquire()
  local dir = state_dir() .. "/lock"
  os.execute("mkdir -p " .. state_dir())
  for _ = 1, 200 do
    if os.execute("mkdir " .. dir .. " 2>/dev/null") == true then
      local f = io.open(dir .. "/pid", "w")
      if f then
        f:write(pid() .. "\n")
        f:close()
      end
      return true
    end
    local f = io.open(dir .. "/pid", "r")
    local stale = false
    if f then
      local p = (f:read("*l") or ""):gsub("%s+$", "")
      f:close()
      stale = not alive(p)
    else
      stale = lock_age(dir) > 5
    end
    if stale then
      os.execute("rm -f " .. dir .. "/pid 2>/dev/null; rmdir " .. dir .. " 2>/dev/null")
    end
    os.execute("sleep 0.1")
  end
  return false
end

local function release()
  local dir = state_dir() .. "/lock"
  os.execute("rm -f " .. dir .. "/pid 2>/dev/null; rmdir " .. dir .. " 2>/dev/null")
end

function M.current()
  return current()
end

function M.to(mode)
  if mode ~= "handheld" and mode ~= "desktop" then
    io.stderr:write("unknown mode: " .. tostring(mode) .. "\n")
    return false
  end
  if not acquire() then
    io.stderr:write("profile switch already in progress\n")
    return false
  end
  if current() == mode then
    release()
    io.stdout:write("already in " .. mode .. " mode\n")
    return false
  end
  io.stdout:write("switching to " .. mode .. " mode\n")
  local ok = profiles.load(mode)
  release()
  return ok
end

local target = arg and arg[1]
if target == "handheld" or target == "desktop" then
  M.to(target)
elseif target then
  io.stderr:write("usage: switch-profile.lua handheld|desktop\n")
  os.exit(1)
end

return M
