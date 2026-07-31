local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
paths.setup()

local profiles = require("profiles")

local M = {}

local function state_file()
  return (os.getenv("HOME") or "~") .. "/.local/state/hypr-adaptive/mode"
end

local function current()
  local f = io.open(state_file(), "r")
  if not f then return nil end
  local m = f:read("*l")
  f:close()
  if m == "handheld" or m == "desktop" then return m end
  return nil
end

function M.current()
  return current()
end

function M.to(mode)
  if mode ~= "handheld" and mode ~= "desktop" then
    io.stderr:write("unknown mode: " .. tostring(mode) .. "\n")
    return false
  end
  if current() == mode then
    io.stdout:write("already in " .. mode .. " mode\n")
    return false
  end
  io.stdout:write("switching to " .. mode .. " mode\n")
  return profiles.load(mode)
end

local target = arg and arg[1]
if target == "handheld" or target == "desktop" then
  M.to(target)
elseif target then
  io.stderr:write("usage: switch-profile.lua handheld|desktop\n")
  os.exit(1)
end

return M
