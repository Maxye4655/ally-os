local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
paths.setup()

local profiles = require("profiles")
local monitors = require("monitors")
local input = require("input")
local options = require("options")
local switch = require("switch-profile")

local M = {}

function M.state()
  return {
    external_monitor = monitors.has_external(),
    touchscreen = input.has_touchscreen(),
    controller = input.has_controller(),
    keyboard = input.has_keyboard(),
    mouse = input.has_mouse(),
  }
end

function M.detect()
  local s = M.state()
  if s.external_monitor then return "desktop" end
  if s.keyboard and s.mouse then return "desktop" end
  if s.keyboard and options.keyboard_only_mode == "desktop" then return "desktop" end
  return "handheld"
end

function M.apply()
  return switch.to(M.detect())
end

if arg and arg[1] == "--apply" then
  M.apply()
end

return M
