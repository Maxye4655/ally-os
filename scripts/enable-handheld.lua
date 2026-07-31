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

restart_waybar(root .. "/config/handheld/waybar.jsonc", root .. "/config/handheld/waybar.css")

run("systemctl --user start squeekboard")

if os.execute("command -v powerprofilesctl >/dev/null 2>&1") then
  run("powerprofilesctl set power-saver")
end

for _, m in ipairs(monitors.external()) do
  run("hyprctl keyword monitor " .. m .. ",disable")
end

local internal = monitors.internal()
if internal then
  run("hyprctl keyword monitor " .. internal .. ",preferred,0x0,1.5")
end

appearance.handheld()
save_state("handheld")

io.stdout:write("handheld profile enabled\n")
