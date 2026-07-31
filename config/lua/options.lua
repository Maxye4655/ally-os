local M = {}

-- Docked: keep the internal panel on as a secondary screen (Discord/Spotify
-- while gaming). Set to true to disable it when an external display is present.
M.disable_internal = false

-- A keyboard alone is not a strong desktop signal (someone may pair a compact
-- Bluetooth keyboard while holding the Ally). "desktop" forces desktop mode;
-- the default "handheld" keeps the big touch-first UI.
M.keyboard_only_mode = "handheld"

return M
