-- Desk layout. Positions are logical pixels (physical resolution / scale).
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2
local duo_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Externals stay at scale 2. Crossbar bottoms meet at y=1280:
--   MateView      3840x2560 -> 1920x1280 at 0x0
--   ASUS XG27UCS  3840x2160 -> 1920x1080 at 1920x200
-- Duo panels are 1920x1200 at scale 1.6 -> 1200x750, centered under the
-- 3840-wide bar. eDP-2 stays off while the keyboard is snapped on.
local ok, duo = pcall(require, "hypr.duo")
if ok and duo.apply_monitors then
  duo.apply_monitors(duo_scale, {
    top = "1320x1280",
    bottom = "1320x2030",
  })
end

-- One line on purpose. Omarchy's clamshell sync only reads a single-line
-- hl.monitor for the laptop output. Without it, that sync treats the
-- scale-2 catch-all as eDP-1's scale and moves the panel back a second
-- after every reload.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "1320x1280", scale = duo_scale })

hl.monitor({
  output = "desc:Huawei Technologies Co. Inc. MateView",
  mode = "3840x2560@60",
  position = "0x0",
  scale = omarchy_monitor_scale,
})

hl.monitor({
  output = "desc:ASUSTek COMPUTER INC XG27UCS",
  mode = "3840x2160@60",
  position = "1920x200",
  scale = omarchy_monitor_scale,
})

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
