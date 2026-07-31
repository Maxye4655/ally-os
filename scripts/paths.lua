local M = {}

local function cwd()
  local p = io.popen("pwd")
  local out = p:read("*l") or "."
  p:close()
  return out
end

local function expand(path)
  if path:sub(1, 1) == "~" then
    path = (os.getenv("HOME") or "") .. path:sub(2)
  end
  if path == "." or path == "" then
    return cwd()
  end
  if path:sub(1, 1) == "/" then return path end
  return cwd() .. "/" .. path
end

function M.root()
  local raw
  if PACKAGE_ROOT then
    raw = PACKAGE_ROOT
  else
    raw = (arg and arg[0]:match("^(.*)/scripts/[^/]+$"))
      or (arg and arg[0]:match("^(.*)/config/lua/[^/]+$"))
      or "."
  end
  return expand(raw)
end

function M.setup()
  local root = M.root()
  PACKAGE_ROOT = root
  package.path = root .. "/config/lua/?.lua;" .. root .. "/scripts/?.lua;" .. package.path
  return root
end

return M
