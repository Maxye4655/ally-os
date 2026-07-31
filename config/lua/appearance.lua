local M = {}

local function run(cmd)
  os.execute(cmd)
end

local function apply(opts)
  run("hyprctl keyword general:gaps_in " .. opts.gaps_in)
  run("hyprctl keyword general:gaps_out " .. opts.gaps_out)
  run("hyprctl keyword general:border_size " .. opts.border)
  run("hyprctl keyword decoration:rounding " .. opts.rounding)
  run("hyprctl keyword decoration:blur:enabled " .. tostring(opts.blur))
  run("hyprctl keyword animations:enabled " .. tostring(opts.animations))
  run("hyprctl keyword cursor:size " .. opts.cursor)
  run("hyprctl keyword misc:disable_hyprland_logo " .. tostring(opts.logo))
end

function M.handheld()
  apply({
    gaps_in = 12,
    gaps_out = 24,
    border = 3,
    rounding = 20,
    cursor = 36,
    blur = false,
    animations = false,
    logo = true,
  })
end

function M.desktop()
  apply({
    gaps_in = 5,
    gaps_out = 10,
    border = 2,
    rounding = 8,
    cursor = 24,
    blur = true,
    animations = true,
    logo = false,
  })
end

return M
