-- Template copied wholesale into config/monitors.lua by enableHdr.sh (laptop case).
-- HDR adds bitdepth/cm/sdr params to the OLED Microstep + eDP-1. Keep eDP-1 on
-- one line so enable/disable-builtin.sh sed can flip it.

hl.monitor({
  output = "desc:Microstep MAG321UP OLED",
  mode = "3840x2160@60Hz",
  position = "3840x0",
  scale = 1,
  vrr = 1,
  bitdepth = 10,
  cm = "hdr",
  sdrbrightness = 1.2,
  sdrsaturation = 0.98,
})

hl.monitor({
  output = "desc:LG Electronics LG HDR 4K 411NTRL54206",
  mode = "3840x2160@60.00Hz",
  position = "0x0",
  scale = 1,
  vrr = 1,
})

hl.monitor({
  output = "desc:ViewSonic Corporation VX3276-QHD VSX2327A0013",
  mode = "2560x1440@60Hz",
  position = "7680x-260",
  scale = "auto",
  transform = 3,
  vrr = 1,
})

-- eDP-1: enable/disable-builtin.sh sed-flips this single line. Keep it on one line.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.333333, vrr = 1, bitdepth = 10, cm = "hdr", sdrbrightness = 1.2, sdrsaturation = 0.98 })

hl.monitor({
  output = "desc:Zhong Shan City Richsound Electronic Industrial Ltd. SONY TV  *30 0x0101010",
  mode = "preferred",
  position = "auto",
  scale = 1.333333,
  vrr = 1,
})

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
})
