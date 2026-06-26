hl.config({
  input = {
    kb_layout = "dk",
    kb_variant = "",
    kb_model = "",
    kb_options = "fkeys:basic_13-24",
    kb_rules = "",
    numlock_by_default = true,
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.8,
    },
  },
  gestures = {
    workspace_swipe_touch = true,
  },
})

hl.device({ name = "logitech-usb-receiver",    sensitivity = -0.72 })
hl.device({ name = "logitech-pro-x-2-dex-1",   sensitivity = -0.72 })
