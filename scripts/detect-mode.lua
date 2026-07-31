local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
paths.setup()

local main = require("main")

local function sleep(sec)
  os.execute("sleep " .. sec)
end

local function hyprctl_ok()
  local p = io.popen("hyprctl monitors >/dev/null 2>&1")
  if not p then return false end
  local ok = p:close()
  return ok == 0 or ok == true
end

local function watch(interval)
  while true do
    if hyprctl_ok() then
      local p = io.popen("timeout " .. interval .. " hyprctl events -m 2>/dev/null")
      if p then
        p:read("*l")
        p:close()
      else
        sleep(interval)
      end
    else
      sleep(interval)
    end
    main.apply()
  end
end

if arg and arg[1] == "--watch" then
  watch(10)
else
  main.apply()
end
