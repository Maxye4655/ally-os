-- Mode-aware application launcher: handheld gets the touch grid, desktop the
-- compact keyboard list.
local home = os.getenv("HOME") or "~"
local mode = "handheld"
local f = io.open(home .. "/.local/state/hypr-adaptive/mode", "r")
if f then
  local m = f:read("*l")
  f:close()
  if m == "desktop" then mode = m end
end
os.execute("lua '" .. home .. "/.config/hypr/config/" .. mode .. "/launcher.lua'")
