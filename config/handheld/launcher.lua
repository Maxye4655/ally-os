-- Fullscreen touch-friendly launcher for handheld mode.
local home = os.getenv("HOME") or "~"
local dir = home .. "/.config/hypr-adaptive"
os.execute("mkdir -p " .. dir)

local theme = dir .. "/handheld-launcher.rasi"
local f = io.open(theme, "w")
assert(f)
f:write([[
configuration {
  font: "Noto Sans 22";
  fullscreen: true;
  show-icons: true;
  icon-theme: "Papirus";
  display-drun: "Apps";
  drun-display-format: "{name}";
}

window {
  background-color: rgba(15, 15, 20, 0.94);
  border-radius: 32px;
  padding: 32px;
}

mainbox {
  spacing: 24px;
}

entry {
  background-color: rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  padding: 16px 22px;
  text-color: #ffffff;
}

listview {
  columns: 4;
  lines: 5;
  padding: 16px;
  spacing: 12px;
}

element {
  background-color: transparent;
  border-radius: 24px;
  padding: 28px 24px;
  margin: 8px;
  text-color: #ffffff;
}

element icon {
  size: 64px;
}

element selected {
  background-color: rgba(79, 168, 255, 0.35);
}

element selected icon {
  color: #8ec5ff;
}

message {
  border-radius: 16px;
}
]])
f:close()

local has_rofi = os.execute("command -v rofi >/dev/null 2>&1")
if has_rofi == 0 or has_rofi == true then
  os.execute("rofi -show drun -theme " .. theme)
else
  os.execute("wofi --show drun --define=font=Noto Sans 22")
end
