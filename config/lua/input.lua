local M = {}

local EXCLUDE = { "Virtual", "onboard", "squeekboard", "wacom", "Wayland" }

local function command(cmd)
  local p = io.popen(cmd, "r")
  if not p then return "" end
  local out = p:read("*a")
  p:close()
  return out or ""
end

local function devices()
  local out = command("libinput list-devices 2>/dev/null")
  local list = {}
  local current = nil
  for line in out:gmatch("[^\n]+") do
    local name = line:match("^Device:%s*(.+)$")
    if name then
      current = { name = name, caps = {} }
      list[#list + 1] = current
    else
      local caps = line:match("^Capabilities:%s*(.+)$")
      if caps and current then
        for cap in caps:gmatch("%S+") do
          current.caps[cap] = true
        end
      end
    end
  end
  return list
end

local function real(name)
  if not name then return false end
  for _, bad in ipairs(EXCLUDE) do
    if name:find(bad, 1, true) then return false end
  end
  return true
end

function M.has_keyboard()
  for _, d in ipairs(devices()) do
    if real(d.name) and d.name:find("Keyboard", 1, true) then
      return true
    end
  end
  local fallback = command("ls /dev/input/by-id/*kbd 2>/dev/null")
  return fallback:match("/dev/input/") ~= nil
end

local function real_mouse(name)
  return name and not name:find("Touch", 1, true)
    and not name:find("TrackPoint", 1, true)
    and not name:find("Synaptics", 1, true)
    and not name:find("ALPS", 1, true)
    and not name:find("ELAN", 1, true)
end

function M.has_mouse()
  for _, d in ipairs(devices()) do
    if real(d.name) and d.caps.pointer and real_mouse(d.name) then
      return true
    end
  end
  return false
end

function M.has_touchscreen()
  for _, d in ipairs(devices()) do
    if d.caps.touch and not d.name:find("Touchpad", 1, true) then
      return true
    end
    if d.name:find("Touchscreen", 1, true) then
      return true
    end
  end
  return false
end

function M.has_controller()
  for _, d in ipairs(devices()) do
    if real(d.name) and d.caps.joystick then
      return true
    end
    if real(d.name) and d.name:match("X%-Box|Xbox|Gamepad|Controller|DualShock|DualSense|Joystick|8BitDo|8bitdo") then
      return true
    end
  end
  local fallback = command("ls /dev/input/js* 2>/dev/null; ls /dev/input/by-id/*joystick* 2>/dev/null")
  return fallback:match("/dev/input/") ~= nil
end

return M
