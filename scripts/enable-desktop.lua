local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
local root = paths.setup()

local monitors = require("monitors")
local appearance = require("appearance")

local function run(cmd)
  os.execute(cmd)
end

local function save_state(mode)
  local home = os.getenv("HOME") or "~"
  local dir = home .. "/.local/state/hypr-adaptive"
  run("mkdir -p " .. dir)
  local f = io.open(dir .. "/mode", "w")
  if f then
    f:write(mode .. "\n")
    f:close()
  end
end

local function restart_waybar(cfg, css)
  run("pkill -x waybar 2>/dev/null")
  run("sleep 0.5")
  run("waybar -c '" .. cfg .. "' -s '" .. css .. "' &")
end

restart_waybar(root .. "/config/desktop/waybar.jsonc", root .. "/config/desktop/waybar.css")

run("systemctl --user stop squeekboard")

if os.execute("command -v powerprofilesctl >/dev/null 2>&1") then
  run("powerprofilesctl set balanced")
end

local external = monitors.external()
local internal = monitors.internal()

if #external > 0 then
  for _, m in ipairs(external) do
    run("hyprctl keyword monitor " .. m .. ",preferred,auto,1")
  end
  if internal then
    run("hyprctl keyword monitor " .. internal .. ",1920x1080,auto,1.5")
  end
elseif internal then
  run("hyprctl keyword monitor " .. internal .. ",preferred,auto,1.5")
end

appearance.desktop()
save_state("desktop")

io.stdout:write("desktop profile enabled\n")
