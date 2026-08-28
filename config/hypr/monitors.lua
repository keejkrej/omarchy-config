-- Machine-independent Omarchy display layout.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local omarchy_gdk_scale = 1.6
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Duo overlay (omarchy-zenbookduo) owns eDP-1/eDP-2 when present.
local ok, duo = pcall(require, "hypr.duo")
if ok and duo.apply_monitors then
  duo.apply_monitors(omarchy_monitor_scale)
end

-- Internal panel when no Duo overlay is installed, plus any external monitors.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
