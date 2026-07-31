local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path

local paths = require("paths")
paths.setup()

local main = require("main")

local function sleep(sec)
  os.execute("sleep " .. sec)
end

local function apply_on_event(line)
  local ev = line:match("^(%w+)>>")
  if ev == "monitoradded" or ev == "monitorremoved" then
    main.apply()
  end
end

local function watch()
  main.apply()
  while true do
    local p = io.popen("hyprctl events -m 2>/dev/null", "r")
    if p then
      while true do
        local line = p:read("*l")
        if not line then break end
        apply_on_event(line)
      end
      p:close()
    end
    sleep(2)
  end
end

if arg and arg[1] == "--watch" then
  watch()
else
  main.apply()
end
