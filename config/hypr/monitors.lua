-- Desk layout. Positions are logical pixels (physical resolution / scale).
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- T at scale 2. Crossbar bottoms meet at y=1280:
--   MateView      3840x2560 -> 1920x1280 at 0x0
--   ASUS XG27UCS  3840x2160 -> 1920x1080 at 1920x200
-- Duo panels are 960x600, centered under the 3840-wide bar.
-- eDP-2 stays off while the keyboard is snapped onto that panel.
local ok, duo = pcall(require, "hypr.duo")
if ok and duo.apply_monitors then
  duo.apply_monitors(omarchy_monitor_scale, {
    top = "1440x1280",
    bottom = "1440x1880",
  })
end

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
