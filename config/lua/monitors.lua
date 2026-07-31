local M = {}

local function hyprctl(args)
  local p = io.popen("hyprctl " .. args, "r")
  if not p then return "" end
  local out = p:read("*a")
  p:close()
  return out or ""
end

local function names(output)
  local out = {}
  -- human-readable output lists active monitors as "Monitor <name> (ID n):"
  for name in output:gmatch("Monitor%s+([^%s%(]+)%s+%(ID") do
    if not out[name] then out[#out + 1] = name end
  end
  return out
end

local function is_external(name)
  return not (name:match("^eDP%-") or name:match("^DSI%-") or name:match("^LVDS%-"))
end

function M.list()
  return names(hyprctl("monitors"))
end

function M.external()
  local out = {}
  for _, name in ipairs(M.list()) do
    if is_external(name) then out[#out + 1] = name end
  end
  return out
end

function M.has_external()
  return #M.external() > 0
end

function M.internal()
  local all = M.list()
  for _, name in ipairs(all) do
    if name:match("^eDP%-") then return name end
  end
  for _, name in ipairs(all) do
    if not is_external(name) then return name end
  end
  return all[1]
end

return M
