-- Keyboard/mouse launcher for desktop mode.
local has_rofi = os.execute("command -v rofi >/dev/null 2>&1")
if has_rofi == 0 or has_rofi == true then
  os.execute("rofi -show drun")
else
  os.execute("wofi --show drun")
end
