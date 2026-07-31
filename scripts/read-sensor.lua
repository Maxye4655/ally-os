-- Usage: read-sensor.lua cpu|gpu|fan|tdp [cycle]
local me = arg and arg[0] or ""
local here = me:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local paths = require("paths")
paths.setup()

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local v = f:read("*l")
  f:close()
  return v and v:match("^%s*(.-)%s*$") or nil
end

local function find_hwmon(driver)
  local p = io.popen("ls /sys/class/hwmon 2>/dev/null")
  if not p then return nil end
  local found = nil
  for line in p:lines() do
    local dir = "/sys/class/hwmon/" .. line
    if read_file(dir .. "/name") == driver then
      found = dir
      break
    end
  end
  p:close()
  return found
end

local function millis(raw)
  return math.floor(tonumber(raw) / 1000)
end

local kind = arg[1]

if kind == "cpu" then
  local dir = find_hwmon("k10temp")
  if not dir then
    io.stdout:write("CPU n/a")
    return
  end
  local raw = read_file(dir .. "/temp1_input")
  if not raw then
    io.stdout:write("CPU n/a")
    return
  end
  io.stdout:write("CPU " .. millis(raw) .. "\194\176C")

elseif kind == "gpu" then
  local dir = find_hwmon("amdgpu")
  if not dir then
    io.stdout:write("GPU n/a")
    return
  end
  local raw = read_file(dir .. "/temp1_input")
  if not raw then
    io.stdout:write("GPU n/a")
    return
  end
  io.stdout:write("GPU " .. millis(raw) .. "\194\176C")

elseif kind == "fan" then
  local p = io.popen("grep -l . /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null")
  local path = p:read("*l")
  p:close()
  if not path then
    io.stdout:write("Fan n/a")
    return
  end
  local raw = read_file(path)
  io.stdout:write("Fan " .. tonumber(raw) .. " RPM")

elseif kind == "tdp" then
  local home = os.getenv("HOME") or "~"
  local dir = home .. "/.local/state/hypr-adaptive"
  local presets = { 15000, 20000, 28000 }
  local labels = { "15W", "20W", "28W" }
  local idx = tonumber(read_file(dir .. "/tdp")) or 2
  if idx < 1 or idx > #presets then idx = 2 end

  if arg[2] == "cycle" then
    idx = idx % #presets + 1
    os.execute("mkdir -p " .. dir)
    local f = io.open(dir .. "/tdp", "w")
    if f then
      f:write(idx .. "\n")
      f:close()
    end
    local has = os.execute("command -v ryzenadj >/dev/null 2>&1")
    if has == 0 or has == true then
      local mw = presets[idx]
      os.execute(string.format(
        "ryzenadj --stapm-limit=%d --fast-limit=%d --slow-limit=%d",
        mw, mw, mw
      ))
    end
  end
  io.stdout:write(labels[idx] .. " TDP")
end
