local M = {}

local root = PACKAGE_ROOT or "."

local function execute(path)
  local p = io.popen("lua '" .. path .. "'", "r")
  if not p then return nil end
  local out = p:read("*a")
  p:close()
  return out
end

function M.load(name)
  if name ~= "handheld" and name ~= "desktop" then
    io.stderr:write("unknown profile: " .. tostring(name) .. "\n")
    return false
  end
  local out = execute(root .. "/scripts/enable-" .. name .. ".lua")
  if out then io.stdout:write(out) end
  return true
end

return M
